"""Merge domaine kit .obj files into one file for a single Import 3D (Merge Meshes OFF).
Objects are renamed <kit>__<piece>; kits are shifted along X so nothing overlaps; the builder regroups them.
Usage: python merge_domaine.py <out_name> <kit> [<kit> ...]      e.g. python merge_domaine.py domaine_veg lavender_row_a ..."""
import sys
from pathlib import Path

D = Path(__file__).parent
out_name, kits = sys.argv[1], sys.argv[2:]
V, VT, VN, OBJS, MTL = [], [], [], [], []
x = 0.0
for k in kits:
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
    x += w + 8.0
out = [f"mtllib {out_name}.mtl"] + [f"v {a:.4f} {b:.4f} {c:.4f}" for a, b, c in V] + VT + VN
for name, faces in OBJS:
    out += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s off"] + faces
(D / f"{out_name}.obj").write_text("\n".join(out) + "\n")
(D / f"{out_name}.mtl").write_text("".join(MTL))
big = [(n, len(f)) for n, f in OBJS if len(f) > 9500]
print(f"{out_name}.obj: {len(V)} verts, {sum(len(f) for _, f in OBJS)} tris, {len(OBJS)} pieces, width {x:.0f}", ("; OVER 9500 TRIS: " + str(big)) if big else "")
