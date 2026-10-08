"""Crab trap for the 1001 Squirrels crab game (Oct 4 2026): a round pot like the one Enzo holds - two grey hoops, four rods,
green netting all round (alpha texture), a netted back and a funnel entrance at the front.
Built in studs (1 Blender unit = 1 stud), axis along Blender Y. Writes crabtrap.fbx (TrapFrame plain grey, TrapNet textured)
+ net.png + a preview render.  Run: blender -b --python gen_crabtrap.py"""
import bpy, bmesh, math, os, traceback
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "gen_log.txt")
R, L = 1.0, 1.3            # hoop radius, trap length (studs)
SEG = 24
def log(m): open(LOG, "a").write(str(m) + "\n")

def net_png(path):
    from PIL import Image, ImageDraw
    N = 512
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0)); dr = ImageDraw.Draw(im)
    cord = (58, 108, 84, 255); dark = (36, 74, 58, 255)
    step = N // 4
    for k in range(-4, 9):                       # diamond lattice, tiles seamlessly at 4 cells per repeat
        dr.line([(k * step, 0), (k * step + N, N)], fill=cord, width=9)
        dr.line([(k * step, N), (k * step + N, 0)], fill=cord, width=9)
    for i in range(5):
        for j in range(5):
            for (x, y) in ((i * step, j * step), (i * step + step // 2, j * step + step // 2)):
                dr.ellipse([x - 8, y - 8, x + 8, y + 8], fill=dark)
    im.save(path)

if __name__ == "__main__" and not bpy.app.background:
    pass
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    png = os.path.join(D, "net.png")

    # ---------- frame: hoops + rods + funnel ring
    bm = bmesh.new()
    def torus(cy, rr, tube, seg=SEG, tseg=6):
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            row = []
            for j in range(tseg):
                b = 2 * math.pi * j / tseg
                rad = rr + tube * math.cos(b)
                row.append(bm.verts.new((rad * math.cos(a), cy + tube * math.sin(b), rad * math.sin(a))))
            ring.append(row)
        for i in range(seg):
            for j in range(tseg):
                bm.faces.new((ring[i][j], ring[(i + 1) % seg][j], ring[(i + 1) % seg][(j + 1) % tseg], ring[i][(j + 1) % tseg]))
    torus(-L / 2, R, 0.07); torus(L / 2, R, 0.07)
    torus(-L / 2 + 0.38, 0.32, 0.04, 16, 5)        # the funnel's inner ring
    def rod(a, w=0.06):
        x, z = R * math.cos(a), R * math.sin(a)
        n = (math.cos(a), math.sin(a)); t = (-math.sin(a), math.cos(a))
        vs = []
        for (yy) in (-L / 2, L / 2):
            for (dn, dt) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                vs.append(bm.verts.new((x + (dn * n[0] + dt * t[0]) * w / 2, yy, z + (dn * n[1] + dt * t[1]) * w / 2)))
        for k in range(4):
            bm.faces.new((vs[k], vs[(k + 1) % 4], vs[4 + (k + 1) % 4], vs[4 + k]))
    for k in range(4): rod(math.pi / 4 + k * math.pi / 2)
    # a rope bridle on top: a small loop to tie the line to
    torus_top = None
    me = bpy.data.meshes.new("TrapFrame"); bm.to_mesh(me); bm.free()
    frame = bpy.data.objects.new("TrapFrame", me); bpy.context.collection.objects.link(frame)
    for p in me.polygons: p.use_smooth = True
    mf = bpy.data.materials.new("Metal"); mf.diffuse_color = (0.42, 0.44, 0.46, 1); me.materials.append(mf)

    # ---------- net: side cylinder, back disc, front funnel cone (all one textured mesh)
    bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")
    def quad(vs, uvs):
        f = bm.faces.new(vs)
        for lp, u in zip(f.loops, uvs): lp[uv].uv = u
    Rn = R - 0.01
    side = [[bm.verts.new((Rn * math.cos(2 * math.pi * i / SEG), y, Rn * math.sin(2 * math.pi * i / SEG))) for y in (-L / 2, L / 2)] for i in range(SEG + 1)]
    for i in range(SEG):
        u0, u1 = 6 * i / SEG, 6 * (i + 1) / SEG
        quad((side[i][0], side[i + 1][0], side[i + 1][1], side[i][1]), ((u0, 0), (u1, 0), (u1, 1.5), (u0, 1.5)))
    # back disc (fan), planar uv
    cb = bm.verts.new((0, L / 2, 0))
    for i in range(SEG):
        a0, a1 = 2 * math.pi * i / SEG, 2 * math.pi * (i + 1) / SEG
        v0 = bm.verts.new((Rn * math.cos(a0), L / 2, Rn * math.sin(a0))); v1 = bm.verts.new((Rn * math.cos(a1), L / 2, Rn * math.sin(a1)))
        f = bm.faces.new((cb, v1, v0))
        for lp in f.loops: lp[uv].uv = (lp.vert.co.x * 1.5 + 0.5, lp.vert.co.z * 1.5 + 0.5)
    # front funnel: cone from the front hoop (y -L/2, r R) to the inner ring (y -L/2+0.38, r 0.32)
    for i in range(SEG):
        a0, a1 = 2 * math.pi * i / SEG, 2 * math.pi * (i + 1) / SEG
        o0 = bm.verts.new((Rn * math.cos(a0), -L / 2, Rn * math.sin(a0))); o1 = bm.verts.new((Rn * math.cos(a1), -L / 2, Rn * math.sin(a1)))
        i0 = bm.verts.new((0.32 * math.cos(a0), -L / 2 + 0.38, 0.32 * math.sin(a0))); i1 = bm.verts.new((0.32 * math.cos(a1), -L / 2 + 0.38, 0.32 * math.sin(a1)))
        u0, u1 = 6 * i / SEG, 6 * (i + 1) / SEG
        quad((o0, o1, i1, i0), ((u0, 0), (u1, 0), (u1, 0.7), (u0, 0.7)))
    me2 = bpy.data.meshes.new("TrapNet"); bm.to_mesh(me2); bm.free()
    net = bpy.data.objects.new("TrapNet", me2); bpy.context.collection.objects.link(net)
    mn = bpy.data.materials.new("Net"); mn.use_nodes = True; nt = mn.node_tree
    bsdf = nt.nodes["Principled BSDF"]; tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(png)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    mn.blend_method = "CLIP" if hasattr(mn, "blend_method") else None
    me2.materials.append(mn)
    for o in (frame, net):
        log(f"{o.name} tris {sum(len(p.vertices) - 2 for p in o.data.polygons)} dims {tuple(round(v, 2) for v in o.dimensions)}")
    for o in bpy.data.objects: o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(D, "crabtrap.fbx"), use_selection=True, axis_forward="-Z", axis_up="Y",
                             apply_scale_options="FBX_SCALE_ALL", path_mode="COPY", embed_textures=True, add_leaf_bones=False, bake_space_transform=True)
    log("FBX_DONE")
    # preview render
    sc = bpy.context.scene
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = (2.6, -3.0, 1.6); cam.rotation_euler = (math.radians(68), 0, math.radians(40))
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun); sun.rotation_euler = (0.7, 0.2, 0.5)
    sc.world = bpy.data.worlds.new("W"); sc.world.color = (0.85, 0.9, 0.95)
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = 600
    sc.render.filepath = os.path.join(D, "preview.png"); bpy.ops.render.render(write_still=True)
    log("RENDER_DONE")
except Exception:
    log(traceback.format_exc())
