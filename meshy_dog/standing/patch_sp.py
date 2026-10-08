from pathlib import Path
import re
p = Path(__file__).parent / "make_standing_scripts.py"
s = p.read_text(encoding="utf-8")
a = s.index("ANIM = r'''"); b = s.index("SITANIM = ")
anim = s[a:b]
anim2 = re.sub(r"\* sit\b(?! blend)", "* sp", anim)
s = s[:a] + anim2 + s[b:]
p.write_text(s, encoding="utf-8")
print("replaced", anim.count("* sit") - anim2.count("* sit"), "occurrences")
