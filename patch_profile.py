#!/usr/bin/env python3
"""Patch 3: Update ProfileManagementScreen to add birthday field."""

FILE = 'lib/screens/profile_management_screen.dart'

with open(FILE, 'rb') as f:
    content = f.read()

def check_and_replace(old_bytes, new_bytes, label):
    if old_bytes not in content:
        raise ValueError(f"Patch '{label}' not found!\nSearched for:\n{old_bytes[:200]}")
    return content.replace(old_bytes, new_bytes, 1)

# ─────────────────────────────────────────────────────────────────────────────
# 1. Add _birthdayController and _birthday to state
# ─────────────────────────────────────────────────────────────────────────────
old1 = (
    b'  final _nameController = TextEditingController();\n'
    b'  final _phoneController = TextEditingController();\n'
    b'  final _emailController = TextEditingController();\n'
)
new1 = (
    b'  final _nameController = TextEditingController();\n'
    b'  final _phoneController = TextEditingController();\n'
    b'  final _emailController = TextEditingController();\n'
    b'  final _birthdayController = TextEditingController();\n'
)
content = check_and_replace(old1, new1, 'BIRTHDAY_CONTROLLER')
print("Patch 1 (birthday controller) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Load birthday in _loadUserData
# ─────────────────────────────────────────────────────────────────────────────
old2 = (
    b"        _emailController.text = (data['email']?.toString() ?? user.email ?? '') as String;\n"
    b"        _profileImageUrl = data['profileImage']?.toString() ?? '';\n"
    b"        _isWorker = data['role'] == 'worker';\n"
)
new2 = (
    b"        _emailController.text = (data['email']?.toString() ?? user.email ?? '') as String;\n"
    b"        _profileImageUrl = data['profileImage']?.toString() ?? '';\n"
    b"        _isWorker = data['role'] == 'worker';\n"
    b"        _birthdayController.text = data['birthday']?.toString() ?? '';\n"
)
content = check_and_replace(old2, new2, 'LOAD_BIRTHDAY')
print("Patch 2 (load birthday) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Dispose birthday controller
# ─────────────────────────────────────────────────────────────────────────────
old3 = (
    b'  @override\n'
    b'  void dispose() {\n'
    b'    _nameController.dispose();\n'
    b'    _phoneController.dispose();\n'
    b'    _emailController.dispose();\n'
    b'    _fadeController.dispose();\n'
    b'    super.dispose();\n'
    b'  }\n'
)
new3 = (
    b'  @override\n'
    b'  void dispose() {\n'
    b'    _nameController.dispose();\n'
    b'    _phoneController.dispose();\n'
    b'    _emailController.dispose();\n'
    b'    _birthdayController.dispose();\n'
    b'    _fadeController.dispose();\n'
    b'    super.dispose();\n'
    b'  }\n'
)
content = check_and_replace(old3, new3, 'DISPOSE_BIRTHDAY')
print("Patch 3 (dispose birthday) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 4. Save birthday in _saveProfile
# ─────────────────────────────────────────────────────────────────────────────
old4 = (
    b'      await updateUserProfile(\n'
    b'        name: _nameController.text.trim(),\n'
    b'        phone: _phoneController.text.trim(),\n'
    b'      );\n'
)
new4 = (
    b'      await updateUserProfile(\n'
    b'        name: _nameController.text.trim(),\n'
    b'        phone: _phoneController.text.trim(),\n'
    b'        birthday: _birthdayController.text.trim(),\n'
    b'      );\n'
)
content = check_and_replace(old4, new4, 'SAVE_BIRTHDAY')
print("Patch 4 (save birthday) OK")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Add birthday field to the UI (after phone field, before email)
# ─────────────────────────────────────────────────────────────────────────────
old5 = (
    b'                  Padding(\n'
    b'                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),\n'
    b'                    child: TextField(\n'
    b'                      controller: _emailController,\n'
    b'                      enabled: false,\n'
    b'                      decoration: InputDecoration(\n'
    b'                        labelText: \'Email Address\',\n'
    b'                        prefixIcon: Icon(Icons.email,\n'
    b'                            color: Theme.of(context).primaryColor, size: 20),\n'
    b'                      ),\n'
    b'                    ),\n'
    b'                  ),\n'
    b'                ],\n'
    b'              ),\n'
)
new5 = (
    b'                  Padding(\n'
    b'                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),\n'
    b'                    child: TextField(\n'
    b'                      controller: _birthdayController,\n'
    b'                      readOnly: true,\n'
    b'                      onTap: () async {\n'
    b'                        final parsed = _birthdayController.text.isNotEmpty\n'
    b'                            ? DateTime.tryParse(_birthdayController.text)\n'
    b'                            : null;\n'
    b'                        final picked = await showDatePicker(\n'
    b'                          context: context,\n'
    b'                          initialDate: parsed ?? DateTime(1990),\n'
    b'                          firstDate: DateTime(1940),\n'
    b'                          lastDate: DateTime.now(),\n'
    b'                        );\n'
    b'                        if (picked != null) {\n'
    b'                          _birthdayController.text =\n'
    b'                              "${picked.year}-${picked.month.toString().padLeft(2, \'0\')}-${picked.day.toString().padLeft(2, \'0\')}";\n'
    b'                          setState(() {});\n'
    b'                        }\n'
    b'                      },\n'
    b'                      decoration: InputDecoration(\n'
    b'                        labelText: \'Date of Birth\',\n'
    b'                        hintText: \'YYYY-MM-DD\',\n'
    b'                        prefixIcon: Icon(Icons.cake_outlined,\n'
    b'                            color: Theme.of(context).primaryColor, size: 20),\n'
    b'                        suffixIcon: Icon(Icons.calendar_today_outlined,\n'
    b'                            color: Colors.grey.shade400, size: 18),\n'
    b'                      ),\n'
    b'                    ),\n'
    b'                  ),\n'
    b'                  Padding(\n'
    b'                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),\n'
    b'                    child: TextField(\n'
    b'                      controller: _emailController,\n'
    b'                      enabled: false,\n'
    b'                      decoration: InputDecoration(\n'
    b'                        labelText: \'Email Address\',\n'
    b'                        prefixIcon: Icon(Icons.email,\n'
    b'                            color: Theme.of(context).primaryColor, size: 20),\n'
    b'                      ),\n'
    b'                    ),\n'
    b'                  ),\n'
    b'                ],\n'
    b'              ),\n'
)
content = check_and_replace(old5, new5, 'BIRTHDAY_FIELD_UI')
print("Patch 5 (birthday UI field) OK")

with open(FILE, 'wb') as f:
    f.write(content)

print("\nAll ProfileManagement patches applied!")
