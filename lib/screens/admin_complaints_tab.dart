import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import '../services/workers_service.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart' show bilingual, showToast, AppRoutes, ConversationArguments;

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

typedef _ComplaintsTab = AdminComplaintsTab;
class AdminComplaintsTab extends StatelessWidget {
  const AdminComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B5E),
        title: const Text('Complaints',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: streamComplaints(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final open = docs.where((d) => !((d.data() as Map)['resolved'] == true)).toList();
          final resolved = docs.where((d) => (d.data() as Map)['resolved'] == true).toList();

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        size: 48,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Complaints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No real complaints have been submitted yet. When a customer or worker lodges a real complaint, it will appear here in real time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (open.isNotEmpty) ...[
                Row(
                  children: [
                    const _SectionHeader(title: 'Open Complaints', color: Color(0xFFEF4444)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${open.length} Open',
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...open.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _ComplaintCard(
                    complaint: data,
                    docId: doc.id,
                    onResolve: () async {
                      await resolveComplaint(doc.id);
                      _snack(context, 'Complaint marked as resolved');
                    },
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Complaint?'),
                          content: const Text('Are you sure you want to permanently delete this complaint?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await deleteComplaint(doc.id);
                        _snack(context, 'Complaint deleted');
                      }
                    },
                  );
                }),
              ],
              if (resolved.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Resolved', color: Color(0xFF10B981)),
                const SizedBox(height: 8),
                ...resolved.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _ComplaintCard(
                    complaint: data,
                    docId: doc.id,
                    onDelete: () async {
                      await deleteComplaint(doc.id);
                      _snack(context, 'Complaint deleted');
                    },
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, this.docId, this.onResolve, this.onDelete});
  final Map<String, dynamic> complaint;
  final String? docId;
  final VoidCallback? onResolve;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final priority = (complaint['priority'] ?? 'Medium').toString();
    final resolved = complaint['resolved'] == true;
    final priorityColor = priority == 'High'
        ? const Color(0xFFEF4444)
        : priority == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    final type = (complaint['type'] ?? 'Complaint').toString();
    final issue = (complaint['issue'] ?? complaint['reason'] ?? complaint['description'] ?? 'No details provided').toString();
    final user = (complaint['customerName'] ?? complaint['user'] ?? complaint['customerId'] ?? 'Customer').toString();
    final worker = (complaint['workerName'] ?? complaint['worker'] ?? complaint['workerId'] ?? 'Worker').toString();

    String dateStr = '';
    final rawDate = complaint['date'];
    final rawCreated = complaint['createdAt'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      dateStr = rawDate.toString();
    } else if (rawCreated is Timestamp) {
      final dt = rawCreated.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    } else {
      dateStr = 'Recent';
    }

    final amount = (complaint['amount'] as num?)?.toDouble() ??
        (complaint['claimAmount'] as num?)?.toDouble() ??
        0.0;
    final jobTitle = complaint['jobTitle']?.toString() ?? '';

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
                  child: Text(type,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700)),
                ),
                if (amount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Rs. ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309))),
                  ),
                ],
                const Spacer(),
                Text(dateStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                    tooltip: 'Delete Complaint',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            if (jobTitle.isNotEmpty && jobTitle != 'General Support') ...[
              const SizedBox(height: 6),
              Text(
                'Job: $jobTitle',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              issue,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text(user,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (worker.isNotEmpty && worker != 'Worker') ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.engineering_outlined,
                      size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 3),
                  Text(worker,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ],
            ),
            if (!resolved && onResolve != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final targetUserId = (complaint['customerId']?.toString().isNotEmpty ?? false)
                            ? complaint['customerId'].toString()
                            : (complaint['workerId']?.toString() ?? '');
                        final targetName = (complaint['customerName'] ?? complaint['user'] ?? complaint['workerName'] ?? 'User').toString();

                        if (targetUserId.isNotEmpty) {
                          try {
                            final existingId = await findExistingConversation(targetUserId);
                            final convId = existingId ?? await createConversation(
                              otherUserId: targetUserId,
                              otherUserName: targetName,
                            );
                            if (context.mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.sharedConversation,
                                arguments: ConversationArguments(
                                  conversationId: convId,
                                  otherName: targetName,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) _snack(context, 'Error opening chat: $e');
                          }
                        } else {
                          _snack(context, 'No user ID associated with this complaint');
                        }
                      },
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
// TAB 3 – User Management (Firestore-backed)
// ─────────────────────────────────────────────