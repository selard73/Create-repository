"""churchfix2 (Oct 23 2026) - new stained glass for the church's six side windows.
Shannon: churchfix1 (the VR flicker fix) "broke them": the windows turned opaque, "painted on", and there is a gap round the arch
top where you see out. Why: the old gold mesh is the WHOLE pane of every window (the blue and red sit on it), so making it opaque
hid the view; it is 0.1 narrower than the opening (a ring of sky all round, unseen while it was see-through) and churchfix1 slid it
0.05 sideways. The flicker itself: three transparent meshes stacked in every window, all with the same centre -> Roblox's sort flips.
New glass: ONE layer per window - gold border, blue field and red centre side by side, never one colour over another; the gold
reaches 0.1 into the plaster and the stone sill all round (no gap); a dark lead line (came) over each colour join, a closed solid
the two colours overlap inside (no hairline crack, nothing to sort). One mesh per colour per side wall (_PX / _NX = Roblox +x / -x)
so the far wall's glass always sorts behind the near wall's. Church_Glass_Ref = the ORIGINAL gold mesh (the windows + the rose,
which sits buried in the front gable): the installer lines the import up on it, then deletes it. The rose is left as it is.
Run (repo root): python croc/run_blender.py tools/japan/church/out_glass/gen_log.txt GLASS tools/japan/church/gen_church_glass.py"""
import os
_D = os.path.dirname(os.path.abspath(__file__))
os.environ["CHURCH_OUT"] = os.path.join(_D, "out_glass")
_src = open(os.path.join(_D, "gen_church.py"), encoding="utf-8").read()
exec(compile(_src.split("\ntry:\n")[0], os.path.join(_D, "gen_church.py"), "exec"))   # the church's helpers, sizes and build_shell

GT, CT, CW, OV = 0.02, 0.05, 0.035, 0.02     # glass half-thickness, came half-thickness, came half-width, colour overlap under a came
BW, BS, BSP = WIN_W - 0.5, WIN_SILL + 0.25, WIN_SPRING - 0.2   # the blue field, as before (width, bottom, springing)
RED = (-0.22, 0.22, WIN_SILL + 1.2, WIN_SILL + 1.88)          # the red centre, as before (y offsets from the window centre, z)
def rect(c, d):
    """the red centre grown by d (shrunk if d < 0), counter-clockwise seen from +x"""
    y0, y1, z0, z1 = c + RED[0] - d, c + RED[1] + d, RED[2] - d, RED[3] + d
    return [(y0, z0), (y1, z0), (y1, z1), (y0, z1)]
def area(p): return 0.5 * sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))
def caps(bm, tris_yz, x0, x1):
    """flat faces on both sides: each triangle wound to face -x at x0 and +x at x1"""
    for t in tris_yz:
        if area(t) < 0: t = [t[0], t[2], t[1]]
        a = [bm.verts.new((x0, y, z)) for (y, z) in t]; b = [bm.verts.new((x1, y, z)) for (y, z) in t]
        bm.faces.new([a[2], a[1], a[0]]); bm.faces.new(b)
def ring_tris(outer, inner):
    """the band between two outlines with matching points (both counter-clockwise)"""
    n, out = len(outer), []
    for i in range(n):
        k = (i + 1) % n
        out += [[outer[i], outer[k], inner[k]], [outer[i], inner[k], inner[i]]]
    return out
def holed_tris(outer, hole):
    from mathutils.geometry import tessellate_polygon
    pts = outer + hole
    tri = tessellate_polygon([[Vector((y, z, 0)) for (y, z) in outer], [Vector((y, z, 0)) for (y, z) in hole]])
    return [[pts[i] for i in t] for t in tri]
def rims(bm, outline, x0, x1, outward=True):
    """side faces along an outline: facing out of the shape, or into its hole"""
    n = len(outline)
    for i in range(n):
        k = (i + 1) % n
        (ya, za), (yb, zb) = outline[i], outline[k]
        q = [bm.verts.new((x0, ya, za)), bm.verts.new((x1, ya, za)), bm.verts.new((x1, yb, zb)), bm.verts.new((x0, yb, zb))]
        bm.faces.new(q if outward else list(reversed(q)))
CHECK = []
def check(name, tris_yz, want):
    got = sum(abs(area(t)) for t in tris_yz); neg = sum(1 for t in tris_yz if area(t) < 0)
    CHECK.append(f"{name}: area {got:.4f} want {want:.4f} ({'OK' if abs(got - want) < 1e-4 else 'MISMATCH'}), {neg} tris wound backwards")

