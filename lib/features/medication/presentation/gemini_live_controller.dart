import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/utils/audio_utils.dart';

// --- MODEL PESAN LOKAL ---
class LiveChatMessage {
  final String text;
  final bool isUser;
  LiveChatMessage({required this.text, required this.isUser});
}

// State: Status Audio Live Aktif?
final isLiveActiveProvider = StateProvider<bool>((ref) => false);

// State: Sedang Menghubungkan? (Loading)
final isConnectingProvider = StateProvider<bool>((ref) => false);

// State: Riwayat Chat (Teks)
final liveChatMessagesProvider = StateProvider<List<LiveChatMessage>>((ref) => []);

class GeminiLiveController {
  final Ref ref;
  
  final AudioInput _audioInput = AudioInput();
  final AudioOutput _audioOutput = AudioOutput();
  
  LiveGenerativeModel? _liveModel;
  LiveSession? _liveSession;
  StreamSubscription? _liveSubscription;
  
  GenerativeModel? _chatModel;
  ChatSession? _chatSession;
  
  bool _isInitialized = false;

  GeminiLiveController(this.ref);

  Future<void> _initIfNeeded() async {
    if (_isInitialized) return;
    
    await _audioInput.init();
    await _audioOutput.init();
    
    _liveModel = FirebaseAI.googleAI().liveGenerativeModel(
      model: 'gemini-2.5-flash-native-audio-preview-12-2025',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'Puck'),
      ),
    );

    _chatModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system("Jawab dengan singkat, ramah, dan jelas. Kamu adalah teman bicara untuk lansia."),
    );
    
    _chatSession = _chatModel!.startChat();
    _isInitialized = true;
  }

  // ===========================================================================
  // BAGIAN 1: TEXT CHAT
  // ===========================================================================

  Future<void> sendTextMessage(String text) async {
    await _initIfNeeded();
    _addMessageToUI(text, true);

    try {
      final content = Content.text(text);
      final responseStream = _chatSession!.sendMessageStream(content);

      _addMessageToUI("", false); // Placeholder AI

      String fullResponse = "";
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;
          _updateLastAiMessage(fullResponse);
        }
      }
    } catch (e) {
      print("Chat Error: $e");
      _updateLastAiMessage("Maaf, koneksi terputus. Coba lagi ya.");
    }
  }

  void _addMessageToUI(String text, bool isUser) {
    final currentList = ref.read(liveChatMessagesProvider);
    ref.read(liveChatMessagesProvider.notifier).state = [
      ...currentList,
      LiveChatMessage(text: text, isUser: isUser)
    ];
  }

  void _updateLastAiMessage(String newText) {
    final currentList = ref.read(liveChatMessagesProvider);
    if (currentList.isEmpty) return;

    final updatedList = List<LiveChatMessage>.from(currentList);
    final lastIndex = updatedList.length - 1;
    
    if (!updatedList[lastIndex].isUser) {
      updatedList[lastIndex] = LiveChatMessage(text: newText, isUser: false);
      ref.read(liveChatMessagesProvider.notifier).state = updatedList;
    }
  }


  // ===========================================================================
  // BAGIAN 2: LIVE AUDIO (FIXED)
  // ===========================================================================

  Future<void> startLiveSession() async {
    // Cegah double start
    if (ref.read(isLiveActiveProvider)) return;

    try {
      ref.read(isConnectingProvider.notifier).state = true; // Set Loading
      await _initIfNeeded();
      print("Gemini Live: Connecting...");

      _liveSession = await _liveModel!.connect();
      
      await _audioOutput.playStream();

      _liveSubscription = _liveSession!.receive().listen((response) {
        final message = response.message;
        if (message is LiveServerContent) {
          final content = message.modelTurn;
          if (content != null) {
            for (final part in content.parts) {
              if (part is InlineDataPart) {
                _audioOutput.addAudioChunk(part.bytes);
              }
            }
          }
        }
      }, onError: (e) {
        print("Stream Error: $e");
        stopLiveSession();
      }, onDone: () {
        print("Stream Closed");
        stopLiveSession();
      });

      final micStream = await _audioInput.startRecording();
      _liveSession!.sendMediaStream(
        micStream.map((bytes) => InlineDataPart('audio/pcm', bytes))
      );

      // Sesi benar-benar siap
      ref.read(isLiveActiveProvider.notifier).state = true;
      print("Gemini Live: Session Active.");

    } catch (e) {
      print("Gemini Live Error: $e");
      await stopLiveSession();
    } finally {
      ref.read(isConnectingProvider.notifier).state = false; // Stop Loading
    }
  }

  Future<void> stopLiveSession() async {
    print("Gemini Live: Stopping...");
    try {
      // 1. Stop Hardware dulu
      await _audioInput.stopRecording();
      await _audioOutput.stopStream();
      
      // 2. Tutup Koneksi
      await _liveSubscription?.cancel();
      await _liveSession?.close();
    } catch (e) {
      print("Error stopping session: $e");
    } finally {
      // 3. WAJIB RESET STATE (Apapun yang terjadi)
      _liveSession = null;
      _liveSubscription = null;
      ref.read(isLiveActiveProvider.notifier).state = false;
      ref.read(isConnectingProvider.notifier).state = false;
    }
  }
}

final geminiLiveControllerProvider = Provider((ref) => GeminiLiveController(ref));
final isLiveSessionActiveProvider = isLiveActiveProvider;
final liveAudioControllerProvider = geminiLiveControllerProvider;