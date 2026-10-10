# Blender (bpy 5.2) script: a small set of cute low-poly flowers for the piazza fountain's garlands (1001 Squirrels,
# Oct 10 2026: the fountain dressed in pink, purple, yellow and red blooms like Shannon's reference). The flowers are
# cloned and scattered along the fountain rims by a Lua installer, so each one is tiny and cheap, and its petals and
# centre are separate objects so Roblox can tint the petals across a palette (untextured MeshParts take a Color).
# 1 Blender unit = 1 stud, Z up while building; the mesh origin of every piece is at the base of its calyx / stem so it
# sits on a surface. Exported Y up / -Z forward with the axis conversion baked into the mesh data (identity rotations).
# Objects (every flower well under 1500 triangles):
#   Flower_A_Petals / Flower_A_Centre   a five-petal daisy, petals slightly cupped, a round yellow centre
#   Flower_B_Petals / Flower_B_Centre   a rounder peony-like bloom, two layers of petals (8 outer, 6 inner)
#   Flower_C_Petals / Flower_C_Centre   a trumpet lily, six pointed recurved petals, yellow stamens
#   Leaf                                a single leaf with a slight curl and a short petiole
# and for the "frog resort" that floats on the water:
#   LilyPad                             a flat round pad 1.6 studs across with a pie-slice notch and a raised rim
#   Lotus_Petals / Lotus_Centre         a lotus bloom, two rings of pointed petals opening upward, a yellow seed pod
# The "_Petals" object also carries the small cup (calyx) under the bloom, in the petal colour, so each flower is only
# two objects. The pieces are laid out in a row along +X (2 studs apart) in the export so they do not overlap in Studio.
# Run: python make_flowers.py <out_dir> [--render] [--samples N] [--extra]   (writes flowers.fbx, flowers_preview.png;
#      --extra also renders top and underside check views)
import bpy, math, sys, os
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "."
RENDER = "--render" in sys.argv
EXTRA = "--extra" in sys.argv
SAMPLES = int(sys.argv[sys.argv.index("--samples") + 1]) if "--samples" in sys.argv else 64
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

# ---------------- materials: flat colours, no textures ----------------
def material(name, colour):
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = 0.65
    m.diffuse_color = (*colour, 1)
    return m
PINK = material("Petals_Pink", (0.95, 0.40, 0.62))
ROSE = material("Petals_Rose", (0.88, 0.16, 0.26))
PURPLE = material("Petals_Purple", (0.62, 0.34, 0.86))
YELLOW = material("Centre_Yellow", (1.0, 0.80, 0.15))
GREEN = material("Leaf_Green", (0.26, 0.60, 0.22))
PAD_GREEN = material("LilyPad_Green", (0.19, 0.47, 0.19))
BLUSH = material("Petals_Blush", (0.98, 0.58, 0.74))

# ---------------- mesh building ----------------
class Builder:
    """Vertices are merged by position so collapsed grid rows (petal tips, lathe apexes) become fans, not zero-area quads."""
    def __init__(self): self.v, self.f, self.key = [], [], {}
    def vert(self, p):
        k = tuple(round(float(c), 5) for c in p)
        i = self.key.get(k)
        if i is None:
            i = len(self.v); self.v.append(tuple(float(c) for c in p)); self.key[k] = i
        return i
    def face(self, idx):
        out = []
        for i in idx:
            if not out or out[-1] != i: out.append(i)
        if len(out) > 1 and out[0] == out[-1]: out.pop()
        if len(out) >= 3 and len(set(out)) == len(out): self.f.append(tuple(out))
    def grid(self, pts, flip=False, wrap=False):
        """pts[i][j]: rows i, columns j. Quads [a b c d] with a=(i,j), b=(i,j+1): normal = (b-a) x (c-b)."""
        ids = [[self.vert(p) for p in r] for r in pts]
        n, m = len(ids), len(ids[0])
        for i in range(n - 1):
            for j in range(m if wrap else m - 1):
                j2 = (j + 1) % m
                q = [ids[i][j], ids[i][j2], ids[i + 1][j2], ids[i + 1][j]]
                if flip: q.reverse()
                self.face(q)
    def object(self, name, mat, location=(0, 0, 0)):
        me = bpy.data.meshes.new(name)
        me.from_pydata(self.v, [], self.f)
        for p in me.polygons: p.use_smooth = True
        me.validate(); me.update()
        # a simple planar UV map (Roblox needs none for a flat colour, but importers like to see one)
        xs = [v[0] for v in self.v]; ys = [v[1] for v in self.v]
        x0, y0 = min(xs), min(ys); span = max(max(xs) - x0, max(ys) - y0, 1e-6)
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
                vx, vy, _ = me.vertices[me.loops[li].vertex_index].co
                uvl.data[li].uv = ((vx - x0) / span, (vy - y0) / span)
        me.materials.append(mat)
        ob = bpy.data.objects.new(name, me); ob.location = location
        bpy.context.scene.collection.objects.link(ob)
        return ob

