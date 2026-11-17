import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Detects whether [text] is primarily Urdu (contains Arabic-script characters).
String detectLanguage(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text) ? 'ur' : 'en';
}

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// In-memory cache to prevent redundant HTTP requests for identical strings
  final Map<String, String> _cache = {};

  /// Optional Google Cloud Translation API key from .env
  static String get apiKey => dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';

  static const String _officialEndpoint =
      'https://translation.googleapis.com/language/translate/v2';
  static const String _gtxEndpoint =
      'https://translate.googleapis.com/translate_a/single';

  /// Translates [text] from [sourceLang] to [targetLang].
  /// Uses multi-tier fallbacks:
  /// 1. Official Google Cloud Translation v2 (if API key is present in .env)
  /// 2. Google Translate GTX Endpoint (Free, fast, no key required)
  /// 3. MyMemory Translation API (Free fallback)
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || sourceLang == targetLang) {
      return text;
    }

    final cacheKey = '$sourceLang->$targetLang:$trimmed';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. Official Google Cloud Translation API (if key is set in .env)
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(_officialEndpoint)
            .replace(queryParameters: {'key': apiKey});
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'q': [trimmed],
                'source': sourceLang,
                'target': targetLang,
                'format': 'text',
              }),
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final translations =
              (body['data']?['translations'] as List?) ?? const [];
          if (translations.isNotEmpty) {
            final first = translations.first as Map<String, dynamic>;
            final t = first['translatedText']?.toString();
            if (t != null && t.isNotEmpty) {
              _cache[cacheKey] = t;
              return t;
            }
          }
        }
      } catch (e) {
        debugPrint('Official Google Cloud translate error: $e');
      }
    }

    // 2. Google Translate GTX Free Endpoint (High accuracy, instant response)
    try {
      final uri = Uri.parse(
        '$_gtxEndpoint?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=${Uri.encodeComponent(trimmed)}',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final sentences = data[0] as List;
          final buffer = StringBuffer();
          for (final sentence in sentences) {
            if (sentence is List &&
                sentence.isNotEmpty &&
                sentence[0] != null) {
              buffer.write(sentence[0].toString());
            }
          }
          final res = buffer.toString().trim();
          if (res.isNotEmpty) {
            _cache[cacheKey] = res;
            return res;
          }
        }
      }
    } catch (e) {
      debugPrint('Google GTX translate error: $e');
    }

    // 3. Fallback: MyMemory API
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(trimmed)}&langpair=$sourceLang|$targetLang',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translatedText =
            data['responseData']?['translatedText']?.toString();
        if (translatedText != null &&
            translatedText.isNotEmpty &&
            !translatedText.toUpperCase().startsWith('MYMEMORY WARNING')) {
          _cache[cacheKey] = translatedText;
          return translatedText;
        }
      }
    } catch (e) {
      debugPrint('MyMemory translate error: $e');
    }

    return text;
  }
}
