import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_jobs_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_earnings_screen.dart';
import 'mazdoor_flow.dart';
import 'admin_complaints_tab.dart';
import 'admin_worker_registrations_tab.dart';
import 'admin_user_management_tab.dart';
import 'admin_dashboard_sheets.dart';
import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import '../services/workers_service.dart';
import '../services/voice_assistant_service.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────
// Entry point routed from /admin/dashboard
// ─────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0; // 0=Home, 1=Workers, 2=Complaints, 3=Users

  // Mic pulse animation
  late AnimationController _micPulse;
  late Animation<double> _micScale;

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _micScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _micPulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _micPulse.dispose();
    super.dispose();
  }

  // ── Pages ────────────────────────────────
  final List<Widget> _pages = const [
    _HomeTab(),
    AdminWorkerRegistrationsTab(),
    JobsTab(),
    AdminComplaintsTab(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openMic() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AdminVoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showExitMazdoorlinkDialog(context);
        if (shouldExit) {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            SystemNavigator.pop();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FA),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _AdminBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          onMicTap: _openMic,
          micScale: _micScale,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Nav
// ─────────────────────────────────────────────
class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onMicTap,
    required this.micScale,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onMicTap;
  final Animation<double> micScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavBtn(
              icon: Icons.home_outlined,
              iconFilled: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBtn(
              icon: Icons.how_to_reg_outlined,
              iconFilled: Icons.how_to_reg,
              label: 'Workers',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            // Central Mic
            Expanded(
              child: GestureDetector(
                onTap: onMicTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: micScale,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006B5E), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF006B5E).withOpacity(0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NavBtn(
              icon: Icons.work_outline,
              iconFilled: Icons.work,
              label: 'Jobs',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBtn(
              icon: Icons.report_problem_outlined,
              iconFilled: Icons.report_problem,
              label: 'Complaints',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF006B5E) : Colors.grey.shade500;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? iconFilled : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 0 – Home / Overview Dashboard
// ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: const Color(0xFF006B5E),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => _snack(context, 'No new notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Exit Mazdoorlink',
                onPressed: () async {
                  final shouldExit = await showExitMazdoorlinkDialog(context);
                  if (shouldExit != true) return;
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    SystemNavigator.pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D45), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'System Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats Row (live from Firestore)
                        Row(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('role', isEqualTo: 'worker')
                                  .snapshots(),
                              builder: (_, snap) {
                                final count = snap.data?.docs.length ?? 0;
                                return _StatPill(label: 'Workers', value: '$count');
                              },
                            ),
                            const SizedBox(width: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: streamComplaints(),
                              builder: (_, snap) {
                                final openCount = snap.data?.docs
                                        .where((d) => !((d.data() as Map)['resolved'] == true))
                                        .length ??
                                    0;
                                return _StatPill(label: 'Complaints', value: '$openCount');
                              },
                            ),
                            const SizedBox(width: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: streamSecurityDeposits(),
                              builder: (_, snap) {
                                double totalRefunds = 0;
                                if (snap.hasData) {
                                  for (final doc in snap.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final deposited = (data['totalDeposited'] as num?)?.toDouble() ?? 0;
                                    final balance = (data['currentBalance'] as num?)?.toDouble() ?? 0;
                                    totalRefunds += deposited - balance;
                                  }
                                }
                                final label = totalRefunds >= 1000
                                    ? 'Rs ${(totalRefunds / 1000).toStringAsFixed(totalRefunds >= 10000 ? 0 : 1)}k'
                                    : 'Rs ${totalRefunds.toStringAsFixed(0)}';
                                return _StatPill(label: 'Refunds', value: label);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions (3 dashboard cards)
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 14),
                _DashboardActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Transactions & Payments',
                  subtitle: 'Customer payments & worker top-ups',
                  color: const Color(0xFF006B5E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTransactionsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DashboardActionCard(
                  icon: Icons.monetization_on_rounded,
                  title: 'Platform Earnings',
                  subtitle: '2% commission cuts from worker top-ups',
                  color: const Color(0xFF0D9488),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminEarningsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: streamDamageClaims(),
                  builder: (context, snap) {
                    final pendingCount = snap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Pending').length ?? 0;
                    return _DashboardActionCard(
                      icon: Icons.broken_image_outlined,
                      title: 'Damage Claims',
                      subtitle: 'Review & approve damage reports',
                      color: const Color(0xFFF59E0B),
                      badgeCount: pendingCount > 0 ? pendingCount : null,
                      onTap: () => _showDamageClaimsSheet(context),
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: streamSecurityDeposits(),
                  builder: (context, snap) {
                    final lowCount = snap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Low Balance').length ?? 0;
                    return _DashboardActionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Security Deposits',
                      subtitle: 'Manage deductions and refunds',
                      color: const Color(0xFF10B981),
                      badgeCount: lowCount > 0 ? lowCount : null,
                      onTap: () => _showDepositsSheet(context),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _DashboardActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Platform Stats',
                  subtitle: 'Analytics, revenue & trends',
                  color: const Color(0xFF6366F1),
                  badgeCount: null,
                  onTap: () => _openStatsSheet(context),
                ),
                const SizedBox(height: 12),
                _DashboardActionCard(
                  icon: Icons.people_outline,
                  title: 'Manage Users',
                  subtitle: 'Customers & Workers',
                  color: const Color(0xFF64748B),
                  onTap: () => _openUserManagement(context),
                ),
                const SizedBox(height: 28),

                // Recent Activity
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _RecentActivityList(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static void _showDamageClaimsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminDamageClaimsSheet(),
    );
  }

  static void _showDepositsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminDepositsSheet(),
    );
  }

  static void _openStatsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminStatsSheet(),
    );
  }

  static void _openUserManagement(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagementTab()));
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recent activity'),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['descriptionEn']?.toString() ?? data['descriptionUr']?.toString() ?? 'Job';
            final status = data['status']?.toString() ?? 'pending';
            final customer = data['customerName']?.toString() ?? 'Customer';
            final worker = data['workerName']?.toString() ?? 'Worker';
            String label;
            IconData icon;
            Color color;
            switch (status) {
              case 'completed':
                label = '$title (Completed)';
                icon = Icons.check_circle_outline;
                color = const Color(0xFF10B981);
                break;
              case 'accepted':
                label = '$title accepted by $worker';
                icon = Icons.handyman_outlined;
                color = const Color(0xFFF59E0B);
                break;
              case 'pending':
                label = 'New job: $title from $customer';
                icon = Icons.business_center_outlined;
                color = const Color(0xFF3B82F6);
                break;
              case 'rejected':
                label = '$title rejected by $worker';
                icon = Icons.cancel_outlined;
                color = const Color(0xFFEF4444);
                break;
              default:
                label = title;
                icon = Icons.circle;
                color = Colors.grey;
            }
            return _ActivityTile(activity: {
              'title': label,
              'time': '',
              'icon': icon,
              'color': color,
              'status': status,
            });
          }).toList(),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity['icon'] as IconData,
                color: activity['color'] as Color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E293B))),
                Text(activity['time'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(activity['status'] as String,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activity['color'] as Color)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 1 – Worker Registrations
// ─────────────────────────────────────────────
// _WorkerRegistrationsTab has been extracted to lib/screens/admin_worker_registrations_tab.dart

// _ComplaintsTab has been extracted to lib/screens/admin_complaints_tab.dart

// _UserManagementTab has been extracted to lib/screens/admin_user_management_tab.dart


// Sheets & Analytics widgets have been extracted to lib/screens/admin_dashboard_sheets.dart


// ─────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────
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
