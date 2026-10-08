"""Top-down NOW vs +8 mock for the Porto promenade. Image = Studio straight-down capture (cam y 95.1, FOV 30,
looking at (238,-46.7,-655)); screen up = +X (shops), right = +Z (north)."""
import re, math
from PIL import Image, ImageDraw, ImageFont
SRC = r'C:\Users\slard\.claude\projects\C--Users-slard\396c58ec-3e4f-4bbd-9d54-a851d5aca070\tool-results\mcp-computer-use-blob-1791241541138-wm2mf4.jpg'
OUT = r'C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\396c58ec-3e4f-4bbd-9d54-a851d5aca070\scratchpad\promenade'
im = Image.open(SRC).convert('RGB'); W, H = im.size
K = 222.5 / (141.8 * math.tan(math.radians(15)))
def px(z): return (836 + (z + 655) * K) * W / 1672
def py(x): return (222.5 - (x - 238) * K) * H / 445
SY = K * H / 445            # image px per stud (vertical)
print('img', W, H, 'px/stud', SY)

# wall sea face per z from the survey (coping + ashlar min x)
L = open(r'C:\Users\slard\roblox-props\tools\italy_squirrels\probe_promenade_out.txt', encoding='utf-8-sig').read().splitlines()
wall = []
for l in L:
    if ('Seawall ashlar' in l or 'Rounded coping' in l) and l.startswith('QPR@item'):
        m = re.search(r'min ([-\d.]+),[-\d.]+,([-\d.]+) max ([-\d.]+),[-\d.]+,([-\d.]+)', l)
        wall.append(tuple(map(float, m.groups())))
def edge_x(z):
    xs = [a for a, z0, b, z1 in wall if z0 - 0.6 <= z <= z1 + 0.6]
    return min(xs) if xs else None

Z0, Z1 = -599.4, -698.6           # promenade extent along the quay
def zones(z):
    """(sea_limit, x_mid, x_shop): x < x_mid moves 8, x_mid..x_shop moves 4, >= x_shop stays."""
    e = edge_x(min(-599.4, max(-698.6, z)))
    if e is None: return None
    sea = e - 0.3
    if -640.2 <= z <= -633.8: sea = 228.6       # Pescatori gangway
    if -688.2 <= z <= -681.8: sea = 225.6       # Reti gangway
    x_mid = 244.0
    if -628.0 <= z <= -626.2: x_mid = 247.6     # nets rack straddles
    if -640.2 <= z <= -633.8: x_mid = 245.5     # Pescatori landing stone moves with the edge
    if -695.0 <= z <= -693.0: x_mid = 245.0     # south lantern
    x_shop = 253.0
    if z >= -604: x_shop = 246.0                # Capitaneria front + its lemon tree stay
    if -657.0 <= z <= -637.2: x_shop = 261.25 if -649.0 <= z <= -647.0 else 262.6   # whole fish market moves 4 (lantern at 262 stays)
    if -637.2 < z <= -635.5: x_shop = 260.0     # Beppe's crate moves, last gelato chair stays
    return sea, x_mid, x_shop

# paving texture sample: clear cobbles x 240..251, z -604..-611
pv = im.crop((int(px(-611)), int(py(251)), int(px(-604)), int(py(240))))
def pave(w, h):
    t = Image.new('RGB', (w, h))
    for yy in range(0, h, pv.size[1]):
        for xx in range(0, w, pv.size[0]): t.paste(pv, (xx, yy))
    return t
tile = pave(W, H)

DE, DM = 10, 5
# Stella Marina slides 4 studs out to sea: cut her (+shadow) and paste 4 lower; refill with open water
bx0, bx1, bz0, bz1 = 216.0, 232.5, -652.0, -641.5
box = (int(px(bz0)), int(py(bx1)), int(px(bz1)) + 1, int(py(bx0)) + 1)
boat = im.crop(box)
sea = im.crop((int(px(bz0 - 10.5)), int(py(bx1)), int(px(bz1 - 10.5)) + 1, int(py(bx0)) + 1))
im.paste(sea.resize(boat.size), box[:2])
im.paste(boat, (box[0], box[1] + int(round(2 * SY))))
out = im.copy()
src = im.load(); dst = out.load(); tl = tile.load()
c0, c1 = int(px(Z1)), int(px(Z0)) + 1
for c in range(c0, c1):
    z = -655 + ((c * 1672 / W) - 836) / K
    zz = zones(z)
    if not zz: continue
    sea, xm, xs = zz
    r_sea, r_mid, r_shop = py(sea), py(xm), py(xs)     # rows (sea is the largest row)
    d8, d4 = DE * SY, DM * SY
    # paint from the sea side inward so later writes win
    for r in range(int(r_mid), int(min(H - 1, r_sea + d8)) + 1):          # edge zone, moved 8
        s = r - d8
        if r_mid <= s <= r_sea: dst[c, r] = src[c, int(s)]
    for r in range(int(r_mid - d8), int(r_mid)):                          # gap -> paving (edge zone top moved)
        pass
    for r in range(int(r_shop), int(r_mid + d4) + 1):                     # middle zone, moved 4
        s = r - d4
        if r_shop <= s <= r_mid: dst[c, r] = src[c, int(s)]
    for r in range(int(r_shop), int(r_shop + d4)):                        # gap behind middle -> paving
        o = src[c, r]
        dst[c, r] = tl[c, r]
    for r in range(int(r_mid + d4), int(r_mid + d8)):                     # gap between middle and edge -> paving
        o = src[c, r]
        dst[c, r] = tl[c, r]

def crop(img):
    return img.crop((int(px(-722)), 0, int(px(-583)), H)).resize(None or (int((px(-583) - px(-722)) * 2), H * 2), Image.LANCZOS)
now, plan = crop(Image.open(SRC).convert('RGB')), crop(out)
now.save(OUT + '_now.png'); plan.save(OUT + '_plan10.png')
print('saved', now.size)


for z in (-646, -669, -627, -615):
    print('edge at z', z, edge_x(z))

