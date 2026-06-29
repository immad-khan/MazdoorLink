import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../main.dart';
import '../app_state.dart';
import '../app_theme.dart';
import '../data/mock_data.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'biometric_verification_screen.dart';
import 'document_upload_screen.dart';
import 'notification_preferences_screen.dart';
import 'price_estimation_screen.dart';
import 'profile_management_screen.dart';
import 'privacy_settings_screen.dart';
import 'voice_navigation_screen.dart';
import 'issue_selection_screen.dart';
import 'worker_services_setup_screen.dart';
import 'signup_data.dart';
import '../services/cloudinary_service.dart';
import '../services/workers_service.dart';
import 'recommendation_arguments.dart';
import 'cancel_job_screen.dart';
import 'customer_support_screen.dart';
import 'worker_support_screen.dart';

import 'worker_tracking_screen.dart';

void showToast(String message) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

Future<LatLng?> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;
  final pos = await Geolocator.getCurrentPosition();
  return LatLng(pos.latitude, pos.longitude);
}

class ProfileArguments {
  final WorkerModel worker;
  final JobPostingArguments job;

  ProfileArguments({required this.worker, required this.job});
}

class TrackingArguments {
  final WorkerModel? worker;
  final JobPostingArguments? job;
  final String? jobId;

  TrackingArguments({this.worker, this.job, this.jobId});
}

class LocationPickArguments {
  final double? customerLatitude;
  final double? customerLongitude;

  LocationPickArguments({this.customerLatitude, this.customerLongitude});
}

class ConversationArguments {
  final String conversationId;
  final String otherName;

  ConversationArguments({required this.conversationId, required this.otherName});
}

class AppRoutes {
  static const welcome = '/';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
  static const login = '/login';
  static const signup = '/signup';
  static const customerHome = '/customer/home';
  static const jobPosting = '/customer/job-posting';
  static const issueSelection = '/customer/issue-selection';
  static const confirmLocation = '/customer/confirm-location';
  static const recommendations = '/customer/recommendations';
  static const workerProfile = '/customer/worker-profile';
  static const tracking = '/customer/tracking';
  static const rating = '/customer/rating';
  static const workerOnboarding = '/worker/onboarding';
  static const workerCategorySelect = '/worker/category-select';
  static const workerDashboard = '/worker/dashboard';
  static const workerEarnings = '/worker/earnings';
  static const priceEstimation = '/shared/price-estimation';
  static const documentUpload = '/worker/document-upload';
  static const workerServicesSetup = '/worker/services-setup';
  static const biometricVerification = '/worker/biometric-verification';
  static const voiceNavigation = '/worker/voice-navigation';
  static const notificationPreferences = '/shared/notification-preferences';
  static const profileManagement = '/shared/profile-management';
  static const privacySettings = '/shared/privacy-settings';
  static const sharedChat = '/shared/chat';
  static const sharedConversation = '/shared/conversation';
  static const sharedHistory = '/shared/history';
  static const sharedSettings = '/shared/settings';
  static const customerSupport = '/customer/support';
  static const workerSupport = '/worker/support';
}

Route<dynamic> buildRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.welcome:
      return _page(const WelcomeScreen(), settings);
    case AppRoutes.adminLogin:
      return _page(const AdminLoginScreen(), settings);
    case AppRoutes.adminDashboard:
      return _page(const AdminDashboardScreen(), settings);
    case AppRoutes.login:
      return _page(const AuthScreen(isSignup: false), settings);
    case AppRoutes.signup:
      return _page(const AuthScreen(isSignup: true), settings);
    case AppRoutes.customerHome:
      return _page(const CustomerHomeScreen(), settings);
    case AppRoutes.issueSelection:
      return _page(const IssueSelectionScreen(), settings);
    case AppRoutes.jobPosting:
      return _page(const FlowJobPostingScreen(), settings);
    case AppRoutes.confirmLocation:
      return _page(const ConfirmLocationScreen(), settings);
    case AppRoutes.recommendations:
      return _page(const WorkerRecommendationsScreen(), settings);
    case AppRoutes.workerProfile:
      return _page(const FlowWorkerProfileScreen(), settings);
    case AppRoutes.tracking:
      return _page(const ServiceTrackingScreen(), settings);
    case AppRoutes.rating:
      return _page(const RatingReviewScreen(), settings);
    case AppRoutes.workerOnboarding:
      return _page(const WorkerOnboardingScreen(), settings);
    case AppRoutes.workerCategorySelect:
      return _page(const WorkerCategorySelectScreen(), settings);
    case AppRoutes.workerDashboard:
      return _page(const WorkerDashboardScreen(), settings);
    case AppRoutes.workerEarnings:
      return _page(const EarningsDashboardScreen(), settings);
    case AppRoutes.priceEstimation:
      return _page(PriceEstimationScreen(), settings);
    case AppRoutes.documentUpload:
      return _page(DocumentUploadScreen(), settings);
    case AppRoutes.workerServicesSetup:
      return _page(const WorkerServicesSetupScreen(), settings);
    case AppRoutes.biometricVerification:
      return _page(BiometricVerificationScreen(), settings);
    case AppRoutes.voiceNavigation:
      return _page(VoiceNavigationScreen(), settings);
    case AppRoutes.notificationPreferences:
      return _page(NotificationPreferencesScreen(), settings);
    case AppRoutes.profileManagement:
      return _page(ProfileManagementScreen(), settings);
    case AppRoutes.privacySettings:
      return _page(const PrivacySettingsScreen(), settings);
    case AppRoutes.sharedChat:
      return _page(const ChatHistoryScreen(), settings);
    case AppRoutes.sharedConversation:
      final args = settings.arguments;
      if (args is ConversationArguments) {
        return _page(ConversationScreen(conversationId: args.conversationId, otherName: args.otherName), settings);
      }
      return _page(const ChatHistoryScreen(), settings);
    case AppRoutes.sharedHistory:
      return _page(const BookingHistoryScreen(), settings);
    case AppRoutes.sharedSettings:
      return _page(const SettingsScreen(), settings);
    case AppRoutes.customerSupport:
      return _page(const CustomerSupportScreen(), settings);
    case AppRoutes.workerSupport:
      return _page(const WorkerSupportScreen(), settings);
    default:
      return _page(const WelcomeScreen(), settings);
  }
}

PageRoute<dynamic> _page(Widget child, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, animation, __, c) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(curve),
          child: c,
        ),
      );
    },
  );
}

String bilingual(BuildContext context, String en, String ur) {
  return AppScope.of(context).isUrdu ? ur : en;
}

class MzScaffold extends StatelessWidget {
  const MzScaffold({
    super.key,
    required this.child,
    this.title,
    this.showBack = false,
    this.showBottomNav = true,
    this.background,
  });

  final Widget child;
  final String? title;
  final bool showBack;
  final bool showBottomNav;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Directionality(
      textDirection: controller.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background ?? const Color(0xFFF9FAFB),
        appBar: title == null
            ? null
            : AppBar(
                title: Text(title!),
                centerTitle: true,
                leading: showBack
                    ? IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Transform.rotate(
                          angle: controller.isUrdu ? math.pi : 0,
                          child: const Icon(Icons.arrow_back),
                        ),
                      )
                    : null,
              ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child,
          ),
        ),
        bottomNavigationBar: showBottomNav ? const RoleBottomNav() : null,
      ),
    );
  }
}

class RoleBottomNav extends StatelessWidget {
  const RoleBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final current = ModalRoute.of(context)?.settings.name ?? '';
    final items = role == UserRole.worker
        ? const [
            _NavItem('/worker/dashboard', Icons.work_outline, Icons.work, 'Dashboard', 'ڈیش بورڈ'),
            _NavItem('/worker/earnings', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Earnings', 'آمدنی'),
            _NavItem('/shared/chat', Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 'چیٹ'),
            _NavItem('/shared/settings', Icons.settings_outlined, Icons.settings, 'Settings', 'ترتیبات'),
          ]
        : const [
            _NavItem('/customer/home', Icons.home_outlined, Icons.home, 'Home', 'ہوم'),
            _NavItem('/shared/history', Icons.history, Icons.history_toggle_off, 'Bookings', 'بکنگز'),
            _NavItem('/shared/chat', Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 'چیٹ'),
            _NavItem('/shared/settings', Icons.settings_outlined, Icons.settings, 'Settings', 'ترتیبات'),
          ];  

    int selected = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i].route == current) {
        selected = i;
        break;
      }
    }

    Widget buildItem(int index, _NavItem item) {
      final isSelected = index == selected;
      final color = isSelected ? const Color(0xFF0D9488) : Colors.grey.shade500;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                Navigator.pushReplacementNamed(context, item.route);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.filled : item.outline,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  isUrdu ? item.ur : item.en,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            buildItem(0, items[0]),
            buildItem(1, items[1]),
            // Central Mic Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const VoiceOverlaySheet(),
                  );
                },
                child: Container(
                  transform: Matrix4.translationValues(0.0, -10.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D9488).withOpacity(0.14),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D9488),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildItem(2, items[2]),
            buildItem(3, items[3]),
          ],
        ),
      ),
    );
  }
}

class VoiceOverlaySheet extends StatefulWidget {
  const VoiceOverlaySheet({super.key});

  @override
  State<VoiceOverlaySheet> createState() => _VoiceOverlaySheetState();
}

class _VoiceOverlaySheetState extends State<VoiceOverlaySheet> with TickerProviderStateMixin {
  bool _listening = true;
  String _recognizedCommand = '';
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true),
    );

    // Simulate listening and recognizing a command after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _recognizedCommand = 'Show my bookings';
      });

      // After recognition, trigger the corresponding navigation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.pop(context); // Close bottom sheet
        
        Navigator.pushReplacementNamed(context, '/shared/history');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 12),
                Text('Navigated to Bookings via Voice Command!'),
              ],
            ),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Voice Control Active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _listening ? 'Listening for your command...' : 'Command Recognized!',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Glowing Visualizer Waves
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(4, (index) {
                final animation = Tween<double>(begin: 15, end: 55).animate(
                  CurvedAnimation(
                    parent: _controllers[index],
                    curve: Interval(0.1 * index, 1.0, curve: Curves.easeInOut),
                  ),
                );
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: _listening ? animation.value : 10.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(_listening ? (0.4 + 0.15 * index) : 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Central Microphone Action Circle
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening ? const Color(0xFF0D9488) : Colors.grey.shade300,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _listening ? Icons.mic : Icons.check,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 28),

          // Recognized Command text
          if (_recognizedCommand.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCFBF1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '“$_recognizedCommand”',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Example Voice Prompts
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try saying:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildPromptChip('“Show bookings”'),
                    _buildPromptChip('“Open settings”'),
                    _buildPromptChip('“Go home”'),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.outline, this.filled, this.en, this.ur);

  final String route;
  final IconData outline;
  final IconData filled;
  final String en;
  final String ur;
}

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
                  builder: (_, value, child) => Transform.scale(scale: value, child: child),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.14),
                    child: const Icon(Icons.hardware, size: 34, color: Color(0xFF0D9488)),
                  ),
                ),
                const SizedBox(height: 18),
                    const Text('MazdoorLink', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text('Connecting verified workers and customers', textAlign: TextAlign.center),
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
                crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: isUrdu ? 22 : 18, fontWeight: FontWeight.w600)),
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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.isSignup});

  final bool isSignup;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _emailError;
  String? _passwordError;
  String? _nameError;
  String? _phoneError;
  String? _confirmPasswordError;
  String? _idFrontError;
  String? _idBackError;
  String? _imageSizeError;
  String? _policeCertError;
  String? _cnicError;

  // Password strength tracking
  bool _pwHasMinLength = false;
  bool _pwHasUppercase = false;
  bool _pwHasDigit = false;
  bool _pwHasSpecial = false;

  void _validateEmail(String val) {
    if (val.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    setState(() {
      _emailError = emailRegex.hasMatch(val) ? null : 'Enter a valid email address';
    });
  }

  void _validatePassword(String val) {
    setState(() {
      _pwHasMinLength = val.length >= 8;
      _pwHasUppercase = val.contains(RegExp(r'[A-Z]'));
      _pwHasDigit = val.contains(RegExp(r'[0-9]'));
      _pwHasSpecial = val.contains(RegExp(r'[!@#\$%^&*(),.?":{}<>]'));
      _passwordError = null;
    });
  }

  void _validateSignupFields() {
    final role = AppScope.of(context).role;
    setState(() {
      _nameError = _fullNameController.text.trim().isEmpty ? 'Full name is required' : null;
      _emailError = _emailController.text.trim().isEmpty
          ? 'Email is required'
          : (RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())
              ? null
              : 'Enter a valid email address');
      _phoneError = _phone.text.trim().isEmpty ? 'Mobile number is required' : null;
      if (_password.text.isEmpty) {
        _passwordError = 'Password is required';
      } else if (_passwordError == null) {
        _validatePassword(_password.text);
      }
      _confirmPasswordError = _confirmPassword.text.isEmpty
          ? 'Please confirm your password'
          : (_password.text != _confirmPassword.text ? 'Passwords must match' : null);
      if (role == UserRole.worker) {
        final cnic = _cnicController.text.trim();
        _cnicError = !RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(cnic) ? 'Enter a valid CNIC (e.g. 42201-1234567-1)' : null;
        _idFrontError = _idFrontImage == null ? 'Front CNIC image is required' : null;
        _idBackError = _idBackImage == null ? 'Back CNIC image is required' : null;
        _policeCertError = null; // Optional for worker
      }
    });
  }

