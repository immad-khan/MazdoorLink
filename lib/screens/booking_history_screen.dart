import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/icon_helper.dart';

class BookingItem {
  final String title;
  final String category;
  final String status;
  final String date;
  final double amount;
  final bool isCompleted;

  BookingItem({
    required this.title,
    required this.category,
    required this.status,
    required this.date,
    required this.amount,
    required this.isCompleted,
  });
}

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

  final List<BookingItem> _allBookings = [
    BookingItem(
      title: 'Plumbing repair - Pipe leak fix',
      category: 'Plumbing',
      status: 'Completed',
      date: '2 days ago',
      amount: 2500,
      isCompleted: true,
    ),
    BookingItem(
      title: 'Electrical rewiring - 3 rooms',
      category: 'Electrical',
      status: 'In Progress',
      date: 'Today',
      amount: 5000,
      isCompleted: false,
    ),
    BookingItem(
      title: 'Carpentry shelf installation',
      category: 'Carpentry',
      status: 'Completed',
      date: '1 week ago',
      amount: 3200,
      isCompleted: true,
    ),
    BookingItem(
      title: 'AC cleaning and maintenance',
      category: 'AC Repair',
      status: 'Pending',
      date: 'Tomorrow',
      amount: 1500,
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _slideController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);
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

  List<BookingItem> get _filteredBookings {
    var filtered = _selectedTab == 0
        ? _allBookings.where((b) => !b.isCompleted).toList()
        : _allBookings.where((b) => b.isCompleted).toList();

    final query = _searchController.text.toLowerCase();
    return filtered
        .where((item) =>
            item.title.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query))
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Color(0xFF059669);
      case 'In Progress':
        return Color(0xFFF59E0B);
      case 'Pending':
        return Color(0xFF3B82F6);
      default:
        return AppTheme.lightText;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Plumbing':
        return IconHelper.plumbing;
      case 'Electrical':
        return IconHelper.electrical;
      case 'Carpentry':
        return IconHelper.carpentry;
      case 'AC Repair':
        return IconHelper.ac;
      default:
        return Icons.work;
    }
  }

  Widget _buildBookingCard(BookingItem booking) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.spacer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              if (!booking.isCompleted) {
                Navigator.pushNamed(context, '/customer/tracking');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job Details opened')),
                );
              }
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
                        child: Icon(_getCategoryIcon(booking.category),
                            color: Theme.of(context).primaryColor, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkerText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              booking.date,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.deactivatedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(booking.status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          booking.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(booking.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: AppTheme.notWhite, height: 0),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Text(
                        'Rs ${booking.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkerText,
                        ),
                      ),
                    ],
                  ),
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('booking_history'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: Icon(IconHelper.search, color: AppTheme.deactivatedText, size: 20),
                  hintText: t.t('search_booking_history'),
                  hintStyle: TextStyle(color: AppTheme.deactivatedText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.spacer),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.spacer),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 20),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.notWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.spacer),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                            border: _selectedTab == 0
                                ? Border.all(color: AppTheme.spacer)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 0
                                    ? Theme.of(context).primaryColor
                                    : AppTheme.lightText,
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
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                            border: _selectedTab == 1
                                ? Border.all(color: AppTheme.spacer)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 1
                                    ? Theme.of(context).primaryColor
                                    : AppTheme.lightText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Bookings List
              if (_filteredBookings.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: AppTheme.deactivatedText),
                        SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _selectedTab == 0
                              ? 'You have no active bookings'
                              : 'No completed bookings yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.deactivatedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
                          .animate(
                        CurvedAnimation(
                          parent: _slideController,
                          curve: Interval(
                            index * 0.1,
                            0.7 + (index * 0.1),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: _buildBookingCard(_filteredBookings[index]),
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
