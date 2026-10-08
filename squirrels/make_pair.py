"""Side-by-side colour + gray preview: python make_pair.py <squirrel folder>"""
import sys
from pathlib import Path
from PIL import Image

d = Path(sys.argv[1])
a = Image.open(d / "preview_color.png").convert("RGB")
b = Image.open(d / "preview_gray.png").convert("RGB")
w, h = a.size
pair = Image.new("RGB", (w * 2, h), (220, 224, 234))
pair.paste(a, (0, 0))
pair.paste(b, (w, 0))
pair.save(d / "preview_pair.png")
print("pair written", pair.size)
