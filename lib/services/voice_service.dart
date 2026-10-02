import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (val) => print('Error initializing speech: $val'),
      onStatus: (val) => print('Speech status: $val'),
    );
    return _isAvailable;
  }

  void startListening(Function(String) onResult) {
    if (_isAvailable) {
      _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
      );
    }
  }

  void stopListening() {
    if (_isAvailable) {
      _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;
}
