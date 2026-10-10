# Blender (bpy 5.2) script: builds the cute low-poly frog for the Porto Nocciola piazza fountain's "frog resort" mode
# (Shannon, Oct 10 2026) plus its three holiday accessories, and exports them for Roblox. 1 Blender unit = 1 stud.
# Built Z up with the nose toward -Y, the project's canonical facing: with the FBX export settings below (copied from
# tools/balloon/blender/make_balloon.py) Import 3D leaves such a model facing -Z, its LookVector, exactly as it left
# the croc (forest/build_croc.lua: Studio X, Y, Z = Blender -X, Z, Y). The origin is the bottom centre of the frog
# (under the feet), so the model sits on the ground.
#
# The frog: a metaball blob (head, body, eye sockets, folded hind legs, front legs, webbed feet with toes) polygonised,
# smoothed and decimated to ~BODY_TRIS triangles, plus small shells for the smile, the pink cheeks and the back spots,
# all in ONE mesh "Body"; the eyes are separate meshes "EyeL" / "EyeR" (the frog's own left / right) with a black pupil
# cap and a white glint. Colours come from a 128 px palette atlas (flat swatches + a green-to-cream belly gradient) so
# every frog object has a single textured material and Roblox imports a Model holding one MeshPart per object.
# Accessories (separate objects placed on the frog): "Sunglasses" (one dark material), "SunHat" (straw + a pink band),
# "SwimRing" (white / coral stripes by face group). By default they use plain flat colour materials; with
# --atlas-accessories they use swatches of the same atlas instead (one material each, so Roblox cannot split them).
# Run: python make_frog.py <out_dir> [--render] [--atlas-accessories]
#   writes frog.fbx, frog.glb, frog_atlas.png and (with --render) frog_preview_front.png, frog_preview_side.png and
#   frog_preview_bare.png (the frog without its accessories).
import bpy, bmesh, math, sys, os
import numpy as np
from mathutils import Vector, Quaternion, Matrix
from mathutils.bvhtree import BVHTree

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
RENDER = "--render" in sys.argv
ATLAS_ACC = "--atlas-accessories" in sys.argv
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

LENGTH = 1.4            # studs, toes to rump; everything of the frog scales with it
RES = 0.022             # metaball polygonisation cell size (design units)
BODY_TRIS = 3400        # the blob is decimated to about this many triangles
THRESH = 0.6            # metaball threshold

# ---------------- the palette atlas (128 x 128, v = 0 at the bottom): row 0 a green->cream gradient, rows 1-3 swatches ----
def hexrgb(h): return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
def to_linear(c): return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)
PALETTE = {"green": "#5CC95C", "cream": "#F7F0CC", "dark": "#2B8F3A", "mouth": "#1D5226", "pink": "#FFA3B5",
           "black": "#141414", "white": "#FFFFFF", "shade": "#1A1A1A", "straw": "#E8C872", "band": "#FF8FB1",
           "ringwhite": "#F4F4F4", "coral": "#FF7A6B"}
