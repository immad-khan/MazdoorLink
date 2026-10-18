# MazdoorLink Application Code Snippets

This document contains the exact source code implementations for all 29 functional requirement snippets modeled in Chapter 4 of the MazdoorLink FYP report. For each snippet, the description, status, requirement reference, source file path, and exact verbatim source code from the codebase are provided.

---

## 4.3.1 Snippet 1: Customer Sign Up and Login

**Description:** The customer signs in or creates an account using the modeled email and password flow, with email verification and password recovery. Successful access opens the customer home screen. Status: Implemented (FR-C01).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Customer account registration and sign-in authentication flow using FirebaseAuth and Cloud Firestore.

```dart
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _password.text,
          );
          
          final userData = <String, dynamic>{
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phone.text.trim(),
            'cnic': _cnicController.text.trim(),
            'role': 'customer',
            'roles': ['customer'],
            'otpVerifiedVia': _selectedOtpMethod,
            'createdAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
          
```

*(Continued from [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart):)*

```dart
      for (final email in targetEmails) {
        try {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (userCredential.user != null) {
            break;
          }
        } catch (e) {
          lastAuthError = e;
        }
      }
```

---

## 4.3.2 Snippet 2: Customer Selects Service Category and Issue

**Description:** The customer chooses a service category and issue, selects a payment method, and proceeds to find matching workers. Status: Implemented (FR-C02).

**Source File:** [`lib/screens/issue_selection_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/issue_selection_screen.dart)

**Implementation Note:** Customer payment method selection modal and proceeding with selected category and issues.

```dart
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
```

---

## 4.3.3 Snippet 3: Intelligent Worker Filtering

**Description:** The customer selects a map location. The system filters workers by category, skills, online availability, and the specified 25 km radius, then displays matching profiles. Status: Implemented (FR-C03).

**Source File:** [`lib/services/workers_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/workers_service.dart)

**Implementation Note:** Worker retrieval filtering by service category, approved verification status, live online availability, and specific skills matching.

```dart
Future<List<WorkerModel>> getWorkersByCategory(String categoryKey) async {
  final categoryName = _categoryKeyToName(categoryKey);
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .where('status', isEqualTo: 'approved')
      .where('isOnline', isEqualTo: true)
      .where('categoryNameEn', isEqualTo: categoryName)
      .get();

  return snapshot.docs.map((doc) {
    return WorkerModel.fromFirestore(doc.data(), docId: doc.id);
  }).toList();
}

/// Returns workers in [categoryKey] who have at least one skill matching
/// any of the [selectedSkillTitles]. Filtering is done client-side because
/// Firestore cannot query on nested array-of-map fields.
/// If [selectedSkillTitles] is empty, all workers in the category are returned.
Future<List<WorkerModel>> getWorkersByCategoryAndSkills(
  String categoryKey,
  List<String> selectedSkillTitles,
) async {
  // Fetch all approved workers in the right category first.
  final allInCategory = await getWorkersByCategory(categoryKey);

  if (selectedSkillTitles.isEmpty) return allInCategory;

  final normalised = selectedSkillTitles
      .map((t) => t.trim().toLowerCase())
      .toSet();

  // Keep only workers whose skills list contains at least one match.
  return allInCategory.where((worker) {
    final workerSkills = worker.skillsEn
        .map((s) => s.trim().toLowerCase())
        .toSet();
    return workerSkills.intersection(normalised).isNotEmpty;
  }).toList();
}
```

---

## 4.3.4 Snippet 4: Customer Hires Worker

**Description:** The customer reviews a worker profile, specifies the offered price and payment method, and submits a request. The modeled job record starts as pending with an expiration time and is sent to the worker as an offer. Status: Implemented (FR-C04).

