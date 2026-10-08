import bpy, math
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_prepped.blend')

mesh = bpy.data.objects['Squirrel']
mesh.vertex_groups.clear()
for m in list(mesh.modifiers):
    mesh.modifiers.remove(m)

# Armature creation
arm_data = bpy.data.armatures.new('OfficerRig')
arm_obj = bpy.data.objects.new('OfficerRig', arm_data)
bpy.context.scene.collection.objects.link(arm_obj)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='EDIT')

b_root = arm_data.edit_bones.new('Root')
b_root.head = Vector((-0.20, -0.05, 0.20))
b_root.tail = Vector((-0.22, -0.08, 0.75))

b_chest = arm_data.edit_bones.new('Chest')
b_chest.head = b_root.tail
b_chest.tail = Vector((-0.25, -0.15, 1.40))
b_chest.parent = b_root

b_neck = arm_data.edit_bones.new('Neck')
b_neck.head = b_chest.tail
b_neck.tail = Vector((-0.28, -0.20, 1.50))
b_neck.parent = b_chest

b_head = arm_data.edit_bones.new('Head')
b_head.head = b_neck.tail
b_head.tail = Vector((-0.35, -0.35, 2.35))
b_head.parent = b_neck

b_tail1 = arm_data.edit_bones.new('Tail1')
b_tail1.head = Vector((0.25, 0.20, 0.50))
b_tail1.tail = Vector((0.55, 0.40, 1.25))
b_tail1.parent = b_root

b_tail2 = arm_data.edit_bones.new('Tail2')
b_tail2.head = b_tail1.tail
b_tail2.tail = Vector((0.65, 0.40, 2.00))
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
    # 1. Tail (X > 0.20 and Y > 0.0)
    if co.x > 0.20 and co.y > 0.05:
        if co.z < 1.20:
            vg_tail1.add([v.index], 1.0, 'REPLACE')
        elif co.z > 1.45:
            vg_tail2.add([v.index], 1.0, 'REPLACE')
        else:
            t = (co.z - 1.20) / 0.25
            vg_tail2.add([v.index], t, 'REPLACE')
            vg_tail1.add([v.index], 1.0 - t, 'REPLACE')
    # 2. Entire Head (Cap, Visor, Badge on hat, Snout, Whiskers, Ears, Cheeks)
    elif co.z >= 1.50 or (co.z >= 1.42 and co.y < -0.25):
        vg_head.add([v.index], 1.0, 'REPLACE')
    # 3. Neck transition zone
    elif co.z >= 1.35 and co.y < 0.15:
        t = (co.z - 1.35) / 0.15
        vg_head.add([v.index], t, 'REPLACE')
        vg_neck.add([v.index], 1.0 - t, 'REPLACE')
    # 4. Torso / Shirt / Tie / Badge / Belt / Arms on hips
    elif co.z >= 0.75:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # 5. Waist transition into hips / legs
    elif co.z >= 0.60:
        t = (co.z - 0.60) / 0.15
        vg_chest.add([v.index], t, 'REPLACE')
        vg_root.add([v.index], 1.0 - t, 'REPLACE')
    # 6. Lower body / Feet / Paws
    else:
        vg_root.add([v.index], 1.0, 'REPLACE')

# Normalize weights
for v in mesh.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_rigged.blend')

# Test pose render
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')
arm_obj.pose.bones['Neck'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Neck'].rotation_euler = (0, 0, math.radians(15 * 0.3))
arm_obj.pose.bones['Head'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Head'].rotation_euler = (math.radians(2), math.radians(2), math.radians(15 * 0.7))
arm_obj.pose.bones['Tail1'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail1'].rotation_euler = (math.radians(5), 0, math.radians(6))
arm_obj.pose.bones['Tail2'].rotation_mode = 'XYZ'
arm_obj.pose.bones['Tail2'].rotation_euler = (math.radians(10), 0, math.radians(10))

# Front camera & lighting
cam = bpy.data.objects.get('FrontCam')
if not cam:
    cam = bpy.data.objects.new('FrontCam', bpy.data.cameras.new('FrontCam'))
    bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
cam.location = (-0.3, -3.2, 1.25)
cam.rotation_euler = (math.radians(88), 0, 0)

world = bpy.data.worlds.new("World")
bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs[0].default_value = (1, 1, 1, 1)
bg.inputs[1].default_value = 1.0

# Light
light_data = bpy.data.lights.new(name="Sun", type='SUN')
light_data.energy = 2.0
light = bpy.data.objects.new(name="Sun", object_data=light_data)
bpy.context.scene.collection.objects.link(light)
light.location = (1, -2, 3)
light.rotation_euler = (math.radians(45), math.radians(15), math.radians(30))

# Setup material
mat = mesh.data.materials[0] if len(mesh.data.materials) > 0 else bpy.data.materials.new(name="Mat")
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
tex_node = [n for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE']
if not tex_node:
    tex_node = mat.node_tree.nodes.new('ShaderNodeTexImage')
    mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
else:
    tex_node = tex_node[0]

tex_node.image = bpy.data.images.load(r'C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_1k.png')

bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/officer_rig_test.png'
bpy.ops.render.render(write_still=True)

# Rest pose for clean FBX export
for pb in arm_obj.pose.bones:
    pb.rotation_euler = (0, 0, 0)
bpy.ops.object.mode_set(mode='OBJECT')

# Export FBXs
dest_color_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/officer_acorn_police_squirrel_color.fbx'
dest_gray_fbx = r'C:/Users/slard/OneDrive/Desktop/squirrel/officer_acorn_police_squirrel_gray.fbx'
color_png = r'C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_1k.png'
gray_png = r'C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_gray_1k.png'

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

with open(r'C:/Users/slard/roblox-props/squirrels/police_squirrel/build_status.txt', 'w') as f:
    f.write('POLICE_SQUIRREL_RIGGED_AND_EXPORTED\n')

print("RIG_AND_EXPORT_DONE")
