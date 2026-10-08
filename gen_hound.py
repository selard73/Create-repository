"""
Cartoon old hound dog, standing: lean tricolor hound. Roblox Import 3D mesh.

Built as SMOOTH BLENDED SURFACES (signed distance fields + marching cubes) instead of stacked balls:
  HoundBody  = chest, belly, rump, shoulders, thighs, all four legs and paws, one seamless surface
  HoundHead  = neck, skull, brow, muzzle, jowls, both ears, one seamless surface (neck root hides in the chest)
  HoundTail  = one tapered curve rooted inside the rump
Eyes, nose, tongue, collar and tag are small separate parts. Coat is painted as a side view.

Outputs: hound.obj / hound.mtl / hound_texture.png / hound_setup.lua / preview_hound.html
Run:  python gen_hound.py     (needs numpy + scikit-image)
Faces +X. About 5 studs tall.
"""
import math
import random
from pathlib import Path

import numpy as np
from skimage import measure
from PIL import Image, ImageDraw, ImageFilter

from gen_mesh import add, sub, mul, dot, cross, length, norm, lathe, blob, grain, paint_gradient
from gen_sign import Obj, tube
from gen_dish import rot_x, rot_y, write_preview as _wp
from gen_ufo import rot_z

OUT = Path(__file__).parent
TEX = 1024
R = math.radians

# whole-dog bounding box used for the side-view texture projection
BX0, BX1, BY0, BY1 = -3.6, 4.9, -0.1, 5.4
UV = {
    "side":   (0.00, 1.00, 0.20, 1.00),   # painted side view of the dog (x -> u, y -> v)
    "black":  (0.00, 0.10, 0.00, 0.10),
    "shine":  (0.10, 0.20, 0.00, 0.10),
    "red":    (0.20, 0.30, 0.00, 0.10),
    "gold":   (0.30, 0.40, 0.00, 0.10),
    "pink":   (0.40, 0.50, 0.00, 0.10),
    "amber":  (0.50, 0.60, 0.00, 0.10),
    "grey":   (0.60, 0.70, 0.00, 0.10),
}

# ------------------------------------------------------------- SDF ------
def sd_ellipsoid(P, c, r):
    q = (P - np.array(c)) / np.array(r)
    k0 = np.linalg.norm(q, axis=-1)
    k1 = np.linalg.norm(q / np.array(r), axis=-1)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)

def sd_roundcone(P, a, b, r1, r2):
    """Capsule with different end radii (a tapered limb)."""
    a, b = np.array(a), np.array(b)
    ba = b - a
    l2 = ba @ ba
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = P - a
    y = pa @ ba
    z = y - l2
    x2 = np.sum((pa * l2 - ba * y[..., None]) ** 2, axis=-1)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    d = np.sqrt(x2 + y2) * il2 - r1
    d = np.where(np.sign(z) * a2 * z2 > k, np.sqrt(x2 + z2) * il2 - r2, d)
    d = np.where(np.sign(y) * a2 * y2 < k, np.sqrt(x2 + y2) * il2 - r1, d)
    mid = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - r1
    both = (np.sign(z) * a2 * z2 <= k) & (np.sign(y) * a2 * y2 >= k)
    return np.where(both, mid, d)

def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)

def smax(a, b, k):
    return -smin(-a, -b, k)

def mesh_from_sdf(fn, lo, hi, step, name, o, uv_fn):
    xs = np.arange(lo[0], hi[0] + step, step)
    ys = np.arange(lo[1], hi[1] + step, step)
    zs = np.arange(lo[2], hi[2] + step, step)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    P = np.stack([X, Y, Z], axis=-1)
    F = fn(P)
    verts, faces, normals, _ = measure.marching_cubes(F, level=0.0, spacing=(step, step, step))
    verts = verts + np.array(lo)
    vlist = [tuple(map(float, v)) for v in verts]
    uvs = [uv_fn(v) for v in vlist]
    flist = [(int(a), int(b), int(c)) for a, b, c in faces]
    # marching cubes winding points inward for our sign convention; add_smooth fixes orientation by centre
    cx = (lo[0] + hi[0]) / 2; cy = (lo[1] + hi[1]) / 2
    o.add_smooth(name, vlist, uvs, flist, lambda p: (p[0], p[1], 0.0))
    return len(flist)

