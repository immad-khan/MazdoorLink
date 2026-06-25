import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/workers_service.dart';

class WorkerTrackingScreen extends StatefulWidget {
  final double jobPrice;
  final String jobId;
  const WorkerTrackingScreen({Key? key, required this.jobPrice, required this.jobId}) : super(key: key);

  @override
  State<WorkerTrackingScreen> createState() => _WorkerTrackingScreenState();
}

class _WorkerTrackingScreenState extends State<WorkerTrackingScreen> {
  int _status = 0; // 0: tracking, 1: arrived/working, 2: completing, 3: completed
  LatLng? _customerLocation;
  String _pin = '';
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _jobSub;
  String _customerName = 'Customer';
  String _customerPhone = '';
  String _jobDesc = '';

  @override
  void initState() {
    super.initState();
    _listenToJob();
  }

  void _listenToJob() {
    _jobSub = streamJobById(widget.jobId).listen((snapshot) async {
      if (!mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final isUrdu = AppScope.of(context).isUrdu;
      double? lat, lng;
      if (data['customerLatitude'] != null && data['customerLongitude'] != null) {
        lat = (data['customerLatitude'] as num).toDouble();
        lng = (data['customerLongitude'] as num).toDouble();
      }
      final customerId = data['customerId']?.toString();
      String phone = '';
      if (customerId != null) {
        phone = await getUserPhone(customerId) ?? '';
      }
      if (!mounted) return;
      setState(() {
        if (lat != null && lng != null) _customerLocation = LatLng(lat, lng);
        _pin = data['pin']?.toString() ?? '';
        _customerName = data['customerName']?.toString() ?? 'Customer';
        _customerPhone = phone;
        _jobDesc = isUrdu
            ? (data['descriptionUr']?.toString() ?? '')
            : (data['descriptionEn']?.toString() ?? '');
        _updateMarkers();
      });
    });
  }

  void _updateMarkers() {
    final center = _customerLocation ?? const LatLng(31.5204, 74.3587);
    _markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: _customerName),
      ),
      Marker(
        markerId: const MarkerId('worker'),
        position: _status >= 1 ? center : LatLng(center.latitude + 0.005, center.longitude + 0.005),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(center));
    }
  }

  Future<void> _openCustomerDirections() async {
    final isUrdu = AppScope.of(context).isUrdu;
    final location = _customerLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isUrdu ? 'گاہک کی لوکیشن دستیاب نہیں ہے' : 'Customer location is not available'),
      ));
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
      'travelmode': 'driving',
    });

    final canOpenMaps = await canLaunchUrl(uri);
    if (!mounted) return;

    if (canOpenMaps) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isUrdu ? 'Google Maps نہیں کھل سکا' : 'Unable to open Google Maps'),
      ));
    }
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

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
              if (otpController.text == _pin) {
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
                  _customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_jobDesc • Rs. ${widget.jobPrice.toStringAsFixed(0)}',
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
            onPressed: () async {
              final isUrdu = AppScope.of(context).isUrdu;
              if (_customerPhone.isNotEmpty) {
                final uri = Uri(scheme: 'tel', path: _customerPhone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isUrdu ? 'کال کرنے سے قاصر' : 'Unable to call'),
                  ));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isUrdu ? 'فون نمبر دستیاب نہیں' : 'No phone number available'),
                ));
              }
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
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _customerLocation ?? const LatLng(31.5204, 74.3587),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),

          // At location status overlay
          if (_status >= 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Text(
                    isUrdu ? 'آپ گاہک کے پاس ہیں' : '📍 At Customer Location',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
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
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final uri = Uri(scheme: 'tel', path: '15');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isUrdu ? 'ایمرجنسی کال کرنے سے قاصر' : 'Unable to call emergency'),
                            ));
                          }
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
                      child: OutlinedButton.icon(
                        onPressed: _openCustomerDirections,
                        icon: const Icon(Icons.navigation),
                        label: Text(isUrdu ? 'Google Maps میں راستہ دیکھیں' : 'Navigate with Google Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(color: Color(0xFF0D9488)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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

// _MapPainter removed — using GoogleMap widget above
