import 'package:flutter/material.dart';
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

  JobPostingArguments({
    required this.descriptionEn,
    required this.descriptionUr,
    required this.price,
    required this.categoryKey,
    this.paymentMethod = 'Cash',
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

class _IssueSelectionScreenState extends State<IssueSelectionScreen> with SingleTickerProviderStateMixin {
  final _customDescController = TextEditingController();
  final _customPriceController = TextEditingController();
  final Set<int> _selectedIndices = <int>{};
  bool _showCustomFields = false;
  String _paymentMethod = 'Cash';
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _customDescController.dispose();
    _customPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitCustomIssue(String categoryKey, bool isUrdu) {
    final desc = _customDescController.text.trim();
    final priceText = _customPriceController.text.trim();

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'براہ کرم مسئلہ بیان کریں' : 'Please describe the issue'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'براہ کرم درست رقم درج کریں' : 'Please enter a valid amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/customer/job-posting',
      arguments: JobPostingArguments(
        descriptionEn: desc,
        descriptionUr: desc,
        price: price,
        categoryKey: categoryKey,
        paymentMethod: _paymentMethod,
      ),
    );
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
    final categoryKey = ModalRoute.of(context)?.settings.arguments as String? ?? 'electrician';
    final controller = AppScope.of(context);
    final isUrdu = controller.isUrdu;

    final issuesList = categoryKey == 'electrician' ? _electricalIssues : _PlumberIssues;
    
    final titleEn = categoryKey == 'electrician' ? 'Select Electrician Issue' : 'Select Plumber Issue';
    final titleUr = categoryKey == 'electrician' ? 'الیکٹریکل مسئلہ منتخب کریں' : 'پلمبنگ مسئلہ منتخب کریں';

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
                                AppRoutes.recommendations,
                                arguments: RecommendationArguments(selectedIssues: selectedIssues, categoryKey: categoryKey, paymentMethod: _paymentMethod),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0D72F), // Bright Indrive-like Green/Yellow
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

                // Others/Custom Issue Card
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _showCustomFields ? const Color(0xFF0D9488) : const Color(0xFFE5E7EB), 
                      width: _showCustomFields ? 2 : 1,
                    ),
                  ),
                  elevation: 1,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showCustomFields = !_showCustomFields;
                            if (_showCustomFields) {
                              _animationController.forward();
                            } else {
                              _animationController.reverse();
                            }
                          });
                        },
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(_showCustomFields ? 0 : 16),
                          bottomRight: Radius.circular(_showCustomFields ? 0 : 16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFF59E0B).withValues(alpha:0.08),
                                child: const Icon(Icons.add_circle_outline, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUrdu ? 'دیگر مسائل (اپنی مرضی کا کام)' : 'Others (Custom issue)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkerText,
                                        fontFamily: AppTheme.fontName,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isUrdu ? 'اپنا مسئلہ اور بجٹ خود درج کریں' : 'Define your own task and price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontFamily: AppTheme.fontName,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showCustomFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Animated Expansion for Custom Fields
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 16),
                              Text(
                                isUrdu ? 'مسئلہ کیا ہے؟' : 'Describe the issue:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                  fontFamily: AppTheme.fontName,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _customDescController,
                                minLines: 2,
                                maxLines: 3,
                                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: isUrdu 
                                      ? 'مثلاً نل کے نیچے سے پائپ تبدیل کرنا ہے' 
                                      : 'E.g., Need to change the pipe under the kitchen sink',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isUrdu ? 'تخمینہ بجٹ (روپے میں):' : 'Proposed Price (Rs.):',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                  fontFamily: AppTheme.fontName,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _customPriceController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  prefixIcon: Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: const Text('PKR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  hintText: 'E.g., 600',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  _buildPaymentSelectorButton(isUrdu),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _submitCustomIssue(categoryKey, isUrdu),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC0D72F), // Bright Indrive-like Green/Yellow
                                        foregroundColor: Colors.black87,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        isUrdu ? 'بجٹ کے ساتھ ورکر تلاش کریں' : 'Find Workers',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontName,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
