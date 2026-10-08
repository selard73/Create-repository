import traceback

try:
    import bpy, math
    from mathutils import Vector

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

    mesh = bpy.data.objects['Squirrel']
    mesh.vertex_groups.clear()
    for m in list(mesh.modifiers):
        mesh.modifiers.remove(m)

    # Clean single vertex tweak to ensure new Roblox mesh hash
    mesh.data.vertices[0].co.z += 0.003

    # Armature
    arm_data = bpy.data.armatures.new('SquirrelRig')
    arm_obj = bpy.data.objects.new('SquirrelRig', arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='EDIT')

    b_root = arm_data.edit_bones.new('Root')
    b_root.head = Vector((-0.10, 0.10, 0.30))
    b_root.tail = Vector((-0.10, 0.05, 0.85))

    b_chest = arm_data.edit_bones.new('Chest')
    b_chest.head = b_root.tail
    b_chest.tail = Vector((-0.10, -0.05, 1.25))
    b_chest.parent = b_root

    b_neck = arm_data.edit_bones.new('Neck')
    b_neck.head = b_chest.tail
    b_neck.tail = Vector((-0.10, -0.10, 1.40))
    b_neck.parent = b_chest

    b_head = arm_data.edit_bones.new('Head')
    b_head.head = b_neck.tail
    b_head.tail = Vector((-0.10, -0.25, 2.30))
    b_head.parent = b_neck

    b_tail1 = arm_data.edit_bones.new('Tail1')
    b_tail1.head = Vector((0.35, 0.30, 0.60))
    b_tail1.tail = Vector((0.55, 0.45, 1.30))
    b_tail1.parent = b_root

    b_tail2 = arm_data.edit_bones.new('Tail2')
    b_tail2.head = b_tail1.tail
    b_tail2.tail = Vector((0.65, 0.45, 1.95))
    b_tail2.parent = b_tail1

    bpy.ops.object.mode_set(mode='OBJECT')

    mod = mesh.modifiers.new('Armature', 'ARMATURE')
    mod.object = arm_obj

    vg_root = mesh.vertex_groups.new(name='Root')
    vg_chest = mesh.vertex_groups.new(name='Chest')
    vg_neck = mesh.vertex_groups.new(name='Neck')
    vg_head = mesh.vertex_groups.new(name='Head')
    vg_tail1 = mesh.vertex_groups.new(name='Tail1')
    vg_tail2 = mesh.vertex_groups.new(name='Tail2')

    for v in mesh.data.vertices:
        co = v.co
        # 1. Forward face & whiskers: ANY vertex with y < -0.15 and z >= 1.25 is 100% HEAD!
        if co.y < -0.15 and co.z >= 1.25:
            vg_head.add([v.index], 1.0, 'REPLACE')
        # 2. Rolling pin barrel & handle (behind whiskers)
        elif co.x < -0.60 and co.z < 1.88 and -0.35 <= co.y <= 0.05:
            vg_chest.add([v.index], 1.0, 'REPLACE')
        # 3. Tail
        elif co.x > 0.25 and co.y > 0.10:
            if co.z < 1.25:
                vg_tail1.add([v.index], 1.0, 'REPLACE')
            elif co.z > 1.45:
                vg_tail2.add([v.index], 1.0, 'REPLACE')
            else:
                t = (co.z - 1.25) / 0.20
                vg_tail2.add([v.index], t, 'REPLACE')
                vg_tail1.add([v.index], 1.0 - t, 'REPLACE')
        # 4. Left shoulder & arm on hip
        elif co.x > 0.25 and co.y <= 0.10 and co.z < 1.70:
            vg_chest.add([v.index], 1.0, 'REPLACE')
        # 5. Upper Head, Hat, Ears (z >= 1.70 everywhere, or z >= 1.36 and y <= 0.10)
        elif co.z >= 1.70 or (co.z >= 1.36 and co.y <= 0.10):
            vg_head.add([v.index], 1.0, 'REPLACE')
        # 6. Neck collar band (z between 1.22 and 1.36, y between -0.15 and 0.10)
        elif co.z >= 1.22 and co.y <= 0.10:
            t = (co.z - 1.22) / 0.14
            vg_head.add([v.index], t, 'REPLACE')
            vg_neck.add([v.index], 1.0 - t, 'REPLACE')
        # 7. Chest / Torso / Apron
        elif co.z >= 0.75:
            vg_chest.add([v.index], 1.0, 'REPLACE')
        # 8. Root / Legs / Feet
        else:
            if co.z > 0.65:
                t = (co.z - 0.65) / 0.10
                vg_chest.add([v.index], t, 'REPLACE')
                vg_root.add([v.index], 1.0 - t, 'REPLACE')
            else:
                vg_root.add([v.index], 1.0, 'REPLACE')

    # Normalize weights
    for v in mesh.data.vertices:
        tot = sum(g.weight for g in v.groups)
        if tot > 0:
            for g in v.groups:
                mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

    bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

    # Rest pose for export
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    for pb in arm_obj.pose.bones:
        pb.rotation_euler = (0, 0, 0)
    bpy.ops.object.mode_set(mode='OBJECT')

    color_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/baker_squirrel_color.fbx'
    gray_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/baker_squirrel_gray.fbx'
    color_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png'
    gray_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray_1k.png'

    tex = [n for n in mesh.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0]

    def export(out_fbx, png):
        tex.image = bpy.data.images.load(png)
        bpy.ops.object.select_all(action='DESELECT')
        mesh.select_set(True)
        arm_obj.select_set(True)
        bpy.context.view_layer.objects.active = arm_obj
        bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

    export(color_fbx, color_png)
    export(gray_fbx, gray_png)

    with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/bulletproof_status.txt', 'w') as f:
        f.write('BULLETPROOF_RIG_EXPORTED_SUCCESSFULLY\n')

except Exception as e:
    with open(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/bulletproof_status.txt', 'w') as f:
        f.write(f"ERROR: {e}\n{traceback.format_exc()}\n")
