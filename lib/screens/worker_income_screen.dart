import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_state.dart';
import 'mazdoor_flow.dart' show AppRoutes;

enum IncomePeriod { day, week, month }

class WorkerIncomeScreen extends StatefulWidget {
  final IncomePeriod initialPeriod;

  const WorkerIncomeScreen({
    super.key,
    this.initialPeriod = IncomePeriod.day,
  });

  @override
  State<WorkerIncomeScreen> createState() => _WorkerIncomeScreenState();
}

class _WorkerIncomeScreenState extends State<WorkerIncomeScreen> {
  late IncomePeriod _selectedPeriod;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _onPeriodChanged(IncomePeriod period) {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
      });
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case IncomePeriod.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case IncomePeriod.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case IncomePeriod.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case IncomePeriod.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case IncomePeriod.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case IncomePeriod.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
      }
    });
  }

  DateTimeRange _getDateRange() {
    switch (_selectedPeriod) {
      case IncomePeriod.day:
        final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
        final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case IncomePeriod.week:
        // Week starting Monday
        final weekday = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
        final monday = _selectedDate.subtract(Duration(days: weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final sunday = monday.add(const Duration(days: 6));
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case IncomePeriod.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0);
        final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
    }
  }

  String _formatPeriodLabel(bool isUrdu) {
    switch (_selectedPeriod) {
      case IncomePeriod.day:
        return DateFormat('MMM d, yyyy').format(_selectedDate);
      case IncomePeriod.week:
        final range = _getDateRange();
        if (range.start.month == range.end.month) {
          return '${DateFormat('MMM d').format(range.start)} - ${DateFormat('d, yyyy').format(range.end)}';
        }
        return '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d, yyyy').format(range.end)}';
      case IncomePeriod.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
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

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final workerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final range = _getDateRange();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isUrdu ? 'آمدنی کا جائزہ' : 'Income Breakdown',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('workerId', isEqualTo: workerUid)
            .snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];

          // Filter completed jobs for the selected period
          final periodDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status']?.toString() ?? '').toLowerCase().trim();
            final isCompleted = status == 'completed' || status == 'worker_completed' || status == 'paid';
            if (!isCompleted) return false;

            final jobDate = _getJobEffectiveDate(data);
            return !jobDate.isBefore(range.start) && !jobDate.isAfter(range.end);
          }).toList();

          // Sort descending by date
          periodDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            return _getJobEffectiveDate(bData).compareTo(_getJobEffectiveDate(aData));
          });

          // Calculate total earnings
          final double totalEarnings = periodDocs.fold<double>(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['price'];
            return sum + ((price as num?)?.toDouble() ?? 0.0);
          });

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Segmented control: Day | Week | Month
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSegmentPill(
                              label: isUrdu ? 'دن' : 'Day',
                              isSelected: _selectedPeriod == IncomePeriod.day,
                              onTap: () => _onPeriodChanged(IncomePeriod.day),
                            ),
                            const SizedBox(width: 4),
                            _buildSegmentPill(
                              label: isUrdu ? 'ہفتہ' : 'Week',
                              isSelected: _selectedPeriod == IncomePeriod.week,
                              onTap: () => _onPeriodChanged(IncomePeriod.week),
                            ),
                            const SizedBox(width: 4),
                            _buildSegmentPill(
                              label: isUrdu ? 'مہینہ' : 'Month',
                              isSelected: _selectedPeriod == IncomePeriod.month,
                              onTap: () => _onPeriodChanged(IncomePeriod.month),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date Navigator: < Date >
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 24),
                          onPressed: _previousPeriod,
                          splashRadius: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _formatPeriodLabel(isUrdu),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 24),
                          onPressed: _nextPeriod,
                          splashRadius: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Large earnings number
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              isUrdu ? 'کمائی (روپے)' : 'Total Earnings (PKR)',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalEarnings.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Middle illustration or order list
                    if (periodDocs.isEmpty) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: Color(0xFF94A3B8),
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isUrdu ? 'اس مدت میں کوئی مکمل شدہ کام نہیں ہے' : 'No completed orders in this period',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isUrdu ? 'مکمل شدہ کام (${periodDocs.length})' : 'Completed Orders (${periodDocs.length})',
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'PKR ${totalEarnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF0D9488),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...periodDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                        final service = (isUrdu ? data['descriptionUr'] : data['descriptionEn']) ??
                            data['descriptionEn'] ??
                            data['categoryKey'] ??
                            'Job';
                        final customerName = data['customerName']?.toString() ?? 'Customer';
                        final jobDate = _getJobEffectiveDate(data);
                        final timeStr = DateFormat('hh:mm a').format(jobDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 6,
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
                                child: const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$customerName • $timeStr',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+PKR ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF0D9488),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),

              // Bottom Section: Order History
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: _buildBottomActionTile(
                  icon: Icons.layers_outlined,
                  title: isUrdu ? 'آرڈر کی مکمل تاریخ' : 'Order history',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.sharedHistory),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegmentPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
