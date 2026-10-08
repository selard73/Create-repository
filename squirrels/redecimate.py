"""Second decimate pass for very dense Meshy models (7.7M tris: one collapse pass stops at ~22k).
Run: blender --background --python redecimate.py -- <blend> <target_tris>   (log: <blend>.redecimate.txt)"""
import bpy, sys, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
BL, TARGET = argv[0], int(argv[1])
LOG = BL + ".redecimate.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]
    bpy.context.view_layer.objects.active = sq
    for o in bpy.data.objects:
        o.select_set(o == sq)
    def tris():
        return sum(len(p.vertices) - 2 for p in sq.data.polygons)
    import bmesh
    bm = bmesh.new(); bm.from_mesh(sq.data)
    v0 = len(bm.verts)
    bound0 = sum(1 for e in bm.edges if e.is_boundary)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    v1 = len(bm.verts); bound1 = sum(1 for e in bm.edges if e.is_boundary)
    bm.to_mesh(sq.data); bm.free(); sq.data.update()
    steps = ["verts %d->%d boundary %d->%d" % (v0, v1, bound0, bound1)]
    for i in range(4):
        t = tris()
        steps.append(t)
        if t <= TARGET * 1.02:
            break
        m = sq.modifiers.new("Dec", "DECIMATE")
        m.ratio = TARGET / t
        m.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.shade_smooth()
    bpy.ops.wm.save_as_mainfile(filepath=BL)
    open(LOG, "w").write("REDECIMATE_DONE steps %s final %d\n" % (steps, tris()))
except Exception:
    open(LOG, "w").write(traceback.format_exc())
