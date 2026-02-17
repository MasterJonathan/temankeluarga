import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

// === AUDIO INPUT (MIC) ===
class AudioInput {
  final _recorder = AudioRecorder();
  Stream<Uint8List>? audioStream;
  bool _isRecording = false;

  Future<void> init() async {
    // Cek Permission
    if (!await _recorder.hasPermission()) {
      throw Exception("Microphone permission not granted");
    }
  }

  Future<Stream<Uint8List>> startRecording() async {
    // Config sesuai spesifikasi Gemini Live (16kHz, 16-bit PCM)
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000, 
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
    );

    final stream = await _recorder.startStream(config);
    _isRecording = true;
    audioStream = stream;
    return stream;
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    await _recorder.stop();
  }
  
  void dispose() {
    _recorder.dispose();
  }
}

// === AUDIO OUTPUT (SPEAKER) ===
class AudioOutput {
  AudioSource? stream;
  SoundHandle? handle;

  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) {
      // Gemini biasanya mengirim output 24kHz
      await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);
    }
    
    // Reset stream jika ada
    await stopStream();
    
    // Setup Buffer Stream
    stream = SoLoud.instance.setBufferStream(
      maxBufferSizeBytes: 1024 * 1024 * 5, // 5MB Buffer
      bufferingType: BufferingType.released,
    );
  }

  Future<void> playStream() async {
    if (stream != null) {
      handle = await SoLoud.instance.play(stream!);
      // Paksa volume maksimal
      if (handle != null) {
        SoLoud.instance.setVolume(handle!, 1.0);
      }
    }
  }

  void addAudioChunk(Uint8List data) {
    if (stream != null) {
      try {
        SoLoud.instance.addAudioDataStream(stream!, data);
      } catch (e) {
        debugPrint("Audio Output Error: $e");
      }
    }
  }

  Future<void> stopStream() async {
    if (stream != null && handle != null) {
      try {
        SoLoud.instance.setDataIsEnded(stream!);
        // Tunggu sebentar atau langsung stop
        await SoLoud.instance.stop(handle!);
      } catch (_) {}
    }
    stream = null;
    handle = null;
  }
  
  void dispose() {
    stopStream();
    // SoLoud.instance.deinit(); // Jangan deinit jika ingin dipakai ulang
  }
}