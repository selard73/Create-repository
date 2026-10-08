from PIL import Image, ImageEnhance

src_path = r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_color.png'
img = Image.open(src_path).convert('RGB')

# 1. Resize to 1024x1024 for clean Roblox performance
img_1k = img.resize((1024, 1024), Image.Resampling.LANCZOS)

# 2. Boost vibrance & contrast so it looks crisp and alive in Roblox lighting
enh_color = ImageEnhance.Color(img_1k)
img_vibrant = enh_color.enhance(1.25) # +25% saturation

enh_cont = ImageEnhance.Contrast(img_vibrant)
img_vibrant = enh_cont.enhance(1.10) # +10% contrast

out_color = r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_1k.png'
img_vibrant.save(out_color, quality=95)
print("Saved color 1k to", out_color)

# 3. Create gray twin texture
img_gray = img_1k.convert('L').convert('RGB')
enh_cont_gray = ImageEnhance.Contrast(img_gray)
img_gray = enh_cont_gray.enhance(1.05)

out_gray = r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_gray_1k.png'
img_gray.save(out_gray, quality=95)
print("Saved gray 1k to", out_gray)
