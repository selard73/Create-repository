"""Rig the Meshy crab (crab.blend from prep_squirrel.py: faces -Y, up Z, feet z=0, height 1.0) for script animation in Roblox.
Bones: Root (body), LegsLF / LegsLB / LegsRF / LegsRB (front and back leg pairs per side, so a scuttle can alternate them),
ClawL / ClawR. Weights by region (hard, with a short blend at the shell edge); eye stalks stay on Root.
Scaled to SCALE first (1.0 tall -> ~0.6 tall, ~1.07 wide). Exports crab_rigged.fbx with the texture embedded + check renders.
Run: blender -b --python rig_crab.py"""
import bpy, os, math, traceback
from mathutils import Vector, Matrix
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "rig_log.txt")
SCALE = 0.6
def log(m):
    open(LOG, "a").write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "crab.blend"))
    for o in list(bpy.data.objects):
        if o.name != "Squirrel": bpy.data.objects.remove(o)
    cr = bpy.data.objects["Squirrel"]; cr.name = "Crab"
    bpy.context.view_layer.objects.active = cr; cr.select_set(True)
    cr.scale = (SCALE, SCALE, SCALE); bpy.ops.object.transform_apply(scale=True)
    S = SCALE
    # bones (Blender coords: x right, -y front, z up), all in the scaled frame
    B = {
        "Root":   ((0, 0, 0.30 * S), (0, 0, 0.62 * S), None),
        "LegsLF": ((-0.46 * S, -0.16 * S, 0.30 * S), (-0.88 * S, -0.16 * S, 0.18 * S), "Root"),
        "LegsLB": ((-0.46 * S, 0.22 * S, 0.30 * S), (-0.82 * S, 0.30 * S, 0.18 * S), "Root"),
        "LegsRF": ((0.46 * S, -0.16 * S, 0.30 * S), (0.88 * S, -0.16 * S, 0.18 * S), "Root"),
        "LegsRB": ((0.46 * S, 0.22 * S, 0.30 * S), (0.82 * S, 0.30 * S, 0.18 * S), "Root"),
        "ClawL":  ((-0.22 * S, -0.32 * S, 0.32 * S), (-0.30 * S, -0.58 * S, 0.22 * S), "Root"),
        "ClawR":  ((0.22 * S, -0.32 * S, 0.32 * S), (0.30 * S, -0.58 * S, 0.22 * S), "Root"),
    }
    ad = bpy.data.armatures.new("CrabRig"); arm = bpy.data.objects.new("CrabRig", ad)
    bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = {}
    for n, (h, t, p) in B.items():
        b = ad.edit_bones.new(n); b.head = Vector(h); b.tail = Vector(t); eb[n] = b
    for n, (h, t, p) in B.items():
        if p: eb[n].parent = eb[p]; eb[n].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    cr.parent = arm
    mod = cr.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    groups = {n: cr.vertex_groups.new(name=n) for n in B}
    counts = {n: 0 for n in B}
    def smooth(t):
        t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)
    for v in cr.data.vertices:
        x, y, z = v.co.x / S, v.co.y / S, v.co.z / S          # back to the unscaled numbers the regions were measured in
        w = {}
        side = "L" if x < 0 else "R"
        # claws: front, inside the shell's width, low (eye stalks are higher, z > 0.6)
        if y < -0.26 and abs(x) < 0.56 and z < 0.58:
            k = smooth((-0.26 - y) / 0.10)
            w["Claw" + side] = k
        # legs: outside the shell's edge, low
        elif (abs(x) > 0.56 and z < 0.56) or (abs(x) > 0.44 and z < 0.30):     # legs; the shell's own rim (x<0.56, z>0.3) stays on Root
            k = smooth((abs(x) - 0.44) / 0.10) if z < 0.30 else smooth((abs(x) - 0.56) / 0.06)
            leg = "Legs" + side + ("F" if y < 0.04 else "B")
            w[leg] = k
        tot = sum(w.values())
        if tot < 1:
            w["Root"] = 1 - tot
        for n, val in w.items():
            if val > 0.001:
                groups[n].add([v.index], val, "REPLACE")
                if val > 0.5: counts[n] += 1
    log(f"dominant vertex counts {counts}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "crab_rigged.blend"))
    # texture: the 1k copy made beforehand (crab_1k.png)
    tex = [n for n in cr.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    tex.image = bpy.data.images.load(os.path.join(D, "crab_1k.png"))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "crab_rigged.blend"))
except Exception:
    log(traceback.format_exc())
try:
    cr = bpy.data.objects["Crab"]; arm = bpy.data.objects["CrabRig"]
    bpy.ops.object.select_all(action="DESELECT"); cr.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.fbx(filepath=os.path.join(D, "crab_rigged.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    # check renders: rest, and a pose (left legs up, right legs down, claws raised)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sc.render.resolution_x, sc.render.resolution_y = 600, 450; sc.render.image_settings.file_format = "PNG"
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    camo.location = Vector((1.1, -1.6, 0.9)); ctr = Vector((0, 0, 0.22))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Z").to_euler()
    sc.render.filepath = os.path.join(D, "crab_rest.png"); bpy.ops.render.render(write_still=True)
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    def rot(name, axis, deg):
        pb[name].rotation_mode = "XYZ"; r = list(pb[name].rotation_euler); r["XYZ".index(axis)] = math.radians(deg); pb[name].rotation_euler = r
    rot("LegsLF", "Y", 25); rot("LegsRB", "Y", 25); rot("LegsLB", "Y", -15); rot("LegsRF", "Y", -15)
    rot("ClawL", "X", 35); rot("ClawR", "X", 35)
    bpy.context.view_layer.update()
    sc.render.filepath = os.path.join(D, "crab_pose.png"); bpy.ops.render.render(write_still=True)
    log("RIG_DONE")
except Exception:
    log(traceback.format_exc())
