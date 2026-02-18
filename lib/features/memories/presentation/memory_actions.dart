import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/features/memories/presentation/memory_provider.dart';
import '../data/memory_repository.dart';
import '../domain/memory_model.dart';
import 'package:http/http.dart' as http;

// Import tambahan untuk fitur Chat Otomatis
import 'package:teman_keluarga/features/family_chat/domain/chat_model.dart';
import 'package:teman_keluarga/features/family_chat/presentation/chat_actions.dart';

class MemoryActions {
  final Ref ref;
  MemoryActions(this.ref);

  // 1. Post Memory (Upload Image + Save to DB + Send Chat Log)
  Future<void> postMemory({
    required String familyId,
    required String authorId,
    required String authorName,
    required String content,
    File? imageFile,
  }) async {
    final repo = ref.read(memoryRepositoryProvider);

    String? imageUrl;

    // A. Upload foto jika ada
    if (imageFile != null) {
      imageUrl = await repo.uploadImage(imageFile, familyId);
    }

    // B. Buat Object Memory
    final newPost = MemoryPost(
      id: '', // Auto Generate di Repo nanti
      familyId: familyId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      imageUrl: imageUrl,
      date: DateTime.now(),
    );

    // C. Simpan ke Repository
    await repo.addMemory(newPost);

    // D. Invalidate UI
    // Tidak perlu invalidate manual karena kita listen ke Query Stream yang sama
    // Tapi untuk keamanan, boleh di-invalidate agar memaksa fetch ulang
    ref.invalidate(memoryProvider(familyId));

    // E. --- LOGIC CHAT (BARU) ---
    // Kirim notifikasi ke chat keluarga bahwa ada memori baru
    try {
      await ref
          .read(chatActionsProvider)
          .sendSystemMessage(
            familyId: familyId,
            senderId: authorId,
            senderName: authorName,
            text: "📸 Membagikan kenangan baru.",
            contextType: ChatContextType.memory, // Icon konteks galeri/memori
            contextData: "Galeri Keluarga",
          );
    } catch (e) {
      debugPrint("Gagal kirim log memori ke chat: $e");
    }
  }

  // 2. React to Post (Original)
  Future<void> reactToPost(
    String familyId,
    String postId,
    String userId,
    String emoji,
  ) async {
    final repo = ref.read(memoryRepositoryProvider);
    await repo.reactToPost(postId, userId, emoji);
    // UI otomatis update via Stream, tapi kita invalidate biar responsif
    ref.invalidate(memoryProvider(familyId));
  }

  Future<void> deleteMemory(
    String familyId,
    String postId,
    String? imageUrl,
  ) async {
    final repo = ref.read(memoryRepositoryProvider);

    // 1. Panggil Repo
    await repo.deleteMemory(postId, imageUrl);

    // 2. Refresh UI
    ref.invalidate(memoryProvider(familyId));
  }

  Future<void> generateDailyArt({
    required String familyId,
    required String userId,
    required String userName,
    required DateTime date,
  }) async {
    try {
      // 1. AMBIL DATA KENANGAN DARI FIRESTORE (Sesuai Logic Cloud Function)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance.collection("memories")
        .where("familyId", isEqualTo: familyId)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("date", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

      String storyText = "";
      List<String> photoUrls = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Gabungkan semua cerita hari itu
        if (data['content'] != null && data['content'].toString().isNotEmpty) {
          storyText += "${data['content']}. ";
        }
        // Kumpulkan semua foto hari itu
        if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
          photoUrls.add(data['imageUrl']);
        }
      }

      if (storyText.isEmpty && photoUrls.isEmpty) {
        throw Exception("Tidak ada kenangan (foto/cerita) di tanggal ini untuk dibuatkan scrapbook.");
      }

      // 2. SIAPKAN GAMBAR INPUT (DOWNLOAD DULU)
      // Gemini butuh input gambar berupa Bytes (InlineDataPart), bukan URL.
      List<Uint8List> inputImages = [];
      
      // Ambil maksimal 2 foto terbaik agar tidak terlalu berat/mahal
      final photosToUse = photoUrls.take(2); 
      
      for (String url in photosToUse) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            inputImages.add(response.bodyBytes);
          }
        } catch (e) {
          print("Gagal download gambar referensi: $e");
        }
      }

      // 3. SIAPKAN MODEL (Nano Banana Pro)
      // Menggunakan gemini-3-pro-image-preview sesuai request
      final model =  FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-image', 
        generationConfig: GenerationConfig(
          responseModalities: [ResponseModalities.image], // Output hanya gambar
          // Aspect Ratio diatur lewat prompt jika config belum support di SDK versi ini
        ),
      );

      // 4. SUSUN PROMPT SCRAPBOOK (Sesuai Cloud Function)
      final dateString = "${date.day}-${date.month}-${date.year}";
      final textPrompt = '''
        Create a digital scrapbook page layout. 
        Theme: Warm family memories, nostalgic, cute aesthetic.
        
        Content to include visually in the image:
        1. A handwritten-style date header: "$dateString".
        2. The following text written creatively on a note or paper scrap element: "${storyText.substring(0, min(storyText.length, 150))}..."
        3. Integrate the provided input images into the layout as polaroid photos or taped snapshots.
        4. Add decorative stickers like hearts, washi tape, and doodles related to the text content.
        
        Style: Watercolor and paper texture background. High resolution.
      ''';

      // 5. GABUNGKAN TEXT + GAMBAR (MULTIMODAL INPUT)
      final contentParts = <Part>[
        TextPart(textPrompt),
        ...inputImages.map((bytes) => InlineDataPart('image/jpeg', bytes)),
      ];

      print("Mulai melukis scrapbook...");
      
      // 6. PANGGIL API
      final response = await model.generateContent([
        Content.multi(contentParts)
      ]);

      // 7. PROSES HASIL
      if (response.inlineDataParts.isNotEmpty) {
        final resultImageBytes = response.inlineDataParts.first.bytes;
        
        // 8. UPLOAD KE STORAGE
        final fileName = "scrapbook_${dateString.replaceAll('-', '')}_${DateTime.now().millisecondsSinceEpoch}.png";
        final storageRef = FirebaseStorage.instance.ref().child('families/$familyId/scrapbooks/$fileName');
        
        final uploadTask = await storageRef.putData(
          resultImageBytes, 
          SettableMetadata(contentType: 'image/png')
        );
        final publicUrl = await uploadTask.ref.getDownloadURL();

        // 9. SIMPAN KE FIRESTORE
        final newPost = MemoryPost(
          id: '',
          familyId: familyId,
          authorId: 'ai_scrapbook',
          authorName: 'Buku Kenangan 📖', // Nama Bot
          content: "Halaman jurnal otomatis tanggal $dateString",
          imageUrl: publicUrl,
          date: DateTime.now(),
          reactions: {}, // Map kosong
        );
        // Note: Tambahkan field 'type': 'scrapbook_page' di model jika ingin styling khusus di UI nanti

        await ref.read(memoryRepositoryProvider).addMemory(newPost);
        
        // Refresh UI
        ref.invalidate(memoryProvider(familyId));
        
      } else {
        throw Exception("AI tidak menghasilkan gambar. Coba lagi.");
      }

    } catch (e) {
      print("Scrapbook Gen Error: $e");
      rethrow;
    }
  }



}

final memoryActionsProvider = Provider((ref) => MemoryActions(ref));
