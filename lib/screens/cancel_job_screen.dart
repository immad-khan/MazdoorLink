import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';

/// Call this from ServiceTrackingScreen instead of directly navigating.
/// Replace the Cancel Job button's onPressed with:
///
///   onPressed: () => Navigator.push(
///     context,
///     MaterialPageRoute(builder: (_) => const CancelJobScreen()),
///   ),

String _bilingual(BuildContext context, String en, String ur) {
  // Reuse your existing bilingual() helper if accessible,
  // otherwise this local fallback reads the locale directly.
  final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
  return isUrdu ? ur : en;
}

class CancelJobScreen extends StatefulWidget {
  const CancelJobScreen({super.key});

  @override
  State<CancelJobScreen> createState() => _CancelJobScreenState();
}

class _CancelJobScreenState extends State<CancelJobScreen>
    with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  String? _selectedCategory;
  String? _selectedReason;
  final TextEditingController _customMessage = TextEditingController();
  bool _submitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Data ─────────────────────────────────────────────────────────────────
  /// Top-level categories shown in the first dropdown.
  static const Map<String, String> _categories = {
    'worker_issue':     'Worker Issue',
    'schedule_change':  'Schedule Change',
    'price_issue':      'Price / Payment Issue',
    'personal_reason':  'Personal Reason',
    'other':            'Other',
  };

  static const Map<String, String> _categoriesUr = {
    'worker_issue':     'ورکر کا مسئلہ',
    'schedule_change':  'شیڈول تبدیلی',
    'price_issue':      'قیمت / ادائیگی کا مسئلہ',
    'personal_reason':  'ذاتی وجہ',
    'other':            'دیگر',
  };

  /// Specific reasons per category.
  static const Map<String, List<String>> _reasons = {
    'worker_issue': [
      'Worker is not responding',
      'Worker behaviour was rude',
      'Wrong worker was assigned',
      'Worker arrived very late',
    ],
    'schedule_change': [
      'I need to reschedule',
      'Emergency at home',
      'Work conflict',
      'Forgot about another appointment',
    ],
    'price_issue': [
      'Price is too high',
      'Found a cheaper option',
      'Budget constraints',
      'Unexpected price change',
    ],
    'personal_reason': [
      'Issue resolved on its own',
      'Family emergency',
      'No longer need the service',
      'Changed my mind',
    ],
    'other': [
      'Duplicate booking',
      'App error / technical issue',
      'I will explain in message below',
    ],
  };

  static const Map<String, List<String>> _reasonsUr = {
    'worker_issue': [
      'ورکر جواب نہیں دے رہا',
      'ورکر کا رویہ غیر مناسب تھا',
      'غلط ورکر تفویض ہوا',
      'ورکر بہت دیر سے پہنچا',
    ],
    'schedule_change': [
      'مجھے شیڈول تبدیل کرنا ہے',
      'گھر میں ہنگامی صورتحال',
      'کام کا تنازع',
      'دوسری ملاقات بھول گیا',
    ],
    'price_issue': [
      'قیمت بہت زیادہ ہے',
      'سستا آپشن مل گیا',
      'بجٹ کی رکاوٹ',
      'غیر متوقع قیمت تبدیلی',
    ],
    'personal_reason': [
      'مسئلہ خود بخود حل ہو گیا',
      'خاندانی ہنگامی صورتحال',
      'سروس کی اب ضرورت نہیں',
      'ذہن بدل گیا',
    ],
    'other': [
      'ڈپلیکیٹ بکنگ',
      'ایپ کی خرابی',
      'میں نیچے پیغام میں بتاؤں گا',
    ],
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 80), _fadeController.forward);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _customMessage.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get _canSubmit =>
      _selectedCategory != null &&
      _selectedReason != null &&
      !_submitting;

  List<String> get _currentReasons {
    if (_selectedCategory == null) return [];
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    return isUrdu
        ? (_reasonsUr[_selectedCategory!] ?? [])
        : (_reasons[_selectedCategory!] ?? []);
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _selectedCategory = value;
      _selectedReason = null; // reset sub-reason when category changes
    });
  }

  Future<void> _submitCancellation() async {
    setState(() => _submitting = true);

    // TODO: wire up to your real backend / API call here.
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(_bilingual(context,
                'Job cancelled successfully.', 'کام کامیابی سے منسوخ ہو گیا۔')),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Pop back to customer home (adjust route name to match your AppRoutes).
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/customer/home',
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFDC2626),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          _bilingual(context, 'Cancel Job', 'کام منسوخ کریں'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Warning banner ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bilingual(context,
                                'Are you sure?', 'کیا آپ واقعی منسوخ کرنا چاہتے ہیں؟'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bilingual(
                              context,
                              'Cancelling may affect your booking record.',
                              'منسوخی آپ کی بکنگ ریکارڈ پر اثر ڈال سکتی ہے۔',
                            ),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section label ────────────────────────────────────────────
              Text(
                _bilingual(context,
                    'Tell us why you\'re cancelling',
                    'ہمیں بتائیں آپ کیوں منسوخ کر رہے ہیں'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              const SizedBox(height: 16),

              // ── Category dropdown ────────────────────────────────────────
              _SectionLabel(
                label: _bilingual(
                    context, 'Cancellation Category', 'منسوخی کی قسم'),
                required: true,
              ),
              const SizedBox(height: 8),
              _StyledDropdown<String>(
                value: _selectedCategory,
                hint: _bilingual(context,
                    'Select a category', 'قسم منتخب کریں'),
                icon: Icons.category_outlined,
                items: _categories.entries.map((e) {
                  final label = isUrdu
                      ? (_categoriesUr[e.key] ?? e.value)
                      : e.value;
                  return DropdownMenuItem(value: e.key, child: Text(label));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 20),

              // ── Reason dropdown (animated in) ────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _selectedCategory == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                            label: _bilingual(context,
                                'Specific Reason', 'مخصوص وجہ'),
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          _StyledDropdown<String>(
                            value: _selectedReason,
                            hint: _bilingual(context,
                                'Select a reason', 'وجہ منتخب کریں'),
                            icon: Icons.help_outline,
                            items: _currentReasons
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedReason = v),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),

              // ── Custom message ───────────────────────────────────────────
              _SectionLabel(
                label: _bilingual(context,
                    'Additional Details (Optional)',
                    'اضافی تفصیل (اختیاری)'),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.spacer),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _customMessage,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: _bilingual(
                      context,
                      'Describe your reason in detail…',
                      'اپنی وجہ تفصیل سے بیان کریں…',
                    ),
                    hintStyle: const TextStyle(
                        color: AppTheme.deactivatedText, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(
                        fontSize: 11, color: AppTheme.lightText),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submitCancellation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    disabledBackgroundColor:
                        const Color(0xFFDC2626).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _bilingual(
                              context, 'Confirm Cancellation', 'منسوخی کی تصدیق کریں'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Keep job button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _bilingual(context, 'Keep the Job', 'کام جاری رکھیں'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkerText,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 14)),
        ],
      ],
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? const Color(0xFF0D9488).withOpacity(0.6)
              : AppTheme.spacer,
          width: value != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppTheme.lightText),
          hint: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.deactivatedText),
              const SizedBox(width: 10),
              Text(hint,
                  style: const TextStyle(
                      color: AppTheme.deactivatedText, fontSize: 14)),
            ],
          ),
          items: items,
          onChanged: onChanged,
          selectedItemBuilder: (context) => items.map((item) {
            return Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0D9488)),
                const SizedBox(width: 10),
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppTheme.darkerText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: item.child,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
