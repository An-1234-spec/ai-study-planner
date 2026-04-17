import sys
import re

log_path = r"C:\Users\User\.gemini\antigravity\brain\9f05cb89-c95e-4b21-b438-03a30087ba01\.system_generated\logs\overview.txt"
output_path = r"c:\Users\User\Desktop\AI STUDY PLANNER\login_screen\lib\screens\timetable_screen.dart"

with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out_lines = []
capturing = False

# Find the most recent deletion block for timetable_screen.dart
for i in range(len(lines)):
    if "The following changes were made by the USER to: c:\\Users\\User\\Desktop\\AI STUDY PLANNER\\login_screen\\lib\\screens\\timetable_screen.dart" in lines[i]:
        # found the user paste
        for j in range(i, len(lines)):
            if "@@ -1,817 +1,269 @@" in lines[j]:
                capturing = True
                continue
            if capturing:
                if "[diff_block_end]" in lines[j]:
                    break
                # Only keep deleted lines (which represent the old file state)
                # and unchanged lines (if any, though it's a full replace)
                if lines[j].startswith('-'):
                    out_lines.append(lines[j][1:])
                elif lines[j].startswith(' ') and not lines[j].startswith('  '): 
                    # standard diff context line (1 space)
                    out_lines.append(lines[j][1:])
        break

if out_lines:
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
    print("RESTORED!")
else:
    print("FAILED TO FIND")
