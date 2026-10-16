"""A flower CARD mesh (job 125): two crossed unit quads with 0..1 UVs, the origin at the bottom centre - a MeshPart that wears the rendered
iris picture (gen_iris_card.py) as its TextureID, DoubleSided, scaled in Studio to the clump's size. Output out_iris/flower_card.fbx +
pieces.json (bbox in Roblox axes). Run: blender -b --python gen_flower_card.py"""
import bpy, bmesh, os, json
D = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("IRIS_OUT") or os.path.join(D, "out_iris")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")
for (ax, ay) in ((1, 0), (0, 1)):                                        # a quad across x, a quad across y (Blender z up)
    vs = [bm.verts.new((-0.5 * ax, -0.5 * ay, 0)), bm.verts.new((0.5 * ax, 0.5 * ay, 0)), bm.verts.new((0.5 * ax, 0.5 * ay, 1)), bm.verts.new((-0.5 * ax, -0.5 * ay, 1))]
    f = bm.faces.new(vs)
    for l, (u, v) in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))): l[uv].uv = (u, v)
me = bpy.data.meshes.new("Flower_Card"); bm.to_mesh(me); bm.free()
o = bpy.data.objects.new("Flower_Card", me); bpy.context.scene.collection.objects.link(o)
m = bpy.data.materials.new("Flower_Card"); m.use_nodes = True; m.use_backface_culling = False; me.materials.append(m)
bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "flower_card.fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                         apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False, bake_space_transform=True)
json.dump({"flower_card": {"min": [-0.5, 0.0, -0.5], "max": [0.5, 1.0, 0.5]}}, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
print("flower_card.fbx written")
