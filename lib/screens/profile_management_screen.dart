import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_frontend/app_theme.dart';

import '../l10n/app_localizations.dart';
import '../services/cloudinary_service.dart';

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
  final Map<String, File> _selectedFiles = {};

  String _profilePicUrl = '';
  String _idFrontUrl = '';
  String _idBackUrl = '';
  String _policeCertUrl = '';
  String _certificationUrl = '';
  String _selectedCategory = 'Select a category';
  String _status = '';
  bool _isWorker = false;
  bool _isLoading = true;
  bool _isSaving = false;

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
        _certificationUrl = data['certificationUrl']?.toString() ?? '';
        _status = data['status']?.toString() ?? '';
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

    final file = File(image.path);
    final sizeInMb = file.lengthSync() / (1024 * 1024);
    if (sizeInMb > 5) {
      _showSnack(
        'Image size must be less than 5MB (current: ${sizeInMb.toStringAsFixed(1)}MB)',
        isError: true,
      );
      return;
    }

    setState(() => _selectedFiles[key] = file);
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

    setState(() => _isSaving = true);

    try {
      final profilePicUrl = await _uploadSelected('profilePicUrl', _profilePicUrl);
      final idFrontUrl = await _uploadSelected('idFrontUrl', _idFrontUrl);
      final idBackUrl = await _uploadSelected('idBackUrl', _idBackUrl);
      final policeCertUrl = await _uploadSelected('policeCertUrl', _policeCertUrl);
      final certificationUrl =
          await _uploadSelected('certificationUrl', _certificationUrl);

      if (_isWorker && (profilePicUrl == null || idFrontUrl == null || idBackUrl == null)) {
        _showSnack('Worker profile picture and CNIC images are required.', isError: true);
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
        if (certificationUrl != null) updates['certificationUrl'] = certificationUrl;
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
          _certificationUrl = certificationUrl ?? '';
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
    final selected = _selectedFiles['profilePicUrl'];
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
                  backgroundImage: selected != null
                      ? FileImage(selected)
                      : (_profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null)
                          as ImageProvider?,
                  child: selected == null && _profilePicUrl.isEmpty
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
                    ? Image.file(selected, fit: BoxFit.cover)
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
              const SizedBox(height: 24),
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
                      title: 'Police Character Certificate',
                      keyName: 'policeCertUrl',
                      currentUrl: _policeCertUrl,
                    ),
                    _documentTile(
                      title: 'Professional Certificate',
                      keyName: 'certificationUrl',
                      currentUrl: _certificationUrl,
                    ),
                  ],
                ),
              ],
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
