"""Oct 5 2026 (Shannon: lifeguard "should have more zinc on his nose ... even"): find the nose in the prepped mesh,
collect the UV triangles of a symmetric band across the nose bridge, and render a face close-up.
Run: blender --background --python paint_zinc.py -- <dir> <name> <mode: dump|render> [png for render] [out png]
dump  -> <dir>/zinc_faces.json  (nose tip, band params, UV triangles)
render-> textured close-up of the face from the front"""
import bpy, bmesh, sys, os, json, math, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
D, NAME, MODE = argv[0], argv[1], argv[2]
LOG = os.path.join(D, "zinc_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(D, NAME + ".blend"))
    sq = bpy.data.objects["Squirrel"]
    me = sq.data
    vs = me.vertices
    # nose tip = most forward vertex in the upper head
    NX = float(os.environ.get("ZINC_NX", "0")); NZ = float(os.environ.get("ZINC_NZ", "1.8"))
    head = [v for v in vs if abs(v.co.x - NX) < 0.15 and abs(v.co.z - NZ) < 0.18]
    tip = min(head, key=lambda v: v.co.y).co.copy()
    log(f"nose tip {tuple(round(c, 3) for c in tip)}")
    if MODE == "dump":
        # band across the nose bridge: centred on the snout's x, from just above the dark nose up toward the eyes
        BX, Z0, Z1, HW = tip.x, tip.z + 0.04, tip.z + 0.14, 0.095
        me.calc_loop_triangles()
        uv = me.uv_layers.active.data
        tris = []
        for lt in me.loop_triangles:
            ps = [vs[i].co for i in lt.vertices]
            c = sum(ps, Vector()) / 3
            if Z0 - 0.06 <= c.z <= Z1 + 0.06 and abs(c.x - BX) <= HW + 0.08 and c.y < tip.y + 0.32 and lt.normal.y < 0.1:
                tris.append({"uv": [[uv[l].uv.x, uv[l].uv.y] for l in lt.loops], "p": [list(q) for q in ps], "n": list(lt.normal)})
        json.dump({"tip": list(tip), "band": [BX, Z0, Z1, HW], "tris": tris}, open(os.path.join(D, "zinc_faces.json"), "w"))
        log(f"band x {BX:.3f}+-{HW} z {Z0:.3f}..{Z1:.3f}: {len(tris)} triangles")
    else:
        png, out = argv[3], argv[4]
        tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
        tex.image = bpy.data.images.load(png)
        for o in list(bpy.data.objects):
            if o.type == "CAMERA" or o.type == "LIGHT": bpy.data.objects.remove(o)
        cam_d = bpy.data.cameras.new("C"); cam = bpy.data.objects.new("C", cam_d); bpy.context.scene.collection.objects.link(cam)
        target = tip + Vector((0, 0.15, 0.05))
        cam.location = target + Vector((0, -1.6, 0.25))
        d = target - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam_d.lens = 60
        sc = bpy.context.scene; sc.camera = cam
        sc.render.engine = "BLENDER_WORKBENCH"
        sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "TEXTURE"
        sc.render.resolution_x = sc.render.resolution_y = 700
        sc.render.filepath = out
        bpy.ops.render.render(write_still=True)
    log("ZINC_DONE")
except Exception:
    log(traceback.format_exc())
