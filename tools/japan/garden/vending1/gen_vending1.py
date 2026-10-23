"""Japan drinks vending machine kit (Oct 22 2026). Shannon: the blue box by Lantern Street station "is floating and it is way too
basic, it needs to look more realistic with more details and sit on the ground" -> a real jidouhanbaiki, stylised like France/Porto.
Blender meshes only, one mesh per colour (the installer colours them); the words go on in Studio as SurfaceGuis (nothing uploaded).
Local frame: x across (left -> right seen from the front), y up, z back; the FRONT faces -z. Ground line y 0.
  vending_machine  4.0 wide x 6.84 tall x 2.6 deep cabinet on a concrete pad (pad -0.30..0.10, sunk into the lawn):
                   lit display window (3 rows behind glass: 7 cans, 6 PET bottles, 7 hot drinks with orange caps), a price strip
                   (blue = cold, red = hot) and a push button under every drink, header panel (VM_Header: the name goes on in Studio),
                   take-out drawer with a smoked flap (VM_Flap = the FRONT marker), payment panel (LED, coin slot, note slot with a
                   green lit edge, IC card pad, coin-return lever + cup), a wave graphic, white side swooshes, kick plate, feet.
  recycle_bin      the can/bottle bin that stands beside every machine: 1.5 wide x 2.75 tall x 1.2, two round holes, a label plate
                   (BIN_Label: the words go on in Studio), blue lid and kick.
Writes vending1/out/japan_kit37_vending1.fbx (Empties vending_machine, recycle_bin), pieces.json, gen_log.txt."""
import bpy, bmesh, math, os, json, traceback
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out")
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "gen_log.txt")
def log(m): open(LOG, "a", encoding="utf-8").write(str(m) + "\n"); print(m)
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
COL = {
    # cabinet
    "VM_Body": (0.16, 0.36, 0.66), "VM_Frame": (0.93, 0.94, 0.95), "VM_Header": (0.97, 0.97, 0.98), "VM_Backlight": (0.98, 0.98, 0.97),
    "VM_Glass": (0.80, 0.90, 0.95), "VM_Shelf": (0.84, 0.85, 0.87), "VM_StripBlue": (0.15, 0.38, 0.75), "VM_StripRed": (0.80, 0.15, 0.13),
    "VM_PriceTag": (0.98, 0.98, 0.95), "VM_Button": (0.62, 0.75, 0.86), "VM_Kick": (0.25, 0.26, 0.28), "VM_Pad": (0.62, 0.61, 0.58),
    "VM_PortDark": (0.08, 0.08, 0.09), "VM_Flap": (0.22, 0.25, 0.28), "VM_Chrome": (0.75, 0.77, 0.80), "VM_Trim": (0.55, 0.57, 0.60),
    "VM_LED": (0.06, 0.06, 0.07), "VM_LEDDigits": (0.90, 0.15, 0.10), "VM_SlotGreen": (0.20, 0.85, 0.40), "VM_ICPad": (0.45, 0.72, 0.92),
    "VM_Graphic": (0.35, 0.65, 0.90), "VM_GraphicWave": (0.97, 0.98, 1.00), "VM_SideStripe": (0.97, 0.98, 1.00),
    # drinks
    "D_Silver": (0.80, 0.81, 0.83), "D_Brown": (0.30, 0.18, 0.11), "D_Gold": (0.82, 0.63, 0.26), "D_Red": (0.80, 0.12, 0.11),
    "D_Orange": (0.97, 0.55, 0.12), "D_Purple": (0.45, 0.22, 0.55), "D_Yellow": (0.96, 0.83, 0.25), "D_Blue": (0.18, 0.45, 0.85),
    "D_White": (0.96, 0.96, 0.94), "D_Green": (0.22, 0.52, 0.24), "D_Tea": (0.64, 0.70, 0.30), "D_Amber": (0.78, 0.50, 0.18),
    "D_Water": (0.80, 0.91, 0.97), "D_Cream": (0.90, 0.80, 0.62),
    # bin
    "BIN_Body": (0.94, 0.95, 0.96), "BIN_Lid": (0.16, 0.36, 0.66), "BIN_Hole": (0.07, 0.07, 0.08), "BIN_Label": (0.99, 0.99, 0.98),
}
UV_STUDS = 6.0
def material(key):
    m = bpy.data.materials.get(key)
    if m: return m
    m = bpy.data.materials.new(key); m.use_nodes = True
    c = COL[key]; bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1); bs.inputs["Roughness"].default_value = 0.6
    m.diffuse_color = (lin(c[0]), lin(c[1]), lin(c[2]), 1)
    return m
