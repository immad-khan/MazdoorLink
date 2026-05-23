import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';

class WorkerHome extends StatefulWidget {
  @override
  _WorkerHomeState createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> with TickerProviderStateMixin {
  bool _online = false;
  late AnimationController _toggleController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    _cardController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _cardController.forward();
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _setOnline(bool online) {
    if (online != _online) {
      setState(() => _online = online);
      if (online) {
        _toggleController.forward();
      } else {
        _toggleController.reverse();
      }
    }
  }

  Widget _featureButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              SizedBox(width: 16),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, color: AppTheme.darkText, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.deactivatedText),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header with profile and notifications
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1506803682981-6e718a9dd3ee?w=100',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muhammad Ali',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Plumber',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Online/Offline Toggle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(_cardController),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _online ? Theme.of(context).primaryColor : AppTheme.deactivatedText,
                    _online ? Theme.of(context).primaryColor.withOpacity(0.8) : Color(0xFFC4B5FD).withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_online)
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _online ? 'You are Online' : 'You are Offline',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => _setOnline(!_online),
                        child: Container(
                          width: 56,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              AnimatedAlign(
                                alignment: _online ? Alignment.centerRight : Alignment.centerLeft,
                                duration: Duration(milliseconds: 400),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  margin: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _online ? 'You are receiving new job requests' : 'Go online to get job requests',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Quick Stats
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.spacer, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.wallet, color: Color(0xFFD97706), size: 20),
                      ),
                      SizedBox(height: 8),
                      Text('Today Earnings', style: TextStyle(color: AppTheme.lightText, fontSize: 12)),
                      SizedBox(height: 4),
                      Text('Rs. 2,500', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkerText)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.spacer, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                      ),
                      SizedBox(height: 8),
                      Text('Completed', style: TextStyle(color: AppTheme.lightText, fontSize: 12)),
                      SizedBox(height: 4),
                      Text('2 jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkerText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Features Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.spacer, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.list, color: Theme.of(context).primaryColor, size: 20),
                      SizedBox(width: 12),
                      Text('Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkerText)),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.notWhite, indent: 0),
                _featureButton(Icons.app_registration, AppLocalizations.of(context).t('onboarding'), () => Navigator.pushNamed(context, '/worker/onboarding')),
                Divider(height: 1, color: AppTheme.notWhite, indent: 16),
                _featureButton(Icons.design_services, 'Manage Services & Rates', () => Navigator.pushNamed(context, '/worker/services-setup', arguments: 0)),
                Divider(height: 1, color: AppTheme.notWhite, indent: 16),
                _featureButton(Icons.badge, AppLocalizations.of(context).t('cnic_upload'), () => Navigator.pushNamed(context, '/worker/document-upload')),
                Divider(height: 1, color: AppTheme.notWhite, indent: 16),
                _featureButton(Icons.fingerprint, AppLocalizations.of(context).t('biometric_verification'), () => Navigator.pushNamed(context, '/worker/biometric-verification')),
                Divider(height: 1, color: AppTheme.notWhite, indent: 16),
                _featureButton(Icons.mic, AppLocalizations.of(context).t('voice_navigation'), () => Navigator.pushNamed(context, '/worker/voice-navigation')),
                Divider(height: 1, color: AppTheme.notWhite, indent: 16),
                _featureButton(Icons.notifications, 'Job Alerts', () => Navigator.pushNamed(context, '/worker/job-notification')),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),
      ],
    );
  }
}
