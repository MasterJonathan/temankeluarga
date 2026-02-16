const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");

admin.initializeApp();

const geminiApiKey = defineSecret("GEMINI_API_KEY");

exports.generateDailyMemoryArt = onCall({ region: "asia-southeast2", timeoutSeconds: 60, secrets: [geminiApiKey] }, async (request) => {
  // 1. Validasi User
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User harus login untuk menggunakan fitur ini.");
  }

  const { dateString, familyId } = request.data;
  const apiKey = geminiApiKey.value(); // Menggunakan secret manager

  if (!apiKey) {
    throw new HttpsError("failed-precondition", "API Key belum dikonfigurasi di server.");
  }

  try {
    // 2. Ambil Data Kenangan Hari Itu dari Firestore
    const startOfDay = new Date(dateString);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(dateString);
    endOfDay.setHours(23, 59, 59, 999);

    const snapshot = await admin.firestore().collection("memories")
      .where("familyId", "==", familyId)
      .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
      .get();

    let storyText = "";
    let photoUrls = [];

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.content) storyText += data.content + ". ";
      if (data.imageUrl) photoUrls.push(data.imageUrl);
    });

    if (!storyText && photoUrls.length === 0) {
      return { success: false, message: "Tidak ada kenangan di tanggal ini untuk dilukis." };
    }

    // 3. Siapkan Request ke Gemini
    // Kita akan menggunakan endpoint generateContent biasa tapi menyertakan gambar sebagai input part jika ada.

    // Convert Image URL to Base64 (Gemini butuh base64 untuk input image di API ini)
    const imageParts = [];
    if (photoUrls.length > 0) {
      // Ambil max 2 foto terbaik agar tidak overload token
      const photosToUse = photoUrls.slice(0, 2);

      for (const url of photosToUse) {
        try {
          // Perlu axios import di atas (pastikan sudah require axios jika belum)
          const axios = require("axios");
          const imgRes = await axios.get(url, { responseType: 'arraybuffer' });
          const b64 = Buffer.from(imgRes.data).toString('base64');
          imageParts.push({
            inlineData: {
              mimeType: "image/jpeg", // Asumsi jpeg/png
              data: b64
            }
          });
        } catch (e) {
          console.warn("Gagal download foto utk prompt:", e);
        }
      }
    }

    // 4. Susun Prompt Scrapbook
    // Instruksi agar teks user dimasukkan ke dalam gambar
    const textPrompt = `
      Create a digital scrapbook page layout. 
      Theme: Warm family memories, nostalgic, cute aesthetic.
      
      Content to include visually in the image:
      1. A handwritten-style date header: "${dateString}".
      2. The following text written creatively on a note or paper scrap element: "${storyText.substring(0, 150)}..."
      3. Integrate the provided input images into the layout as polaroid photos or taped snapshots.
      4. Add decorative stickers like hearts, washi tape, and doodles related to the text content.
      
      Style: Watercolor and paper texture background. High resolution.
    `;

    // 5. Call API Nano Banana Pro (Gemini 3 Pro Image Preview)
    const client = new GoogleGenAI({ apiKey: apiKey });

    // Note: Model name 'gemini-3-pro-image-preview' for advanced composition
    const response = await client.models.generateContent({
      model: 'gemini-3-pro-image-preview',
      contents: [
        {
          parts: [
            { text: textPrompt },
            ...imageParts // Masukkan foto asli user sebagai referensi
          ]
        }
      ],
      config: {
        responseModalities: ["IMAGE"],
        imageConfig: {
          aspectRatio: "1:1",
          imageSize: "1K"
        }
      }
    });

    // 6. Proses Response (Base64)
    const candidates = response.candidates;
    if (!candidates || candidates.length === 0) {
      throw new Error("No image generated.");
    }

    const imagePart = candidates[0].content.parts.find(p => p.inlineData);
    if (!imagePart) {
      throw new Error("Response format invalid (no inlineData).");
    }

    const base64Result = imagePart.inlineData.data;
    const buffer = Buffer.from(base64Result, 'base64');

    // 7. Simpan Hasil ke Firebase Storage & Firestore
    const bucket = admin.storage().bucket();
    const fileName = `families/${familyId}/scrapbooks/${dateString}_${Date.now()}.png`;
    const file = bucket.file(fileName);

    await file.save(buffer, {
      metadata: { contentType: 'image/png' },
      public: true
    });

    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    await admin.firestore().collection("memories").add({
      familyId: familyId,
      authorId: "ai_scrapbook",
      authorName: "Buku Kenangan 📖",
      content: "Halaman jurnal otomatis tanggal " + dateString,
      imageUrl: publicUrl,
      date: admin.firestore.Timestamp.now(),
      type: "scrapbook_page", // Tipe baru
      reactions: {},
      sourceDate: dateString
    });

    return {
      success: true,
      imageUrl: publicUrl,
      message: "Berhasil membuat halaman scrapbook!"
    };

  } catch (error) {
    console.error("Scrapbook Gen Error:", error);
    throw new HttpsError("internal", "Gagal memproses scrapbook.", error.message);
  }
});