def P(x, y, z): return (x, -z, y)                                   # local (x, y up, z) -> Blender
BMS = {}                                                            # key -> bmesh being built (one mesh per colour per piece)
def bm_for(key):
    if key not in BMS: BMS[key] = bmesh.new()
    return BMS[key]
def hull(key, pts):
    bm = bm_for(key)
    vs = [bm.verts.new(P(*p)) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
def box(key, x0, x1, y0, y1, z0, z1): hull(key, [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)])
def cbox(key, x0, x1, y0, y1, z0, z1, c):                           # a box with every edge chamfered by c
    pts = []
    for (ax, ay, az) in ((c, 0, c), (0, c, c), (c, c, 0)):
        pts += [(x, y, z) for x in (x0 + ax, x1 - ax) for y in (y0 + ay, y1 - ay) for z in (z0 + az, z1 - az)]
    hull(key, pts)
def ring_y(cx, cz, r, y, seg): return [(cx + r * math.cos(2 * math.pi * i / seg), y, cz + r * math.sin(2 * math.pi * i / seg)) for i in range(seg)]
def frustum_y(key, cx, cz, r0, y0, r1, y1, seg=16): hull(key, ring_y(cx, cz, r0, y0, seg) + ring_y(cx, cz, r1, y1, seg))
def cyl_y(key, cx, cz, r, y0, y1, seg=16): frustum_y(key, cx, cz, r, y0, r, y1, seg)
def disc_z(key, cx, cy, r, z0, z1, seg=24):                          # a disc facing the front (axis along z)
    pts = []
    for z in (z0, z1):
        pts += [(cx + r * math.cos(2 * math.pi * i / seg), cy + r * math.sin(2 * math.pi * i / seg), z) for i in range(seg)]
    hull(key, pts)
def flush(prefix_objs):
    objs = []
    for key, bm in BMS.items():
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0003)
        bm.normal_update()
        uv = bm.loops.layers.uv.new("UVMap")
        for f in bm.faces:
            n = f.normal; ax = max(range(3), key=lambda i: abs(n[i]))
            for l in f.loops:
                c = l.vert.co
                u, v = ((c.y, c.z), (c.x, c.z), (c.x, c.y))[ax]
                l[uv].uv = (u / UV_STUDS, v / UV_STUDS)
        me = bpy.data.meshes.new(key); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(key, me); bpy.context.scene.collection.objects.link(o)
        me.materials.append(material(key))
        smooth = key.startswith("D_") or key in ("BIN_Hole",)
        for p in me.polygons: p.use_smooth = smooth
        objs.append(o)
    BMS.clear()
    return objs
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)

# ---------------------------------------------------------------- the machine
W = 2.0                      # half width
ZF, ZB = 0.55, 2.60          # cabinet front plane (behind the frame) and back
Y0 = 0.35                    # cabinet bottom (feet + kick below)
WIN = (-1.82, 1.82, 2.98, 5.98)
ZC = 0.30                    # drinks' centre depth inside the window
def can(x, yb, body, band, h=0.52, r=0.14):
    frustum_y("D_Silver", x, ZC, r * 0.86, yb, r, yb + 0.03)
    cyl_y(body, x, ZC, r, yb + 0.03, yb + h - 0.05)
    frustum_y("D_Silver", x, ZC, r, yb + h - 0.05, r * 0.80, yb + h)
    if band: cyl_y(band, x, ZC, r + 0.004, yb + h * 0.36, yb + h * 0.58)
def pet(x, yb, liquid, label, cap, h=0.72, r=0.15):
    frustum_y(liquid, x, ZC, r * 0.88, yb, r, yb + 0.03)
    cyl_y(liquid, x, ZC, r, yb + 0.03, yb + h * 0.61)
    cyl_y(label, x, ZC, r + 0.006, yb + h * 0.17, yb + h * 0.50)
    frustum_y(liquid, x, ZC, r, yb + h * 0.61, r * 0.42, yb + h * 0.81)
    cyl_y(liquid, x, ZC, r * 0.40, yb + h * 0.81, yb + h * 0.87)
    cyl_y(cap, x, ZC, r * 0.47, yb + h * 0.87, yb + h, seg=14)
def row(yb, items, hot):
    n = len(items)
    pitch = (WIN[1] - WIN[0]) / n
    # the shelf the drinks stand on + its front lip that carries the price strips and buttons
    box("VM_Shelf", WIN[0], WIN[1], yb - 0.05, yb, 0.06, ZF)
    box("VM_Shelf", WIN[0], WIN[1], yb - 0.36, yb, 0.04, 0.10)
    for i, it in enumerate(items):
        x = WIN[0] + pitch * (i + 0.5)
        it(x, yb)
        box("VM_StripRed" if hot else "VM_StripBlue", x - 0.18, x + 0.18, yb - 0.17, yb - 0.04, 0.025, 0.04)
        box("VM_PriceTag", x - 0.12, x + 0.12, yb - 0.145, yb - 0.065, 0.018, 0.025)
        cbox("VM_Button", x - 0.13, x + 0.13, yb - 0.31, yb - 0.215, 0.012, 0.04, 0.012)