def side_uv(v):
    u0, u1, v0, v1 = UV["side"]
    return (u0 + (u1 - u0) * (v[0] - BX0) / (BX1 - BX0), v0 + (v1 - v0) * (v[1] - BY0) / (BY1 - BY0))

# ------------------------------------------------------------ the dog ----
def body_sdf(P):
    K = 0.35
    d = sd_ellipsoid(P, (0.0, 2.75, 0.0), (2.05, 1.0, 0.82))                  # barrel
    d = smin(d, sd_ellipsoid(P, (1.35, 2.6, 0.0), (1.0, 1.2, 0.9)), K)          # deep chest
    d = smin(d, sd_ellipsoid(P, (-1.55, 2.7, 0.0), (0.95, 0.95, 0.78)), K)      # rump
    d = smin(d, sd_ellipsoid(P, (1.3, 3.2, 0.0), (0.8, 0.6, 0.7)), K)           # shoulder mound (neck root sits in here)
    for s in (-1, 1):
        d = smin(d, sd_ellipsoid(P, (-1.45, 2.0, s * 0.62), (0.7, 0.85, 0.36)), 0.3)          # thigh
        d = smin(d, sd_roundcone(P, (1.3, 2.4, s * 0.5), (1.35, 0.45, s * 0.55), 0.34, 0.24), 0.25)   # front leg
        d = smin(d, sd_roundcone(P, (-1.4, 2.2, s * 0.55), (-1.75, 1.25, s * 0.58), 0.36, 0.26), 0.25)  # hind upper
        d = smin(d, sd_roundcone(P, (-1.75, 1.25, s * 0.58), (-1.55, 0.45, s * 0.58), 0.26, 0.23), 0.2)  # hind lower
        d = smin(d, sd_ellipsoid(P, (1.6, 0.32, s * 0.56), (0.55, 0.32, 0.4)), 0.18)          # front paw
        d = smin(d, sd_ellipsoid(P, (-1.3, 0.3, s * 0.58), (0.55, 0.3, 0.4)), 0.18)           # hind paw
    d = smax(d, -(P[..., 1] - 0.02), 0.05)                                                     # flat feet on the ground
    return d

def head_sdf(P):
    K = 0.3
    d = sd_roundcone(P, (1.35, 3.0, 0.0), (2.55, 3.95, 0.0), 0.58, 0.52)      # neck
    d = smin(d, sd_ellipsoid(P, (2.95, 4.3, 0.0), (0.88, 0.8, 0.76)), K)       # skull
    d = smin(d, sd_ellipsoid(P, (3.4, 4.62, 0.0), (0.55, 0.28, 0.68)), 0.25)   # brow ridge
    d = smin(d, sd_roundcone(P, (3.3, 4.12, 0.0), (4.4, 4.02, 0.0), 0.56, 0.4), K)   # muzzle
    for s in (-1, 1):
        d = smin(d, sd_ellipsoid(P, (3.85, 3.7, s * 0.3), (0.5, 0.48, 0.3)), 0.28)   # jowls (soft, blended)
        d = smin(d, sd_ellipsoid(P, (2.7, 3.95, s * 0.86), (0.4, 0.98, 0.14)), 0.18)  # ear flap, hanging from the skull top
        d = smin(d, sd_ellipsoid(P, (2.75, 4.75, s * 0.62), (0.34, 0.26, 0.26)), 0.22)  # ear root high on the head
        d = smax(d, -sd_ellipsoid(P, (3.6, 4.58, s * 0.42), (0.26, 0.24, 0.26)), 0.08)  # eye socket
    d = smin(d, sd_ellipsoid(P, (2.35, 3.1, 0.0), (0.45, 0.5, 0.42)), 0.3)     # dewlap
    return d

