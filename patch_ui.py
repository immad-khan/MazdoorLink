#!/usr/bin/env python3
"""Patch 2: Update signup UI, category screen, and profile screen."""

FILE = 'lib/screens/mazdoor_flow.dart'

with open(FILE, 'rb') as f:
    content = f.read()

def check_and_replace(old_bytes, new_bytes, label):
    if old_bytes not in content:
        raise ValueError(f"Patch '{label}' not found in file!")
    return content.replace(old_bytes, new_bytes, 1)

# ─────────────────────────────────────────────────────────────────────────────
# A. Replace the password hint text + static hint with dynamic strength widget
#    and add police cert + certification fields BEFORE the Submit button
# ─────────────────────────────────────────────────────────────────────────────
old_pw_hint = (
    b"          const SizedBox(height: 6),\r\n"
    b"          const Text('Password must be at least 8 characters with letters and numbers', style: TextStyle(fontSize: 11, color: Colors.black54)),\r\n"
    b"          const SizedBox(height: 24),\r\n"
    b"          \r\n"
    b"          if (role == UserRole.worker) ...[\r\n"
    b"            const Divider(),\r\n"
    b"            const SizedBox(height: 16),\r\n"
    b"            const Text('ID Card Images (Front & Back)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),\r\n"
    b"            const SizedBox(height: 2),\r\n"
    b"            Text('Max 5MB per image', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),\r\n"
)
new_pw_hint = (
    b"          const SizedBox(height: 10),\r\n"
    b"          // Dynamic password strength indicator\r\n"
    b"          if (_password.text.isNotEmpty) ...[\r\n"
    b"            Container(\r\n"
    b"              padding: const EdgeInsets.all(12),\r\n"
    b"              decoration: BoxDecoration(\r\n"
    b"                color: const Color(0xFFF8FAFC),\r\n"
    b"                borderRadius: BorderRadius.circular(10),\r\n"
    b"                border: Border.all(color: const Color(0xFFE2E8F0)),\r\n"
    b"              ),\r\n"
    b"              child: Column(\r\n"
    b"                crossAxisAlignment: CrossAxisAlignment.start,\r\n"
    b"                children: [\r\n"
    b"                  const Text('Password requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),\r\n"
    b"                  const SizedBox(height: 6),\r\n"
    b"                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),\r\n"
    b"                  _pwRequirementRow('At least 1 uppercase letter', _pwHasUppercase),\r\n"
    b"                  _pwRequirementRow('At least 1 number', _pwHasDigit),\r\n"
    b"                  _pwRequirementRow('At least 1 special character (!@#\$...)', _pwHasSpecial),\r\n"
    b"                ],\r\n"
    b"              ),\r\n"
    b"            ),\r\n"
    b"          ],\r\n"
    b"          const SizedBox(height: 24),\r\n"
    b"          \r\n"
    b"          if (role == UserRole.worker) ...[\r\n"
    b"            const Divider(),\r\n"
    b"            const SizedBox(height: 16),\r\n"
    b"            const Text('CNIC Images (Front & Back)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),\r\n"
    b"            const SizedBox(height: 2),\r\n"
    b"            Text('Max 5MB per image', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),\r\n"
)
content = check_and_replace(old_pw_hint, new_pw_hint, 'PW_HINT_AND_CNIC_LABEL')
print("Patch A (password strength + CNIC label) OK")

