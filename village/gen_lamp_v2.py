"""Lamp post v2: same lamp as gen_village.lamp_post() but the pole now reaches the lantern's base plate (the kit had a
0.3 stud gap between the pole top at y 8.0 and the plate at 8.3..8.5). Nothing else in gen_village.py is regenerated:
the generator's helpers are loaded without running its main block.
Writes lamp_post_v2.obj/.mtl and lamp_v2.obj/.mtl (pieces named lamp_post__Post / lamp_post__Lantern for Import 3D).
Run: python gen_lamp_v2.py"""
from pathlib import Path

D = Path(__file__).parent
src = (D / "gen_village.py").read_text(encoding="utf-8")
cut = src.index("\ncounts = {}") if "\ncounts = {}" in src else src.index("counts[\"townhouse_a\"]")
ns = {"__file__": str(D / "gen_village.py"), "__name__": "gen_village_helpers"}
exec(compile(src[:cut], "gen_village_helpers", "exec"), ns)
Obj, ring, tube, box = ns["Obj"], ns["ring"], ns["tube"], ns["box"]

POLE_TOP = 8.3          # was 8.0; the plate sits at 8.3..8.5


def lamp_post_v2(name):
    o = Obj()
    tube(o, "Post", [ring((0, 0, 0), 0.5, 0, 6), ring((0, 0, 0), 0.5, 0.6, 6), ring((0, 0, 0), 0.18, 0.7, 6),
                     ring((0, 0, 0), 0.16, POLE_TOP, 6)], (0, 4, 0), cap_bottom=True, cap_top=True)
    box(o, "Post", (0, 8.4, 0), 1.2, 0.2, 1.2)
    lt = []
    box(o, "Lantern", (0, 9.2, 0), 0.9, 1.4, 0.9, tris_out=lt)
    o.add_flat("Lantern", lt)
    # roof cap: four slopes plus a BASE, oriented from a centre inside the pyramid so the base faces down. The old cap
    # had no base and its sides were seen from below through their open underside, so the cap looked detached.
    b = 9.86                                   # base slightly inside the lantern top (9.9): overlap, no coplanar fight
    pt = [((-0.7, b, -0.7), (0.7, b, -0.7), (0, 10.7, 0)), ((0.7, b, -0.7), (0.7, b, 0.7), (0, 10.7, 0)),
          ((0.7, b, 0.7), (-0.7, b, 0.7), (0, 10.7, 0)), ((-0.7, b, 0.7), (-0.7, b, -0.7), (0, 10.7, 0)),
          ((-0.7, b, -0.7), (0.7, b, 0.7), (0.7, b, -0.7)), ((-0.7, b, -0.7), (-0.7, b, 0.7), (0.7, b, 0.7))]
    o.add_flat("Post", pt, (0, 10.15, 0))
    return o.write(D / f"{name}.obj")


lamp_post_v2("lamp_post_v2")

# one-kit merge with the builder's "<kit>__<piece>" naming (same pattern as merge_bakeryb_v1.py)
lines = (D / "lamp_post_v2.obj").read_text().splitlines()
out = ["mtllib lamp_v2.mtl"]
for l in lines:
    if l.startswith("o "):
        out.append(f"o lamp_post__{l[2:].strip()}")
    elif l.startswith("g "):
        out.append(f"g lamp_post__{l[2:].strip()}")
    elif l.startswith("usemtl m_"):
        out.append(l.replace("usemtl m_", "usemtl m_lamp_post__"))
    elif l.startswith("mtllib"):
        continue
    else:
        out.append(l)
(D / "lamp_v2.obj").write_text("\n".join(out) + "\n")
(D / "lamp_v2.mtl").write_text((D / "lamp_post_v2.mtl").read_text().replace("newmtl m_", "newmtl m_lamp_post__"))

# report the vertical extents per piece so the join can be checked without Blender
v = [tuple(map(float, l.split()[1:])) for l in lines if l.startswith("v ")]
piece, ranges, cur = None, {}, None
idx = 0
for l in lines:
    if l.startswith("o "):
        cur = l[2:].strip(); ranges.setdefault(cur, [1e9, -1e9])
    elif l.startswith("f ") and cur:
        for tok in l.split()[1:]:
            y = v[int(tok.split("/")[0]) - 1][1]
            ranges[cur][0] = min(ranges[cur][0], y); ranges[cur][1] = max(ranges[cur][1], y)
for k, (lo, hi) in ranges.items():
    print(f"{k}: y {lo:.2f}..{hi:.2f}")
print("pole top now", POLE_TOP, "(plate 8.3..8.5, lantern 8.5..9.9, roof 9.9..10.7); wrote lamp_v2.obj")
