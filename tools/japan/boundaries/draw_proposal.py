"""Japan boundaries - the proposal picture (Oct 23 2026). Shannon: "how are we going to block off sections on this map seeing as
how it is flat and wide open?" Draws the proposed lines on a Studio top-down capture (camera at (5950, 900, -60) looking straight
down; calibrated on the palace walls: 0.697 px per stud, (5950, -60) at pixel (694, 317), +z is down the picture, +x is right).
  blue   = the water lines already there (the mountain stream, the canal)
  red    = new fences
  green  = gates (the farm bridge, the three canal bridges, the two station level crossings)
Run: python tools/japan/boundaries/draw_proposal.py <topdown.jpg>"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

D = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1]
im = Image.open(src).convert("RGB")
dr = ImageDraw.Draw(im, "RGBA")
S, CX, CY = 0.697, 694, 317
def P(x, z): return (CX + (x - 5950) * S, CY + (z + 60) * S)
try:
    F = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 22); f = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 15)
except Exception:
    F = f = ImageFont.load_default()
BLUE, RED, GREEN, WHITE = (40, 150, 255, 255), (235, 40, 40, 255), (40, 210, 90, 255), (255, 255, 255, 255)

def line(pts, col, w=5, dash=None):
    pts = [P(*q) for q in pts]
    if not dash:
        dr.line(pts, fill=col, width=w, joint="curve"); return
    for a, b in zip(pts, pts[1:]):
        dx, dy = b[0] - a[0], b[1] - a[1]; L = (dx * dx + dy * dy) ** 0.5
        n = max(1, int(L / dash)); on = True
        for i in range(n):
            if on: dr.line([(a[0] + dx * i / n, a[1] + dy * i / n), (a[0] + dx * (i + 1) / n, a[1] + dy * (i + 1) / n)], fill=col, width=w)
            on = not on
def gate(x, z, label):
    cx, cy = P(x, z)
    dr.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=GREEN, outline=WHITE, width=2)
    dr.text((cx + 12, cy - 9), label, font=f, fill=WHITE, stroke_width=3, stroke_fill=(0, 0, 0, 255))
def label(x, z, text, font=F, col=WHITE):
    cx, cy = P(x, z)
    dr.text((cx, cy), text, font=font, fill=col, anchor="mm", stroke_width=4, stroke_fill=(0, 0, 0, 255))

# the water lines there already
line([(5765, -305), (5765, 85)], BLUE, 7)
line([(6101, -226), (6101, 109)], BLUE, 7)
# new fences
line([(5765, 85), (5765, 123)], RED, 5, 9)                                   # stream's south end -> the railway
line([(5765, -305), (5765, -372)], RED, 5, 9)                                # stream's north end -> the mountains (to confirm)
line([(5765, 123), (5680, 123)], RED, 5, 9); line([(5580, 123), (5345, 123)], RED, 5, 9)   # railway, Tea Hills side (gap = the station crossing)
line([(6101, 109), (6101, 123)], RED, 5, 9)                                  # canal's south end -> the railway
line([(6101, 123), (6330, 123)], RED, 5, 9); line([(6428, 123), (6655, 123)], RED, 5, 9)   # railway, Palace side (gap = the station crossing)
line([(6118, -226), (6131, -244), (6131, -385)], RED, 5, 9)                   # canal's north end, past the church, to the steep slope
# gates
gate(5765, 70, "farm bridge")
gate(6101, -203, "canal bridge"); gate(6101, -75, "canal bridge"); gate(6101, 80, "canal bridge")
gate(5630, 123, "Tea Hills station crossing"); gate(6379, 123, "Palace station crossing + palace gate")
# names
label(5955, -150, "1  LANTERN STREET\n(opens Sunday)")
label(5540, -40, "2  TEA HILLS\n(closed, coming soon)")
label(6382, -100, "3  PALACE\n(closed, coming soon)")
label(6145, 250, "arrival", f)
label(6115, -281, "church", f)
label(5990, 365, "lawn south of the railway = part of area 1", f)
label(6000, -470, "mountains (solid)", f)
out = os.path.join(D, "japan_boundaries_proposal.png")
im.save(out); print(out)
