import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';
import '../services/skill_deduplicator.dart';
import '../services/location_service.dart';
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
    'Ù¾Ù„Ù…Ø¨Ø±',
    'Ø§Ù„ÛŒÚ©Ù¹Ø±ÛŒØ´Ù†',
  ];

  final Map<int, List<ServiceItem>> _servicesMap = {
    // Plumber
    0: [
      ServiceItem(titleEn: 'Water Tap Leakage Fix', titleUr: 'Ù†Ù„Ú©Û’ Ø³Û’ Ù¾Ø§Ù†ÛŒ Ú©Ø§ Ø±Ø³Ø§Ùˆ Ù¹Ú¾ÛŒÚ© Ú©Ø±Ù†Ø§', price: 300, isSelected: true),
      ServiceItem(titleEn: 'Flush Tank Repair', titleUr: 'ÙÙ„Ø´ Ù¹ÛŒÙ†Ú© Ú©ÛŒ Ù…Ø±Ù…Øª', price: 600, isSelected: true),
      ServiceItem(titleEn: 'Sink / Wash Basin Installation', titleUr: 'ÙˆØ§Ø´ Ø¨ÛŒØ³Ù† Ù„Ú¯Ø§Ù†Ø§', price: 1200),
      ServiceItem(titleEn: 'Motor Pump Installation', titleUr: 'Ù¾Ø§Ù†ÛŒ Ú©ÛŒ Ù…ÙˆÙ¹Ø± Ù„Ú¯Ø§Ù†Ø§', price: 2500),
      ServiceItem(titleEn: 'Geyser Repair & Service', titleUr: 'Ú¯ÛŒØ²Ø± Ú©ÛŒ Ø³Ø±ÙˆØ³ Ø§ÙˆØ± Ù…Ø±Ù…Øª', price: 1800),
      ServiceItem(titleEn: 'Pipeline Leakage Repair', titleUr: 'Ù¾Ø§Ø¦Ù¾ Ù„Ø§Ø¦Ù† Ù„ÛŒÚ©ÛŒØ¬ Ù…Ø±Ù…Øª', price: 1000),
      ServiceItem(titleEn: 'Shower Fitting Replacement', titleUr: 'Ø´Ø§ÙˆØ± ÙÙ¹Ù†Ú¯ ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±Ù†Ø§', price: 700),
      ServiceItem(titleEn: 'Drain Blockage Cleaning', titleUr: 'Ø¨Ù†Ø¯ Ù†Ø§Ù„ÛŒ Ú©ÛŒ ØµÙØ§Ø¦ÛŒ', price: 800),
      ServiceItem(titleEn: 'Full Washroom Setup', titleUr: 'ÙˆØ§Ø´ Ø±ÙˆÙ… Ú©Ø§ Ù…Ú©Ù…Ù„ Ø³ÛŒÙ¹ Ø§Ù¾', price: 12000),
    ],
    // Electrician
    1: [
      ServiceItem(titleEn: 'Broken Switch Repair', titleUr: 'Ø®Ø±Ø§Ø¨ Ø³ÙˆØ¦Ú† Ú©ÛŒ Ù…Ø±Ù…Øª', price: 300, isSelected: true),
      ServiceItem(titleEn: 'Short Circuit Fix', titleUr: 'Ø´Ø§Ø±Ù¹ Ø³Ø±Ú©Ù¹ Ù¹Ú¾ÛŒÚ© Ú©Ø±Ù†Ø§', price: 400, isSelected: true),
      ServiceItem(titleEn: 'Ceiling Fan Installation', titleUr: 'Ø³ÛŒÙ„Ù†Ú¯ ÙÛŒÙ† Ø§Ù†Ø³Ù¹Ø§Ù„ÛŒØ´Ù†', price: 500),
      ServiceItem(titleEn: 'Full Home Wiring Repair', titleUr: 'Ù…Ú©Ù…Ù„ Ú¯Ú¾Ø± Ú©ÛŒ ÙˆØ§Ø¦Ø±Ù†Ú¯ Ù…Ø±Ù…Øª', price: 8000),
      ServiceItem(titleEn: 'AC Switch Installation', titleUr: 'Ø§Û’ Ø³ÛŒ Ø³ÙˆØ¦Ú† Ù„Ú¯Ø§Ù†Ø§', price: 450),
      ServiceItem(titleEn: 'UPS Setup & Installation', titleUr: 'ÛŒÙˆ Ù¾ÛŒ Ø§ÛŒØ³ Ø³ÛŒÙ¹ Ø§Ù¾', price: 1500),
      ServiceItem(titleEn: 'Generator Repair', titleUr: 'Ø¬Ù†Ø±ÛŒÙ¹Ø± Ú©ÛŒ Ù…Ø±Ù…Øª', price: 2000),
      ServiceItem(titleEn: 'Bulb or Holder Replacement', titleUr: 'Ø¨Ù„Ø¨ ÛŒØ§ ÛÙˆÙ„ÚˆØ± ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±Ù†Ø§', price: 150),
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
    // Helper to determine category index from stored category name
    int getCategoryIndex(String? categoryNameEn) {
      if (categoryNameEn == null || categoryNameEn.isEmpty) return -1;
      final idx = _skillNamesEn.indexWhere((e) => e.toLowerCase() == categoryNameEn.toLowerCase());
      return idx >= 0 ? idx : -1;
    }

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
          
          // Determine category from stored profile data
          final storedCategoryName = data['categoryNameEn']?.toString();
          final categoryIdx = getCategoryIndex(storedCategoryName);
          if (categoryIdx >= 0) {
            _categoryIndex = categoryIdx;
          }
          
          final savedSkills = data['skills'] as List<dynamic>?;
          
          // Parse saved skills (if any)
          final List<ServiceItem> saved = [];
          if (savedSkills != null) {
            for (final s in savedSkills) {
              if (s is Map<String, dynamic>) {
                saved.add(ServiceItem(
                  titleEn: s['titleEn']?.toString() ?? '',
                  titleUr: s['titleUr']?.toString() ?? '',
                  price: (s['price'] as num?)?.toDouble() ?? 0,
                  isSelected: true,
                ));
              } else if (s is Map) {
                final m = Map<String, dynamic>.from(s);
                saved.add(ServiceItem(
                  titleEn: m['titleEn']?.toString() ?? '',
                  titleUr: m['titleUr']?.toString() ?? '',
                  price: (m['price'] as num?)?.toDouble() ?? 0,
                  isSelected: true,
                ));
              }
            }
          }
          
          // Get predefined skills for the worker's category
          final defaults = _servicesMap[_categoryIndex] ?? [];
          
          // Merge: predefined skills are selected ONLY if they exist in saved skills
          final merged = defaults.map((d) {
            final existing = saved.where((s) => s.titleEn == d.titleEn).firstOrNull;
            return ServiceItem(
              titleEn: d.titleEn,
              titleUr: d.titleUr,
              price: existing?.price ?? d.price,
              isSelected: existing != null, // Only selected if worker saved it
            );
          }).toList();
          
          // Add any custom skills the worker added (not in predefined list)
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
      } catch (_) {}
    }

    // Fallback: no saved data - show all predefined skills as unselected
    if (mounted) {
      setState(() {
        final list = _servicesMap[_categoryIndex] ?? [];
        _currentServices = list.map((item) => ServiceItem(
          titleEn: item.titleEn,
          titleUr: item.titleUr,
          price: item.price,
          isSelected: false, // Empty slate - nothing selected
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

  bool _checkingDuplicate = false;

  Future<void> _addCustomService(bool isUrdu) async {
    final title = _customTitleController.text.trim();
    final priceText = _customPriceController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ø³Ø±ÙˆØ³ Ú©Ø§ Ù†Ø§Ù… Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº' : 'Please enter service name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu ? 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ø¯Ø±Ø³Øª Ø±Ù‚Ù… Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº' : 'Please enter a valid amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // â”€â”€ Semantic deduplication via Groq â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    setState(() => _checkingDuplicate = true);
    final allTitles = _currentServices.map((s) => s.titleEn).toList();
    final duplicate = await SkillDeduplicator.findDuplicate(
      newTitle: title,
      existingTitles: allTitles,
    );
    if (!mounted) return;
    setState(() => _checkingDuplicate = false);

    if (duplicate != null) {
      // Show a friendly dialog telling the worker which existing item matches
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.merge_type, color: Color(0xFF0D9488)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUrdu ? 'Ù…Ù„ØªÛŒ Ø¬Ù„ØªÛŒ Ø®Ø¯Ù…Øª Ù…ÙˆØ¬ÙˆØ¯ ÛÛ’' : 'Similar Service Exists',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isUrdu
                ? '"$title" Ù¾ÛÙ„Û’ Ø³Û’ Ù…ÙˆØ¬ÙˆØ¯ Ø®Ø¯Ù…Øª "$duplicate" Ú©Û’ Ù…ØªØ±Ø§Ø¯Ù ÛÛ’Û”\nØ¨Ø±Ø§Û Ú©Ø±Ù… Ø§Ø³Û’ ÙÛØ±Ø³Øª Ø³Û’ Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚºÛ”'
                : '"$title" is equivalent to the existing service:\n\n"$duplicate"\n\nPlease select it from the list instead.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isUrdu ? 'Ù¹Ú¾ÛŒÚ© ÛÛ’' : 'Got it'),
            ),
          ],
        ),
      );
      return; // Do NOT add the duplicate
    }
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            Text(isUrdu ? 'Ù†Ø¦ÛŒ Ø³Ø±ÙˆØ³ Ú©Ø§Ù…ÛŒØ§Ø¨ÛŒ Ø³Û’ Ø´Ø§Ù…Ù„ Ú©Ø± Ø¯ÛŒ Ú¯Ø¦ÛŒ' : 'New service added successfully'),
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
          content: Text(isUrdu ? 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ú©Ù… Ø§Ø² Ú©Ù… Ø§ÛŒÚ© Ø³Ø±ÙˆØ³ Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚº' : 'Please select at least one service'),
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
          'roles': ['worker'],
          'workerStatus': 'pending',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'idFrontUrl': _signupData!.idFrontUrl,
          'idBackUrl': _signupData!.idBackUrl,
          'category': categoryKey,
          'skills': selectedServices,
          'categoryNameEn': _skillNamesEn[_categoryIndex],
          'categoryNameUr': _skillNamesUr[_categoryIndex],
          'setupComplete': true,
          'latitude': LocationService.instance.currentLocation.latitude,
          'longitude': LocationService.instance.currentLocation.longitude,
          'city': LocationService.instance.currentLocation.city,
          'area': LocationService.instance.currentLocation.area,
          'locationAddress': LocationService.instance.currentLocation.fullAddress,
          'isInsideTwinCities': LocationService.instance.currentLocation.isInsideTwinCities,
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
            content: Text(isUrdu ? 'Ù…Ø­ÙÙˆØ¸ Ú©Ø±Ù†Û’ Ù…ÛŒÚº Ø®Ø±Ø§Ø¨ÛŒ: $e' : 'Error saving: $e'),
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
                isUrdu ? 'Ù…Ø­ÙÙˆØ¸ ÛÙˆ Ú¯ÛŒØ§!' : 'Saved!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isUrdu
                    ? 'Ø¢Ù¾ Ú©ÛŒ Ø³Ø±ÙˆØ³Ø² Ø§ÙˆØ± Ø±ÛŒÙ¹Ø³ Ú©Ø§Ù…ÛŒØ§Ø¨ÛŒ Ø³Û’ Ù…Ø­ÙÙˆØ¸ Ú©Ø± Ø¯ÛŒÛ’ Ú¯Ø¦Û’ ÛÛŒÚºÛ”'
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
                    isUrdu ? 'Ù…Ø­ÙÙˆØ¸ Ú©Ø±ÛŒÚº' : 'Save & Go Back',
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
              icon: const Icon(Icons.language, size: 18),
              label: Text(
                controller.isUrdu ? 'English' : 'اردو',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
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
                                isUrdu ? 'Ø¢Ù¾ Ú©Ø§ Ù¾ÛŒØ´Û' : 'Your Profession',
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
                            ? 'Ø§Ù¾Ù†ÛŒ Ù¾ÛŒØ´ Ú©Ø±Ø¯Û Ø³Ø±ÙˆØ³Ø² Ú©Ùˆ Ù†Ø´Ø§Ù† Ø²Ø¯ Ú©Ø±ÛŒÚº Ø§ÙˆØ± Ø§Ù¾Ù†ÛŒ Ù‚ÛŒÙ…Øª Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚºÛ” Ú©Ø³Ù¹Ù…Ø±Ø² Ú©Ùˆ ÛŒÛ Ø±ÛŒÙ¹Ø³ Ø¨Ø±Ø§Û Ø±Ø§Ø³Øª Ù†Ø¸Ø± Ø¢Ø¦ÛŒÚº Ú¯Û’Û”'
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
                                          isUrdu ? 'Ø±ÙˆÙ¾Û’' : 'Rs.',
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
                                    ),     ),
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
                                      isUrdu ? 'Ø³Ø±ÙˆØ³ Ú©Ø§ Ù†Ø§Ù… Ú©ÛŒØ§ ÛÛ’ØŸ' : 'Describe the service:',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _customTitleController,
                                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                      decoration: InputDecoration(
                                        hintText: isUrdu ? 'Ù…Ø«Ù„Ø§Ù‹ Ú©Ú†Ù† Ù¾Ø§Ø¦Ù¾ Ú©ÛŒ ØµÙØ§Ø¦ÛŒ' : 'E.g., Kitchen pipe cleaning',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isUrdu ? 'Ø¢Ù¾ Ú©ÛŒ Ù‚ÛŒÙ…Øª (Ø±ÙˆÙ¾Û’ Ù…ÛŒÚº):' : 'Proposed Price (Rs.):',
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
                                        onPressed: _checkingDuplicate ? null : () => _addCustomService(isUrdu),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D9488),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.6),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: _checkingDuplicate
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    isUrdu ? 'Ø¬Ø§Ù†Ú† Ú©ÛŒ Ø¬Ø§ Ø±ÛÛŒ ÛÛ’...' : 'Checking...',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                isUrdu ? 'Ø³Ø±ÙˆØ³ Ø´Ø§Ù…Ù„ Ú©Ø±ÛŒÚº' : 'Add Service',
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
