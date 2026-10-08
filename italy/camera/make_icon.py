"""Hotbar icon for the Camera Tool (Oct 8 2026), drawn to match the in-game model and the other tool icons
(boundary/marketing/tool_icons.py): a little vintage camera - brown leather body, silver top plate, black lens with a
brass ring and a blue glass glint, a viewfinder bump and a red shutter button. Transparent 256x256 PNG, drawn at 4x.
Run: python make_icon.py  -> icon_camera.png (in this folder)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

D = Path(__file__).parent
SZ, K = 256, 4
W = SZ * K
OUTLINE = (30, 22, 34)
LEATHER, LEATHER_DARK = (112, 72, 46), (82, 52, 34)
SILVER, SILVER_DARK = (206, 208, 214), (150, 152, 160)
LENS_BLACK, BRASS = (40, 38, 44), (214, 170, 80)
GLASS, GLASS_GLINT = (86, 140, 186), (210, 236, 255)
RED = (214, 64, 58)


def shadow(img, blur=18, dy=10, alpha=110):
    a = img.split()[3].filter(ImageFilter.GaussianBlur(blur))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh.putalpha(a.point(lambda v: int(v * alpha / 255)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (0, dy))
    out.alpha_composite(img)
    return out


def camera():
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ol = 22
    cx, cy = W / 2, W / 2 + 40
    bw, bh = 780, 470
    x0, y0, x1, y1 = cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2
    # viewfinder bump and shutter button sit on top, drawn first so the body overlaps their feet
    d.rounded_rectangle((cx - 330, y0 - 120, cx - 110, y0 + 40), radius=40, fill=SILVER, outline=OUTLINE, width=ol)
    d.rounded_rectangle((cx - 290, y0 - 85, cx - 150, y0 - 25), radius=22, fill=(60, 70, 84))
    d.rounded_rectangle((cx + 170, y0 - 95, cx + 300, y0 + 30), radius=34, fill=RED, outline=OUTLINE, width=ol)
    d.rounded_rectangle((cx + 195, y0 - 75, cx + 240, y0 - 50), radius=12, fill=(246, 150, 140))
    # body: silver top band over brown leather
    d.rounded_rectangle((x0, y0, x1, y1), radius=90, fill=LEATHER, outline=OUTLINE, width=ol)
    d.rounded_rectangle((x0 + ol, y0 + ol, x1 - ol, y0 + 150), radius=70, fill=SILVER)
    d.rectangle((x0 + ol, y0 + 100, x1 - ol, y0 + 150), fill=SILVER)
    d.line((x0 + ol, y0 + 150, x1 - ol, y0 + 150), fill=OUTLINE, width=ol)
    d.rounded_rectangle((x0 + 60, y0 + 45, x0 + 300, y0 + 75), radius=15, fill=(236, 238, 242))
    # leather grain: a few darker dimples
    for (px, py) in ((x0 + 90, y1 - 120), (x0 + 150, y1 - 80), (x1 - 120, y1 - 110), (x1 - 170, y1 - 70), (x0 + 110, y0 + 230), (x1 - 100, y0 + 220)):
        d.ellipse((px - 14, py - 14, px + 14, py + 14), fill=LEATHER_DARK)
    # the lens: brass ring, black barrel, blue glass with a glint
    lx, ly = cx, cy + 40
    for r, fill in ((250, BRASS), (205, LENS_BLACK), (140, GLASS)):
        d.ellipse((lx - r, ly - r, lx + r, ly + r), fill=fill, outline=OUTLINE, width=ol)
    d.ellipse((lx - 110, ly - 110, lx - 30, ly - 40), fill=GLASS_GLINT)
    d.ellipse((lx + 40, ly + 50, lx + 75, ly + 85), fill=(170, 210, 240))
    return img


im = shadow(camera()).resize((SZ, SZ), Image.LANCZOS)
im.save(D / "icon_camera.png")
print("wrote icon_camera.png", im.size)
