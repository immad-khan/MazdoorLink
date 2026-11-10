import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mazdoor_flow.dart';
import 'admin_jobs_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_earnings_screen.dart';
import 'admin_worker_registrations_tab.dart';
import 'admin_complaints_tab.dart';
import 'admin_user_management_tab.dart';
import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import '../services/workers_service.dart';
import '../services/voice_assistant_service.dart';
import '../app_state.dart';

// Public typedefs for drop-in compatibility
typedef _DamageClaimsSheet = AdminDamageClaimsSheet;
typedef _DepositsSheet = AdminDepositsSheet;
typedef _StatsSheet = AdminStatsSheet;
typedef _AdminVoiceSheet = AdminVoiceSheet;
// ─────────────────────────────────────────────
// Damage Claims Sheet (Firestore-backed)
// ─────────────────────────────────────────────
class AdminDamageClaimsSheet extends StatelessWidget {
  const AdminDamageClaimsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: streamDamageClaims(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No damage claims.'));
            }
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Damage Claims',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status']?.toString() ?? 'Pending';
                      final statusColor = status == 'Approved'
                          ? const Color(0xFF10B981)
                          : status == 'Rejected'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B);
                      final title = data['title']?.toString() ?? 'Claim';
                      final customerName = data['customerName']?.toString() ?? '';
                      final workerName = data['workerName']?.toString() ?? '';
                      final amount = data['amount'];
                      final amountStr = amount != null ? 'Rs ${(amount as num).toStringAsFixed(0)}' : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$customerName · $workerName · $amountStr',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            if (status == 'Pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await updateDamageClaimStatus(doc.id, 'Rejected');
                                        _snack(context, 'Claim rejected');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFEF4444)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await updateDamageClaimStatus(doc.id, 'Approved');
                                        _snack(context, 'Claim approved');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        elevation: 0,
                                      ),
                                      child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Security Deposits Sheet (Firestore-backed)
// ─────────────────────────────────────────────
class AdminDepositsSheet extends StatelessWidget {
  const AdminDepositsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: streamSecurityDeposits(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No security deposits.'));
            }
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Security Deposits',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status']?.toString() ?? 'Active';
                      final statusColor = status == 'Active'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444);
                      final workerName = data['workerName']?.toString() ?? 'Worker';
                      final totalDeposited = (data['totalDeposited'] as num?)?.toDouble() ?? 0;
                      final currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(workerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Total Deposited: Rs ${totalDeposited.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text('Current Balance: Rs ${currentBalance.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AdminStatsSheet extends StatefulWidget {
  const AdminStatsSheet({super.key});

  @override
  State<AdminStatsSheet> createState() => _AdminStatsSheetState();
}

class _AdminStatsSheetState extends State<AdminStatsSheet> {
  String _selectedPeriod = 'All Time';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Platform Analytics',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All Time', isSelected: _selectedPeriod == 'All Time', onTap: () => setState(() => _selectedPeriod = 'All Time')),
                  _FilterChip(label: 'Today', isSelected: _selectedPeriod == 'Today', onTap: () => setState(() => _selectedPeriod = 'Today')),
                  _FilterChip(label: 'This Week', isSelected: _selectedPeriod == 'This Week', onTap: () => setState(() => _selectedPeriod = 'This Week')),
                  _FilterChip(label: 'This Month', isSelected: _selectedPeriod == 'This Month', onTap: () => setState(() => _selectedPeriod = 'This Month')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats Cards (live)
            _LiveStatsCards(period: _selectedPeriod),
            const SizedBox(height: 24),
            const Text('Bookings Trend',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _LiveBarChart(period: _selectedPeriod),
            const SizedBox(height: 24),
            const Text('Top Service Categories',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _LiveCategoryBars(period: _selectedPeriod),
          ],
        ),
      ),
    );
  }
}

class _LiveStatsCards extends StatelessWidget {
  const _LiveStatsCards({required this.period});
  final String period;

  DateTime? _periodStart() {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _periodStart();

    Query completedQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'completed');
    if (start != null) {
      completedQuery = completedQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }

