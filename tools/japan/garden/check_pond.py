"""Check out_pond/pond_ring.fbx: every piece closed (no boundary / non-manifold edges), normals outward (signed volume > 0), and a
workbench preview render with a water disc at 3.9 and the court at 3.09. Writes out_pond/check_log.txt + prev_pond_*.png."""
import bpy, bmesh, math, os, traceback
from mathutils import Vector
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "out_pond")
LOG = os.path.join(OUT, "check_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n"); print(m)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(OUT, "pond_ring.fbx"), axis_forward="-Z", axis_up="Y")
    bad = []
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        bm = bmesh.new(); bm.from_mesh(o.data); bm.transform(o.matrix_world)
        open_e = sum(1 for e in bm.edges if not e.is_manifold)
        vol = bm.calc_volume(signed=True)
        if open_e or vol <= 0: bad.append(f"{o.name}: {open_e} open edges, volume {vol:.2f}")
        bm.free()
    log(f"checked {len([o for o in bpy.data.objects if o.type == 'MESH'])} meshes; problems: {bad if bad else 'none'}")
    sc = bpy.context.scene
    def disc(name, r, z, col, alpha=1.0):
        bpy.ops.mesh.primitive_circle_add(vertices=96, radius=r, fill_type="NGON", location=(0, 0, z)); o = bpy.context.active_object; o.name = name
        m = bpy.data.materials.new(name); m.diffuse_color = (col[0], col[1], col[2], alpha); o.data.materials.append(m)
        return o
    disc("water", 36.5, 3.9, (0.16, 0.41, 0.44), 0.7)
    disc("court", 70, 3.09, (0.45, 0.38, 0.32))
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"; sc.display.shading.light = "STUDIO"
    sc.display.shading.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 560
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 24
    for fn, loc, target in (("prev_pond_edge.png", (-58, -8, 9), (0, 0, 3)), ("prev_pond_close.png", (-46, -10, 6.2), (-36, 0, 3.8)),
                            ("prev_pond_above.png", (0, -80, 75), (0, 0, 0))):
        cam.location = loc
        d = Vector(target) - Vector(loc)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, fn); bpy.ops.render.render(write_still=True); log("shot " + fn)
    log("CHECK_DONE")
except Exception:
    log(traceback.format_exc()); log("CHECK_FAILED")