**Source File:** [`lib/services/workers_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/workers_service.dart)

**Implementation Note:** Customer job request creation storing offered price, payment method, coordinates, pending status, and expiration timestamp.

```dart
Future<String?> createJobOffer({
  required String? workerId,
  required String workerName,
  required String descriptionEn,
  required String descriptionUr,
  required double price,
  required String categoryKey,
  String paymentMethod = 'Cash',
  double? customerLatitude,
  double? customerLongitude,
  int visibilityDurationMinutes = 10,
}) async {
  final customer = FirebaseAuth.instance.currentUser;
  if (customer == null || workerId == null) return null;

  final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customer.uid).get();
  final customerName = customerDoc.data()?['name']?.toString() ?? customer.displayName ?? 'Customer';

  final pin = '${1000 + Random().nextInt(9000)}';
  final expiresAt = DateTime.now().add(Duration(minutes: visibilityDurationMinutes));

  final docRef = await FirebaseFirestore.instance.collection('jobs').add({
    'customerId': customer.uid,
    'customerName': customerName,
    'workerId': workerId,
    'workerName': workerName,
    'descriptionEn': descriptionEn,
    'descriptionUr': descriptionUr,
    'price': price,
    'categoryKey': categoryKey,
    'paymentMethod': paymentMethod,
    'status': 'pending',
    'pin': pin,
    if (customerLatitude != null) 'customerLatitude': customerLatitude,
    if (customerLongitude != null) 'customerLongitude': customerLongitude,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresAt': expiresAt.toIso8601String(),
    'visibilityDurationMinutes': visibilityDurationMinutes,
  });

  return docRef.id;
}
```

---

## 4.3.5 Snippet 5: Chat between Customer and Worker

**Description:** After a job is accepted, the customer and worker exchange real-time messages and may request English–Urdu translation. Status: Pending (FR-C05 and FR-W08).

**Source File:** [`lib/services/workers_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/workers_service.dart)

**Implementation Note:** Real-time bidirectional message dispatch with automatic language detection, translation (English-to-Urdu and Urdu-to-English), and unread count tracking.

```dart
Future<void> sendMessage(String conversationId, String text) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final sourceLang = detectLanguage(text);
  final otherLang = sourceLang == 'en' ? 'ur' : 'en';
  final translated = await TranslationService().translate(
    text: text,
    sourceLang: sourceLang,
    targetLang: otherLang,
  );
  final textEn = sourceLang == 'en' ? text : translated;
  final textUr = sourceLang == 'ur' ? text : translated;
  final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(convRef);
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? []);
    final otherId = participants.where((p) => p != user.uid).firstOrNull ?? '';
    tx.set(convRef.collection('messages').doc(), {
      'senderId': user.uid,
      'text': text,
      'textEn': textEn,
      'textUr': textUr,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [user.uid],
    });
    final unread = Map<String, dynamic>.from(data['unreadCounts'] as Map? ?? {});
    if (otherId.isNotEmpty) {
      unread[otherId] = ((unread[otherId] as num?)?.toInt() ?? 0) + 1;
    }
    tx.update(convRef, {
      'lastMessage': text,
      'lastMessageEn': textEn,
      'lastMessageUr': textUr,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts': unread,
    });
  });
}
```

---

## 4.3.6 Snippet 6: Customer Views Job History

**Description:** The customer views past and ongoing job requests, with status changes modeled as live updates. The functional requirements table marks booking history as pending. Status: Pending (FR-C11).

**Source File:** [`lib/screens/booking_history_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/booking_history_screen.dart)

**Implementation Note:** Real-time StreamBuilder listening to Firestore jobs collection filtered by user and live status changes.

```dart
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
```

---

## 4.3.7 Snippet 7: Real-Time Worker Tracking Map

**Description:** After the worker accepts a job, the customer follows the worker’s location. Arrival confirmations update both participants and advance the job workflow. Status: Implemented (FR-C07).

**Source File:** [`lib/screens/worker_tracking_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/worker_tracking_screen.dart)

**Implementation Note:** Real-time job tracking listener that updates worker and customer GPS coordinates, live status transitions, and arrival confirmation PIN.

