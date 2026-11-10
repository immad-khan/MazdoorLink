import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import '../services/workers_service.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart' show bilingual, showToast;

typedef _WorkerRegistrationsTab = AdminWorkerRegistrationsTab;
class AdminWorkerRegistrationsTab extends StatefulWidget {
  const AdminWorkerRegistrationsTab({super.key});

  @override
  State<AdminWorkerRegistrationsTab> createState() => _AdminWorkerRegistrationsTabState();
}

class _AdminWorkerRegistrationsTabState extends State<AdminWorkerRegistrationsTab> {
  String _selectedCategory = 'approved';

  String _getWorkerStatus(Map<String, dynamic> data) {
    final s = (data['workerStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase().trim();
    if (s == 'approved') return 'approved';
    if (s == 'rejected' || s == 'declined') return 'rejected';
    return 'pending';
  }

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

  void _rejectWorker(
    BuildContext context,
    String docId,
    String workerName,
    String workerEmail,
  ) {
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
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              await FirebaseFirestore.instance.collection('users').doc(docId).update({
                'status': 'rejected',
                'workerStatus': 'rejected',
                'rejectReason': reason,
              });
              final emailSent = await SmtpService.sendWorkerRejectionEmail(
                email: workerEmail,
                workerName: workerName,
                reason: reason,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    emailSent
                        ? 'Worker rejected and email sent.'
                        : 'Worker rejected, but email could not be sent.',
                  ),
                  duration: const Duration(seconds: 7),
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveWorker(
    BuildContext context,
    String docId,
    String workerName,
    String workerEmail, {
    String? workerPhone,
    String? otpVerifiedVia,
    String? notificationPreference,
  }) async {
    // Fetch latest user document to ensure up-to-date phone and notification preference
    Map<String, dynamic> uData = {};
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      uData = snap.data() ?? {};
    } catch (_) {}

    final phone = (uData['phone']?.toString().isNotEmpty == true)
        ? uData['phone'].toString()
        : (workerPhone ?? '');
    final email = (uData['email']?.toString().isNotEmpty == true)
        ? uData['email'].toString()
        : workerEmail;
    final name = (uData['name']?.toString().isNotEmpty == true)
        ? uData['name'].toString()
        : workerName;
    final otpVia = uData['otpVerifiedVia']?.toString() ?? otpVerifiedVia ?? '';
    final pref = uData['notificationPreference']?.toString() ?? notificationPreference;

    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'status': 'approved',
      'workerStatus': 'approved',
      'roles': FieldValue.arrayUnion(['worker']),
    });

    // Notification channel logic:
    // If worker specified a preference in settings:
    // 'phone' -> SMS only
    // 'email' -> Email only
    // 'both' -> Both SMS and Email
    // If no preference set yet:
    // If worker asked OTP on number ('phone') -> send SMS on number as well!
    // If worker used OTP for email ('email') -> send email.
    bool sendEmail = false;
    bool sendSms = false;

    if (pref == 'phone') {
      sendSms = true;
    } else if (pref == 'email') {
      sendEmail = true;
    } else if (pref == 'both') {
      sendEmail = true;
      sendSms = true;
    } else {
      if (otpVia == 'phone') {
        sendSms = true;
        if (email.isNotEmpty && email != 'No email' && email.contains('@')) {
          sendEmail = true;
        }
      } else {
        sendEmail = true;
      }
    }

    bool emailSent = false;
    bool smsSent = false;

    if (sendEmail && email.isNotEmpty && email != 'No email' && email.contains('@')) {
      emailSent = await SmtpService.sendWorkerApprovalEmail(
        email: email,
        workerName: name,
      );
    }

    if (sendSms && phone.isNotEmpty && phone != 'No phone') {
      smsSent = await SmsService.sendWorkerApprovalSms(
        phoneNumber: phone,
        workerName: name,
      );
    }

    final List<String> details = [];
    if (sendEmail) {
      details.add(emailSent ? 'Email sent' : 'Email failed');
    }
    if (sendSms) {
      details.add(smsSent ? 'SMS sent to $phone' : 'SMS failed');
    }
    final summary = details.isNotEmpty ? ' (${details.join(', ')})' : '';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name approved.$summary'),
          duration: const Duration(seconds: 7),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showWorkerDetail(BuildContext context, Map<String, dynamic> w, String docId) {
    final name = w['name'] ?? 'Unknown';
    final email = w['email'] ?? 'No email';
    final phone = w['phone'] ?? 'No phone';
    final cnicNumber = w['cnicNumber'];
    final status = _getWorkerStatus(w);
    final idFrontUrl = w['idFrontUrl'];
    final idBackUrl = w['idBackUrl'];
    final policeCertUrl = w['policeCertUrl'];
    final certificationUrl = w['certificationUrl'];
    final List<String> allCerts = [];
    final rawCerts = w['certificates'] ?? w['certificateUrls'];
    if (rawCerts is List) {
      for (final item in rawCerts) {
        if (item != null && item.toString().isNotEmpty) {
          allCerts.add(item.toString());
        }
      }
    }
    if (allCerts.isEmpty) {
      if (policeCertUrl != null && policeCertUrl.toString().isNotEmpty) {
        allCerts.add(policeCertUrl.toString());
      }
      if (certificationUrl != null &&
          certificationUrl.toString().isNotEmpty &&
          !allCerts.contains(certificationUrl.toString())) {
        allCerts.add(certificationUrl.toString());
      }
    }
    final category = w['category'];
    final categoryNameEn = w['categoryNameEn'];
    final categoryNameUr = w['categoryNameUr'];
    final skills = w['skills'] as List<dynamic>?;
    final setupComplete = w['setupComplete'] as bool? ?? false;
    final profilePicUrl = w['profilePicUrl'] ?? w['profileImage'];

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
                      backgroundImage: profilePicUrl != null && profilePicUrl.toString().isNotEmpty
                          ? NetworkImage(profilePicUrl.toString())
                          : null,
                      child: profilePicUrl == null || profilePicUrl.toString().isEmpty
                          ? Text(
                              name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF006B5E), fontWeight: FontWeight.bold, fontSize: 28),
                            )
                          : null,
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
                  if (cnicNumber != null) _detailField('CNIC Number', cnicNumber.toString(), Icons.badge_outlined),
                  if (category != null) _detailField('Category (Key)', category.toString(), Icons.category_outlined),
                  if (categoryNameEn != null) _detailField('Category (English)', categoryNameEn.toString(), Icons.translate),
                  if (categoryNameUr != null) _detailField('Category (Urdu)', categoryNameUr.toString(), Icons.translate),

