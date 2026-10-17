"""Bamboo maze kit (runner 7, Oct 17 2026). Shannon: "a proper bamboo forest maze ... the bamboo needs to be close enough together so
that it makes solid walls, so you can't see through them, with twists and turns, some wrong turns, and one entrance and one exit, like
a corn maze". Earlier (Oct 16): one Blender bamboo-hedge mesh replaces the 102 part-built clumps; a new layout each day.
Pieces (1 = 1 stud; Blender X along the wall, Blender -Y = Roblox Z across it, Blender Z = Roblox Y up; base at 0):
  bamboo_wall_A/B/C  one wall SLOT: 12 long (the 9-stud cell pitch + 1.5 over each node, so walls meeting at a node close the corner),
                     a solid dark core (Bamboo_Core, x +-5.85, y -0.3..21.5, z +-1.15 - the only collider: nothing shows through and
                     nobody walks into the culms), dense culms on both faces half sunk into it plus a few standing proud (Bamboo_Culm,
                     textured: 4 greens with node rings), culms across both ends (a wall stub ends in bamboo, not a slab), and leaf blades
                     (Bamboo_LeafL / Bamboo_LeafD: tufts at the culm tops 17..27 and a few sprays lower down; DoubleSided in Studio).
                     Three variants (seeds) so neighbouring walls differ.
  maze_gate          an entrance / exit frame across a 6-wide opening: two thick posts, two cross bars (Gate_Culm, textured), a
                     hanging board (Gate_Board; the installer writes the words on it with a SurfaceGui), lashings (Gate_Rope).
The culm texture (out_bamboo/bamboo_culm.png, 256 x 1024: 4 columns of greens, 32 studs tall, a node every 6 studs) is embedded in the
kit FBX (Import 3D uploads it; opaque, so MeshPart.TextureID is fine). No vertex colours.
Writes out_bamboo/japan_kit14_bamboo_maze.fbx (Empties bamboo_wall_A/B/C, maze_gate), pieces.json, gen_log.txt, prev_bamboo_*.png.
Run: blender -b --python gen_bamboo.py"""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_bamboo")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"Bamboo_Core": (0.15, 0.20, 0.11), "Bamboo_LeafL": (0.42, 0.62, 0.24), "Bamboo_LeafD": (0.25, 0.44, 0.16),
       "Gate_Board": (0.55, 0.38, 0.22), "Gate_Rope": (0.80, 0.72, 0.52)}
