# Blender (bpy 5.2) script: builds the rainbow hot air balloon for Porto's balloon field (Shannon, Oct 9 2026, from her
# reference: twelve rainbow gores on a teardrop envelope, tan load tapes, cables to a burner frame on four leather
# uprights, a wicker basket with a padded rim, sandbags and a coiled rope). 1 Blender unit = 1 stud, Z up, the basket
# floor centre at the origin. One 512 px texture atlas for everything; the flame is its own object (Neon in Roblox).
# Objects: Envelope, EnvelopeInner, Rigging, Basket, Flame (each well under Roblox's 20k triangle limit).
# Run: python make_balloon.py <out_dir> [--render]   (writes balloon.fbx, balloon.glb, balloon_atlas.png, previews)
import bpy, bmesh, math, sys, os
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
RENDER = "--render" in sys.argv
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

# ---------------- the texture atlas (512 x 512, v = 0 at the bottom) ----------------
# top half: 8 columns of 64 px: six gore colours, tan rope, metal.  bottom half: wicker (left 256), leather, dark leather.
S = 512
img = np.zeros((S, S, 4), dtype=np.float32); img[..., 3] = 1
GORE = [(0.86, 0.10, 0.09), (0.96, 0.47, 0.06), (0.99, 0.84, 0.10), (0.12, 0.62, 0.20), (0.10, 0.32, 0.86), (0.50, 0.17, 0.68)]
yy, xx = np.mgrid[0:S, 0:S]
for c in range(8):
    x0 = c * 64
    u = (xx[256:, x0:x0 + 64] - x0 + 0.5) / 64.0
    v = (yy[256:, x0:x0 + 64] - 256 + 0.5) / 256.0
    if c < 6:
        shade = (0.80 + 0.20 * np.sin(np.pi * u) ** 0.6) * (0.90 + 0.10 * v)
        col = GORE[c]
    elif c == 6:
        shade = 0.85 + 0.15 * np.sin(np.pi * u) * (0.9 + 0.1 * np.sin(v * 200))
        col = (0.78, 0.66, 0.47)
    else:
        shade = 0.75 + 0.25 * np.sin(np.pi * u)
        col = (0.62, 0.63, 0.66)
    for k in range(3):
        img[256:, x0:x0 + 64, k] = np.clip(col[k] * shade, 0, 1)
# wicker: woven rows over upright stakes
wx, wy = xx[:256, :256], yy[:256, :256]
row = wy // 10
strand = 0.72 + 0.28 * np.sin(np.pi * (wy % 10) / 10.0)
weave = 0.86 + 0.14 * np.cos(2 * np.pi * (wx + (row % 2) * 12) / 24.0)
stake = np.where((wx % 24) < 2, 0.70, 1.0)
w = strand * weave * stake
for k, cc in enumerate((0.74, 0.56, 0.33)):
    img[:256, :256, k] = np.clip(cc * w, 0, 1)
# leather (two browns) with a soft grain
grain = 0.92 + 0.08 * np.sin(xx[:256, 256:] * 0.9) * np.sin(yy[:256, 256:] * 0.7)
for k, (a, b) in enumerate(((0.50, 0.30), (0.29, 0.16), (0.16, 0.08))):
    img[:256, 256:384, k] = a * grain[:, :128]
    img[:256, 384:448, k] = b * grain[:, 128:192]
cu = (xx[:256, 448:] - 448 + 0.5) / 64.0
for k in range(3):
    img[:256, 448:, k] = 0.86 + 0.14 * np.sin(np.pi * cu)          # white cloth, a little shaded at its edges
# the wavy white band round the upper envelope (Shannon's picture), painted into every gore column so it runs round
gv = (yy[256:, :384] - 256 + 0.5) / 256.0
gu = ((xx[256:, :384] % 64) + 0.5) / 64.0
mid = 0.725 + 0.022 * np.sin(2 * np.pi * gu)
d = np.abs(gv - mid)
band = d < 0.040
edge = (d >= 0.040) & (d < 0.046)
for k in range(3):
    ch = img[256:, :384, k]
    ch[band] = 0.97 - 0.10 * (d[band] / 0.040) ** 2
    ch[edge] = 0.62