                  const SizedBox(height: 16),

                  // ID Images
                  if (idFrontUrl != null || idBackUrl != null) ...[
                    const Text('ID Card Images', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  if (allCerts.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFF0D9488)),
                        const SizedBox(width: 6),
                        Text(
                          'Certificates & Documents (${allCerts.length}):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...allCerts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final certUrl = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificate #${idx + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                certUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 100,
                                  color: Colors.grey.shade100,
                                  child: const Center(child: Text('Could not load certificate image')),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
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
                  if (status == 'pending') ...[
                    const Divider(height: 24),
                    const Text('Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectWorker(context, docId, name.toString(), email.toString());
                            },
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
                            onPressed: () {
                              Navigator.pop(context);
                              _approveWorker(
                                context,
                                docId,
                                name.toString(),
                                email.toString(),
                                workerPhone: phone.toString(),
                                otpVerifiedVia: w['otpVerifiedVia']?.toString(),
                                notificationPreference: w['notificationPreference']?.toString(),
                              );
                            },
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

  Widget _buildCategoryHeader({
    required int approvedCount,
    required int pendingCount,
    required int rejectedCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            category: 'approved',
            label: 'Approved',
            count: approvedCount,
            activeColor: const Color(0xFF10B981),
            icon: Icons.check_circle_outline_rounded,
          ),
          _buildSegmentItem(
            category: 'pending',
            label: 'Pending',
            count: pendingCount,
            activeColor: const Color(0xFFF59E0B),
            icon: Icons.hourglass_top_rounded,
          ),
          _buildSegmentItem(
            category: 'rejected',
            label: 'Rejected',
            count: rejectedCount,
            activeColor: const Color(0xFFEF4444),
            icon: Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String category,
    required String label,
    required int count,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : activeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    String subtitle;
    Color color;

    if (_selectedCategory == 'approved') {
      icon = Icons.verified_outlined;
      title = 'No approved workers';
      subtitle = 'Approved workers will appear here';
      color = const Color(0xFF10B981);
    } else if (_selectedCategory == 'pending') {
      icon = Icons.hourglass_empty_rounded;
      title = 'No pending registrations';
      subtitle = 'New worker applications will appear here for review';
      color = const Color(0xFFF59E0B);
    } else {
      icon = Icons.cancel_outlined;
      title = 'No rejected workers';
      subtitle = 'Rejected worker applications will appear here';
      color = const Color(0xFFEF4444);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
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
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role']?.toString();
            final roles = (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final workerStatus = data['workerStatus']?.toString();
            return role == 'worker' || roles.contains('worker') || workerStatus != null;
          }).toList();

          int pendingCount = 0;
          int approvedCount = 0;
          int rejectedCount = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final st = _getWorkerStatus(data);
            if (st == 'pending') {
              pendingCount++;
            } else if (st == 'approved') {
              approvedCount++;
            } else if (st == 'rejected') {
              rejectedCount++;
            }
          }

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _getWorkerStatus(data) == _selectedCategory;
          }).toList();

          return Column(
            children: [
              _buildCategoryHeader(
                approvedCount: approvedCount,
                pendingCount: pendingCount,
                rejectedCount: rejectedCount,
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No worker registrations found.'))
                    : filteredDocs.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: filteredDocs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final w = filteredDocs[i].data() as Map<String, dynamic>;
                              final docId = filteredDocs[i].id;
                              
                              final name = w['name'] ?? 'Unknown';
                              final email = w['email'] ?? 'No email';
                              final status = _getWorkerStatus(w);
                              final idFrontUrl = w['idFrontUrl'];
                              final idBackUrl = w['idBackUrl'];
                              final profilePicUrl = w['profilePicUrl'] ?? w['profileImage'];

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
                                  onTap: () => _showWorkerDetail(context, w, docId),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
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
                                                backgroundImage: profilePicUrl != null && profilePicUrl.toString().isNotEmpty
                                                    ? NetworkImage(profilePicUrl.toString())
                                                    : null,
                                                child: profilePicUrl == null || profilePicUrl.toString().isEmpty
                                                    ? Text(
                                                        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                                                        style: const TextStyle(
                                                            color: Color(0xFF006B5E),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18),
                                                      )
                                                    : null,
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
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor),
                                                ),
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
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 2 – Complaints
// ─────────────────────────────────────────────