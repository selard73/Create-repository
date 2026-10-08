import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

sq = bpy.data.objects['Squirrel']
arm = bpy.data.objects['SquirrelRig']

vgs = {vg.name: vg for vg in sq.vertex_groups}

# In baker squirrel:
# Squirrel forward is canonical -Y.
# Viewer looking at face:
# Squirrel\'s left side (viewer\'s right) is +X!
# Squirrel\'s right side (holding rolling pin) is -X!
# Let\'s check where the face is:
# Head is located at Z >= 1.45, Y <= 0.15.
# On squirrel\'s right side (-X): rolling pin is at X < -0.42, Y < -0.10 -> pinned to Chest.
# On the rest of the head: ALL vertices above neck (Z >= 1.50, Y <= 0.20, and not rolling pin) MUST BE 100% HEAD!
# Absolutely ZERO Tail1, ZERO Tail2, ZERO Chest, ZERO Root!

fixed_count = 0
for v in sq.data.vertices:
    co = v.co
    # Is it rolling pin?
    is_pin = (co.x < -0.42 and co.y < -0.10)
    
    # Is it head? (Z >= 1.48, Y <= 0.15, not rolling pin)
    if co.z >= 1.48 and co.y <= 0.15 and not is_pin:
        # Strip all other bones completely
        for bname in ['Tail1', 'Tail2', 'Root', 'Chest']:
            if bname in vgs:
                vgs[bname].remove([v.index])
        # Give 100% to Head (or split smoothly with Neck if 1.48 <= Z < 1.58)
        if co.z >= 1.58:
            if 'Neck' in vgs: vgs['Neck'].remove([v.index])
            vgs['Head'].add([v.index], 1.0, 'REPLACE')
        else:
            # Transition zone near neck:
            t = (co.z - 1.48) / 0.10
            vgs['Head'].add([v.index], t, 'REPLACE')
            vgs['Neck'].add([v.index], 1.0 - t, 'REPLACE')
        fixed_count += 1

# Also check any cheek/whisker vertices between Z=1.35 and 1.50 with Y <= -0.20
cheek_count = 0
for v in sq.data.vertices:
    co = v.co
    is_pin = (co.x < -0.42 and co.y < -0.10)
    if not is_pin and 1.35 <= co.z < 1.48 and co.y <= -0.20:
        # Snout / cheeks sticking forward: should follow Head / Neck, NOT Tail!
        if 'Tail1' in vgs: vgs['Tail1'].remove([v.index])
        if 'Tail2' in vgs: vgs['Tail2'].remove([v.index])
        cheek_count += 1

# Normalize all vertex weights
for v in sq.data.vertices:
    tot = sum(g.weight for g in v.groups)
    if tot > 0:
        for g in v.groups:
            sq.vertex_groups[g.group].add([v.index], g.weight / tot, 'REPLACE')

print(f'Fixed head: {fixed_count} verts, Fixed cheeks: {cheek_count} verts')

# Save blend
bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

# Export both FBXs
color_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_color.fbx'
gray_fbx = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray.fbx'
color_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png'
gray_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray_1k.png'

tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0]

def export(out_fbx, png):
    tex.image = bpy.data.images.load(png)
    bpy.ops.object.select_all(action='DESELECT')
    sq.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

export(color_fbx, color_png)
export(gray_fbx, gray_png)
print('EXPORT_SUCCESS')
