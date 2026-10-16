"""Japan garden pieces, batch 1 (job 125, Oct 16 2026). Shannon: the elements of her reference pictures, "on same par with the italy
and france maps" (low-poly, faceted, clean colours - like the Rue de Noisette trees), and "do not build anything from roblox parts" ...
"if you build it has to be in blender". Eight pieces, each its own FBX, every mesh object named for its colour in Studio:
  torii.fbx         Torii_Red, Torii_Black, Torii_Plaque
  lantern.fbx       Lantern_Stone, Lantern_Paper (Neon + a small light in Studio)
  bridge.fbx        Bridge_Red, Bridge_Deck, Bridge_Gold, Bridge_Stone - a taiko bridge, 40 long (x -20..20), 8 wide, deck 0 at the
                    ends and +5.5 at the crown; placed at y 0.3 it clears the bank tops (2.1) and crowns at ~6.1 as today
  maple_a.fbx / maple_b.fbx   Maple_Bark, Maple_Red, Maple_Orange, Maple_Gold - faceted autumn clusters on a curved trunk
  pine.fbx          Pine_Bark, Pine_Needles - a leaning twisted pine with flat cloud pads
  rocks.fbx         Rock1..3_Grey + Rock1..3_Moss (a mossy top band)
  slabs.fbx         Slab1..3 - irregular stepping slabs
  waterfall.fbx     Fall_Rock, Fall_Moss, Fall_Water (a curved falling sheet), Fall_Foam
Units: 1 Blender unit = 1 stud, Z up, front = -Y (exported -Z forward / Y up, as the Porto lifeguard props). Triangle counts and sizes
go to gen_log.txt; previews (Workbench, flat colours) prev_*.png. Run: blender -b --python gen_garden1.py   (or a bpy module)."""
import bpy, bmesh, math, os, random, traceback, sys
from mathutils import Vector, Matrix, noise
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out1")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)

COL = {  # sRGB 0..1 - the installer uses the same values in Studio
    "Torii_Red": (0.80, 0.20, 0.13), "Torii_Black": (0.13, 0.12, 0.12), "Torii_Plaque": (0.20, 0.16, 0.14),
    "Lantern_Stone": (0.62, 0.62, 0.60), "Lantern_Paper": (1.00, 0.88, 0.62),
    "Bridge_Red": (0.82, 0.18, 0.12), "Bridge_Deck": (0.55, 0.38, 0.24), "Bridge_Gold": (0.93, 0.74, 0.30), "Bridge_Stone": (0.58, 0.57, 0.55),
    "Maple_Bark": (0.36, 0.25, 0.19), "Maple_Red": (0.86, 0.24, 0.16), "Maple_Orange": (0.95, 0.52, 0.18), "Maple_Gold": (0.98, 0.74, 0.28),
    "Pine_Bark": (0.30, 0.22, 0.18), "Pine_Needles": (0.20, 0.42, 0.26),
    "Rock_Grey": (0.55, 0.55, 0.54), "Rock_Moss": (0.42, 0.58, 0.30),
    "Slab_Stone": (0.66, 0.65, 0.62),
    "Fall_Rock": (0.50, 0.50, 0.50), "Fall_Moss": (0.40, 0.56, 0.30), "Fall_Water": (0.72, 0.88, 0.97), "Fall_Foam": (0.95, 0.98, 1.00),
}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(name):
    key = name.rstrip("0123456789")
    for k in COL:
        if name.startswith(k.split("_")[0]) and name.endswith(k.split("_")[1]): key = k
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def obj_from_bm(name, bm, mat=None):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(mat or name))
    for p in me.polygons: p.use_smooth = False                              # faceted, like the France trees
    return o
# ---------- primitive helpers (all write into a bmesh) ----------
def frame(z):
    z = z.normalized(); a = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0))
    x = a.cross(z).normalized(); return x, z.cross(x), z
