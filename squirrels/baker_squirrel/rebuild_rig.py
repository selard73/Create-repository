import bpy, math, json
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
mesh.name = 'Squirrel'

# Clear any existing vertex groups or armature modifiers
mesh.vertex_groups.clear()
for m in list(mesh.modifiers):
    mesh.modifiers.remove(m)

# Create Armature
arm_data = bpy.data.armatures.new('SquirrelRig')
arm_obj = bpy.data.objects.new('SquirrelRig', arm_data)
bpy.context.scene.collection.objects.link(arm_obj)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='EDIT')

# Define Bones:
# Center of body is roughly X = -0.05, Y = 0.05
# Head center is X = -0.05, Y = -0.35, Z = 1.95
# Tail is on +X side: X = 0.50, Y = 0.40, Z = 0.3..2.0

# 1. Root: ( -0.05, 0.10, 0.30 ) -> ( -0.05, 0.05, 0.90 )
b_root = arm_data.edit_bones.new('Root')
b_root.head = Vector((-0.05, 0.10, 0.30))
b_root.tail = Vector((-0.05, 0.05, 0.90))

# 2. Chest: ( -0.05, 0.05, 0.90 ) -> ( -0.05, -0.10, 1.40 )
b_chest = arm_data.edit_bones.new('Chest')
b_chest.head = b_root.tail
b_chest.tail = Vector((-0.05, -0.10, 1.40))
b_chest.parent = b_root

# 3. Neck: ( -0.05, -0.10, 1.40 ) -> ( -0.05, -0.20, 1.60 )
b_neck = arm_data.edit_bones.new('Neck')
b_neck.head = b_chest.tail
b_neck.tail = Vector((-0.05, -0.20, 1.60))
b_neck.parent = b_chest

# 4. Head: ( -0.05, -0.20, 1.60 ) -> ( -0.05, -0.40, 2.30 )
b_head = arm_data.edit_bones.new('Head')
b_head.head = b_neck.tail
b_head.tail = Vector((-0.05, -0.40, 2.30))
b_head.parent = b_neck

# 5. Tail1: ( 0.20, 0.25, 0.60 ) -> ( 0.50, 0.40, 1.30 )
b_tail1 = arm_data.edit_bones.new('Tail1')
b_tail1.head = Vector((0.20, 0.25, 0.60))
b_tail1.tail = Vector((0.50, 0.40, 1.30))
b_tail1.parent = b_root

# 6. Tail2: ( 0.50, 0.40, 1.30 ) -> ( 0.65, 0.45, 1.95 )
b_tail2 = arm_data.edit_bones.new('Tail2')
b_tail2.head = b_tail1.tail
b_tail2.tail = Vector((0.65, 0.45, 1.95))
b_tail2.parent = b_tail1

bpy.ops.object.mode_set(mode='OBJECT')

# Add Armature modifier
mod = mesh.modifiers.new('Armature', 'ARMATURE')
mod.object = arm_obj

# Create Vertex Groups
vg_root = mesh.vertex_groups.new(name='Root')
vg_chest = mesh.vertex_groups.new(name='Chest')
vg_neck = mesh.vertex_groups.new(name='Neck')
vg_head = mesh.vertex_groups.new(name='Head')
vg_tail1 = mesh.vertex_groups.new(name='Tail1')
vg_tail2 = mesh.vertex_groups.new(name='Tail2')

# Rigid / Clean Weight Assignment:
# Tail: Verts with X > 0.25 and Y > 0.05
# Head: Verts with Z >= 1.50 and not Tail and not Pin
# Pin: Verts with X < -0.45 and Y < 0.00
# Torso/Chest: 0.85 <= Z < 1.50 (plus Pin)
# Root/Hips/Feet: Z < 0.85 (and not Tail)

for v in mesh.data.vertices:
    co = v.co
    # Tail check:
    if co.x > 0.25 and co.y > 0.05:
        # Tail:
        if co.z < 1.30:
            vg_tail1.add([v.index], 1.0, 'REPLACE')
        else:
            t = min(1.0, (co.z - 1.30) / 0.35)
            vg_tail2.add([v.index], t, 'REPLACE')
            vg_tail1.add([v.index], 1.0 - t, 'REPLACE')
    # Rolling Pin & Right Arm:
    elif co.x < -0.45 and co.y < 0.00:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # Head & Hat (Z >= 1.55):
    elif co.z >= 1.55:
        vg_head.add([v.index], 1.0, 'REPLACE')
    # Neck transition (1.45 <= Z < 1.55):
    elif co.z >= 1.45:
        t = (co.z - 1.45) / 0.10
        vg_head.add([v.index], t, 'REPLACE')
        vg_neck.add([v.index], 1.0 - t, 'REPLACE')
    # Chest / Torso / Apron (0.85 <= Z < 1.45):
    elif co.z >= 0.85:
        vg_chest.add([v.index], 1.0, 'REPLACE')
    # Root / Legs / Feet (Z < 0.85):
    else:
        if co.z > 0.70:
            t = (co.z - 0.70) / 0.15
            vg_chest.add([v.index], t, 'REPLACE')
            vg_root.add([v.index], 1.0 - t, 'REPLACE')
        else:
            vg_root.add([v.index], 1.0, 'REPLACE')

# Normalize all weights
for v in mesh.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

# Save rigged blend
bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

# Export both FBXs
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
    bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

export(color_fbx, color_png)
export(gray_fbx, gray_png)
print('RIG_AND_EXPORT_COMPLETE')
