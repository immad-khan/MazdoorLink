import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/workers_service.dart';
import 'services/notification_service.dart';

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

  /// The currently active role string ('customer' or 'worker'), persisted in
  /// SharedPreferences so the app can restore it on next launch.
  String activeRole = 'customer';

  bool get isUrdu => locale.languageCode == 'ur';

  void selectRole(UserRole value, {bool updateLocale = true}) {
    role = value;
    if (updateLocale) {
      locale = value == UserRole.worker ? const Locale('ur') : const Locale('en');
    }
    activeRole = value == UserRole.worker ? 'worker' : 'customer';
    chatUnread.start();
    NotificationService.saveCurrentToken();
    notifyListeners();
    _persistActiveRole(activeRole);
  }

  /// Switch the active role in-app (from Settings). Preserves current locale.
  void switchActiveRole(UserRole value) {
    role = value;
    activeRole = value == UserRole.worker ? 'worker' : 'customer';
    chatUnread.start();
    notifyListeners();
    _persistActiveRole(activeRole);
  }

  void setLocale(Locale value) {
    locale = value;
    notifyListeners();
  }

  void toggleLanguage() {
    locale = isUrdu ? const Locale('en') : const Locale('ur');
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await WorkerPresenceService.instance.setOnline(false);
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    role = null;
    activeRole = 'customer';
    locale = const Locale('en');
    chatUnread.reset();
    notifyListeners();
    await _persistActiveRole('customer');
  }

  Future<void> _persistActiveRole(String roleName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_role', roleName);
    } catch (_) {}
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
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
