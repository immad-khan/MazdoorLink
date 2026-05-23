import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';

class VoiceNavigationScreen extends StatefulWidget {
  @override
  State<VoiceNavigationScreen> createState() => _VoiceNavigationScreenState();
}

class _VoiceNavigationScreenState extends State<VoiceNavigationScreen>
    with TickerProviderStateMixin {
  bool _listening = false;
  String _recognizedCommand = '';
  late List<AnimationController> _waveControllers;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this,
      ),
    );
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() => _listening = true);
    _recognizedCommand = '';

    for (var controller in _waveControllers) {
      controller.repeat();
    }

    Future.delayed(Duration(seconds: 3), () {
      for (var controller in _waveControllers) {
        controller.stop();
      }

      setState(() {
        _listening = false;
        _recognizedCommand = 'Post a plumbing job in Lahore';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Command recognized successfully'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Widget _buildWaveBar(int index) {
    return Expanded(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _waveControllers[index],
            curve: Curves.easeInOut,
          ),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.3),
                Theme.of(context).primaryColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Voice Navigation',
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(IconHelper.microphone,
                          color: Theme.of(context).primaryColor, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Commands',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkerText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isUrdu ? 'اردو یا انگریزی میں بولیں' : 'Speak in Urdu or English',
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
              SizedBox(height: 32),

              // Voice Visualization
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.05),
                      Theme.of(context).primaryColor.withOpacity(0.1),
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
                  children: [
                    // Wave bars
                    if (_listening)
                      Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: _buildWaveBar(index),
                            ),
                          ),
                        ),
                      ),
                    // Mic Button
                    GestureDetector(
                      onTap: _listening ? null : _startListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _listening
                              ? Color(0xFFDC2626)
                              : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: (_listening
                                      ? Color(0xFFDC2626)
                                      : Theme.of(context).primaryColor)
                                  .withOpacity(0.3),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _listening ? Icons.stop : IconHelper.microphone,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _listening ? 'Listening...' : 'Tap to speak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _listening
                          ? 'Speak your command clearly'
                          : 'Say a command to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Recognized Command
              if (_recognizedCommand.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recognized Command',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _recognizedCommand,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkerText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_recognizedCommand.isEmpty) ...[
                SizedBox(height: 32),
                // Example Commands
                Text(
                  'Example Commands',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkerText,
                  ),
                ),
                SizedBox(height: 12),
                _buildCommandExample(
                  'Post a plumbing job',
                  'Create a new service request',
                ),
                SizedBox(height: 12),
                _buildCommandExample(
                  'Show my earnings',
                  'View your today\'s earnings',
                ),
                SizedBox(height: 12),
                _buildCommandExample(
                  'Find nearby jobs',
                  'Search for available jobs nearby',
                ),
                SizedBox(height: 12),
                _buildCommandExample(
                  'Open chat',
                  'Start messaging with a worker',
                ),
              ],
              SizedBox(height: 32),

              // Language Note
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
                        'Commands work in both English and Urdu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandExample(String command, String description) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.spacer),
      ),
      child: InkWell(
        onTap: _listening ? null : () {
          setState(() {
            _listening = true;
            _recognizedCommand = '';
          });
          for (var controller in _waveControllers) {
            controller.repeat();
          }
          Future.delayed(const Duration(seconds: 2), () {
            for (var controller in _waveControllers) {
              controller.stop();
            }
            setState(() {
              _listening = false;
              _recognizedCommand = command;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Command recognized: "$command"'),
                backgroundColor: const Color(0xFF059669),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.mic,
                    color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkerText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
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
      ),
    );
  }
}