def sheet(B, pts, thick):
    """A thin solid from an n x m grid of points: top faces (normal = rows x columns), bottom faces and a rim."""
    P = np.array(pts, float); n, m = P.shape[:2]
    N = np.zeros_like(P)
    for i in range(n):
        for j in range(m):
            du = P[i][min(j + 1, m - 1)] - P[i][max(j - 1, 0)]
            dv = P[min(i + 1, n - 1)][j] - P[max(i - 1, 0)][j]
            N[i][j] = np.cross(dv, du)
    for i in range(n):                                   # collapsed rows (a point) take the neighbouring row's normal
        if np.linalg.norm(N[i], axis=1).max() < 1e-9:
            for i2 in (i - 1, i + 1):
                if 0 <= i2 < n and np.linalg.norm(N[i2], axis=1).max() > 1e-9:
                    N[i][:] = N[i2].mean(axis=0); break
    L = np.linalg.norm(N, axis=2, keepdims=True); N = N / np.maximum(L, 1e-9)
    top = P + N * thick / 2; bot = P - N * thick / 2
    B.grid(top.tolist(), flip=True)
    B.grid(bot.tolist(), flip=False)
    loop = [(0, j) for j in range(m)] + [(i, m - 1) for i in range(1, n)] + [(n - 1, j) for j in range(m - 2, -1, -1)] + [(i, 0) for i in range(n - 2, 0, -1)]
    for k in range(len(loop)):
        (i1, j1), (i2, j2) = loop[k], loop[(k + 1) % len(loop)]
        B.face([B.vert(top[i1][j1]), B.vert(top[i2][j2]), B.vert(bot[i2][j2]), B.vert(bot[i1][j1])])

def lathe(B, profile, sides, centre=(0, 0, 0), flip=False):
    """profile: (r, z) pairs from the bottom up; outward normals when z increases along the profile."""
    cx, cy, cz = centre
    pts = [[(cx + r * math.cos(2 * math.pi * k / sides), cy + r * math.sin(2 * math.pi * k / sides), cz + z) for k in range(sides)] for (r, z) in profile]
    B.grid(pts, flip=flip, wrap=True)

def tube(B, path, radius, sides):
    path = [np.array(p, float) for p in path]
    rings = []
    for i, p in enumerate(path):
        t = path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]; t /= np.linalg.norm(t)
        a = np.array((1.0, 0, 0)) if abs(t[2]) > 0.9 else np.array((0, 0, 1.0))
        nrm = np.cross(t, a); nrm /= np.linalg.norm(nrm); b = np.cross(t, nrm)
        r = radius(i / max(1, len(path) - 1)) if callable(radius) else radius
        rings.append([p + r * (math.cos(2 * math.pi * k / sides) * nrm + math.sin(2 * math.pi * k / sides) * b) for k in range(sides)])
    B.grid(rings, wrap=True)

