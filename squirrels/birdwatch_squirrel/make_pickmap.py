"""Draws the forest placement map: the Studio top-down plate, rotated so +X is right and +Z is down (the same way
round as the in-game map), with the squirrels already hidden marked in blue and numbered gold pins for the spots
Shannon can choose from.  Run: python make_pickmap.py"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

D = Path(__file__).parent
PLATE = D / "map_plate.png"
OUT = D / "forest_pickmap3.png"
FONT = r"C:\Windows\Fonts\seguibl.ttf"
FONT_T = r"C:\Windows\Fonts\segoeui.ttf"

# from the four magenta calibration dots in map_plate's twin (map_calib.png), after a 180 deg rotation
def P(x, z):
    return (30.5 + 3.172 * (x + 120), 728.5 + 3.1727 * (z - 15))

SQUIRRELS = [                       # already hidden in The Great Acorn Forest
    ("Mr. Holmes", 31, -186), ("Rainy Day", 68, -153), ("Buccaneer", -42, -143),
    ("El Scientifico", 54, -113), ("Surfer Dude", -16, -47), ("Nacho Libre", 91, -40),
    ("Gordo", -3, -149), ("Fairy", 18, -52), ("Ski-a-roo", 80, -123),
    ("Ballerina", 32, -136), ("Baking Betty", -18, -93),
    ("Kite Flyer", -104, -97),
    ("Sky Diver", 60, -18),
]
SPOTS = [                           # candidate homes for the last two forest squirrels
    (1, -70, -22, "meadow edge, west"),
    (2, -110, -52, "west woods, top end"),
    (3, 0, -200, "south tree line, centre"),
    (4, -72, -188, "deep woods, south-west"),
    (5, 110, -86, "east edge, by the river"),
    (6, 104, -152, "south-east woods"),
]

GOLD, GOLD_DK, INK = (255, 206, 84), (150, 100, 30), (46, 30, 18)
BLUE, BLUE_DK, CREAM = (110, 190, 255), (20, 60, 120), (255, 248, 230)
HDR = 112


def main():
    plate = Image.open(PLATE).convert("RGB").rotate(180)
    W, H = plate.size
    img = Image.new("RGB", (W, H + HDR), (28, 36, 30))
    img.paste(plate, (0, HDR))
    d = ImageDraw.Draw(img, "RGBA")
    f_t = ImageFont.truetype(FONT, 30)
    f_s = ImageFont.truetype(FONT_T, 17)
    f_n = ImageFont.truetype(FONT, 22)
    f_lab = ImageFont.truetype(FONT, 15)
    f_leg = ImageFont.truetype(FONT_T, 16)

    d.text((18, 20), "THE GREAT ACORN FOREST", font=f_t, fill=GOLD)
    d.text((22, 54), "the last two: bird watcher and ranger.  pick two numbers", font=f_s, fill=CREAM)
    d.text((22, 80), "spawn is the acorn tile at the bottom", font=f_lab, fill=(150, 160, 150))
    d.text((W - 210, 60), "Rue de Noisette", font=f_lab, fill=(190, 200, 190))
    d.text((W - 210, 80), "is off to the right", font=f_lab, fill=(150, 160, 150))
    # who we are placing
    try:
        who = Image.open(D / "preview_color.png").convert("RGB").crop((150, 130, 610, 590)).resize((88, 88), Image.LANCZOS)
        img.paste(who, (W - 330, 6))
        d.rectangle((W - 331, 5, W - 241, 95), outline=GOLD, width=2)
        d.text((W - 331, 96), "bird watcher", font=f_lab, fill=CREAM)
    except Exception as e:
        print("no preview:", e)

    def dot(x, z, r, fill, edge, width=2):
        px, py = P(x, z); py += HDR
        d.ellipse((px - r, py - r, px + r, py + r), fill=fill, outline=edge, width=width)
        return px, py

    # squirrels already hidden: a small blue dot with its name, placed so the labels do not collide
    for i, (name, x, z) in enumerate(SQUIRRELS):
        px, py = dot(x, z, 6, BLUE + (235,), BLUE_DK, 2)
        w = d.textlength(name, font=f_lab)
        tx, ty = px + 11, py - 9
        if tx + w > W - 6:
            tx = px - 11 - w
        d.text((tx + 1, ty + 1), name, font=f_lab, fill=(0, 0, 0, 170))
        d.text((tx, ty), name, font=f_lab, fill=BLUE)

    # the choices: a big gold pin with its number
    for n, x, z, note in SPOTS:
        px, py = P(x, z); py += HDR
        d.ellipse((px - 22, py - 22, px + 22, py + 22), fill=(0, 0, 0, 90))
        d.ellipse((px - 19, py - 19, px + 19, py + 19), fill=GOLD + (245,), outline=(255, 255, 255), width=3)
        d.ellipse((px - 19, py - 19, px + 19, py + 19), outline=GOLD_DK, width=1)
        tw = d.textlength(str(n), font=f_n)
        d.text((px - tw / 2, py - 14), str(n), font=f_n, fill=INK)
        w = d.textlength(note, font=f_lab)
        tx = min(max(6, px - w / 2), W - w - 6)
        d.text((tx + 1, py + 23), note, font=f_lab, fill=(0, 0, 0, 180))
        d.text((tx, py + 22), note, font=f_lab, fill=CREAM)

    # legend
    ly = HDR + H - 30
    d.rectangle((10, ly - 14, 330, ly + 14), fill=(20, 26, 22, 205))
    d.ellipse((22, ly - 6, 34, ly + 6), fill=BLUE, outline=BLUE_DK, width=2)
    d.text((42, ly - 9), "already hidden", font=f_leg, fill=CREAM)
    d.ellipse((178, ly - 8, 194, ly + 8), fill=GOLD, outline=(255, 255, 255), width=2)
    d.text((202, ly - 9), "pick two of these", font=f_leg, fill=CREAM)

    img.save(OUT)
    print("wrote", OUT, img.size)


if __name__ == "__main__":
    main()
