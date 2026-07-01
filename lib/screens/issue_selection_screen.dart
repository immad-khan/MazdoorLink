import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart';
import 'recommendation_arguments.dart';

class JobPostingArguments {
  final String descriptionEn;
  final String descriptionUr;
  final double price;
  final String categoryKey;
  final String paymentMethod;
  final double? customerLatitude;
  final double? customerLongitude;

  JobPostingArguments({
    required this.descriptionEn,
    required this.descriptionUr,
    required this.price,
    required this.categoryKey,
    this.paymentMethod = 'Cash',
    this.customerLatitude,
    this.customerLongitude,
  });
}

class IssueItem {
  final String titleEn;
  final String titleUr;
  final double price;
  final IconData icon;

  const IssueItem({
    required this.titleEn,
    required this.titleUr,
    required this.price,
    required this.icon,
  });
}

class IssueSelectionScreen extends StatefulWidget {
  const IssueSelectionScreen({Key? key}) : super(key: key);

  @override
  State<IssueSelectionScreen> createState() => _IssueSelectionScreenState();
}

class _IssueSelectionScreenState extends State<IssueSelectionScreen> {
  final Set<int> _selectedIndices = <int>{};
  String _paymentMethod = 'Cash';
  String _categoryKey = 'electrician';
  bool _initialized = false;
  List<IssueItem> _customSkills = [];
  bool _loadingCustomSkills = true;
  final List<IssueItem> _electricalIssues = const [
    IssueItem(titleEn: 'Broken Switch', titleUr: 'خراب سوئچ', price: 300, icon: Icons.toggle_off),
    IssueItem(titleEn: 'Short Circuit', titleUr: 'شارٹ سرکٹ', price: 400, icon: Icons.flash_on),
    IssueItem(titleEn: 'Ceiling Fan Installation', titleUr: 'سیلنگ فین انسٹالیشن', price: 500, icon: Icons.ac_unit),
    IssueItem(titleEn: 'Full Home Wiring Repair', titleUr: 'مکمل گھر کی وائرنگ مرمت', price: 8000, icon: Icons.power),
    IssueItem(titleEn: 'AC Switch Installation', titleUr: 'اے سی سوئچ لگانا', price: 450, icon: Icons.electrical_services),
    IssueItem(titleEn: 'UPS Setup & Installation', titleUr: 'یو پی ایس سیٹ اپ', price: 1500, icon: Icons.battery_charging_full),
    IssueItem(titleEn: 'Generator Repair', titleUr: 'جنریٹر کی مرمت', price: 2000, icon: Icons.settings_input_component),
    IssueItem(titleEn: 'Bulb or Holder Replacement', titleUr: 'بلب یا ہولڈر تبدیل کرنا', price: 150, icon: Icons.lightbulb_outline),
  ];

  final List<IssueItem> _PlumberIssues = const [
    IssueItem(titleEn: 'Water Tap Leakage', titleUr: 'نلکے سے پانی کا رساو', price: 300, icon: Icons.water_drop),
    IssueItem(titleEn: 'Flush Tank Repair', titleUr: 'فلش ٹینک کی مرمت', price: 600, icon: Icons.wash),
    IssueItem(titleEn: 'Sink / Wash Basin Installation', titleUr: 'واش بیسن لگانا', price: 1200, icon: Icons.bathroom),
    IssueItem(titleEn: 'Motor Pump Installation', titleUr: 'پانی کی موٹر لگانا', price: 2500, icon: Icons.plumbing),
    IssueItem(titleEn: 'Geyser Repair & Service', titleUr: 'گیزر کی سروس اور مرمت', price: 1800, icon: Icons.heat_pump),
    IssueItem(titleEn: 'Pipeline Leakage Repair', titleUr: 'پائپ لائن لیکیج مرمت', price: 1000, icon: Icons.healing),
    IssueItem(titleEn: 'Shower Fitting Replacement', titleUr: 'شاور فٹنگ تبدیل کرنا', price: 700, icon: Icons.shower),
    IssueItem(titleEn: 'Drain Blockage Cleaning', titleUr: 'بند نالی کی صفائی', price: 800, icon: Icons.cleaning_services),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) _categoryKey = args;
      _initialized = true;
      _loadCustomSkills();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _categoryKeyToName(String key) {
    switch (key.toLowerCase()) {
      case 'electrician': return 'Electrician';
      case 'plumber': return 'Plumber';
      default: return key;
    }
  }

