import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"C:/Users/slard/roblox-props/squirrels/police_squirrel/police_squirrel_raw.fbx")

mesh = None
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        mesh = obj
        break

report = []
if mesh:
    report.append(f"Name: {mesh.name}")
    report.append(f"Vertices: {len(mesh.data.vertices)}")
    report.append(f"Polygons: {len(mesh.data.polygons)}")
    report.append(f"Dimensions: {mesh.dimensions}")
    report.append(f"Location: {mesh.location}")
    
    # Bounding box in world coordinates
    min_x = min(v.co.x for v in mesh.data.vertices)
    max_x = max(v.co.x for v in mesh.data.vertices)
    min_y = min(v.co.y for v in mesh.data.vertices)
    max_y = max(v.co.y for v in mesh.data.vertices)
    min_z = min(v.co.z for v in mesh.data.vertices)
    max_z = max(v.co.z for v in mesh.data.vertices)
    report.append(f"Bounds X: [{min_x:.3f}, {max_x:.3f}]")
    report.append(f"Bounds Y: [{min_y:.3f}, {max_y:.3f}]")
    report.append(f"Bounds Z: [{min_z:.3f}, {max_z:.3f}]")
else:
    report.append("No mesh found!")

with open(r"C:/Users/slard/roblox-props/squirrels/police_squirrel/inspect_raw.txt", "w") as f:
    f.write("\n".join(report))
print("INSPECT_RAW_DONE")
