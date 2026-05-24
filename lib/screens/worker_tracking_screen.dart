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
  int _status = 0; // 0: tracking, 1: arrived, 2: completing, 3: completed, 4: payment received
  bool _isLoading = false;

  void _onArrived() {
    setState(() {
      _status = 1;
    });
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
          // Map Viewer
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE5E3DF),
              child: CustomPaint(
                size: Size.infinite,
                painter: _MapPainter(),
              ),
            ),
          ),
          if (_status == 0) ...[
            Positioned(
              top: 110,
              left: 80,
              child: Column(
                children: [
                   const CircleAvatar(radius: 18, backgroundColor: Colors.black87, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 240,
              right: 70,
              child: Column(
                children: [
                  const CircleAvatar(radius: 18, backgroundColor: Color(0xFF0D9488), child: Icon(Icons.location_on, color: Colors.white)),
                  Text(isUrdu ? 'گاہک' : 'Customer'),
                ],
              ),
            ),
          ],
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  const SizedBox(height: 20),
                  
                  if (_status == 0) ...[
                    Text(
                      isUrdu ? 'گاہک کے مقام کی طرف جا رہے ہیں...' : 'Heading to customer location...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
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
                  ] else if (_status == 1) ...[
                    Text(
                      isUrdu ? 'کام جاری ہے...' : 'Work in progress...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
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
                  ] else if (_status == 2) ...[
                    const CircularProgressIndicator(color: Color(0xFF0D9488)),
                    const SizedBox(height: 16),
                    Text(
                      isUrdu ? 'تصدیق کا انتظار ہے...' : 'Waiting for confirmation...',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ] else if (_status == 3) ...[
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
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.8)..strokeWidth = 8;
    for (var i = 0.0; i < size.height; i += 90) {
      canvas.drawLine(Offset(0, i + 10), Offset(size.width, i + 40), p);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(100, 130)
      ..quadraticBezierTo(170, 170, 190, 220)
      ..quadraticBezierTo(210, 240, 250, 260);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