def tail_sdf(P):
    pts = [(-2.2, 2.75, 0.0), (-2.85, 3.3, 0.05), (-3.15, 4.0, 0.1), (-3.0, 4.7, 0.15), (-2.55, 5.05, 0.2)]
    rads = [0.22, 0.19, 0.16, 0.13, 0.1]
    d = None
    for i in range(len(pts) - 1):
        seg = sd_roundcone(P, pts[i], pts[i + 1], rads[i], rads[i + 1])
        d = seg if d is None else smin(d, seg, 0.12)
    return d

def ell(o, name, c, s, uv, segs=14, lats=8, rot=None):
    v, uvv, f = blob((0.0, 0.0, 0.0), s, segs, lats, uv)
    if rot:
        px, yw, rl = rot
        v = [rot_y(rot_x(rot_z(p, rl), px), yw) for p in v]
    v = [add(p, c) for p in v]
    o.add_smooth(name, v, uvv, f, lambda p, c=c: c)

def build(step=0.1):
    o = Obj()
    n1 = mesh_from_sdf(body_sdf, (-2.9, -0.1, -1.2), (2.7, 4.1, 1.2), step * 1.22, "HoundBody", o, side_uv)
    n2 = mesh_from_sdf(head_sdf, (1.0, 2.3, -1.2), (5.0, 5.2, 1.2), step, "HoundHead", o, side_uv)
    n3 = mesh_from_sdf(tail_sdf, (-3.6, 2.3, -0.3), (-1.9, 5.4, 0.5), step, "HoundTail", o, side_uv)
    print(f"  body {n1} tris, head {n2} tris, tail {n3} tris")
    # eyes in their sockets, nose, tongue, collar
    for s in (-1, 1):
        ec = (3.62, 4.58, s * 0.4)
        ell(o, f"EyeWhite{s}", ec, (0.2, 0.21, 0.21), UV["shine"], 14, 8)
        ell(o, f"Iris{s}", add(ec, (0.13, -0.04, s * 0.02)), (0.1, 0.12, 0.12), UV["amber"], 10, 6)
        ell(o, f"Pupil{s}", add(ec, (0.19, -0.05, s * 0.02)), (0.05, 0.08, 0.08), UV["black"], 8, 4)
        ell(o, f"EyeShine{s}", add(ec, (0.2, 0.05, s * 0.06)), (0.035, 0.035, 0.035), UV["shine"], 6, 3)
    ell(o, "Nose", (4.55, 4.1, 0.0), (0.3, 0.26, 0.32), UV["black"], 14, 8)
    ell(o, "NoseShine", (4.73, 4.26, -0.1), (0.055, 0.05, 0.055), UV["shine"], 8, 4)
    ell(o, "Tongue", (4.1, 3.42, 0.14), (0.3, 0.07, 0.18), UV["pink"], 12, 6, rot=(R(12), 0.0, 0.0))
    ring = []
    for i in range(32):
        a = 2 * math.pi * i / 32
        p = rot_z((0.0, 0.7 * math.cos(a), 0.74 * math.sin(a)), R(-40))
        ring.append((2.05 + p[0], 3.55 + p[1], p[2]))
    v, uv, f = tube(ring, 0.09, 8, UV["red"], closed=True)
    o.add_smooth("Collar", v, uv, f, lambda p: (2.05, 3.55, 0.0))
    ell(o, "CollarRing", (2.6, 2.95, 0.0), (0.07, 0.07, 0.04), UV["grey"], 8, 4)
    ell(o, "CollarTag", (2.68, 2.77, 0.0), (0.15, 0.17, 0.05), UV["gold"], 10, 5)
    ell(o, "NeckPivot", (1.9, 3.45, 0.0), (0.05, 0.05, 0.05), UV["grey"], 6, 3)
    ell(o, "TailPivot", (-2.2, 2.75, 0.0), (0.05, 0.05, 0.05), UV["grey"], 6, 3)
    return o

