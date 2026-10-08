
import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_rigged.blend')

mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]

color_tex = bpy.data.images.load(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_1k.png')
gray_tex = bpy.data.images.load(r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray_1k.png')

mat = mesh.data.materials[0]
bsdf = mat.node_tree.nodes.get('Principled BSDF')
tex_node = mat.node_tree.nodes.get('Image Texture')

bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm

# Export color
if tex_node: tex_node.image = color_tex
bpy.ops.export_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_color.fbx', 
    use_selection=True, add_leaf_bones=False, bake_anim=False)

# Export gray
if tex_node: tex_node.image = gray_tex
bpy.ops.export_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/baker_squirrel/baker_squirrel_gray.fbx', 
    use_selection=True, add_leaf_bones=False, bake_anim=False)

print('EXPORTED_BOTH_SUCCESSFULLY')
