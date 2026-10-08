"""Painted mountain backdrop for Porto Nocciola (Oct 4 2026): a 3-panel seamless panorama (each 1024x717, together periodic),
three ranges with atmospheric haze plus a near green ridge with cypress/pine silhouettes; sky fully transparent.
Panel = 200 x 140 studs, image top = y 170, bottom = y 30. Writes backdrop_A/B/C.png, preview.png and a carrier OBJ
(3 quads, one texture each) for Studio's Import 3D, which uploads the textures."""
import math, random, os
from PIL import Image, ImageDraw, ImageFilter
D = os.path.dirname(os.path.abspath(__file__))
W, H, N = 1024, 717, 3
TW = W * N
random.seed(1004)
def make_noise(seed, cells):
    r = random.Random(seed); return [r.uniform(-1, 1) for _ in range(cells)]
def vnoise(lat, x):                  # periodic value noise over TW, cosine-interpolated
    n = len(lat); f = x / TW * n; i = int(math.floor(f)); t = f - i
    t = (1 - math.cos(t * math.pi)) / 2
    return lat[i % n] * (1 - t) + lat[(i + 1) % n] * t
def ridge_line(seed, base, amp, oct0, octs, rough, ridged):
    lats = [make_noise(seed + o, oct0 * 2 ** o) for o in range(octs)]
    out = []
    for x in range(TW):
        v, a, tot = 0.0, 1.0, 0.0
        for o in range(octs):
            nv = vnoise(lats[o], x)
            if ridged and o < 3: nv = 1 - 2 * abs(nv)      # sharper crests on the big shapes
            v += a * nv; tot += a; a *= rough
        out.append(base + amp * v / tot)
    return out
def y_of_stud(y):                    # stud height -> image row
    return (170 - y) / 140 * H
# ranges: (seed, base, amplitude, first-octave cells, octaves, roughness, ridged, colour top, colour bottom)
RANGES = [
    (11, 140, 22, 7, 7, 0.52, True,  (176, 192, 207), (194, 207, 218)),
    (23, 108, 16, 9, 7, 0.55, True,  (139, 162, 160), (163, 182, 180)),
    (37,  74,  8, 13, 6, 0.5, False, (104, 137, 103), (124, 153, 116)),
]
img = Image.new('RGBA', (TW, H), (0, 0, 0, 0))
px = img.load()
LINES = []
for seed, base, amp, c0, octs, rough, ridged, ct, cb in RANGES:
    ridge = ridge_line(seed, base, amp, c0, octs, rough, ridged)
    LINES.append(ridge)
    for x in range(TW):
        top = int(max(0, y_of_stud(ridge[x])))
        for y in range(top, H):
            t = min(1.0, (y - top) / 120)          # haze thickens toward each range's foot
            c = tuple(int(ct[i] * (1 - t) + cb[i] * t) for i in range(3))
            px[x, y] = c + (255,)
# cypresses and umbrella pines on the near ridge
near = LINES[2]
dr = ImageDraw.Draw(img)
x = 0
while x < TW:
    r = near[x]
    yb = y_of_stud(r) + 3
    if random.random() < 0.45:
        h = random.uniform(14, 26); w = h * 0.22
        dr.polygon([(x - w, yb), (x, yb - h), (x + w, yb)], fill=(66, 96, 70, 255))
        dr.ellipse([x - w * 0.9, yb - h * 0.55, x + w * 0.9, yb + 1], fill=(66, 96, 70, 255))
    else:
        h = random.uniform(9, 14); w = h * 0.9
        dr.line([(x, yb), (x, yb - h * 0.7)], fill=(80, 70, 58, 255), width=2)
        dr.ellipse([x - w, yb - h, x + w, yb - h * 0.55], fill=(74, 104, 72, 255))
    x += random.randint(6, 40) if random.random() < 0.8 else random.randint(60, 140)
# soften edges a touch (keeps the silhouette crisp but not jagged)
a = img.split()[3].filter(ImageFilter.GaussianBlur(0.6))
img.putalpha(a)
for i, name in enumerate('ABC'):
    tile = img.crop((i * W, 0, (i + 1) * W, H))
    tile.save(os.path.join(D, f'backdrop_{name}.png'))
prev = Image.new('RGB', (TW, H), (150, 196, 232))
prev.paste(img, (0, 0), img)
prev.resize((TW // 2, H // 2)).save(os.path.join(D, 'preview.png'))
# carrier: three 20x14 quads side by side, each with its own material/texture (Import 3D uploads the textures)
with open(os.path.join(D, 'backdrop_carrier.mtl'), 'w') as f:
    for n in 'ABC':
        f.write(f'newmtl bd{n}\nKd 1 1 1\nmap_Kd backdrop_{n}.png\n\n')
with open(os.path.join(D, 'backdrop_carrier.obj'), 'w') as f:
    f.write('mtllib backdrop_carrier.mtl\n')
    v = 1
    for i, n in enumerate('ABC'):
        x0 = i * 22
        f.write(f'o Backdrop_{n}\n')
        for (x, y) in ((x0, 0), (x0 + 20, 0), (x0 + 20, 14), (x0, 14)):
            f.write(f'v {x} {y} 0\n')
        f.write('vt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\n')
        f.write(f'usemtl bd{n}\nf {v}/{v}/{i+1} {v+1}/{v+1}/{i+1} {v+2}/{v+2}/{i+1} {v+3}/{v+3}/{i+1}\n')
        v += 4
print('ok', TW, H)
