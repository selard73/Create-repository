"""
Area 51 cartoon prop generator -> Roblox model files (.rbxmx)

Run:  python gen_props.py
Then in Roblox Studio: right-click Workspace > Insert from File... > pick the .rbxmx

Each prop is a function that returns a Model. Add new props to the PROPS list at the bottom.
Every prop is written to its own .rbxmx so each one can be published separately.
"""
import xml.dom.minidom
from pathlib import Path

# Roblox Enum.Material values
MAT = {
    "Plastic": 256, "SmoothPlastic": 272, "Neon": 288,
    "Wood": 512, "WoodPlanks": 528,
    "Slate": 800, "Concrete": 816, "Granite": 832, "Brick": 848, "Cobblestone": 880,
    "CorrodedMetal": 1040, "DiamondPlate": 1056, "Metal": 1088,
    "Grass": 1280, "Sand": 1296, "Fabric": 1312, "Glass": 1568,
}
# Roblox Enum.PartType values
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}

# Rotation matrices (row-major R00..R22). Cylinders lie along X, so "upright"
# rotates local X to world Y.
ROT_NONE = (1, 0, 0, 0, 1, 0, 0, 0, 1)
ROT_UPRIGHT = (0, -1, 0, 1, 0, 0, 0, 0, 1)   # 90 deg about Z

_ref = 0
def next_ref():
    global _ref
    _ref += 1
    return f"RBX{_ref}"

def color_uint(rgb):
    r, g, b = rgb
    return (0xFF << 24) | (r << 16) | (g << 8) | b

def part(name, size, pos, color, material="SmoothPlastic", shape="Block", rot=ROT_NONE,
         transparency=0.0, can_collide=True, children=""):
    ref = next_ref()
    x, y, z = pos
    sx, sy, sz = size
    R = rot
    xml = f"""
<Item class="Part" referent="{ref}">
  <Properties>
    <bool name="Anchored">true</bool>
    <bool name="CanCollide">{'true' if can_collide else 'false'}</bool>
    <token name="BottomSurface">0</token>
    <token name="TopSurface">0</token>
    <Color3uint8 name="Color3uint8">{color_uint(color)}</Color3uint8>
    <CoordinateFrame name="CFrame">
      <X>{x}</X><Y>{y}</Y><Z>{z}</Z>
      <R00>{R[0]}</R00><R01>{R[1]}</R01><R02>{R[2]}</R02>
      <R10>{R[3]}</R10><R11>{R[4]}</R11><R12>{R[5]}</R12>
      <R20>{R[6]}</R20><R21>{R[7]}</R21><R22>{R[8]}</R22>
    </CoordinateFrame>
    <token name="Material">{MAT[material]}</token>
    <string name="Name">{name}</string>
    <Vector3 name="size"><X>{sx}</X><Y>{sy}</Y><Z>{sz}</Z></Vector3>
    <token name="shape">{SHAPE[shape]}</token>
    <float name="Transparency">{transparency}</float>
  </Properties>
  {children}
</Item>"""
    return ref, xml

def ellipsoid(name, size, pos, color, material="SmoothPlastic", can_collide=True):
    """A Block with a sphere SpecialMesh: renders as an ellipsoid. Roblox forces true Ball parts
    to be perfectly round, so use this whenever the three dimensions differ."""
    mesh = f"""
<Item class="SpecialMesh" referent="{next_ref()}">
  <Properties>
    <token name="MeshType">3</token>
    <Vector3 name="Scale"><X>1</X><Y>1</Y><Z>1</Z></Vector3>
  </Properties>
</Item>"""
    return part(name, size, pos, color, material, "Block", can_collide=can_collide, children=mesh)

def model(name, parts, primary=None, extra=""):
    """parts: list of (ref, xml). primary: ref of the PrimaryPart. extra: raw xml for
    non-part children such as a Highlight."""
    body = "".join(x for _, x in parts)
    prim = f'<Ref name="PrimaryPart">{primary}</Ref>' if primary else ""
    return name, f"""
<Item class="Model" referent="{next_ref()}">
  <Properties>
    <string name="Name">{name}</string>
    {prim}
  </Properties>
  {body}
  {extra}
</Item>"""

def point_light(color, brightness=1.5, range_=12.0):
    r, g, b = (c / 255 for c in color)
    return f"""
<Item class="PointLight" referent="{next_ref()}">
  <Properties>
    <float name="Brightness">{brightness}</float>
    <Color3 name="Color"><R>{r:.3f}</R><G>{g:.3f}</G><B>{b:.3f}</B></Color3>
    <float name="Range">{range_}</float>
    <bool name="Shadows">false</bool>
  </Properties>
</Item>"""

