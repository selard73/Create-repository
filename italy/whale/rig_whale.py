"""Rig the decimated Meshy whale (faces -Y, up +Z, centred at the origin, ~1.9 long) with a spine chain + flippers,
weights by position (smooth along the body), export whale_color.fbx for Roblox, render pose checks, write whale_data.json.
Run: blender --background --python rig_whale.py -- <in.fbx> <png> <outdir>"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index("--") + 1:]
IN, PNG, OUTD = argv[0], argv[1], argv[2]
LOG = os.path.join(OUTD, "rig_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def centroid(ps): return sum(ps, Vector()) / len(ps) if ps else None
def clamp(v, a, b): return max(a, min(b, v))
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
    w.name = "Whale"; w.data.name = "Whale"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # centre at the bbox centre
    pts = [v.co.copy() for v in w.data.vertices]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (mn + mx) / 2
    for v in w.data.vertices: v.co -= ctr
    pts = [v.co.copy() for v in w.data.vertices]
    mn -= ctr; mx -= ctr
    L = mx.y - mn.y
    log(f"verts {len(pts)} tris {sum(len(p.vertices)-2 for p in w.data.polygons)} bbox min {tuple(round(v,3) for v in mn)} max {tuple(round(v,3) for v in mx)} length {L:.3f}")
    # material: single image texture = our 1k png
    mat = w.data.materials[0] if w.data.materials and w.data.materials[0] else bpy.data.materials.new("WhaleMat")
    if not w.data.materials: w.data.materials.append(mat)
    for i in range(len(w.data.materials)): w.data.materials[i] = mat
    mat.use_nodes = True; nt = mat.node_tree
    for n in list(nt.nodes):
        if n.type not in ("BSDF_PRINCIPLED", "OUTPUT_MATERIAL"): nt.nodes.remove(n)
    bsdf = [n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"][0]
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(PNG)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.6
    # --- landmarks ---
    FY0, FY1 = float(os.environ.get("FLIP_Y0", "-0.75")), float(os.environ.get("FLIP_Y1", "0.3"))
    FBX_ = float(os.environ.get("FLIP_BASEX", "0.36"))   # body half-width where the flippers leave the body
    flipL = [p for p in pts if p.x > FBX_ and FY0 < p.y < FY1 and p.z < 0.15]
    flipR = [p for p in pts if p.x < -FBX_ and FY0 < p.y < FY1 and p.z < 0.15]
    def ends(fl, sgn):
        base = centroid([p for p in fl if abs(p.x) < FBX_ + 0.08]) or Vector((sgn * FBX_, -0.3, -0.1))
        tip = centroid([p for p in fl if abs(p.x) > FBX_ + 0.2]) or Vector((sgn * 0.62, -0.15, -0.15))
        return base, tip
    bL, tL = ends(flipL, 1); bR, tR = ends(flipR, -1)
    log(f"flipperL n={len(flipL)} base {tuple(round(v,3) for v in bL)} tip {tuple(round(v,3) for v in tL)}; flipperR n={len(flipR)} base {tuple(round(v,3) for v in bR)} tip {tuple(round(v,3) for v in tR)}")
    headreg = [p for p in pts if -0.72 < p.y < -0.3 and abs(p.x) < 0.08]
    blow = max(headreg, key=lambda p: p.z)
    nose = min(pts, key=lambda p: p.y)
    log(f"blowhole (top of head) {tuple(round(v,3) for v in blow)}; nose {tuple(round(v,3) for v in nose)}")
    # --- bones (y along the body; nose at -y) ---
    S = [("Head", -0.55), ("Root", -0.1), ("Spine1", 0.28), ("Spine2", 0.52), ("Tail", 0.71), ("Flukes", 0.88)]
    B = {
        "Root":   ((0, 0.05, 0), (0, -0.2, 0), None),
        "Head":   ((0, -0.3, 0), (0, -0.8, 0), "Root"),
        "Spine1": ((0, 0.15, 0), (0, 0.42, 0), "Root"),
        "Spine2": ((0, 0.42, 0), (0, 0.62, 0), "Spine1"),
        "Tail":   ((0, 0.62, 0), (0, 0.8, 0), "Spine2"),
        "Flukes": ((0, 0.8, 0), (0, 0.95, 0), "Tail"),
        "FlipperL": (tuple(bL), tuple(tL), "Root"),
        "FlipperR": (tuple(bR), tuple(tR), "Root"),
    }
    arm_data = bpy.data.armatures.new("WhaleRig"); arm = bpy.data.objects.new("WhaleRig", arm_data)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for name, (h, t, parent) in B.items():
        b = arm_data.edit_bones.new(name); b.head = Vector(h); b.tail = Vector(t); eb[name] = b
    for name, (h, t, parent) in B.items():
        if parent: eb[name].parent = eb[parent]; eb[name].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    # --- weights by position ---
    vg = {name: w.vertex_groups.new(name=name) for name in B}
    names = [n for n, _ in S]; cs = [c for _, c in S]
    FW = float(os.environ.get("FLIP_BLEND", "0.12"))
    for v in w.data.vertices:
        p = v.co; y = p.y
        wts = {}
        if y <= cs[0]: wts[names[0]] = 1.0
        elif y >= cs[-1]: wts[names[-1]] = 1.0
        else:
            for i in range(len(cs) - 1):
                if cs[i] <= y < cs[i + 1]:
                    t = (y - cs[i]) / (cs[i + 1] - cs[i])
                    wts[names[i]] = 1 - t; wts[names[i + 1]] = t
                    break
        fl = None
        if FY0 < y < FY1 and p.z < 0.15 and abs(p.x) > FBX_:
            fl = "FlipperL" if p.x > 0 else "FlipperR"
            t = clamp((abs(p.x) - FBX_) / FW, 0.0, 1.0)
            wts = {k: val * (1 - t) for k, val in wts.items()}
            wts[fl] = t
        for k, val in wts.items():
            if val > 0.001: vg[k].add([v.index], val, "REPLACE")
    mod = w.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    w.parent = arm
    cnt = {n: sum(1 for v in w.data.vertices for g in v.groups if g.group == vg[n].index and g.weight > 0.5) for n in B}
    log(f"dominant counts {cnt}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "whale_rigged.blend"))
    json.dump({"length": L, "bbox_min": list(mn), "bbox_max": list(mx), "blowhole": list(blow), "nose": list(nose),
               "flipperL": [list(bL), list(tL)], "flipperR": [list(bR), list(tR)],
               "bones": {k: [list(h), list(t), p] for k, (h, t, p) in B.items()}, "spine_centres": S},
              open(os.path.join(OUTD, "whale_data.json"), "w"), indent=1)
    bpy.ops.object.select_all(action="DESELECT"); w.select_set(True); arm.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "whale_color.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    # --- pose renders ---
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 800, 500; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 45
    def shoot(path, off, target=Vector((0, 0, 0))):
        camo.location = target + off
        camo.rotation_euler = (target - camo.location).to_track_quat("-Z", "Z").to_euler()
        sc.render.filepath = path; bpy.ops.render.render(write_still=True)
    X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
    def rot_world(pb, axis, deg):
        m = pb.matrix.copy(); loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m; m2.translation = loc; pb.matrix = m2
        bpy.context.view_layer.update()
    def reset():
        for b in pb: b.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    q34 = Vector((3.2, -3.4, 1.6)); side = Vector((4.6, 0.6, 0.6))
    shoot(os.path.join(OUTD, "pose_rest.png"), q34)
    # tail up (flukes rise): rotate about world X; sign checked in the render
    rot_world(pb["Spine1"], X, -8); rot_world(pb["Spine2"], X, -12); rot_world(pb["Tail"], X, -16); rot_world(pb["Flukes"], X, -18)
    rot_world(pb["FlipperL"], Y, 15); rot_world(pb["FlipperR"], Y, -15); rot_world(pb["Head"], X, 4)
    shoot(os.path.join(OUTD, "pose_tailup.png"), q34); shoot(os.path.join(OUTD, "pose_tailup_side.png"), side)
    reset()
    rot_world(pb["Spine1"], X, 8); rot_world(pb["Spine2"], X, 12); rot_world(pb["Tail"], X, 16); rot_world(pb["Flukes"], X, 18)
    rot_world(pb["FlipperL"], Y, -15); rot_world(pb["FlipperR"], Y, 15); rot_world(pb["Head"], X, -4)
    shoot(os.path.join(OUTD, "pose_taildown.png"), q34); shoot(os.path.join(OUTD, "pose_taildown_side.png"), side)
    reset()
    rot_world(pb["Spine1"], Z, 8); rot_world(pb["Spine2"], Z, 12); rot_world(pb["Tail"], Z, 16); rot_world(pb["Flukes"], Z, 18); rot_world(pb["Head"], Z, -6)
    shoot(os.path.join(OUTD, "pose_bend.png"), Vector((0.5, 0.2, 5.2)))
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
