import bpy, sys, os
argv = sys.argv[sys.argv.index("--") + 1:]
D = argv[0]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(D, "broomcart.fbx"))
ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
img = bpy.data.images.load(os.path.join(D, "broomcart_1k.png"))
W, H = img.size; px = list(img.pixels)
me = ob.data; uv = me.uv_layers.active.data
mw = ob.matrix_world
pts = []
for poly in me.polygons:
    u = sum(uv[i].uv[0] for i in poly.loop_indices) / len(poly.loop_indices)
    v = sum(uv[i].uv[1] for i in poly.loop_indices) / len(poly.loop_indices)
    x = min(W - 1, max(0, int(u * W))); y = min(H - 1, max(0, int(v * H)))
    k = (y * W + x) * 4; r, g, b = px[k], px[k + 1], px[k + 2]
    if r > 0.6 and g > 0.55 and b > 0.45 and abs(r - b) < 0.25:
        c = mw @ poly.center
        pts.append((c, mw.to_3x3() @ poly.normal))
out = [f"light polys {len(pts)}"]
if pts:
    xs = [p[0].x for p in pts]; ys = [p[0].y for p in pts]; zs = [p[0].z for p in pts]
    out.append(f"bbox x {min(xs):.3f}..{max(xs):.3f} y {min(ys):.3f}..{max(ys):.3f} z {min(zs):.3f}..{max(zs):.3f}")
    n = sum((p[1] for p in pts), pts[0][1] * 0); out.append(f"mean normal {tuple(round(a, 2) for a in n.normalized())}")
allv = [mw @ v.co for v in me.vertices]
out.append(f"mesh bbox x {min(v.x for v in allv):.3f}..{max(v.x for v in allv):.3f} y {min(v.y for v in allv):.3f}..{max(v.y for v in allv):.3f} z {min(v.z for v in allv):.3f}..{max(v.z for v in allv):.3f}")
open(os.path.join(D, "sign_probe.txt"), "w").write("\n".join(out))
