import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ProfileArguments {
  final WorkerModel worker;
  final JobPostingArguments job;

  ProfileArguments({required this.worker, required this.job});
}

class SimulatorArguments {
  final WorkerModel worker;
  final JobPostingArguments job;

  SimulatorArguments({required this.worker, required this.job});
}

class TrackingArguments {
  final WorkerModel worker;
  final JobPostingArguments job;

  TrackingArguments({required this.worker, required this.job});
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
  static const recommendations = '/customer/recommendations';
  static const workerProfile = '/customer/worker-profile';
  static const tracking = '/customer/tracking';
  static const rating = '/customer/rating';
  static const workerOnboarding = '/worker/onboarding';
  static const workerCategorySelect = '/worker/category-select';
  static const workerDashboard = '/worker/dashboard';
  static const workerNotification = '/worker/job-notification';
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
  static const sharedHistory = '/shared/history';
  static const sharedSettings = '/shared/settings';
  static const customerSupport = '/customer/support';
  static const workerSupport = '/worker/support';
  static const matchingSimulator = '/customer/matching-simulator';
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
    case AppRoutes.workerNotification:
      return _page(const JobNotificationScreen(), settings);
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
      return _page(const SmartChatScreen(), settings);
    case AppRoutes.sharedHistory:
      return _page(const BookingHistoryScreen(), settings);
    case AppRoutes.sharedSettings:
      return _page(const SettingsScreen(), settings);
    case AppRoutes.customerSupport:
      return _page(const CustomerSupportScreen(), settings);
    case AppRoutes.workerSupport:
      return _page(const WorkerSupportScreen(), settings);
    case AppRoutes.matchingSimulator:
      return _page(const WorkerAcceptanceSimulatorScreen(), settings);
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
    if (val.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }
    bool hasUppercase = val.contains(RegExp(r'[A-Z]'));
    bool hasDigits = val.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (val.length < 8) {
      setState(() => _passwordError = 'Must be at least 8 characters');
    } else if (!hasUppercase) {
      setState(() => _passwordError = 'Must contain at least 1 uppercase letter');
    } else if (!hasDigits) {
      setState(() => _passwordError = 'Must contain at least 1 number');
    } else if (!hasSpecialCharacters) {
      setState(() => _passwordError = 'Must contain at least 1 special character');
    } else {
      setState(() => _passwordError = null);
    }
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
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) _idFrontImage = File(image.path);
        else _idBackImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = 'dcdhsyj86';
    const apiKey = '921185953673167';
    const apiSecret = 'P-Vro4fA8_gF9dnTcHgKnOQ-xGI';
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final strToSign = "timestamp=$timestamp$apiSecret";
    final bytes = utf8.encode(strToSign);
    final digest = sha1.convert(bytes);
    final signature = digest.toString();

    var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonMap = json.decode(responseData);
      return jsonMap['secure_url'];
    }
    return null;
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
        if (_fullNameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _password.text.isEmpty) {
          showToast('Please fill all required fields');
          return;
        }
        if (_password.text != _confirmPassword.text) {
          showToast('Passwords must match');
          return;
        }
        final role = AppScope.of(context).role;
        if (role == UserRole.worker && (_idFrontImage == null || _idBackImage == null)) {
          showToast('Please upload both front and back of your ID card');
          return;
        }

        setState(() => _isUploading = true);

        try {
          String? frontUrl;
          String? backUrl;
          if (role == UserRole.worker) {
            frontUrl = await _uploadToCloudinary(_idFrontImage!);
            backUrl = await _uploadToCloudinary(_idBackImage!);
            if (frontUrl == null || backUrl == null) {
              setState(() => _isUploading = false);
              if (mounted) showToast('Failed to upload ID images. Try again.');
              return;
            }
          }

          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _password.text,
          );
          
          await userCredential.user?.sendEmailVerification();
          
          final userData = {
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phone.text.trim(),
            'role': role == UserRole.worker ? 'worker' : 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (role == UserRole.worker) {
            userData['status'] = 'pending';
            userData['idFrontUrl'] = frontUrl!;
            userData['idBackUrl'] = backUrl!;
          }

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
          
          setState(() => _isUploading = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Account created! Please check your email to verify your account before logging in.'),
              duration: Duration(seconds: 5),
            ));
            Navigator.pushReplacementNamed(context, AppRoutes.login);
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
      if (_emailController.text.trim().isEmpty || _password.text.isEmpty) {
        showToast('Please enter your email and password');
        return;
      }
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _password.text,
        );
        
        if (!userCredential.user!.emailVerified) {
          if (mounted) {
            showToast('Please verify your email first! Check your inbox.');
          }
          return;
        }
        
        // Fetch user data from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists && mounted) {
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
          showToast(e.toString());
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
          decoration: InputDecoration(
            hintText: 'Enter your password',
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
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Enter your full name',
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
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text('+92', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '3038064241',
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
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirm your password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Password must be at least 8 characters with letters and numbers', style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 24),
          
          if (role == UserRole.worker) ...[
            const Divider(),
            const SizedBox(height: 16),
            const Text('ID Card Images (Front & Back)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(true),
                    child: Container(
                      height: 100,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: _idFrontImage != null 
                          ? Image.file(_idFrontImage!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 100,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: _idBackImage != null
                          ? Image.file(_idBackImage!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                    ),
                  ),
                ),
              ],
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
          for (final w in workers)
            ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(w.image)),
              title: Text(w.name),
              subtitle: Text('⭐ ${w.rating}  ${w.category}  • ${w.distanceKm} km'),
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
                      AppRoutes.recommendations,
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



class WorkerRecommendationsScreen extends StatelessWidget {
  const WorkerRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final isUrdu = AppScope.of(context).isUrdu;

    List<IssueItem> selectedIssues = [];
    String categoryKey = 'electrician';
    String paymentMethod = 'Cash';

    if (rawArgs is RecommendationArguments) {
      selectedIssues = rawArgs.selectedIssues;
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
    } else if (rawArgs is JobPostingArguments) {
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
      selectedIssues = [
        IssueItem(
          titleEn: rawArgs.descriptionEn,
          titleUr: rawArgs.descriptionUr,
          price: rawArgs.price,
          icon: Icons.build,
        ),
      ];
    }

    final List<WorkerModel> matchedWorkers = [];
    for (int i = 0; i < selectedIssues.length; i++) {
      final issue = selectedIssues[i];
      final base = workers[i % workers.length];
      final double workerPrice = issue.price + (i * 50);

      matchedWorkers.add(WorkerModel(
        name: base.name,
        category: categoryKey == 'Plumber' ? 'Plumber' : 'Electrician',
        rating: base.rating,
        reviews: base.reviews,
        distanceKm: (i + 1) * 1.5,
        price: 'Rs. ${workerPrice.toStringAsFixed(0)}',
        image: base.image,
        skillsEn: [issue.titleEn, ...base.skillsEn],
        skillsUr: [issue.titleUr, ...base.skillsUr],
      ));
    }

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Available Workers', 'دستیاب ورکرز'),
      child: ListView(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Text(
                          isUrdu
                              ? '📌 ${selectedIssues[i].titleUr}'
                              : '📌 ${selectedIssues[i].titleEn}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              matchedWorkers[i].image,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.person)),
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
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 15),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${matchedWorkers[i].rating} • ${matchedWorkers[i].reviews} ${isUrdu ? 'جائزے' : 'reviews'}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 3),
                                    Text(
                                      isUrdu ? '${matchedWorkers[i].distanceKm} کلومیٹر دور' : '${matchedWorkers[i].distanceKm} km away',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isUrdu ? 'ورکر کی مقرر کردہ قیمت:' : 'Worker\'s Preset Price:',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Text(
                              matchedWorkers[i].price,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.workerProfile,
                              arguments: ProfileArguments(
                                worker: matchedWorkers[i],
                                job: JobPostingArguments(
                                  descriptionEn: selectedIssues[i].titleEn,
                                  descriptionUr: selectedIssues[i].titleUr,
                                  price: 0,
                                  categoryKey: categoryKey,
                                  paymentMethod: paymentMethod,
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

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ProfileArguments?;
    final worker = args?.worker ?? workers.first;
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    return MzScaffold(
      showBottomNav: false,
      background: Colors.white,
      child: Stack(
        children: [
          ListView(
            children: [
              Stack(
                children: [
                  Image.network(worker.image, height: 260, width: double.infinity, fit: BoxFit.cover),
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
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(bilingual(context, 'Added to Favorites! You will ping this worker first next time.', 'پسندیدہ میں شامل کر دیا گیا! اگلی بار یہ ورکر کو سب سے پہلے درخواست دی جائے گی'))),
                          );
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
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.sharedChat),
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
                           Navigator.pushNamed(
                             context,
                             AppRoutes.matchingSimulator,
                             arguments: SimulatorArguments(
                               worker: worker,
                               job: args?.job ?? JobPostingArguments(
                                 descriptionEn: 'Scheduled Service',
                                 descriptionUr: 'شیڈولڈ سروس',
                                 price: offerPrice,
                                 categoryKey: worker.category.toLowerCase(),
                               ),
                             ),
                           );
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
                    onPressed: () {
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
                      Navigator.pushNamed(
                        context,
                        AppRoutes.matchingSimulator,
                        arguments: SimulatorArguments(
                          worker: worker,
                          job: args?.job ?? JobPostingArguments(
                            descriptionEn: 'Service',
                            descriptionUr: 'سروس',
                            price: offerPrice,
                            categoryKey: worker.category.toLowerCase(),
                          ),
                        ),
                      );
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
  int _trackingState = 0; // 0: tracking, 1: arrived, 2: completed?

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() async {
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) setState(() => _trackingState = 1);
    
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) setState(() => _trackingState = 2);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final worker = args?.worker ?? workers.first;
    final job = args?.job;

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Service Tracking', 'سروس ٹریکنگ'),
      child: Stack(
        children: [
          Container(
            color: const Color(0xFFE5E3DF),
            child: CustomPaint(
              size: Size.infinite,
              painter: _MapPainter(),
            ),
          ),
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          showToast('SOS Triggered!');
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
                      '${bilingual(context, 'PIN', 'پِن')}: 4921',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
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
                          _trackingState == 0 
                              ? bilingual(context, 'Arriving in 12 min', '12 منٹ میں پہنچ رہا ہے')
                              : _trackingState == 1 
                                  ? bilingual(context, 'Worker arrived', 'ورکر پہنچ گیا')
                                  : bilingual(context, 'Worker claims job is completed', 'ورکر کا دعویٰ ہے کہ کام مکمل ہو گیا'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.explore),
                    ],
                  ),
                  if (_trackingState == 0) Text(bilingual(context, '2.5 km away', '2.5 کلومیٹر دور')),
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
                        IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.sharedChat), icon: const Icon(Icons.chat)),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling worker...')),
                            );
                          }, 
                          icon: const Icon(Icons.call, color: Colors.green)
                        ),
                      ],
                    ),
                  ),
                  if (_trackingState == 2) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () { 
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.8)..strokeWidth = 8;
    for (var i = 0.0; i < size.height; i += 90) {
      canvas.drawLine(Offset(0, i + 10), Offset(size.width, i + 40), p);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(100, 130)
      ..quadraticBezierTo(170, 170, 190, 220)
      ..quadraticBezierTo(210, 240, 250, 260);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    review.dispose();
    super.dispose();
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
    return ListView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.task_alt, color: Color(0xFF059669), size: 64),
        const SizedBox(height: 16),
        Text(bilingual(context, 'Job Completed!', 'کام مکمل ہو گیا!'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _BillRow('Service Fee', 'Rs. 1,000'),
                Divider(),
                _BillRow('Total Paid', 'Rs. 1,000', bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            final args = ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
            final paymentMethod = args?.job?.paymentMethod ?? 'Cash';
            if (paymentMethod == 'Cash') {
              setState(() => _step = PostJobStep.workerConfirmationWaiting);
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted && _step == PostJobStep.workerConfirmationWaiting) {
                  setState(() => _step = PostJobStep.paymentSuccessTick);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _step = PostJobStep.ratingForm);
                  });
                }
              });
            } else {
              _selectedProvider = paymentMethod;
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
          controller: _claimDesc,
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
          onPressed: () {
            showToast(bilingual(context, 'Complaint Submitted', 'شکایت جمع کر دی گئی'));
            setState(() => _step = PostJobStep.ratingForm);
          },
          child: Text(bilingual(context, 'Submit Complaint', 'شکایت جمع کریں')),
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
    return Center(
      key: const ValueKey('tickSuccess'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(bilingual(context, 'Payment Successful!', 'ادائیگی کامیاب!'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 30),
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
          onPressed: () {
            setState(() => _step = PostJobStep.workerConfirmationWaiting);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _step = PostJobStep.paymentSuccessTick);
            });
          },
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
        CircleAvatar(radius: 32, backgroundImage: NetworkImage(workers.first.image)),
        const SizedBox(height: 10),
        Text(bilingual(context, 'How was Muhammad Ali?', 'محمد علی کی سروس کیسی تھی؟'), textAlign: TextAlign.center),
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
      'subtitle': 'Wiring, fittings, panels & electrician repairs',
      'icon': Icons.electrical_services,
      'color': Color(0xFFF59E0B),
    },
  ];

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category to continue')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'category': _selected,
        });
      }
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.workerDashboard);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              const Text(
                'What is your specialty?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the category that best describes your profession. This will show you relevant jobs.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
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
                      : const Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
  bool _isEditingPrice = false;
  double? _negotiatedPrice;
  late TextEditingController _negotiatePriceController;

  @override
  void initState() {
    super.initState();
    _negotiatePriceController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    return MzScaffold(
      showBottomNav: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundImage: NetworkImage(workers.first.image)),
            title: Text(
              isUrdu ? 'محمد علی' : 'Muhammad Ali',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(isUrdu ? 'پلمبر' : 'Plumber'),
            trailing: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.workerNotification),
            ),
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
          if (online)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              builder: (_, value, child) => Transform.translate(offset: Offset(0, 12 * (1 - value)), child: Opacity(opacity: value, child: child)),
              child: Card(
                shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF0D9488), width: 2), borderRadius: BorderRadius.circular(12)),
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
                      Text(isUrdu ? 'کچن کے سنک کی لیکیج' : 'Kitchen sink leakage'),
                      Text(isUrdu ? '📍 گلبرگ 3 (2.5 کلومیٹر)' : '📍 Gulberg III (2.5 km)'),
                      const SizedBox(height: 4),
                      Text(
                        isUrdu ? 'ادائیگی بذریعہ: کیش' : 'Payment Method: Cash',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                      ),
                      const SizedBox(height: 8),
                      
                      // Negotiation / Price display area
                      if (_isEditingPrice) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _negotiatePriceController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: isUrdu ? 'پیشکش قیمت' : 'Offer Price (Rs.)',
                                  prefixIcon: Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: const Text('PKR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final enteredPrice = double.tryParse(_negotiatePriceController.text.trim());
                                if (enteredPrice != null && enteredPrice > 0) {
                                  setState(() {
                                    _negotiatedPrice = enteredPrice;
                                    _isEditingPrice = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isUrdu 
                                          ? 'پیشکش روپے ${enteredPrice.toStringAsFixed(0)} بھیج دی گئی ہے!' 
                                          : 'Negotiation offer of Rs. ${enteredPrice.toStringAsFixed(0)} sent!'),
                                      backgroundColor: const Color(0xFF0D9488),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(isUrdu ? 'بھیجیں' : 'Send'),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingPrice = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _negotiatedPrice != null
                                  ? 'Rs. ${_negotiatedPrice!.toStringAsFixed(0)}'
                                  : 'Rs. 1,000',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            if (_negotiatedPrice != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUrdu ? 'باہمی پیشکش بھیج دی گئی' : 'Offer Sent',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      
                      // Action buttons row
                      if (!_isEditingPrice)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _negotiatedPrice = null;
                                  });
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
                                      content: Text(isUrdu ? 'کیا آپ اس کام کو قبول کرنا چاہتے ہیں؟' : 'Are you sure you want to accept this job?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(isUrdu ? 'نہیں' : 'No', style: const TextStyle(color: Colors.red)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => WorkerTrackingScreen(
                                                jobPrice: _negotiatedPrice ?? 1000.0,
                                              ),
                                            ));
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
            )
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

