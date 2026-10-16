"""Canal falls r3 (cloud, Oct 16 2026). Shannon, with a picture of r2 from the lawn: "that is a problem that needs to be fixed" -
r2's rocks were jittered icospheres: round pale balloons that bulged out over the lawn (dark undersides showing), spilled past the end
wall onto the side walls, and let the end wall's coping stick out through the pile like a plank.
r3 keeps r2's water exactly (the same cleft, chute, ribbon, foam and the installer's beam points) and rebuilds the stone as a Japanese
garden waterfall (taki-ishi): ANGULAR stones (each the convex hull of three jittered rings: a wide base, flat-ish tilted top - no bulge,
no undercut), stacked:
  * the water-fall stone (mizuochi-ishi) with a straight lip the water leaves from, its face set back under the sheet
  * two tall guardian stones (waki-ishi) either side of the fall, unequal heights
  * stones lining the chute, stepping up to the spring; the water comes out from under a dark lintel stone at the back
  * the rise behind on the lawn in lower stones, bases in the ground (z -0.6)
  * at each end of the gap, stones that swallow the cut ends of the end wall's remaining pieces (WallS1 / WallS4) - coping included -
    and stop at x +-10, so the side walls and most of S1/S4's coping stay clean
  * a few low stones in the water at the foot
Two stone tones (Fall_Rock, Fall_Rock2) so neighbouring stones read apart; both lighter than the lanterns (0.40). No vertex colours.
Meshes (the installer's colour keys): Fall_Rock, Fall_Rock2, Fall_Water, Fall_Foam. Frame and units as gen_falls2.py: 1 = 1 stud, Z up,
ORIGIN = the end wall's WATER FACE (y 0), the canal's centre line (x 0), lawn level (z 0); the canal at -y. Water 1.3, bed -4.0, the gap
x -8..8, S1/S4 at x -16..-8 / 8..16 (coping y -0.3..4.3, z 1.65..2.1), the side walls' water faces at x -+12.5.
Writes out_falls3/canal_falls3.fbx, japan_falls3_kit.fbx (one Empty "canal_falls3"), pieces.json, prev_falls3_*.png (stand-ins: the real
canal_wall kit pieces from out3/).  Run: blender -b --python gen_falls3.py   (or python with the bpy module)"""
import bpy, bmesh, math, os, json, random, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("GARDEN_OUT") or os.path.join(D, "out_falls3")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
COL = {"Fall_Rock": (0.50, 0.49, 0.46), "Fall_Rock2": (0.43, 0.42, 0.40), "Fall_Water": (0.72, 0.88, 0.97), "Fall_Foam": (0.95, 0.98, 1.00)}
UV_STUDS = 6.0
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.85 if key != "Fall_Water" else 0.1
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def box_uvs(bm):
    """planar UVs per face on its dominant axis, UV_STUDS studs per tile (as gen_garden3) - a Studio material can tile over the stone"""
    bm.normal_update()
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            c = l.vert.co
            u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
            l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
def obj_from_bm(name, bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    box_uvs(bm)
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(name))
    for p in me.polygons: p.use_smooth = False
    return o
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
WATER, BED = 1.3, -4.0
FOOT = BED - 0.6          # the in-water stones' feet (under the bed)
GROUND = -0.6             # the lawn stones' feet (under the lawn)
# ---------- the water's path: r2's, unchanged (the installer's beam points depend on it) ----------
CH = 1.7
PATH = [(10.0, 6.6), (8.0, 6.0), (6.0, 5.2), (4.0, 4.4), (2.0, 3.8), (0.4, 3.45), (-0.5, 3.3), (-0.9, 2.7), (-1.15, 2.0), (-1.3, WATER + 0.02)]
HALF = [1.3, 1.35, 1.4, 1.45, 1.5, 1.55, 1.6, 1.65, 1.7, 1.8]
def chute_floor(y):
    if y >= PATH[0][0]: return PATH[0][1] - 0.15
    for (ya, za), (yb, zb) in zip(PATH, PATH[1:]):
        if yb <= y <= ya:
            t = (ya - y) / (ya - yb); return za + (zb - za) * t - 0.15
    return -10.0