```dart
  void _listenToJob() {
    _jobSub = streamJobById(widget.jobId).listen((snapshot) async {
      if (!mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final isUrdu = AppScope.of(context).isUrdu;
      double? lat, lng;
      if (data['customerLatitude'] != null && data['customerLongitude'] != null) {
        lat = (data['customerLatitude'] as num).toDouble();
        lng = (data['customerLongitude'] as num).toDouble();
      }
      final customerId = data['customerId']?.toString();
      String phone = '';
      if (customerId != null) {
        phone = await getUserPhone(customerId) ?? '';
      }
      if (!mounted) return;
      setState(() {
        final jobStatus = data['status']?.toString() ?? 'accepted';
        if (jobStatus == 'arrival_pending') {
          _status = 4;
        } else if (jobStatus == 'working') {
          _status = 1;
        } else if (jobStatus == 'worker_completed') {
          _status = 2;
        } else if (jobStatus == 'payment_pending') {
          _status = 2;
        } else if (jobStatus == 'worker_payment_pending') {
          _status = 6;
        } else if (jobStatus == 'completed') {
          _status = 3;
        } else if (jobStatus == 'arrival_declined') {
          _status = 5;
        } else if (jobStatus == 'scheduled') {
          _status = 7;
        } else {
          _status = 0;
        }
        if (lat != null && lng != null) _customerLocation = LatLng(lat, lng);
        _pin = data['pin']?.toString() ?? '';
        _customerName = data['customerName']?.toString() ?? 'Customer';
        _customerPhone = phone;
        _paymentMethod = data['paymentMethod']?.toString() ?? 'Cash';
        _jobDesc = isUrdu
            ? (data['descriptionUr']?.toString() ?? '')
            : (data['descriptionEn']?.toString() ?? '');
        final scheduledRaw = data['scheduledReminderAt'];
        _scheduledTime = scheduledRaw is Timestamp ? scheduledRaw.toDate() : null;
        _scheduleConfirmed = data['scheduleConfirmed'] as bool? ?? false;
        _updateMarkers();
      });
    });
  }
```

---

## 4.3.8 Snippet 8: Customer Cancels Job

**Description:** Before the worker arrives, the customer can cancel the job and provide a reason, which is recorded and communicated to the worker. Status: Implemented (FR-C08).

**Source File:** [`lib/screens/cancel_job_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/cancel_job_screen.dart)

**Implementation Note:** Customer job cancellation category and sub-reason classification system with localized English and Urdu explanations.

```dart
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
```

---

## 4.3.9 Snippet 9: Customer Complaint and Admin Chat

**Description:** The customer submits a complaint about a booking and contacts support; an administrator reviews the complaint and replies. Status: Pending (FR-C09).

**Source File:** [`lib/screens/customer_support_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/customer_support_screen.dart)

**Implementation Note:** Order selection and customer complaint intake form collecting issue description and claimed dispute amount.

```dart
class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _complaintController = TextEditingController();
  final _amountController = TextEditingController();
  int? _selectedOrderIndex;

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'title': 'Plumber Repair',
      'date': '24 May 2025',
      'worker': 'Ali Khan',
      'status': 'Completed',
    },
    {
      'title': 'Electrician Wiring',
      'date': '12 May 2025',
      'worker': 'Usman Ahmed',
      'status': 'Completed',
    },
    {
      'title': 'AC Installation',
      'date': '01 Apr 2025',
      'worker': 'Raza',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    if (_selectedOrderIndex != null) {
      return _buildComplaintForm(isUrdu);
    }
```

---

## 4.3.10 Snippet 10: Worker Sign Up, Login, and Approval

**Description:** The worker accesses or creates an account, submits personal details and verification documents, and awaits administrator approval or rejection. Status: Implemented (FR-W01).

