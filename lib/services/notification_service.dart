import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level handler for notifications received while the app is terminated
/// or in the background. Runs in its own isolate, so Firebase is re-initialized.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Receives the notification data payload (conversationId, otherName, otherImage).
typedef MessageTapHandler = void Function(Map<String, String> data);

class NotificationService {
  /// Called when the user taps a chat notification.
  static MessageTapHandler? onOpen;

  /// Called for chat notifications received while the app is in the foreground.
  static MessageTapHandler? onForeground;

  static bool _initialized = false;

  /// Requests permission, registers background/foreground/tap handlers and
  /// stores the FCM token on the signed-in user's Firestore doc.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      onForeground?.call(Map<String, String>.from(message.data));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onOpen?.call(Map<String, String>.from(message.data));
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      Future(() => onOpen?.call(Map<String, String>.from(initial.data)));
    }

    await saveCurrentToken();

    messaging.onTokenRefresh.listen((_) => saveCurrentToken());
  }

  /// Fetches the FCM token and stores it on the current user's doc.
  /// No-op when nobody is signed in.
  static Future<void> saveCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (_) {
      // Best-effort; the token can be re-saved on next launch.
    }
  }
}
