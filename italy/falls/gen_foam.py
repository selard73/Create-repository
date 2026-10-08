"""gen_foam.py: a patchy foam texture for the rapids beams (512 x 1024 RGBA): white foam streaks and blotches stretched along
the flow (V), ~40% coverage, fully transparent between them so the dark teal river shows through (her rapids reference:
foam in patches on dark water, not a solid white sheet). Plus a one-quad Import 3D carrier."""
import numpy as np
from PIL import Image, ImageFilter
import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
W, H = 512, 1024
rng = np.random.default_rng(9)
alpha = np.zeros((H, W), np.float32)
x = np.arange(W)[None, :]
y = np.arange(H)[:, None]
# long streaks (foam lines along the flow)
for i in range(90):
    cx0 = rng.uniform(0, W); w = rng.uniform(3, 14); L = rng.uniform(120, 420); y0 = rng.uniform(0, H)
    amp = rng.uniform(2, 10); ph = rng.uniform(0, 2 * np.pi); per = rng.uniform(200, 600)
    cx = cx0 + amp * np.sin(2 * np.pi * y / per + ph)
    d = np.abs(((x - cx + W / 2) % W) - W / 2)
    core = np.clip(1 - (d / (w / 2)) ** 2, 0, 1)
    env = np.exp(-((((y - y0 + H / 2) % H) - H / 2) / (L / 2)) ** 2)
    alpha = np.maximum(alpha, core * env * rng.uniform(0.6, 1.0))
# blotches (boils)
for i in range(140):
    cx0 = rng.uniform(0, W); cy0 = rng.uniform(0, H); rx = rng.uniform(8, 30); ry = rng.uniform(16, 70)
    dx = ((x - cx0 + W / 2) % W) - W / 2
    dy = ((y - cy0 + H / 2) % H) - H / 2
    blob = np.clip(1 - (dx / rx) ** 2 - (dy / ry) ** 2, 0, 1) ** 0.7
    alpha = np.maximum(alpha, blob * rng.uniform(0.5, 1.0))
a = np.array(Image.fromarray((np.clip(alpha, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))).astype(np.float32) / 255
a = np.clip(a * 1.2, 0, 1)
rgba = np.stack([np.full_like(a, 244), np.full_like(a, 250), np.full_like(a, 255), 255 * a], axis=-1).astype(np.uint8)
Image.fromarray(rgba, "RGBA").save("falls2_foam.png")
print("falls2_foam.png alpha mean %.2f" % a.mean())
bg = Image.new("RGBA", (W, H), (30, 70, 80, 255)); bg.alpha_composite(Image.fromarray(rgba, "RGBA")); bg.convert("RGB").resize((256, 512)).save("falls2_foam_over_dark.jpg", quality=85)
open("falls2_foam_carrier.obj", "w", newline="\n").write("""# foam texture carrier
mtllib falls2_foam_carrier.mtl
o Falls2Foam
g Falls2Foam
usemtl Falls2Foam
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
""")
open("falls2_foam_carrier.mtl", "w", newline="\n").write("newmtl Falls2Foam\nKd 1 1 1\nmap_Kd falls2_foam.png\n")
print("carrier written")
