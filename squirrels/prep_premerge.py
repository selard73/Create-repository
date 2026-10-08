"""Pre-pass for huge Meshy FBX files (Oct 4 2026: the 2M-tri crab catcher shattered in prep_squirrel's 10x passes).
Import, merge by distance, report islands, decimate gently (ratio >= 0.35 per pass) to TARGET, export FBX.
Run: blender --background --python prep_premerge.py -- <in.fbx> <out.fbx> <target_tris> <log>"""
import bpy, sys, bmesh, traceback
argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT, TARGET, LOG = argv[0], argv[1], int(argv[2]), argv[3]
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.fbx(filepath=IN, use_custom_normals=False)
    except Exception:
        bpy.ops.import_scene.fbx(filepath=IN)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects: o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1: bpy.ops.object.join()
    sq = bpy.context.view_layer.objects.active
    tris = lambda: sum(len(p.vertices) - 2 for p in sq.data.polygons)
    log(f"meshes {len(meshes)} verts {len(sq.data.vertices)} tris {tris()}")
    dim = max(sq.dimensions)
    bm = bmesh.new(); bm.from_mesh(sq.data)
    n0 = len(bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dim * 1e-5)
    log(f"merged {n0 - len(bm.verts)} duplicate verts (dist {dim*1e-5:.6f})")
    # islands
    seen = set(); sizes = []
    for v in bm.verts:
        if v.index in seen: continue
        stack = [v]; seen.add(v.index); n = 0
        while stack:
            a = stack.pop(); n += 1
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in seen: seen.add(b.index); stack.append(b)
        sizes.append(n)
    sizes.sort(reverse=True)
    log(f"islands {len(sizes)} biggest {sizes[:8]} singles {sum(1 for s in sizes if s < 4)}")
    bm.to_mesh(sq.data); bm.free()
    log(f"tris after merge {tris()}")
    for _ in range(12):
        t = tris()
        if t <= TARGET * 1.02: break
        mod = sq.modifiers.new("D", "DECIMATE"); mod.ratio = max(TARGET / t, 0.35); mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
        log(f"  pass -> {tris()}")
    bpy.ops.export_scene.fbx(filepath=OUT, use_selection=False, path_mode="COPY", embed_textures=False)
    log("PREMERGE_DONE")
except Exception:
    log(traceback.format_exc())
