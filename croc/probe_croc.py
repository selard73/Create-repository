"""Probe the prepped croc (croc.blend): torso centre line, head + jaw landmarks, leg clusters, tail path (geodesic bins).
Run: blender --background --python probe_croc.py -- <out_dir>"""
import bpy, bmesh, sys, os, math, heapq, traceback
from mathutils import Vector
OUTD = sys.argv[sys.argv.index("--") + 1:][0]
LOG = os.path.join(OUTD, "probe_log.txt")
def log(m):
    with open(LOG, "a") as f: f.write(str(m) + "\n")
def r2(v): return tuple(round(c, 2) for c in v)
try:
    open(LOG, "w").close()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(OUTD, "croc.blend"))
    croc = bpy.data.objects["Croc"]
    me = croc.data
    pts = [v.co.copy() for v in me.vertices]
    # islands
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    comp = [-1] * len(bm.verts); nc = 0
    for s in range(len(bm.verts)):
        if comp[s] >= 0: continue
        st = [s]; comp[s] = nc
        while st:
            i = st.pop()
            for e in bm.verts[i].link_edges:
                j = e.other_vert(bm.verts[i]).index
                if comp[j] < 0: comp[j] = nc; st.append(j)
        nc += 1
    sizes = {}
    for c in comp: sizes[c] = sizes.get(c, 0) + 1
    big = max(sizes, key=sizes.get)
    log(f"islands {nc}; main island {sizes[big]} verts; others: " + ", ".join(
        f"{c}:{n}@{r2(sum((pts[i] for i in range(len(pts)) if comp[i]==c), Vector())/n)}" for c, n in sorted(sizes.items(), key=lambda kv: -kv[1])[1:40]))
    # torso centre line (|x|<1.0), per y
    log("TORSO |x|<1.0: y zmin zmax zc")
    for k in range(0, 33):
        y = k * 0.5
        sl = [p.z for p in pts if abs(p.y - y) < 0.2 and abs(p.x) < 1.0]
        if sl: log(f"{y:5.1f} {min(sl):5.2f} {max(sl):5.2f} {(min(sl)+max(sl))/2:5.2f}")
    # head side profile at x in [-0.3, 0.3]: for y 0..5 list z clusters
    log("HEAD profile |x|<0.3 (z clusters, gap>0.18)")
    for k in range(0, 26):
        y = k * 0.2
        zs = sorted(p.z for p in pts if abs(p.y - y) < 0.1 and abs(p.x) < 0.3)
        cl = []; 
        for z in zs:
            if cl and z - cl[-1][1] < 0.18: cl[-1][1] = z
            else: cl.append([z, z])
        log(f"{y:4.1f} " + " ".join(f"[{a:.2f}-{b:.2f}]" for a, b in cl))
    # leg clusters: |x| > 1.3 (outside torso) per side and fore/hind
    for tag, ya, yb in (("FRONT", 2.8, 7.0), ("HIND", 7.2, 10.8)):
        for s in (1, -1):
            L = [p for p in pts if ya < p.y < yb and p.x * s > 1.3 and p.z < 3.0]
            if not L: log(f"{tag} {s}: none"); continue
            foot = [p for p in L if p.z < 0.35]
            fc = sum(foot, Vector()) / len(foot) if foot else None
            out = max(L, key=lambda p: p.x * s)
            log(f"{tag} side {s:+d}: n {len(L)} foot {r2(fc) if fc else None} (n {len(foot)}) outermost {r2(out)} zmax {max(p.z for p in L):.2f}")
            for z0 in (0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4):
                b = [p for p in L if z0 <= p.z < z0 + 0.4]
                if b:
                    c = sum(b, Vector()) / len(b)
                    log(f"   z {z0:.1f}-{z0+0.4:.1f}: n {len(b):4d} c {r2(c)} x {min(p.x for p in b):5.2f}..{max(p.x for p in b):5.2f} y {min(p.y for p in b):5.2f}..{max(p.y for p in b):5.2f}")
    # tail path: geodesic distance on the main island from the ring at y~10.4 (|x|<1.6)
    seeds = [i for i, p in enumerate(pts) if comp[i] == big and 10.2 < p.y < 10.6 and p.z > 0.6]
    dist = {i: 0.0 for i in seeds}; hq = [(0.0, i) for i in seeds]
    while hq:
        d, i = heapq.heappop(hq)
        if d > dist.get(i, 1e9): continue
        for e in bm.verts[i].link_edges:
            j = e.other_vert(bm.verts[i]).index
            if pts[j].y < 10.2: continue
            nd = d + (pts[i] - pts[j]).length
            if nd < dist.get(j, 1e9): dist[j] = nd; heapq.heappush(hq, (nd, j))
    mx = max(dist.values())
    log(f"TAIL geodesic from y~10.4 ring: max {mx:.2f}")
    nb = 10
    for b in range(nb):
        sel = [pts[i] for i, d in dist.items() if b * mx / nb <= d < (b + 1) * mx / nb]
        if sel:
            c = sum(sel, Vector()) / len(sel)
            log(f"  bin {b}: n {len(sel)} centroid {r2(c)} zmin {min(p.z for p in sel):.2f} zmax {max(p.z for p in sel):.2f}")
    log("PROBE_DONE")
except Exception:
    log(traceback.format_exc()); log("PROBE_FAILED")
