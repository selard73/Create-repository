"""Japan market stall goods kit v3 (Oct 22 2026). Shannon on v2: "looks bad; you need to use blender, not roblox shapes; the ice
does not look like ice, it looks like toddler plastic toys". v2's ice was smooth hull shapes in flat colours. v3:
  * the ice mounds, the bear's face and the takoyaki balls are proper lathed meshes, roughened with layered Perlin noise
    (lumps + grain) so the silhouette is lumpy like shaved ice / a fried crust
  * baked textures (colour + roughness + normal, 1k PNGs embedded in the FBX -> SurfaceAppearance in Studio): ice grain with
    sparkle and crystal gaps, syrup soaking in (blue mound: blue below, white top with blue flecks; strawberry: red; the bear:
    rainbow bands with noisy edges), a mottled golden crust for the takoyaki, printed blue wave bands on the paper cups
  * a lit Cycles render of the served trio (out/render_served3.png) so the look is judged under real light, not Workbench grey
Pieces (same names as v2 so stalls1.lua works): kakigori_a (shaver, ice block, syrups, straws), kakigori_b (cup stack + the
blue one, the rainbow bear, the strawberry one), kori_flag, takoyaki_a (pan + bottles + jar + picks), takoyaki_b (boats + shaker).
Local frame: x along the counter, y up, z toward the back; the customer side is -z; base y 0 = the counter top.
Writes stalls1/out/japan_kit38_stalls3.fbx (+ textures), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback, sys
import numpy as np
from mathutils import Vector, noise as mnoise
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a", encoding="utf-8").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {   # flat-colour keys (display values); textured keys are in TEX
    "KG_Iron": (0.16, 0.17, 0.18), "KG_Enamel": (0.93, 0.90, 0.82), "KG_Chrome": (0.78, 0.80, 0.82), "KG_Wood": (0.55, 0.40, 0.25),
    "KG_Tray": (0.70, 0.72, 0.74), "KG_Ice": (0.90, 0.96, 1.00), "KG_Glass": (0.85, 0.92, 0.96), "KG_Snow": (0.98, 0.98, 1.00),
    "KG_SyrupRed": (0.86, 0.12, 0.18), "KG_SyrupGreen": (0.30, 0.72, 0.25), "KG_SyrupBlue": (0.18, 0.55, 0.90), "KG_SyrupYellow": (0.98, 0.82, 0.20),
    "KG_Knob": (0.75, 0.15, 0.12), "KG_FlagPole": (0.25, 0.20, 0.16), "KG_FlagCloth": (0.16, 0.38, 0.75), "KG_Cup": (0.96, 0.94, 0.88),
    "KG_Cookie": (0.78, 0.55, 0.28), "KG_Choco": (0.22, 0.12, 0.08), "KG_Pink": (0.95, 0.55, 0.65), "KG_Cream": (0.99, 0.98, 0.95),
    "KG_MiniStick": (0.85, 0.75, 0.55), "KG_MiniFlag1": (0.97, 0.97, 0.97), "KG_MiniFlag2": (0.97, 0.97, 0.97), "KG_Straw": (0.95, 0.55, 0.65),
    "TK_IronDark": (0.20, 0.20, 0.21), "TK_Iron": (0.10, 0.10, 0.11), "TK_Sauce": (0.30, 0.16, 0.08), "TK_Mayo": (0.98, 0.96, 0.88),
    "TK_Nori": (0.14, 0.28, 0.12), "TK_Bonito": (0.80, 0.62, 0.45), "TK_Paper": (0.95, 0.90, 0.78), "TK_Chrome": (0.78, 0.80, 0.82),
    "TK_SauceBottle": (0.35, 0.20, 0.10), "TK_MayoBottle": (0.96, 0.95, 0.90), "TK_RedCap": (0.80, 0.12, 0.10), "TK_YellowCap": (0.95, 0.75, 0.15),
    "TK_Glass": (0.85, 0.92, 0.96), "TK_Bamboo": (0.80, 0.70, 0.45), "TK_Pick": (0.88, 0.80, 0.60),
}
TEX = {"KG_MoundBlue": "ice_blue", "KG_MoundStraw": "ice_straw", "KG_MoundBear": "ice_bear", "KG_FaceSnow": "ice_white",
       "KG_CupTex": "cup", "TK_BallTex": "crust"}
SMOOTH = set(TEX) | {"KG_Glass", "KG_Snow", "KG_Ice", "TK_Sauce", "TK_Glass", "KG_SyrupRed", "KG_SyrupGreen", "KG_SyrupBlue",
                     "KG_SyrupYellow", "KG_Cup", "KG_Choco", "KG_Pink", "KG_Cookie", "KG_Cream"}
UV_STUDS = 6.0
def P(x, y, z): return (x, -z, y)

# ------------------------------------------------------------ textures (numpy, 1024 square; u = around, v = height, row 0 = bottom)
S = 1024
def value_noise(freq, seed):
    rng = np.random.default_rng(seed)
    g = rng.random((freq + 1, freq + 1)) * 2 - 1
    g[:, -1] = g[:, 0]; g[-1, :] = g[0, :]
    t = np.linspace(0, freq, S, endpoint=False)
    i0 = np.floor(t).astype(int); f = t - i0; sm = f * f * (3 - 2 * f); i1 = i0 + 1
    a = g[np.ix_(i0, i0)]; b = g[np.ix_(i0, i1)]; c = g[np.ix_(i1, i0)]; d = g[np.ix_(i1, i1)]
    top = a + (b - a) * sm[None, :]; bot = c + (d - c) * sm[None, :]
    return top + (bot - top) * sm[:, None]
def fractal(freq, octaves, seed):
    out = np.zeros((S, S)); amp, f, tot = 1.0, freq, 0.0
    for o in range(octaves):
        out += amp * value_noise(f, seed + o); tot += amp; amp *= 0.5; f *= 2
    return out / tot
V = np.linspace(0, 1, S, endpoint=False)[:, None] * np.ones((1, S))
U = np.ones((S, 1)) * np.linspace(0, 1, S, endpoint=False)[None, :]
def rgb(c): return np.array([lin(c[0]), lin(c[1]), lin(c[2])])
def solid(c): return np.ones((S, S, 3)) * rgb(c)[None, None, :]
def mix(a, b, s): return a * (1 - s[..., None]) + b * s[..., None]
def save_img(name, arr, data=False):
    img = bpy.data.images.new(name, S, S, alpha=True, float_buffer=False)
    if data: img.colorspace_settings.name = "Non-Color"
    px = np.ones((S, S, 4), dtype=np.float32); px[..., :3] = np.clip(arr, 0, 1)
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = os.path.join(OUT, name + ".png"); img.file_format = "PNG"; img.save()
    return img
def normal_from_height(h, strength):
    gy, gx = np.gradient(h)
    n = np.dstack((-gx * strength, -gy * strength, np.ones_like(h)))
    n /= np.linalg.norm(n, axis=2)[..., None]
    return n * 0.5 + 0.5
IMAGES = {}
def make_textures():
    grain = fractal(40, 3, 11); fine = fractal(110, 2, 23); lump = fractal(5, 2, 37)
    rng = np.random.default_rng(5); spark = rng.random((S, S))
    ice = solid((0.97, 0.985, 1.0)) * (1 - 0.10 * np.clip(grain, 0, 1) - 0.07 * np.abs(fine))[..., None]
    ice = mix(ice, solid((0.84, 0.92, 1.0)), (fine < -0.5).astype(float) * 0.6)          # crystal gaps, a cool blue
    ice = np.where((spark > 0.988)[..., None], np.minimum(ice * 1.25, 1.0), ice)          # sparkle
    rough_ice = 0.58 + 0.22 * np.abs(grain)
    nrm = normal_from_height(0.6 * grain + 0.4 * fine, 7.0)
    def variant(name, col, rough):
        IMAGES[name] = (save_img(name + "_color", col), save_img(name + "_rough", np.dstack((rough,) * 3), True), save_img(name + "_normal", nrm, True))
    variant("ice_white", ice, rough_ice)
    s = np.clip((0.66 - V) * 4.5 + 0.45 * lump, 0, 1)
    blue = mix(ice, solid((0.20, 0.56, 0.93)), s * 0.92)
    blue = mix(blue, solid((0.20, 0.56, 0.93)), ((V > 0.66) & (fine > 0.45)).astype(float) * 0.7)   # blue flecks on the white top
    variant("ice_blue", blue, rough_ice - 0.3 * s)
    st = np.clip((0.74 - V) * 5 + 0.4 * lump, 0, 1)                                       # red below, white top (her photo)
    straw = mix(ice, solid((0.86, 0.10, 0.22)), st * 0.94)
    straw = mix(straw, solid((0.86, 0.10, 0.22)), ((V > 0.74) & (fine > 0.5)).astype(float) * 0.6)   # red flecks on the white top
    variant("ice_straw", straw, rough_ice - 0.28 * st)
    vb = V + 0.035 * lump
    bands = [(0.20, (0.90, 0.15, 0.20)), (0.38, (0.98, 0.52, 0.12)), (0.55, (0.98, 0.85, 0.20)), (0.73, (0.35, 0.75, 0.30)), (9.0, (0.30, 0.62, 0.95))]
    bear = ice.copy(); lo = -1.0
    for hi, c in bands:
        m = ((vb >= lo) & (vb < hi)).astype(float)
        bear = mix(bear, solid(c), m * 0.86); lo = hi
    variant("ice_bear", bear, rough_ice - 0.25)
    blotch = fractal(5, 2, 71); crust = solid((0.80, 0.55, 0.22)) * (1 - 0.08 * np.abs(fine))[..., None]
    crust = mix(crust, solid((0.52, 0.30, 0.10)), np.clip((blotch - 0.2) * 2.5, 0, 1))
    crust = mix(crust, solid((0.40, 0.22, 0.08)), (fine > 0.62).astype(float) * 0.7)
    IMAGES["crust"] = (save_img("crust_color", crust), save_img("crust_rough", np.dstack((0.5 + 0.2 * np.abs(grain),) * 3), True),
                       save_img("crust_normal", normal_from_height(0.5 * grain + 0.5 * fine, 5.0), True))
    cup = solid((0.97, 0.96, 0.92)); wave = 0.018 * np.sin(U * 2 * math.pi * 14)
    for a, b in ((0.22, 0.34), (0.52, 0.64)):
        band = ((V > a + wave) & (V < b + wave)).astype(float)
        cup = mix(cup, solid((0.20, 0.45, 0.80)), band)
        cup = mix(cup, solid((0.97, 0.96, 0.92)), ((V > a + 0.04 + wave) & (V < a + 0.055 + wave)).astype(float))
    IMAGES["cup"] = (save_img("cup_color", cup), None, None)

# ------------------------------------------------------------ meshes
BMS, UVL = {}, {}
def bm_for(key):
    if key not in BMS:
        BMS[key] = bmesh.new(); UVL[key] = BMS[key].loops.layers.uv.new("UVMap")
    return BMS[key]
def hull(key, pts):
    bm = bm_for(key)
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(key, x0, x1, y0, y1, z0, z1): hull(key, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cbox(key, x0, x1, y0, y1, z0, z1, c):
    pts = []
    for (ax, ay, az) in ((c, 0, c), (0, c, c), (c, c, 0)):
        pts += [(x, y, z) for x in (x0 + ax, x1 - ax) for y in (y0 + ay, y1 - ay) for z in (z0 + az, z1 - az)]
    hull(key, pts)
def ring(cx, cz, rx, rz, y, seg): return [(cx + rx * math.cos(2 * math.pi * i / seg), y, cz + rz * math.sin(2 * math.pi * i / seg)) for i in range(seg)]
def frustum(key, cx, cz, r0, y0, r1, y1, seg=16): hull(key, ring(cx, cz, r0, r0, y0, seg) + ring(cx, cz, r1, r1, y1, seg))
def cyl(key, cx, cz, r, y0, y1, seg=16): frustum(key, cx, cz, r, y0, r, y1, seg)
def dome(key, cx, cz, r, y0, h, seg=16, steps=5):
    prev = None
    for k in range(steps + 1):
        t = k / steps
        rr = r * math.cos(t * math.pi / 2); yy = y0 + h * math.sin(t * math.pi / 2)
        if prev is not None: hull(key, ring(cx, cz, prev[0], prev[0], prev[1], seg) + ring(cx, cz, max(rr, 0.02), max(rr, 0.02), yy, seg))
        prev = (rr, yy)
def sphere_hull(key, cx, cy, cz, r, seg=10, rows=6):
    pts = []
    for j in range(1, rows):
        ph = math.pi * j / rows
        pts += ring(cx, cz, r * math.sin(ph), r * math.sin(ph), cy + r * math.cos(ph), seg)
    pts += [(cx, cy + r, cz), (cx, cy - r, cz)]
    hull(key, pts)
def stick(key, a, b, t):
    pts = []
    for (x, y, z) in (a, b):
        pts += [(x + dx, y + dy, z + dz) for dx in (-t, t) for dy in (-t, t) for dz in (-t, t)]
    hull(key, pts)
def lathe(key, cx, cz, prof, seg, disp=None, uvv=(0.0, 1.0)):
    """A real surface of revolution with (u around, v height) UVs: prof = [(r, y)] bottom -> top, r 0 at a pole.
    disp(co) displaces each new vertex along its outward normal (lumps / grain)."""
    bm = bm_for(key); uv = UVL[key]
    rings = []
    for (r, y) in prof:
        if r <= 1e-4: rings.append(("pole", bm.verts.new(P(cx, y, cz))))
        else: rings.append(("ring", [bm.verts.new(P(cx + r * math.cos(2 * math.pi * i / seg), y, cz + r * math.sin(2 * math.pi * i / seg))) for i in range(seg)]))
    n = len(prof); faces = []
    for j in range(n - 1):
        a, b = rings[j], rings[j + 1]
        tj = uvv[0] + (uvv[1] - uvv[0]) * j / (n - 1); tj1 = uvv[0] + (uvv[1] - uvv[0]) * (j + 1) / (n - 1)
        for i in range(seg):
            i1 = (i + 1) % seg
            if a[0] == "ring" and b[0] == "ring":
                f = bm.faces.new((a[1][i], a[1][i1], b[1][i1], b[1][i])); uvs = [(i / seg, tj), ((i + 1) / seg, tj), ((i + 1) / seg, tj1), (i / seg, tj1)]
            elif a[0] == "ring":
                f = bm.faces.new((a[1][i], a[1][i1], b[1])); uvs = [(i / seg, tj), ((i + 1) / seg, tj), ((i + 0.5) / seg, tj1)]
            else:
                f = bm.faces.new((a[1], b[1][i1], b[1][i])); uvs = [((i + 0.5) / seg, tj), ((i + 1) / seg, tj1), (i / seg, tj1)]
            for l, (u, v) in zip(f.loops, uvs): l[uv].uv = (u, v)
            faces.append(f)
    bmesh.ops.recalc_face_normals(bm, faces=faces)
    if disp:
        bm.normal_update()
        verts = {v for f in faces for v in f.verts}
        new = {v: v.co + v.normal * disp(v.co) for v in verts}
        for v, co in new.items(): v.co = co
        bm.normal_update()
def mound_prof(cx_r, y0, H, rows):
    prof = []
    for j in range(rows + 1):
        t = j / rows
        r = cx_r * max(0.0, 1 - t ** 2.2) ** 0.5
        prof.append((r if j < rows else 0.0, y0 + H * t))
    return prof
def smooth01(x): x = min(max(x, 0.0), 1.0); return x * x * (3 - 2 * x)
def heap_prof(rows):
    """The kakigori heap: starts INSIDE the cup (r 0.33 at y 0.4, under the rim at 0.62), widens to 0.56 by y 0.84 so it
    overhangs the rim, then domes. v3 started at y 0.5 with r 0.5 and bled through the cup wall (Shannon, in the game)."""
    prof = []
    for j in range(rows + 1):
        t = j / rows
        if t < 0.35: r = 0.33 + 0.23 * smooth01(t / 0.35)
        else: r = 0.56 * max(0.0, 1 - ((t - 0.35) / 0.65) ** 2.2) ** 0.5
        prof.append((r if j < rows else 0.0, 0.4 + 1.25 * t))
    return prof
def heap_disp(off):
    base = noise_disp(0.055, 2.6, 0.024, 7.0, 0.009, 18.0, off)
    return lambda co: base(co) * smooth01((co.z - 0.55) / 0.35)      # co.z is the design-frame height; no lumps inside the cup
def sphere_prof(r, cy, rows):
    return [(r * math.sin(math.pi * j / rows) if 0 < j < rows else 0.0, cy - r * math.cos(math.pi * j / rows)) for j in range(rows + 1)]
def noise_disp(a1, f1, a2, f2, a3=0.0, f3=1.0, off=0.0):
    o = Vector((off, off * 0.7, off * 1.3))
    return lambda co: a1 * mnoise.noise(co * f1 + o) + a2 * mnoise.noise(co * f2 + o * 2) + (a3 * mnoise.noise(co * f3 + o * 3) if a3 else 0.0)
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    nt = m.node_tree; bs = nt.nodes["Principled BSDF"]
    if key in TEX:
        col, rough, nrm = IMAGES[TEX[key]]
        tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = col; nt.links.new(tc.outputs["Color"], bs.inputs["Base Color"])
        if rough:
            tr = nt.nodes.new("ShaderNodeTexImage"); tr.image = rough; nt.links.new(tr.outputs["Color"], bs.inputs["Roughness"])
        else: bs.inputs["Roughness"].default_value = 0.55
        if nrm:
            tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = nrm
            nm = nt.nodes.new("ShaderNodeNormalMap"); nm.inputs["Strength"].default_value = 1.0
            nt.links.new(tn.outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
        m.diffuse_color = (0.9, 0.9, 0.9, 1)
    else:
        c = COL[key]
        bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
        bs.inputs["Roughness"].default_value = 0.25 if key in ("KG_Glass", "TK_Glass", "TK_Sauce", "KG_Chrome", "TK_Chrome", "KG_SyrupRed", "KG_SyrupGreen", "KG_SyrupBlue", "KG_SyrupYellow") else 0.6
        if key in ("KG_Chrome", "TK_Chrome", "KG_Tray"): bs.inputs["Metallic"].default_value = 0.9
        if key in ("KG_Glass", "TK_Glass", "KG_Ice"): bs.inputs["Alpha"].default_value = 0.5; m.blend_method = "BLEND"
        m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def flush():
    objs = []
    for key, bm in BMS.items():
        uv = UVL[key]
        bmesh.ops.remove_doubles(bm, verts=[v for v in bm.verts if not v.link_faces or key not in TEX], dist=0.0003) if key not in TEX else None
        bm.normal_update()
        if key not in TEX:                                           # box UVs for the hull pieces (lathe pieces carry their own)
            for f in bm.faces:
                n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
                for l in f.loops:
                    c = l.vert.co; u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
                    l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
        me = bpy.data.meshes.new(key); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(key, me); bpy.context.scene.collection.objects.link(o)
        me.materials.append(material(key))
        for p in me.polygons: p.use_smooth = key in SMOOTH
        objs.append(o)
    BMS.clear(); UVL.clear()
    return objs
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

# ------------------------------------------------------------ kakigori
def kakigori_a():
    cbox("KG_Iron", -2.35, -0.85, 0.0, 0.14, -0.6, 0.6, 0.03)
    box("KG_Enamel", -1.85, -1.35, 0.14, 1.75, 0.18, 0.52)
    cbox("KG_Enamel", -2.25, -0.95, 1.75, 2.0, -0.35, 0.52, 0.04)
    cyl("KG_Chrome", -1.6, -0.05, 0.5, 1.0, 1.06, 18)
    cyl("KG_Iron", -1.6, -0.05, 0.42, 1.06, 1.75, 18)
    cyl("KG_Chrome", -1.6, -0.05, 0.1, 2.0, 2.12, 10)
    stick("KG_Chrome", (-1.6, 2.1, -0.05), (-0.95, 2.1, -0.05), 0.035)
    cyl("KG_Knob", -0.95, -0.05, 0.075, 2.1, 2.42, 10)
    frustum("KG_Glass", -1.6, -0.05, 0.3, 0.14, 0.48, 0.62, 16)
    lathe("KG_FaceSnow", -1.6, -0.05, mound_prof(0.38, 0.45, 0.3, 8), 24, noise_disp(0.02, 8, 0.01, 20, off=3.0))   # snow in the catch bowl
    cbox("KG_Tray", -0.45, 0.95, 0.0, 0.1, -0.55, 0.55, 0.02)
    cbox("KG_Ice", -0.35, 0.85, 0.1, 0.98, -0.42, 0.42, 0.07)
    stick("KG_Chrome", (0.5, 0.12, -0.5), (1.15, 0.12, -0.25), 0.03)
    stick("KG_Chrome", (0.5, 0.12, -0.5), (1.15, 0.12, -0.62), 0.03)
    cbox("KG_Wood", 1.35, 3.05, 0.0, 0.42, -0.42, 0.42, 0.03)
    for i, key in enumerate(("KG_SyrupRed", "KG_SyrupGreen", "KG_SyrupBlue", "KG_SyrupYellow")):
        x = 1.58 + i * 0.41
        lathe(key, x, 0.0, [(0.0, 0.42), (0.15, 0.42), (0.165, 0.5), (0.165, 1.15), (0.1, 1.3), (0.07, 1.36), (0.0, 1.36)], 14)
        cyl(key, x, 0.0, 0.09, 1.36, 1.52, 10)
        stick("KG_Chrome", (x, 1.5, 0.0), (x, 1.5, -0.2), 0.03)
    lathe("KG_CupTex", 1.12, -0.78, [(0.0, 0.0), (0.13, 0.0), (0.16, 0.45), (0.0, 0.45)], 14)   # the straw cup
    for k, skey in enumerate(("KG_Straw", "KG_SyrupBlue", "KG_SyrupYellow", "KG_SyrupGreen", "KG_Straw", "KG_SyrupBlue", "KG_Chrome", "KG_Chrome")):
        a = 2 * math.pi * k / 8
        stick(skey, (1.12 + 0.07 * math.cos(a), 0.3, -0.78 + 0.07 * math.sin(a)), (1.12 + 0.14 * math.cos(a), 1.05, -0.78 + 0.14 * math.sin(a)), 0.016)
    return flush()
CUP = [(0.0, 0.08), (0.4, 0.08), (0.5, 0.62), (0.46, 0.62), (0.42, 0.36), (0.0, 0.36)]   # a hollow cup: outer wall, rim, inner wall, floor
def tray_and_cup(x, z):
    cbox("KG_Wood", x - 0.8, x + 0.8, 0.0, 0.08, z - 0.62, z + 0.62, 0.03)
    lathe("KG_CupTex", x - 0.15, z, CUP, 24)
    hull("KG_Chrome", ring(x + 0.55, z + 0.3, 0.13, 0.09, 0.09, 10) + ring(x + 0.55, z + 0.3, 0.1, 0.06, 0.13, 10))
    stick("KG_Chrome", (x + 0.55, 0.11, z + 0.2), (x + 0.62, 0.11, z - 0.5), 0.025)
    return x - 0.15
def ice_mound(key, cx, z, off):
    lathe(key, cx, z, heap_prof(44), 56, heap_disp(off))
def mini_flag(x, z, key):
    stick("KG_MiniStick", (x, 1.5, z), (x + 0.06, 2.25, z), 0.018)
    box(key, x + 0.04, x + 0.36, 1.95, 2.27, z - 0.012, z + 0.012)
def kakigori_b():
    for k in range(5):
        lathe("KG_CupTex", -2.45, 0.0, [(r, y - 0.08 + 0.1 * k) for (r, y) in CUP], 24)
    cx = tray_and_cup(-1.05, -0.25); ice_mound("KG_MoundBlue", cx, -0.25, 1.0); mini_flag(cx, -0.25, "KG_MiniFlag1")
    cx = tray_and_cup(0.55, 0.2); ice_mound("KG_MoundBear", cx, 0.2, 5.0)
    for sx in (-0.33, 0.33):
        hull("KG_Cookie", [(cx + sx + 0.17 * math.cos(a), 1.66 + 0.17 * math.sin(a), zz) for a in [2 * math.pi * i / 12 for i in range(12)] for zz in (0.22, 0.3)])
    lathe("KG_FaceSnow", cx, -0.12, sphere_prof(0.3, 1.12, 18), 28, noise_disp(0.015, 9, 0.008, 22, off=9.0))
    for sx in (-0.12, 0.12): sphere_hull("KG_Choco", cx + sx, 1.24, -0.12 - 0.26, 0.045, 8, 4)
    sphere_hull("KG_SyrupRed", cx, 1.1, -0.12 - 0.29, 0.065, 8, 4)
    for sx in (-0.21, 0.21): sphere_hull("KG_Pink", cx + sx, 1.06, -0.12 - 0.2, 0.04, 8, 4)
    cx = tray_and_cup(2.1, -0.3); ice_mound("KG_MoundStraw", cx, -0.3, 13.0)
    lathe("KG_Cream", cx, -0.3, mound_prof(0.2, 1.56, 0.17, 8), 24, noise_disp(0.03, 5.0, 0.012, 12.0, off=21.0))       # a dollop of cream hugging the peak
    lathe("KG_SyrupRed", cx + 0.07, -0.36, [(0.0, 1.7), (0.07, 1.71), (0.1, 1.78), (0.085, 1.86), (0.04, 1.93), (0.0, 1.95)], 12,
          noise_disp(0.006, 40, 0.0, 1))                                                                             # the strawberry
    for a in (0.3, 2.4, 4.5): stick("KG_SyrupGreen", (cx + 0.07, 1.93, -0.36), (cx + 0.07 + 0.07 * math.cos(a), 1.9, -0.36 + 0.07 * math.sin(a)), 0.012)
    mini_flag(cx - 0.14, -0.24, "KG_MiniFlag2")
    return flush()
def kori_flag():
    cbox("KG_FlagPole", -0.25, 0.25, 0.0, 0.12, -0.25, 0.25, 0.02)
    cyl("KG_FlagPole", 0.0, 0.0, 0.05, 0.0, 6.6, 10)
    stick("KG_FlagPole", (0.0, 6.42, 0.0), (1.25, 6.42, 0.0), 0.04)
    box("KG_FlagCloth", 0.08, 1.2, 3.5, 6.35, -0.02, 0.02)
    return flush()

# ------------------------------------------------------------ takoyaki
def ball(x, y, z, r, sauced, off):
    lathe("TK_BallTex", x, z, sphere_prof(r, y, 12), 18, noise_disp(0.013, 22, 0.006, 50, off=off))
    if sauced: lathe("TK_Sauce", x, z, [(r * 0.78, y + r * 0.5), (r * 0.6, y + r * 0.85), (r * 0.3, y + r * 1.03), (0.0, y + r * 1.06)], 14, noise_disp(0.012, 30, 0.0, 1, off=off + 1))
def takoyaki_a():
    cbox("TK_IronDark", -2.95, -0.05, 0.0, 0.32, -0.95, 0.95, 0.04)
    box("TK_Chrome", -1.65, -1.35, 0.1, 0.24, -1.03, -0.95)
    cbox("TK_Iron", -2.85, -0.15, 0.32, 0.58, -0.85, 0.85, 0.03)
    k = 0
    for i in range(6):
        for j in range(4):
            k += 1
            ball(-2.62 + i * 0.47, 0.58, -0.62 + j * 0.41, 0.19, (i + j) % 3 == 0, k * 0.7)
    stick("TK_Chrome", (-2.9, 0.62, 0.9), (-1.7, 0.62, 1.0), 0.025)
    for x, body, cap in ((0.85, "TK_SauceBottle", "TK_RedCap"), (1.45, "TK_MayoBottle", "TK_YellowCap")):
        lathe(body, x, 0.25, [(0.0, 0.0), (0.15, 0.0), (0.17, 0.1), (0.17, 0.9), (0.15, 0.95), (0.0, 0.95)], 14)
        lathe(cap, x, 0.25, [(0.0, 0.95), (0.17, 0.95), (0.05, 1.25), (0.0, 1.28)], 14)
    cyl("TK_Glass", 2.45, 0.3, 0.32, 0.0, 0.72, 16)
    cyl("TK_Bonito", 2.45, 0.3, 0.27, 0.03, 0.6, 12)
    cyl("TK_Chrome", 2.45, 0.3, 0.33, 0.72, 0.82, 16)
    cyl("TK_Bamboo", 2.4, -0.65, 0.16, 0.0, 0.46, 12)
    for q in range(7):
        a = 2 * math.pi * q / 7
        stick("TK_Pick", (2.4 + 0.08 * math.cos(a), 0.3, -0.65 + 0.08 * math.sin(a)), (2.4 + 0.13 * math.cos(a), 0.95, -0.65 + 0.13 * math.sin(a)), 0.014)
    return flush()
def boat(x, z, off):
    hull("TK_Paper", ring(x, z, 0.55, 0.36, 0.0, 12) + ring(x, z, 0.78, 0.52, 0.24, 12))
    k = 0
    for i in range(3):
        for j in range(2):
            k += 1
            ball(x - 0.27 + i * 0.27, 0.3, z - 0.14 + j * 0.28, 0.16, True, off + k)
    rng = np.random.default_rng(int(off))
    pts = [(x - 0.44 + k * 0.063, 0.50 + 0.012 * math.sin(k * 2.1), z + 0.17 * math.sin(k * 0.9 + off)) for k in range(15)]   # the mayo squiggle
    for p, q in zip(pts, pts[1:]): stick("TK_Mayo", p, q, 0.016)
    for k in range(10):                                                    # nori flakes: thin, varied, turned any which way
        a = rng.uniform(0, 2 * math.pi); cx, cz = x + rng.uniform(-0.38, 0.38), z + rng.uniform(-0.22, 0.22)
        w, h = rng.uniform(0.03, 0.06), rng.uniform(0.02, 0.04); y = 0.5 + rng.uniform(0.0, 0.03)
        hull("TK_Nori", [(cx + dx * math.cos(a) - dz * math.sin(a), y + dy, cz + dx * math.sin(a) + dz * math.cos(a)) for dx in (-w, w) for dz in (-h, h) for dy in (0, 0.006)])
    for k in range(6):                                                     # bonito flakes: thin curled shavings
        a = rng.uniform(0, 2 * math.pi); cx, cz = x + rng.uniform(-0.36, 0.36), z + rng.uniform(-0.2, 0.2); y = 0.52 + rng.uniform(0, 0.04)
        prev = (cx, y, cz)
        for s in range(3):
            nxt = (prev[0] + 0.045 * math.cos(a + s * 0.9), prev[1] + 0.02, prev[2] + 0.045 * math.sin(a + s * 0.9))
            stick("TK_Bonito", prev, nxt, 0.007); prev = nxt
def takoyaki_b():
    boat(-2.0, -0.3, 20.0); boat(-0.3, 0.3, 30.0); boat(1.4, -0.25, 40.0)
    cyl("TK_Glass", 2.55, 0.35, 0.15, 0.0, 0.62, 12)
    cyl("TK_Nori", 2.55, 0.35, 0.12, 0.03, 0.5, 10)
    cyl("TK_Chrome", 2.55, 0.35, 0.155, 0.62, 0.72, 12)
    return flush()

# ------------------------------------------------------------ the lit render of the served trio (judged before any import)
def render_served(objs):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48; sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640; sc.render.film_transparent = False
    w = bpy.data.worlds.new("w"); w.use_nodes = True; sc.world = w
    bg = w.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.62, 0.66, 0.72, 1); bg.inputs[1].default_value = 0.9
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 3.0; sun.data.angle = 0.25
    sun.rotation_euler = (math.radians(50), math.radians(-20), math.radians(35)); sc.collection.objects.link(sun)
    fill = bpy.data.objects.new("fill", bpy.data.lights.new("fill", "AREA")); fill.data.energy = 300; fill.data.size = 6
    fill.location = P(2.0, 4.0, -5.0); fill.rotation_euler = (Vector(P(0, 1, 0)) - Vector(P(2, 4, -5))).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(fill)
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, -0.001)); pl = bpy.context.active_object
    mw = bpy.data.materials.new("counter"); mw.use_nodes = True; mw.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.62), lin(0.5), lin(0.36), 1)
    pl.data.materials.append(mw)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 42
    loc, target = (0.9, 2.3, -4.6), (0.5, 0.95, 0.0)
    cam.location = P(*loc); cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUT, "render_served3.png"); bpy.ops.render.render(write_still=True); log("rendered render_served3.png")
    loc, target = (-0.6, 1.9, -3.4), (-0.3, 0.6, 0.1)
    for o in objs: o.hide_render = True
    for o in TAKO: o.hide_render = False
    cam.location = P(*loc); cam.rotation_euler = (Vector(P(*target)) - Vector(P(*loc))).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUT, "render_takoyaki3.png"); bpy.ops.render.render(write_still=True); log("rendered render_takoyaki3.png")

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"}, path_mode="COPY", embed_textures=True)
TAKO = []
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    make_textures(); log("textures made")
    pieces = {"kakigori_a": kakigori_a(), "kakigori_b": kakigori_b(), "kori_flag": kori_flag(), "takoyaki_a": takoyaki_a(), "takoyaki_b": takoyaki_b()}
    TAKO = pieces["takoyaki_b"]
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)], "parts": {o.name: tris(o) for o in objs}}
        big = max(objs, key=tris)
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris (largest {big.name} {tris(big)})")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 10.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit38_stalls3.fbx"))
    served = [o for o in allobjs if o.name == "kakigori_b" or (o.parent and o.parent.name == "kakigori_b")]
    export(served, os.path.join(OUT, "japan_kit38_kakigori4.fbx"))     # the served set alone, for the cup-fix re-import
    log("FBX_DONE")
    try:
        for name, objs in pieces.items():
            if name != "kakigori_b":
                for o in objs: o.hide_render = True
        for o in allobjs:
            if o.type == "EMPTY": o.location.x = 0.0
        render_served(pieces["kakigori_b"])
        log("RENDER_DONE")
    except Exception:
        log(traceback.format_exc()); log("RENDER_FAILED")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
