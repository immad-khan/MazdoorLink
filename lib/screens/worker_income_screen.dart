import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

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
  double _incomeGoal = 0.0;
  bool _loadingGoal = true;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadGoal();
  }

  String get _goalKey {
    switch (_selectedPeriod) {
      case IncomePeriod.day:
        return 'income_goal_day';
      case IncomePeriod.week:
        return 'income_goal_week';
      case IncomePeriod.month:
        return 'income_goal_month';
    }
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    double? savedGoal;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null && data[_goalKey] != null) {
          savedGoal = (data[_goalKey] as num?)?.toDouble();
        }
      } catch (e) {
        debugPrint('Error loading income goal: $e');
      }
    }

    savedGoal ??= prefs.getDouble(_goalKey) ?? 0.0;

    if (mounted) {
      setState(() {
        _incomeGoal = savedGoal!;
        _loadingGoal = false;
      });
    }
  }

  Future<void> _saveGoal(double newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalKey, newGoal);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          _goalKey: newGoal,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving income goal to Firestore: $e');
      }
    }

    if (mounted) {
      setState(() => _incomeGoal = newGoal);
    }
  }

  void _onPeriodChanged(IncomePeriod period) {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
        _loadingGoal = true;
      });
      _loadGoal();
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

  void _showSetGoalBottomSheet(BuildContext context, bool isUrdu) {
    final textController = TextEditingController(
      text: _incomeGoal > 0 ? _incomeGoal.toStringAsFixed(0) : '',
    );

    List<double> presets;
    switch (_selectedPeriod) {
      case IncomePeriod.day:
        presets = [1000, 2000, 3000, 5000];
        break;
      case IncomePeriod.week:
        presets = [7000, 15000, 25000, 40000];
        break;
      case IncomePeriod.month:
        presets = [30000, 50000, 80000, 120000];
        break;
    }

    String periodTitle;
    switch (_selectedPeriod) {
      case IncomePeriod.day:
        periodTitle = isUrdu ? 'روزانہ' : 'Daily';
        break;
      case IncomePeriod.week:
        periodTitle = isUrdu ? 'ہفتہ وار' : 'Weekly';
        break;
      case IncomePeriod.month:
        periodTitle = isUrdu ? 'ماہانہ' : 'Monthly';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUrdu
                            ? '$periodTitle آمدنی کا ہدف مقرر کریں'
                            : 'Set $periodTitle Income Plan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUrdu
                        ? 'اپنا ٹارگٹ درج کریں تاکہ آپ کی روزانہ کی ترقی کو ٹریک کیا جا سکے۔'
                        : 'Set a target amount to track your progress and stay motivated.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'PKR ',
                      prefixStyle: const TextStyle(color: Color(0xFFBEF264), fontSize: 20, fontWeight: FontWeight.bold),
                      hintText: '0',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFBEF264), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((amount) {
                      return ActionChip(
                        label: Text(
                          'PKR ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFF2C2C2E),
                        side: BorderSide(
                          color: textController.text == amount.toStringAsFixed(0)
                              ? const Color(0xFFBEF264)
                              : Colors.white12,
                        ),
                        onPressed: () {
                          setModalState(() {
                            textController.text = amount.toStringAsFixed(0);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(textController.text.trim()) ?? 0.0;
                      _saveGoal(val);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFBEF264),
                          content: Text(
                            isUrdu ? 'ہدف محفوظ ہو گیا!' : 'Income plan updated successfully!',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBEF264),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isUrdu ? 'ہدف محفوظ کریں' : 'Save Income Plan',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAchievementsBottomSheet(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final achievements = [
          {
            'icon': Icons.star_rounded,
            'color': const Color(0xFFF59E0B),
            'title': isUrdu ? '5 اسٹار سروس' : '5-Star Provider',
            'desc': isUrdu ? 'بہترین کسٹمر ریٹنگ برقرار رکھیں' : 'Maintain outstanding customer reviews',
            'unlocked': true,
          },
          {
            'icon': Icons.bolt_rounded,
            'color': const Color(0xFF3B82F6),
            'title': isUrdu ? 'فوری رسپانس' : 'Quick Responder',
            'desc': isUrdu ? '10 منٹ کے اندر جاب قبول کریں' : 'Accept jobs within 10 minutes of request',
            'unlocked': true,
          },
          {
            'icon': Icons.emoji_events_rounded,
            'color': const Color(0xFFBEF264),
            'title': isUrdu ? 'ہدف فاتح' : 'Goal Crusher',
            'desc': isUrdu ? 'اپنا روزانہ کا آمدنی کا ہدف مکمل کریں' : 'Achieve your daily income plan',
            'unlocked': _incomeGoal > 0,
          },
          {
            'icon': Icons.military_tech_rounded,
            'color': const Color(0xFFA855F7),
            'title': isUrdu ? 'ٹاپ ورکر' : 'Top Earner Club',
            'desc': isUrdu ? 'مہینے میں 25 سے زائد کام مکمل کریں' : 'Complete over 25 orders in a single month',
            'unlocked': false,
          },
        ];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFFBEF264), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isUrdu ? 'ورکر کامیابیاں' : 'Achievements',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...achievements.map((item) {
                final unlocked = item['unlocked'] as bool;
                final color = item['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: unlocked ? color.withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: unlocked ? null : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (unlocked)
                        const Icon(Icons.check_circle, color: Color(0xFFBEF264), size: 20)
                      else
                        const Icon(Icons.lock_outline, color: Colors.white30, size: 18),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    final workerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final range = _getDateRange();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Segmented control: Day | Week | Month
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
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
                            const SizedBox(width: 6),
                            _buildSegmentPill(
                              label: isUrdu ? 'ہفتہ' : 'Week',
                              isSelected: _selectedPeriod == IncomePeriod.week,
                              onTap: () => _onPeriodChanged(IncomePeriod.week),
                            ),
                            const SizedBox(width: 6),
                            _buildSegmentPill(
                              label: isUrdu ? 'مہینہ' : 'Month',
                              isSelected: _selectedPeriod == IncomePeriod.month,
                              onTap: () => _onPeriodChanged(IncomePeriod.month),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date Navigator: < Date >
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                          onPressed: _previousPeriod,
                          splashRadius: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _formatPeriodLabel(isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                          onPressed: _nextPeriod,
                          splashRadius: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Large earnings number (e.g. 0.00)
                    Center(
                      child: Text(
                        totalEarnings.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // "Set income plan" button (Lime green)
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _showSetGoalBottomSheet(context, isUrdu),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBEF264),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          isUrdu ? 'آمدنی کا منصوبہ بنائیں' : 'Set income plan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),

                    // Goal progress indicator (if goal is set)
                    if (!_loadingGoal && _incomeGoal > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isUrdu ? 'ہدف کی پیش رفت' : 'Plan Progress',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'PKR ${totalEarnings.toStringAsFixed(0)} / ${_incomeGoal.toStringAsFixed(0)} (${((totalEarnings / _incomeGoal) * 100).clamp(0, 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(color: Color(0xFFBEF264), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (_incomeGoal > 0 ? totalEarnings / _incomeGoal : 0.0).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF2C2C2E),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBEF264)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Middle illustration or order list
                    if (periodDocs.isEmpty) ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFF262626),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white38,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isUrdu ? 'کوئی مکمل شدہ آرڈر نہیں' : 'No completed orders',
                              style: const TextStyle(
                                color: Colors.white54,
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
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'PKR ${totalEarnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFBEF264),
                                fontSize: 13,
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
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBEF264).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.check_circle, color: Color(0xFFBEF264), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$customerName • $timeStr',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+PKR ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFFBEF264),
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

              // Bottom Section: Order History & Achievements
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  border: Border(
                    top: BorderSide(color: Color(0xFF262626), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBottomActionTile(
                      icon: Icons.layers_outlined,
                      title: isUrdu ? 'آرڈر کی تاریخ' : 'Order history',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.sharedHistory),
                    ),
                    const SizedBox(height: 8),
                    _buildBottomActionTile(
                      icon: Icons.outlined_flag,
                      title: isUrdu ? 'کامیابیاں' : 'Achievements',
                      onTap: () => _showAchievementsBottomSheet(context, isUrdu),
                    ),
                  ],
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
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
