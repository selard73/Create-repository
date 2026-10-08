"""Targeted weight fixes for a rigged squirrel, then re-export colour + gray FBX and render previews.
Run: blender --background --python fix_weights.py -- <out_dir> <name> <head_zcut> [tail_zcut] [tail_ymin] [blend] [regions_json]
  head_zcut  > 0: Head/Neck weight on every vertex below this height moves to Chest (bodies that turn with the head)
  tail_zcut  > 0: Tail weight on vertices below this height AND in front of tail_ymin moves to Root (hips, bags)
Leaves everything above the cutoffs untouched, so the face and the tail itself keep their motion.
Careful with a cutoff that empties a bone completely: Roblox only creates a Bone for joints the skinning data
names, so a bone left with no weights never arrives, and SquirrelSetup only counts a mesh as a squirrel when it
has both Root and Tail2. That is what happened to the church mouse, whose whole tail went to Root; he imported
without Tail1/Tail2 and the game did not see him. Leave the tail a token weight, or add the bones back in
Studio afterwards."""
import bpy, sys, os, traceback
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
OUTD, NAME = argv[0], argv[1]
HEAD_ZCUT = float(argv[2]) if len(argv) > 2 else 0.0
TAIL_ZCUT = float(argv[3]) if len(argv) > 3 else 0.0
TAIL_YMIN = float(argv[4]) if len(argv) > 4 else -9.0
BLEND = float(argv[5]) if len(argv) > 5 else 0.25          # height over which head weight fades out below head_zcut
# optional hard region rules, JSON: [{"box": [x0, x1, y0, y1, z0, z1], "from": ["Head", "Neck"], "to": "Chest"}, ...]
import json
REGIONS = json.loads(argv[6]) if len(argv) > 6 and argv[6].strip() else []
LOG = os.path.join(OUTD, "fixw_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    sq = bpy.data.objects["Squirrel"]; arm = bpy.data.objects["SquirrelRig"]
    gi = {g.index: g.name for g in sq.vertex_groups}
    def move(test, src_names, dst_name):
        dst = sq.vertex_groups.get(dst_name) or sq.vertex_groups.new(name=dst_name)
        moved = 0
        for v in sq.data.vertices:
            if not test(v.co): continue
            w = sum(g.weight for g in v.groups if gi[g.group] in src_names)
            if w <= 0: continue
            for nm in src_names:
                if nm in sq.vertex_groups: sq.vertex_groups[nm].remove([v.index])
            cur = sum(g.weight for g in v.groups if gi[g.group] == dst_name)
            dst.add([v.index], min(1.0, cur + w), "REPLACE"); moved += 1
        return moved
    def inbox(c, b): return b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5]
    import bmesh
    def piece(box, seed):
        """Vertices of the connected piece inside box (edges only between in-box vertices) nearest to seed."""
        bm = bmesh.new(); bm.from_mesh(sq.data); bm.verts.ensure_lookup_table()
        inb = {v.index for v in bm.verts if inbox(v.co, box)}
        sd = Vector(seed); start = min(inb, key=lambda i: (bm.verts[i].co - sd).length)
        seen = {start}; stack = [bm.verts[start]]
        while stack:
            v = stack.pop()
            for e in v.link_edges:
                o = e.other_vert(v)
                if o.index in inb and o.index not in seen: seen.add(o.index); stack.append(o)
        bm.free(); return seen
    for r in REGIONS:
        if "seed" in r:
            r["_set"] = piece(r["box"], r["seed"])
            sel = r["_set"]
            n = move(lambda c, sel=sel, pos={i: tuple(sq.data.vertices[i].co) for i in sel}: tuple(c) in set(pos.values()), tuple(r["from"]), r["to"])
            log(f"piece {r['box']} seed {r['seed']}: {len(sel)} verts in piece, {n} moved {'+'.join(r['from'])} -> {r['to']}")
        else:
            log(f"region {r['box']} {'+'.join(r['from'])} -> {r['to']}: {move(lambda c, b=r['box']: inbox(c, b), tuple(r['from']), r['to'])} vertices")
    if HEAD_ZCUT > 0:
        # soft falloff: full head weight at HEAD_ZCUT, none at HEAD_ZCUT - BLEND and below, linear in between,
        # so a scarf or collar near the neck still bends smoothly (no crease at a hard line)
        z1, z0 = HEAD_ZCUT, HEAD_ZCUT - BLEND
        chest = sq.vertex_groups.get("Chest") or sq.vertex_groups.new(name="Chest")
        moved = 0
        for v in sq.data.vertices:
            if v.co.z >= z1: continue
            t = max(0.0, min(1.0, (v.co.z - z0) / (z1 - z0)))
            take = 0.0
            for g in list(v.groups):
                nm = gi[g.group]
                if nm in ("Head", "Neck") and g.weight > 0:
                    keep = g.weight * t; take += g.weight - keep
                    if keep > 1e-4: sq.vertex_groups[nm].add([v.index], keep, "REPLACE")
                    else: sq.vertex_groups[nm].remove([v.index])
            if take > 1e-4:
                cur = sum(g.weight for g in v.groups if gi[g.group] == "Chest")
                chest.add([v.index], min(1.0, cur + take), "REPLACE"); moved += 1
        log(f"head->chest soft falloff z {z0:.2f}..{z1:.2f}: {moved} vertices adjusted")
    if TAIL_ZCUT > 0:
        log(f"tail->root below z {TAIL_ZCUT} and y < {TAIL_YMIN}: {move(lambda c: c.z < TAIL_ZCUT and c.y < TAIL_YMIN, ('Tail1', 'Tail2'), 'Root')} vertices")
    for r in REGIONS:                                          # proof: what still follows the source bones in each box / piece
        vs = [sq.data.vertices[i] for i in r["_set"]] if "_set" in r else [v for v in sq.data.vertices if inbox(v.co, r["box"])]
        left = [sum(g.weight for g in v.groups if gi[g.group] in r["from"]) for v in vs]
        log(f"after: region {r['box']} {len(vs)} verts, mean {'+'.join(r['from'])} weight {sum(left) / max(1, len(left)):.3f}, max {max(left) if left else 0:.2f}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, f"{NAME}_rigged.blend"))
    tex = [n for n in sq.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
    def export(tag, png):
        tex.image = bpy.data.images.load(png)
        bpy.ops.object.select_all(action="DESELECT"); sq.select_set(True); arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"{NAME}_{tag}.fbx"), use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                                 global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    export("color", os.path.join(OUTD, f"{NAME}_1k.png"))
    export("gray", os.path.join(OUTD, f"{NAME}_gray_1k.png"))
    # previews: colour + gray, a straight 3/4 view from eye height (Z up, no roll)
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
    sh.background_type = "VIEWPORT"; sh.background_color = (0.86, 0.88, 0.92)
    sc.render.resolution_x, sc.render.resolution_y = 700, 700; sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    for o in list(bpy.data.objects):
        if o.type == "CAMERA": bpy.data.objects.remove(o)
    cam = bpy.data.cameras.new("Cam"); camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    cam.lens = 60
    ctr = Vector((0, 0, 1.15))
    camo.location = ctr + Vector((-6.0, -7.0, 2.6))
    camo.rotation_euler = (ctr - camo.location).to_track_quat("-Z", "Y").to_euler()
    for tag, png in (("color", f"{NAME}_1k.png"), ("gray", f"{NAME}_gray_1k.png")):
        tex.image = bpy.data.images.load(os.path.join(OUTD, png))
        sc.render.filepath = os.path.join(OUTD, f"preview_{tag}.png"); bpy.ops.render.render(write_still=True)
    log("FIXW_DONE")
except Exception:
    log(traceback.format_exc())
