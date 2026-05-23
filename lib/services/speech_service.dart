class SpeechService {
  bool _enabled = false;

  Future<void> enableUrduRecognition() async {
    // Placeholder for mic permission and recognizer setup.
    _enabled = true;
  }

  Future<String> captureUrduText() async {
    if (!_enabled) {
      throw StateError('Speech recognizer is not enabled.');
    }
    // Placeholder transcript.
    return 'یہ ایک نمونہ آواز ان پٹ ہے';
  }
}
