"""Straighten the dog so his spine runs along -Y (nose toward -Y, tail toward +Y), feet on z=0,
centred on x=0. Export pup_aligned.fbx/.obj and write a slice profile to align_log.txt.
Run: blender --background --python align_analyze.py -- <in.fbx> <out_dir>"""
import bpy, sys, os, math, traceback
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUTD = argv[0], argv[1]
LOG = os.path.join(OUTD, "align_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")

try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=IN)
    dog = [o for o in bpy.data.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = dog; dog.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pts = [dog.matrix_world @ v.co for v in dog.data.vertices]
    n = len(pts)
    mx = sum(p.x for p in pts) / n; my = sum(p.y for p in pts) / n
    # PCA on x,y
    sxx = sum((p.x - mx) ** 2 for p in pts); syy = sum((p.y - my) ** 2 for p in pts); sxy = sum((p.x - mx) * (p.y - my) for p in pts)
    ang = 0.5 * math.atan2(2 * sxy, sxx - syy)     # angle of the long axis from +X
    # rotate so the long axis lies along Y: rotate by (90deg - ang)
    rot = Matrix.Rotation(math.radians(90) - ang, 4, "Z")
    dog.matrix_world = rot @ dog.matrix_world
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pts = [v.co.copy() for v in dog.data.vertices]
    ys = sorted(p.y for p in pts); ylo, yhi = ys[0], ys[-1]
    # which end is the head? the end whose top 15% slice has the greater max z
    span = yhi - ylo
    zA = max(p.z for p in pts if p.y < ylo + 0.15 * span)
    zB = max(p.z for p in pts if p.y > yhi - 0.15 * span)
    if zB > zA:   # head is at +Y; flip 180 about Z so head goes to -Y
        dog.matrix_world = Matrix.Rotation(math.pi, 4, "Z") @ dog.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        pts = [v.co.copy() for v in dog.data.vertices]
    # centre x, feet on ground
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2
    zmin = min(p.z for p in pts)
    for v in dog.data.vertices:
        v.co.x -= cx; v.co.z -= zmin
    pts = [v.co.copy() for v in dog.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    log(f"aligned bbox min {tuple(round(v,2) for v in lo)} max {tuple(round(v,2) for v in hi)}  (nose toward -Y)")
    # slice profile along Y
    log("y_from  y_to   n    zmin  zmax  xmin  xmax")
    step = 0.25
    y = lo.y
    while y < hi.y:
        sl = [p for p in pts if y <= p.y < y + step]
        if sl:
            log(f"{y:6.2f} {y+step:6.2f} {len(sl):5d} {min(p.z for p in sl):5.2f} {max(p.z for p in sl):5.2f} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f}")
        y += step
    # head region detail: for y slices near the nose, z profile
    log("head detail (y < nose+2.2): z_from z_to n xmin xmax ymin ymax")
    head = [p for p in pts if p.y < lo.y + 2.2]
    z = 0.0
    while z < hi.z:
        sl = [p for p in head if z <= p.z < z + 0.25]
        if sl:
            log(f"{z:5.2f} {z+0.25:5.2f} {len(sl):5d} {min(p.x for p in sl):5.2f} {max(p.x for p in sl):5.2f} {min(p.y for p in sl):5.2f} {max(p.y for p in sl):5.2f}")
        z += 0.25
    dog.name = "Hound"
    bpy.ops.object.select_all(action="DESELECT"); dog.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "pup_aligned.fbx"), use_selection=True, path_mode="COPY", embed_textures=False,
                             mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True)
    bpy.ops.wm.obj_export(filepath=os.path.join(OUTD, "pup_aligned.obj"), export_selected_objects=True, export_materials=True,
                          export_normals=True, export_uv=True, forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "pup_aligned.blend"))
    log("ALIGN_DONE")
except Exception:
    log(traceback.format_exc())
