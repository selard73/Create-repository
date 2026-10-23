# Lantern lettering: ink on transparent, characters stacked top to bottom, sized for a 1.55 x 2.35 paper lantern face.
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = sys.argv[1]
W, H = 528, 800
FONT = r"C:\Windows\Fonts\YuGothB.ttc"
INK = (30, 24, 20)
WORDS = {
    "kissa": "喫茶",     # cat cafe
    "bungu": "文具",     # stationery shop
    "kome": "米",        # rice and provisions
    "wagasa": "和傘",    # and more umbrellas
    "kimono": "着物",    # kimono shop
    "kimonokana": "きもの",  # and more kimonos
    "mochi": "もち",     # mochi stall
}
# share of the face height each character cell takes
CELL = {1: 0.40, 2: 0.31, 3: 0.235}

for name, text in WORDS.items():
    n = len(text)
    cell = int(H * CELL[n])
    font = ImageFont.truetype(FONT, int(cell * 0.92), index=0)
    img = Image.new("RGBA", (W * 2, H * 2), (0, 0, 0, 0))  # draw at 2x, then shrink for smooth edges
    d = ImageDraw.Draw(img)
    total = cell * n * 2
    y = (H * 2 - total) // 2
    for ch in text:
        box = d.textbbox((0, 0), ch, font=ImageFont.truetype(FONT, int(cell * 0.92 * 2), index=0))
        f2 = ImageFont.truetype(FONT, int(cell * 0.92 * 2), index=0)
        cw, chh = box[2] - box[0], box[3] - box[1]
        x = (W * 2 - cw) // 2 - box[0]
        yy = y + (cell * 2 - chh) // 2 - box[1]
        d.text((x, yy), ch, font=f2, fill=INK + (240,))
        y += cell * 2
    img = img.filter(ImageFilter.GaussianBlur(1.2)).resize((W, H), Image.LANCZOS)
    img.save(f"{OUT}/{name}.png")
    print("wrote", name, text)
