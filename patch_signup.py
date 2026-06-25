#!/usr/bin/env python3
"""Patch mazdoor_flow.dart with all required signup and category changes."""
import re as re_module

FILE = 'lib/screens/mazdoor_flow.dart'

with open(FILE, 'rb') as f:
    content = f.read()

def check_patch(old_bytes, label):
    if old_bytes not in content:
        raise ValueError(f"Patch '{label}' not found in file!")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Add new state vars: policeCertError + password strength tracking
# ─────────────────────────────────────────────────────────────────────────────
old1 = b'  String? _idFrontError;\r\n  String? _idBackError;\r\n  String? _imageSizeError;\r\n'
new1 = (
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
)
check_patch(old1, 'STATE_VARS')
content = content.replace(old1, new1, 1)
print("Patch 1 (state vars) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Replace _validatePassword to track individual booleans
# ─────────────────────────────────────────────────────────────────────────────
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
    b"      _pwHasSpecial = val.contains(RegExp(r'[!@#\$%^&*(),.?\":{}<>]'));\r\n"
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
old3 = (
    b"      if (role == UserRole.worker) {\r\n"
    b"        _idFrontError = _idFrontImage == null ? 'Front ID image is required' : null;\r\n"
    b"        _idBackError = _idBackImage == null ? 'Back ID image is required' : null;\r\n"
    b"      }\r\n"
)
new3 = (
    b"      if (role == UserRole.worker) {\r\n"
    b"        _idFrontError = _idFrontImage == null ? 'Front CNIC image is required' : null;\r\n"
    b"        _idBackError = _idBackImage == null ? 'Back CNIC image is required' : null;\r\n"
    b"        _policeCertError = _policeCertFile == null ? 'Police certificate is required' : null;\r\n"
    b"      }\r\n"
)
check_patch(old3, 'VALIDATE_FIELDS')
content = content.replace(old3, new3, 1)
print("Patch 3 (_validateSignupFields) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 4. Add _policeCertFile and _certificationFile fields
# ─────────────────────────────────────────────────────────────────────────────
old4 = (
    b'  File? _idFrontImage;\r\n'
    b'  File? _idBackImage;\r\n'
    b'  bool _isUploading = false;\r\n'
    b'  final ImagePicker _picker = ImagePicker();\r\n'
)
new4 = (
    b'  File? _idFrontImage;\r\n'
    b'  File? _idBackImage;\r\n'
    b'  File? _policeCertFile;       // Required for worker\r\n'
    b'  File? _certificationFile;    // Optional for worker\r\n'
    b'  bool _isUploading = false;\r\n'
    b'  final ImagePicker _picker = ImagePicker();\r\n'
)
check_patch(old4, 'FILE_FIELDS')
content = content.replace(old4, new4, 1)
print("Patch 4 (file fields) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Add _pickPoliceCert / _pickCertification after _uploadToCloudinary
# ─────────────────────────────────────────────────────────────────────────────
old5 = (
    b'  Future<String?> _uploadToCloudinary(File imageFile) async {\r\n'
    b'    return CloudinaryService.uploadImage(imageFile);\r\n'
    b'  }\r\n'
)
new5 = (
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
check_patch(old5, 'UPLOAD_METHOD')
content = content.replace(old5, new5, 1)
print("Patch 5 (pick methods) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 6. Remove redundant null assignments in dispose()
# ─────────────────────────────────────────────────────────────────────────────
old6 = (
    b'    _imageSizeError = null;\r\n'
    b'    _nameError = null;\r\n'
    b'    _phoneError = null;\r\n'
    b'    _confirmPasswordError = null;\r\n'
    b'    _idFrontError = null;\r\n'
    b'    _idBackError = null;\r\n'
    b'    super.dispose();\r\n'
)
new6 = b'    super.dispose();\r\n'
check_patch(old6, 'DISPOSE')
content = content.replace(old6, new6, 1)
print("Patch 6 (dispose) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 7a. Update _next() ID card check message + add police cert check
# ─────────────────────────────────────────────────────────────────────────────
old7a = (
    b"        if (role == UserRole.worker && (_idFrontError != null || _idBackError != null)) {\r\n"
    b"          showToast('Please upload both front and back of your ID card');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
)
new7a = (
    b"        if (role == UserRole.worker && (_idFrontError != null || _idBackError != null)) {\r\n"
    b"          showToast('Please upload both front and back of your CNIC');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
    b"        if (role == UserRole.worker && _policeCertError != null) {\r\n"
    b"          showToast('Please upload your police character certificate');\r\n"
    b"          return;\r\n"
    b"        }\r\n"
)
check_patch(old7a, 'NEXT_CHECK')
content = content.replace(old7a, new7a, 1)
print("Patch 7a (next check) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 7b. Add police cert + certification uploads
# ─────────────────────────────────────────────────────────────────────────────
old7b = (
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
new7b = (
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
check_patch(old7b, 'UPLOAD_SECTION')
content = content.replace(old7b, new7b, 1)
print("Patch 7b (upload section) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 7c. Fix userData type and add new document URL fields
# ─────────────────────────────────────────────────────────────────────────────
old7c = (
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
new7c = (
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
check_patch(old7c, 'USERDATA')
content = content.replace(old7c, new7c, 1)
print("Patch 7c (userData) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 7d. Replace snackbar with success dialog
# ─────────────────────────────────────────────────────────────────────────────
old7d = (
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
new7d = (
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
check_patch(old7d, 'SUCCESS_DIALOG')
content = content.replace(old7d, new7d, 1)
print("Patch 7d (success dialog) OK")

with open(FILE, 'wb') as f:
    f.write(content)

print("\nAll patches applied successfully! File written.")
