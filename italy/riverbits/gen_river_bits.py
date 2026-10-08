# gen_river_bits.py: two decal images for the river drift (her note, Oct 1 2026: real leaves and twigs, not squares and lines):
# leaf.png = a pale leaf with a midrib and veins (tinted per leaf by Decal.Color3), twig.png = a brown twig with small green
# leaflets (natural colours). 512x512 RGBA, drawn at 4x and downsampled; RGB on the outline colour + alpha mask (no halo).
# Also the Import 3D carrier: two quads, two materials, so Studio uploads both images.
import math
from PIL import Image, ImageDraw
S = 4
N = 512 * S
def leaf_outline(cx, cy, length, width, angle, n=200):
    pts = []
    for i in range(n):
        t = i / (n - 1)
        x = (t - 0.5) * length
        hw = width * math.sin(math.pi * t) ** 0.8 * (1 - 0.15 * t)
        for side in (1,):
            pass
        pts.append((x, hw))
    for i in range(n - 1, -1, -1):
        t = i / (n - 1)
        x = (t - 0.5) * length
        hw = width * math.sin(math.pi * t) ** 0.8 * (1 - 0.15 * t)
        pts.append((x, -hw))
    ca, sa = math.cos(angle), math.sin(angle)
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]
# ---- the leaf
PALE, VEIN, EDGE = (235, 235, 225), (170, 172, 150), (150, 152, 130)
rgb = Image.new("RGB", (N, N), EDGE)
mask = Image.new("L", (N, N), 0)
cx, cy = N / 2, N / 2
pts = leaf_outline(cx, cy, N * 0.86, N * 0.24, math.radians(-28))
for img, fill in ((rgb, PALE), (mask, 255)):
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=fill)
d = ImageDraw.Draw(rgb)
ca, sa = math.cos(math.radians(-28)), math.sin(math.radians(-28))
def L(x, y): return (cx + x * ca - y * sa, cy + x * sa + y * ca)
half = N * 0.43
d.line([L(-half * 0.95, 0), L(half * 0.98, 0)], fill=VEIN, width=6 * S)
for k in range(-4, 5):
    x0 = k * half * 0.19
    for side in (1, -1):
        d.line([L(x0, 0), L(x0 + half * 0.22, side * N * 0.10 * (1 - abs(k) / 6))], fill=VEIN, width=3 * S)
# a short stem
d.line([L(-half * 0.95, 0), L(-half * 1.12, N * 0.02)], fill=(120, 110, 80), width=8 * S)
dm = ImageDraw.Draw(mask)
dm.line([L(-half * 0.95, 0), L(-half * 1.12, N * 0.02)], fill=255, width=8 * S)
rgb = rgb.resize((512, 512), Image.LANCZOS); mask = mask.resize((512, 512), Image.LANCZOS)
rgb.putalpha(mask); rgb.save("leaf.png")
# ---- the twig
BARK, BARK2 = (104, 78, 50), (82, 60, 38)
GREENS = [(96, 140, 62), (122, 160, 70), (150, 170, 66)]
rgb = Image.new("RGB", (N, N), BARK2)
mask = Image.new("L", (N, N), 0)
d = ImageDraw.Draw(rgb); dm = ImageDraw.Draw(mask)
def stick(a, b, w):
    d.line([a, b], fill=BARK, width=w); dm.line([a, b], fill=255, width=w)
    for p in (a, b):
        d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=BARK); dm.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255)
main_a, main_b = (N * 0.08, N * 0.56), (N * 0.94, N * 0.42)
stick(main_a, main_b, 14 * S)
stick((N * 0.40, N * 0.505), (N * 0.62, N * 0.30), 9 * S)
stick((N * 0.66, N * 0.46), (N * 0.80, N * 0.62), 8 * S)
stick((N * 0.22, N * 0.535), (N * 0.30, N * 0.68), 7 * S)
leaves = [((N * 0.62, N * 0.27), 0.22, 0.07, -60), ((N * 0.52, N * 0.38), 0.20, 0.065, -35), ((N * 0.80, N * 0.64), 0.20, 0.065, 55),
          ((N * 0.30, N * 0.70), 0.19, 0.06, 70), ((N * 0.88, N * 0.40), 0.21, 0.07, 10), ((N * 0.14, N * 0.50), 0.18, 0.06, -150)]
for i, (c, ln, wd, ang) in enumerate(leaves):
    g = GREENS[i % 3]
    p = leaf_outline(c[0], c[1], N * ln, N * wd, math.radians(ang), 120)
    d.polygon(p, fill=g); dm.polygon(p, fill=255)
rgb = rgb.resize((512, 512), Image.LANCZOS); mask = mask.resize((512, 512), Image.LANCZOS)
rgb.putalpha(mask); rgb.save("twig.png")
# previews on water blue
for name in ("leaf", "twig"):
    im = Image.open(name + ".png")
    prev = Image.new("RGB", im.size, (70, 120, 150)); prev.paste(im, (0, 0), im); prev.save(name + "_preview.png")
open("riverbits_carrier.obj", "w").write("# river bits carrier: two quads, one material each, so Import 3D uploads both images\nmtllib riverbits_carrier.mtl\no RiverLeaf\ng RiverLeaf\nusemtl RiverLeaf\nv -2 -2 0\nv 2 -2 0\nv 2 2 0\nv -2 2 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/1\nf 1/1/1 3/3/1 4/4/1\no RiverTwig\ng RiverTwig\nusemtl RiverTwig\nv 3 -2 0\nv 7 -2 0\nv 7 2 0\nv 3 2 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nf 5/5/1 6/6/1 7/7/1\nf 5/5/1 7/7/1 8/8/1\n")
open("riverbits_carrier.mtl", "w").write("newmtl RiverLeaf\nKd 1 1 1\nmap_Kd leaf.png\n\nnewmtl RiverTwig\nKd 1 1 1\nmap_Kd twig.png\n")
print("wrote leaf.png twig.png + carrier")
