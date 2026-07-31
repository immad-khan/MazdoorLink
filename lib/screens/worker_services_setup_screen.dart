import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';
import 'signup_data.dart';

class ServiceItem {
  final String titleEn;
  final String titleUr;
  double price;
  bool isSelected;

  ServiceItem({
    required this.titleEn,
    required this.titleUr,
    required this.price,
    this.isSelected = false,
  });
}

class WorkerServicesSetupScreen extends StatefulWidget {
  const WorkerServicesSetupScreen({Key? key}) : super(key: key);

  @override
  State<WorkerServicesSetupScreen> createState() => _WorkerServicesSetupScreenState();
}

class _WorkerServicesSetupScreenState extends State<WorkerServicesSetupScreen> with SingleTickerProviderStateMixin {
  final _customTitleController = TextEditingController();
  final _customPriceController = TextEditingController();
  bool _showCustomFields = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Cache controllers for editable prices
  final Map<int, TextEditingController> _priceControllers = {};

  final List<String> _skillNamesEn = const [
    'Plumber',
    'Electrician',
  ];

  final List<String> _skillNamesUr = const [
    'پلمبر',
    'الیکٹریشن',
  ];

  final Map<int, List<ServiceItem>> _servicesMap = {
    // Plumber
    0: [
      ServiceItem(titleEn: 'Water Tap Leakage Fix', titleUr: 'نلکے سے پانی کا رساو ٹھیک کرنا', price: 300, isSelected: true),
      ServiceItem(titleEn: 'Flush Tank Repair', titleUr: 'فلش ٹینک کی مرمت', price: 600, isSelected: true),
      ServiceItem(titleEn: 'Sink / Wash Basin Installation', titleUr: 'واش بیسن لگانا', price: 1200),
      ServiceItem(titleEn: 'Motor Pump Installation', titleUr: 'پانی کی موٹر لگانا', price: 2500),
      ServiceItem(titleEn: 'Geyser Repair & Service', titleUr: 'گیزر کی سروس اور مرمت', price: 1800),
      ServiceItem(titleEn: 'Pipeline Leakage Repair', titleUr: 'پائپ لائن لیکیج مرمت', price: 1000),
      ServiceItem(titleEn: 'Shower Fitting Replacement', titleUr: 'شاور فٹنگ تبدیل کرنا', price: 700),
      ServiceItem(titleEn: 'Drain Blockage Cleaning', titleUr: 'بند نالی کی صفائی', price: 800),
      ServiceItem(titleEn: 'Full Washroom Setup', titleUr: 'واش روم کا مکمل سیٹ اپ', price: 12000),
    ],
    // Electrician
    1: [
      ServiceItem(titleEn: 'Broken Switch Repair', titleUr: 'خراب سوئچ کی مرمت', price: 300, isSelected: true),
      ServiceItem(titleEn: 'Short Circuit Fix', titleUr: 'شارٹ سرکٹ ٹھیک کرنا', price: 400, isSelected: true),
      ServiceItem(titleEn: 'Ceiling Fan Installation', titleUr: 'سیلنگ فین انسٹالیشن', price: 500),
      ServiceItem(titleEn: 'Full Home Wiring Repair', titleUr: 'مکمل گھر کی وائرنگ مرمت', price: 8000),
      ServiceItem(titleEn: 'AC Switch Installation', titleUr: 'اے سی سوئچ لگانا', price: 450),
      ServiceItem(titleEn: 'UPS Setup & Installation', titleUr: 'یو پی ایس سیٹ اپ', price: 1500),
      ServiceItem(titleEn: 'Generator Repair', titleUr: 'جنریٹر کی مرمت', price: 2000),
      ServiceItem(titleEn: 'Bulb or Holder Replacement', titleUr: 'بلب یا ہولڈر تبدیل کرنا', price: 150),
    ],
  };

