import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';
import '../services/safepay_service.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart' show bilingual, MzScaffold, AppRoutes;

class _ColorStatCard extends StatelessWidget {
  const _ColorStatCard({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  bool weekly = true;

  void _showTopUpDialog(BuildContext context, bool isUrdu) {
    String selectedMethod = 'Safepay';
    final amountController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isUrdu ? 'ٹاپ اپ کریں' : 'Add Top-up',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'طریقہ منتخب کریں' : 'Select Method',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Safepay',
                      child: Text(
                        isUrdu
                            ? 'سیف پے (آن لائن کارڈ)'
                            : 'Safepay (Debit / Credit Card & Online)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Cash',
                      child: Text(
                        isUrdu
                            ? 'نقد (فرنچائز / ایڈمن)'
                            : 'Pay in Cash (Franchise / Admin)',
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setModalState(() => selectedMethod = val!),
                ),
                if (selectedMethod == 'Cash') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.money, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUrdu
                                ? 'رقم فرنچائز یا آفس میں نقد جمع کروائیں'
                                : 'Deposit cash directly at franchise or admin office',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUrdu
                                ? 'سیف پے چیک آؤٹ میں ویزا، ماسٹر کارڈ، یا پے پاک سے ادا کریں'
                                : 'Pay securely via Visa, MasterCard, or PayPak in Safepay',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'رقم' : 'Amount (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amount =
                              int.tryParse(amountController.text.trim()) ?? 0;
                          if (amount <= 0) return;
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          if (selectedMethod == 'Safepay') {
                            Navigator.pop(ctx);
                            await SafepayService.instance.startPaymentFlow(
                              context: context,
                              amount: amount.toDouble(),
                              orderId:
                                  'TOPUP-${user.uid}-${DateTime.now().millisecondsSinceEpoch}',
                              title: isUrdu
                                  ? 'ورکر والٹ ٹاپ اپ'
                                  : 'Worker Wallet Top-up',
                              onPaymentSuccess: () async {
                                try {
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();
                                  final workerName =
                                      userDoc.data()?['name']?.toString() ??
                                      user.displayName ??
                                      'Worker';
                                  final currentTopup =
                                      (userDoc.data()?['topupBalance'] as num?)?.toDouble() ?? 0.0;
                                  final newBalance = currentTopup + amount;

                                  final depositQuery = await FirebaseFirestore
                                      .instance
                                      .collection('security_deposits')
                                      .where('workerId', isEqualTo: user.uid)
                                      .limit(1)
                                      .get();

                                  if (depositQuery.docs.isNotEmpty) {
                                    final docId = depositQuery.docs.first.id;
                                    await FirebaseFirestore.instance
                                        .collection('security_deposits')
                                        .doc(docId)
                                        .update({
                                          'totalDeposited':
                                              FieldValue.increment(amount),
                                          'currentBalance':
                                              FieldValue.increment(amount),
                                          'status': newBalance < 0 ? 'Negative' : 'Active',
                                          'lastTopUpAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                          'method': 'Safepay',
                                          'accountNumber': 'Online Card',
                                        });
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('security_deposits')
                                        .add({
                                          'workerId': user.uid,
                                          'workerName': workerName,
                                          'totalDeposited': amount.toDouble(),
                                          'currentBalance': newBalance,
                                          'status': newBalance < 0 ? 'Negative' : 'Active',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                          'lastTopUpAt':
                                              FieldValue.serverTimestamp(),
                                          'method': 'Safepay',
                                          'accountNumber': 'Online Card',
                                        });
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                        'topupBalance': FieldValue.increment(
                                          amount,
                                        ),
                                      }, SetOptions(merge: true));

                                  await FirebaseFirestore.instance
                                      .collection('topup_transactions')
                                      .add({
                                        'workerId': user.uid,
                                        'workerName': workerName,
                                        'amount': amount.toDouble(),
                                        'method': 'Safepay',
                                        'accountNumber': 'Online Card',
                                        'status': 'Completed',
                                        'timestamp': FieldValue.serverTimestamp(),
                                      });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isUrdu
                                              ? 'سیف پے کے ذریعے ٹاپ اپ کامیاب ہو گیا!'
                                              : 'Top-up of Rs. $amount via Safepay Successful!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF0D9488,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to update balance: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);

                          try {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            final workerName =
                                userDoc.data()?['name']?.toString() ??
                                user.displayName ??
                                'Worker';
                            final currentTopup =
                                (userDoc.data()?['topupBalance'] as num?)?.toDouble() ?? 0.0;
                            final newBalance = currentTopup + amount;

                            final depositQuery = await FirebaseFirestore
                                .instance
                                .collection('security_deposits')
                                .where('workerId', isEqualTo: user.uid)
                                .limit(1)
                                .get();

                            if (depositQuery.docs.isNotEmpty) {
                              final docId = depositQuery.docs.first.id;
                              await FirebaseFirestore.instance
                                  .collection('security_deposits')
                                  .doc(docId)
                                  .update({
                                    'totalDeposited': FieldValue.increment(
                                      amount,
                                    ),
                                    'currentBalance': FieldValue.increment(
                                      amount,
                                    ),
                                    'status': newBalance < 0 ? 'Negative' : 'Active',
                                    'lastTopUpAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'method': 'Cash',
                                    'accountNumber': 'Cash at Franchise',
                                  });
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('security_deposits')
                                  .add({
                                    'workerId': user.uid,
                                    'workerName': workerName,
                                    'totalDeposited': amount.toDouble(),
                                    'currentBalance': newBalance,
                                    'status': newBalance < 0 ? 'Negative' : 'Active',
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'lastTopUpAt': FieldValue.serverTimestamp(),
                                    'method': 'Cash',
                                    'accountNumber': 'Cash at Franchise',
                                  });
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'topupBalance': FieldValue.increment(amount),
                                }, SetOptions(merge: true));

                            await FirebaseFirestore.instance
                                .collection('topup_transactions')
                                .add({
                                  'workerId': user.uid,
                                  'workerName': workerName,
                                  'amount': amount.toDouble(),
                                  'method': 'Cash',
                                  'accountNumber': 'Cash at Franchise',
                                  'status': 'Completed',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isUrdu
                                        ? 'نقد ٹاپ اپ کامیاب ہو گیا'
                                        : 'Cash Top-up Successful!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Top-up failed: $e')),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isUrdu ? 'رقم بھیجیں' : 'Proceed to Top-up'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    final workerUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return MzScaffold(
      showBottomNav: true,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('workerId', isEqualTo: workerUid)
            .snapshots(),
        builder: (context, jobsSnapshot) {
          if (jobsSnapshot.connectionState == ConnectionState.waiting && !jobsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (jobsSnapshot.hasError) {
            debugPrint('EarningsDashboard jobs stream error: ${jobsSnapshot.error}');
          }

          final allDocs = jobsSnapshot.data?.docs ?? [];

          // Sort all jobs by createdAt descending
          final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            DateTime parseDate(dynamic d) {
              if (d is Timestamp) return d.toDate();
              if (d is DateTime) return d;
              if (d is String) return DateTime.tryParse(d) ?? DateTime(1970);
              return DateTime(1970);
            }
            return parseDate(bData['createdAt']).compareTo(parseDate(aData['createdAt']));
          });

          // All completed jobs (case-insensitive)
          final completedDocs = sortedDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status']?.toString() ?? '').toLowerCase().trim();
            return status == 'completed' || status == 'worker_completed' || status == 'paid';
          }).toList();

          // Calculate total earnings directly from completed jobs
          final double totalEarnings = completedDocs.fold<double>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'];
            return sum + ((price as num?)?.toDouble() ?? 0);
          });

          final int completedCount = completedDocs.length;

          // For recent transactions list, show completed and active jobs
          final jobs = sortedDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status']?.toString() ?? '').toLowerCase().trim();
            return status == 'completed' ||
                status == 'accepted' ||
                status == 'working' ||
                status == 'arrival_pending' ||
                status == 'worker_completed' ||
                status == 'payment_pending' ||
                status == 'worker_payment_pending';
          }).toList();

              return ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'میری آمدنی' : 'My Earnings',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isUrdu ? 'اب تک کی کل کمائی' : 'Total earnings',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUrdu
                              ? '${totalEarnings.toStringAsFixed(0)} روپے'
                              : 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ColorStatCard(
                            color: const Color(0xFFDCFCE7),
                            label: isUrdu ? 'مکمل' : 'Completed',
                            value: isUrdu
                                ? '$completedCount کام'
                                : '$completedCount jobs',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ColorStatCard(
                            color: const Color(0xFFDBEAFE),
                            label: isUrdu ? 'کل کمائی' : 'Total Earned',
                            value: isUrdu
                                ? '${totalEarnings.toStringAsFixed(0)} روپے'
                                : 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.workerIncome),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF0D9488), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'روزانہ، ہفتہ وار اور ماہانہ آمدنی' : 'Daily, Weekly & Monthly Income',
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isUrdu ? 'تفصیلی گراف اور ہدف دیکھیں' : 'View income plan and breakdown',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF94A3B8), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(workerUid)
                          .snapshots(),
                      builder: (context, userSnap) {
                        final uData = userSnap.data?.data() as Map<String, dynamic>?;
                        final double topupBalance =
                            (uData?['topupBalance'] as num?)?.toDouble() ?? 0.0;
                        final bool isNegative = topupBalance < 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isNegative ? const Color(0xFFFCA5A5) : const Color(0xFFC7D2FE),
                              width: isNegative ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (isNegative) ...[
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
                                        const SizedBox(width: 8),
                                      ],
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isUrdu
                                                ? (isNegative ? 'ڈپازٹ بیلنس (منفی)' : 'ٹاپ اپ بیلنس')
                                                : (isNegative ? 'Deposit Balance (Negative)' : 'Top-up Balance'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isNegative ? Colors.red.shade800 : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isUrdu
                                                ? (isNegative
                                                    ? '-Rs. ${topupBalance.abs().toStringAsFixed(0)}'
                                                    : '${topupBalance.toStringAsFixed(0)} روپے')
                                                : (isNegative
                                                    ? '-Rs. ${topupBalance.abs().toStringAsFixed(0)}'
                                                    : 'Rs. ${topupBalance.toStringAsFixed(0)}'),
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: isNegative ? Colors.red.shade700 : const Color(0xFF1E1B4B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isNegative ? Colors.red : const Color(0xFF4F46E5),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.add_card, size: 18),
                                    label: Text(
                                      isUrdu
                                          ? (isNegative ? 'بیلنس کلیئر کریں' : 'ٹاپ اپ کریں')
                                          : (isNegative ? 'Top Up Now' : 'Top-up'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () =>
                                        _showTopUpDialog(context, isUrdu),
                                  ),
                                ],
                              ),
                              if (isNegative) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          isUrdu
                                              ? 'پلیٹ فارم فیس کی وجہ سے بیلنس منفی ہے۔ نئے کام قبول کرنے کے لیے ٹاپ اپ کریں۔'
                                              : 'Deposit balance is negative from job fee deductions. Top up to accept new jobs.',
                                          style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isUrdu ? 'حالیہ لین دین' : 'Recent Transactions',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (jobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          isUrdu
                              ? 'ابھی تک کوئی لین دین نہیں'
                              : 'No transactions yet',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...jobs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final desc = isUrdu
                          ? (data['descriptionUr']?.toString() ??
                                data['descriptionEn']?.toString() ??
                                'Service')
                          : (data['descriptionEn']?.toString() ??
                                data['descriptionUr']?.toString() ??
                                'Service');
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final status = (data['status']?.toString() ?? '').toLowerCase().trim();
                      final customer =
                          data['customerName']?.toString() ?? 'Customer';
                      final isCompleted = status == 'completed' || status == 'worker_completed' || status == 'paid';
                      return ListTile(
                        leading: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.south_west,
                          color: isCompleted
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(desc),
                        subtitle: Text(
                          isUrdu
                              ? '$customer • ${isCompleted ? "مکمل" : "جاری"}'
                              : '$customer • ${isCompleted ? "Completed" : "In progress"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '+${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        );
      }
}
