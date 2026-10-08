"""Repaint the boat's OUTER hull one flat colour (keeps wood trim, white interior, red/black motor).
Works on prep_v2/boat.blend. For each outward-facing face (not red/black motor faces), paints every texel inside
its UV triangle (dilated 1.5 px) that is not wood-orange and not very dark.
Run: blender --background --python recolor_boat.py -- <boat.blend> <out_dir> <name> <r> <g> <b>   (sRGB 0..1)"""
import bpy, sys, os, math, traceback, colorsys
import numpy as np
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND, OUTD, NAME = argv[0], argv[1], argv[2]
COL = np.array([float(argv[3]), float(argv[4]), float(argv[5])])
os.makedirs(OUTD, exist_ok=True)
LOG = os.path.join(OUTD, f"recolor_{NAME}.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    b = bpy.data.objects["Boat"]
    img = [n for n in b.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0].image
    W, H = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)
    rgb = px[..., :3]
    mx = rgb.max(-1); mn = rgb.min(-1); sat = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0)
    r, g, bl = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    ratio = g / np.maximum(r, 1e-4)
    wood = (r > g) & (g > bl) & (sat > 0.35) & (r > 0.25) & (ratio > 0.33)   # honey/orange/brown, not red specks
    redm = (r > 0.3) & (r > 2.0 * g) & (r > 2.0 * bl)
    dark = mx < 0.22
    me = b.data; uvl = me.uv_layers.active.data
    owner = np.full((H, W), -1, np.int32)
    def raster(uv, fid, dil):
        P = np.array([[u.x * W, u.y * H] for u in uv])
        for k in range(1, len(P) - 1):
            T = P[[0, k, k + 1]]
            x0, y0 = np.floor(T.min(0) - 2).astype(int); x1, y1 = np.ceil(T.max(0) + 2).astype(int)
            x0, y0 = max(x0, 0), max(y0, 0); x1, y1 = min(x1, W - 1), min(y1, H - 1)
            if x1 < x0 or y1 < y0: continue
            xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            area = (T[1, 0] - T[0, 0]) * (T[2, 1] - T[0, 1]) - (T[1, 1] - T[0, 1]) * (T[2, 0] - T[0, 0])
            if abs(area) < 1e-9: continue
            sgn = 1 if area > 0 else -1
            inside = np.ones(xs.shape, bool)
            for i in range(3):
                a, c2 = T[i], T[(i + 1) % 3]
                e = c2 - a; Ln = math.hypot(*e) or 1
                d = sgn * (e[0] * (ys - a[1]) - e[1] * (xs - a[0])) / Ln
                inside &= d >= -dil
            sub = owner[y0:y1 + 1, x0:x1 + 1]
            sub[inside & (sub < 0)] = fid
    NF = len(me.polygons)
    kind = np.zeros(NF, np.int8)   # 0 keep, 1 outer hull, 2 inner wall
    for p in me.polygons:
        c = p.center; n = p.normal
        raster([uvl[li].uv for li in p.loop_indices], p.index, 0.3)
        dv = c - Vector((0, c.y * 0.5, 1.0)); dv.z *= 0.3
        outward = (dv.length > 1e-6 and n.dot(dv.normalized()) > 0.15) or n.z < -0.5
        if outward and c.z <= 1.75: kind[p.index] = 1
        elif c.z > 1.0 and abs(n.z) < 0.7 and c.y < 2.2: kind[p.index] = 3 if c.z > 1.68 else 2
    own = owner >= 0
    cnt = np.bincount(owner[own], minlength=NF).astype(float)
    fw = np.bincount(owner[own], weights=wood[own].astype(float), minlength=NF) / np.maximum(cnt, 1)
    fm = np.bincount(owner[own], weights=(redm | dark)[own].astype(float), minlength=NF) / np.maximum(cnt, 1)
    ystern = np.array([p.center.y > 1.4 for p in me.polygons])
    fm = np.where(ystern, fm, 0.0)   # only the stern holds the motor
    kind[((fw > 0.5) & (kind != 3)) | (fm > 0.3)] = 0
    for p in me.polygons:   # lower hull sides are always paint (not the centre-line stem/keel)
        c = p.center
        if fm[p.index] <= 0.3 and c.z < 1.45 and abs(c.x) > 0.5 and ((p.normal.x * math.copysign(1, c.x) > 0.3 and p.normal.z < 0.5) or p.normal.z < -0.5): kind[p.index] = 1
    # grow owners 3 px into empty texels so filtering at island edges samples the right colour
    for _ in range(3):
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = np.roll(owner, (dy, dx), (0, 1))
            fill = (owner < 0) & (nb >= 0)
            owner[fill] = nb[fill]
    k = np.where(owner >= 0, kind[np.maximum(owner, 0)], 0)
    sel_o = k == 1; sel_i = k == 2
    light = sel_i & (mx > 0.6) & ~wood
    cream = np.median(rgb[light], axis=0) if light.any() else np.array([0.92, 0.91, 0.87])
    log(f"outer faces {int((kind==1).sum())} texels {int(sel_o.sum())}; inner faces {int((kind==2).sum())} texels {int(sel_i.sum())} cream {np.round(cream, 3)}")
    woodc = np.median(rgb[wood & (mx > 0.55)], axis=0)
    rgb[k == 3] = woodc
    nonmotor = np.where(owner >= 0, fm[np.maximum(owner, 0)] <= 0.3, False)
    rgb[(k == 0) & nonmotor & (redm | ((r > 0.3) & (ratio < 0.33) & (sat > 0.4)))] = woodc
    rgb[sel_i] = cream
    rgb[sel_o] = COL
    for p in me.polygons:   # faces too thin to own texels: paint round their UV centre
        if kind[p.index] == 1 and cnt[p.index] < 2:
            uv = [uvl[li].uv for li in p.loop_indices]
            ux = int(sum(u.x for u in uv) / len(uv) % 1 * W); uy = int(sum(u.y for u in uv) / len(uv) % 1 * H)
            blk = (slice(max(uy - 2, 0), uy + 3), slice(max(ux - 2, 0), ux + 3))
            rgb[blk][~wood[blk]] = COL
    px[..., :3] = rgb
    img.pixels[:] = px.ravel()
    tex_out = os.path.join(OUTD, f"boat_tex_{NAME}.png")
    img.filepath_raw = tex_out; img.file_format = "PNG"; img.save()
    bpy.ops.object.select_all(action="DESELECT"); b.select_set(True); bpy.context.view_layer.objects.active = b
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, f"boat_{NAME}.fbx"), use_selection=True, add_leaf_bones=False,
                             bake_anim=False, path_mode="COPY", embed_textures=True, mesh_smooth_type="FACE",
                             global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE")
    sc = bpy.context.scene; sc.render.resolution_x, sc.render.resolution_y = 700, 520
    sc.render.engine = "BLENDER_WORKBENCH"; sc.render.image_settings.file_format = "PNG"
    sh = sc.display.shading; sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_backface_culling = True
    world = bpy.data.worlds.new("w"); sc.world = world; world.color = (0.62, 0.78, 0.9)
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0.55))
    wm = bpy.data.materials.new("Water"); wm.diffuse_color = (0.25, 0.55, 0.62, 1)
    bpy.context.active_object.data.materials.append(wm)
    cam = bpy.data.cameras.new("Cam"); cam.lens = 45
    camo = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(camo); sc.camera = camo
    look_at = Vector((0, 0, 1.5))
    for vn, dv in {"low": (1, -1, 0.28), "high": (-1, -0.8, 0.9)}.items():
        camo.location = look_at + Vector(dv).normalized() * 12.5
        camo.rotation_euler = (look_at - camo.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTD, f"{NAME}_{vn}.png"); bpy.ops.render.render(write_still=True)
    log("DONE")
except Exception:
    log(traceback.format_exc())








