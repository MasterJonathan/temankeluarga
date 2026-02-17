const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();


exports.sendChatNotification = onDocumentCreated("families/{familyId}/messages/{messageId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const messageData = snapshot.data();
    const familyId = event.params.familyId;
    const senderId = messageData.senderId;
    const senderName = messageData.senderName;
    const content = messageData.content;
    const type = messageData.type; // 'text', 'image', dll

    // 1. Tentukan Isi Pesan Notifikasi
    let notificationBody = content;
    if (type === 'image') notificationBody = "📷 Mengirim foto baru";
    if (content.includes("SOS")) notificationBody = "🚨 DARURAT: Menekan Tombol SOS!";
    
    // Custom Title untuk System Log
    let title = senderName;
    if (senderId === 'system_ai' || senderId === 'ai_bot') title = "Silver Guide";

    // 2. Ambil Daftar Member Keluarga
    const familyDoc = await admin.firestore().collection('families').doc(familyId).get();
    const memberIds = familyDoc.data().memberIds || [];

    // Filter: Jangan kirim notif ke pengirim pesan itu sendiri
    const recipientIds = memberIds.filter(uid => uid !== senderId);

    if (recipientIds.length === 0) {
        console.log("Tidak ada penerima notifikasi.");
        return;
    }

    // 3. Ambil Token FCM dari User Penerima
    // Firestore 'in' query max 10, jika member > 10 perlu loop/batch. (Asumsi keluarga kecil < 10)
    const usersSnapshot = await admin.firestore()
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', recipientIds)
        .get();

    let tokens = [];
    usersSnapshot.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
            tokens.push(...userData.fcmTokens);
        }
    });

    if (tokens.length === 0) {
        console.log("Tidak ada token device ditemukan.");
        return;
    }

    // 4. Kirim Notifikasi via FCM
    const payload = {
        notification: {
            title: title,
            body: notificationBody,
        },
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK", // Agar membuka app
            familyId: familyId,
            type: "chat"
        },
        tokens: tokens
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        console.log("Notifikasi dikirim:", response.successCount, "sukses,", response.failureCount, "gagal.");
        
        // (Opsional) Hapus token yang sudah invalid
        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(tokens[idx]);
                }
            });
            // Logic menghapus token invalid bisa ditambahkan di sini
        }
    } catch (error) {
        console.error("Gagal kirim notifikasi:", error);
    }
});