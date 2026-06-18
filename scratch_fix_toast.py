import os
import re

file_path = r"d:\Desktop\MazdoorLink\lib\screens\mazdoor_flow.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove fluttertoast import
content = content.replace("import 'package:fluttertoast/fluttertoast.dart';\n", "")

# 2. Add main.dart import if not present
if "import '../main.dart';" not in content:
    content = content.replace("import '../app_state.dart';", "import '../main.dart';\nimport '../app_state.dart';")

# 3. Replace the showToast global method
toast_method_pattern = r'void showToast\(String message\) \{[\s\S]*?Fluttertoast\.showToast\([\s\S]*?\}\s*'

new_toast_method = """void showToast(String message) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

"""

match = re.search(toast_method_pattern, content)
if match:
    content = content.replace(match.group(0), new_toast_method)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed fluttertoast usage in favor of global ScaffoldMessenger in mazdoor_flow.dart")
