"""Backup prep for very dense Meshy squirrels (Oct 3 2026: 7.7M-tri downloads that collapse-decimate cannot take below ~22k).
Builds a clean low mesh by voxel remesh + decimate, unwraps it, and bakes the original colour texture onto it.
Output matches prep_squirrel.py: <name>.blend (object "Squirrel", 2.4 tall, feet z=0, faces -Y, image texture material)
plus <name>_1k.png (baked colour) and preview renders.
Run: blender --background --python rebuild_bake.py -- <in.fbx> <out_dir> <name> <colour_png> <target_tris> <height> [voxel]
Log: <out_dir>/rebuild_log.txt (ends with REBUILD_DONE)."""
import bpy, sys, os, math, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUTD, NAME, PNG = argv[0], argv[1], argv[2], argv[3]
TARGET = int(argv[4]); HEIGHT = float(argv[5]); VOXEL = float(argv[6]) if len(argv) > 6 else 0.011
LOG = os.path.join(OUTD, "rebuild_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def tris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)
def activate(o):
    for x in bpy.data.objects: x.select_set(x == o)
    bpy.context.view_layer.objects.active = o
def decimate_to(o, target, max_step=0.1):
    activate(o)
    for _ in range(10):
        t = tris(o)
        if t <= target * 1.02: break
        m = o.modifiers.new("Dec", "DECIMATE"); m.ratio = max(target / t, max_step); m.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=m.name)
        log(f"  {o.name} decimate -> {tris(o)}")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    activate(meshes[0])
    for o in meshes: o.select_set(True)
    if len(meshes) > 1: bpy.ops.object.join()
    hi = bpy.context.view_layer.objects.active; hi.name = "Hi"
    for o in list(bpy.data.objects):
        if o != hi: bpy.data.objects.remove(o)
    activate(hi)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    log(f"source tris {tris(hi)}")
    decimate_to(hi, 300000)
    # scale / centre exactly like prep_squirrel.py
    s = HEIGHT / hi.dimensions.z
    hi.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    pts = [v.co for v in hi.data.vertices]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
    zmin = min(p.z for p in pts)
    for v in hi.data.vertices: v.co.x -= cx; v.co.y -= cy; v.co.z -= zmin
    hi.data.update()
    # source material keeps the Meshy UVs + full-size colour image
    mat = bpy.data.materials.new("HiMat"); mat.use_nodes = True; nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]; tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    hi.data.materials.clear(); hi.data.materials.append(mat)
    # low: voxel remesh (clean, closed) then decimate
    lo = hi.copy(); lo.data = hi.data.copy(); bpy.context.collection.objects.link(lo); lo.name = "Squirrel"
    activate(lo)
    rm = lo.modifiers.new("Vox", "REMESH"); rm.mode = "VOXEL"; rm.voxel_size = VOXEL; rm.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=rm.name)
    log(f"voxel {VOXEL} -> {tris(lo)} tris")
    decimate_to(lo, TARGET, 0.25)
    bpy.ops.object.shade_smooth()
    # unwrap
    activate(lo)
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    # bake target
    img = bpy.data.images.new(f"{NAME}_1k", 1024, 1024)
    lmat = bpy.data.materials.new("SquirrelMat"); lmat.use_nodes = True; ln = lmat.node_tree
    for n in list(ln.nodes): ln.nodes.remove(n)
    out = ln.nodes.new("ShaderNodeOutputMaterial"); lb = ln.nodes.new("ShaderNodeBsdfPrincipled"); lt = ln.nodes.new("ShaderNodeTexImage")
    lt.image = img; ln.links.new(lt.outputs["Color"], lb.inputs["Base Color"]); ln.links.new(lb.outputs["BSDF"], out.inputs["Surface"])
    ln.nodes.active = lt
    lo.data.materials.clear(); lo.data.materials.append(lmat)
    sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 1
    bk = sc.render.bake; bk.use_selected_to_active = True; bk.cage_extrusion = 0.03; bk.max_ray_distance = 0.08; bk.margin = 6
    bk.use_pass_direct = False; bk.use_pass_indirect = False; bk.use_pass_color = True
    for x in bpy.data.objects: x.select_set(x in (hi, lo))
    bpy.context.view_layer.objects.active = lo
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_selected_to_active=True, cage_extrusion=0.03, max_ray_distance=0.08, margin=6)
    png1k = os.path.join(OUTD, f"{NAME}_1k.png")
    img.filepath_raw = png1k; img.file_format = "PNG"; img.save()
    lt.image = bpy.data.images.load(png1k)
    log(f"baked -> {png1k}")
    # keep only the low mesh, save like prep
    bpy.data.objects.remove(hi)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}.blend"))
    # previews
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 800, 800; sc.render.image_settings.file_format = "PNG"
    sc.world = bpy.data.worlds.new("W"); sc.world.color = (0.86, 0.88, 0.92)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = HEIGHT + 0.6
    ctr = Vector((0, 0, HEIGHT / 2))
    for vname, off in {"front": Vector((0, -20, 0)), "q34": Vector((-12, -14, 3)), "side": Vector((20, 0, 0)), "back": Vector((0, 20, 0))}.items():
        camo.location = ctr + off
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"rebuild_{vname}.png"); bpy.ops.render.render(write_still=True)
    log(f"final tris {tris(lo)}")
    log("REBUILD_DONE")
except Exception:
    log(traceback.format_exc())
