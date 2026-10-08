"""Builds badge_check/badge_sheet.png: for each French squirrel, the current badge and the fixed badge side by side,
cropped to the round badge with the dark HUD panel colour outside the circle and a gold ring, like the in-game HUD."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

D = Path(__file__).parent / "badge_check"
IDS = ["mailman_squirrel", "philosopher_squirrel", "waiter_squirrel", "mime_squirrel", "cyclist_squirrel", "glam_squirrel",
       "bird_feeder_squirrel", "firefighter_squirrel", "tourist_squirrel", "painter_squirrel", "florist_squirrel", "spy_squirrel"]
PANEL = (38, 30, 52)
GOLD = (222, 184, 92)
S = 150


def badge(path):
    im = Image.open(path).convert("RGB").resize((S, S), Image.LANCZOS)
    out = Image.new("RGB", (S, S), PANEL)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, S - 1, S - 1), fill=255)
    out.paste(im, (0, 0), mask)
    ImageDraw.Draw(out).ellipse((1, 1, S - 2, S - 2), outline=GOLD, width=4)
    return out


try:
    font = ImageFont.truetype("arial.ttf", 15)
except Exception:
    font = ImageFont.load_default()
cols, cellw, cellh = 3, 2 * S + 40, S + 40
rows = (len(IDS) + cols - 1) // cols
sheet = Image.new("RGB", (cols * cellw + 20, rows * cellh + 40), (24, 20, 34))
dr = ImageDraw.Draw(sheet)
dr.text((12, 10), "left = now in the game      right = fixed", fill=(240, 240, 240), font=font)
for i, sid in enumerate(IDS):
    x = 10 + (i % cols) * cellw
    y = 36 + (i // cols) * cellh
    for j, tag in enumerate(("now", "fixed")):
        p = D / f"{sid}_{tag}.png"
        if p.exists():
            sheet.paste(badge(p), (x + j * (S + 10), y))
    dr.text((x, y + S + 4), sid.replace("_squirrel", "").replace("_", " "), fill=(240, 240, 240), font=font)
sheet.save(D / "badge_sheet.png")
print("wrote", D / "badge_sheet.png")
