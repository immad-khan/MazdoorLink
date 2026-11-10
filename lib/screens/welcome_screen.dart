import 'package:flutter/material.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart' show MzScaffold, AppRoutes;
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);

    return MzScaffold(
      showBottomNav: false,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(
                      0xFF0D9488,
                    ).withValues(alpha: 0.14),
                    child: const Icon(
                      Icons.hardware,
                      size: 34,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'MazdoorLink',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Connecting verified workers and customers',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Customer - English
                _RoleCard(
                  icon: Icons.person,
                  title: 'I need a service',
                  subtitle: 'Hire verified pros',
                  onTap: () {
                    c.selectRole(UserRole.customer);
                    c.setLocale(const Locale('en')); // English
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                ),
                const SizedBox(height: 16),
                // Worker - English
                _RoleCard(
                  icon: Icons.construction,
                  title: 'I want to work',
                  subtitle: 'Register and get jobs',
                  onTap: () {
                    c.selectRole(UserRole.worker);
                    c.setLocale(const Locale('en')); // English
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  c.selectRole(UserRole.admin);
                  c.setLocale(const Locale('en'));
                  Navigator.pushNamed(context, AppRoutes.adminLogin);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF99F6E4)),
          color: Colors.white,
        ),
        child: Row(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
              child: Icon(icon, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: isUrdu
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isUrdu ? 22 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
