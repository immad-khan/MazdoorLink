import re

path = r'd:\Desktop\MazdoorLink\lib\screens\mazdoor_flow.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Change _selectedCategory = 'Plumber' to 'Select a category'
content = content.replace("String _selectedCategory = 'Plumber';", "String _selectedCategory = 'Select a category';")

# 2. Change Dropdown items
old_dropdown_items = "items: ['Plumber', 'Electrician'].map((String value) {"
new_dropdown_items = "items: ['Select a category', 'Plumber', 'Electrician'].map((String value) {"
content = content.replace(old_dropdown_items, new_dropdown_items)

# 3. Move Password Requirements block
old_pw_req_block = """          if (role == UserRole.worker) ...[
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
                  items: ['Select a category', 'Plumber', 'Electrician'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Dynamic password strength indicator
          if (_password.text.isNotEmpty || _confirmPassword.text.isNotEmpty) ...[
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
                  const Text('Password requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),
                  _pwRequirementRow('At least 1 uppercase letter', _pwHasUppercase),
                  _pwRequirementRow('At least 1 number', _pwHasDigit),
                  _pwRequirementRow('At least 1 special character (!@#\$...)', _pwHasSpecial),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),"""

new_pw_req_block = """          const SizedBox(height: 10),
          // Dynamic password strength indicator
          if (_password.text.isNotEmpty || _confirmPassword.text.isNotEmpty) ...[
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
                  const Text('Password requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  _pwRequirementRow('At least 8 characters', _pwHasMinLength),
                  _pwRequirementRow('At least 1 uppercase letter', _pwHasUppercase),
                  _pwRequirementRow('At least 1 number', _pwHasDigit),
                  _pwRequirementRow('At least 1 special character (!@#\$...)', _pwHasSpecial),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          if (role == UserRole.worker) ...[
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
                  items: ['Select a category', 'Plumber', 'Electrician'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ],"""

content = content.replace(old_pw_req_block, new_pw_req_block)

# 4. Make Police Certificate Required
old_police_optional = """                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
                ),"""
new_police_required = """                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Required', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                ),"""
content = content.replace(old_police_optional, new_police_required)

# Also need to update the text 'Upload image of your police certificate (max 100KB)' wait, no, the text is fine.
# But I must find the validation function `_next` or `_submit` where police certificate is checked to ensure it enforces requirement.
# Let's save and then we can look at the validation.

# 5. Change "Continue" to "Sign up"
old_button = """              child: _isUploading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Continue'),"""
new_button = """              child: _isUploading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sign up'),"""
content = content.replace(old_button, new_button)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated UI layout successfully")
