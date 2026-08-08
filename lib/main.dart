import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'app_theme.dart';
import 'screens/mazdoor_flow.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Failed to load .env file: $e');
  }
  await Firebase.initializeApp();
  print('App starting...');
  NotificationService.onOpen = _openConversationFromNotification;
  NotificationService.onForeground = _showForegroundNotification;
  await NotificationService.initialize();
  runApp(ServiceApp());
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
  @override
  _ServiceAppState createState() => _ServiceAppState();
}

class _ServiceAppState extends State<ServiceApp> {
  final AppController _controller = AppController();

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
          initialRoute: AppRoutes.welcome,
        ),
      ),
    );
  }
}
