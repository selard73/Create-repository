"""The octopus texture for Roblox: Meshy's 4k PNG -> 1024 px, sharpened and a touch more saturated (the whale / rig_any recipe:
UnsharpMask x2, colour 1.12, contrast 1.05).  Run: python make_tex.py"""
import os
from PIL import Image, ImageEnhance, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
im = Image.open(os.path.join(HERE, "src", "octopus_texture.png")).convert("RGB")
print("source", im.size)
im = im.resize((1024, 1024), Image.LANCZOS)
im.save(os.path.join(HERE, "octopus_1k_plain.png"))
im = im.filter(ImageFilter.UnsharpMask(radius=1.6, percent=90, threshold=2))
im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=60, threshold=2))
im = ImageEnhance.Color(im).enhance(1.12)
im = ImageEnhance.Contrast(im).enhance(1.05)
out = os.path.join(HERE, "octopus_1k.png")
im.save(out)
print("wrote", out, im.size)
