"""Colour-aware weight fixes: each rule selects vertices by texture colour class (same classifier as probe_colors.py)
plus a box, and moves weight from some bones to one bone, hard or with a soft height fade. Re-exports colour + gray
FBX, renders previews and a head-turned pose, and logs per-class weights after.
Run: blender --background --python fix_by_color.py -- <out_dir> <name> <rules json file>
rule: {"classes": ["yellow", ...] or ["*"], "box": [x0,x1,y0,y1,z0,z1], "from": ["Head","Neck"], "to": "Chest",
       "soft": [z0, z1] (optional: keep fraction (z-z0)/(z1-z0) of the source weight inside the band)}"""
import bpy, sys, os, json, math, colorsys, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
RULES = json.load(open(argv[2]))
LOG = os.path.join(OUTD, "fixc_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


def cls(r, g, b, z):
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    h *= 360
    if s < 0.18:
        if v > 0.62:
            return "white-high" if z > 0.9 else "white-low"
        return "gray" if v > 0.22 else "dark"
    if 35 <= h < 70 and s > 0.35:
        return "yellow"
    if 15 <= h < 45:
        return "brown"
    if 190 <= h < 260:
        return "blue"
    if h >= 300 or h < 15:
        return "pink/red"
    return "other"


try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    me = sq.data
    gi = {g.index: g.name for g in sq.vertex_groups}
    img = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    W, H = img.size
    px = list(img.pixels)
    uvl = me.uv_layers.active.data
    acc = {}
    for loop in me.loops:
        u, v = uvl[loop.index].uv
        x = min(W - 1, max(0, int(u % 1.0 * W)))
        y = min(H - 1, max(0, int(v % 1.0 * H)))
        i = (y * W + x) * 4
        a = acc.setdefault(loop.vertex_index, [0.0, 0.0, 0.0, 0])
        a[0] += px[i]; a[1] += px[i + 1]; a[2] += px[i + 2]; a[3] += 1
    C = {vi: cls(a[0] / a[3], a[1] / a[3], a[2] / a[3], me.vertices[vi].co.z) for vi, a in acc.items()}

    def inbox(c, b):
        return b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5]

    for r in RULES:
        dst = sq.vertex_groups.get(r["to"]) or sq.vertex_groups.new(name=r["to"])
        moved = 0
        for v in me.vertices:
            if not inbox(v.co, r["box"]):
                continue
            if r["classes"] != ["*"] and C.get(v.index) not in r["classes"]:
                continue
            keep_frac = 0.0
            if "soft" in r:
                z0, z1 = r["soft"]
                keep_frac = max(0.0, min(1.0, (v.co.z - z0) / (z1 - z0)))
            take = 0.0
            for g in list(v.groups):
                nm = gi[g.group]
                if nm in r["from"] and g.weight > 0:
                    keep = g.weight * keep_frac
                    take += g.weight - keep
                    if keep > 1e-4:
                        sq.vertex_groups[nm].add([v.index], keep, "REPLACE")
                    else:
                        sq.vertex_groups[nm].remove([v.index])
            if take > 1e-4:
                cur = sum(g.weight for g in v.groups if gi[g.group] == r["to"])
                dst.add([v.index], min(1.0, cur + take), "REPLACE")
                moved += 1
        soft = (" soft " + str(r["soft"])) if "soft" in r else ""
        log(f"rule {r['classes']} box {r['box']} {'+'.join(r['from'])} -> {r['to']}{soft}: {moved} vertices")

    def w(vi, names):
        return sum(g.weight for g in me.vertices[vi].groups if gi[g.group] in names)

    by = {}
    for vi, c in C.items():
        by.setdefault(c, []).append(vi)
    log("after, per colour class (head = Head+Neck):")
    for c, vs in sorted(by.items(), key=lambda kv: -len(kv[1])):
        n = len(vs)
        log(f"   {c:11s} {n:5d}  head {sum(w(i, ('Head', 'Neck')) for i in vs) / n:.2f}  chest {sum(w(i, ('Chest',)) for i in vs) / n:.2f}"
            f"  root {sum(w(i, ('Root',)) for i in vs) / n:.2f}  tail {sum(w(i, ('Tail1', 'Tail2')) for i in vs) / n:.2f}")
    g_low = [vi for vi in by.get("gray", []) if me.vertices[vi].co.z < 0.9 and me.vertices[vi].co.y < 0.1]
    if g_low:
        log(f"   gray fur below z 0.9 in front half: {len(g_low)} verts, head {sum(w(i, ('Head', 'Neck')) for i in g_low) / len(g_low):.2f}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))

    tex = [n for n in me.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]

    def export(tag, png):
        tex.image = bpy.data.images.load(png)
        bpy.ops.object.select_all(action="DESELECT")
        sq.select_set(True); arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}_{tag}.fbx"), use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")

    export("color", os.path.join(OUTD, f"{NAME}_1k.png"))
    export("gray", os.path.join(OUTD, f"{NAME}_gray_1k.png"))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.resolution_x, sc.render.resolution_y = 700, 700
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o)
    cam = bpy.data.cameras.new("Cam")
    camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 60

    def shoot(path, off, ctr=Vector((0, 0, 1.15))):
        camo.location = ctr + off
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)

    for tag, png in (("color", f"{NAME}_1k.png"), ("gray", f"{NAME}_gray_1k.png")):
        tex.image = bpy.data.images.load(os.path.join(OUTD, png))
        shoot(os.path.join(OUTD, f"preview_{tag}.png"), Vector((-6.0, -7.0, 2.6)))
    tex.image = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))

    # head turned hard (much more than the game does) to prove what follows the head and what stays put
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones

    def rot_world(b, axis, deg):
        m = b.matrix.copy()
        loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m
        m2.translation = loc
        b.matrix = m2
        bpy.context.view_layer.update()

    rot_world(pb["Neck"], Vector((0, 0, 1)), 15)
    rot_world(pb["Head"], Vector((0, 0, 1)), 25)
    shoot(os.path.join(OUTD, "pose_after_front.png"), Vector((0.0, -8.5, 1.2)))
    shoot(os.path.join(OUTD, "pose_after_34.png"), Vector((-6.0, -7.0, 2.6)))
    log("FIXC_DONE")
except Exception:
    log(traceback.format_exc())
