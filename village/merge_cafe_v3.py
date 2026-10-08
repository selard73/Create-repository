"""Merge the rebuilt shop-house kit (townhouse_a/b/c, pot, crates) into cafe_v3.obj for one Import 3D.
Objects are renamed <kit>__<piece>; each prop is shifted along X so nothing overlaps; the builder regroups them."""
from pathlib import Path
D = Path(__file__).parent
KIT = ["disp_cafe", "chalkboard"]
V, VT, VN, OBJS, MTL = [], [], [], [], []
x = 0.0
for k in KIT:
    lines = (D / f"{k}.obj").read_text().splitlines()
    v = [tuple(map(float, l.split()[1:])) for l in lines if l.startswith("v ")]
    xs = [p[0] for p in v]; w = max(xs) - min(xs)
    off = x - min(xs)
    bv, bvt, bvn = len(V), len(VT), len(VN)
    V += [(p[0] + off, p[1], p[2]) for p in v]
    VT += [l for l in lines if l.startswith("vt ")]
    VN += [l for l in lines if l.startswith("vn ")]
    for l in lines:
        if l.startswith("o "):
            OBJS.append((f"{k}__{l[2:].strip()}", []))
        elif l.startswith("f "):
            parts = []
            for tok in l.split()[1:]:
                a, b, c = tok.split("/")
                parts.append(f"{int(a)+bv}/{int(b)+bvt}/{int(c)+bvn}")
            OBJS[-1][1].append("f " + " ".join(parts))
    MTL.append((D / f"{k}.mtl").read_text().replace("newmtl m_", f"newmtl m_{k}__"))
    x += w + 6.0
out = ["mtllib cafe_v3.mtl"] + [f"v {a:.4f} {b:.4f} {c:.4f}" for a, b, c in V] + VT + VN
for name, faces in OBJS:
    out += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s off"] + faces
(D / "cafe_v3.obj").write_text("\n".join(out) + "\n")
(D / "cafe_v3.mtl").write_text("".join(MTL))
print("cafe_v3.obj:", len(V), "verts,", sum(len(f) for _, f in OBJS), "tris,", len(OBJS), "pieces, width", round(x, 1))
