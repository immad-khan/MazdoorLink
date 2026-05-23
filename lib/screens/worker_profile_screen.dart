import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';
import 'chat_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _heroController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _heroController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          t.t('worker_profile_view'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.darkerText,
          ),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: AppTheme.darkerText, size: 24),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.darkerText),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1).animate(
                CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506803682981-6e718a9dd3ee?w=500',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(IconHelper.star,
                              color: Color(0xFFFCD34D), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Info Section
            FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Role
                    Text(
                      'Muhammad Ali',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Professional Plumber',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '124 completed jobs • 2 km away',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightText,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Verification Badges
                    Text(
                      'Verifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: VerificationBadge(
                            label: 'CNIC',
                            icon: IconHelper.verified,
                            bgColor: Color(0xFF059669),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: VerificationBadge(
                            label: 'Police',
                            icon: IconHelper.verified,
                            bgColor: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: VerificationBadge(
                            label: 'Biometric',
                            icon: IconHelper.fingerprint,
                            bgColor: Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Skills Section
                    Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Pipe Repair', 'Installation', 'Leak Detection', 'Maintenance']
                          .map((skill) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 24),

                    // Reviews Section
                    Text(
                      'Recent Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildReviewCard(
                      'Great work and on time',
                      5.0,
                      'Ahmed Hassan',
                      '3 days ago',
                    ),
                    SizedBox(height: 12),
                    _buildReviewCard(
                      'Fixed leak quickly and efficiently',
                      4.7,
                      'Fatima Khan',
                      '1 week ago',
                    ),
                    SizedBox(height: 24),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking request sent to Muhammad Ali'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Send Booking Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(IconHelper.chat,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Send Message',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
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
      ),
    );
  }

  Widget _buildReviewCard(
    String comment,
    double rating,
    String authorName,
    String timeAgo,
  ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.spacer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
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
                authorName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkerText,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.toInt()
                        ? IconHelper.star
                        : IconHelper.starOutline,
                    color: Color(0xFFFCD34D),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkText,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.deactivatedText,
            ),
          ),
        ],
      ),
    );
  }
}

// VerificationBadge widget
class VerificationBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;

  const VerificationBadge({
    Key? key,
    required this.label,
    required this.icon,
    required this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bgColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: bgColor, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ],
      ),
    );
  }
}