COL = {k: hexrgb(v) for k, v in PALETTE.items()}
S, CELL = 128, 32
CELL_POS = {name: (i % 4, 1 + i // 4) for i, name in enumerate(PALETTE)}     # (column, row) of each swatch
img = np.zeros((S, S, 4), dtype=np.float32); img[..., 3] = 1; img[..., :3] = COL["green"]
uu = (np.arange(S) + 0.5) / S
grad = np.clip((uu - 0.08) / 0.84, 0, 1)                                      # flat green / cream at the ends
for k in range(3): img[:CELL, :, k] = COL["green"][k] + (COL["cream"][k] - COL["green"][k]) * grad[None, :]
for name, (c, r) in CELL_POS.items(): img[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL, :3] = COL[name]
atlas = bpy.data.images.new("frog_atlas", S, S, alpha=False)
atlas.pixels.foreach_set(img.ravel())
atlas.filepath_raw = os.path.join(OUT, "frog_atlas.png"); atlas.file_format = "PNG"; atlas.save()
atlas.pack()

def material(name, image=None, colour=None):
    m = bpy.data.materials.new(name)
    nt = m.node_tree; bsdf = nt.nodes.get("Principled BSDF")
    if image:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = image
        nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    if colour: bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = 0.6
    return m
ATLAS_MAT = material("FrogAtlas", image=atlas)
FLAT_NAMES = {"shade": "Shades", "straw": "Straw", "band": "HatBand", "ringwhite": "RingWhite", "coral": "RingCoral"}
FLAT = {}
def flat_mat(cell):
    # sRGB numbers on purpose: Studio takes the FBX diffuse colour as a Color3; the renders convert them to linear
    if cell not in FLAT: FLAT[cell] = material(FLAT_NAMES.get(cell, cell.title()), colour=COL[cell])
    return FLAT[cell]

def cell_uv(cell, n):
    c, r = CELL_POS[cell]; cu, cv = (c + 0.5) / 4, (r + 0.5) / 4
    return [(cu + 0.08 * math.cos(2 * math.pi * k / n), cv + 0.08 * math.sin(2 * math.pi * k / n)) for k in range(n)]
def grad_uv(t, p):                                                            # belly-ness t: 0 green .. 1 cream
    return (0.04 + 0.92 * t, 0.125 + 0.06 * math.sin(9 * p[0] + 5 * p[1] + 3 * p[2]))

# ---------------- mesh building ----------------
class Builder:
    def __init__(self): self.v, self.f, self.uv, self.cell = [], [], [], []
    def add_vert(self, p): self.v.append(tuple(p)); return len(self.v) - 1
    def face(self, idx, cell, uvs=None):
        idx = tuple(idx); self.f.append(idx); self.cell.append(cell)
        self.uv.append(uvs if uvs is not None else cell_uv(cell, len(idx)))
    def grid(self, rows, cell, wrap=False):
        """quads between consecutive rows of points (rows[i][j]); wrap closes each row round"""
        ids = [[self.add_vert(p) for p in r] for r in rows]
        m = len(rows[0]); cols = m if wrap else m - 1
        for i in range(len(rows) - 1):
            for j in range(cols):
                j2 = (j + 1) % m
                self.face((ids[i][j], ids[i + 1][j], ids[i + 1][j2], ids[i][j2]), cell)
        return ids
    def fan(self, centre, ring, cell, reverse=False):
        c = self.add_vert(centre); n = len(ring)
        for k in range(n):
            a, b = ring[k], ring[(k + 1) % n]
            self.face((c, b, a) if reverse else (c, a, b), cell)
    def object(self, name, flat=False):
        me = bpy.data.meshes.new(name); me.from_pydata(self.v, [], self.f)
        uvl = me.uv_layers.new(name="UVMap")
        for poly, uvs in zip(me.polygons, self.uv):
            for k in range(poly.loop_total): uvl.data[poly.loop_start + k].uv = uvs[k]
        if flat:
            cells = []
            for c in self.cell:
                if c not in cells: cells.append(c)
            for c in cells: me.materials.append(flat_mat(c))
            for poly, c in zip(me.polygons, self.cell): poly.material_index = cells.index(c)
        else: me.materials.append(ATLAS_MAT)
        for p in me.polygons: p.use_smooth = True
        me.validate(); me.update()
        bm = bmesh.new(); bm.from_mesh(me)                                    # consistent outward normals, shell by shell
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
        ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
        return ob

def frame_to(direction):
    """rotation taking local +Z to the direction"""
    return Vector((0, 0, 1)).rotation_difference(Vector(direction).normalized()).to_matrix()

def sphere(B, centre, radii, segs, polar, rot=None, cell="green", cell_fn=None):
    """UV sphere / ellipsoid, pole along local +Z (rotated by rot). polar: polar angles in degrees, 0 .. 180; band i
    lies between polar[i] and polar[i + 1] (band 0 and the last band are the pole fans); cell_fn(i) picks its swatch"""
    rot = rot or Matrix.Identity(3); c = Vector(centre); rx, ry, rz = radii
    band = (lambda i: cell_fn(i)) if cell_fn else (lambda i: cell)
    rows = []
    for a in polar[1:-1]:
        th = math.radians(a)
        rows.append([c + rot @ Vector((rx * math.sin(th) * math.cos(2 * math.pi * k / segs),
                                       ry * math.sin(th) * math.sin(2 * math.pi * k / segs), rz * math.cos(th))) for k in range(segs)])
    prev = [B.add_vert(p) for p in rows[0]]
    B.fan(c + rot @ Vector((0, 0, rz)), prev, band(0))
    for i in range(1, len(rows)):
        cur = [B.add_vert(p) for p in rows[i]]
        for k in range(segs):
            k2 = (k + 1) % segs
            B.face((prev[k], cur[k], cur[k2], prev[k2]), band(i))
        prev = cur
    B.fan(c + rot @ Vector((0, 0, -rz)), prev, band(len(rows)), reverse=True)

def tube(B, path, radius, sides, cell, caps=True):
    path = [Vector(p) for p in path]
    rows = []
    for i, p in enumerate(path):
        t = path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]
        rot = frame_to(t)
        r = radius(i / (len(path) - 1)) if callable(radius) else radius
        rows.append([p + rot @ Vector((r * math.cos(2 * math.pi * k / sides), r * math.sin(2 * math.pi * k / sides), 0)) for k in range(sides)])
    ids = B.grid(rows, cell, wrap=True)
    if caps: B.fan(path[0], ids[0], cell, reverse=True); B.fan(path[-1], ids[-1], cell)

def mesh_arrays(me):
    V = np.zeros(len(me.vertices) * 3); me.vertices.foreach_get("co", V)
    return V.reshape(-1, 3), [tuple(p.vertices) for p in me.polygons]

# ---------------- the frog blob: metaballs (design coordinates; nose toward -Y, Z up) ----------------
# visible radius of an element = K(stiffness) * element radius (surface where the summed field equals THRESH)
def K(s): return math.sqrt(1 - (THRESH / s) ** (1 / 3))
mb = bpy.data.metaballs.new("FrogBlob")
mb.resolution = RES; mb.render_resolution = RES; mb.threshold = THRESH
ELEMS = []                                                                    # own copies, to tell which element owns a vertex
def blob(co, semi, s, rot=None, tag="green"):
    if isinstance(semi, (int, float)): semi = (semi, semi, semi)
    el = mb.elements.new(); el.co = co; el.stiffness = s
    m = max(semi); el.radius = m / K(s)
    if semi[0] == semi[1] == semi[2]: el.type = "BALL"
    else: el.type = "ELLIPSOID"; el.size_x, el.size_y, el.size_z = semi[0] / m, semi[1] / m, semi[2] / m
    q = rot or Quaternion((1, 0, 0, 0)); el.rotation = q
    ELEMS.append(dict(co=np.array(co, float), R=el.radius, exp=np.array((semi[0] / m, semi[1] / m, semi[2] / m)), s=s,
                      imat=np.array(q.to_matrix().inverted()), half=0.0, tag=tag))
def capsule(a, b, r, s, tag="green"):
    a, b = Vector(a), Vector(b); d = b - a
    el = mb.elements.new(); el.type = "CAPSULE"; el.co = (a + b) / 2; el.stiffness = s
    el.radius = r / K(s); el.size_x = d.length / 2
    q = Vector((1, 0, 0)).rotation_difference(d); el.rotation = q
    ELEMS.append(dict(co=np.array((a + b) / 2), R=el.radius, exp=np.ones(3), s=s, imat=np.array(q.to_matrix().inverted()),
                      half=d.length / 2, tag=tag))
def density(P, e):
    d = (P - e["co"]) @ e["imat"].T
    if e["half"] > 0: d[:, 0] = np.sign(d[:, 0]) * np.maximum(np.abs(d[:, 0]) - e["half"], 0)
    d = d / e["exp"]
    q = 1 - (d ** 2).sum(1) / e["R"] ** 2
    return np.where(q > 0, e["s"] * q ** 3, 0.0)

S_BIG, S_MID, S_SMALL = 3.0, 6.0, 9.0
HEAD_C = (0, -0.26, 0.52)
blob(HEAD_C, (0.44, 0.40, 0.38), S_BIG, tag="belly")                         # the big round head
blob((0, 0.22, 0.42), (0.46, 0.50, 0.36), S_BIG, tag="belly")                # the squat body
TILT = Quaternion((1, 0, 0), math.radians(12))                               # front end of the thigh a little lower
EYE_D = {}                                                                    # design eye centres
for sx in (-1, 1):
    blob((sx * 0.25, -0.36, 0.81), 0.20, S_MID)                               # eye socket bulge
    EYE_D[sx] = Vector((sx * 0.26, -0.38, 0.83))
    blob((sx * 0.44, 0.24, 0.26), (0.18, 0.30, 0.23), S_MID, rot=TILT)        # folded hind leg
    blob((sx * 0.46, -0.18, 0.065), (0.12, 0.20, 0.065), S_SMALL)             # hind foot
    blob((sx * 0.46, -0.40, 0.03), (0.15, 0.09, 0.03), S_SMALL)               # its webbing
    for i in range(3):                                                        # three toes, fanned
        th = math.radians(sx * (i - 1) * 20); dirn = Vector((math.sin(th), -math.cos(th), 0))
        a = Vector((sx * 0.46 + sx * (i - 1) * 0.09, -0.33, 0.045))
        capsule(a, a + 0.13 * dirn, 0.045, S_SMALL)
    capsule((sx * 0.27, -0.44, 0.30), (sx * 0.31, -0.56, 0.10), 0.08, S_MID)   # short front leg
    blob((sx * 0.32, -0.54, 0.055), (0.10, 0.13, 0.055), S_SMALL)             # front foot
    blob((sx * 0.32, -0.64, 0.025), (0.12, 0.07, 0.025), S_SMALL)             # its webbing
    for i in range(3):
        th = math.radians(sx * (i - 1) * 22); dirn = Vector((math.sin(th), -math.cos(th), 0))
        a = Vector((sx * 0.32 + sx * (i - 1) * 0.07, -0.60, 0.04))
        capsule(a, a + 0.11 * dirn, 0.04, S_SMALL)

mob = bpy.data.objects.new("FrogBlob", mb); sc.collection.objects.link(mob)
dg = bpy.context.evaluated_depsgraph_get()
raw = bpy.data.meshes.new_from_object(mob.evaluated_get(dg)); raw.validate()
raw_tris = sum(len(p.vertices) - 2 for p in raw.polygons)
tob = bpy.data.objects.new("FrogRaw", raw); sc.collection.objects.link(tob)
smo = tob.modifiers.new("smooth", "SMOOTH"); smo.factor = 0.5; smo.iterations = 2
dec = tob.modifiers.new("decimate", "DECIMATE"); dec.ratio = min(1.0, BODY_TRIS / raw_tris); dec.use_collapse_triangulate = True
dg = bpy.context.evaluated_depsgraph_get()
blobme = bpy.data.meshes.new_from_object(tob.evaluated_get(dg))
V, F = mesh_arrays(blobme)
print("BLOB raw tris", raw_tris, "-> decimated tris", sum(len(f) - 2 for f in F))
for o in (tob, mob): bpy.data.objects.remove(o)
bpy.data.meshes.remove(raw); bpy.data.metaballs.remove(mb)

# ---------------- the Body mesh: blob (belly gradient) + smile + cheeks + spots ----------------
owner = np.stack([density(V, e) for e in ELEMS], 1).argmax(1)
belly_ok = np.array([ELEMS[i]["tag"] == "belly" for i in owner])
zline = np.interp(V[:, 1], [-0.70, -0.45, -0.20, 0.30, 0.75], [0.40, 0.36, 0.30, 0.25, 0.20])   # cream below this line
t = np.clip((zline - V[:, 2]) / 0.10 + 0.5, 0, 1); t = t * t * (3 - 2 * t); t[~belly_ok] = 0
B = Builder()
for p in V: B.add_vert(p)
for f in F: B.face(f, "green", [grad_uv(t[i], V[i]) for i in f])
bvh = BVHTree.FromPolygons([tuple(p) for p in V], F, all_triangles=all(len(f) == 3 for f in F))
def surface(origin, direction):
    loc, nrm, idx, dist = bvh.ray_cast(Vector(origin), Vector(direction).normalized(), 5.0)
    return loc, nrm
def head_dir(ph, el): return Vector((math.sin(ph) * math.cos(el), -math.cos(ph) * math.cos(el), math.sin(el)))
HC = Vector((0, -0.26, 0.50))
path = []
for s_ in (float(q) for q in np.linspace(-1, 1, 25)):                                           # the wide smile, corners turned up
    loc, nrm = surface(HC, head_dir(s_ * math.radians(62), -0.10 + 0.22 * s_ * s_))
    sink = 0.004 + 0.014 * max(0.0, abs(s_) - 0.85) / 0.15
    path.append(loc - sink * nrm)
tube(B, path, 0.016, 6, "mouth")
for sx in (-1, 1):                                                            # pink cheeks beside the mouth corners
    loc, nrm = surface(HC, head_dir(sx * math.radians(72), 0.17))
    sphere(B, loc - 0.012 * nrm, (0.062, 0.062, 0.026), 10, [0, 45, 90, 135, 180], rot=frame_to(nrm), cell="pink")
SPOTS = [(0.0, 0.12, 0.085), (0.24, 0.34, 0.07), (-0.22, 0.44, 0.075), (0.18, -0.03, 0.06), (-0.18, 0.04, 0.065),
         (0.08, 0.60, 0.05), (-0.34, 0.24, 0.055), (0.0, -0.14, 0.055), (0.52, 0.30, 0.055), (-0.50, 0.17, 0.05)]
for (x, y, r) in SPOTS:                                                       # darker spots on the back and thighs
    loc, nrm = surface((x, y, 2.0), (0, 0, -1))
    sphere(B, loc - 0.1 * r * nrm, (r, r, 0.3 * r), 8, [0, 45, 90, 135, 180], rot=frame_to(nrm), cell="dark")
body = B.object("Body")

# ---------------- the eyes ----------------
EYE_R = 0.20
def eye(name, sx):
    E = Builder(); c = EYE_D[sx]
    d = Vector((sx * 0.30, -0.85, 0.35)).normalized()                         # gaze: forward, a little up and out
    rot = frame_to(d)
    polar = [0, 11, 22, 33, 45, 60, 75, 90, 105, 120, 140, 160, 180]          # the pupil cap ends exactly at 33 degrees
    sphere(E, c, (EYE_R,) * 3, 20, polar, rot=rot, cell_fn=lambda i: "black" if polar[i + 1] <= 33 else "white")
    up = Vector((0, 0, 1)); upl = (up - up.dot(d) * d).normalized()
    out = Vector((sx, 0, 0)); outl = (out - out.dot(d) * d).normalized()
    g = (d * math.cos(math.radians(15)) + (0.85 * upl + 0.40 * outl).normalized() * math.sin(math.radians(15))).normalized()
    sphere(E, c + g * (EYE_R - 0.012), (0.038,) * 3, 8, [0, 45, 90, 135, 180], cell="white")   # the glint
    return E.object(name)
eyeL, eyeR = eye("EyeL", 1), eye("EyeR", -1)                                  # the frog faces -Y, so its left is +X

# ---------------- normalise: LENGTH studs long, origin at the bottom centre ----------------
def verts_of(objs): return np.concatenate([mesh_arrays(o.data)[0] for o in objs])
FROG = [body, eyeL, eyeR]
lo, hi = verts_of(FROG).min(0), verts_of(FROG).max(0)
SCALE = LENGTH / (hi[1] - lo[1])
M = Matrix.Translation((-(lo[0] + hi[0]) / 2 * SCALE, -(lo[1] + hi[1]) / 2 * SCALE, -lo[2] * SCALE)) @ Matrix.Scale(SCALE, 4)
for o in FROG: o.data.transform(M); o.data.update()
EYE_C = {sx: M @ EYE_D[sx] for sx in (-1, 1)}; EYE_R *= SCALE
Vb, Fb = mesh_arrays(body.data)
bvh = BVHTree.FromPolygons([tuple(p) for p in Vb], Fb, all_triangles=all(len(f) == 3 for f in Fb))

# ---------------- accessories (final coordinates, placed on the frog) ----------------
FLAT_ACC = not ATLAS_ACC
# Sunglasses: two chunky cat-eye lenses on a common plane just in front of the eyes, a bridge and short arms
G = Builder()
fwd = Vector((0, -0.92, 0.39)).normalized(); xh = Vector((1, 0, 0)); uph = fwd.cross(xh)   # in-plane right and up
LR, LTH = 0.205, 0.045
lens_c = {}
for sx in (-1, 1):
    C = EYE_C[sx] + fwd * (EYE_R + 0.035); lens_c[sx] = C
    th0 = math.radians(45 if sx > 0 else 135)                                 # the upswept outer corner
    outline = []
    for k in range(28):
        th = 2 * math.pi * k / 28; dd = (th - th0 + math.pi) % (2 * math.pi) - math.pi
        r = LR + 0.07 * math.exp(-(dd / 0.5) ** 2)
        outline.append(C + r * (math.cos(th) * xh + math.sin(th) * uph))
    ids = G.grid([[p - fwd * LTH / 2 for p in outline], [p + fwd * LTH / 2 for p in outline]], "shade", wrap=True)
    G.fan(C + fwd * LTH / 2, ids[1], "shade"); G.fan(C - fwd * LTH / 2, ids[0], "shade", reverse=True)
tube(G, [lens_c[-1] + xh * (LR - 0.03), lens_c[1] - xh * (LR - 0.03)], 0.03, 8, "shade")           # bridge
for sx in (-1, 1):
    start = lens_c[sx] + xh * sx * (LR - 0.01)
    tube(G, [start, start + Vector((sx * 0.06, 0.46, -0.10))], 0.024, 8, "shade")                   # arm
glasses = G.object("Sunglasses", flat=FLAT_ACC)

# SunHat: a straw lathe (domed crown, wide rippled brim, closed underneath) with a pink band, perched behind the eyes,
# tipped back 17 degrees so the brim clears the eyes and a touch sideways
H = Builder()
HAT_ROT = Matrix.Rotation(math.radians(-22), 3, "X") @ Matrix.Rotation(math.radians(6), 3, "Y")
PROFILE = [(0.13, 0.25), (0.25, 0.22), (0.33, 0.155), (0.36, 0.08), (0.365, 0.0), (0.39, 0.0), (0.54, -0.02), (0.66, -0.05),
           (0.74, -0.07), (0.755, -0.08), (0.74, -0.09), (0.66, -0.07), (0.54, -0.04), (0.39, -0.02)]
HSEG = 24
HAT_C = Vector((0, 0.06, 0.86))
nrm_hat = HAT_ROT @ Vector((0, 0, 1))
def brim_clearance(sx): return -(EYE_C[sx] - (HAT_C + HAT_ROT @ Vector((0, 0, -0.02)))).dot(nrm_hat) - EYE_R
while min(brim_clearance(-1), brim_clearance(1)) < 0.03: HAT_C.z += 0.005   # perch it just clear of both eyes
def hat_pt(r, z, k):
    th = 2 * math.pi * k / HSEG
    ripple = 0.014 * math.sin(5 * th) * max(0.0, (r - 0.39) / 0.365)
    return HAT_C + HAT_ROT @ Vector((r * math.cos(th), r * math.sin(th), z + ripple))
rows = [[hat_pt(r, z, k) for k in range(HSEG)] for (r, z) in PROFILE]
ids = H.grid(rows, "straw", wrap=True)
H.fan(HAT_C + HAT_ROT @ Vector((0, 0, 0.255)), ids[0], "straw")
H.fan(HAT_C + HAT_ROT @ Vector((0, 0, -0.02)), ids[-1], "straw", reverse=True)
band_prof = [(0.345, 0.012), (0.381, 0.012), (0.381, 0.07), (0.345, 0.07), (0.345, 0.012)]
H.grid([[HAT_C + HAT_ROT @ Vector((r * math.cos(2 * math.pi * k / HSEG), r * math.sin(2 * math.pi * k / HSEG), z)) for k in range(HSEG)]
        for (r, z) in band_prof], "band", wrap=True)
hat = H.object("SunHat", flat=FLAT_ACC)

# SwimRing: a torus 1.6 across (tube 0.35) lying flat round the frog's middle, 12 stripes white / coral
W = Builder()
R_MAJ, R_MIN, NMAJ, NMIN, STRIPES = 0.625, 0.175, 36, 12, 12
RING_C = Vector((0, 0.24, 0.29))
ring_ids = []
for j in range(NMAJ):
    ph = 2 * math.pi * j / NMAJ
    ring_ids.append([W.add_vert(RING_C + Vector(((R_MAJ + R_MIN * math.cos(th)) * math.cos(ph), (R_MAJ + R_MIN * math.cos(th)) * math.sin(ph),
                                                 R_MIN * math.sin(th)))) for th in (2 * math.pi * k / NMIN for k in range(NMIN))])
for j in range(NMAJ):
    j2 = (j + 1) % NMAJ; cell = "ringwhite" if (j * STRIPES // NMAJ) % 2 == 0 else "coral"
    for k in range(NMIN):
        k2 = (k + 1) % NMIN
        W.face((ring_ids[j][k], ring_ids[j2][k], ring_ids[j2][k2], ring_ids[j][k2]), cell)
ring = W.object("SwimRing", flat=FLAT_ACC)
ACC = [glasses, hat, ring]

# ---------------- report ----------------
def report(o):
    Vo, Fo = mesh_arrays(o.data); lo, hi = Vo.min(0), Vo.max(0)
    tris = sum(len(f) - 2 for f in Fo)
    # Studio axes as Import 3D maps them for this pipeline (croc precedent): X = -Blender x, Y = Blender z, Z = Blender y
    # share of faces whose normal points away from the object's centre (a crude outward check; the body is not convex)
    n = np.zeros(len(o.data.polygons) * 3); o.data.polygons.foreach_get("normal", n); n = n.reshape(-1, 3)
    cen = np.zeros(len(o.data.polygons) * 3); o.data.polygons.foreach_get("center", cen); cen = cen.reshape(-1, 3)
    outward = float(((cen - (lo + hi) / 2) * n).sum(1).__gt__(0).mean())
    size = hi - lo; c = (lo + hi) / 2
    print(f"OBJ {o.name}: tris {tris}, verts {len(Vo)}, mats {[m.name for m in o.data.materials]}, "
          f"size Blender xyz {size[0]:.3f} x {size[1]:.3f} x {size[2]:.3f} (Roblox X {size[0]:.3f} Y {size[2]:.3f} Z {size[1]:.3f}), "
          f"bbox centre Roblox (X {-c[0]:.3f}, Y {c[2]:.3f}, Z {c[1]:.3f}) from the origin, outward-normals {outward:.2f}")
    return tris
total = sum(report(o) for o in FROG + ACC)
lo, hi = verts_of(FROG).min(0), verts_of(FROG).max(0)
print(f"FROG total tris {sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in FROG)}, all objects {total}; "
      f"frog size: long {hi[1] - lo[1]:.3f} tall {hi[2] - lo[2]:.3f} wide {hi[0] - lo[0]:.3f} studs; eye tops z {hi[2]:.3f}")
# the hat brim must clear the eyes: signed gap between each eye sphere and the brim's underside plane
for sx in (-1, 1): print(f"CHECK eye {sx:+d} clears the hat brim's underside by {brim_clearance(sx):.3f} studs")

# ---------------- export (settings copied from make_balloon.py) ----------------
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "frog.fbx"), use_selection=False, path_mode="COPY", embed_textures=True,
                         apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "frog.glb"), export_format="GLB")

