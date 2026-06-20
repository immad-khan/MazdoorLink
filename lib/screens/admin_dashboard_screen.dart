import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_jobs_screen.dart';

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
    _WorkerRegistrationsTab(),
    JobsTab(),
    _ComplaintsTab(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openMic() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AdminVoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onMicTap: _openMic,
        micScale: _micScale,
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
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
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
                        // Stats Row
                        Row(
                          children: const [
                            _StatPill(label: 'Workers', value: '124'),
                            SizedBox(width: 12),
                            _StatPill(label: 'Complaints', value: '18'),
                            SizedBox(width: 12),
                            _StatPill(label: 'Refunds', value: 'Rs 45k'),
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
                  icon: Icons.broken_image_outlined,
                  title: 'Damage Claims',
                  subtitle: 'Review & approve damage reports',
                  color: const Color(0xFFF59E0B),
                  badgeCount: 7,
                  onTap: () => _openDetail(context, 'Damage Claims', _damageClaimsData),
                ),
                const SizedBox(height: 12),
                _DashboardActionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Security Deposits',
                  subtitle: 'Manage deductions and refunds',
                  color: const Color(0xFF10B981),
                  badgeCount: 4,
                  onTap: () => _openDetail(context, 'Security Deposits', _depositsData),
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

  static void _openDetail(BuildContext context, String title, List<Map<String, String>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListDetailSheet(title: title, items: items),
    );
  }

  static void _openStatsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StatsSheet(),
    );
  }

  static void _openUserManagement(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _UserManagementTab()));
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
class _WorkerRegistrationsTab extends StatelessWidget {
  const _WorkerRegistrationsTab();

