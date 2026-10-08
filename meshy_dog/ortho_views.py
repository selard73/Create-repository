"""Orthographic reference renders (side / front / top) with 1-stud grid lines and axis labels,
so bones can be placed by reading coordinates off the pictures.
Run: blender --background --python ortho_views.py -- <in.fbx> <out_prefix>"""
import bpy, sys, os, traceback
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, PREFIX = argv[0], argv[1]
LOG = PREFIX + "_log.txt"
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    xs, ys, zs = [], [], []
    for o in meshes:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
    lo = Vector((min(xs), min(ys), min(zs))); hi = Vector((max(xs), max(ys), max(zs)))
    c = (lo + hi) / 2
    log(f"bbox min {tuple(round(v,2) for v in lo)} max {tuple(round(v,2) for v in hi)}")
    size = max(hi - lo) * 1.15
    # grid: thin cylinders every 1 unit on the three planes behind the dog
    grid_mat = bpy.data.materials.new("Grid"); grid_mat.diffuse_color = (0.1, 0.1, 0.1, 1)
    def line(a, b, r=0.012):
        a, b = Vector(a), Vector(b)
        mid = (a + b) / 2; d = b - a
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d.length, location=mid)
        ob = bpy.context.object
        ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
        ob.data.materials.append(grid_mat)
        return ob
    import math
    rng = range(int(math.floor(min(lo) - 1)), int(math.ceil(max(hi) + 2)))
    # back wall (behind dog for side view: plane x = lo.x - 0.5), floor grid for top view
    for k in rng:
        line((lo.x - 0.6, k, lo.z - 1), (lo.x - 0.6, k, hi.z + 1))        # vertical lines on side wall (y = k)
        line((lo.x - 0.6, lo.y - 1, k), (lo.x - 0.6, hi.y + 1, k))        # horizontal lines on side wall (z = k)
        line((k, lo.y - 0.6, lo.z - 1), (k, lo.y - 0.6, hi.z + 1))        # front wall verticals (x = k)
        line((lo.x - 1, lo.y - 0.6, k), (hi.x + 1, lo.y - 0.6, k))        # front wall horizontals (z = k)
        line((k, lo.y - 1, lo.z - 0.02), (k, hi.y + 1, lo.z - 0.02))      # floor lines x = k
        line((lo.x - 1, k, lo.z - 0.02), (hi.x + 1, k, lo.z - 0.02))      # floor lines y = k
    # thicker axis lines at 0
    line((lo.x - 0.6, 0, lo.z - 1), (lo.x - 0.6, 0, hi.z + 1), 0.03)
    line((0, lo.y - 0.6, lo.z - 1), (0, lo.y - 0.6, hi.z + 1), 0.03)
    line((0, lo.y - 1, lo.z - 0.02), (0, hi.y + 1, lo.z - 0.02), 0.03)
    line((lo.x - 1, 0, lo.z - 0.02), (hi.x + 1, 0, lo.z - 0.02), 0.03)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 1000, 1000
    sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); cam.type = "ORTHO"; cam.ortho_scale = size
    camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    views = {
        "side":  ((c.x + 20, c.y, c.z), (math.radians(90), 0, math.radians(90))),     # looking -X: image right = -Y? we log it
        "front": ((c.x, c.y - 20, c.z), (math.radians(90), 0, 0)),                    # looking +Y
        "top":   ((c.x, c.y, c.z + 20), (0, 0, 0)),                                    # looking -Z, image up = +Y
    }
    for name, (loc, rot) in views.items():
        camo.location = loc; camo.rotation_euler = rot
        sc.render.filepath = f"{PREFIX}_{name}.png"
        bpy.ops.render.render(write_still=True)
        log(f"rendered {name}")
    log("VIEWS_DONE")
except Exception:
    log(traceback.format_exc())
