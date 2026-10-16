"""Japan canal boat (job 125, Oct 16 2026). Shannon, with a photo of a Yanagawa-style wooden canal boat: "to go in the water instead
of that terrible thing in there now can you make something that look like this?" (the flat brown box LanternStreet."Canal boat").
A long, slim, flat-bottomed boat of pale cedar planks: flared sides in three strakes with dark seams, a raked square bow board that
rises high, a raked transom, thick gunwale rails whose ends run past the bow, beams through the sides, floor boards, a boatman's deck
at the stern and a small foredeck, three thwarts, two straw kasa hats left on the thwarts, a bamboo pole and a coil of rope.
Every mesh object is named for its colour in Studio (as gen_garden1.py):
  Boat_Hull, Boat_Seam, Boat_Rail, Boat_Beam, Boat_Floor, Boat_Deck, Boat_Bench, Boat_Hat, Boat_Pole, Boat_Rope
Units: 1 Blender unit = 1 stud, Z up, the bow = -Y (exported -Z forward / Y up). The origin is the middle of the flat bottom, outside.
26 long, 6.6 wide over the rails (7.5 over the beam ends); the bow board tops out at ~3.1. Writes out_boat/boat.fbx,
out_boat/japan_boat_kit.fbx (one Empty "boat" for a one-step Import 3D), out_boat/pieces.json, previews prev_boat_*.png.
Run: blender -b --python gen_boat.py"""
import bpy, bmesh, math, os, json, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_boat")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)

COL = {  # sRGB 0..1 - the installer uses the same values in Studio
    "Boat_Hull": (0.86, 0.63, 0.39), "Boat_Seam": (0.50, 0.32, 0.18), "Boat_Rail": (0.72, 0.48, 0.27), "Boat_Beam": (0.64, 0.42, 0.24),
    "Boat_Floor": (0.78, 0.58, 0.38), "Boat_Deck": (0.80, 0.57, 0.35), "Boat_Bench": (0.75, 0.53, 0.31), "Boat_Hat": (0.88, 0.78, 0.55),
    "Boat_Pole": (0.74, 0.68, 0.44), "Boat_Rope": (0.92, 0.90, 0.84),
}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def uv_project(bm, scale=6.0):
    """box-project UVs (grain along the boat's length) so a Roblox material such as Wood can tile on it if wanted"""
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for lp in f.loops:
            p = lp.vert.co
            lp[uv].uv = (p.y / scale, p.z / scale) if ax == 0 else ((p.x / scale, p.z / scale) if ax == 1 else (p.y / scale, p.x / scale))
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv_project(bm)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(name))
    for p in me.polygons: p.use_smooth = False                              # faceted, like the France trees and the garden kit
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

# ---------- the hull's lines: station t runs from the stern (0, y +13) to the bow (1, y -13) ----------
L = 26.0
def curve(pts, t):
    t = max(pts[0][0], min(pts[-1][0], t))
    for (t0, v0), (t1, v1) in zip(pts, pts[1:]):
        if t <= t1:
            u = (t - t0) / (t1 - t0) if t1 > t0 else 0.0
            u = u * u * (3 - 2 * u)                                           # smoothstep between control points
            return v0 + (v1 - v0) * u
    return pts[-1][1]
WG = [(0, 2.55), (0.15, 3.05), (0.5, 3.25), (0.8, 3.0), (1.0, 2.05)]     # half width at the gunwale
WB = [(0, 1.95), (0.15, 2.35), (0.5, 2.5), (0.8, 2.25), (1.0, 1.2)]      # half width at the chine (the flat bottom's edge)
ZB = [(0, 0.35), (0.12, 0.05), (0.2, 0.0), (0.7, 0.0), (0.85, 0.25), (1.0, 1.0)]   # the bottom's rocker
ZG = [(0, 2.0), (0.2, 1.7), (0.55, 1.65), (0.8, 1.9), (1.0, 2.9)]       # the sheer: low amidships, high at the bow
RAKE = [(0, -0.7), (0.1, 0.0), (0.9, 0.0), (1.0, 1.6)]                   # the chine's y offset from the gunwale's: raked bow and transom
def yt(t): return L / 2 - L * t
def chine(t, side): return Vector((side * curve(WB, t), yt(t) + curve(RAKE, t), curve(ZB, t)))
def gunwale(t, side): return Vector((side * curve(WG, t), yt(t), curve(ZG, t)))
def side_pt(t, side, f):
    """a point on the outer side, f = 0 at the chine to 1 at the gunwale, with a slight outward round"""
    c, g = chine(t, side), gunwale(t, side)
    return c.lerp(g, f) + Vector((side * 0.14 * math.sin(math.pi * f), 0, 0))
