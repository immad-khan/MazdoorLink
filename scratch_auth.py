import os
import re

file_path = r"d:\Desktop\MazdoorLink\lib\screens\mazdoor_flow.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add fluttertoast import
if "import 'package:fluttertoast/fluttertoast.dart';" not in content:
    content = content.replace("import 'package:firebase_auth/firebase_auth.dart';", 
                              "import 'package:firebase_auth/firebase_auth.dart';\nimport 'package:fluttertoast/fluttertoast.dart';")

# 2. Add validation variables and _showToast
state_class_start = "class _AuthScreenState extends State<AuthScreen> {"
state_vars = """
  String? _emailError;
  String? _passwordError;

  void _validateEmail(String val) {
    if (val.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    setState(() {
      _emailError = emailRegex.hasMatch(val) ? null : 'Enter a valid email address';
    });
  }

  void _validatePassword(String val) {
    if (val.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }
    bool hasUppercase = val.contains(RegExp(r'[A-Z]'));
    bool hasDigits = val.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (val.length < 8) {
      setState(() => _passwordError = 'Must be at least 8 characters');
    } else if (!hasUppercase) {
      setState(() => _passwordError = 'Must contain at least 1 uppercase letter');
    } else if (!hasDigits) {
      setState(() => _passwordError = 'Must contain at least 1 number');
    } else if (!hasSpecialCharacters) {
      setState(() => _passwordError = 'Must contain at least 1 special character');
    } else {
      setState(() => _passwordError = null);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
"""

if "_emailError" not in content:
    content = content.replace(state_class_start, state_class_start + state_vars)

# 3. Replace ScaffoldMessenger with _showToast in _AuthScreenState
# This is tricky using regex, we can replace some common patterns:
content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s*SnackBar\(content:\s*Text\((.*?)\)\)\s*\);', r'_showToast(\1);', content)
content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content:\s*Text\((.*?)\)\)\s*\);', r'_showToast(\1);', content)
content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*duration:.*?\)\s*\);', r'_showToast(\1);', content)
content = re.sub(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*duration:.*?\)\s*\);', r'_showToast(\1);', content)

# 4. Replace _forgotPasswordFlow
old_forgot = re.search(r'Widget _forgotPasswordFlow\(\) \{.*?(?=Widget _loginScreen\(\))', content, re.DOTALL)
new_forgot = """Widget _forgotPasswordFlow() {
    return Column(
      key: const ValueKey('forgotPasswordStep0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset password',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address to reset your password',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _next,
            child: const Text('Send Reset Link'),
          ),
        ),
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
                  _emailError = null;
                });
              },
              child: const Text('Back to Login', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  """
if old_forgot:
    content = content.replace(old_forgot.group(0), new_forgot)

# 5. Add validation to signup textfields
old_email_signup = """TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mail_outline),
              hintText: 'Enter your email address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )"""
new_email_signup = """TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mail_outline),
              hintText: 'Enter your email address',
              errorText: _emailError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )"""
content = content.replace(old_email_signup, new_email_signup)

old_password_signup = """TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Enter your password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          )"""
new_password_signup = """TextField(
            controller: _password,
            obscureText: _obscurePassword,
            onChanged: _validatePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Enter your password',
              errorText: _passwordError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          )"""
content = content.replace(old_password_signup, new_password_signup)

old_email_login = """TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'john@example.com',
            ),
          )"""
new_email_login = """TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              hintText: 'john@example.com',
              errorText: _emailError,
            ),
          )"""
content = content.replace(old_email_login, new_email_login)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated mazdoor_flow.dart")