# ─────────────────────────────────────────────────────────────────────────────
# B. After the CNIC section (before the Submit button), add police cert + cert fields
# ─────────────────────────────────────────────────────────────────────────────
old_cnic_end = (
    b"            if (_imageSizeError != null)\r\n"
    b"              Padding(\r\n"
    b"                padding: const EdgeInsets.only(top: 8),\r\n"
    b"                child: Row(\r\n"
    b"                  children: [\r\n"
    b"                    const Icon(Icons.warning_amber, color: Colors.red, size: 14),\r\n"
    b"                    const SizedBox(width: 4),\r\n"
    b"                    Expanded(\r\n"
    b"                      child: Text(_imageSizeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),\r\n"
    b"                    ),\r\n"
    b"                  ],\r\n"
    b"                ),\r\n"
    b"              ),\r\n"
    b"            const SizedBox(height: 24),\r\n"
    b"          ],\r\n"
    b"          SizedBox(\r\n"
)
new_cnic_end = (
    b"            if (_imageSizeError != null)\r\n"
    b"              Padding(\r\n"
    b"                padding: const EdgeInsets.only(top: 8),\r\n"
    b"                child: Row(\r\n"
    b"                  children: [\r\n"
    b"                    const Icon(Icons.warning_amber, color: Colors.red, size: 14),\r\n"
    b"                    const SizedBox(width: 4),\r\n"
    b"                    Expanded(\r\n"
    b"                      child: Text(_imageSizeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),\r\n"
    b"                    ),\r\n"
    b"                  ],\r\n"
    b"                ),\r\n"
    b"              ),\r\n"
    b"            const SizedBox(height: 20),\r\n"
    b"            // Police Certificate (Required)\r\n"
    b"            const Divider(),\r\n"
    b"            const SizedBox(height: 16),\r\n"
    b"            Row(\r\n"
    b"              children: [\r\n"
    b"                const Icon(Icons.policy_outlined, size: 18, color: Color(0xFF0D9488)),\r\n"
    b"                const SizedBox(width: 8),\r\n"
    b"                const Text('Police Character Certificate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),\r\n"
    b"                const SizedBox(width: 4),\r\n"
    b"                Container(\r\n"
    b"                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),\r\n"
    b"                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),\r\n"
    b"                  child: const Text('Required', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),\r\n"
    b"                ),\r\n"
    b"              ],\r\n"
    b"            ),\r\n"
    b"            const SizedBox(height: 6),\r\n"
    b"            Text('Upload image of your police certificate (max 10MB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),\r\n"
    b"            const SizedBox(height: 10),\r\n"
    b"            InkWell(\r\n"
    b"              onTap: _pickPoliceCert,\r\n"
    b"              child: Container(\r\n"
    b"                width: double.infinity,\r\n"
    b"                height: 80,\r\n"
    b"                clipBehavior: Clip.antiAlias,\r\n"
    b"                decoration: BoxDecoration(\r\n"
    b"                  color: _policeCertFile != null ? const Color(0xFFF0FDFA) : Colors.grey.shade50,\r\n"
    b"                  borderRadius: BorderRadius.circular(10),\r\n"
    b"                  border: Border.all(\r\n"
    b"                    color: _policeCertError != null ? Colors.red : (_policeCertFile != null ? const Color(0xFF0D9488) : Colors.grey.shade300),\r\n"
    b"                    width: _policeCertFile != null ? 1.5 : 1,\r\n"
    b"                  ),\r\n"
    b"                ),\r\n"
    b"                child: _policeCertFile != null\r\n"
    b"                    ? Row(\r\n"
    b"                        mainAxisAlignment: MainAxisAlignment.center,\r\n"
    b"                        children: [\r\n"
    b"                          const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 22),\r\n"
    b"                          const SizedBox(width: 10),\r\n"
    b"                          Text('Certificate uploaded', style: TextStyle(color: const Color(0xFF0D9488), fontWeight: FontWeight.w600, fontSize: 13)),\r\n"
    b"                        ],\r\n"
    b"                      )\r\n"
    b"                    : Row(\r\n"
    b"                        mainAxisAlignment: MainAxisAlignment.center,\r\n"
    b"                        children: [\r\n"
    b"                          const Icon(Icons.upload_file_outlined, color: Colors.grey, size: 26),\r\n"
    b"                          const SizedBox(width: 10),\r\n"
    b"                          Text('Tap to upload certificate', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),\r\n"
    b"                        ],\r\n"
    b"                      ),\r\n"
    b"              ),\r\n"
    b"            ),\r\n"
    b"            if (_policeCertError != null)\r\n"
    b"              Padding(\r\n"
    b"                padding: const EdgeInsets.only(top: 4),\r\n"
    b"                child: Text(_policeCertError!, style: const TextStyle(color: Colors.red, fontSize: 11)),\r\n"
    b"              ),\r\n"
    b"            const SizedBox(height: 20),\r\n"
    b"            // Certification / Specialization (Optional)\r\n"
    b"            const Divider(),\r\n"
    b"            const SizedBox(height: 16),\r\n"
    b"            Row(\r\n"
    b"              children: [\r\n"
    b"                const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFF0D9488)),\r\n"
    b"                const SizedBox(width: 8),\r\n"
    b"                const Text('Certification / Specialization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),\r\n"
    b"                const SizedBox(width: 4),\r\n"
    b"                Container(\r\n"
    b"                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),\r\n"
    b"                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),\r\n"
    b"                  child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),\r\n"
    b"                ),\r\n"
    b"              ],\r\n"
    b"            ),\r\n"
    b"            const SizedBox(height: 6),\r\n"
    b"            Text('Upload any trade certificate, specialization diploma, etc.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),\r\n"
    b"            const SizedBox(height: 10),\r\n"
    b"            InkWell(\r\n"
    b"              onTap: _pickCertification,\r\n"
    b"              child: Container(\r\n"
    b"                width: double.infinity,\r\n"
    b"                height: 80,\r\n"
    b"                clipBehavior: Clip.antiAlias,\r\n"
    b"                decoration: BoxDecoration(\r\n"
    b"                  color: _certificationFile != null ? const Color(0xFFF0FDFA) : Colors.grey.shade50,\r\n"
    b"                  borderRadius: BorderRadius.circular(10),\r\n"
    b"                  border: Border.all(\r\n"
    b"                    color: _certificationFile != null ? const Color(0xFF0D9488) : Colors.grey.shade300,\r\n"
    b"                    width: _certificationFile != null ? 1.5 : 1,\r\n"
    b"                  ),\r\n"
    b"                ),\r\n"
    b"                child: _certificationFile != null\r\n"
    b"                    ? Row(\r\n"
    b"                        mainAxisAlignment: MainAxisAlignment.center,\r\n"
    b"                        children: [\r\n"
    b"                          const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 22),\r\n"
    b"                          const SizedBox(width: 10),\r\n"
    b"                          Text('Certificate uploaded', style: TextStyle(color: const Color(0xFF0D9488), fontWeight: FontWeight.w600, fontSize: 13)),\r\n"
    b"                          const SizedBox(width: 8),\r\n"
    b"                          GestureDetector(\r\n"
    b"                            onTap: () => setState(() => _certificationFile = null),\r\n"
    b"                            child: const Icon(Icons.close, size: 16, color: Colors.grey),\r\n"
    b"                          ),\r\n"
    b"                        ],\r\n"
    b"                      )\r\n"
    b"                    : Row(\r\n"
    b"                        mainAxisAlignment: MainAxisAlignment.center,\r\n"
    b"                        children: [\r\n"
    b"                          const Icon(Icons.upload_file_outlined, color: Colors.grey, size: 26),\r\n"
    b"                          const SizedBox(width: 10),\r\n"
    b"                          Text('Tap to upload (optional)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),\r\n"
    b"                        ],\r\n"
    b"                      ),\r\n"
    b"              ),\r\n"
    b"            ),\r\n"
    b"            const SizedBox(height: 24),\r\n"
    b"          ],\r\n"
    b"          SizedBox(\r\n"
)
content = check_and_replace(old_cnic_end, new_cnic_end, 'POLICE_CERT_AND_CERT_FIELDS')
print("Patch B (police cert + certification fields) OK")

