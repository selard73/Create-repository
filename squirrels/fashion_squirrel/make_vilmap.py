"""Rue de Noisette placement map: the Studio top-down plate rotated so +X is right and +Z is down (the same way
round as the in-game map), the twelve squirrels already hidden marked in blue, and numbered spots to choose from.
Run: python make_vilmap.py"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

D = Path(__file__).parent
OUT = D / "rue_pickmap.png"
FONT = r"C:\Windows\Fonts\seguibl.ttf"
FONT_T = r"C:\Windows\Fonts\segoeui.ttf"
CROP = (496, 26, 1424, 772)          # on the 180-degree-rotated capture; from the four magenta corner dots


def P(x, z):
    return (19.5 + 4.396 * (x - 150), 724.5 + 4.40 * (z + 10))


SQUIRRELS = [
    ("Mailman", 186, -139), ("Philosopher", 331, -136), ("Waiter", 217, -106), ("Marcel the Mime", 244, -77),
    ("Cyclist", 328, -122), ("Glam", 296, -106), ("Bird Feeder", 265, -97), ("Firefighter", 200, -144),
    ("Tourist", 178, -105), ("Painter", 188, -20), ("Florist", 334, -103), ("Spy", 167, -114),
]
SPOTS = [
    (1, 165, -55, "river bank, by the meadow"),
    (2, 160, -152, "river bank, top of the street"),
    (3, 232, -122, "middle of the street"),
    (4, 278, -130, "street, east of the square"),
    (5, 318, -64, "grass behind the east shops"),
    (6, 206, -72, "courtyard behind the west shops"),
]
GOLD, GOLD_DK, INK = (255, 206, 84), (150, 100, 30), (46, 30, 18)
BLUE, BLUE_DK, CREAM = (110, 190, 255), (20, 60, 120), (255, 248, 230)
HDR = 112


def main():
    plate = Image.open(D / "vil_plate.png").convert("RGB").rotate(180).crop(CROP)
    W, H = plate.size
    img = Image.new("RGB", (W, H + HDR), (28, 32, 40))
    img.paste(plate, (0, HDR))
    d = ImageDraw.Draw(img, "RGBA")
    f_t = ImageFont.truetype(FONT, 30)
    f_s = ImageFont.truetype(FONT_T, 17)
    f_n = ImageFont.truetype(FONT, 22)
    f_lab = ImageFont.truetype(FONT, 15)
    f_leg = ImageFont.truetype(FONT_T, 16)

    d.text((18, 20), "RUE DE NOISETTE", font=f_t, fill=GOLD)
    d.text((22, 54), "fashion designer and fisherman.  pick two numbers", font=f_s, fill=CREAM)
    d.text((22, 80), "the forest is off to the left, past the bridge", font=f_lab, fill=(150, 160, 150))
    for i, (src, cap, dx) in enumerate((("../fashion_squirrel/preview_color.png", "designer", 330),
                                        ("../fishing_squirrel/preview_color.png", "fisherman", 220))):
        try:
            who = Image.open(D / src).convert("RGB").crop((150, 130, 610, 590)).resize((88, 88), Image.LANCZOS)
            img.paste(who, (W - dx, 6))
            d.rectangle((W - dx - 1, 5, W - dx + 89, 95), outline=GOLD, width=2)
            d.text((W - dx - 1, 96), cap, font=f_lab, fill=CREAM)
        except Exception as e:
            print("no preview:", src, e)

    for name, x, z in SQUIRRELS:
        px, py = P(x, z); py += HDR
        d.ellipse((px - 6, py - 6, px + 6, py + 6), fill=BLUE + (235,), outline=BLUE_DK, width=2)
        w = d.textlength(name, font=f_lab)
        tx, ty = px + 11, py - 9
        if tx + w > W - 6:
            tx = px - 11 - w
        d.text((tx + 1, ty + 1), name, font=f_lab, fill=(0, 0, 0, 180))
        d.text((tx, ty), name, font=f_lab, fill=BLUE)

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

    ly = HDR + H - 30
    d.rectangle((10, ly - 14, 330, ly + 14), fill=(20, 24, 30, 210))
    d.ellipse((22, ly - 6, 34, ly + 6), fill=BLUE, outline=BLUE_DK, width=2)
    d.text((42, ly - 9), "already hidden", font=f_leg, fill=CREAM)
    d.ellipse((178, ly - 8, 194, ly + 8), fill=GOLD, outline=(255, 255, 255), width=2)
    d.text((202, ly - 9), "pick two of these", font=f_leg, fill=CREAM)
    img.save(OUT)
    print("wrote", OUT, img.size)


if __name__ == "__main__":
    main()
