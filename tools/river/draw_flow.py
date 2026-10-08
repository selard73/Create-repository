"""Annotate the Studio top-down river shot with the proposed flow direction (viewport px from cam_topdown3/rim_walls)."""
from PIL import Image, ImageDraw, ImageFont
import math

S = 1568 / 1631
src = Image.open("topdown_raw.jpg").convert("RGBA")
W, H = src.size
TOP, BOT = 70, 96
img = Image.new("RGBA", (W, H + TOP + BOT), (250, 247, 240, 255))
img.paste(src, (0, TOP))

def P(x, y):  # viewport px -> image px
    return (x * S, y * S + TOP)

F = "C:/Windows/Fonts/"
f_title = ImageFont.truetype(F + "arialbd.ttf", 30)
f_lab = ImageFont.truetype(F + "arialbd.ttf", 19)
f_small = ImageFont.truetype(F + "arial.ttf", 17)

# shade what lies outside the map today (rim walls: village z=-205 at vx 516 / forest z=-215 at vx 489; village z=5 at 1087 / forest z=25 at 1141)
ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
od = ImageDraw.Draw(ov)
left = [P(0, 0), P(516, 0), P(516, 352), P(489, 352), P(489, 490), P(0, 490)]
right = [P(1087, 0), P(1631, 0), P(1631, 490), P(1141, 490), P(1141, 432), P(1087, 432)]
for poly in (left, right):
    od.polygon(poly, fill=(20, 20, 30, 120))
img = Image.alpha_composite(img, ov)
d = ImageDraw.Draw(img)
d.line(left[1:5], fill=(255, 255, 255, 230), width=3)
d.line([right[0], right[5], right[4], right[3]], fill=(255, 255, 255, 230), width=3)

cl = [(350, 197), (404, 213), (459, 250), (513, 284), (568, 296), (622, 297), (676, 298), (731, 298), (785, 297), (839, 297),
      (894, 296), (948, 294), (1003, 274), (1057, 236), (1111, 204), (1166, 202), (1220, 238)]
pts = [P(*c) for c in cl]

def arrow(a, b, col, w=7, head=20):
    d.line([a, b], fill=col, width=w)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for s in (1, -1):
        d.line([b, (b[0] - head * math.cos(ang + s * 0.5), b[1] - head * math.sin(ang + s * 0.5))], fill=col, width=w)

YEL = (255, 214, 0, 255)
# flow runs north (right) -> south (left): arrows along the centre line, downstream = decreasing index
for i in range(len(pts) - 1, 0, -2):
    a, b = pts[i], pts[i - 1]
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    arrow(a, (mid[0] + (b[0] - a[0]) * 0.35, mid[1] + (b[1] - a[1]) * 0.35), YEL)

def label(xy, text, font=f_lab, fill=(255, 255, 255, 255), bg=(30, 30, 40, 200), anchor="mm"):
    bb = d.textbbox(xy, text, font=font, anchor=anchor)
    d.rounded_rectangle((bb[0] - 7, bb[1] - 5, bb[2] + 7, bb[3] + 5), 6, fill=bg)
    d.text(xy, text, font=font, fill=fill, anchor=anchor)

label(P(1360, 60), "outside the map today", f_small)
label(P(250, 60), "outside the map today", f_small)
label(P(1225, 140), "WATER ENTERS (north edge)", fill=YEL)
label(P(300, 300), "LEAVES TOWN (south edge)", fill=YEL)
label(P(300, 330), "future gorge + boat route out", f_small)
label(P(745, 350), "bridge (untouched)", f_small)
label(P(1020, 120), "painter + easels (untouched)", f_small)
label(P(584, 455), "swamp", f_small)
label(P(924, 330), "fishing squirrel", f_small)
label(P(975, 160), "village spawn", f_small)

d.text((16, 16), "1001 Squirrels river, seen from above: proposed current = north to south (yellow arrows)", font=f_title, fill=(30, 30, 40))
y = TOP + H + 12
d.text((16, y), "Top of picture = village (Rue de Noisette, street runs up from the bridge).  Bottom = forest.  Dark sides = past the map's edge walls,", font=f_small, fill=(40, 40, 50))
d.text((16, y + 24), "where the river mesh keeps going into empty space.  Inside the map the river is about 210 studs long, between the two white lines.", font=f_small, fill=(40, 40, 50))
d.text((16, y + 48), "Reverse option: flip every arrow (enter south by the swamp, leave north past the painter).", font=f_small, fill=(40, 40, 50))
img.convert("RGB").save("river_flow_proposal.png")
print("ok", img.size)
