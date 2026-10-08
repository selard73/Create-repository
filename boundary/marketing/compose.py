"""Builds the 1001 Squirrels store art from viewport captures (village/capture_view2.ps1 output, 1451x622):
  icon_512.png            square icon, the pirate squirrel with the title band
  thumb_1_hero.png        1920x1080, the pirate squirrel + title + "Find them all!"
  thumb_2_street.png      Rue de Noisette scene
  thumb_3_chateau.png     Château de l'Acorn scene
  thumb_4_hint.png        the hint glow (if scene_hint.png exists)
Run: python compose.py   (inputs in this folder: portrait_icon.png, portrait_hero.png, portrait_rainy.png, scene_street.png,
scene_chateau.png, scene_hint.png)"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

D = Path(__file__).parent
FONT = r"C:\Windows\Fonts\seguibl.ttf"       # Segoe UI Black
CREAM, GOLD, INK, PANEL = (255, 246, 220), (255, 214, 90), (58, 36, 22), (38, 30, 52)


def font(size):
    return ImageFont.truetype(FONT, size)


def crop_to(img, w, h, fx=0.5, fy=0.5):
    """Largest w:h crop of img, positioned so (fx, fy) of the image sits as central as possible, resized to w x h."""
    W, H = img.size
    scale = max(w / W, h / H)
    cw, ch = w / scale, h / scale
    x0 = min(max(W * fx - cw / 2, 0), W - cw)
    y0 = min(max(H * fy - ch / 2, 0), H - ch)
    return img.crop((int(x0), int(y0), int(x0 + cw), int(y0 + ch))).resize((w, h), Image.LANCZOS)


def text_block(draw, xy, text, size, fill=CREAM, stroke=INK, sw=None, anchor="la", shadow=True):
    f = font(size)
    sw = sw if sw is not None else max(3, size // 14)
    x, y = xy
    if shadow:
        draw.text((x + size * 0.05, y + size * 0.06), text, font=f, fill=(0, 0, 0, 150), stroke_width=sw, stroke_fill=(0, 0, 0, 150), anchor=anchor)
    draw.text((x, y), text, font=f, fill=fill, stroke_width=sw, stroke_fill=stroke, anchor=anchor)
    return draw.textbbox((x, y), text, font=f, stroke_width=sw, anchor=anchor)


def panel(img, box, radius=28, alpha=165):
    over = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(over).rounded_rectangle(box, radius=radius, fill=PANEL + (alpha,))
    return Image.alpha_composite(img, over)


def vignette(img, strength=0.45):
    W, H = img.size
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse((-W * 0.25, -H * 0.35, W * 1.25, H * 1.35), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(W, H) * 0.18))
    dark = Image.new("RGBA", (W, H), (10, 8, 20, int(255 * strength)))
    dark.putalpha(Image.eval(mask, lambda v: int((255 - v) * strength)))
    return Image.alpha_composite(img, dark)


def load(name):
    p = D / name
    if not p.exists(): return None
    im = Image.open(p).convert("RGBA")
    W, H = im.size
    return im.crop((8, 8, W - 4, H - 4))            # the capture's window-edge sliver


def make_icon():
    src = load("portrait_icon.png")
    if not src: print("no portrait_icon.png"); return
    im = crop_to(src, 1024, 1024, fx=0.5, fy=0.55)
    im = vignette(im, 0.35)
    im = panel(im, (60, 700, 964, 990), radius=48, alpha=175)
    d = ImageDraw.Draw(im)
    text_block(d, (512, 780), "1001", 170, fill=GOLD, anchor="mm", sw=12)
    text_block(d, (512, 920), "SQUIRRELS", 96, fill=CREAM, anchor="mm", sw=8)
    im.resize((512, 512), Image.LANCZOS).convert("RGB").save(D / "icon_512.png")
    print("icon_512.png")


def make_hero():
    src = load("portrait_hero.png")
    if not src: print("no portrait_hero.png"); return
    im = crop_to(src, 1920, 1080, fx=0.38, fy=0.5)
    im = vignette(im, 0.3)
    im = panel(im, (70, 300, 1010, 790), radius=40, alpha=170)
    d = ImageDraw.Draw(im)
    text_block(d, (540, 420), "1001", 230, fill=GOLD, anchor="mm", sw=14)
    text_block(d, (540, 600), "SQUIRRELS", 120, fill=CREAM, anchor="mm", sw=9)
    text_block(d, (540, 720), "Find them all!", 68, fill=(255, 255, 255), anchor="mm", sw=6)
    im.convert("RGB").save(D / "thumb_1_hero.png", quality=95)
    print("thumb_1_hero.png")


def make_scene(name, out, title, sub, fx=0.5, fy=0.5, inset=None, tsize=104, ssize=60):
    src = load(name)
    if not src: print("no", name); return
    im = crop_to(src, 1920, 1080, fx=fx, fy=fy)
    im = vignette(im, 0.28)
    if inset:
        por = load(inset)
        if por:
            p = crop_to(por, 640, 640, fx=0.5, fy=0.55)
            mask = Image.new("L", p.size, 0); ImageDraw.Draw(mask).ellipse((0, 0, 640, 640), fill=255)
            ring = Image.new("RGBA", (680, 680), (0, 0, 0, 0)); ImageDraw.Draw(ring).ellipse((0, 0, 680, 680), fill=GOLD + (255,))
            ring.paste(p, (20, 20), mask)
            im.alpha_composite(ring, (1920 - 720, 1080 - 730))
    # THE PANEL IS CUT TO THE TEXT. It was a fixed 1000 wide, which fit the titles and left the ends of the
    # longer subtitles hanging over bare artwork - "and a tractor to drive" sat out on open sky. Measure both
    # lines, shrink the subtitle if it would reach past MAXR, then size the panel to whichever line is wider.
    TX, TY, SX, SY = 110, 110, 112, 240
    TSW, SSW, PAD, PADB, MAXR = 8, 5, 50, 34, 1420
    probe = ImageDraw.Draw(im)

    def extent(x, y, text, size, sw):
        b = probe.textbbox((x, y), text, font=font(size), stroke_width=sw, anchor="la")
        return b[2] + size * 0.05, b[3] + size * 0.06      # the drop shadow reaches past the glyphs

    tr, _ = extent(TX, TY, title, tsize, TSW)
    while ssize > 30 and extent(SX, SY, sub, ssize, SSW)[0] > MAXR - PAD:
        ssize -= 2
    sr, sb = extent(SX, SY, sub, ssize, SSW)

    right, bottom = max(tr, sr) + PAD, sb + PADB
    im = panel(im, (60, 60, right, bottom), radius=40, alpha=170)
    d = ImageDraw.Draw(im)
    text_block(d, (TX, TY), title, tsize, fill=GOLD, anchor="la", sw=TSW)
    text_block(d, (SX, SY), sub, ssize, fill=CREAM, anchor="la", sw=SSW)
    im.convert("RGB").save(D / out, quality=95)
    print(f"{out}  panel {right:.0f}x{bottom:.0f}, subtitle {ssize}px, clear by {right - max(tr, sr):.0f}px")


if __name__ == "__main__":
    make_icon()
    make_hero()
    make_scene("scene_street.png", "thumb_2_street.png", "Rue de Noisette", "Shops, a river, and squirrels in hiding", fx=0.5, fy=0.5, inset="portrait_rainy.png")
    make_scene("scene_chateau.png", "thumb_3_chateau.png", "Château de l'Acorn", "Lavender, a windmill, hens and a tractor to drive", fx=0.5, fy=0.5)
    make_scene("scene_hint.png", "thumb_4_hint.png", "Stuck? Get a hint", "The squirrel lights up, just for you", fx=0.5, fy=0.5)