**Source File:** [`lib/screens/worker_verification_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/worker_verification_screen.dart)

**Implementation Note:** Worker document submission workflow validating 13-digit CNIC, uploading front/back ID images, police clearance, and profile picture for admin review.

```dart
  Future<void> _submitVerification() async {
    final isUrdu = AppScope.of(context).isUrdu;
    final cnic = _cnicController.text.trim();

    setState(() {
      _cnicError = !RegExp(r'^\d{13}$').hasMatch(cnic)
          ? bilingual(context, 'Enter a valid 13-digit CNIC', '13 ہندسوں کا درست شناختی کارڈ نمبر درج کریں')
          : null;
    });

    if (_cnicError != null) {
      showToast(bilingual(context, 'Please fix CNIC errors', 'شناختی کارڈ نمبر درست درج کریں'));
      return;
    }

    if (!_hasImage('idFront')) {
      showToast(bilingual(context, 'Front CNIC image is required', 'شناختی کارڈ کی فرنٹ تصویر لازمی ہے'));
      return;
    }

    if (!_hasImage('idBack')) {
      showToast(bilingual(context, 'Back CNIC image is required', 'شناختی کارڈ کی بیک تصویر لازمی ہے'));
      return;
    }

    if (!_hasImage('policeCert')) {
      showToast(bilingual(context, 'Police certificate is required for verification', 'پولیس سرٹیفکیٹ لازمی ہے'));
      return;
    }

    if (!_hasImage('profilePic')) {
      showToast(bilingual(context, 'Profile picture is required', 'پروفائل تصویر لازمی ہے'));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(bilingual(context, 'User not logged in', 'صارف لاگ ان نہیں ہے'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingStatus = bilingual(context, 'Uploading documents...', 'دستاویزات اپ لوڈ ہو رہی ہیں...');
    });

    try {
      final frontUrl = await _uploadImageFile('idFront', _existingIdFrontUrl);
      final backUrl = await _uploadImageFile('idBack', _existingIdBackUrl);
      final policeCertUrl = await _uploadImageFile('policeCert', _existingPoliceCertUrl);
      final certUrl = await _uploadImageFile('specializationCert', _existingCertUrl);
      final profilePicUrl = await _uploadImageFile('profilePic', _existingProfilePicUrl);

      if (frontUrl == null || backUrl == null || policeCertUrl == null) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          showToast(bilingual(context, 'Failed to upload documents. Please check connection and try again.', 'دستاویزات اپ لوڈ کرنے میں ناکامی۔ دوبارہ کوشش کریں۔'));
        }
        return;
      }
```

---

## 4.3.11 Snippet 11: Worker Toggles Online/Offline Presence

**Description:** The worker changes availability. The modeled flow updates online status and last-seen time, sends periodic heartbeats, and marks the worker offline when the app enters the background. Status: Implemented (FR-W02).

**Source File:** [`lib/services/workers_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/workers_service.dart)

**Implementation Note:** Worker presence service maintaining online availability status, 30-second heartbeat updates, and automatic offline switching on app lifecycle detach/pause.

```dart
class WorkerPresenceService with WidgetsBindingObserver {
  static final WorkerPresenceService instance = WorkerPresenceService._();
  WorkerPresenceService._();

  bool _initialized = false;
  bool isOnline = false;
  Timer? _heartbeat;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isOnline) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastSeenAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        setPresence(online: true).catchError((_) {});
      }
    });
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> setOnline(bool value) async {
    isOnline = value;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': value,
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
      await setPresence(online: value);
    } catch (_) {}

    if (value) {
      startHeartbeat();
    } else {
      stopHeartbeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Only manage online status if worker had toggled online
    if (!isOnline) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Worker left the app: mark offline in Firestore
      stopHeartbeat();
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
      setPresence(online: false).catchError((_) {});
    } else if (state == AppLifecycleState.resumed) {
      // Worker returned to the app: restore online status in Firestore
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
```

---

## 4.3.12 Snippet 12: Worker Manages Skills and Rates

**Description:** The worker adds or edits offered services and rates, then saves these profile details for customers to view. Status: Implemented (FR-W03).

**Source File:** [`lib/screens/worker_services_setup_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/worker_services_setup_screen.dart)

**Implementation Note:** Worker skill setup loading and persisting customized services and pricing rates to Firestore.

```dart
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
```

---

## 4.3.13 Snippet 13: Worker Receives Job Offers

**Description:** Available workers receive new requests through the real-time job stream; expired offers are no longer shown as available. Status: Implemented (FR-W04).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Real-time job offers stream for online workers, validating expiration timestamps and calculating remaining active offer time.

```dart
            StreamBuilder<QuerySnapshot>(
              stream: streamWorkerJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('WorkerJobsError: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allJobs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final jobs = allJobs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final expiresAtStr = data['expiresAt']?.toString();
                  if (expiresAtStr != null) {
                    final expiresAt = DateTime.tryParse(expiresAtStr);
                    if (expiresAt != null && expiresAt.isBefore(now)) return false;
                  }
                  return true;
                }).toList();

                jobs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aCreated = aData['createdAt'];
                  final bCreated = bData['createdAt'];
                  final aTime = (aCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bTime = (bCreated as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });

                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        bilingual(context, 'No new jobs yet', 'ابھی تک کوئی نیا کام نہیں'),
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }
                return Column(
                  children: jobs.map((doc) {
                    final jobData = doc.data() as Map<String, dynamic>;
                    final jobId = doc.id;
                    final descEn = jobData['descriptionEn']?.toString() ?? 'Service';
                    final descUr = jobData['descriptionUr']?.toString() ?? 'سروس';
                    final price = (jobData['price'] as num?)?.toDouble() ?? 0;
                    final payment = jobData['paymentMethod']?.toString() ?? 'Cash';
                    final customerName = jobData['customerName']?.toString() ?? 'Customer';

                    String remainingTime = '';
                    final expiresAtStr = jobData['expiresAt']?.toString();
                    if (expiresAtStr != null) {
                      final expiresAt = DateTime.tryParse(expiresAtStr);
                      if (expiresAt != null) {
                        final diff = expiresAt.difference(now);
                        if (diff.isNegative) {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        } else if (diff.inDays > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inDays} دن باقی'
                              : '${diff.inDays}d remaining';
                        } else if (diff.inHours > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inHours} گھنٹے باقی'
                              : '${diff.inHours}h remaining';
                        } else if (diff.inMinutes > 0) {
                          remainingTime = isUrdu
                              ? '${diff.inMinutes} منٹ باقی'
                              : '${diff.inMinutes}min remaining';
                        } else {
                          remainingTime = isUrdu ? 'میعاد ختم' : 'Expired';
                        }
                      }
                    }
```

---

## 4.3.14 Snippet 14: Worker Accepts or Declines Job

**Description:** The worker accepts or declines an offer. Acceptance and subsequent job-state updates are reflected in the customer’s view. Status: Implemented (FR-W05).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Worker job offer decision actions updating job status to accepted or rejected in Firestore.

```dart
  Future<void> _handleAcceptJob(BuildContext context, String jobId, double price) async {
    final isUrdu = AppScope.of(context).isUrdu;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final busy = await workerHasActiveJob(user.uid);
    if (!mounted) return;

    if (!busy) {
      await updateJobStatus(jobId, 'accepted');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerTrackingScreen(jobPrice: price, jobId: jobId),
        ),
      );
      return;
    }

    final scheduled = await _pickScheduleTime(context);
    if (scheduled == null || !mounted) return;
    await scheduleAcceptedJob(jobId, scheduled);
    if (!mounted) return;
    _notifyScheduleProposal(jobId, scheduled);
    showToast(isUrdu
        ? 'آپ کی تجویز کردہ آمد کا وقت گاہک کی منظوری کے لیے بھیج دیا گیا'
        : 'Your proposed arrival time was sent to the customer for approval');
  }
