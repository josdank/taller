import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuración básica para español
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setSpeechRate(0.5); // Velocidad normal
      await _flutterTts.setVolume(1.0); // Volumen máximo
      await _flutterTts.setPitch(1.0); // Tono normal

      _isInitialized = true;
    } catch (e) {
      print('Error inicializando TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error al hablar: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error al detener: $e');
    }
  }

  Future<bool> isSpeaking() async {
    try {
      final result = await _flutterTts.awaitSpeakCompletion(true);
      return result;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}