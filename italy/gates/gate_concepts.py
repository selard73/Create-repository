"""Oct 8 2026: concept renders of the proposed Porto Nocciola gates (for Shannon's page, before anything is built).
Everything is boxes, cylinders and wedges at stud scale (1 Blender unit = 1 stud), i.e. things that can be rebuilt from
Parts in Studio. A 5-stud blocky figure stands by each gate for scale. Eevee, sun + sky world, Standard view transform
(same as the gorge previews, so colours read roughly as they do in Roblox).
Usage: blender -b --python gate_concepts.py -- [name ...]      Output: renders/<name>.png"""
import bpy, os, sys, math
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "renders"); os.makedirs(OUT, exist_ok=True)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ONLY = set(argv)


def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


MATS = {}
def mat(name, rgb, rough=0.85, metal=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (lin(rgb[0] / 255), lin(rgb[1] / 255), lin(rgb[2] / 255), 1)
    b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    MATS[name] = m; return m


STONE, STONE2, JOINT = (206, 198, 182), (190, 181, 164), (150, 140, 126)
OCHRE, TERRA, WOOD, WOOD2 = (220, 191, 128), (178, 92, 62), (124, 80, 48), (104, 66, 40)
IRON, ROPE, BOARD, RED = (40, 40, 45), (196, 166, 110), (240, 228, 200), (150, 40, 30)
COBBLE, GRASS, ROCK = (196, 191, 181), (120, 170, 90), (150, 148, 150)


def box(name, size, loc, rgb, rot=(0, 0, 0), m=None, **kw):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.object; o.name = name; o.scale = size
    o.data.materials.append(m or mat(str(rgb) + str(kw), rgb, **kw)); return o


def cyl(name, r, h, loc, rgb, rot=(0, 0, 0), verts=24, **kw):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.object; o.name = name; o.data.materials.append(mat(str(rgb) + str(kw), rgb, **kw)); return o


def ball(name, r, loc, rgb, **kw):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=20, ring_count=12)
    o = bpy.context.object; o.name = name; bpy.ops.object.shade_smooth()
    o.data.materials.append(mat(str(rgb) + str(kw), rgb, **kw)); return o


def prism(name, pts, X, depth, rgb):
    import bmesh
    me = bpy.data.meshes.new(name); bm = bmesh.new()
    front = [bm.verts.new((X + x, -depth / 2, z)) for (x, z) in pts]
    back = [bm.verts.new((X + x, depth / 2, z)) for (x, z) in pts]
    bm.faces.new(list(reversed(front))); bm.faces.new(back)
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.data.materials.append(mat(str(rgb), rgb)); return o


FONT = None
def text(name, body, loc, size, rgb, rot=(math.pi / 2, 0, 0), align="CENTER"):
    global FONT
    if FONT is None:
        for f in ("C:/Windows/Fonts/georgiab.ttf", "C:/Windows/Fonts/timesbd.ttf", "C:/Windows/Fonts/arialbd.ttf"):
            if os.path.exists(f): FONT = bpy.data.fonts.load(f); break
    cu = bpy.data.curves.new(name, "FONT"); cu.body = body; cu.size = size; cu.align_x = align; cu.align_y = "CENTER"
    if FONT: cu.font = FONT
    cu.extrude = 0.02
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o)
    o.location = loc; o.rotation_euler = rot; o.data.materials.append(mat(str(rgb), rgb)); return o


def figure(x, y, yaw=0.0):
    """a 5-stud blocky player for scale"""
    c, s = math.cos(yaw), math.sin(yaw)
    def P(dx, dy, z): return (x + dx * c - dy * s, y + dx * s + dy * c, z)
    for dx in (-0.5, 0.5): box("leg", (1, 1, 2), P(dx, 0, 1), (60, 80, 140))
    box("torso", (2, 1, 2), P(0, 0, 3), (220, 120, 60))
    for dx in (-1.5, 1.5): box("arm", (1, 1, 2), P(dx, 0, 3), (240, 200, 160))
    box("head", (1.2, 1.2, 1.2), P(0, 0, 4.6), (240, 200, 160))


