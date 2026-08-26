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
          ? _electricalIssues.map((e) => e.titleEn.toLowerCase()).toSet()
          : _PlumberIssues.map((e) => e.titleEn.toLowerCase()).toSet();
      final seen = <String>{};
      final skills = <IssueItem>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final skillsData = data['skills'] as List<dynamic>? ?? [];
        for (final s in skillsData) {
          final map = s as Map<String, dynamic>;
          final title = map['titleEn']?.toString() ?? '';
          final titleLower = title.toLowerCase();
          // Skip if it matches a predefined issue (case-insensitive)
          if (title.isNotEmpty && !predefinedTitles.contains(titleLower) && seen.add(titleLower)) {
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

  Widget _buildIssueCard({
    required int index,
    required String titleEn,
    required String titleUr,
    required IconData icon,
    required bool isUrdu,
    required int totalIndex,
    bool isCustom = false,
  }) {
    final isSelected = _selectedIndices.contains(totalIndex);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + index * 50),
      builder: (context, value, child) => Transform.scale(
        scale: 0.95 + value * 0.05,
        child: Opacity(opacity: value, child: child),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (_selectedIndices.contains(totalIndex)) {
                _selectedIndices.remove(totalIndex);
              } else {
                _selectedIndices.add(totalIndex);
              }
            });
          },
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: const Color(0xFF0D9488),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedIndices.add(totalIndex);
                    } else {
                      _selectedIndices.remove(totalIndex);
                    }
                  });
                },
              ),
              CircleAvatar(
                backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.08),
                child: Icon(icon, color: const Color(0xFF0D9488)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isUrdu ? titleUr : titleEn,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.darkerText : Colors.black54,
                    fontFamily: AppTheme.fontName,
                  ),
                ),
              ),
              if (isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      isUrdu ? 'کسٹم' : 'Custom',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

    final hasSelection = _selectedIndices.isNotEmpty;

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
            child: Column(
              children: [
                // ── Scrollable issue list ──────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

                      // Predefined issues
                      for (int i = 0; i < issuesList.length; i++)
                        _buildIssueCard(
                          index: i,
                          titleEn: issuesList[i].titleEn,
                          titleUr: issuesList[i].titleUr,
                          icon: issuesList[i].icon,
                          isUrdu: isUrdu,
                          totalIndex: i,
                        ),

                      // Custom worker-added skills
                      if (_loadingCustomSkills)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_customSkills.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  isUrdu ? 'ورکرز کی اضافی خدمات' : 'Additional Worker Services',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                    fontFamily: AppTheme.fontName,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),
                        for (int i = 0; i < _customSkills.length; i++)
                          _buildIssueCard(
                            index: issuesList.length + i,
                            titleEn: _customSkills[i].titleEn,
                            titleUr: _customSkills[i].titleUr,
                            icon: Icons.handyman,
                            isUrdu: isUrdu,
                            totalIndex: issuesList.length + i,
                            isCustom: true,
                          ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // ── Fixed bottom: Payment + Find Workers ──────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        _buildPaymentSelectorButton(isUrdu),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: hasSelection
                                  ? () {
                                      final allIssues = [...issuesList, ..._customSkills];
                                      final selectedIssues = _selectedIndices.map((i) => allIssues[i]).toList();
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.confirmLocation,
                                        arguments: RecommendationArguments(
                                          selectedIssues: selectedIssues,
                                          categoryKey: _categoryKey,
                                          paymentMethod: _paymentMethod,
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasSelection ? const Color(0xFFC0D72F) : Colors.grey.shade200,
                                foregroundColor: hasSelection ? Colors.black87 : Colors.grey.shade400,
                                disabledBackgroundColor: Colors.grey.shade200,
                                disabledForegroundColor: Colors.grey.shade400,
                                elevation: hasSelection ? 2 : 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasSelection) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_selectedIndices.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    isUrdu ? 'ورکر تلاش کریں' : 'Find Workers',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: AppTheme.fontName,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
