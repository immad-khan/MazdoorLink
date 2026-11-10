import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_state.dart';
import '../services/workers_service.dart';
import '../data/mock_data.dart';
import 'issue_selection_screen.dart';
import 'worker_tracking_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        TrackingArguments,
        ConversationArguments,
        ProfileArguments;
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  // 0 = Ongoing/Active, 1 = Scheduled, 2 = Completed, 3 = Cancelled
  int _tab = 0;

  void _showCancelledJobDialog(BuildContext context, Map<String, dynamic> data) {
    final isUrdu = AppScope.of(context).isUrdu;
    final descEn = data['descriptionEn']?.toString() ?? 'Service';
    final descUr = data['descriptionUr']?.toString() ?? 'سروس';
    final price = data['price'];
    final priceStr = price != null ? 'Rs. ${(price as num).toStringAsFixed(0)}' : '';
    final reason = data['cancelReason']?.toString() ?? (isUrdu ? 'کوئی وجہ فراہم نہیں کی گئی' : 'No reason provided');
    final role = AppScope.of(context).role;
    final otherPerson = role == UserRole.worker
        ? (data['customerName']?.toString() ?? 'Customer')
        : (data['workerName']?.toString() ?? 'Worker');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bilingual(context, 'Cancelled Job Details', 'منسوخ شدہ کام کی تفصیلات'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? descUr : descEn,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (priceStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                priceStr,
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  role == UserRole.worker ? Icons.person_outline : Icons.handyman_outlined,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  role == UserRole.worker
                      ? '${bilingual(context, 'Customer:', 'گاہک:')} $otherPerson'
                      : '${bilingual(context, 'Worker:', 'ورکر:')} $otherPerson',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bilingual(context, 'Cancellation Reason', 'منسوخی کی وجہ'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(bilingual(context, 'Close', 'بند کریں')),
          ),
        ],
      ),
    );
  }

  String _bookingStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return bilingual(context, 'Pending', 'زیر التوا');
      case 'scheduled':
        return bilingual(context, 'Scheduled', 'شیڈول');
      case 'accepted':
        return bilingual(context, 'Worker on the way', 'ورکر راستے میں ہے');
      case 'arrival_pending':
        return bilingual(
          context,
          'Arrival confirmation pending',
          'آمد کی تصدیق باقی ہے',
        );
      case 'working':
        return bilingual(
          context,
          'Working at customer',
          'کسٹمر کے مقام پر کام جاری ہے',
        );
      case 'worker_completed':
        return bilingual(
          context,
          'Customer completion pending',
          'کسٹمر کی تکمیل تصدیق باقی ہے',
        );
      case 'payment_pending':
        return bilingual(context, 'Payment pending', 'ادائیگی زیر التوا');
      case 'worker_payment_pending':
        return bilingual(
          context,
          'Awaiting payment confirmation',
          'ادائیگی کی تصدیق زیر التوا',
        );
      case 'payment_disputed':
        return bilingual(context, 'Payment disputed', 'ادائیگی کا تنازع');
      case 'completed':
        return bilingual(context, 'Completed', 'مکمل');
      case 'arrival_declined':
        return bilingual(context, 'Arrival declined', 'آمد مسترد');
      case 'rejected':
        return bilingual(context, 'Rejected', 'مسترد');
      case 'cancelled':
        return bilingual(context, 'Cancelled', 'منسوخ شدہ');
      default:
        return status;
    }
  }

  static const List<String> _activeStatuses = [
    'pending',
    'accepted',
    'arrival_pending',
    'working',
    'worker_completed',
    'payment_pending',
    'worker_payment_pending',
    'payment_disputed',
  ];

  static const List<String> _scheduledStatuses = ['scheduled'];

  static const List<String> _completedStatuses = ['completed'];

  static const List<String> _cancelledStatuses = [
    'cancelled',
    'rejected',
    'arrival_declined',
  ];

  Stream<QuerySnapshot> _buildStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    final role = AppScope.of(context).role;
    final uidField = role == UserRole.worker ? 'workerId' : 'customerId';
    return FirebaseFirestore.instance
        .collection('jobs')
        .where(uidField, isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: true,
      title: AppScope.of(context).role == UserRole.worker
          ? bilingual(context, 'My Jobs', 'میرے کام')
          : bilingual(context, 'My Bookings', 'میری بکنگز'),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(bilingual(context, 'Ongoing', 'جاری')),
                  selected: _tab == 0,
                  selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(bilingual(context, 'Scheduled', 'شیڈول')),
                  selected: _tab == 1,
                  selectedColor: Colors.amber.shade100,
                  onSelected: (_) => setState(() => _tab = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(bilingual(context, 'Completed', 'مکمل')),
                  selected: _tab == 2,
                  selectedColor: Colors.green.shade100,
                  onSelected: (_) => setState(() => _tab = 2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(bilingual(context, 'Cancelled', 'منسوخ')),
                  selected: _tab == 3,
                  selectedColor: Colors.red.shade100,
                  onSelected: (_) => setState(() => _tab = 3),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        bilingual(
                          context,
                          'Failed to load bookings. Please try again.',
                          'بکنگز لوڈ کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final List<String> statusFilter = _tab == 0
                    ? _activeStatuses
                    : _tab == 1
                    ? _scheduledStatuses
                    : _tab == 2
                    ? _completedStatuses
                    : _cancelledStatuses;
                final filtered =
                    docs.where((doc) {
                      final status =
                          (doc.data() as Map<String, dynamic>)['status']
                              ?.toString() ??
                          '';
                      return statusFilter.contains(status);
                    }).toList()..sort((a, b) {
                      final aTime =
                          ((a.data() as Map<String, dynamic>)['createdAt']
                                  as Timestamp?)
                              ?.toDate() ??
                          DateTime(2000);
                      final bTime =
                          ((b.data() as Map<String, dynamic>)['createdAt']
                                  as Timestamp?)
                              ?.toDate() ??
                          DateTime(2000);
                      return bTime.compareTo(aTime);
                    });

                if (filtered.isEmpty) {
                  final emptyText = _tab == 0
                      ? bilingual(context, 'No ongoing jobs', 'کوئی جاری کام نہیں')
                      : _tab == 1
                      ? bilingual(context, 'No scheduled jobs', 'کوئی شیڈول کام نہیں')
                      : _tab == 2
                      ? bilingual(context, 'No completed jobs', 'کوئی مکمل کام نہیں')
                      : bilingual(context, 'No cancelled jobs', 'کوئی منسوخ شدہ کام نہیں');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tab == 3
                                ? Icons.cancel_outlined
                                : _tab == 2
                                ? Icons.task_alt
                                : _tab == 1
                                ? Icons.calendar_month_outlined
                                : Icons.assignment_outlined,
                            size: 48,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emptyText,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status']?.toString() ?? '';
                    final descEn = data['descriptionEn']?.toString() ?? '';
                    final descUr = data['descriptionUr']?.toString() ?? '';
                    final price = data['price'];
                    final priceStr = price != null
                        ? 'Rs. ${(price as num).toStringAsFixed(0)}'
                        : '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeStr = createdAt != null
                        ? DateFormat('d MMM yyyy').format(createdAt.toDate())
                        : '';

                    String? reminderLine;
                    final scheduledRaw = data['scheduledReminderAt'];
                    final schedTime = scheduledRaw is Timestamp
                        ? DateFormat('hh:mm a').format(scheduledRaw.toDate())
                        : '';
                    if (scheduledRaw is Timestamp) {
                      final confirmed =
                          data['scheduleConfirmed'] as bool? ?? false;
                      reminderLine = confirmed
                          ? '${bilingual(context, 'Reminder: worker arrives at', 'یاد دہانی: ورکر آئے گا')} $schedTime'
                          : '${bilingual(context, 'Schedule approval pending', 'شیڈول کی منظوری زیر التوا')} • $schedTime';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          if (_tab == 3) {
                            _showCancelledJobDialog(context, data);
                            return;
                          }
                          if (_tab != 2 &&
                              AppScope.of(context).role == UserRole.worker) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkerTrackingScreen(
                                  jobPrice: (price as num?)?.toDouble() ?? 0,
                                  jobId: doc.id,
                                ),
                              ),
                            );
                          } else if (_tab == 0) {
                            final workerId = data['workerId']?.toString() ?? '';
                            if (workerId.isNotEmpty) {
                              final workerDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(workerId)
                                  .get();
                              final workerData = workerDoc.data();
                              if (workerData != null && context.mounted) {
                                final worker = WorkerModel.fromFirestore(
                                  workerData,
                                  docId: workerDoc.id,
                                );
                                final jobArgs = JobPostingArguments(
                                  descriptionEn: descEn,
                                  descriptionUr: descUr,
                                  price: (price as num?)?.toDouble() ?? 0,
                                  categoryKey:
                                      data['categoryKey']?.toString() ?? '',
                                  paymentMethod:
                                      data['paymentMethod']?.toString() ??
                                      'Cash',
                                  customerLatitude:
                                      (data['customerLatitude'] as num?)
                                          ?.toDouble(),
                                  customerLongitude:
                                      (data['customerLongitude'] as num?)
                                          ?.toDouble(),
                                );
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.tracking,
                                  arguments: TrackingArguments(
                                    worker: worker,
                                    job: jobArgs,
                                    jobId: doc.id,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    status == 'completed'
                                        ? Icons.check_circle
                                        : status == 'scheduled'
                                        ? Icons.calendar_month
                                        : (status == 'cancelled' ||
                                                status == 'rejected' ||
                                                status == 'arrival_declined')
                                            ? Icons.cancel
                                            : Icons.schedule,
                                    color: status == 'completed'
                                        ? Colors.green
                                        : status == 'scheduled'
                                        ? Colors.amber.shade700
                                        : (status == 'cancelled' ||
                                                status == 'rejected' ||
                                                status == 'arrival_declined')
                                            ? Colors.red
                                            : const Color(0xFF0D9488),
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
                                    priceStr,
                                    style: const TextStyle(
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$timeStr • ${_bookingStatusLabel(context, status)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              if (status == 'cancelled' ||
                                  status == 'rejected' ||
                                  status == 'arrival_declined') ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.cancel_outlined,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            bilingual(
                                              context,
                                              'Cancelled Job',
                                              'منسوخ شدہ کام',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (data['cancelReason'] != null &&
                                          data['cancelReason']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '${bilingual(context, 'Reason:', 'وجہ:')} ${data['cancelReason']}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              if (reminderLine != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  reminderLine,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              // --- Scheduled tab actions ---
                              if (_tab == 1) ...[
                                const SizedBox(height: 12),
                                if (AppScope.of(context).role ==
                                    UserRole.worker) ...[
                                  // Worker: start the job
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
                                        backgroundColor: const Color(
                                          0xFF0D9488,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await startScheduledJob(doc.id);
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  WorkerTrackingScreen(
                                                    jobPrice:
                                                        (price as num?)
                                                            ?.toDouble() ??
                                                        0,
                                                    jobId: doc.id,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.chat_outlined),
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
                                          final newId =
                                              await createConversation(
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
                                ] else ...[
                                  // Customer: Approve / Decline / Message worker
                                  if (!(data['scheduleConfirmed'] as bool? ??
                                      false)) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            color: Color(0xFFB45309),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              bilingual(
                                                context,
                                                schedTime.isNotEmpty
                                                    ? 'Worker wants to schedule this work to $schedTime. Accept or Chat?'
                                                    : 'Worker wants to schedule this work. Accept or Chat?',
                                                schedTime.isNotEmpty
                                                    ? 'ورکر اس کام کو $schedTime پر شیڈول کرنا چاہتا ہے۔ منظور کریں یا بات چیت کریں؟'
                                                    : 'ورکر اس کام کو شیڈول کرنا چاہتا ہے۔ منظور کریں یا بات چیت کریں؟',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF0D9488,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFF0D9488),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.chat_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              bilingual(
                                                context,
                                                'Chat',
                                                'چیٹ کریں',
                                              ),
                                            ),
                                            onPressed: () async {
                                              final workerId = data['workerId']
                                                  ?.toString();
                                              if (workerId == null ||
                                                  workerId.isEmpty)
                                                return;
                                              final workerName =
                                                  data['workerName']
                                                      ?.toString() ??
                                                  'Worker';
                                              final existingId =
                                                  await findExistingConversation(
                                                    workerId,
                                                  );
                                              if (!context.mounted) return;
                                              if (existingId != null) {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.sharedConversation,
                                                  arguments:
                                                      ConversationArguments(
                                                        conversationId:
                                                            existingId,
                                                        otherName: workerName,
                                                        otherImage: '',
                                                      ),
                                                );
                                              } else {
                                                final newId =
                                                    await createConversation(
                                                      otherUserId: workerId,
                                                      otherUserName: workerName,
                                                      otherUserImage: '',
                                                    );
                                                if (context.mounted) {
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes
                                                        .sharedConversation,
                                                    arguments:
                                                        ConversationArguments(
                                                          conversationId: newId,
                                                          otherName: workerName,
                                                          otherImage: '',
                                                        ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF0D9488,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              size: 16,
                                            ),
                                            label: Text(
                                              bilingual(
                                                context,
                                                'Accept',
                                                'منظور کریں',
                                              ),
                                            ),
                                            onPressed: () async {
                                              await acceptScheduledJob(doc.id);
                                              if (context.mounted)
                                                setState(() {});
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF0D9488),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          bilingual(
                                            context,
                                            'Schedule approved',
                                            'شیڈول منظور',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF0D9488),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.chat_outlined),
                                        label: Text(
                                          bilingual(
                                            context,
                                            'Message Worker',
                                            'ورکر کو میسیج کریں',
                                          ),
                                        ),
                                        onPressed: () async {
                                          final workerId = data['workerId']
                                              ?.toString();
                                          if (workerId == null ||
                                              workerId.isEmpty)
                                            return;
                                          final workerName =
                                              data['workerName']?.toString() ??
                                              'Worker';
                                          final existingId =
                                              await findExistingConversation(
                                                workerId,
                                              );
                                          if (!context.mounted) return;
                                          if (existingId != null) {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.sharedConversation,
                                              arguments: ConversationArguments(
                                                conversationId: existingId,
                                                otherName: workerName,
                                                otherImage: '',
                                              ),
                                            );
                                          } else {
                                            final newId =
                                                await createConversation(
                                                  otherUserId: workerId,
                                                  otherUserName: workerName,
                                                  otherUserImage: '',
                                                );
                                            if (context.mounted) {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.sharedConversation,
                                                arguments:
                                                    ConversationArguments(
                                                      conversationId: newId,
                                                      otherName: workerName,
                                                      otherImage: '',
                                                    ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                              // --- Past tab actions (Completed jobs & Ratings) ---
                              if (_tab == 2 && status == 'completed') ...[
                                const SizedBox(height: 10),
                                if (data['reviewed'] == true ||
                                    data['customerRating'] != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFD97706),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${bilingual(context, 'Rated', 'درجہ بندی')}: ${(data['customerRating'] as num?)?.toStringAsFixed(1) ?? '5.0'} / 5.0',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (data['customerReview'] != null &&
                                            data['customerReview']
                                                .toString()
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '"${data['customerReview']}"',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF78350F),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else if (AppScope.of(context).role ==
                                    UserRole.customer) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      icon: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      label: Text(
                                        bilingual(
                                          context,
                                          'Rate Worker',
                                          'ورکر کی درجہ بندی کریں',
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0D9488,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final workerId =
                                            data['workerId']?.toString() ?? '';
                                        final workerName =
                                            data['workerName']?.toString() ??
                                            'Worker';
                                        final workerCategory =
                                            data['categoryKey']?.toString() ??
                                            '';
                                        WorkerModel? worker;
                                        if (workerId.isNotEmpty) {
                                          try {
                                            final wDoc = await FirebaseFirestore
                                                .instance
                                                .collection('users')
                                                .doc(workerId)
                                                .get();
                                            final wData = wDoc.data();
                                            if (wData != null) {
                                              worker =
                                                  WorkerModel.fromFirestore(
                                                    wData,
                                                    docId: wDoc.id,
                                                  );
                                            }
                                          } catch (_) {}
                                        }
                                        if (!context.mounted) return;
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.rating,
                                          arguments: TrackingArguments(
                                            jobId: doc.id,
                                            worker:
                                                worker ??
                                                WorkerModel(
                                                  id: workerId,
                                                  name: workerName,
                                                  phone: '',
                                                  category: workerCategory,
                                                  rating: 5.0,
                                                  reviews: 0,
                                                  image: '',
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
