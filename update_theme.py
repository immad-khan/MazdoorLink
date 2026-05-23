import os
import glob
import re

mapping = {
    "Color(0xFFE5E7EB)": "AppTheme.spacer",
    "Color(0xFFF3F4F6)": "AppTheme.notWhite",
    "Color(0xFF374151)": "AppTheme.darkText",
    "Color(0xFF1F2937)": "AppTheme.darkerText",
    "Color(0xFF6B7280)": "AppTheme.lightText",
    "Color(0xFF9CA3AF)": "AppTheme.deactivatedText",
    "Color(0xFFD1D5DB)": "AppTheme.deactivatedText"
}

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()
    
    modified = False
    for old, new in mapping.items():
        if old in content:
            content = content.replace(old, new)
            modified = True
            
    if modified:
        if 'app_theme.dart' not in content:
            # Add import after the first import statement
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i + 1, "import 'package:service_frontend/app_theme.dart';")
                    break
            content = '\n'.join(lines)
            
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")