def ground(x0, rgb=COBBLE, w=60, d=60):
    box("ground", (w, d, 0.4), (x0, 0, -0.2), rgb)


def stones_row(name, x0, x1, y, z0, h, depth, seed, rgb=STONE):
    """an irregular dry-stone course from x0 to x1"""
    import random
    r = random.Random(seed); x = x0
    while x < x1 - 0.2:
        w = min(r.uniform(0.9, 1.8), x1 - x)
        dv = r.randint(-16, 8); col = tuple(min(255, max(0, v + dv)) for v in rgb)
        box(name, (w - 0.08, depth * r.uniform(0.9, 1.0), h - 0.06), (x + w / 2, y + r.uniform(-0.06, 0.06), z0 + h / 2), col)
        x += w


# --------------------------------------------------------------------------------------------- the gates
def porta_del_borgo(X):
    """stone town arch over the stairs, two wooden doors under it, an iron fan in the lunette, a plaque"""
    ground(X)
    W, SPR, R = 12.0, 8.0, 6.0          # opening width, springing height, arch radius
    for sx in (-1, 1):                                       # piers
        cx = X + sx * (W / 2 + 1.75)
        box("plinth", (4.1, 4.0, 1.0), (cx, 0, 0.5), STONE2)
        box("impost", (3.9, 3.8, 0.6), (cx, 0, SPR - 0.3), STONE2)
        for k in range(1, 7):                                # rustication joints
            box("joint", (3.5, 3.48, 0.12), (cx, 0, k * 1.15 + 0.4), JOINT)
    # the wall with its round-arched opening: one solid piece (piers + spandrels + attic), then a raised arch ring with joints
    Wt, Ht = W + 7.0, SPR + R + 4.4
    pts = [(-Wt / 2, 0), (-W / 2, 0), (-W / 2, SPR)]
    for i in range(1, 24): a = math.pi - math.pi * i / 24; pts.append((math.cos(a) * W / 2, SPR + math.sin(a) * W / 2))
    pts += [(W / 2, SPR), (W / 2, 0), (Wt / 2, 0), (Wt / 2, Ht), (-Wt / 2, Ht)]
    prism("archwall", pts, X, 3.4, STONE)
    ring = []
    for i in range(25): a = math.pi * i / 24; ring.append((math.cos(a) * (R + 1.6), SPR + math.sin(a) * (R + 1.6)))
    for i in range(24, -1, -1): a = math.pi * i / 24; ring.append((math.cos(a) * R, SPR + math.sin(a) * R))
    prism("archring", ring, X, 3.8, STONE2)
    for i in range(1, 11):                                   # voussoir joints on the front of the ring
        am = math.pi * i / 11
        box("vjoint", (1.62, 0.06, 0.1), (X + math.cos(am) * (R + 0.8), -1.92, SPR + math.sin(am) * (R + 0.8)), JOINT, rot=(0, -am, 0))
    box("keystone", (1.5, 4.0, 2.4), (X, 0, SPR + R + 1.0), STONE2)
    box("cornice", (Wt + 0.8, 4.0, 0.6), (X, 0, Ht + 0.3), STONE2)
    for i in range(12):                                      # terracotta coping
        cyl("tile", 0.32, 4.0, (X - 9.6 + i * 1.75, 0, Ht + 0.8), TERRA, rot=(math.pi / 2, 0, 0), verts=10)
    box("plaque", (7.0, 0.2, 1.3), (X, -1.75, SPR + R + 2.95), BOARD)
    text("plaque_t", "PORTA DEL BORGO", (X, -1.87, SPR + R + 2.93), 0.78, RED)
    # doors (closed): planks + iron straps + rings
    for sx in (-1, 1):
        cx = X + sx * W / 4
        for k in range(6):
            box("plank", (W / 12 - 0.06, 0.4, SPR), (cx - W / 4 + (k + 0.5) * W / 12, 0.2, SPR / 2), WOOD if k % 2 else WOOD2)
        for z in (1.4, 4.0, 6.6):
            box("strap", (W / 2 - 0.4, 0.12, 0.35), (cx, -0.06, z), IRON, rough=0.5, metal=0.6)
        cyl("ring", 0.35, 0.1, (X + sx * 0.8, -0.1, 4.2), IRON, rot=(math.pi / 2, 0, 0), verts=16, rough=0.5, metal=0.6)
    # iron fan in the lunette
    for i in range(9):
        a = math.pi * (i + 0.5) / 9
        box("fanbar", (0.16, 0.16, R - 0.3), (X + math.cos(a) * (R - 0.3) / 2, 0.3, SPR + math.sin(a) * (R - 0.3) / 2), IRON, rot=(0, -a + math.pi / 2, 0), rough=0.5, metal=0.6)
    box("fanbase", (W, 0.3, 0.3), (X, 0.3, SPR + 0.15), IRON, rough=0.5, metal=0.6)
    # stair treads running up through the arch
    for k in range(8):
        box("step", (W + 6, 1.4, 0.6), (X, 2.5 + k * 1.4, 0.3 + k * 0.6), STONE2)
    for sx in (-1, 1): box("house", (6, 10, 16), (X + sx * 13.5, 4, 8), OCHRE if sx < 0 else (221, 132, 101))
    figure(X + 11.5, -3.0, -0.5)