final _phone = TextEditingController();
  final _emailController = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpNodes = List.generate(4, (_) => FocusNode());
  int step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isForgotPassword = false;
  
  File? _idFrontImage;
  File? _idBackImage;
  File? _profilePicFile;      // Optional for worker
  File? _policeCertFile;       // Optional for worker
  File? _certificationFile;    // Optional for worker
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('remembered_email') ?? '';
      final password = prefs.getString('remembered_password') ?? '';
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _emailController.text = email;
          _password.text = password;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final sizeInKb = file.lengthSync() / 1024;
      if (sizeInKb > 100) {
        setState(() {
          _imageSizeError = 'Image size must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)';
        });
        return;
      }
      setState(() {
        _imageSizeError = null;
        if (isFront) {
          _idFrontImage = file;
          _idFrontError = null;
        } else {
          _idBackImage = file;
          _idBackError = null;
        }
      });
    }
  }

  Future<void> _pickPoliceCert() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final sizeInKb = file.lengthSync() / 1024;
      if (sizeInKb > 100) {
        setState(() => _imageSizeError = 'Police certificate must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)');
        return;
      }
      setState(() {
        _policeCertFile = file;
        _policeCertError = null;
        _imageSizeError = null;
      });
    }
  }

  Future<void> _pickProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final sizeInKb = file.lengthSync() / 1024;
      if (sizeInKb > 100) {
        setState(() => _imageSizeError = 'Profile picture must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)');
        return;
      }
      setState(() {
        _profilePicFile = file;
        _imageSizeError = null;
      });
    }
  }

  String _formatCnic(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  Future<void> _pickCertification() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final sizeInKb = file.lengthSync() / 1024;
      if (sizeInKb > 100) {
        setState(() => _imageSizeError = 'Certificate must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)');
        return;
      }
      setState(() {
        _certificationFile = file;
        _imageSizeError = null;
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    return CloudinaryService.uploadImage(imageFile);
  }

  @override
  void dispose() {
    _phone.dispose();
    _emailController.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullNameController.dispose();
    _cnicController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (_isForgotPassword) {
      if (step == 0) {
        if (_emailController.text.trim().isEmpty) return;
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
          showToast('Password reset email sent!');
          setState(() {
            _isForgotPassword = false;
            _emailController.clear();
          });
        } catch (e) {
          showToast(e.toString());
        }
        return;
      }
    }

    if (widget.isSignup) {
      if (step == 0) {
        _validateSignupFields();
        final role = AppScope.of(context).role;
        if (_nameError != null || _emailError != null || _phoneError != null || _passwordError != null || _confirmPasswordError != null) {
          showToast('Please fill all required fields correctly');
          return;
        }
        if (role == UserRole.worker && (_idFrontError != null || _idBackError != null)) {
          showToast('Please upload both front and back of your CNIC');
          return;
        }
        setState(() => _isUploading = true);

        try {
          String? frontUrl;
          String? backUrl;
          String? profilePicUrl;
          String? policeCertUrl;
          String? certificationUrl;
          if (role == UserRole.worker) {
            frontUrl = await _uploadToCloudinary(_idFrontImage!);
            backUrl = await _uploadToCloudinary(_idBackImage!);
            if (frontUrl == null || backUrl == null) {
              setState(() => _isUploading = false);
              if (mounted) showToast('Failed to upload CNIC images. Try again.');
              return;
            }
            if (_profilePicFile != null) {
              profilePicUrl = await _uploadToCloudinary(_profilePicFile!);
            }
            if (_policeCertFile != null) {
              policeCertUrl = await _uploadToCloudinary(_policeCertFile!);
              if (policeCertUrl == null) {
                setState(() => _isUploading = false);
                if (mounted) showToast('Failed to upload police certificate. Try again.');
                return;
              }
            }
            if (_certificationFile != null) {
              certificationUrl = await _uploadToCloudinary(_certificationFile!);
            }

            setState(() => _isUploading = false);

            if (mounted) {
              final signupData = WorkerSignupData(
                name: _fullNameController.text.trim(),
                email: _emailController.text.trim(),
                password: _password.text,
                phone: _phone.text.trim(),
                profilePicUrl: profilePicUrl,
                cnicNumber: _cnicController.text.trim(),
                idFrontUrl: frontUrl!,
                idBackUrl: backUrl!,
                policeCertUrl: policeCertUrl,
                certificationUrl: certificationUrl,
              );
              Navigator.pushReplacementNamed(context, AppRoutes.workerCategorySelect, arguments: signupData);
            }
            return;
          }

          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _password.text,
          );
          
          await userCredential.user?.sendEmailVerification();
          
          final userData = <String, dynamic>{
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phone.text.trim(),
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
          
          setState(() => _isUploading = false);

          await FirebaseAuth.instance.signOut();

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDCFCE7),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF059669), size: 44),
                      ),
                      const SizedBox(height: 20),
                      const Text('Registration Submitted!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      const Text(
                        'A verification email has been sent. Please verify your email before logging in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Go to Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return;
        } catch (e) {
          setState(() => _isUploading = false);
          if (mounted) {
            showToast(e.toString());
          }
          return;
        }
      } 
    } else {
      // Login flow
      setState(() {
        _emailError = _emailController.text.trim().isEmpty
            ? 'Email is required'
            : (RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())
                ? null
                : 'Enter a valid email address');
        _passwordError = _password.text.isEmpty ? 'Password is required' : null;
      });
      if (_emailError != null || _passwordError != null) {
        showToast('Please enter your email and password');
        return;
      }
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _password.text,
        );
        
        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            showToast('Please verify your email first! Check your inbox.');
          }
          return;
        }
        
        // Fetch user data from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists && mounted) {
          if (_rememberMe) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('remembered_email', _emailController.text.trim());
            await prefs.setString('remembered_password', _password.text);
          }
          final data = doc.data()!;
          if (data['role'] == 'worker') {
            final status = data['status'] ?? 'pending';
            if (status == 'pending') {
              await FirebaseAuth.instance.signOut();
              if (mounted) showToast('Your account is pending admin approval.');
              return;
            } else if (status == 'rejected') {
              await FirebaseAuth.instance.signOut();
              final reason = data['rejectReason'] ?? 'Not specified';
              if (mounted) showToast('Account rejected by admin. Reason: $reason');
              return;
            }
            AppScope.of(context).selectRole(UserRole.worker);
            // Check if worker has selected a category yet
            final category = data['category'];
            if (category == null || category.toString().isEmpty) {
              Navigator.pushReplacementNamed(context, AppRoutes.workerCategorySelect);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.workerDashboard);
            }
          } else {
            AppScope.of(context).selectRole(UserRole.customer);
            Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
          }
        } else if (mounted) {
          // Default fallback
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
        return;
      } catch (e) {
        if (mounted) {
          final msg = e.toString();
          if (msg.contains('user-not-found') || msg.contains('no user record')) {
            showToast('No account found with this email. Please sign up first.');
          } else if (msg.contains('wrong-password') || msg.contains('password is invalid')) {
            showToast('Wrong password. Try again or tap "Forgot password?" to reset it.');
          } else if (msg.contains('too-many-requests')) {
            showToast('Too many failed attempts. Please wait a few minutes and try again.');
          } else {
            showToast(msg);
          }
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: (_isForgotPassword)
          ? 'Reset Password'
          : (widget.isSignup ? 'Sign up' : 'Login'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: (_isForgotPassword)
                ? _forgotPasswordFlow()
                : (widget.isSignup ? _signupFlow() : _loginScreen()),
          ),
        ),
      ),
    );
  }

  Widget _forgotPasswordFlow() {
    return Column(
      key: const ValueKey('forgotPasswordStep0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset password',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address to reset your password',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              hintText: 'john@example.com',
              errorText: _emailError,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _next,
            child: const Text('Send Reset Link'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isForgotPassword = false;
                  step = 0;
                  _emailController.clear();
                  _emailError = null;
                });
              },
              child: const Text('Back to Login', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loginScreen() {
    return Column(
      key: const ValueKey('loginScreen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login to your MazdoorLink account',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              hintText: 'john@example.com',
              errorText: _emailError,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Password',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: _obscurePassword,
          onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
          decoration: InputDecoration(
            hintText: 'Enter your password',
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon((_obscurePassword) ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscurePassword = !(_obscurePassword)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                _isForgotPassword = true;
                step = 0;
                _phone.clear();
                _password.clear();
                _confirmPassword.clear();
              });
            },
            child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF0D9488))),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _next,
            child: const Text('Continue'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No account? '),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.signup);
              },
              child: const Text('Sign up', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pwRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? const Color(0xFF059669) : Colors.grey.shade300,
            ),
            child: met
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF059669) : Colors.grey.shade500,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              decoration: met ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupFlow() {
    final role = AppScope.of(context).role;
    
    if (step == 0) {
      return Column(
        key: const ValueKey('signupStep0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fill in your details to get started',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text('Full name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _fullNameController,
            onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Enter your full name',
              errorText: _nameError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mail_outline),
              hintText: 'Enter your email address',
              errorText: _emailError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Mobile number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) { if (_phoneError != null) setState(() => _phoneError = null); },
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text('+92', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '3038064241',
                errorText: _phoneError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            onChanged: _validatePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Enter your password',
              errorText: _passwordError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Confirm password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) {
              if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirm your password',
              errorText: _confirmPasswordError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Dynamic password strength indicator
          if (_password.text.isNotEmpty || _confirmPassword.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Password requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),
                  _pwRequirementRow('At least 1 uppercase letter', _pwHasUppercase),
                  _pwRequirementRow('At least 1 number', _pwHasDigit),
                  _pwRequirementRow('At least 1 special character (!@#\$...)', _pwHasSpecial),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          if (role == UserRole.worker) ...[
            // Profile Picture (Optional)
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('Profile Picture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Upload your profile picture (max 100KB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickProfilePic,
              child: Container(
                width: double.infinity,
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _profilePicFile != null ? const Color(0xFFF0FDFA) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _profilePicFile != null ? const Color(0xFF0D9488) : Colors.grey.shade300,
                    width: _profilePicFile != null ? 1.5 : 1,
                  ),
                ),
                child: _profilePicFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_profilePicFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                          const SizedBox(height: 6),
                          Text('Tap to upload', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // CNIC Number
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('CNIC Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Required', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Enter your CNIC number with dashes (e.g. 42201-1234567-1)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextField(
              controller: _cnicController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final formatted = _formatCnic(val);
                if (formatted != val) {
                  _cnicController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
                if (_cnicError != null) setState(() => _cnicError = null);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.credit_card_outlined),
                hintText: '42201-1234567-1',
                errorText: _cnicError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const Text('CNIC Images (Front & Back)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 2),
            Text('Max 5MB per image', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _pickImage(true),
                        child: Container(
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _idFrontError != null ? Colors.red : Colors.grey.shade300)
                          ),
                          child: _idFrontImage != null 
                              ? Image.file(_idFrontImage!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                        ),
                      ),
                      if (_idFrontError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_idFrontError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _idBackError != null ? Colors.red : Colors.grey.shade300)
                          ),
                          child: _idBackImage != null
                              ? Image.file(_idBackImage!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                        ),
                      ),
                      if (_idBackError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_idBackError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_imageSizeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(_imageSizeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Police Certificate (Optional)
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.policy_outlined, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('Police Character Certificate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Upload image of your police certificate (max 100KB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickPoliceCert,
              child: Container(
                width: double.infinity,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _policeCertFile != null ? const Color(0xFFF0FDFA) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _policeCertError != null ? Colors.red : (_policeCertFile != null ? const Color(0xFF0D9488) : Colors.grey.shade300),
                    width: _policeCertFile != null ? 1.5 : 1,
                  ),
                ),
                child: _policeCertFile != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 22),
                          const SizedBox(width: 10),
                          Text('Certificate uploaded', style: TextStyle(color: const Color(0xFF0D9488), fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_file_outlined, color: Colors.grey, size: 26),
                          const SizedBox(width: 10),
                          Text('Tap to upload certificate', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            if (_policeCertError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_policeCertError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
              ),
            const SizedBox(height: 20),
            // Certification / Specialization (Optional)
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('Certification / Specialization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Upload any trade certificate, specialization diploma, etc. (max 100KB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickCertification,
              child: Container(
                width: double.infinity,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _certificationFile != null ? const Color(0xFFF0FDFA) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _certificationFile != null ? const Color(0xFF0D9488) : Colors.grey.shade300,
                    width: _certificationFile != null ? 1.5 : 1,
                  ),
                ),
                child: _certificationFile != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 22),
                          const SizedBox(width: 10),
                          Text('Certificate uploaded', style: TextStyle(color: const Color(0xFF0D9488), fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _certificationFile = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_file_outlined, color: Colors.grey, size: 26),
                          const SizedBox(width: 10),
                          Text('Tap to upload (optional)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isUploading ? null : _next,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: _isUploading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? '),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('Login', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('signupStep1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter verification code',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 4-digit code to +92 ${_phone.text}',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _otpNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification code resent successfully')),
                );
              },
              child: const Text('Resend code', style: TextStyle(color: Color(0xFF0D9488))),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: const Text('Complete Sign up'),
            ),
          ),
        ],
      );
    }
  }
}

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    return MzScaffold(
      showBottomNav: true,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (scope.role != UserRole.worker)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                color: const Color(0xFFF0FDFA),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0D9488),
                    child: Icon(Icons.work_outline, color: Colors.white),
                  ),
                  title: Text(bilingual(context, 'Want to work instead?', 'کیا آپ کام کرنا چاہتے ہیں؟')),
                  subtitle: Text(bilingual(context, 'Switch to worker mode to receive jobs', 'ورکر موڈ میں جائیں اور کام وصول کریں')),
                  trailing: FilledButton(
                    onPressed: () {
                      scope.selectRole(UserRole.worker);
                      Navigator.pushNamed(context, AppRoutes.workerOnboarding);
                    },
                    child: Text(bilingual(context, 'Switch', 'تبدیل کریں')),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      bilingual(context, 'Gulberg III, Lahore', 'گلبرگ 3، لاہور'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Text(isUrdu ? 'AR' : 'EN', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    hintText: bilingual(context, 'What service do you need?', 'آپ کو کون سی سروس چاہیے؟'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteWorkersScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFF0D9488)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bilingual(context, 'Favorite Workers', 'پسندیدہ ورکرز'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(bilingual(context, 'Hire your preferred providers directly.', 'اپنے پسندیدہ کاریگروں کو تیزی سے ہائر کریں۔'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0D9488)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(bilingual(context, 'Categories', 'زمرہ جات'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              itemCount: categories.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1),
              itemBuilder: (context, i) {
                final item = categories[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 240 + i * 60),
                  builder: (_, value, child) => Opacity(opacity: value, child: Transform.scale(scale: 0.92 + value * 0.08, child: child)),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.issueSelection, arguments: item.key),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(backgroundColor: const Color(0xFFE6FFFA), child: Icon(item.icon, color: const Color(0xFF0D9488))),
                          const SizedBox(height: 6),
                          Text(isUrdu ? item.ur : item.en, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Text(bilingual(context, 'Top Rated Workers', 'بہترین ورکرز'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(bilingual(context, 'See all', 'سب دیکھیں'), style: const TextStyle(color: Color(0xFF0D9488))),
              ],
            ),
          ),
          StreamBuilder<List<WorkerModel>>(
            stream: streamApprovedWorkers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(bilingual(context, 'Failed to load workers', 'ورکرز لوڈ کرنے میں ناکامی')),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final realWorkers = snapshot.data!;
              if (realWorkers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(bilingual(context, 'No workers available yet', 'ابھی کوئی ورکر دستیاب نہیں')),
                );
              }
              return Column(
                children: [
                  for (final w in realWorkers)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: w.image.isNotEmpty ? NetworkImage(w.image) : null,
                        child: w.image.isEmpty ? Text(w.name.isNotEmpty ? w.name[0].toUpperCase() : '?') : null,
                      ),
                      title: Text(w.name),
                      subtitle: Text('${w.category}${w.price.isNotEmpty ? '  •  ${w.price}' : ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.workerProfile,
                        arguments: ProfileArguments(
                          worker: w,
                          job: JobPostingArguments(descriptionEn: '', descriptionUr: '', price: 0, categoryKey: ''),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class FlowJobPostingScreen extends StatefulWidget {
  const FlowJobPostingScreen({super.key});

  @override
  State<FlowJobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<FlowJobPostingScreen> {
  int step = 0;
  bool asap = true;
  final desc = TextEditingController();
  final List<_JobPhotoAsset> _selectedPhotos = [];
  double _selectedPrice = 0.0;
  String _categoryKey = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is JobPostingArguments) {
        final isUrdu = AppScope.of(context).isUrdu;
        desc.text = isUrdu ? args.descriptionUr : args.descriptionEn;
        _selectedPrice = args.price;
        _categoryKey = args.categoryKey;
      }
      _initialized = true;
    }
  }
  static const List<_JobPhotoAsset> _photoOptions = [
    _JobPhotoAsset('Tap to capture', 'assets/images/userImage.png', Icons.camera_alt_outlined),
    _JobPhotoAsset('Gallery pick', 'assets/images/helpImage.png', Icons.photo_library_outlined),
    _JobPhotoAsset('Recent upload', 'assets/images/inviteImage.png', Icons.image_outlined),
    _JobPhotoAsset('Service issue', 'assets/images/feedbackImage.png', Icons.broken_image_outlined),
    _JobPhotoAsset('Workspace', 'assets/images/supportIcon.png', Icons.work_outline),
  ];

  @override
  void dispose() {
    desc.dispose();
    super.dispose();
  }
  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<_JobPhotoAsset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    bilingual(context, 'Add job photos', 'کام کی تصاویر شامل کریں'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bilingual(context, 'Pick a recent photo or capture one for this request', 'حالیہ تصویر منتخب کریں یا نیا فوٹو شامل کریں'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoActionCard(
                          icon: Icons.photo_camera_outlined,
                          title: bilingual(context, 'Open camera', 'کیمرہ کھولیں'),
                          subtitle: bilingual(context, 'Capture a new photo', 'نئی تصویر لیں'),
                          onTap: () => Navigator.pop(context, _photoOptions.first),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PhotoActionCard(
                          icon: Icons.photo_library_outlined,
                          title: bilingual(context, 'Choose from gallery', 'گیلری سے منتخب کریں'),
                          subtitle: bilingual(context, 'Pick from saved images', 'محفوظ تصاویر میں سے'),
                          onTap: () => Navigator.pop(context, _photoOptions[1]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    bilingual(context, 'Recent options', 'حالیہ تصاویر'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _photoOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (_, index) {
                      final item = _photoOptions[index];
                      return InkWell(
                        onTap: () => Navigator.pop(context, item),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(item.asset, fit: BoxFit.cover),
                                Container(color: Colors.black26),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(item.icon, color: const Color(0xFF0D9488)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (choice == null) return;
    setState(() => _selectedPhotos.add(choice));
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Post a Job', 'کام پوسٹ کریں'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bilingual(context, 'Step ${step + 1} of 2', '${step + 1} از 2')),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: step == 0 ? _stepOne(context) : _stepTwo(context),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (step == 0) {
                    setState(() => step = 1);
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.confirmLocation,
                      arguments: JobPostingArguments(
                        descriptionEn: desc.text,
                        descriptionUr: desc.text,
                        price: _selectedPrice > 0 ? _selectedPrice : 1000.0,
                        categoryKey: _categoryKey.isNotEmpty ? _categoryKey : 'electrician',
                      ),
                    );
                  }
                },
                child: Text(step == 0 ? bilingual(context, 'Continue', 'جاری رکھیں') : bilingual(context, 'Find Workers', 'ورکر تلاش کریں')),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _stepOne(BuildContext context) {
    return ListView(
      key: const ValueKey('step1'),
      children: [
        Text(bilingual(context, 'What needs to be done?', 'کیا کام کرنا ہے؟'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: desc,
          minLines: 4,
          maxLines: 4,
          decoration: InputDecoration(hintText: bilingual(context, 'E.g., My kitchen sink is leaking', 'مثلاً کچن سنک لیک ہو رہا ہے')),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(bilingual(context, 'Add Photos (Optional)', 'تصاویر شامل کریں')),
        ),
        if (_selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            bilingual(context, 'Selected photos', 'منتخب تصاویر'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _selectedPhotos[index];
                return Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(item.asset, fit: BoxFit.cover),
                        Container(color: Colors.black26),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            item.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _stepTwo(BuildContext context) {
    return ListView(
      key: const ValueKey('step2'),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on),
          title: Text(bilingual(context, 'Service Location', 'سروس لوکیشن')),
          subtitle: Text(bilingual(context, 'House 42, Street 7, Sector F-8/4', 'گھر 42، سٹریٹ 7، سیکٹر ایف-8/4')),
          trailing: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location picker opened')),
              );
            }, 
            child: Text(bilingual(context, 'Change', 'تبدیل'))
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFECFEFF), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bilingual(context, 'Location', 'مقام'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(bilingual(context, 'Workers will be matched to your location.', 'ورکرز آپ کے مقام کے مطابق تلاش کیے جائیں گے۔')),
            ],
          ),
        )
      ],
    );
  }
}


class ConfirmLocationScreen extends StatefulWidget {
  const ConfirmLocationScreen({super.key});

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  static const LatLng _fallbackLocation = LatLng(31.5204, 74.3587);
  GoogleMapController? _mapController;
  LatLng _selectedLocation = _fallbackLocation;
  bool _loadingLocation = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final lat = args is JobPostingArguments
        ? args.customerLatitude
        : args is RecommendationArguments
            ? args.customerLatitude
            : null;
    final lng = args is JobPostingArguments
        ? args.customerLongitude
        : args is RecommendationArguments
            ? args.customerLongitude
            : null;

    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
      _loadingLocation = false;
    } else {
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    final location = await getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _selectedLocation = location ?? _fallbackLocation;
      _loadingLocation = false;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation, 16));
    }

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bilingual(context, 'Location permission unavailable. Move the pin manually.', 'لوکیشن دستیاب نہیں۔ پن کو خود منتقل کریں۔'))),
      );
    }
  }

  void _confirmLocation() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LocationPickArguments) {
      Navigator.pop(context, {
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      });
      return;
    }
    if (args is JobPostingArguments) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recommendations,
        arguments: JobPostingArguments(
          descriptionEn: args.descriptionEn,
          descriptionUr: args.descriptionUr,
          price: args.price,
          categoryKey: args.categoryKey,
          paymentMethod: args.paymentMethod,
          customerLatitude: _selectedLocation.latitude,
          customerLongitude: _selectedLocation.longitude,
        ),
      );
      return;
    }

    if (args is RecommendationArguments) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recommendations,
        arguments: RecommendationArguments(
          selectedIssues: args.selectedIssues,
          categoryKey: args.categoryKey,
          paymentMethod: args.paymentMethod,
          customerLatitude: _selectedLocation.latitude,
          customerLongitude: _selectedLocation.longitude,
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.recommendations);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Confirm Location', 'لوکیشن کی تصدیق کریں'),
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 16),
            markers: {
              Marker(
                markerId: const MarkerId('customer_location'),
                position: _selectedLocation,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: InfoWindow(title: bilingual(context, 'Service location', 'سروس لوکیشن')),
                onDragEnd: (position) => setState(() => _selectedLocation = position),
              ),
            },
            onTap: (position) => setState(() => _selectedLocation = position),
            onMapCreated: (controller) {
              _mapController = controller;
              controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation, 16));
            },
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_loadingLocation)
            Container(
              color: Colors.white.withOpacity(0.65),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bilingual(context, 'Set exact service point', 'درست سروس پوائنٹ منتخب کریں'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bilingual(context, 'Drag the pin or tap the map. The worker will navigate to this exact point.', 'پن کو منتقل کریں یا نقشے پر ٹیپ کریں۔ ورکر اسی مقام پر آئے گا۔'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF0D9488), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadingLocation ? null : () => _useCurrentLocation(),
                          icon: const Icon(Icons.my_location),
                          label: Text(isUrdu ? 'موجودہ لوکیشن' : 'Use current'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loadingLocation ? null : _confirmLocation,
                          icon: const Icon(Icons.check),
                          label: Text(isUrdu ? 'تصدیق' : 'Confirm'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class WorkerRecommendationsScreen extends StatefulWidget {
  const WorkerRecommendationsScreen({super.key});

  @override
  State<WorkerRecommendationsScreen> createState() => _WorkerRecommendationsScreenState();
}

class _WorkerRecommendationsScreenState extends State<WorkerRecommendationsScreen> {
  List<IssueItem> selectedIssues = [];
  String categoryKey = 'electrician';
  String paymentMethod = 'Cash';
  double? customerLatitude;
  double? customerLongitude;
  late Future<List<WorkerModel>> _workersFuture;
  List<String> _favouriteIds = [];
  StreamSubscription? _favSub;

  @override
  void initState() {
    super.initState();
    _favSub = streamFavouriteWorkerIds().listen((ids) {
      if (mounted) setState(() => _favouriteIds = ids);
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is RecommendationArguments) {
      selectedIssues = rawArgs.selectedIssues;
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
      customerLatitude = rawArgs.customerLatitude;
      customerLongitude = rawArgs.customerLongitude;
    } else if (rawArgs is JobPostingArguments) {
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
      customerLatitude = rawArgs.customerLatitude;
      customerLongitude = rawArgs.customerLongitude;
      selectedIssues = [
        IssueItem(
          titleEn: rawArgs.descriptionEn,
          titleUr: rawArgs.descriptionUr,
          price: rawArgs.price,
          icon: Icons.build,
        ),
      ];
    }

    _workersFuture = getWorkersByCategory(categoryKey);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Available Workers', 'دستیاب ورکرز'),
      child: FutureBuilder<List<WorkerModel>>(
        future: _workersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(bilingual(context, 'Failed to load workers', 'ورکرز لوڈ کرنے میں ناکامی')),
            );
          }
          final matchedWorkers = snapshot.data ?? [];
          if (matchedWorkers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  bilingual(context, 'No workers found for this category. Check back later.', 'اس زمرے میں کوئی ورکر نہیں ملا۔ بعد میں دوبارہ چیک کریں۔'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu
                                ? '${matchedWorkers.length} ورکرز دستیاب ہیں'
                                : '${matchedWorkers.length} workers available',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUrdu ? 'قیمت دیکھنے کے لیے پیشکش کریں' : 'Make an offer to negotiate price',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < matchedWorkers.length; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 320 + i * 100),
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedIssues.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF99F6E4)),
                              ),
                              child: Text(
                                isUrdu
                                    ? '📌 ${selectedIssues[i % selectedIssues.length].titleUr}'
                                    : '📌 ${selectedIssues[i % selectedIssues.length].titleEn}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                              ),
                            ),
                          if (selectedIssues.isNotEmpty) const SizedBox(height: 12),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: matchedWorkers[i].image.isNotEmpty
                                    ? Image.network(
                                        matchedWorkers[i].image,
                                        width: 62,
                                        height: 62,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => CircleAvatar(
                                          radius: 31,
                                          child: Text(matchedWorkers[i].name.isNotEmpty ? matchedWorkers[i].name[0].toUpperCase() : '?'),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 31,
                                        child: Text(matchedWorkers[i].name.isNotEmpty ? matchedWorkers[i].name[0].toUpperCase() : '?'),
                                      ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  matchedWorkers[i].name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkerText),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  matchedWorkers[i].category,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                if (matchedWorkers[i].price.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    matchedWorkers[i].price,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _favouriteIds.contains(matchedWorkers[i].id) ? Icons.favorite : Icons.favorite_border,
                              color: _favouriteIds.contains(matchedWorkers[i].id) ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            onPressed: () async {
                              final wid = matchedWorkers[i].id;
                              if (wid == null) return;
                              if (_favouriteIds.contains(wid)) {
                                removeFavouriteWorker(wid);
                              } else {
                                addFavouriteWorker(wid);
                              }
                            },
                          ),
                            ],
                          ),
                          if (matchedWorkers[i].skillsEn.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: (isUrdu ? matchedWorkers[i].skillsUr : matchedWorkers[i].skillsEn).map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(s, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                final issueIndex = i % (selectedIssues.isNotEmpty ? selectedIssues.length : 1);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.workerProfile,
                                  arguments: ProfileArguments(
                                    worker: matchedWorkers[i],
                                    job: JobPostingArguments(
                                      descriptionEn: selectedIssues.isNotEmpty ? selectedIssues[issueIndex].titleEn : '',
                                      descriptionUr: selectedIssues.isNotEmpty ? selectedIssues[issueIndex].titleUr : '',
                                      price: 0,
                                      categoryKey: categoryKey,
                                      paymentMethod: paymentMethod,
                                      customerLatitude: customerLatitude,
                                      customerLongitude: customerLongitude,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_outline, size: 16),
                              label: Text(bilingual(context, 'View Profile', 'پروفائل دیکھیں'), style: const TextStyle(fontSize: 14)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class FlowWorkerProfileScreen extends StatefulWidget {
  const FlowWorkerProfileScreen({super.key});

  @override
  State<FlowWorkerProfileScreen> createState() => _FlowWorkerProfileScreenState();
}

class _FlowWorkerProfileScreenState extends State<FlowWorkerProfileScreen> {
  final TextEditingController _offerController = TextEditingController();
  List<String> _favouriteIds = [];
  StreamSubscription? _favSub;
  int _visibilityMinutes = 10;

  @override
  void initState() {
    super.initState();
    _favSub = streamFavouriteWorkerIds().listen((ids) {
      if (mounted) setState(() => _favouriteIds = ids);
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ProfileArguments?;
    final worker = args?.worker;
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    if (worker == null) {
      return Scaffold(
        appBar: AppBar(title: Text(bilingual(context, 'Worker not found', 'ورکر نہیں ملا'))),
      );
    }

    return MzScaffold(
      showBottomNav: false,
      background: Colors.white,
      child: Stack(
        children: [
          ListView(
            children: [
              Stack(
                children: [
                  worker.image.isNotEmpty
                      ? Image.network(worker.image, height: 260, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                          height: 260,
                          width: double.infinity,
                          color: const Color(0xFF0D9488),
                          child: Center(
                            child: Text(
                              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent]),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 14,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 14,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: Icon(
                          _favouriteIds.contains(worker.id) ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final wid = worker.id;
                          if (wid == null) return;
                          if (_favouriteIds.contains(wid)) {
                            removeFavouriteWorker(wid);
                          } else {
                            addFavouriteWorker(wid);
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        Expanded(child: Text(worker.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))),
                        const Text('⭐ 4.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${worker.category} • ${worker.distanceKm} km ${bilingual(context, 'away', 'دور')}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: const [
                      _Tag('CNIC Verified', Colors.green),
                      _Tag('Police Cleared', Colors.blue),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: bilingual(context, 'Jobs', 'مکمل کام'), value: '124+')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: bilingual(context, 'Response', 'جواب'), value: '<10 min')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bilingual(context, 'Worker\'s Preset Price:', 'ورکر کی مقرر کردہ قیمت:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(worker.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _offerController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: const Text('PKR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                        ),
                        hintText: isUrdu ? 'مثلاً 500' : 'E.g., 500',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                        ),
                        labelText: isUrdu ? 'اپنی پیشکش درج کریں (Rs)' : 'Enter Your Offer (Rs)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bilingual(context, 'Offer visible to worker for:', 'ورکر کو پیشکش نظر آئے گی:'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _DurationChip(label: '10 min', minutes: 10, selected: _visibilityMinutes == 10, onTap: () => setState(() => _visibilityMinutes = 10)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '30 min', minutes: 30, selected: _visibilityMinutes == 30, onTap: () => setState(() => _visibilityMinutes = 30)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '1 ${bilingual(context, 'hr', 'گھنٹہ')}', minutes: 60, selected: _visibilityMinutes == 60, onTap: () => setState(() => _visibilityMinutes = 60)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '6 ${bilingual(context, 'hr', 'گھنٹے')}', minutes: 360, selected: _visibilityMinutes == 360, onTap: () => setState(() => _visibilityMinutes = 360)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '1 ${bilingual(context, 'day', 'دن')}', minutes: 1440, selected: _visibilityMinutes == 1440, onTap: () => setState(() => _visibilityMinutes = 1440)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '3 ${bilingual(context, 'days', 'دن')}', minutes: 4320, selected: _visibilityMinutes == 4320, onTap: () => setState(() => _visibilityMinutes = 4320)),
                                const SizedBox(width: 6),
                                _DurationChip(label: '1 ${bilingual(context, 'week', 'ہفتہ')}', minutes: 10080, selected: _visibilityMinutes == 10080, onTap: () => setState(() => _visibilityMinutes = 10080)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(bilingual(context, 'Skills', 'مہارتیں'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...((isUrdu ? worker.skillsUr : worker.skillsEn).map((e) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(e)))),
                    const SizedBox(height: 10),
                    Text(bilingual(context, 'Recent Reviews', 'حالیہ جائزے'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Card(child: ListTile(title: Text('Ahmad R. ⭐⭐⭐⭐⭐'), subtitle: Text('Very professional and on-time service.'))),
                    const Card(child: ListTile(title: Text('Sana K. ⭐⭐⭐⭐⭐'), subtitle: Text('Handled the issue quickly.'))),
                    const SizedBox(height: 90),
                  ],
                ),
              )
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: () async {
                    final wid = worker.id;
                    if (wid == null) return;
                    final existingId = await findExistingConversation(wid);
                    if (!context.mounted) return;
                    if (existingId != null) {
                      Navigator.pushNamed(context, AppRoutes.sharedConversation, arguments: ConversationArguments(conversationId: existingId, otherName: worker.name));
                    } else {
                      final newId = await createConversation(otherUserId: wid, otherUserName: worker.name);
                      if (context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.sharedConversation, arguments: ConversationArguments(conversationId: newId, otherName: worker.name));
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context, 
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && context.mounted) {
                           final priceText = _offerController.text.trim();
                           final offerPrice = double.tryParse(priceText);
                           if (offerPrice == null || offerPrice <= 0) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(bilingual(context, 'Please enter a valid amount to make an offer.', 'براہ کرم پیشکش کرنے کے لئے ایک درست رقم درج کریں۔')),
                                 backgroundColor: Colors.redAccent,
                               ),
                             );
                             return;
                           }
                            final jobDesc = args?.job ?? JobPostingArguments(
                              descriptionEn: 'Scheduled Service',
                              descriptionUr: 'شیڈولڈ سروس',
                              price: offerPrice,
                              categoryKey: worker.category.toLowerCase(),
                            );
                              double? latitude = jobDesc.customerLatitude;
                              double? longitude = jobDesc.customerLongitude;
                              if (latitude == null || longitude == null) {
                                final loc = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.confirmLocation,
                                  arguments: LocationPickArguments(),
                                );
                                if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
                                  latitude = (loc['lat'] as num).toDouble();
                                  longitude = (loc['lng'] as num).toDouble();
                                }
                                if (!context.mounted) return;
                              }
                              final jobId = await createJobOffer(
                                workerId: worker.id,
                                workerName: worker.name,
                                descriptionEn: jobDesc.descriptionEn,
                                descriptionUr: jobDesc.descriptionUr,
                                price: offerPrice,
                                categoryKey: jobDesc.categoryKey.isNotEmpty ? jobDesc.categoryKey : worker.category.toLowerCase(),
                                paymentMethod: jobDesc.paymentMethod,
                                customerLatitude: latitude,
                                customerLongitude: longitude,
                                visibilityDurationMinutes: _visibilityMinutes,
                              );
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.tracking,
                                 arguments: TrackingArguments(
                                   worker: worker,
                                   job: jobDesc,
                                   jobId: jobId,
                                 ),
                               );
                             }
                         }
                       }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(bilingual(context, 'Schedule', 'شیڈول کریں')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final priceText = _offerController.text.trim();
                      final offerPrice = double.tryParse(priceText);
                      if (offerPrice == null || offerPrice <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(bilingual(context, 'Please enter a valid amount to make an offer.', 'براہ کرم پیشکش کرنے کے لئے ایک درست رقم درج کریں۔')),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      final jobDesc = args?.job ?? JobPostingArguments(
                        descriptionEn: 'Service',
                        descriptionUr: 'سروس',
                        price: offerPrice,
                        categoryKey: worker.category.toLowerCase(),
                      );
                      double? latitude = jobDesc.customerLatitude;
                      double? longitude = jobDesc.customerLongitude;
                      if (latitude == null || longitude == null) {
                        final loc = await Navigator.pushNamed(
                          context,
                          AppRoutes.confirmLocation,
                          arguments: LocationPickArguments(),
                        );
                        if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
                          latitude = (loc['lat'] as num).toDouble();
                          longitude = (loc['lng'] as num).toDouble();
                        }
                        if (!context.mounted) return;
                      }
                      final jobId = await createJobOffer(
                        workerId: worker.id,
                        workerName: worker.name,
                        descriptionEn: jobDesc.descriptionEn,
                        descriptionUr: jobDesc.descriptionUr,
                        price: offerPrice,
                        categoryKey: jobDesc.categoryKey.isNotEmpty ? jobDesc.categoryKey : worker.category.toLowerCase(),
                        paymentMethod: jobDesc.paymentMethod,
                        customerLatitude: latitude,
                        customerLongitude: longitude,
                        visibilityDurationMinutes: _visibilityMinutes,
                      );
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.tracking,
                          arguments: TrackingArguments(
                            worker: worker,
                            job: jobDesc,
                            jobId: jobId,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                    child: Text(bilingual(context, 'Hire Now', 'ابھی ہائر کریں')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label),
        ],
      ),
    );
  }
}

class ServiceTrackingScreen extends StatefulWidget {
  const ServiceTrackingScreen({super.key});

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  int _trackingState = 0;
  StreamSubscription<DocumentSnapshot>? _jobSub;
  LatLng? _customerLocation;
  String _pin = '';
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _listenToJob();
  }

  void _listenToJob() {
    final args = ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final jobId = args?.jobId;
    if (jobId == null) return;
    _jobSub = streamJobById(jobId).listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final status = data['status']?.toString() ?? 'pending';
      if (status == 'rejected') {
        showToast(bilingual(context, 'Worker declined your offer. Please find another worker.', 'ورکر نے آپ کی پیشکش مسترد کر دی۔ براہ کرم دوسرا ورکر تلاش کریں۔'));
        Navigator.pop(context);
        return;
      }
      double? lat, lng;
      if (data['customerLatitude'] != null && data['customerLongitude'] != null) {
        lat = (data['customerLatitude'] as num).toDouble();
        lng = (data['customerLongitude'] as num).toDouble();
      }
      setState(() {
        if (status == 'accepted') {
          _trackingState = 1;
        } else if (status == 'arrival_pending') {
          _trackingState = 3;
        } else if (status == 'working') {
          _trackingState = 4;
        } else if (status == 'worker_completed') {
          _trackingState = 2;
        } else if (status == 'completed') {
          _trackingState = 5;
        } else {
          _trackingState = 0;
        }
        if (lat != null && lng != null) _customerLocation = LatLng(lat, lng);
        _pin = data['pin']?.toString() ?? '';
        _markers = {
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerLocation ?? const LatLng(31.5204, 74.3587),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: bilingual(context, 'You', 'آپ')),
          ),
          Marker(
            markerId: const MarkerId('worker'),
            position: _trackingState >= 1
                ? (_customerLocation ?? const LatLng(31.5204, 74.3587))
                : LatLng(
                    (_customerLocation?.latitude ?? 31.5204) + 0.005,
                    (_customerLocation?.longitude ?? 74.3587) + 0.005,
                  ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: bilingual(context, 'Worker', 'ورکر')),
          ),
        };
        if (_mapController != null && _customerLocation != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(_customerLocation!));
        }
      });
    });
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _trackingTitle(BuildContext context) {
    switch (_trackingState) {
      case 0:
        return bilingual(context, 'Waiting for worker to accept...', 'ورکر کے قبول کرنے کا انتظار ہے...');
      case 1:
        return bilingual(context, 'Worker is on the way', 'ورکر راستے میں ہے');
      case 2:
        return bilingual(context, 'Worker claims job is completed', 'ورکر کا دعویٰ ہے کہ کام مکمل ہو گیا');
      case 3:
        return bilingual(context, 'Worker has arrived', 'ورکر پہنچ گیا ہے');
      case 4:
        return bilingual(context, 'Worker is working at your location', 'ورکر آپ کے مقام پر کام کر رہا ہے');
      case 5:
        return bilingual(context, 'Job completed', 'کام مکمل ہو گیا');
      default:
        return bilingual(context, 'Tracking job', 'کام ٹریک ہو رہا ہے');
    }
  }

  String? _trackingDetail(BuildContext context) {
    switch (_trackingState) {
      case 3:
        return bilingual(context, 'Please confirm the worker is at your location.', 'براہ کرم تصدیق کریں کہ ورکر آپ کے مقام پر موجود ہے۔');
      case 4:
        return bilingual(context, 'This job is now working at customer.', 'یہ کام اب کسٹمر کے مقام پر جاری ہے۔');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final worker = args?.worker;
    final job = args?.job;
    final jobId = args?.jobId;

    if (worker == null) {
      return Scaffold(
        body: Center(
          child: Text(bilingual(context, 'Tracking data not available', 'ٹریکنگ ڈیٹا دستیاب نہیں')),
        ),
      );
    }

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Service Tracking', 'سروس ٹریکنگ'),
      child: Stack(
        children: [
          if (_trackingState >= 1)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _customerLocation ?? const LatLng(31.5204, 74.3587),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
          if (_trackingState == 0)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 100),
                  const CircularProgressIndicator(color: Color(0xFF0D9488)),
                  const SizedBox(height: 24),
                  Text(
                    bilingual(context, 'Request sent to worker...', 'ورکر کو درخواست بھیج دی گئی...'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bilingual(context, 'Waiting for them to accept your offer', 'ان کے آپ کی پیشکش قبول کرنے کا انتظار ہے'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (_trackingState >= 1)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton.extended(
              heroTag: 'customer_sos',
              backgroundColor: Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(bilingual(context, 'Emergency SOS', 'ہنگامی صورتحال (SOS)')),
                    content: Text(bilingual(context, 'Are you in danger? Calling Admin/Police.', 'کیا آپ خطرے میں ہیں؟ پولیس کو کال کی جا رہی ہے۔')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(bilingual(context, 'Cancel', 'منسوخ کریں'))),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.call),
                        label: const Text('15 / Admin'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final uri = Uri(scheme: 'tel', path: '15');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            showToast(bilingual(context, 'Unable to call emergency', 'ایمرجنسی کال کرنے سے قاصر'));
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.local_police, color: Colors.white),
              label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_trackingState == 0 || _trackingState == 1)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${bilingual(context, 'PIN', 'پِن')}: $_pin',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (_trackingState >= 1)
            Positioned(
            top: 110,
            left: 80,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    worker.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    worker.name.split(' ').first,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (_trackingState >= 1)
            Positioned(
            top: 240,
            right: 70,
            child: Column(
              children: const [
                CircleAvatar(radius: 18, backgroundColor: Colors.black87, child: Icon(Icons.location_on, color: Colors.white)),
                Text('You'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, -8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, width: 42, color: Colors.black26),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _trackingTitle(context),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.explore),
                    ],
                  ),
                  if (_trackingState == 1) Text(bilingual(context, 'Worker has accepted the job', 'ورکر نے کام قبول کر لیا ہے')),
                  if (_trackingDetail(context) != null) Text(_trackingDetail(context)!),
                  if (_trackingState == 2) ...[
                    const SizedBox(height: 8),
                    Text(
                      bilingual(context, 'Is it completed?', 'کیا کام مکمل ہو گیا ہے؟'),
                      style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        worker.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),
                    title: Text(worker.name),
                    subtitle: Text(
                      '${worker.category} • ${bilingual(context, job?.descriptionEn ?? "Service", job?.descriptionUr ?? "سروس")} • ${worker.price}'
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final wid = worker.id;
                            if (wid == null) return;
                            final existingId = await findExistingConversation(wid);
                            if (!context.mounted) return;
                            if (existingId != null) {
                              Navigator.pushNamed(context, AppRoutes.sharedConversation, arguments: ConversationArguments(conversationId: existingId, otherName: worker.name));
                            } else {
                              final newId = await createConversation(otherUserId: wid, otherUserName: worker.name);
                              if (context.mounted) {
                                Navigator.pushNamed(context, AppRoutes.sharedConversation, arguments: ConversationArguments(conversationId: newId, otherName: worker.name));
                              }
                            }
                          },
                          icon: const Icon(Icons.chat),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (worker.phone.isNotEmpty) {
                              final uri = Uri(scheme: 'tel', path: worker.phone);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                showToast(bilingual(context, 'Unable to call', 'کال کرنے سے قاصر'));
                              }
                            } else {
                              showToast(bilingual(context, 'No phone number available', 'فون نمبر دستیاب نہیں'));
                            }
                          },
                          icon: const Icon(Icons.call, color: Colors.green)
                        ),
                      ],
                    ),
                  ),
                  if (_trackingState == 3) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (jobId != null) {
                                await updateJobStatus(jobId, 'arrival_declined');
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(bilingual(context, 'Worker presence declined.', 'ورکر کی موجودگی مسترد کر دی گئی۔'))),
                              );
                            },
                            child: Text(bilingual(context, 'No', 'نہیں')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (jobId != null) {
                                await updateJobStatus(jobId, 'working');
                              }
                            },
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                            child: Text(bilingual(context, 'Yes', 'ہاں')),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_trackingState == 2) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (jobId != null) {
                                await updateJobStatus(jobId, 'working');
                              }
                              // explicitly stay on the current screen/state
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(bilingual(context, 'Waiting for worker to finish.', 'ورکر کا انتظار کیا جا رہا ہے۔'))),
                              );
                            },
                            child: Text(bilingual(context, 'No', 'نہیں')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (jobId != null) {
                                updateJobStatus(jobId, 'payment_pending');
                              }
                              Navigator.pushReplacementNamed(context, AppRoutes.rating, arguments: args);
                            },
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                            child: Text(bilingual(context, 'Yes', 'ہاں')),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CancelJobScreen()),
                        ),
                        child: Text(bilingual(context, 'Cancel Job', 'کام منسوخ کریں')),
                      ),
                    )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// _MapPainter has been replaced by GoogleMap widget above.

