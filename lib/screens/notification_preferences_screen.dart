import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> with TickerProviderStateMixin {
  bool _jobAlerts = true;
  bool _bookingUpdates = true;
  bool _chatMessages = true;
  bool _priceUpdates = false;
  bool _workerReviews = true;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildNotificationTile(
    String title,
    String description,
    bool value,
    IconData icon,
    Color iconColor,
    Function(bool) onChanged,
    int index,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.spacer),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkerText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Theme.of(context).primaryColor,
                inactiveThumbColor: AppTheme.deactivatedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('notification_preferences'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha:0.1),
                    Theme.of(context).primaryColor.withValues(alpha:0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha:0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_active,
                        color: Theme.of(context).primaryColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkerText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Control which notifications you receive',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Job Alerts Section
            Text(
              'Job & Service Notifications',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            _buildNotificationTile(
              t.t('pref_job_alerts'),
              'New job requests matching your profile',
              _jobAlerts,
              Icons.work,
              Color(0xFF3B82F6),
              (v) => setState(() => _jobAlerts = v),
              0,
            ),
            _buildNotificationTile(
              'Price Updates',
              'Alerts when prices change in your area',
              _priceUpdates,
              Icons.trending_up,
              Color(0xFFF59E0B),
              (v) => setState(() => _priceUpdates = v),
              1,
            ),
            SizedBox(height: 20),

            // Booking Section
            Text(
              'Booking & Status Updates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            _buildNotificationTile(
              t.t('pref_booking_updates'),
              'Booking confirmations and status changes',
              _bookingUpdates,
              Icons.calendar_today,
              Color(0xFF10B981),
              (v) => setState(() => _bookingUpdates = v),
              2,
            ),
            _buildNotificationTile(
              'Worker Reviews',
              'New reviews from customers about your work',
              _workerReviews,
              Icons.star,
              Color(0xFFEC4899),
              (v) => setState(() => _workerReviews = v),
              3,
            ),
            SizedBox(height: 20),

            // Chat & Communication
            Text(
              'Chat & Communication',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            _buildNotificationTile(
              t.t('pref_chat_messages'),
              'Messages from customers and workers',
              _chatMessages,
              Icons.chat,
              Color(0xFF8B5CF6),
              (v) => setState(() => _chatMessages = v),
              4,
            ),
            SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text(t.t('preferences_saved')),
                        ],
                      ),
                      backgroundColor: Color(0xFF059669),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );

                  Future.delayed(Duration(milliseconds: 500), () {
                    Navigator.pop(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.t('save_preferences'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Info Text
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can always change these settings later',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
