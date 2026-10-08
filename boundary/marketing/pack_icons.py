"""Developer Product icons for the three acorn packs: a handful (three acorns), a basket (wicker, heaped) and a
wheelbarrow (heaped higher), on the store's parchment. 512x512 PNGs, drawn at 3x and downsampled.
Run: python pack_icons.py  -> pack_handful.png, pack_basket.png, pack_barrow.png (in this folder)."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFilter

D = Path(__file__).parent
SZ, K = 512, 3
W = SZ * K
PARCH, PARCH_DEEP, RIM = (250, 241, 219), (234, 220, 189), (118, 80, 46)
NUT, NUT_LIGHT, CAP, CAP_DARK, STEM, OUTLINE = (196, 136, 66), (226, 176, 104), (120, 78, 40), (90, 56, 28), (70, 44, 22), (48, 30, 16)
WICKER, WICKER_DARK = (204, 160, 92), (150, 108, 56)
IRON, WOOD = (72, 74, 80), (170, 118, 62)


def shadow(img, blur=30, dy=18, alpha=90):
    a = img.split()[3].filter(ImageFilter.GaussianBlur(blur))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh.putalpha(a.point(lambda v: int(v * alpha / 255)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (0, dy))
    out.alpha_composite(img)
    return out


def acorn(d, cx, cy, s, tilt=0):
    """one acorn, height ~ 2.2 s: the nut (an egg), the cap (a dome with scales), the stem"""
    ol = max(4, int(s * 0.12))
    # nut
    d.ellipse((cx - s, cy - s * 0.5, cx + s, cy + s * 1.3), fill=NUT, outline=OUTLINE, width=ol)
    d.ellipse((cx - s * 0.55, cy - s * 0.2, cx - s * 0.15, cy + s * 0.5), fill=NUT_LIGHT)
    # cap
    d.chord((cx - s * 1.08, cy - s * 1.1, cx + s * 1.08, cy + s * 0.25), 180, 360, fill=CAP, outline=OUTLINE, width=ol)
    d.rounded_rectangle((cx - s * 1.08, cy - s * 0.5, cx + s * 1.08, cy - s * 0.2), radius=s * 0.12, fill=CAP, outline=OUTLINE, width=ol)
    for k in range(-1, 2):                        # scale marks, kept inside the dome
        d.arc((cx + k * s * 0.5 - s * 0.22, cy - s * 0.78, cx + k * s * 0.5 + s * 0.22, cy - s * 0.4), 200, 340, fill=CAP_DARK, width=max(3, int(s * 0.07)))
    # stem
    d.rounded_rectangle((cx - s * 0.12, cy - s * 1.45, cx + s * 0.12, cy - s * 0.9), radius=s * 0.1, fill=STEM, outline=OUTLINE, width=max(3, ol - 2))


def canvas():
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((40, 40, W - 40, W - 40), radius=150, fill=PARCH, outline=RIM, width=28)
    d.rounded_rectangle((90, 90, W - 90, W - 90), radius=120, fill=PARCH_DEEP)
    return img, d


def handful():
    img, d = canvas()
    art = Image.new("RGBA", (W, W), (0, 0, 0, 0)); a = ImageDraw.Draw(art)
    acorn(a, W * 0.32, W * 0.56, 150)
    acorn(a, W * 0.68, W * 0.56, 150)
    acorn(a, W * 0.5, W * 0.4, 165)
    img.alpha_composite(shadow(art))
    return img


def basket():
    img, d = canvas()
    art = Image.new("RGBA", (W, W), (0, 0, 0, 0)); a = ImageDraw.Draw(art)
    cx, top, bot, hw = W / 2, W * 0.5, W * 0.84, W * 0.34
    # the heap
    for (x, y, s) in ((0.36, 0.44, 95), (0.64, 0.44, 95), (0.5, 0.35, 105), (0.43, 0.5, 90), (0.57, 0.5, 90), (0.28, 0.5, 80), (0.72, 0.5, 80)):
        acorn(a, W * x, W * y, s)
    # the basket: a trapezoid body with wicker bands
    a.polygon([(cx - hw, top), (cx + hw, top), (cx + hw * 0.8, bot), (cx - hw * 0.8, bot)], fill=WICKER, outline=OUTLINE)
    for i in range(6):
        y = top + (bot - top) * (i + 0.5) / 6
        f = 1 - 0.2 * (y - top) / (bot - top)
        a.line([(cx - hw * f, y), (cx + hw * f, y)], fill=WICKER_DARK, width=14)
    for j in range(-4, 5):
        x0, x1 = cx + j * hw / 4.5, cx + j * hw / 4.5 * 0.8
        a.line([(x0, top), (x1, bot)], fill=WICKER_DARK, width=10)
    a.polygon([(cx - hw, top), (cx + hw, top), (cx + hw * 0.8, bot), (cx - hw * 0.8, bot)], outline=OUTLINE, width=18)
    a.rounded_rectangle((cx - hw - 10, top - 26, cx + hw + 10, top + 26), radius=26, fill=WICKER_DARK, outline=OUTLINE, width=14)
    # the handle
    a.arc((cx - hw * 0.75, top - W * 0.28, cx + hw * 0.75, top + W * 0.1), 180, 360, fill=WICKER_DARK, width=34)
    a.arc((cx - hw * 0.75, top - W * 0.28, cx + hw * 0.75, top + W * 0.1), 180, 360, fill=OUTLINE, width=8)
    img.alpha_composite(shadow(art))
    return img


def barrow():
    img, d = canvas()
    art = Image.new("RGBA", (W, W), (0, 0, 0, 0)); a = ImageDraw.Draw(art)
    cx = W * 0.5
    # the heap, high
    for (x, y, s) in ((0.36, 0.38, 92), (0.62, 0.36, 96), (0.49, 0.26, 104), (0.42, 0.45, 86), (0.56, 0.46, 88), (0.29, 0.46, 78), (0.7, 0.47, 80), (0.49, 0.4, 80)):
        acorn(a, W * x, W * y, s)
    # the tray
    a.polygon([(W * 0.16, W * 0.5), (W * 0.84, W * 0.5), (W * 0.74, W * 0.74), (W * 0.3, W * 0.74)], fill=WOOD, outline=OUTLINE, width=18)
    for i in range(3):
        y = W * 0.5 + (W * 0.24) * (i + 0.5) / 3
        a.line([(W * 0.16 + (W * 0.14) * (y - W * 0.5) / (W * 0.24), y), (W * 0.84 - (W * 0.1) * (y - W * 0.5) / (W * 0.24), y)], fill=(130, 88, 44), width=10)
    a.rounded_rectangle((W * 0.14, W * 0.48, W * 0.86, W * 0.53), radius=20, fill=(140, 96, 48), outline=OUTLINE, width=12)
    # handles and leg
    a.line([(W * 0.84, W * 0.52), (W * 0.96, W * 0.44)], fill=IRON, width=30)
    a.line([(W * 0.3, W * 0.74), (W * 0.28, W * 0.88)], fill=IRON, width=26)
    a.line([(W * 0.62, W * 0.74), (W * 0.64, W * 0.86)], fill=IRON, width=26)
    # the wheel
    wx, wy, r = W * 0.24, W * 0.84, W * 0.1
    a.ellipse((wx - r, wy - r, wx + r, wy + r), fill=IRON, outline=OUTLINE, width=16)
    a.ellipse((wx - r * 0.45, wy - r * 0.45, wx + r * 0.45, wy + r * 0.45), fill=(120, 122, 130), outline=OUTLINE, width=10)
    img.alpha_composite(shadow(art))
    return img


for name, fn in (("pack_handful", handful), ("pack_basket", basket), ("pack_barrow", barrow)):
    im = fn().resize((SZ, SZ), Image.LANCZOS)
    im.save(D / (name + ".png"))
    print(name + ".png")