# ------------------------------------------------------------- texture ----
TAN, BLACK, WHITE, GREY = (188, 116, 54), (44, 38, 36), (242, 236, 226), (176, 168, 160)

def fur(w, h, base, seed, strokes=1.0):
    rnd = random.Random(seed)
    img = paint_gradient(w, h, tuple(min(255, c + 8) for c in base), tuple(max(0, c - 10) for c in base)).convert("RGBA")
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    for _ in range(int(w * h / 520 * strokes)):
        x, y = rnd.randint(0, w), rnd.randint(0, h)
        L = rnd.randint(int(h * 0.015), int(h * 0.05))
        col = (255, 245, 225, rnd.randint(12, 26)) if rnd.random() < 0.5 else (40, 20, 10, rnd.randint(10, 22))
        d.line([(x, y), (x + rnd.randint(-2, 2), y + L)], fill=col, width=rnd.randint(1, 2))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.7)))
    return img

def patch(img, box_, color, alpha=255, blur=2.5):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    d.ellipse(box_, fill=color + (alpha,))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))

def shape(img, pts, color, alpha=255, blur=2.5, wobble=0.0, seed=0):
    """Crisp-edged coat patch from a polygon (world coords already converted to pixels), with a
    slightly wavy outline so it reads as fur, not a sticker."""
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    smooth = []
    n = len(pts)
    for i in range(n):
        p0, p1 = pts[i], pts[(i + 1) % n]
        for k in range(8):
            t = k / 8
            x = p0[0] + (p1[0] - p0[0]) * t; y = p0[1] + (p1[1] - p0[1]) * t
            smooth.append((x + rnd.uniform(-wobble, wobble), y + rnd.uniform(-wobble, wobble)))
    d.polygon(smooth, fill=color + (alpha,))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))

def rb(r):
    u0, u1, v0, v1 = r
    return int(u0 * TEX), int((1 - v1) * TEX), int(u1 * TEX), int((1 - v0) * TEX)