def petal(L, W, rows, cols, wfn, elev, curl, cup, r0, z0, yaw, keel=0.0):
    """A petal grid along its own +X: length L, width W * wfn(t), lifted by elev degrees at the base, the tip bending
    up by curl (negative = recurving down), the edges cupping up by cup, an optional keel (V-fold) along the middle.
    Placed with its base at radius r0, height z0, turned by yaw degrees."""
    e, y = math.radians(elev), math.radians(yaw)
    out = []
    for i in range(rows):
        t = i / (rows - 1)
        hw = 0.5 * W * wfn(t)
        row = []
        for j in range(cols):
            s = -1 + 2 * j / (cols - 1)
            x, yy = L * t, hw * s
            z = L * curl * t * t + cup * hw * s * s - keel * hw * (1 - abs(s))
            X = x * math.cos(e) - z * math.sin(e) + r0
            Z = x * math.sin(e) + z * math.cos(e) + z0
            row.append((X * math.cos(y) - yy * math.sin(y), X * math.sin(y) + yy * math.cos(y), Z))
        out.append(row)
    return out

def width(keys):
    ts, ws = zip(*keys)
    return lambda t: float(np.interp(t, ts, ws))

THICK = 0.025
def calyx(B, r_top, z_top, sides=10):
    """the small cup under a bloom, flat at z=0 so the flower sits on a surface"""
    lathe(B, [(0, 0), (0.5 * r_top, 0), (0.8 * r_top, 0.3 * z_top), (r_top, 0.7 * z_top), (0.92 * r_top, z_top), (0.0, z_top)], sides)

def dome(B, cx, cz, rx, rz, sides=12, rings=6):
    prof = [(rx * math.sin(ph), cz + rz * -math.cos(ph)) for ph in np.linspace(0, math.pi, rings + 1)]
    lathe(B, prof, sides, centre=(cx, 0, 0))

objects = []
def finish(B, name, mat, x):
    ob = B.object(name, mat, location=(x, 0, 0)); objects.append(ob); return ob

# ---------------- Flower_A: a five-petal daisy ----------------
XA = 0.0
A = Builder()
calyx(A, 0.2, 0.15)
wA = width([(0, 0.32), (0.25, 0.86), (0.5, 1.0), (0.75, 0.92), (1, 0.48)])
for k in range(5):
    sheet(A, petal(0.55, 0.38, 5, 4, wA, elev=16, curl=0.28, cup=0.45, r0=0.07, z0=0.15, yaw=90 + 72 * k), THICK)
finish(A, "Flower_A_Petals", PINK, XA)
Ac = Builder()
dome(Ac, 0, 0.25, 0.2, 0.11, sides=12, rings=6)       # a squashed yellow button
finish(Ac, "Flower_A_Centre", YELLOW, XA)

# ---------------- Flower_B: a rounder peony-like bloom, two layers ----------------
XB = 2.0
Bp = Builder()
calyx(Bp, 0.22, 0.15)
wB = width([(0, 0.4), (0.3, 0.92), (0.6, 1.0), (0.85, 0.9), (1, 0.55)])
for k in range(8):                                      # outer layer: broad bowl petals
    sheet(Bp, petal(0.52, 0.46, 5, 4, wB, elev=14, curl=0.5, cup=0.5, r0=0.06, z0=0.15, yaw=90 + 45 * k), THICK)
for k in range(6):                                      # inner layer: smaller, more upright, turned between the outer ones
    sheet(Bp, petal(0.42, 0.38, 5, 4, wB, elev=42, curl=0.5, cup=0.55, r0=0.04, z0=0.19, yaw=112 + 60 * k), THICK)
finish(Bp, "Flower_B_Petals", ROSE, XB)
Bc = Builder()
dome(Bc, 0, 0.36, 0.13, 0.1, sides=10, rings=5)
finish(Bc, "Flower_B_Centre", YELLOW, XB)

# ---------------- Flower_C: a trumpet lily ----------------
XC = 4.0
Cp = Builder()
TR, TZ = 0.22, 0.34                                     # trumpet rim radius / height
trumpet = [(0, 0), (0.11, 0), (0.13, 0.1), (0.16, 0.21), (TR, TZ)]
lathe(Cp, trumpet, 12)
lathe(Cp, [(r * 0.94, z + (0.02 if r == 0 else 0)) for (r, z) in trumpet], 12, flip=True)   # the inside of the trumpet
wC = width([(0, 0.62), (0.25, 1.0), (0.5, 0.9), (0.75, 0.6), (1, 0.0)])
for k in range(6):
    sheet(Cp, petal(0.43, 0.28, 5, 4, wC, elev=42, curl=-0.55, cup=0.12, r0=TR - 0.03, z0=TZ - 0.01, yaw=90 + 60 * k, keel=0.06), THICK)