def highlight(outline, transparency=0.25):
    """Glowing rim outline around the whole model. Studio allows 31 of these per place."""
    r, g, b = (c / 255 for c in outline)
    return f"""
<Item class="Highlight" referent="{next_ref()}">
  <Properties>
    <token name="DepthMode">1</token>
    <bool name="Enabled">true</bool>
    <Color3 name="FillColor"><R>1</R><G>1</G><B>1</B></Color3>
    <float name="FillTransparency">1</float>
    <Color3 name="OutlineColor"><R>{r:.3f}</R><G>{g:.3f}</G><B>{b:.3f}</B></Color3>
    <float name="OutlineTransparency">{transparency}</float>
  </Properties>
</Item>"""

# Cartoon palette
CACTUS = (108, 148, 70)       # dingy olive green, matte
RIB_GLOW = (170, 245, 120)    # neon ridge lines
SPINE = (255, 255, 215)       # neon dots
GLOW_LIGHT = (130, 255, 130)  # light the cactus casts on the sand
RED = (255, 48, 48)           # flower centers (neon)
WHITE = (250, 246, 236)       # petals
PINK = (255, 150, 200)
YELLOW = (255, 214, 70)
WHITE_GLOW = (255, 250, 235)  # flower core
FLOWER_LIGHT = (255, 120, 110)
CLAY = (176, 84, 52)          # red desert clay
INK = (35, 35, 40)
BLUSH = (255, 160, 170)
SKIN = "Fabric"               # matte, fine grain; no plastic sheen

import math

# ---------------------------------------------------------------- PROPS ----

def flower(cx, cy, cz, petals=(WHITE,), yellow_ring=False):
    """Ring of petals around a glowing red core with its own small light.
    petals: colors cycled around the ring, e.g. (WHITE, PINK)."""
    p = []
    for i in range(8):
        a = i * math.pi / 4
        p.append(part("Petal", (0.62, 0.62, 0.62), (cx + 0.55 * math.cos(a), cy, cz + 0.55 * math.sin(a)),
                      petals[i % len(petals)], "Plastic", "Ball", can_collide=False))
    if yellow_ring:
        for i in range(4):
            a = i * math.pi / 2 + math.pi / 4
            p.append(part("Stamen", (0.3, 0.3, 0.3), (cx + 0.32 * math.cos(a), cy + 0.32, cz + 0.32 * math.sin(a)),
                          YELLOW, "SmoothPlastic", "Ball", can_collide=False))
    p.append(part("FlowerCore", (0.7, 0.7, 0.7), (cx, cy + 0.25, cz), RED, "Neon", "Ball",
                  can_collide=False, children=point_light(FLOWER_LIGHT, 1.2, 6)))
    return p

def rib_down(x, z, y_top, length, thick, mat):
    """A glowing ridge that starts at y_top and runs down `length`, bright for the first
    two thirds and fading for the last third, so the light reads as flowing down from the top."""
    bright, tail = length * 0.66, length * 0.34
    return [
        part("Rib", (bright, thick, thick), (x, y_top - bright / 2, z), RIB_GLOW, mat, "Cylinder", ROT_UPRIGHT, can_collide=False),
        part("RibFade", (tail, thick * 0.8, thick * 0.8), (x, y_top - bright - tail / 2, z), RIB_GLOW, mat, "Cylinder", ROT_UPRIGHT,
             transparency=0.55, can_collide=False),
    ]

