"""Preview the bamboo maze kit: a 3 x 3-cell corner of a maze (9-stud cells, walls on the grid lines, a dead end and a T), lawn, a
6.3-tall grey stand-in figure for scale (not part of the design), workbench renders with the culm texture. out_bamboo/prev_*.png"""
import bpy, math, os, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_bamboo")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "japan_kit14_bamboo_maze.fbx"), axis_forward="-Z", axis_up="Y")
    kit = {o.name: o for o in bpy.data.objects if o.type == "EMPTY"}
    log("empties: " + ", ".join(sorted(kit)))
    def place(name, x, y, rot):
        src = kit[name]
        new = []
        for ch in src.children:
            c = ch.copy(); c.data = ch.data; bpy.context.scene.collection.objects.link(c); c.parent = None
            M = __import__("mathutils").Matrix
            # keep the importer's axis rotation (it sits on the Empty), drop only the Empty's position
            c.matrix_world = M.Translation((x, y, 0)) @ M.Rotation(rot, 4, "Z") @ M.Translation(-src.matrix_world.translation) @ ch.matrix_world
            new.append(c)
        return new
    P = 9.0
    # grid lines x = 0, 9, 18, 27 ; y = 0, 9, 18, 27. Walls: (orientation, i, j): 'h' along x between nodes (i,j)-(i+1,j); 'v' along y
    walls = [("h", 0, 0), ("h", 1, 0), ("h", 2, 0), ("v", 0, 0), ("v", 0, 1), ("v", 0, 2), ("h", 0, 2), ("v", 2, 1), ("h", 1, 1), ("v", 3, 0), ("v", 3, 1), ("h", 2, 3), ("h", 0, 3), ("v", 3, 2)]
    names = ["bamboo_wall_A", "bamboo_wall_B", "bamboo_wall_C"]
    for k, (o, i, j) in enumerate(walls):
        if o == "h": place(names[k % 3], i * P + P / 2, j * P, (k % 2) * math.pi)
        else: place(names[k % 3], i * P, j * P + P / 2, math.pi / 2 + (k % 2) * math.pi)
    place("maze_gate", 13.5, 27.0, 0.0)
    for e in list(kit.values()):
        for ch in list(e.children): bpy.data.objects.remove(ch, do_unlink=True)
        bpy.data.objects.remove(e, do_unlink=True)
    bpy.ops.mesh.primitive_plane_add(size=120, location=(13.5, 13.5, 0)); g = bpy.context.active_object
    m = bpy.data.materials.new("lawn"); m.diffuse_color = (0.18, 0.36, 0.12, 1); g.data.materials.append(m)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=5.2, location=(4.5, 13.5, 2.6)); fig = bpy.context.active_object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=(4.5, 13.5, 5.7)); head = bpy.context.active_object
    mf = bpy.data.materials.new("figure"); mf.diffuse_color = (0.75, 0.75, 0.78, 1)
    for o in (fig, head): o.data.materials.append(mf)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "TEXTURE"; sc.display.shading.light = "STUDIO"
    sc.display.shading.show_shadows = True; sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 22
    shots = (("prev_bamboo_corridor.png", (4.5, 24.0, 5.6), (4.5, 8.0, 4.5)),
             ("prev_bamboo_entrance.png", (13.5, 44.0, 6.0), (13.5, 20.0, 6.0)),
             ("prev_bamboo_above.png", (-14.0, 44.0, 38.0), (13.5, 13.5, 4.0)))
    for fn, loc, target in shots:
        cam.location = loc
        cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
