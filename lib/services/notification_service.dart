import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Placeholder: request permissions and subscribe to user/worker topics.
    await _messaging.requestPermission();
  }

  Future<String?> token() async {
    return _messaging.getToken();
  }
}
