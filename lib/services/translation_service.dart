import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Detects whether [text] is primarily Urdu (contains Arabic-script characters).
String detectLanguage(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text) ? 'ur' : 'en';
}

class TranslationService {
  /// Google Cloud Translation API key.
  ///
  /// To enable real translations:
  ///  1. Enable the "Cloud Translation API" in Google Cloud Console.
  ///  2. Create an API key under "Credentials".
  ///  3. Paste it below.
  ///
  /// While empty, messages are stored untranslated (both fields fall back to
  /// the original text) so the UI stays testable without a key.
  static const String apiKey = '';

  static const String _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  /// Translates [text] from [sourceLang] to [targetLang].
  /// Falls back to the original text on any error or missing key.
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (apiKey.isEmpty || text.trim().isEmpty || sourceLang == targetLang) {
      return text;
    }
    try {
      final uri = Uri.parse(_endpoint)
          .replace(queryParameters: {'key': apiKey});
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': [text],
              'source': sourceLang,
              'target': targetLang,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return text;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final translations = (body['data']?['translations'] as List?) ?? const [];
      if (translations.isEmpty) return text;
      final first = translations.first as Map<String, dynamic>;
      return first['translatedText']?.toString() ?? text;
    } catch (_) {
      return text;
    }
  }
}
