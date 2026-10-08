"""gen_falls2.py: two high-contrast waterfall textures for Beams (512 x 1024, RGBA, alpha gaps between the strands) and a
two-quad Import 3D carrier (falls2_carrier.obj/.mtl) whose materials map them, so Studio uploads both as image assets.
  falls2_strands.png : dense strands, 3-24 px wide, brightness varied, ~50% coverage (the main layers)
  falls2_wisps.png   : sparse fine wisps, ~18% coverage (the overlay layer)
The gaps are fully transparent so whatever is behind (the dark wet backdrop) shows between the strands."""
import numpy as np
from PIL import Image, ImageFilter
import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
W, H = 512, 1024
rng = np.random.default_rng(5)

def strands(n, wmin, wmax, bright, coverage_target):
    # each strand: a vertical ribbon with a slow horizontal wobble, soft edges, its own brightness and a few breaks
    alpha = np.zeros((H, W), np.float32)
    lum = np.zeros((H, W), np.float32)
    x = np.arange(W)[None, :]
    y = np.arange(H)[:, None]
    for i in range(n):
        cx0 = rng.uniform(0, W)
        w = rng.uniform(wmin, wmax)
        amp = rng.uniform(2, 9)
        ph = rng.uniform(0, 2 * np.pi)
        per = rng.uniform(300, 900)
        cx = cx0 + amp * np.sin(2 * np.pi * y / per + ph)        # wobble along the length (seamless-ish: per divides ~H)
        d = np.abs(((x - cx + W / 2) % W) - W / 2)                 # wrap horizontally so the texture tiles sideways
        core = np.clip(1 - (d / (w / 2)) ** 2, 0, 1)
        b = rng.uniform(bright[0], bright[1])
        # breaks: fade the strand out and in along its length a few times
        nb = rng.integers(1, 4)
        env = np.ones((H, 1), np.float32)
        for _ in range(nb):
            y0 = rng.uniform(0, H); L = rng.uniform(60, 220)
            env *= 1 - 0.85 * np.exp(-((((y - y0 + H / 2) % H) - H / 2) / L) ** 2)
        a = core * env * b
        alpha = np.maximum(alpha, a)
        lum = np.maximum(lum, a)
    return alpha, lum

def make(name, n, wmin, wmax, bright, blur):
    alpha, lum = strands(n, wmin, wmax, bright, None)
    # vertical motion blur so the strands read as streaks, and a tiny horizontal softening
    img_a = Image.fromarray((np.clip(alpha, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))
    a = np.array(img_a).astype(np.float32) / 255
    # colour: white with a hint of mint in the fainter parts
    r = 236 + 19 * a; g = 246 + 9 * a; b = 250 + 5 * a
    rgba = np.stack([r, g, b, 255 * np.clip(a * 1.15, 0, 1)], axis=-1).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(name)
    print(name, "alpha mean %.2f" % (a.mean()))

make("falls2_strands.png", 150, 3, 24, (0.55, 1.0), 1.2)
make("falls2_wisps.png", 55, 2, 9, (0.5, 0.9), 1.0)

obj = """# falls2 texture carrier: two quads, one material each, so Import 3D uploads both images
mtllib falls2_carrier.mtl
o Falls2Strands
g Falls2Strands
usemtl Falls2Strands
v -2 -2 0
v 2 -2 0
v 2 2 0
v -2 2 0
vt 0 0
vt 1 0
vt 1 1
vt 0 1
vn 0 0 1
f 1/1/1 2/2/1 3/3/1
f 1/1/1 3/3/1 4/4/1
o Falls2Wisps
g Falls2Wisps
usemtl Falls2Wisps
v 6 -2 0
v 10 -2 0
v 10 2 0
v 6 2 0
vt 0 0
vt 1 0
vt 1 1
vt 0 1
vn 0 0 1
f 5/5/2 6/6/2 7/7/2
f 5/5/2 7/7/2 8/8/2
"""
open("falls2_carrier.obj", "w", newline="\n").write(obj)
open("falls2_carrier.mtl", "w", newline="\n").write("newmtl Falls2Strands\nKd 1 1 1\nmap_Kd falls2_strands.png\n\nnewmtl Falls2Wisps\nKd 1 1 1\nmap_Kd falls2_wisps.png\n")
print("carrier written")