def paint():
    atlas = Image.new("RGB", (TEX, TEX), (30, 30, 30))
    x0, y0, x1, y1 = rb(UV["side"]); w, h = x1 - x0, y1 - y0
    def px(x, y):   # world (x, y) -> pixel in the side-view region
        return (int((x - BX0) / (BX1 - BX0) * w), int((1 - (y - BY0) / (BY1 - BY0)) * h))
    def box_(xa, ya, xb, yb):
        (ax, ay), (bx, by) = px(xa, yb), px(xb, ya)
        return (ax, ay, bx, by)
    side = fur(w, h, WHITE, 1, 0.5)
    W = 6
    # tan head and ears, with a white muzzle and a blaze; the tan runs down the back of the neck
    shape(side, [px(1.7, 3.0), px(1.9, 3.8), px(2.2, 4.6), px(2.6, 5.15), px(3.4, 5.15), px(3.9, 4.75), px(3.6, 4.3), px(3.2, 3.55), px(2.8, 2.7), px(2.4, 2.75)], TAN, 255, 2.5, W, 1)
    shape(side, [px(3.55, 4.45), px(4.0, 4.55), px(4.9, 4.35), px(4.95, 3.7), px(4.3, 3.3), px(3.6, 3.35), px(3.35, 3.8)], WHITE, 255, 2, W, 2)   # white muzzle + jowls
    shape(side, [px(3.35, 4.35), px(3.55, 5.1), px(3.8, 5.12), px(3.75, 4.4)], WHITE, 255, 2, 3, 3)                                            # blaze up the forehead
    shape(side, [px(4.25, 3.6), px(4.95, 3.65), px(4.95, 4.4), px(4.4, 4.45)], GREY, 120, 4, 3, 4)                                            # grey around the old muzzle
    # white throat and chest down to the front legs
    shape(side, [px(1.2, 3.3), px(2.5, 2.8), px(2.6, 2.2), px(1.9, 1.6), px(0.9, 1.7), px(0.7, 2.6)], WHITE, 255, 2.5, W, 5)
    # tan patches: shoulder/flank and hip
    shape(side, [px(-0.4, 3.55), px(0.9, 3.65), px(1.5, 3.0), px(1.3, 2.2), px(0.5, 1.7), px(-0.3, 1.9), px(-0.6, 2.7)], TAN, 255, 2.5, W, 6)
    shape(side, [px(-2.6, 3.5), px(-1.3, 3.6), px(-0.7, 3.0), px(-0.9, 2.1), px(-1.7, 1.6), px(-2.5, 1.9), px(-2.8, 2.7)], TAN, 255, 2.5, W, 7)
    # black saddle over the back, dipping down the flanks
    shape(side, [px(-2.0, 3.85), px(-1.0, 3.95), px(0.3, 3.9), px(1.0, 3.7), px(0.9, 3.2), px(0.2, 2.75), px(-0.8, 2.6), px(-1.7, 2.85), px(-2.1, 3.3)], BLACK, 255, 2.5, W, 8)
    # tan cuffs on the legs, white socks below
    shape(side, [px(0.95, 2.55), px(1.75, 2.55), px(1.7, 1.65), px(1.0, 1.65)], TAN, 255, 2, 4, 9)
    shape(side, [px(-2.15, 2.5), px(-1.0, 2.5), px(-1.05, 1.5), px(-2.1, 1.5)], TAN, 255, 2, 4, 10)
    # tail: tan with a white tip
    shape(side, [px(-3.5, 2.6), px(-2.0, 2.6), px(-2.0, 4.6), px(-3.5, 4.6)], TAN, 255, 2.5, 4, 11)
    shape(side, [px(-3.3, 4.55), px(-2.1, 4.55), px(-2.1, 5.4), px(-3.3, 5.4)], WHITE, 255, 2.5, 4, 12)
    # painted eyebrows and eye bags (no bumps)
    d = ImageDraw.Draw(side)
    ex, ey = px(3.62, 4.58)
    d.arc([ex - 26, ey - 42, ex + 30, ey - 6], 200, 340, fill=(60, 40, 28, 255), width=7)
    d.arc([ex - 22, ey - 2, ex + 24, ey + 30], 20, 160, fill=(120, 80, 70, 200), width=4)
    atlas.paste(side.convert("RGB"), (x0, y0))
    for key, col in (("black", (24, 22, 24)), ("shine", (250, 250, 250)), ("red", (196, 40, 40)), ("gold", (240, 190, 60)),
                     ("pink", (214, 110, 120)), ("amber", (150, 90, 30)), ("grey", (150, 146, 142))):
        x0, y0, x1, y1 = rb(UV[key]); atlas.paste(Image.new("RGB", (x1 - x0, y1 - y0), col), (x0, y0))
    return atlas

