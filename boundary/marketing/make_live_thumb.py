"""YouTube live-stream thumbnail for 1001 Squirrels (1280x720): a squirrel from the store art (the pirate by default), LIVE, the game's
title, the hook, and Henrietta (Shannon's squirrel narrator) in a framed cam window with her name tag.
Run: python make_live_thumb.py <screenshot with the Warudo window> [out_dir] [background capture]"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

D = Path(__file__).parent
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else D
FONT = r"C:\Windows\Fonts\seguibl.ttf"       # Segoe UI Black (the store art's font)
CREAM, GOLD, INK = (255, 246, 220), (255, 214, 90), (58, 36, 22)
RED, PINK = (228, 32, 48), (246, 150, 196)
W, H = 1280, 720


def font(size):
    return ImageFont.truetype(FONT, size)


def cover(img, w, h, fx=0.5, fy=0.5):
    """the largest w:h crop of img with (fx, fy) of the image as central as it can be, resized to w x h"""
    iw, ih = img.size
    s = max(w / iw, h / ih)
    cw, ch = w / s, h / s
    x0 = min(max(iw * fx - cw / 2, 0), iw - cw)
    y0 = min(max(ih * fy - ch / 2, 0), ih - ch)
    return img.crop((int(x0), int(y0), int(x0 + cw), int(y0 + ch))).resize((w, h), Image.LANCZOS)


def text(draw, xy, s, size, fill=CREAM, stroke=INK, sw=None, anchor="la"):
    f = font(size)
    sw = sw if sw is not None else max(4, size // 11)
    x, y = xy
    draw.text((x + size * 0.05, y + size * 0.07), s, font=f, fill=(0, 0, 0, 140), stroke_width=sw, stroke_fill=(0, 0, 0, 140), anchor=anchor)
    draw.text((x, y), s, font=f, fill=fill, stroke_width=sw, stroke_fill=stroke, anchor=anchor)
    return draw.textbbox((x, y), s, font=f, stroke_width=sw, anchor=anchor)


shot = Image.open(sys.argv[1]).convert("RGB")
CUTOUT = Path(sys.argv[4]) if len(sys.argv) > 4 else None                               # a squirrel rendered on transparent
NAME = sys.argv[5] if len(sys.argv) > 5 else "youtube_live_thumb"
BG = sys.argv[3] if len(sys.argv) > 3 else "portrait_hero.png"                          # (Shannon: not the rainy day one)
src = Image.open(D / BG).convert("RGB")
src = src.crop((4, 4, src.width - 4, src.height - 4))                                   # (the capture's thin border)
bg = cover(src, W, H, fx=0.0, fy=0.55)                                                  # (the squirrel to the right)
canvas = bg.convert("RGBA")

# a soft dark wash down the left, so the words read over the forest
wash = Image.new("L", (W, H), 0)
wd = ImageDraw.Draw(wash)
for x in range(W):
    wd.line([(x, 0), (x, H)], fill=int(150 * max(0.0, 1 - x / 760) ** 1.4))
canvas.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", (W, H), (22, 14, 30)).split(), wash)))

# a squirrel on the right, standing in the scene, with a soft shadow at its feet
if CUTOUT:
    sq = Image.open(CUTOUT).convert("RGBA")
    sq = sq.crop(sq.getbbox())
    sh_ = 540
    sq = sq.resize((int(sq.width * sh_ / sq.height), sh_), Image.LANCZOS)
    sx, sy = 905 - sq.width // 2, H - 22 - sq.height
    shadow_ = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow_).ellipse((sx + sq.width * 0.12, H - 58, sx + sq.width * 0.88, H - 8), fill=(20, 16, 30, 120))
    canvas.alpha_composite(shadow_.filter(ImageFilter.GaussianBlur(12)))
    canvas.alpha_composite(sq, (sx, sy))

d = ImageDraw.Draw(canvas)
# LIVE
d.rounded_rectangle((44, 38, 44 + 188, 38 + 70), radius=18, fill=RED, outline=(255, 255, 255), width=4)
d.ellipse((66, 60, 66 + 26, 60 + 26), fill=(255, 255, 255))
d.text((104, 73), "LIVE", font=font(44), fill=(255, 255, 255), anchor="lm")
# the title, the hook
text(d, (258, 44), "1001 SQUIRRELS", 58, fill=CREAM)
text(d, (44, 126), "FIND THE", 84, fill=CREAM)
text(d, (40, 210), "LAST 2!", 150, fill=GOLD, sw=14)
# 42 of 44, as a badge up in the trees on the right
bx, by = W - 44 - 214, 38
d.rounded_rectangle((bx, by, bx + 214, by + 118), radius=22, fill=(38, 30, 52, 215), outline=GOLD, width=4)
d.text((bx + 107, by + 50), "42/44", font=font(58), fill=GOLD, anchor="mm")
d.text((bx + 107, by + 96), "squirrels found", font=font(22), fill=CREAM, anchor="mm")

# Henrietta's cam window: her head and shoulders from the Warudo window, framed in white, tipped a little
cam = shot.crop((1132, 575, 1392, 744)).resize((380, 247), Image.LANCZOS)
cam = cam.filter(ImageFilter.UnsharpMask(radius=2, percent=90, threshold=2))
frame = Image.new("RGBA", (cam.width + 24, cam.height + 24), (0, 0, 0, 0))
fd = ImageDraw.Draw(frame)
fd.rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), radius=26, fill=(255, 255, 255, 255))
mask = Image.new("L", cam.size, 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, cam.width - 1, cam.height - 1), radius=18, fill=255)
frame.paste(cam, (12, 12), mask)
frame = frame.rotate(-3, resample=Image.BICUBIC, expand=True)
fx, fy = 34, H - frame.height - 52                                   # bottom left, under the words
shadow = Image.new("RGBA", frame.size, (0, 0, 0, 0))
shadow.putalpha(frame.getchannel("A").point(lambda a: int(a * 0.55)))
shadow = shadow.filter(ImageFilter.GaussianBlur(10))
canvas.alpha_composite(shadow, (fx + 8, fy + 12))
canvas.alpha_composite(frame, (fx, fy))
# her name tag, pinned to the frame's lower edge
d = ImageDraw.Draw(canvas)
tag = "HENRIETTA \u2665"
tf = font(40)
tb = d.textbbox((0, 0), tag, font=tf)
tw, th = tb[2] - tb[0], tb[3] - tb[1]
tx, ty = fx + frame.width // 2 - (tw + 48) // 2, fy + frame.height - 30
d.rounded_rectangle((tx, ty, tx + tw + 48, ty + th + 30), radius=24, fill=PINK, outline=(255, 255, 255), width=4)
d.text((tx + 24 + tw // 2, ty + (th + 30) // 2), tag, font=tf, fill=(92, 28, 64), anchor="mm")

out = canvas.convert("RGB")
out.save(OUT / f"{NAME}.png")
out.save(OUT / f"{NAME}.jpg", quality=92)
print("saved", OUT / f"{NAME}.png")
