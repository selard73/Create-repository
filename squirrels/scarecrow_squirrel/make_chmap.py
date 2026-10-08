"""Chateau de l'Acorn placement map: the Studio top-down plate rotated so +X is right and +Z is down, with numbered
spots to choose from. No squirrels live here yet, so there are no blue markers.
Run: python make_chmap.py"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

D = Path(__file__).parent
OUT = D / "chateau_pickmap2.png"
FONT = r"C:\Windows\Fonts\seguibl.ttf"
FONT_T = r"C:\Windows\Fonts\segoeui.ttf"
CROP = (460, 0, 1460, 799)


def P(x, z):
    return (15.5 + 2.7816 * (x - 352), 788.5 + 2.7857 * (z - 30))


PLACED = [("Vintner", 580, -183), ("Chevre", 478, -74)]
SPOTS = [
    (1, 452, -162, "in the lavender rows"),
    (2, 424, -102, "among the sunflowers"),
    (3, 515, -158, "west edge of the vineyard"),
    (4, 419, -134, "by the old well"),
    (5, 560, -215, "deep in the vine rows"),
    (6, 502, -56, "under the apple trees"),
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
    d.text((22, 54), "where should the scarecrow stand?  pick a number", font=f_s, fill=CREAM)
    d.text((22, 80), "Rue de Noisette is off to the left", font=f_lab, fill=(150, 150, 140))
    for src, cap, dx in (("preview_color.png", "scarecrow", 220),):
        try:
            who = Image.open(D / src).convert("RGB").crop((150, 130, 610, 590)).resize((88, 88), Image.LANCZOS)
            img.paste(who, (W - dx, 6))
            d.rectangle((W - dx - 1, 5, W - dx + 89, 95), outline=GOLD, width=2)
            d.text((W - dx - 1, 96), cap, font=f_lab, fill=CREAM)
        except Exception as e:
            print("no preview:", src, e)

    BLUE, BLUE_DK = (110, 190, 255), (20, 60, 120)
    for name, x, z in PLACED:
        px, py = P(x, z); py += HDR
        d.ellipse((px - 6, py - 6, px + 6, py + 6), fill=BLUE + (235,), outline=BLUE_DK, width=2)
        d.text((px + 12, py - 8), name, font=f_lab, fill=(0, 0, 0, 180))
        d.text((px + 11, py - 9), name, font=f_lab, fill=BLUE)
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
