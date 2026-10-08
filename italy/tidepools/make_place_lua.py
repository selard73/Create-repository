"""Writes ../../tools/italy_squirrels/tidepools_place.lua from tidepools_data.json + exact heights from gen_tidepools.heights()."""
import json, os
import numpy as np
import gen_tidepools as G

HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, "tidepools_data.json")))
sh, wa = d["pieces"]["TidePoolShelf"], d["pieces"]["TidePoolWater"]


def hy(x, z):
    H, _, _, _ = G.heights(np.array([x]), np.array([z]))
    return round(float(H[0]), 3)


life = []


def add(kind, x, z, extra=0):
    life.append((kind, x, hy(x, z), z, extra))


# starfish on pool beds (under water), anemones on beds, seaweed on rims, shells, one crab on dry rock
for (x, z, rot) in [(291.0, -783.4, 10), (294.4, -794.6, 40), (303.2, -801.0, 75)]:
    add("starfish", x, z, rot)
for (x, z) in [(295.6, -771.6), (296.4, -786.9), (290.3, -780.2)]:
    add("anemone", x, z)
for (x, z) in [(292.2, -768.4), (297.7, -773.9), (289.2, -781.8), (292.9, -786.9), (291.0, -792.3), (297.4, -797.2),
               (300.7, -799.0), (306.2, -803.5), (299.3, -776.0)]:
    add("seaweed", x, z)
for (x, z) in [(293.4, -771.9), (297.3, -785.6), (294.9, -796.9), (304.4, -801.6), (298.3, -777.8)]:
    add("shell", x, z)
add("crab", 299.4, -790.4, -60)

rows = ['{"%s",%.2f,%.3f,%.2f,%g}' % (k, x, y, z, e) for (k, x, y, z, e) in life]
lua = open(os.path.join(HERE, "place_template.lua")).read()
lua = lua.replace("%SHELF%", "{%.4f,%.4f,%.4f,%.4f,%.4f,%.4f}" % tuple(sh["centre"] + sh["size"]))
lua = lua.replace("%WATER%", "{%.4f,%.4f,%.4f,%.4f,%.4f,%.4f}" % tuple(wa["centre"] + wa["size"]))
lua = lua.replace("%LIFE%", "{" + ",".join(rows) + "}")
out = os.path.normpath(os.path.join(HERE, "..", "..", "tools", "italy_squirrels", "tidepools_place.lua"))
open(out, "w").write(lua)
print("wrote", out, len(life), "life items")
for (k, x, y, z, e), r in zip(life, rows):
    wl = min(d["water"], key=lambda w: (w["centre"][0] - x) ** 2 + (w["centre"][1] - z) ** 2)["level"]
    print(r, "under water" if y < wl else "dry", "(nearest pool level %.2f)" % wl)
