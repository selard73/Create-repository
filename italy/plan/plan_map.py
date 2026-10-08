import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon
import numpy as np, re
# the real channel, measured Sep 30 (gorge_probe1): z, water x min..max
rows = []
for line in open(r"C:\Users\slard\roblox-props\tools\gorge_probe1_out.txt", encoding="utf-8-sig"):
    m = re.match(r"Z\s+(-?\d+) .*water x (\d+)\.\.(\d+)", line.strip())
    if m:
        rows.append((int(m.group(1)), int(m.group(2)), int(m.group(3))))
rows = [r for r in rows if r[0] <= -220]
Z = np.array([r[0] for r in rows]); X0 = np.array([r[1] for r in rows]); X1 = np.array([r[2] for r in rows]); XC = (X0 + X1) / 2
f, ax = plt.subplots(figsize=(10, 8.6))
ax.add_patch(Rectangle((-1024, -1024), 2048, 1100, fc="#e6efd9", ec="none"))
# the south ridge (new terrain hills)
ax.add_patch(Rectangle((-240, -1020), 1240, 790, fc="#b9cf9a", ec="#7f9b5a", lw=1, alpha=0.9))
for zz, lab in ((-300, "ridge ~45 high by the gorge"), (-620, "hills rising to 60-70"), (-900, "hills 80-90: the horizon")):
    ax.text(960, zz, lab, ha="right", fontsize=8, color="#4d6a2e")
# play area
ax.add_patch(Rectangle((-138, -251), 839, 284, fc="#f3e0b5", ec="#b58", lw=1.4))
ax.text(-120, -40, "PLAY AREA (unchanged)", fontsize=9, color="#7a4d2a")
ax.plot([142, 352], [-205, -205], color="#b58", lw=2.2); ax.text(250, -198, "village south wall z -205", fontsize=7, ha="center", color="#7a4d2a")
ax.add_patch(Rectangle((440, -271), 152, 18, fc="#e2b779", ec="#8a6436")); ax.text(516, -290, "Sandstone Climb", fontsize=7, ha="center")
# the gorge: rock faces either side of the water from the wall to the second bend
gz = (Z >= -540)
L = np.column_stack([X0[gz] - 4, Z[gz]]); R = np.column_stack([X1[gz] + 4, Z[gz]])
ax.add_patch(Polygon(np.vstack([L - [10, 0], R[::-1] + [10, 0]]), fc="#e8cf9f", ec="#9a6b35", lw=1.2))
ax.add_patch(Polygon(np.vstack([np.column_stack([X0[gz], Z[gz]]), np.column_stack([X1[gz], Z[gz]])[::-1]]), fc="#4a9be0", ec="#2c6fb0"))
# the basin + aqueduct at the west bend, where the river runs straight south
zb = -388; xb = float(np.interp(-zb, -Z, XC))
ax.add_patch(Polygon([(xb - 32, zb + 26), (xb + 32, zb + 26), (xb + 32, zb - 26), (xb - 32, zb - 26)], fc="#f1e2b8", ec="#9a6b35", lw=1, alpha=0.9))
ax.add_patch(Polygon(np.vstack([np.column_stack([X0[gz], Z[gz]]), np.column_stack([X1[gz], Z[gz]])[::-1]]), fc="#4a9be0", ec="none"))
ax.plot([xb - 50, xb + 50], [zb, zb], color="#8a5a2b", lw=5, solid_capstyle="butt")
ax.annotate("AQUEDUCT + basin\n(river runs due south here)", xy=(xb + 40, zb), xytext=(xb + 120, zb - 40), fontsize=8, arrowprops=dict(arrowstyle="-", color="#555"))
ax.plot([XC[Z == -208][0] if (Z == -208).any() else 160], [-208], "o", color="#c0392b")
ax.annotate("autopilot starts\n('Sail to Italy?' Yes)", xy=(165, -212), xytext=(250, -168), fontsize=8, color="#c0392b", arrowprops=dict(arrowstyle="-", color="#c0392b"))
zf = -470; xf = float(np.interp(-zf, -Z, XC))
ax.plot([xf - 26, xf + 26], [zf, zf], color="#8e44ad", lw=2.5, ls="--")
ax.annotate("bend hides the way on:\nfade + map card", xy=(xf + 26, zf), xytext=(xf + 110, zf - 50), fontsize=8, color="#8e44ad", arrowprops=dict(arrowstyle="-", color="#8e44ad"))
ax.text(80, -560, "old channel beyond here:\nburied under the hills", fontsize=7, color="#1b5c99")
ax.plot(157, -157, "s", color="#556b2f", ms=7); ax.text(170, -150, "jetty", fontsize=7)
for (x, z, t) in ((497, -260, "summit view"), (480, -250, "")):
    pass
ax.set_xlim(-260, 1020); ax.set_ylim(-1030, 60); ax.set_aspect("equal")
ax.set_xlabel("x (studs)"); ax.set_ylabel("z (studs)   south = down")
ax.set_title("South gorge build: where everything goes (top-down, from today's measurements)", fontsize=10)
ax.grid(alpha=0.15)
plt.tight_layout(); plt.savefig(r"C:\Users\slard\roblox-props\italy\plan\plan_map.png", dpi=110)
print("ok", len(rows), "rows; aqueduct x", round(xb, 1), "fade x", round(xf, 1))
