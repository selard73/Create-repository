"""Boat prep: join, decimate, 1024 texture, bow toward -Y (stern = the red motor), scale to LENGTH studs,
keel z=0, centred; export boat.fbx; log slices (for seat/hull placement); render low-angle previews (backface culling).
Run: blender --background --python prep_boat.py -- <in.fbx> <in_png> <out_dir> <target_tris> <length>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, PNG, OUTD = argv[0], argv[1], argv[2]
TARGET = int(argv[3]); LENGTH = float(argv[4])
os.makedirs(OUTD, exist_ok=True)
LOG = os.path.join(OUTD, "prep_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    b = bpy.context.view_layer.objects.active; b.name = "Boat"
    for o in list(bpy.data.objects):
        if o != b: bpy.data.objects.remove(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    tris = sum(len(p.vertices) - 2 for p in b.data.polygons)
    log(f"tris before {tris}")
    # 1024 texture
    img = bpy.data.images.load(PNG)
    log(f"tex in {tuple(img.size)}")
    img.scale(1024, 1024)
    tex_out = os.path.join(OUTD, "boat_tex.png")
    img.filepath_raw = tex_out; img.file_format = "PNG"; img.save()
    img = bpy.data.images.load(tex_out)
    W, H = img.size; px = list(img.pixels)
    def sample(u, v):
        x = min(W - 1, max(0, int((u % 1.0) * W))); y = min(H - 1, max(0, int((v % 1.0) * H)))
        i = (y * W + x) * 4
        return px[i], px[i + 1], px[i + 2]
    # find the red motor -> stern
    me = b.data; uvl = me.uv_layers.active.data
    red = Vector((0, 0, 0)); nred = 0
    for p in me.polygons:
        li = p.loop_indices[0]
        r, g, bl = sample(*uvl[li].uv)
        if r > 0.35 and r > 2.2 * g and r > 2.2 * bl:
            red += p.center; nred += 1
    red /= max(nred, 1)
    d = b.dimensions
    log(f"dims {tuple(round(v,3) for v in d)} red faces {nred} red centroid {tuple(round(v,3) for v in red)}")
    ctr = Vector([(min(v.co[i] for v in me.vertices) + max(v.co[i] for v in me.vertices)) / 2 for i in range(3)])
    # long axis in XY; rotate so stern (red) goes to +Y, bow to -Y
    long_ax = 0 if d.x >= d.y else 1
    rel = red - ctr
    stern_dir = Vector((1, 0, 0)) if long_ax == 0 else Vector((0, 1, 0))
    if rel[long_ax] < 0: stern_dir = -stern_dir
    ang = math.atan2(stern_dir.y, stern_dir.x)  # current stern heading
    rot = math.pi / 2 - ang                       # bring it to +Y
    log(f"long axis {'xy'[long_ax]} stern {tuple(stern_dir)} rotate {math.degrees(rot):.0f}")
    b.matrix_world = Matrix.Rotation(rot, 4, "Z") @ Matrix.Translation(-ctr)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if tris > TARGET:
        mod = b.modifiers.new("Decimate", "DECIMATE"); mod.ratio = TARGET / tris; mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_flat()
    log(f"tris after {sum(len(p.vertices) - 2 for p in b.data.polygons)}")
    mat = bpy.data.materials.new("BoatMat"); mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    b.data.materials.clear(); b.data.materials.append(mat)
    s = LENGTH / b.dimensions.y
    b.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    pts = [v.co.copy() for v in b.data.vertices]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
    zmin = min(p.z for p in pts)
    for v in b.data.vertices: v.co.x -= cx; v.co.y -= cy; v.co.z -= zmin
    pts = [v.co.copy() for v in b.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"bbox min {tuple(round(v,2) for v in lo)} max {tuple(round(v,2) for v in hi)}  (bow = -Y, stern/motor = +Y)")
    log("Y slices (bow->stern): y_from y_to n zmin zmax xmin xmax")
    step = 0.5; y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step]
        if sl: log(f"{y:5.2f} {y+step:5.2f} {len(sl):5d} {min(p.z for p in sl):5.2f} {max(p.z for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        y += step
    # interior floor/bench heights: lowest upward-facing surface near centre line, per Y slice
    log("Centre-line top surfaces (|x|<0.4): y  z_values(rounded, upward faces)")
    y = lo.y
    while y < hi.y:
        zs = sorted({round(p.center.z, 1) for p in b.data.polygons if y <= p.center.y < y + step and abs(p.center.x) < 0.4 and p.normal.z > 0.7})
        if zs: log(f"{y:5.2f} {zs}")
        y += step
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "boat.blend"))
    bpy.ops.object.select_all(action="DESELECT"); b.select_set(True); bpy.context.view_layer.objects.active = b
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "boat.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    log("exported boat.fbx")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_backface_culling = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 700; sc.render.image_settings.file_format = "PNG"
    world = bpy.data.worlds.new("w"); sc.world = world; world.color = (0.62, 0.78, 0.9)
    # a water-ish plane a little above the keel, so she sees roughly how it sits
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0.55))
    wm = bpy.data.materials.new("Water"); wm.diffuse_color = (0.25, 0.55, 0.62, 1)
    bpy.context.active_object.data.materials.append(wm)
    cam = bpy.data.cameras.new("Cam"); cam.lens = 45
    camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    look_at = Vector((0, 0, hi.z * 0.55))
    views = {"low_threequarter": (1, -1, 0.28), "low_side": (1, 0, 0.12), "low_back": (0.35, 1, 0.3),
             "front": (-0.3, -1, 0.25), "high_threequarter": (-1, -0.8, 0.9), "top": (0, 0.001, 1)}
    for name, dv in views.items():
        v = Vector(dv).normalized() * 13.5
        camo.location = look_at + v
        camo.rotation_euler = (look_at - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"view_{name}.png"); bpy.ops.render.render(write_still=True)
    log("PREP_DONE")
except Exception:
    log(traceback.format_exc())

