import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=r'C:/Users/slard/roblox-props/squirrels/market_squirrel/market_squirrel_prepped.blend')

obj = bpy.data.objects['Squirrel']

with open(r'C:/Users/slard/roblox-props/squirrels/market_squirrel/anatomy.txt', 'w') as f:
    for z in [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2]:
        layer = [v for v in obj.data.vertices if abs(v.co.z - z) < 0.05]
        if layer:
            min_x = min(v.co.x for v in layer)
            max_x = max(v.co.x for v in layer)
            min_y = min(v.co.y for v in layer)
            max_y = max(v.co.y for v in layer)
            f.write(f"Z={z:.1f}: count={len(layer)}, X=[{min_x:.3f}, {max_x:.3f}], Y=[{min_y:.3f}, {max_y:.3f}]\n")

    # Tail is behind (Y > 0.15)
    tail_candidates = [v for v in obj.data.vertices if v.co.y > 0.20 and v.co.z > 0.6]
    f.write(f"Tail candidates (y > 0.2, z > 0.6): {len(tail_candidates)}\n")
    if tail_candidates:
        f.write(f"  Tail Z range: [{min(v.co.z for v in tail_candidates):.3f}, {max(v.co.z for v in tail_candidates):.3f}]\n")
        f.write(f"  Tail X range: [{min(v.co.x for v in tail_candidates):.3f}, {max(v.co.x for v in tail_candidates):.3f}]\n")
        f.write(f"  Tail Y range: [{min(v.co.y for v in tail_candidates):.3f}, {max(v.co.y for v in tail_candidates):.3f}]\n")

    # Grocery bags are on the sides (left bag x < -0.4, right bag x > 0.4)
    bags = [v for v in obj.data.vertices if abs(v.co.x) > 0.45 and v.co.z < 1.3]
    f.write(f"Bag candidates (|x| > 0.45, z < 1.3): {len(bags)}\n")

    # Head is upper forward (z > 1.4, y < 0.2)
    head_candidates = [v for v in obj.data.vertices if v.co.z > 1.4 and v.co.y < 0.15]
    f.write(f"Head candidates (z > 1.4, y < 0.15): {len(head_candidates)}\n")
    if head_candidates:
        f.write(f"  Head Z range: [{min(v.co.z for v in head_candidates):.3f}, {max(v.co.z for v in head_candidates):.3f}]\n")
        f.write(f"  Head Y range: [{min(v.co.y for v in head_candidates):.3f}, {max(v.co.y for v in head_candidates):.3f}]\n")