LUA = r'''-- Old hound: run in the Command Bar with the imported model SELECTED. Safe to run again.
-- Matte fur, glossy nose and eyes, and an idle script: breathing, tail wag, looking around, a howl now and then.
local model = game.Selection:Get()[1] or workspace:FindFirstChild("hound")
assert(model and model:IsA("Model"), "Select the imported hound model first")
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		p.CanCollide = (p.Name == "HoundBody" or p.Name == "HoundHead")
		if p.Name == "Nose" or p.Name:match("^EyeWhite") or p.Name:match("^Iris") or p.Name:match("^Pupil") then
			p.Material = Enum.Material.Glass; p.Reflectance = 0
		elseif p.Name:match("Pivot") then
			p.Transparency = 1; p.CanCollide = false
		elseif p.Name:match("^Collar") then
			p.Material = Enum.Material.SmoothPlastic
		else
			p.Material = Enum.Material.Fabric
		end
	end
end
local old = model:FindFirstChild("HoundIdle"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "HoundIdle"
s.Source = [[
local model = script.Parent
local RunService = game:GetService("RunService")
local body = model:FindFirstChild("HoundBody")
if not body then return end
local HEAD = {"^HoundHead", "^Nose", "^Tongue", "^Eye", "^Iris", "^Pupil"}
local function isHead(n) for _, k in ipairs(HEAD) do if n:match(k) then return true end end return false end
local rest, head, tail = {}, {}, {}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= body then
		local off = body.CFrame:ToObjectSpace(p.CFrame)
		if p.Name == "HoundTail" then table.insert(tail, {p, off})
		elseif isHead(p.Name) then table.insert(head, {p, off})
		else table.insert(rest, {p, off}) end
	end
end
local home = body.CFrame
local np, tpv = model:FindFirstChild("NeckPivot"), model:FindFirstChild("TailPivot")
local neckPivot = home:ToObjectSpace(CFrame.new(np and np.Position or (body.Position + Vector3.new(1.9, 0.7, 0))))
local tailPivot = home:ToObjectSpace(CFrame.new(tpv and tpv.Position or (body.Position - Vector3.new(2.2, 0, 0))))
local rng = Random.new()
local t, nextHowl, howlT = 0, rng:NextNumber(8, 16), -1
local lookYaw, lookTarget, lookTimer = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local breathe = math.sin(t * 1.0) * 0.03
	local base = home * CFrame.new(0, breathe, 0)
	body.CFrame = base
	for _, e in ipairs(rest) do e[1].CFrame = base * e[2] end
	lookTimer -= dt
	if lookTimer <= 0 then lookTarget = rng:NextNumber(-0.3, 0.3); lookTimer = rng:NextNumber(3, 7) end
	lookYaw += (lookTarget - lookYaw) * math.min(1, dt * 1.5)
	local pitch = 0
	if howlT < 0 and t > nextHowl then howlT = 0 end
	if howlT >= 0 then
		howlT += dt
		local k = math.min(howlT / 3.2, 1)
		pitch = -math.rad(34) * math.sin(k * math.pi) ^ 0.7
		if howlT >= 3.2 then howlT = -1; nextHowl = t + rng:NextNumber(12, 25) end
	end
	local headCF = neckPivot * CFrame.Angles(0, lookYaw, pitch) * neckPivot:Inverse()
	for _, e in ipairs(head) do e[1].CFrame = base * headCF * e[2] end
	local wag = math.sin(t * (howlT >= 0 and 5 or 2)) * math.rad(18)
	local swing = tailPivot * CFrame.Angles(wag, 0, 0) * tailPivot:Inverse()
	for _, e in ipairs(tail) do e[1].CFrame = base * swing * e[2] end
end)
]]
s.Parent = model
model.Name = "OldHound"
print("Old hound: matte fur and idle motion applied")
'''

def write_preview(obj_text, png_path, out_name, cam, look):
    _wp(obj_text, png_path, out_name, cam, look)
    p = OUT / out_name; h = p.read_text(encoding="utf-8")
    for old in ("new THREE.MeshStandardMaterial({map:tex,roughness:0.55,metalness:0.45})", "new THREE.MeshStandardMaterial({map:tex,roughness:0.8,metalness:0.05})"):
        h = h.replace(old, "new THREE.MeshStandardMaterial({map:tex,roughness:0.95,metalness:0})")
    p.write_text(h, encoding="utf-8")

if __name__ == "__main__":
    o = build()
    tris = o.write(OUT / "hound.obj", "hound_texture.png")
    paint().save(OUT / "hound_texture.png")
    (OUT / "hound_setup.lua").write_text(LUA, encoding="utf-8")
    write_preview((OUT / "hound.obj").read_text(encoding="utf-8"), OUT / "hound_texture.png", "preview_hound.html", (9, 5.5, 10), (0.6, 2.8, 0))
    print(f"hound.obj: {tris} triangles, {len(o.objects)} pieces")
