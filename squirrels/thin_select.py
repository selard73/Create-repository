"""Select thin-wire geometry (ray thickness along -normal < T) inside a box; render it red, or delete it.
Run: blender -b --python thin_select.py -- <blend> <out_prefix> <delete 0/1> T x0 x1 y0 y1 z0 z1 [camx camy camz]"""
import bpy, sys, traceback, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index("--") + 1:]
BL, OUT, DEL = argv[0], argv[1], argv[2] == "1"; T = float(argv[3]); x0, x1, y0, y1, z0, z1 = map(float, argv[4:10])
LOG = OUT + "_log.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]; me = sq.data
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
    tree = BVHTree.FromBMesh(bm)
    thin = set()
    for v in bm.verts:
        c = v.co
        if not (x0 < c.x < x1 and y0 < c.y < y1 and z0 < c.z < z1): continue
        n = v.normal
        hit = tree.ray_cast(c - n * 0.001, -n, 0.2)
        if hit[0] is not None and hit[3] < T: thin.add(v.index)
    faces = [f.index for f in bm.faces if all(v.index in thin for v in f.verts)]
    cs = [bm.faces[i].calc_center_median() for i in faces]
    out = ["thin verts %d faces %d" % (len(thin), len(faces))]
    if cs: out.append("bbox x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % (min(c.x for c in cs), max(c.x for c in cs), min(c.y for c in cs), max(c.y for c in cs), min(c.z for c in cs), max(c.z for c in cs)))
    if DEL:
        bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.faces.ensure_lookup_table(); seen = set(); small = []
        for f in bm.faces:
            if f.index in seen: continue
            st = [f]; seen.add(f.index); isl = []
            while st:
                g = st.pop(); isl.append(g)
                for e in g.edges:
                    for h in e.link_faces:
                        if h.index not in seen: seen.add(h.index); st.append(h)
            if len(isl) < 40: small += isl
        out.append("leftover small islands faces removed: %d" % len(small))
        bmesh.ops.delete(bm, geom=small, context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(me); me.update(); bpy.ops.wm.save_as_mainfile(filepath=BL); out.append("deleted + saved")
    else:
        red = bpy.data.materials.new("Red"); red.diffuse_color = (1, 0, 0, 1); me.materials.append(red)
        for i in faces: me.polygons[i].material_index = len(me.materials) - 1
        me.materials[0].diffuse_color = (0.75, 0.7, 0.65, 1)
    bm.free()
    for o in list(bpy.data.objects):
        if o.name != "Squirrel": bpy.data.objects.remove(o)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE" if DEL else "MATERIAL"; sh.show_shadows = False
    sc.render.resolution_x = sc.render.resolution_y = 600; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); co = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(co); sc.camera = co
    cam.type = "ORTHO"; cam.ortho_scale = 0.9; C = Vector((0.0, -0.4, 1.85))
    for name, off in {"front": (0, -10, 0), "q34l": (-7, -7, 1.5), "left": (-10, 0, 0), "q34r": (7, -7, 1.5)}.items():
        co.location = C + Vector(off); co.rotation_euler = (C - co.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{OUT}_{name}.png"; bpy.ops.render.render(write_still=True)
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
