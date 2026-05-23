import 'package:flutter/material.dart';
import 'mazdoor_flow.dart';

/// Legacy entry point kept for compatibility with older navigation paths.
/// The actual login/signup flow now lives in `mazdoor_flow.dart`.
class AuthLoginScreen extends StatelessWidget {
  const AuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(isSignup: false);
  }
}
