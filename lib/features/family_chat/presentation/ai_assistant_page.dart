import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:teman_keluarga/features/medication/presentation/gemini_live_controller.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  // 0 = Live Audio, 1 = Chat Teks
  int _selectedTab = 0;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = ref.watch(isLiveSessionActiveProvider);
    final isConnecting = ref.watch(isConnectingProvider);
    final messages = ref.watch(liveChatMessagesProvider);

    // Auto scroll listener
    ref.listen(
      liveChatMessagesProvider,
      (_, __) =>
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom),
    );

    return PopScope(
      // Pastikan session berhenti saat back ditekan
      onPopInvoked: (didPop) {
        if (didPop) {
          ref.read(geminiLiveControllerProvider).stopLiveSession();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text("Teman AI"),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- TAB SWITCHER (Audio / Pesan) ---
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondarySurface),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabBtn("Suara", 0, _selectedTab == 0),
                    ),
                    Expanded(
                      child: _buildTabBtn("Pesan", 1, _selectedTab == 1),
                    ),
                  ],
                ),
              ),

              // --- KONTEN UTAMA ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? (isLive
                              ? AppColors.danger.withOpacity(0.05)
                              : AppColors.surface)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedTab == 0
                          ? (isLive ? AppColors.danger : Colors.transparent)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _selectedTab == 0
                      ? _buildLiveAudioView(context, ref, isLive, isConnecting)
                      : _buildChatView(messages, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        // Matikan Live Audio jika pindah ke tab Chat agar tidak tabrakan
        ref.read(geminiLiveControllerProvider).stopLiveSession();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.surface : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- TAMPILAN 1: LIVE AUDIO ---
  Widget _buildLiveAudioView(
    BuildContext context,
    WidgetRef ref,
    bool isLive,
    bool isConnecting,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isConnecting
              ? "Menghubungkan..."
              : (isLive ? "Saya Mendengarkan..." : "Ketuk untuk Bicara"),
          style: TextStyle(
            color: isLive ? AppColors.danger : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 40),

        // BIG MIC BUTTON
        GestureDetector(
          onTap: isConnecting
              ? null
              : () {
                  if (isLive) {
                    ref.read(geminiLiveControllerProvider).stopLiveSession();
                  } else {
                    ref.read(geminiLiveControllerProvider).startLiveSession();
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isLive ? AppColors.danger : AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLive
                      ? AppColors.danger.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: isLive
                    ? AppColors.surface
                    : AppColors.primary.withOpacity(0.2),
                width: isLive ? 4 : 1,
              ),
            ),
            child: isConnecting
                ? const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Icon(
                    isLive ? Icons.stop : Icons.mic,
                    size: 60,
                    color: isLive ? AppColors.surface : AppColors.primary,
                  ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          "Ceritakan harimu atau tanyakan sesuatu.\nSaya siap mendengarkan.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // --- TAMPILAN 2: CHAT TEKS ---
  Widget _buildChatView(List<LiveChatMessage> messages, WidgetRef ref) {
    return Column(
      children: [
        // List Pesan
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Mulai percakapan...",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8).copyWith(
                            bottomRight: msg.isUser ? Radius.zero : null,
                            bottomLeft: !msg.isUser ? Radius.zero : null,
                          ),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser
                                ? AppColors.surface
                                : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input Field
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: (val) => _sendMessage(ref),
                  decoration: const InputDecoration(
                    hintText: "Ketik pesan...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _sendMessage(ref),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.send, color: AppColors.surface, size: 32),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage(WidgetRef ref) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(geminiLiveControllerProvider).sendTextMessage(text);
    _textController.clear();
  }
}