atlas = bpy.data.images.new("balloon_atlas", S, S, alpha=False)
atlas.pixels.foreach_set(img.ravel())
atlas.filepath_raw = os.path.join(OUT, "balloon_atlas.png"); atlas.file_format = "PNG"; atlas.save()
atlas.pack()

def material(name, image=None, colour=None, emit=0.0):
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if image:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = image
        nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    if colour:
        bsdf.inputs["Base Color"].default_value = (*colour, 1)
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*colour, 1); bsdf.inputs["Emission Strength"].default_value = emit
    bsdf.inputs["Roughness"].default_value = 0.6
    return m
MAT = material("BalloonAtlas", image=atlas)
FLAME_MAT = material("Flame", colour=(1.0, 0.55, 0.12), emit=6.0)

# UV regions (u0, v0, u1, v1)
def gore_uv(c): return (c / 8 + 0.004, 0.502, (c + 1) / 8 - 0.004, 0.998)
TAN = (6 / 8 + 0.01, 0.51, 7 / 8 - 0.01, 0.99)
METAL = (7 / 8 + 0.01, 0.51, 1 - 0.01, 0.99)
WICKER = (0.002, 0.002, 0.498, 0.498)
LEATHER = (0.502, 0.002, 0.748, 0.498)
DARK = (0.752, 0.002, 0.873, 0.498)
WHITE = (0.877, 0.002, 0.998, 0.498)

class Builder:
    def __init__(self): self.v, self.f, self.uv = [], [], []
    def add_vert(self, p): self.v.append(tuple(p)); return len(self.v) - 1
    def face(self, idx, uvs): self.f.append(tuple(idx)); self.uv.append(list(uvs))
    def grid(self, pts, region, flip=False, wrap=False):
        """pts[i][j]: rows i (along), columns j (around). Quads; uv spread over the region."""
        n, m = len(pts), len(pts[0])
        ids = [[self.add_vert(p) for p in r] for r in pts]
        u0, v0, u1, v1 = region
        cols = m if wrap else m - 1
        for i in range(n - 1):
            for j in range(cols):
                j2 = (j + 1) % m
                a, b, c, d = ids[i][j], ids[i][j2], ids[i + 1][j2], ids[i + 1][j]
                ua, ub = u0 + (u1 - u0) * j / cols, u0 + (u1 - u0) * (j + 1) / cols
                va, vb = v0 + (v1 - v0) * i / (n - 1), v0 + (v1 - v0) * (i + 1) / (n - 1)
                q, quv = [a, b, c, d], [(ua, va), (ub, va), (ub, vb), (ua, vb)]
                if flip: q.reverse(); quv.reverse()
                self.face(q, quv)
    def object(self, name, mat, smooth=True):
        me = bpy.data.meshes.new(name)
        me.from_pydata(self.v, [], self.f)
        uvl = me.uv_layers.new(name="UVMap")
        li = 0
        for poly, uvs in zip(me.polygons, self.uv):
            for k in range(poly.loop_total):
                uvl.data[poly.loop_start + k].uv = uvs[k]
        for p in me.polygons: p.use_smooth = smooth
        me.validate(); me.update()
        me.materials.append(mat)
        ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
        return ob

def frame_vectors(t):
    t = np.array(t, float); t /= np.linalg.norm(t)
    a = np.array((0, 0, 1.0)) if abs(t[2]) < 0.9 else np.array((1.0, 0, 0))
    n = np.cross(t, a); n /= np.linalg.norm(n); b = np.cross(t, n)
    return n, b

def tube(B, path, radius, sides, region, closed=False):
    path = [np.array(p, float) for p in path]
    rings = []
    for i, p in enumerate(path):
        if closed: t = path[(i + 1) % len(path)] - path[i - 1]
        else: t = path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]
        n, b = frame_vectors(t)
        r = radius(i / max(1, len(path) - 1)) if callable(radius) else radius
        rings.append([p + r * (math.cos(2 * math.pi * k / sides) * n + math.sin(2 * math.pi * k / sides) * b) for k in range(sides)])
    if closed: rings.append(rings[0])
    B.grid(rings, region, wrap=True)