def keep_out(v):
    """keep stone out of the cleft: x -CH..CH (+0.2) above the chute floor, from the canal side of the lip to the spring"""
    if abs(v.co.x) < CH + 0.2 and v.co.z > chute_floor(v.co.y) - 0.1 and -3.0 < v.co.y < 10.05:
        v.co.x = math.copysign(CH + 0.2, v.co.x if v.co.x != 0 else 1)
# ---------- angular stones ----------
HULLS = []                # (name, planes) per stone, for the coverage check
def hull_into(bm, pts, name, guard=False):
    """the convex hull of pts added to bm (triangles merged into flat facets); guard=True pushes it out of the cleft"""
    t = bmesh.new()
    vs = [t.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(t, input=vs, use_existing_faces=False)
    kill = list({g for g in res["geom_interior"] + res["geom_unused"] if isinstance(g, bmesh.types.BMVert)})
    if kill: bmesh.ops.delete(t, geom=kill, context="VERTS")
    if guard:
        for v in t.verts: keep_out(v)
    bmesh.ops.dissolve_limit(t, angle_limit=math.radians(1.0), verts=list(t.verts), edges=list(t.edges))
    t.normal_update()
    HULLS.append((name, [(f.normal.copy(), f.calc_center_median().copy()) for f in t.faces]))
    m = {}
    for v in t.verts: m[v] = bm.verts.new(v.co)
    for f in t.faces: bm.faces.new([m[v] for v in f.verts])
    t.free()
rnd = random.Random(1316)
def stone(bm, name, c, z0, z1, ax, ay, top=0.55, tilt=(0.0, 0.0), yaw=0.0, n=6, guard=True):
    """a stone standing at c (x, y): its foot at z0 (under the lawn / the bed) straight up to the lawn, then rounded shoulders - rings
    at 45% (0.97) and 82% (0.86) of its height over the lawn - to a smaller tilted top at z1, the upper rings leaning a little; hulled"""
    pts, H = [], max(z1, 0.6)
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    la = rnd.uniform(0, 2 * math.pi); lean = rnd.uniform(0.04, 0.11) * H
    for ring, (z, s) in enumerate(((z0, 1.0), (0.0, 1.0), (0.45 * H, 0.97), (0.82 * H, 0.86), (H, top + 0.07))):
        if ring == 1 and z0 >= -0.01: continue
        k = n if ring < 4 else n - 1
        off = rnd.uniform(0, 2 * math.pi); f = max(z, 0.0) / H
        for i in range(k):
            a = off + 2 * math.pi * i / k + rnd.uniform(-0.22, 0.22)
            rr = s * rnd.uniform(0.9, 1.05)
            x, y = ax * rr * math.cos(a), ay * rr * math.sin(a)
            zz = z + (tilt[0] * x + tilt[1] * y + rnd.uniform(-0.08, 0.08) if ring == 4 else (rnd.uniform(-0.06, 0.06) * H if ring in (2, 3) else 0.0))
            x += lean * f * math.cos(la); y += lean * f * math.sin(la)
            pts.append(Vector((c[0] + x * cy - y * sy, c[1] + x * sy + y * cy, zz)))
    hull_into(bm, pts, name, guard)
# (name, tone 1/2, centre, foot z, top z, half sizes x/y, top size, tilt, yaw) - the west side is -x; unequal on purpose. The stones by the
# cleft are centred close enough that their upper rings reach into it: keep_out then stands their inner faces up straight at the water
STONES = [
    # the two guardian stones either side of the fall (their feet in the canal bed)
    ("waki_w",   1, (-3.55, 0.30), FOOT,   5.3, 1.95, 2.05, 0.52, (0.10, 0.00),   8),
    ("waki_e",   2, (3.40, 0.55),  FOOT,   4.5, 1.85, 1.95, 0.56, (-0.10, 0.03), -12),
    # lining the chute, stepping up to the spring
    ("chute_w1", 2, (-3.10, 4.40), FOOT,   5.6, 2.10, 2.20, 0.58, (0.08, 0.04),  -6),
    ("chute_w2", 1, (-3.00, 8.10), GROUND, 6.7, 1.95, 2.00, 0.56, (0.08, -0.02), 10),
    ("chute_e1", 1, (3.05, 4.20),  FOOT,   5.1, 2.10, 2.10, 0.58, (-0.08, 0.05),  5),
    ("chute_e2", 2, (2.95, 7.90),  GROUND, 6.2, 1.95, 2.05, 0.56, (-0.08, 0.02), -8),
    # the rise behind on the lawn: lower and lower outward and backward
    ("rise_w1",  1, (-6.70, 5.50), FOOT,   4.0, 2.25, 2.30, 0.52, (0.10, 0.0),   14),
    ("rise_w2",  2, (-6.80, 9.40), GROUND, 4.2, 2.45, 2.30, 0.52, (0.08, -0.06), -10),
    ("rise_w3",  2, (-3.90, 13.4), GROUND, 3.4, 2.55, 2.10, 0.50, (0.05, -0.12),  20),
    ("rise_w4",  1, (-9.40, 7.60), GROUND, 2.0, 1.60, 1.90, 0.50, (0.12, 0.0),   -18),
    ("rise_w5",  1, (-7.40, 13.0), GROUND, 1.8, 2.00, 1.85, 0.50, (0.08, -0.08),  30),
    ("rise_e1",  2, (6.50, 5.10),  FOOT,   3.6, 2.15, 2.20, 0.52, (-0.10, 0.0),  -16),
    ("rise_e2",  1, (6.80, 9.10),  GROUND, 3.8, 2.35, 2.35, 0.52, (-0.08, -0.05), 12),
    ("rise_e3",  1, (3.70, 13.30), GROUND, 3.1, 2.45, 2.05, 0.50, (-0.05, -0.12), -24),
    ("rise_e4",  2, (9.30, 6.70),  GROUND, 1.7, 1.50, 1.80, 0.50, (-0.12, 0.0),   22),
    ("rise_e5",  2, (7.80, 12.40), GROUND, 1.5, 1.80, 1.75, 0.50, (-0.08, -0.08), -28),
    ("rise_back",1, (0.30, 15.40), GROUND, 1.9, 2.60, 1.55, 0.52, (0.0, -0.12),    6),
    ("low_w",    2, (-10.0, 11.0), GROUND, 0.9, 1.30, 1.20, 0.55, (0.0, 0.0),    40),
    ("low_e",    1, (10.1, 10.2),  GROUND, 0.8, 1.20, 1.10, 0.55, (0.0, 0.0),   -35),
    ("low_back", 2, (-1.6, 17.3),  GROUND, 0.9, 1.40, 1.00, 0.55, (0.0, 0.0),    15),
    # filling where WallS2 / WallS3 stood (y 0..4.6) between the guardians and the wall ends
    ("gap_w",    2, (-6.20, 1.90), FOOT,   3.4, 1.80, 1.90, 0.55, (0.06, 0.0),   -4),
    ("gap_e",    1, (6.00, 2.00),  FOOT,   3.0, 1.70, 1.90, 0.55, (-0.06, 0.0),   6),
    # the wall ends: swallow WallS1 / WallS4's cut ends at x -+8 (stonework and coping, y -0.3..4.3), stop by x -+10
    ("end_w1",   1, (-8.05, 0.45), FOOT,   2.9, 1.70, 2.05, 0.58, (0.08, 0.0),   0),
    ("end_w2",   2, (-8.25, 3.50), FOOT,   3.3, 1.65, 2.05, 0.58, (0.08, 0.04),  0),
    ("end_e1",   2, (8.10, 0.50),  FOOT,   2.8, 1.70, 2.05, 0.58, (-0.08, 0.0),  0),
    ("end_e2",   1, (8.20, 3.45),  FOOT,   3.1, 1.65, 2.05, 0.58, (-0.08, 0.04), 0),
    # in the water at the foot, clear of the falling sheet and the foam
    ("front_w",  1, (-6.00, -1.05), FOOT,  2.5, 1.60, 1.50, 0.55, (0.06, 0.0),  10),
    ("front_e",  2, (5.85, -0.85), FOOT,   2.2, 1.50, 1.45, 0.55, (-0.06, 0.0), -14),
    ("sute_w",   2, (-4.90, -3.05), FOOT,  1.75, 1.05, 0.85, 0.55, (0.0, 0.0),   25),
    ("sute_e",   1, (6.30, -2.65), FOOT,   1.60, 0.95, 0.85, 0.55, (0.0, 0.0),  -30),
]
def build():
    r1, r2, wa, fo = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    for (name, tone, c, z0, z1, ax, ay, top, tilt, yaw) in STONES:
        stone(r1 if tone == 1 else r2, name, c, z0, z1, ax, ay, top=top, tilt=tilt, yaw=yaw)
    # the water-fall stone: a straight lip at 3.15 the water leaves from, its face set back under the sheet (bottom further back)
    lip = []
    for s in (-1, 1):
        lip += [Vector((s * 2.05, -0.35, 3.15)), Vector((s * 2.25, -0.15, 1.2)), Vector((s * 2.35, 0.05, FOOT)),
                Vector((s * 2.25, 3.25, 3.15)), Vector((s * 2.40, 3.35, FOOT))]
    hull_into(r2, lip, "mizuochi")
    # a stone core across the old WallS2 / S3 footprint, set 0.3 back from the water face and under the coping height: the crevices
    # between the stones show stone, never a hole
    core = [Vector((sx * 8.3, y, z)) for sx in (-1, 1) for y in (0.3, 4.7) for z in (FOOT, 1.85)]
    core += [Vector((x, y, 1.85 + rnd.uniform(-0.1, 0.05))) for x in (-5.0, -2.5, 0.0, 2.5, 5.0) for y in (0.35, 4.65)]
    hull_into(r2, core, "core", guard=False)
    # the back of the cleft: a face straight up just behind where the water starts, the back sloping down to the lawn
    spring = []
    for sx in (-1, 1):
        spring += [Vector((sx * 2.75, 10.15, GROUND)), Vector((sx * 2.6, 10.15, 6.95)), Vector((sx * 2.9, 12.2, 5.9)), Vector((sx * 2.8, 14.3, 2.6)),
                   Vector((sx * 2.7, 14.6, GROUND))]
    spring += [Vector((rnd.uniform(-2.4, 2.4), rnd.uniform(12.6, 13.9), rnd.uniform(3.4, 5.6))) for _ in range(5)]
    hull_into(r1, spring, "spring", guard=False)
    stone(r2, "spring_bw", (-2.3, 13.7), GROUND, 4.3, 1.6, 1.5, top=0.55, tilt=(0.06, -0.1), yaw=18, guard=False)
    stone(r1, "spring_be", (2.5, 13.9), GROUND, 3.7, 1.5, 1.45, top=0.55, tilt=(-0.06, -0.1), yaw=-12, guard=False)
    # the lintel over the spring: the water comes out from under it (its front underside 0.5 over the water)
    lint = []
    for sx in (-1, 1):
        lint += [Vector((sx * 3.1, 9.25, 6.9)), Vector((sx * 2.9, 9.45, 7.95)), Vector((sx * 3.3, 12.4, 6.5)), Vector((sx * 3.0, 12.0, 7.6))]
    lint += [Vector((0.4, 10.6, 8.3)), Vector((-0.9, 11.3, 8.05)), Vector((1.8, 9.6, 7.75)), Vector((-2.2, 11.9, 7.5)), Vector((3.5, 10.8, 7.2))]
    hull_into(r2, lint, "lintel", guard=False)
    # the chute: r2's faceted trough under the water from the spring to the lip stone, now solid down to the ground
    secs = []
    for y in [p[0] for p in PATH if p[0] >= 0.4]:
        f = chute_floor(y); h = CH + 0.5
        secs.append([Vector((-h, y, GROUND)), Vector((h, y, GROUND)), Vector((h, y, f + 0.3)), Vector((CH * 0.8, y, f)), Vector((-CH * 0.8, y, f)), Vector((-h, y, f + 0.3))])
    rings = [[r2.verts.new(p) for p in s] for s in secs]
    for a, b in zip(rings, rings[1:]):
        for i in range(len(a)):
            j = (i + 1) % len(a); r2.faces.new([a[i], a[j], b[j], b[i]])
    r2.faces.new(list(reversed(rings[0]))); r2.faces.new(rings[-1])
    # the water: r2's ribbon
    N = 6; top, bot = [], []
    for k, (y, z) in enumerate(PATH):
        h = HALF[k]; rt, rb = [], []
        for i in range(N + 1):
            x = -h + 2 * h * i / N
            dz = 0.06 * math.sin(i * 1.7 + k * 1.3) if 0 < i < N else -0.04
            if z < 3.3:
                rt.append(wa.verts.new((x, y + dz, z))); rb.append(wa.verts.new((x, y + dz + 0.1, z)))
            else:
                rt.append(wa.verts.new((x, y, z + dz))); rb.append(wa.verts.new((x, y, z + dz - 0.1)))
        top.append(rt); bot.append(rb)
    for k in range(len(PATH) - 1):
        for i in range(N):
            wa.faces.new([top[k][i], top[k][i + 1], top[k + 1][i + 1], top[k + 1][i]])
            wa.faces.new([bot[k + 1][i], bot[k + 1][i + 1], bot[k][i + 1], bot[k][i]])
        wa.faces.new([top[k][0], top[k + 1][0], bot[k + 1][0], bot[k][0]])
        wa.faces.new([bot[k][N], bot[k + 1][N], top[k + 1][N], top[k][N]])
    # the foam: r2's
    res = bmesh.ops.create_circle(fo, cap_ends=True, segments=16, radius=1.0)
    for v in res["verts"]:
        a = math.atan2(v.co.y, v.co.x); w = 1.0 + 0.2 * math.sin(5 * a + 0.7) + 0.1 * math.sin(9 * a)
        v.co = Vector((v.co.x * 2.6 * w, -2.6 + v.co.y * 1.3 * w, WATER + 0.03))
    ext = bmesh.ops.extrude_face_region(fo, geom=[f for f in fo.faces])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]: v.co.z += 0.04
    for (x, y, r) in ((-1.0, -1.9, 0.42), (1.0, -2.0, 0.45), (0.0, -1.7, 0.4), (-1.9, -2.8, 0.3), (1.8, -3.0, 0.32)):
        r2b = bmesh.ops.create_icosphere(fo, subdivisions=1, radius=r)
        for v in r2b["verts"]: v.co.z *= 0.35; v.co += Vector((x, y, WATER + 0.05))
    return [obj_from_bm("Fall_Rock", r1), obj_from_bm("Fall_Rock2", r2), obj_from_bm("Fall_Water", wa), obj_from_bm("Fall_Foam", fo)]