finish(Cp, "Flower_C_Petals", PURPLE, XC)
Cc = Builder()
for k in range(6):                                      # stamens: thin filaments with a little anther on top
    a = math.radians(30 + 60 * k)
    top = (0.09 * math.cos(a), 0.09 * math.sin(a), 0.5)
    tube(Cc, [(0.0, 0.0, 0.14), (0.04 * math.cos(a), 0.04 * math.sin(a), 0.32), top], 0.016, 4)
    lathe(Cc, [(0, -0.035), (0.025, -0.02), (0.03, 0.01), (0.02, 0.035), (0, 0.04)], 5, centre=top)
tube(Cc, [(0, 0, 0.14), (0, 0, 0.54)], 0.02, 5)          # the pistil
lathe(Cc, [(0, -0.03), (0.035, 0), (0, 0.03)], 6, centre=(0, 0, 0.56))
finish(Cc, "Flower_C_Centre", YELLOW, XC)

# ---------------- Leaf: a single leaf with a slight curl ----------------
XL = 5.6
Lf = Builder()
wL = width([(0, 0.12), (0.2, 0.7), (0.45, 1.0), (0.7, 0.8), (0.9, 0.38), (1, 0.0)])
tube(Lf, [(0, 0, 0.03), (0.12, 0, 0.04)], 0.025, 4)
sheet(Lf, petal(0.85, 0.46, 7, 4, wL, elev=10, curl=0.35, cup=0.35, r0=0.1, z0=0.03, yaw=0, keel=0.05), 0.02)
finish(Lf, "Leaf", GREEN, XL)

# ---------------- LilyPad: a notched disc with a slightly raised rim, underside at z=0 ----------------
XP = 8.0
Pd = Builder()
NOTCH, PAD_R, PAD_T = 44.0, 0.8, 0.04
rim_lift = lambda r: 0.075 * max(0.0, (r - 0.5) / (PAD_R - 0.5)) ** 2
pad = []
for r in (0.0, 0.28, 0.5, 0.64, 0.74, PAD_R):
    row = []
    for j in range(25):
        a = math.radians(NOTCH / 2 + (360 - NOTCH) * j / 24)
        row.append((r * math.cos(a), r * math.sin(a), PAD_T / 2 + rim_lift(r)))
    pad.append(row)
sheet(Pd, pad, PAD_T)
finish(Pd, "LilyPad", PAD_GREEN, XP)

# ---------------- Lotus: two rings of pointed petals opening upward ----------------
XO = 10.0
Lo = Builder()
calyx(Lo, 0.2, 0.14)
wO = width([(0, 0.45), (0.3, 0.95), (0.5, 1.0), (0.75, 0.7), (1, 0.0)])
for k in range(8):                                      # outer ring
    sheet(Lo, petal(0.6, 0.38, 5, 4, wO, elev=24, curl=0.5, cup=0.5, r0=0.07, z0=0.13, yaw=90 + 45 * k), THICK)
for k in range(8):                                      # inner ring, steeper, between the outer petals
    sheet(Lo, petal(0.5, 0.34, 5, 4, wO, elev=52, curl=0.35, cup=0.5, r0=0.05, z0=0.16, yaw=112.5 + 45 * k), THICK)
finish(Lo, "Lotus_Petals", BLUSH, XO)
Oc = Builder()
lathe(Oc, [(0, 0.16), (0.09, 0.16), (0.11, 0.3), (0.13, 0.42), (0.11, 0.45), (0.06, 0.46), (0, 0.46)], 10)   # the seed pod
for k in range(5):                                      # seeds poking out of the top
    a = math.radians(72 * k)
    lathe(Oc, [(0, -0.015), (0.02, 0), (0, 0.025)], 5, centre=(0.07 * math.cos(a), 0.07 * math.sin(a), 0.46))
finish(Oc, "Lotus_Centre", YELLOW, XO)

