import bpy, math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_raw.fbx")

mesh = [o for o in bpy.data.objects if o.type == 'MESH'][0]

# Add material with texture
mat = bpy.data.materials.new(name="Mat")
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
tex_node = mat.node_tree.nodes.new('ShaderNodeTexImage')
tex_node.image = bpy.data.images.load(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_color.png")
mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
bsdf.inputs['Roughness'].default_value = 0.8

mesh.data.materials.clear()
mesh.data.materials.append(mat)

# World lighting
world = bpy.data.worlds.new("World")
bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs[0].default_value = (1, 1, 1, 1)
bg.inputs[1].default_value = 1.0

# Camera
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

scene = bpy.context.scene
scene.render.resolution_x = 600
scene.render.resolution_y = 600

# Front render
cam.location = (0, -3.0, 0)
cam.rotation_euler = (math.radians(90), 0, 0)
scene.render.filepath = r"C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/officer_ref_front.png"
bpy.ops.render.render(write_still=True)

# Side render
cam.location = (3.0, 0, 0)
cam.rotation_euler = (math.radians(90), 0, math.radians(90))
scene.render.filepath = r"C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/officer_ref_side.png"
bpy.ops.render.render(write_still=True)

# Back render
cam.location = (0, 3.0, 0)
cam.rotation_euler = (math.radians(90), 0, math.radians(180))
scene.render.filepath = r"C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/officer_ref_back.png"
bpy.ops.render.render(write_still=True)

print("REF_RENDERS_DONE")
