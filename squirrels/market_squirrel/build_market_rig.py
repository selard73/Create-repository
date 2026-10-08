import bpy, math
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_prepped.blend')

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
b_root.head = Vector((0.0, 0.05, 0.25))
b_root.tail = Vector((0.0, 0.0, 0.85))

b_chest = arm_data.edit_bones.new('Chest')
b_chest.head = b_root.tail
b_chest.tail = Vector((0.0, -0.05, 1.35))
b_chest.parent = b_root

b_neck = arm_data.edit_bones.new('Neck')
b_neck.head = b_chest.tail
b_neck.tail = Vector((0.0, -0.10, 1.48))
b_neck.parent = b_chest

b_head = arm_data.edit_bones.new('Head')
b_head.head = b_neck.tail
b_head.tail = Vector((0.0, -0.25, 2.30))
b_head.parent = b_neck

b_tail1 = arm_data.edit_bones.new('Tail1')
b_tail1.head = Vector((0.15, 0.25, 0.65))
b_tail1.tail = Vector((0.35, 0.45, 1.25))
b_tail1.parent = b_root

b_tail2 = arm_data.edit_bones.new('Tail2')
b_tail2.head = b_tail1.tail
b_tail2.tail = Vector((0.50, 0.50, 1.95))
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
    # 1. Forward face & snout & chin & whiskers: 100% HEAD
    if co.y < -0.15 and co.z >= 1.32:
        vg_head.add([v.index], 1.0, 'REPLACE')
    # 2. Tail behind
    elif co.y > 0.20 and co.x > -0.25 and co.z >= 0.60:
        if co.z < 1.25:
            vg_tail1.add([v.index], 1.0, 'REPLACE')
        elif co.z > 1.45:
            vg_tail2.add([v.index], 1.0, 'REPLACE')
        else:
            t = (co.z - 1.25) / 0.20
            vg_tail2.add([v.index], t, 'REPLACE')
            vg_tail1.add([v.index], 1.0 - t, 'REPLACE')
    # 3. Grocery bags on both sides (outside hips/shoulders)
    elif abs(co.x) > 0.42 and co.z < 1.40:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 4. Upper head & ears
    elif co.z >= 1.65 or (co.z >= 1.45 and co.y <= 0.15):
        vg_head.add([v.index], 1.0, 'REPLACE')
    # 5. Neck collar transition
    elif co.z >= 1.32 and co.y <= 0.15:
        t = (co.z - 1.32) / 0.13
        vg_head.add([v.index], t, 'REPLACE')
        vg_neck.add([v.index], 1.0 - t, 'REPLACE')
    # 6. Torso / Cardigan / Blouse / Skirt top
    elif co.z >= 0.80:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 7. Lower Skirt / Feet / Legs
    else:
        if co.z > 0.65:
            t = (co.z - 0.65) / 0.15
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

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_rigged.blend')

# Pose test render with head turn and tail wag
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')
arm_obj.pose.bones['Neck'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Neck'].rotation_euler = (0, 0, math.radians(20 * 0.35))
arm_obj.pose.bones['Head'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Head'].rotation_euler = (math.radians(1.5), math.radians(4), math.radians(20 * 0.65))
arm_obj.pose.bones['Tail1'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail1'].rotation_euler = (math.radians(7), 0, math.radians(5))
arm_obj.pose.bones['Tail2'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail2'].rotation_euler = (math.radians(13), 0, math.radians(8))

cam = bpy.data.objects.get('FrontCam')
if not cam:
    cam = bpy.data.objects.new('FrontCam', bpy.data.cameras.new('FrontCam'))
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
cam.location = (0, -3.8, 1.2)
cam.rotation_euler = (1.5708, 0, 0)

# Add sun light
light = bpy.data.objects.get('Sun')
if not light:
    light_data = bpy.data.lights.new(name="Sun", type='SUN')
    light_data.energy = 3.0
    light = bpy.data.objects.new(name="Sun", object_data=light_data)
    bpy.context.scene.collection.objects.link(light)
light.location = (2, -3, 4)
light.rotation_euler = (0.785, 0.3, 0.5)

# Setup texture
mat = mesh.data.materials[0]
mat.use_nodes = True
tex_node = [n for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE'][0]
tex_node.image = bpy.data.images.load(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_1k.png')

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/market_rig_test.png'
bpy.ops.render.render(write_still=True)

# Rest pose for export
for pb in arm_obj.pose.bones:
    pb.rotation_euler = (0, 0, 0)
bpy.ops.object.mode_set(mode='OBJECT')

# Export both color and gray FBXs directly to C:/Users/slard/OneDrive/Desktop/squirrel/
dest_color_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/giulia_market_squirrel_color.fbx'
dest_gray_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/giulia_market_squirrel_gray.fbx'
color_png = r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_1k.png'
gray_png = r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_gray_1k.png'

def export(out_fbx, png):
    tex_node.image = bpy.data.images.load(png)
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

export(dest_color_fbx, color_png)
export(dest_gray_fbx, gray_png)

with open(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/build_status.txt', 'w') as f:
    f.write('MARKET_SQUIRREL_RIGGED_AND_EXPORTED\n')

print("RIG_AND_EXPORT_DONE")
