from PIL import Image, ImageEnhance

# 1. Color texture
img = Image.open(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_color.png").convert("RGBA")
img_1k = img.resize((1024, 1024), Image.Resampling.LANCZOS)

rgb = img_1k.convert("RGB")
# Boost saturation +25%
sat_enhancer = ImageEnhance.Color(rgb)
rgb_boosted = sat_enhancer.enhance(1.25)

# Boost contrast +10%
con_enhancer = ImageEnhance.Contrast(rgb_boosted)
rgb_final = con_enhancer.enhance(1.10)

# Re-attach alpha if any
r, g, b = rgb_final.split()
a = img_1k.split()[3]
color_1k = Image.merge("RGBA", (r, g, b, a))
color_1k.save(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_1k.png", "PNG", optimize=True)

# 2. Gray texture
gray_l = rgb_final.convert("L")
gray_con = ImageEnhance.Contrast(gray_l).enhance(1.05)
gray_rgb = gray_con.convert("RGB")
gr, gg, gb = gray_rgb.split()
gray_1k = Image.merge("RGBA", (gr, gg, gb, a))
gray_1k.save(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_gray_1k.png", "PNG", optimize=True)

print("TEXTURES_PROCESSED_SUCCESSFULLY")
