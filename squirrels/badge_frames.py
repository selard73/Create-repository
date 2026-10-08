"""French squirrels ONLY (the forest squirrels are approved and are not touched or loaded).
Replicates the in-game album badge camera (faceCamera in the SquirrelAnim client script) in rest pose, measures where the
head (vertices weighted >= 0.5 to the Head bone: head, ears, hat) lands in the round badge, and solves per-squirrel
dist / up / side so the badge matches the approved look from the notes: head centred left-right, ear tips / hat just
clearing the top of the circle, head filling the circle. Renders <id>_now.png and <id>_fixed.png (300 px squares).
Run: blender --background --python badge_frames.py -- <out_dir>"""
import bpy, sys, os, math, json, traceback
from mathutils import Vector

ROOT = r"C:\Users\slard\roblox-props\squirrels"
argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
os.makedirs(OUT, exist_ok=True)
LOG = os.path.join(OUT, "badge_log.txt")


def log(m):
    with open(LOG, "a") as f:
        f.write(str(m) + "\n")


FRENCH = ["mailman_squirrel", "philosopher_squirrel", "waiter_squirrel", "mime_squirrel", "cyclist_squirrel", "glam_squirrel",
          "bird_feeder_squirrel", "firefighter_squirrel", "tourist_squirrel", "painter_squirrel", "florist_squirrel", "spy_squirrel"]
TAN = math.tan(math.radians(12))   # FieldOfView 24 (vertical), square badge; the mask shows the inscribed circle
UPV = Vector((0, 0, 1))
TOP, BOTTOM, EDGE = 0.90, -0.55, 0.93   # head top just inside the circle, chin low in the circle, sides inside the ring


class Sq:
    def __init__(self, sid):
        bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, sid, f"{sid}_rigged.blend"))
        self.sid = sid
        self.obj = bpy.data.objects["Squirrel"]
        arm = bpy.data.objects["SquirrelRig"]
        mw = self.obj.matrix_world
        pts = [mw @ v.co for v in self.obj.data.vertices]
        xs = [p.x for p in pts]; ys = [p.y for p in pts]; zs = [p.z for p in pts]
        self.H = max(zs) - min(zs)
        self.bottom = Vector(((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, min(zs)))
        gi = self.obj.vertex_groups["Head"].index
        self.head = []
        for v in self.obj.data.vertices:
            for g in v.groups:
                if g.group == gi and g.weight >= 0.5:
                    self.head.append(mw @ v.co)
                    break
        self.bones = {b.name: arm.matrix_world @ b.head_local for b in arm.data.bones}
        f = self.bones["Head"] - self.bones["Root"]
        f.z = 0
        self.fwd = f.normalized() if f.length > 0.05 else Vector((0, -1, 0))
        self.left = UPV.cross(self.fwd)

    def camera(self, tw):
        H = self.H
        dist = tw.get("dist", 1.35); up = tw.get("up", 0.0); camUp = tw.get("camUp", 0.05); side = tw.get("side", 0.0)
        centre = self.bottom + UPV * ((0.70 + up) * H) + self.fwd * (0.30 * H)
        d = self.bones["Head"] - centre
        centre = centre + self.left * d.dot(self.left)
        centre = centre + self.left * (side * H)
        cam = centre + self.fwd * (dist * H) + UPV * (camUp * H)
        return cam, centre

    def metrics(self, tw):
        cam, centre = self.camera(tw)
        view = (centre - cam).normalized()
        right = view.cross(UPV).normalized()
        upc = right.cross(view).normalized()
        sx = []; sy = []
        for p in self.head:
            d = p - cam
            depth = max(d.dot(view), 1e-4)
            sx.append(d.dot(right) / (depth * TAN)); sy.append(d.dot(upc) / (depth * TAN))
        return {"left": min(sx), "right": max(sx), "bottom": min(sy), "top": max(sy),
                "hx": (max(sx) + min(sx)) / 2, "wide": max(abs(min(sx)), abs(max(sx)))}

    def render(self, tw, path):
        cam_pos, centre = self.camera(tw)
        tex = [n for n in self.obj.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0]
        tex.image = bpy.data.images.load(os.path.join(ROOT, self.sid, f"{self.sid}_1k.png"), check_existing=True)
        sc = bpy.context.scene
        sc.render.engine = "BLENDER_WORKBENCH"
        sh = sc.display.shading
        sh.light = "STUDIO"; sh.color_type = "TEXTURE"; sh.show_shadows = False
        sh.background_type = "VIEWPORT"; sh.background_color = (38 / 255, 30 / 255, 52 / 255)
        sc.render.resolution_x = sc.render.resolution_y = 300
        sc.render.image_settings.file_format = "PNG"
        sc.view_settings.view_transform = "Standard"
        camo = sc.camera
        if camo is None or camo.type != "CAMERA":
            cd = bpy.data.cameras.new("BadgeCam")
            camo = bpy.data.objects.new("BadgeCam", cd)
            sc.collection.objects.link(camo)
            sc.camera = camo
        camo.data.sensor_fit = "VERTICAL"
        camo.data.angle = math.radians(24)
        camo.data.clip_start = 0.01
        camo.location = cam_pos
        camo.rotation_euler = (centre - cam_pos).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)


def solve(sq):
    import numpy as np
    top, bottom = TOP, BOTTOM
    p = [1.35, 0.0, 0.0]
    tw = lambda q: {"dist": q[0], "up": q[1], "side": q[2], "camUp": 0.05}
    for attempt in range(4):
        def F(q):
            m = sq.metrics(tw(q))
            return [m["top"] - top, m["bottom"] - bottom, m["hx"]]
        for _ in range(20):
            f = F(p)
            if max(abs(x) for x in f) < 0.004:
                break
            J = np.zeros((3, 3)); h = 1e-3
            for j in range(3):
                q = list(p); q[j] += h
                fq = F(q)
                for i in range(3):
                    J[i, j] = (fq[i] - f[i]) / h
            dp = np.linalg.lstsq(J, -np.array(f), rcond=None)[0]
            p = [p[k] + 0.8 * float(dp[k]) for k in range(3)]
            p[0] = min(4.0, max(0.7, p[0]))
        m = sq.metrics(tw(p))
        if m["wide"] <= EDGE:
            break
        # a wide hat or ears would touch the ring: shrink the head around its centre until the sides fit
        k = EDGE / m["wide"]
        mid = (top + bottom) / 2
        top, bottom = mid + (top - mid) * k, mid + (bottom - mid) * k
    return {"dist": round(p[0], 3), "up": round(p[1], 3), "side": round(p[2], 3), "camUp": 0.05}


try:
    open(LOG, "w").close()
    result = {}
    for sid in FRENCH:
        sq = Sq(sid)
        m0 = sq.metrics({})
        tw = solve(sq)
        m1 = sq.metrics(tw)
        result[sid] = {"now": m0, "face": tw, "fixed": m1, "H": sq.H, "head_verts": len(sq.head)}
        sq.render({}, os.path.join(OUT, f"{sid}_now.png"))
        sq.render(tw, os.path.join(OUT, f"{sid}_fixed.png"))
        r3 = lambda d: {k: round(v, 3) for k, v in d.items()}
        log(f"{sid} head_verts={len(sq.head)} now={json.dumps(r3(m0))} face={json.dumps(tw)} fixed={json.dumps(r3(m1))}")
    json.dump(result, open(os.path.join(OUT, "badge_frames.json"), "w"), indent=1)
    log("BADGE_DONE")
except Exception:
    log(traceback.format_exc())
