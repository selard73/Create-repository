"""Standing Meshy dog: join, decimate, 1k texture, PCA-align (nose -> -Y), feet z=0, scale to HEIGHT,
save standing.blend + standing.obj, log slice profile, render ortho reference views.
Run: blender --background --python prep_align.py -- <in.fbx> <out_dir> <colour_png> <target_tris> <height>"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUTD, PNG = argv[0], argv[1], argv[2]
TARGET = int(argv[3]); HEIGHT = float(argv[4])
LOG = os.path.join(OUTD, "prep_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    log(f"meshes in: {[(o.name, len(o.data.polygons)) for o in meshes]}")
    for o in bpy.data.objects: o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    dog = bpy.context.view_layer.objects.active; dog.name = "Hound"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tris = sum(len(p.vertices) - 2 for p in dog.data.polygons)
    log(f"tris before {tris}")
    if tris > TARGET:
        mod = dog.modifiers.new("Decimate", "DECIMATE"); mod.ratio = TARGET / tris; mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    log(f"tris after {sum(len(p.vertices) - 2 for p in dog.data.polygons)}")
    # material: 1k colour only
    mat = bpy.data.materials.new("HoundMat"); mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    dog.data.materials.clear(); dog.data.materials.append(mat)
    # align: PCA in xy so long axis -> Y
    pts = [v.co.copy() for v in dog.data.vertices]; n = len(pts)
    mx = sum(p.x for p in pts) / n; my = sum(p.y for p in pts) / n
    sxx = sum((p.x - mx) ** 2 for p in pts); syy = sum((p.y - my) ** 2 for p in pts); sxy = sum((p.x - mx) * (p.y - my) for p in pts)
    ang = 0.5 * math.atan2(2 * sxy, sxx - syy)
    dog.matrix_world = Matrix.Rotation(math.radians(90) - ang, 4, "Z") @ dog.matrix_world
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pts = [v.co.copy() for v in dog.data.vertices]
    ys = sorted(p.y for p in pts); ylo, yhi = ys[0], ys[-1]; span = yhi - ylo
    zA = max(p.z for p in pts if p.y < ylo + 0.15 * span); zB = max(p.z for p in pts if p.y > yhi - 0.15 * span)
    if zB > zA:
        dog.matrix_world = Matrix.Rotation(math.pi, 4, "Z") @ dog.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # scale to HEIGHT, centre x, feet on z=0
    d = dog.dimensions; s = HEIGHT / d.z
    dog.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    pts = [v.co.copy() for v in dog.data.vertices]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; zmin = min(p.z for p in pts)
    for v in dog.data.vertices: v.co.x -= cx; v.co.z -= zmin
    pts = [v.co.copy() for v in dog.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"bbox min {tuple(round(v,2) for v in lo)} max {tuple(round(v,2) for v in hi)} (nose -Y)")
    log("y_from y_to n zmin zmax xmin xmax")
    y = lo.y; step = 0.25
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step]
        if sl: log(f"{y:6.2f} {y+step:6.2f} {len(sl):5d} {min(p.z for p in sl):5.2f} {max(p.z for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        y += step
    # leg columns: low slices (z<1.6) grouped by y and x sign
    log("legs z<40%: y_from y_to  xL_min xL_max  xR_min xR_max  n")
    zl = hi.z * 0.4; y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step and p.z < zl]
        if sl:
            L = [p.x for p in sl if p.x > 0]; R = [p.x for p in sl if p.x < 0]
            log(f"{y:6.2f} {y+step:6.2f}  {min(L) if L else 0:5.2f} {max(L) if L else 0:5.2f}  {min(R) if R else 0:5.2f} {max(R) if R else 0:5.2f} {len(sl)}")
        y += step
    bpy.ops.object.select_all(action="DESELECT"); dog.select_set(True)
    bpy.ops.wm.obj_export(filepath=os.path.join(OUTD, "standing.obj"), export_selected_objects=True, export_materials=True,
                          export_normals=True, export_uv=True, forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "standing.blend"))
    # ortho reference renders with grid lines every 0.5
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 1000; sc.render.image_settings.file_format = "PNG"
    # grid: thin cubes
    gmat = bpy.data.materials.new("Grid"); gmat.diffuse_color = (0.1, 0.1, 0.9, 1)
    ext = max(hi.y - lo.y, hi.z) + 1
    def bar(loc, size):
        bpy.ops.mesh.primitive_cube_add(location=loc); c = bpy.context.active_object; c.scale = size; c.data.materials.append(gmat)
    for i in range(-8, 9):
        v = i * 0.5
        bar((v, 0, -0.02), (0.01, ext, 0.01)); bar((0, v, -0.02), (ext, 0.01, 0.01))     # floor grid xy
        bar((-4.2, v, 0), (0.01, 0.01, ext)); bar((-4.2, 0, max(v,0)), (0.01, ext, 0.01)) # side wall grid yz at x=-4.2
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = 8.0
    ctr = Vector((0, (lo.y + hi.y) / 2, hi.z / 2))
    views = {"side": Vector((20, 0, 0)), "front": Vector((0, -20, 0)), "top": Vector((0, 0, 20)), "back": Vector((0, 20, 0))}
    for name, off in views.items():
        camo.location = ctr + off
        up = "Y" if name == "top" else "Z"
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", up).to_euler()
        sc.render.filepath = os.path.join(OUTD, f"ref_{name}.png"); bpy.ops.render.render(write_still=True)
    log("PREP_DONE")
except Exception:
    log(traceback.format_exc())
