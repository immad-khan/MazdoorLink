import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_state.dart';
import '../services/location_service.dart';
import '../services/smtp_service.dart';
import '../services/workers_service.dart';
import 'worker_tracking_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ConversationArguments;

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool online = false;
  bool _loadingOnline = true;

  @override
  void initState() {
    super.initState();
    online = WorkerPresenceService.instance.isOnline;
    _loadOnlineStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationService.instance.ensureLocationReady(context);
      }
    });
  }

  Future<void> _loadOnlineStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingOnline = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      // Guard: worker must be approved by admin
      final workerStatus =
          data?['workerStatus']?.toString() ?? data?['status']?.toString();
      final roles =
          (data?['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final hasWorkerRole =
          roles.contains('worker') || data?['role'] == 'worker';
      if (!hasWorkerRole || workerStatus != 'approved') {
        if (mounted) {
          final isUrdu = AppScope.of(context).isUrdu;
          AppScope.of(context).switchActiveRole(UserRole.customer);
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.customerHome,
            (r) => false,
          );
          showToast(
            isUrdu
                ? 'ورکر موڈ استعمال کرنے کے لیے ایڈمن کی منظوری درکار ہے'
                : 'Admin approval is required to access Worker Mode',
          );
        }
        return;
      }

      final isOn = data?['isOnline'] as bool? ?? false;
      final hasLocation = await LocationService.instance
          .isLocationEnabledAndPermitted();
      final effectiveOnline =
          (WorkerPresenceService.instance.isOnline || isOn) && hasLocation;

      if (!hasLocation && isOn) {
        await WorkerPresenceService.instance.setOnline(false);
      }

      WorkerPresenceService.instance.isOnline = effectiveOnline;
      if (effectiveOnline) {
        WorkerPresenceService.instance.startHeartbeat();
      }
      if (mounted) {
        setState(() {
          online = effectiveOnline;
          _loadingOnline = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOnline = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    if (value) {
      final allowed = await LocationService.instance
          .verifyWorkerLocationForOnline(context);
      if (!allowed || !mounted) {
        setState(() => online = false);
        return;
      }
    }
    setState(() => online = value);
    await WorkerPresenceService.instance.setOnline(value);
  }

  Future<DateTime?> _pickScheduleTime(BuildContext context) async {
    final isUrdu = AppScope.of(context).isUrdu;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return null;
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(DateTime.now())) {
      showToast(
        isUrdu
            ? 'براہ کرم مستقبل کا وقت منتخب کریں'
            : 'Please select a future time',
      );
      return null;
    }
    return scheduled;
  }

  void _showNegativeDepositDialog(BuildContext context, double balance) {
    final isUrdu = AppScope.of(context).isUrdu;
    final absAmount = balance.abs().toStringAsFixed(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isUrdu ? 'بیلنس منفی ہے' : 'Negative Deposit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                children: [
                  Text(
                    isUrdu ? 'موجودہ سیکیورٹی ڈپازٹ بیلنس' : 'Current Deposit Balance',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '-Rs. $absAmount',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isUrdu
                  ? 'سابقہ کاموں سے ایڈمن / پلیٹ فارم فیس کٹنے کے بعد آپ کا ڈپازٹ بیلنس منفی ہو گیا ہے۔\n\nنئے کام قبول کرنے کے لیے پہلے اپنے ڈپازٹ اکاؤنٹ میں رقم جمع کروائیں۔'
                  : 'Your deposit balance is negative due to platform fee deductions from previous jobs.\n\nPlease add funds (top up) to your deposit account before accepting new jobs.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isUrdu ? 'منسوخ' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.workerEarnings);
            },
            icon: const Icon(Icons.add_card, size: 18),
            label: Text(
              isUrdu ? 'رقم جمع کروائیں' : 'Add Deposit / Top Up',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInstantAcceptJob(
    BuildContext context,
    String jobId,
    double price,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final depositBalance = await getWorkerDepositBalance(user.uid);
    if (depositBalance < 0) {
      if (!mounted) return;
      _showNegativeDepositDialog(context, depositBalance);
      return;
    }

    await updateJobStatus(jobId, 'accepted');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerTrackingScreen(jobPrice: price, jobId: jobId),
      ),
    );
  }

  Future<void> _handleScheduleJob(BuildContext context, String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final depositBalance = await getWorkerDepositBalance(user.uid);
    if (depositBalance < 0) {
      if (!mounted) return;
      _showNegativeDepositDialog(context, depositBalance);
      return;
    }

    final isUrdu = AppScope.of(context).isUrdu;
    final scheduled = await _pickScheduleTime(context);
    if (scheduled == null || !mounted) return;
    await scheduleProposedJob(jobId, scheduled);
    if (!mounted) return;
    _notifyScheduleProposal(jobId, scheduled);

    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();
      final data = jobDoc.data();
      final customerId = data?['customerId']?.toString();
      final customerName = data?['customerName']?.toString() ?? 'Customer';
      final formattedTime = DateFormat('hh:mm a, d MMM yyyy').format(scheduled);
      if (customerId != null && customerId.isNotEmpty) {
        final convId = await createConversation(
          otherUserId: customerId,
          otherUserName: customerName,
          otherUserImage: '',
        );
        await sendMessage(
          convId,
          'I would like to schedule this work for $formattedTime. Please accept or let me know if another time works better.',
        );
      }
    } catch (_) {}

    showToast(
      isUrdu
          ? 'شیڈول تجویز گاہک کو بھیج دی گئی'
          : 'Schedule proposal sent to customer',
    );
  }

  Future<void> _notifyScheduleProposal(String jobId, DateTime scheduled) async {
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();
      final data = jobDoc.data();
      if (data == null) return;
      final customerId = data['customerId']?.toString();
      final customerEmail = customerId != null
          ? await getUserEmail(customerId)
          : null;
      if (customerEmail == null) return;
      await SmtpService.sendScheduleProposalEmail(
        email: customerEmail,
        workerName: data['workerName']?.toString() ?? 'Worker',
        jobDesc: data['descriptionEn']?.toString() ?? 'Service',
        scheduledTime: scheduled,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final user = FirebaseAuth.instance.currentUser;

    return MzScaffold(
      showBottomNav: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: streamCurrentUserData(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final name =
                  data?['name']?.toString() ?? (isUrdu ? 'ورکر' : 'Worker');
              final categoryUr = data?['categoryNameUr']?.toString() ?? '';
              final categoryEn = data?['categoryNameEn']?.toString() ?? '';
              final profileImage = data?['profileImage']?.toString() ?? '';
              final double ratingVal =
                  (data?['rating'] as num?)?.toDouble() ?? 0.0;
              final int reviewsVal = (data?['reviews'] as num?)?.toInt() ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'W')
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu && categoryUr.isNotEmpty
                              ? categoryUr
                              : categoryEn,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              ratingVal > 0
                                  ? ratingVal.toStringAsFixed(1)
                                  : (isUrdu ? 'نیا' : 'New'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($reviewsVal ${isUrdu ? 'جائزے' : 'reviews'})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF0D9488),
                            size: 26,
                          ),
                          tooltip: isUrdu ? 'میرے کام' : 'My Jobs',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.sharedHistory,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.exit_to_app_rounded,
                            color: Color(0xFF64748B),
                            size: 24,
                          ),
                          tooltip: isUrdu ? 'باہر نکلیں' : 'Exit Mazdoorlink',
                          onPressed: () async {
                            final shouldExit =
                                await showExitMazdoorlinkDialog(context);
                            if (shouldExit == true) {
                              await scope.logout();
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
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<AppLocation>(
                    valueListenable:
                        LocationService.instance.currentLocationNotifier,
                    builder: (context, loc, _) {
                      return InkWell(
                        onTap: () => LocationService.instance
                            .showAreaPickerDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12, top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D9488,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF0D9488),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isUrdu
                                              ? 'آپ کا ورکنگ علاقہ'
                                              : 'Working Area',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF0D9488),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF0D9488,
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'ISB / RWP',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              color: Color(0xFF0D9488),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loc.shortDisplayNameBilingual(isUrdu),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F766E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    isUrdu ? 'تبدیل' : 'Change',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFF0D9488),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (((data?['topupBalance'] as num?)?.toDouble() ?? 0.0) < 0) ...[
                    Builder(
                      builder: (context) {
                        final topupBal = (data?['topupBalance'] as num?)!.toDouble();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUrdu ? 'سیکیورٹی ڈپازٹ بیلنس منفی ہے' : 'Deposit Balance Negative',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isUrdu
                                          ? 'رقم جمع کروائیں تاکہ نوکریاں قبول کر سکیں (-Rs. ${topupBal.abs().toStringAsFixed(0)})'
                                          : 'Top up deposit to accept jobs (-Rs. ${topupBal.abs().toStringAsFixed(0)})',
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.workerEarnings),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(isUrdu ? 'رقم جمع کریں' : 'Top Up'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: online ? const Color(0xFF0D9488) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        online
                            ? (isUrdu ? 'آپ آن لائن ہیں' : 'You are online')
                            : (isUrdu ? 'آپ آف لائن ہیں' : 'You are offline'),
                        style: TextStyle(
                          color: online ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            online ? Icons.check_circle : Icons.location_on,
                            size: 13,
                            color: online ? Colors.white70 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              online
                                  ? (isUrdu
                                        ? 'لوکیشن فعال ہے • جابز موصول ہو رہی ہیں'
                                        : 'Location Active • Receiving Jobs')
                                  : (isUrdu
                                        ? 'آن لائن ہونے کے لیے لوکیشن درکار ہے'
                                        : 'Location required to go online'),
                              style: TextStyle(
                                fontSize: 11,
                                color: online ? Colors.white70 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: online,
                  activeColor: Colors.white,
                  onChanged: _loadingOnline ? null : _toggleOnline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.sharedHistory),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF0D9488),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bilingual(context, 'My Jobs', 'میرے کام'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          bilingual(
                            context,
                            'Ongoing, Scheduled, Completed & Cancelled',
                            'جاری، شیڈول، مکمل اور منسوخ کام',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          if (online && user != null)
            StreamBuilder<QuerySnapshot>(
              stream: streamWorkerJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('WorkerJobsError: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allJobs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final jobs = allJobs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final expiresAtStr = data['expiresAt']?.toString();
                  if (expiresAtStr != null) {
                    final expiresAt = DateTime.tryParse(expiresAtStr);
                    if (expiresAt != null && expiresAt.isBefore(now))
                      return false;
                  }
                  return true;
                }).toList();

                jobs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aCreated = aData['createdAt'];
                  final bCreated = bData['createdAt'];
                  final aTime =
                      (aCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bTime =
                      (bCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });

                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        bilingual(
                          context,
                          'No new jobs yet',
                          'ابھی تک کوئی نیا کام نہیں',
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: jobs.map((doc) {
                    final jobData = doc.data() as Map<String, dynamic>;
                    final jobId = doc.id;
                    final descEn =
                        jobData['descriptionEn']?.toString() ?? 'Service';
                    final descUr =
                        jobData['descriptionUr']?.toString() ?? 'سروس';
                    final price = (jobData['price'] as num?)?.toDouble() ?? 0;
                    final payment =
                        jobData['paymentMethod']?.toString() ?? 'Cash';
                    final customerName =
                        jobData['customerName']?.toString() ?? 'Customer';

                    String remainingTime = '';
                    final expiresAtStr = jobData['expiresAt']?.toString();
                    if (expiresAtStr != null) {
                      final expiresAt = DateTime.tryParse(expiresAtStr);
                      if (expiresAt != null) {
                        final diff = expiresAt.difference(now);
                        if (diff.isNegative) {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        } else if (diff.inDays > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inDays} دن باقی'
                              : '${diff.inDays}d remaining';
                        } else if (diff.inHours > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inHours} گھنٹے باقی'
                              : '${diff.inHours}h remaining';
                        } else if (diff.inMinutes > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inMinutes} منٹ باقی'
                              : '${diff.inMinutes}min remaining';
                        } else {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        }
                      }
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 260),
                      builder: (_, value, child) => Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Color(0xFF0D9488),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'نیا کام!' : 'New Job!',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isUrdu ? descUr : descEn,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${bilingual(context, 'Customer:', 'گاہک:')} $customerName',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              if (remainingTime.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  remainingTime,
                                  style: TextStyle(
                                    color:
                                        remainingTime.contains('Expired') ||
                                            remainingTime.contains('ختم')
                                        ? Colors.red
                                        : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${bilingual(context, 'Payment:', 'ادائیگی:')} $payment',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Reject
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        updateJobStatus(jobId, 'rejected');
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isUrdu
                                                  ? 'کام رد کر دیا گیا'
                                                  : 'Job rejected',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        isUrdu ? 'رد کریں' : 'Reject',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Schedule
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _handleScheduleJob(context, jobId),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber.shade800,
                                        side: BorderSide(
                                          color: Colors.amber.shade800,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        isUrdu ? 'شیڈول' : 'Schedule',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Accept (Instantly accepts and starts workflow of maps)
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _handleInstantAcceptJob(
                                        context,
                                        jobId,
                                        price,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0D9488,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        isUrdu ? 'قبول کریں' : 'Accept',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          if (online && user != null)
            StreamBuilder<QuerySnapshot>(
              stream: streamWorkerUpcomingJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final upcoming =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['scheduledReminderAt'] != null;
                    }).toList()..sort((a, b) {
                      final at =
                          (a.data()
                                  as Map<
                                    String,
                                    dynamic
                                  >)['scheduledReminderAt']
                              as Timestamp?;
                      final bt =
                          (b.data()
                                  as Map<
                                    String,
                                    dynamic
                                  >)['scheduledReminderAt']
                              as Timestamp?;
                      return ((at?.toDate()) ?? DateTime(9999)).compareTo(
                        (bt?.toDate()) ?? DateTime(9999),
                      );
                    });
                if (upcoming.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      bilingual(
                        context,
                        'Upcoming Scheduled',
                        'آئندہ شیڈول کام',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final scheduled =
                          (data['scheduledReminderAt'] as Timestamp?)?.toDate();
                      final confirmed =
                          data['scheduleConfirmed'] as bool? ?? false;
                      final descEn =
                          data['descriptionEn']?.toString() ?? 'Service';
                      final descUr =
                          data['descriptionUr']?.toString() ?? 'سروس';
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final timeStr = scheduled != null
                          ? DateFormat('hh:mm a, d MMM').format(scheduled)
                          : '';
                      final isPast =
                          scheduled != null &&
                          scheduled.isBefore(DateTime.now());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: confirmed
                                ? const Color(0xFF0D9488)
                                : Colors.amber.shade700,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isPast
                                ? Icons.notifications_active
                                : Icons.schedule,
                            color: isPast
                                ? const Color(0xFF0D9488)
                                : Colors.amber.shade700,
                          ),
                          title: Text(isUrdu ? descUr : descEn),
                          subtitle: Text(
                            confirmed
                                ? (isPast
                                      ? bilingual(
                                          context,
                                          'Scheduled time reached — start the job',
                                          'شیڈول وقت ہو گیا — کام شروع کریں',
                                        )
                                      : '${bilingual(context, 'Confirmed for', 'تصدیق شدہ وقت')} $timeStr')
                                : '${bilingual(context, 'Waiting for customer approval', 'گاہک کی منظوری کا انتظار')} • $timeStr',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerTrackingScreen(
                                    jobPrice: price,
                                    jobId: doc.id,
                                  ),
                                ),
                              );
                            },
                            child: Text(bilingual(context, 'Track', 'ٹریک')),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          if (online && user != null)
            StreamBuilder<QuerySnapshot>(
              stream: streamWorkerScheduledJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData)
                  return const SizedBox.shrink();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bilingual(
                            context,
                            'Proposed Schedules',
                            'تجویز کردہ شیڈول',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final scheduled =
                          (data['scheduledReminderAt'] as Timestamp?)?.toDate();
                      final confirmed =
                          data['scheduleConfirmed'] as bool? ?? false;
                      final descEn =
                          data['descriptionEn']?.toString() ?? 'Service';
                      final descUr =
                          data['descriptionUr']?.toString() ?? 'سروس';
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final timeStr = scheduled != null
                          ? DateFormat('hh:mm a, d MMM').format(scheduled)
                          : '';
                      final isPast =
                          scheduled != null &&
                          scheduled.isBefore(DateTime.now());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: confirmed
                                ? const Color(0xFF0D9488)
                                : Colors.amber.shade400,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: confirmed
                                        ? const Color(0xFF0D9488)
                                        : Colors.amber.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isUrdu ? descUr : descEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs. $price',
                                    style: const TextStyle(
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    confirmed
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    size: 14,
                                    color: confirmed
                                        ? const Color(0xFF0D9488)
                                        : Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      confirmed
                                          ? bilingual(
                                              context,
                                              'Customer approved — ready to start',
                                              'گاہک نے منظور کیا — شروع کریں',
                                            )
                                          : bilingual(
                                              context,
                                              'Waiting for customer approval',
                                              'گاہک کی منظوری کا انتظار ہے',
                                            ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: confirmed
                                            ? const Color(0xFF0D9488)
                                            : Colors.amber.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (confirmed || isPast) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: Text(
                                      bilingual(
                                        context,
                                        'Start Job Now',
                                        'ابھی کام شروع کریں',
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                    ),
                                    onPressed: () async {
                                      await startScheduledJob(doc.id);
                                      if (!mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkerTrackingScreen(
                                            jobPrice: price,
                                            jobId: doc.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.chat_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    bilingual(
                                      context,
                                      'Message Customer',
                                      'گاہک کو میسیج کریں',
                                    ),
                                  ),
                                  onPressed: () async {
                                    final customerId = data['customerId']
                                        ?.toString();
                                    if (customerId == null ||
                                        customerId.isEmpty)
                                      return;
                                    final customerName =
                                        data['customerName']?.toString() ??
                                        'Customer';
                                    final existingId =
                                        await findExistingConversation(
                                          customerId,
                                        );
                                    if (!context.mounted) return;
                                    if (existingId != null) {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.sharedConversation,
                                        arguments: ConversationArguments(
                                          conversationId: existingId,
                                          otherName: customerName,
                                          otherImage: '',
                                        ),
                                      );
                                    } else {
                                      final newId = await createConversation(
                                        otherUserId: customerId,
                                        otherUserName: customerName,
                                        otherUserImage: '',
                                      );
                                      if (context.mounted) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.sharedConversation,
                                          arguments: ConversationArguments(
                                            conversationId: newId,
                                            otherName: customerName,
                                            otherImage: '',
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
