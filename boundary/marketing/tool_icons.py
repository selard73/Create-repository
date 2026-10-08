"""Hotbar icons for the two tools, drawn to match the in-game models: binoculars (two dark barrels, red lenses,
steel bridge) and the slingshot (wooden fork, dark band, leather pouch). Transparent 256x256 PNGs, drawn at 4x and
downsampled. Roblox shows Tool.TextureId in the hotbar slot instead of the tool's name.
Run: python tool_icons.py  -> icon_binoculars.png, icon_slingshot.png (in this folder)."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFilter

D = Path(__file__).parent
SZ, K = 256, 4                       # output size, supersample
W = SZ * K
BLACK, STEEL, LENS, GLINT = (44, 42, 48), (150, 152, 160), (205, 62, 62), (255, 170, 170)
WOOD, WOOD_DARK, BAND, POUCH = (176, 122, 66), (110, 72, 38), (46, 42, 42), (110, 74, 44)
OUTLINE = (30, 22, 34)


def shadow(img, blur=18, dy=10, alpha=110):
    """a soft drop shadow under whatever is drawn, so the icon sits on the dark slot"""
    a = img.split()[3].filter(ImageFilter.GaussianBlur(blur))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh.putalpha(a.point(lambda v: int(v * alpha / 255)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (0, dy))
    out.alpha_composite(img)
    return out


def rrect(d, box, r, fill, outline=None, width=0):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def binoculars():
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = W / 2, W / 2 + 20
    bw, bh = 300, 520                          # a barrel, seen from the front-ish: tall rounded body
    gap = 40
    ol = 22
    for sx in (-1, 1):
        x0 = cx + sx * (gap / 2 + bw / 2) - bw / 2
        # barrel body
        rrect(d, (x0, cy - bh / 2, x0 + bw, cy + bh / 2), 120, BLACK, OUTLINE, ol)
        # eyecup at the top, a darker rounded cap
        rrect(d, (x0 + 30, cy - bh / 2 - 30, x0 + bw - 30, cy - bh / 2 + 90), 60, (28, 26, 30), OUTLINE, ol)
        # lens at the bottom: a red disc with a glint
        lx, ly, lr = x0 + bw / 2, cy + bh / 2 - 150, 105
        d.ellipse((lx - lr, ly - lr, lx + lr, ly + lr), fill=LENS, outline=OUTLINE, width=ol)
        d.ellipse((lx - lr + 30, ly - lr + 30, lx - lr + 95, ly - lr + 80), fill=GLINT)
        # a soft highlight stripe down the barrel
        d.rounded_rectangle((x0 + 40, cy - bh / 2 + 130, x0 + 80, cy + bh / 2 - 300), radius=20, fill=(90, 88, 96))
    # the bridge: steel bar joining the barrels, with the focus wheel on top
    rrect(d, (cx - 130, cy - 120, cx + 130, cy - 40), 30, STEEL, OUTLINE, ol)
    d.ellipse((cx - 55, cy - 200, cx + 55, cy - 90), fill=(120, 122, 130), outline=OUTLINE, width=ol)
    d.ellipse((cx - 30, cy - 175, cx + 30, cy - 115), fill=(170, 172, 180))
    return img


def slingshot():
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, base = W / 2, W - 150
    ol = 22
    # handle: a stout wooden stick
    rrect(d, (cx - 70, base - 430, cx + 70, base), 60, WOOD, OUTLINE, ol)
    # two prongs leaning out
    spread = math.radians(26)
    fork_y = base - 400
    tips = []
    for sx in (-1, 1):
        L = 380
        x1, y1 = cx + sx * math.sin(spread) * L, fork_y - math.cos(spread) * L
        tips.append((x1, y1))
        d.line((cx + sx * 30, fork_y, x1, y1), fill=OUTLINE, width=130 + 2 * ol)
        d.line((cx + sx * 30, fork_y, x1, y1), fill=WOOD, width=130)
        d.ellipse((x1 - 65 - ol, y1 - 65 - ol, x1 + 65 + ol, y1 + 65 + ol), fill=OUTLINE)
        d.ellipse((x1 - 65, y1 - 65, x1 + 65, y1 + 65), fill=WOOD_DARK)
    # the band, drawn slack from tip to tip through the pouch
    px, py = cx, fork_y - 120
    for (x1, y1) in tips:
        d.line((x1, y1, px, py), fill=OUTLINE, width=44 + 2 * ol)
    for (x1, y1) in tips:
        d.line((x1, y1, px, py), fill=BAND, width=44)
    # the pouch: a leather pad with an acorn in it
    rrect(d, (px - 110, py - 60, px + 110, py + 60), 50, POUCH, OUTLINE, ol)
    d.ellipse((px - 48, py - 58, px + 48, py + 38), fill=(128, 84, 42), outline=OUTLINE, width=ol)
    d.ellipse((px - 40, py - 66, px + 40, py - 26), fill=(92, 58, 30), outline=OUTLINE, width=ol)
    # wood grain hints on the handle
    for y in (base - 330, base - 230, base - 130):
        d.rounded_rectangle((cx - 30, y, cx + 20, y + 14), radius=7, fill=WOOD_DARK)
    return img


for name, fn in (("icon_binoculars.png", binoculars), ("icon_slingshot.png", slingshot)):
    im = shadow(fn())
    im = im.resize((SZ, SZ), Image.LANCZOS)
    im.save(D / name)
    print("wrote", name, im.size)