enum PostJobStep {
  chooseAction,
  complaintForm,
  paymentMethod,
  workerConfirmationWaiting,
  paymentSuccessTick,
  onlinePaymentSelect,
  onlinePaymentForm,
  ratingForm,
  completed
}

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  PostJobStep _step = PostJobStep.chooseAction;

  // Complaint
  final _claimDesc = TextEditingController();
  final _claimAmount = TextEditingController();
  bool _img1Added = false;
  bool _img2Added = false;

  // Online Payment
  String? _selectedProvider;
  final _senderName = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _payAmount = TextEditingController(text: '1050');
  final _paymentIssue = TextEditingController();

  // Rating
  int rating = 0;
  final review = TextEditingController();

  @override
  void dispose() {
    _claimDesc.dispose();
    _claimAmount.dispose();
    _senderName.dispose();
    _mobileNumber.dispose();
    _payAmount.dispose();
    _paymentIssue.dispose();
    review.dispose();
    super.dispose();
  }

  TrackingArguments? _trackingArgs(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
  }

  double _jobAmount(BuildContext context) {
    return _trackingArgs(context)?.job?.price ?? 0;
  }

  String _jobPaymentMethod(BuildContext context) {
    return _trackingArgs(context)?.job?.paymentMethod ?? 'Cash';
  }

  String? _jobId(BuildContext context) {
    return _trackingArgs(context)?.jobId;
  }

  Future<void> _markCustomerPaid(BuildContext context) async {
    final jobId = _jobId(context);
    if (jobId != null) {
      await updateJobStatus(jobId, 'worker_payment_pending');
    }
    if (!mounted) return;
    setState(() => _step = PostJobStep.workerConfirmationWaiting);
  }

  Future<void> _completeOnlinePayment(BuildContext context) async {
    final jobId = _jobId(context);
    if (jobId != null) {
      await updateJobCompleted(jobId);
    }
    if (!mounted) return;
    setState(() => _step = PostJobStep.paymentSuccessTick);
  }

  Future<void> _submitPaymentIssue(BuildContext context) async {
    final reason = _paymentIssue.text.trim();
    if (reason.isEmpty) {
      showToast(bilingual(context, 'Please explain why you are not paying.', 'براہ کرم وجہ لکھیں کہ ادائیگی کیوں نہیں کر رہے۔'));
      return;
    }
    final jobId = _jobId(context);
    final amount = _jobAmount(context);
    final paymentMethod = _jobPaymentMethod(context);
    if (jobId != null) {
      await submitPaymentComplaint(
        jobId: jobId,
        reason: reason,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      await updateJobStatus(jobId, 'payment_disputed');
    }
    if (!mounted) return;
    showToast(bilingual(context, 'Payment issue sent to admin.', 'ادائیگی کا مسئلہ ایڈمن کو بھیج دیا گیا۔'));
    setState(() => _step = PostJobStep.completed);
  }

  void _showCashPaidDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bilingual(context, 'Have you paid?', 'کیا آپ نے ادائیگی کر دی؟')),
        content: Text(bilingual(
          context,
          'Have you paid Rs. ${amount.toStringAsFixed(0)} to the worker by hand?',
          'کیا آپ نے ورکر کو ${amount.toStringAsFixed(0)} روپے نقد ادا کر دیے ہیں؟',
        )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _step = PostJobStep.complaintForm);
            },
            child: Text(bilingual(context, 'No', 'نہیں')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markCustomerPaid(context);
            },
            child: Text(bilingual(context, 'Yes', 'ہاں')),
          ),
        ],
      ),
    );
  }

  String _getTitle(BuildContext context) {
    if (_step == PostJobStep.chooseAction) return bilingual(context, 'Service Summary', 'سروس کا خلاصہ');
    if (_step == PostJobStep.complaintForm) return bilingual(context, 'Lodge Complaint', 'شکایت درج کریں');
    if (_step == PostJobStep.paymentMethod || _step == PostJobStep.onlinePaymentSelect || _step == PostJobStep.onlinePaymentForm) {
      return bilingual(context, 'Payment', 'ادائیگی');
    }
    return bilingual(context, 'Rate Service', 'درجہ بندی کریں');
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      title: _getTitle(context),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildCurrentStep(context),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case PostJobStep.chooseAction:
        return _buildChooseAction(context);
      case PostJobStep.complaintForm:
        return _buildComplaintForm(context);
      case PostJobStep.paymentMethod:
        return _buildPaymentMethod(context);
      case PostJobStep.workerConfirmationWaiting:
        return _buildCashWaiting(context);
      case PostJobStep.paymentSuccessTick:
        return _buildTickSuccess(context);
      case PostJobStep.onlinePaymentSelect:
        return _buildOnlineSelect(context);
      case PostJobStep.onlinePaymentForm:
        return _buildOnlineForm(context);
      case PostJobStep.ratingForm:
        return _buildRatingForm(context);
      case PostJobStep.completed:
        return _buildCompleted(context);
    }
  }

  Widget _buildChooseAction(BuildContext context) {
    final amount = _jobAmount(context);
    final paymentMethod = _jobPaymentMethod(context);
    final isCash = paymentMethod.toLowerCase() == 'cash';

    return ListView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.task_alt, color: Color(0xFF059669), size: 64),
        const SizedBox(height: 16),
        Text(bilingual(context, 'Job Completed!', 'کام مکمل ہو گیا!'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BillRow('Service Fee', 'Rs. ${amount.toStringAsFixed(0)}'),
                _BillRow('Payment Method', paymentMethod),
                const Divider(),
                _BillRow('Total', 'Rs. ${amount.toStringAsFixed(0)}', bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            if (isCash) {
              _showCashPaidDialog(context, amount);
            } else {
              _selectedProvider = paymentMethod;
              _payAmount.text = amount.toStringAsFixed(0);
              setState(() => _step = PostJobStep.onlinePaymentForm);
            }
          },
          child: Text(bilingual(context, 'Proceed to Payment', 'ادائیگی کریں')),
        ),
      ],
    );
  }

  Widget _buildComplaintForm(BuildContext context) {
    return ListView(
      key: const ValueKey('complaint'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(bilingual(context, 'File a Complaint', 'ایک شکایت درج کریں'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _paymentIssue,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: bilingual(context, 'Description / Issue', 'تفصیل / مسئلہ'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _claimAmount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: bilingual(context, 'Money Claim Amount', 'رقم کے دعوے کی رقم'),
            prefixText: 'Rs. '
          ),
        ),
        const SizedBox(height: 24),
        Text(bilingual(context, 'Add Photos (Optional)', 'تصاویر شامل کریں (اختیاری)')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _img1Added = !_img1Added),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Icon(_img1Added ? Icons.image : Icons.add_a_photo, color: _img1Added ? Colors.green : Colors.grey, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _img2Added = !_img2Added),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Icon(_img2Added ? Icons.image : Icons.add_a_photo, color: _img2Added ? Colors.green : Colors.grey, size: 32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => _submitPaymentIssue(context),
          child: Text(bilingual(context, 'Submit to Admin', 'ایڈمن کو بھیجیں')),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return ListView(
      key: const ValueKey('paymentMethod'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(bilingual(context, 'Select Payment Method', 'ادائیگی کا طریقہ منتخب کریں'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.money, size: 36, color: Colors.green),
          title: Text(bilingual(context, 'Cash by Hand', 'نقد ادا کریں')),
          subtitle: Text(bilingual(context, 'Pay directly to worker', 'براہ راست ورکر کو ادائیگی کریں')),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          onTap: () {
            setState(() => _step = PostJobStep.workerConfirmationWaiting);
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted && _step == PostJobStep.workerConfirmationWaiting) {
                setState(() => _step = PostJobStep.paymentSuccessTick);
              }
            });
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet, size: 36, color: Colors.blue),
          title: Text(bilingual(context, 'Pay Online', 'آن لائن ادائیگی')),
          subtitle: Text(bilingual(context, 'JazzCash, EasyPaisa, etc.', 'جاز کیش، ایزی پیسہ وغیرہ')),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          onTap: () {
            setState(() => _step = PostJobStep.onlinePaymentSelect);
          },
        ),
      ],
    );
  }

  Widget _buildCashWaiting(BuildContext context) {
    final jobId = _jobId(context);
    if (jobId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: streamJobById(jobId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data?['status'] == 'completed') {
            return _buildTickSuccess(context);
          }
          return _buildCashWaitingContent(context);
        },
      );
    }
    return _buildCashWaitingContent(context);
  }

  Widget _buildCashWaitingContent(BuildContext context) {
    return Center(
      key: const ValueKey('cashWait'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(bilingual(context, 'Message sent to worker...', 'ورکر کو پیغام بھیجا گیا...'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(bilingual(context, 'Waiting for worker to confirm payment received', 'ورکر کی جانب سے ادائیگی کی وصولی کی تصدیق کا انتظار ہے'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTickSuccess(BuildContext context) {
    final amount = _jobAmount(context);
    final method = _jobPaymentMethod(context);
    final workerName = _trackingArgs(context)?.worker?.name ?? 'Worker';
    final receiptId = (_jobId(context) ?? 'JOB');

    return Center(
      key: const ValueKey('tickSuccess'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(bilingual(context, 'Payment Successful!', 'ادائیگی کامیاب!'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 18),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _BillRow(
                    'Receipt',
                    '#${receiptId.length > 6 ? receiptId.substring(0, 6) : receiptId}',
                    bold: true,
                  ),
                  const Divider(),
                  _BillRow('Worker', workerName),
                  _BillRow('Payment', method),
                  _BillRow('Amount', 'Rs. ${amount.toStringAsFixed(0)}', bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _step = PostJobStep.ratingForm),
            child: Text(bilingual(context, 'Continue to Rating', 'درجہ بندی پر جائیں')),
          )
        ],
      ),
    );
  }

  Widget _buildOnlineSelect(BuildContext context) {
    return Padding(
      key: const ValueKey('onlineSelect'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(bilingual(context, 'Choose Provider', 'فراہم کنندہ منتخب کریں'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedProvider = 'JazzCash';
                    _step = PostJobStep.onlinePaymentForm;
                  }),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('JazzCash', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedProvider = 'EasyPaisa';
                    _step = PostJobStep.onlinePaymentForm;
                  }),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('EasyPaisa', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineForm(BuildContext context) {
    return ListView(
      key: const ValueKey('onlineForm'),
      padding: const EdgeInsets.all(24),
      children: [
        Text('${bilingual(context, 'Pay via', 'ذریعے ادائیگی کریں')} $_selectedProvider', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        TextField(
          controller: _senderName,
          decoration: InputDecoration(labelText: bilingual(context, 'Sender Name', 'بھیجنے والے کا نام')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _mobileNumber,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: bilingual(context, 'Mobile Number', 'موبائل نمبر')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _payAmount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: bilingual(context, 'Amount', 'رقم')),
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () => _completeOnlinePayment(context),
          child: Text(bilingual(context, 'Send Payment', 'ادائیگی بھیجیں')),
        ),
      ],
    );
  }

  Widget _buildRatingForm(BuildContext context) {
    return ListView(
      key: const ValueKey('ratingForm'),
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 32,
          child: Icon(Icons.person, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          bilingual(context, 'How was your service?', 'آپ کی سروس کیسی تھی؟'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final active = index < rating;
            return IconButton(
              onPressed: () => setState(() => rating = index + 1),
              icon: Icon(active ? Icons.star : Icons.star_border, color: const Color(0xFFF59E0B), size: 34),
            );
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: review,
          minLines: 3,
          maxLines: 3,
          decoration: InputDecoration(hintText: bilingual(context, 'Write your review', 'اپنا جائزہ لکھیں')),
        ),
        const SizedBox(height: 24),
        Text(bilingual(context, 'Add a Tip for the Worker', 'ورکر کے لیے ٹپ شامل کریں'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bilingual(context, 'Rs. 50 Tip Added', '50 روپے کی ٹپ شامل کر دی گئی')))),
                child: const Text('Rs. 50'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bilingual(context, 'Rs. 100 Tip Added', '100 روپے کی ٹپ شامل کر دی گئی')))),
                child: const Text('Rs. 100'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bilingual(context, 'Rs. 200 Tip Added', '200 روپے کی ٹپ شامل کر دی گئی')))),
                child: const Text('Rs. 200'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: rating == 0 ? null : () => setState(() => _step = PostJobStep.completed),
          child: Text(bilingual(context, 'Submit Review', 'جائزہ جمع کریں')),
        )
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Center(
      key: const ValueKey('completed'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (_, value, child) => Transform.scale(scale: value, child: child),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.check, color: Color(0xFF059669), size: 42),
              ),
            ),
            const SizedBox(height: 14),
            Text(bilingual(context, 'Thank You!', 'شکریہ!'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(bilingual(context, 'Your feedback helps keep our community safe.', 'آپ کا فیڈ بیک کمیونٹی کو محفوظ بناتا ہے۔'), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.customerHome, (r) => false),
              child: Text(bilingual(context, 'Back to Home', 'ہوم پر واپس جائیں')),
            )
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(this.left, this.right, {this.bold = false});

  final String left;
  final String right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(left, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          Text(right, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  int selectedSkill = 0;

  final skills = const ['پلمبر', 'الیکٹریشن', 'کارپینٹر', 'اے سی مکینک', 'پینٹر', 'صفائی'];
  final skillsEn = const ['Plumber', 'Electrician', 'Carpenter', 'AC Mechanic', 'Painter', 'Cleaner'];

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: isUrdu ? 'ورکر آن بورڈنگ' : 'Worker Onboarding',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isUrdu ? 'اپنا ہنر منتخب کریں' : 'Choose Your Category', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(isUrdu ? 'براہ کرم اپنا پیشہ منتخب کریں تاکہ سروسز کا سیٹ اپ ہو سکے' : 'Please select your profession to set up services', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: skills.length,
                itemBuilder: (context, i) {
                  final selected = i == selectedSkill;
                  return InkWell(
                    onTap: () => setState(() => selectedSkill = i),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE6FFFA) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? const Color(0xFF0D9488) : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected ? [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.engineering, // Generic icon for now
                            color: selected ? const Color(0xFF0D9488) : Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isUrdu ? skills[i] : skillsEn[i],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              color: selected ? const Color(0xFF0F766E) : AppTheme.darkerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.workerServicesSetup,
                    arguments: selectedSkill,
                  );
                },
                child: Text(isUrdu ? 'آگے بڑھیں (سروسز کا انتخاب)' : 'Continue to Services'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Worker Category Selection Screen (shown on first login)
// ─────────────────────────────────────────────────────
class WorkerCategorySelectScreen extends StatefulWidget {
  const WorkerCategorySelectScreen({super.key});
  @override
  State<WorkerCategorySelectScreen> createState() => _WorkerCategorySelectScreenState();
}

class _WorkerCategorySelectScreenState extends State<WorkerCategorySelectScreen> {
  String? _selected;
  bool _isSaving = false;
  bool _isLoading = true;
  WorkerSignupData? _signupData;

  static const _categories = [
    {
      'key': 'plumber',
      'title': 'Plumber',
      'subtitle': 'Pipes, leaks, drainage & water systems',
      'icon': Icons.plumbing,
      'color': Color(0xFF0EA5E9),
    },
    {
      'key': 'electrician',
      'title': 'Electrician',
      'subtitle': 'Wiring, fittings, panels & electrical repairs',
      'icon': Icons.electrical_services,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WorkerSignupData) {
      _signupData = args;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingCategory();
  }

  Future<void> _loadExistingCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final category = data['category']?.toString();
        if (category != null && _categories.any((c) => c['key'] == category)) {
          _selected = category;
        } else {
          final nameEn = data['categoryNameEn']?.toString().toLowerCase() ?? '';
          for (final c in _categories) {
            if (nameEn.contains(c['key'] as String)) {
              _selected = c['key'] as String;
              break;
            }
          }
        }
      }
    }
    if (mounted) {
      // Existing user with a category — skip category picker, go straight to services
      if (_signupData == null && _selected != null) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.workerServicesSetup,
            arguments: _categoryKeyToIndex(_selected!),
          );
        }
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  int _categoryKeyToIndex(String key) {
    switch (key) {
      case 'plumber': return 0;
      case 'electrician': return 1;
      default: return 0;
    }
  }

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category to continue')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_signupData != null) {
        // Signup mode - pass data forward
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.workerServicesSetup,
            arguments: ServicesSetupArguments(
              categoryIndex: _categoryKeyToIndex(_selected!),
              signupData: _signupData,
            ),
          );
        }
      } else {
        // Existing user mode - save category to Firestore first
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'category': _selected,
          });
        }
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.workerServicesSetup,
            arguments: ServicesSetupArguments(
              categoryIndex: _categoryKeyToIndex(_selected!),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isUrdu = controller.isUrdu;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(isUrdu ? Icons.arrow_forward : Icons.arrow_back),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                controller.toggleLanguage();
                setState(() {});
              },
              icon: const Icon(Icons.translate, size: 18),
              label: Text(controller.isUrdu ? 'EN' : 'اردو', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF0D9488),
                  child: Icon(Icons.construction, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  isUrdu ? 'آپ کی خصوصیت کیا ہے؟' : 'What is your specialty?',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  isUrdu
                      ? 'وہ زمرہ منتخب کریں جو آپ کے پیشے کو بہترین طور پر بیان کرے۔ اس سے آپ کو متعلقہ کام دکھائے جائیں گے۔'
                      : 'Select the category that best describes your profession. This will show you relevant jobs.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 32),
                ...(_categories.map((cat) {
                final key = cat['key'] as String;
                final isSelected = _selected == key;
                final color = cat['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selected = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(cat['icon'] as IconData, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'] as String,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? color : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat['subtitle'] as String,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: color, size: 24),
                      ],
                    ),
                  ),
                );
              })),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isUrdu ? 'خدمات کے سیٹ اپ پر جائیں' : 'Continue to Services Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool online = true;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final user = FirebaseAuth.instance.currentUser;

    return MzScaffold(
      showBottomNav: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: streamCurrentUserData(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final name = data?['name']?.toString() ?? (isUrdu ? 'ورکر' : 'Worker');
              final categoryUr = data?['categoryNameUr']?.toString() ?? '';
              final categoryEn = data?['categoryNameEn']?.toString() ?? '';
              final profileImage = data?['profileImage']?.toString() ?? '';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                  child: profileImage.isEmpty
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'W')
                      : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(isUrdu && categoryUr.isNotEmpty ? categoryUr : categoryEn),
                trailing: const SizedBox(width: 48),
              );
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: online ? const Color(0xFF0D9488) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    online
                        ? (isUrdu ? 'آپ آن لائن ہیں' : 'You are online')
                        : (isUrdu ? 'آپ آف لائن ہیں' : 'You are offline'),
                    style: TextStyle(
                      color: online ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(value: online, onChanged: (v) => setState(() => online = v)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (online && user != null)
            StreamBuilder<QuerySnapshot>(
              stream: streamWorkerJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('WorkerJobsError: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allJobs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final jobs = allJobs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final expiresAtStr = data['expiresAt']?.toString();
                  if (expiresAtStr != null) {
                    final expiresAt = DateTime.tryParse(expiresAtStr);
                    if (expiresAt != null && expiresAt.isBefore(now)) return false;
                  }
                  return true;
                }).toList();

                jobs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aCreated = aData['createdAt'];
                  final bCreated = bData['createdAt'];
                  final aTime = (aCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bTime = (bCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });

                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        bilingual(context, 'No new jobs yet', 'ابھی تک کوئی نیا کام نہیں'),
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }
                return Column(
                  children: jobs.map((doc) {
                    final jobData = doc.data() as Map<String, dynamic>;
                    final jobId = doc.id;
                    final descEn = jobData['descriptionEn']?.toString() ?? 'Service';
                    final descUr = jobData['descriptionUr']?.toString() ?? 'سروس';
                    final price = (jobData['price'] as num?)?.toDouble() ?? 0;
                    final payment = jobData['paymentMethod']?.toString() ?? 'Cash';
                    final customerName = jobData['customerName']?.toString() ?? 'Customer';

                    String remainingTime = '';
                    final expiresAtStr = jobData['expiresAt']?.toString();
                    if (expiresAtStr != null) {
                      final expiresAt = DateTime.tryParse(expiresAtStr);
                      if (expiresAt != null) {
                        final diff = expiresAt.difference(now);
                        if (diff.isNegative) {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        } else if (diff.inDays > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inDays} دن باقی'
                              : '${diff.inDays}d remaining';
                        } else if (diff.inHours > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inHours} گھنٹے باقی'
                              : '${diff.inHours}h remaining';
                        } else if (diff.inMinutes > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inMinutes} منٹ باقی'
                              : '${diff.inMinutes}min remaining';
                        } else {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        }
                      }
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 260),
                      builder: (_, value, child) => Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF0D9488), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'نیا کام!' : 'New Job!',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(isUrdu ? descUr : descEn, style: const TextStyle(fontSize: 16)),
                              Text(
                                '${bilingual(context, 'Customer:', 'گاہک:')} $customerName',
                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                              if (remainingTime.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  remainingTime,
                                  style: TextStyle(
                                    color: remainingTime.contains('Expired') || remainingTime.contains('ختم')
                                        ? Colors.red
                                        : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${bilingual(context, 'Payment:', 'ادائیگی:')} $payment',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        updateJobStatus(jobId, 'rejected');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isUrdu ? 'کام رد کر دیا گیا' : 'Job rejected'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: Text(isUrdu ? 'رد کریں' : 'Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(isUrdu ? 'تصدیق کریں' : 'Confirm?'),
                                            content: Text(isUrdu
                                                ? 'کیا آپ اس کام کو قبول کرنا چاہتے ہیں؟'
                                                : 'Are you sure you want to accept this job?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(isUrdu ? 'نہیں' : 'No',
                                                    style: const TextStyle(color: Colors.red)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  updateJobStatus(jobId, 'accepted');
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => WorkerTrackingScreen(
                                                        jobPrice: price,
                                                        jobId: jobId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(isUrdu ? 'جی ہاں' : 'Yes'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: Text(isUrdu ? 'قبول کریں' : 'Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ColorStatCard extends StatelessWidget {
  const _ColorStatCard({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  bool weekly = true;
  int _topupBalance = 500;

  void _showTopUpDialog(BuildContext context, bool isUrdu) {
    String selectedMethod = 'JazzCash';
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isUrdu ? 'ٹاپ اپ کریں' : 'Add Top-up', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'طریقہ منتخب کریں' : 'Select Method',
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                    DropdownMenuItem(value: 'EasyPaisa', child: Text('EasyPaisa')),
                  ],
                  onChanged: (val) => setModalState(() => selectedMethod = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'اکاؤنٹ نمبر' : 'Account Number',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'رقم' : 'Amount (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final amount = int.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      setState(() {
                        _topupBalance += amount;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isUrdu ? 'ٹاپ اپ کامیاب ہو گیا' : 'Top-up Successful!')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(isUrdu ? 'رقم بھیجیں' : 'Send Money'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: true,
      child: StreamBuilder<double>(
        stream: streamWorkerEarnings(),
        builder: (context, earningsSnapshot) {
          final totalEarnings = earningsSnapshot.data ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .where('status', whereIn: ['accepted', 'completed'])
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, jobsSnapshot) {
              final jobs = jobsSnapshot.data?.docs ?? [];
              final completedCount = jobs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'completed';
              }).length;

              return ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'میری آمدنی' : 'My Earnings',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isUrdu ? 'اب تک کی کل کمائی' : 'Total earnings',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUrdu ? '${totalEarnings.toStringAsFixed(0)} روپے' : 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ColorStatCard(
                            color: const Color(0xFFDCFCE7),
                            label: isUrdu ? 'مکمل' : 'Completed',
                            value: isUrdu ? '$completedCount کام' : '$completedCount jobs',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ColorStatCard(
                            color: const Color(0xFFDBEAFE),
                            label: isUrdu ? 'کل کمائی' : 'Total Earned',
                            value: isUrdu ? '${totalEarnings.toStringAsFixed(0)} روپے' : 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isUrdu ? 'ٹاپ اپ بیلنس' : 'Top-up Balance', style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(isUrdu ? '$_topupBalance روپے' : 'Rs. $_topupBalance', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                            icon: const Icon(Icons.add_card),
                            label: Text(isUrdu ? 'ٹاپ اپ کریں' : 'Top-up'),
                            onPressed: () => _showTopUpDialog(context, isUrdu),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isUrdu ? 'حالیہ لین دین' : 'Recent Transactions',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (jobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          isUrdu ? 'ابھی تک کوئی لین دین نہیں' : 'No transactions yet',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...jobs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final desc = isUrdu
                          ? (data['descriptionUr']?.toString() ?? data['descriptionEn']?.toString() ?? 'Service')
                          : (data['descriptionEn']?.toString() ?? data['descriptionUr']?.toString() ?? 'Service');
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final status = data['status']?.toString() ?? '';
                      final customer = data['customerName']?.toString() ?? 'Customer';
                      return ListTile(
                        leading: Icon(
                          status == 'completed' ? Icons.check_circle : Icons.south_west,
                          color: status == 'completed' ? Colors.green : Colors.orange,
                        ),
                        title: Text(desc),
                        subtitle: Text(
                          isUrdu ? '$customer • ${status == "completed" ? "مکمل" : "جاری"}' : '$customer • ${status == "completed" ? "Completed" : "In progress"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '+${price.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class SmartChatScreen extends StatefulWidget {
  const SmartChatScreen({super.key});
  @override
  State<SmartChatScreen> createState() => _SmartChatScreenState();
}
class _SmartChatScreenState extends State<SmartChatScreen> {
  final input = TextEditingController();
  late final VoidCallback _inputListener;
  bool showUrdu = false;

  final List<_Message> messages = [
    _Message('Hi, available?', 'سلام، دستیاب؟', false),
    _Message('Yes, 15 minutes', 'جی، 15 منٹ', true),
  ];

  @override
  void initState() {
    super.initState();
    _inputListener = () {
      if (mounted) setState(() {});
    };
    input.addListener(_inputListener);
  }

  @override
  void dispose() {
    input.removeListener(_inputListener);
    input.dispose();
    super.dispose();
  }

  bool _isUrduText(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  String _translateToUrdu(String english) {
    final map = {
      'hello': 'سلام / ہیلو',
      'hi': 'سلام',
      'how are you': 'آپ کیسے ہیں؟',
      'where are you': 'آپ کہاں ہیں؟',
      'i am coming': 'میں آ رہا ہوں',
      'ok': 'ٹھیک ہے',
      'yes': 'جی ہاں',
      'no': 'جی نہیں',
      'thanks': 'شکریہ',
      'thank you': 'شکریہ',
      'price': 'قیمت',
    };
    final lower = english.toLowerCase().trim();
    return map[lower] ?? 'ترجمہ: $english';
  }

  String _translateToEnglish(String urdu) {
    final map = {
      'سلام': 'hi',
      'جی، 15 منٹ': 'Yes, 15 minutes',
      'آپ کیسے ہیں؟': 'how are you?',
      'شکریہ': 'thanks',
      'ٹھیک ہے': 'ok',
    };
    final trimmed = urdu.trim();
    return map[trimmed] ?? 'Translation: $urdu';
  }

  void _sendMessage() {
    final text = input.text.trim();
    if (text.isEmpty) return;
    final urText = _isUrduText(text);
    setState(() {
      messages.add(_Message(
        urText ? _translateToEnglish(text) : text,
        urText ? text : _translateToUrdu(text),
        true,
      ));
      input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    return MzScaffold(
      showBottomNav: true,
      showBack: true,
      title: bilingual(context, 'Smart Chat', 'سمارٹ چیٹ'),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(bilingual(context, 'Messages auto-translated', 'پیغامات خودکار ترجمہ ہوتے ہیں'))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final m = messages[i];
                final own = m.own;
                return Align(
                  alignment: own ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: own ? const Color(0xFF0D9488) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (showUrdu) ? m.ur : m.en, 
                          style: TextStyle(color: own ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            DateFormat('hh:mm a').format(DateTime.now()), 
                            style: TextStyle(color: own ? Colors.white60 : Colors.black45, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showUrdu = !(showUrdu);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      (showUrdu) ? 'UR ➔ EN' : 'EN ➔ UR',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice input activated')),
                    );
                  }, 
                  icon: const Icon(Icons.mic_none)
                ),
                Expanded(
                  child: TextField(
                    controller: input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(hintText: bilingual(context, 'Type a message...', 'پیغام لکھیں...')),
                  ),
                ),
                Transform.rotate(
                  angle: isUrdu ? math.pi : 0,
                  child: IconButton(
                    onPressed: input.text.trim().isEmpty ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});
  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      showBottomNav: true,
      title: bilingual(context, 'Chat History', 'چیٹ ہسٹری'),
      child: StreamBuilder<QuerySnapshot>(
        stream: streamConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data?.docs ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  bilingual(context, 'No conversations yet. Start a chat with a worker to see it here.', 'ابھی تک کوئی گفتگو نہیں۔ کسی ورکر کے ساتھ چیٹ شروع کریں۔'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (_, i) {
              final doc = conversations[i];
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              final participantNames = data['participantNames'] as Map<String, dynamic>?;
              final lastMsg = data['lastMessage'] as String? ?? '';
              final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final otherId = participants.where((p) => p != currentUid).firstOrNull ?? '';
              final otherName = participantNames?[otherId] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0D9488).withOpacity(0.15),
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
                title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.sharedConversation,
                    arguments: ConversationArguments(conversationId: doc.id, otherName: otherName),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  const ConversationScreen({super.key, required this.conversationId, required this.otherName});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    sendMessage(widget.conversationId, text);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      showBottomNav: false,
      title: widget.otherName,
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                final msgs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final senderId = data['senderId'] as String? ?? '';
                    final text = data['text'] as String? ?? '';
                    final isMe = senderId == FirebaseAuth.instance.currentUser?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF0D9488) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: bilingual(context, 'Type a message...', 'پیغام لکھیں...'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0D9488)),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  _Message(this.en, this.ur, this.own);

  final String en;
  final String ur;
  final bool own;
}

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  bool activeTab = true;

  String _bookingStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return bilingual(context, 'Pending', 'زیر التوا');
      case 'accepted':
        return bilingual(context, 'Worker on the way', 'ورکر راستے میں ہے');
      case 'arrival_pending':
        return bilingual(context, 'Arrival confirmation pending', 'آمد کی تصدیق باقی ہے');
      case 'working':
        return bilingual(context, 'Working at customer', 'کسٹمر کے مقام پر کام جاری ہے');
      case 'worker_completed':
        return bilingual(context, 'Customer completion pending', 'کسٹمر کی تکمیل تصدیق باقی ہے');
      case 'completed':
        return bilingual(context, 'Completed', 'مکمل');
      case 'arrival_declined':
        return bilingual(context, 'Arrival declined', 'آمد مسترد');
      case 'rejected':
        return bilingual(context, 'Rejected', 'مسترد');
      default:
        return status;
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    final role = AppScope.of(context).role;
    final uidField = role == UserRole.worker ? 'workerId' : 'customerId';
    return FirebaseFirestore.instance
        .collection('jobs')
        .where(uidField, isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: true,
      title: bilingual(context, 'Bookings', 'بکنگز'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: ChoiceChip(label: Text(bilingual(context, 'Active', 'ایکٹو')), selected: activeTab, onSelected: (_) => setState(() => activeTab = true))),
                const SizedBox(width: 8),
                Expanded(child: ChoiceChip(label: Text(bilingual(context, 'Past', 'ماضی')), selected: !activeTab, onSelected: (_) => setState(() => activeTab = false))),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final status = (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
                  return activeTab
                      ? (status == 'pending' || status == 'accepted' || status == 'arrival_pending' || status == 'working' || status == 'worker_completed')
                      : (status == 'completed' || status == 'rejected' || status == 'arrival_declined');
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(bilingual(context, 'No bookings yet', 'ابھی کوئی بکنگ نہیں')));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status']?.toString() ?? '';
                    final descEn = data['descriptionEn']?.toString() ?? '';
                    final descUr = data['descriptionUr']?.toString() ?? '';
                    final price = data['price'];
                    final priceStr = price != null ? 'Rs. ${(price as num).toStringAsFixed(0)}' : '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeStr = createdAt != null
                        ? DateFormat('d MMM yyyy').format(createdAt.toDate())
                        : '';

                    return Card(
                      child: InkWell(
                        onTap: () async {
                          if (activeTab && AppScope.of(context).role == UserRole.worker) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkerTrackingScreen(
                                  jobPrice: (price as num?)?.toDouble() ?? 0,
                                  jobId: doc.id,
                                ),
                              ),
                            );
                          } else if (activeTab) {
                            final workerId = data['workerId']?.toString() ?? '';
                            if (workerId.isNotEmpty) {
                              final workerDoc = await FirebaseFirestore.instance.collection('users').doc(workerId).get();
                              final workerData = workerDoc.data();
                              if (workerData != null && context.mounted) {
                                final worker = WorkerModel.fromFirestore(workerData, docId: workerDoc.id);
                                final jobArgs = JobPostingArguments(
                                  descriptionEn: descEn,
                                  descriptionUr: descUr,
                                  price: (price as num?)?.toDouble() ?? 0,
                                  categoryKey: data['categoryKey']?.toString() ?? '',
                                  paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
                                  customerLatitude: (data['customerLatitude'] as num?)?.toDouble(),
                                  customerLongitude: (data['customerLongitude'] as num?)?.toDouble(),
                                );
                                Navigator.pushNamed(context, AppRoutes.tracking, arguments: TrackingArguments(
                                  worker: worker,
                                  job: jobArgs,
                                  jobId: doc.id,
                                ));
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job Details opened')),
                            );
                          }
                        },
                        child: ListTile(
                          leading: Icon(status == 'completed' ? Icons.check_circle : Icons.schedule,
                              color: status == 'completed' ? Colors.green : Colors.amber.shade700),
                          title: Text(isUrdu ? descUr : descEn),
                          subtitle: Text('$timeStr • ${_bookingStatusLabel(context, status)}'),
                          trailing: Text(priceStr, style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final isWorker = c.role == UserRole.worker;

    return MzScaffold(
      showBottomNav: true,
      title: bilingual(context, 'Settings', 'ترتیبات'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: streamCurrentUserData(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final name = data?['name']?.toString() ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
              final phone = data?['phone']?.toString() ?? '+92 300 1234567';
              final profileImage = data?['profileImage']?.toString() ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                  child: profileImage.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                ),
                title: Text(name),
                subtitle: Text(phone),
              );
            },
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileManagement),
            child: _SettingsItem(icon: Icons.person, color: Colors.blue, title: bilingual(context, 'Profile', 'پروفائل')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationPreferences),
            child: _SettingsItem(icon: Icons.notifications, color: Colors.amber, title: bilingual(context, 'Notifications', 'نوٹیفیکیشن')),
          ),
          _SettingsItem(
            icon: Icons.language,
            color: Colors.purple,
            title: bilingual(context, 'Language', 'زبان'),
            trailing: TextButton(
              onPressed: c.toggleLanguage,
              child: Text(c.isUrdu ? 'English' : 'اردو'),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
            child: _SettingsItem(icon: Icons.lock, color: Colors.green, title: bilingual(context, 'Privacy', 'پرائیویسی')),
          ),
          if (!isWorker)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/customer/support'),
              child: _SettingsItem(icon: Icons.help_outline, color: const Color(0xFF0D9488), title: bilingual(context, 'Customer Support', 'کسٹمر سپورٹ')),
            ),
          if (isWorker)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/worker/support'),
              child: _SettingsItem(icon: Icons.help_outline, color: const Color(0xFF0D9488), title: bilingual(context, 'Worker Support', 'ورکر سپورٹ')),
            ),
          if (isWorker)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.workerCategorySelect),
              child: _SettingsItem(icon: Icons.build, color: const Color(0xFF0D9488), title: bilingual(context, 'Skills & Services', 'مہارتیں اور خدمات')),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              c.logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(bilingual(context, 'Log Out', 'لاگ آؤٹ'), style: const TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.icon, required this.color, required this.title, this.trailing});

  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
        title: Text(title),
        trailing: trailing ?? Transform.rotate(angle: isUrdu ? math.pi : 0, child: const Icon(Icons.chevron_right)),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0D9488) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Data model for job photos in the photo picker modal
class _JobPhotoAsset {
  const _JobPhotoAsset(this.label, this.asset, this.icon);
  final String label;
  final String asset;
  final IconData icon;
}

/// Card widget for camera/gallery action buttons in photo picker
/// Card widget for camera/gallery action buttons in photo picker
class _PhotoActionCard extends StatelessWidget {
  const _PhotoActionCard({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
              child: Icon(icon, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


class FavoriteWorkersScreen extends StatefulWidget {
  const FavoriteWorkersScreen({super.key});
  @override
  State<FavoriteWorkersScreen> createState() => _FavoriteWorkersScreenState();
}

class _FavoriteWorkersScreenState extends State<FavoriteWorkersScreen> {
  StreamSubscription? _favSub;
  List<String> _favouriteIds = [];
  List<WorkerModel> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _favSub = streamFavouriteWorkerIds().listen((ids) {
      _favouriteIds = ids;
      _fetchWorkers(ids);
    });
  }

  Future<void> _fetchWorkers(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() { _workers = []; _loading = false; });
      return;
    }
    final workers = <WorkerModel>[];
    for (final id in ids) {
      try {
        final doc = await FirebaseFirestore.instance.collection('workers').doc(id).get();
        final data = doc.data();
        if (data != null) {
          workers.add(WorkerModel.fromFirestore(data, docId: doc.id));
        }
      } catch (_) {}
    }
    if (mounted) setState(() { _workers = workers; _loading = false; });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      title: bilingual(context, 'Favorite Workers', 'پسندیدہ ورکرز'),
      showBottomNav: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      bilingual(context, 'No favourite workers yet. Tap the heart icon on a worker\'s profile to add them.', 'ابھی تک کوئی پسندیدہ ورکر نہیں۔ ورکر کے پروفائل پر دل کے آئیکن کو تھپتھپا کر شامل کریں۔'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _workers.length,
                  itemBuilder: (context, i) {
                    final w = _workers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: w.image.isNotEmpty ? NetworkImage(w.image) : null,
                        child: w.image.isEmpty ? Text(w.name.isNotEmpty ? w.name[0].toUpperCase() : '?') : null,
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${w.category}${w.price.isNotEmpty ? '  •  ${w.price}' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                            onPressed: () {
                              final wid = w.id;
                              if (wid == null) return;
                              removeFavouriteWorker(wid);
                              setState(() => _favouriteIds.remove(wid));
                              _fetchWorkers(_favouriteIds);
                            },
                          ),
                          IconButton.filledTonal(
                            onPressed: () {
                              Navigator.pushNamed(
                                context, 
                                AppRoutes.workerProfile,
                                arguments: ProfileArguments(
                                  worker: w,
                                  job: JobPostingArguments(descriptionEn: '', descriptionUr: '', price: 0, categoryKey: ''),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_ios, size: 14),
                            color: const Color(0xFF0D9488),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.workerProfile,
                          arguments: ProfileArguments(
                            worker: w,
                            job: JobPostingArguments(descriptionEn: '', descriptionUr: '', price: 0, categoryKey: ''),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
