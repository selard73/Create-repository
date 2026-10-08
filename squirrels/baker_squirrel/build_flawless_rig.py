import bpy, math
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = bpy.data.objects['Squirrel']
mesh.vertex_groups.clear()
for m in list(mesh.modifiers):
    mesh.modifiers.remove(m)

# Armature
arm_data = bpy.data.armatures.new('SquirrelRig')
arm_obj = bpy.data.objects.new('SquirrelRig', arm_data)
bpy.context.scene.collection.objects.link(arm_obj)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='EDIT')

b_root = arm_data.edit_bones.new('Root')
b_root.head = Vector((-0.10, 0.10, 0.30))
b_root.tail = Vector((-0.10, 0.05, 0.90))

b_chest = arm_data.edit_bones.new('Chest')
b_chest.head = b_root.tail
b_chest.tail = Vector((-0.10, -0.10, 1.40))
b_chest.parent = b_root

b_neck = arm_data.edit_bones.new('Neck')
b_neck.head = b_chest.tail
b_neck.tail = Vector((-0.10, -0.20, 1.60))
b_neck.parent = b_chest

b_head = arm_data.edit_bones.new('Head')
b_head.head = b_neck.tail
b_head.tail = Vector((-0.10, -0.35, 2.30))
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

# Exact classification rules:
# 1. Rolling Pin Barrel & Handle:
#    X < -0.60, Z < 1.88, Y in [-0.35, 0.05] -> 100% Chest
#    (Note: whiskers extending forward at Y < -0.35 are 100% Head!)
# 2. Tail:
#    X > 0.25 and Y > 0.10 -> Tail!
#    If Z < 1.25: Tail1, else Tail2
# 3. Left Shoulder & Paw on Hip:
#    X > 0.25 and Y <= 0.10 and Z < 1.80 -> 100% Chest
# 4. Head & Face & Ears & Hat & All Whiskers:
#    Everything at Z >= 1.55 (not Pin, not Tail, not Shoulder) -> 100% Head
#    PLUS all whiskers reaching forward (Y < -0.35 and Z >= 1.45) -> 100% Head!
# 5. Neck:
#    Z in [1.45, 1.55] -> Neck/Head
# 6. Torso / Apron:
#    Z in [0.80, 1.45] -> Chest
# 7. Root / Legs / Feet:
#    Z < 0.80 -> Root

for v in mesh.data.vertices:
    co = v.co
    # Whisker override (any forward whisker at Y < -0.35 with Z >= 1.45):
    if co.y < -0.35 and co.z >= 1.45:
        vg_head.add([v.index], 1.0, 'REPLACE')
    # 1. Rolling pin (cylinder behind whiskers)
    elif co.x < -0.60 and co.z < 1.88 and -0.35 <= co.y <= 0.05:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 2. Tail
    elif co.x > 0.25 and co.y > 0.10:
        if co.z < 1.25:
            vg_tail1.add([v.index], 1.0, 'REPLACE')
        elif co.z > 1.45:
            vg_tail2.add([v.index], 1.0, 'REPLACE')
        else:
            t = (co.z - 1.25) / 0.20
            vg_tail2.add([v.index], t, 'REPLACE')
            vg_tail1.add([v.index], 1.0 - t, 'REPLACE')
    # 3. Left shoulder
    elif co.x > 0.25 and co.y <= 0.10 and co.z < 1.80:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 4. Head, hat, ears, face
    elif (co.z >= 1.55 and co.y <= 0.10) or (co.z >= 1.80):
        vg_head.add([v.index], 1.0, 'REPLACE')
    # 5. Neck collar
    elif co.z >= 1.45 and co.y <= 0.10:
        t = (co.z - 1.45) / 0.10
        vg_head.add([v.index], t, 'REPLACE')
        vg_neck.add([v.index], 1.0 - t, 'REPLACE')
    # 6. Torso / Apron
    elif co.z >= 0.80:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 7. Root / Legs
    else:
        if co.z > 0.68:
            t = (co.z - 0.68) / 0.12
            vg_chest.add([v.index], t, 'REPLACE')
            vg_root.add([v.index], 1.0 - t, 'REPLACE')
        else:
            vg_root.add([v.index], 1.0, 'REPLACE')

# Normalize
for v in mesh.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

# Render pose test
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')
arm_obj.pose.bones['Head'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Head'].rotation_euler = (0, 0, 0.45)
arm_obj.pose.bones['Tail2'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail2'].rotation_euler = (0.35, 0, 0.35)

cam = bpy.data.objects.get('FrontCam')
if not cam:
    cam = bpy.data.objects.new('FrontCam', bpy.data.cameras.new('FrontCam'))
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
cam.location = (0, -3.8, 1.3)
cam.rotation_euler = (1.5708, 0, 0)

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/flawless_turn_test.png'
bpy.ops.render.render(write_still=True)

# Export FBXs in rest pose
for pb in arm_obj.pose.bones:
    pb.rotation_euler = (0, 0, 0)
bpy.ops.object.mode_set(mode='OBJECT')

color_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_color.fbx'
gray_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray.fbx'
color_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png'
gray_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray_1k.png'

tex = [n for n in mesh.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0]

def export(out_fbx, png):
    tex.image = bpy.data.images.load(png)
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.export_scene(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                         bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                         global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

export(color_fbx, color_png)
export(gray_fbx, gray_png)
print('FLAWLESS_RIG_COMPLETE')
