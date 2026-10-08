"""Rig the decimated Meshy octopus (Polpo Brontolone; faces -Y, up +Z, centred at the origin, ~1.9 wide): Root (mantle) +
Head (the dome) + 8 tentacles x 3 bones found from the mesh itself (an angle histogram of the arm vertices), weights by
position (radial blend along each arm, like the whale's spine), export octopus_color.fbx for Roblox, render pose checks,
write octopus_data.json.
Run: blender --background --python rig_octopus.py -- <in.fbx> <png> <outdir>"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, PNG, OUTD = argv[0], argv[1], argv[2]
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def clamp(v, a, b): return max(a, min(b, v))
def angdiff(a, b):
    d = (a - b + math.pi) % (2 * math.pi) - math.pi
    return abs(d)
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.fbx(filepath=IN, use_custom_normals=False)
    except Exception:
        bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    w = bpy.context.view_layer.objects.active
    for o in list(bpy.data.objects):
        if o != w: bpy.data.objects.remove(o)
    w.name = "Octopus"; w.data.name = "Octopus"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pts = [v.co.copy() for v in w.data.vertices]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (mn + mx) / 2
    for v in w.data.vertices: v.co -= ctr
    pts = [v.co.copy() for v in w.data.vertices]
    mn -= ctr; mx -= ctr
    W, H = mx.x - mn.x, mx.z - mn.z
    log(f"verts {len(pts)} tris {sum(len(p.vertices)-2 for p in w.data.polygons)} bbox min {tuple(round(v,3) for v in mn)} max {tuple(round(v,3) for v in mx)} width {W:.3f} height {H:.3f}")
    # material: single image texture = our 1k png
    mat = w.data.materials[0] if w.data.materials and w.data.materials[0] else bpy.data.materials.new("OctopusMat")
    if not w.data.materials: w.data.materials.append(mat)
    for i in range(len(w.data.materials)): w.data.materials[i] = mat
    mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes):
        if n.type not in ("BSDF_PRINCIPLED", "OUTPUT_MATERIAL"): nt.nodes.remove(n)
    bsdf = [n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"][0]
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.55
    # --- the arms: everything outside the head ball, or low and away from the middle ---
    HEAD_R = float(os.environ.get("HEAD_R", "0.42"))      # the dome's radius in x/y
    ARM_R0 = float(os.environ.get("ARM_R0", "0.25"))      # where an arm leaves the mantle (low vertices only)
    ARM_Z = float(os.environ.get("ARM_Z", "-0.15"))       # below this, r > ARM_R0 is arm
    def rad(p): return math.hypot(p.x, p.y)
    def isarm(p): return rad(p) > HEAD_R or (rad(p) > ARM_R0 and p.z < ARM_Z)
    arm_idx = [i for i, p in enumerate(pts) if isarm(p)]
    # angle histogram of the outer arm vertices -> 8 peaks
    NB = 72
    hist = [0] * NB
    for i in arm_idx:
        p = pts[i]
        if rad(p) > 0.5:
            hist[int(((math.atan2(p.y, p.x) + 2 * math.pi) % (2 * math.pi)) / (2 * math.pi) * NB) % NB] += 1
    sm = [(hist[(i - 1) % NB] + 2 * hist[i] + hist[(i + 1) % NB]) / 4 for i in range(NB)]
    cand = sorted(range(NB), key=lambda i: -sm[i])
    peaks = []
    for i in cand:
        a = (i + 0.5) / NB * 2 * math.pi
        if sm[i] <= 0: break
        if all(angdiff(a, b) > math.radians(22) for b in peaks): peaks.append(a)
        if len(peaks) == 8: break
    peaks.sort()
    log(f"histogram {[int(v) for v in sm]}")
    log(f"peaks (deg) {[round(math.degrees(a),1) for a in peaks]} n={len(peaks)}")
    # refine each peak = the mean angle of its sector's outer vertices
    def nearest_peak(p):
        a = math.atan2(p.y, p.x)
        return min(range(len(peaks)), key=lambda k: angdiff(a, peaks[k]))
    sect = {k: [] for k in range(len(peaks))}
    for i in arm_idx: sect[nearest_peak(pts[i])].append(i)
    for k in range(len(peaks)):
        outer = [pts[i] for i in sect[k] if rad(pts[i]) > 0.5]
        if outer:
            sx = sum(math.cos(math.atan2(p.y, p.x)) for p in outer); sy = sum(math.sin(math.atan2(p.y, p.x)) for p in outer)
            peaks[k] = math.atan2(sy, sx)
    order = sorted(range(len(peaks)), key=lambda k: peaks[k]); peaks = [peaks[k] for k in order]; sect = {j: sect[order[j]] for j in range(len(order))}
    log(f"refined peaks (deg) {[round(math.degrees(a),1) for a in peaks]}")
    # joints per arm: r0 at the mantle, then thirds to the tip; z = the arm's mean height at that radius
    arms = []
    for k, a in enumerate(peaks):
        rs = sorted(rad(pts[i]) for i in sect[k])
        rmax = rs[int(len(rs) * 0.985)] if rs else 0.9
        rj = [ARM_R0 + 0.03, ARM_R0 + 0.03 + (rmax - ARM_R0 - 0.03) / 3, ARM_R0 + 0.03 + 2 * (rmax - ARM_R0 - 0.03) / 3, rmax]
        joints = []
        lastz = ARM_Z - 0.12
        for r in rj:
            zs = [pts[i].z for i in sect[k] if abs(rad(pts[i]) - r) < 0.06]
            z = sum(zs) / len(zs) if zs else lastz
            lastz = z
            joints.append(Vector((r * math.cos(a), r * math.sin(a), z)))
        arms.append({"angle": a, "rmax": rmax, "r": rj, "joints": joints, "n": len(sect[k])})
        log(f"arm {k}: angle {math.degrees(a):.1f} n={len(sect[k])} rmax {rmax:.3f} joints {[tuple(round(v,3) for v in j) for j in joints]}")
    headtop = max(pts, key=lambda p: p.z)
    front = min(pts, key=lambda p: p.y)
    log(f"head top {tuple(round(v,3) for v in headtop)}; front-most {tuple(round(v,3) for v in front)}; bottom z {mn.z:.3f}")
    # --- bones ---
    B = {"Root": ((0, 0, -0.1), (0, 0, 0.1), None), "Head": ((0, 0, 0.12), (0, 0, 0.42), "Root")}
    for k, arm in enumerate(arms):
        j = arm["joints"]
        B[f"Arm{k}a"] = (tuple(j[0]), tuple(j[1]), "Root")
        B[f"Arm{k}b"] = (tuple(j[1]), tuple(j[2]), f"Arm{k}a")
        B[f"Arm{k}c"] = (tuple(j[2]), tuple(j[3]), f"Arm{k}b")
    arm_data = bpy.data.armatures.new("OctopusRig"); arm = bpy.data.objects.new("OctopusRig", arm_data)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in B.items():
        b = arm_data.edit_bones.new(name); b.head = Vector(h); b.tail = Vector(t); eb[name] = b
    for name, (h, t, parent) in B.items():
        if parent: eb[name].parent = eb[parent]; eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    # --- weights ---
    vg = {name: w.vertex_groups.new(name=name) for name in B}
    HZ0, HZ1 = float(os.environ.get("HEAD_Z0", "0.05")), float(os.environ.get("HEAD_Z1", "0.22"))
    armof = {}
    for k in sect:
        for i in sect[k]: armof[i] = k
    for v in w.data.vertices:
        p = v.co; wts = {}
        k = armof.get(v.index)
        if k is None:
            t = clamp((p.z - HZ0) / (HZ1 - HZ0), 0.0, 1.0)
            wts = {"Root": 1 - t, "Head": t}
        else:
            rj = arms[k]["r"]
            names = ["Root", f"Arm{k}a", f"Arm{k}b", f"Arm{k}c"]
            cs = [rj[0] - 0.08, (rj[0] + rj[1]) / 2, (rj[1] + rj[2]) / 2, (rj[2] + rj[3]) / 2]
            r = rad(p)
            if r <= cs[0]: wts = {names[0]: 1.0}
            elif r >= cs[-1]: wts = {names[-1]: 1.0}
            else:
                for i in range(len(cs) - 1):
                    if cs[i] <= r < cs[i + 1]:
                        t = (r - cs[i]) / (cs[i + 1] - cs[i]); wts = {names[i]: 1 - t, names[i + 1]: t}; break
        for name, val in wts.items():
            if val > 0.001: vg[name].add([v.index], val, "REPLACE")
    mod = w.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    w.parent = arm
    cnt = {n: sum(1 for v in w.data.vertices for g in v.groups if g.group == vg[n].index and g.weight > 0.5) for n in B}
    log(f"dominant counts {cnt}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "octopus_rigged.blend"))
    json.dump({"width": W, "height": H, "bbox_min": list(mn), "bbox_max": list(mx), "head_top": list(headtop), "front": list(front),
               "arms": [{"angle_deg": math.degrees(a["angle"]), "rmax": a["rmax"], "joints": [list(j) for j in a["joints"]]} for a in arms],
               "bones": {k: [list(h), list(t), p] for k, (h, t, p) in B.items()}},
              open(os.path.join(OUTD, "octopus_data.json"), "w"), indent=1)
    bpy.ops.object.select_all(action="DESELECT"); w.select_set(True); arm.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "octopus_color.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    # --- pose renders ---
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 800, 560; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 45
    def shoot(path, off, target=Vector((0, 0, 0))):
        camo.location = target + off
        camo.rotation_euler = (target - camo.location).to_track_quat("-Z", "Z").to_euler()
        sc.render.filepath = path; bpy.ops.render.render(write_still=True)
    def rot_world(pb, axis, deg):
        m = pb.matrix.copy(); loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m; m2.translation = loc; pb.matrix = m2
        bpy.context.view_layer.update()
    def reset():
        for b in pb: b.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    q34 = Vector((2.4, -3.0, 1.5)); frontv = Vector((0, -4.0, 0.6)); topv = Vector((0, -0.01, 4.2))
    shoot(os.path.join(OUTD, "pose_rest.png"), q34); shoot(os.path.join(OUTD, "pose_rest_front.png"), frontv); shoot(os.path.join(OUTD, "pose_rest_top.png"), topv)
    def curl(sign, degs=(25, 35, 45)):
        for k, a in enumerate(arms):
            ax = Vector((-math.sin(a["angle"]), math.cos(a["angle"]), 0))     # tangential: a turn about it lifts/drops the arm
            for s, d in zip("abc", degs): rot_world(pb[f"Arm{k}{s}"], ax, sign * d)
    curl(1); shoot(os.path.join(OUTD, "pose_curl_pos.png"), q34); shoot(os.path.join(OUTD, "pose_curl_pos_front.png"), frontv); reset()
    curl(-1); shoot(os.path.join(OUTD, "pose_curl_neg.png"), q34); shoot(os.path.join(OUTD, "pose_curl_neg_front.png"), frontv); reset()
    # grab: the two arms nearest the front (-Y) rise, the head nods forward
    fronts = sorted(range(len(arms)), key=lambda k: angdiff(arms[k]["angle"], -math.pi / 2))[:2]
    for k in fronts:
        a = arms[k]; ax = Vector((-math.sin(a["angle"]), math.cos(a["angle"]), 0))
        for s, d in zip("abc", (-40, -45, -50)): rot_world(pb[f"Arm{k}{s}"], ax, d)
    rot_world(pb["Head"], Vector((1, 0, 0)), -10)
    shoot(os.path.join(OUTD, "pose_grab.png"), q34); shoot(os.path.join(OUTD, "pose_grab_front.png"), frontv); reset()
    log(f"front arms {fronts}")
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