def inside(p, planes, eps=0.02): return all(n.dot(p - c) <= -eps for (n, c) in planes)
def coverage():
    """every corner of S1 / S4's cut ends (stonework, coping) must sit inside a stone; nothing but the water in the cleft"""
    bad = []
    for sx in (-1, 1):
        for y in (-0.32, 0.5, 1.5, 2.5, 3.5, 4.32):
            for z in (-1.15, 0.0, 1.0, 1.65, 2.13):
                if z == -1.15 and not (0 <= y <= 4): continue
                p = Vector((sx * 8.0, y, z))
                if not any(inside(p, pl) for _, pl in HULLS): bad.append((round(p.x, 2), y, z))
    for x10 in range(-80, 81, 5):                                         # the old WallS2 / S3 footprint at the water line and the lawn
        x = x10 / 10
        if abs(x) < CH + 0.5: continue                                    # (the cleft: the lip stone and the trough fill it)
        for y10 in range(0, 47, 5):
            for z in (0.05, 1.35):
                p = Vector((x, y10 / 10, z))
                if not any(inside(p, pl) for _, pl in HULLS): bad.append((x, y10 / 10, z))
    clash = []
    for k, (y, z) in enumerate(PATH):
        for x in (-HALF[k] + 0.1, 0.0, HALF[k] - 0.1):
            p = Vector((x, y, z + 0.08))
            for name, pl in HULLS:
                if inside(p, pl, eps=0.0): clash.append((name, round(x, 2), y, z))
    return bad, clash
