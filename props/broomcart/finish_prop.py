"""Finish a decimated Meshy prop for Roblox: feet on z=0, centred, sharpened 1k texture, FBX + preview renders.
Run: blender --background --python finish_prop.py -- <in.fbx> <tex.png> <out_dir> <name>"""
import bpy, sys, os, math, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
IN, TEX, OUTD, NAME = argv
LOG = os.path.join(OUTD, "finish_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    mn = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    mx = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    off = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    for v in ob.data.vertices: v.co -= off
    H = mx.z - mn.z
    s = 2.4 / H                                   # same 2.4 working height as the squirrels; Studio scales it
    for v in ob.data.vertices: v.co *= s
    log(f"tris {sum(len(p.vertices) - 2 for p in ob.data.polygons)} size {(mx - mn) * s}")
    mat = bpy.data.materials.new(NAME); mat.use_nodes = True
    nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = bpy.data.images.load(TEX)
    nt.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])
    ob.data.materials.clear(); ob.data.materials.append(mat)
    ob.name = NAME; ob.data.name = NAME
    bpy.ops.object.select_all(action="DESELECT"); ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"
    sc.render.resolution_x = sc.render.resolution_y = 700
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    for tag, pos in (("front", (0, -6, 1.6)), ("q34", (4.2, -4.4, 2.4)), ("back", (-3.5, 4.8, 2.2))):
        cam.location = Vector(pos)
        d = Vector((0, 0, 1.1)) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"view_{tag}.png")
        bpy.ops.render.render(write_still=True)
    log("FINISH_DONE")
except Exception:
    log(traceback.format_exc())
