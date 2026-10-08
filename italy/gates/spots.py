# Oct 8 2026: numbered gate markers on the Studio captures (positions projected with proj.Cam)
from PIL import Image, ImageDraw, ImageFont
from proj import Cam
F = ImageFont.truetype('arialbd.ttf', 22)
G = {1: (359, -47, -627), 2: (323, -52, -771), 'F': (340, -44, -604), 3: (379, -5, -1003), 4: (423, 1, -1031), 5: (551, 11, -985),
     6: (680, 49, -759), 7: (703, 59, -759)}
RING = {1: (215, 40, 40), 2: (215, 40, 40), 'F': (40, 90, 160)}
shots = [('porta_borgo.jpg', (312, -36, -606), (362, -44, -632), [1, 'F'], 'spot_1'),
         ('sentiero_start.jpg', (296, -36, -728), (325, -50, -776), [2], 'spot_2'),
         ('junction_over.jpg', (405, 75, -985), (405, -5, -1012), [3, 4], 'spot_34'),
         ('meadow_path.jpg', (566, 28, -962), (546, 10, -1004), [5], 'spot_5'),
         ('terraces.jpg', (640, 85, -705), (695, 55, -765), [6, 7], 'spot_67')]
for src, eye, at, gates, out in shots:
    cam = Cam(eye, at)
    im = Image.open('caps/' + src).convert('RGB'); im = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
    d = ImageDraw.Draw(im, 'RGBA')
    for g in gates:
        s = cam(G[g]); X, Y = s[0] * 2, s[1] * 2
        col = RING.get(g, (120, 40, 190))
        d.line([X, Y, X, Y - 46], fill=col + (255,), width=4)
        d.ellipse([X - 7, Y - 7, X + 7, Y + 7], outline=col + (255,), width=3)
        r = 19; cy = Y - 46 - r
        d.ellipse([X - r, cy - r, X + r, cy + r], fill=(255, 250, 235, 255), outline=col + (255,), width=4)
        d.text((X, cy + 1), str(g), fill=col, font=F, anchor='mm')
    im.save('page/img/' + out + '.jpg', quality=88)
