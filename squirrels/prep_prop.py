"""Prop prep: join, decimate, 1k texture, scale to HEIGHT, feet z=0, centre; export a rig-free FBX for Roblox.
Deliberately adds no bones: a prop with Root/Tail2 bones would be picked up as a findable squirrel.
Run: blender --background --python prep_prop.py -- <in.fbx> <out_dir> <name> <colour_png> <target_tris> <height> <yaw_deg>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUTD, NAME, PNG = argv[0], argv[1], argv[2], argv[3]
TARGET = int(argv[4]); HEIGHT = float(argv[5]); YAW = float(argv[6])
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
    sq = bpy.context.view_layer.objects.active; sq.name = "Squirrel"
    for o in list(bpy.data.objects):
        if o != sq: bpy.data.objects.remove(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tris = sum(len(p.vertices) - 2 for p in sq.data.polygons)
    log(f"tris before {tris}")
    if tris > TARGET:
        mod = sq.modifiers.new("Decimate", "DECIMATE"); mod.ratio = TARGET / tris; mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    log(f"tris after {sum(len(p.vertices) - 2 for p in sq.data.polygons)}")
    mat = bpy.data.materials.new("SquirrelMat"); mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    sq.data.materials.clear(); sq.data.materials.append(mat)
    if abs(YAW) > 1e-3:
        sq.matrix_world = Matrix.Rotation(math.radians(YAW), 4, "Z") @ sq.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    d = sq.dimensions; s = HEIGHT / d.z
    sq.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    pts = [v.co.copy() for v in sq.data.vertices]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
    zmin = min(p.z for p in pts)
    for v in sq.data.vertices: v.co.x -= cx; v.co.y -= cy; v.co.z -= zmin
    pts = [v.co.copy() for v in sq.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"bbox min {tuple(round(v,2) for v in lo)} max {tuple(round(v,2) for v in hi)}")
    step = 0.2
    log("Z slices: z_from z_to n ymin ymax xmin xmax  (y<0 = 'front' side of view)")
    z = 0.0
    while z < hi.z:
        sl = [p for p in pts if z <= p.z < z + step]
        if sl: log(f"{z:5.2f} {z+step:5.2f} {len(sl):5d} {min(p.y for p in sl):5.2f} {max(p.y for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        z += step
    log("Y slices: y_from y_to n zmin zmax xmin xmax")
    y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step]
        if sl: log(f"{y:5.2f} {y+step:5.2f} {len(sl):5d} {min(p.z for p in sl):5.2f} {max(p.z for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        y += step
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}.blend"))
    bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True)
    bpy.context.view_layer.objects.active = sq
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    log("exported " + NAME + ".fbx")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 800, 800; sc.render.image_settings.file_format = "PNG"
    gmat = bpy.data.materials.new("Grid"); gmat.diffuse_color = (0.1, 0.1, 0.9, 1)
    ext = HEIGHT + 1
    def bar(loc, size):
        bpy.ops.mesh.primitive_cube_add(location=loc); c = bpy.context.active_object; c.scale = size; c.data.materials.append(gmat)
    for i in range(-6, 7):
        v = i * 0.5
        bar((v, 0, -0.02), (0.01, ext, 0.01)); bar((0, v, -0.02), (ext, 0.01, 0.01))
        bar((-2.5, v, 0), (0.01, 0.01, ext)); bar((-2.5, 0, max(v, 0)), (0.01, ext, 0.01))
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"; cam.ortho_scale = HEIGHT + 1.5
    ctr = Vector((0, 0, hi.z / 2))
    views = {"side": Vector((20, 0, 0)), "front": Vector((0, -20, 0)), "back": Vector((0, 20, 0)), "top": Vector((0, 0, 20))}
    for name, off in views.items():
        camo.location = ctr + off
        up = "Y" if name == "top" else "Z"
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", up).to_euler()
        sc.render.filepath = os.path.join(OUTD, f"ref_{name}.png"); bpy.ops.render.render(write_still=True)
    log("PREP_DONE")
except Exception:
    log(traceback.format_exc())
