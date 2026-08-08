import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_state.dart';
import '../screens/mazdoor_flow.dart';

// ─────────────────────────────────────────────
// Voice Assistant Service — Groq + STT + TTS
// ─────────────────────────────────────────────

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._();

  // ── Groq API ──────────────────────────────
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  // ── STT & TTS ──────────────────────────────
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInitialized = false;
  bool _isListening = false;

  // ── Conversation State Machine ────────────
  String _currentFlow = '';
  Map<String, dynamic> _flowData = {};

  bool get isListening => _isListening;

  // ── Initialize ────────────────────────────
  Future<bool> initialize() async {
    if (!_sttInitialized) {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
        },
      );
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    return _sttInitialized;
  }

  // ── Listen ─────────────────────────────────
  /// Start listening for speech. Calls [onResult] with partial/final text,
  /// and [onDone] when recognition completes.
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required VoidCallback onDone,
    String locale = 'en_US',
  }) async {
    if (!_sttInitialized) {
      final ok = await initialize();
      if (!ok) {
        onResult('Speech recognition unavailable');
        onDone();
        return;
      }
    }

    _isListening = true;
    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onDone();
        }
      },
      localeId: locale,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  // ── Speak ──────────────────────────────────
  Future<void> speak(String text, {String language = 'en-US'}) async {
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ── Parse Intent via Groq LLM ─────────────
  Future<Map<String, dynamic>> parseIntent(String userText, {UserRole? role}) async {
    final roleContext = switch (role) {
      UserRole.customer => 'The user is a CUSTOMER looking to hire workers for home services.',
      UserRole.worker => 'The user is a WORKER looking for jobs and managing their profile.',
      UserRole.admin => 'The user is an ADMIN managing the platform.',
      _ => 'The user role is unknown.',
    };

    final systemPrompt = '''You are an intent parser for MazdoorLink, a Pakistani home-services app connecting customers with workers (plumbers, electricians, carpenters, painters, cleaners, AC repair).
$roleContext

Parse the user's natural language into a JSON intent. Respond ONLY with valid JSON, no explanation.

Available intents:
- {"intent": "navigate_home"} — Go to home screen
- {"intent": "navigate_settings"} — Go to settings
- {"intent": "navigate_bookings"} — Go to booking history
- {"intent": "navigate_chat"} — Go to chat
- {"intent": "navigate_earnings"} — Go to earnings (worker only)
- {"intent": "navigate_profile"} — Go to profile management
- {"intent": "navigate_support"} — Go to customer/worker support
- {"intent": "post_job", "category": "<plumber|electrician|carpenter|painter|cleaner|ac_repair>"} — Post a new job
- {"intent": "hire_worker", "category": "<plumber|electrician|carpenter|painter|cleaner|ac_repair>"} — Hire a worker
- {"intent": "find_workers", "category": "<plumber|electrician|carpenter|painter|cleaner|ac_repair>"} — Find workers in category
- {"intent": "check_price", "category": "<category>"} — Check price estimation
- {"intent": "track_worker"} — Track current worker location
- {"intent": "view_notifications"} — View notification preferences
- {"intent": "view_privacy"} — View privacy settings
- {"intent": "change_language", "language": "urdu|english"} — Switch language
- {"intent": "logout"} — Log out
- {"intent": "show_workers"} — Admin: Show worker registrations tab
- {"intent": "show_complaints"} — Admin: Show complaints tab
- {"intent": "show_jobs"} — Admin: Show jobs tab
- {"intent": "show_stats"} — Admin: Show platform stats
- {"intent": "unknown", "message": "<helpful response>"} — If you can't parse the intent

If the user mentions a service category, map it:
- plumber/plumbing/pipe/leak/tap → plumber
- electrician/electric/wiring/switch/socket → electrician
- carpenter/wood/furniture/door → carpenter
- painter/paint/wall/color → painter
- cleaner/cleaning/sweep/mop/wash → cleaner
- ac/air conditioner/cooling/hvac → ac_repair

Examples:
User: "hire a plumber" → {"intent": "hire_worker", "category": "plumber"}
User: "show my bookings" → {"intent": "navigate_bookings"}
User: "I need someone to fix my AC" → {"intent": "hire_worker", "category": "ac_repair"}
User: "mujhe electrician chahiye" → {"intent": "hire_worker", "category": "electrician"}
User: "go to settings" → {"intent": "navigate_settings"}
User: "post a job for painting" → {"intent": "post_job", "category": "painter"}
User: "switch to urdu" → {"intent": "change_language", "language": "urdu"}''';

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userText},
          ],
          'temperature': 0.1,
          'max_tokens': 150,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'] as String;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        debugPrint('Groq API error: ${response.statusCode} — ${response.body}');
        return _fallbackIntentParse(userText);
      }
    } catch (e) {
      debugPrint('Groq API exception: $e');
      return _fallbackIntentParse(userText);
    }
  }

  // ── Fallback Rules-Based Parser ────────────
  Map<String, dynamic> _fallbackIntentParse(String text) {
    final lower = text.toLowerCase().trim();

    // Navigation intents
    if (_match(lower, ['home', 'main', 'ghar'])) {
      return {'intent': 'navigate_home'};
    }
    if (_match(lower, ['setting', 'preferences', 'ترتیبات'])) {
      return {'intent': 'navigate_settings'};
    }
    if (_match(lower, ['booking', 'history', 'orders', 'بکنگ'])) {
      return {'intent': 'navigate_bookings'};
    }
    if (_match(lower, ['chat', 'message', 'چیٹ'])) {
      return {'intent': 'navigate_chat'};
    }
    if (_match(lower, ['earning', 'income', 'آمدنی', 'kamai'])) {
      return {'intent': 'navigate_earnings'};
    }
    if (_match(lower, ['profile', 'account', 'پروفائل'])) {
      return {'intent': 'navigate_profile'};
    }
    if (_match(lower, ['support', 'help', 'مدد'])) {
      return {'intent': 'navigate_support'};
    }
    if (_match(lower, ['track', 'location', 'ٹریکنگ'])) {
      return {'intent': 'track_worker'};
    }
    if (_match(lower, ['notification', 'اطلاع'])) {
      return {'intent': 'view_notifications'};
    }
    if (_match(lower, ['privacy', 'پرائیویسی'])) {
      return {'intent': 'view_privacy'};
    }
    if (_match(lower, ['logout', 'sign out', 'لاگ آؤٹ'])) {
      return {'intent': 'logout'};
    }
    if (_match(lower, ['urdu', 'اردو'])) {
      return {'intent': 'change_language', 'language': 'urdu'};
    }
    if (_match(lower, ['english', 'انگریزی'])) {
      return {'intent': 'change_language', 'language': 'english'};
    }

    // Admin intents
    if (_match(lower, ['worker', 'registration'])) {
      return {'intent': 'show_workers'};
    }
    if (_match(lower, ['complaint', 'شکایت'])) {
      return {'intent': 'show_complaints'};
    }
    if (_match(lower, ['stat', 'analytics', 'revenue'])) {
      return {'intent': 'show_stats'};
    }

    // Category detection
    final category = _detectCategory(lower);

    if (category != null) {
      if (_match(lower, ['hire', 'need', 'want', 'find', 'get', 'chahiye', 'مطلوب'])) {
        return {'intent': 'hire_worker', 'category': category};
      }
      if (_match(lower, ['post', 'create', 'new job'])) {
        return {'intent': 'post_job', 'category': category};
      }
      if (_match(lower, ['price', 'cost', 'قیمت', 'rate'])) {
        return {'intent': 'check_price', 'category': category};
      }
      // Default: hire if category is mentioned
      return {'intent': 'hire_worker', 'category': category};
    }

    if (_match(lower, ['post', 'create', 'new job'])) {
      return {'intent': 'post_job'};
    }
    if (_match(lower, ['price', 'cost', 'estimate', 'قیمت'])) {
      return {'intent': 'check_price'};
    }

    return {
      'intent': 'unknown',
      'message': 'Sorry, I didn\'t understand. Try "hire a plumber" or "show bookings".'
    };
  }

  bool _match(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String? _detectCategory(String text) {
    if (_match(text, ['plumb', 'pipe', 'leak', 'tap', 'پلمبر'])) return 'plumber';
    if (_match(text, ['electric', 'wiring', 'switch', 'socket', 'الیکٹریشن'])) {
      return 'electrician';
    }
    if (_match(text, ['carpent', 'wood', 'furniture', 'door', 'بڑھئی'])) {
      return 'carpenter';
    }
    if (_match(text, ['paint', 'wall', 'color', 'پینٹر'])) return 'painter';
    if (_match(text, ['clean', 'sweep', 'mop', 'wash', 'صفائی'])) return 'cleaner';
    if (_match(text, ['ac', 'air condition', 'cooling', 'hvac', 'اے سی'])) {
      return 'ac_repair';
    }
    return null;
  }

  // ── Action Engine ──────────────────────────
  /// Execute the parsed intent and return a response string for TTS.
  /// Returns a map with 'response' (String for TTS) and 'navigated' (bool).
  Map<String, dynamic> executeIntent({
    required BuildContext context,
    required Map<String, dynamic> intent,
    required UserRole? role,
  }) {
    final intentType = intent['intent'] as String? ?? 'unknown';
    final category = intent['category'] as String?;

    switch (intentType) {
      // ── Navigation Intents ───────────────
      case 'navigate_home':
        final route = role == UserRole.worker
            ? AppRoutes.workerDashboard
            : AppRoutes.customerHome;
        Navigator.pushReplacementNamed(context, route);
        return {'response': 'Taking you to the home screen.', 'navigated': true};

      case 'navigate_settings':
        Navigator.pushReplacementNamed(context, AppRoutes.sharedSettings);
        return {'response': 'Opening settings.', 'navigated': true};

      case 'navigate_bookings':
        Navigator.pushReplacementNamed(context, AppRoutes.sharedHistory);
        return {'response': 'Showing your bookings.', 'navigated': true};

      case 'navigate_chat':
        Navigator.pushReplacementNamed(context, AppRoutes.sharedChat);
        return {'response': 'Opening your chats.', 'navigated': true};

      case 'navigate_earnings':
        if (role == UserRole.worker) {
          Navigator.pushReplacementNamed(context, AppRoutes.workerEarnings);
          return {'response': 'Showing your earnings dashboard.', 'navigated': true};
        }
        return {
          'response': 'Earnings is available for workers only.',
          'navigated': false
        };

      case 'navigate_profile':
        Navigator.pushNamed(context, AppRoutes.profileManagement);
        return {'response': 'Opening your profile.', 'navigated': true};

      case 'navigate_support':
        final route = role == UserRole.worker
            ? AppRoutes.workerSupport
            : AppRoutes.customerSupport;
        Navigator.pushNamed(context, route);
        return {'response': 'Opening support.', 'navigated': true};

      // ── Job & Hiring Intents ─────────────
      case 'hire_worker':
      case 'find_workers':
        if (category != null) {
          _currentFlow = 'hiring';
          _flowData = {'category': category};
          Navigator.pushNamed(context, AppRoutes.jobPosting);
          final categoryDisplay = _formatCategory(category);
          return {
            'response':
                'Let me help you find a $categoryDisplay. Taking you to job posting.',
            'navigated': true
          };
        }
        Navigator.pushNamed(context, AppRoutes.customerHome);
        return {
          'response': 'Which type of worker do you need? Plumber, electrician, carpenter, painter, cleaner, or AC repair?',
          'navigated': false
        };

      case 'post_job':
        Navigator.pushNamed(context, AppRoutes.jobPosting);
        if (category != null) {
          final categoryDisplay = _formatCategory(category);
          return {
            'response': 'Creating a new $categoryDisplay job. Fill in the details.',
            'navigated': true
          };
        }
        return {
          'response': 'Opening job posting. Select a service category.',
          'navigated': true
        };

      case 'check_price':
        Navigator.pushNamed(context, AppRoutes.priceEstimation);
        return {
          'response': 'Opening price estimation tool.',
          'navigated': true
        };

      case 'track_worker':
        Navigator.pushNamed(context, AppRoutes.tracking);
        return {
          'response': 'Opening worker tracking map.',
          'navigated': true
        };

      case 'view_notifications':
        Navigator.pushNamed(context, AppRoutes.notificationPreferences);
        return {
          'response': 'Opening notification preferences.',
          'navigated': true
        };

      case 'view_privacy':
        Navigator.pushNamed(context, AppRoutes.privacySettings);
        return {
          'response': 'Opening privacy settings.',
          'navigated': true
        };

      // ── Language ──────────────────────────
      case 'change_language':
        final lang = intent['language'] as String? ?? '';
        final controller = AppScope.of(context);
        if (lang == 'urdu') {
          controller.setLocale(const Locale('ur'));
          return {
            'response': 'Language switched to Urdu.',
            'navigated': false
          };
        } else {
          controller.setLocale(const Locale('en'));
          return {
            'response': 'Language switched to English.',
            'navigated': false
          };
        }

      // ── Logout ────────────────────────────
      case 'logout':
        return {
          'response': 'Are you sure you want to logout? Use the settings page to confirm.',
          'navigated': false
        };

      // ── Admin Intents ─────────────────────
      case 'show_workers':
        return {
          'response': 'Switching to worker registrations tab.',
          'navigated': false,
          'adminTab': 1
        };

      case 'show_complaints':
        return {
          'response': 'Switching to complaints tab.',
          'navigated': false,
          'adminTab': 3
        };

      case 'show_jobs':
        return {
          'response': 'Switching to jobs tab.',
          'navigated': false,
          'adminTab': 2
        };

      case 'show_stats':
        return {
          'response': 'Opening platform statistics.',
          'navigated': false,
          'adminTab': 0,
          'openStats': true
        };

      // ── Unknown ───────────────────────────
      case 'unknown':
      default:
        final message = intent['message'] as String? ??
            'Sorry, I didn\'t understand that. Try saying "hire a plumber" or "show bookings".';
        return {'response': message, 'navigated': false};
    }
  }

  String _formatCategory(String category) {
    return switch (category) {
      'plumber' => 'plumber',
      'electrician' => 'electrician',
      'carpenter' => 'carpenter',
      'painter' => 'painter',
      'cleaner' => 'cleaning service',
      'ac_repair' => 'AC repair technician',
      _ => category,
    };
  }

  // ── Flow State ────────────────────────────
  void resetFlow() {
    _currentFlow = '';
    _flowData = {};
  }

  String get currentFlow => _currentFlow;
  Map<String, dynamic> get flowData => _flowData;

  // ── Dispose ───────────────────────────────
  void dispose() {
    _stt.stop();
    _tts.stop();
  }
}
