import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  String _customerPaymentQuery = '';
  String _workerTopupQuery = '';

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FA),
        appBar: AppBar(
          title: Text(
            isUrdu ? 'ٹرانزیکشنز اور ادائیگیاں' : 'Transactions & Payments',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF006B5E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFFFFC107),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.payments_rounded, size: 20),
                text: isUrdu ? 'کسٹمر ادائیگیاں' : 'Customer Payments',
              ),
              Tab(
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                text: isUrdu ? 'ورکر ٹاپ اپس' : 'Worker Top-ups',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCustomerPaymentsTab(context, isUrdu),
            _buildWorkerTopupsTab(context, isUrdu),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: Customer Payments (Paid to Workers)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCustomerPaymentsTab(BuildContext context, bool isUrdu) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: isUrdu ? 'کسٹمر، ورکر یا سروس تلاش کریں...' : 'Search by customer, worker, or service...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF006B5E)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() => _customerPaymentQuery = val.trim().toLowerCase());
            },
          ),
        ),

        // Stream from 'jobs' collection
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    isUrdu ? 'ڈیٹا لوڈ کرنے میں غلطی' : 'Error loading transactions: ${snapshot.error}',
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF006B5E)));
              }

              final allDocs = snapshot.data?.docs ?? [];
              // Filter completed or paid jobs
              final paidJobs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString().toLowerCase() ?? '';
                final payStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';
                final isPaidOrCompleted = status == 'completed' ||
                    payStatus == 'paid' ||
                    data['paidAt'] != null ||
                    data['customerMarkedPaidAt'] != null;

                if (!isPaidOrCompleted) return false;

                if (_customerPaymentQuery.isEmpty) return true;

                final cName = (data['customerName']?.toString() ?? '').toLowerCase();
                final wName = (data['workerName']?.toString() ?? '').toLowerCase();
                final descEn = (data['descriptionEn']?.toString() ?? '').toLowerCase();
                final cat = (data['categoryKey']?.toString() ?? '').toLowerCase();

                return cName.contains(_customerPaymentQuery) ||
                    wName.contains(_customerPaymentQuery) ||
                    descEn.contains(_customerPaymentQuery) ||
                    cat.contains(_customerPaymentQuery);
              }).toList();

              if (paidJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        isUrdu ? 'کوئی ٹرانزیکشن نہیں ملی' : 'No customer payment transactions found.',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              double totalVolume = 0;
              for (final d in paidJobs) {
                final data = d.data() as Map<String, dynamic>;
                final price = (data['price'] as num?)?.toDouble() ?? 0;
                final tip = (data['tipAmount'] as num?)?.toDouble() ?? 0;
                totalVolume += (price + tip);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: paidJobs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildPaymentsSummaryCard(paidJobs.length, totalVolume, isUrdu);
                  }

                  final doc = paidJobs[index - 1];
                  final job = doc.data() as Map<String, dynamic>;
                  final jobId = doc.id;

                  return _buildCustomerPaymentItem(context, job, jobId, isUrdu);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsSummaryCard(int count, double totalVolume, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D45), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B5E).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu ? 'کل ادا شدہ رقم' : 'Total Amount Paid',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs. ${totalVolume.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu ? 'مکمل ادائیگیاں' : 'Transactions',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPaymentItem(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    bool isUrdu,
  ) {
    final title = job['descriptionEn']?.toString() ??
        job['descriptionUr']?.toString() ??
        job['categoryKey']?.toString() ??
        'Service Job';
    final customer = job['customerName']?.toString() ?? 'Customer';
    final worker = job['workerName']?.toString() ?? 'Worker';
    final price = (job['price'] as num?)?.toDouble() ?? 0;
    final tip = (job['tipAmount'] as num?)?.toDouble() ?? 0;
    final total = price + tip;
    final method = job['paymentMethod']?.toString() ?? 'Cash';
    final isOnline = method.toLowerCase() != 'cash';

    final ts = (job['completedAt'] ?? job['paidAt'] ?? job['createdAt']) as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('d MMM yyyy, hh:mm a').format(ts.toDate())
        : 'Recently';

    final rating = (job['customerRating'] as num?)?.toDouble() ??
        (job['rating'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showCustomerPaymentDetail(context, job, jobId, isUrdu),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOnline ? Icons.credit_card_rounded : Icons.payments_rounded,
                        color: isOnline ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$customer  ➔  $worker',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF006B5E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            method,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOnline
                                  ? const Color(0xFF0369A1)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          if (job['customerReview'] != null &&
                              job['customerReview'].toString().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• "${job['customerReview']}"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        isUrdu ? 'جائزہ ابھی باقی ہے' : 'No rating given yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    Row(
                      children: [
                        Text(
                          isUrdu ? 'مکمل تفصیلات' : 'View Details',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: Color(0xFF0D9488)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Customer Payment Detail Modal Sheet
  // ─────────────────────────────────────────────────────────────
  void _showCustomerPaymentDetail(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    bool isUrdu,
  ) {
    final title = job['descriptionEn']?.toString() ??
        job['descriptionUr']?.toString() ??
        job['categoryKey']?.toString() ??
        'Service Job';
    final customer = job['customerName']?.toString() ?? 'Customer';
    final worker = job['workerName']?.toString() ?? 'Worker';
    final customerId = job['customerId']?.toString() ?? '';
    final workerId = job['workerId']?.toString() ?? '';
    final category = job['categoryKey']?.toString() ?? 'general';
    final price = (job['price'] as num?)?.toDouble() ?? 0;
    final tip = (job['tipAmount'] as num?)?.toDouble() ?? 0;
    final total = price + tip;
    final method = job['paymentMethod']?.toString() ?? 'Cash';
    final rating = (job['customerRating'] as num?)?.toInt() ?? 0;
    final reviewText = job['customerReview']?.toString() ?? '';

    final area = job['area']?.toString();
    final city = job['city']?.toString();
    final address = job['locationAddress']?.toString() ??
        job['customerAddress']?.toString() ??
        (area != null ? '$area, ${city ?? 'Twin Cities'}' : 'Twin Cities, Pakistan');
    final lat = job['customerLatitude'] ?? job['latitude'];
    final lng = job['customerLongitude'] ?? job['longitude'];

    final beforePhotos = job['beforePhotos'] as List<dynamic>?;
    final afterPhotos = job['afterPhotos'] as List<dynamic>?;

    final ts = (job['completedAt'] ?? job['paidAt'] ?? job['createdAt']) as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('EEEE, d MMMM yyyy, hh:mm a').format(ts.toDate())
        : 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Badge & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Payment Completed',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '#$jobId',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 28),

                  // ── SECTION 1: PROFILES (Worker & Customer) ───────────
                  _buildSectionHeader(Icons.people_alt_outlined, 'Profiles Involved', isUrdu ? 'افراد کی پروفائلز' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Customer profile card
                      Expanded(
                        child: _buildProfileCard(
                          title: 'Customer',
                          name: customer,
                          sub: 'ID: ${customerId.isNotEmpty ? customerId.substring(0, customerId.length.clamp(0, 8)) : "N/A"}',
                          icon: Icons.person_outline,
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Worker profile card
                      Expanded(
                        child: _buildProfileCard(
                          title: 'Worker (${category.toUpperCase()})',
                          name: worker,
                          sub: 'ID: ${workerId.isNotEmpty ? workerId.substring(0, workerId.length.clamp(0, 8)) : "N/A"}',
                          icon: Icons.handyman_outlined,
                          iconBg: const Color(0xFFCCFBF1),
                          iconColor: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 2: WORK DONE ─────────────────────────────
                  _buildSectionHeader(Icons.build_circle_outlined, 'Work Performed', isUrdu ? 'کیا گیا کام' : null),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category: ${category.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                        ),
                        if (beforePhotos != null && beforePhotos.isNotEmpty ||
                            afterPhotos != null && afterPhotos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Before & After Photos:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (beforePhotos != null)
                                ...beforePhotos.map((url) => _buildPhotoThumb(url.toString(), 'Before')),
                              if (afterPhotos != null)
                                ...afterPhotos.map((url) => _buildPhotoThumb(url.toString(), 'After')),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 3: RECEIPT OF WORK ─────────────────────────
                  _buildSectionHeader(Icons.receipt_long_outlined, 'Receipt & Payment Details', isUrdu ? 'ادائیگی کی رسید' : null),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('Base Job Price', 'Rs. ${price.toStringAsFixed(0)}'),
                        if (tip > 0) ...[
                          const SizedBox(height: 6),
                          _buildReceiptRow('Worker Tip', 'Rs. ${tip.toStringAsFixed(0)}'),
                        ],
                        const SizedBox(height: 6),
                        _buildReceiptRow('Payment Method', method, isHighlight: true),
                        const SizedBox(height: 6),
                        _buildReceiptRow('Status', 'Verified & Received', isHighlight: true, isGreen: true),
                        const Divider(height: 16),
                        _buildReceiptRow('Total Amount Paid', 'Rs. ${total.toStringAsFixed(0)}', isBold: true, isLarge: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 4: RATINGS & FEEDBACK ──────────────────────
                  _buildSectionHeader(Icons.star_outline_rounded, 'Ratings & Reviews Exchanged', isUrdu ? 'درجہ بندی اور جائزہ' : null),
                  const SizedBox(height: 8),
                  Container(
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
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 22,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rating > 0 ? '$rating / 5 Stars' : 'No Rating',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (reviewText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"$reviewText"',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Customer gave rating without written comments.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 5: PLACE WHERE WORK WAS DONE ──────────────
                  _buildSectionHeader(Icons.location_on_outlined, 'Place of Service', isUrdu ? 'سروس کا مقام' : null),
                  const SizedBox(height: 8),
                  Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lat != null && lng != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              'GPS Coordinates: ${lat.toString().substring(0, (lat.toString().length).clamp(0, 8))}, ${lng.toString().substring(0, (lng.toString().length).clamp(0, 8))}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006B5E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close Details'),
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

  // ─────────────────────────────────────────────────────────────
  // TAB 2: Worker Top-ups (Amount Worker Topped into Account)
  // ─────────────────────────────────────────────────────────────
  Widget _buildWorkerTopupsTab(BuildContext context, bool isUrdu) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: isUrdu ? 'ورکر کا نام تلاش کریں...' : 'Search by worker name...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF006B5E)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() => _workerTopupQuery = val.trim().toLowerCase());
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('security_deposits')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    isUrdu ? 'ڈیٹا لوڈ کرنے میں غلطی' : 'Error loading top-ups: ${snapshot.error}',
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF006B5E)));
              }

              final allDocs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
              allDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTs = (aData['updatedAt'] ?? aData['lastTopUpAt'] ?? aData['createdAt']) as Timestamp?;
                final bTs = (bData['updatedAt'] ?? bData['lastTopUpAt'] ?? bData['createdAt']) as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });

              final filteredDocs = allDocs.where((doc) {
                if (_workerTopupQuery.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final wName = (data['workerName']?.toString() ?? '').toLowerCase();
                return wName.contains(_workerTopupQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        isUrdu ? 'کوئی ٹاپ اپ نہیں ملا' : 'No worker top-up transactions found.',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              double totalDeposits = 0;
              double totalCurrentBalance = 0;
              for (final d in filteredDocs) {
                final data = d.data() as Map<String, dynamic>;
                totalDeposits += (data['totalDeposited'] as num?)?.toDouble() ?? 0;
                totalCurrentBalance += (data['currentBalance'] as num?)?.toDouble() ?? 0;
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filteredDocs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildTopupSummaryCard(totalDeposits, totalCurrentBalance, filteredDocs.length, isUrdu);
                  }

                  final doc = filteredDocs[index - 1];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  return _buildWorkerTopupItem(context, data, docId, isUrdu);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopupSummaryCard(double totalDeposited, double totalBalance, int count, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006B5E), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B5E).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'کل ٹاپ اپ رقم' : 'Total Top-ups (Deposits)',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${totalDeposited.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Container(height: 38, width: 1, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'موجودہ بیلنس' : 'Active Wallet Balance',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${totalBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  isUrdu ? 'پلیٹ فارم 2٪ کمیشن اسی ٹاپ اپ سے کٹے گا' : 'Platform 2% commission will deduct from this balance',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerTopupItem(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    bool isUrdu,
  ) {
    final workerName = data['workerName']?.toString() ?? 'Worker';
    final totalDeposited = (data['totalDeposited'] as num?)?.toDouble() ?? 0;
    final currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? 0;
    final method = data['method']?.toString() ?? 'Safepay';
    final status = data['status']?.toString() ?? 'Active';
    final isSafepay = method.toLowerCase() == 'safepay';

    final ts = (data['lastTopUpAt'] ?? data['updatedAt'] ?? data['createdAt']) as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('d MMM yyyy, hh:mm a').format(ts.toDate())
        : 'Recently';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showWorkerTopupDetail(context, data, docId, isUrdu),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFCCFBF1),
                  child: Text(
                    workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                    style: const TextStyle(
                      color: Color(0xFF006B5E),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSafepay ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              method,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSafepay ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${totalDeposited.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF006B5E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'Active' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Bal: Rs. ${currentBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'Active' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Worker Top-up Detail Modal Sheet
  // ─────────────────────────────────────────────────────────────
  void _showWorkerTopupDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    bool isUrdu,
  ) {
    final workerId = data['workerId']?.toString() ?? '';
    final workerName = data['workerName']?.toString() ?? 'Worker';
    final totalDeposited = (data['totalDeposited'] as num?)?.toDouble() ?? 0;
    final currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? 0;
    final method = data['method']?.toString() ?? 'Safepay';
    final accountNumber = data['accountNumber']?.toString() ?? 'Safepay Online';
    final status = data['status']?.toString() ?? 'Active';

    final ts = (data['lastTopUpAt'] ?? data['updatedAt'] ?? data['createdAt']) as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('EEEE, d MMMM yyyy, hh:mm a').format(ts.toDate())
        : 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: workerId.isNotEmpty
                    ? FirebaseFirestore.instance.collection('users').doc(workerId).get()
                    : null,
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final phone = userData?['phone']?.toString() ?? 'Not provided';
                  final email = userData?['email']?.toString() ?? 'Not provided';
                  final category = userData?['categoryNameEn']?.toString() ??
                      userData?['category']?.toString() ??
                      'Worker';
                  final liveTopupBalance = (userData?['topupBalance'] as num?)?.toDouble() ?? currentBalance;

                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance_wallet, color: Color(0xFF006B5E), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Top-up Record',
                                  style: TextStyle(
                                    color: Color(0xFF006B5E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '#$docId',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Top-up Big Banner Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF004D45), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Current Active Top-up Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs. ${liveTopupBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Lifetime Deposited: Rs. ${totalDeposited.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Worker Profile Info
                      _buildSectionHeader(Icons.person_pin_rounded, 'Worker Information', isUrdu ? 'ورکر کی معلومات' : null),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRow('Worker Name', workerName, isBold: true),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Trade / Category', category),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Phone Number', phone),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Email', email),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Worker UID', workerId.isNotEmpty ? workerId : 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Top-up Transaction Details
                      _buildSectionHeader(Icons.receipt_outlined, 'Top-up Transaction Details', isUrdu ? 'ٹرانزیکشن کی تفصیلات' : null),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRow('Deposit Method', method, isHighlight: true),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Account Reference', accountNumber),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Status', status, isHighlight: true, isGreen: status == 'Active'),
                            const SizedBox(height: 6),
                            _buildReceiptRow('Timestamp', dateStr),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Commission Notice Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Platform 2% Commission Deduction',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Whenever a customer pays this worker for a job, 2% of the payment amount will be automatically cut from this worker\'s top-up balance.',
                                    style: TextStyle(fontSize: 11, color: Colors.green.shade800, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006B5E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title, [String? titleUr]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF006B5E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String name,
    required String sub,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isGreen = false,
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 16 : 12,
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isGreen
                ? const Color(0xFF16A34A)
                : isHighlight
                    ? const Color(0xFF006B5E)
                    : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumb(String url, String label) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            url,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 20)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