HALF, THICK, CORE_TOP = 5.85, 1.15, 21.5
TEX_H = 32.0                                  # studs the culm texture spans top to bottom
# ---------- the culm texture ----------
def make_texture():
    W, H = 256, 1024
    img = bpy.data.images.new("bamboo_culm", W, H, alpha=False)
    greens = [(0.47, 0.64, 0.27), (0.36, 0.53, 0.22), (0.58, 0.68, 0.30), (0.42, 0.55, 0.30)]   # fresh, deep, yellow-green, olive
    px = [0.0] * (W * H * 4)
    rnd = random.Random(7)
    stripes = [rnd.uniform(-0.04, 0.04) for _ in range(W)]
    for y in range(H):
        studs = y / H * TEX_H
        d = (studs % 6.0)                      # distance above the last node
        for x in range(W):
            col = greens[x * 4 // W]
            u = (x % (W // 4)) / (W // 4)
            shade = 0.82 + 0.30 * math.sin(math.pi * u)          # rounder in the middle of each culm band
            k = shade + stripes[x]
            if d < 0.10 or d > 5.93: k *= 0.55                      # the dark line of the node
            elif d < 0.45: k *= 1.18                                # the pale ring just above it
            elif d > 5.6: k *= 0.92
            i = (y * W + x) * 4
            px[i] = lin(min(1, col[0] * k)); px[i + 1] = lin(min(1, col[1] * k)); px[i + 2] = lin(min(1, col[2] * k)); px[i + 3] = 1.0
    img.pixels = px
    path = os.path.join(OUT, "bamboo_culm.png")
    img.filepath_raw = path; img.file_format = "PNG"; img.save()
    return img
def material(key, img=None):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    bs = m.node_tree.nodes["Principled BSDF"]; bs.inputs["Roughness"].default_value = 0.8
    if img is not None:
        t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img
        m.node_tree.links.new(t.outputs["Color"], bs.inputs["Base Color"])
        m.diffuse_color = (0.4, 0.55, 0.25, 1)
    else:
        c = COL[key]; bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def to_obj(name, key, bm, uv_done=True, img=None):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0002)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(key, img))
    for p in me.polygons: p.use_smooth = key in ("Bamboo_Culm", "Gate_Culm")
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
# ---------- geometry helpers ----------
def culm(bm, uv, base, top, r0, col, voff, sides=6):
    """a tapering 6-sided culm from base to top (Vectors); UVs: u inside the texture column col (0..3), v = (height + voff) / TEX_H"""
    axis = (top - base); L = axis.length; a = axis.normalized()
    t1 = a.orthogonal().normalized(); t2 = a.cross(t1).normalized()
    rings = []
    for (z, r) in ((0.0, r0), (L, r0 * 0.82)):
        ring = []
        for k in range(sides + 1):
            ang = 2 * math.pi * k / sides
            p = base + a * z + (t1 * math.cos(ang) + t2 * math.sin(ang)) * r
            ring.append((bm.verts.new(p) if k < sides else None, k))
        rings.append(ring)
    for k in range(sides):
        v00, v01 = rings[0][k][0], rings[0][(k + 1) % sides][0]
        v10, v11 = rings[1][k][0], rings[1][(k + 1) % sides][0]
        f = bm.faces.new((v00, v01, v11, v10))
        u0 = (col + 0.06 + 0.88 * k / sides) / 4; u1 = (col + 0.06 + 0.88 * (k + 1) / sides) / 4
        vb = (voff) / TEX_H; vt = (voff + L) / TEX_H
        for l, (u, v) in zip(f.loops, ((u0, vb), (u1, vb), (u1, vt), (u0, vt))): l[uv].uv = (u, v)
def blade(bm, root, direction, length, width):
    """a leaf blade: root -> tip along direction (drooping), a diamond 2 tris, flat across its own side vector"""
    d = direction.normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 1e-4: side = Vector((1, 0, 0))
    side = side.normalized() * (width / 2)
    mid = root + d * (length * 0.38)
    tip = root + d * length + Vector((0, 0, -0.18 * length))
    vs = [bm.verts.new(root), bm.verts.new(mid + side), bm.verts.new(tip), bm.verts.new(mid - side)]
    bm.faces.new(vs)
def box(bm, x0, x1, y0, y1, z0, z1):
    vs = [bm.verts.new((x, y, z)) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
    def v(i, j, k): return vs[i * 4 + j * 2 + k]
    for f in ((v(0,0,0), v(0,1,0), v(0,1,1), v(0,0,1)), (v(1,0,0), v(1,0,1), v(1,1,1), v(1,1,0)), (v(0,0,0), v(0,0,1), v(1,0,1), v(1,0,0)),
              (v(0,1,0), v(1,1,0), v(1,1,1), v(0,1,1)), (v(0,0,0), v(1,0,0), v(1,1,0), v(0,1,0)), (v(0,0,1), v(0,1,1), v(1,1,1), v(1,0,1))):
        bm.faces.new(f)
# ---------- one wall slot ----------
def build_wall(tag, seed, img):
    rnd = random.Random(seed)
    objs = []
    bm = bmesh.new(); box(bm, -HALF, HALF, -THICK, THICK, -0.3, CORE_TOP); objs.append(to_obj(f"Bamboo_Core_{tag}", "Bamboo_Core", bm))
    bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")
    tops = []
    def add(x, y, r, h, lean=0.03):
        base = Vector((x, y, -0.3)); top = Vector((x + rnd.uniform(-lean, lean) * h, y + rnd.uniform(-lean, lean) * h * 0.5, h))
        culm(bm, uv, base, top, r, rnd.randrange(4), rnd.uniform(0, TEX_H - h - 0.5))
        tops.append((top, y))
    for side in (1, -1):
        x = -HALF + rnd.uniform(0, 0.4)
        while x < HALF:                                     # the sunk row: centres 0.15 inside the core face, touching or nearly
            r = rnd.uniform(0.26, 0.38)
            add(x, side * (THICK + 0.05 - 0.15), r, rnd.uniform(22.0, 26.5))
            x += 2 * r + rnd.uniform(0.02, 0.22)
        x = -HALF + rnd.uniform(0.3, 1.5)
        while x < HALF - 0.3:                               # a few culms standing proud, for depth
            r = rnd.uniform(0.24, 0.34)
            add(x, side * (THICK + 0.42 + rnd.uniform(0, 0.12)), r, rnd.uniform(21.0, 26.0), 0.04)
            x += rnd.uniform(1.6, 3.2)
    for end in (1, -1):                                     # across both ends: a wall stub finishes in bamboo
        for y in (-0.75, 0.0, 0.75):
            add(end * (HALF - 0.05) + rnd.uniform(-0.05, 0.05), y + rnd.uniform(-0.08, 0.08), rnd.uniform(0.3, 0.38), rnd.uniform(22.0, 26.0))
    objs.append(to_obj(f"Bamboo_Culm_{tag}", "Bamboo_Culm", bm, img=img))
    leaves = {"Bamboo_LeafL": bmesh.new(), "Bamboo_LeafD": bmesh.new()}
    for (top, y) in tops:                                   # a tuft at every top
        for _ in range(rnd.randint(5, 8)):
            out = 1 if y > 0.2 else (-1 if y < -0.2 else rnd.choice((1, -1)))      # mostly away from the wall's middle
            h = Vector((rnd.uniform(-0.9, 0.9), out * rnd.uniform(0.25, 1.0), 0)).normalized()
            d = Vector((h.x, h.y, rnd.uniform(-0.55, 0.15)))
            root = top + Vector((0, 0, -rnd.uniform(0.0, 2.5)))
            blade(leaves[rnd.choice(("Bamboo_LeafL", "Bamboo_LeafD"))], root, d, rnd.uniform(1.4, 2.3), rnd.uniform(0.28, 0.4))
    for _ in range(46):                                     # sprays lower down on both faces
        x = rnd.uniform(-HALF + 0.3, HALF - 0.3); side = rnd.choice((1, -1)); z = rnd.uniform(9.0, 19.0)
        root = Vector((x, -side * (THICK + 0.3), z))
        for _ in range(rnd.randint(3, 5)):
            yaw = rnd.uniform(-0.9, 0.9) + (-math.pi / 2 if side > 0 else math.pi / 2)
            d = Vector((math.cos(yaw), math.sin(yaw), rnd.uniform(-0.6, 0.0)))
            blade(leaves[rnd.choice(("Bamboo_LeafL", "Bamboo_LeafD"))], root, d, rnd.uniform(1.0, 1.6), rnd.uniform(0.22, 0.32))
    for key, b in leaves.items(): objs.append(to_obj(f"{key}_{tag}", key, b))
    return objs
# ---------- the gate ----------
def build_gate(img):
    rnd = random.Random(31)
    objs = []
    bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")
    for x in (-3.25, 3.25):                                 # posts just inside the 6.5 between the wall ends' culms
        culm(bm, uv, Vector((x, 0, -0.3)), Vector((x, 0, 11.6)), 0.5, 1, 2.0)
    culm(bm, uv, Vector((-4.3, 0, 10.6)), Vector((4.3, 0, 10.75)), 0.34, 2, 1.0)
    culm(bm, uv, Vector((-3.9, 0, 9.5)), Vector((3.9, 0, 9.5)), 0.26, 0, 3.0)
    objs.append(to_obj("Gate_Culm", "Gate_Culm", bm, img=img))
    bm = bmesh.new(); box(bm, -2.4, 2.4, -0.12, 0.12, 7.3, 8.9); objs.append(to_obj("Gate_Board", "Gate_Board", bm))
    bm = bmesh.new()
    for x in (-1.9, 1.9): box(bm, x - 0.05, x + 0.05, -0.05, 0.05, 8.9, 9.5)
    for x in (-3.25, 3.25):
        for z in (9.5, 10.68): box(bm, x - 0.56, x + 0.56, -0.56, 0.56, z - 0.12, z + 0.12)
    objs.append(to_obj("Gate_Rope", "Gate_Rope", bm))
    return objs
def export(objs, path, embed=False):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    kw = dict(path_mode="COPY", embed_textures=True) if embed else {}
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"}, **kw)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    img = make_texture()
    pieces = {}
    for tag, seed in (("A", 101), ("B", 202), ("C", 303)): pieces["bamboo_wall_" + tag] = build_wall(tag, seed, img)
    pieces["maze_gate"] = build_gate(img)
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
                      "tris": {o.name: tris(o) for o in objs}}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({k: {"min": v["min"], "max": v["max"]} for k, v in info.items()}))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 20.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit14_bamboo_maze.fbx"), embed=True)
    log(f"kit: {os.path.getsize(os.path.join(OUT, 'japan_kit14_bamboo_maze.fbx'))} bytes")
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
