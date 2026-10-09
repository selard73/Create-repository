# Blender: import Shannon's Meshy balloon FBX, print its size and triangle count, render a preview with its colour map.
# Run: python meshy_inspect.py <fbx> <out_dir>
import bpy, sys, os, math
import numpy as np
fbx, OUT = sys.argv[1], sys.argv[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx)
obs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in obs:
    me = o.data
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    co = np.array([o.matrix_world @ v.co for v in me.vertices])
    print("MESH", o.name, "verts", len(me.vertices), "tris", tris, "min", co.min(0).round(2), "max", co.max(0).round(2),
          "mats", [m.name for m in me.materials if m], "uvs", [u.name for u in me.uv_layers])
for m in bpy.data.materials:
    imgs = [n.image.name + " %dx%d" % tuple(n.image.size) for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image] if m.node_tree else []
    print("MAT", m.name, imgs)
co = np.concatenate([np.array([o.matrix_world @ v.co for v in o.data.vertices]) for o in obs])
lo, hi = co.min(0), co.max(0); c = (lo + hi) / 2; size = hi - lo
print("BOUNDS", lo.round(2), hi.round(2), "size", size.round(2))
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 32
sc.render.resolution_x, sc.render.resolution_y = 640, 800; sc.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("Sky"); sc.world = w; w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.75, 0.95, 1)
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 4
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
r = max(size) * 1.6
loc = c + np.array((r * 0.65, -r * 0.8, -size[2] * 0.15))
d = c - loc
cam.location = loc; cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2); cam.data.lens = 50
sc.render.filepath = os.path.join(OUT, "meshy_preview.png"); bpy.ops.render.render(write_still=True)
print("DONE")
