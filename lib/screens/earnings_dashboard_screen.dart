import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';
import '../services/safepay_service.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart' show bilingual, MzScaffold;

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
                                          'status': 'Active',
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
                                          'currentBalance': amount.toDouble(),
                                          'status': 'Active',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
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
                                    'status': 'Active',
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
                                    'currentBalance': amount.toDouble(),
                                    'status': 'Active',
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
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
      child: StreamBuilder<double>(
        stream: streamWorkerEarnings(),
        builder: (context, earningsSnapshot) {
          final totalEarnings = earningsSnapshot.data ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('workerId', isEqualTo: workerUid)
                .where('status', whereIn: ['accepted', 'completed'])
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, jobsSnapshot) {
              final jobs = jobsSnapshot.data?.docs ?? [];
              final completedCount = jobs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'completed';
              }).length;

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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('security_deposits')
                          .where('workerId', isEqualTo: workerUid)
                          .limit(1)
                          .snapshots(),
                      builder: (context, depositSnap) {
                        double topupBalance = 0;
                        if (depositSnap.hasData &&
                            depositSnap.data!.docs.isNotEmpty) {
                          final depData =
                              depositSnap.data!.docs.first.data()
                                  as Map<String, dynamic>;
                          topupBalance =
                              (depData['currentBalance'] as num?)?.toDouble() ??
                              0;
                        }
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'ٹاپ اپ بیلنس' : 'Top-up Balance',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isUrdu
                                        ? '${topupBalance.toStringAsFixed(0)} روپے'
                                        : 'Rs. ${topupBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                ),
                                icon: const Icon(Icons.add_card),
                                label: Text(isUrdu ? 'ٹاپ اپ کریں' : 'Top-up'),
                                onPressed: () =>
                                    _showTopUpDialog(context, isUrdu),
                              ),
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
                      final status = data['status']?.toString() ?? '';
                      final customer =
                          data['customerName']?.toString() ?? 'Customer';
                      return ListTile(
                        leading: Icon(
                          status == 'completed'
                              ? Icons.check_circle
                              : Icons.south_west,
                          color: status == 'completed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(desc),
                        subtitle: Text(
                          isUrdu
                              ? '$customer • ${status == "completed" ? "مکمل" : "جاری"}'
                              : '$customer • ${status == "completed" ? "Completed" : "In progress"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '+${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