def iron_gate(X, wall=False, sign="", single=False, posts="ochre"):
    """a wrought-iron gate between two pillars (ochre stucco + stone caps + ball finials), or stone posts in a dry-stone wall"""
    ground(X, GRASS if wall else COBBLE)
    if wall: box("pathstrip", (7.5, 60, 0.42), (X, 0, -0.19), COBBLE)
    W = 6.0 if single else 10.0
    H = 6.5
    pc = OCHRE if posts == "ochre" else STONE
    for sx in (-1, 1):
        cx = X + sx * (W / 2 + 0.9)
        box("pillar", (1.8, 1.8, 7.5), (cx, 0, 3.75), pc)
        box("cap", (2.2, 2.2, 0.5), (cx, 0, 7.75), STONE2)
        ball("finial", 0.6, (cx, 0, 8.6), STONE2)
        if wall:
            x0, x1 = (X + W / 2 + 1.8, X + W / 2 + 14) if sx > 0 else (X - W / 2 - 14, X - W / 2 - 1.8)
            for row in range(3):
                stones_row("drystone", x0, x1, 0, row * 1.1, 1.1, 1.6, 7 + row + sx * 3)
            box("coping", (x1 - x0, 1.9, 0.35), ((x0 + x1) / 2, 0, 3.47), STONE2)
    leaves = [(X, W)] if single else [(X - W / 4, W / 2), (X + W / 4, W / 2)]
    for (cx, lw) in leaves:
        nb = int(lw / 0.55)
        for i in range(nb + 1):
            bx = cx - lw / 2 + 0.15 + i * (lw - 0.3) / nb
            top = H - 0.6 + 0.7 * math.sin(math.pi * (bx - (cx - lw / 2)) / lw)      # gently arched top
            box("bar", (0.13, 0.13, top - 0.3), (bx, 0, 0.3 + (top - 0.3) / 2), IRON, rough=0.45, metal=0.7)
            box("spear", (0.24, 0.24, 0.24), (bx, 0, top + 0.12), IRON, rot=(0, math.pi / 4, 0), rough=0.45, metal=0.7)
        for z in (0.5, 2.2, H - 1.4):
            box("rail", (lw - 0.1, 0.18, 0.18), (cx, 0, z), IRON, rough=0.45, metal=0.7)
        for k in (-1, 1):                                    # scrolls
            bpy.ops.mesh.primitive_torus_add(major_radius=0.55, minor_radius=0.07, location=(cx + k * lw / 4, 0, 1.35), rotation=(math.pi / 2, 0, 0))
            o = bpy.context.object; o.data.materials.append(mat("iron_t", IRON, rough=0.45, metal=0.7))
    if sign:
        box("signboard", (5.6, 0.15, 1.5), (X, -0.25, H - 2.6), BOARD)
        for j, line in enumerate(sign.split("\n")):
            text("sign_t", line, (X, -0.35, H - 2.3 - j * 0.65), 0.5, RED)
    figure(X + W / 2 + 4.5, -2.5, -0.5)


