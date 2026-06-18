import os
import re

file_path = r"d:\Desktop\MazdoorLink\lib\screens\mazdoor_flow.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix the syntax errors where ', duration: ...;' was left over
content = re.sub(r'_showToast\((.*?)\),\s*duration:[^;]+;', r'_showToast(\1);', content)

# 2. Extract the _showToast method and move it outside to be a global showToast
toast_method_pattern = r'  void _showToast\(String message\) \{[\s\S]*?Fluttertoast\.showToast\([\s\S]*?\}\s*'

match = re.search(toast_method_pattern, content)
if match:
    method_str = match.group(0)
    # remove it from its current position
    content = content.replace(method_str, '')
    
    # create the global version
    global_method = method_str.replace('void _showToast', 'void showToast').lstrip()
    
    # insert it near the top, e.g., right after imports
    # let's find the first class definition and put it above that
    class_index = content.find('class ')
    if class_index != -1:
        content = content[:class_index] + global_method + '\n\n' + content[class_index:]

# 3. Rename all calls from _showToast to showToast
content = content.replace('_showToast', 'showToast')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Syntax errors fixed in mazdoor_flow.dart")
