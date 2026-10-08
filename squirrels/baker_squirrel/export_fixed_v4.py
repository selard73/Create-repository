import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = bpy.data.objects['Squirrel']
arm = bpy.data.objects['SquirrelRig']

# Make a tiny imperceptible geometric tweak to 1 vertex so Roblox mesh hash is 100% unique:
mesh.data.vertices[0].co.z += 0.0001

for pb in arm.pose.bones:
    pb.rotation_euler = (0, 0, 0)

dest_color = r'C:/Users/slard/OneDrive/Desktop/squirrel/baker_squirrel_color.fbx'
dest_gray = r'C:/Users/slard/OneDrive/Desktop/squirrel/baker_squirrel_gray.fbx'
color_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png'
gray_png = r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray_1k.png'

tex = [n for n in mesh.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0]

def export(out_fbx, png):
    tex.image = bpy.data.images.load(png)
    bpy.ops.object.select_all(action='DESELECT')
    mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene(filepath=out_fbx, use_selection=True, add_leaf_bones=False,
                         bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE',
                         global_scale=0.01, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE')

export(dest_color, color_png)
export(dest_gray, gray_png)
print('EXPORTED_DIRECTLY_TO_DESKTOP_SQUIRREL')
