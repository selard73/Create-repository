"""Lifeguard props for Rocco the Lifeguard (Porto Nocciola beach, Oct 4 2026, Shannon): a tall white wooden lifeguard
chair with a red/white umbrella and a ring buoy, and a red rescue rowboat with SALVATAGGIO on both sides.
Built in studs (1 Blender unit = 1 stud), front = -Y (the sea). Writes lifeguard_chair.fbx + rescue_boat.fbx (pieces named
for colouring in Studio) and preview renders with Rocco for scale.  Run: blender -b --python gen_lifeguard.py"""
import bpy, bmesh, math, os, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "gen_log.txt")
SQ_BLEND = r"C:\Users\slard\roblox-props\squirrels\lifeguard_squirrel\lifeguard_squirrel.blend"
def log(m): open(LOG, "a").write(str(m) + "\n")

COL = {  # sRGB 0..1 (converted to linear for the preview); the installer uses the same values in Studio
    "Chair_Wood": (0.94, 0.93, 0.89), "Umbrella_Red": (0.80, 0.13, 0.13), "Umbrella_White": (0.97, 0.97, 0.96),
    "Umbrella_Pole": (0.78, 0.78, 0.76), "Buoy_Red": (0.84, 0.16, 0.14), "Buoy_White": (0.97, 0.97, 0.96),
    "Boat_Hull": (0.78, 0.11, 0.11), "Boat_Trim": (0.97, 0.97, 0.96), "Boat_Wood": (0.62, 0.45, 0.28),
    "Boat_Text": (0.98, 0.98, 0.98),
}
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def material(name):
    m = bpy.data.materials.get(name)
    if m: return m
    m = bpy.data.materials.new(name); m.use_nodes = True
    c = COL[name]; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m

def obj_from_bm(name, bm, mat):
    me = bpy.data.meshes.new(name); bm.normal_update(); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(mat)); return o

def box(bm, p1, p2, t, t2=None):
    """square-ish beam from p1 to p2, thickness t (and t2 across)"""
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1; L = d.length; z = d.normalized()
    a = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0))
    x = a.cross(z).normalized(); y = z.cross(x)
    t2 = t2 or t
    vs = []
    for (sx, sy, sz) in [(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
        vs.append(bm.verts.new(p1 + x * (sx * t / 2) + y * (sy * t2 / 2) + z * (sz * L)))
    for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
        bm.faces.new([vs[i] for i in f])

def slab(bm, cx, cy, cz, sx, sy, sz):
    box(bm, (cx, cy, cz - sz / 2), (cx, cy, cz + sz / 2), sx, sy)

def cyl(bm, p1, p2, r, seg=10):
    p1, p2 = Vector(p1), Vector(p2); z = (p2 - p1).normalized()
    a = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0))
    x = a.cross(z).normalized(); y = z.cross(x)
    ring1 = [bm.verts.new(p1 + (x * math.cos(2*math.pi*i/seg) + y * math.sin(2*math.pi*i/seg)) * r) for i in range(seg)]
    ring2 = [bm.verts.new(v.co + (p2 - p1)) for v in ring1]
    for i in range(seg):
        j = (i + 1) % seg; bm.faces.new([ring1[i], ring1[j], ring2[j], ring2[i]])
    bm.faces.new(list(reversed(ring1))); bm.faces.new(ring2)

