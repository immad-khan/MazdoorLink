import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_frontend/app_theme.dart';

import '../l10n/app_localizations.dart';
import '../services/cloudinary_service.dart';
import '../services/sms_service.dart';
import '../services/smtp_service.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _birthdayController = TextEditingController();

  late AnimationController _fadeController;

  final ImagePicker _picker = ImagePicker();
  final Map<String, XFile> _selectedFiles = {};
  final Map<String, Uint8List> _selectedFileBytes = {};

  String _profilePicUrl = '';
  String _idFrontUrl = '';
  String _idBackUrl = '';
  String _policeCertUrl = '';
  String _selectedCategory = 'Select a category';
  String _status = '';
  bool _isWorker = false;
  double _rating = 0.0;
  int _reviewsCount = 0;
  int _jobsCompleted = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String _notificationPreference = 'email';

  static const _categories = ['Select a category', 'Plumber', 'Electrician'];

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        final role = data['role']?.toString() ?? 'customer';
        _isWorker = role == 'worker';
        _notificationPreference = data['notificationPreference']?.toString() ??
            (data['otpVerifiedVia'] == 'phone' ? 'phone' : 'email');
        _nameController.text = data['name']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? user.email ?? '';
        _cnicController.text =
            data['cnicNumber']?.toString() ?? data['cnic']?.toString() ?? '';
        _birthdayController.text = data['birthday']?.toString() ?? '';
        _profilePicUrl =
            data['profilePicUrl']?.toString() ?? data['profileImage']?.toString() ?? '';
        _idFrontUrl = data['idFrontUrl']?.toString() ?? '';
        _idBackUrl = data['idBackUrl']?.toString() ?? '';
        _policeCertUrl = data['policeCertUrl']?.toString() ?? '';
        _status = data['status']?.toString() ?? '';
        _rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        _reviewsCount = (data['reviews'] as num?)?.toInt() ?? (data['ratingCount'] as num?)?.toInt() ?? 0;
        _jobsCompleted = (data['jobsCompleted'] as num?)?.toInt() ?? 0;
        _selectedCategory =
            data['categoryNameEn']?.toString() ?? _categoryKeyToName(data['category']?.toString());
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'Select a category';
        }
      }
    } catch (e) {
      _showSnack('Unable to load profile: $e', isError: true);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _birthdayController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _categoryKeyToName(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'plumber':
        return 'Plumber';
      case 'electrician':
        return 'Electrician';
      default:
        return 'Select a category';
    }
  }

  String _categoryNameToKey(String name) {
    switch (name.toLowerCase()) {
      case 'plumber':
        return 'plumber';
      case 'electrician':
        return 'electrician';
      default:
        return '';
    }
  }

  String _categoryNameUr(String name) {
    switch (name.toLowerCase()) {
      case 'plumber':
        return 'پلمبر';
      case 'electrician':
        return 'الیکٹریشن';
      default:
        return '';
    }
  }

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

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please log in again to update your profile.', isError: true);
      return;
    }

    final cnic = _cnicController.text.trim();
    if (cnic.isNotEmpty && !RegExp(r'^\d{13}$').hasMatch(cnic)) {
      _showSnack('Enter a valid 13-digit CNIC number.', isError: true);
      return;
    }

    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showSnack('Name and phone number are required.', isError: true);
      return;
    }

    if (_isWorker && _categoryNameToKey(_selectedCategory).isEmpty) {
      _showSnack('Please select a worker category.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profilePicUrl = await _uploadSelected('profilePicUrl', _profilePicUrl);
      final idFrontUrl = await _uploadSelected('idFrontUrl', _idFrontUrl);
      final idBackUrl = await _uploadSelected('idBackUrl', _idBackUrl);
      final policeCertUrl = await _uploadSelected('policeCertUrl', _policeCertUrl);
      if (_isWorker &&
          (profilePicUrl == null ||
              idFrontUrl == null ||
              idBackUrl == null)) {
        _showSnack('Worker profile picture and CNIC images are required.',
            isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_birthdayController.text.trim().isNotEmpty) {
        updates['birthday'] = _birthdayController.text.trim();
      }

      if (_isWorker) {
        final categoryKey = _categoryNameToKey(_selectedCategory);
        updates.addAll({
          'cnicNumber': cnic,
          'profilePicUrl': profilePicUrl,
          'profileImage': profilePicUrl,
          'idFrontUrl': idFrontUrl,
          'idBackUrl': idBackUrl,
          'category': categoryKey,
          'categoryNameEn': _selectedCategory,
          'categoryNameUr': _categoryNameUr(_selectedCategory),
        });
        if (policeCertUrl != null) updates['policeCertUrl'] = policeCertUrl;
      } else {
        updates['cnic'] = cnic;
        if (profilePicUrl != null) {
          updates['profilePicUrl'] = profilePicUrl;
          updates['profileImage'] = profilePicUrl;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

      if (mounted) {
        setState(() {
          _profilePicUrl = profilePicUrl ?? '';
          _idFrontUrl = idFrontUrl ?? '';
          _idBackUrl = idBackUrl ?? '';
          _policeCertUrl = policeCertUrl ?? '';
          _selectedFiles.clear();
        });
        _showSnack('Profile updated successfully');
      }
    } catch (e) {
      _showSnack('Error updating profile: $e', isError: true);
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.spacer),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
      ),
    );
  }

  Widget _imageHeader() {
    final selectedBytes = _selectedFileBytes['profilePicUrl'];
    final ImageProvider? avatarImage = selectedBytes != null
        ? MemoryImage(selectedBytes)
        : (_profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) as ImageProvider : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickFile('profilePicUrl'),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundImage: avatarImage,
                  child: selectedBytes == null && _profilePicUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 34)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Your Name',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _isWorker
                       ? 'Worker${_status.isNotEmpty ? ' - ${_status.toUpperCase()}' : ''}'
                      : 'Customer',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pickFile('profilePicUrl'),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required String title,
    required String keyName,
    required String currentUrl,
    bool requiredFile = false,
  }) {
    final selected = _selectedFiles[keyName];
    final hasExisting = currentUrl.isNotEmpty;
    final hasFile = selected != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: () => _pickFile(keyName),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasFile
                    ? Image.memory(_selectedFileBytes[keyName]!, fit: BoxFit.cover)
                    : hasExisting
                        ? Image.network(currentUrl, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      hasFile
                          ? 'New image selected'
                          : hasExisting
                              ? 'Uploaded. Tap to replace'
                              : requiredFile
                                  ? 'Required'
                                  : 'Optional',
                      style: TextStyle(
                        color: requiredFile && !hasExisting && !hasFile
                            ? Colors.redAccent
                            : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D9488)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
        ),
        items: _categories
            .map((category) => DropdownMenuItem(value: category, child: Text(category)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedCategory = value);
        },
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final parsed =
        _birthdayController.text.isNotEmpty ? DateTime.tryParse(_birthdayController.text) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthdayController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  String _getChannelSubtitle() {
    final pref = _notificationPreference.toLowerCase();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (pref == 'phone' || pref == 'sms') {
      return phone.isNotEmpty
          ? 'Reset via SMS OTP sent to $phone'
          : 'Reset via SMS OTP to phone';
    } else if (pref == 'both') {
      return 'Reset via OTP to both Phone (SMS) & Email';
    } else {
      return email.isNotEmpty
          ? 'Reset via OTP / link sent to $email'
          : 'Reset via link sent to email';
    }
  }

  Future<bool> _sendOtpToDestination({
    required String channel,
    required String otp,
    required String phone,
    required String email,
  }) async {
    final norm = channel.toLowerCase();
    bool success = false;

    if (norm == 'phone' || norm == 'sms') {
      if (phone.isEmpty) return false;
      success = await SmsService.sendOtp(phone, otp);
    } else if (norm == 'both') {
      bool sentSms = false;
      bool sentEmail = false;
      if (phone.isNotEmpty) {
        sentSms = await SmsService.sendOtp(phone, otp);
      }
      if (email.isNotEmpty) {
        sentEmail = await SmtpService.sendPasswordResetOTP(email, otp);
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        } catch (_) {}
      }
      success = sentSms || sentEmail;
    } else {
      if (email.isEmpty) return false;
      success = await SmtpService.sendPasswordResetOTP(email, otp);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        success = true;
      } catch (_) {}
    }

    return success;
  }

  Future<void> _startPasswordResetFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please log in again to change your password.', isError: true);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _notificationPreference = data['notificationPreference']?.toString() ??
              (data['otpVerifiedVia'] == 'phone' ? 'phone' : _notificationPreference);
        });
      }
    } catch (_) {}

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (user.email ?? '');

    final currentChannel = _notificationPreference.toLowerCase();
    if ((currentChannel == 'phone' || currentChannel == 'sms') && phone.isEmpty) {
      _showSnack('Please add and save a phone number to receive reset OTP via SMS.', isError: true);
      return;
    }
    if (currentChannel == 'email' && email.isEmpty) {
      _showSnack('No email address found for this account.', isError: true);
      return;
    }

    final random = math.Random();
    final activeOtp = (1000 + random.nextInt(9000)).toString();

    _showSnack(
      currentChannel == 'phone' || currentChannel == 'sms'
          ? 'Sending password reset OTP via SMS to $phone...'
          : currentChannel == 'both'
              ? 'Sending password reset OTP to both phone & email...'
              : 'Sending password reset OTP to $email...',
    );

    final sent = await _sendOtpToDestination(
      channel: currentChannel,
      otp: activeOtp,
      phone: phone,
      email: email,
    );

    if (!sent && mounted) {
      _showSnack(
        'Failed to deliver OTP. Please check your contact details and try again.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    _showChangePasswordModal(initialOtp: activeOtp, initialChannel: currentChannel);
  }

  void _showChangePasswordModal({
    required String initialOtp,
    required String initialChannel,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (user.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String activeOtp = initialOtp;
        String activeChannel = initialChannel;
        final otpController = TextEditingController();
        final newPasswordController = TextEditingController();
        final confirmPasswordController = TextEditingController();
        final currentPasswordController = TextEditingController();

        bool obscureNew = true;
        bool obscureConfirm = true;
        bool obscureCurrent = true;
        bool showCurrentPasswordField = false;
        bool isSubmitting = false;
        bool isResending = false;
        String? modalError;
        String? modalSuccess;

        return StatefulBuilder(
          builder: (context, setModalState) {
            String channelBannerText() {
              if (activeChannel == 'phone' || activeChannel == 'sms') {
                return 'A 4-digit password reset OTP has been sent via SMS to $phone';
              } else if (activeChannel == 'both') {
                return 'A 4-digit password reset OTP has been sent to $phone (SMS) and $email (Email)';
              } else {
                return 'A 4-digit password reset OTP and link have been sent to $email';
              }
            }

            Widget channelChip({
              required String label,
              required IconData icon,
              required String value,
            }) {
              final isSelected = activeChannel == value;
              final primary = Theme.of(context).primaryColor;
              return Expanded(
                child: InkWell(
                  onTap: isSubmitting || isResending
                      ? null
                      : () async {
                          if (activeChannel == value) return;
                          setModalState(() {
                            activeChannel = value;
                            isResending = true;
                            modalError = null;
                            modalSuccess = null;
                          });

                          // Update Firestore notification preference
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notificationPreference': value});
                            if (mounted) {
                              setState(() => _notificationPreference = value);
                            }
                          } catch (_) {}

                          final random = math.Random();
                          final newOtp = (1000 + random.nextInt(9000)).toString();
                          final sent = await _sendOtpToDestination(
                            channel: value,
                            otp: newOtp,
                            phone: phone,
                            email: email,
                          );

                          setModalState(() {
                            isResending = false;
                            if (sent) {
                              activeOtp = newOtp;
                              otpController.clear();
                              modalSuccess = 'New OTP sent via ${value == 'phone' ? 'SMS' : value == 'both' ? 'Both SMS & Email' : 'Email'}';
                            } else {
                              modalError = 'Failed to deliver OTP to selected channel.';
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? primary : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.darkerText),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.darkerText,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkerText,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Delivery channel selector
                    const Text(
                      'Delivery Channel:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        channelChip(
                          label: 'Number (SMS)',
                          icon: Icons.sms_outlined,
                          value: 'phone',
                        ),
                        const SizedBox(width: 8),
                        channelChip(
                          label: 'Email',
                          icon: Icons.email_outlined,
                          value: 'email',
                        ),
                        const SizedBox(width: 8),
                        channelChip(
                          label: 'Both',
                          icon: Icons.all_inclusive,
                          value: 'both',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Informational banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            activeChannel == 'phone' || activeChannel == 'sms'
                                ? Icons.sms_outlined
                                : activeChannel == 'both'
                                    ? Icons.all_inclusive
                                    : Icons.email_outlined,
                            color: const Color(0xFF16A34A),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              channelBannerText(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // OTP input
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter 4-Digit OTP',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        suffixIcon: TextButton(
                          onPressed: isResending
                              ? null
                              : () async {
                                  setModalState(() {
                                    isResending = true;
                                    modalError = null;
                                    modalSuccess = null;
                                  });
                                  final random = math.Random();
                                  final newOtp = (1000 + random.nextInt(9000)).toString();
                                  final sent = await _sendOtpToDestination(
                                    channel: activeChannel,
                                    otp: newOtp,
                                    phone: phone,
                                    email: email,
                                  );
                                  setModalState(() {
                                    isResending = false;
                                    if (sent) {
                                      activeOtp = newOtp;
                                      modalSuccess = 'Verification code resent successfully!';
                                    } else {
                                      modalError = 'Failed to resend code. Please try again.';
                                    }
                                  });
                                },
                          child: isResending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Resend'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // New Password field
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm New Password field
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),

                    if (showCurrentPasswordField) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password (Required for confirmation)',
                          prefixIcon: const Icon(Icons.security),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                      ),
                    ],

                    if (modalError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (modalSuccess != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalSuccess!,
                                style: const TextStyle(color: Color(0xFF166534), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final enteredOtp = otpController.text.trim();
                                if (enteredOtp.length != 4) {
                                  setModalState(() {
                                    modalError = 'Please enter the 4-digit verification code.';
                                  });
                                  return;
                                }

                                if (enteredOtp != activeOtp) {
                                  setModalState(() {
                                    modalError = 'Invalid verification code. Please check your SMS/email.';
                                  });
                                  return;
                                }

                                final newPass = newPasswordController.text;
                                final confirmPass = confirmPasswordController.text;

                                if (newPass.length < 6) {
                                  setModalState(() {
                                    modalError = 'New password must be at least 6 characters.';
                                  });
                                  return;
                                }

                                if (newPass != confirmPass) {
                                  setModalState(() {
                                    modalError = 'Passwords do not match.';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                  modalError = null;
                                  modalSuccess = null;
                                });

                                try {
                                  if (showCurrentPasswordField && currentPasswordController.text.isNotEmpty) {
                                    final emailForAuth = user.email ?? email;
                                    if (emailForAuth.isNotEmpty) {
                                      final cred = EmailAuthProvider.credential(
                                        email: emailForAuth,
                                        password: currentPasswordController.text.trim(),
                                      );
                                      await user.reauthenticateWithCredential(cred);
                                    }
                                  }

                                  await user.updatePassword(newPass);

                                  if (bottomSheetContext.mounted) {
                                    Navigator.pop(bottomSheetContext);
                                  }
                                  _showSnack('Password updated successfully!');
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'requires-recent-login') {
                                    setModalState(() {
                                      isSubmitting = false;
                                      showCurrentPasswordField = true;
                                      modalError = 'Recent login required. Please enter your current password to confirm.';
                                    });
                                  } else {
                                    setModalState(() {
                                      isSubmitting = false;
                                      modalError = e.message ?? 'Failed to update password.';
                                    });
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    modalError = 'Error updating password: $e';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.mail_outline, size: 16),
                        label: const Text(
                          'Send password reset link to email instead',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          if (email.isEmpty) {
                            setModalState(() {
                              modalError = 'No email associated with this account.';
                            });
                            return;
                          }
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            if (bottomSheetContext.mounted) {
                              Navigator.pop(bottomSheetContext);
                            }
                            _showSnack('Password reset email sent to $email');
                          } catch (e) {
                            setModalState(() {
                              modalError = 'Error sending email: $e';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.t('profile_management'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          t.t('profile_management'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageHeader(),
              if (_isWorker) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                              const SizedBox(width: 4),
                              Text(
                                _rating > 0 ? _rating.toStringAsFixed(1) : 'New',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
                      Column(
                        children: [
                          Text(
                            '$_reviewsCount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
                      Column(
                        children: [
                          Text(
                            '$_jobsCompleted',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _section(
                'SIGN UP DETAILS',
                [
                  _field(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  _field(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    hintText: 'Email is tied to login',
                  ),
                  _field(
                    controller: _phoneController,
                    label: 'Mobile Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    controller: _cnicController,
                    label: 'CNIC Number',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 13,
                  ),
                  _field(
                    controller: _birthdayController,
                    label: 'Date of Birth',
                    icon: Icons.cake_outlined,
                    readOnly: true,
                    onTap: _pickBirthday,
                    hintText: 'YYYY-MM-DD',
                  ),
                  if (_isWorker) _categoryDropdown(),
                ],
              ),
              if (_isWorker) ...[
                const SizedBox(height: 24),
                _section(
                  'WORKER DOCUMENTS',
                  [
                    _documentTile(
                      title: 'Profile Picture',
                      keyName: 'profilePicUrl',
                      currentUrl: _profilePicUrl,
                      requiredFile: true,
                    ),
                    _documentTile(
                      title: 'CNIC Front Image',
                      keyName: 'idFrontUrl',
                      currentUrl: _idFrontUrl,
                      requiredFile: true,
                    ),
                    _documentTile(
                      title: 'CNIC Back Image',
                      keyName: 'idBackUrl',
                      currentUrl: _idBackUrl,
                      requiredFile: true,
                    ),
                    _documentTile(
                      title: 'Certificate / Experience Letter',
                      keyName: 'policeCertUrl',
                      currentUrl: _policeCertUrl,
                      requiredFile: false,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _section(
                'ACCOUNT SECURITY',
                [
                  ListTile(
                    leading: Icon(Icons.lock_reset, color: Theme.of(context).primaryColor),
                    title: const Text('Change Password'),
                    subtitle: Text(_getChannelSubtitle()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _notificationPreference == 'phone' || _notificationPreference == 'sms'
                                    ? Icons.sms_outlined
                                    : _notificationPreference == 'both'
                                        ? Icons.all_inclusive
                                        : Icons.email_outlined,
                                size: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _notificationPreference == 'phone' || _notificationPreference == 'sms'
                                    ? 'SMS'
                                    : _notificationPreference == 'both'
                                        ? 'Both'
                                        : 'Email',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _startPasswordResetFlow,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Updating...' : t.t('update_profile'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
