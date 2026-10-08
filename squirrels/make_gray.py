"""Gray twin texture like the earlier squirrels: luminance with a percentile stretch (1% -> 0, 99.5% -> 255).
Run: python make_gray.py <folder> <name>  (reads <name>_1k.png, writes <name>_gray_1k.png)"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
d, n = Path(sys.argv[1]), sys.argv[2]
a = np.asarray(Image.open(d / f"{n}_1k.png").convert("RGB")).astype(np.float32)
L = a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114
lo, hi = np.percentile(L, 1), np.percentile(L, 99.5)
g = np.clip((L - lo) * 255.0 / max(hi - lo, 1), 0, 255).astype(np.uint8)
Image.fromarray(np.stack([g, g, g], -1)).save(d / f"{n}_gray_1k.png")
print("gray written", lo, hi)
