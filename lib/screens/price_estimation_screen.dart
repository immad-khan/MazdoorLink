import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';

class PriceEstimationScreen extends StatefulWidget {
  @override
  State<PriceEstimationScreen> createState() => _PriceEstimationScreenState();
}

class _PriceEstimationScreenState extends State<PriceEstimationScreen>
    with TickerProviderStateMixin {
  double _complexity = 2;
  double _hours = 2;
  late AnimationController _slideController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _slideController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    _cardController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _slideController.forward();
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final minPrice = (800 + (_complexity * 250) + (_hours * 300)).round();
    final maxPrice = (minPrice * 1.25).round();
    final avgPrice = ((minPrice + maxPrice) / 2).round();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('ai_price_tool'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            SlideTransition(
              position: Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero)
                  .animate(_slideController),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
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
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.price_check,
                              color: Theme.of(context).primaryColor, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.t('ai_price_tool'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkerText,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Get fair market price range',
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 28),

            // Complexity Slider
            Text(
              t.t('job_complexity'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkerText,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.spacer),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${_complexity.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_complexity.toStringAsFixed(0)}/5',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                          elevation: 2,
                        ),
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: AppTheme.spacer,
                        thumbColor: Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: _complexity,
                        onChanged: (v) => setState(() => _complexity = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Hours Slider
            Text(
              t.t('estimated_hours'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkerText,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.spacer),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_hours.toStringAsFixed(0)} hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                          elevation: 2,
                        ),
                        activeTrackColor: Color(0xFFF59E0B),
                        inactiveTrackColor: AppTheme.spacer,
                        thumbColor: Color(0xFFF59E0B),
                      ),
                      child: Slider(
                        min: 1,
                        max: 8,
                        divisions: 7,
                        value: _hours,
                        onChanged: (v) => setState(() => _hours = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Price Range Card - Animated
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1)
                  .animate(CurvedAnimation(
                    parent: _cardController,
                    curve: Curves.easeOut,
                  )),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.08),
                      Color(0xFFF59E0B).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      t.t('suggested_fair_range'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Minimum',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.deactivatedText,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Rs $minPrice',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: AppTheme.spacer,
                        ),
                        Column(
                          children: [
                            Text(
                              'Average',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.deactivatedText,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Rs $avgPrice',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: AppTheme.spacer,
                        ),
                        Column(
                          children: [
                            Text(
                              'Maximum',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.deactivatedText,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Rs $maxPrice',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Based on Pakistan market rates for ${_complexity.toStringAsFixed(0)}-level complexity work',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Price range saved! Average: Rs $avgPrice',
                      ),
                      backgroundColor: Color(0xFF059669),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Use This Price',
                  style: TextStyle(
                    fontSize: 16,
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
    );
  }
}