def lathe(B, profile, sides, region, flip=False, centre=(0, 0, 0)):
    cx, cy, cz = centre
    pts = [[(cx + r * math.cos(2 * math.pi * k / sides), cy + r * math.sin(2 * math.pi * k / sides), cz + z) for k in range(sides)] for (r, z) in profile]
    B.grid(pts, region, flip=flip, wrap=True)

# ---------------- the envelope ----------------
R, H, Z_MOUTH, N_GORE, SEG = 15.0, 36.0, 13.0, 12, 8
Y_EQ = 0.58 * H
R_MOUTH = 0.17 * R
def env_rings():
    out = []
    for i in range(28):                                  # lower: mouth to the equator
        s = i / 27
        out.append((R_MOUTH + (R - R_MOUTH) * (1 - (1 - s) ** 2.2), s * Y_EQ))
    for i in range(1, 21):                               # the dome
        ph = (math.pi / 2) * (i / 21) ** 0.9
        out.append((R * math.cos(ph), Y_EQ + (H - Y_EQ) * math.sin(ph)))
    return out
RINGS = env_rings()
def env_point(r, z, theta, scale=1.0):
    g = theta / (2 * math.pi / N_GORE)
    frac = g - math.floor(g)
    rr = r * (1 + 0.045 * math.sin(math.pi * frac)) * scale
    return (rr * math.cos(theta), rr * math.sin(theta), Z_MOUTH + z)

def envelope(B, scale=1.0, flip=False):
    order = [5, 0, 1, 2, 3, 4]                           # purple, red, orange, yellow, green, blue, as in the picture
    for g in range(N_GORE):
        pts = []
        for (r, z) in RINGS:
            pts.append([env_point(r, z, 2 * math.pi * (g + j / SEG) / N_GORE, scale) for j in range(SEG + 1)])
        B.grid(pts, gore_uv(order[g % 6]), flip=flip)
    # the crown vent cap
    top = B.add_vert((0, 0, Z_MOUTH + H))
    r, z = RINGS[-1]
    ring = [B.add_vert(env_point(r, z, 2 * math.pi * k / (N_GORE * SEG), scale)) for k in range(N_GORE * SEG)]
    u0, v0, u1, v1 = TAN
    for k in range(len(ring)):
        tri = [ring[k], ring[(k + 1) % len(ring)], top]
        uv = [(u0, v1), (u1, v1), ((u0 + u1) / 2, v1)]
        if flip: tri.reverse(); uv.reverse()
        B.face(tri, uv)

E = Builder()
envelope(E)
for g in range(N_GORE):                                  # load tapes on every seam
    th = 2 * math.pi * g / N_GORE
    tube(E, [env_point(r + 0.06, z, th) for (r, z) in RINGS], 0.14, 5, TAN)
tube(E, [env_point(R_MOUTH + 0.05, 0.05, 2 * math.pi * k / 48) for k in range(48)], 0.2, 6, TAN, closed=True)
rc, zc = RINGS[-1]
tube(E, [(rc * math.cos(2 * math.pi * k / 32), rc * math.sin(2 * math.pi * k / 32), Z_MOUTH + zc + 0.05) for k in range(32)], 0.18, 6, TAN, closed=True)
# white swags draped round the balloon below its widest point, one scallop per gore (Shannon's picture)
RZ = np.array([z for (r, z) in RINGS]); RR = np.array([r for (r, z) in RINGS])
def r_at(z): return float(np.interp(z, RZ, RR))
Z_LINE, DEEP, THIN = Y_EQ * 0.86, 3.0, 1.1
for g in range(N_GORE):
    rows = []
    for (amp, off) in ((THIN, 0.10), (DEEP, 0.10)):
        row = []
        for j in range(13):
            u = j / 12
            z = Z_LINE - amp * math.sin(math.pi * u)
            th = 2 * math.pi * (g + u) / N_GORE
            row.append(env_point(r_at(z) + off + 0.18 * math.sin(math.pi * u), z, th))
        rows.append(row)
    mid = [tuple((np.array(a) + np.array(b)) / 2 + 0.06 * np.array((math.cos(2 * math.pi * (g + j / 12) / N_GORE), math.sin(2 * math.pi * (g + j / 12) / N_GORE), 0)))
           for j, (a, b) in enumerate(zip(rows[0], rows[1]))]
    E.grid([rows[0], mid, rows[1]], WHITE)
    E.grid([rows[0], mid, rows[1]], WHITE, flip=True)          # both faces: it is cloth
