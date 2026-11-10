import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_state.dart';
import '../services/voice_assistant_service.dart';
import '../services/workers_service.dart';
import '../screens/mazdoor_flow.dart'
    show bilingual, showExitMazdoorlinkDialog, AppRoutes;
class MzScaffold extends StatelessWidget {
  const MzScaffold({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.showBottomNav = true,
    this.background,
    this.enableExitPopScope = true,
    this.actions,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final bool showBottomNav;
  final Color? background;
  final bool enableExitPopScope;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final scaffold = Directionality(
      textDirection: controller.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background ?? const Color(0xFFF9FAFB),
        appBar: (title == null && titleWidget == null)
            ? null
            : AppBar(
                title: titleWidget ?? Text(title!),
                centerTitle: true,
                actions: actions,
                leading: showBack
                    ? IconButton(
                        onPressed: () async {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            final shouldExit = await showExitMazdoorlinkDialog(
                              context,
                            );
                            if (shouldExit) {
                              await controller.logout();
                              if (context.mounted) {
                                SystemNavigator.pop();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.welcome,
                                  (route) => false,
                                );
                              }
                            }
                          }
                        },
                        icon: Transform.rotate(
                          angle: controller.isUrdu ? math.pi : 0,
                          child: const Icon(Icons.arrow_back),
                        ),
                      )
                    : null,
              ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child,
          ),
        ),
        bottomNavigationBar: showBottomNav ? const RoleBottomNav() : null,
      ),
    );

    if (!enableExitPopScope) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
        final isRootDashboard = currentRoute == AppRoutes.customerHome ||
            currentRoute == AppRoutes.workerDashboard ||
            currentRoute == AppRoutes.adminDashboard ||
            currentRoute == '/customer/home' ||
            currentRoute == '/worker/dashboard' ||
            currentRoute == '/admin/dashboard';

        final isBottomNavTab = currentRoute == AppRoutes.sharedHistory ||
            currentRoute == AppRoutes.sharedChat ||
            currentRoute == AppRoutes.sharedSettings ||
            currentRoute == AppRoutes.workerEarnings ||
            currentRoute == '/shared/history' ||
            currentRoute == '/shared/chat' ||
            currentRoute == '/shared/settings' ||
            currentRoute == '/worker/earnings';

        if (isRootDashboard) {
          final shouldExit = await showExitMazdoorlinkDialog(context);
          if (shouldExit) {
            await controller.logout();
            if (context.mounted) {
              SystemNavigator.pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (route) => false,
              );
            }
          }
          return;
        }

        if (isBottomNavTab) {
          final role = controller.role;
          final homeRoute = role == UserRole.worker
              ? AppRoutes.workerDashboard
              : AppRoutes.customerHome;
          Navigator.pushReplacementNamed(context, homeRoute);
          return;
        }

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(result);
          return;
        }

        final shouldExit = await showExitMazdoorlinkDialog(context);
        if (shouldExit) {
          await controller.logout();
          if (context.mounted) {
            SystemNavigator.pop();
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (route) => false,
            );
          }
        }
      },
      child: scaffold,
    );
  }
}

class RoleBottomNav extends StatelessWidget {
  const RoleBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final current = ModalRoute.of(context)?.settings.name ?? '';
    final items = role == UserRole.worker
        ? const [
            _NavItem(
              '/worker/dashboard',
              Icons.work_outline,
              Icons.work,
              'Dashboard',
              'ڈیش بورڈ',
            ),
            _NavItem(
              '/worker/earnings',
              Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet,
              'Earnings',
              'آمدنی',
            ),
            _NavItem(
              '/shared/chat',
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Chat',
              'چیٹ',
            ),
            _NavItem(
              '/shared/settings',
              Icons.settings_outlined,
              Icons.settings,
              'Settings',
              'ترتیبات',
            ),
          ]
        : const [
            _NavItem(
              '/customer/home',
              Icons.home_outlined,
              Icons.home,
              'Home',
              'ہوم',
            ),
            _NavItem(
              '/shared/history',
              Icons.history,
              Icons.history_toggle_off,
              'Bookings',
              'بکنگز',
            ),
            _NavItem(
              '/shared/chat',
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Chat',
              'چیٹ',
            ),
            _NavItem(
              '/shared/settings',
              Icons.settings_outlined,
              Icons.settings,
              'Settings',
              'ترتیبات',
            ),
          ];

    int selected = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i].route == current) {
        selected = i;
        break;
      }
    }

    Widget buildItem(int index, _NavItem item) {
      final isSelected = index == selected;
      final color = isSelected ? const Color(0xFF0D9488) : Colors.grey.shade500;
      final isChat = item.route == '/shared/chat';
      final controller = AppScope.of(context);
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                Navigator.pushReplacementNamed(context, item.route);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isChat
                    ? ListenableBuilder(
                        listenable: controller.chatUnread,
                        builder: (context, _) {
                          final unread = controller.chatUnread.total;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? item.filled : item.outline,
                                color: color,
                                size: 24,
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: -10,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : Icon(
                        isSelected ? item.filled : item.outline,
                        color: color,
                        size: 24,
                      ),
                const SizedBox(height: 4),
                Text(
                  isUrdu ? item.ur : item.en,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            buildItem(0, items[0]),
            buildItem(1, items[1]),
            // Central Mic Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const VoiceOverlaySheet(),
                  );
                },
                child: Container(
                  transform: Matrix4.translationValues(0.0, -10.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D9488).withOpacity(0.14),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D9488),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildItem(2, items[2]),
            buildItem(3, items[3]),
          ],
        ),
      ),
    );
  }
}

