"""Rig Chompy (croc.blend from prep_croc.py): spine (Hips, Chest, Neck, Head), a hinged Jaw, five tail bones following
the curled tail, and 3-bone sprawled legs. Auto (heat) weights for the body; the head and jaw are weighted by hand:
everything in front of the neck follows the Head, and whatever lies under the mouth plane follows the Jaw.
Exports croc_rigged.fbx (embedded 1k texture, same settings as the squirrels) and renders a bone overlay sheet and
test poses. Pose rotations use CROC-SPACE axes (left=+X, up=+Z, fwd=-Y), the same numbers the Roblox script uses.
Run: blender --background --python rig_croc.py -- <out_dir> [poses_only]"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]; POSES_ONLY = len(argv) > 1 and argv[1] == "poses_only"
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
LEFT, UP, FWD = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0))

# joints measured from probe_log.txt (croc-space, studs)
B = {
    "Hips":  ((0, 10.0, 1.80), (0, 7.8, 2.30), None),
    "Chest": ((0, 7.8, 2.30), (0, 5.6, 3.10), "Hips"),
    "Neck":  ((0, 5.6, 3.10), (0, 4.4, 3.60), "Chest"),
    "Head":  ((0, 4.4, 3.60), (0, 0.3, 3.45), "Neck"),
    "Jaw":   ((0, 3.6, 3.15), (0, 1.25, 1.60), "Head"),
    "Tail1": ((0, 10.0, 1.80), (-0.65, 11.8, 1.85), "Hips"),
    "Tail2": ((-0.65, 11.8, 1.85), (-1.15, 13.4, 2.30), "Tail1"),
    "Tail3": ((-1.15, 13.4, 2.30), (-0.60, 14.7, 3.35), "Tail2"),
    "Tail4": ((-0.60, 14.7, 3.35), (0.90, 15.3, 4.30), "Tail3"),
    "Tail5": ((0.90, 15.3, 4.30), (2.20, 14.9, 4.55), "Tail4"),
    "FrontUpper.L": ((1.20, 6.2, 2.50), (1.85, 5.8, 1.40), "Chest"),
    "FrontLower.L": ((1.85, 5.8, 1.40), (2.15, 5.0, 0.45), "FrontUpper.L"),
    "FrontFoot.L":  ((2.15, 5.0, 0.45), (2.60, 3.6, 0.12), "FrontLower.L"),
    "FrontUpper.R": ((-1.20, 6.2, 2.50), (-1.80, 5.8, 1.40), "Chest"),
    "FrontLower.R": ((-1.80, 5.8, 1.40), (-2.05, 4.9, 0.45), "FrontUpper.R"),
    "FrontFoot.R":  ((-2.05, 4.9, 0.45), (-2.40, 3.45, 0.12), "FrontLower.R"),
    "HindUpper.L":  ((1.20, 9.3, 2.20), (2.00, 8.7, 1.35), "Hips"),
    "HindLower.L":  ((2.00, 8.7, 1.35), (2.30, 9.2, 0.45), "HindUpper.L"),
    "HindFoot.L":   ((2.30, 9.2, 0.45), (2.75, 8.1, 0.10), "HindLower.L"),
    "HindUpper.R":  ((-1.20, 9.3, 2.20), (-2.00, 8.8, 1.35), "Hips"),
    "HindLower.R":  ((-2.00, 8.8, 1.35), (-2.40, 9.1, 0.45), "HindUpper.R"),
    "HindFoot.R":   ((-2.40, 9.1, 0.45), (-2.95, 8.0, 0.10), "HindLower.R"),
}
ORDER = list(B.keys())
# mouth plane (side view): through (y 1.2, z 2.45) and the hinge (y 3.6, z 3.2)
def mouth_z(y): return 2.45 + (y - 1.2) * (3.2 - 2.45) / (3.6 - 1.2)
def smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a))); return t * t * (3 - 2 * t)

def build_rig(croc):
    arm_data = bpy.data.armatures.new("CrocRig"); arm = bpy.data.objects.new("CrocRig", arm_data)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in B.items():
        b = arm_data.edit_bones.new(name); b.head = Vector(h); b.tail = Vector(t); b.roll = 0; eb[name] = b
    for name, (h, t, parent) in B.items():
        if parent: eb[name].parent = eb[parent]; eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); croc.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    vg = croc.vertex_groups; gi = {g.index: g.name for g in vg}
    zero = [v.index for v in croc.data.vertices if sum(g.weight for g in v.groups) < 0.01]
    log(f"auto weights: {len(zero)} / {len(croc.data.vertices)} vertices unweighted")
    # hand weights for the head and jaw
    head_n = jaw_n = 0
    for v in croc.data.vertices:
        c = v.co
        cur = {gi[g.group]: g.weight for g in v.groups if g.weight > 0}
        cur.pop("Jaw", None)                                   # the jaw only gets what the mouth plane gives it
        tot = sum(cur.values())
        if tot > 0: cur = {k: w / tot for k, w in cur.items()}
        if c.y < 4.8 and c.z > 1.0 and abs(c.x) < 2.4:
            hr = 1 - smooth(3.9, 4.8, c.y)
            s = c.z - mouth_z(c.y)
            jaw = (1 - smooth(-0.12, 0.12, s)) * (1 - smooth(3.4, 4.2, c.y))
            new = {k: w * (1 - hr) for k, w in cur.items()}
            new["Head"] = new.get("Head", 0) + hr * (1 - jaw)
            new["Jaw"] = new.get("Jaw", 0) + hr * jaw
            cur = new; head_n += 1
            if jaw > 0.5: jaw_n += 1
        elif not cur:
            # nothing from the heat solve: take the nearest bone segment
            best, bd = None, 1e9
            for name, (h, t, p) in B.items():
                a, b_ = Vector(h), Vector(t); ab = b_ - a
                u = max(0.0, min(1.0, (c - a).dot(ab) / ab.length_squared))
                d = (a + ab * u - c).length
                if d < bd: best, bd = name, d
            cur = {best: 1.0}
        # keep the strongest 4, drop crumbs, normalise
        top = sorted(cur.items(), key=lambda kv: -kv[1])[:4]
        top = [(k, w) for k, w in top if w >= 0.02] or top[:1]
        s_ = sum(w for k, w in top)
        for g in list(v.groups): vg[g.group].remove([v.index])
        for k, w in top:
            grp = vg.get(k) or vg.new(name=k)
            grp.add([v.index], w / s_, "REPLACE")
    log(f"head/jaw hand weights on {head_n} vertices, {jaw_n} mostly jaw")
    per = {g.name: 0 for g in vg}
    for v in croc.data.vertices:
        for g in v.groups:
            if g.weight > 0.5: per[vg[g.group].name] += 1
    log("vertices >50% per bone: " + ", ".join(f"{k} {n}" for k, n in per.items()))
    return arm

def rot_world(pb, axis, deg):
    if abs(deg) < 1e-6: return
    m = pb.matrix.copy(); loc = m.to_translation()
    R = Matrix.Rotation(math.radians(deg), 4, Vector(axis))
    m2 = R @ m; m2.translation = loc; pb.matrix = m2
    bpy.context.view_layer.update()
def pose(pb, name, pitch=0, yaw=0, roll=0):
    b = pb[name]
    rot_world(b, FWD, roll); rot_world(b, LEFT, pitch); rot_world(b, UP, yaw)

# pitch: about LEFT (+X), negative = front/tip UP;  yaw: about UP, positive turns +X toward +Y;  roll: about FWD (-Y)
POSES = {
    "rest": {},
    "shut": {"Jaw": dict(pitch=-22)},
    "chomp": {"Neck": dict(pitch=-6), "Head": dict(pitch=-10), "Jaw": dict(pitch=12)},
    "sway": {"Chest": dict(yaw=5), "Neck": dict(yaw=-4), "Head": dict(yaw=-10),
             "Tail1": dict(yaw=14), "Tail2": dict(yaw=16), "Tail3": dict(yaw=16), "Tail4": dict(yaw=12), "Tail5": dict(yaw=8)},
    "stepA": {"Hips": dict(yaw=-4), "Chest": dict(yaw=6),
              "FrontUpper.L": dict(yaw=-22, roll=16), "FrontLower.L": dict(roll=-8),
              "FrontUpper.R": dict(yaw=-16),
              "HindUpper.R": dict(yaw=22, roll=-16), "HindLower.R": dict(roll=8),
              "HindUpper.L": dict(yaw=16),
              "Tail1": dict(yaw=-10), "Tail2": dict(yaw=-10), "Tail3": dict(yaw=-8)},
}

def render(sc, path, cam_from, target, ortho=None, res=(1100, 700), up=(0, 0, 1)):
    sc.render.resolution_x, sc.render.resolution_y = res
    cam = sc.camera
    cam.location = Vector(cam_from)
    f = (Vector(target) - cam.location).normalized()
    r = f.cross(Vector(up)).normalized(); u = r.cross(f).normalized()
    M = Matrix((r, u, -f)).transposed().to_4x4()
    cam.rotation_mode = "QUATERNION"; cam.rotation_quaternion = M.to_quaternion()
    if ortho: cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else: cam.data.type = "PERSP"; cam.data.lens = 40
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)

try:
    open(LOG, "w").close()
    if POSES_ONLY:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "croc_rigged.blend"))
        arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
        croc = bpy.data.objects["Croc"]
    else:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "croc.blend"))
        for o in list(bpy.data.objects):
            if not (o.type == "MESH" and o.name == "Croc"): bpy.data.objects.remove(o)
        croc = bpy.data.objects["Croc"]
        bpy.context.view_layer.objects.active = croc; croc.select_set(True)
        arm = build_rig(croc)
        with open(os.path.join(OUTD, "bones.json"), "w") as f:
            json.dump({k: [list(v[0]), list(v[1]), v[2]] for k, v in B.items()}, f, indent=1)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "croc_rigged.blend"))
        bpy.ops.object.select_all(action="DESELECT"); croc.select_set(True); arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "croc_rigged.fbx"), use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
        log("exported croc_rigged.fbx")
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = True
    sc.render.image_settings.file_format = "PNG"
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 8, 0)); fl = bpy.context.active_object; fl.name = "Floor"
    fm = bpy.data.materials.new("Floor"); fm.diffuse_color = (0.33, 0.45, 0.28, 1); fl.data.materials.append(fm)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    # bone overlay: sticks + joint balls, rendered in x-ray over the rest pose
    stick_mat = bpy.data.materials.new("Stick"); stick_mat.diffuse_color = (1.0, 0.2, 0.6, 1)
    jaw_mat = bpy.data.materials.new("JawStick"); jaw_mat.diffuse_color = (0.1, 0.9, 1.0, 1)
    sticks = []
    for name, (h, t, p) in B.items():
        a, b_ = Vector(h), Vector(t); d = b_ - a
        bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=d.length, location=(a + b_) / 2)
        cyl = bpy.context.active_object; cyl.rotation_mode = "QUATERNION"; cyl.rotation_quaternion = d.to_track_quat("Z", "Y")
        cyl.data.materials.append(jaw_mat if name == "Jaw" else stick_mat); sticks.append(cyl)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, location=a); s_ = bpy.context.active_object
        s_.data.materials.append(jaw_mat if name == "Jaw" else stick_mat); sticks.append(s_)
    sh.show_xray = True; sh.xray_alpha = 0.35
    render(sc, os.path.join(OUTD, "bones_side.png"), (40, 8, 3), (0, 8, 3), ortho=17.5, res=(1600, 700))
    render(sc, os.path.join(OUTD, "bones_top.png"), (0, 8, 40), (0, 8, 0), ortho=17.5, res=(800, 1600), up=(0, -1, 0))
    render(sc, os.path.join(OUTD, "bones_front.png"), (0, -40, 3), (0, 0, 3), ortho=8.5, res=(1000, 800))
    sh.show_xray = False
    for s_ in sticks: bpy.data.objects.remove(s_)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    for name, spec in POSES.items():
        for b in pb: b.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        for bn in ORDER:
            if bn in spec: pose(pb, bn, **spec[bn])
        bpy.ops.object.mode_set(mode="OBJECT")
        render(sc, os.path.join(OUTD, f"pose_{name}_34.png"), (10, -7, 6.5), (0, 6.5, 2.0))
        render(sc, os.path.join(OUTD, f"pose_{name}_side.png"), (40, 8, 3), (0, 8, 3), ortho=17.5, res=(1600, 700))
        if name in ("stepA", "sway"):
            render(sc, os.path.join(OUTD, f"pose_{name}_top.png"), (0, 8, 40), (0, 8, 0), ortho=17.5, res=(800, 1600), up=(0, -1, 0))
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc()); log("RIG_FAILED")
