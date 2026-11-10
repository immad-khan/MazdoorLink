import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../services/cloudinary_service.dart';
import '../services/location_service.dart';
import '../services/voice_assistant_service.dart';
import '../services/sms_service.dart';
import '../services/smtp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes;
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.isSignup});

  final bool isSignup;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}$",
  );

  String? _emailError;
  String? _passwordError;
  String? _nameError;
  String? _phoneError;
  String? _confirmPasswordError;
  String? _idFrontError;
  String? _idBackError;
  String? _imageSizeError;
  String? _profilePicError;
  String? _cnicError;
  String? _categoryError;

  // Password strength tracking
  bool _pwHasMinLength = false;
  bool _pwHasUppercase = false;
  bool _pwHasDigit = false;
  bool _pwHasSpecial = false;

  bool _isValidEmail(String email) => _emailRegex.hasMatch(email);

  String? _emailValidationMessage(String email) {
    if (email.isEmpty) return 'Email is required';
    return _isValidEmail(email) ? null : 'Enter a valid email address';
  }

  void _validateEmail(String val) {
    final email = val.trim();
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    setState(() {
      _emailError = _emailValidationMessage(email);
    });
  }

  bool _isPhoneLike(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 13;
  }

  String? _loginIdValidationMessage(String value) {
    if (value.isEmpty) return 'Email or mobile number is required';
    if (_isValidEmail(value)) return null;
    if (_isPhoneLike(value)) return null;
    return 'Enter a valid email or 10-digit mobile number';
  }

  void _validateLoginId(String val) {
    final value = val.trim();
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    setState(() {
      _emailError = _loginIdValidationMessage(value);
    });
  }

  Future<List<String>> _resolveEmailsByPhone(String input) async {
    final rawTrimmed = input.trim();
    String digits = rawTrimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    // `digits` is the normalized 10-digit number (e.g. 3001234567)
    final candidates = <String>{
      rawTrimmed,
      digits,
      '0$digits',
      '+92$digits',
      '+92 $digits',
      '92$digits',
    };
    if (digits.length >= 7) {
      final prefix = digits.substring(0, 3);
      final rest = digits.substring(3);
      candidates.add('0$prefix $rest');
      candidates.add('0$prefix-$rest');
      candidates.add('+92 $prefix $rest');
      candidates.add('+92-$prefix-$rest');
    }

    final emails = <String>{};
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      try {
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: candidate)
            .get();
        for (final doc in qs.docs) {
          final email = doc.data()['email']?.toString().trim();
          if (email != null && email.isNotEmpty) {
            emails.add(email);
          }
        }
      } catch (e) {
        debugPrint('Candidate query failed for "$candidate": $e');
      }
    }
    return emails.toList();
  }

  void _validatePassword(String val) {
    setState(() {
      _pwHasMinLength = val.length >= 8;
      _pwHasUppercase = val.contains(RegExp(r'[A-Z]'));
      _pwHasDigit = val.contains(RegExp(r'[0-9]'));
      _pwHasSpecial = val.contains(RegExp(r'[!@#\$%^&*(),.?":{}<>]'));
      _passwordError = null;
    });
  }

  bool _validatePasswordFields() {
    setState(() {
      _pwHasMinLength = _password.text.length >= 8;
      _pwHasUppercase = _password.text.contains(RegExp(r'[A-Z]'));
      _pwHasDigit = _password.text.contains(RegExp(r'[0-9]'));
      _pwHasSpecial = _password.text.contains(
        RegExp(r'[!@#\$%^&*(),.?":{}<>]'),
      );
      if (_password.text.isEmpty) {
        _passwordError = 'Password is required';
      } else if (!_pwHasMinLength ||
          !_pwHasUppercase ||
          !_pwHasDigit ||
          !_pwHasSpecial) {
        _passwordError = 'Password does not meet requirements';
      } else {
        _passwordError = null;
      }
      _confirmPasswordError = _confirmPassword.text.isEmpty
          ? 'Please confirm your password'
          : (_password.text != _confirmPassword.text
                ? 'Passwords must match'
                : null);
    });
    return _passwordError == null && _confirmPasswordError == null;
  }

  void _validateSignupFields() {
    final role = AppScope.of(context).role;
    setState(() {
      _nameError = _fullNameController.text.trim().isEmpty
          ? 'Full name is required'
          : null;
      _emailError = _emailValidationMessage(_emailController.text.trim());
      final rawPhone = _phone.text.trim();
      final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
      final national = (digits.startsWith('92') && digits.length > 10)
          ? digits.substring(2)
          : (digits.startsWith('0') ? digits.substring(1) : digits);
      _phoneError = rawPhone.isEmpty
          ? 'Mobile number is required'
          : (national.length == 10
                ? null
                : 'Enter a valid 10-digit mobile number');
      if (_password.text.isEmpty) {
        _passwordError = 'Password is required';
      } else {
        _pwHasMinLength = _password.text.length >= 8;
        _pwHasUppercase = _password.text.contains(RegExp(r'[A-Z]'));
        _pwHasDigit = _password.text.contains(RegExp(r'[0-9]'));
        _pwHasSpecial = _password.text.contains(
          RegExp(r'[!@#\$%^&*(),.?":{}<>]'),
        );

        if (!_pwHasMinLength ||
            !_pwHasUppercase ||
            !_pwHasDigit ||
            !_pwHasSpecial) {
          _passwordError = 'Password does not meet requirements';
        } else {
          _passwordError = null;
        }
      }
      _confirmPasswordError = _confirmPassword.text.isEmpty
          ? 'Please confirm your password'
          : (_password.text != _confirmPassword.text
                ? 'Passwords must match'
                : null);
      final cnic = _cnicController.text.trim();
      _cnicError = !RegExp(r'^\d{13}$').hasMatch(cnic)
          ? 'Enter a valid 13-digit CNIC'
          : null;
      if (role == UserRole.worker) {
        _categoryError = _selectedCategory == 'Select a category'
            ? 'Please select a worker category'
            : null;
        _profilePicError = _profilePicFile == null
            ? 'Profile picture is required'
            : null;
        _idFrontError = _idFrontImage == null
            ? 'Front CNIC image is required'
            : null;
        _idBackError = _idBackImage == null
            ? 'Back CNIC image is required'
            : null;
      } else {
        _categoryError = null;
      }
    });
  }

  final _phone = TextEditingController();
  final _emailController = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpNodes = List.generate(4, (_) => FocusNode());
  int step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isForgotPassword = false;
  String _selectedCategory = 'Select a category';
  String? _generatedOtp;
  String _selectedOtpMethod = 'email'; // 'email' or 'phone'

  Future<bool> _dispatchOtp(String method) async {
    final random = math.Random();
    _generatedOtp = (1000 + random.nextInt(9000)).toString();

    if (method == 'email') {
      final email = _emailController.text.trim();
      return await SmtpService.sendOTP(email, _generatedOtp!);
    } else {
      final phone = '+92${_phone.text.trim()}';
      return await SmsService.sendOtp(phone, _generatedOtp!);
    }
  }

  Future<String?> _showOtpMethodDialog() async {
    String tempSelected = _selectedOtpMethod;
    final isUrdu = AppScope.of(context).isUrdu;
    final formattedPhone = '+92 ${_phone.text.trim()}';
    final email = _emailController.text.trim();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0D9488),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu
                                  ? 'او ٹی پی تصدیق کا طریقہ'
                                  : 'Verify Your Account',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUrdu
                                  ? 'اکاؤنٹ بنانے سے پہلے او ٹی پی کہاں بھیجا جائے؟'
                                  : 'Where should we send your verification OTP?',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Option 1: Email
                  _buildOtpOptionCard(
                    title: isUrdu ? 'ای میل پر او ٹی پی' : 'Send to Email',
                    subtitle: email,
                    note: isUrdu
                        ? 'آپ کے ای میل ان باکس میں 4 ہندسوں کا کوڈ آئے گا'
                        : 'A 4-digit code will be sent to your inbox',
                    icon: Icons.email_outlined,
                    isSelected: tempSelected == 'email',
                    onTap: () => setModalState(() => tempSelected = 'email'),
                  ),
                  const SizedBox(height: 12),
                  // Option 2: Mobile Number
                  _buildOtpOptionCard(
                    title: isUrdu
                        ? 'موبائل نمبر (ایس ایم ایس)'
                        : 'Send to Mobile Number (SMS)',
                    subtitle: formattedPhone,
                    note: isUrdu
                        ? 'آپ کے نمبر پر 4 ہندسوں کا ایس ایم ایس آئے گا'
                        : 'A 4-digit code will be sent via SMS',
                    icon: Icons.sms_outlined,
                    isSelected: tempSelected == 'phone',
                    onTap: () => setModalState(() => tempSelected = 'phone'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, tempSelected),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isUrdu ? 'او ٹی پی بھیجیں' : 'Send Verification OTP',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text(
                        isUrdu ? 'منسوخ کریں' : 'Cancel',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOtpOptionCard({
    required String title,
    required String subtitle,
    required String note,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D9488)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: const Color(0xFF0D9488),
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorPopup(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  XFile? _idFrontImage;
  XFile? _idBackImage;
  XFile? _profilePicFile; // Optional for worker
  final List<XFile> _certificateFiles = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('remembered_email') ?? '';
      final password = prefs.getString('remembered_password') ?? '';
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _emailController.text = email;
          _password.text = password;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final sizeInKb = bytes.length / 1024;
      if (sizeInKb > 100) {
        setState(() {
          _imageSizeError =
              'Image size must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)';
        });
        return;
      }
      setState(() {
        _imageSizeError = null;
        if (isFront) {
          _idFrontImage = image;
          _idFrontError = null;
        } else {
          _idBackImage = image;
          _idBackError = null;
        }
      });
    }
  }

  Future<void> _pickProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final sizeInKb = bytes.length / 1024;
      if (sizeInKb > 100) {
        setState(
          () => _imageSizeError =
              'Profile picture must be less than 100KB (current: ${sizeInKb.toStringAsFixed(0)}KB)',
        );
        return;
      }
      setState(() {
        _profilePicFile = image;
        _profilePicError = null;
        _imageSizeError = null;
      });
    }
  }

  Future<void> _pickCertificate() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final sizeInMb = bytes.length / (1024 * 1024);
      if (sizeInMb > 5) {
        setState(
          () => _imageSizeError =
              'Certificate image must be less than 5MB (current: ${sizeInMb.toStringAsFixed(1)}MB)',
        );
        return;
      }
      setState(() {
        _certificateFiles.add(image);
        _imageSizeError = null;
      });
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificateFiles.removeAt(index);
    });
  }

  String _formatCnic(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  Future<String?> _uploadToCloudinary(XFile imageFile) async {
    return CloudinaryService.uploadImage(imageFile);
  }

  @override
  void dispose() {
    _phone.dispose();
    _emailController.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullNameController.dispose();
    _cnicController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (_isForgotPassword) {
      if (step == 0) {
        if (_selectedOtpMethod == 'email') {
          final email = _emailController.text.trim();
          setState(() {
            _emailError = _emailValidationMessage(email);
          });
          if (_emailError != null) {
            showToast('Please enter a valid email address');
            return;
          }
        } else {
          final phone = _phone.text.trim();
          if (phone.isEmpty || phone.length < 10) {
            setState(() => _phoneError = 'Enter a valid 10-digit phone number');
            showToast('Please enter a valid phone number');
            return;
          } else {
            setState(() => _phoneError = null);
          }
          // Look up the account's email by phone number in Firestore
          try {
            final emails = await _resolveEmailsByPhone(phone);
            if (emails.isEmpty) {
              showToast('No account found with this phone number.');
              return;
            }
            _emailController.text = emails.first;
          } catch (e) {
            showToast('Error looking up account: ${e.toString()}');
            return;
          }
        }
        try {
          final random = math.Random();
          _generatedOtp = (1000 + random.nextInt(9000)).toString();
          final bool sent;
          if (_selectedOtpMethod == 'email') {
            sent = await SmtpService.sendPasswordResetOTP(
              _emailController.text.trim(),
              _generatedOtp!,
            );
          } else {
            sent = await SmsService.sendOtp(
              '+92${_phone.text.trim()}',
              _generatedOtp!,
            );
          }
          if (!sent) {
            showToast(
              _selectedOtpMethod == 'email'
                  ? 'Failed to send reset code via email. Try again.'
                  : 'Failed to send reset code via SMS. Try again.',
            );
            return;
          }
          setState(() {
            step = 1;
            for (final c in _otpControllers) {
              c.clear();
            }
          });
          showToast(
            _selectedOtpMethod == 'email'
                ? 'Password reset code sent to your email!'
                : 'Password reset code sent via SMS!',
          );
        } catch (e) {
          showToast(e.toString());
        }
        return;
      } else if (step == 1) {
        final enteredOtp = _otpControllers.map((c) => c.text).join();
        if (enteredOtp.length != 4 || enteredOtp != _generatedOtp) {
          showToast('Invalid OTP. Please try again.');
          return;
        }
        setState(() {
          step = 2;
          _password.clear();
          _confirmPassword.clear();
          _passwordError = null;
          _confirmPasswordError = null;
        });
        return;
      } else if (step == 2) {
        if (!_validatePasswordFields()) {
          showToast('Please enter a valid password and confirmation.');
          return;
        }
        final email = _emailController.text.trim();
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email == email) {
            await user.updatePassword(_password.text);
            await FirebaseAuth.instance.signOut();
            showToast('Password reset successfully. Please log in again.');
          } else {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            showToast(
              'OTP verified. Check your email to finish resetting your Firebase password.',
            );
          }
          setState(() {
            _isForgotPassword = false;
            step = 0;
            _emailController.clear();
            _password.clear();
            _confirmPassword.clear();
            _generatedOtp = null;
            for (final c in _otpControllers) {
              c.clear();
            }
          });
        } catch (e) {
          showToast(e.toString());
        }
        return;
      }
    }

    if (widget.isSignup) {
      if (step == 0) {
        _validateSignupFields();
        final role = AppScope.of(context).role;
        if (_nameError != null ||
            _emailError != null ||
            _phoneError != null ||
            _passwordError != null ||
            _confirmPasswordError != null ||
            _cnicError != null) {
          showToast('Please fill all required fields correctly');
          return;
        }
        if (role == UserRole.worker &&
            (_categoryError != null ||
                _profilePicError != null ||
                _idFrontError != null ||
                _idBackError != null)) {
          showToast('Please fill all worker required fields');
          return;
        }

        // Ask user where to send the OTP (Email or Mobile Number)
        final selectedMethod = await _showOtpMethodDialog();
        if (selectedMethod == null) {
          // User closed or cancelled selection modal
          return;
        }
        _selectedOtpMethod = selectedMethod;

        setState(() => _isUploading = true);

        final sent = await _dispatchOtp(_selectedOtpMethod);

        setState(() => _isUploading = false);

        if (!sent) {
          if (mounted) {
            showToast(
              _selectedOtpMethod == 'email'
                  ? 'Failed to send verification email. Try again.'
                  : 'Failed to send SMS OTP. Please try again or choose email.',
            );
          }
          return;
        }

        if (mounted) {
          for (final c in _otpControllers) {
            c.clear();
          }
          if (_selectedOtpMethod == 'email') {
            showToast(
              'Verification code sent to ${_emailController.text.trim()}',
            );
          } else {
            showToast(
              'Verification code sent via SMS to +92 ${_phone.text.trim()}',
            );
          }
          setState(() {
            step = 1;
          });
        }
        return;
      } else if (step == 1) {
        setState(() => _isUploading = true);

        final enteredOtp = _otpControllers.map((c) => c.text).join();
        if (enteredOtp != _generatedOtp) {
          setState(() => _isUploading = false);
          if (mounted) showToast('Invalid OTP. Please try again.');
          return;
        }

        try {
          String? frontUrl;
          String? backUrl;
          String? profilePicUrl;
          final role = AppScope.of(context).role;

          if (role == UserRole.worker) {
            frontUrl = await _uploadToCloudinary(_idFrontImage!);
            backUrl = await _uploadToCloudinary(_idBackImage!);
            if (frontUrl == null || backUrl == null) {
              setState(() => _isUploading = false);
              if (mounted)
                showToast('Failed to upload CNIC images. Try again.');
              return;
            }
            if (_profilePicFile != null) {
              profilePicUrl = await _uploadToCloudinary(_profilePicFile!);
            }

            final List<String> certUrls = [];
            for (final certFile in _certificateFiles) {
              final url = await _uploadToCloudinary(certFile);
              if (url != null && url.isNotEmpty) {
                certUrls.add(url);
              }
            }
            setState(() => _isUploading = false);

            final userCredential = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _password.text,
                );

            final categoryKey = _selectedCategory.toLowerCase();
            final categoryNameUr = categoryKey == 'plumber'
                ? 'پلمبر'
                : 'الیکٹریشن';

            final userData = <String, dynamic>{
              'name': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phone.text.trim(),
              'cnicNumber': _cnicController.text.trim(),
              'role': 'worker',
              'roles': ['worker'],
              'workerStatus': 'pending',
              'status': 'pending',
              'otpVerifiedVia': _selectedOtpMethod,
              'createdAt': FieldValue.serverTimestamp(),
              'idFrontUrl': frontUrl,
              'idBackUrl': backUrl,
              'category': categoryKey,
              'categoryNameEn': _selectedCategory,
              'categoryNameUr': categoryNameUr,
              'skills': [],
              'setupComplete': false,
              'latitude': LocationService.instance.currentLocation.latitude,
              'longitude': LocationService.instance.currentLocation.longitude,
              'city': LocationService.instance.currentLocation.city,
              'area': LocationService.instance.currentLocation.area,
              'locationAddress':
                  LocationService.instance.currentLocation.fullAddress,
              'isInsideTwinCities':
                  LocationService.instance.currentLocation.isInsideTwinCities,
            };
            if (profilePicUrl != null) {
              userData['profilePicUrl'] = profilePicUrl;
            }
            if (certUrls.isNotEmpty) {
              userData['certificates'] = certUrls;
              userData['certificationUrl'] = certUrls.first;
              userData['policeCertUrl'] = certUrls.first;
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(userData);

            await FirebaseAuth.instance.signOut();

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDCFCE7),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: Color(0xFF059669),
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Registration Submitted!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your profile is under admin review. You can log in once your account is approved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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

          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
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
            'latitude': LocationService.instance.currentLocation.latitude,
            'longitude': LocationService.instance.currentLocation.longitude,
            'city': LocationService.instance.currentLocation.city,
            'area': LocationService.instance.currentLocation.area,
            'locationAddress':
                LocationService.instance.currentLocation.fullAddress,
            'isInsideTwinCities':
                LocationService.instance.currentLocation.isInsideTwinCities,
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          setState(() => _isUploading = false);

          await FirebaseAuth.instance.signOut();

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDCFCE7),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFF059669),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Registration Submitted!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your account has been created successfully. You can now log in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
        } catch (e) {
          setState(() => _isUploading = false);
          if (mounted) {
            showToast(e.toString());
          }
          return;
        }
      }
    } else {
      // Login flow
      final loginId = _emailController.text.trim();
      final password = _password.text;
      setState(() {
        _emailError = _loginIdValidationMessage(loginId);
        _passwordError = password.isEmpty ? 'Password is required' : null;
      });
      if (_emailError != null || _passwordError != null) {
        _showErrorPopup(
          bilingual(context, 'Missing Credentials', 'معلومات درکار ہے'),
          bilingual(
            context,
            'Please enter your email or mobile number and password.',
            'براہ کرم اپنا ای میل یا موبائل نمبر اور پاس ورڈ درج کریں۔',
          ),
        );
        return;
      }

      List<String> targetEmails = [];
      if (_isValidEmail(loginId)) {
        targetEmails = [loginId];
      } else {
        setState(() => _isUploading = true);
        targetEmails = await _resolveEmailsByPhone(loginId);
        setState(() => _isUploading = false);
        if (targetEmails.isEmpty) {
          if (mounted) {
            _showErrorPopup(
              bilingual(context, 'Account Not Found', 'اکاؤنٹ نہیں ملا'),
              bilingual(
                context,
                'No account was found with this mobile number. Please check the number or sign up.',
                'اس موبائل نمبر سے کوئی اکاؤنٹ نہیں ملا۔ نمبر درست کریں یا نیا اکاؤنٹ بنائیں۔',
              ),
            );
          }
          return;
        }
      }

      setState(() => _isUploading = true);
      UserCredential? userCredential;
      dynamic lastAuthError;

      for (final email in targetEmails) {
        try {
          userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          if (userCredential.user != null) {
            break;
          }
        } catch (e) {
          lastAuthError = e;
        }
      }

      setState(() => _isUploading = false);

      if (userCredential == null || userCredential.user == null) {
        if (mounted) {
          final msg = (lastAuthError?.toString() ?? '').toLowerCase();
          String title = bilingual(context, 'Login Failed', 'لاگ ان ناکام');
          String friendlyMsg;
          if (msg.contains('invalid-credential') ||
              msg.contains('invalid_credential') ||
              msg.contains('wrong-password') ||
              msg.contains('password is invalid') ||
              msg.contains('user-not-found') ||
              msg.contains('no user record')) {
            friendlyMsg = bilingual(
              context,
              'Invalid email/mobile number or password. Please check your credentials and try again.',
              'غلط ای میل / موبائل نمبر یا پاس ورڈ۔ براہ کرم دوبارہ کوشش کریں۔',
            );
          } else if (msg.contains('too-many-requests')) {
            title = bilingual(context, 'Too Many Attempts', 'بہت زیادہ کوششیں');
            friendlyMsg = bilingual(
              context,
              'Too many failed login attempts. Please wait a few minutes and try again.',
              'لاگ ان کی ناکام کوششیں زیادہ ہو گئیں۔ براہ کرم چند منٹ بعد کوشش کریں۔',
            );
          } else if (msg.contains('network-request-failed')) {
            title = bilingual(context, 'Network Error', 'انٹرنیٹ مسئلہ');
            friendlyMsg = bilingual(
              context,
              'Unable to connect to the server. Please check your internet connection.',
              'سرور سے رابطہ ممکن نہیں۔ انٹرنیٹ کنکشن چیک کریں۔',
            );
          } else {
            friendlyMsg = bilingual(
              context,
              'Login failed: ${lastAuthError?.toString() ?? "Check your credentials"}',
              'لاگ ان ناکام: اپنی معلومات چیک کریں۔',
            );
          }
          _showErrorPopup(title, friendlyMsg);
        }
        return;
      }

      try {
        // Fetch user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (doc.exists && mounted) {
          if (_rememberMe) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'remembered_email',
              _emailController.text.trim(),
            );
            await prefs.setString('remembered_password', password);
          }
          final data = doc.data()!;
          final firestoreRole = data['role']?.toString() ?? 'customer';
          final roles =
              (data['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final hasWorkerAccess =
              firestoreRole == 'worker' || roles.contains('worker');
          final workerStatus =
              data['workerStatus']?.toString() ?? data['status']?.toString();
          final targetRole = AppScope.of(context).role ?? UserRole.customer;

          // ── Case 1: Logging in as Customer ──────────────────────────────
          // A registered worker CAN login as customer directly!
          if (targetRole == UserRole.customer) {
            AppScope.of(context).selectRole(UserRole.customer);
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.customerHome,
              (route) => false,
            );
            return;
          }

          // ── Case 2: Logging in as Worker ────────────────────────────────
          if (targetRole == UserRole.worker) {
            if (!hasWorkerAccess) {
              // Registered customer trying to login as worker without worker profile
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bilingual(
                              context,
                              'Worker Verification Required',
                              'ورکر تصدیق درکار ہے',
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      bilingual(
                        context,
                        'You are registered as a Customer. To login as a Worker, you must complete worker verification (CNIC, optional experience/certificates, and skills) and be approved by admin.\\n\\nYou can continue as a Customer or submit worker registration.',
                        'آپ کسٹمر کے طور پر رجسٹرڈ ہیں۔ ورکر لاگ ان کے لیے شناختی کارڈ، سرٹیفکیٹ/تجربہ اور مہارت کی ایڈمن منظوری درکار ہے۔\\n\\nآپ کسٹمر کے طور پر جاری رکھ سکتے ہیں۔',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(bilingual(context, 'Cancel', 'منسوخ')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          AppScope.of(context).selectRole(UserRole.customer);
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.customerHome,
                          );
                        },
                        child: Text(
                          bilingual(
                            context,
                            'Continue as Customer',
                            'گاہک کے طور پر جاری رکھیں',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return;
            }

            if (workerStatus == 'pending') {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bilingual(
                              context,
                              'Application Pending',
                              'درخواست زیر جائزہ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      bilingual(
                        context,
                        'Your worker verification request is under admin review. You can log in as a Worker once approved.\\n\\nIn the meantime, you can continue using MazdoorLink as a Customer.',
                        'آپ کی ورکر تصدیقی درخواست ایڈمن کے جائزے میں ہے۔ منظوری پر آپ ورکر لاگ ان کر سکیں گے۔\\n\\nاس دوران آپ کسٹمر کے طور پر ایپ استعمال کر سکتے ہیں۔',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text(bilingual(context, 'OK', 'ٹھیک ہے')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          AppScope.of(context).selectRole(UserRole.customer);
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.customerHome,
                          );
                        },
                        child: Text(
                          bilingual(
                            context,
                            'Continue as Customer',
                            'گاہک کے طور پر جاری رکھیں',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return;
            } else if (workerStatus == 'rejected') {
              if (mounted) {
                final reason = data['rejectReason'] ?? 'Documents not verified';
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bilingual(
                              context,
                              'Worker Application Rejected',
                              'ورکر درخواست مسترد',
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      bilingual(
                        context,
                        'Your worker application was rejected by admin.\nReason: $reason\n\nYou can continue as a Customer or update your verification documents.',
                        'ایڈمن کی جانب سے آپ کی ورکر درخواست مسترد ہو گئی ہے۔\nوجہ: $reason\n\nآپ کسٹمر کے طور پر جاری رکھ سکتے ہیں یا دستاویزات درست کریں۔',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text(bilingual(context, 'OK', 'ٹھیک ہے')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          AppScope.of(context).selectRole(UserRole.customer);
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.customerHome,
                          );
                        },
                        child: Text(
                          bilingual(
                            context,
                            'Continue as Customer',
                            'گاہک کے طور پر جاری رکھیں',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return;
            }

            // Approved worker
            final setupComplete = data['setupComplete'] as bool? ?? false;
            AppScope.of(context).selectRole(UserRole.worker);
            if (!setupComplete) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.workerServicesSetup,
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.workerDashboard,
                (route) => false,
              );
            }
            return;
          }
        } else if (mounted) {
          // Default fallback
          AppScope.of(context).selectRole(UserRole.customer);
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.customerHome,
            (route) => false,
          );
        }
        return;
      } catch (e) {
        if (mounted) {
          _showErrorPopup(
            bilingual(context, 'Profile Error', 'پروفائل خرابی'),
            bilingual(
              context,
              'Error loading user profile: ${e.toString()}',
              'پروفائل لوڈ کرنے میں خرابی: ${e.toString()}',
            ),
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !(_isForgotPassword && step > 0) && !(widget.isSignup && step > 0),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isForgotPassword && step > 0) {
          setState(() => step--);
        } else if (widget.isSignup && step > 0) {
          setState(() => step = 0);
        }
      },
      child: MzScaffold(
        enableExitPopScope: false,
        showBottomNav: false,
        showBack: true,
        title: (_isForgotPassword)
            ? 'Reset Password'
            : (widget.isSignup
                  ? (step == 0 ? 'Sign up' : 'Verification')
                  : 'Login'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: (_isForgotPassword)
                  ? _forgotPasswordFlow()
                  : (widget.isSignup ? _signupFlow() : _loginScreen()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _forgotPasswordFlow() {
    final title = step == 0
        ? 'Reset password'
        : step == 1
        ? 'Enter OTP'
        : 'Create new password';
    final otpTarget = _selectedOtpMethod == 'email'
        ? _emailController.text.trim()
        : '+92 ${_phone.text.trim()}';
    final subtitle = step == 0
        ? 'Choose how you want to receive your reset code'
        : step == 1
        ? (_selectedOtpMethod == 'email'
              ? 'We sent a 4-digit code to $otpTarget'
              : 'We sent a 4-digit code via SMS to $otpTarget')
        : 'Enter and confirm your new password';

    return Column(
      key: ValueKey('forgotPasswordStep$step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        if (step == 0) ...[
          // Method selector cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOtpMethod = 'email'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedOtpMethod == 'email'
                          ? const Color(0xFFCCFBF1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedOtpMethod == 'email'
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: _selectedOtpMethod == 'email'
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF94A3B8),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _selectedOtpMethod == 'email'
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOtpMethod = 'phone'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedOtpMethod == 'phone'
                          ? const Color(0xFFCCFBF1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedOtpMethod == 'phone'
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          color: _selectedOtpMethod == 'phone'
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF94A3B8),
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SMS',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _selectedOtpMethod == 'phone'
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Input field based on selected method
          if (_selectedOtpMethod == 'email') ...[
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _validateEmail,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: 'john@example.com',
                  errorText: _emailError,
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Mobile Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (v) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+92 ',
                  hintText: '3001234567',
                  counterText: '',
                  errorText: _phoneError,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Send OTP'),
            ),
          ),
        ] else if (step == 1) ...[
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _otpNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () async {
                final random = math.Random();
                _generatedOtp = (1000 + random.nextInt(9000)).toString();
                final bool sent;
                if (_selectedOtpMethod == 'email') {
                  sent = await SmtpService.sendPasswordResetOTP(
                    _emailController.text.trim(),
                    _generatedOtp!,
                  );
                } else {
                  sent = await SmsService.sendOtp(
                    '+92${_phone.text.trim()}',
                    _generatedOtp!,
                  );
                }
                if (sent) {
                  for (final c in _otpControllers) {
                    c.clear();
                  }
                  showToast(
                    _selectedOtpMethod == 'email'
                        ? 'Reset code resent to your email'
                        : 'Reset code resent via SMS to +92${_phone.text.trim()}',
                  );
                } else {
                  showToast('Failed to resend code');
                }
              },
              child: const Text(
                'Resend code',
                style: TextStyle(color: Color(0xFF0D9488)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Verify OTP'),
            ),
          ),
        ] else ...[
          const Text(
            'New password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            onChanged: _validatePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Enter new password',
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) {
              if (_confirmPasswordError != null)
                setState(() => _confirmPasswordError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirm new password',
              errorText: _confirmPasswordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_password.text.isNotEmpty || _confirmPassword.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password requirements:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),
                  _pwRequirementRow(
                    'At least 1 uppercase letter',
                    _pwHasUppercase,
                  ),
                  _pwRequirementRow('At least 1 number', _pwHasDigit),
                  _pwRequirementRow(
                    'At least 1 special character (!@#\$...)',
                    _pwHasSpecial,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Reset Password'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isForgotPassword = false;
                  step = 0;
                  _emailController.clear();
                  _password.clear();
                  _confirmPassword.clear();
                  _emailError = null;
                  _passwordError = null;
                  _confirmPasswordError = null;
                  _generatedOtp = null;
                  for (final c in _otpControllers) {
                    c.clear();
                  }
                });
              },
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loginScreen() {
    final selectedRole = AppScope.of(context).role ?? UserRole.customer;
    final isWorker = selectedRole == UserRole.worker;
    final isUrdu = AppScope.of(context).isUrdu;
    return Column(
      key: const ValueKey('loginScreen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bilingual(context, 'Welcome back', 'خوش آمدید'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isWorker
              ? bilingual(
                  context,
                  'Login to your Worker account',
                  'اپنے ورکر اکاؤنٹ میں لاگ ان کریں',
                )
              : bilingual(
                  context,
                  'Login to your Customer account',
                  'اپنے کسٹمر اکاؤنٹ میں لاگ ان کریں',
                ),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        const Text(
          'Email or Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateLoginId,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Email or 03000000000',
              errorText: _emailError,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: _obscurePassword,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          decoration: InputDecoration(
            hintText: 'Enter your password',
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                (_obscurePassword)
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !(_obscurePassword)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                _isForgotPassword = true;
                step = 0;
                _selectedOtpMethod = 'email';
                _emailController.clear();
                _phone.clear();
                _password.clear();
                _confirmPassword.clear();
                _emailError = null;
                _phoneError = null;
              });
            },
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: Color(0xFF0D9488)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _next, child: const Text('Continue')),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No account? '),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.signup);
              },
              child: const Text(
                'Sign up',
                style: TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pwRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? const Color(0xFF059669) : Colors.grey.shade300,
            ),
            child: met
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF059669) : Colors.grey.shade500,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              decoration: met ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupFlow() {
    final role = AppScope.of(context).role;

    if (step == 0) {
      return Column(
        key: const ValueKey('signupStep0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fill in your details to get started',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text(
            'Full name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fullNameController,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Enter your full name',
              errorText: _nameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mail_outline),
              hintText: 'Enter your email address',
              errorText: _emailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mobile number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    '+92',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: '3000000000',
                errorText: _phoneError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D9488),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CNIC Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            maxLength: 13,
            onChanged: (val) {
              if (_cnicError != null) setState(() => _cnicError = null);
            },
            decoration: InputDecoration(
              counterText: '',
              prefixIcon: const Icon(Icons.credit_card_outlined),
              hintText: '4220112345671',
              errorText: _cnicError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0D9488),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            onChanged: _validatePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Enter your password',
              errorText: _passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) {
              if (_confirmPasswordError != null)
                setState(() => _confirmPasswordError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirm your password',
              errorText: _confirmPasswordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Dynamic password strength indicator
          if (_password.text.isNotEmpty ||
              _confirmPassword.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password requirements:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),
                  _pwRequirementRow(
                    'At least 1 uppercase letter',
                    _pwHasUppercase,
                  ),
                  _pwRequirementRow('At least 1 number', _pwHasDigit),
                  _pwRequirementRow(
                    'At least 1 special character (!@#\$...)',
                    _pwHasSpecial,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          if (role == UserRole.worker) ...[
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ['Select a category', 'Plumber', 'Electrician'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                        _categoryError = null;
                      });
                    }
                  },
                ),
              ),
            ),
            if (_categoryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _categoryError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],

          if (role == UserRole.worker) ...[
            // Profile Picture (Required)
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Upload your profile picture (max 100KB)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickProfilePic,
              child: Container(
                width: double.infinity,
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _profilePicFile != null
                      ? const Color(0xFFF0FDFA)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _profilePicFile != null
                        ? const Color(0xFF0D9488)
                        : Colors.grey.shade300,
                    width: _profilePicFile != null ? 1.5 : 1,
                  ),
                ),
                child: _profilePicFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _profilePicFile!.path,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to upload',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_profilePicError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _profilePicError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'CNIC Images (Front & Back)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Max 5MB per image',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _pickImage(true),
                        child: Container(
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _idFrontError != null
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: _idFrontImage != null
                              ? Image.network(
                                  _idFrontImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                        ),
                      ),
                      if (_idFrontError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _idFrontError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _idBackError != null
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: _idBackImage != null
                              ? Image.network(
                                  _idBackImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                        ),
                      ),
                      if (_idBackError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _idBackError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_imageSizeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _imageSizeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Certificates & Experience Letters (Optional)
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Certificates & Experience',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              bilingual(
                context,
                'You can upload any certificate, such as an experience letter, skill training, diploma, or police clearance. Tap "+" to add more.',
                'آپ کوئی بھی سرٹیفکیٹ شامل کر سکتے ہیں جیسے تجربہ کا سرٹیفکیٹ، ٹریننگ ڈپلومہ یا پولیس کلیئرنس۔ مزید شامل کرنے کے لیے + پر کلک کریں۔',
              ),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...List.generate(_certificateFiles.length, (idx) {
                  final cert = _certificateFiles[idx];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0D9488),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          cert.path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF0FDFA),
                            child: const Center(
                              child: Icon(
                                Icons.description,
                                color: Color(0xFF0D9488),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removeCertificate(idx),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Cert #${idx + 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                InkWell(
                  onTap: _pickCertificate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF0D9488),
                        style: BorderStyle.solid,
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
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bilingual(context, 'Add (+)', 'شامل کریں (+)'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
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
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 4),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isUploading ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Sign up'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? '),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      final isUrdu = AppScope.of(context).isUrdu;
      final target = _selectedOtpMethod == 'email'
          ? _emailController.text.trim()
          : '+92 ${_phone.text.trim()}';

      return Column(
        key: const ValueKey('signupStep1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrdu ? 'تصدیقی کوڈ درج کریں' : 'Enter verification code',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFCCFBF1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedOtpMethod == 'email'
                      ? Icons.email_outlined
                      : Icons.sms_outlined,
                  size: 14,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedOtpMethod == 'email'
                      ? (isUrdu
                            ? 'ہم نے $target پر 4 ہندسوں کا کوڈ بھیجا ہے'
                            : 'We sent a 4-digit code to $target')
                      : (isUrdu
                            ? 'ہم نے $target پر 4 ہندسوں کا ایس ایم ایس بھیجا ہے'
                            : 'We sent a 4-digit SMS code to $target'),
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _otpNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Color(0xFF0D9488),
                  ),
                  label: Text(
                    isUrdu ? 'دوبارہ کوڈ بھیجیں' : 'Resend code',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    setState(() => _isUploading = true);
                    final sent = await _dispatchOtp(_selectedOtpMethod);
                    setState(() => _isUploading = false);
                    if (sent) {
                      for (final c in _otpControllers) {
                        c.clear();
                      }
                      if (_selectedOtpMethod == 'email') {
                        showToast(
                          'Verification code resent to ${_emailController.text.trim()}',
                        );
                      } else {
                        showToast(
                          'Verification code resent via SMS to +92 ${_phone.text.trim()}',
                        );
                      }
                    } else {
                      showToast('Failed to resend verification code');
                    }
                  },
                ),
                const Text('|', style: TextStyle(color: Colors.grey)),
                TextButton.icon(
                  icon: Icon(
                    _selectedOtpMethod == 'email'
                        ? Icons.sms_outlined
                        : Icons.email_outlined,
                    size: 16,
                    color: const Color(0xFF0D9488),
                  ),
                  label: Text(
                    _selectedOtpMethod == 'email'
                        ? (isUrdu
                              ? 'نمبر پر ایس ایم ایس بھیجیں'
                              : 'Send via SMS instead')
                        : (isUrdu
                              ? 'ای میل پر بھیجیں'
                              : 'Send via Email instead'),
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final newMethod = _selectedOtpMethod == 'email'
                        ? 'phone'
                        : 'email';
                    setState(() {
                      _isUploading = true;
                      _selectedOtpMethod = newMethod;
                    });
                    final sent = await _dispatchOtp(newMethod);
                    setState(() => _isUploading = false);
                    if (sent) {
                      for (final c in _otpControllers) {
                        c.clear();
                      }
                      if (newMethod == 'email') {
                        showToast(
                          'Verification code sent to ${_emailController.text.trim()}',
                        );
                      } else {
                        showToast(
                          'Verification code sent via SMS to +92 ${_phone.text.trim()}',
                        );
                      }
                    } else {
                      showToast(
                        'Failed to send code via ${newMethod == 'email' ? 'Email' : 'SMS'}',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  step = 0;
                });
              },
              child: Text(
                isUrdu
                    ? 'معلومات تبدیل کریں (واپس جائیں)'
                    : 'Edit registration details (Go back)',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isUploading ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isUrdu ? 'سائن اپ مکمل کریں' : 'Complete Sign up'),
            ),
          ),
        ],
      );
    }
  }
}
