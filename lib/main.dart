import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'app_theme.dart';
import 'screens/mazdoor_flow.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthResult {
  final String route;
  final UserRole? role;
  const _AuthResult(this.route, this.role);
}

Future<_AuthResult> _resolveAuth() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return _AuthResult(AppRoutes.welcome, null);

  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return _AuthResult(AppRoutes.welcome, null);
    final data = doc.data();
    if (data == null) return _AuthResult(AppRoutes.welcome, null);

    final role = data['role']?.toString();
    final status = data['status']?.toString();

    UserRole? userRole;
    String route;

    if (role == 'admin') {
      userRole = UserRole.admin;
      route = AppRoutes.adminDashboard;
    } else if (role == 'worker') {
      userRole = UserRole.worker;
      if (status == 'pending') {
        route = AppRoutes.workerOnboarding;
      } else {
        final setupComplete = data['setupComplete'] as bool? ?? false;
        if (status == 'approved' && !setupComplete) {
          route = AppRoutes.workerServicesSetup;
        } else {
          route = AppRoutes.workerDashboard;
        }
      }
    } else {
      userRole = UserRole.customer;
      route = AppRoutes.customerHome;
    }

    return _AuthResult(route, userRole);
  } catch (e) {
    return _AuthResult(AppRoutes.welcome, null);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Failed to load .env file: $e');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  print('App starting...');
  try {
    NotificationService.onOpen = _openConversationFromNotification;
    NotificationService.onForeground = _showForegroundNotification;
    await NotificationService.initialize();
  } catch (e) {
    print('Failed to initialize Notifications: $e');
  }

  final authResult = await _resolveAuth();

  runApp(ServiceApp(initialRoute: authResult.route, initialUserRole: authResult.role));
}

void _openConversationFromNotification(Map<String, String> data) {
  final conversationId = data['conversationId'] ?? '';
  if (conversationId.isEmpty) return;
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushNamed(
    AppRoutes.sharedConversation,
    arguments: ConversationArguments(
      conversationId: conversationId,
      otherName: data['otherName'] ?? 'Worker',
      otherImage: data['otherImage'],
    ),
  );
}

void _showForegroundNotification(Map<String, String> data) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  final otherName = data['otherName'] ?? 'New message';
  final body = data['body'] ?? '';
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      content: Text(
        body.isEmpty ? otherName : '$otherName: $body',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () => _openConversationFromNotification(data),
      ),
    ),
  );
}

class ServiceApp extends StatefulWidget {
  final String initialRoute;
  final UserRole? initialUserRole;

  const ServiceApp({super.key, required this.initialRoute, this.initialUserRole});

  @override
  _ServiceAppState createState() => _ServiceAppState();
}

class _ServiceAppState extends State<ServiceApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    if (widget.initialUserRole != null) {
      _controller.selectRole(widget.initialUserRole!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building ServiceApp...');
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorKey: rootNavigatorKey,
          title: 'MazdoorLink',
          locale: _controller.locale,
          debugShowCheckedModeBanner: false,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            platform: TargetPlatform.android,
            primaryColor: const Color(0xFF0D9488),
            scaffoldBackgroundColor: AppTheme.notWhite,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D9488),
              secondary: Color(0xFFF59E0B),
              surface: AppTheme.white,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {TargetPlatform.android: ZoomPageTransitionsBuilder()},
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppTheme.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
              titleTextStyle: TextStyle(
                color: AppTheme.nearlyBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontName,
              ),
            ),
            textTheme: AppTheme.textTheme,
            cardTheme: CardThemeData(
              color: AppTheme.white,
              elevation: 2,
              shadowColor: AppTheme.grey.withValues(alpha:0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontName,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppTheme.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.chipBackground),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF0D9488), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          onGenerateRoute: buildRoute,
          initialRoute: widget.initialRoute,
        ),
      ),
    );
  }
}
