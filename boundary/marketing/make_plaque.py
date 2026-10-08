"""Turns the carved-acorn plaque reference into a flat square texture in the game's palette.
  1. finds the plaque's four corners in the 3/4-view render (the brown pixels against the grey backdrop)
  2. warps that quad to a square, so the carving faces straight up
  3. maps its brightness onto the game's cream / tan / brown ramp, keeping the carved shading
Run: python make_plaque.py <source image> [out.png]"""
import sys
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r"C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\images\31.webp")
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).parent / "plaque_acorn.png"
SIZE = 1024

# the game's palette, darkest first: outline brown -> cap brown -> nut tan -> cream slab -> highlight
RAMP = [(0.00, (68, 40, 22)), (0.20, (104, 66, 38)), (0.42, (162, 110, 62)), (0.62, (212, 162, 98)),
        (0.80, (236, 222, 192)), (1.00, (252, 250, 240))]


def corners(img):
    """The four extreme points of the plaque (brown, against a grey backdrop): top, right, bottom, left."""
    a = np.asarray(img).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    wood = (r > g + 18) & (g > b + 8) & (r > 70)
    ys, xs = np.nonzero(wood)
    assert len(xs) > 1000, "no plaque found"
    s, d = xs + ys, xs - ys
    pts = {
        "tl": (xs[np.argmin(s)], ys[np.argmin(s)]),
        "br": (xs[np.argmax(s)], ys[np.argmax(s)]),
        "tr": (xs[np.argmax(d)], ys[np.argmax(d)]),
        "bl": (xs[np.argmin(d)], ys[np.argmin(d)]),
    }
    return pts


def ramp_lut():
    lut = np.zeros((256, 3), dtype=np.uint8)
    for i in range(256):
        t = i / 255
        for k in range(len(RAMP) - 1):
            t0, c0 = RAMP[k]
            t1, c1 = RAMP[k + 1]
            if t0 <= t <= t1:
                f = (t - t0) / (t1 - t0)
                lut[i] = [round(c0[j] + (c1[j] - c0[j]) * f) for j in range(3)]
                break
        else:
            lut[i] = RAMP[-1][1]
    return lut


def main():
    img = Image.open(SRC).convert("RGB")
    p = corners(img)
    quad = (p["tl"][0], p["tl"][1], p["bl"][0], p["bl"][1], p["br"][0], p["br"][1], p["tr"][0], p["tr"][1])
    print("plaque corners:", {k: tuple(int(v) for v in val) for k, val in p.items()})
    flat = img.transform((SIZE, SIZE), Image.QUAD, quad, Image.BICUBIC)

    # brightness -> palette ramp, with the contrast stretched so the carving reads
    grey = np.asarray(flat.convert("L")).astype(float)
    lo, hi = np.percentile(grey, 10), np.percentile(grey, 95)
    grey = np.clip((grey - lo) / max(1.0, hi - lo), 0, 1)
    grey = grey * grey * (3 - 2 * grey)          # an S-curve: deeper shadows, brighter reliefs
    idx = (grey * 255).astype(np.uint8)
    lut = ramp_lut()
    out = Image.fromarray(lut[idx], "RGB").filter(ImageFilter.SMOOTH)
    out.save(OUT)
    print("wrote", OUT, out.size)


if __name__ == "__main__":
    main()
