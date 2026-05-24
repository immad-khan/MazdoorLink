import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';

class DocumentUploadScreen extends StatefulWidget {
  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen>
    with TickerProviderStateMixin {
  bool _cnicFrontUploaded = false;
  bool _cnicBackUploaded = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _slideController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _slideController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _simulateUpload(bool isFront) {
    setState(() {
      if (isFront) {
        _cnicFrontUploaded = true;
      } else {
        _cnicBackUploaded = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(isFront
                ? 'CNIC Front uploaded successfully'
                : 'CNIC Back uploaded successfully'),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUploadZone(String label, bool isUploaded, bool isFront) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            isFront ? 0 : 0.2,
            isFront ? 0.5 : 0.7,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _simulateUpload(isFront),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isUploaded ? Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUploaded ? Color(0xFF86EFAC) : AppTheme.spacer,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              if (isUploaded)
                BoxShadow(
                  color: Color(0xFF059669).withValues(alpha:0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? Color(0xFFD1FAE5)
                      : AppTheme.notWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle : Icons.image,
                  color: isUploaded ? Color(0xFF059669) : AppTheme.deactivatedText,
                  size: 40,
                ),
              ),
              SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                isUploaded ? 'Document verified' : 'Tap to upload',
                style: TextStyle(
                  fontSize: 14,
                  color: isUploaded ? Color(0xFF059669) : AppTheme.deactivatedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isUploaded)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF059669).withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            color: Color(0xFF059669), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bothUploaded = _cnicFrontUploaded && _cnicBackUploaded;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Document Upload',
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
                      child: Icon(Icons.card_membership,
                          color: Theme.of(context).primaryColor, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Your Identity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkerText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Upload CNIC for verification',
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

              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _cnicFrontUploaded
                                ? Color(0xFF059669)
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              _cnicFrontUploaded ? Icons.check : Icons.image,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'CNIC Front',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkerText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _cnicFrontUploaded ? Color(0xFF059669) : AppTheme.spacer,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _cnicBackUploaded
                                ? Color(0xFF059669)
                                : (_cnicFrontUploaded
                                    ? Theme.of(context).primaryColor
                                    : AppTheme.notWhite),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              _cnicBackUploaded ? Icons.check : Icons.image,
                              color: _cnicBackUploaded || _cnicFrontUploaded
                                  ? Colors.white
                                  : AppTheme.deactivatedText,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'CNIC Back',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkerText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Upload Zones
              Text(
                'CNIC Front Side',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              SizedBox(height: 12),
              _buildUploadZone('CNIC Front', _cnicFrontUploaded, true),
              SizedBox(height: 24),

              Text(
                'CNIC Back Side',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              SizedBox(height: 12),
              _buildUploadZone('CNIC Back', _cnicBackUploaded, false),
              SizedBox(height: 32),

              // Info Box
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your CNIC is securely encrypted and never shared',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: bothUploaded
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF059669),
                                        size: 48,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Documents Verified!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkerText,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Your CNIC has been successfully verified',
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
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
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
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: bothUploaded
                        ? Theme.of(context).primaryColor
                        : AppTheme.deactivatedText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    bothUploaded ? 'Verify Documents' : 'Upload Both Documents',
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
      ),
    );
  }
}
