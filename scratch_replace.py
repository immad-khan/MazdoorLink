import os
import re

directory = r"d:\Desktop\MazdoorLink\lib"

def replace_preserve_case(match):
    word = match.group(0)
    if word == "electrical":
        return "electrician"
    elif word == "Electrical":
        return "Electrician"
    elif word == "ELECTRICAL":
        return "ELECTRICIAN"
    return word

count = 0
for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content, num_subs = re.subn(r'\belectrical\b', replace_preserve_case, content, flags=re.IGNORECASE)
            
            if num_subs > 0:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += num_subs

print(f"Replaced {count} occurrences of 'electrical' with 'electrician'.")
