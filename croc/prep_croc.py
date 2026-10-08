"""Chompy the crocodile (Meshy): join, decimate, 1k colour texture, PCA-align (snout -> -Y), lowest point z=0,
scale to LENGTH studs, save croc.blend, log slice profiles (length, mouth gap, legs), render textured reference views.
Run: blender --background --python prep_croc.py -- <in.fbx> <out_dir> <colour_1k.png> <target_tris> <length> [flip]"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUTD, PNG = argv[0], argv[1], argv[2]
TARGET = int(argv[3]); LENGTH = float(argv[4]); FLIP = len(argv) > 5 and argv[5] == "flip"
LOG = os.path.join(OUTD, "prep_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def r2(v): return tuple(round(c, 2) for c in v)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    log("objects in: " + str([(o.name, o.type, len(o.data.polygons) if o.type == "MESH" else "") for o in bpy.data.objects]))
    for o in [o for o in bpy.data.objects if o.type not in ("MESH",)]:
        bpy.data.objects.remove(o)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    croc = bpy.context.view_layer.objects.active; croc.name = "Croc"
    for m in list(croc.modifiers): croc.modifiers.remove(m)
    croc.parent = None
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    log(f"raw dims {r2(croc.dimensions)}")
    try:                                   # Meshy's baked split normals make the decimated mesh look faceted: drop them
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
        log("custom split normals cleared")
    except Exception as e:
        log(f"no custom normals to clear ({e})")
    tris = sum(len(p.vertices) - 2 for p in croc.data.polygons)
    log(f"tris before {tris}")
    if tris > TARGET:
        mod = croc.modifiers.new("Decimate", "DECIMATE"); mod.ratio = TARGET / tris; mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    log(f"tris after {sum(len(p.vertices) - 2 for p in croc.data.polygons)}, verts {len(croc.data.vertices)}")
    mat = bpy.data.materials.new("CrocMat"); mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    croc.data.materials.clear(); croc.data.materials.append(mat)
    # PCA in xy: long axis -> Y
    pts = [v.co.copy() for v in croc.data.vertices]; n = len(pts)
    mx = sum(p.x for p in pts) / n; my = sum(p.y for p in pts) / n
    sxx = sum((p.x - mx) ** 2 for p in pts); syy = sum((p.y - my) ** 2 for p in pts); sxy = sum((p.x - mx) * (p.y - my) for p in pts)
    ang = 0.5 * math.atan2(2 * sxy, sxx - syy)
    log(f"pca long-axis angle from X: {math.degrees(ang):.1f} deg")
    croc.matrix_world = Matrix.Rotation(math.radians(90) - ang, 4, "Z") @ croc.matrix_world
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # which end is the head? the snout end is broad and deep; the tail tip is thin
    pts = [v.co.copy() for v in croc.data.vertices]
    ys = sorted(p.y for p in pts); ylo, yhi = ys[0], ys[-1]; span = yhi - ylo
    def endstat(sel):
        e = [p for p in pts if sel(p.y)]
        return len(e), max(p.x for p in e) - min(p.x for p in e), max(p.z for p in e) - min(p.z for p in e)
    A = endstat(lambda y: y < ylo + 0.12 * span); B = endstat(lambda y: y > yhi - 0.12 * span)
    log(f"end -Y: n {A[0]} xr {A[1]:.2f} zr {A[2]:.2f} | end +Y: n {B[0]} xr {B[1]:.2f} zr {B[2]:.2f}")
    head_at_plus = B[1] * B[2] > A[1] * A[2]
    if head_at_plus != FLIP:
        croc.matrix_world = Matrix.Rotation(math.pi, 4, "Z") @ croc.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        log("turned 180 so the snout points -Y" + (" (FLIP asked)" if FLIP else ""))
    s = LENGTH / croc.dimensions.y
    croc.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    pts = [v.co.copy() for v in croc.data.vertices]
    ys = sorted(p.y for p in pts); ylo, yhi = ys[0], ys[-1]; span = yhi - ylo
    mid = [p for p in pts if ylo + 0.3 * span < p.y < ylo + 0.6 * span]
    cx = sum(p.x for p in mid) / len(mid); zmin = min(p.z for p in pts); cy = ylo
    for v in croc.data.vertices: v.co.x -= cx; v.co.z -= zmin; v.co.y -= cy     # snout tip at y = 0, body runs to +Y
    pts = [v.co.copy() for v in croc.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"bbox min {r2(lo)} max {r2(hi)} (snout tip at y=0, tail toward +Y, left = +X)")
    step = LENGTH / 56
    log("SLICES y_from y_to n zmin zmax xmin xmax")
    y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step]
        if sl: log(f"{y:6.2f} {y+step:6.2f} {len(sl):5d} {min(p.z for p in sl):5.2f} {max(p.z for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        y += step
    log("MOUTH: front 35%, centre strip |x|<0.35 and side strips; z gaps > 0.10")
    y = lo.y; step2 = LENGTH / 80
    while y < lo.y + 0.35 * span:
        row = []
        for xs, (xa, xb) in (("mid", (-0.35, 0.35)), ("L", (0.35, 1.2)), ("R", (-1.2, -0.35))):
            zs = sorted(p.z for p in pts if y <= p.y < y + step2 and xa <= p.x < xb)
            gaps = [(round(zs[i], 2), round(zs[i + 1], 2)) for i in range(len(zs) - 1) if zs[i + 1] - zs[i] > 0.10]
            row.append(f"{xs}:{len(zs)}:{(round(zs[0],2), round(zs[-1],2)) if zs else ''} gaps {gaps}")
        log(f"{y:6.2f} " + " | ".join(row))
        y += step2
    H = hi.z
    log(f"LEGS: verts with z < {0.3*H:.2f}, by y band and side")
    y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step and p.z < 0.3 * H]
        if sl:
            L = [p.x for p in sl if p.x > 0]; R = [p.x for p in sl if p.x < 0]
            log(f"{y:6.2f} {y+step:6.2f}  L {min(L) if L else 0:5.2f}..{max(L) if L else 0:5.2f}  R {min(R) if R else 0:5.2f}..{max(R) if R else 0:5.2f}  n {len(sl)}  zmin {min(p.z for p in sl):.2f}")
        y += step
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "croc.blend"))
    # renders: textured, studio light; grid every 1 stud (every 5th darker)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.image_settings.file_format = "PNG"
    g1 = bpy.data.materials.new("Grid1"); g1.diffuse_color = (0.55, 0.6, 0.95, 1)
    g5 = bpy.data.materials.new("Grid5"); g5.diffuse_color = (0.1, 0.1, 0.7, 1)
    def bar(loc, size, m):
        bpy.ops.mesh.primitive_cube_add(location=loc); c = bpy.context.active_object; c.scale = size; c.data.materials.append(m)
    wallx = lo.x - 1.5
    for i in range(-2, int(hi.y) + 3):
        m = g5 if i % 5 == 0 else g1
        bar((0, i, -0.03), (6, 0.012, 0.012), m)                    # floor lines across (constant y)
        bar((wallx, i, H / 2 + 1), (0.012, 0.012, H / 2 + 2), m)    # side wall verticals
    for k in range(0, int(H) + 3):
        m = g5 if k % 5 == 0 else g1
        bar((wallx, hi.y / 2, k), (0.012, hi.y / 2 + 3, 0.012), m)  # side wall horizontals
    for i in range(-6, 7):
        bar((i, hi.y / 2, -0.03), (0.012, hi.y / 2 + 3, 0.012), g5 if i == 0 else g1)   # floor lines along
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    def shot(name, frm, to, ortho=None, res=(1000, 1000), up=(0, 0, 1)):
        sc.render.resolution_x, sc.render.resolution_y = res
        camo.location = Vector(frm)
        f = (Vector(to) - camo.location).normalized()
        r = f.cross(Vector(up)).normalized(); u = r.cross(f).normalized()
        M = Matrix((r, u, -f)).transposed().to_4x4()
        camo.rotation_mode = "QUATERNION"; camo.rotation_quaternion = M.to_quaternion()
        if ortho: cam.type = "ORTHO"; cam.ortho_scale = ortho
        else: cam.type = "PERSP"; cam.lens = 40
        sc.render.filepath = os.path.join(OUTD, name); bpy.ops.render.render(write_still=True)
    cy_ = hi.y / 2; cz = H / 2
    shot("ref_side.png", (40, cy_, cz), (0, cy_, cz), ortho=hi.y * 1.08, res=(1600, 700))
    shot("ref_top.png", (0, cy_, 40), (0, cy_, 0), ortho=hi.y * 1.08, res=(700, 1600), up=(0, -1, 0))
    shot("ref_front.png", (0, -40, cz), (0, 0, cz), ortho=max(hi.x - lo.x, H) * 1.3)
    shot("ref_back.png", (0, hi.y + 40, cz), (0, hi.y, cz), ortho=max(hi.x - lo.x, H) * 1.3)
    shot("ref_head_side.png", (40, 0.2 * hi.y, cz), (0, 0.2 * hi.y, cz), ortho=0.45 * hi.y, res=(1200, 900))
    shot("ref_34.png", (9, -7, 6), (0, 0.38 * hi.y, 1.0), res=(1400, 900))
    shot("ref_34_back.png", (-9, hi.y + 5, 7), (0, 0.55 * hi.y, 1.0), res=(1400, 900))
    log("PREP_DONE")
except Exception:
    log(traceback.format_exc())
    log("PREP_FAILED")