def build_glass():
    hw = W / 2
    names = []
    COL["Church_Lead_Came"] = (0.17, 0.15, 0.14)
    for sx in (-1, 1):
        side = "_PX" if sx < 0 else "_NX"                      # Roblox x = -S * this x (the mirror), so sx -1 is the Roblox +x wall
        gold, blue, red = B("Church_Glass_Gold" + side), B("Church_Glass_Blue" + side), B("Church_Glass_Red" + side)
        for k in ("Gold", "Blue", "Red"): COL["Church_Glass_" + k + side] = COL["Church_Glass_" + k]
        came = B("Church_Lead_Came")
        xm = sx * (hw - T / 2)
        x0, x1 = xm - GT, xm + GT
        for c in WIN_Y:
            outer = arch_outline(c, WIN_W + 0.2, WIN_SILL - 0.1, WIN_SPRING)      # 0.1 into the piers, the header and the stone sill
            g_in = arch_outline(c, BW - 2 * OV, BS + OV, BSP)                      # gold runs 0.02 under the blue's came
            t = ring_tris(outer, g_in); caps(gold, t, x0, x1); check(f"gold{side} {c}", t, area(outer) - area(g_in))
            b_out = arch_outline(c, BW + 2 * OV, BS - OV, BSP)                     # blue runs 0.02 under the same came
            t = holed_tris(b_out, rect(c, -OV)); caps(blue, t, x0, x1); check(f"blue{side} {c}", t, area(b_out) - area(rect(c, -OV)))
            r = rect(c, OV); t = [[r[0], r[1], r[2]], [r[0], r[2], r[3]]]; caps(red, t, x0, x1)
            # the cames: closed solids over the two joins (blue field edge, red centre edge), thicker than the glass
            for (co, ci) in ((arch_outline(c, BW + 2 * CW, BS - CW, BSP), arch_outline(c, BW - 2 * CW, BS + CW, BSP)), (rect(c, CW), rect(c, -CW))):
                caps(came, ring_tris(co, ci), xm - CT, xm + CT); rims(came, co, xm - CT, xm + CT, True); rims(came, ci, xm - CT, xm + CT, False)
        names += ["Church_Glass_Gold" + side, "Church_Glass_Blue" + side, "Church_Glass_Red" + side]
    names.append("Church_Lead_Came")
    # the reference: the old gold mesh exactly as gen_church.py built it (side windows + the rose ring)
    ref = B("Church_Glass_Ref"); COL["Church_Glass_Ref"] = (1.0, 0.0, 1.0)
    for sx in (-1, 1):
        xm = sx * (hw - T / 2)
        for wy in WIN_Y:
            prism_x(ref, arch_outline(wy, WIN_W - 0.1, WIN_SILL + 0.06, WIN_SPRING), xm - 0.03, xm + 0.03)
    cz, yo = EAVE + 1.6, -L / 2
    prism_y(ref, [(0.9 * math.cos(2 * math.pi * i / 16), cz + 0.9 * math.sin(2 * math.pi * i / 16)) for i in range(16)], yo + 0.25, yo + 0.31)
    names.append("Church_Glass_Ref")
    return names

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glass = finish(build_glass(), "")
    for line in CHECK: log("CHECK " + line)
    export(glass, "church_glass")
    info = {o.name: bbox([o]) for o in glass}
    json.dump(info, open(os.path.join(OUT, "glass_pieces.json"), "w"), indent=1)
    for k, v in info.items(): log(f"BBOX {k} {v}")
    log("FBX_DONE")
    # check renders (mine, not for her): the new glass in the shell, the old glass hidden
    shell = finish(build_shell(), "")
    for o in shell:
        if o.name.startswith("Church_Glass_"): o.hide_render = True
    for o in glass:
        if o.name == "Church_Glass_Ref": o.hide_render = True
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = 900, 600
    sc.world = bpy.data.worlds.new("W"); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (lin(0.62), lin(0.80), lin(0.95), 1); bg.inputs["Strength"].default_value = 1.2
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-120)); sun.data.energy = 3.0
    lamp = bpy.data.objects.new("Lamp", bpy.data.lights.new("Lamp", "POINT")); sc.collection.objects.link(lamp); lamp.location = (0, -6, 10); lamp.data.energy = 3000
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(fn, loc, target, lens):
        cam.data.lens = lens; cam.location = Vector(loc); d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log(f"shot {fn}")
    wx = (W / 2 - T / 2) * S                     # the +x (Blender, after the mirror) side wall's middle plane
    shot("glass_inside_close.png", (wx - 6.5, -6, 11.5), (wx, -6, 12.6), 40)
    shot("glass_inside_wide.png", (0, -22, 9), (wx, -6, 10.5), 30)
    shot("glass_outside_close.png", (wx + 8, -6, 11.5), (wx, -6, 12.0), 40)
    log("GLASS_DONE")
except Exception:
    log(traceback.format_exc()); log("GLASS_FAILED")
