# gen_bubble.py: draws the Sky Diving Squirrel speech bubble as an image (her reference: an irregular rounded blob, thin
# outline, a small tail at the bottom left), 440x330 RGBA, rendered at 4x and downsampled. Also writes the Import 3D
# carrier (one textured quad) so Studio uploads the image as an asset.
import math
from PIL import Image, ImageDraw
S = 4
W, H = 440 * S, 330 * S
BROWN = (120, 80, 46)
WHITE = (255, 255, 255)
cx, cy = 220 * S, 150 * S
ax, ay = 196 * S, 126 * S
def r(t):
    return 1 + 0.045 * math.cos(t - 0.6) + 0.035 * math.cos(2 * t + 1.2) + 0.02 * math.sin(3 * t + 0.4)
pts = []
N = 720
for i in range(N):
    t = 2 * math.pi * i / N
    rr = r(t)
    pts.append((cx + ax * rr * math.cos(t), cy + ay * rr * math.sin(t)))
def at(deg):
    t = math.radians(deg)
    rr = r(t)
    return (cx + ax * rr * math.cos(t), cy + ay * rr * math.sin(t))
base1 = at(104)
base2 = at(122)
tip = (cx - 0.34 * ax, cy + 1.26 * ay)
LW = 14 * S // 4 * 2   # outline: 28 px at 4x = 7 px on the 440 image, about 3 px on screen at 220 wide
rgb = Image.new("RGB", (W, H), BROWN)
mask = Image.new("L", (W, H), 0)
for img, fillc, white in ((rgb, BROWN, WHITE), (mask, 255, 255)):
    d = ImageDraw.Draw(img)
    d.line(pts + [pts[0]], fill=fillc, width=LW, joint="curve")
    d.line([base1, tip, base2], fill=fillc, width=LW, joint="curve")
    d.ellipse([tip[0] - LW / 2, tip[1] - LW / 2, tip[0] + LW / 2, tip[1] + LW / 2], fill=fillc)
    d.polygon(pts, fill=white)
    d.polygon([base1, tip, base2], fill=white)
rgb = rgb.resize((W // S, H // S), Image.LANCZOS)
mask = mask.resize((W // S, H // S), Image.LANCZOS)
rgb.putalpha(mask)
rgb.save("bubble_blob.png")
# a preview on a sky-blue background, 2x, to judge the shape
prev = Image.new("RGB", (W // S, H // S), (140, 190, 240))
prev.paste(rgb, (0, 0), rgb)
prev = prev.resize((W // S * 2, H // S * 2), Image.LANCZOS)
prev.save("bubble_blob_preview.png")
open("bubble_carrier.obj", "w").write("# bubble texture carrier: one quad so Import 3D uploads the image\nmtllib bubble_carrier.mtl\no BubbleBlob\ng BubbleBlob\nusemtl BubbleBlob\nv -2 -1.5 0\nv 2 -1.5 0\nv 2 1.5 0\nv -2 1.5 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/1\nf 1/1/1 3/3/1 4/4/1\n")
open("bubble_carrier.mtl", "w").write("newmtl BubbleBlob\nKd 1 1 1\nmap_Kd bubble_blob.png\n")
print("wrote bubble_blob.png", rgb.size, "preview", prev.size, "tip", tip[0] / S, tip[1] / S)
