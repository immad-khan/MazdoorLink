import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';

class JobPostingScreen extends StatefulWidget {
  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  String _category = 'Plumber';
  bool _urgent = false;
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _slideController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context);

    // Show success message
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFFCD34D),
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Job Posted Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your ${t.t(_category)} job is now live',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightText,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final t = AppLocalizations.of(context);

    if (_currentStep == 0) {
      return SlideTransition(
        position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
            .animate(_slideController),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkerText,
              ),
            ),
            SizedBox(height: 16),
            // Job Title
            Text(
              t.t('job_title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Pipe leak repair',
                hintStyle: TextStyle(color: AppTheme.deactivatedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.t('required') : null,
            ),
            SizedBox(height: 16),

            // Category
            Text(
              t.t('category'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.spacer),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: ['Plumber', 'electrician', 'carpentry']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Row(
                            children: [
                              Icon(
                                e == 'Plumber'
                                    ? IconHelper.Plumber
                                    : e == 'electrician'
                                        ? IconHelper.electrician
                                        : IconHelper.carpentry,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 8),
                              Text(t.t(e)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? _category),
              ),
            ),
            SizedBox(height: 16),

            // Description
            Text(
              t.t('describe_requirement'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what needs to be done',
                hintStyle: TextStyle(color: AppTheme.deactivatedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.t('required') : null,
            ),
            SizedBox(height: 16),

            // Urgent Switch
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _urgent
                    ? Color(0xFFFECDD3)
                    : AppTheme.notWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _urgent ? Color(0xFFF87171) : AppTheme.spacer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: _urgent ? Color(0xFFDC2626) : AppTheme.deactivatedText,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('urgent_request'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkerText,
                          ),
                        ),
                        Text(
                          'Get faster matches (25% extra)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _urgent,
                    onChanged: (v) => setState(() => _urgent = v),
                    activeThumbColor: Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return SlideTransition(
        position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
            .animate(_slideController),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location & Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkerText,
              ),
            ),
            SizedBox(height: 16),

            // Location
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: Icon(IconHelper.location, size: 18),
                hintText: 'Gulberg III, Lahore',
                hintStyle: TextStyle(color: AppTheme.deactivatedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.t('required') : null,
            ),
            SizedBox(height: 16),

            // Budget
            Text(
              'Budget (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: Icon(IconHelper.rupee, size: 18),
                prefixText: 'Rs ',
                hintText: 'Enter budget or leave blank for AI estimation',
                hintStyle: TextStyle(color: AppTheme.deactivatedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.spacer),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 20),

            // Info Box
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Workers will see your job and send offers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('job_posting_interface'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _currentStep == 0
                          ? Theme.of(context).primaryColor
                          : Color(0xFF059669),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep == 1
                          ? Theme.of(context).primaryColor
                          : AppTheme.spacer,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _currentStep == 1
                          ? Theme.of(context).primaryColor
                          : AppTheme.notWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _currentStep == 1
                            ? Colors.transparent
                            : AppTheme.spacer,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: _currentStep == 1
                              ? Colors.white
                              : AppTheme.deactivatedText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28),

              // Content
              FadeTransition(
                opacity: _fadeController,
                child: _buildStepContent(),
              ),
              SizedBox(height: 32),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentStep == 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep = 0);
                          _slideController.forward(from: 0);
                          _fadeController.forward(from: 0);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppTheme.spacer,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep == 1) SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 0) {
                          if (_titleController.text.isEmpty ||
                              _detailsController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please fill in all required fields'),
                              ),
                            );
                            return;
                          }
                          setState(() => _currentStep = 1);
                          _slideController.forward(from: 0);
                          _fadeController.forward(from: 0);
                        } else {
                          _submit();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == 0 ? 'Next' : 'Post Job',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
