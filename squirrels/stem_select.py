"""Pick the cheek-side glasses stem (gold faces running back from the left rim), render it red, optionally delete it.
Run: blender -b --python stem_select.py -- <blend> <png> <out_prefix> <delete 0/1>"""
import bpy, sys, traceback, bmesh
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]; BL, PNG, OUT, DEL = argv[0], argv[1], argv[2], argv[3] == "1"; LOG = OUT + "_log.txt"
try:
    bpy.ops.wm.open_mainfile(filepath=BL)
    sq = bpy.data.objects["Squirrel"]; me = sq.data
    img = bpy.data.images.load(PNG); W, H = img.size; px = list(img.pixels)
    uv = me.uv_layers.active.data
    def gold(p):
        u = sum(uv[l].uv[0] for l in p.loop_indices) / p.loop_total; v = sum(uv[l].uv[1] for l in p.loop_indices) / p.loop_total
        x = min(W - 1, max(0, int(u * W))); y = min(H - 1, max(0, int(v * H))); i = (y * W + x) * 4
        r, g, b = px[i], px[i + 1], px[i + 2]
        return r > 0.35 and g > 0.25 and b < 0.6 * g and r > b * 1.6 and abs(r - g) < 0.35
    sel = [p.index for p in me.polygons if p.center.x < 0.06 and -0.52 < p.center.y < 0.25 and 1.65 < p.center.z < 2.15 and gold(p)]
    out = ["stem faces %d" % len(sel)]
    if sel:
        cs = [me.polygons[i].center for i in sel]
        out.append("bbox x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % (min(c.x for c in cs), max(c.x for c in cs), min(c.y for c in cs), max(c.y for c in cs), min(c.z for c in cs), max(c.z for c in cs)))
    if DEL:
        bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[bm.faces[i] for i in sel], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(me); bm.free(); me.update()
        bpy.ops.wm.save_as_mainfile(filepath=BL)
        out.append("deleted + saved")
    else:
        red = bpy.data.materials.new("Red"); red.diffuse_color = (1, 0, 0, 1); me.materials.append(red)
        for i in sel: me.polygons[i].material_index = len(me.materials) - 1
    for o in list(bpy.data.objects):
        if o.name != "Squirrel": bpy.data.objects.remove(o)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "MATERIAL" if not DEL else "TEXTURE"; sh.show_shadows = False
    if not DEL:
        m0 = me.materials[0]; m0.diffuse_color = (0.75, 0.7, 0.65, 1)
    sc.render.resolution_x = sc.render.resolution_y = 600; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); co = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(co); sc.camera = co
    cam.type = "ORTHO"; cam.ortho_scale = 0.9; C = Vector((0.25, -0.4, 1.78))
    for name, off in {"front": (0, -10, 0), "q34l": (-7, -7, 1.5), "left": (-10, 0, 0)}.items():
        co.location = C + Vector(off); co.rotation_euler = (C - co.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{OUT}_{name}.png"; bpy.ops.render.render(write_still=True)
    open(LOG, "w").write("\n".join(out) + "\n")
except Exception:
    open(LOG, "w").write(traceback.format_exc())
