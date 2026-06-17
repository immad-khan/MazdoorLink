import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';

class CustomerHome extends StatefulWidget {
  @override
  _CustomerHomeState createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 100)),
        vsync: this,
      ),
    );
    Future.delayed(Duration(milliseconds: 100), () {
      for (var controller in _controllers) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedCard(
    int index,
    IconData icon,
    String label,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _controllers[index], curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _controllers[index],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.spacer, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                  ),
                  SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header with location
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha:0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha:0.2),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).t('current_location'),
                        style: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Gulberg III, Lahore',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha:0.3)),
                    ),
                    child: Center(
                      child: Text('AR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.deactivatedText, size: 20),
                    hintText: AppLocalizations.of(context).t('search_hint'),
                    hintStyle: TextStyle(color: AppTheme.deactivatedText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Categories Section
        Text(
          AppLocalizations.of(context).t('categories'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildAnimatedCard(0, Icons.home_repair_service, 'Plumber', Color(0xFF3B82F6), () => Navigator.pushNamed(context, '/customer/job-posting')),
            _buildAnimatedCard(1, Icons.bolt, 'Electrician', Color(0xFFFCD34D), () => Navigator.pushNamed(context, '/customer/job-posting')),
            _buildAnimatedCard(2, Icons.handyman, 'Carpentry', Color(0xFF8B5A3C), () => Navigator.pushNamed(context, '/customer/job-posting')),
            _buildAnimatedCard(3, Icons.cleaning_services, 'Cleaning', Color(0xFF06B6D4), () => Navigator.pushNamed(context, '/customer/job-posting')),
            _buildAnimatedCard(4, Icons.format_paint, 'Painting', Color(0xFFEC4899), () => Navigator.pushNamed(context, '/customer/job-posting')),
            _buildAnimatedCard(5, Icons.ac_unit, 'AC Repair', Color(0xFF10B981), () => Navigator.pushNamed(context, '/customer/job-posting')),
          ],
        ),
        SizedBox(height: 24),

        // Featured Workers Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).t('top_workers'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('See all', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 12),

        // Features Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.spacer, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t('quick_actions'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkerText),
              ),
              SizedBox(height: 16),
              _featureButton(Icons.request_page, AppLocalizations.of(context).t('job_posting_interface'), () => Navigator.pushNamed(context, '/customer/job-posting')),
              Divider(height: 12, color: AppTheme.notWhite),
              _featureButton(Icons.verified_user, AppLocalizations.of(context).t('worker_profile_view'), () => Navigator.pushNamed(context, '/customer/worker-profile')),
              Divider(height: 12, color: AppTheme.notWhite),
              _featureButton(Icons.favorite, Localizations.localeOf(context).languageCode == 'ur' ? 'پسندیدہ ورکرز' : 'Favorite Workers', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'ur' ? 'آپ کے 2 پسندیدہ ورکرز ہیں' : 'You have 2 Favorite Workers')),
                );
              }),
              Divider(height: 12, color: AppTheme.notWhite),
              _featureButton(Icons.price_check, AppLocalizations.of(context).t('ai_price_tool'), () => Navigator.pushNamed(context, '/shared/price-estimation')),
              Divider(height: 12, color: AppTheme.notWhite),
              _featureButton(Icons.map, AppLocalizations.of(context).t('tracking_map'), () => Navigator.pushNamed(context, '/customer/tracking')),
              Divider(height: 12, color: AppTheme.notWhite),
              _featureButton(Icons.star, AppLocalizations.of(context).t('rating_review'), () => Navigator.pushNamed(context, '/customer/rating')),
            ],
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _featureButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              SizedBox(width: 16),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, color: AppTheme.darkText, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFC4B5FD)),
            ],
          ),
        ),
      ),
    );
  }
}
