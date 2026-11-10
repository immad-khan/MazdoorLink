import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mazdoor_flow.dart';
import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import '../services/workers_service.dart';

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

// Public alias & typedef
typedef _UserManagementTab = AdminUserManagementTab;
class AdminUserManagementTab extends StatefulWidget {
  const AdminUserManagementTab({super.key});

  @override
  State<AdminUserManagementTab> createState() => _AdminUserManagementTabState();
}

class _AdminUserManagementTabState extends State<AdminUserManagementTab> {
  String _searchQuery = '';

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return '';
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is String) {
      date = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      return '';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _displayStatus(String? status) {
    switch (status) {
      case 'approved':
      case 'active':
        return 'Active';
      case 'suspended':
        return 'Suspended';
      case 'banned':
        return 'Banned';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Active';
    }
  }

  Future<void> _updateUserStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'status': newStatus,
    });
  }

  void _showDeductDepositDialog(BuildContext context, String workerId, String workerName) async {
    final depositSnap = await FirebaseFirestore.instance
        .collection('security_deposits')
        .where('workerId', isEqualTo: workerId)
        .limit(1)
        .get();
    final currentBalance = depositSnap.docs.isNotEmpty
        ? ((depositSnap.docs.first.data()['currentBalance'] as num?)?.toDouble() ?? 0)
        : 0.0;

    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deduct Security Deposit: $workerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Top-up Balance: Rs. ${currentBalance.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);

              if (depositSnap.docs.isNotEmpty) {
                final docId = depositSnap.docs.first.id;
                final newBalance = currentBalance - amount;
                await FirebaseFirestore.instance.collection('security_deposits').doc(docId).update({
                  'currentBalance': newBalance,
                  'lastDeductionAt': FieldValue.serverTimestamp(),
                });
              }
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final query = _searchQuery.toLowerCase();
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name']?.toString() ?? '').toLowerCase();
                  return name.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching users.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    final docId = filtered[i].id;
                    final name = data['name']?.toString() ?? 'Unknown';
                    final role = data['role']?.toString() ?? 'customer';
                    final isWorker = role == 'worker';
                    final displayStatus = _displayStatus(data['status']?.toString());
                    final joined = _formatJoinDate(data['createdAt']);
                    final profilePicUrl = data['profilePicUrl'] ?? data['profileImage'];

                    Color statusColor;
                    switch (displayStatus) {
                      case 'Active':
                        statusColor = const Color(0xFF10B981);
                        break;
                      case 'Suspended':
                        statusColor = const Color(0xFFF59E0B);
                        break;
                      case 'Banned':
                      case 'Rejected':
                        statusColor = const Color(0xFFEF4444);
                        break;
                      default:
                        statusColor = const Color(0xFFF59E0B);
                    }

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
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: (isWorker
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF0D9488))
                              .withOpacity(0.12),
                          backgroundImage: profilePicUrl != null &&
                                  profilePicUrl.toString().isNotEmpty
                              ? NetworkImage(profilePicUrl.toString())
                              : null,
                          child: profilePicUrl == null ||
                                  profilePicUrl.toString().isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: isWorker
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF0D9488)),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B))),
                        subtitle: Text(
                            '${isWorker ? 'Worker' : 'Customer'}${joined.isNotEmpty ? ' · Since $joined' : ''}',
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
                              child: Text(displayStatus,
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
                                  _showDeductDepositDialog(
                                      context, docId, name);
                                  return;
                                }
                                _updateUserStatus(docId, value);
                                _snack(context, '$name has been ${value.toLowerCase()}');
                              },
                              itemBuilder: (_) => [
                                if (isWorker)
                                  const PopupMenuItem(
                                    value: 'DeductDeposit',
                                    child: Text('Deduct Security Deposit'),
                                  ),
                                const PopupMenuItem(
                                    value: 'approved',
                                    child: Text('Restore / Activate')),
                                const PopupMenuItem(
                                    value: 'suspended',
                                    child: Text('Suspend User')),
                                const PopupMenuItem(
                                    value: 'banned',
                                    child: Text('Ban User')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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