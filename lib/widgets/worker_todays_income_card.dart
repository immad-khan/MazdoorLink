import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../screens/mazdoor_flow.dart' show AppRoutes;
import '../screens/worker_income_screen.dart';

class WorkerTodaysIncomeCard extends StatefulWidget {
  const WorkerTodaysIncomeCard({super.key});

  @override
  State<WorkerTodaysIncomeCard> createState() => _WorkerTodaysIncomeCardState();
}

class _WorkerTodaysIncomeCardState extends State<WorkerTodaysIncomeCard> {
  double _dailyGoal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDailyGoal();
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    double? goal;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        goal = (doc.data()?['income_goal_day'] as num?)?.toDouble();
      } catch (_) {}
    }

    goal ??= prefs.getDouble('income_goal_day') ?? 0.0;

    if (mounted) {
      setState(() => _dailyGoal = goal!);
    }
  }

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
    Navigator.pushNamed(context, AppRoutes.workerIncome).then((_) {
      _loadDailyGoal();
    });
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
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                        Text(
                          isUrdu ? 'آج کی آمدنی' : "Today's income",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Amount: PKR 0
                    Text(
                      'PKR ${todayIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bottom pill: "+ Add daily goal" or current goal
                    InkWell(
                      onTap: () => _navigateToDetail(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _dailyGoal > 0 ? Icons.flag_rounded : Icons.add,
                              color: _dailyGoal > 0 ? const Color(0xFFBEF264) : Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dailyGoal > 0
                                  ? (isUrdu
                                      ? 'ہدف: PKR ${_dailyGoal.toStringAsFixed(0)}'
                                      : 'Goal: PKR ${_dailyGoal.toStringAsFixed(0)}')
                                  : (isUrdu ? 'روزانہ کا ہدف شامل کریں' : 'Add daily goal'),
                              style: TextStyle(
                                color: _dailyGoal > 0 ? const Color(0xFFBEF264) : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
