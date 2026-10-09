# Blender (bpy 5.2): turns Shannon's Meshy balloon (one 2M-triangle mesh, metres) into Roblox-ready pieces.
#   Envelope: Meshy's, with the broken ropes cut away (faces hanging clear of the skin), decimated to 18k triangles
#   Basket:   Meshy's, cut just above its four posts (Meshy's frame, cables and rope roots are discarded), 12k
#   Rigging / Burner: rebuilt clean: a mouth ring, 16 cables to the four post tops, a square frame, collars, two
#             burner cans; Flame: a cone for a Neon part in Studio
#   One material with the 1024 px colour, normal and roughness maps; 54 studs tall, basket floor at the origin.
# Run: python meshy_clean.py <meshy.fbx> <texture_dir> <out_dir> [--render]
import bpy, sys, os, math
import numpy as np
from mathutils import Matrix

FBX, TEX, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
RENDER = "--render" in sys.argv
os.makedirs(OUT, exist_ok=True)
Z_MOUTH, Z_POSTS, Z_ROPE_TOP = -0.345, -0.615, 0.12   # model units: envelope mouth; top of the basket posts; ropes rejoin the skin
MARGIN, MIN_ISLAND = 0.035, 3000
TARGET = {"Envelope": 18000, "Basket": 12000}
HEIGHT = 54.0                                          # studs

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FBX)
src = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
me = src.data
nv, nf = len(me.vertices), len(me.polygons)
lt = np.empty(nf, int); me.polygons.foreach_get("loop_total", lt); assert (lt == 3).all(), "not triangulated"
co = np.empty(nv * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
tris = np.empty(nf * 3, int); me.polygons.foreach_get("vertices", tris); tris = tris.reshape(-1, 3)
uv = np.empty(nf * 6); me.uv_layers[0].data.foreach_get("uv", uv); uv = uv.reshape(-1, 3, 2)
print("LOADED verts", nv, "tris", nf)
r = np.hypot(co[:, 0], co[:, 1]); z = co[:, 2]
cen = co[tris].mean(1); rc = np.hypot(cen[:, 0], cen[:, 1]); zc = cen[:, 2]

# ---------- the envelope: cut the ropes hanging clear of the skin ----------
edges = np.linspace(Z_MOUTH, z.max(), 61); mids, skin = [], []
for i in range(60):
    m = (z >= edges[i]) & (z < edges[i + 1])
    if m.sum() > 50: mids.append((edges[i] + edges[i + 1]) / 2); skin.append(np.percentile(r[m], 40))
env_r = np.interp(zc, mids, skin)
cut = (zc >= Z_MOUTH) & (zc < Z_ROPE_TOP) & (rc > env_r + MARGIN)
keep_env = (zc >= Z_MOUTH) & ~cut
print("CUT rope faces", int(cut.sum()))

def components(n, tri):
    a = np.concatenate([tri[:, 0], tri[:, 1], tri[:, 2], tri[:, 1], tri[:, 2], tri[:, 0]])
    b = np.concatenate([tri[:, 1], tri[:, 2], tri[:, 0], tri[:, 0], tri[:, 1], tri[:, 2]])
    order = np.argsort(a, kind="stable"); a, b = a[order], b[order]
    indptr = np.searchsorted(a, np.arange(n + 1))
    comp = -np.ones(n, int); c = 0
    for seed in np.where(np.bincount(tri.ravel(), minlength=n) > 0)[0]:
        if comp[seed] >= 0: continue
        comp[seed] = c; frontier = np.array([seed])
        while frontier.size:
            s, e = indptr[frontier], indptr[frontier + 1]; cnt = e - s
            idx = np.repeat(s - np.cumsum(cnt) + cnt, cnt) + np.arange(cnt.sum())
            nb = np.unique(b[idx]); nb = nb[comp[nb] < 0]; comp[nb] = c; frontier = nb
        c += 1
    return comp
comp = components(nv, tris[keep_env]); sizes = np.bincount(comp[comp >= 0])
small = np.isin(comp[tris[:, 0]], np.where(sizes < MIN_ISLAND)[0])
print("ISLANDS", len(sizes), "fragments dropped", int((sizes < MIN_ISLAND).sum()))
keep_env &= ~small
keep_bask = zc < Z_POSTS

# ---------- where the new rigging attaches: the mouth ring and the four post tops ----------
m = (z >= Z_MOUTH) & (z < Z_MOUTH + 0.03); R_M = float(np.percentile(r[m], 40))
band = np.where((z > Z_POSTS - 0.03) & (z < Z_POSTS) & (r > 0.08))[0]
ang = np.degrees(np.arctan2(co[band, 1], co[band, 0])) % 360
hist = np.bincount((ang // 10).astype(int), minlength=36); peaks = []
for b in np.argsort(-hist):
    a = b * 10 + 5
    if hist[b] > 0 and all(min(abs(a - p), 360 - abs(a - p)) >= 50 for p in peaks): peaks.append(a)
    if len(peaks) == 4: break
posts = []
if len(peaks) == 4:
    for a in peaks:
        d = np.abs(((ang - a + 180) % 360) - 180) < 15
        th = math.atan2(np.sin(np.radians(ang[d])).mean(), np.cos(np.radians(ang[d])).mean()); rr = float(np.median(r[band[d]]))
        posts.append((rr * math.cos(th), rr * math.sin(th)))
else:
    posts = [(0.155 * math.cos(math.radians(a)), 0.155 * math.sin(math.radians(a))) for a in (45, 135, 225, 315)]
posts.sort(key=lambda p: math.atan2(p[1], p[0]))
print("MOUTH r %.3f at z %.3f; POSTS" % (R_M, Z_MOUTH), [(round(p[0], 3), round(p[1], 3)) for p in posts])

# ---------- meshes ----------
S = HEIGHT / (z.max() - z.min())
M = Matrix.Diagonal((S, S, S, 1.0)) @ Matrix.Translation((0, 0, -z.min()))
def link(name, mesh):
    mesh.polygons.foreach_set("use_smooth", np.ones(len(mesh.polygons), bool)); mesh.update()
    ob = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(ob); return ob
def make_part(name, mask):
    t = tris[mask]; used, inv = np.unique(t, return_inverse=True)
    mesh = bpy.data.meshes.new(name); mesh.from_pydata(co[used].tolist(), [], inv.reshape(-1, 3).tolist())
    mesh.uv_layers.new(name="UVMap"); mesh.uv_layers[0].data.foreach_set("uv", uv[mask].ravel())
    ob = link(name, mesh); n0 = len(mesh.polygons)
    mod = ob.modifiers.new("dec", "DECIMATE"); mod.ratio = min(1.0, TARGET[name] / n0); mod.use_collapse_triangulate = True
    dg = bpy.context.evaluated_depsgraph_get(); new = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ob.modifiers.clear(); ob.data = new; bpy.data.meshes.remove(mesh)
    new.transform(M); new.polygons.foreach_set("use_smooth", np.ones(len(new.polygons), bool)); new.update()
    print("PART", name, n0, "->", len(new.polygons), "tris")
    return ob
bpy.data.objects.remove(src)
env, bask = make_part("Envelope", keep_env), make_part("Basket", keep_bask)

class B:
    def __init__(self): self.v, self.f = [], []
    def grid(self, rows, wrap):
        ids = [[len(self.v) + i * len(rows[0]) + j for j in range(len(rows[0]))] for i in range(len(rows))]
        for row in rows: self.v += [tuple(p) for p in row]
        m = len(rows[0]); cols = m if wrap else m - 1
        for i in range(len(rows) - 1):
            for j in range(cols): self.f.append((ids[i][j], ids[i][(j + 1) % m], ids[i + 1][(j + 1) % m], ids[i + 1][j]))
    def mesh(self, name):
        mesh = bpy.data.meshes.new(name); mesh.from_pydata(self.v, [], self.f); mesh.transform(M); return link(name, mesh)
def frame_vectors(t):
    t = np.array(t, float); t /= np.linalg.norm(t)
    a = np.array((0, 0, 1.0)) if abs(t[2]) < 0.9 else np.array((1.0, 0, 0))
    n = np.cross(t, a); n /= np.linalg.norm(n); return n, np.cross(t, n)
def tube(b, path, radius, sides, closed=False):
    path = [np.array(p, float) for p in path]; rings = []
    for i, p in enumerate(path):
        t = (path[(i + 1) % len(path)] - path[i - 1]) if closed else (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)])
        n, bb = frame_vectors(t)
        rings.append([p + radius * (math.cos(2 * math.pi * k / sides) * n + math.sin(2 * math.pi * k / sides) * bb) for k in range(sides)])
    if closed: rings.append(rings[0])
    b.grid(rings, True)
def lathe(b, profile, sides, centre):
    cx, cy, cz = centre
    b.grid([[(cx + rr * math.cos(2 * math.pi * k / sides), cy + rr * math.sin(2 * math.pi * k / sides), cz + zz) for k in range(sides)] for (rr, zz) in profile], True)

ZF = Z_POSTS + 0.004                                     # the frame's height
Rg = B()
tube(Rg, [((R_M + 0.004) * math.cos(2 * math.pi * k / 48), (R_M + 0.004) * math.sin(2 * math.pi * k / 48), Z_MOUTH + 0.012) for k in range(48)], 0.009, 6, closed=True)
path = []
for i in range(4):
    p, q = np.array(posts[i]), np.array(posts[(i + 1) % 4])
    path += [(*(p + (q - p) * t), ZF) for t in np.linspace(0, 1, 8)[:-1]]
tube(Rg, path, 0.009, 6, closed=True)                    # the square frame through the post tops
for (px, py) in posts:
    lathe(Rg, [(0, 0), (0.017, 0), (0.017, 0.02), (0.012, 0.022), (0, 0.022)], 10, (px, py, Z_POSTS - 0.014))   # leather collar on each post top
    thp = math.atan2(py, px)
    for off in (-33.75, -11.25, 11.25, 33.75):           # four cables per corner, from the mouth ring
        a = thp + math.radians(off)
        tube(Rg, [((R_M + 0.002) * math.cos(a), (R_M + 0.002) * math.sin(a), Z_MOUTH + 0.012), (px, py, ZF + 0.004)], 0.0035, 4)
rig = Rg.mesh("Rigging")
Bu = B()
for i in range(2): tube(Bu, [(*posts[i], ZF), (*posts[i + 2], ZF)], 0.005, 6)   # cross bars under the burner
for sx in (-0.02, 0.02): lathe(Bu, [(0, 0), (0.015, 0), (0.015, 0.045), (0.011, 0.048), (0, 0.048)], 12, (sx, 0, ZF))
burner = Bu.mesh("Burner")
Fl = B()
lathe(Fl, [(0.025 * (1 - t) ** 0.7 * (0.75 + 0.25 * math.sin(math.pi * t)), 0.2 * t) for t in np.linspace(0, 1, 10)], 12, (0, 0, ZF + 0.046))
flame = Fl.mesh("Flame")
print("RIG tris", len(rig.data.polygons), "burner", len(burner.data.polygons), "flame", len(flame.data.polygons))

# ---------- materials ----------
def img(name, noncolor=False):
    i = bpy.data.images.load(os.path.join(TEX, name)); i.pack()
    if noncolor: i.colorspace_settings.name = "Non-Color"
    return i
mat = bpy.data.materials.new("Balloon"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = img("balloon_color.png"); nt.links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
tr = nt.nodes.new("ShaderNodeTexImage"); tr.image = img("balloon_roughness.png", True); nt.links.new(tr.outputs["Color"], bsdf.inputs["Roughness"])
tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = img("balloon_normal.png", True)
nm = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(tn.outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
def plain(name, colour, rough, metal=0.0, emit=0.0):
    mt = bpy.data.materials.new(name); mt.use_nodes = True; b = mt.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*colour, 1); b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
    if emit: b.inputs["Emission Color"].default_value = (*colour, 1); b.inputs["Emission Strength"].default_value = emit
    return mt
for ob in (env, bask): ob.data.materials.append(mat)
rig.data.materials.append(plain("Rope", (0.74, 0.62, 0.42), 0.85))
burner.data.materials.append(plain("Metal", (0.62, 0.63, 0.66), 0.35, 0.8))
flame.data.materials.append(plain("Flame", (1.0, 0.55, 0.12), 0.5, 0.0, 6.0))

# ---------- export ----------
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "balloon_meshy.fbx"), path_mode="COPY", embed_textures=True,
                         apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "balloon_meshy.glb"), export_format="GLB")

if RENDER:
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48
    sc.render.resolution_x, sc.render.resolution_y = 640, 800; sc.view_settings.view_transform = "Standard"
    w = bpy.data.worlds.new("Sky"); sc.world = w; w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.75, 0.95, 1)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 4
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
    bpy.ops.mesh.primitive_plane_add(size=400); g = bpy.context.object; g.data.materials.append(plain("Grass", (0.22, 0.45, 0.16), 0.9))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    def shot(loc, look, lens, name):
        cam.location = loc; d = np.array(look) - np.array(loc)
        cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2); cam.data.lens = lens
        sc.render.filepath = os.path.join(OUT, name); bpy.ops.render.render(write_still=True)
    shot((60, -72, 16), (0, 0, 28), 42, "preview_full.png")
    shot((11, -13, 9), (0, 0, 7), 30, "preview_basket.png")
print("DONE")