  List<ServiceItem> _currentServices = [];
  int _categoryIndex = 0;
  bool _loadedFromFirestore = false;
  WorkerSignupData? _signupData;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _categoryIndex = args;
    } else if (args is ServicesSetupArguments) {
      _categoryIndex = args.categoryIndex;
      _signupData = args.signupData;
    } else if (args is String) {
      int foundIndex = _skillNamesEn.indexWhere((element) => element.toLowerCase() == args.toLowerCase());
      if (foundIndex != -1) {
        _categoryIndex = foundIndex;
      }
    }

    if (_currentServices.isEmpty) {
      _loadFromFirestoreOrInit();
    }
  }

  Future<void> _loadFromFirestoreOrInit() async {
    if (_signupData != null) {
      // Signup mode - init with defaults, no Firestore to load from yet
      if (mounted) {
        setState(() {
          final list = _servicesMap[_categoryIndex] ?? [];
          _currentServices = list.map((item) => ServiceItem(
            titleEn: item.titleEn,
            titleUr: item.titleUr,
            price: item.price,
            isSelected: item.isSelected,
          )).toList();
          for (int i = 0; i < _currentServices.length; i++) {
            _priceControllers[i] = TextEditingController(text: _currentServices[i].price.toStringAsFixed(0));
          }
          _loadedFromFirestore = true;
        });
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          final savedSkills = data['skills'] as List<dynamic>?;
          if (savedSkills != null && savedSkills.isNotEmpty) {
            final saved = savedSkills.map((s) {
              final m = s as Map<String, dynamic>;
              return ServiceItem(
                titleEn: m['titleEn']?.toString() ?? '',
                titleUr: m['titleUr']?.toString() ?? '',
                price: (m['price'] as num?)?.toDouble() ?? 0,
                isSelected: true,
              );
            }).toList();

            final defaults = _servicesMap[_categoryIndex] ?? [];
            final merged = defaults.map((d) {
              final existing = saved.where((s) => s.titleEn == d.titleEn).firstOrNull;
              return ServiceItem(
                titleEn: d.titleEn,
                titleUr: d.titleUr,
                price: existing?.price ?? d.price,
                isSelected: existing != null || d.isSelected,
              );
            }).toList();

            final custom = saved.where((s) => !defaults.any((d) => d.titleEn == s.titleEn)).toList();

            if (mounted) {
              setState(() {
                _currentServices = [...merged, ...custom];
                for (int i = 0; i < _currentServices.length; i++) {
                  _priceControllers[i] = TextEditingController(text: _currentServices[i].price.toStringAsFixed(0));
                }
                _loadedFromFirestore = true;
              });
            }
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        final list = _servicesMap[_categoryIndex] ?? [];
        _currentServices = list.map((item) => ServiceItem(
          titleEn: item.titleEn,
          titleUr: item.titleUr,
          price: item.price,
          isSelected: item.isSelected,
        )).toList();
        for (int i = 0; i < _currentServices.length; i++) {
          _priceControllers[i] = TextEditingController(text: _currentServices[i].price.toStringAsFixed(0));
        }
        _loadedFromFirestore = true;
      });
    }
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _customPriceController.dispose();
    _animationController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addCustomService(bool isUrdu) {
    final title = _customTitleController.text.trim();
    final priceText = _customPriceController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'براہ کرم سروس کا نام درج کریں' : 'Please enter service name'),
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

    setState(() {
      final newItem = ServiceItem(
        titleEn: title,
        titleUr: title,
        price: price,
        isSelected: true,
      );
      _currentServices.add(newItem);
      final newIndex = _currentServices.length - 1;
      _priceControllers[newIndex] = TextEditingController(text: price.toStringAsFixed(0));

      // Reset custom inputs
      _customTitleController.clear();
      _customPriceController.clear();
      _showCustomFields = false;
      _animationController.reverse();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(isUrdu ? 'نئی سروس کامیابی سے شامل کر دی گئی' : 'New service added successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  Future<void> _completeSetup(bool isUrdu) async {
    // Check if at least one service is selected
    final selectedCount = _currentServices.where((element) => element.isSelected).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'براہ کرم کم از کم ایک سروس منتخب کریں' : 'Please select at least one service'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Save edited prices back to models
    for (int i = 0; i < _currentServices.length; i++) {
      if (_currentServices[i].isSelected) {
        final text = _priceControllers[i]?.text.trim() ?? '';
        final parsedPrice = double.tryParse(text);
        if (parsedPrice != null && parsedPrice > 0) {
          _currentServices[i].price = parsedPrice;
        }
      }
    }

    // Save skills/services to Firestore
    try {
      final selectedServices = _currentServices
          .where((s) => s.isSelected)
          .map((s) => {
                'titleEn': s.titleEn,
                'titleUr': s.titleUr,
                'price': s.price,
              })
          .toList();

      if (_signupData != null) {
        // Signup mode - create user and save everything
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _signupData!.email,
          password: _signupData!.password,
        );
        await userCredential.user?.sendEmailVerification();

        final categoryKey = _categoryIndex == 0 ? 'plumber' : 'electrician';
        final userData = <String, dynamic>{
          'name': _signupData!.name,
          'email': _signupData!.email,
          'phone': _signupData!.phone,
          'role': 'worker',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'idFrontUrl': _signupData!.idFrontUrl,
          'idBackUrl': _signupData!.idBackUrl,
          'category': categoryKey,
          'skills': selectedServices,
          'categoryNameEn': _skillNamesEn[_categoryIndex],
          'categoryNameUr': _skillNamesUr[_categoryIndex],
          'setupComplete': true,
        };
        if (_signupData!.cnicNumber != null && _signupData!.cnicNumber!.isNotEmpty) {
          userData['cnicNumber'] = _signupData!.cnicNumber;
        }
        if (_signupData!.profilePicUrl != null) {
          userData['profilePicUrl'] = _signupData!.profilePicUrl;
        }
        if (_signupData!.certificationUrl != null) {
          userData['certificationUrl'] = _signupData!.certificationUrl;
        }

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
        await FirebaseAuth.instance.signOut();

        // Show signup success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDCFCE7),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF059669), size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text('Registration Submitted!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    const Text(
                      'A verification email has been sent.\n\nYour profile is under admin review. You can log in once your account is approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Go to Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      // Existing mode - update current user document
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'skills': selectedServices,
          'categoryNameEn': _skillNamesEn[_categoryIndex],
          'categoryNameUr': _skillNamesUr[_categoryIndex],
          'setupComplete': true,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUrdu ? 'محفوظ کرنے میں خرابی: $e' : 'Error saving: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Display success modal (existing mode)
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha:0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isUrdu ? 'محفوظ ہو گیا!' : 'Saved!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isUrdu
                    ? 'آپ کی سروسز اور ریٹس کامیابی سے محفوظ کر دیے گئے ہیں۔'
                    : 'Your services and rates have been saved successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Pop dialog
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isUrdu ? 'محفوظ کریں' : 'Save & Go Back',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isUrdu = controller.isUrdu;

    final categoryNameEn = _skillNamesEn[_categoryIndex];
    final categoryNameUr = _skillNamesUr[_categoryIndex];

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(isUrdu ? 'خدمات اور قیمت کا سیٹ اپ' : 'Services & Rates Setup'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(isUrdu ? Icons.arrow_forward : Icons.arrow_back),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                controller.toggleLanguage();
                setState(() {});
              },
              icon: const Icon(Icons.translate, size: 18),
              label: Text(controller.isUrdu ? 'EN' : 'اردو', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // Top Info Header Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha:0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.engineering, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'آپ کا پیشہ' : 'Your Profession',
                                style: TextStyle(color: Colors.white.withValues(alpha:0.75), fontSize: 12),
                              ),
                              Text(
                                isUrdu ? categoryNameUr : categoryNameEn,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isUrdu
                            ? 'اپنی پیش کردہ سروسز کو نشان زد کریں اور اپنی قیمت درج کریں۔ کسٹمرز کو یہ ریٹس براہ راست نظر آئیں گے۔'
                            : 'Check the services you perform and define your custom rates. Customers will see these rates directly.',
                        style: TextStyle(color: Colors.white.withValues(alpha:0.9), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                // Services List View
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (int index = 0; index < _currentServices.length; index++) ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _currentServices[index].isSelected
                                  ? const Color(0xFF0D9488)
                                  : const Color(0xFFE5E7EB),
                              width: _currentServices[index].isSelected ? 1.8 : 1,
                            ),
                          ),
                          elevation: _currentServices[index].isSelected ? 1.5 : 0.5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // Checkbox to select service
                                Checkbox(
                                  activeColor: const Color(0xFF0D9488),
                                  value: _currentServices[index].isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      _currentServices[index].isSelected = val ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUrdu ? _currentServices[index].titleUr : _currentServices[index].titleEn,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: _currentServices[index].isSelected
                                              ? AppTheme.darkerText
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Editable Price Field
                                Container(
                                  width: 100,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _currentServices[index].isSelected
                                        ? const Color(0xFFF0FDFA)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _currentServices[index].isSelected
                                          ? const Color(0xFF99F6E4)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          isUrdu ? 'روپے' : 'Rs.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _currentServices[index].isSelected
                                                ? const Color(0xFF0F766E)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _priceControllers[index],
                                          enabled: _currentServices[index].isSelected,
                                          keyboardType: TextInputType.number,
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _currentServices[index].isSelected
                                                ? const Color(0xFF0F766E)
                                                : Colors.grey.shade500,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(bottom: 12),
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
                      ],

                      // Add Custom Service Section
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _showCustomFields ? const Color(0xFF0D9488) : const Color(0xFFE5E7EB),
                            width: _showCustomFields ? 1.8 : 1,
                          ),
                        ),
                        elevation: 0.5,
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF0D9488).withValues(alpha:0.08),
                                      child: const Icon(Icons.add, color: Color(0xFF0D9488)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isUrdu ? 'دیگر سروس شامل کریں' : 'Add Custom Service',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.darkerText,
                                            ),
                                          ),
                                          Text(
                                            isUrdu ? 'اپنی مرضی کی خدمت اور ریٹ لکھیں' : 'Define your own task and price',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

                            SizeTransition(
                              sizeFactor: _expandAnimation,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 16),
                                    Text(
                                      isUrdu ? 'سروس کا نام کیا ہے؟' : 'Describe the service:',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _customTitleController,
                                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                      decoration: InputDecoration(
                                        hintText: isUrdu ? 'مثلاً کچن پائپ کی صفائی' : 'E.g., Kitchen pipe cleaning',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isUrdu ? 'آپ کی قیمت (روپے میں):' : 'Proposed Price (Rs.):',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _customPriceController,
                                      keyboardType: TextInputType.number,
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        hintText: 'E.g., 600',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _addCustomService(isUrdu),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D9488),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          isUrdu ? 'سروس شامل کریں' : 'Add Service',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                    ],
                  ),
                ),

                // Save Button Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      )
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _completeSetup(isUrdu),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        isUrdu ? 'مکمل کریں' : 'Complete Setup',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