```

*(Continued from [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart):)*

```dart
                                  // Reject
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        updateJobStatus(jobId, 'rejected');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isUrdu ? 'کام رد کر دیا گیا' : 'Job rejected'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: Text(isUrdu ? 'رد کریں' : 'Reject'),
                                    ),
                                  ),
```

---

## 4.3.15 Snippet 15: Worker Views Earnings and Tops Up Balance

**Description:** The worker views earnings and transaction history and can initiate an account balance top-up. Both functions remain pending in the requirements table. Status: Pending (FR-W06 and FR-W09).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Worker earnings dashboard showing real-time earnings stream and history of completed and accepted jobs.

```dart
    return MzScaffold(
      showBottomNav: true,
      child: StreamBuilder<double>(
        stream: streamWorkerEarnings(),
        builder: (context, earningsSnapshot) {
          final totalEarnings = earningsSnapshot.data ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .where('status', whereIn: ['accepted', 'completed'])
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, jobsSnapshot) {
              final jobs = jobsSnapshot.data?.docs ?? [];
              final completedCount = jobs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'completed';
```

---

## 4.3.16 Snippet 16: Worker Voice Navigation (Accessibility)

**Description:** The worker navigates using Urdu voice commands. Chapter 2 notes that the UI exists but the speech-recognition service is still a stub. Status: Pending (FR-W07).

**Source File:** [`lib/screens/voice_navigation_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/voice_navigation_screen.dart)

**Implementation Note:** Speech recognition interface providing accessibility audio wave feedback and simulated command processing for Urdu navigation.

```dart
  void _startListening() {
    setState(() => _listening = true);
    _recognizedCommand = '';

    for (var controller in _waveControllers) {
      controller.repeat();
    }

    Future.delayed(Duration(seconds: 3), () {
      for (var controller in _waveControllers) {
        controller.stop();
      }

      setState(() {
        _listening = false;
        _recognizedCommand = 'Post a Plumber job in Lahore';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Command recognized successfully'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
```

---

## 4.3.17 Snippet 17: Customer and Worker Change App Language

**Description:** The customer or worker selects English or Urdu, and the chosen language is applied across the interface. Status: Implemented (FR-G03).

**Source File:** [`lib/screens/language_selection.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/language_selection.dart)

**Implementation Note:** User interface screen for toggling between Urdu and English localization locales.

```dart
class LanguageSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('language_selection'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context).t('language_urdu')),
              onTap: () => Navigator.pop(context, Locale('ur')),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context).t('language_english')),
              onTap: () => Navigator.pop(context, Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4.3.18 Snippet 18: Admin Worker Approval Workflow

**Description:** The administrator reviews a pending worker’s identity, contact details, and submitted documents, then approves the application or rejects it with a reason. Status: Implemented (FR-A01).

**Source File:** [`lib/screens/admin_dashboard_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/admin_dashboard_screen.dart)

**Implementation Note:** Administrator rejection and approval methods updating verification state in Firestore and notifying the worker.

```dart
  void _rejectWorker(
    BuildContext context,
    String docId,
    String workerName,
    String workerEmail,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject $workerName'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. ID blurry',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              await FirebaseFirestore.instance.collection('users').doc(docId).update({
                'status': 'rejected',
                'workerStatus': 'rejected',
                'rejectReason': reason,
              });
              final emailSent = await SmtpService.sendWorkerRejectionEmail(
```

*(Continued from [`lib/screens/admin_dashboard_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/admin_dashboard_screen.dart):)*

```dart
  void _approveWorker(
    BuildContext context,
    String docId,
    String workerName,
    String workerEmail,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'status': 'approved',
      'workerStatus': 'approved',
      'roles': FieldValue.arrayUnion(['worker']),
    });
    final emailSent = await SmtpService.sendWorkerApprovalEmail(
      email: workerEmail,
      workerName: workerName,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          emailSent
              ? '$workerName approved and email sent.'
              : '$workerName approved, but email could not be sent.',
        ),
        duration: const Duration(seconds: 7),
      ),
    );
  }
```

---

## 4.3.19 Snippet 19: Admin Views Jobs and Applies Penalty

**Description:** The administrator reviews ongoing and completed jobs and may apply a penalty to a completed job as described in the use case. Status: Pending (FR-A02).

**Source File:** [`lib/screens/admin_jobs_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/admin_jobs_screen.dart)

**Implementation Note:** Admin job inspection modal allowing application of standard (5%, 10%) or custom financial penalty deductions.

```dart
            if (isCompleted) ...[
              const Text('Add Penalty (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => penaltyController.text = (price * 0.05).toStringAsFixed(0),
                      child: const Text('5%'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => penaltyController.text = (price * 0.10).toStringAsFixed(0),
                      child: const Text('10%'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: penaltyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Penalty Amount (PKR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Penalty of Rs. ${penaltyController.text} applied to $worker')));
                  },
                  child: const Text('Apply Penalty'),
                ),
              ),
```

---

## 4.3.20 Snippet 20: Admin Views Platform Stats

**Description:** The administrator views measures such as revenue, active jobs, user totals, service categories, and booking trends. Status: Pending (FR-A03).

**Source File:** [`lib/screens/admin_dashboard_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/admin_dashboard_screen.dart)

**Implementation Note:** Platform metrics overview calculating total completed revenue, active user counts, worker distribution, and service metrics.

```dart
class _LiveStatsCards extends StatelessWidget {
  const _LiveStatsCards({required this.period});
  final String period;

  DateTime? _periodStart() {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _periodStart();

    Query completedQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'completed');
    if (start != null) {
      completedQuery = completedQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }

    Query activeQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', whereIn: [
      'pending', 'accepted', 'arrival_pending', 'working',
      'worker_completed', 'payment_pending', 'worker_payment_pending',
      'payment_disputed',
    ]);
    if (start != null) {
      activeQuery = activeQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: completedQuery.snapshots(),
      builder: (_, completedSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: activeQuery.snapshots(),
          builder: (_, activeSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (_, usersSnap) {
                double totalRevenue = 0;
                if (completedSnap.hasData) {
                  for (final doc in completedSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalRevenue += (data['price'] as num?)?.toDouble() ?? 0;
                  }
                }
                final activeJobs = activeSnap.data?.docs.length ?? 0;
                final totalUsers = usersSnap.data?.docs.length ?? 0;

                String revenueStr;
                if (totalRevenue >= 1000000) {
                  revenueStr = 'Rs ${(totalRevenue / 1000000).toStringAsFixed(1)}M';
                } else if (totalRevenue >= 1000) {
                  revenueStr = 'Rs ${(totalRevenue / 1000).toStringAsFixed(1)}k';
                } else {
                  revenueStr = 'Rs ${totalRevenue.toStringAsFixed(0)}';
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        _StatsCard(
                            label: 'Total Revenue', value: revenueStr,
                            icon: Icons.paid_outlined, color: const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _StatsCard(
                            label: 'Active Jobs', value: '$activeJobs',
                            icon: Icons.work_outline, color: const Color(0xFF6366F1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatsCard(
                            label: 'Total Users', value: '$totalUsers',
                            icon: Icons.people_outline, color: const Color(0xFF0D9488)),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
```

---

## 4.3.21 Snippet 21: Admin Manages Damage Claims and Security Deposits

**Description:** The administrator reviews damage claims and may deduct compensation from a worker’s security deposit. Chapter 2 notes that the full claim lifecycle and financial transaction logic are planned for a future phase. Status: Pending (FR-A04).

**Source File:** [`lib/screens/admin_dashboard_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/admin_dashboard_screen.dart)

**Implementation Note:** Security deposit deduction dialog allowing administrator to penalize damage claims from worker balance.

```dart
  void _showDeductDepositDialog(BuildContext context, String workerId, String workerName) async {
    final depositSnap = await FirebaseFirestore.instance
        .collection('security_deposits')
        .where('workerId', isEqualTo: workerId)
        .limit(1)
        .get();
    final currentBalance = depositSnap.docs.isNotEmpty
        ? ((depositSnap.docs.first.data()['currentBalance'] as num?)?.toDouble() ?? 0)
        : 0.0;

    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deduct Security Deposit: $workerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Top-up Balance: Rs. ${currentBalance.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Deduct (Rs.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
```

---

## 4.3.22 Snippet 22: Customer Adds Favourite Worker

**Description:** The customer saves a preferred worker for quicker access during future service searches. Status: Implemented (FR-C10).

**Source File:** [`lib/services/workers_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/workers_service.dart)

**Implementation Note:** Customer favourite worker persistence methods adding/removing worker references with Firestore arrayUnion/arrayRemove.

```dart
Future<void> addFavouriteWorker(String workerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'favouriteWorkerIds': FieldValue.arrayUnion([workerId]),
  });
}

Future<void> removeFavouriteWorker(String workerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'favouriteWorkerIds': FieldValue.arrayRemove([workerId]),
  });
}

Stream<List<String>> streamFavouriteWorkerIds() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        final ids = doc.data()?['favouriteWorkerIds'] as List<dynamic>?;
        return ids?.map((e) => e.toString()).toList() ?? [];
      });
}
```

---

## 4.3.23 Snippet 23: Customer Views Past and Active Bookings

**Description:** The customer opens the bookings view and selects active or past records, with completed booking details shown for reference. This shares the same requirement as Snippet 6. Status: Pending (FR-C11).

**Source File:** [`lib/screens/booking_history_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/booking_history_screen.dart)

**Implementation Note:** Segmented tab controller allowing customer to switch between active booking records and completed history.

```dart
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
```

---

## 4.3.24 Snippet 24: Customer Rates Worker

**Description:** After a service is completed, the customer submits a rating for the worker. Status: Pending (FR-C12).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Post-service rating submission persisting customer 5-star rating and textual review to worker profile.

```dart
  Future<void> _submitRating(BuildContext context) async {
    final args = _trackingArgs(context);
    final workerId = args?.worker?.id;
    final jobId = args?.jobId;
    
    if (workerId == null || jobId == null) {
      showToast(bilingual(context, 'Unable to submit rating', 'درجہ بندی جمع نہیں ہو سکی'));
      setState(() => _step = PostJobStep.completed);
      return;
    }
    
    try {
      await submitWorkerRating(
        workerId: workerId,
        jobId: jobId,
        rating: rating,
        reviewText: review.text.trim().isNotEmpty ? review.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _step = PostJobStep.completed);
    } catch (e) {
      if (!mounted) return;
      showToast(bilingual(context, 'Error submitting rating', 'درجہ بندی جمع کرنے میں خرابی'));
      setState(() => _step = PostJobStep.completed);
    }
  }
```

---

## 4.3.25 Snippet 25: Customer Pays for Services

**Description:** The customer pays the worker for a booked service. Payment processing is not marked as implemented in the requirements table. Status: Pending (FR-C13).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Customer in-app payment confirmation dialog handling hand-to-hand cash payment and online payment transitions.

```dart
  void _showCashPaidDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bilingual(context, 'Have you paid?', 'کیا آپ نے ادائیگی کر دی؟')),
        content: Text(bilingual(
          context,
          'Have you paid Rs. ${amount.toStringAsFixed(0)} to the worker by hand?',
          'کیا آپ نے ورکر کو ${amount.toStringAsFixed(0)} روپے نقد ادا کر دیے ہیں؟',
        )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _step = PostJobStep.complaintForm);
            },
            child: Text(bilingual(context, 'No', 'نہیں')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markCustomerPaid(context);
            },
            child: Text(bilingual(context, 'Yes', 'ہاں')),
          ),
        ],
      ),
    );
  }
```

---

## 4.3.26 Snippet 26: Worker Tops Up Account Balance

**Description:** The worker adds funds to the account balance. This is also included in Use Case 15 and remains pending. Status: Pending (FR-W09).

**Source File:** [`lib/screens/mazdoor_flow.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/mazdoor_flow.dart)

