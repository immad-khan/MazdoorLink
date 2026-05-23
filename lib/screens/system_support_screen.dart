import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'booking_history_screen.dart';
import 'notification_preferences_screen.dart';
import 'profile_management_screen.dart';
import 'auth_login_screen.dart';
import 'translation_toggle_screen.dart';
import 'call_interaction_screen.dart';

class SystemSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.lock),
            title: Text(AppLocalizations.of(context).t('auth_login')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuthLoginScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text(AppLocalizations.of(context).t('booking_history')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingHistoryScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text(AppLocalizations.of(context).t('notification_preferences')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationPreferencesScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text(AppLocalizations.of(context).t('profile_management')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileManagementScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.translate),
            title: Text(AppLocalizations.of(context).t('translation_toggle')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TranslationToggleScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.call),
            title: Text(AppLocalizations.of(context).t('call_interaction')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CallInteractionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