  Future<void> _loadCustomSkills() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('status', isEqualTo: 'approved')
          .where('categoryNameEn', isEqualTo: _categoryKeyToName(_categoryKey))
          .get();
      final predefinedTitles = _categoryKey == 'electrician'
          ? _electricalIssues.map((e) => e.titleEn).toSet()
          : _PlumberIssues.map((e) => e.titleEn).toSet();
      final seen = <String>{};
      final skills = <IssueItem>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final skillsData = data['skills'] as List<dynamic>? ?? [];
        for (final s in skillsData) {
          final map = s as Map<String, dynamic>;
          final title = map['titleEn']?.toString() ?? '';
          if (title.isNotEmpty && !predefinedTitles.contains(title) && seen.add(title)) {
            skills.add(IssueItem(
              titleEn: title,
              titleUr: map['titleUr']?.toString() ?? title,
              price: (map['price'] as num?)?.toDouble() ?? 0,
              icon: Icons.handyman,
            ));
          }
        }
      }
      if (mounted) setState(() { _customSkills = skills; _loadingCustomSkills = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCustomSkills = false);
    }
  }

  void _showPaymentOptions(bool isUrdu) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrdu ? 'ادائیگی کا طریقہ منتخب کریں' : 'Select Payment Method',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontName),
                ),
                const SizedBox(height: 16),
                _buildPaymentTile('Cash', Icons.money, isUrdu),
                _buildPaymentTile('Easypaisa', Icons.phone_android, isUrdu),
                _buildPaymentTile('JazzCash', Icons.account_balance_wallet, isUrdu),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentTile(String method, IconData icon, bool isUrdu) {
    final title = method == 'Cash' ? (isUrdu ? 'کیش' : 'Cash') : method;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0D9488)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: AppTheme.fontName)),
      trailing: _paymentMethod == method ? const Icon(Icons.check_circle, color: Color(0xFF0D9488)) : null,
      onTap: () {
        setState(() => _paymentMethod = method);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildPaymentSelectorButton(bool isUrdu) {
    IconData icon = Icons.money;
    if (_paymentMethod == 'Easypaisa') icon = Icons.phone_android;
    if (_paymentMethod == 'JazzCash') icon = Icons.account_balance_wallet;

    return InkWell(
      onTap: () => _showPaymentOptions(isUrdu),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        width: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF0D9488), size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isUrdu = controller.isUrdu;

    final issuesList = _categoryKey == 'electrician' ? _electricalIssues : _PlumberIssues;
    
    final titleEn = _categoryKey == 'electrician' ? 'Select Electrician Issue' : 'Select Plumber Issue';
    final titleUr = _categoryKey == 'electrician' ? 'الیکٹریکل مسئلہ منتخب کریں' : 'پلمبنگ مسئلہ منتخب کریں';

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(isUrdu ? titleUr : titleEn),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(isUrdu ? Icons.arrow_forward : Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  isUrdu 
                      ? 'ملازمت پوسٹ کرنے کے لیے ایک عام مسئلہ منتخب کریں۔' 
                      : 'Choose a common issue to post your job.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: AppTheme.fontName,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Issues Grid/List
                for (int index = 0; index < issuesList.length; index++) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 200 + index * 50),
                    builder: (context, value, child) => Transform.scale(
                      scale: 0.95 + value * 0.05,
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                      ),
                      elevation: 1,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedIndices.contains(index),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            },
                          ),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF0D9488).withValues(alpha:0.08),
                            child: Icon(issuesList[index].icon, color: const Color(0xFF0D9488)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUrdu ? issuesList[index].titleUr : issuesList[index].titleEn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkerText,
                                    fontFamily: AppTheme.fontName,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Continue Button for Multiple Selection
                if (_selectedIndices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        _buildPaymentSelectorButton(isUrdu),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final selectedIssues = _selectedIndices.map((i) => issuesList[i]).toList();
                              Navigator.pushNamed(
                                context,
                                AppRoutes.confirmLocation,
                                arguments: RecommendationArguments(selectedIssues: selectedIssues, categoryKey: _categoryKey, paymentMethod: _paymentMethod),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0D72F),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              isUrdu ? 'منتخب کریں اور ورکر تلاش کریں' : 'Find Workers', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: AppTheme.fontName)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Custom Skills from Workers
                if (_loadingCustomSkills)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loadingCustomSkills && _customSkills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    isUrdu ? 'ورکرز کی طرف سے شامل کردہ خدمات' : 'Services added by workers',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 10),
                  for (int index = 0; index < _customSkills.length; index++) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                      ),
                      elevation: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFF59E0B).withValues(alpha:0.08),
                              child: const Icon(Icons.handyman, color: Color(0xFFF59E0B), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isUrdu ? _customSkills[index].titleUr : _customSkills[index].titleEn,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.darkerText),
                              ),
                            ),
                            Text(
                              'Rs. ${_customSkills[index].price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