def side_frame(t, side, f):
    """the side's 'up along the plank' and 'outward' directions at a point"""
    a, b = side_pt(t, side, max(0.0, f - 0.05)), side_pt(t, side, min(1.0, f + 0.05))
    up = (b - a).normalized()
    out = Vector((side * up.z, 0, -side * up.x)).normalized()               # square to the plank in the x-z plane, facing out (and a little down)
    return up, out
N = 28
TS = [i / N for i in range(N + 1)]
FS = [0.0, 1 / 3, 2 / 3, 1.0]

def ribbon(bm, pts_fn, w, h, ts):
    """a box-section strip following pts_fn(t) -> (centre, up, out) at each station; w across 'up', h along 'out'"""
    rings = []
    for t in ts:
        c, up, out = pts_fn(t)
        rings.append([bm.verts.new(c + up * (su * w / 2) + out * (so * h)) for (su, so) in [(-1, 0), (1, 0), (1, 1), (-1, 1)]])
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            j = (i + 1) % 4; bm.faces.new([a[i], a[j], b[j], b[i]])
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
def box(bm, c, sx, sy, sz):
    c = Vector(c)
    vs = [bm.verts.new(c + Vector((dx * sx / 2, dy * sy / 2, dz * sz / 2))) for dx, dy, dz in
          [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: bm.faces.new([vs[i] for i in f])
def prism(bm, c, r1, r2, h, seg=8, z0=0.0):
    b = [bm.verts.new((c[0] + r1 * math.cos(2*math.pi*i/seg), c[1] + r1 * math.sin(2*math.pi*i/seg), z0)) for i in range(seg)]
    t = [bm.verts.new((c[0] + r2 * math.cos(2*math.pi*i/seg), c[1] + r2 * math.sin(2*math.pi*i/seg), z0 + h)) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg; bm.faces.new([b[i], b[j], t[j], t[i]])
    bm.faces.new(list(reversed(b))); bm.faces.new(t)

def hw(t, z):
    """the hull's INNER half width at height z, station t"""
    zb_, zg_ = curve(ZB, t), curve(ZG, t); f = max(0.0, min(1.0, (z - zb_) / (zg_ - zb_)))
    return curve(WB, t) + (curve(WG, t) - curve(WB, t)) * f + 0.14 * math.sin(math.pi * f) - 0.22
def loft(bm, secs):
    """connect a list of 4-vertex cross sections (Vectors) into a closed strip"""
    rings = [[bm.verts.new(p) for p in sec] for sec in secs]
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            j = (i + 1) % 4; bm.faces.new([a[i], a[j], b[j], b[i]])
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
def torus(bm, c, R, r, segs=14, rsegs=6):
    rings = []
    for i in range(segs):
        a = 2 * math.pi * i / segs; d = Vector((math.cos(a), math.sin(a), 0))
        rings.append([bm.verts.new(Vector(c) + d * (R + r * math.cos(2 * math.pi * k / rsegs)) + Vector((0, 0, r * math.sin(2 * math.pi * k / rsegs))))
                      for k in range(rsegs)])
    for i in range(segs):
        A, B = rings[i], rings[(i + 1) % segs]
        for k in range(rsegs):
            m = (k + 1) % rsegs; bm.faces.new([A[k], A[m], B[m], B[k]])
SOLE = 0.9          # the raised floor's underside: its top (1.05) stays above the canal water when the boat sits 0.55 deep... see the installer
T_S0, T_S1 = 0.1, 0.88

def merge(a, b):
    """copy bmesh b's geometry into a (one object, one colour)"""
    me = bpy.data.meshes.new("tmp"); b.to_mesh(me); b.free(); a.from_mesh(me); bpy.data.meshes.remove(me); return a

def build_boat():
    # 1. the hull: an open-topped shell lofted through the stations, closed by the transom and the bow board, then thickened inward
    hb = bmesh.new()
    rings = []
    for t in TS:
        ring = [side_pt(t, -1, f) for f in reversed(FS)] + [side_pt(t, 1, f) for f in FS]   # left gunwale .. left chine, right chine .. right gunwale
        rings.append([hb.verts.new(p) for p in ring])
    for a, b in zip(rings, rings[1:]):
        for i in range(len(a) - 1): hb.faces.new([a[i], a[i + 1], b[i + 1], b[i]])
    hb.faces.new(rings[0]); hb.faces.new(list(reversed(rings[-1])))      # the transom and the bow board
    bmesh.ops.recalc_face_normals(hb, faces=hb.faces)
    hull = obj_from_bm("Boat_Hull", hb)
    sol = hull.modifiers.new("Solidify", "SOLIDIFY"); sol.thickness = 0.2; sol.offset = -1.0; sol.use_rim = True; sol.use_even_offset = True
    bpy.context.view_layer.objects.active = hull; hull.select_set(True)
    bpy.ops.object.modifier_apply(modifier=sol.name)
    # 2. the seams: dark battens along the two strake lines and the chine on each side
    sm = bmesh.new()
    for side in (-1, 1):
        for f in (0.02, 1 / 3, 2 / 3):
            def fn(t, side=side, f=f):
                up, out = side_frame(t, side, f)
                return side_pt(t, side, f), up, out
            ribbon(sm, fn, 0.09, 0.05, TS)
    # 3. the gunwale rails: thick caps along the sheer that run past the bow board (the horns) and a little past the transom
    rl = bmesh.new()
    ext = [-0.35 / L] + TS + [1 + 0.75 / L]
    for side in (-1, 1):
        def fn(t, side=side):
            tc = max(0.0, min(1.0, t))
            g = gunwale(tc, side) + Vector((0, -(t - tc) * L, max(0.0, t - tc) * L * 0.55))   # past the ends: straight on, rising a little at the bow
            return g + Vector((-side * 0.12, 0, 0.0)), Vector((1, 0, 0)), Vector((0, 0, 1))
        ribbon(rl, fn, 0.42, 0.3, ext)
    for t, extra in ((0.0, 0.0), (1.0, 0.0)):                             # caps across the transom and the bow board
        gL, gR = gunwale(t, -1), gunwale(t, 1)
        box(rl, ((gL + gR) / 2) + Vector((0, 0, 0.15)), (gR - gL).length + 0.2, 0.4, 0.3)
    # 4. the beams through the sides (their ends stick out), the stern deck and foredeck, the thwarts, the floor boards
    bm_ = bmesh.new()
    for t in (0.1, 0.36, 0.62, 0.88):
        w = curve(WG, t); z = curve(ZG, t) - 0.32
        box(bm_, (0, yt(t), z), 2 * w + 0.9, 0.32, 0.3)
    dk = bmesh.new()
    def deck(t0, t1, planks, dz=0.2):
        for k in range(planks):
            a, b = t0 + (t1 - t0) * k / planks, t0 + (t1 - t0) * (k + 1) / planks
            tm = (a + b) / 2; w = min(curve(WG, a), curve(WG, b)) - 0.25
            z = min(curve(ZG, a), curve(ZG, b)) - dz
            box(dk, (0, yt(tm), z), 2 * w, abs(yt(b) - yt(a)) - 0.06, 0.14)
    deck(0.0, 0.1, 3)                                                     # where the boatman stands
    fts = [T_S1 + (0.985 - T_S1) * i / 6 for i in range(7)]                # the foredeck: one plate following the sheer up to the bow board
    secs = []
    for t in fts:
        w = curve(WG, t) - 0.3; z = curve(ZG, t) - 0.32
        secs.append([Vector((-w, yt(t), z)), Vector((w, yt(t), z)), Vector((w, yt(t), z + 0.14)), Vector((-w, yt(t), z + 0.14))])
    loft(dk, secs)
    for t, ztop in ((T_S0, min(curve(ZG, a) for a in (0.0, 1 / 30, 2 / 30, 0.1)) - 0.27), (T_S1, curve(ZG, T_S1) - 0.32)):   # bulkheads
        zb0 = SOLE - 0.05
        w0, w1 = hw(t, zb0) + 0.1, hw(t, ztop) + 0.1; y0 = yt(t) + (0.06 if t < 0.5 else -0.06); y1 = y0 + (-0.14 if t < 0.5 else 0.14)
        secs = [[Vector((-w0, y, zb0)), Vector((w0, y, zb0)), Vector((w1, y, ztop)), Vector((-w1, y, ztop))] for y in (y0, y1)]
        loft(dk, secs)
    bn = bmesh.new()
    for t in (0.3, 0.5, 0.7):
        z = 1.45
        box(bn, (0, yt(t), z), 2 * (hw(t, z) + 0.1), 1.05, 0.15)
    fl, sub = bmesh.new(), bmesh.new()
    sts = [T_S0 + (T_S1 - T_S0) * i / 14 for i in range(15)]
    loft(sub, [[Vector((-hw(t, SOLE) - 0.08, yt(t), SOLE)), Vector((hw(t, SOLE) + 0.08, yt(t), SOLE)),
                Vector((hw(t, SOLE + 0.06) + 0.08, yt(t), SOLE + 0.06)), Vector((-hw(t, SOLE + 0.06) - 0.08, yt(t), SOLE + 0.06))] for t in sts])
    NP = 6
    for k in range(NP):                                                   # the floor boards on it, thin dark gaps between
        secs = []
        for t in sts:
            w = hw(t, SOLE + 0.1) + 0.02; a, b = -w + 2 * w * k / NP + 0.03, -w + 2 * w * (k + 1) / NP - 0.03
            secs.append([Vector((a, yt(t), SOLE + 0.05)), Vector((b, yt(t), SOLE + 0.05)), Vector((b, yt(t), SOLE + 0.15)), Vector((a, yt(t), SOLE + 0.15))])
        loft(fl, secs)
    # 5. two straw kasa hats left on the thwarts, the bamboo pole resting on the thwarts, a coil of rope on the foredeck
    ht = bmesh.new()
    for (x, t, r) in ((0.9, 0.3, 0.95), (-0.45, 0.7, 0.9)):
        prism(ht, (x, yt(t)), r, 0.05, 0.42, seg=12, z0=1.525)
        prism(ht, (x, yt(t)), 0.12, 0.05, 0.12, seg=6, z0=1.9)
    pl = bmesh.new()
    p0, p1 = Vector((-1.9, yt(0.04), 1.89)), Vector((-1.45, yt(0.86), 1.56))   # on the stern deck and the last thwart
    seg = 10
    for k in range(seg):
        a, b = p0.lerp(p1, k / seg), p0.lerp(p1, (k + 1) / seg)
        d = (b - a); n = d.normalized()
        x = n.cross(Vector((0, 0, 1))).normalized(); y = x.cross(n)
        r1 = 0.1; r2 = 0.13
        ring_a = [pl.verts.new(a + (x * math.cos(2*math.pi*i/8) + y * math.sin(2*math.pi*i/8)) * r1) for i in range(8)]
        ring_m = [pl.verts.new(b - n * 0.12 + (x * math.cos(2*math.pi*i/8) + y * math.sin(2*math.pi*i/8)) * r1) for i in range(8)]
        ring_n = [pl.verts.new(b - n * 0.05 + (x * math.cos(2*math.pi*i/8) + y * math.sin(2*math.pi*i/8)) * r2) for i in range(8)]   # the node
        ring_b = [pl.verts.new(b + (x * math.cos(2*math.pi*i/8) + y * math.sin(2*math.pi*i/8)) * r1) for i in range(8)]
        for A, B in ((ring_a, ring_m), (ring_m, ring_n), (ring_n, ring_b)):
            for i in range(8):
                j = (i + 1) % 8; pl.faces.new([A[i], A[j], B[j], B[i]])
        pl.faces.new(list(reversed(ring_a))); pl.faces.new(ring_b)
    rp = bmesh.new()                                                      # a coil of rope on the floor by the foredeck
    for k in range(3): torus(rp, (1.25, yt(0.84), SOLE + 0.15 + 0.08 + 0.13 * k), 0.42 - 0.03 * k, 0.08)
    return [hull, obj_from_bm("Boat_Seam", merge(sm, sub)), obj_from_bm("Boat_Rail", rl), obj_from_bm("Boat_Beam", bm_), obj_from_bm("Boat_Deck", dk),
            obj_from_bm("Boat_Bench", bn), obj_from_bm("Boat_Floor", fl), obj_from_bm("Boat_Hat", ht), obj_from_bm("Boat_Pole", pl),
            obj_from_bm("Boat_Rope", rp)]

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = build_boat()
    export(objs, os.path.join(OUT, "boat.fbx"))
    log(f"boat.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    rb = [(p.x, p.z, -p.y) for p in pts]                                  # Roblox axes: x, y up, z = -Blender y (the bow is at Roblox +z)
    info = {"boat": {"min": [round(min(q[i] for q in rb), 3) for i in range(3)], "max": [round(max(q[i] for q in rb), 3) for i in range(3)]}}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("BBOX " + json.dumps(info))
    emp = bpy.data.objects.new("boat", None); bpy.context.scene.collection.objects.link(emp)   # one Empty: one Model "boat" on Import 3D
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_boat_kit.fbx"))
    log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # ---------- previews: on canal-green water, Cycles on the CPU ----------
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0.7)); g = bpy.context.active_object; g.name = "Water"
    gm = bpy.data.materials.new("Water"); gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(0.30), lin(0.42), lin(0.34), 1)
    gm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.25
    g.data.materials.append(gm)
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 32; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(45), math.radians(10), math.radians(-35)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 35
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_boat_photo_angle.png", (22, -16, 8), (0, -1, 1.2))         # like her photo: from the bow quarter, a little above
    shot("prev_boat_side.png", (30, 0, 3.5), (0, 0, 1.4))
    shot("prev_boat_above.png", (9, 14, 17), (0, 0, 1.0))
    shot("prev_boat_stern.png", (-14, 22, 6), (0, 2, 1.4))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