tube(E, [env_point(r_at(Z_LINE) + 0.12, Z_LINE, 2 * math.pi * k / (N_GORE * SEG)) for k in range(N_GORE * SEG)], 0.1, 5, TAN, closed=True)
E.object("Envelope", MAT)
EI = Builder(); envelope(EI, scale=0.985, flip=True); EI.object("EnvelopeInner", MAT)

# ---------------- rigging: uprights, load frame, burners, cables ----------------
BASKET_H, TOP_HALF, BOT_HALF, Z_FRAME = 3.6, 2.8, 2.5, 8.6
FR = 1.55
corners = [(sx * FR, sy * FR) for sx, sy in ((1, 1), (-1, 1), (-1, -1), (1, -1))]
Rg = Builder()
for (cx, cy) in corners:                                 # leather-wrapped uprights from the basket corners to the frame
    bx, by = math.copysign(TOP_HALF - 0.35, cx), math.copysign(TOP_HALF - 0.35, cy)
    tube(Rg, [(bx + (cx - bx) * t, by + (cy - by) * t, BASKET_H + (Z_FRAME - BASKET_H) * t) for t in np.linspace(0, 1, 6)], 0.2, 8, LEATHER)
tube(Rg, [(c[0], c[1], Z_FRAME) for c in corners], 0.13, 6, METAL, closed=True)
for sx in (-0.55, 0.55):                                 # two burner cans with coils
    lathe(Rg, [(0.0, 0.0), (0.42, 0.0), (0.42, 1.25), (0.3, 1.32), (0.0, 1.32)], 14, METAL, centre=(sx, 0, Z_FRAME - 0.1))
    for k in range(4):
        z = Z_FRAME + 0.15 + k * 0.25
        tube(Rg, [(sx + 0.48 * math.cos(2 * math.pi * a / 14), 0.48 * math.sin(2 * math.pi * a / 14), z) for a in range(14)], 0.05, 4, METAL, closed=True)
tube(Rg, [(-0.55, 0, Z_FRAME + 0.6), (0.55, 0, Z_FRAME + 0.6)], 0.08, 6, METAL)
for g in range(N_GORE):                                  # cables from every load tape to the nearest frame corner
    th = 2 * math.pi * g / N_GORE
    mx, my = R_MOUTH * math.cos(th), R_MOUTH * math.sin(th)
    c = min(corners, key=lambda q: (q[0] - mx) ** 2 + (q[1] - my) ** 2)
    tube(Rg, [(mx, my, Z_MOUTH), (c[0], c[1], Z_FRAME + 0.1)], 0.055, 4, TAN)
Rg.object("Rigging", MAT)

# ---------------- the basket ----------------
Bk = Builder()
def basket_box(half_top, half_bot, z0, z1, flip):
    sq = [(1, 1), (-1, 1), (-1, -1), (1, -1)]
    for k in range(4):
        a, b = sq[k], sq[(k + 1) % 4]
        p = [[(a[0] * half_bot, a[1] * half_bot, z0), (b[0] * half_bot, b[1] * half_bot, z0)],
             [(a[0] * half_top, a[1] * half_top, z1), (b[0] * half_top, b[1] * half_top, z1)]]
        Bk.grid(p, WICKER, flip=not flip)
