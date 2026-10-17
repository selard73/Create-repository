"""The Mikan greengrocer's FRONT (runner 7, Oct 17 2026), from Shannon's photo of a grocery store front (SHOPFRONTS.md #2): a big
grey-tiled awning over the whole front on a timber frame with posts on the lane, a carved wooden sign on its front beam, shelves of
jars at the back wall, baskets of goods on low benches outside, dark side banners with a crest, potted bamboo, a standing lantern sign.
Local frame: x along the front, y up from the lane floor, +z OUT toward the lane (the back wall is z = 0). Pieces:
  front_awning   30 wide x 11 deep tiled awning: top edge at the wall y 10.4, down to 8.6 at z 11; ridge roll, tile ribs, a fascia beam
                 at the outer edge, 3 struts under, two 0.5-square posts at z 10.4, x +-14 (Awn_Tile, Awn_Wood)
  sign_board     a carved board 9 x 2.2: dark frame, a raised lighter panel (the words go on as a SurfaceGui) (Sign_Frame, Sign_Panel)
  jar_shelf      8 wide x 7 tall x 1.3 deep: three shelves with 10 jars each in amber / cream / dark red (Shelf_Wood, Jar_Amber, Jar_Cream, Jar_Red, Jar_Lid)
  basket_bench   a low bench 6 x 1.3 on trestles with three round baskets heaped with goods (Bench_Wood, Basket_Weave, Goods_Orange, Goods_Green, Goods_Pink)
  potted_bamboo  a square clay pot with five culms and leaf tufts (Pot_Clay, Bam_Culm, Bam_Leaf)
  andon_sign     a standing paper box lantern on a base with a little roof (Andon_Wood, Andon_Paper)
  side_banner    a rod from a bracket at y 8.2 with an indigo cloth 2.2 x 6.4 hanging and a white round crest (Banner_Rod, Banner_Cloth, Banner_Crest)
Base at y 0. Box UVs. Writes out_shopfront/japan_kit21_mikan_front.fbx, pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_shopfront")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {"Awn_Tile": (0.30, 0.30, 0.33), "Awn_Wood": (0.42, 0.30, 0.18), "Sign_Frame": (0.22, 0.15, 0.10), "Sign_Panel": (0.52, 0.36, 0.20),
       "Shelf_Wood": (0.40, 0.28, 0.17), "Jar_Amber": (0.80, 0.52, 0.18), "Jar_Cream": (0.90, 0.84, 0.66), "Jar_Red": (0.50, 0.14, 0.12), "Jar_Lid": (0.85, 0.80, 0.70),
       "Bench_Wood": (0.52, 0.38, 0.22), "Basket_Weave": (0.72, 0.58, 0.34), "Goods_Orange": (0.92, 0.52, 0.14), "Goods_Green": (0.42, 0.62, 0.26), "Goods_Pink": (0.90, 0.62, 0.70),
       "Pot_Clay": (0.36, 0.26, 0.20), "Bam_Culm": (0.52, 0.62, 0.30), "Bam_Leaf": (0.36, 0.58, 0.24), "Andon_Wood": (0.28, 0.20, 0.13), "Andon_Paper": (0.96, 0.92, 0.80),
       "Banner_Rod": (0.30, 0.21, 0.14), "Banner_Cloth": (0.16, 0.19, 0.38), "Banner_Crest": (0.95, 0.94, 0.90)}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)
def hull(bm, pts):
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(bm, x0, x1, y0, y1, z0, z1): hull(bm, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cyl(bm, cx, cz, r, y0, y1, n=12, r1=None):
    r1 = r if r1 is None else r1
    pts = []
    for k in range(n):
        a = 2 * math.pi * k / n
        pts.append((cx + r * math.cos(a), y0, cz + r * math.sin(a))); pts.append((cx + r1 * math.cos(a), y1, cz + r1 * math.sin(a)))
    hull(bm, pts)
def dome(bm, cx, cy, cz, r, h, n=10):
    pts = [(cx + r * math.cos(2 * math.pi * k / n), cy, cz + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    pts += [(cx + 0.6 * r * math.cos(2 * math.pi * k / n), cy + 0.7 * h, cz + 0.6 * r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    pts.append((cx, cy + h, cz)); hull(bm, pts)
def finish(name, key, bm, smooth=False):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            c = l.vert.co
            u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
            l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(key))
    for p in me.polygons: p.use_smooth = smooth
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def build_awning():
    objs = []
    W, DEEP, Y0, Y1 = 15.0, 11.0, 10.4, 8.6
    bm = bmesh.new()
    hull(bm, [(x, y, z) for x in (-W, W) for (y, z) in ((Y0, -0.05), (Y0 + 0.25, -0.05), (Y1 + 0.25, DEEP), (Y1, DEEP))])
    box(bm, -W - 0.2, W + 0.2, Y0 + 0.2, Y0 + 0.5, -0.05, 0.4)                                            # ridge roll at the wall
    n = int(2 * W / 0.8)
    for i in range(n + 1):
        x = -W + 2 * W * i / n
        hull(bm, [(x - 0.07, Y0 + 0.22, 0.0), (x + 0.07, Y0 + 0.22, 0.0), (x - 0.07, Y0 + 0.36, 0.0), (x + 0.07, Y0 + 0.36, 0.0),
                  (x - 0.07, Y1 + 0.22, DEEP), (x + 0.07, Y1 + 0.22, DEEP), (x - 0.07, Y1 + 0.36, DEEP), (x + 0.07, Y1 + 0.36, DEEP)])
    objs.append(finish("Awn_Tile", "Awn_Tile", bm))
    bm = bmesh.new()
    box(bm, -W - 0.3, W + 0.3, Y1 - 0.55, Y1 + 0.05, DEEP - 0.5, DEEP + 0.05)                               # the fascia beam
    box(bm, -W - 0.3, W + 0.3, Y0 - 0.5, Y0 + 0.05, -0.05, 0.45)                                           # the wall beam
    for x in (-14.0, 14.0): box(bm, x - 0.25, x + 0.25, 0.0, Y1 - 0.5, DEEP - 0.9, DEEP - 0.4)              # the posts on the lane
    for x in (-7.0, 0.0, 7.0): hull(bm, [(x - 0.12, Y0 - 0.5, 0.0), (x + 0.12, Y0 - 0.5, 0.0), (x - 0.12, Y0 - 0.2, 0.0), (x + 0.12, Y0 - 0.2, 0.0), (x - 0.12, Y1 - 0.55, DEEP - 0.6), (x + 0.12, Y1 - 0.55, DEEP - 0.6), (x - 0.12, Y1 - 0.25, DEEP - 0.6), (x + 0.12, Y1 - 0.25, DEEP - 0.6)])
    for x in (-14.0, 14.0): hull(bm, [(x - 0.12, Y1 - 3.2, DEEP - 0.65), (x + 0.12, Y1 - 3.2, DEEP - 0.65), (x - 0.12, Y1 - 2.9, DEEP - 0.65), (x + 0.12, Y1 - 2.9, DEEP - 0.65), (x - 0.12, Y1 - 0.6, DEEP - 3.2), (x + 0.12, Y1 - 0.6, DEEP - 3.2), (x - 0.12, Y1 - 0.3, DEEP - 3.2), (x + 0.12, Y1 - 0.3, DEEP - 3.2)])   # knee braces
    objs.append(finish("Awn_Wood", "Awn_Wood", bm))
    return objs
def build_sign():
    objs = []
    bm = bmesh.new(); box(bm, -4.5, 4.5, 0.0, 2.2, 0.0, 0.3); objs.append(finish("Sign_Frame", "Sign_Frame", bm))
    bm = bmesh.new(); hull(bm, [(x, y, 0.3) for x in (-4.2, 4.2) for y in (0.2, 2.0)] + [(x, y, 0.42) for x in (-4.0, 4.0) for y in (0.32, 1.88)]); objs.append(finish("Sign_Panel", "Sign_Panel", bm))
    return objs
def build_shelf():
    objs = []
    rnd = random.Random(11)
    bm = bmesh.new()
    for x in (-3.9, 3.9): box(bm, x - 0.12, x + 0.12, 0.0, 7.0, 0.0, 1.3)
    for y in (1.0, 3.2, 5.4): box(bm, -4.0, 4.0, y - 0.12, y + 0.12, 0.0, 1.3)
    box(bm, -4.0, 4.0, 0.0, 7.0, -0.05, 0.05)
    objs.append(finish("Shelf_Wood", "Shelf_Wood", bm))
    jars = {"Jar_Amber": bmesh.new(), "Jar_Cream": bmesh.new(), "Jar_Red": bmesh.new()}; lids = bmesh.new()
    keys = list(jars)
    for y in (1.12, 3.32, 5.52):
        x = -3.5
        while x < 3.5:
            r = rnd.uniform(0.26, 0.36); h = rnd.uniform(1.1, 1.6)
            k = keys[rnd.randrange(3)]
            cyl(jars[k], x, 0.65, r, y, y + h, 10, r * 0.9); cyl(lids, x, 0.65, r * 0.75, y + h, y + h + 0.12, 10)
            x += 2 * r + rnd.uniform(0.08, 0.2)
    for k, b in jars.items(): objs.append(finish(k, k, b, True))
    objs.append(finish("Jar_Lid", "Jar_Lid", lids, True))
    return objs
def build_bench():
    objs = []
    bm = bmesh.new()
    box(bm, -3.0, 3.0, 1.05, 1.25, -0.65, 0.65)
    for x in (-2.4, 2.4): hull(bm, [(x - 0.1, 0.0, -0.75), (x + 0.1, 0.0, -0.75), (x - 0.1, 0.0, 0.75), (x + 0.1, 0.0, 0.75), (x - 0.1, 1.05, -0.15), (x + 0.1, 1.05, -0.15), (x - 0.1, 1.05, 0.15), (x + 0.1, 1.05, 0.15)])
    objs.append(finish("Bench_Wood", "Bench_Wood", bm))
    bm = bmesh.new()
    for x in (-2.0, 0.0, 2.0): cyl(bm, x, 0.0, 0.7, 1.25, 1.95, 12, 0.85)
    objs.append(finish("Basket_Weave", "Basket_Weave", bm, True))
    for x, k in ((-2.0, "Goods_Orange"), (0.0, "Goods_Green"), (2.0, "Goods_Pink")):
        bm = bmesh.new(); dome(bm, x, 1.85, 0.0, 0.72, 0.55); objs.append(finish(k, k, bm, True))
    return objs
def build_bamboo():
    objs = []
    rnd = random.Random(21)
    bm = bmesh.new(); hull(bm, [(x, 0.0, z) for x in (-0.7, 0.7) for z in (-0.7, 0.7)] + [(x, 1.4, z) for x in (-0.85, 0.85) for z in (-0.85, 0.85)]); objs.append(finish("Pot_Clay", "Pot_Clay", bm))
    bm = bmesh.new(); leaves = bmesh.new()
    for i in range(5):
        a = 2 * math.pi * i / 5; cx, cz = 0.35 * math.cos(a), 0.35 * math.sin(a)
        h = rnd.uniform(5.0, 7.2)
        cyl(bm, cx, cz, 0.12, 1.3, h, 6, 0.09)
        for _ in range(6):
            ly = rnd.uniform(3.0, h); ang = rnd.uniform(0, 6.28); L = rnd.uniform(0.9, 1.4)
            hull(leaves, [(cx, ly, cz), (cx + 0.5 * L * math.cos(ang) - 0.15 * math.sin(ang), ly + 0.1, cz + 0.5 * L * math.sin(ang) + 0.15 * math.cos(ang)), (cx + 0.5 * L * math.cos(ang) + 0.15 * math.sin(ang), ly + 0.1, cz + 0.5 * L * math.sin(ang) - 0.15 * math.cos(ang)), (cx + L * math.cos(ang), ly - 0.25, cz + L * math.sin(ang))])
    objs.append(finish("Bam_Culm", "Bam_Culm", bm, True)); objs.append(finish("Bam_Leaf", "Bam_Leaf", leaves))
    return objs
def build_andon():
    objs = []
    bm = bmesh.new()
    box(bm, -1.1, 1.1, 0.0, 0.6, -1.1, 1.1)
    for x in (-0.95, 0.95):
        for z in (-0.95, 0.95): box(bm, x - 0.08, x + 0.08, 0.6, 5.0, z - 0.08, z + 0.08)
    hull(bm, [(x, 5.0, z) for x in (-1.25, 1.25) for z in (-1.25, 1.25)] + [(x, 5.6, z) for x in (-0.3, 0.3) for z in (-0.3, 0.3)])
    objs.append(finish("Andon_Wood", "Andon_Wood", bm))
    bm = bmesh.new(); box(bm, -0.9, 0.9, 0.7, 4.9, -0.9, 0.9); objs.append(finish("Andon_Paper", "Andon_Paper", bm))
    return objs
def build_banner():
    objs = []
    bm = bmesh.new(); box(bm, -0.08, 0.08, 8.1, 8.3, -0.1, 0.2); cyl(bm, 0, 0, 0.0, 8.2, 8.2, 4)
    hull(bm, [(x, 8.2 + dy, z) for x in (-1.3, 1.3) for dy in (-0.08, 0.08) for z in (0.12, 0.28)])
    objs.append(finish("Banner_Rod", "Banner_Rod", bm))
    bm = bmesh.new(); hull(bm, [(x, y, z) for x in (-1.1, 1.1) for (y, z) in ((8.15, 0.16), (8.15, 0.24), (1.7, 0.3), (1.7, 0.38))]); objs.append(finish("Banner_Cloth", "Banner_Cloth", bm))
    bm = bmesh.new()
    pts = [(0.55 * math.cos(2 * math.pi * k / 14), 5.6 + 0.55 * math.sin(2 * math.pi * k / 14), z) for k in range(14) for z in (0.14, 0.18)]
    hull(bm, pts)
    objs.append(finish("Banner_Crest", "Banner_Crest", bm))
    return objs
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = {"front_awning": build_awning(), "sign_board": build_sign(), "jar_shelf": build_shelf(), "basket_bench": build_bench(),
              "potted_bamboo": build_bamboo(), "andon_sign": build_andon(), "side_banner": build_banner()}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 40.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit21_mikan_front.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
