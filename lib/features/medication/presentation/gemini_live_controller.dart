import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/utils/audio_utils.dart';

// State: Apakah sesi aktif?
final isLiveActiveProvider = StateProvider<bool>((ref) => false);

class GeminiLiveController {
  final Ref ref;
  
  // Hardware
  final AudioInput _audioInput = AudioInput();
  final AudioOutput _audioOutput = AudioOutput();
  
  // Firebase AI
  LiveGenerativeModel? _model;
  LiveSession? _session;
  StreamSubscription? _responseSubscription;
  
  bool _isInitialized = false;

  GeminiLiveController(this.ref);

  Future<void> _initIfNeeded() async {
    if (_isInitialized) return;
    
    // 1. Init Audio Hardware
    await _audioInput.init();
    await _audioOutput.init();
    
    // 2. Init Model
    // Pastikan FirebaseApp sudah di-init di main.dart
    _model = FirebaseAI.googleAI().liveGenerativeModel(
      model: 'gemini-2.5-flash-native-audio-preview-12-2025', // Model Terbaru
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'Puck'), // Suara
      ),
    );
    
    _isInitialized = true;
  }

  Future<void> startSession() async {
    try {
      await _initIfNeeded();
      print("Gemini Live: Connecting...");

      // 1. Connect Session
      _session = await _model!.connect();
      print("Gemini Live: Connected!");

      // 2. Start Speaker
      await _audioOutput.playStream();

      // 3. Listen to Gemini Response (Output)
      _responseSubscription = _session!.receive().listen((response) {
        final message = response.message;
        
        // Handle Content
        if (message is LiveServerContent) {
          final content = message.modelTurn;
          if (content != null) {
            for (final part in content.parts) {
              // Jika Audio
              if (part is InlineDataPart) {
                _audioOutput.addAudioChunk(part.bytes);
              }
            }
          }
          
          // Handle Interruption (Jika user bicara, stop output saat ini)
          if (message.interrupted == true) {
             print("Gemini: Interrupted");
             // Opsional: Clear buffer speaker jika didukung library
          }
        }
      });

      // 4. Start Microphone & Stream to Gemini (Input)
      final micStream = await _audioInput.startRecording();
      _session!.sendMediaStream(
        micStream.map((bytes) => InlineDataPart('audio/pcm', bytes))
      );

      // 5. Update State
      ref.read(isLiveActiveProvider.notifier).state = true;
      print("Gemini Live: Session Active. Listening...");

    } catch (e) {
      print("Gemini Live Error: $e");
      await stopSession();
    }
  }

  Future<void> stopSession() async {
    print("Gemini Live: Stopping...");
    
    // Stop Hardware
    await _audioInput.stopRecording();
    await _audioOutput.stopStream();
    
    // Close Connection
    await _responseSubscription?.cancel();
    await _session?.close();
    
    _session = null;
    ref.read(isLiveSessionActiveProvider.notifier).state = false;
  }
}

final geminiLiveControllerProvider = Provider((ref) => GeminiLiveController(ref));
// Alias agar sesuai dengan UI yang sudah ada
final isLiveSessionActiveProvider = isLiveActiveProvider;
final liveAudioControllerProvider = geminiLiveControllerProvider;