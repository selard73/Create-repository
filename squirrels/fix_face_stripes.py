"""Repaint stray stripe pixels (navy + the white between them) inside given UV triangles with the surrounding colour.
Oct 5 2026: Meshy painted the octopus catcher's shirt stripes onto his cheek.
Run: python fix_face_stripes.py <texture.png> <uvtris.json> <out.png> [preview.png]
 - mask = the UV triangles (2 px dilation for seams)
 - stripe = blue-dominant pixels (b > r + 35 and b > g + 10), plus near-white pixels within 9 px of a blue one
   (eye whites have no navy next to them, so they stay)
 - fill = OpenCV Telea inpaint from the unmasked-stripe neighbours, then a light blur only on the filled pixels."""
import sys, json
import numpy as np, cv2
from PIL import Image
src, tj, out = sys.argv[1], sys.argv[2], sys.argv[3]
import os; MINSUM = int(os.environ.get("MINSUM", "150"))
im = np.array(Image.open(src).convert("RGB")).astype(np.int16)
H, W = im.shape[:2]
mask = np.zeros((H, W), np.uint8)
for t in json.load(open(tj)):
    pts = np.array([[u * W, (1 - v) * H] for u, v in t], np.int32)
    cv2.fillConvexPoly(mask, pts, 255)
mask = cv2.dilate(mask, np.ones((5, 5), np.uint8))
r, g, b = im[..., 0], im[..., 1], im[..., 2]
blue = (b > r + 35) & (b > g + 10) & (r + g + b >= MINSUM) & (mask > 0)   # MINSUM 150 keeps a dark-navy beanie out; 0 when the box is clear of it
NEAR = int(os.environ.get("NEAR", "19"))
near = cv2.dilate(blue.astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (NEAR, NEAR))) > 0
white = (r > 185) & (g > 185) & (b > 185) & (np.abs(r - b) < 40)
# the octopus catcher's stripe also had a dark GREY band (90,85,96) between the navy and the white
gray = (np.abs(r - g) < 22) & (b >= r - 5) & (r + g + b > 150) & (r + g + b < 420)
stripe = blue | ((white | gray) & near & (mask > 0))
KEEP = os.environ.get("KEEP")   # "r,g,b;r,g,b;..." = the patch's real colours: everything else in the mask (not near-black) is repainted
if KEEP:
    kc = [tuple(map(int, c.split(","))) for c in KEEP.split(";")]
    rf, gf, bf = r.astype(np.float32), g.astype(np.float32), b.astype(np.float32)
    dmin = np.min([np.sqrt((rf - c[0]) ** 2 + (gf - c[1]) ** 2 + (bf - c[2]) ** 2) for c in kc], 0)
    stripe = stripe | ((dmin > float(os.environ.get("KEEPTOL", "45"))) & (r + g + b > 120) & (mask > 0))
stripe = cv2.dilate(stripe.astype(np.uint8), np.ones((3, 3), np.uint8)) & (mask > 0)
print("mask px", int((mask > 0).sum()), "blue px", int(blue.sum()), "stripe px", int(stripe.sum()))
# fill ONLY from this patch's own fur: known = in the mask, not stripe, not white, not dark (normalized convolution,
# growing the blur until every stripe pixel has a value). Telea inpaint pulled navy in from the neighbouring atlas islands.
known = ((mask > 0) & (stripe == 0) & ~white & (r + g + b > 120)).astype(np.float32)
src_f = im.astype(np.float32)
fillc = src_f.copy(); todo = stripe > 0
for sig in (4, 8, 16, 32, 64, 128):
    if not todo.any(): break
    k = int(sig * 3) | 1
    wsum = cv2.GaussianBlur(known, (k, k), sig)
    acc = np.dstack([cv2.GaussianBlur(src_f[..., c] * known, (k, k), sig) for c in range(3)])
    ok = todo & (wsum > 1e-3)
    fillc[ok] = acc[ok] / wsum[ok][:, None]
    todo &= ~ok
fill = cv2.cvtColor(np.clip(fillc, 0, 255).astype(np.uint8), cv2.COLOR_RGB2BGR)
print("unfilled px", int(todo.sum()))
Image.fromarray(cv2.cvtColor(fill, cv2.COLOR_BGR2RGB)).save(out)
if len(sys.argv) > 4:   # before | after crop around the changed pixels
    ys, xs = np.nonzero(stripe)
    if len(xs):
        x0, x1, y0, y1 = max(0, xs.min() - 60), min(W, xs.max() + 60), max(0, ys.min() - 60), min(H, ys.max() + 60)
        a = im[y0:y1, x0:x1].astype(np.uint8); c = cv2.cvtColor(fill, cv2.COLOR_BGR2RGB)[y0:y1, x0:x1]
        Image.fromarray(np.concatenate([a, c], 1)).save(sys.argv[4])
print("FIX_DONE", out)