# ─────────────────────────────────────────────────────────────────────────────
# C. Add _pwRequirementRow helper method BEFORE the _signupFlow method
# ─────────────────────────────────────────────────────────────────────────────
old_signup_flow_start = b'  Widget _signupFlow() {\r\n'
new_with_helper = (
    b'  Widget _pwRequirementRow(String text, bool met) {\r\n'
    b'    return Padding(\r\n'
    b'      padding: const EdgeInsets.symmetric(vertical: 2),\r\n'
    b'      child: Row(\r\n'
    b'        children: [\r\n'
    b'          AnimatedContainer(\r\n'
    b'            duration: const Duration(milliseconds: 200),\r\n'
    b'            width: 16, height: 16,\r\n'
    b'            decoration: BoxDecoration(\r\n'
    b'              shape: BoxShape.circle,\r\n'
    b'              color: met ? const Color(0xFF059669) : Colors.grey.shade300,\r\n'
    b'            ),\r\n'
    b'            child: met\r\n'
    b'                ? const Icon(Icons.check, size: 10, color: Colors.white)\r\n'
    b'                : null,\r\n'
    b'          ),\r\n'
    b'          const SizedBox(width: 8),\r\n'
    b'          Text(\r\n'
    b'            text,\r\n'
    b'            style: TextStyle(\r\n'
    b'              fontSize: 12,\r\n'
    b'              color: met ? const Color(0xFF059669) : Colors.grey.shade500,\r\n'
    b'              fontWeight: met ? FontWeight.w600 : FontWeight.normal,\r\n'
    b'              decoration: met ? TextDecoration.none : TextDecoration.none,\r\n'
    b'            ),\r\n'
    b'          ),\r\n'
    b'        ],\r\n'
    b'      ),\r\n'
    b'    );\r\n'
    b'  }\r\n'
    b'\r\n'
    b'  Widget _signupFlow() {\r\n'
)
if old_signup_flow_start not in content:
    raise ValueError("_signupFlow start not found")