basket_box(TOP_HALF, BOT_HALF, 0, BASKET_H, False)
basket_box(TOP_HALF - 0.28, BOT_HALF - 0.28, 0.25, BASKET_H, True)
floor = [[(-BOT_HALF + 0.28, -BOT_HALF + 0.28, 0.25), (BOT_HALF - 0.28, -BOT_HALF + 0.28, 0.25)],
         [(-BOT_HALF + 0.28, BOT_HALF - 0.28, 0.25), (BOT_HALF - 0.28, BOT_HALF - 0.28, 0.25)]]
Bk.grid(floor, WICKER)
under = [[(-BOT_HALF, -BOT_HALF, 0), (BOT_HALF, -BOT_HALF, 0)], [(-BOT_HALF, BOT_HALF, 0), (BOT_HALF, BOT_HALF, 0)]]
Bk.grid(under, DARK, flip=True)
def rounded_square(half, z, n=6, rad=0.35):
    pts = []
    for (sx, sy, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        cx, cy = sx * (half - rad), sy * (half - rad)
        for k in range(n):
            a = math.radians(a0 + 90 * k / (n - 1))
            pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a), z))
    return pts
tube(Bk, rounded_square(TOP_HALF - 0.14, BASKET_H + 0.05), 0.24, 8, LEATHER, closed=True)   # padded rim
tube(Bk, rounded_square(BOT_HALF + 0.02, 0.12), 0.14, 6, DARK, closed=True)                  # skid band
for (sx, sy) in ((1, 1), (-1, 1), (-1, -1), (1, -1)):   # sandbags on short ropes at the corners
    cx, cy = sx * (TOP_HALF + 0.35), sy * (TOP_HALF + 0.35)
    prof = [(0.0, 0.0), (0.22, 0.04), (0.33, 0.22), (0.35, 0.45), (0.28, 0.66), (0.12, 0.8), (0.07, 0.86), (0.11, 0.92), (0.0, 0.95)]
    lathe(Bk, prof, 10, LEATHER, centre=(cx, cy, BASKET_H - 1.7))
    tube(Bk, [(cx, cy, BASKET_H - 0.78), (sx * (TOP_HALF - 0.05), sy * (TOP_HALF - 0.05), BASKET_H)], 0.04, 4, TAN)
for k in range(3):                                       # a coiled rope on the side
    tube(Bk, [(TOP_HALF + 0.12 + 0.05 * k, 0.6 + 0.55 * math.cos(2 * math.pi * a / 16), 2.0 + 0.04 * k + 0.55 * math.sin(2 * math.pi * a / 16)) for a in range(16)], 0.09, 5, TAN, closed=True)
Bk.object("Basket", MAT)

# ---------------- the flame ----------------
Fl = Builder()
lathe(Fl, [(0.6 * (1 - t) ** 0.7 * (0.75 + 0.25 * math.sin(math.pi * t)), 5.6 * t) for t in np.linspace(0, 1, 11)], 12, (0, 0, 1, 1), centre=(0, 0, Z_FRAME + 1.25))
Fl.object("Flame", FLAME_MAT)

tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in bpy.context.scene.objects}
print("TRIS", tris)

# ---------------- export ----------------
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "balloon.fbx"), use_selection=False, path_mode="COPY", embed_textures=True,
                         apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "balloon.glb"), export_format="GLB")

# ---------------- preview renders ----------------
if RENDER:
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48
    try: sc.cycles.use_denoising = True
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = 640, 800
    sc.view_settings.view_transform = "Standard"           # true colours, as Roblox shows the texture
    world = bpy.data.worlds.new("Sky"); sc.world = world
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.75, 0.95, 1); world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.data.energy = 4.0; sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0)); g = bpy.context.object
    g.data.materials.append(material("Grass", colour=(0.22, 0.45, 0.16)))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(loc, look, lens, name):
        cam.location = loc
        d = np.array(look) - np.array(loc)
        cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)
        cam.data.lens = lens
        sc.render.filepath = os.path.join(OUT, name); bpy.ops.render.render(write_still=True)
    shot((52, -62, 14), (0, 0, 24), 42, "preview_full.png")
    shot((9, -10.5, 6.5), (0, 0, 5.5), 30, "preview_basket.png")
print("DONE", OUT)
