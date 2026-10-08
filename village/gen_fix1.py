"""Village fix 1 (Sep 16): regenerates ONLY the two pitched-roof houses (gable ends now face outward), adds the new
table_setting kit (cloth, glass vase, roses, plates, cups, napkins, cutlery for the cafe tables) and merges them with
lamp_post_v2 into village_fix1.obj for one Import 3D. Helpers come from gen_village.py without running its main block.
Run: python gen_fix1.py"""
import math, random
from pathlib import Path

D = Path(__file__).parent
src = (D / "gen_village.py").read_text(encoding="utf-8")
ns = {"__file__": str(D / "gen_village.py"), "__name__": "gen_village_helpers"}
exec(compile(src[:src.index('if __name__ == "__main__":')], "gen_village_helpers", "exec"), ns)
Obj, ring, tube, box, icoblob, townhouse, F = ns["Obj"], ns["ring"], ns["tube"], ns["box"], ns["icoblob"], ns["townhouse"], ns["F"]

F.GRAYS.update({"Cloth": (0.97, 0.96, 0.93), "Plate": (0.98, 0.98, 0.97), "Cup": (0.98, 0.98, 0.97), "Napkin": (0.78, 0.24, 0.24),
                "Rose": (0.90, 0.35, 0.47), "Cutlery": (0.70, 0.71, 0.75), "Glass": (0.78, 0.86, 0.92), "Leaf": (0.45, 0.62, 0.40)})

# 1. the two pitched-roof houses, exactly the main block's calls (gable fix lives in townhouse())
print("townhouse_b", townhouse("townhouse_b", 2, 22.0, 2, "pitched", "centre", "arch", flowers=True, door_style="double"), "tris")
print("townhouse_d", townhouse("townhouse_d", 4, 18.0, 3, "pitched", "left", "arch", door_style="arched", shutters=True), "tris")


# 2. table setting: kit y = 0 is 0.6 below the table top (the cloth skirt hangs 0.6), so the builder rests it at
#    ground + 2.3 - 0.6. Plates face the chairs, which sit at +-z on the cafe_table kit.
def table_setting(name, seed):
    rnd = random.Random(seed); o = Obj()
    T = 0.6                                                                    # table-top plane
    tube(o, "Cloth", [ring((0, 0, 0), 1.34, T, 10), ring((0, 0, 0), 1.34, T + 0.06, 10)], (0, T + 0.03, 0), cap_top=True, cap_bottom=True)
    tube(o, "Cloth", [ring((0, 0, 0), 1.28, 0.0, 10), ring((0, 0, 0), 1.34, T, 10)], (0, T / 2, 0))        # skirt
    tube(o, "Glass", [ring((0, 0, 0), 0.14, T + 0.06, 8), ring((0, 0, 0), 0.10, T + 0.40, 8), ring((0, 0, 0), 0.16, T + 0.62, 8)],
         (0, T + 0.3, 0), cap_bottom=True, cap_top=False)
    lt, rt = [], []
    icoblob(o, "Leaf", (0, T + 0.72, 0), 0.17, rnd, 0.12, (1.3, 0.6, 1.3), tris_out=lt)
    for k, (dx, dz, dy) in enumerate(((-0.11, 0.05, 0.86), (0.10, 0.08, 0.90), (0.0, -0.11, 0.94))):
        icoblob(o, "Rose", (dx, T + dy, dz), 0.12, rnd, 0.08, tris_out=rt)
    o.add_flat("Leaf", lt); o.add_flat("Rose", rt)
    pt, ct, nt, kt = [], [], [], []
    for sgn in (-1, 1):
        z = sgn * 0.62
        tube(o, "Plate", [ring((0, 0, z), 0.34, T + 0.06, 12), ring((0, 0, z), 0.34, T + 0.10, 12)], (0, T + 0.08, z), cap_top=True, cap_bottom=True, tris_out=pt)
        tube(o, "Plate", [ring((0, 0, z), 0.22, T + 0.10, 12), ring((0, 0, z), 0.22, T + 0.12, 12)], (0, T + 0.11, z), cap_top=True, tris_out=pt)   # rim step
        tube(o, "Cup", [ring((0.52, 0, z * 0.85), 0.13, T + 0.06, 8), ring((0.52, 0, z * 0.85), 0.15, T + 0.30, 8)], (0.52, T + 0.18, z * 0.85), cap_bottom=True, tris_out=ct)
        box(o, "Napkin", (-0.55, T + 0.08, z), 0.34, 0.04, 0.5, tris_out=nt)
        box(o, "Cutlery", (-0.55, T + 0.11, z), 0.04, 0.02, 0.44, tris_out=kt)                                 # fork on the napkin
        box(o, "Cutlery", (0.44, T + 0.08, z), 0.05, 0.02, 0.46, tris_out=kt)                                  # knife
    o.add_flat("Plate", pt); o.add_flat("Cup", ct); o.add_flat("Napkin", nt); o.add_flat("Cutlery", kt)
    return o.write(D / f"{name}.obj")


print("table_setting", table_setting("table_setting", 41), "tris")

# 3. merge for one Import 3D (pieces "<kit>__<piece>", kits shifted along X so nothing overlaps; builder regroups)
KIT = ["lamp_post_v2", "townhouse_b", "townhouse_d", "table_setting"]
ALIAS = {"lamp_post_v2": "lamp_post"}
V, VT, VN, OBJS, MTL = [], [], [], [], []
x = 0.0
for k in KIT:
    kit = ALIAS.get(k, k)
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
            OBJS.append((f"{kit}__{l[2:].strip()}", []))
        elif l.startswith("f "):
            parts = []
            for tok in l.split()[1:]:
                a, b, c = tok.split("/")
                parts.append(f"{int(a) + bv}/{int(b) + bvt}/{int(c) + bvn}")
            OBJS[-1][1].append("f " + " ".join(parts))
    MTL.append((D / f"{k}.mtl").read_text().replace("newmtl m_", f"newmtl m_{kit}__"))
    x += w + 8.0
out = ["mtllib village_fix1.mtl"] + [f"v {a:.4f} {b:.4f} {c:.4f}" for a, b, c in V] + VT + VN
for name, faces in OBJS:
    out += [f"o {name}", f"g {name}", f"usemtl m_{name}", "s off"] + faces
(D / "village_fix1.obj").write_text("\n".join(out) + "\n")
(D / "village_fix1.mtl").write_text("".join(MTL))
names = sorted({n.split("__")[0] for n, _ in OBJS})
print("village_fix1.obj:", len(V), "verts,", sum(len(f) for _, f in OBJS), "tris,", len(OBJS), "pieces, kits:", names)
