import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────────────────────
// Admin Platform Earnings Screen
// Tracks the 2% platform commission cut from worker top-up balances
// on customer-to-worker payments.
// ─────────────────────────────────────────────────────────────
class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  String _searchQuery = '';
  String _selectedPeriod = 'All Time'; // 'All Time', 'This Month', 'This Week'
  String _paymentMethodFilter = 'All'; // 'All', 'Safepay', 'Cash'

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? 'پلیٹ فارم کی کمائی' : 'Platform Earnings',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              isUrdu
                  ? 'ورکر ٹاپ اپ بیلنس سے 2 فیصد کٹوتی'
                  : '2% commission cut from worker top-up balance',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006B5E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: isUrdu ? 'کمیشن معلومات' : 'Commission Policy',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCommissionInfoDialog(context, isUrdu),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Controls
          _buildFilterBar(isUrdu),

          // Main Earnings List & Analytics
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('platform_earnings')
                  .snapshots(),
              builder: (context, earningsSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .snapshots(),
                  builder: (context, jobsSnap) {
                    if (earningsSnap.connectionState == ConnectionState.waiting &&
                        jobsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF006B5E)),
                      );
                    }

                    // Collect unified commission items
                    final items = _mergeCommissionRecords(
                      earningsSnap.data?.docs ?? [],
                      jobsSnap.data?.docs ?? [],
                    );

                    final filtered = _filterItems(items);

                    // Compute summary metrics
                    double totalEarnings = 0;
                    double totalGrossPaid = 0;
                    for (final item in filtered) {
                      totalEarnings += (item['commissionAmount'] as num?)?.toDouble() ?? 0;
                      totalGrossPaid += (item['totalPaid'] as num?)?.toDouble() ?? 0;
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeroAnalyticsCard(
                            totalEarnings: totalEarnings,
                            totalGrossPaid: totalGrossPaid,
                            count: filtered.length,
                            isUrdu: isUrdu,
                          );
                        }

                        final item = filtered[index - 1];
                        return _buildEarningsItemCard(context, item, isUrdu);
                      },
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

  // ─────────────────────────────────────────────────────────────
  // Filter & Search Header
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(bool isUrdu) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search TextField
          TextField(
            decoration: InputDecoration(
              hintText: isUrdu
                  ? 'ورکر، گاہک، یا کام کی قسم سے تلاش کریں...'
                  : 'Search by worker, customer, or service...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF006B5E)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),

          // Filters Row: Period Chips & Payment Method Dropdown
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('All Time', isUrdu ? 'تمام وقت' : 'All Time'),
                      const SizedBox(width: 6),
                      _buildChip('This Month', isUrdu ? 'اس مہینے' : 'This Month'),
                      const SizedBox(width: 6),
                      _buildChip('This Week', isUrdu ? 'اس ہفتے' : 'This Week'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Payment Method Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMethodFilter,
                    icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF006B5E)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text(isUrdu ? 'تمام طریقے' : 'All Methods'),
                      ),
                      const DropdownMenuItem(
                        value: 'Safepay',
                        child: Text('Safepay Card'),
                      ),
                      const DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash Handover'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethodFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = periodKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006B5E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF006B5E) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hero Analytics Banner
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroAnalyticsCard({
    required double totalEarnings,
    required double totalGrossPaid,
    required int count,
    required bool isUrdu,
  }) {
    final avgCut = count > 0 ? (totalEarnings / count) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D45), Color(0xFF006B5E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B5E).withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUrdu ? 'مجموعی کمائی (2 فیصد کٹوتی)' : 'Total Platform Earnings',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF34D399), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                    SizedBox(width: 4),
                    Text(
                      '2% Platform Cut',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Earnings Figure
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Rs. ',
                style: TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              Text(
                totalEarnings.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Sub-metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubMetric(
                label: isUrdu ? 'گاہک ادائیگی' : 'Gross Job Volume',
                value: 'Rs. ${totalGrossPaid.toStringAsFixed(0)}',
              ),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildSubMetric(
                label: isUrdu ? 'کل ٹرانزیکشنز' : 'Jobs Processed',
                value: '$count',
              ),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildSubMetric(
                label: isUrdu ? 'اوسط فی کام' : 'Avg Cut / Job',
                value: 'Rs. ${avgCut.toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Earnings Transaction Item Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildEarningsItemCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isUrdu,
  ) {
    final worker = item['workerName']?.toString() ?? 'Worker';
    final customer = item['customerName']?.toString() ?? 'Customer';
    final title = item['jobTitle']?.toString() ?? 'Service Job';
    final category = item['categoryKey']?.toString() ?? 'general';
    final totalPaid = (item['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final commission = (item['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final method = item['paymentMethod']?.toString() ?? 'Cash';
    final isSafepay = method.toLowerCase() == 'safepay';

    final ts = item['timestamp'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} • ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : 'Recent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEarningsDetailModal(context, item, isUrdu),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: 2% Badge + Commission Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.percent_rounded,
                        color: Color(0xFF137333),
                        size: 22,
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
                          const SizedBox(height: 3),
                          Text(
                            '$worker  ➔  $customer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+ Rs. ${commission.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF006B5E),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '2% Admin Cut',
                            style: TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 10),

                // Bottom Metadata: Customer Payment, Cut notice, Date, Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isUrdu ? 'گاہک ادائیگی: ' : 'Paid by Customer: ',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Rs. ${totalPaid.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 11,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isUrdu
                                  ? 'ورکر کے ٹاپ اپ بیلنس سے منہا'
                                  : 'Cut from worker top-up',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSafepay
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSafepay
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSafepay ? Icons.credit_card : Icons.payments_rounded,
                                size: 11,
                                color: isSafepay ? Colors.green.shade700 : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSafepay ? 'Safepay' : 'Cash',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSafepay ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
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
  // Detail Drill-Down Modal Sheet
  // ─────────────────────────────────────────────────────────────
  void _showEarningsDetailModal(
    BuildContext context,
    Map<String, dynamic> item,
    bool isUrdu,
  ) {
    final worker = item['workerName']?.toString() ?? 'Worker';
    final workerId = item['workerId']?.toString() ?? '';
    final customer = item['customerName']?.toString() ?? 'Customer';
    final customerId = item['customerId']?.toString() ?? '';
    final title = item['jobTitle']?.toString() ?? 'Service Job';
    final category = item['categoryKey']?.toString() ?? 'general';
    final totalPaid = (item['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final commission = (item['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final workerNet = totalPaid - commission;
    final method = item['paymentMethod']?.toString() ?? 'Cash';
    final isSafepay = method.toLowerCase() == 'safepay';
    final jobId = item['jobId']?.toString() ?? 'JOB';

    final ts = item['timestamp'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} at ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : 'Completed Recently';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              // Drag handle
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'کمیشن ٹرانزیکشن کی تفصیلات' : 'Commission Breakdown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Job ID: $jobId',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 1. 2% Calculation Highlight Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu ? 'پلیٹ فارم کمائی (2 فیصد):' : 'Platform Revenue (2%):',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          '+ Rs. ${commission.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF86EFAC), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMathPill(
                          label: isUrdu ? 'گاہک ادائیگی' : 'Customer Paid',
                          val: 'Rs. ${totalPaid.toStringAsFixed(0)}',
                        ),
                        const Text('×', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534))),
                        _buildMathPill(label: isUrdu ? 'شرح' : 'Fixed Rate', val: '2.0%'),
                        const Text('=', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534))),
                        _buildMathPill(
                          label: isUrdu ? 'ورکر خالص' : 'Worker Net',
                          val: 'Rs. ${workerNet.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Worker Live Top-up Balance Status ──
              const Text(
                'Worker & Top-up Balance Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              if (workerId.isNotEmpty)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(workerId).snapshots(),
                  builder: (context, userSnap) {
                    final uData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                    final liveBalance = (uData['topupBalance'] as num?)?.toDouble() ?? 0.0;
                    final phone = uData['phone']?.toString() ?? 'N/A';
                    final isLow = liveBalance < 500;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF006B5E),
                                child: Text(
                                  worker.isNotEmpty ? worker[0].toUpperCase() : 'W',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Phone: $phone • ID: ${workerId.length > 8 ? workerId.substring(0, 8) : workerId}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'ورکر کا موجودہ ٹاپ اپ بیلنس:' : 'Worker Live Top-up Balance:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rs. ${liveBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isLow ? const Color(0xFFDC2626) : const Color(0xFF006B5E),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                      size: 13,
                                      color: isLow ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isLow ? 'Low Balance' : 'Healthy Balance',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Worker: $worker'),
                ),

              const SizedBox(height: 20),

              // ── 3. Customer Info ──
              const Text(
                'Customer Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF0284C7),
                      child: Text(
                        customer.isNotEmpty ? customer[0].toUpperCase() : 'C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Customer UID: ${customerId.isNotEmpty ? (customerId.length > 8 ? customerId.substring(0, 8) : customerId) : 'N/A'}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 4. Service & Receipt Audit ──
              const Text(
                'Service & Financial Receipt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildAuditRow('Service Title', title),
                    const Divider(height: 16),
                    _buildAuditRow('Category', category.toUpperCase()),
                    const Divider(height: 16),
                    _buildAuditRow('Payment Method', isSafepay ? 'Safepay Online Card' : 'Pay in Cash (Direct)'),
                    const Divider(height: 16),
                    _buildAuditRow('Deduction Status', 'Deducted from Top-up Balance', isGreen: true),
                    const Divider(height: 16),
                    _buildAuditRow('Date & Time', dateStr),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006B5E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(isUrdu ? 'بند کریں' : 'Close Details'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMathPill({required String label, required String val}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF166534))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF14532D))),
      ],
    );
  }

  Widget _buildAuditRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Data Consolidation & Filtering
  // ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _mergeCommissionRecords(
    List<QueryDocumentSnapshot> earningsDocs,
    List<QueryDocumentSnapshot> jobsDocs,
  ) {
    final Map<String, Map<String, dynamic>> map = {};

    // 1. First add dedicated platform_earnings records
    for (final doc in earningsDocs) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      final jobId = data['jobId']?.toString() ?? doc.id;
      map[jobId] = data;
    }

    // 2. Fallback: Add completed/paid jobs that may have happened prior to earnings collection
    for (final doc in jobsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      final payStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';
      final isPaid = status == 'completed' || payStatus == 'paid' || data['paidAt'] != null;

      if (!isPaid) continue;

      final jobId = doc.id;
      if (!map.containsKey(jobId)) {
        final totalPaid = (data['price'] as num?)?.toDouble() ?? 0.0;
        final commission = (data['commissionAmount'] as num?)?.toDouble() ??
            double.parse((totalPaid * 0.02).toStringAsFixed(2));

        map[jobId] = {
          'jobId': jobId,
          'workerId': data['workerId']?.toString() ?? '',
          'workerName': data['workerName']?.toString() ?? 'Worker',
          'customerId': data['customerId']?.toString() ?? '',
          'customerName': data['customerName']?.toString() ?? 'Customer',
          'jobTitle': data['descriptionEn']?.toString() ??
              data['descriptionUr']?.toString() ??
              data['categoryKey']?.toString() ??
              'Service Job',
          'categoryKey': data['categoryKey']?.toString() ?? 'general',
          'totalPaid': totalPaid,
          'commissionRate': 0.02,
          'commissionAmount': commission,
          'paymentMethod': data['paymentMethod']?.toString() ?? 'Cash',
          'status': 'Deducted from Top-up Balance',
          'timestamp': data['completedAt'] ?? data['paidAt'] ?? data['createdAt'],
        };
      }
    }

    final list = map.values.toList();
    // Sort descending by timestamp
    list.sort((a, b) {
      final aTs = a['timestamp'] as Timestamp?;
      final bTs = b['timestamp'] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });

    return list;
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> list) {
    final now = DateTime.now();

    return list.where((item) {
      // 1. Payment Method Filter
      if (_paymentMethodFilter != 'All') {
        final method = item['paymentMethod']?.toString().toLowerCase() ?? '';
        if (_paymentMethodFilter.toLowerCase() != method) return false;
      }

      // 2. Period Filter
      if (_selectedPeriod != 'All Time') {
        final ts = item['timestamp'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          if (_selectedPeriod == 'This Month') {
            if (dt.month != now.month || dt.year != now.year) return false;
          } else if (_selectedPeriod == 'This Week') {
            final diff = now.difference(dt).inDays;
            if (diff > 7) return false;
          }
        }
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final wName = (item['workerName']?.toString() ?? '').toLowerCase();
        final cName = (item['customerName']?.toString() ?? '').toLowerCase();
        final title = (item['jobTitle']?.toString() ?? '').toLowerCase();
        final cat = (item['categoryKey']?.toString() ?? '').toLowerCase();

        return wName.contains(_searchQuery) ||
            cName.contains(_searchQuery) ||
            title.contains(_searchQuery) ||
            cat.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Information Dialog
  // ─────────────────────────────────────────────────────────────
  void _showCommissionInfoDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_rounded, color: Color(0xFF006B5E)),
            const SizedBox(width: 8),
            Text(isUrdu ? 'کمیشن پالیسی' : 'Commission Policy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu
                  ? '• ہر کام کی ادائیگی پر گاہک کی طرف سے ادا کردہ رقم سے 2 فیصد کٹوتی کی جاتی ہے۔\n\n'
                    '• یہ 2 فیصد کٹوتی ورکر کے موجودہ ٹاپ اپ بیلنس (Top-up Balance) سے خودکار طور پر منہا ہوتی ہے۔\n\n'
                    '• اگر ورکر کا ٹاپ اپ بیلنس کم ہو تو وہ سیف پے یا فرنچائز سے بیلنس ریچارج کر سکتا ہے۔'
                  : '• Every completed job payment attracts a fixed 2% platform fee.\n\n'
                    '• This 2% is automatically deducted from the worker\'s active Top-up Balance.\n\n'
                    '• Workers must maintain sufficient top-up balance via Safepay or franchise deposits.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006B5E)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'ٹھیک ہے' : 'Understood'),
          ),
        ],
      ),
    );
  }
}