content = content.replace(old_signup_flow_start, new_with_helper, 1)
print("Patch C (_pwRequirementRow helper) OK")

# ─────────────────────────────────────────────────────────────────────────────
# D. Reduce WorkerCategorySelectScreen to only Plumber + Electrician
# ─────────────────────────────────────────────────────────────────────────────
old_categories = (
    b"  static const _categories = [\r\n"
    b"    {\r\n"
    b"      'key': 'plumber',\r\n"
    b"      'title': 'Plumber',\r\n"
    b"      'subtitle': 'Pipes, leaks, drainage & water systems',\r\n"
    b"      'icon': Icons.plumbing,\r\n"
    b"      'color': Color(0xFF0EA5E9),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'electrician',\r\n"
    b"      'title': 'Electrician',\r\n"
    b"      'subtitle': 'Wiring, fittings, panels & electrician repairs',\r\n"
    b"      'icon': Icons.electrical_services,\r\n"
    b"      'color': Color(0xFFF59E0B),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'carpenter',\r\n"
    b"      'title': 'Carpenter',\r\n"
    b"      'subtitle': 'Woodwork, furniture, doors & cabinets',\r\n"
    b"      'icon': Icons.handyman,\r\n"
    b"      'color': Color(0xFF8B5CF6),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'acmechanic',\r\n"
    b"      'title': 'AC Mechanic',\r\n"
    b"      'subtitle': 'AC repair, service, installation & gas refill',\r\n"
    b"      'icon': Icons.ac_unit,\r\n"
    b"      'color': Color(0xFF06B6D4),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'painter',\r\n"
    b"      'title': 'Painter',\r\n"
    b"      'subtitle': 'Wall painting, polish, texture & finishing',\r\n"
    b"      'icon': Icons.format_paint,\r\n"
    b"      'color': Color(0xFFEC4899),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'cleaner',\r\n"
    b"      'title': 'Cleaner',\r\n"
    b"      'subtitle': 'Deep cleaning, sofa, kitchen & full house',\r\n"
    b"      'icon': Icons.cleaning_services,\r\n"
    b"      'color': Color(0xFF10B981),\r\n"
    b"    },\r\n"
    b"  ];\r\n"
)
new_categories = (
    b"  static const _categories = [\r\n"
    b"    {\r\n"
    b"      'key': 'plumber',\r\n"
    b"      'title': 'Plumber',\r\n"
    b"      'subtitle': 'Pipes, leaks, drainage & water systems',\r\n"
    b"      'icon': Icons.plumbing,\r\n"
    b"      'color': Color(0xFF0EA5E9),\r\n"
    b"    },\r\n"
    b"    {\r\n"
    b"      'key': 'electrician',\r\n"
    b"      'title': 'Electrician',\r\n"
    b"      'subtitle': 'Wiring, fittings, panels & electrical repairs',\r\n"
    b"      'icon': Icons.electrical_services,\r\n"
    b"      'color': Color(0xFFF59E0B),\r\n"
    b"    },\r\n"
    b"  ];\r\n"
)
content = check_and_replace(old_categories, new_categories, 'CATEGORIES')
print("Patch D (categories trimmed to 2) OK")

# ─────────────────────────────────────────────────────────────────────────────
# E. Update _categoryKeyToIndex to only handle plumber + electrician
# ─────────────────────────────────────────────────────────────────────────────
old_key_to_index = (
    b"  int _categoryKeyToIndex(String key) {\r\n"
    b"    switch (key) {\r\n"
    b"      case 'plumber': return 0;\r\n"
    b"      case 'electrician': return 1;\r\n"
    b"      case 'carpenter': return 2;\r\n"
    b"      case 'acmechanic': return 3;\r\n"
    b"      case 'painter': return 4;\r\n"
    b"      case 'cleaner': return 5;\r\n"
    b"      default: return 0;\r\n"
    b"    }\r\n"
    b"  }\r\n"
)
new_key_to_index = (
    b"  int _categoryKeyToIndex(String key) {\r\n"
    b"    switch (key) {\r\n"
    b"      case 'plumber': return 0;\r\n"
    b"      case 'electrician': return 1;\r\n"
    b"      default: return 0;\r\n"
    b"    }\r\n"
    b"  }\r\n"
)
content = check_and_replace(old_key_to_index, new_key_to_index, 'KEY_TO_INDEX')
print("Patch E (_categoryKeyToIndex) OK")

with open(FILE, 'wb') as f:
    f.write(content)

print("\nAll UI patches applied successfully!")
