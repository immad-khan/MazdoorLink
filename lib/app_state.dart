import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/workers_service.dart';

enum UserRole { customer, worker, admin }

/// Tracks the total unread chat messages for the signed-in user so the bottom
/// nav can show a badge. Starts/stops with the app role lifecycle.
class ChatUnreadController extends ChangeNotifier {
  int _total = 0;
  StreamSubscription<QuerySnapshot>? _sub;

  int get total => _total;

  void start() {
    _sub?.cancel();
    _sub = streamConversations().listen((snap) {
      final me = FirebaseAuth.instance.currentUser?.uid ?? '';
      var total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final counts = data['unreadCounts'] as Map<String, dynamic>?;
        total += (counts?[me] as num?)?.toInt() ?? 0;
      }
      if (total != _total) {
        _total = total;
        notifyListeners();
      }
    });
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    if (_total != 0) {
      _total = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class AppController extends ChangeNotifier {
  UserRole? role;
  Locale locale = const Locale('en');
  final ChatUnreadController chatUnread = ChatUnreadController();

  bool get isUrdu => locale.languageCode == 'ur';

  void selectRole(UserRole value) {
    role = value;
    locale = value == UserRole.worker ? const Locale('ur') : const Locale('en');
    chatUnread.start();
    notifyListeners();
  }

  void setLocale(Locale value) {
    locale = value;
    notifyListeners();
  }

  void toggleLanguage() {
    locale = isUrdu ? const Locale('en') : const Locale('ur');
    notifyListeners();
  }

  void logout() {
    role = null;
    locale = const Locale('en');
    chatUnread.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    chatUnread.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
