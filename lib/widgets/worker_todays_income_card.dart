import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_state.dart';
import '../screens/mazdoor_flow.dart' show AppRoutes;

class WorkerTodaysIncomeCard extends StatelessWidget {
  const WorkerTodaysIncomeCard({super.key});

  DateTime _parseJobDate(dynamic d) {
    if (d is Timestamp) return d.toDate();
    if (d is DateTime) return d;
    if (d is String) return DateTime.tryParse(d) ?? DateTime(1970);
    return DateTime(1970);
  }

  DateTime _getJobEffectiveDate(Map<String, dynamic> data) {
    if (data['completedAt'] != null) return _parseJobDate(data['completedAt']);
    if (data['workerCompletedAt'] != null) return _parseJobDate(data['workerCompletedAt']);
    if (data['statusUpdatedAt'] != null) return _parseJobDate(data['statusUpdatedAt']);
    if (data['createdAt'] != null) return _parseJobDate(data['createdAt']);
    return DateTime.now();
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.workerIncome);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    final user = FirebaseAuth.instance.currentUser;
    final workerUid = user?.uid ?? '';

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('workerId', isEqualTo: workerUid)
          .snapshots(),
      builder: (context, snapshot) {
        double todayIncome = 0.0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status']?.toString() ?? '').toLowerCase().trim();
            final isCompleted = status == 'completed' || status == 'worker_completed' || status == 'paid';
            if (!isCompleted) continue;

            final jobDate = _getJobEffectiveDate(data);
            if (!jobDate.isBefore(startOfToday) && !jobDate.isAfter(endOfToday)) {
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              todayIncome += price;
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToDetail(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: "Today's income" and chevron
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF0D9488),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUrdu ? 'آج کی آمدنی' : "Today's income",
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Amount: PKR 0
                    Text(
                      'PKR ${todayIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom helper link: View breakdown
                    Row(
                      children: [
                        Text(
                          isUrdu ? 'تفصیلات اور گراف دیکھیں' : 'View income breakdown',
                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF0D9488),
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
