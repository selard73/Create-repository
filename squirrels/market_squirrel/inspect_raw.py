import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_raw.fbx')

with open(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/inspect_raw.txt', 'w') as f:
    f.write(f"Objects in scene: {[o.name for o in bpy.data.objects]}\n")
    for obj in bpy.data.objects:
        f.write(f"Object: {obj.name}, Type: {obj.type}\n")
        if obj.type == 'MESH':
            verts = obj.data.vertices
            f.write(f"  Vert count: {len(verts)}\n")
            f.write(f"  Dimensions: {obj.dimensions}\n")
            xs = [v.co.x for v in verts]
            ys = [v.co.y for v in verts]
            zs = [v.co.z for v in verts]
            f.write(f"  X range: [{min(xs):.4f}, {max(xs):.4f}]\n")
            f.write(f"  Y range: [{min(ys):.4f}, {max(ys):.4f}]\n")
            f.write(f"  Z range: [{min(zs):.4f}, {max(zs):.4f}]\n")
            f.write(f"  Vertex groups: {[g.name for g in obj.vertex_groups]}\n")
            f.write(f"  Materials: {[m.name for m in obj.data.materials if m]}\n")

bpy.ops.wm.save_as_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel.blend')
