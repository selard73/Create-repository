"""Rig the standing Meshy dog with 3-joint legs, measured from the mesh.
Bones: Hips, Chest, Neck, Head, Ear.L/R, Tail1, Tail2,
       FrontUpper/FrontLower/FrontPaw .L/.R, HindUpper/HindLower/HindPaw .L/.R
Then bind (auto weights), export standing_rigged.fbx, and render rest / walk / sit test poses.
All pose rotations use DOG-SPACE world axes (left=+X, up=+Z, fwd=-Y) so the same numbers port to Roblox.
Run: blender --background --python rig_standing.py -- <out_dir> [poses_only]"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD = argv[0]; POSES_ONLY = len(argv) > 1 and argv[1] == "poses_only"
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")

LEFT, UP, FWD = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0))

def centroid(ps):
    return sum(ps, Vector()) / len(ps) if ps else None

def measure(dog):
    pts = [v.co.copy() for v in dog.data.vertices]
    # torso yaw correction + recentre using torso points (above legs, between leg columns)
    torso = [p for p in pts if 1.6 < p.z < 3.2 and -0.5 < p.y < 1.9]
    front = centroid([p for p in torso if p.y < 0.4]); back = centroid([p for p in torso if p.y > 1.0])
    d = front - back                      # should point straight ahead: (0, -1, 0)
    corr = -math.atan2(d.x, -d.y)         # rotate about Z so d.x becomes 0
    log(f"torso front {tuple(round(v,2) for v in front)} back {tuple(round(v,2) for v in back)} yaw_corr_deg {math.degrees(corr):.1f}")
    if abs(corr) < math.radians(15):
        dog.matrix_world = Matrix.Rotation(corr, 4, "Z") @ dog.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        pts = [v.co.copy() for v in dog.data.vertices]
        torso = [p for p in pts if 1.6 < p.z < 3.2 and -0.5 < p.y < 1.9]
    cx = centroid(torso).x
    for v in dog.data.vertices: v.co.x -= cx
    pts = [v.co.copy() for v in dog.data.vertices]
    zmin = min(p.z for p in pts)
    for v in dog.data.vertices: v.co.z -= zmin
    pts = [v.co.copy() for v in dog.data.vertices]
    ymin = min(p.y for p in pts); ymax = max(p.y for p in pts); zmax = max(p.z for p in pts)
    log(f"after recentre: y {ymin:.2f}..{ymax:.2f} z max {zmax:.2f}")
    belly_f = min(p.z for p in pts if -0.05 < p.y < 0.4)
    belly_h = min(p.z for p in pts if 1.3 < p.y < 1.85)
    log(f"belly front {belly_f:.2f} hind {belly_h:.2f}")
    def zc(y):   # torso centre height at y
        sl = [p.z for p in pts if abs(p.y - y) < 0.15 and p.z > 1.0]
        return (min(sl) + max(sl)) / 2
    def leg(ysel, sgn, belly, tag):
        L = [p for p in pts if ysel(p.y) and p.z < belly - 0.1 and p.x * sgn > 0.02]
        def band(z0, z1):
            b = [p for p in L if z0 <= p.z < z1]
            return centroid(b) or centroid(L)
        H = belly
        low = band(0.0, 0.35); ank = band(0.42, 0.7); kne = band(0.62 * H, 0.8 * H); top = band(H - 0.35, H - 0.1)
        toe_y = min(p.y for p in L if p.z < 0.35)          # toes point forward (-Y)
        j = {
            "top":   Vector((top.x * 0.7, top.y + 0.1, H + 0.6)),
            "knee":  Vector((kne.x, kne.y - 0.05, 0.68 * H)),
            "ankle": Vector((ank.x, ank.y + 0.05, 0.5)),
            "toe":   Vector((low.x, toe_y + 0.15, 0.06)),
        }
        log(f"leg {tag} n={len(L)} " + " ".join(f"{k}={tuple(round(v,2) for v in p)}" for k, p in j.items()))
        return j
    FL = leg(lambda y: -1.45 < y < -0.05, +1, belly_f, "FL"); FR = leg(lambda y: -1.45 < y < -0.05, -1, belly_f, "FR")
    HL = leg(lambda y: 1.85 < y < 2.7, +1, belly_h, "HL"); HR = leg(lambda y: 1.85 < y < 2.7, -1, belly_h, "HR")
    head_pts = [p for p in pts if p.y < -1.35]
    hc = centroid(head_pts); hz = hc.z
    nose = min(head_pts, key=lambda p: p.y)
    earL = [p for p in head_pts if p.x > 0.55 and p.z > hz + 0.2]; earR = [p for p in head_pts if p.x < -0.55 and p.z > hz + 0.2]
    eL = centroid(earL) or Vector((1.0, -1.8, hz + 0.6)); eR = centroid(earR) or Vector((-1.0, -1.8, hz + 0.6))
    tail = [p for p in pts if p.y > 2.55 and p.z > 1.8]
    if tail:
        zmid = (min(q.z for q in tail) + max(q.z for q in tail)) / 2
        t_low = centroid([p for p in tail if p.z < zmid]) or Vector((0, 2.7, 2.8))
        t_tip = max(tail, key=lambda p: p.z)
    else:
        t_low = Vector((0, 2.7, 2.8)); t_tip = Vector((0, 2.9, 3.4))
    log(f"head centre {tuple(round(v,2) for v in hc)} nose {tuple(round(v,2) for v in nose)} earL {tuple(round(v,2) for v in eL)} earR {tuple(round(v,2) for v in eR)} tail {tuple(round(v,2) for v in t_low)} -> {tuple(round(v,2) for v in t_tip)}")
    y_hip = (HL["top"].y + HR["top"].y) / 2 - 0.15
    y_sh = (FL["top"].y + FR["top"].y) / 2
    B = {}
    B["Hips"]  = ((0, y_hip, zc(y_hip)), (0, 0.45, zc(0.45)), None)
    B["Chest"] = ((0, 0.45, zc(0.45)), (0, y_sh + 0.05, zc(y_sh) + 0.15), "Hips")
    B["Neck"]  = ((0, y_sh + 0.05, zc(y_sh) + 0.15), (0, -1.3, hz - 0.25), "Chest")
    B["Head"]  = ((0, -1.3, hz - 0.25), (nose.x * 0.5, nose.y + 0.35, nose.z + 0.1), "Neck")
    B["Ear.L"] = ((0.4, eL.y + 0.1, hz + 0.35), tuple(eL), "Head")
    B["Ear.R"] = ((-0.4, eR.y + 0.1, hz + 0.35), tuple(eR), "Head")
    B["Tail1"] = ((0, y_hip + 0.4, zc(y_hip) + 0.35), tuple(t_low), "Hips")
    B["Tail2"] = (tuple(t_low), tuple(t_tip), "Tail1")
    for nm, J, s, par in (("Front", FL, ".L", "Chest"), ("Front", FR, ".R", "Chest"), ("Hind", HL, ".L", "Hips"), ("Hind", HR, ".R", "Hips")):
        B[f"{nm}Upper{s}"] = (tuple(J["top"]), tuple(J["knee"]), par)
        B[f"{nm}Lower{s}"] = (tuple(J["knee"]), tuple(J["ankle"]), f"{nm}Upper{s}")
        B[f"{nm}Paw{s}"]   = (tuple(J["ankle"]), tuple(J["toe"]), f"{nm}Lower{s}")
    return B

def build_rig(dog, B):
    arm_data = bpy.data.armatures.new("HoundRig"); arm = bpy.data.objects.new("HoundRig", arm_data)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in B.items():
        b = arm_data.edit_bones.new(name); b.head = Vector(h); b.tail = Vector(t); eb[name] = b
    for name, (h, t, parent) in B.items():
        if parent: eb[name].parent = eb[parent]; eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT"); dog.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    zero = sum(1 for v in dog.data.vertices if not v.groups or sum(g.weight for g in v.groups) < 0.01)
    log(f"bound; vertices with no weight: {zero} / {len(dog.data.vertices)}")
    return arm

# ---- posing in dog-space world axes (same semantics as the Roblox script) ----
def rot_world(pb, axis, deg):
    if abs(deg) < 1e-6: return
    m = pb.matrix.copy(); loc = m.to_translation()
    R = Matrix.Rotation(math.radians(deg), 4, Vector(axis))
    m2 = R @ m; m2.translation = loc; pb.matrix = m2
    bpy.context.view_layer.update()
def move_world(pb, off):
    m = pb.matrix.copy(); m.translation = m.to_translation() + Vector(off); pb.matrix = m
    bpy.context.view_layer.update()
def pose(pb, name, pitch=0, yaw=0, roll=0, off=None):
    b = pb[name]
    if off: move_world(b, off)
    rot_world(b, FWD, roll); rot_world(b, LEFT, pitch); rot_world(b, UP, yaw)

ORDER = ["Hips", "Chest", "Neck", "Head", "Ear.L", "Ear.R", "Tail1", "Tail2",
         "FrontUpper.L", "FrontLower.L", "FrontPaw.L", "FrontUpper.R", "FrontLower.R", "FrontPaw.R",
         "HindUpper.L", "HindLower.L", "HindPaw.L", "HindUpper.R", "HindLower.R", "HindPaw.R"]

POSES = {
  "rest": {},
  "walk": {"Hips": dict(off=(0, 0, 0.05)), "Chest": dict(pitch=-2),
           "FrontUpper.L": dict(pitch=-28), "FrontLower.L": dict(pitch=22), "FrontPaw.L": dict(pitch=10),
           "FrontUpper.R": dict(pitch=24), "FrontLower.R": dict(pitch=-8),
           "HindUpper.R": dict(pitch=-24), "HindLower.R": dict(pitch=-14), "HindPaw.R": dict(pitch=40),
           "HindUpper.L": dict(pitch=22), "HindLower.L": dict(pitch=6), "HindPaw.L": dict(pitch=-10),
           "Tail1": dict(yaw=20), "Tail2": dict(yaw=15), "Ear.L": dict(roll=-15), "Ear.R": dict(roll=15)},
  "sit":  {"Hips": dict(pitch=-30, off=(0, 0.15, -1.35)), "Chest": dict(pitch=-22), "Neck": dict(pitch=22), "Head": dict(pitch=14),
           "FrontUpper.L": dict(pitch=48), "FrontPaw.L": dict(pitch=4), "FrontUpper.R": dict(pitch=48), "FrontPaw.R": dict(pitch=4),
           "HindUpper.L": dict(pitch=-40), "HindLower.L": dict(pitch=20), "HindPaw.L": dict(pitch=-1),
           "HindUpper.R": dict(pitch=-40), "HindLower.R": dict(pitch=20), "HindPaw.R": dict(pitch=-1),
           "Tail1": dict(pitch=30), "Tail2": dict(pitch=10)},
}

def render(sc, path, cam_from, target, ortho=None):
    cam = sc.camera
    cam.location = Vector(cam_from)
    f = (Vector(target) - cam.location).normalized()
    r = f.cross(Vector((0, 0, 1))).normalized(); u = r.cross(f).normalized()
    M = Matrix((r, u, -f)).transposed().to_4x4()      # camera X=right, Y=up, looks down -Z
    cam.rotation_mode = "QUATERNION"; cam.rotation_quaternion = M.to_quaternion()
    if ortho: cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else: cam.data.type = "PERSP"; cam.data.lens = 45
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)

try:
    open(LOG, "w").close()
    if POSES_ONLY:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "standing_rigged.blend"))
        arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    else:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "standing.blend"))
        for o in list(bpy.data.objects):
            if not (o.type == "MESH" and o.name == "Hound"): bpy.data.objects.remove(o)   # drop grid bars / camera
        dog = [o for o in bpy.data.objects if o.type == "MESH"][0]
        bpy.context.view_layer.objects.active = dog; dog.select_set(True)
        B = measure(dog)
        with open(os.path.join(OUTD, "bones.json"), "w") as f:
            json.dump({k: [list(v[0]), list(v[1]), v[2]] for k, v in B.items()}, f, indent=1)
        arm = build_rig(dog, B)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "standing_rigged.blend"))
        bpy.ops.object.select_all(action="DESELECT"); dog.select_set(True); arm.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "standing_rigged.fbx"), use_selection=True, path_mode="COPY", embed_textures=False,
                                 mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=False,
                                 add_leaf_bones=False, primary_bone_axis="Y", secondary_bone_axis="X", armature_nodetype="NULL",
                                 bake_anim=False, object_types={"ARMATURE", "MESH"})
        log("exported standing_rigged.fbx")
    # renders
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 700; sc.render.image_settings.file_format = "PNG"
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0)); fl = bpy.context.active_object
    fm = bpy.data.materials.new("Floor"); fm.diffuse_color = (0.55, 0.25, 0.18, 1); fl.data.materials.append(fm)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
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
        # measure the posed mesh: lowest points of rump / paws relative to the ground (z=0)
        dg = bpy.context.evaluated_depsgraph_get()
        dogo = [o for o in bpy.data.objects if o.type == "MESH" and o.name == "Hound"][0]
        ev = dogo.evaluated_get(dg); vs = [ev.matrix_world @ v.co for v in ev.data.vertices]
        ys = sorted(v.y for v in vs); span = ys[-1] - ys[0]
        rump = [v for v in vs if v.y > ys[-1] - 0.35 * span and abs(v.x) < 0.6]
        front = [v for v in vs if v.y < ys[0] + 0.5 * span]
        log(f"POSE {name}: lowest overall z {min(v.z for v in vs):.2f}, rump lowest z {min(v.z for v in rump):.2f}, front half lowest z {min(v.z for v in front):.2f}, head top z {max(v.z for v in vs):.2f}")
        render(sc, os.path.join(OUTD, f"pose_{name}_34.png"), (7.5, -7.5, 4.5), (0, 0.2, 2.2))
        render(sc, os.path.join(OUTD, f"pose_{name}_side.png"), (14, 0.2, 3.6), (0, 0.2, 1.9), ortho=7.5)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
