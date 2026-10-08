"""Inspect a Meshy boat FBX: triangle count, size, objects, texture; render 4 textured views.
Run: blender --background --python inspect_boat.py -- <fbx> <out_dir>"""
import bpy, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, OUTD = argv[0], argv[1]
os.makedirs(OUTD, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FBX)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
tris = 0
mn, mx = Vector((1e9, 1e9, 1e9)), Vector((-1e9, -1e9, -1e9))
for o in meshes:
    me = o.data
    me.calc_loop_triangles()
    tris += len(me.loop_triangles)
    for v in o.bound_box:
        w = o.matrix_world @ Vector(v)
        mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
print("QQ objects", [(o.name, len(o.data.polygons)) for o in meshes])
print("QQ tris", tris)
open(os.path.join(OUTD, "stats.txt"), "w").write("tris %d objects %s size %s" % (tris, [(o.name, len(o.data.polygons)) for o in meshes], tuple(round(c, 3) for c in (mx - mn))))
print("QQ size", tuple(round(c, 3) for c in (mx - mn)), "min", tuple(round(c, 3) for c in mn))
for o in meshes:
    for s in o.material_slots:
        m = s.material
        if m and m.use_nodes:
            for n in m.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image:
                    print("QQ tex", m.name, n.image.name, tuple(n.image.size))
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_backface_culling = True
sc.render.resolution_x = sc.render.resolution_y = 700
sc.render.image_settings.file_format = "PNG"
world = bpy.data.worlds.new("w"); sc.world = world
world.color = (0.93, 0.95, 0.97)
ctr = (mn + mx) / 2
rad = (mx - mn).length
cam = bpy.data.cameras.new("c"); cam.lens = 50
co = bpy.data.objects.new("c", cam); sc.collection.objects.link(co); sc.camera = co
def look(pos):
    co.location = pos
    d = (ctr - Vector(pos))
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
views = {"threequarter": (1, -1, 0.7), "side": (1, 0, 0.15), "back": (0, 1, 0.5), "top": (0.001, 0.001, 1), "front": (0, -1, 0.3)}
for name, d in views.items():
    v = Vector(d).normalized() * rad * 1.35
    look(ctr + v)
    sc.render.filepath = os.path.join(OUTD, f"view_{name}.png")
    bpy.ops.render.render(write_still=True)
print("QQ DONE")
