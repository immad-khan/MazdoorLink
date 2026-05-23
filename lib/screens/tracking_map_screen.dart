import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';

class TrackingMapScreen extends StatefulWidget {
  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen>
    with TickerProviderStateMixin {
  int _currentStatus = 1; // 0: Assigned, 1: On Way, 2: Arrived, 3: In Progress
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<String> _statuses = [
    'Assigned',
    'On the Way',
    'Arrived',
    'In Progress',
  ];

  final List<String> _statusDescriptions = [
    'Worker assigned',
    'Worker on the way',
    'Worker arrived at location',
    'Service in progress',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(duration: Duration(milliseconds: 1500), vsync: this)
          ..repeat();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _advanceStatus() {
    setState(() {
      _currentStatus = (_currentStatus + 1) % _statuses.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Status: ${_statuses[_currentStatus]}'),
            ),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(int index) {
    if (index < _currentStatus) return Color(0xFF059669);
    if (index == _currentStatus) return Color(0xFFF59E0B);
    return AppTheme.deactivatedText;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('tracking_map'),
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
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Placeholder
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.notWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.spacer),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Map background
                    Center(
                      child: Icon(
                        Icons.map,
                        size: 80,
                        color: AppTheme.deactivatedText,
                      ),
                    ),
                    // Worker marker
                    Positioned(
                      top: 80,
                      left: 100,
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.4)
                                .animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    // Worker pin
                    Positioned(
                      top: 90,
                      left: 115,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    // Destination marker
                    Positioned(
                      bottom: 60,
                      right: 60,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Current Status Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(_currentStatus).withOpacity(0.1),
                      _getStatusColor(_currentStatus).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(_currentStatus).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: _getStatusColor(_currentStatus),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _statuses[_currentStatus],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_currentStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _statusDescriptions[_currentStatus],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Status Timeline
              Text(
                'Service Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.spacer),
                ),
                child: Column(
                  children: List.generate(
                    _statuses.length,
                    (index) => Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getStatusColor(index)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(index),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: index < _currentStatus
                                    ? Icon(Icons.check,
                                        color: _getStatusColor(index),
                                        size: 20)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: _getStatusColor(index),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statuses[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkerText,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    _statusDescriptions[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.deactivatedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (index < _statuses.length - 1)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Container(
                              width: 2,
                              height: 24,
                              color: _getStatusColor(index + 1)
                                  .withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Worker Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.spacer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Provider',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(Icons.person,
                              color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ahmed Hassan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkerText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 14, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.8 • 156 reviews',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling worker...'),
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                            icon: Icon(Icons.phone, size: 18),
                            label: Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening chat...'),
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                            icon: Icon(Icons.message,
                                size: 18, color: Theme.of(context).primaryColor),
                            label: Text(
                              'Chat',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Advance Status Button (for demo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _advanceStatus,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Advance Status (Demo)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