# ---------------- report ----------------
def tri_count(ob): return sum(len(p.vertices) - 2 for p in ob.data.polygons)
print("PIECES")
for ob in objects:
    co = np.array([v.co[:] for v in ob.data.vertices])
    lo, hi = co.min(axis=0), co.max(axis=0)
    print("  %-18s tris %4d  verts %4d  size x %.2f y %.2f z %.2f  (z from %.2f)  mat %s  at x=%.1f" % (
        ob.name, tri_count(ob), len(ob.data.vertices), hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], lo[2], ob.data.materials[0].name, ob.location.x))
for base in ("Flower_A", "Flower_B", "Flower_C", "Lotus"):
    obs = [o for o in objects if o.name.startswith(base)]
    co = np.vstack([np.array([v.co[:] for v in o.data.vertices]) for o in obs])
    lo, hi = co.min(axis=0), co.max(axis=0)
    print("  %s total tris %d  across %.2f x %.2f  tall %.2f" % (base, sum(tri_count(o) for o in obs), hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]))

# ---------------- export (before the render-only props exist) ----------------
FBX = os.path.join(OUT, "flowers.fbx")
bpy.ops.export_scene.fbx(filepath=FBX, use_selection=False, object_types={"MESH"}, apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL",
                         axis_forward="-Z", axis_up="Y", bake_space_transform=True, mesh_smooth_type="FACE", use_mesh_modifiers=True,
                         use_triangles=False, add_leaf_bones=False, path_mode="AUTO", embed_textures=False)
print("WROTE", FBX)

# ---------------- preview render ----------------
if RENDER:
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = SAMPLES
    try: sc.cycles.use_denoising = True
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = 2000, 620
    sc.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Sky"); sc.world = world
    bg = world.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.75, 0.85, 0.98, 1); bg.inputs[1].default_value = 0.45
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.data.energy = 2.4; sun.data.angle = math.radians(8); sun.rotation_euler = (math.radians(42), math.radians(-18), math.radians(-25))
    bpy.ops.mesh.primitive_plane_add(size=60, location=(5, 0, 0)); ground = bpy.context.object
    ground.data.materials.append(material("Stone", (0.60, 0.58, 0.54)))
    # the model sheet: a tighter row than the export, every piece turned 30 degrees so a straight-on raised camera sees it 3/4
    sheet_x = {"Flower_A": 0.0, "Flower_B": 1.55, "Flower_C": 3.15, "Leaf": 4.55, "LilyPad": 6.45, "Lotus": 8.35}
    for ob in objects:
        base = ob.name.replace("_Petals", "").replace("_Centre", "")
        ob.location.x = sheet_x[base]; ob.rotation_euler.z = math.radians(30)
    for ob in objects:                                   # name tags under each piece
        if ob.name.endswith("_Centre"): continue
        cu = bpy.data.curves.new("tag", type="FONT"); cu.body = ob.name.replace("_Petals", ""); cu.size = 0.2; cu.align_x = "CENTER"
        tx = bpy.data.objects.new("tag", cu); sc.collection.objects.link(tx)
        tx.location = (ob.location.x + (0.35 if ob.name == "Leaf" else 0), -1.0 if ob.name == "LilyPad" else -0.8, 0.005)
        cu.materials.append(material("Ink", (0.15, 0.13, 0.12)))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 10.2
    def shot(look, offset, name, scale=10.2):
        look = np.array(look, float); loc = look + np.array(offset, float); d = look - loc
        cam.location = loc; cam.data.ortho_scale = scale
        cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)
        sc.render.filepath = os.path.join(OUT, name); bpy.ops.render.render(write_still=True)
        print("WROTE", sc.render.filepath)
    shot((4.15, 0.25, 0.25), (0.0, -5.0, 3.4), "flowers_preview.png")
    if EXTRA:                                            # check views: straight down, and from below with the ground gone
        shot((4.15, 0.0, 0.0), (0.0, -0.01, 6.0), "check_top.png")
        ground.hide_render = True
        shot((4.15, 0.0, 0.3), (0.0, -3.0, -4.0), "check_under.png")
print("DONE", OUT)
