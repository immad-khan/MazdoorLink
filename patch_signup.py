#!/usr/bin/env python3
"""Patch mazdoor_flow.dart with all required signup and category changes."""

FILE = 'lib/screens/mazdoor_flow.dart'

with open(FILE, 'rb') as f:
    content = f.read()

def patch(old_bytes, new_bytes, label):
    if old_bytes not in content:
        raise ValueError(f"Patch '{label}' not found in file!")
    return content.replace(old_bytes, new_bytes, 1)

# ─────────────────────────────────────────────────────────────────────────────
# 1. Add new state vars: policeCertError + password strength tracking
# ─────────────────────────────────────────────────────────────────────────────
content = patch(
    b'  String? _idFrontError;\r\n  String? _idBackError;\r\n  String? _imageSizeError;\r\n',
    (
        b'  String? _idFrontError;\r\n'
        b'  String? _idBackError;\r\n'
        b'  String? _imageSizeError;\r\n'
        b'  String? _policeCertError;\r\n'
        b'\r\n'
        b'  // Password strength tracking\r\n'
        b'  bool _pwHasMinLength = false;\r\n'
        b'  bool _pwHasUppercase = false;\r\n'
        b'  bool _pwHasDigit = false;\r\n'
        b'  bool _pwHasSpecial = false;\r\n'
    ),
    'STATE_VARS'
)
print("Patch 1 (state vars) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Replace _validatePassword to track individual booleans
# ─────────────────────────────────────────────────────────────────────────────
content = patch(
    (
        b'  void _validatePassword(String val) {\r\n'
        b'    if (val.isEmpty) {\r\n'
        b'      setState(() => _passwordError = null);\r\n'
        b'      return;\r\n'
        b'    }\r\n'
        b'    bool hasUppercase = val.contains(RegExp(r\'[A-Z]\'));\r\n'
        b'    bool hasDigits = val.contains(RegExp(r\'[0-9]\'));\r\n'
        b'    bool hasSpecialCharacters = val.contains(RegExp(r\'[!@#$%^&*(),.?\":{}\r\n'
        b'|<>]\'));\r\n'
    ),
    b'PLACEHOLDER_NOT_USED\r\n',
    'PLACEHOLDER_NOT_USED'  # We'll use a different approach below
)

print("Will use regex approach instead")

# Reload original
with open(FILE, 'rb') as f:
    content = f.read()

import re as re_module

# Find and replace _validatePassword using a regex on the binary content
old_vp_pattern = rb'  void _validatePassword\(String val\) \{.*?  \}\r\n'
old_vp_match = re_module.search(old_vp_pattern, content, re_module.DOTALL)
if not old_vp_match:
    raise ValueError("Could not find _validatePassword method")

new_vp = (
    b'  void _validatePassword(String val) {\r\n'
    b'    setState(() {\r\n'
    b"      _pwHasMinLength = val.length >= 8;\r\n"
    b"      _pwHasUppercase = val.contains(RegExp(r'[A-Z]'));\r\n"
    b"      _pwHasDigit = val.contains(RegExp(r'[0-9]'));\r\n"
    b"      _pwHasSpecial = val.contains(RegExp(r'[!@#$%^&*(),.?\":{}<>]'));\r\n"
    b"      if (val.isEmpty) {\r\n"
    b"        _passwordError = null;\r\n"
    b"      } else if (!_pwHasMinLength) {\r\n"
    b"        _passwordError = 'Must be at least 8 characters';\r\n"
    b"      } else if (!_pwHasUppercase) {\r\n"
    b"        _passwordError = 'Must contain at least 1 uppercase letter';\r\n"
    b"      } else if (!_pwHasDigit) {\r\n"
    b"        _passwordError = 'Must contain at least 1 number';\r\n"
    b"      } else if (!_pwHasSpecial) {\r\n"
    b"        _passwordError = 'Must contain at least 1 special character';\r\n"
    b"      } else {\r\n"
    b"        _passwordError = null;\r\n"
    b"      }\r\n"
    b"    });\r\n"
    b'  }\r\n'
)
content = content[:old_vp_match.start()] + new_vp + content[old_vp_match.end():]
print("Patch 2 (_validatePassword) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Add policeCertError to _validateSignupFields
# ─────────────────────────────────────────────────────────────────────────────
old_worker_id_check = (
    b"      if (role == UserRole.worker) {\r\n"
    b"        _idFrontError = _idFrontImage == null ? 'Front ID image is required' : null;\r\n"
    b"        _idBackError = _idBackImage == null ? 'Back ID image is required' : null;\r\n"
    b"      }\r\n"
)
new_worker_id_check = (
    b"      if (role == UserRole.worker) {\r\n"
    b"        _idFrontError = _idFrontImage == null ? 'Front CNIC image is required' : null;\r\n"
    b"        _idBackError = _idBackImage == null ? 'Back CNIC image is required' : null;\r\n"
    b"        _policeCertError = _policeCertFile == null ? 'Police certificate is required' : null;\r\n"
    b"      }\r\n"
)
if old_worker_id_check not in content:
    raise ValueError("Patch 3 not found")
content = content.replace(old_worker_id_check, new_worker_id_check, 1)
print("Patch 3 (_validateSignupFields) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 4. Add _policeCertFile and _certificationFile fields
# ─────────────────────────────────────────────────────────────────────────────
old_file_fields = (
    b'  File? _idFrontImage;\r\n'
    b'  File? _idBackImage;\r\n'
    b'  bool _isUploading = false;\r\n'
    b'  final ImagePicker _picker = ImagePicker();\r\n'
)
new_file_fields = (
    b'  File? _idFrontImage;\r\n'
    b'  File? _idBackImage;\r\n'
    b'  File? _policeCertFile;       // Required for worker\r\n'
    b'  File? _certificationFile;    // Optional for worker\r\n'
    b'  bool _isUploading = false;\r\n'
    b'  final ImagePicker _picker = ImagePicker();\r\n'
)
if old_file_fields not in content:
    raise ValueError("Patch 4 not found")
content = content.replace(old_file_fields, new_file_fields, 1)
print("Patch 4 (file fields) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Add _pickPoliceCert / _pickCertification after _pickImage method
# ─────────────────────────────────────────────────────────────────────────────
old_upload_method = (
    b'  Future<String?> _uploadToCloudinary(File imageFile) async {\r\n'
    b'    return CloudinaryService.uploadImage(imageFile);\r\n'
    b'  }\r\n'
)
new_upload_method = (
    b'  Future<void> _pickPoliceCert() async {\r\n'
    b'    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);\r\n'
    b'    if (image != null) {\r\n'
    b'      final file = File(image.path);\r\n'
    b'      final sizeInMb = file.lengthSync() / (1024 * 1024);\r\n'
    b'      if (sizeInMb > 10) {\r\n'
    b"        setState(() => _imageSizeError = 'Police certificate must be less than 10MB');\r\n"
    b'        return;\r\n'
    b'      }\r\n'
    b'      setState(() {\r\n'
    b'        _policeCertFile = file;\r\n'
    b'        _policeCertError = null;\r\n'
    b'        _imageSizeError = null;\r\n'
    b'      });\r\n'
    b'    }\r\n'
    b'  }\r\n'
    b'\r\n'
    b'  Future<void> _pickCertification() async {\r\n'
    b'    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);\r\n'
    b'    if (image != null) {\r\n'
    b'      setState(() => _certificationFile = File(image.path));\r\n'
    b'    }\r\n'
    b'  }\r\n'
    b'\r\n'
    b'  Future<String?> _uploadToCloudinary(File imageFile) async {\r\n'
    b'    return CloudinaryService.uploadImage(imageFile);\r\n'
    b'  }\r\n'
)
if old_upload_method not in content:
    raise ValueError("Patch 5 not found")
content = content.replace(old_upload_method, new_upload_method, 1)
print("Patch 5 (pick methods) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 6. Remove redundant null assignments in dispose()
# ─────────────────────────────────────────────────────────────────────────────
old_dispose_extras = (
    b'    _imageSizeError = null;\r\n'
    b'    _nameError = null;\r\n'
    b'    _phoneError = null;\r\n'
    b'    _confirmPasswordError = null;\r\n'
    b'    _idFrontError = null;\r\n'
    b'    _idBackError = null;\r\n'
    b'    super.dispose();\r\n'
)
new_dispose = b'    super.dispose();\r\n'
if old_dispose_extras not in content:
    raise ValueError("Patch 6 not found")
content = content.replace(old_dispose_extras, new_dispose, 1)
print("Patch 6 (dispose cleanup) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 7. Update _next() signup logic
# ─────────────────────────────────────────────────────────────────────────────
old_next_check = (
    b"        if (role == UserRole.worker && (_idFrontError != null || _idBackError != null)) {\r\n"
    b"          showToast('Please upload both front and back of your ID card');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
)
new_next_check = (
    b"        if (role == UserRole.worker && (_idFrontError != null || _idBackError != null)) {\r\n"
    b"          showToast('Please upload both front and back of your CNIC');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
    b"        if (role == UserRole.worker && _policeCertError != null) {\r\n"
    b"          showToast('Please upload your police character certificate');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
)
if old_next_check not in content:
    raise ValueError("Patch 7a not found")
content = content.replace(old_next_check, new_next_check, 1)
print("Patch 7a (next check) OK")

# Update the upload section - add police cert and certification uploads
old_upload_section = (
    b"          String? frontUrl;\r\n"
    b"          String? backUrl;\r\n"
    b"          if (role == UserRole.worker) {\r\n"
    b"            frontUrl = await _uploadToCloudinary(_idFrontImage!);\r\n"
    b"            backUrl = await _uploadToCloudinary(_idBackImage!);\r\n"
    b"            if (frontUrl == null || backUrl == null) {\r\n"
    b"              setState(() => _isUploading = false);\r\n"
    b"              if (mounted) showToast('Failed to upload ID images. Try again.');\r\n"
    b"              return;\r\n"
    b"            }\r\n"
    b"          }\r\n"
)
new_upload_section = (
    b"          String? frontUrl;\r\n"
    b"          String? backUrl;\r\n"
    b"          String? policeCertUrl;\r\n"
    b"          String? certificationUrl;\r\n"
    b"          if (role == UserRole.worker) {\r\n"
    b"            frontUrl = await _uploadToCloudinary(_idFrontImage!);\r\n"
    b"            backUrl = await _uploadToCloudinary(_idBackImage!);\r\n"
    b"            if (frontUrl == null || backUrl == null) {\r\n"
    b"              setState(() => _isUploading = false);\r\n"
    b"              if (mounted) showToast('Failed to upload CNIC images. Try again.');\r\n"
    b"              return;\r\n"
    b"            }\r\n"
    b"            policeCertUrl = await _uploadToCloudinary(_policeCertFile!);\r\n"
    b"            if (policeCertUrl == null) {\r\n"
    b"              setState(() => _isUploading = false);\r\n"
    b"              if (mounted) showToast('Failed to upload police certificate. Try again.');\r\n"
    b"              return;\r\n"
    b"            }\r\n"
    b"            if (_certificationFile != null) {\r\n"
    b"              certificationUrl = await _uploadToCloudinary(_certificationFile!);\r\n"
    b"            }\r\n"
    b"          }\r\n"
)
if old_upload_section not in content:
    raise ValueError("Patch 7b not found")
content = content.replace(old_upload_section, new_upload_section, 1)
print("Patch 7b (upload section) OK")

# Fix userData type and add new fields
old_userdata = (
    b"          final userData = {\r\n"
    b"            'name': _fullNameController.text.trim(),\r\n"
    b"            'email': _emailController.text.trim(),\r\n"
    b"            'phone': _phone.text.trim(),\r\n"
    b"            'role': role == UserRole.worker ? 'worker' : 'customer',\r\n"
    b"            'createdAt': FieldValue.serverTimestamp(),\r\n"
    b"          };\r\n"
    b"\r\n"
    b"          if (role == UserRole.worker) {\r\n"
    b"            userData['status'] = 'pending';\r\n"
    b"            userData['idFrontUrl'] = frontUrl!;\r\n"
    b"            userData['idBackUrl'] = backUrl!;\r\n"
    b"          }\r\n"
)
new_userdata = (
    b"          final userData = <String, dynamic>{\r\n"
    b"            'name': _fullNameController.text.trim(),\r\n"
    b"            'email': _emailController.text.trim(),\r\n"
    b"            'phone': _phone.text.trim(),\r\n"
    b"            'role': role == UserRole.worker ? 'worker' : 'customer',\r\n"
    b"            'createdAt': FieldValue.serverTimestamp(),\r\n"
    b"          };\r\n"
    b"\r\n"
    b"          if (role == UserRole.worker) {\r\n"
    b"            userData['status'] = 'pending';\r\n"
    b"            userData['idFrontUrl'] = frontUrl!;\r\n"
    b"            userData['idBackUrl'] = backUrl!;\r\n"
    b"            userData['policeCertUrl'] = policeCertUrl!;\r\n"
    b"            if (certificationUrl != null) {\r\n"
    b"              userData['certificationUrl'] = certificationUrl;\r\n"
    b"            }\r\n"
    b"          }\r\n"
)
if old_userdata not in content:
    raise ValueError("Patch 7c not found")
content = content.replace(old_userdata, new_userdata, 1)
print("Patch 7c (userData) OK")

# Replace snackbar success with dialog
old_success = (
    b"          if (mounted) {\r\n"
    b"            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(\r\n"
    b"              content: Text('Account created! Please check your email to verify your account before logging in.'),\r\n"
    b"              duration: Duration(seconds: 5),\r\n"
    b"            ));\r\n"
    b"            Navigator.pushReplacementNamed(context, AppRoutes.login);\r\n"
    b"          }\r\n"
    b"          return;\r\n"
    b"        } catch (e) {\r\n"
)
new_success = (
    b"          if (mounted) {\r\n"
    b"            showDialog(\r\n"
    b"              context: context,\r\n"
    b"              barrierDismissible: false,\r\n"
    b"              builder: (ctx) => Dialog(\r\n"
    b"                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),\r\n"
    b"                child: Padding(\r\n"
    b"                  padding: const EdgeInsets.all(28),\r\n"
    b"                  child: Column(\r\n"
    b"                    mainAxisSize: MainAxisSize.min,\r\n"
    b"                    children: [\r\n"
    b"                      Container(\r\n"
    b"                        width: 80, height: 80,\r\n"
    b"                        decoration: const BoxDecoration(\r\n"
    b"                          shape: BoxShape.circle,\r\n"
    b"                          color: Color(0xFFDCFCE7),\r\n"
    b"                        ),\r\n"
    b"                        child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF059669), size: 44),\r\n"
    b"                      ),\r\n"
    b"                      const SizedBox(height: 20),\r\n"
    b"                      const Text('Registration Submitted!',\r\n"
    b"                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),\r\n"
    b"                      const SizedBox(height: 12),\r\n"
    b"                      role == UserRole.worker\r\n"
    b"                          ? const Text(\r\n"
    b"                              'A verification email has been sent.\\n\\nYour profile is under admin review. You can log in once your account is approved.',\r\n"
    b"                              textAlign: TextAlign.center,\r\n"
    b"                              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),\r\n"
    b"                            )\r\n"
    b"                          : const Text(\r\n"
    b"                              'A verification email has been sent. Please verify your email before logging in.',\r\n"
    b"                              textAlign: TextAlign.center,\r\n"
    b"                              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),\r\n"
    b"                            ),\r\n"
    b"                      const SizedBox(height: 24),\r\n"
    b"                      SizedBox(\r\n"
    b"                        width: double.infinity,\r\n"
    b"                        child: FilledButton(\r\n"
    b"                          onPressed: () {\r\n"
    b"                            Navigator.of(ctx).pop();\r\n"
    b"                            Navigator.pushReplacementNamed(context, AppRoutes.login);\r\n"
    b"                          },\r\n"
    b"                          style: FilledButton.styleFrom(\r\n"
    b"                            backgroundColor: const Color(0xFF0D9488),\r\n"
    b"                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\r\n"
    b"                          ),\r\n"
    b"                          child: const Text('Go to Login'),\r\n"
    b"                        ),\r\n"
    b"                      ),\r\n"
    b"                    ],\r\n"
    b"                  ),\r\n"
    b"                ),\r\n"
    b"              ),\r\n"
    b"            );\r\n"
    b"          }\r\n"
    b"          return;\r\n"
    b"        } catch (e) {\r\n"
)
if old_success not in content:
    raise ValueError("Patch 7d (success dialog) not found")
content = content.replace(old_success, new_success, 1)
print("Patch 7d (success dialog) OK")

with open(FILE, 'wb') as f:
    f.write(content)

print("\nAll patches applied successfully! File written.")
