"""Rig a prepped Meshy squirrel (faces -Y, up Z, feet z=0, height 2.4) with a small idle rig:
Root -> Chest -> Neck -> Head ; Root -> Tail1 -> Tail2 ; and export colour + gray FBX for Roblox.
Renders rest + posed 3/4 views so the deformation can be checked.
Run: blender --background --python rig_squirrel.py -- <out_dir> <name> <tail_xmax> [body_x] [head_zmax] [tail_zmax] [head_ymax] [head_zmin]"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
TAIL_XMAX = float(argv[2]) if len(argv) > 2 else 9.0     # rainy-day: keep umbrella out of the tail cluster
BX = float(argv[3]) if len(argv) > 3 else 0.0            # where the body sits sideways: a big side prop (the kite)
                                                         # pushes the squirrel off the bbox centre, so the spine moves with it
HEAD_ZMAX = float(argv[4]) if len(argv) > 4 else 99.0    # a ceiling on the head / tail searches: a prop ABOVE the squirrel
TAIL_ZMAX = float(argv[5]) if len(argv) > 5 else 99.0    # (the parachute canopy) would otherwise drag both centroids up
HEAD_YMAX = float(argv[6]) if len(argv) > 6 else -0.55   # upright heads (the realtor) don't reach y -0.55: loosen the face search
HEAD_ZMIN = float(argv[7]) if len(argv) > 7 else 1.3     # ...and lift its floor so the chest/scarf stays out
TAIL_XMIN = float(argv[8]) if len(argv) > 8 else -9.0    # Oct 5: a tail that sits to one side, head back reaching y 0.45 (sailor crabber)
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def centroid(ps): return sum(ps, Vector()) / len(ps) if ps else None
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}.blend"))
    sq = bpy.data.objects["Squirrel"]
    for o in list(bpy.data.objects):
        if o != sq: bpy.data.objects.remove(o)      # grid bars + camera from prep
    pts = [v.co.copy() for v in sq.data.vertices]
    H = max(p.z for p in pts)
    head = [p for p in pts if p.y < HEAD_YMAX and HEAD_ZMIN < p.z < HEAD_ZMAX and abs(p.x - BX) < 0.5]
    hc = centroid(head)
    # env TAILBANDS "zmin,z1,z2" (Oct 5: Penny's tail curls low, z 0.4..1.7, under a wide hat brim)
    TZ0, TZ1, TZ2 = [float(v) for v in os.environ.get("TAILBANDS", "1.2,1.5,2.0").split(",")]
    tail = [p for p in pts if p.y > 0.2 and TZ0 < p.z < TAIL_ZMAX and TAIL_XMIN < p.x < TAIL_XMAX]
    t_low = centroid([p for p in tail if p.z < TZ1]) or Vector((0, 0.6, 1.3))
    t_mid = centroid([p for p in tail if TZ1 <= p.z < TZ2]) or Vector((0, 0.8, 1.8))
    t_tip = centroid([p for p in tail if p.z >= TZ2]) or Vector((0, 0.8, 2.3))
    log(f"body x {BX}; head centre {tuple(round(v,2) for v in hc)} n={len(head)}; tail low {tuple(round(v,2) for v in t_low)} mid {tuple(round(v,2) for v in t_mid)} tip {tuple(round(v,2) for v in t_tip)} n={len(tail)}")
    neck = Vector((BX, hc.y + 0.35, hc.z - 0.35))
    B = {
        "Root":  ((BX, 0.15, 0.30), (BX, 0.05, 0.90), None),
        "Chest": ((BX, 0.05, 0.90), (BX, -0.15, 1.35), "Root"),
        "Neck":  ((BX, -0.15, 1.35), tuple(neck), "Chest"),
        "Head":  (tuple(neck), (BX, hc.y - 0.15, hc.z + 0.45), "Neck"),
        "Tail1": ((t_low.x, 0.35, 0.95), tuple(t_mid), "Root"),
        "Tail2": (tuple(t_mid), tuple(t_tip + (t_tip - t_mid) * 0.4), "Tail1"),
    }
    json.dump({k: [list(h), list(t), p] for k, (h, t, p) in B.items()}, open(os.path.join(OUTD, "bones.json"), "w"), indent=1)
    arm_data = bpy.data.armatures.new("SquirrelRig"); arm = bpy.data.objects.new("SquirrelRig", arm_data)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in B.items():
        b = arm_data.edit_bones.new(name); b.head = Vector(h); b.tail = Vector(t); eb[name] = b
    for name, (h, t, parent) in B.items():
        if parent: eb[name].parent = eb[parent]; eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    zero = sum(1 for v in sq.data.vertices if not v.groups or sum(g.weight for g in v.groups) < 0.01)
    log(f"bound; vertices with no weight: {zero} / {len(sq.data.vertices)}")
    # anything unweighted (floating accessories) -> Chest, so it never gets left behind
    vg = sq.vertex_groups.get("Chest") or sq.vertex_groups.new(name="Chest")
    for v in sq.data.vertices:
        if not v.groups or sum(g.weight for g in v.groups) < 0.01: vg.add([v.index], 1.0, "REPLACE")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    # export: colour and gray (same rig, swap the image)
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    def export(tag, png):
        tex.image = bpy.data.images.load(png)
        bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True); arm.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}_{tag}.fbx"), use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    export("color", os.path.join(OUTD, f"{NAME}_1k.png"))
    export("gray", os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    tex.image = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    # test poses: rest and "alert" (head turned + tilted, tail swung)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 600, 600; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 50
    ctr = Vector((0, 0, H / 2))
    def shoot(path, off):
        camo.location = ctr + off
        camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
        sc.render.filepath = path; bpy.ops.render.render(write_still=True)
    LEFT, UP, FWD = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0))
    def rot_world(pb, axis, deg):
        m = pb.matrix.copy(); loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m; m2.translation = loc; pb.matrix = m2
        bpy.context.view_layer.update()
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    q34 = Vector((-5.5, -5.5, 2.2))
    shoot(os.path.join(OUTD, "pose_rest.png"), q34)
    rot_world(pb["Neck"], UP, 12); rot_world(pb["Head"], UP, 18); rot_world(pb["Head"], FWD, 12)
    rot_world(pb["Tail1"], UP, 18); rot_world(pb["Tail2"], UP, 22); rot_world(pb["Chest"], LEFT, -4)
    shoot(os.path.join(OUTD, "pose_alert.png"), q34)
    for b in pb: b.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    rot_world(pb["Tail1"], LEFT, -25); rot_world(pb["Tail2"], LEFT, -30); rot_world(pb["Head"], LEFT, -14)
    shoot(os.path.join(OUTD, "pose_tail.png"), Vector((7.5, -1.5, 1.8)))
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