**Implementation Note:** Worker balance top-up sheet supporting JazzCash / EasyPaisa digital deposit and balance update.

```dart
  void _showTopUpDialog(BuildContext context, bool isUrdu) {
    String selectedMethod = 'JazzCash';
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isUrdu ? 'ٹاپ اپ کریں' : 'Add Top-up', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'طریقہ منتخب کریں' : 'Select Method',
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                    DropdownMenuItem(value: 'EasyPaisa', child: Text('EasyPaisa')),
                  ],
                  onChanged: (val) => setModalState(() => selectedMethod = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'اکاؤنٹ نمبر' : 'Account Number',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'رقم' : 'Amount (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final amount = int.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      setState(() {
                        _topupBalance += amount;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isUrdu ? 'ٹاپ اپ کامیاب ہو گیا' : 'Top-up Successful!')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(isUrdu ? 'رقم بھیجیں' : 'Send Money'),
                ),
              ],
            ),
```

---

## 4.3.27 Snippet 27: Users Control App Functions Using Voice Commands

**Description:** The user invokes application functions through spoken commands. This general voice-control requirement is distinct from the worker navigation flow in Use Case 16. Status: Pending (FR-G01).

**Source File:** [`lib/services/voice_assistant_service.dart`](file:///D:/Desktop/MazdoorLink/lib/services/voice_assistant_service.dart)

**Implementation Note:** Voice assistant core service integrating speech-to-text listening and speech synthesis for voice commands.

```dart
  Future<void> startListening({
    required ValueChanged<String> onResult,
    required VoidCallback onDone,
    String locale = 'en_US',
  }) async {
    if (!_sttInitialized) {
      final ok = await initialize();
      if (!ok) {
        onResult('Speech recognition unavailable');
        onDone();
        return;
      }
    }

    _isListening = true;
    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onDone();
        }
      },
      localeId: locale,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }
```

---

## 4.3.28 Snippet 28: Customers and Workers Upload Profile Pictures

**Description:** The customer or worker selects and uploads or updates a profile picture. Status: Implemented (FR-G02).

**Source File:** [`lib/screens/profile_management_screen.dart`](file:///D:/Desktop/MazdoorLink/lib/screens/profile_management_screen.dart)

**Implementation Note:** Image picker integration with 5MB validation and Cloudinary cloud storage upload for user profile photos.

```dart
  Future<void> _pickFile(String key) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final fileBytes = await image.readAsBytes();
    final sizeInMb = fileBytes.length / (1024 * 1024);
    if (sizeInMb > 5) {
      _showSnack(
        'Image size must be less than 5MB (current: ${sizeInMb.toStringAsFixed(1)}MB)',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedFiles[key] = image;
      _selectedFileBytes[key] = fileBytes;
    });
  }

  Future<String?> _uploadSelected(String key, String existingUrl) async {
    final file = _selectedFiles[key];
    if (file == null) return existingUrl.isEmpty ? null : existingUrl;
    return CloudinaryService.uploadImage(file);
  }
```

---

## 4.3.29 Snippet 29: Users Change App Language

**Description:** The user switches the interface language between English and Urdu. This repeats the language-change behavior in Snippet 17. Status: Implemented (FR-G03).

**Source File:** [`lib/app_state.dart`](file:///D:/Desktop/MazdoorLink/lib/app_state.dart)

**Implementation Note:** Global app controller methods managing locale state changes and bilingual English/Urdu toggling.

```dart
  void setLocale(Locale value) {
    locale = value;
    notifyListeners();
  }

  void toggleLanguage() {
    locale = isUrdu ? const Locale('en') : const Locale('ur');
    notifyListeners();
  }
```

---

