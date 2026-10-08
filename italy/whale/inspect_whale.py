"""Inspect the Meshy whale: objects, counts, bbox, textures; render 4 textured views.
Run: blender --background --python inspect_whale.py -- <in.fbx> <png> <outdir>"""
import bpy, sys, os, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
IN, PNG, OUTD = argv[0], argv[1], argv[2]
LOG = os.path.join(OUTD, "inspect_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.fbx(filepath=IN, use_custom_normals=False)
    except Exception:
        bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects:
        log(f"obj {o.name} type {o.type} loc {tuple(round(v,3) for v in o.location)} rot {tuple(round(v,3) for v in o.rotation_euler)} scale {tuple(round(v,3) for v in o.scale)} dims {tuple(round(v,3) for v in o.dimensions)}")
    for o in meshes:
        tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
        log(f"mesh {o.name}: verts {len(o.data.vertices)} polys {len(o.data.polygons)} tris {tris} uv layers {[u.name for u in o.data.uv_layers]} materials {[m.name if m else None for m in o.data.materials]}")
        ws = [o.matrix_world @ v.co for v in o.data.vertices]
        mn = Vector((min(p.x for p in ws), min(p.y for p in ws), min(p.z for p in ws)))
        mx = Vector((max(p.x for p in ws), max(p.y for p in ws), max(p.z for p in ws)))
        log(f"  world bbox min {tuple(round(v,3) for v in mn)} max {tuple(round(v,3) for v in mx)} size {tuple(round(v,3) for v in (mx-mn))}")
        for m in o.data.materials:
            if m and m.node_tree:
                for n in m.node_tree.nodes:
                    if n.type == "TEX_IMAGE":
                        log(f"  tex node {n.name} image {n.image.name if n.image else None} {n.image.filepath if n.image else ''}")
    # join + texture for renders
    for o in bpy.data.objects: o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    w = bpy.context.view_layer.objects.active
    mat = w.data.materials[0] if w.data.materials and w.data.materials[0] else bpy.data.materials.new("W")
    if not w.data.materials: w.data.materials.append(mat)
    mat.use_nodes = True
    nt = mat.node_tree
    texn = [n for n in nt.nodes if n.type == "TEX_IMAGE"]
    if texn:
        tex = texn[0]
    else:
        tex = nt.nodes.new("ShaderNodeTexImage")
        bsdf = [n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"][0]
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    tex.image = bpy.data.images.load(PNG)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 900, 600; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.type = "ORTHO"
    ws = [w.matrix_world @ v.co for v in w.data.vertices]
    mn = Vector((min(p.x for p in ws), min(p.y for p in ws), min(p.z for p in ws)))
    mx = Vector((max(p.x for p in ws), max(p.y for p in ws), max(p.z for p in ws)))
    ctr = (mn + mx) / 2; size = mx - mn; big = max(size)
    cam.ortho_scale = big * 1.15
    def shoot(name, off, up):
        camo.location = ctr + off
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", up).to_euler()
        sc.render.filepath = os.path.join(OUTD, name); bpy.ops.render.render(write_still=True)
    d = big * 3
    shoot("view_side_px.png", Vector((d, 0, 0)), "Z")
    shoot("view_side_py.png", Vector((0, d, 0)), "Z")
    shoot("view_top.png", Vector((0, 0, d)), "Y")
    shoot("view_front_ny.png", Vector((0, -d, 0)), "Z")
    shoot("view_front_nx.png", Vector((-d, 0, 0)), "Z")
    log("INSPECT_DONE")
except Exception:
    log(traceback.format_exc())
