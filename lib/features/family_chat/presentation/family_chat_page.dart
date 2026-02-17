import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'chat_provider.dart';
import 'chat_actions.dart';
import '../domain/chat_model.dart';

// State lokal: Apakah sedang di dalam Room?
final isChatRoomActiveProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class FamilyChatPage extends ConsumerWidget {
  const FamilyChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChatActive = ref.watch(isChatRoomActiveProvider);
    final userAsync = ref.watch(profileControllerProvider);
    final user = userAsync.value;

    if (user == null) return const Center(child: CircularProgressIndicator());
    if (user.familyId == null || user.familyId!.isEmpty) {
      return const Center(child: Text("Silakan gabung keluarga di Settings."));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isChatActive
          ? _ChatRoom(
              familyId: user.familyId!,
              userId: user.id,
              userName: user.name,
            )
          : _TopicSelector(
              familyId: user.familyId!,
              userId: user.id,
              userName: user.name,
            ),
    );
  }
}

// === 1. TOPIC SELECTOR (LAUNCHER) ===
class _TopicSelector extends ConsumerWidget {
  final String familyId;
  final String userId;
  final String userName;

  const _TopicSelector({
    required this.familyId,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Mau bahas apa\nhari ini?",
              style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pilih topik biar tidak lupa.",
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _TopicCard(
              icon: Icons.medication,
              color: AppColors.primary,
              title: "Lapor Minum Obat",
              subtitle: "Kabari kalau sudah minum obat.",
              onTap: () => _enterChat(
                ref,
                "Sudah minum obat.",
                ChatContextType.health,
                "Laporan Obat",
              ),
            ),
            const SizedBox(height: 16),
            _TopicCard(
              icon: Icons.photo_album,
              color: AppColors.accent,
              title: "Bahas Cerita",
              subtitle: "Ngobrolin foto atau kenangan.",
              onTap: () => _enterChat(
                ref,
                "Ada cerita seru nih!",
                ChatContextType.memory,
                "Topik: Kenangan",
              ),
            ),
            const SizedBox(height: 16),
            _TopicCard(
              icon: Icons.coffee,
              color: AppColors.secondary,
              title: "Masuk Ruang Keluarga",
              subtitle: "Luangkan waktu bersama keluarga.",
              onTap: () => _enterChat(ref, null, ChatContextType.general, null),
            ),
          ],
        ),
      ),
    );
  }

  void _enterChat(
    WidgetRef ref,
    String? text,
    ChatContextType type,
    String? data,
  ) {
    ref.read(isChatRoomActiveProvider.notifier).state = true;
    if (text != null) {
      ref
          .read(chatActionsProvider)
          .sendTextMessage(
            familyId: familyId,
            senderId: userId,
            senderName: userName,
            text: text,
            contextType: type,
            contextData: data,
          );
    }
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TopicCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === 2. CHAT ROOM (REALTIME) ===
class _ChatRoom extends ConsumerStatefulWidget {
  final String familyId;
  final String userId;
  final String userName;
  const _ChatRoom({
    required this.familyId,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<_ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends ConsumerState<_ChatRoom> {
  final TextEditingController _msgController = TextEditingController();
  bool _isComposing = false; // State untuk tombol Mic vs Send

  void _handleSend() {
    if (_msgController.text.trim().isEmpty) return;
    ref
        .read(chatActionsProvider)
        .sendTextMessage(
          familyId: widget.familyId,
          senderId: widget.userId,
          senderName: widget.userName,
          text: _msgController.text.trim(),
        );
    _msgController.clear();
    setState(() => _isComposing = false);
  }

  void _handleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      ref
          .read(chatActionsProvider)
          .sendImageMessage(
            familyId: widget.familyId,
            senderId: widget.userId,
            senderName: widget.userName,
            imageFile: File(picked.path),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(chatProvider(widget.familyId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              ref.read(isChatRoomActiveProvider.notifier).state = false,
        ),
        title: const Text(
          "Grup Keluarga",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: asyncMessages.when(
              data: (messages) => ListView.builder(
                reverse: true, // Chat mulai dari bawah
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _ChatBubble(
                    message: msg,
                    isMe: msg.senderId == widget.userId,
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Tombol Upload Gambar
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.primary,
                    ),
                    onPressed: _handleImage,
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Ketik pesan...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Tombol Send / Mic
                  FloatingActionButton(
                    heroTag: "fab_send_chat",
                    mini: true,
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    onPressed: _isComposing
                        ? _handleSend
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Fitur Pesan Suara (Coming Soon)",
                                ),
                              ),
                            );
                          },
                    child: Icon(_isComposing ? Icons.send : Icons.mic),
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
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.textPrimary,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Pengirim (Jika bukan saya)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

            // Konteks (Badge)
            if (message.contextData != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.black12 : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 12,
                      color: isMe ? AppColors.surface : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.contextData!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? AppColors.surface : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // Isi Pesan (Text vs Image)
            if (message.type == ChatType.image)
              GestureDetector(
                onTap: () {
                  // TODO: Buka full screen image
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.content,
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, loading) => loading == null
                        ? child
                        : Container(
                            height: 150,
                            width: 200,
                            color: AppColors.textPrimary,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                  ),
                ),
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? AppColors.surface : AppColors.textPrimary,
                ),
              ),

            const SizedBox(height: 4),

            // Jam
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? AppColors.surface : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
