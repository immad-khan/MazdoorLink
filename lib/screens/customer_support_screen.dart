import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _complaintController = TextEditingController();
  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedOrder;
  bool _isSubmitting = false;
  int _selectedTab = 0; // 0 = File Complaint, 1 = My Complaints

  @override
  void dispose() {
    _complaintController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    }
    if (dt == null) return '';
    return DateFormat('d MMM yyyy').format(dt);
  }

  Future<void> _submitComplaint({bool openChat = false}) async {
    final issue = _complaintController.text.trim();
    final isUrdu = AppScope.of(context).isUrdu;

    if (issue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'براہ کرم شکایت کی تفصیلات درج کریں'
                : 'Please describe the issue before submitting',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu ? 'براہ کرم پہلے لاگ ان کریں' : 'Please log in to submit a complaint',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String customerName = user.displayName ?? '';
      if (customerName.isEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        customerName = userDoc.data()?['name']?.toString() ?? 'Customer';
      }

      final claimAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final isGeneral = _selectedOrder?['isGeneral'] == true;
      final jobId = isGeneral ? '' : (_selectedOrder?['id'] ?? _selectedOrder?['jobId'] ?? '');
      final jobTitle = isGeneral
          ? 'General Support'
          : (_selectedOrder?['title'] ?? _selectedOrder?['descriptionEn'] ?? 'Service Job');
      final workerId = isGeneral ? '' : (_selectedOrder?['workerId'] ?? '');
      final workerName = isGeneral ? '' : (_selectedOrder?['workerName'] ?? '');

      final now = DateTime.now();
      final dateStr = DateFormat('d MMM yyyy').format(now);

      await FirebaseFirestore.instance.collection('complaints').add({
        'jobId': jobId,
        'jobTitle': jobTitle,
        'customerId': user.uid,
        'customerName': customerName,
        'customerEmail': user.email ?? '',
        'user': customerName,
        'workerId': workerId,
        'workerName': workerName,
        'worker': workerName,
        'type': isGeneral ? 'General Support' : 'Service Complaint',
        'issue': issue,
        'reason': issue,
        'amount': claimAmount,
        'claimAmount': claimAmount,
        'priority': claimAmount > 0 ? 'High' : 'Medium',
        'status': 'pending',
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'date': dateStr,
      });

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _complaintController.clear();
        _amountController.clear();
        _selectedOrder = null;
        _selectedTab = 1;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 28),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'شکایت درج ہو گئی' : 'Complaint Submitted',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isUrdu
                ? 'آپ کی شکایت ایڈمن کو بھیج دی گئی ہے۔ جلد آپ سے رابطہ کیا جائے گا۔'
                : 'Your complaint has been submitted successfully to admin. Our team will review it shortly.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (openChat) {
                  Navigator.pushNamed(context, '/shared/chat');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
              ),
              child: Text(isUrdu ? 'شکایات دیکھیں' : (openChat ? 'Open Chat' : 'View Complaints')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit complaint: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    final user = FirebaseAuth.instance.currentUser;

    if (_selectedOrder != null) {
      return _buildComplaintForm(isUrdu);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isUrdu ? 'کسٹمر سپورٹ' : 'Customer Support'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: user == null
          ? Center(
              child: Text(
                isUrdu
                    ? 'شکایت درج کرنے کے لیے لاگ ان کریں'
                    : 'Please log in to view orders and file complaints.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              children: [
                _buildSegmentedControl(isUrdu),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildFileComplaintTab(user, isUrdu)
                      : _buildMyComplaintsTab(user, isUrdu),
                ),
              ],
            ),
    );
  }

  Widget _buildSegmentedControl(bool isUrdu) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isUrdu ? 'شکایت درج کریں' : 'File Complaint',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isUrdu ? 'میری شکایات' : 'My Complaints',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 1
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileComplaintTab(User user, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            isUrdu ? 'آپ کو کس آرڈر میں مدد چاہیے؟' : 'Which order do you need help with?',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        // General Issue option card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedOrder = {
                  'isGeneral': true,
                  'title': isUrdu ? 'عام مسئلہ / سپورٹ' : 'General Issue / Support',
                  'workerName': isUrdu ? 'ایڈمن سپورٹ' : 'Platform Support',
                  'date': isUrdu ? 'آج' : 'Today',
                };
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF99F6E4), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_center_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'عام شکایت یا سوال' : 'General Support / Inquiry',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUrdu
                              ? 'کسی خاص آرڈر کے بغیر ایپ یا سروس کے بارے میں رابطہ کریں'
                              : 'Not related to a specific order (app issue, question)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0D9488)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(
            isUrdu ? 'یا پچھلے آرڈرز میں سے منتخب کریں:' : 'Or select from your recent orders:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('customerId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    isUrdu ? 'لوڈ کرنے میں خرابی' : 'Error loading orders',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          isUrdu
                              ? 'ابھی تک کوئی پچھلا آرڈر نہیں ہے۔\nآپ اوپر "عام شکایت" کا انتخاب کر سکتے ہیں۔'
                              : 'No past orders found.\nYou can select "General Support" above to submit an issue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['descriptionEn']?.toString() ??
                      data['title']?.toString() ??
                      'Service Order';
                  final workerName = data['workerName']?.toString() ?? 'Worker';
                  final dateStr = _formatDate(data['createdAt']);
                  final status = data['status']?.toString() ?? 'completed';

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOrder = {
                          'isGeneral': false,
                          'id': doc.id,
                          'jobId': doc.id,
                          'title': title,
                          'workerName': workerName,
                          'workerId': data['workerId']?.toString() ?? '',
                          'date': dateStr,
                          'status': status,
                        };
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history, color: Color(0xFF0D9488)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$workerName • $dateStr',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
    );
  }

  Widget _buildMyComplaintsTab(User user, bool isUrdu) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('customerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              isUrdu ? 'شکایات لوڈ کرنے میں خرابی' : 'Error loading complaints: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'] as Timestamp?;
            final bTs = bData['createdAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

        if (sortedDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUrdu ? 'کوئی شکایت نہیں ملی' : 'No Complaints Filed',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUrdu
                        ? 'آپ نے ابھی تک کوئی شکایت درج نہیں کروائی۔ جب آپ شکایت جمع کروائیں گے، وہ یہاں نظر آئے گی۔'
                        : 'You have not submitted any complaints yet. When you file a complaint, it will appear here in real time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final data = sortedDocs[index].data() as Map<String, dynamic>;
            final isResolved = data['resolved'] == true;
            final type = data['type']?.toString() ?? 'Complaint';
            final issue = (data['issue'] ?? data['reason'] ?? data['description'] ?? 'No details').toString();
            final jobTitle = data['jobTitle']?.toString() ?? '';
            final worker = (data['workerName'] ?? data['worker'] ?? '').toString();
            final dateStr = (data['date'] ?? _formatDate(data['createdAt'])).toString();
            final amount = (data['amount'] as num?)?.toDouble() ?? (data['claimAmount'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isResolved
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : const Color(0xFFF59E0B).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isResolved ? Icons.check_circle_outline : Icons.hourglass_top,
                              size: 13,
                              color: isResolved ? const Color(0xFF059669) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isResolved
                                  ? (isUrdu ? 'حل ہو گئی' : 'Resolved')
                                  : (isUrdu ? 'زیرِ جائزہ' : 'Under Review'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isResolved ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                        ),
                      ),
                      const Spacer(),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  if (jobTitle.isNotEmpty && jobTitle != 'General Support') ...[
                    const SizedBox(height: 8),
                    Text(
                      worker.isNotEmpty ? '$jobTitle ($worker)' : jobTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    issue,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                  ),
                  if (amount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUrdu
                            ? 'دعویٰ کی رقم: Rs. ${amount.toStringAsFixed(0)}'
                            : 'Claim Amount: Rs. ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/shared/chat'),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF0D9488)),
                      label: Text(
                        isUrdu ? 'ایڈمن سے رابطہ کریں' : 'Chat with Admin',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                      ),
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
  Widget _buildComplaintForm(bool isUrdu) {
    final title = _selectedOrder?['title'] ?? 'Order';
    final worker = _selectedOrder?['workerName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isUrdu ? 'شکایت درج کریں' : 'File a Complaint'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedOrder = null;
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0D9488)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      worker.isNotEmpty
                          ? (isUrdu ? '$title ($worker) کے لیے شکایت' : 'Filing complaint for $title ($worker)')
                          : (isUrdu ? '$title کے لیے شکایت' : 'Filing complaint for $title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isUrdu ? 'تفصیلات بتائیں *' : 'Describe the issue *',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _complaintController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: isUrdu ? 'مسئلہ تفصیل سے لکھیں...' : 'Write your complaint in detail...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF0D9488)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUrdu ? 'کیا کوئی نقصان ہوا؟ (اختیاری)' : 'Claim Amount? (Optional)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF0D9488)),
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : () => _submitComplaint(openChat: false),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isUrdu ? 'شکایت جمع کروائیں' : 'Submit Complaint',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _submitComplaint(openChat: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isUrdu ? 'جمع کروائیں اور ایڈمن سے چیٹ کریں' : 'Submit & Chat with Admin',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