def build_machine():
    # concrete pad, feet, kick plate
    cbox("VM_Pad", -2.40, 2.40, -0.30, 0.10, -0.45, 3.00, 0.05)
    for x in (-1.75, 1.75):
        for z in (0.35, 2.35): box("VM_Kick", x - 0.12, x + 0.12, 0.10, 0.24, z - 0.12, z + 0.12)
    box("VM_Kick", -1.95, 1.95, 0.22, Y0, 0.10, 2.50)
    # cabinet: blue body behind the white front frame, a lip on top
    cbox("VM_Body", -W, W, Y0, 6.72, ZF - 0.02, ZB, 0.07)
    cbox("VM_Body", -W - 0.06, W + 0.06, 6.72, 6.84, -0.10, ZB + 0.06, 0.03)
    # white front frame: lower panel, sill, pillars, top rail
    box("VM_Frame", -W, W, Y0, 2.80, 0.0, ZF)
    cbox("VM_Frame", -W, W, 2.80, WIN[2], -0.05, ZF, 0.02)
    box("VM_Frame", -W, WIN[0], WIN[2], WIN[3], -0.02, ZF)
    box("VM_Frame", WIN[1], W, WIN[2], WIN[3], -0.02, ZF)
    box("VM_Frame", -W, W, WIN[3], 6.12, -0.02, ZF)
    cbox("VM_Header", -W, W, 6.12, 6.72, -0.07, ZF, 0.025)
    # the display: backlight wall, glass
    box("VM_Backlight", WIN[0], WIN[1], WIN[2], WIN[3], ZF - 0.05, ZF - 0.03)   # just in front of the blue cabinet face
    box("VM_Glass", WIN[0], WIN[1], WIN[2], WIN[3], -0.005, 0.01)
    # drinks: top row cans, middle row 500 ml bottles, bottom row hot (red strips, orange caps)
    row(5.32, [lambda x, y, a=a: can(x, y, *a) for a in (("D_Brown", "D_Gold"), ("D_Gold", "D_Brown"), ("D_Red", "D_White"),
               ("D_Orange", "D_White"), ("D_Purple", "D_White"), ("D_Yellow", "D_Green"), ("D_Blue", "D_White"))], False)
    row(4.32, [lambda x, y, a=a: pet(x, y, *a) for a in (("D_Tea", "D_Green", "D_Green"), ("D_Brown", "D_Red", "D_White"),
               ("D_Water", "D_Blue", "D_Blue"), ("D_Amber", "D_Yellow", "D_White"), ("D_Water", "D_White", "D_Blue"),
               ("D_Amber", "D_Red", "D_White"))], False)
    hot = [lambda x, y, a=a: can(x, y, *a, h=0.44, r=0.13) for a in (("D_Brown", "D_Gold"), ("D_White", "D_Brown"), ("D_Gold", "D_Red"))]
    hot += [lambda x, y, a=a: pet(x, y, *a, h=0.52, r=0.13) for a in (("D_Tea", "D_Green", "D_Orange"), ("D_Amber", "D_Red", "D_Orange"))]
    hot += [lambda x, y, a=a: can(x, y, *a, h=0.44, r=0.13) for a in (("D_Brown", "D_White"),)]
    hot += [lambda x, y, a=a: pet(x, y, *a, h=0.52, r=0.13) for a in (("D_Cream", "D_Brown", "D_Orange"),)]
    row(3.32, hot, True)
    # the lower front is drawn with x mirrored (mb/mc): seen from the front, local -x is the RIGHT hand, and the payment panel
    # belongs on the right as on real machines; the drawer and graphic on the left
    def mb(key, x0, x1, *r): box(key, -x1, -x0, *r)
    def mc(key, x0, x1, *r): cbox(key, -x1, -x0, *r)
    # take-out drawer: bezel, dark opening, smoked flap on a hinge bar (VM_Flap is the FRONT marker for the installer)
    mc("VM_Trim", -1.78, 0.48, 0.52, 1.58, -0.035, 0.0, 0.02)
    mb("VM_PortDark", -1.70, 0.40, 0.60, 1.50, -0.045, -0.035)
    mb("VM_Flap", -1.62, 0.32, 0.66, 1.42, -0.09, -0.05)
    cyl_hinge = [(-x, 1.46 + 0.035 * math.cos(a), -0.08 + 0.035 * math.sin(a)) for x in (-1.66, 0.36) for a in [2 * math.pi * i / 10 for i in range(10)]]
    hull("VM_Chrome", cyl_hinge)
    # wave graphic above the drawer
    mb("VM_Graphic", -1.78, 0.48, 1.75, 2.70, -0.02, 0.0)
    for k, (ya, yb) in enumerate(((1.80, 2.10), (2.05, 2.40), (2.30, 2.65))):
        hull("VM_GraphicWave", [(-x, y, z) for (x, y) in ((-1.78, ya), (-1.78, ya + 0.08), (0.48, yb), (0.48, yb + 0.08)) for z in (-0.03, -0.02)])
    # payment panel
    mc("VM_Chrome", 0.70, 1.82, 1.05, 2.72, -0.08, 0.0, 0.03)
    mb("VM_LED", 0.86, 1.66, 2.38, 2.60, -0.095, -0.08)
    mb("VM_LEDDigits", 1.06, 1.56, 2.44, 2.54, -0.10, -0.095)
    mc("VM_ICPad", 0.80, 1.20, 1.96, 2.30, -0.11, -0.08, 0.04)
    mb("VM_Trim", 1.29, 1.48, 1.93, 2.29, -0.09, -0.08)          # coin slot bezel
    mb("VM_PortDark", 1.355, 1.415, 1.98, 2.24, -0.095, -0.09)
    mc("VM_Trim", 1.56, 1.72, 1.98, 2.26, -0.13, -0.08, 0.02)   # coin-return lever
    mb("VM_Trim", 0.80, 1.72, 1.60, 1.84, -0.09, -0.08)          # note slot bezel
    mb("VM_PortDark", 0.86, 1.66, 1.70, 1.76, -0.095, -0.09)
    mb("VM_SlotGreen", 0.86, 1.66, 1.645, 1.675, -0.095, -0.09)
    mb("VM_Trim", 0.98, 1.62, 1.08, 1.46, -0.09, -0.08)          # coin-return cup
    mb("VM_PortDark", 1.05, 1.55, 1.13, 1.40, -0.095, -0.09)
    # white swooshes on both sides
    for sx, s0, s1 in ((W, W, W + 0.015), (-W, -W - 0.015, -W)):
        hull("VM_SideStripe", [(x, y, z) for (y, z) in ((1.0, 2.30), (1.6, 2.30), (5.6, 0.80), (6.2, 0.80)) for x in (s0, s1)])
    return flush(None)

