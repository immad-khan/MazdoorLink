import 'package:flutter/material.dart';

enum UserRole { customer, worker }

class AppController extends ChangeNotifier {
  UserRole? role;
  Locale locale = const Locale('en');

  bool get isUrdu => locale.languageCode == 'ur';

  void selectRole(UserRole value) {
    role = value;
    locale = value == UserRole.worker ? const Locale('ur') : const Locale('en');
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
    notifyListeners();
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