    Query activeQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', whereIn: [
      'pending', 'accepted', 'arrival_pending', 'working',
      'worker_completed', 'payment_pending', 'worker_payment_pending',
      'payment_disputed',
    ]);
    if (start != null) {
      activeQuery = activeQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: completedQuery.snapshots(),
      builder: (_, completedSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: activeQuery.snapshots(),
          builder: (_, activeSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (_, usersSnap) {
                double totalRevenue = 0;
                if (completedSnap.hasData) {
                  for (final doc in completedSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalRevenue += (data['price'] as num?)?.toDouble() ?? 0;
                  }
                }
                final activeJobs = activeSnap.data?.docs.length ?? 0;
                final totalUsers = usersSnap.data?.docs.length ?? 0;

                String revenueStr;
                if (totalRevenue >= 1000000) {
                  revenueStr = 'Rs ${(totalRevenue / 1000000).toStringAsFixed(1)}M';
                } else if (totalRevenue >= 1000) {
                  revenueStr = 'Rs ${(totalRevenue / 1000).toStringAsFixed(1)}k';
                } else {
                  revenueStr = 'Rs ${totalRevenue.toStringAsFixed(0)}';
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        _StatsCard(
                            label: 'Total Revenue', value: revenueStr,
                            icon: Icons.paid_outlined, color: const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _StatsCard(
                            label: 'Active Jobs', value: '$activeJobs',
                            icon: Icons.work_outline, color: const Color(0xFF6366F1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatsCard(
                            label: 'Total Users', value: '$totalUsers',
                            icon: Icons.people_outline, color: const Color(0xFF0D9488)),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LiveBarChart extends StatelessWidget {
  const _LiveBarChart({required this.period});
  final String period;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: streamAllJobs(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final now = DateTime.now();
        final months = <String, int>{};
        const monthLabels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

        for (int i = 6; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          months['${monthLabels[m.month - 1]}'] = 0;
        }

        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'];
          if (createdAt is! Timestamp) continue;
          final date = createdAt.toDate();
          final label = monthLabels[date.month - 1];
          if (months.containsKey(label)) {
            months[label] = months[label]! + 1;
          }
        }

        final maxVal = months.values.fold<int>(1, (a, b) => a > b ? a : b);
        final bars = months.entries
            .map((e) => (e.key, e.value / maxVal))
            .toList();

        return _BarChartWidget(bars: bars);
      },
    );
  }
}

class _LiveCategoryBars extends StatelessWidget {
  const _LiveCategoryBars({required this.period});
  final String period;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: streamAllJobs(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No jobs yet'),
          );
        }

        final categoryCount = <String, int>{};
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = data['categoryKey']?.toString() ?? 'Other';
          categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        }

        final sorted = categoryCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(5).toList();
        final total = top.fold<int>(0, (sum, e) => sum + e.value);

        const colors = [
          Color(0xFF0D9488),
          Color(0xFF6366F1),
          Color(0xFFF59E0B),
          Color(0xFFEF4444),
          Color(0xFF3B82F6),
        ];

        return Column(
          children: List.generate(top.length, (i) {
            final entry = top[i];
            final fraction = total > 0 ? entry.value / total : 0.0;
            final label = entry.key[0].toUpperCase() + entry.key.substring(1);
            return _CategoryBar(
                label: label, fraction: fraction, color: colors[i % colors.length]);
          }),
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.bars});
  final List<(String, double)> bars;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: bars.map((b) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 28,
                height: 80 * b.$2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006B5E), Color(0xFF0D9488)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Text(b.$1,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.fraction,
    required this.color,
  });
  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
              Text('${(fraction * 100).round()}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Admin Voice Sheet
// ─────────────────────────────────────────────
class AdminVoiceSheet extends StatefulWidget {
  const AdminVoiceSheet({super.key});

  @override
  State<AdminVoiceSheet> createState() => _AdminVoiceSheetState();
}

class _AdminVoiceSheetState extends State<AdminVoiceSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ring;
  String _phase = 'idle'; // idle, listening, processing, responded, error
  String _recognizedText = '';
  String _responseText = '';
  String _errorText = '';

  final _voiceService = VoiceAssistantService();

  final List<String> _suggestions = [
    'Show pending worker registrations',
    'How many complaints today?',
    'Show platform revenue',
    'Show jobs',
  ];

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _startListening();
  }

  @override
  void dispose() {
    _ring.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _phase = 'listening';
      _recognizedText = '';
      _responseText = '';
      _errorText = '';
    });

    try {
      await _voiceService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() => _recognizedText = text);
        },
        onDone: () {
          if (!mounted) return;
          if (_recognizedText.trim().isNotEmpty) {
            _processCommand(_recognizedText.trim());
          } else {
            setState(() {
              _phase = 'error';
              _errorText = 'No speech detected.';
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = 'error';
        _errorText = 'Microphone error.';
      });
    }
  }

  Future<void> _processCommand(String text) async {
    setState(() => _phase = 'processing');

    final intent = await _voiceService.parseIntent(text, role: UserRole.admin);

    if (!mounted) return;

    final result = _voiceService.executeIntent(
      context: context,
      intent: intent,
      role: UserRole.admin,
    );

    final response = result['response'] as String? ?? 'Done.';

    setState(() {
      _phase = 'responded';
      _responseText = response;
    });

    await _voiceService.speak(response);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.pop(context);
    _snack(context, response);
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _phase == 'listening';
    final isProcessing = _phase == 'processing';
    final isResponded = _phase == 'responded';
    final isError = _phase == 'error';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Admin Voice Assistant',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isListening
                ? 'Listening...'
                : isProcessing
                    ? 'Understanding...'
                    : isResponded
                        ? _responseText
                        : isError
                            ? _errorText
                            : 'Tap mic to speak',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              if (isListening) {
                _voiceService.stopListening();
                if (_recognizedText.trim().isNotEmpty) {
                  _processCommand(_recognizedText.trim());
                } else {
                  setState(() => _phase = 'idle');
                }
              } else if (!isProcessing) {
                _startListening();
              }
            },
            child: AnimatedBuilder(
              animation: _ring,
              builder: (_, child) => Container(
                padding: EdgeInsets.all(isListening ? 14 + 4 * _ring.value : 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF006B5E)
                      .withOpacity(isListening ? 0.15 + 0.1 * _ring.value : 0.1),
                ),
                child: child,
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isListening
                        ? [const Color(0xFF004D45), const Color(0xFF0D9488)]
                        : [const Color(0xFF006B5E), const Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006B5E).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        isListening
                            ? Icons.mic
                            : isResponded
                                ? Icons.check
                                : Icons.mic_none,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
          ),
          if (_recognizedText.isNotEmpty && (isListening || isProcessing)) ...[
            const SizedBox(height: 16),
            Text(
              '"$_recognizedText"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF006B5E),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try saying...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map(
            (s) => GestureDetector(
              onTap: () {
                setState(() => _recognizedText = s);
                _processCommand(s);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mic_none_outlined,
                      size: 16,
                      color: Color(0xFF006B5E),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 7),
    ),
  );
}