def build_chair():
    objs = []
    # ---- white wooden frame
    bm = bmesh.new()
    SEAT = 4.2; B0, B1 = 1.25, 0.95          # half footprint at the ground / at the seat
    corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    def leg_at(sx, sy, z):
        f = z / SEAT; h = B0 + (B1 - B0) * f; return Vector((sx * h, sy * h, z))
    for sx, sy in corners:
        box(bm, leg_at(sx, sy, 0), leg_at(sx, sy, SEAT), 0.24)
    for z in (1.4, 2.8):                     # side + back rails (front gets ladder rungs instead)
        for (a, b) in [((-1, -1), (-1, 1)), ((1, -1), (1, 1)), ((-1, 1), (1, 1))]:
            box(bm, leg_at(*a, z), leg_at(*b, z), 0.16)
    for sx in (-1, 1):                       # X braces on both sides
        box(bm, leg_at(sx, -1, 0.3), leg_at(sx, 1, 2.7), 0.12); box(bm, leg_at(sx, 1, 0.3), leg_at(sx, -1, 2.7), 0.12)
    box(bm, leg_at(-1, 1, 0.3), leg_at(1, 1, 2.7), 0.12); box(bm, leg_at(1, 1, 0.3), leg_at(-1, 1, 2.7), 0.12)
    z = 0.55
    while z < SEAT - 0.3:                    # ladder rungs on the front
        box(bm, leg_at(-1, -1, z), leg_at(1, -1, z), 0.13); z += 0.55
    slab(bm, 0, 0, SEAT + 0.08, 2.4, 2.4, 0.16)                       # seat platform
    slab(bm, 0, 0.1, SEAT + 0.42, 1.5, 1.0, 0.12)                     # seat bench
    for sx in (-1, 1):
        box(bm, (sx * 1.1, 1.1, SEAT + 0.16), (sx * 1.1, 1.1, SEAT + 1.55), 0.16)      # back posts
        box(bm, (sx * 1.1, -1.1, SEAT + 0.16), (sx * 1.1, -1.1, SEAT + 0.85), 0.14)    # front posts
        box(bm, (sx * 1.1, -1.2, SEAT + 0.85), (sx * 1.1, 1.18, SEAT + 0.85), 0.14, 0.2)  # armrests
    for zz in (SEAT + 0.75, SEAT + 1.1, SEAT + 1.45):
        box(bm, (-1.18, 1.1, zz), (1.18, 1.1, zz), 0.1, 0.22)           # back slats
    objs.append(obj_from_bm("Chair_Wood", bm, "Chair_Wood"))
    # ---- umbrella pole + canopy (8 alternating gores, double-sided) + finial
    TOP, RIM, RAD = 8.6, 7.75, 2.25
    bm = bmesh.new(); cyl(bm, (0, 1.22, SEAT + 0.2), (0, 1.22, TOP + 0.25), 0.07); cyl(bm, (0, 1.22, TOP + 0.25), (0, 1.22, TOP + 0.42), 0.13, 8)
    objs.append(obj_from_bm("Umbrella_Pole", bm, "Umbrella_Pole"))
    for colour, parity in (("Umbrella_Red", 0), ("Umbrella_White", 1)):
        bm = bmesh.new()
        for g in range(8):
            if g % 2 != parity: continue
            a0, a1 = 2 * math.pi * g / 8, 2 * math.pi * (g + 1) / 8
            tip = Vector((0, 1.22, TOP)); n = 4
            pts = [Vector((math.cos(a0 + (a1 - a0) * k / n) * RAD, 1.22 + math.sin(a0 + (a1 - a0) * k / n) * RAD, RIM)) for k in range(n + 1)]
            # slight droop between ribs reads as fabric
            for k in range(1, n): pts[k].z -= 0.12 * math.sin(math.pi * k / n)
            up = [bm.verts.new(tip)] + [bm.verts.new(p) for p in pts]
            dn = [bm.verts.new(tip - Vector((0, 0, 0.05)))] + [bm.verts.new(p - Vector((0, 0, 0.05))) for p in pts]
            for k in range(n):
                bm.faces.new([up[0], up[k + 1], up[k + 2]]); bm.faces.new([dn[0], dn[k + 2], dn[k + 1]])
                bm.faces.new([up[k + 1], dn[k + 1], dn[k + 2], up[k + 2]])
            bm.faces.new([up[0], dn[0], dn[1], up[1]]); bm.faces.new([up[0], up[n + 1], dn[n + 1], dn[0]])
        objs.append(obj_from_bm(colour, bm, colour))
    # ---- ring buoy hung on the left side (+X), four alternating quarters
    C = Vector((1.32, -0.1, 3.05)); R, r = 0.62, 0.16; SEG, TS = 24, 8
    for colour, parity in (("Buoy_Red", 0), ("Buoy_White", 1)):
        bm = bmesh.new()
        for q in range(4):
            if q % 2 != parity: continue
            rows = []
            for i in range(SEG // 4 + 1):
                a = 2 * math.pi * (q * SEG // 4 + i) / SEG
                cdir = Vector((0, math.cos(a), math.sin(a)))
                rows.append([bm.verts.new(C + cdir * (R + r * math.cos(2*math.pi*j/TS)) + Vector((r * math.sin(2*math.pi*j/TS), 0, 0))) for j in range(TS)])
            for i in range(len(rows) - 1):
                for j in range(TS):
                    k = (j + 1) % TS; bm.faces.new([rows[i][j], rows[i][k], rows[i + 1][k], rows[i + 1][j]])
            bm.faces.new(rows[0]); bm.faces.new(list(reversed(rows[-1])))
        objs.append(obj_from_bm(colour, bm, colour))
    return objs

# ---------- rowboat (built along X: stern -X, bow +X; bottom at z 0)
L, BEAM, DEP = 6.6, 2.5, 0.95
def half_w(u):
    if u < 0.38: return BEAM / 2 * (0.80 + 0.20 * math.sin(math.pi / 2 * u / 0.38))
    return BEAM / 2 * max(0.015, math.sqrt(max(0.0, 1 - ((u - 0.38) / 0.62) ** 2)))
def sheer(u): return DEP + 0.38 * max(0.0, (u - 0.55) / 0.45) ** 2
def keel(u): return 0.0 + 0.45 * max(0.0, (u - 0.62) / 0.38) ** 2
NSEC, NPT, PWR = 40, 16, 3.0
def sec_pt(u, k, shrink=0.0):
    a = math.pi * k / NPT - math.pi / 2               # -90 = port top .. 0 = keel .. 90 = starboard top
    s, c = math.sin(a), math.cos(a)
    w = max(0.005, half_w(u) - shrink); top = sheer(u); bot = keel(u) + shrink * 0.9
    y = w * math.copysign(abs(s) ** (2 / PWR), s)
    z = top - (top - bot) * abs(c) ** (2 / PWR)
    return Vector((-L / 2 + L * u, y, z))
def side_y(u, z, shrink=0.0):
    """y of the starboard outer surface at height z (bisection on k)"""
    lo, hi = NPT / 2, NPT
    for _ in range(30):
        mid = (lo + hi) / 2
        if sec_pt(u, mid, shrink).z < z: lo = mid
        else: hi = mid
    return sec_pt(u, (lo + hi) / 2, shrink).y

def build_boat():
    objs = []
    us = [i / NSEC for i in range(NSEC + 1)]
    bm = bmesh.new()
    outer = [[bm.verts.new(sec_pt(u, k)) for k in range(NPT + 1)] for u in us]
    inner = [[bm.verts.new(sec_pt(u, k, 0.1)) for k in range(NPT + 1)] for u in us]
    for i in range(NSEC):
        for k in range(NPT):
            bm.faces.new([outer[i][k], outer[i + 1][k], outer[i + 1][k + 1], outer[i][k + 1]])
            bm.faces.new([inner[i][k], inner[i][k + 1], inner[i + 1][k + 1], inner[i + 1][k]])
        for k in (0, NPT):                                    # gunwale tops
            bm.faces.new([outer[i][k], inner[i][k], inner[i + 1][k], outer[i + 1][k]])
    bm.faces.new(list(reversed(outer[0])))                    # solid transom: outside, inside, and its top edge
    bm.faces.new(inner[0])
    bm.faces.new([outer[0][0], outer[0][NPT], inner[0][NPT], inner[0][0]])
    for k in range(NPT):                                      # bow stem (sections almost meet there)
        bm.faces.new([outer[NSEC][k], outer[NSEC][k + 1], inner[NSEC][k + 1], inner[NSEC][k]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    objs.append(obj_from_bm("Boat_Hull", bm, "Boat_Hull"))
    # white band along the top of both sides (a thin skin just outside the hull)
    bm = bmesh.new()
    for side in (1, -1):
        rows = []
        for u in us:
            top = sheer(u)
            pts = []
            for zz in (top + 0.01, top - 0.18):
                y = side_y(u, zz) * side
                n = Vector((0, side, 0))
                pts.append((Vector((-L / 2 + L * u, y, zz)), n))
            rows.append([bm.verts.new(p + n * 0.012) for p, n in pts] + [bm.verts.new(p + n * 0.045) for p, n in pts])
        for i in range(len(rows) - 1):
            a, b = rows[i], rows[i + 1]
            for f in [(2, 3, 7, 6), (0, 2, 6, 4), (1, 0, 4, 5), (3, 1, 5, 7)]:   # outer, top, inner, bottom
                bm.faces.new([a[f[0]], a[f[1]], b[f[1]], b[f[0]]] if False else [a[f[0]], b[f[0]], b[f[1]], a[f[1]]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    objs.append(obj_from_bm("Boat_Trim", bm, "Boat_Trim"))
    # thwarts + oars
    bm = bmesh.new()
    for u in (0.3, 0.62):
        z = sheer(u) * 0.62; w = side_y(u, z, 0.1)
        slab(bm, -L / 2 + L * u, 0, z, 0.42, 2 * w, 0.09)
    for side in (1, -1):
        y = 0.32 * side; z0 = sheer(0.3) * 0.62 + 0.09
        cyl(bm, (-2.25, y, z0), (1.55, y, z0 + 0.02), 0.055, 8)
        slab(bm, 1.95, y, z0 + 0.02, 0.85, 0.3, 0.05)
    objs.append(obj_from_bm("Boat_Wood", bm, "Boat_Wood"))
    # SALVATAGGIO on both sides, wrapped onto the hull surface
    bpy.ops.object.text_add(); t = bpy.context.active_object
    t.data.body = "SALVATAGGIO"; t.data.size = 0.42; t.data.extrude = 0.012; t.data.align_x = "CENTER"; t.data.align_y = "CENTER"
    bpy.ops.object.convert(target="MESH"); tm = t.data
    ZC = DEP * 0.55; UC = 0.44
    bm = bmesh.new()
    src = [(v.co.x, v.co.y, v.co.z) for v in tm.vertices]
    for side in (1, -1):
        base = len(bm.verts); vmap = []
        for (tx, ty, tz) in src:
            bx = (-tx if side == 1 else tx) + (-L / 2 + L * UC)
            u = (bx + L / 2) / L; zz = ZC + ty
            y = side_y(u, zz) * side
            vmap.append(bm.verts.new(Vector((bx, y + side * (0.02 + (tz + 0.012) * 1.5), zz))))
        bm.verts.ensure_lookup_table()
        for p in tm.polygons:
            bm.faces.new([vmap[i] for i in p.vertices])
    bpy.data.objects.remove(t)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    objs.append(obj_from_bm("Boat_Text", bm, "Boat_Text"))
    return objs

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    chair = build_chair(); boat = build_boat()
    for o in chair + boat:
        log(f"{o.name} tris {sum(len(p.vertices) - 2 for p in o.data.polygons)} dims {tuple(round(v, 2) for v in o.dimensions)}")
    export(chair, os.path.join(D, "lifeguard_chair.fbx")); export(boat, os.path.join(D, "rescue_boat.fbx"))
    log("FBX_DONE")
    # ---------- preview layout: Rocco at the origin facing -Y, chair beside him, boat on the sand toward the sea
    CHAIR_AT, BOAT_AT, BOAT_ROT = Vector((2.6, -0.3, 0)), Vector((0.06, -13.2, 0)), math.radians(-61.8)   # v2: her boat spot (253.74,-726.55)
    for o in chair: o.location = CHAIR_AT
    for o in boat: o.location = BOAT_AT; o.rotation_euler = (0, 0, BOAT_ROT)
    with bpy.data.libraries.load(SQ_BLEND) as (src, dst): dst.objects = [n for n in src.objects]
    for o in dst.objects:
        if o is not None and o.type == "MESH": bpy.context.scene.collection.objects.link(o)
    sc = bpy.context.scene
    def plane(name, size, loc, rgb):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc); p = bpy.context.active_object; p.name = name
        m = bpy.data.materials.new(name); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (lin(rgb[0]), lin(rgb[1]), lin(rgb[2]), 1)
        p.data.materials.append(m)
    plane("Sand", 60, (0, 0, 0), (0.87, 0.79, 0.62))
    plane("Sea", 80, (0, -60, 0.02), (0.25, 0.55, 0.72))
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35)); sun.data.energy = 3.5
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.78), lin(0.92), 1); bg.inputs["Strength"].default_value = 1.0
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1200, 800
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 35
    def shot(name, loc, target):
        cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(D, name); bpy.ops.render.render(write_still=True); log(f"shot {name}")
    shot("prev_front.png", (9.0, -27.0, 7.0), (0.8, -5.5, 2.0))
    shot("prev_side.png", (-15.0, -8.0, 5.5), (0.5, -6.5, 1.8))
    shot("prev_boat.png", (-5.5, -20.5, 3.2), (0.3, -12.0, 0.8))
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
