import numpy as np
from PIL import Image, ImageEnhance

# Load original texture
img = Image.open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png').convert('RGB')
arr = np.array(img, dtype=np.float32)

# Convert to HSV-like or work directly in RGB
# Let's inspect where the fur is:
# Fur has R > G > B, with R in [80, 180], G in [60, 150], B in [40, 130]
# Hat/Apron has R, G, B > 200 and (R-B) < 40 (near white/cream)

r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]

# Fur mask: where it's brown/tan/wood (not pure white apron/hat)
is_white = (r > 215) & (g > 215) & (b > 215)
is_cream = (r > 200) & (g > 185) & (b > 170) & (r - b < 45)

# For fur / wood: warm it up and richen the saturation
# Standard saturation boost using PIL
enhancer_color = ImageEnhance.Color(img)
img_sat = enhancer_color.enhance(1.45) # +45% saturation

enhancer_contrast = ImageEnhance.Contrast(img_sat)
img_cont = enhancer_contrast.enhance(1.15) # +15% contrast

arr_enhanced = np.array(img_cont, dtype=np.float32)

# Add a rich warm amber-red curve to the fur midtones
# Midtone mask: values between 40 and 190
r_enh = arr_enhanced[:,:,0]
g_enh = arr_enhanced[:,:,1]
b_enh = arr_enhanced[:,:,2]

# Boost R channel slightly in brown areas to get that rich squirrel chestnut warmth
fur_mask = (r_enh > 50) & (r_enh < 190) & (r_enh > b_enh + 15)
r_enh[fur_mask] = np.clip(r_enh[fur_mask] * 1.12, 0, 255)
g_enh[fur_mask] = np.clip(g_enh[fur_mask] * 1.02, 0, 255)
b_enh[fur_mask] = np.clip(b_enh[fur_mask] * 0.92, 0, 255) # slight cool reduction in fur

# Ensure whites don't blow out
arr_final = np.stack([r_enh, g_enh, b_enh], axis=2)
arr_final = np.clip(arr_final, 0, 255).astype(np.uint8)

res_img = Image.fromarray(arr_final)
out_path = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k_vibrant.png'
res_img.save(out_path)
print("Saved vibrant texture to", out_path)