def box(bm, p1, p2, t, t2=None, up=None):
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1; L = d.length; z = d.normalized()
    x, y, _ = frame(z)
    if up is not None:                                                     # keep the beam's t2 side facing "up"
        y = Vector(up).normalized(); y = (y - z * y.dot(z)).normalized(); x = y.cross(z)
    t2 = t2 or t
    vs = [bm.verts.new(p1 + x * (sx * t / 2) + y * (sy * t2 / 2) + z * (sz * L)) for (sx, sy, sz) in
          [(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: bm.faces.new([vs[i] for i in f])
def prism(bm, c, r1, r2, h, seg=6, z0=0.0, rot=0.0):
    """a seg-sided prism / frustum standing at c (x, y), from z0 to z0 + h"""
    b = [bm.verts.new((c[0] + r1 * math.cos(rot + 2*math.pi*i/seg), c[1] + r1 * math.sin(rot + 2*math.pi*i/seg), z0)) for i in range(seg)]
    t = [bm.verts.new((c[0] + r2 * math.cos(rot + 2*math.pi*i/seg), c[1] + r2 * math.sin(rot + 2*math.pi*i/seg), z0 + h)) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg; bm.faces.new([b[i], b[j], t[j], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)
    return b, t
def tube(bm, pts, radii, seg=6):
    """a tapered tube along a polyline (trunks, branches)"""
    rings = []
    for k, p in enumerate(pts):
        p = Vector(p)
        d = (Vector(pts[min(k + 1, len(pts) - 1)]) - Vector(pts[max(k - 1, 0)])).normalized()
        x, y, _ = frame(d)
        rings.append([bm.verts.new(p + (x * math.cos(2*math.pi*i/seg) + y * math.sin(2*math.pi*i/seg)) * radii[k]) for i in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg; bm.faces.new([a[i], a[j], b[j], b[i]])
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
def blob(bm, c, r, sz=1.0, jitter=0.18, subdiv=2, seed=0, flat_bottom=None):
    """a faceted low-poly cluster (France-tree style): an icosphere ADDED to bm, jittered, squashed by sz"""
    rnd = random.Random(seed)
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    for v in res["verts"]:
        v.co *= 1.0 + rnd.uniform(-jitter, jitter)
        v.co.z *= sz
        if flat_bottom is not None and v.co.z < flat_bottom: v.co.z = flat_bottom
        v.co += Vector(c)
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

# ---------- 1. torii ----------
def build_torii():
    red, blk, plq = bmesh.new(), bmesh.new(), bmesh.new()
    for x in (-6, 6):
        prism(red, (x, 0), 0.6, 0.48, 14.6, seg=8)                        # the pillars, a little tapered
        prism(blk, (x, 0), 0.85, 0.75, 0.9, seg=8)                        # the black feet (kamebara)
    box(red, (-8.6, 0, 12.0), (8.6, 0, 12.0), 0.9, 0.7, up=(0, 0, 1))     # the nuki crossbeam
    box(red, (-7.6, 0, 14.75), (7.6, 0, 14.75), 0.9, 0.7, up=(0, 0, 1))   # the shimaki under the top beam
    n = 12                                                                # the kasagi: a top beam whose ends sweep up
    pts = [Vector((-9.8 + 19.6 * i / n, 0, 15.5 + 0.9 * (abs(-9.8 + 19.6 * i / n) / 9.8) ** 2.2)) for i in range(n + 1)]
    for a, b in zip(pts, pts[1:]): box(blk, a, b, 1.5, 0.9, up=(0, 0, 1))
    box(red, (0, 0, 12.4), (0, 0, 14.4), 0.5, 0.5)                        # the plaque post
    box(plq, (0, -0.3, 12.7), (0, -0.3, 14.3), 1.6, 0.35)                 # the plaque
    return [obj_from_bm("Torii_Red", red), obj_from_bm("Torii_Black", blk), obj_from_bm("Torii_Plaque", plq)]

# ---------- 2. stone lantern (Kasuga style) ----------
def build_lantern():
    st, pp = bmesh.new(), bmesh.new()
    prism(st, (0, 0), 1.25, 1.05, 0.45, seg=6)                            # base
    prism(st, (0, 0), 0.38, 0.32, 2.3, seg=8, z0=0.45)                    # post
    prism(st, (0, 0), 0.75, 1.05, 0.4, seg=6, z0=2.75)                    # platform
    for i in range(6):                                                    # the firebox's six corner posts
        a = 2 * math.pi * i / 6
        prism(st, (0.72 * math.cos(a), 0.72 * math.sin(a)), 0.12, 0.12, 1.05, seg=4, z0=3.15, rot=a)
    prism(pp, (0, 0), 0.66, 0.66, 1.05, seg=6, z0=3.15)                   # the paper (lit in Studio)
    b, t = prism(st, (0, 0), 1.55, 0.25, 0.7, seg=6, z0=4.2)              # the roof
    for v in b: v.co.z += 0.18                                            # the corners curl up a little
    prism(st, (0, 0), 1.25, 1.35, 0.12, seg=6, z0=4.12)                   # the roof's lower lip
    blob(st, (0, 0, 5.15), 0.32, sz=1.3, jitter=0.0, subdiv=1)            # the top jewel
    return [obj_from_bm("Lantern_Stone", st), obj_from_bm("Lantern_Paper", pp)]

# ---------- 3. taiko bridge ----------
L2, W2, RISE = 20.0, 4.0, 5.5     # (placed at y 0.3 by the canal: the deck clears the bank tops at 2.1, the crown at ~6.1 as today)
def arch(x): return RISE * (1 - (x / L2) ** 2)
def build_bridge():
    red, deck, gold, stone = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    n = 20
    xs = [-L2 + 2 * L2 * i / n for i in range(n + 1)]
    for a, b in zip(xs, xs[1:]):                                          # the deck: a curved slab in planks
        p1, p2 = Vector((a, 0, arch(a) - 0.3)), Vector((b, 0, arch(b) - 0.3))
        box(deck, p1, p2, 2 * W2 - 0.6, 0.6, up=(0, 0, 1))
        for y in (-W2 + 0.35, W2 - 0.35):                                 # the red side beams under its edges
            box(red, Vector((a, y, arch(a) - 0.9)), Vector((b, y, arch(b) - 0.9)), 0.7, 1.0, up=(0, 0, 1))
    post_x = [-L2 + 0.4 + i * (2 * L2 - 0.8) / 10 for i in range(11)]
    for y in (-W2 + 0.35, W2 - 0.35):
        for k, x in enumerate(post_x):
            z = arch(x)
            box(red, (x, y, z - 0.2), (x, y, z + 2.3), 0.42, 0.42)        # posts
            if k in (0, 10, 5):                                           # gold caps (giboshi) on the ends and the crown
                blob(gold, (x, y, z + 2.55), 0.32, sz=1.1, jitter=0.0, subdiv=1)
                prism(gold, (x, y), 0.06, 0.0, 0.35, seg=6, z0=z + 2.75)
        for a, b in zip(post_x, post_x[1:]):                              # the top rail and the mid rail follow the arch
            for h, t in ((2.05, 0.34), (1.1, 0.24)):
                box(red, Vector((a, y, arch(a) + h)), Vector((b, y, arch(b) + h)), t, t, up=(0, 0, 1))
    for x in (-L2 + 1.2, L2 - 1.2):                                       # stone footings at both ends
        box(stone, (x, 0, -2.4), (x, 0, -0.2), 2 * W2 + 0.8, 2.6)          # (across the bridge: 8.8 along Y, 2.6 along X)
    for x in (-8, 8):                                                     # two red cross-beams under the arch
        box(red, (x, -W2 + 0.75, arch(x) - 1.3), (x, W2 - 0.75, arch(x) - 1.3), 0.5, 0.6)   # (inside the side beams)
    return [obj_from_bm("Bridge_Red", red), obj_from_bm("Bridge_Deck", deck), obj_from_bm("Bridge_Gold", gold), obj_from_bm("Bridge_Stone", stone)]

# ---------- 4. autumn maple ----------
def build_maple(seed, name):
    rnd = random.Random(seed)
    bark = bmesh.new(); leaves = {"Red": bmesh.new(), "Orange": bmesh.new(), "Gold": bmesh.new()}
    lean = rnd.uniform(-0.6, 0.6)
    trunk = [(0, 0, 0), (lean * 0.3, 0.1, 2.0), (lean * 0.8, -0.2, 4.0), (lean * 1.1, 0.1, 5.8)]
    tube(bark, trunk, [0.62, 0.48, 0.38, 0.3], seg=7)
    tops = []
    for k in range(5):                                                    # branches spreading up and out
        a = k * 2 * math.pi / 5 + rnd.uniform(-0.3, 0.3)
        base = Vector(trunk[2 + (k % 2)])
        tip = base + Vector((math.cos(a) * rnd.uniform(2.6, 3.6), math.sin(a) * rnd.uniform(2.6, 3.6), rnd.uniform(1.8, 2.8)))
        mid = base.lerp(tip, 0.5) + Vector((0, 0, 0.5))
        tube(bark, [base, mid, tip], [0.26, 0.18, 0.1], seg=5)
        tops.append(tip)
    tops.append(Vector(trunk[-1]) + Vector((0, 0, 1.6)))
    cols = ["Red", "Orange", "Gold"]
    for k, tp in enumerate(tops):                                         # faceted autumn clusters, in tiers
        blob(leaves[cols[k % 3]], tp + Vector((0, 0, 0.4)), rnd.uniform(2.0, 2.6), sz=0.62, seed=seed * 10 + k)
        blob(leaves[cols[(k + 1) % 3]], tp + Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), -0.7)), rnd.uniform(1.4, 1.8), sz=0.6, seed=seed * 10 + k + 50)
    objs = [obj_from_bm(name + "_Maple_Bark", bark, "Maple_Bark")]
    for c, bm in leaves.items(): objs.append(obj_from_bm(name + "_Maple_" + c, bm, "Maple_" + c))
    return objs

# ---------- 5. black pine ----------
def build_pine():
    rnd = random.Random(7)
    bark, ndl = bmesh.new(), bmesh.new()
    trunk = [(0, 0, 0), (0.6, 0.2, 2.0), (1.6, -0.1, 3.8), (2.2, 0.3, 5.4), (2.0, 0.0, 7.0)]
    tube(bark, trunk, [0.62, 0.5, 0.42, 0.34, 0.24], seg=7)
    pads = [(Vector(trunk[1]), Vector((-3.4, 0.6, 2.6)), 2.3), (Vector(trunk[2]), Vector((4.6, -1.0, 3.6)), 2.1),
            (Vector(trunk[3]), Vector((-1.0, 3.4, 5.6)), 1.9), (Vector(trunk[3]), Vector((4.0, 2.2, 6.0)), 1.8), (Vector(trunk[4]), Vector((2.0, 0.0, 7.6)), 2.2)]
    for k, (base, tip, r) in enumerate(pads):                             # horizontal limbs to flat cloud pads
        tube(bark, [base, base.lerp(tip, 0.6) + Vector((0, 0, -0.2)), tip], [0.22, 0.15, 0.1], seg=5)
        blob(ndl, tip + Vector((0, 0, 0.35)), r, sz=0.34, jitter=0.15, seed=70 + k)
    return [obj_from_bm("Pine_Bark", bark), obj_from_bm("Pine_Needles", ndl)]

# ---------- 6. rocks with a mossy top ----------
def build_rocks():
    objs = []
    for k, (r, sz) in enumerate(((1.6, 0.7), (2.4, 0.55), (1.1, 0.9)), start=1):
        bm = bmesh.new(); blob(bm, (0, 0, 0), r, sz=sz, jitter=0.25, subdiv=2, seed=200 + k, flat_bottom=-r * sz * 0.35)
        moss = bmesh.new()
        me = bpy.data.meshes.new("_r"); bm.to_mesh(me); bm.free()
        g, m = bmesh.new(), bmesh.new()
        src = bmesh.new(); src.from_mesh(me); src.normal_update()
        for f in src.faces:                                               # faces looking up are moss, the rest grey stone
            dst = m if f.normal.z > 0.62 else g
            vs = [dst.verts.new(v.co) for v in f.verts]; dst.faces.new(vs)
        src.free(); bpy.data.meshes.remove(me); moss.free()
        objs += [obj_from_bm(f"Rock{k}_Grey", g, "Rock_Grey"), obj_from_bm(f"Rock{k}_Moss", m, "Rock_Moss")]
    return objs

# ---------- 7. stepping slabs ----------
def build_slabs():
    objs = []
    for k, (r, n) in enumerate(((1.5, 7), (1.9, 8), (1.3, 6)), start=1):
        rnd = random.Random(300 + k); bm = bmesh.new()
        ring = [(r * rnd.uniform(0.8, 1.1) * math.cos(2*math.pi*i/n + rnd.uniform(-0.2, 0.2)), r * rnd.uniform(0.8, 1.1) * math.sin(2*math.pi*i/n)) for i in range(n)]
        b = [bm.verts.new((x, y, 0)) for x, y in ring]; t = [bm.verts.new((x * 0.93, y * 0.93, 0.35)) for x, y in ring]
        for i in range(n):
            j = (i + 1) % n; bm.faces.new([b[i], b[j], t[j], t[i]])
        bm.faces.new(list(reversed(b))); bm.faces.new(t)
        objs.append(obj_from_bm(f"Slab{k}", bm, "Slab_Stone"))
    return objs

# ---------- 8. waterfall head ----------
def build_waterfall():
    rk, ms, wa, fo = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    rocks = [((-4.5, 1.0, 3.5), 3.4, 1.1), ((4.5, 1.0, 3.2), 3.2, 1.1), ((-3.0, 2.6, 7.5), 2.8, 0.9), ((3.2, 2.4, 7.2), 2.7, 0.9),
             ((0, 3.4, 8.6), 3.0, 0.6), ((-6.5, -0.6, 1.2), 2.0, 0.8), ((6.4, -0.4, 1.3), 2.1, 0.8), ((0, 1.6, 4.6), 2.2, 1.6)]
    for k, (c, r, sz) in enumerate(rocks):
        tmp = bmesh.new(); blob(tmp, c, r, sz=sz, jitter=0.22, seed=400 + k)
        me = bpy.data.meshes.new("_w"); tmp.to_mesh(me); tmp.free()
        src = bmesh.new(); src.from_mesh(me); src.normal_update()
        for f in src.faces:
            dst = ms if f.normal.z > 0.65 else rk
            dst.faces.new([dst.verts.new(v.co) for v in f.verts])
        src.free(); bpy.data.meshes.remove(me)
    n = 10                                                                # the falling sheet: out over the lip, then down
    prof = [(0.4 - 1.4 * (i / n) ** 0.5, 9.4 - 9.0 * (i / n) ** 1.6) for i in range(n + 1)]
    left = [wa.verts.new((-1.6 - 0.15 * i / n, y, z)) for i, (y, z) in enumerate(prof)]
    right = [wa.verts.new((1.6 + 0.15 * i / n, y, z)) for i, (y, z) in enumerate(prof)]
    for i in range(n):
        wa.faces.new([left[i], right[i], right[i + 1], left[i + 1]])     # one-sided: DoubleSided = true on the MeshPart in Studio
    prism(fo, (0, -1.2), 2.6, 1.8, 0.35, seg=9, z0=0.0)                   # the foam where it lands
    return [obj_from_bm("Fall_Rock", rk), obj_from_bm("Fall_Moss", ms), obj_from_bm("Fall_Water", wa), obj_from_bm("Fall_Foam", fo)]

def export(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
    total = sum(tris(o) for o in objs)
    log(f"{name}.fbx: {len(objs)} meshes, {total} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"torii": build_torii(), "lantern": build_lantern(), "bridge": build_bridge(), "maple_a": build_maple(1, "A"),
              "maple_b": build_maple(2, "B"), "pine": build_pine(), "rocks": build_rocks(), "slabs": build_slabs(), "waterfall": build_waterfall()}
    for name, objs in pieces.items(): export(objs, name)
    # each piece's bounding box in ROBLOX axes (x, y up, z) relative to its Blender origin (the ground centre): Roblox x = Blender x,
    # y = Blender z, z = -Blender y (the -Z-forward / Y-up export) - the placement script uses it to find the origin whatever the importer
    # does to the pivot. Groups (Rock1, Slab2 ...) get their own box.
    import json
    def bbox(objs):
        pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
        rb = [(p.x, p.z, -p.y) for p in pts]
        return {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}
    info = {name: bbox(objs) for name, objs in pieces.items()}
    for k in (1, 2, 3):
        info[f"rocks/Rock{k}"] = bbox([o for o in pieces["rocks"] if o.name.startswith(f"Rock{k}_")])
        info[f"slabs/Slab{k}"] = bbox([o for o in pieces["slabs"] if o.name == f"Slab{k}"])
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("BBOX " + json.dumps(info))
    log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # ---------- previews: a lineup on grass, Workbench flat colours (works headless) ----------
    lay = {"bridge": (0, 0, 0), "torii": (0, 14, 0), "lantern": (-14, -10, 0), "maple_a": (-26, 6, 0), "maple_b": (26, 6, 0),
           "pine": (22, -12, 0), "rocks": (-8, -14, 0), "slabs": (6, -14, 0), "waterfall": (0, 30, 0)}
    for name, objs in pieces.items():
        for o in objs: o.location = Vector(lay[name])
    for k, n in enumerate(("Rock1", "Rock2", "Rock3")):
        for o in pieces["rocks"]:
            if o.name.startswith(n): o.location = Vector(lay["rocks"]) + Vector((k * 4.5, 0, 0))
    for k, n in enumerate(("Slab1", "Slab2", "Slab3")):
        for o in pieces["slabs"]:
            if o.name == n: o.location = Vector(lay["slabs"]) + Vector((k * 4.2, 0, 0))
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=160, location=(0, 0, -0.01)); g = bpy.context.active_object; g.name = "Ground"
    gm = bpy.data.materials.new("Ground"); gm.diffuse_color = (lin(0.36), lin(0.62), lin(0.30), 1); g.data.materials.append(gm)
    # Cycles on the CPU (no GPU or OpenGL needed - runs headless anywhere), few samples: a preview, not a beauty shot
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 620
    gm.use_nodes = True; gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.36), lin(0.62), lin(0.30), 1)
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(8), math.radians(-30)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 32
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_lineup.png", (0, -62, 26), (0, 6, 4))
    shot("prev_bridge.png", (16, -24, 9), (0, 0, 2.5))
    shot("prev_torii_lantern.png", (-20, -26, 8), (-6, 4, 5))
    shot("prev_trees.png", (0, -34, 10), (0, 0, 5))
    shot("prev_waterfall.png", (10, 6, 9), (0, 30, 4))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc())