# ---------------------------------------------------------------- the bin
def build_bin():
    cbox("BIN_Body", -0.75, 0.75, 0.0, 2.50, 0.0, 1.20, 0.06)
    cbox("BIN_Lid", -0.78, 0.78, 2.50, 2.75, -0.03, 1.23, 0.05)
    box("BIN_Lid", -0.76, 0.76, -0.02, 0.16, -0.01, 1.21)
    for x in (-0.36, 0.36):
        disc_z("BIN_Lid", x, 2.05, 0.27, -0.015, 0.0)
        disc_z("BIN_Hole", x, 2.05, 0.21, -0.025, -0.015)
    box("BIN_Label", -0.62, 0.62, 1.05, 1.62, -0.02, 0.0)
    return flush(None)

def export(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"})
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    machine = build_machine()
    binobjs = build_bin()
    pieces = {"vending_machine": machine, "recycle_bin": binobjs}
    def rb(p): return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    info = {}
    for name, objs in pieces.items():
        q = [rb(o.matrix_world @ v.co) for o in objs for v in o.data.vertices]
        info[name] = {"min": [min(a[i] for a in q) for i in range(3)], "max": [max(a[i] for a in q) for i in range(3)],
                      "parts": {o.name: {"tris": tris(o)} for o in objs}}
        big = max(objs, key=tris)
        log(f"{name}: {len(objs)} meshes, {sum(tris(o) for o in objs)} tris (largest {big.name} {tris(big)})")
    json.dump(info, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    log("INFO " + json.dumps({k: {"min": v["min"], "max": v["max"]} for k, v in info.items()}))
    allobjs = []
    x = 0.0
    for name, objs in pieces.items():
        emp = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(emp)
        for o in objs:
            mw = o.matrix_world.copy(); o.parent = emp; o.matrix_world = mw
        emp.location.x = x; x += 10.0
        allobjs += [emp] + objs
    export(allobjs, os.path.join(OUT, "japan_kit37_vending1.fbx"))
    log("FBX_DONE")
except Exception:
    log(traceback.format_exc()); log("FBX_FAILED")
