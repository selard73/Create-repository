
import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

vg_head = mesh.vertex_groups.get('Head')
vg_neck = mesh.vertex_groups.get('Neck')
vg_chest = mesh.vertex_groups.get('Chest')
vg_root = mesh.vertex_groups.get('Root')
vg_tail1 = mesh.vertex_groups.get('Tail1')
vg_tail2 = mesh.vertex_groups.get('Tail2')

# Rules:
# 1. Rolling pin: verts with X < -0.42 and Y < -0.10 -> 100% Chest! (no Head, Neck, or Tail pull)
# 2. Apron / torso: verts below neck (Z < 1.55) -> no Head or Neck pull, transfer to Chest or Root
# 3. Tail isolation: tail is at X > 0.20 and Y > 0.10. Head verts must have 0 Tail weight, Tail verts must have 0 Head weight!

pin_count = 0
head_strip_count = 0
tail_strip_count = 0

for v in mesh.data.vertices:
    co = v.co
    # 1. Pin
    if co.x < -0.42 and co.y < -0.10:
        pin_count += 1
        for vg in [vg_head, vg_neck, vg_tail1, vg_tail2]:
            if vg: vg.remove([v.index])
        if vg_chest: vg.add([v.index], 1.0, 'REPLACE')

    # 2. Below neck: if Z < 1.50 and not in pin
    elif co.z < 1.50:
        # Strip head pull
        for vg in [vg_head, vg_neck]:
            if vg:
                w = 0
                for g in v.groups:
                    if g.group == vg.index:
                        w = g.weight
                if w > 0:
                    vg.remove([v.index])
                    if vg_chest:
                        vg_chest.add([v.index], w, 'ADD')
                    head_strip_count += 1

    # 3. Head (Z >= 1.50, X >= -0.42): strip tail
    if co.z >= 1.50 and co.x >= -0.42:
        for vg in [vg_tail1, vg_tail2]:
            if vg:
                vg.remove([v.index])
                tail_strip_count += 1

print(f'Weight fixes: {pin_count} pin verts, {head_strip_count} head stripped, {tail_strip_count} tail stripped')

# Normalize weights
for v in mesh.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            mesh.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

# Re-export FBX
color_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_color.fbx'
gray_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray.fbx'

# Select mesh and armature
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=color_fbx, use_selection=True, add_leaf_bones=False, bake_anim=False)
print('Exported color FBX')

bpy.ops.wm.save_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')
