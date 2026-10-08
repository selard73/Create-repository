import bpy, os, sys, math
from mathutils import Vector

OUTD = r"C:\Users\slard\roblox-props\squirrels\pizzadelivery_squirrel"
NAME = "pizzadelivery_squirrel"
LOG = os.path.join(OUTD, "fixw_log.txt")

with open(LOG, "w") as logf:
    def log(m):
        logf.write(str(m) + "\n")
        print(m)

    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]
    arm = bpy.data.objects["SquirrelRig"]
    gi = {g.index: g.name for g in sq.vertex_groups}

    def move(test, src_names, dst_name):
        dst = sq.vertex_groups.get(dst_name) or sq.vertex_groups.new(name=dst_name)
        moved = 0
        for v in sq.data.vertices:
            if not test(v.co, v.index): continue
            old = {gi[g.group]: g.weight for g in v.groups if gi.get(g.group) in src_names}
            w = sum(old.values())
            if w <= 0: continue
            for nm, ow in old.items():
                sq.vertex_groups[nm].remove([v.index])
            cur = sum(g.weight for g in v.groups if gi.get(g.group) == dst_name)
            dst.add([v.index], min(1.0, cur + w), "REPLACE")
            moved += 1
        return moved

    # 1. Wheels, chassis, floorboard (z < 0.85): 100% rigid on Root
    n1 = move(lambda c, i: c.z < 0.85, ["Chest", "Neck", "Head", "Tail1", "Tail2"], "Root")
    log(f"1. Low chassis (z < 0.85 -> Root): {n1} verts")

    # 2. Front scooter body, headlight, handlebars, front fork (y < -0.45, z < 1.40): 100% Root
    n2 = move(lambda c, i: c.y < -0.45 and c.z < 1.40, ["Chest", "Neck", "Head", "Tail1", "Tail2"], "Root")
    log(f"2. Scooter front/handlebars (y < -0.45, z < 1.40 -> Root): {n2} verts")

    # 3. Pizza box, rack, and rear scooter body (y > 0.45, z < 1.38): 100% Root
    n3 = move(lambda c, i: c.y > 0.45 and c.z < 1.38, ["Chest", "Neck", "Head", "Tail1", "Tail2"], "Root")
    log(f"3. Pizza box & rack (y > 0.45, z < 1.38 -> Root): {n3} verts")

    # 4. Squirrel torso, seat, jacket, arms (-0.45 <= y <= 0.35, 0.85 <= z < 1.40): Head/Neck/Tail -> Chest
    n4 = move(lambda c, i: -0.45 <= c.y <= 0.35 and 0.85 <= c.z < 1.40, ["Head", "Neck", "Tail1", "Tail2"], "Chest")
    log(f"4. Torso/arms (-0.45 <= y <= 0.35, 0.85 <= z < 1.40 -> Chest): {n4} verts")

    # 5. Head / helmet / face (z >= 1.40, y <= 0.05): ALL Tail1 and Tail2 -> Head
    n5 = move(lambda c, i: c.z >= 1.40 and c.y <= 0.05, ["Tail1", "Tail2", "Root"], "Head")
    log(f"5. Head/helmet (z >= 1.40, y <= 0.05 -> Head): {n5} verts")

    # 6. Tail (y >= 0.15, z >= 1.25): Head/Neck/Root -> Tail1 (or Tail2 if z > 1.7)
    n6a = move(lambda c, i: c.y >= 0.15 and 1.25 <= c.z < 1.70, ["Head", "Neck", "Root"], "Tail1")
    n6b = move(lambda c, i: c.y >= 0.15 and c.z >= 1.70, ["Head", "Neck", "Root"], "Tail2")
    log(f"6. Tail (y >= 0.15 -> Tail1/Tail2): {n6a + n6b} verts")

    # Verify 0 tail on head
    head_leaks = sum(1 for v in sq.data.vertices if v.co.z >= 1.45 and v.co.y < 0.05 and any("Tail" in gi.get(g.group, "") and g.weight > 0.001 for g in v.groups))
    log(f"Head tail leaks: {head_leaks}")

    # Bone counts
    for bname in ["Root", "Chest", "Neck", "Head", "Tail1", "Tail2"]:
        count = sum(1 for v in sq.data.vertices if any(gi.get(g.group) == bname and g.weight > 0.05 for g in v.groups))
        log(f"Bone {bname} vert count: {count}")

    # Save fixed blend
    bpy.ops.wm.save_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    log("Saved fixed blend.")

    # Export colour FBX
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUTD, f"{NAME}_color.fbx"),
        use_selection=False,
        bake_anim=False,
        add_leaf_bones=False,
        primary_bone_axis='Y',
        secondary_bone_axis='X',
        armature_nodetype='NULL'
    )
    log("Exported color FBX.")

    # Export gray FBX
    img_gray = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    for mat in sq.data.materials:
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE':
                node.image = img_gray
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUTD, f"{NAME}_gray.fbx"),
        use_selection=False,
        bake_anim=False,
        add_leaf_bones=False,
        primary_bone_axis='Y',
        secondary_bone_axis='X',
        armature_nodetype='NULL'
    )
    log("Exported gray FBX.")

    # Render head-turn test views
    # Restore color texture for render
    img_col = bpy.data.images.load(os.path.join(OUTD, f"{NAME}_1k.png"))
    for mat in sq.data.materials:
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE':
                node.image = img_col

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.resolution_x, sc.render.resolution_y = 700, 700

    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o)

    cam = bpy.data.cameras.new("Cam")
    camo = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 55

    # Pose: turn neck +15 deg, head +25 deg
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    from mathutils import Matrix
    def rot_world(b, axis, deg):
        m = b.matrix.copy(); loc = m.to_translation()
        m2 = Matrix.Rotation(math.radians(deg), 4, axis) @ m; m2.translation = loc; b.matrix = m2
        bpy.context.view_layer.update()

    rot_world(pb["Neck"], Vector((0, 0, 1)), 15)
    rot_world(pb["Head"], Vector((0, 0, 1)), 25)

    # 3/4 front view
    ctr = Vector((0, -0.4, 1.4))
    camo.location = ctr + Vector((-2.2, -3.2, 1.0))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUTD, "turn_q34.png")
    bpy.ops.render.render(write_still=True)

    # Close-up face view with turned head
    camo.location = ctr + Vector((-1.0, -1.8, 0.5))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUTD, "turn_close.png")
    bpy.ops.render.render(write_still=True)

    log("PIZZA_FIX_DONE")
