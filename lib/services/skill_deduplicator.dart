import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Uses the Groq LLM to semantically deduplicate worker-submitted custom skill
/// titles against the canonical (predefined) list.
///
/// If the new title is semantically the same as an existing one (even if
/// phrased differently, e.g. "pipe setup dull house" ≈ "Pipeline Leakage
/// Repair"), the method returns the matching canonical title so the worker's
/// entry can be merged.
///
/// Returns `null` when no match is found (the skill is genuinely new).
class SkillDeduplicator {
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// [newTitle]        – the custom title the worker just entered
  /// [existingTitles]  – the full list of canonical + already-accepted titles
  ///
  /// Returns the matching canonical title, or `null` if it is unique.
  static Future<String?> findDuplicate({
    required String newTitle,
    required List<String> existingTitles,
  }) async {
    if (newTitle.trim().isEmpty || existingTitles.isEmpty) return null;

    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null; // graceful fallback – no key, no dedup

    final existingList =
        existingTitles.map((t) => '- $t').join('\n');

    final systemPrompt = '''
You are a semantic similarity classifier for a home-services app (plumbing, electrical work) in Pakistan.
Your job: decide whether a new worker-submitted service title is semantically equivalent to any item in the existing canonical list.
"Semantically equivalent" means the same type of work, even if the wording, language or grammar is completely different.
Examples of MATCHES:
  "pipe setup dull house" → "Pipeline Leakage Repair"
  "bathroom complete fitting" → "Full Washroom Setup"
  "paani ki motor" → "Motor Pump Installation"
Examples of NON-MATCHES:
  "Wallpaper Removal" – does not match any plumbing/electrical item

Rules:
- Reply ONLY with a JSON object: {"match": "<exact canonical title>"} or {"match": null}
- Do NOT include any explanation or extra text.
''';

    final userMessage = '''
Existing canonical titles:
$existingList

New title submitted by worker: "$newTitle"

Does it semantically match any canonical title? Reply with the JSON.
''';

    try {
      final response = await http
          .post(
            Uri.parse(_groqEndpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama3-8b-8192',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.1,
              'max_tokens': 60,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (body['choices'] as List?)
              ?.firstOrNull?['message']?['content']
              ?.toString()
              .trim() ??
          '';

      // Extract the JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch == null) return null;

      final parsed =
          jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final match = parsed['match'];
      if (match == null || match == 'null') return null;
      final matchStr = match.toString().trim();
      // Only return if it actually matches one of the existing titles
      return existingTitles.contains(matchStr) ? matchStr : null;
    } catch (_) {
      return null; // Network error – allow the skill through
    }
  }
}
