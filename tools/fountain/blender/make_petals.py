# Blender (bpy 5.2) script: three single flower petals for the piazza fountain's "flower petals" mode (1001 Squirrels,
# Oct 10 2026), the loose petals that drift on the water and the rims; Roblox tints them, so each is one object with
# one flat pale pink material. Thin closed shells (top, bottom and a rim) so they render from both sides, smooth
# shaded, well under 400 triangles each. 1 Blender unit = 1 stud. Each petal lies flat, resting on z=0, centred on its
# bounding box, with its long axis along Blender Y (tip at +Y), which the Y-up / -Z-forward export turns into the
# object's Z axis in Roblox. Same export settings as make_flowers.py (axis conversion baked into the mesh data).
# Objects:
#   Petal_A   a rose petal: a cupped teardrop with a slight curl at the tip (about 0.55 long x 0.4 wide x 0.12 high)
#   Petal_B   a rounder peony petal with a wavy, ruffled edge (about 0.5 x 0.45)
#   Petal_C   a slimmer pointed petal (about 0.6 x 0.3)
# Run: python make_petals.py <out_dir> [--render] [--samples N]   (writes petals.fbx, petals_preview.png)
import bpy, math, sys, os
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "."
RENDER = "--render" in sys.argv
SAMPLES = int(sys.argv[sys.argv.index("--samples") + 1]) if "--samples" in sys.argv else 64
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name, colour):
    m = bpy.data.materials.new(name)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = 0.65
    m.diffuse_color = (*colour, 1)
    return m
PETAL = material("Petal_Pink", (0.97, 0.72, 0.82))

class Builder:
    """Vertices merged by position, so collapsed grid rows (a pointed tip) become fans, not zero-area quads."""
    def __init__(self): self.v, self.f, self.key = [], [], {}
    def vert(self, p):
        k = tuple(round(float(c), 5) for c in p)
        i = self.key.get(k)
        if i is None:
            i = len(self.v); self.v.append(tuple(float(c) for c in p)); self.key[k] = i
        return i
    def face(self, idx):
        out = []
        for i in idx:
            if not out or out[-1] != i: out.append(i)
        if len(out) > 1 and out[0] == out[-1]: out.pop()
        if len(out) >= 3 and len(set(out)) == len(out): self.f.append(tuple(out))
    def grid(self, pts, flip=False):
        ids = [[self.vert(p) for p in r] for r in pts]
        for i in range(len(ids) - 1):
            for j in range(len(ids[0]) - 1):
                q = [ids[i][j], ids[i][j + 1], ids[i + 1][j + 1], ids[i + 1][j]]
                if flip: q.reverse()
                self.face(q)
    def settle(self):
        """centre the mesh on its X/Y bounding box and rest it on z=0"""
        co = np.array(self.v); lo, hi = co.min(axis=0), co.max(axis=0)
        off = np.array(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))
        self.v = [tuple(p - off) for p in co]
    def object(self, name, mat, location=(0, 0, 0)):
        me = bpy.data.meshes.new(name)
        me.from_pydata(self.v, [], self.f)
        for p in me.polygons: p.use_smooth = True
        me.validate(); me.update()
        xs = [v[0] for v in self.v]; ys = [v[1] for v in self.v]
        x0, y0 = min(xs), min(ys); span = max(max(xs) - x0, max(ys) - y0, 1e-6)
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
                vx, vy, _ = me.vertices[me.loops[li].vertex_index].co
                uvl.data[li].uv = ((vx - x0) / span, (vy - y0) / span)
        me.materials.append(mat)
        ob = bpy.data.objects.new(name, me); ob.location = location
        bpy.context.scene.collection.objects.link(ob)
        return ob

def sheet(B, pts, thick):
    """A thin solid from an n x m grid of points: top faces (normal = rows x columns), bottom faces and a rim."""
    P = np.array(pts, float); n, m = P.shape[:2]
    N = np.zeros_like(P)
    for i in range(n):
        for j in range(m):
            du = P[i][min(j + 1, m - 1)] - P[i][max(j - 1, 0)]
            dv = P[min(i + 1, n - 1)][j] - P[max(i - 1, 0)][j]
            N[i][j] = np.cross(dv, du)
    for i in range(n):
        if np.linalg.norm(N[i], axis=1).max() < 1e-9:
            for i2 in (i - 1, i + 1):
                if 0 <= i2 < n and np.linalg.norm(N[i2], axis=1).max() > 1e-9:
                    N[i][:] = N[i2].mean(axis=0); break
    N = N / np.maximum(np.linalg.norm(N, axis=2, keepdims=True), 1e-9)
    top = P + N * thick / 2; bot = P - N * thick / 2
    B.grid(top.tolist(), flip=True)
    B.grid(bot.tolist(), flip=False)
    loop = [(0, j) for j in range(m)] + [(i, m - 1) for i in range(1, n)] + [(n - 1, j) for j in range(m - 2, -1, -1)] + [(i, 0) for i in range(n - 2, 0, -1)]
    for k in range(len(loop)):
        (i1, j1), (i2, j2) = loop[k], loop[(k + 1) % len(loop)]
        B.face([B.vert(top[i1][j1]), B.vert(top[i2][j2]), B.vert(bot[i2][j2]), B.vert(bot[i1][j1])])

