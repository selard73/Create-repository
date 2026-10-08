"""patch_end.py - one-off patch (Sep 30 2026): the gorge's end becomes a HEADWALL with a cave mouth.
gorge_shape.py: the walls end at full width at Z_END = -548 (no pinch); headwall constants.
gen_gorge_real.py: no sliver rule (keeps chunk bounds), no end caps at the join, the headwall + tunnel + dark back
meshes, and an extra OBJ (end_roblox.obj) with just the pieces that change."""
import os
HERE = os.path.dirname(os.path.abspath(__file__))

s = open(os.path.join(HERE, "gorge_shape.py"), encoding="utf-8").read()
old = "Z_START, Z_END = -228.0, -566.0"
assert old in s
s = s.replace(old, "Z_START, Z_END = -228.0, -548.0")
old = "    close = close_f(z)\n    return f * (1 - close) - 1.0 * close"
assert old in s
s = s.replace(old, "    return f                                              # (the walls run at full width to the headwall; no pinch)")
old = '''def close_f(z):
    """0 through the gorge -> 1 at its far end, where the walls straighten and meet"""
    return smoothstep(Z_END + 40.0, Z_END + 4.0, z)'''
assert old in s
s = s.replace(old, '''def close_f(z):
    """(kept for the face functions) the walls no longer pinch: the headwall closes the slot"""
    return np.zeros_like(np.asarray(z, dtype=float))''')
if "R_END" not in s:
    s += '''

# ---------------------------------------------------------------- the headwall (the gorge's end) ----
# A half-circle of the same rock closing the slot at Z_END, bulging downstream, joining each wall at its face; a low
# arch (ARCH_W wide, ARCH_H high above the water) at its foot leads into a short dark tunnel (the river goes on under
# the mountain, toward Italy). Radius chosen so the arc is about one strata-texture repeat long (48 studs).
R_END = 48.0 / math.pi
ARCH_W, ARCH_H, TUNNEL_D = 8.0, 6.0, 7.0


def headwall_centre():
    return float(centre_x(Z_END)), Z_END


def headwall_R(theta):
    """the face's base distance from the centre at angle theta (0 = west join, pi = east join): each wall's own foot at
    the join, R_END round the apex"""
    fw, fe = float(foot(Z_END, -1)), float(foot(Z_END, 1))
    w = math.sin(theta) ** 2
    return (fw if theta < math.pi / 2 else fe) * (1 - w) + R_END * w


def headwall_T(theta):
    tw, te = float(top_at(Z_END, -1)), float(top_at(Z_END, 1))
    return tw + (te - tw) * theta / math.pi
'''
open(os.path.join(HERE, "gorge_shape.py"), "w", encoding="utf-8", newline="\n").write(s)

g = open(os.path.join(HERE, "gen_gorge_real.py"), encoding="utf-8").read()
g = g.replace("    if bounds[-1] - bounds[-2] < 8:                     # no sliver at the end\n        bounds.pop(-2)\n", "")
old = ('        ROCK.append(chunk_mesh("SouthRock_%s%02d" % (tag, k + 1), P, V, N, bounds[k], bounds[k + 1], s,\n'
       '                               cap_start=(k == 0), cap_end=(k == len(bounds) - 2)))')
assert old in g
g = g.replace(old, '        ROCK.append(chunk_mesh("SouthRock_%s%02d" % (tag, k + 1), P, V, N, bounds[k], bounds[k + 1], s,\n'
                   '                               cap_start=(k == 0), cap_end=False))                 # (the headwall meets the walls at the end)')
headwall_code = open(os.path.join(HERE, "headwall_block.py.txt"), encoding="utf-8").read()
marker = "\n\n# ================================================================ the aqueduct ================"
assert marker in g
if "SouthRock_End" not in g:
    g = g.replace(marker, headwall_code + marker)
g = g.replace('"BoatGreen": ("col", (86, 96, 60))}', '"BoatGreen": ("col", (86, 96, 60)), "CaveDark": ("col", (18, 16, 14))}')
old = 'write_mtl(os.path.join(HERE, "rock_roblox.mtl"), ["Strata"])'
if old in g:
    g = g.replace(old, 'write_mtl(os.path.join(HERE, "rock_roblox.mtl"), ["Strata", "CaveDark"])\n'
                       'end_c = write_obj(os.path.join(HERE, "end_roblox.obj"), [m for m in ROCK if m.name in END_PIECES], "end_roblox.mtl", roblox=True)\n'
                       'write_mtl(os.path.join(HERE, "end_roblox.mtl"), ["Strata", "CaveDark"])')
g = g.replace('data = dict(rock=rock_c, aqueduct=aq_c, trees=TREES, root=ROOT,', 'data = dict(rock=rock_c, aqueduct=aq_c, trees=TREES, root=ROOT, end=end_c,')
open(os.path.join(HERE, "gen_gorge_real.py"), "w", encoding="utf-8", newline="\n").write(g)
print("patched")