class VoiceOverlaySheet extends StatefulWidget {
  const VoiceOverlaySheet({super.key});

  @override
  State<VoiceOverlaySheet> createState() => _VoiceOverlaySheetState();
}

class _VoiceOverlaySheetState extends State<VoiceOverlaySheet>
    with TickerProviderStateMixin {
  // idle -> listening -> processing -> responded -> (navigating or idle)
  String _phase = 'idle';
  String _recognizedText = '';
  String _responseText = '';
  String _errorText = '';

  late List<AnimationController> _waveControllers;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _voiceService = VoiceAssistantService();

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + index * 150),
      ),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Auto-start listening when sheet opens
    _startListening();
  }

  @override
  void dispose() {
    for (final c in _waveControllers) {
      c.dispose();
    }
    _pulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _phase = 'listening';
      _recognizedText = '';
      _responseText = '';
      _errorText = '';
    });
    for (final c in _waveControllers) {
      c.repeat(reverse: true);
    }

    try {
      await _voiceService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() => _recognizedText = text);
        },
        onDone: () {
          if (!mounted) return;
          if (_recognizedText.trim().isNotEmpty) {
            _processCommand(_recognizedText.trim());
          } else {
            setState(() {
              _phase = 'error';
              _errorText = 'No speech detected. Tap mic to try again.';
            });
            _stopWaves();
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = 'error';
        _errorText = 'Microphone not available. Check permissions.';
      });
      _stopWaves();
    }
  }

  void _stopWaves() {
    for (final c in _waveControllers) {
      c.stop();
      c.value = 0.0;
    }
  }

  Future<void> _processCommand(String text) async {
    setState(() => _phase = 'processing');
    _stopWaves();

    final role = AppScope.of(context).role;
    final intent = await _voiceService.parseIntent(text, role: role);

    if (!mounted) return;

    final result = _voiceService.executeIntent(
      context: context,
      intent: intent,
      role: role,
    );

    final response = result['response'] as String? ?? 'Done.';
    final navigated = result['navigated'] as bool? ?? false;

    setState(() {
      _phase = 'responded';
      _responseText = response;
    });

    await _voiceService.speak(response);

    if (navigated) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mic, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(response)),
            ],
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _phase == 'listening';
    final isProcessing = _phase == 'processing';
    final isResponded = _phase == 'responded';
    final isError = _phase == 'error';

    String statusText;
    if (isListening) {
      statusText = 'Listening for your command...';
    } else if (isProcessing) {
      statusText = 'Processing your command...';
    } else if (isResponded) {
      statusText = 'Command Recognized!';
    } else if (isError) {
      statusText = _errorText;
    } else {
      statusText = 'Tap the mic to speak';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isError ? 'Voice Error' : 'Voice Assistant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Wave Visualizer
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(5, (index) {
                final anim = Tween<double>(begin: 12, end: 52).animate(
                  CurvedAnimation(
                    parent: _waveControllers[index],
                    curve: Interval(0.08 * index, 1.0, curve: Curves.easeInOut),
                  ),
                );
                return AnimatedBuilder(
                  animation: anim,
                  builder: (context, child) {
                    return Container(
                      width: 7,
                      height: isListening ? anim.value : 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(
                          isListening ? (0.4 + 0.12 * index) : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Mic Button
          GestureDetector(
            onTap: () {
              if (isListening) {
                _voiceService.stopListening();
                _stopWaves();
                if (_recognizedText.trim().isNotEmpty) {
                  _processCommand(_recognizedText.trim());
                } else {
                  setState(() => _phase = 'idle');
                }
              } else if (!isProcessing) {
                _startListening();
              }
            },
            child: ScaleTransition(
              scale: isListening
                  ? _pulseAnim
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? const Color(0xFF0D9488)
                      : isProcessing
                      ? const Color(0xFFF59E0B)
                      : isResponded
                      ? const Color(0xFF10B981)
                      : isError
                      ? const Color(0xFFEF4444)
                      : Colors.grey.shade300,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isListening
                                  ? const Color(0xFF0D9488)
                                  : isProcessing
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981))
                              .withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        isListening
                            ? Icons.mic
                            : isResponded
                            ? Icons.check
                            : isError
                            ? Icons.mic_off
                            : Icons.mic_none,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Live Transcription
          if (_recognizedText.isNotEmpty && (isListening || isProcessing))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_quote,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Response
          if (isResponded && _responseText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCFBF1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_recognizedText.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over,
                          color: Color(0xFF0D9488),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '"$_recognizedText"',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFCCFBF1)),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF0D9488),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _responseText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Suggestion chips (only when idle or error)
          if (_phase == 'idle' || isError) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try saying:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPromptChip('"Hire a plumber"'),
                _buildPromptChip('"Show bookings"'),
                _buildPromptChip('"Open settings"'),
                _buildPromptChip('"Post a job"'),
              ],
            ),
          ],

          // Retry button after response
          if (isResponded) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Ask again'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return GestureDetector(
      onTap: () {
        final cleaned = text.replaceAll('"', '').replaceAll('"', '');
        setState(() {
          _recognizedText = cleaned;
          _phase = 'processing';
        });
        _processCommand(cleaned);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCCFBF1)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0D9488),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.outline, this.filled, this.en, this.ur);

  final String route;
  final IconData outline;
  final IconData filled;
  final String en;
  final String ur;
}
