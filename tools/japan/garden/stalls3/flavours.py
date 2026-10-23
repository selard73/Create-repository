"""stalls3c (Oct 23 2026): her "I don't like the way the ice looks, seems like there should be more variety and color" -> a quick
recolour for Sunday (her Meshy kakigori come later). The blue kakigori colour map (stalls1/out/ice_blue_color.png: white shaved
ice on top, a syrup band below, syrup flecks in the ice) re-syruped into six flavours: the syrup weight t = saturation / the syrup's
saturation; the ice keeps its grain (grey from the pixel's value), the syrup takes the flavour's colour at the pixel's brightness.
Writes out/ice_<flavour>_color.png + out/flavours_sheet.png (a contact sheet for checking).
Run: python tools/japan/garden/stalls3/flavours.py"""
import os
import numpy as np
from PIL import Image

D = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(D, "..", "stalls1", "out", "ice_blue_color.png")
OUT = os.path.join(D, "out")
os.makedirs(OUT, exist_ok=True)
PASTEL = 0.42                     # (v2, after her reference photos: the ice coloured right through) the white ice takes this much of the flavour
FLAVOURS = {                      # sRGB syrup colours
    "blue": (46, 118, 232),
    "strawberry": (232, 52, 74),
    "mango": (250, 170, 30),
    "matcha": (112, 152, 48),
    "melon": (118, 212, 84),
    "grape": (132, 58, 172),
    "orange": (246, 118, 28),
    "peach": (246, 150, 162),
}
img = np.asarray(Image.open(SRC).convert("RGB")).astype(np.float32) / 255.0
mx, mn = img.max(axis=2), img.min(axis=2)
sat = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0.0)
val = mx
h = img.shape[0]
band = img[int(h * 0.75):, :, :].reshape(-1, 3)              # the solid syrup at the bottom
bmx, bmn = band.max(axis=1), band.min(axis=1)
s_base = float(np.median((bmx - bmn) / np.maximum(bmx, 1e-4)))
v_base = float(np.median(bmx))
t = np.clip(sat / s_base, 0.0, 1.0)[..., None]
grey = np.repeat(val[..., None], 3, axis=2)
sheet = []
for name, rgb in FLAVOURS.items():
    tgt = np.array(rgb, np.float32) / 255.0
    syrup = tgt[None, None, :] * np.clip(val / v_base, 0.0, 1.15)[..., None]
    ice = grey * (1 - PASTEL) + grey * tgt[None, None, :] * PASTEL                  # pastel-tinted ice, grain kept
    out = np.clip(ice * (1 - t) + syrup * t, 0.0, 1.0)
    im = Image.fromarray((out * 255 + 0.5).astype(np.uint8))
    im.save(os.path.join(OUT, f"ice_{name}_color.png"))
    sheet.append(im.resize((256, 256)))
    print(f"{name}: written")
cs = Image.new("RGB", (256 * len(sheet), 256))
for i, im in enumerate(sheet): cs.paste(im, (256 * i, 0))
cs.save(os.path.join(OUT, "flavours_sheet.png"))
print(f"syrup base: saturation {s_base:.2f}, value {v_base:.2f}; sheet written")
