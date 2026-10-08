"""paint_zinc_tex.py <dir> : paint an even zinc band onto the Meshy texture using zinc_faces.json (per-texel 3D test).
Keeps <texture>_orig.png the first time; always paints from the original."""
import sys, os, json, glob, shutil
import numpy as np
from PIL import Image
D = sys.argv[1]
J = json.load(open(os.path.join(D, "zinc_faces.json")))
png = [p for p in glob.glob(os.path.join(D, "src*", "*", "*_texture.png"))][0]
orig = png.replace("_texture.png", "_texture_orig.png")
if not os.path.exists(orig):
    shutil.copy(png, orig)
img = np.asarray(Image.open(orig).convert("RGB")).astype(np.float32)
H, W = img.shape[:2]
BX, Z0, Z1, HW = J["band"]
tipY = J["tip"][1]
ZINC = np.array([252, 252, 250], np.float32)
EDGE = 0.012                                    # soft edge width (model units)
alpha = np.zeros((H, W), np.float32)
for t in J["tris"]:
    uv = np.array(t["uv"]); P = np.array(t["p"])
    px = uv[:, 0] * W; py = (1 - uv[:, 1]) * H
    x0, x1 = int(max(0, np.floor(px.min()) - 1)), int(min(W - 1, np.ceil(px.max()) + 1))
    y0, y1 = int(max(0, np.floor(py.min()) - 1)), int(min(H - 1, np.ceil(py.max()) + 1))
    if x1 < x0 or y1 < y0:
        continue
    gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax, ay), (bx, by), (cx, cy) = zip(px, py)
    den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(den) < 1e-9:
        continue
    l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
    l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
    l3 = 1 - l1 - l2
    inside = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
    X = l1 * P[0, 0] + l2 * P[1, 0] + l3 * P[2, 0]
    Z = l1 * P[0, 2] + l2 * P[1, 2] + l3 * P[2, 2]
    Y = l1 * P[0, 1] + l2 * P[1, 1] + l3 * P[2, 1]
    Zb, Zt = Z0 - 0.025, Z1 - 0.02                                     # sits right on top of the nose
    Zc, hz = (Zb + Zt) / 2, (Zt - Zb) / 2
    hw = HW * (1 - 0.15 * np.clip((Z - Zb) / (Zt - Zb), 0, 1))
    u = np.abs(X - BX) / hw; v = np.abs(Z - Zc) / hz
    r = (u ** 4 + v ** 4) ** 0.25                                      # rounded rectangle
    d = (1 - r) * min(HW, hz)
    a = np.clip(d / EDGE + 0.5, 0, 1) * (Y < tipY + 0.28)
    a = np.where(inside, a, 0)
    sub = alpha[y0:y1 + 1, x0:x1 + 1]
    np.maximum(sub, a, out=sub)
a3 = (alpha * 0.97)[..., None]
out = img * (1 - a3) + ZINC * a3
Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(png)
print("painted texels", int((alpha > 0.5).sum()), "->", png)
