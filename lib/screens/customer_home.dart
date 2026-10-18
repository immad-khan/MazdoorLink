import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../services/workers_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationService.instance.ensureLocationReady(context);
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

  void _showCategoryBlockedDialog(String categoryName, CustomerActiveJobInfo activeJob) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu ? '$categoryName کا کام جاری ہے' : '$categoryName In Progress',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isUrdu
              ? 'آپ کا $categoryName کا کام کاریگر (${activeJob.workerName}) کے ساتھ پہلے سے جاری ہے۔ جب تک یہ کام مکمل نہیں ہو جاتا، آپ نیا کام شروع نہیں کر سکتے۔'
              : 'You already have an active $categoryName job with ${activeJob.workerName}. Until this job is completed, you cannot start a new $categoryName request.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'سمجھ گیا' : 'OK'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/customer/tracking');
            },
            child: Text(isUrdu ? 'ٹریک کریں' : 'Track Job', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(
    int index,
    IconData icon,
    String label,
    Color bgColor,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFFFFFBEB) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLocked ? const Color(0xFFF59E0B) : AppTheme.spacer,
                  width: isLocked ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isLocked ? const Color(0xFFFEF3C7) : bgColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: isLocked ? const Color(0xFFD97706) : Theme.of(context).primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isLocked ? FontWeight.bold : FontWeight.w600,
                            color: isLocked ? const Color(0xFF92400E) : AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 9, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Active',
                              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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
                  ValueListenableBuilder<AppLocation>(
                    valueListenable: LocationService.instance.currentLocationNotifier,
                    builder: (context, loc, _) {
                      return InkWell(
                        onTap: () => LocationService.instance.showAreaPickerDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).t('current_location'),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ISB / RWP',
                                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  loc.shortDisplayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
        StreamBuilder<Map<String, CustomerActiveJobInfo>>(
          stream: streamCustomerActiveCategoriesMap(FirebaseAuth.instance.currentUser?.uid ?? ''),
          builder: (context, snapshot) {
            final activeMap = snapshot.data ?? {};
            final activePlumber = activeMap['plumber'];
            final activeElectrician = activeMap['electrician'];
            final activeCarpenter = activeMap['carpentry'] ?? activeMap['carpenter'];
            final activeCleaner = activeMap['cleaning'] ?? activeMap['cleaner'];
            final activePainter = activeMap['painting'] ?? activeMap['painter'];
            final activeAc = activeMap['ac repair'] ?? activeMap['ac'];

            return GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAnimatedCard(
                  0,
                  Icons.home_repair_service,
                  'Plumber',
                  const Color(0xFF3B82F6),
                  () {
                    if (activePlumber != null) {
                      _showCategoryBlockedDialog('Plumber', activePlumber);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activePlumber != null,
                ),
                _buildAnimatedCard(
                  1,
                  Icons.bolt,
                  'Electrician',
                  const Color(0xFFFCD34D),
                  () {
                    if (activeElectrician != null) {
                      _showCategoryBlockedDialog('Electrician', activeElectrician);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activeElectrician != null,
                ),
                _buildAnimatedCard(
                  2,
                  Icons.handyman,
                  'Carpentry',
                  const Color(0xFF8B5A3C),
                  () {
                    if (activeCarpenter != null) {
                      _showCategoryBlockedDialog('Carpentry', activeCarpenter);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activeCarpenter != null,
                ),
                _buildAnimatedCard(
                  3,
                  Icons.cleaning_services,
                  'Cleaning',
                  const Color(0xFF06B6D4),
                  () {
                    if (activeCleaner != null) {
                      _showCategoryBlockedDialog('Cleaning', activeCleaner);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activeCleaner != null,
                ),
                _buildAnimatedCard(
                  4,
                  Icons.format_paint,
                  'Painting',
                  const Color(0xFFEC4899),
                  () {
                    if (activePainter != null) {
                      _showCategoryBlockedDialog('Painting', activePainter);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activePainter != null,
                ),
                _buildAnimatedCard(
                  5,
                  Icons.ac_unit,
                  'AC Repair',
                  const Color(0xFF10B981),
                  () {
                    if (activeAc != null) {
                      _showCategoryBlockedDialog('AC Repair', activeAc);
                    } else {
                      Navigator.pushNamed(context, '/customer/job-posting');
                    }
                  },
                  isLocked: activeAc != null,
                ),
              ],
            );
          },
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
