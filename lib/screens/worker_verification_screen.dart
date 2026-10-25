import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';
import '../services/cloudinary_service.dart';
import 'mazdoor_flow.dart';

class WorkerVerificationScreen extends StatefulWidget {
  const WorkerVerificationScreen({super.key});

  @override
  State<WorkerVerificationScreen> createState() => _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen> {
  final _cnicController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Plumber';
  String? _cnicError;
  String? _categoryError;

  // Selected files & bytes for preview
  final Map<String, XFile> _files = {};
  final Map<String, Uint8List> _fileBytes = {};

  // Existing URLs from user doc
  String _existingProfilePicUrl = '';
  String _existingIdFrontUrl = '';
  String _existingIdBackUrl = '';
  List<String> _existingCertUrls = [];

  // New selected certificates
  final List<XFile> _newCertFiles = [];
  final List<Uint8List> _newCertBytes = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _submittingStatus = '';

  final List<Map<String, String>> _categories = const [
    {'key': 'plumber', 'en': 'Plumber', 'ur': 'پلمبر'},
    {'key': 'electrician', 'en': 'Electrician', 'ur': 'الیکٹریشن'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        _cnicController.text =
            data['cnicNumber']?.toString() ?? data['cnic']?.toString() ?? '';
        _existingProfilePicUrl =
            data['profilePicUrl']?.toString() ?? data['profileImage']?.toString() ?? '';
        _existingIdFrontUrl = data['idFrontUrl']?.toString() ?? '';
        _existingIdBackUrl = data['idBackUrl']?.toString() ?? '';

        final certsList = data['certificates'] as List<dynamic>?;
        if (certsList != null) {
          _existingCertUrls = certsList
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          final pol = data['policeCertUrl']?.toString().trim();
          final cert = data['certificationUrl']?.toString().trim();
          if (pol != null && pol.isNotEmpty) _existingCertUrls.add(pol);
          if (cert != null && cert.isNotEmpty && !_existingCertUrls.contains(cert)) {
            _existingCertUrls.add(cert);
          }
        }

        final savedCat = data['categoryNameEn']?.toString();
        if (savedCat != null &&
            _categories.any((c) => c['en']!.toLowerCase() == savedCat.toLowerCase())) {
          _selectedCategory = savedCat;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage(String key) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final sizeInMb = bytes.length / (1024 * 1024);
    if (sizeInMb > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bilingual(
                context,
                'Image size must be less than 5MB (selected: ${sizeInMb.toStringAsFixed(1)}MB)',
                'تصویر کا سائز 5 ایم بی سے کم ہونا چاہیے',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() {
      _files[key] = image;
      _fileBytes[key] = bytes;
    });
  }

  void _removeImage(String key) {
    setState(() {
      _files.remove(key);
      _fileBytes.remove(key);
      if (key == 'profilePic') _existingProfilePicUrl = '';
      if (key == 'idFront') _existingIdFrontUrl = '';
      if (key == 'idBack') _existingIdBackUrl = '';
    });
  }

  Future<void> _pickNewCert() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final sizeInMb = bytes.length / (1024 * 1024);
    if (sizeInMb > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bilingual(
                context,
                'Certificate size must be less than 5MB (selected: ${sizeInMb.toStringAsFixed(1)}MB)',
                'سرٹیفکیٹ کا سائز 5 ایم بی سے کم ہونا چاہیے',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() {
      _newCertFiles.add(image);
      _newCertBytes.add(bytes);
    });
  }

  void _removeExistingCert(int index) {
    setState(() {
      _existingCertUrls.removeAt(index);
    });
  }

  void _removeNewCert(int index) {
    setState(() {
      _newCertFiles.removeAt(index);
      _newCertBytes.removeAt(index);
    });
  }

  bool _hasImage(String key) {
    if (_files.containsKey(key)) return true;
    if (key == 'profilePic' && _existingProfilePicUrl.isNotEmpty) return true;
    if (key == 'idFront' && _existingIdFrontUrl.isNotEmpty) return true;
    if (key == 'idBack' && _existingIdBackUrl.isNotEmpty) return true;
    return false;
  }

  Future<String?> _uploadImageFile(String key, String existingUrl) async {
    final file = _files[key];
    if (file != null) {
      return await CloudinaryService.uploadImage(file);
    }
    return existingUrl.isNotEmpty ? existingUrl : null;
  }

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
      final profilePicUrl = await _uploadImageFile('profilePic', _existingProfilePicUrl);

      if (frontUrl == null || backUrl == null) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          showToast(bilingual(context, 'Failed to upload CNIC documents. Please check connection and try again.', 'دستاویزات اپ لوڈ کرنے میں ناکامی۔ دوبارہ کوشش کریں۔'));
        }
        return;
      }

      // Upload new certificates (optional)
      final List<String> allCertUrls = List<String>.from(_existingCertUrls);
      for (final file in _newCertFiles) {
        final uploaded = await CloudinaryService.uploadImage(file);
        if (uploaded != null && uploaded.isNotEmpty) {
          allCertUrls.add(uploaded);
        }
      }

      setState(() {
        _submittingStatus = bilingual(context, 'Submitting verification request to admin...', 'درخواست ایڈمن کو بھیجی جا رہی ہے...');
      });

      final catMatch = _categories.firstWhere(
        (c) => c['en']!.toLowerCase() == _selectedCategory.toLowerCase(),
        orElse: () => _categories.first,
      );

      final updates = <String, dynamic>{
        'role': 'worker',
        'roles': FieldValue.arrayUnion(['worker']),
        'workerStatus': 'pending',
        'status': 'pending',
        'rejectReason': FieldValue.delete(),
        'cnicNumber': cnic,
        'category': catMatch['key'],
        'categoryNameEn': catMatch['en'],
        'categoryNameUr': catMatch['ur'],
        'idFrontUrl': frontUrl,
        'idBackUrl': backUrl,
        'certificates': allCertUrls,
        'verificationRequestedAt': FieldValue.serverTimestamp(),
        'setupComplete': false,
      };

      if (allCertUrls.isNotEmpty) {
        updates['certificationUrl'] = allCertUrls.first;
        updates['policeCertUrl'] = allCertUrls.first;
      }
      if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        updates['profilePicUrl'] = profilePicUrl;
        updates['profileImage'] = profilePicUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFDCFCE7),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    bilingual(context, 'Verification Request Submitted!', 'درخواست برائے تصدیق جمع ہو گئی!'),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bilingual(
                      context,
                      'Your certificates and CNIC documents have been forwarded to the admin for review. Once approved, you can switch to worker mode to accept jobs.',
                      'آپ کے سرٹیفکیٹس اور شناختی دستاویزات ایڈمن کے جائزے کے لیے بھیج دیے گئے ہیں۔ منظوری کے بعد آپ ورکر موڈ استعمال کر سکیں گے۔',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Pop back to settings / home
                      },
                      child: Text(bilingual(context, 'Done', 'مکمل')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showToast('Error: $e');
      }
    }
  }

  Widget _buildDocUploadCard({
    required String title,
    required String titleUr,
    required String subtitle,
    required String subtitleUr,
    required String keyName,
    required bool isRequired,
    required String existingUrl,
    IconData icon = Icons.file_present_rounded,
  }) {
    final hasFile = _files.containsKey(keyName);
    final hasExisting = existingUrl.isNotEmpty;
    final isUploaded = hasFile || hasExisting;
    final fileBytes = _fileBytes[keyName];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? const Color(0xFF10B981) : Colors.grey.shade300,
          width: isUploaded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0D9488), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bilingual(context, title, titleUr),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRequired
                        ? bilingual(context, 'Required', 'لازمی')
                        : bilingual(context, 'Optional', 'اختیاری'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRequired ? const Color(0xFFDC2626) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bilingual(context, subtitle, subtitleUr),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (isUploaded) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: hasFile && fileBytes != null
                          ? Image.memory(fileBytes, fit: BoxFit.cover)
                          : Image.network(existingUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Text('Document selected'))),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () => _removeImage(keyName),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            bilingual(context, 'Ready', 'تیار ہے'),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _pickImage(keyName),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(bilingual(context, 'Change File', 'تبدیل کریں'), style: const TextStyle(fontSize: 12)),
                ),
              ),
            ] else ...[
              InkWell(
                onTap: () => _pickImage(keyName),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade600, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        bilingual(context, 'Tap to choose photo (Max 5MB)', 'فوٹو منتخب کرنے کے لیے ٹیپ کریں (زیادہ سے زیادہ 5MB)'),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(bilingual(context, 'Worker Verification', 'ورکر تصدیق')),
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          bilingual(context, 'Worker Verification', 'ورکر تصدیق'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bilingual(context, 'Admin Verification Required', 'ایڈمن تصدیق لازمی ہے'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bilingual(
                              context,
                              'To maintain quality & safety, workers must submit CNIC and optional certificates/experience letters before accepting jobs.',
                              'معیار اور حفاظت کو یقینی بنانے کے لیے ورکرز کو شناختی کارڈ اور تجربہ سرٹیفکیٹ جمع کروانا ہوتا ہے۔',
                            ),
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Picture
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                          backgroundImage: _files.containsKey('profilePic') && _fileBytes['profilePic'] != null
                              ? MemoryImage(_fileBytes['profilePic']!) as ImageProvider
                              : (_existingProfilePicUrl.isNotEmpty ? NetworkImage(_existingProfilePicUrl) : null),
                          child: !_hasImage('profilePic')
                              ? const Icon(Icons.person, size: 48, color: Color(0xFF0D9488))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _pickImage('profilePic'),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF0D9488),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bilingual(context, 'Worker Profile Photo', 'ورکر پروفائل تصویر'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            bilingual(context, 'Required', 'لازمی'),
                            style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profession / Category Selection
              Text(
                bilingual(context, 'Skill Category', 'مہارت کا شعبہ'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory.toLowerCase() == cat['en']!.toLowerCase();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['en']!),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE6FFFA) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                cat['key'] == 'plumber' ? Icons.plumbing : Icons.electrical_services,
                                color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade600,
                                size: 26,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isUrdu ? cat['ur']! : cat['en']!,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF334155),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // CNIC Number Input
              Text(
                bilingual(context, 'CNIC Number (13 Digits)', 'شناختی کارڈ نمبر (13 ہندسے)'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                onChanged: (_) {
                  if (_cnicError != null) setState(() => _cnicError = null);
                },
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0D9488)),
                  hintText: '4220112345671',
                  errorText: _cnicError,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // CNIC Front Card
              _buildDocUploadCard(
                title: 'CNIC Front Side',
                titleUr: 'شناختی کارڈ سامنے کا حصہ',
                subtitle: 'Clear, glare-free picture of CNIC front side',
                subtitleUr: 'شناختی کارڈ کے سامنے کے رخ کی واضح تصویر',
                keyName: 'idFront',
                isRequired: true,
                existingUrl: _existingIdFrontUrl,
                icon: Icons.credit_card,
              ),

              // CNIC Back Card
              _buildDocUploadCard(
                title: 'CNIC Back Side',
                titleUr: 'شناختی کارڈ پچھلا حصہ',
                subtitle: 'Clear picture of CNIC back side showing address',
                subtitleUr: 'شناختی کارڈ کے پچھلے رخ کی واضح تصویر',
                keyName: 'idBack',
                isRequired: true,
                existingUrl: _existingIdBackUrl,
                icon: Icons.credit_card_outlined,
              ),

              // Certificates & Experience Letters Card (Optional)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: Color(0xFF0D9488), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bilingual(context, 'Certificates & Experience Letters', 'سرٹیفکیٹ اور تجربہ کے خطوط'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bilingual(context, 'Optional', 'اختیاری'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bilingual(
                        context,
                        'You can upload any certificate (such as an experience letter, skill training, diploma, trade license, or police clearance). Tap "+" to add more.',
                        'آپ کوئی بھی سرٹیفکیٹ جمع کروا سکتے ہیں جیسے تجربہ کا سرٹیفکیٹ، ٹریننگ ڈپلومہ یا پولیس کلیئرنس سرٹیفکیٹ۔ مزید شامل کرنے کے لیے + پر کلک کریں۔',
                      ),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Existing URLs
                        ...List.generate(_existingCertUrls.length, (idx) {
                          final url = _existingCertUrls[idx];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 95,
                                height: 95,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.description, color: Color(0xFF0D9488)),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _removeExistingCert(idx),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Doc #${idx + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        // New Files
                        ...List.generate(_newCertFiles.length, (idx) {
                          final bytes = _newCertBytes[idx];
                          final totalIdx = _existingCertUrls.length + idx + 1;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 95,
                                height: 95,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _removeNewCert(idx),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Doc #$totalIdx',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        // Add Button
                        InkWell(
                          onTap: _pickNewCert,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0D9488),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCCFBF1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF0D9488),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  bilingual(context, 'Add (+)', 'شامل کریں (+)'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    bilingual(context, 'Submit for Admin Verification', 'ایڈمن تصدیق کے لیے جمع کروائیں'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),

          // Uploading overlay
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF0D9488)),
                      const SizedBox(height: 20),
                      Text(
                        _submittingStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bilingual(context, 'Please wait...', 'براہ کرم انتظار کریں...'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