  void _showImages(BuildContext context, String front, String back) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ID Images'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Front:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network(front),
              const SizedBox(height: 16),
              const Text('Back:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network(back),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _rejectWorker(BuildContext context, String docId, String workerName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject $workerName'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. ID blurry',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('users').doc(docId).update({
                'status': 'rejected',
                'rejectReason': reasonController.text.trim(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker rejected')));
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveWorker(BuildContext context, String docId, String workerName) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'status': 'approved',
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$workerName approved!')));
  }

  void _showWorkerDetail(BuildContext context, Map<String, dynamic> w) {
    final name = w['name'] ?? 'Unknown';
    final email = w['email'] ?? 'No email';
    final phone = w['phone'] ?? 'No phone';
    final status = w['status'] ?? 'pending';
    final idFrontUrl = w['idFrontUrl'];
    final idBackUrl = w['idBackUrl'];
    final category = w['category'];
    final categoryNameEn = w['categoryNameEn'];
    final categoryNameUr = w['categoryNameUr'];
    final skills = w['skills'] as List<dynamic>?;
    final setupComplete = w['setupComplete'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF006B5E).withOpacity(0.12),
                      child: Text(
                        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF006B5E), fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'approved' ? const Color(0xFF10B981).withOpacity(0.12)
                            : status == 'rejected' ? const Color(0xFFEF4444).withOpacity(0.12)
                            : const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          color: status == 'approved' ? const Color(0xFF10B981)
                              : status == 'rejected' ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold, fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  // Personal Info
                  _detailField('Email', email, Icons.email_outlined),
                  _detailField('Phone', phone, Icons.phone_outlined),
                  if (category != null) _detailField('Category (Key)', category.toString(), Icons.category_outlined),
                  if (categoryNameEn != null) _detailField('Category (English)', categoryNameEn.toString(), Icons.translate),
                  if (categoryNameUr != null) _detailField('Category (Urdu)', categoryNameUr.toString(), Icons.translate),

                  const SizedBox(height: 16),

                  // ID Images
                  if (idFrontUrl != null || idBackUrl != null) ...[
                    const Text('ID Card Images', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    if (idFrontUrl != null) ...[
                      const Text('Front:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(idFrontUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Center(child: Text('Failed to load'))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (idBackUrl != null) ...[
                      const Text('Back:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(idBackUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Center(child: Text('Failed to load'))),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Skills / Services
                  if (setupComplete && skills != null && skills.isNotEmpty) ...[
                    const Text('Selected Services / Skills', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    ...skills.map((s) {
                      final skill = s as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${skill['titleEn'] ?? ''} / ${skill['titleUr'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rs. ${(skill['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D9488)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  if (!setupComplete && status == 'approved')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Worker approved but hasn\'t completed services setup yet.', style: TextStyle(color: Color(0xFF92400E), fontSize: 13))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B5E),
        title: const Text('Worker Registrations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'worker')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No worker registrations found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final w = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              
              final name = w['name'] ?? 'Unknown';
              final email = w['email'] ?? 'No email';
              final status = w['status'] ?? 'pending';
              final idFrontUrl = w['idFrontUrl'];
              final idBackUrl = w['idBackUrl'];

              Color statusColor = status == 'approved'
                  ? const Color(0xFF10B981)
                  : status == 'rejected'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showWorkerDetail(context, w),
                  child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF006B5E).withOpacity(0.12),
                            child: Text(
                              name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Color(0xFF006B5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                                Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(status.toString().toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor)),
                          ),
                        ],
                      ),
                      if (idFrontUrl != null && idBackUrl != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _showImages(context, idFrontUrl, idBackUrl),
                          icon: const Icon(Icons.image),
                          label: const Text('View ID Images'),
                        ),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rejectWorker(context, docId, name),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveWorker(context, docId, name),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],                      // close children list
                  ),
                ),
              ),
            ),
          );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 2 – Complaints
// ─────────────────────────────────────────────
class _ComplaintsTab extends StatefulWidget {
  const _ComplaintsTab();

  @override
  State<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  final List<Map<String, dynamic>> _complaints = [
    {
      'user': 'Sara Malik',
      'worker': 'Ali Raza',
      'issue': 'Worker did not complete the job properly and left a mess.',
      'date': 'May 22',
      'type': 'Service Quality',
      'priority': 'High',
      'resolved': false,
    },
    {
      'user': 'Ahmed Khan',
      'worker': 'Bilal Plumber',
      'issue': 'Overcharged for materials without prior agreement.',
      'date': 'May 21',
      'type': 'Billing',
      'priority': 'Medium',
      'resolved': false,
    },
    {
      'user': 'Fatima Bano',
      'worker': 'Hassan Electrician',
      'issue': 'Worker was rude and disrespectful during the visit.',
      'date': 'May 20',
      'type': 'Conduct',
      'priority': 'High',
      'resolved': false,
    },
    {
      'user': 'Rahul Arif',
      'worker': 'Tariq Mehmood',
      'issue': 'App showed wrong estimated price.',
      'date': 'May 19',
      'type': 'App Issue',
      'priority': 'Low',
      'resolved': true,
    },
    {
      'user': 'Nida Hussain',
      'worker': 'Umar Farooq',
      'issue': 'Worker cancelled last minute without notice.',
      'date': 'May 18',
      'type': 'Cancellation',
      'priority': 'Medium',
      'resolved': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final open = _complaints.where((c) => !(c['resolved'] as bool)).toList();
    final resolved = _complaints.where((c) => c['resolved'] as bool).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B5E),
        title: const Text('Complaints',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${open.length} Open',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (open.isNotEmpty) ...[
            const _SectionHeader(title: 'Open Complaints', color: Color(0xFFEF4444)),
            const SizedBox(height: 8),
            ...open.map((c) => _ComplaintCard(
                  complaint: c,
                  onResolve: () {
                    setState(() => c['resolved'] = true);
                    _snack(context, 'Complaint marked as resolved');
                  },
                )),
          ],
          if (resolved.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Resolved', color: Color(0xFF10B981)),
            const SizedBox(height: 8),
            ...resolved.map((c) => _ComplaintCard(complaint: c)),
          ],
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, this.onResolve});
  final Map<String, dynamic> complaint;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final priority = complaint['priority'] as String;
    final resolved = complaint['resolved'] as bool;
    final priorityColor = priority == 'High'
        ? const Color(0xFFEF4444)
        : priority == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(priority,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(complaint['type'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700)),
                ),
                const Spacer(),
                Text(complaint['date'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              complaint['issue'] as String,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text('${complaint['user']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 10),
                const Icon(Icons.engineering_outlined,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text('${complaint['worker']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            if (!resolved && onResolve != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _snack(context, 'Opening chat with user...'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006B5E),
                        side: const BorderSide(color: Color(0xFF006B5E)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Contact', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text('Resolve', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
            if (resolved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('Resolved',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 3 – User Management
// ─────────────────────────────────────────────
class _UserManagementTab extends StatefulWidget {
  const _UserManagementTab();

  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  final List<Map<String, dynamic>> _users = [
    {'name': 'Sara Malik', 'type': 'Customer', 'joined': 'Jan 2025', 'jobs': 12, 'status': 'Active', 'flag': false},
    {'name': 'Ali Raza', 'type': 'Worker', 'joined': 'Feb 2025', 'jobs': 34, 'status': 'Active', 'flag': false},
    {'name': 'Ahmed Khan', 'type': 'Customer', 'joined': 'Mar 2025', 'jobs': 5, 'status': 'Active', 'flag': true},
    {'name': 'Bilal Ahmed', 'type': 'Worker', 'joined': 'Mar 2025', 'jobs': 21, 'status': 'Suspended', 'flag': false},
    {'name': 'Nida Hussain', 'type': 'Customer', 'joined': 'Apr 2025', 'jobs': 8, 'status': 'Active', 'flag': false},
    {'name': 'Tariq Mehmood', 'type': 'Worker', 'joined': 'Apr 2025', 'jobs': 17, 'status': 'Active', 'flag': false},
    {'name': 'Kamran Shah', 'type': 'Worker', 'joined': 'May 2025', 'jobs': 3, 'status': 'Banned', 'flag': true},
  ];

  String _searchQuery = '';

  void _showDeductDepositDialog(BuildContext context, String workerName) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deduct Security Deposit: $workerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Current Top-up Balance: Rs. 500', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Deduct (Rs.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack(context, 'Deducted Rs. ${amountController.text} from $workerName');
            },
            child: const Text('Deduct'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users
        .where((u) =>
            (u['name'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B5E),
        title: const Text('User Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF006B5E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = filtered[i];
                final status = u['status'] as String;
                final statusColor = status == 'Active'
                    ? const Color(0xFF10B981)
                    : status == 'Suspended'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                final isWorker = u['type'] == 'Worker';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: (isWorker
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF0D9488))
                              .withOpacity(0.12),
                          child: Text(
                            (u['name'] as String)[0],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: isWorker
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF0D9488)),
                          ),
                        ),
                        if (u['flag'] as bool)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(u['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B))),
                    subtitle: Text(
                        '${u['type']} · ${u['jobs']} jobs · Since ${u['joined']}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor)),
                        ),
                        const SizedBox(width: 6),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              size: 18, color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'DeductDeposit') {
                              _showDeductDepositDialog(context, u['name'] as String);
                              return;
                            }
                            setState(() => filtered[i]['status'] = value);
                            _snack(context,
                                '${u['name']} has been $value');
                          },
                          itemBuilder: (_) => [
                            if (isWorker)
                              const PopupMenuItem(
                                value: 'DeductDeposit',
                                child: Text('Deduct Security Deposit'),
                              ),
                            const PopupMenuItem(
                                value: 'Active',
                                child: Text('Restore / Activate')),
                            const PopupMenuItem(
                                value: 'Suspended',
                                child: Text('Suspend User')),
                            const PopupMenuItem(
                                value: 'Banned',
                                child: Text('Ban User')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheets
// ─────────────────────────────────────────────

class _ListDetailSheet extends StatefulWidget {
  const _ListDetailSheet({required this.title, required this.items});
  final String title;
  final List<Map<String, String>> items;

  @override
  State<_ListDetailSheet> createState() => _ListDetailSheetState();
}

class _ListDetailSheetState extends State<_ListDetailSheet> {
  late final List<String> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = widget.items.map((e) => e['status']!).toList();
  }

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
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B))),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = widget.items[i];
                  final status = _statuses[i];
                  final statusColor = (status == 'Approved' || status == 'Active')
                      ? const Color(0xFF10B981)
                      : (status == 'Rejected' || status == 'Low Balance')
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B);

                  return Container(
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
                              child: Text(item['title']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${item['sub']} · ${item['amount']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        if (widget.title == 'Damage Claims')
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _showDamageViewSheet(context, item),
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              label: const Text('View Claim Details & Contact Info'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0D9488),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: const Color(0xFF0D9488).withOpacity(0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        if (status == 'Pending' && widget.title != 'Security Deposits') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => _statuses[i] = 'Rejected');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(
                                        color: Color(0xFFEF4444)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                  ),
                                  child: const Text('Reject',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => _statuses[i] = 'Approved');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    elevation: 0,
                                  ),
                                  child: const Text('Approve',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDamageViewSheet(BuildContext context, Map<String, String> item) {
    final parts = item['sub']!.split(' · ');
    final customerName = parts.isNotEmpty ? parts[0] : 'Customer User';
    final workerName = parts.length > 1 ? parts[1] : 'Worker Profile';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(item['title']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Claim Amount:', style: TextStyle(color: Colors.grey.shade600)),
                    Text(item['amount']!, style: const TextStyle(fontSize: 16, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'The customer reported that during the service, the worker accidentally damaged the item. Please review the chat and approve/reject the claim. This is a system-generated description for "${item['title']}".',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text('Evidence Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 40),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildPartyInfo(context, 'Customer', customerName, '+92 300 1234567'),
                const SizedBox(height: 12),
                _buildPartyInfo(context, 'Worker', workerName, '+92 321 7654321'),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyInfo(BuildContext context, String role, String name, String phone) {
    final isCustomer = role == 'Customer';
    final primaryColor = isCustomer ? const Color(0xFF0D9488) : const Color(0xFFF59E0B);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(isCustomer ? Icons.person_outline : Icons.construction_outlined, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$role Account • $phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chat with $role',
            icon: Icon(Icons.chat_bubble_outline, color: primaryColor),
            onPressed: () {
               // Close the current detail sheet and navigate to chat
               Navigator.pop(context); // Close party info sheet
               Navigator.pop(context); // Close list detail sheet
               Navigator.pushNamed(context, '/shared/chat');
            },
          ),
        ],
      )
    );
  }
}

class _StatsSheet extends StatelessWidget {
  const _StatsSheet();

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
                  _FilterChip(label: 'Today', isSelected: true),
                  _FilterChip(label: 'Weekly', isSelected: false),
                  _FilterChip(label: 'Monthly', isSelected: false),
                  _FilterChip(label: 'Yearly: 2025', isSelected: false),
                  _FilterChip(label: 'Yearly: 2026', isSelected: false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatsCard(
                    label: 'Total Revenue', value: 'Rs 1.2M', icon: Icons.paid_outlined,
                    color: const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _StatsCard(
                    label: 'Active Jobs', value: '234', icon: Icons.work_outline,
                    color: const Color(0xFF6366F1)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatsCard(
                    label: 'Total Users', value: '1,842', icon: Icons.people_outline,
                    color: const Color(0xFF0D9488)),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Bookings Trend',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _BarChartWidget(
              bars: const [
                ('Jan', 0.4), ('Feb', 0.55), ('Mar', 0.6), ('Apr', 0.75),
                ('May', 0.9), ('Jun', 0.7), ('Jul', 0.8),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Top Service Categories',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            ...[
              ('Plumber', 0.82, const Color(0xFF0D9488)),
              ('Electrician', 0.70, const Color(0xFF6366F1)),
            ].map((e) => _CategoryBar(label: e.$1, fraction: e.$2, color: e.$3)),
          ],
        ),
      ),
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
  const _FilterChip({required this.label, required this.isSelected});
  final String label;
  final bool isSelected;
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
class _AdminVoiceSheet extends StatefulWidget {
  const _AdminVoiceSheet();

  @override
  State<_AdminVoiceSheet> createState() => _AdminVoiceSheetState();
}

class _AdminVoiceSheetState extends State<_AdminVoiceSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ring;
  bool _listening = false;
  final List<String> _suggestions = [
    'Show pending worker registrations',
    'How many complaints today?',
    'Show platform revenue',
    'List suspended users',
    'Approve all pending deposits',
  ];

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('Admin Voice Command',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text('Tap mic and speak a command',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 28),
          GestureDetector(
            onTapDown: (_) => setState(() => _listening = true),
            onTapUp: (_) {
              setState(() => _listening = false);
              _snack(context, 'Voice command received!');
              Navigator.pop(context);
            },
            child: AnimatedBuilder(
              animation: _ring,
              builder: (_, child) => Container(
                padding: EdgeInsets.all(_listening ? 14 + 4 * _ring.value : 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF006B5E)
                      .withOpacity(_listening ? 0.15 + 0.1 * _ring.value : 0.1),
                ),
                child: child,
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _listening
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
                child: const Icon(Icons.mic, color: Colors.white, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Try saying...',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map(
            (s) => GestureDetector(
              onTap: () {
                _snack(context, 'Command: "$s"');
                Navigator.pop(context);
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
                    const Icon(Icons.mic_none_outlined,
                        size: 16, color: Color(0xFF006B5E)),
                    const SizedBox(width: 10),
                    Text(s,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1E293B))),
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

// ─────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────
final List<Map<String, String>> _damageClaimsData = [
  {'title': 'Broken Kitchen Tap', 'sub': 'Sara Malik · Plumber Ali Raza', 'amount': 'Rs 3,200', 'status': 'Pending'},
  {'title': 'Cracked Wall Tiles', 'sub': 'Ahmed Khan · Mason Bilal', 'amount': 'Rs 8,500', 'status': 'Pending'},
  {'title': 'Damaged Electrician Panel', 'sub': 'Nida Hussain · Hassan Elec.', 'amount': 'Rs 12,000', 'status': 'Approved'},
  {'title': 'Scratched Floor', 'sub': 'Rahul Arif · Carpenter Umar', 'amount': 'Rs 6,000', 'status': 'Rejected'},
  {'title': 'Broken Window Pane', 'sub': 'Fatima Bano · Worker Kamran', 'amount': 'Rs 4,500', 'status': 'Pending'},
  {'title': 'Water Pipe Burst', 'sub': 'Ali Shah · Plumber Tariq', 'amount': 'Rs 9,800', 'status': 'Pending'},
  {'title': 'AC Unit Damaged', 'sub': 'Hina Malik · Tech Zubair', 'amount': 'Rs 15,000', 'status': 'Pending'},
];

final List<Map<String, String>> _depositsData = [
  {'title': 'Ali Raza (Plumber)', 'sub': 'Total Deposited', 'amount': 'Rs 5,000  •  Current Balance: Rs 5,000', 'status': 'Active'},
  {'title': 'Hassan Elec. (Electrician)', 'sub': 'Total Deposited', 'amount': 'Rs 5,000  •  Current Balance: Rs 3,500', 'status': 'Active'},
  {'title': 'Bilal Ahmed (Mason)', 'sub': 'Total Deposited', 'amount': 'Rs 4,000  •  Current Balance: Rs 800', 'status': 'Low Balance'},
  {'title': 'Umar Farooq (Carpenter)', 'sub': 'Total Deposited', 'amount': 'Rs 5,000  •  Current Balance: Rs 5,000', 'status': 'Active'},
];

final List<Map<String, dynamic>> _recentActivity = [
  {'title': 'Worker Hassan approved', 'time': '5 min ago', 'icon': Icons.check_circle_outline, 'color': Color(0xFF10B981), 'status': 'Approved'},
  {'title': 'New complaint from Sara Malik', 'time': '12 min ago', 'icon': Icons.report_problem_outlined, 'color': Color(0xFFEF4444), 'status': 'Open'},
  {'title': 'Damage claim Rs 8,500 filed', 'time': '1 hr ago', 'icon': Icons.broken_image_outlined, 'color': Color(0xFFF59E0B), 'status': 'Pending'},
  {'title': 'Kamran Shah account banned', 'time': '2 hr ago', 'icon': Icons.block, 'color': Color(0xFFEF4444), 'status': 'Banned'},
  {'title': 'Deposit refund Rs 5,000 sent', 'time': '3 hr ago', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF10B981), 'status': 'Done'},
];

// ─────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────
void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}
