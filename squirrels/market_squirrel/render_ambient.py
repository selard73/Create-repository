import bpy, math

bpy.ops.wm.open_mainfile(filepath=r"C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_rigged.blend")

world = bpy.context.scene.world
if not world:
    world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
    bg.inputs[1].default_value = 1.0

# Add a fill light in front
fill_light = bpy.data.objects.get("FillLight")
if not fill_light:
    fill_data = bpy.data.lights.new(name="FillLight", type='POINT')
    fill_data.energy = 200.0
    fill_light = bpy.data.objects.new(name="FillLight", object_data=fill_data)
    bpy.context.scene.collection.objects.link(fill_light)
fill_light.location = (0, -2.5, 1.5)

cam = bpy.data.objects.get('FrontCam')
if cam:
    cam.location = (0, -3.2, 1.3)
    cam.rotation_euler = (math.radians(85), 0, 0)

scene = bpy.context.scene
scene.render.resolution_x = 800
scene.render.resolution_y = 800
scene.render.filepath = r"C:/Users/slard/.gemini/antigravity/brain/4f96fdcb-94d3-476a-a289-803dced405eb/market_ambient_test.png"
bpy.ops.render.render(write_still=True)
print("AMBIENT_RENDER_DONE")