def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
def import_piece(path, at, rot_deg, scene_objs):
    """a kit FBX from out3/ placed as a stand-in: rotated about z, then moved to `at` (Blender axes)"""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before]
    M = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(rot_deg), 4, "Z")
    for o in new:
        if o.parent is None: o.matrix_world = M @ o.matrix_world
    scene_objs += new
    return new
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = build()
    bad, clash = coverage()
    log(f"coverage: {len(bad)} wall-end corners / old-wall footprint points NOT inside a stone {bad[:12]}; {len(clash)} water points inside a stone {clash[:12]}")
    export(objs, os.path.join(OUT, "canal_falls3.fbx"))
    log(f"canal_falls3.fbx: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris; " + ", ".join(f"{o.name} {tris(o)}" for o in objs))
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]   # Blender (x, y, z) -> Roblox (x, y up, z)
    info = {}
    for o in objs:
        q = [rb(o.matrix_world @ v.co) for v in o.data.vertices]
        info["canal_falls3/" + o.name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)]}
    allq = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
    info["canal_falls3"] = {"min": [min(a[i] for a in allq) for i in range(3)], "max": [max(a[i] for a in allq) for i in range(3)]}
    info["beams"] = {"chute_top": rb((0, PATH[0][0], PATH[0][1] + 0.12)), "lip": rb((0, PATH[6][0], PATH[6][1] + 0.12)),
                     "foot": rb((0, PATH[-1][0] - 0.1, WATER + 0.05)), "mist": rb((0, -2.2, WATER + 0.3))}
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps(info))
    emp = bpy.data.objects.new("canal_falls3", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
    export([emp] + objs, os.path.join(OUT, "japan_falls3_kit.fbx"))
    log("FBX_DONE")
    if os.environ.get("GARDEN_NO_RENDER"): raise SystemExit
    # previews: the real wall kit (S1, S4 and the side walls' south ends) around the stones, the water, the lawn
    sc = bpy.context.scene
    def slab(name, c, s, col):
        bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.active_object; o.name = name; o.scale = s
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(col[0]), lin(col[1]), lin(col[2]), 1)
        o.data.materials.append(m); return o
    stand = []
    K3 = os.path.join(D, "out3")
    import_piece(os.path.join(K3, "canal_wall_b.fbx"), (-12, 0, 0), -90, stand)          # WallS1 (x -16..-8)
    import_piece(os.path.join(K3, "canal_wall.fbx"), (12, 0, 0), -90, stand)            # WallS4 (x 8..16)
    for k, y in enumerate((-0.2, -8.2, -16.2, -24.2, -32.2)):                            # the side walls from the south end (y 3.8) north
        import_piece(os.path.join(K3, "canal_wall.fbx" if k % 2 else "canal_wall_b.fbx"), (-12.5, y, 0), 0, stand)
        import_piece(os.path.join(K3, "canal_wall_b.fbx" if k % 2 else "canal_wall.fbx"), (12.5, y, 0), 180, stand)
    slab("LawnBack", (0, 30, -0.05), (140, 52, 0.1), (0.36, 0.62, 0.30))
    for sx in (-1, 1): slab("LawnSide", (sx * 44.75, -26, -0.05), (63.5, 60, 0.1), (0.36, 0.62, 0.30))
    slab("Bed", (0, -26, BED - 0.05), (25, 60, 0.1), (0.20, 0.22, 0.23))
    w = slab("Water", (0, -26, WATER - 0.01), (25, 60, 0.02), (0.16, 0.45, 0.52))
    wm = w.data.materials[0].node_tree.nodes["Principled BSDF"]; wm.inputs["Alpha"].default_value = 0.75; wm.inputs["Roughness"].default_value = 0.15
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 640
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.9
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(45), math.radians(10), math.radians(-35)); sun.data.energy = 3.2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 28
    def shot(fn, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    shot("prev_falls3_from_canal.png", (0, -20, 5.0), (0, 4, 3.0))
    shot("prev_falls3_from_lawn_west.png", (-24, -4, 3.2), (0, 3, 2.4))                    # about where her picture was taken
    shot("prev_falls3_three_quarter.png", (-14, -15, 8), (0, 3, 2.5))
    shot("prev_falls3_from_behind.png", (12, 26, 7), (0, 4, 3))
    log("RENDER_DONE")
except SystemExit:
    pass
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