def width(keys):
    ts, ws = zip(*keys)
    return lambda t: float(np.interp(t, ts, ws))

def petal_grid(L, W, rows, cols, wfn, curl=0.0, cup=0.0, keel=0.0, wave_z=0.0, wave_w=0.0, waves=3, arch=0.0):
    """A petal lying along +Y from y=0 (base) to y=L (tip): width W * wfn(t); the tip lifting by curl, the edges by cup,
    a keel folding the middle down, an arch bowing the middle of the length up, and a ruffle (wave_z up and down along
    the edges, wave_w in and out of the outline) with `waves` half-waves along the length."""
    out = []
    for i in range(rows):
        t = i / (rows - 1)
        hw = 0.5 * W * wfn(t) * (1 + wave_w * math.sin(waves * math.pi * t))
        row = []
        for j in range(cols):
            s = -1 + 2 * j / (cols - 1)
            z = L * curl * t * t + cup * hw * s * s - keel * hw * (1 - abs(s)) + arch * L * math.sin(math.pi * t) + wave_z * math.sin(waves * math.pi * t) * s * s
            row.append((-hw * s, L * t, z))
        out.append(row)
    return out

THICK = 0.02
objects = []
def make(name, grid, x):
    B = Builder(); sheet(B, grid, THICK); B.settle()
    ob = B.object(name, PETAL, location=(x, 0, 0)); objects.append(ob); return ob

# Petal_A: a rose petal, a cupped teardrop (narrow base, broad rounded tip) with a slight curl at the tip
wA = width([(0, 0.18), (0.2, 0.55), (0.45, 0.9), (0.65, 1.0), (0.85, 0.82), (1, 0.4)])
make("Petal_A", petal_grid(0.55, 0.40, 7, 5, wA, curl=0.12, cup=0.33, arch=0.02), 0.0)
# Petal_B: a rounder peony petal with a wavy, ruffled edge
wB = width([(0, 0.32), (0.22, 0.78), (0.5, 1.0), (0.75, 0.96), (0.9, 0.78), (1, 0.5)])
make("Petal_B", petal_grid(0.5, 0.45, 9, 5, wB, curl=0.08, cup=0.3, wave_z=0.03, wave_w=0.05, waves=4, arch=0.03), 1.0)
# Petal_C: a slimmer pointed petal, a shallow keel and a slight lift at the tip
wC = width([(0, 0.3), (0.25, 0.85), (0.45, 1.0), (0.7, 0.75), (0.88, 0.38), (1, 0.0)])
make("Petal_C", petal_grid(0.6, 0.30, 7, 5, wC, curl=0.12, cup=0.3, keel=0.1, arch=0.02), 2.0)

def tri_count(ob): return sum(len(p.vertices) - 2 for p in ob.data.polygons)
print("PIECES")
for ob in objects:
    co = np.array([v.co[:] for v in ob.data.vertices]); lo, hi = co.min(axis=0), co.max(axis=0)
    print("  %-8s tris %3d  verts %3d  wide x %.2f  long y %.2f  high z %.2f  (z from %.3f)  mat %s  at x=%.1f" % (
        ob.name, tri_count(ob), len(ob.data.vertices), hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], lo[2], ob.data.materials[0].name, ob.location.x))

FBX = os.path.join(OUT, "petals.fbx")
bpy.ops.export_scene.fbx(filepath=FBX, use_selection=False, object_types={"MESH"}, apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL",
                         axis_forward="-Z", axis_up="Y", bake_space_transform=True, mesh_smooth_type="FACE", use_mesh_modifiers=True,
                         use_triangles=False, add_leaf_bones=False, path_mode="AUTO", embed_textures=False)
print("WROTE", FBX)

if RENDER:
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = SAMPLES
    try: sc.cycles.use_denoising = True
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = 1500, 600
    sc.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Sky"); sc.world = world
    bg = world.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.75, 0.85, 0.98, 1); bg.inputs[1].default_value = 0.45
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sc.collection.objects.link(sun)
    sun.data.energy = 2.4; sun.data.angle = math.radians(8); sun.rotation_euler = (math.radians(42), math.radians(-18), math.radians(-25))
    bpy.ops.mesh.primitive_plane_add(size=40, location=(1, 0, 0)); ground = bpy.context.object
    ground.data.materials.append(material("Stone", (0.60, 0.58, 0.54)))
    for ob in objects:                                   # turned 35 degrees so a straight-on raised camera sees them 3/4
        ob.rotation_euler.z = math.radians(-35)
        cu = bpy.data.curves.new("tag", type="FONT"); cu.body = ob.name; cu.size = 0.09; cu.align_x = "CENTER"
        tx = bpy.data.objects.new("tag", cu); sc.collection.objects.link(tx)
        tx.location = (ob.location.x, -0.42, 0.002)
        cu.materials.append(material("Ink", (0.15, 0.13, 0.12)))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.1
    look = np.array((1.0, 0.05, 0.05)); loc = look + np.array((0.0, -5.0, 3.6)); d = look - loc
    cam.location = loc
    cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)
    sc.render.filepath = os.path.join(OUT, "petals_preview.png"); bpy.ops.render.render(write_still=True)
    print("WROTE", sc.render.filepath)
print("DONE", OUT)