def rope_chain(X):
    """the Beach steps: two bollards, a rope swag with a short chain at the hook, a hanging board"""
    box("ground", (60, 30, 0.4), (X, -15, -0.2), COBBLE)
    for sx in (-1, 1):
        box("cheek", (20, 30, 12), (X + sx * 15.5, 15, -6.2), ROCK)
        box("cheekgrass", (20, 30, 0.6), (X + sx * 15.5, 15, 0.1), GRASS)
    box("sea", (60, 40, 0.2), (X, 30, -8), (80, 150, 170), rough=0.2)
    W = 9.0
    for sx in (-1, 1):
        cx = X + sx * (W / 2 + 0.6)
        cyl("bollard", 0.55, 3.6, (cx, 0, 1.8), WOOD2, verts=16)
        cyl("cap", 0.65, 0.3, (cx, 0, 3.7), IRON, verts=16, rough=0.5, metal=0.6)
        bpy.ops.mesh.primitive_torus_add(major_radius=0.32, minor_radius=0.07, location=(cx - sx * 0.6, 0, 3.0), rotation=(0, math.pi / 2, 0))
        bpy.context.object.data.materials.append(mat("iron_t", IRON, rough=0.45, metal=0.7))
    # rope: a catenary from hook to hook made of short cylinders
    a, b = X - W / 2, X + W / 2 - 1.4
    N = 18
    pts = []
    for i in range(N + 1):
        t = i / N; x = a + (b - a) * t
        pts.append((x, 3.0 - 0.9 * 4 * t * (1 - t)))
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
        L = math.hypot(x1 - x0, z1 - z0); ang = math.atan2(z1 - z0, x1 - x0)
        cyl("rope", 0.16, L + 0.05, (mx, 0, mz), ROPE, rot=(0, math.pi / 2 - ang, 0), verts=10)
    for k in range(4):                                       # chain links from the rope end to the right hook
        x = b + 0.2 + k * 0.35
        bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.05, location=(x, 0, 3.0), rotation=((k % 2) * math.pi / 2, math.pi / 2, 0))
        bpy.context.object.data.materials.append(mat("iron_t", IRON, rough=0.45, metal=0.7))
    mid = pts[N // 2]
    bz = mid[1] - 1.0
    box("board", (5.4, 0.15, 1.6), (X - 0.7, -0.1, bz), BOARD)
    box("boardrim", (5.6, 0.12, 1.8), (X - 0.7, 0.0, bz), (60, 110, 160))
    for sx in (-1, 1): box("hanger", (0.05, 0.05, 0.75), (X - 0.7 + sx * 2.0, -0.1, bz + 1.05), ROPE)
    text("b1", "SPIAGGIA CHIUSA", (X - 0.7, -0.22, bz + 0.3), 0.52, RED)
    text("b2", "alta marea!", (X - 0.7, -0.22, bz - 0.38), 0.5, (40, 80, 130))
    # the steps going down behind
    for k in range(8):
        box("step", (W + 2, 1.3, 0.5), (X, 0.65 + k * 1.3, -0.25 - k * 0.5), STONE2)
    figure(X + 7.5, -4.0, -0.6)


def farm_gate(X, sign=""):
    """the olive/lemon terraces: a five-bar wooden gate with a brace, rough posts, a little painted sign"""
    ground(X, GRASS)
    box("pathstrip", (6.5, 60, 0.42), (X, 0, -0.19), (200, 180, 150))
    W = 7.0
    for sx in (-1, 1):
        cx = X + sx * (W / 2 + 0.5)
        box("post", (1.0, 1.0, 5.4), (cx, 0, 2.7), WOOD2)
        box("postcap", (1.15, 1.15, 0.25), (cx, 0, 5.5), WOOD)
        # a short stone terrace wall either side
        x0, x1 = (cx + 0.5, cx + 12) if sx > 0 else (cx - 12, cx - 0.5)
        for row in range(2): stones_row("tw", x0, x1, 0.6, row * 1.0, 1.0, 1.4, 31 + row + sx)
    for k in range(5):
        box("rail", (W - 0.2, 0.3, 0.42), (X, 0, 0.8 + k * 0.85), WOOD if k % 2 else WOOD2)
    for xx in (X - W / 2 + 0.45, X, X + W / 2 - 0.45):
        box("stile", (0.4, 0.34, 4.0), (xx, 0, 2.5), WOOD2)
    L = math.hypot(W - 1.0, 3.3); ang = math.atan2(3.3, W - 1.0)
    box("brace", (L, 0.3, 0.38), (X, -0.05, 2.5), WOOD, rot=(0, -ang, 0))
    if sign:
        box("sign", (3.6, 0.12, 1.1), (X + W / 2 + 0.5, -0.6, 4.4), (250, 225, 90))
        text("sign_t", sign, (X + W / 2 + 0.5, -0.7, 4.4), 0.45, (60, 90, 40))
    # lemon trees behind
    for (dx, dy) in ((-6, 8), (5, 11)):
        cyl("trunk", 0.35, 3.2, (X + dx, dy, 1.6), WOOD2, verts=10)
        ball("crown", 2.0, (X + dx, dy, 4.2), (90, 140, 70))
        for i in range(7):
            a = i * 0.9
            ball("lemon", 0.25, (X + dx + math.cos(a) * 1.7, dy + math.sin(a) * 1.7 - 0.6, 3.6 + (i % 3) * 0.5), (250, 220, 60))
    figure(X + W / 2 + 4.0, -2.2, -0.5)


GATES = {
    "g1_porta_del_borgo": (lambda X: porta_del_borgo(X), (-9, -30, 6.0), (1.5, 0, 8.0), 30),
    "g2_sentiero_iron": (lambda X: iron_gate(X, sign="SENTIERO DEL FARO"), (-12, -19, 6.0), (0, 0, 4.0), 30),
    "g3_beach_rope": (lambda X: rope_chain(X), (-7, -16, 10.0), (0, 3, 0.5), 28),
    "g4_dry_stone_iron": (lambda X: iron_gate(X, wall=True, single=True, posts="stone", sign="FARO\nPROPRIETÀ PRIVATA"), (-12, -20, 6.5), (0, 0, 3.5), 30),
    "g5_farm_gate": (lambda X: farm_gate(X, sign="LIMONETO"), (-11, -17, 6.0), (0, 0, 3.0), 30),
}


def setup():
    global FONT
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear(); FONT = None            # the factory reset deletes them
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try: sc.render.engine = eng; break
        except Exception: pass
    sc.view_settings.view_transform = "Standard"
    try: sc.eevee.taa_render_samples = 48
    except Exception: pass
    w = bpy.data.worlds.new("Sky"); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (lin(0.62), lin(0.78), lin(0.95), 1); bg.inputs["Strength"].default_value = 0.7
    sd = bpy.data.lights.new("Sun", "SUN"); sd.energy = 3.4; sd.angle = math.radians(2)
    sun = bpy.data.objects.new("Sun", sd); sc.collection.objects.link(sun)
    sun.rotation_euler = Vector((0.45, 0.65, -0.62)).to_track_quat("-Z", "Y").to_euler()
    cd = bpy.data.cameras.new("Cam"); cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 1200, 800


def main():
    for name, (build, eye, at, lens) in GATES.items():
        if ONLY and name not in ONLY: continue
        setup()
        build(0.0)
        sc = bpy.context.scene; cam = sc.camera
        cam.data.lens = lens
        e, a = Vector(eye), Vector(at)
        cam.location = e; cam.rotation_euler = (a - e).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUT, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("RENDERED", name)


main()