class JobNotificationScreen extends StatelessWidget {
  const JobNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final price = ModalRoute.of(context)?.settings.arguments as double? ?? 1000.0;

    return MzScaffold(
      showBottomNav: false,
      background: Colors.grey.shade900,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=1200',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              builder: (_, value, child) => Transform.translate(offset: Offset(0, 30 * (1 - value)), child: Opacity(opacity: value, child: child)),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ نیا کام!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('گاہک آپ کا انتظار کر رہا ہے'),
                      const SizedBox(height: 8),
                      const Text('کچن کے سنک کی لیکیج'),
                      const Text('📍 مکان 42، سیکٹر F-8/4'),
                      const Text('🕐 ابھی'),
                      const SizedBox(height: 4),
                      const Text(
                        'Payment Method: Cash',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                      ),
                      const SizedBox(height: 8),
                      Text('Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.workerDashboard),
                              child: const Text('رد'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.sharedChat),
                              icon: const Icon(Icons.explore),
                              label: const Text('قبول کریں'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('ایڈمن نوٹس (جرمانہ)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('ایڈمن نے پچھلے کام کی شکایت پر 10% کٹوتی کی ہے۔', style: TextStyle(color: Colors.red, fontSize: 13)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.sharedChat),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.red),
                                label: const Text('ایڈمن سے بات کریں', style: TextStyle(color: Colors.red, fontSize: 12)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              ),
                            )
                          ],
                        )
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
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
      child: ListView(
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
                  isUrdu ? 'اس ہفتے کی کمائی' : 'Earnings this week',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(isUrdu ? '12,500 روپے' : 'Rs. 12,500', style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(isUrdu ? 'ہفتہ' : 'Week'),
                      selected: weekly,
                      onSelected: (_) => setState(() => weekly = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(isUrdu ? 'مہینہ' : 'Month'),
                      selected: !weekly,
                      onSelected: (_) => setState(() => weekly = false),
                    ),
                  ],
                )
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
                    value: isUrdu ? '15 کام' : '15 jobs',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ColorStatCard(
                    color: const Color(0xFFDBEAFE),
                    label: isUrdu ? 'نکلوائی' : 'Withdrawn',
                    value: isUrdu ? '8,000 روپے' : 'Rs. 8,000',
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
          ListTile(
            leading: const Icon(Icons.south_west, color: Colors.green),
            title: Text(isUrdu ? 'کچن پلمبنگ' : 'Kitchen Plumber'),
            subtitle: Text('12 May, 2:30 PM • Adnan Ali (PKR 1000 - PKR 0 Penalty)', style: const TextStyle(fontSize: 12)),
            trailing: const Text('+1,000', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            title: Text(isUrdu ? 'الیکٹریکل وائرنگ' : 'Electrician Wiring'),
            subtitle: Text('10 May, 4:00 PM • Raza (10% Damage Penalty)', style: const TextStyle(fontSize: 12)),
            trailing: const Text('+4,500', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.north_east, color: Colors.red),
            title: Text(isUrdu ? 'نکالے' : 'Withdrawn'),
            subtitle: Text('10 May, 8:00 AM • EasyPaisa Transfer', style: const TextStyle(fontSize: 12)),
            trailing: const Text('-5,000', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.south_west, color: Colors.green),
            title: Text(isUrdu ? 'موٹر مرمت' : 'Motor Repair'),
            subtitle: Text('08 May, 1:15 PM • Usman (PKR 1500)', style: const TextStyle(fontSize: 12)),
            trailing: const Text('+1,500', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final list = jobs.where((e) => activeTab ? e.status == 'pending' : e.status == 'completed').toList();

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
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final item in list)
                  Card(
                    child: InkWell(
                      onTap: () {
                        if (activeTab) {
                          Navigator.pushNamed(context, AppRoutes.tracking);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Job Details opened')),
                          );
                        }
                      },
                      child: ListTile(
                        leading: Icon(item.status == 'completed' ? Icons.check_circle : Icons.schedule, color: item.status == 'completed' ? Colors.green : Colors.amber.shade700),
                        title: Text(isUrdu ? item.titleUr : item.titleEn),
                        subtitle: Text('${item.time} • ${item.distance}'),
                        trailing: Text(item.price, style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
                      ),
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
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(isWorker ? workers.first.image : workers[1].image)),
            title: Text(isWorker ? 'Muhammad Ali' : 'Ahmad Raza'),
            subtitle: const Text('+92 300 1234567'),
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
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(bilingual(context, 'Switch Role', 'کردار تبدیل کریں')),
                  content: Text(bilingual(
                    context,
                    'Would you like to switch to ${isWorker ? 'customer' : 'worker'} mode?',
                    'کیا آپ ${isWorker ? 'گاہک' : 'ورکر'} موڈ میں تبدیل کرنا چاہتے ہیں؟',
                  )),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(bilingual(context, 'Cancel', 'منسوخ')),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        c.selectRole(isWorker ? UserRole.customer : UserRole.worker);
                        final targetRoute = isWorker ? AppRoutes.customerHome : AppRoutes.workerOnboarding;
                        Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
                      },
                      child: Text(bilingual(context, 'Switch', 'تبدیل کریں')),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              bilingual(
                context,
                'Switch to ${isWorker ? 'Customer' : 'Worker'} Mode',
                '${isWorker ? 'گاہک' : 'ورکر'} موڈ میں تبدیل کریں',
              ),
            ),
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

class WorkerAcceptanceSimulatorScreen extends StatefulWidget {
  const WorkerAcceptanceSimulatorScreen({super.key});

  @override
  State<WorkerAcceptanceSimulatorScreen> createState() => _WorkerAcceptanceSimulatorScreenState();
}

class _WorkerAcceptanceSimulatorScreenState extends State<WorkerAcceptanceSimulatorScreen> with TickerProviderStateMixin {
  int _currentState = 0; // 0: Radar scanning, 1: Worker smartphone chassis, 2: Success acceptance
  late AnimationController _radarController;
  late AnimationController _vibrateController;
  late AnimationController _successController;
  
  @override
  void initState() {
    super.initState();
    
    // Radar controller for concentric pulses
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Vibrate controller for shaking worker phone
    _vibrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();

    // Success checkmark scaling
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Auto-transition from State 0 (Radar) to State 1 (Worker Perspective) after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _currentState = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _vibrateController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onAccept(WorkerModel worker, JobPostingArguments job) {
    setState(() {
      _currentState = 2;
    });
    _successController.forward();
    
    // Auto-route to tracking screen after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.tracking,
          arguments: TrackingArguments(worker: worker, job: job),
        );
      }
    });
  }

  void _onDecline() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bilingual(
            context,
            'Offer declined by worker. Please choose another match.',
            'ورکر نے پیشکش مسترد کر دی ہے۔ براہ کرم دوسرا انتخاب کریں۔'
          ),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as SimulatorArguments?;
    final worker = args?.worker ?? workers.first;
    final job = args?.job ?? JobPostingArguments(
      descriptionEn: 'Service',
      descriptionUr: 'سروس',
      price: 1000,
      categoryKey: 'other',
    );
    
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: false,
      showBack: _currentState == 0,
      background: const Color(0xFF0F172A), // Premium Dark Slate Background
      title: _currentState == 0 
          ? bilingual(context, 'Finding Worker', 'ورکر تلاش کیا جا رہا ہے')
          : _currentState == 1 
              ? bilingual(context, 'Worker Perspective', 'ورکر کا نقطہ نظر')
              : bilingual(context, 'Match Confirmed!', 'میچ کی تصدیق ہو گئی!'),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildCurrentState(worker, job, isUrdu),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentState(WorkerModel worker, JobPostingArguments job, bool isUrdu) {
    switch (_currentState) {
      case 0:
        return _buildRadarState(worker, job);
      case 1:
        return _buildSmartphoneChassisState(worker, job, isUrdu);
      case 2:
        return _buildSuccessState(worker);
      default:
        return Container();
    }
  }

  // State 0: Customer View Radar Scan
  Widget _buildRadarState(WorkerModel worker, JobPostingArguments job) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 280,
          width: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric expanding glassmorphic pulses
              ...List.generate(3, (index) {
                final delayVal = index * 0.33;
                return AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    double progress = _radarController.value + delayVal;
                    if (progress > 1.0) progress -= 1.0;
                    return Container(
                      width: 280 * progress,
                      height: 280 * progress,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D9488).withOpacity((1.0 - progress) * 0.4),
                          width: 2,
                        ),
                        color: const Color(0xFF0D9488).withOpacity((1.0 - progress) * 0.08),
                      ),
                    );
                  },
                );
              }),
              // Customer Avatar in Center
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF0D9488), width: 3),
                ),
                child: const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.person, color: Color(0xFF2DD4BF), size: 40),
                ),
              ),
              // Floating Worker Avatar on Radar Edge
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  final angle = _radarController.value * 2 * math.pi;
                  final radius = 100.0;
                  final x = math.cos(angle) * radius;
                  final y = math.sin(angle) * radius;
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.shade500,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          worker.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Custom Pulse offer texts
        Text(
          bilingual(context, 'Sending Job Offer...', 'ملازمت کی پیشکش بھیجی جا رہی ہے...'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            '${bilingual(context, "Offered Budget:", "پیشکش بجٹ:")} ${worker.price}',
            style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          bilingual(
            context,
            'Requesting acceptance from ${worker.name}...',
            '${worker.name} سے قبولیت کی درخواست کی جا رہی ہے...'
          ),
          style: const TextStyle(color: Colors.white60, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
          ),
        ),
      ],
    );
  }

  // State 1: Simulated Worker Smartphone Chassis and Alert Modal
  Widget _buildSmartphoneChassisState(WorkerModel worker, JobPostingArguments job, bool isUrdu) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bilingual(
                      context,
                      "VIRTUAL SIMULATOR: See how the incoming job looks on the worker's smartphone!",
                      "ورچوئل سمیلیٹر: دیکھیں کہ آنے والی نوکری ورکر کے اسمارٹ فون پر کیسی لگتی ہے!"
                    ),
                    style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vibrating Smartphone Chassis Frame
        AnimatedBuilder(
          animation: _vibrateController,
          builder: (context, child) {
            // Vibration offsets (small side to side shake)
            double offsetX = 0.0;
            if (_currentState == 1) {
              offsetX = math.sin(_vibrateController.value * 2 * math.pi * 4) * 2.5;
            }
            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: child,
            );
          },
          child: Container(
            width: 320,
            height: 580,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF334155), width: 10), // Sleek metallic slate chassis
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Lockscreen gradient background with abstract pattern
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E1E38), Color(0xFF0F172A), Color(0xFF090D16)],
                      ),
                    ),
                  ),
                  // Background Grid Mesh design
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                        itemCount: 40,
                        itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.5))),
                      ),
                    ),
                  ),
                  // Upper Notch of smartphone
                  Positioned(
                    top: 0,
                    left: 110,
                    right: 110,
                    child: Container(
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF334155),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(width: 30, height: 3, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(2))),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
                  // Smartphone status bar elements
                  Positioned(
                    top: 6,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('12:00', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.signal_cellular_4_bar, color: Colors.white70, size: 10),
                            SizedBox(width: 4),
                            Icon(Icons.wifi, color: Colors.white70, size: 10),
                            SizedBox(width: 4),
                            Icon(Icons.battery_std, color: Colors.white70, size: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Main Screen Content: Incoming Call Notification Card & Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // Spinning incoming phone glow ring
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3), width: 1),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D9488).withOpacity(0.1),
                            ),
                            child: const Icon(Icons.phone_in_talk, color: Color(0xFF2DD4BF), size: 36),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Gorgeous incoming offer card (Bilingual UI)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header Banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D9488),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.psychology, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isUrdu ? 'ملازمت کی نئی پیشکش!' : 'NEW JOB OFFER RECEIVED!',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Customer info
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Color(0xFFCCFBF1),
                                          child: Icon(Icons.person, color: Color(0xFF0D9488), size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Immad Ahmed (Customer)',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                            ),
                                            Row(
                                              children: const [
                                                Icon(Icons.star, color: Colors.amber, size: 12),
                                                SizedBox(width: 2),
                                                Text('4.9 Rating', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: Colors.black12),
                                    // Task subcategory description
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.work_outline, color: Color(0xFF0D9488), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isUrdu ? 'مطلوبہ کام' : 'Requested Work',
                                                style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                bilingual(context, job.descriptionEn, job.descriptionUr),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Budget offered
                                    Row(
                                      children: [
                                        const Icon(Icons.payments_outlined, color: Color(0xFF0D9488), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isUrdu ? 'طے شدہ بجٹ' : 'Offered Budget',
                                                style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                worker.price,
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0D9488)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Location
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: Color(0xFF0D9488), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isUrdu ? 'مقام' : 'Location',
                                                style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isUrdu ? 'گلبرگ، لاہور (2.5 کلومیٹر دور)' : 'Gulberg, Lahore (2.5 km away)',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Slide-to-Accept or Simple Glowing accept/decline action buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _onDecline,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDA4AF).withOpacity(0.2),
                                    foregroundColor: const Color(0xFFF43F5E),
                                    side: const BorderSide(color: Color(0xFFF43F5E), width: 1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    bilingual(context, 'Decline', 'مسترد کریں'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _onAccept(worker, job),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text(
                                    bilingual(context, 'Accept', 'قبول کریں'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // State 2: Success acceptance popup
  Widget _buildSuccessState(WorkerModel worker) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.12),
              border: Border.all(color: const Color(0xFF10B981), width: 4),
            ),
            child: const Icon(Icons.check, color: Color(0xFF10B981), size: 80),
          ),
          const SizedBox(height: 32),
          Text(
            bilingual(context, 'Job Offer Accepted!', 'ملازمت کی پیشکش قبول کر لی گئی!'),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${worker.name} ${bilingual(context, "is on the way to your location.", "آپ کے مقام کی طرف آ رہے ہیں۔")}',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteWorkersScreen extends StatelessWidget {
  const FavoriteWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A mock representation of favorited workers (simulating a filtered list)
    final favWorkers = workers.take(2).toList(); 

    return MzScaffold(
      showBack: true,
      title: bilingual(context, 'Favorite Workers', 'پسندیدہ ورکرز'),
      showBottomNav: false,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: favWorkers.length,
        itemBuilder: (context, i) {
          final w = favWorkers[i];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(w.image)),
            title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${w.category} • ⭐ ${w.rating}'),
            trailing: IconButton.filledTonal(
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
