import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_frontend/app_theme.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart';

class BookingHistoryScreen extends StatefulWidget {
  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  String _searchQuery = '';

  static const List<String> _activeStatuses = [
    'pending', 'accepted', 'arrival_pending', 'working',
    'worker_completed', 'payment_pending', 'worker_payment_pending',
    'payment_disputed', 'scheduled',
  ];

  static const List<String> _completedStatuses = [
    'completed', 'rejected', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _slideController = AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Color(0xFF059669);
      case 'working':
      case 'arrival_pending':
      case 'accepted': return Color(0xFFF59E0B);
      case 'pending':
      case 'scheduled': return Color(0xFF3B82F6);
      case 'rejected':
      case 'cancelled': return Color(0xFFEF4444);
      default: return AppTheme.lightText;
    }
  }

  String _getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'working': return 'In Progress';
      case 'arrival_pending': return 'Arrival Pending';
      case 'accepted': return 'Accepted';
      case 'pending': return 'Pending';
      case 'scheduled': return 'Scheduled';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      case 'worker_completed': return 'Work Done';
      case 'payment_pending':
      case 'worker_payment_pending': return 'Payment Pending';
      case 'payment_disputed': return 'Disputed';
      default: return status;
    }
  }

  IconData _getCategoryIcon(String? categoryKey) {
    if (categoryKey == null) return Icons.work;
    switch (categoryKey.toLowerCase()) {
      case 'plumber': return IconHelper.Plumber;
      case 'electrician': return IconHelper.electrician;
      case 'carpenter':
      case 'carpentry': return IconHelper.carpentry;
      case 'ac_mechanic':
      case 'ac': return IconHelper.ac;
      default: return Icons.work;
    }
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
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes} min ago';
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(dt);
    }
  }

  Widget _buildBookingCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['descriptionEn']?.toString() ?? 'Service';
    final categoryKey = data['categoryKey']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final amount = (data['price'] as num?)?.toDouble() ?? 0;
    final createdAt = data['createdAt'];
    final jobId = doc.id;
    final isUrdu = AppScope.of(context).isUrdu;
    final displayStatus = _getDisplayStatus(status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.spacer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Job ID: $jobId')),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.notWhite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getCategoryIcon(categoryKey),
                            color: Theme.of(context).primaryColor, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkerText)),
                            SizedBox(height: 4),
                            Text(_formatDate(createdAt),
                              style: TextStyle(fontSize: 12, color: AppTheme.deactivatedText)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
                        ),
                        child: Text(displayStatus,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(status))),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppTheme.notWhite, height: 0),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isUrdu ? 'رقم' : 'Amount', style: TextStyle(fontSize: 12, color: AppTheme.lightText)),
                      Text('Rs ${amount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkerText)),
                    ],
                  ),
                  if (status == 'completed') ...[
                    SizedBox(height: 10),
                    if (data['reviewed'] == true || data['customerRating'] != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${isUrdu ? 'درجہ بندی' : 'Rated'}: ${(data['customerRating'] as num?)?.toStringAsFixed(1) ?? '5.0'} / 5.0',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                            if (data['customerReview'] != null && data['customerReview'].toString().trim().isNotEmpty) ...[
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"${data['customerReview']}"',
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF78350F)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          label: Text(isUrdu ? 'ورکر کی درجہ بندی کریں' : 'Rate Worker'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Color(0xFF0D9488),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.rating,
                              arguments: TrackingArguments(jobId: jobId),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isUrdu = AppScope.of(context).isUrdu;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(t.t('booking_history'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24)),
          ),
        ),
      ),
      body: user == null
        ? Center(child: Text(isUrdu ? 'براہ کرم لاگ ان کریں' : 'Please log in'))
        : SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    prefixIcon: Icon(IconHelper.search, color: AppTheme.deactivatedText, size: 20),
                    hintText: t.t('search_booking_history'),
                    hintStyle: TextStyle(color: AppTheme.deactivatedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.spacer)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.spacer)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: AppTheme.notWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.spacer)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
                              border: _selectedTab == 0 ? Border.all(color: AppTheme.spacer) : null,
                            ),
                            child: Center(child: Text(isUrdu ? 'فعال' : 'Active',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: _selectedTab == 0 ? Theme.of(context).primaryColor : AppTheme.lightText))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11)),
                              border: _selectedTab == 1 ? Border.all(color: AppTheme.spacer) : null,
                            ),
                            child: Center(child: Text(isUrdu ? 'مکمل' : 'Completed',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: _selectedTab == 1 ? Theme.of(context).primaryColor : AppTheme.lightText))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('workerId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(isUrdu ? 'لوڈ کرنے میں خرابی' : 'Error loading jobs', style: TextStyle(color: Colors.red))));
                    }
                    final allDocs = snapshot.data?.docs ?? [];
                    final filteredByStatus = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status']?.toString() ?? '').toLowerCase();
                      if (_selectedTab == 0) return _activeStatuses.contains(status);
                      return _completedStatuses.contains(status);
                    }).toList();
                    final filteredDocs = _searchQuery.isEmpty ? filteredByStatus : filteredByStatus.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['descriptionEn']?.toString() ?? '').toLowerCase();
                      final category = (data['categoryKey']?.toString() ?? '').toLowerCase();
                      return title.contains(_searchQuery.toLowerCase()) || category.contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.deactivatedText),
                            SizedBox(height: 16),
                            Text(isUrdu ? 'کوئی کام نہیں ملا' : 'No jobs found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.lightText)),
                            SizedBox(height: 8),
                            Text(_selectedTab == 0
                                ? (isUrdu ? 'کوئی فعال کام نہیں' : 'You have no active jobs')
                                : (isUrdu ? 'کوئی مکمل کام نہیں' : 'No completed jobs yet'),
                              style: TextStyle(fontSize: 14, color: AppTheme.deactivatedText)),
                          ],
                        )),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        return SlideTransition(
                          position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(
                            CurvedAnimation(parent: _slideController,
                              curve: Interval((index * 0.1).clamp(0.0, 0.9), (0.7 + index * 0.1).clamp(0.0, 1.0), curve: Curves.easeOut)),
                          ),
                          child: _buildBookingCard(filteredDocs[index]),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}
