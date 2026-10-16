"""Blender headless: prepare Shannon's Meshy koi for the pond. Join, clear split normals, decimate to <target> tris, smooth,
centre on the bbox centre, longest axis = <length> studs, the colour texture downscaled to <texpx> and packed, export one FBX with
the texture embedded, plus top/side renders to read which way the head points.
Args: <in.fbx> <colour.png> <out_dir> <target_tris> <length> <texpx> <log>"""
import bpy, sys, os, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, PNG, OUTD, TARGET, LENGTH, TEXPX, LOG = argv[0], argv[1], argv[2], int(argv[3]), float(argv[4]), int(argv[5]), argv[6]
def log(m):
    with open(LOG, "a", encoding="utf-8") as f: f.write(str(m) + "\n")
def r3(v): return tuple(round(c, 3) for c in v)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN, use_image_search=False)
    for o in [o for o in bpy.data.objects if o.type != "MESH"]: bpy.data.objects.remove(o)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active; ob.name = "Koi"; ob.data.name = "KoiMesh"
    for m in list(ob.modifiers): ob.modifiers.remove(m)
    ob.parent = None
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    try: bpy.ops.mesh.customdata_custom_splitnormals_clear()
    except Exception as e: log(f"no split normals ({e})")
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    log(f"tris before {tris}")
    if tris > TARGET:
        mod = ob.modifiers.new("Decimate", "DECIMATE"); mod.ratio = TARGET / tris; mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    pts = [v.co.copy() for v in ob.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    dims = hi - lo
    s = LENGTH / max(dims)
    c = (lo + hi) / 2
    for v in ob.data.vertices: v.co = (v.co - c) * s
    pts = [v.co.copy() for v in ob.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"tris after {sum(len(p.vertices) - 2 for p in ob.data.polygons)}; scale {s:.4f}; Blender bbox min {r3(lo)} max {r3(hi)} dims {r3(hi - lo)}")
    # thickness at each end of the longest axis (the head end is usually the thicker, the tail fin thin)
    ax = max(range(3), key=lambda i: (hi - lo)[i])
    def thick(lo_frac, hi_frac):
        a, b = lo[ax] + lo_frac * (hi[ax] - lo[ax]), lo[ax] + hi_frac * (hi[ax] - lo[ax])
        sel = [p for p in pts if a <= p[ax] <= b]
        if not sel: return 0
        others = [i for i in range(3) if i != ax]
        return max(p[others[0]] for p in sel) - min(p[others[0]] for p in sel), max(p[others[1]] for p in sel) - min(p[others[1]] for p in sel)
    log(f"longest axis {'XYZ'[ax]}; extents near the MIN end (0-15%) {thick(0.0, 0.15)}, near the MAX end (85-100%) {thick(0.85, 1.0)}")
    img = bpy.data.images.load(PNG)
    img.scale(TEXPX, TEXPX)
    img.pack()
    mat = bpy.data.materials.new("KoiMat"); mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    ob.data.materials.clear(); ob.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT"); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    fbx = os.path.join(OUTD, "koi_meshy.fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, path_mode="COPY", embed_textures=True)
    log(f"FBX {fbx} {os.path.getsize(fbx)} bytes")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cc = (lo + hi) / 2; R = max(hi - lo) * 3
    def shot(name, d, up=(0, 0, 1)):
        sc.render.resolution_x, sc.render.resolution_y = 700, 700
        camo.location = cc + Vector(d).normalized() * R
        f = (cc - camo.location).normalized(); r = f.cross(Vector(up)).normalized(); u = r.cross(f).normalized()
        camo.rotation_mode = "QUATERNION"; camo.rotation_quaternion = Matrix((r, u, -f)).transposed().to_quaternion()
        cam.type = "ORTHO"; cam.ortho_scale = max(hi - lo) * 1.2; cam.clip_end = R * 4
        sc.render.filepath = os.path.join(OUTD, name); bpy.ops.render.render(write_still=True)
    shot("koi_top.png", (0, 0, 1), up=(0, 1, 0)); shot("koi_side.png", (1, 0, 0)); shot("koi_front.png", (0, -1, 0))
    log("KOI_DONE")
except Exception:
    log(traceback.format_exc()); log("KOI_FAILED")
