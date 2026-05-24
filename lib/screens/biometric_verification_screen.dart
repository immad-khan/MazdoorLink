import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../widgets/icon_helper.dart';

class BiometricVerificationScreen extends StatefulWidget {
  @override
  State<BiometricVerificationScreen> createState() =>
      _BiometricVerificationScreenState();
}

class _BiometricVerificationScreenState extends State<BiometricVerificationScreen>
    with TickerProviderStateMixin {
  bool _scanning = false;
  bool _fingerprintScanned = false;
  bool _faceScanned = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

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

  void _startScan(bool isFingerprint) {
    setState(() => _scanning = true);

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        if (isFingerprint) {
          _fingerprintScanned = true;
        } else {
          _faceScanned = true;
        }
        _scanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(isFingerprint
                  ? 'Fingerprint scanned successfully'
                  : 'Face scanned successfully'),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Widget _buildBioScanCard(
    String title,
    String subtitle,
    IconData icon,
    bool isScanned,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isScanned ? Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isScanned ? Color(0xFF86EFAC) : AppTheme.spacer,
            width: 2,
          ),
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
            Stack(
              alignment: Alignment.center,
              children: [
                if (_scanning && !isScanned)
                  ScaleTransition(
                    scale: Tween<double>(begin: 1, end: 1.3).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isScanned
                        ? Color(0xFFD1FAE5)
                        : Theme.of(context).primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isScanned ? Icons.check_circle : icon,
                    color: isScanned
                        ? Color(0xFF059669)
                        : Theme.of(context).primaryColor,
                    size: 40,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkerText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.lightText,
              ),
            ),
            if (isScanned)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bothScanned = _fingerprintScanned && _faceScanned;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Biometric Verification',
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
                      child: Icon(IconHelper.fingerprint,
                          color: Theme.of(context).primaryColor, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Your Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkerText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Complete biometric scan for verification',
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
                            color: _fingerprintScanned
                                ? Color(0xFF059669)
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              _fingerprintScanned
                                  ? Icons.check
                                  : IconHelper.fingerprint,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fingerprint',
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
                      color: _fingerprintScanned
                          ? Color(0xFF059669)
                          : AppTheme.spacer,
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
                            color: _faceScanned
                                ? Color(0xFF059669)
                                : (_fingerprintScanned
                                    ? Theme.of(context).primaryColor
                                    : AppTheme.notWhite),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              _faceScanned
                                  ? Icons.check
                                  : Icons.face,
                              color: _faceScanned || _fingerprintScanned
                                  ? Colors.white
                                  : AppTheme.deactivatedText,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Face ID',
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

              // Scan Cards
              _buildBioScanCard(
                'Fingerprint Scan',
                'Place your finger on the scanner',
                IconHelper.fingerprint,
                _fingerprintScanned,
                _fingerprintScanned
                    ? () {}
                    : () => _startScan(true),
              ),
              SizedBox(height: 20),
              _buildBioScanCard(
                'Face Recognition',
                'Position your face for recognition',
                Icons.face,
                _faceScanned,
                _faceScanned
                    ? () {}
                    : (_fingerprintScanned
                        ? () => _startScan(false)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please scan fingerprint first'),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          }),
              ),
              SizedBox(height: 32),

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
                        'Biometric data is stored securely on your device',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
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
                  onPressed: bothScanned
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
                                      'Biometric Verified!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkerText,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Your biometric data has been verified successfully',
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
                    backgroundColor: bothScanned
                        ? Theme.of(context).primaryColor
                        : AppTheme.deactivatedText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    bothScanned ? 'Verification Complete' : 'Complete Both Scans',
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
