"""Crown fix: fade stray Chest/Root weight on head fur back to the Head bone.
Only touches vertices that are already mostly head (Head+Neck >= 0.2) and not tail (Tail < 0.05), so props that were
deliberately moved to the body (Head+Neck ~ 0) and the tail are left alone. Below Z0 nothing changes; above Z1 all
body weight moves to Head; linear in between. Optional force boxes move all Chest/Root weight inside them to Head
(for head parts that an older radius rule stripped completely). Logs before/after, re-exports colour + gray FBX,
renders previews plus head-turned front and back-3/4 views.
Run: blender --background --python fix_crown.py -- <out_dir> <name> <z0> <z1> ['[[x0,x1,y0,y1,z0,z1], ...]']"""
import bpy, sys, os, json, math, traceback
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME, Z0, Z1 = argv[0], argv[1], float(argv[2]), float(argv[3])
FORCE = json.loads(argv[4]) if len(argv) > 4 and argv[4].strip() else []
LOG = os.path.join(OUTD, "crownfix_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    me = sq.data
    G = {g.index: g.name for g in sq.vertex_groups}
    head_g = sq.vertex_groups["Head"]

    def w(v, names):
        return sum(g.weight for g in v.groups if G[g.group] in names)

    def stats(label):
        zone = [v for v in me.vertices if v.co.z >= Z1 and w(v, ("Tail1", "Tail2")) < 0.05]
        mixed = [v for v in zone if 0.2 <= w(v, ("Head", "Neck")) <= 0.9 and w(v, ("Chest", "Root")) >= 0.1]
        body = [v for v in zone if w(v, ("Head", "Neck")) < 0.2 and w(v, ("Chest", "Root")) >= 0.5]
        band = [v for v in me.vertices if Z0 < v.co.z < Z1 and w(v, ("Tail1", "Tail2")) < 0.05
                and w(v, ("Head", "Neck")) >= 0.2 and w(v, ("Chest", "Root")) >= 0.1]
        mb = sum(w(v, ("Chest", "Root")) for v in mixed) / len(mixed) if mixed else 0.0
        log(f"{label}: zone z >= {Z1:.2f}: {len(zone)} verts, MIXED {len(mixed)} (mean body {mb:.2f}), BODY {len(body)}; "
            f"fade band {Z0:.2f}-{Z1:.2f}: {len(band)} partial verts")

    stats("BEFORE")
    # report: vertices just above the neck that are fully on the body (head parts stripped by an older rule?)
    near = [v for v in me.vertices if Z0 - 0.1 < v.co.z < Z1 + 0.2 and w(v, ("Tail1", "Tail2")) < 0.05
            and w(v, ("Head", "Neck")) < 0.2 and w(v, ("Chest", "Root")) >= 0.5 and v.co.y > -0.6]
    if near:
        cells = {}
        for v in near:
            k = (round(v.co.x / 0.25), round(v.co.y / 0.25), round(v.co.z / 0.25))
            cells[k] = cells.get(k, 0) + 1
        top = sorted(cells.items(), key=lambda kv: -kv[1])[:8]
        log(f"note: {len(near)} fully body-bound verts behind the face near the neck; cells " +
            ", ".join(f"({k[0] * 0.25:.2f},{k[1] * 0.25:.2f},{k[2] * 0.25:.2f})x{n}" for k, n in top))

    moved = 0
    for v in me.vertices:
        z = v.co.z
        if z <= Z0 or w(v, ("Tail1", "Tail2")) >= 0.05 or w(v, ("Head", "Neck")) < 0.2:
            continue
        f = max(0.0, min(1.0, (z - Z0) / (Z1 - Z0)))
        take = 0.0
        for g in list(v.groups):
            nm = G[g.group]
            if nm in ("Chest", "Root") and g.weight > 0:
                keep = g.weight * (1.0 - f)
                take += g.weight - keep
                if keep > 1e-4:
                    sq.vertex_groups[nm].add([v.index], keep, "REPLACE")
                else:
                    sq.vertex_groups[nm].remove([v.index])
        if take > 1e-4:
            cur = sum(g.weight for g in v.groups if G[g.group] == "Head")
            head_g.add([v.index], min(1.0, cur + take), "REPLACE")
            moved += 1
    log(f"faded body weight back to Head on {moved} vertices")

    for b in FORCE:
        n = 0
        for v in me.vertices:
            c = v.co
            if not (b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5]):
                continue
            take = 0.0
            for g in list(v.groups):
                nm = G[g.group]
                if nm in ("Chest", "Root") and g.weight > 0:
                    take += g.weight
                    sq.vertex_groups[nm].remove([v.index])
            if take > 1e-4:
                cur = sum(g.weight for g in v.groups if G[g.group] == "Head")
                head_g.add([v.index], min(1.0, cur + take), "REPLACE")
                n += 1
        log(f"force box {b}: {n} vertices moved to Head")

    stats("AFTER")
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
    head_ctr = Vector((0, -0.4, 1.7))
    shoot(os.path.join(OUTD, "pose_crown_back.png"), Vector((3.6, 4.6, 1.3)), head_ctr)
    shoot(os.path.join(OUTD, "pose_crown_front.png"), Vector((-3.6, -4.6, 0.9)), head_ctr)
    log("CROWN_FIX_DONE")
except Exception:
    log(traceback.format_exc())