# ---------------- preview renders (Cycles CPU; EEVEE needs a GPU context this venv has not got) ----------------
if RENDER:
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 64
    try: sc.cycles.use_denoising = True
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = 900, 900
    sc.view_settings.view_transform = "Standard"                             # true colours, as Studio shows the texture
    for m in FLAT.values():                                                   # flat materials hold sRGB numbers for Studio
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*to_linear(m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value[:3]), 1)
    for m in [ATLAS_MAT] + list(FLAT.values()):                              # back faces glow red: a winding check
        nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]; geo = nt.nodes.new("ShaderNodeNewGeometry")
        bsdf.inputs["Emission Color"].default_value = (1, 0, 0, 1)
        nt.links.new(geo.outputs["Backfacing"], bsdf.inputs["Emission Strength"])
    world = bpy.data.worlds.new("Sky"); sc.world = world
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.78, 0.95, 1); world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.data.energy = 3.5; sun.data.angle = math.radians(8)
    sun.rotation_euler = (math.radians(48), math.radians(-12), math.radians(-30))
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0)); ground = bpy.context.object
    ground.data.materials.append(material("Ground", colour=(0.52, 0.50, 0.44)))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(loc, look, lens, name):
        cam.location = loc; cam.data.lens = lens
        cam.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, name); bpy.ops.render.render(write_still=True)
    shot((1.55, -2.05, 1.25), (0, -0.05, 0.50), 50, "frog_preview_front.png")
    shot((3.3, 0.15, 0.75), (0, 0.05, 0.50), 70, "frog_preview_side.png")
    for o in ACC: o.hide_render = True
    shot((1.55, -2.05, 1.25), (0, -0.05, 0.50), 50, "frog_preview_bare.png")
print("DONE", OUT)
