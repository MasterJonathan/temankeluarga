import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'chat_controller.dart';
import '../domain/chat_model.dart';

// State lokal untuk menentukan apakah sedang di halaman "Pilih Topik" atau "Ruang Chat"
final isChatRoomActiveProvider = StateProvider.autoDispose<bool>((ref) => false);

class FamilyChatPage extends ConsumerWidget {
  const FamilyChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChatActive = ref.watch(isChatRoomActiveProvider);

    // Animasi transisi sederhana antara Launcher dan Room
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isChatActive ? const _ChatRoom() : const _TopicSelector(),
    );
  }
}

// === BAGIAN 1: TOPIC SELECTOR (LAUNCHER) ===
class _TopicSelector extends ConsumerWidget {
  const _TopicSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Mau bahas apa\nhari ini?",
              style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              "Pilih topik biar tidak lupa mau ngomong apa.",
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Opsi 1: Bahas Kesehatan (Context: Health)
            _TopicCard(
              icon: Icons.medication,
              color: AppColors.primary,
              title: "Lapor Minum Obat",
              subtitle: "Kabari anak kalau bapak sudah minum obat pagi.",
              onTap: () {
                _enterChat(ref, "Sudah minum obat, Pak?", ChatContextType.health, "Laporan Obat: Amlodipine (Selesai)");
              },
            ),
            
            const SizedBox(height: 16),

            // Opsi 2: Bahas Kenangan (Context: Memory)
            _TopicCard(
              icon: Icons.photo_album,
              color: AppColors.accent,
              title: "Bahas Cerita Tadi",
              subtitle: "Ngobrolin soal jurnal atau foto cucu yang baru.",
              onTap: () {
                _enterChat(ref, "Cerita di jurnal tadi seru ya?", ChatContextType.memory, "Topik: Jurnal Hari Ini");
              },
            ),

            const SizedBox(height: 16),

            // Opsi 3: Santai (General)
            _TopicCard(
              icon: Icons.coffee,
              color: AppColors.secondary,
              title: "Obrolan Santai",
              subtitle: "Sekadar menyapa atau tanya kabar.",
              onTap: () {
                _enterChat(ref, null, ChatContextType.general, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _enterChat(WidgetRef ref, String? initialMessage, ChatContextType type, String? data) {
    // Masuk ke room
    ref.read(isChatRoomActiveProvider.notifier).state = true;
    
    // Jika ada pesan otomatis (pemicu topik), kirimkan
    if (initialMessage != null) {
      ref.read(chatControllerProvider.notifier).sendMessage(initialMessage, type: type, extraData: data);
    }
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TopicCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.shadow.withOpacity(0.1)),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// === BAGIAN 2: CHAT ROOM ===
class _ChatRoom extends ConsumerStatefulWidget {
  const _ChatRoom();
  @override
  ConsumerState<_ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends ConsumerState<_ChatRoom> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(isChatRoomActiveProvider.notifier).state = false,
        ),
        title: const Row(
          children: [
            CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: Colors.white)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Grup Keluarga", style: TextStyle(fontSize: 18)),
                Text("Anak, Cucu, Eyang", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // List Pesan
          Expanded(
            child: asyncMessages.when(
              data: (messages) {
                // Auto scroll ke bawah
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _ChatBubble(message: messages[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),

          // Input Bar (Besar & Jelas)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: "Ketik pesan...",
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Kirim / Mic
                  FloatingActionButton(
                    onPressed: () {
                      if (_msgController.text.isNotEmpty) {
                        ref.read(chatControllerProvider.notifier).sendMessage(_msgController.text);
                        _msgController.clear();
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Tekan dan tahan untuk Pesan Suara (Demo)")),
                         );
                      }
                    },
                    backgroundColor: AppColors.primary,
                    elevation: 2,
                    child: const Icon(Icons.mic, color: Colors.white), // Default Mic Icon (Priority)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jika ada konteks (misal: "Laporan Obat"), tampilkan badge kecil
            if (message.contextData != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.black12 : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 12, color: isMe ? Colors.white70 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      message.contextData!,
                      style: TextStyle(fontSize: 10, color: isMe ? Colors.white : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            
            Text(
              message.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}