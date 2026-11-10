import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import '../services/smtp_service.dart';
import '../services/location_service.dart';
import 'cancel_job_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        TrackingArguments,
        ConversationArguments;
class ServiceTrackingScreen extends StatefulWidget {
  const ServiceTrackingScreen({super.key});

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  int _trackingState = 0;
  StreamSubscription<DocumentSnapshot>? _jobSub;
  LatLng? _customerLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  DateTime? _scheduledTime;
  bool _scheduleConfirmed = false;
  Timer? _countdownTimer;
  bool _reminderEmailSent = false;
  String _jobDescEmail = '';

  @override
  void initState() {
    super.initState();
    _listenToJob();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final scheduled = _scheduledTime;
      if (scheduled == null || !_scheduleConfirmed) return;
      if (!scheduled.isAfter(DateTime.now()) &&
          !_reminderEmailSent &&
          _trackingState == 1) {
        _reminderEmailSent = true;
        _sendArrivalReminderEmail();
      }
      setState(() {});
    });
  }

  void _listenToJob() {
    final args =
        ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final jobId = args?.jobId;
    if (jobId == null) return;
    _jobSub = streamJobById(jobId).listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final status = data['status']?.toString() ?? 'pending';
      if (status == 'cancelled') {
        showToast(
          bilingual(
            context,
            'Job has been cancelled.',
            'کام منسوخ کر دیا گیا ہے۔',
          ),
        );
        Navigator.pop(context);
        return;
      }
      if (status == 'rejected') {
        final wasScheduled = data['scheduleDeclined'] as bool? ?? false;
        showToast(
          wasScheduled
              ? bilingual(
                  context,
                  'You declined the worker\'s proposed schedule. This job is closed.',
                  'آپ نے ورکر کے تجویز کردہ شیڈول کو مسترد کر دیا۔ یہ کام بند ہو گیا۔',
                )
              : bilingual(
                  context,
                  'Worker declined your offer. Please find another worker.',
                  'ورکر نے آپ کی پیشکش مسترد کر دی۔ براہ کرم دوسرا ورکر تلاش کریں۔',
                ),
        );
        Navigator.pop(context);
        return;
      }
      double? lat, lng;
      if (data['customerLatitude'] != null &&
          data['customerLongitude'] != null) {
        lat = (data['customerLatitude'] as num).toDouble();
        lng = (data['customerLongitude'] as num).toDouble();
      }
      setState(() {
        final scheduledRaw = data['scheduledReminderAt'];
        _scheduledTime = scheduledRaw is Timestamp
            ? scheduledRaw.toDate()
            : null;
        _scheduleConfirmed = data['scheduleConfirmed'] as bool? ?? false;
        _jobDescEmail = data['descriptionEn']?.toString() ?? '';
        if (status == 'accepted') {
          _trackingState = 1;
        } else if (status == 'arrival_pending') {
          _trackingState = 3;
        } else if (status == 'working') {
          _trackingState = 4;
        } else if (status == 'worker_completed' || status == 'completed') {
          _trackingState = 5;
        } else if (status == 'payment_pending' ||
            status == 'worker_payment_pending' ||
            status == 'payment_disputed') {
          _trackingState = 6;
        } else if (status == 'arrival_declined') {
          _trackingState = 7;
        } else if (status == 'scheduled') {
          _trackingState = 8;
        } else {
          _trackingState = 0;
        }
        if (lat != null && lng != null) _customerLocation = LatLng(lat, lng);
        _markers = {
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerLocation ?? LocationService.defaultIslamabad,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(title: bilingual(context, 'You', 'آپ')),
          ),
          Marker(
            markerId: const MarkerId('worker'),
            position: _trackingState >= 1
                ? (_customerLocation ?? LocationService.defaultIslamabad)
                : LatLng(
                    (_customerLocation?.latitude ??
                            LocationService.defaultIslamabad.latitude) +
                        0.005,
                    (_customerLocation?.longitude ??
                            LocationService.defaultIslamabad.longitude) +
                        0.005,
                  ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(title: bilingual(context, 'Worker', 'ورکر')),
          ),
        };
        if (_mapController != null && _customerLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_customerLocation!),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    _countdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildSchedulePanel(BuildContext context, String? jobId) {
    final scheduled = _scheduledTime;
    if (scheduled == null) return const SizedBox.shrink();
    final t = DateFormat('hh:mm a, d MMM').format(scheduled);
    final args =
        ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final worker = args?.worker;

    if (_scheduleConfirmed) {
      final remaining = scheduled.difference(DateTime.now());
      final String reminder;
      if (remaining.isNegative) {
        reminder = bilingual(
          context,
          'Worker should be arriving now',
          'ورکر کو اب پہنچنا چاہیے',
        );
      } else if (remaining.inHours > 0) {
        final mins = remaining.inMinutes % 60;
        reminder = bilingual(
          context,
          'Worker arrives in ${remaining.inHours} h $mins min',
          'ورکر ${remaining.inHours} گھنٹے $mins منٹ میں پہنچے گا',
        );
      } else {
        reminder = bilingual(
          context,
          'Worker arrives in ${remaining.inMinutes} min',
          'ورکر ${remaining.inMinutes} منٹ میں پہنچے گا',
        );
      }
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bilingual(
                          context,
                          'Schedule confirmed for $t',
                          'شیڈول $t کے لیے منظور شدہ',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      Text(
                        reminder,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: Text(
                  bilingual(context, 'Message Worker', 'ورکر کو میسج کریں'),
                ),
                onPressed: () async {
                  final workerId = worker?.id;
                  if (workerId == null || workerId.isEmpty) return;
                  final workerName = worker?.name ?? 'Worker';
                  final existingId = await findExistingConversation(workerId);
                  if (!context.mounted) return;
                  if (existingId != null) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.sharedConversation,
                      arguments: ConversationArguments(
                        conversationId: existingId,
                        otherName: workerName,
                        otherImage: worker?.image,
                      ),
                    );
                  } else {
                    final newId = await createConversation(
                      otherUserId: workerId,
                      otherUserName: workerName,
                      otherUserImage: worker?.image ?? '',
                    );
                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.sharedConversation,
                        arguments: ConversationArguments(
                          conversationId: newId,
                          otherName: workerName,
                          otherImage: worker?.image,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bilingual(
                    context,
                    'Worker wants to schedule this work to $t',
                    'ورکر یہ کام $t پر شیڈول کرنا چاہتا ہے',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  onPressed: () async {
                    if (jobId != null) {
                      await acceptScheduledJob(jobId);
                      _notifyScheduleApproval(jobId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bilingual(
                                context,
                                'Schedule accepted!',
                                'شیڈول منظور ہو گیا!',
                              ),
                            ),
                            backgroundColor: const Color(0xFF0D9488),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: Text(bilingual(context, 'Accept', 'قبول کریں')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: Text(bilingual(context, 'Chat', 'چیٹ کریں')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final workerId = worker?.id;
                    if (workerId == null || workerId.isEmpty) return;
                    final workerName = worker?.name ?? 'Worker';
                    final existingId = await findExistingConversation(workerId);
                    if (!context.mounted) return;
                    if (existingId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.sharedConversation,
                        arguments: ConversationArguments(
                          conversationId: existingId,
                          otherName: workerName,
                          otherImage: worker?.image,
                        ),
                      );
                    } else {
                      final newId = await createConversation(
                        otherUserId: workerId,
                        otherUserName: workerName,
                        otherUserImage: worker?.image ?? '',
                      );
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.sharedConversation,
                          arguments: ConversationArguments(
                            conversationId: newId,
                            otherName: workerName,
                            otherImage: worker?.image,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (jobId != null) {
                  await FirebaseFirestore.instance
                      .collection('jobs')
                      .doc(jobId)
                      .update({
                        'status': 'rejected',
                        'scheduleDeclined': true,
                        'statusUpdatedAt': FieldValue.serverTimestamp(),
                      });
                  _notifyScheduleDeclined(jobId);
                }
              },
              child: Text(
                bilingual(context, 'Decline', 'مسترد کریں'),
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyScheduleApproval(String jobId) async {
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();
      final data = jobDoc.data();
      if (data == null) return;
      final workerId = data['workerId']?.toString();
      final workerEmail = workerId != null
          ? await getUserEmail(workerId)
          : null;
      if (workerEmail == null) return;
      final scheduledRaw = data['scheduledReminderAt'];
      final scheduled = scheduledRaw is Timestamp
          ? scheduledRaw.toDate()
          : null;
      if (scheduled == null) return;
      await SmtpService.sendScheduleConfirmedEmail(
        email: workerEmail,
        workerName: data['workerName']?.toString() ?? 'Worker',
        jobDesc: data['descriptionEn']?.toString() ?? 'Service',
        scheduledTime: scheduled,
      );
    } catch (_) {}
  }

  Future<void> _notifyScheduleDeclined(String jobId) async {
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();
      final data = jobDoc.data();
      if (data == null) return;
      final workerId = data['workerId']?.toString();
      final workerEmail = workerId != null
          ? await getUserEmail(workerId)
          : null;
      if (workerEmail == null) return;
      await SmtpService.sendScheduleDeclinedEmail(
        email: workerEmail,
        workerName: data['workerName']?.toString() ?? 'Worker',
        jobDesc: data['descriptionEn']?.toString() ?? 'Service',
      );
    } catch (_) {}
  }

  Future<void> _sendArrivalReminderEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await SmtpService.sendArrivalReminderEmail(
        email: email,
        jobDesc: _jobDescEmail.isEmpty ? 'Service' : _jobDescEmail,
      );
    } catch (_) {}
  }

  String _trackingTitle(BuildContext context) {
    switch (_trackingState) {
      case 0:
        return bilingual(
          context,
          'Waiting for worker to accept...',
          'ورکر کے قبول کرنے کا انتظار ہے...',
        );
      case 1:
        if (_scheduledTime != null && _scheduleConfirmed) {
          final t = DateFormat('hh:mm a, d MMM').format(_scheduledTime!);
          return bilingual(
            context,
            'Worker will arrive at $t',
            'ورکر $t پر پہنچے گا',
          );
        }
        return bilingual(context, 'Worker is on the way', 'ورکر راستے میں ہے');
      case 2:
      case 5:
        return bilingual(context, 'Job completed', 'کام مکمل ہو گیا');
      case 3:
        return bilingual(context, 'Worker has arrived', 'ورکر پہنچ گیا ہے');
      case 4:
        return bilingual(
          context,
          'Worker is working at your location',
          'ورکر آپ کے مقام پر کام کر رہا ہے',
        );
      case 6:
        return bilingual(
          context,
          'Awaiting payment confirmation',
          'ادائیگی کی تصدیق زیر التوا',
        );
      case 7:
        return bilingual(
          context,
          'Worker arrival was declined',
          'ورکر کی آمد مسترد کر دی گئی',
        );
      case 8:
        if (_scheduleConfirmed) {
          final t = _scheduledTime != null
              ? DateFormat('hh:mm a, d MMM').format(_scheduledTime!)
              : '';
          return bilingual(
            context,
            'Scheduled for $t',
            'شیڈول $t کے لیے منظور شدہ',
          );
        }
        final t = _scheduledTime != null
            ? DateFormat('hh:mm a, d MMM').format(_scheduledTime!)
            : '';
        return bilingual(
          context,
          'Worker wants to schedule ($t)',
          'ورکر شیڈول کرنا چاہتا ہے ($t)',
        );
      default:
        return bilingual(context, 'Tracking job', 'کام ٹریک ہو رہا ہے');
    }
  }

  String? _trackingDetail(BuildContext context) {
    switch (_trackingState) {
      case 3:
        return bilingual(
          context,
          'Please confirm the worker is at your location.',
          'براہ کرم تصدیق کریں کہ ورکر آپ کے مقام پر موجود ہے۔',
        );
      case 4:
        return bilingual(
          context,
          'This job is now working at customer.',
          'یہ کام اب کسٹمر کے مقام پر جاری ہے۔',
        );
      case 6:
        return bilingual(
          context,
          'Waiting for the worker to confirm receipt of payment.',
          'ورکر ادائیگی موصول ہونے کی تصدیق کرے گا۔',
        );
      case 7:
        return bilingual(
          context,
          'This job has been closed because the arrival was declined.',
          'آمد مسترد ہونے کی وجہ سے یہ کام بند ہو گیا۔',
        );
      case 8:
        if (!_scheduleConfirmed) {
          return bilingual(
            context,
            'Worker wants to schedule this work. Accept or Chat to discuss.',
            'ورکر یہ کام شیڈول کرنا چاہتا ہے۔ قبول کریں یا بات چیت کے لیے چیٹ کریں۔',
          );
        }
        return bilingual(
          context,
          'This request is scheduled. The job will become active once it starts.',
          'یہ درخواست شیڈول ہو چکی ہے۔ کام شروع ہوتے ہی ایکٹو ہو جائے گی۔',
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
    final worker = args?.worker;
    final job = args?.job;
    final jobId = args?.jobId;

    if (worker == null) {
      return Scaffold(
        body: Center(
          child: Text(
            bilingual(
              context,
              'Tracking data not available',
              'ٹریکنگ ڈیٹا دستیاب نہیں',
            ),
          ),
        ),
      );
    }

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Service Tracking', 'سروس ٹریکنگ'),
      actions: [
        IconButton(
          tooltip: bilingual(context, 'Home', 'ہوم'),
          icon: const Icon(
            Icons.home_rounded,
            color: Color(0xFF0D9488),
            size: 26,
          ),
          onPressed: () {
            final role = AppScope.of(context).role;
            final homeRoute = role == UserRole.worker
                ? AppRoutes.workerDashboard
                : AppRoutes.customerHome;
            Navigator.pushNamedAndRemoveUntil(
              context,
              homeRoute,
              (route) => false,
            );
          },
        ),
      ],
      child: Stack(
        children: [
          if (_trackingState >= 1)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _customerLocation ?? LocationService.defaultIslamabad,
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
          if (_trackingState == 0)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 100),
                  const CircularProgressIndicator(color: Color(0xFF0D9488)),
                  const SizedBox(height: 24),
                  Text(
                    bilingual(
                      context,
                      'Request sent to worker...',
                      'ورکر کو درخواست بھیج دی گئی...',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bilingual(
                      context,
                      'Waiting for them to accept your offer',
                      'ان کے آپ کی پیشکش قبول کرنے کا انتظار ہے',
                    ),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (_trackingState >= 1)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton.extended(
                heroTag: 'customer_sos',
                backgroundColor: Colors.red,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        bilingual(
                          context,
                          'Emergency SOS',
                          'ہنگامی صورتحال (SOS)',
                        ),
                      ),
                      content: Text(
                        bilingual(
                          context,
                          'Are you in danger? Calling Admin/Police.',
                          'کیا آپ خطرے میں ہیں؟ پولیس کو کال کی جا رہی ہے۔',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            bilingual(context, 'Cancel', 'منسوخ کریں'),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.call),
                          label: const Text('15 / Admin'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final uri = Uri(scheme: 'tel', path: '15');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              showToast(
                                bilingual(
                                  context,
                                  'Unable to call emergency',
                                  'ایمرجنسی کال کرنے سے قاصر',
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.local_police, color: Colors.white),
                label: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_trackingState >= 1)
            Positioned(
              top: 110,
              left: 80,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      worker.image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      worker.name.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_trackingState >= 1)
            Positioned(
              top: 240,
              right: 70,
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black87,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  Text('You'),
                ],
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, width: 42, color: Colors.black26),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _trackingTitle(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.explore),
                    ],
                  ),
                  if (_trackingState == 1)
                    Text(
                      bilingual(
                        context,
                        'Worker has accepted the job',
                        'ورکر نے کام قبول کر لیا ہے',
                      ),
                    ),
                  if ((_trackingState == 1 || _trackingState == 8) &&
                      _scheduledTime != null)
                    _buildSchedulePanel(context, jobId),
                  if (_trackingDetail(context) != null)
                    Text(_trackingDetail(context)!),
                  if (_trackingState == 2) ...[
                    const SizedBox(height: 8),
                    Text(
                      bilingual(
                        context,
                        'Is it completed?',
                        'کیا کام مکمل ہو گیا ہے؟',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF0D9488),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        worker.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),
                    title: Text(worker.name),
                    subtitle: Text(
                      '${worker.category} • ${bilingual(context, job?.descriptionEn ?? "Service", job?.descriptionUr ?? "سروس")} • ${worker.price}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final wid = worker.id;
                            if (wid == null) return;
                            final existingId = await findExistingConversation(
                              wid,
                            );
                            if (!context.mounted) return;
                            if (existingId != null) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.sharedConversation,
                                arguments: ConversationArguments(
                                  conversationId: existingId,
                                  otherName: worker.name,
                                  otherImage: worker.image,
                                ),
                              );
                            } else {
                              final newId = await createConversation(
                                otherUserId: wid,
                                otherUserName: worker.name,
                                otherUserImage: worker.image,
                              );
                              if (context.mounted) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.sharedConversation,
                                  arguments: ConversationArguments(
                                    conversationId: newId,
                                    otherName: worker.name,
                                    otherImage: worker.image,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (worker.phone.isNotEmpty) {
                              final uri = Uri(
                                scheme: 'tel',
                                path: worker.phone,
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                showToast(
                                  bilingual(
                                    context,
                                    'Unable to call',
                                    'کال کرنے سے قاصر',
                                  ),
                                );
                              }
                            } else {
                              showToast(
                                bilingual(
                                  context,
                                  'No phone number available',
                                  'فون نمبر دستیاب نہیں',
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.call, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  if (_trackingState == 3) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (jobId != null) {
                                await updateJobStatus(
                                  jobId,
                                  'arrival_declined',
                                );
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    bilingual(
                                      context,
                                      'Worker presence declined.',
                                      'ورکر کی موجودگی مسترد کر دی گئی۔',
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(bilingual(context, 'No', 'نہیں')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (jobId != null) {
                                await updateJobStatus(jobId, 'working');
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                            ),
                            child: Text(bilingual(context, 'Yes', 'ہاں')),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_trackingState == 2 || _trackingState == 5) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.rating,
                                arguments: args,
                              );
                            },
                            icon: const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            label: Text(
                              bilingual(
                                context,
                                'Rate Worker',
                                'ورکر کی درجہ بندی کریں',
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(bilingual(context, 'Done', 'مکمل')),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_trackingState == 4) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CancelJobScreen(
                              jobId: jobId,
                              workerId: worker.id,
                              workerName: worker.name,
                              workerPhone: worker.phone,
                              jobTitle: job?.categoryKey ?? worker.category,
                            ),
                          ),
                        ),
                        child: Text(
                          bilingual(
                            context,
                            'Cancel Job',
                            'کام منسوخ کریں',
                          ),
                        ),
                      ),
                    ),
                  ] else if (_trackingState == 6 || _trackingState == 7) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(bilingual(context, 'Back', 'واپس جائیں')),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CancelJobScreen(
                              jobId: jobId,
                              workerId: worker.id,
                              workerName: worker.name,
                              workerPhone: worker.phone,
                              jobTitle: job?.categoryKey ?? worker.category,
                            ),
                          ),
                        ),
                        child: Text(
                          bilingual(
                            context,
                            'Cancel Job',
                            'کام منسوخ کریں',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _MapPainter has been replaced by GoogleMap widget above.

// RatingReviewScreen has been extracted to lib/screens/rating_review_screen.dart

void showWorkerReviewsSheet(BuildContext context, String workerId) {
  final isUrdu = AppScope.of(context).isUrdu;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bilingual(
                        context,
                        'Customer Reviews & Ratings',
                        'کسٹمر جائزے اور درجہ بندی',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: streamWorkerReviews(workerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              bilingual(
                                context,
                                'No Reviews Yet',
                                'ابھی تک کوئی جائزہ نہیں ملا',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bilingual(
                                context,
                                'Complete jobs to start receiving 5-star ratings and reviews from customers.',
                                'گاہکوں سے 5 اسٹار ریٹنگز اور جائزے حاصل کرنے کے لیے کام مکمل کریں۔',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final customerName =
                          data['customerName']?.toString() ??
                          (isUrdu ? 'کسٹمر' : 'Customer');
                      final r = (data['rating'] as num?)?.toInt() ?? 5;
                      final reviewStr = data['review']?.toString() ?? '';
                      final jobTitle = data['jobTitle']?.toString() ?? '';
                      final ts = data['createdAt'] as Timestamp?;
                      final dateStr = ts != null
                          ? DateFormat('d MMM yyyy').format(ts.toDate())
                          : '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(
                                    0xFF0D9488,
                                  ).withValues(alpha: 0.15),
                                  child: Text(
                                    customerName.isNotEmpty
                                        ? customerName[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D9488),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (jobTitle.isNotEmpty)
                                        Text(
                                          jobTitle,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (sIdx) {
                                return Icon(
                                  sIdx < r
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 18,
                                );
                              }),
                            ),
                            if (reviewStr.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                reviewStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// WorkerOnboardingScreen removed (deprecated)

// WorkerDashboardScreen has been extracted to lib/screens/worker_dashboard_screen.dart

// EarningsDashboardScreen has been extracted to lib/screens/earnings_dashboard_screen.dart
