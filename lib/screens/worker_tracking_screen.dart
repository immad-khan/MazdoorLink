import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';

class WorkerTrackingScreen extends StatefulWidget {
  final double jobPrice;
  const WorkerTrackingScreen({Key? key, required this.jobPrice}) : super(key: key);

  @override
  State<WorkerTrackingScreen> createState() => _WorkerTrackingScreenState();
}

class _WorkerTrackingScreenState extends State<WorkerTrackingScreen> {
  int _status = 0; // 0: tracking, 1: arrived/working, 2: completing, 3: completed
  bool _isLoading = false;

  void _onArrived() {
    final isUrdu = AppScope.of(context).isUrdu;
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isUrdu ? 'گاہک سے تصدیق' : 'Customer Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isUrdu ? 'کام شروع کرنے کے لیے گاہک سے 4 ہندسوں کا پِن طلب کریں:' : 'Ask the customer for the 4-digit PIN to start the service:'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '----',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (otpController.text == '4921') {
                Navigator.pop(ctx);
                setState(() {
                  _status = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isUrdu ? 'پِن درست ہے! کام شروع ہو گیا ہے۔' : 'PIN Verified! Job Started.'),
                  backgroundColor: Colors.green,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isUrdu ? 'غلط پِن!' : 'Invalid PIN! Please try again.'),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: Text(isUrdu ? 'تصدیق کریں' : 'Verify'),
          ),
        ],
      ),
    );
  }

  void _onWorkCompleted() {
    setState(() {
      _status = 2;
    });
    // simulate customer agreeing
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      final isUrdu = AppScope.of(context).isUrdu;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 48),
              const SizedBox(height: 16),
              Text(
                isUrdu ? 'گاہک نے تصدیق کر دی ہے کہ کام مکمل ہو گیا ہے۔' : 'Customer agrees work is done.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        Navigator.pop(context); // close first dialog
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(isUrdu ? 'ادائیگی موصول کریں' : 'Payment Received?'),
            content: Text(isUrdu 
              ? 'گاہک نے آپ کو ${widget.jobPrice.toStringAsFixed(0)} روپے ہینڈ ٹو ہینڈ دیئے ہیں۔ کیا آپ کو یہ رقم مل گئی ہے؟' 
              : 'Customer has made PKR ${widget.jobPrice.toStringAsFixed(0)} with hand. Did you receive it?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _status = 3;
                  });
                },
                child: Text(isUrdu ? 'جی ہاں' : 'Yes'),
              ),
            ],
          ),
        );
      });
    });
  }

  Widget _buildCustomerInfoTile(bool isUrdu) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF0D9488),
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'عمر فاروق' : 'Omer Farooq',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kitchen Leakage • Rs. 1500',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/shared/chat'),
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0D9488)),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling customer...')),
              );
            },
            icon: const Icon(Icons.call, color: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'ٹریکنگ' : 'Job Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // Map background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE8EDDF),
              child: CustomPaint(
                size: Size.infinite,
                painter: _MapPainter(status: _status),
              ),
            ),
          ),

          // Worker pin (en-route)
          if (_status == 0)
            Positioned(
              top: 90,
              left: 60,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.handyman, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isUrdu ? 'آپ' : 'You', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Customer pin (en-route)
          if (_status == 0)
            Positioned(
              top: 200,
              right: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isUrdu ? 'گاہک' : 'Customer', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // At location pin (after arrived)
          if (_status >= 1)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Text(
                      isUrdu ? '📍 آپ گاہک کے پاس ہیں' : '📍 At Customer Location',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
            ),
          
          // SOS button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'worker_sos',
              backgroundColor: Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isUrdu ? 'ہنگامی صورتحال (SOS)' : 'Emergency SOS'),
                    content: Text(isUrdu ? 'کیا آپ خطرے میں ہیں؟ پولیس کو کال کی جا رہی ہے۔' : 'Are you in danger? Calling Admin/Police.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel')),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        icon: const Icon(Icons.call),
                        label: const Text('15 / Admin'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Triggered!')));
                        },
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.local_police, color: Colors.white),
              label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status 0: En-route
                  if (_status == 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isUrdu ? '12 منٹ میں پہنچ رہے ہیں' : 'Arriving in 12 min',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, size: 16, color: Color(0xFF0D9488)),
                              const SizedBox(width: 4),
                              Text(
                                isUrdu ? '2.5 کلومیٹر' : '2.5 km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCustomerInfoTile(isUrdu),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _onArrived,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        child: Text(isUrdu ? 'کیا آپ پہنچ گئے ہیں؟' : 'Have you arrived?', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ]
                  // Status 1: Working (PIN verified)
                  else if (_status == 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF059669), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isUrdu ? 'پِن تصدیق شدہ — کام جاری ہے' : 'PIN Verified — Work in progress',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomerInfoTile(isUrdu),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _onWorkCompleted,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        child: Text(isUrdu ? 'کیا کام مکمل ہو گیا ہے؟' : 'Is work completed?', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ]
                  // Status 2: Waiting for confirmation
                  else if (_status == 2) ...[
                    const CircularProgressIndicator(color: Color(0xFF0D9488)),
                    const SizedBox(height: 16),
                    Text(
                      isUrdu ? 'تصدیق کا انتظار ہے...' : 'Waiting for confirmation...',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ]
                  // Status 3: Completed
                  else if (_status == 3) ...[
                    const Icon(Icons.task_alt, color: Color(0xFF059669), size: 64),
                    const SizedBox(height: 16),
                    Text(
                      isUrdu ? 'کام اور ادائیگی مکمل ہو گئی!' : 'Job and payment completed!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUrdu ? 'وصول کیے گئے: PKR ${widget.jobPrice.toStringAsFixed(0)}' : 'Received: PKR ${widget.jobPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final isUrdu = AppScope.of(context).isUrdu;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(isUrdu ? 'گاہک کو ریٹ کریں' : 'Rate Customer'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(isUrdu ? 'اس گاہک کے ساتھ آپ کا تجربہ کیسا رہا؟' : 'How was your experience with this customer?'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.amber, size: 36)),
                                  )
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: Text(isUrdu ? 'جمع کروائیں' : 'Submit'),
                                )
                              ],
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                        child: Text(isUrdu ? 'گاہک کو ریٹ کریں' : 'Rate Customer'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(isUrdu ? 'ڈیش بورڈ پر واپس جائیں' : 'Back to Dashboard'),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final int status;
  _MapPainter({this.status = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EDDF),
    );

    // Draw road grid (horizontal roads)
    final roadFill = Paint()..color = const Color(0xFFF5F5F0);
    final roadLine = Paint()..color = const Color(0xFFD1D5C8)..strokeWidth = 1;
    for (var y = 60.0; y < size.height; y += 100) {
      canvas.drawRect(Rect.fromLTWH(0, y - 14, size.width, 28), roadFill);
      canvas.drawLine(Offset(0, y - 14), Offset(size.width, y - 14), roadLine);
      canvas.drawLine(Offset(0, y + 14), Offset(size.width, y + 14), roadLine);
      // Center dashes
      final dashPaint = Paint()..color = const Color(0xFFCCD2C5)..strokeWidth = 1;
      for (var dx = 0.0; dx < size.width; dx += 20) {
        canvas.drawLine(Offset(dx, y), Offset(dx + 10, y), dashPaint);
      }
    }

    // Draw road grid (vertical roads)
    for (var x = 80.0; x < size.width; x += 120) {
      canvas.drawRect(Rect.fromLTWH(x - 14, 0, 28, size.height), roadFill);
      canvas.drawLine(Offset(x - 14, 0), Offset(x - 14, size.height), roadLine);
      canvas.drawLine(Offset(x + 14, 0), Offset(x + 14, size.height), roadLine);
      // Center dashes
      final dashPaint = Paint()..color = const Color(0xFFCCD2C5)..strokeWidth = 1;
      for (var dy = 0.0; dy < size.height; dy += 20) {
        canvas.drawLine(Offset(x, dy), Offset(x, dy + 10), dashPaint);
      }
    }

    // Draw blocks (buildings/houses)
    final blockPaint = Paint()..color = const Color(0xFFCCD5C0);
    final blockBorder = Paint()
      ..color = const Color(0xFFB8C1AD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = 80.0; y < size.height - 60; y += 100) {
      for (var x = 100.0; x < size.width - 40; x += 120) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 40, y, 80, 68),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, blockPaint);
        canvas.drawRRect(rect, blockBorder);
      }
    }

    // Draw route line (only when en-route)
    if (status == 0) {
      final routeGlow = Paint()
        ..color = const Color(0xFF0D9488).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final routePaint = Paint()
        ..color = const Color(0xFF0D9488)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()
        ..moveTo(85, 120)
        ..lineTo(85, 160)
        ..lineTo(200, 160)
        ..lineTo(200, 230)
        ..lineTo(size.width - 70, 230);
      
      canvas.drawPath(path, routeGlow);
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.status != status;
}