def cactus(show_face=False, show_flowers=True, glow=True):
    """Tall slim saguaro with two upraised arms, glowing ridges, on a small sand mound. ~11 studs tall."""
    p = []
    rib_mat = "Neon" if glow else "SmoothPlastic"

    # small sand mound so it sits on any ground
    mound = ellipsoid("ClayMound", (3.6, 0.8, 3.6), (0, 0.2, 0), CLAY, "Sand")
    p.append(mound)

    # trunk: tall upright cylinder, rounded top, soft green light inside
    R = 1.2                       # trunk radius
    H = 9.0                       # trunk height
    body_light = point_light(GLOW_LIGHT, 1.0, 14) if glow else ""
    p.append(part("Body", (H, 2 * R, 2 * R), (0, H / 2, 0), CACTUS, SKIN, "Cylinder", ROT_UPRIGHT, children=body_light))
    p.append(part("BodyTop", (2 * R, 2 * R, 2 * R), (0, H, 0), CACTUS, SKIN, "Ball"))
    for i in range(6):
        a = i * math.pi / 3 + math.pi / 6
        rx, rz = (R - 0.07) * math.cos(a), (R - 0.07) * math.sin(a)
        p += rib_down(rx, rz, H + 0.3, H * 0.55, 0.24, rib_mat)

    # arms: (side, height it leaves the trunk, forearm top). Both reach up high like a saguaro.
    arms = ((-1, 3.8, 8.2, 1.5), (1, 5.0, 8.8, 1.4))
    tips = []
    for side, y0, ytop, d in arms:
        r = d / 2
        ex = side * (R + 1.0)                  # elbow x
        p.append(part("Arm", (R + 1.0, d, d), (side * (R + 1.0) / 2, y0, 0), CACTUS, SKIN, "Cylinder"))
        p.append(part("Elbow", (d, d, d), (ex, y0, 0), CACTUS, SKIN, "Ball"))
        fh = ytop - y0
        p.append(part("Forearm", (fh, d, d), (ex, y0 + fh / 2, 0), CACTUS, SKIN, "Cylinder", ROT_UPRIGHT))
        p.append(part("Tip", (d, d, d), (ex, ytop, 0), CACTUS, SKIN, "Ball"))
        for fz in (-(r - 0.06), r - 0.06):
            p += rib_down(ex, fz, ytop + 0.2, fh * 0.6, 0.2, rib_mat)
        tips.append((ex, ytop + r))

    # glowing dot "spines" placed on the trunk surface (angle, height) and on the forearms
    spine_mat = "Neon" if glow else "SmoothPlastic"
    for (deg, sy) in ((20, 1.4), (100, 2.6), (200, 3.3), (300, 4.4), (50, 5.6), (150, 6.7), (250, 7.6), (350, 8.6)):
        a = math.radians(deg)
        p.append(part("Spine", (0.3, 0.3, 0.3), (R * math.cos(a), sy, R * math.sin(a)), SPINE, spine_mat, "Ball", can_collide=False))
    for (sx, sy, sz) in ((-2.2, 5.5, 0.72), (-2.2, 7.0, -0.7), (2.2, 6.4, 0.68), (2.2, 7.8, -0.66), (0.5, 9.9, 0.9)):
        p.append(part("Spine", (0.3, 0.3, 0.3), (sx, sy, sz), SPINE, spine_mat, "Ball", can_collide=False))

    if show_flowers:
        p += flower(0, H + R + 0.05, 0)                                          # top: white petals, red core
        for tx, ty in tips:
            p += flower(tx, ty + 0.05, 0, petals=(WHITE, PINK), yellow_ring=True)  # arms: add pink and yellow

    if show_face:
        zf = R + 0.05
        for ex in (-0.45, 0.45):
            p.append(ellipsoid("Eye", (0.4, 0.5, 0.3), (ex, 6.2, zf), INK, can_collide=False))
            p.append(part("EyeShine", (0.14, 0.14, 0.14), (ex + 0.09, 6.34, zf + 0.15), SPINE, "SmoothPlastic", "Ball", can_collide=False))
        for bx in (-0.85, 0.85):
            p.append(ellipsoid("Blush", (0.45, 0.28, 0.2), (bx, 5.75, math.sqrt(max(R * R - bx * bx, 0.01))), BLUSH, can_collide=False))
        for (mx, my) in ((-0.3, 5.6), (0, 5.47), (0.3, 5.6)):
            p.append(part("Smile", (0.2, 0.2, 0.2), (mx, my, zf), INK, "SmoothPlastic", "Ball", can_collide=False))

    rim = highlight(RIB_GLOW, 0.3) if glow else ""
    return model("Cactus", p, mound[0], extra=rim)


# Add each prop you ask for here. Each becomes its own .rbxmx file.
PROPS = [
    cactus(),
]

HEADER = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
          'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')

for name, body in PROPS:
    doc = f"{HEADER}{body}</roblox>"
    pretty = xml.dom.minidom.parseString(doc).toprettyxml(indent="  ")
    pretty = "\n".join(line for line in pretty.splitlines() if line.strip())
    out = Path(__file__).with_name(f"{name}.rbxmx")
    out.write_text(pretty, encoding="utf-8")
    print(f"wrote {out.name} ({out.stat().st_size} bytes, {body.count('class=\"Part\"')} parts)")
