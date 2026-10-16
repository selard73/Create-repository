"""Rebuild Japan's black-rendering Blender meshes WITHOUT their vertex colours (job 125, Oct 16 2026).
Cause (runner 7): JP_Waterfall_Rockface, JP_Onsen_Shore, JP_Koi_Pond_Shore (and the volcano / ridgelines / island cliffs) carry vertex
colours of luminance ~0.13-0.27, which Roblox multiplies over the part's colour, material variant AND texture - so they draw near black
whatever the part is set to (tested: plain Rock grey, SmoothPlastic white, a TextureID - all still black). Geometry and normals are fine.
Input: mesh dumps read from Studio with EditableMesh (read-only) - lines "v x y z" (Roblox mesh space), "t u v", "f v/t v/t v/t".
Output: one FBX with an Empty "dark_rock_fix" holding one mesh per dump, named after the original MeshPart, same mesh-space size, UVs kept,
no vertex colours, smooth-shaded by angle. In Studio each original gets old:ApplyMesh(new) so its CFrame / Size / material stay.
Args: <dump_dir> <out_fbx> <log> name [name ...]"""
import bpy, bmesh, os, sys, math, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
DUMPS, OUT, LOG, NAMES = argv[0], argv[1], argv[2], argv[3:]
def log(s):
    with open(LOG, "a", encoding="utf-8") as f: f.write(str(s) + "\n")
def build(name):
    vs, ts, fs = [], [], []
    for line in open(os.path.join(DUMPS, name + ".txt"), encoding="utf-8"):
        p = line.split()
        if not p: continue
        if p[0] == "v": x, y, z = map(float, p[1:4]); vs.append((x, -z, y))          # Roblox (x, y up, z) -> Blender (x, -z, y)
        elif p[0] == "t": ts.append((float(p[1]), 1.0 - float(p[2])))                 # Roblox UV origin top-left -> Blender bottom-left
        elif p[0] == "f": fs.append([tuple(int(a) for a in q.split("/")) for q in p[1:4]])
    bm = bmesh.new()
    bv = [bm.verts.new(v) for v in vs]
    uv = bm.loops.layers.uv.new("UVMap")
    bad = 0
    for f in fs:
        try:
            face = bm.faces.new([bv[a - 1] for a, _ in f])
        except ValueError:
            bad += 1; continue
        for loop, (_, t) in zip(face.loops, f):
            if t > 0: loop[uv].uv = ts[t - 1]
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    mat = bpy.data.materials.get("Rock") or bpy.data.materials.new("Rock"); me.materials.append(mat)
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    try: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    except Exception:
        for p in me.polygons: p.use_smooth = True
    o.select_set(False)
    xs = [v[0] for v in vs]; ys = [v[1] for v in vs]; zs = [v[2] for v in vs]
    log(f"{name}: {len(vs)} verts, {len(fs)} faces ({bad} duplicate faces skipped), {len(ts)} uvs; Roblox size {max(xs)-min(xs):.3f} x {max(zs)-min(zs):.3f} x {max(ys)-min(ys):.3f}")
    return o
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = [build(n) for n in NAMES]
    emp = bpy.data.objects.new("dark_rock_fix", None); bpy.context.scene.collection.objects.link(emp)
    for o in objs: o.parent = emp
    for i, o in enumerate(objs): o.location.x = i * 120.0          # spread out on import (the swap only takes the mesh)
    bpy.ops.object.select_all(action="DESELECT")
    for o in [emp] + objs: o.select_set(True)
    bpy.context.view_layer.objects.active = emp
    bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, bake_space_transform=True, object_types={"EMPTY", "MESH"}, colors_type="NONE")
    log(f"FIX_DONE {OUT} {os.path.getsize(OUT)} bytes")
except Exception:
    log(traceback.format_exc()); log("FIX_FAILED")
