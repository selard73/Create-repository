"""Chateau de l'Acorn placement map: the Studio top-down plate rotated so +X is right and +Z is down, with numbered
spots to choose from. No squirrels live here yet, so there are no blue markers.
Run: python make_chmap.py"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

D = Path(__file__).parent
OUT = D / "chateau_pickmap.png"
FONT = r"C:\Windows\Fonts\seguibl.ttf"
FONT_T = r"C:\Windows\Fonts\segoeui.ttf"
CROP = (460, 0, 1460, 799)


def P(x, z):
    return (15.5 + 2.7816 * (x - 352), 788.5 + 2.7857 * (z - 30))


SPOTS = [
    (1, 575, -138, "end of the vine rows"),
    (2, 650, -190, "east side of the vineyard"),
    (3, 502, -170, "edge of the lavender"),
    (4, 487, -12, "in front of the farmhouse"),
    (5, 612, -72, "beside the windmill"),
    (6, 468, -82, "by the long table"),
]
GOLD, GOLD_DK, INK = (255, 206, 84), (150, 100, 30), (46, 30, 18)
CREAM = (255, 248, 230)
HDR = 112


def main():
    plate = Image.open(D / "ch_plate.png").convert("RGB").rotate(180).crop(CROP)
    W, H = plate.size
    img = Image.new("RGB", (W, H + HDR), (32, 30, 24))
    img.paste(plate, (0, HDR))
    d = ImageDraw.Draw(img, "RGBA")
    f_t = ImageFont.truetype(FONT, 30)
    f_s = ImageFont.truetype(FONT_T, 17)
    f_n = ImageFont.truetype(FONT, 22)
    f_lab = ImageFont.truetype(FONT, 15)

    d.text((18, 20), "CHÂTEAU DE L'ACORN", font=f_t, fill=GOLD)
    d.text((22, 54), "vintner and cheese maker.  pick two numbers", font=f_s, fill=CREAM)
    d.text((22, 80), "Rue de Noisette is off to the left; nobody is hidden here yet", font=f_lab, fill=(150, 150, 140))
    for src, cap, dx in (("../vintner_squirrel/preview_color.png", "vintner", 330),
                         ("../chevre_squirrel/preview_color.png", "cheese", 220)):
        try:
            who = Image.open(D / src).convert("RGB").crop((150, 130, 610, 590)).resize((88, 88), Image.LANCZOS)
            img.paste(who, (W - dx, 6))
            d.rectangle((W - dx - 1, 5, W - dx + 89, 95), outline=GOLD, width=2)
            d.text((W - dx - 1, 96), cap, font=f_lab, fill=CREAM)
        except Exception as e:
            print("no preview:", src, e)

    for n, x, z, note in SPOTS:
        px, py = P(x, z); py += HDR
        d.ellipse((px - 22, py - 22, px + 22, py + 22), fill=(0, 0, 0, 90))
        d.ellipse((px - 19, py - 19, px + 19, py + 19), fill=GOLD + (245,), outline=(255, 255, 255), width=3)
        tw = d.textlength(str(n), font=f_n)
        d.text((px - tw / 2, py - 14), str(n), font=f_n, fill=INK)
        w = d.textlength(note, font=f_lab)
        tx = min(max(6, px - w / 2), W - w - 6)
        d.text((tx + 1, py + 23), note, font=f_lab, fill=(0, 0, 0, 190))
        d.text((tx, py + 22), note, font=f_lab, fill=CREAM)
    img.save(OUT)
    print("wrote", OUT, img.size)


if __name__ == "__main__":
    main()
