import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel.blend')

obj = bpy.data.objects['Mesh_0']
obj.name = 'Squirrel'

# Add camera and lights
light_data = bpy.data.lights.new(name="Sun", type='SUN')
light_data.energy = 3.0
light_obj = bpy.data.objects.new(name="Sun", object_data=light_data)
bpy.context.scene.collection.objects.link(light_obj)
light_obj.location = (2, -3, 4)
light_obj.rotation_euler = (0.785, 0.3, 0.5)

cam_data = bpy.data.cameras.new("Cam")
cam_obj = bpy.data.objects.new("Cam", cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# Setup texture on material
mat = obj.data.materials[0]
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links
bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]

tex_node = nodes.new('ShaderNodeTexImage')
tex_node.image = bpy.data.images.load(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_color.png')
links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

bpy.context.scene.render.resolution_x = 600
bpy.context.scene.render.resolution_y = 600

# 1. Front view (-Y)
cam_obj.location = (0, -3.5, 0)
cam_obj.rotation_euler = (1.5708, 0, 0)
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/market_ref_front.png'
bpy.ops.render.render(write_still=True)

# 2. Side view (+X)
cam_obj.location = (3.5, 0, 0)
cam_obj.rotation_euler = (1.5708, 0, 1.5708)
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/market_ref_side.png'
bpy.ops.render.render(write_still=True)

# 3. Back view (+Y)
cam_obj.location = (0, 3.5, 0)
cam_obj.rotation_euler = (1.5708, 0, 3.14159)
bpy.context.scene.render.filepath = r'C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/market_ref_back.png'
bpy.ops.render.render(write_still=True)

print("REF_RENDERS_DONE")
