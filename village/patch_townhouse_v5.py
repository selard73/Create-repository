"""v5: three door styles (arched brick, panelled with stone surround, glazed double door) and two more house
types (narrow 3-floor pitched 'd', wide 2-floor flat 'e') so neighbours never share a width or layout."""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)

rep('def townhouse(name, seed, width, floors, roof="flat", door="centre", upper="arch", flowers=False):',
    'def townhouse(name, seed, width, floors, roof="flat", door="centre", upper="arch", flowers=False, door_style="arched", shutters=False):')
rep('            window("front", x, y0, upper, shutters=(upper == "tall"), railing=(upper == "tall"), flowerbox=flowers)',
    '            window("front", x, y0, upper, shutters=(upper == "tall") or shutters, railing=(upper == "tall"), flowerbox=flowers)')
rep('    dwid = 3.6\n', '    dwid = 4.6 if door_style == "double" else 3.6\n')

a = s.index("        else:\n            # arched shop door in a brick surround")
b = s.index('        box(o, "Shopfront", (b, gtop / 2 - fasc / 2, zf - 0.25), 0.5, gtop - fasc, 0.5, tris_out=sf)        # post between bays')
s = s[:a] + r'''        else:
            dh = 7.0; cxd = (a + b) / 2
            if door_style == "arched":
                # arched shop door in a brick surround (after Shannon's low-poly bakery references)
                hr = dh - dwid / 2
                opening = arch_profile(cxd, 0.0, dwid, hr)
                brick = []
                extrude_ring(o, "Brick", rect_profile_n(cxd, -0.1, dwid + 1.6, bay_top + 0.1), opening, "z", zf - 0.55, zf + 0.05, tris_out=brick)
                extrude_ring(o, "Brick", arch_profile(cxd, -0.1, dwid + 0.9, hr), opening, "z", zf - 0.85, zf - 0.5, tris_out=brick)
                o.add_flat("Brick", brick)
                lw = dwid - 0.2; leaf = arch_profile(cxd, 0.0, lw, hr - 0.1)
                gw, gy0 = 2.4, 3.0; ghr = (dh - 0.4) - gy0 - gw / 2
                glass = arch_profile(cxd, gy0, gw, ghr)
                extrude_ring(o, "DoorShop", leaf, glass, "z", zf - 0.2, zf + 0.05)
                box(o, "DoorShop", (cxd, 1.5, zf - 0.26), lw - 0.8, 2.0, 0.12)
                box(o, "DoorShop", (cxd, gy0 - 0.15, zf - 0.26), lw - 0.3, 0.3, 0.12)
                extrude(o, "GlassDoor", glass, "z", zf - 0.12, zf - 0.06, tris_out=gt)
                for dx in (-1.0, -0.5, 0.0, 0.5, 1.0):
                    ytop = gy0 + ghr + math.sqrt(max((gw / 2) ** 2 - dx * dx, 0.0)) - 0.12
                    box(o, "Iron", (cxd + dx, (gy0 + ytop) / 2, zf - 0.19), 0.08, ytop - gy0, 0.08, tris_out=it)
                for yy in (gy0 + 1.1, gy0 + 2.2):
                    box(o, "Iron", (cxd, yy, zf - 0.19), gw, 0.08, 0.08, tris_out=it)
                for dx in (-0.75, -0.25, 0.25, 0.75):
                    box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.34, 0.34, 0.06, tris_out=it)
                    box(o, "Iron", (cxd + dx, gy0 + 0.5, zf - 0.19), 0.2, 0.2, 0.09, tris_out=it)
                box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.42), 0.14, 1.2, 0.14, tris_out=br)
                box(o, "Brass", (cxd + lw * 0.36, 3.6, zf - 0.3), 0.34, 0.6, 0.1, tris_out=br)
            elif door_style == "panel":
                # panelled wooden door in a stone surround, with a transom light above
                extrude_ring(o, "Trim", rect_profile(cxd, -0.1, dwid + 1.4, bay_top + 0.1), rect_profile(cxd, 0.0, dwid, bay_top - 0.35), "z", zf - 0.55, zf + 0.05, tris_out=tt)
                box(o, "Trim", (cxd, dh + 0.15, zf - 0.45), dwid + 0.2, 0.3, 0.9, tris_out=tt)                       # transom bar
                box(o, "GlassDoor", (cxd, dh + 0.3 + (bay_top - 0.35 - dh - 0.3) / 2, zf - 0.08), dwid, bay_top - 0.35 - dh - 0.3, 0.08, tris_out=gt)
                box(o, "Trim", (cxd, dh + 0.3 + (bay_top - 0.35 - dh - 0.3) / 2, zf - 0.14), 0.1, bay_top - 0.35 - dh - 0.3, 0.06, tris_out=tt)
                lw = dwid - 0.2
                box(o, "DoorShop", (cxd, dh / 2 - 0.05, zf - 0.14), lw, dh - 0.3, 0.28)
                for sgn in (-1, 1):                                                                              # two glazed upper panels
                    box(o, "GlassDoor", (cxd + sgn * lw * 0.24, dh * 0.7, zf - 0.3), lw * 0.34, 2.2, 0.06, tris_out=gt)
                    box(o, "Trim", (cxd + sgn * lw * 0.24, dh * 0.7, zf - 0.32), lw * 0.34 + 0.16, 2.36, 0.02, tris_out=tt)
                    box(o, "DoorShop", (cxd + sgn * lw * 0.24, 1.9, zf - 0.34), lw * 0.34, 2.4, 0.12)                # raised lower panels
                box(o, "Brass", (cxd + lw * 0.38, 3.4, zf - 0.44), 0.16, 0.16, 0.3, tris_out=br)                     # knob
                box(o, "Brass", (cxd + lw * 0.38, 3.4, zf - 0.32), 0.34, 0.5, 0.06, tris_out=br)
                box(o, "Brass", (cxd, 0.4, zf - 0.3), lw - 0.4, 0.5, 0.05, tris_out=br)                            # kick plate
            else:
                # glazed double door with slim painted frames, like the cafe door in the references
                for sgn in (-1, 1):
                    box(o, "Shopfront", (cxd + sgn * (dwid / 2 + 0.2), dh / 2 + 0.6, zf - 0.4), 0.4, dh + 1.2, 0.8, tris_out=sf)
                box(o, "Shopfront", (cxd, bay_top - 0.15, zf - 0.4), dwid + 0.8, 0.3, 0.8, tris_out=sf)
                box(o, "Shopfront", (cxd, dh + 0.15, zf - 0.3), dwid, 0.3, 0.6, tris_out=sf)                     # transom bar
                box(o, "GlassDoor", (cxd, dh + 0.3 + (bay_top - 0.3 - dh - 0.3) / 2, zf - 0.08), dwid, bay_top - 0.3 - dh - 0.3, 0.08, tris_out=gt)
                lw = dwid / 2 - 0.08
                for sgn in (-1, 1):
                    cx2 = cxd + sgn * (lw / 2 + 0.04)
                    leaf = rect_profile(cx2, 0.0, lw, dh - 0.05)
                    pane = rect_profile(cx2, 1.7, lw - 0.5, dh - 2.2)
                    extrude_ring(o, "DoorShop", leaf, pane, "z", zf - 0.2, zf + 0.05)
                    extrude(o, "GlassDoor", pane, "z", zf - 0.12, zf - 0.06, tris_out=gt)
                    box(o, "DoorShop", (cx2, 0.85, zf - 0.26), lw - 0.5, 1.0, 0.12)                                 # lower panel
                    box(o, "Brass", (cxd + sgn * 0.35, 3.6, zf - 0.42), 0.12, 1.4, 0.12, tris_out=br)            # handles by the meeting edge
            box(o, "Trim", (cxd, 0.08, zf - 0.7), dwid + 0.8, 0.16, 1.3, tris_out=tt)                         # threshold
            # a little of the shop behind the door glass
            zi0, zi1 = zf + 0.1, zf + 4.0; zc = (zi0 + zi1) / 2; dep = zi1 - zi0
            box(o, "Interior", (cxd, 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            box(o, "Interior", (cxd, dh / 2, zi1 - 0.05), dwid, dh, 0.1, tris_out=ii)
            box(o, "Interior", (cxd, dh - 0.05, zc), dwid, 0.1, dep, tris_out=ii)
            for xx in (cxd - dwid / 2 + 0.05, cxd + dwid / 2 - 0.05):
                box(o, "Interior", (xx, dh / 2, zc), 0.1, dh, dep, tris_out=ii)
''' + s[b:]

rep('''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 28.0, 3, "flat", "right", "arch")
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 22.0, 2, "pitched", "centre", "arch", flowers=True)
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 34.0, 3, "flat", "left", "tall")''',
'''    counts["townhouse_a"] = townhouse("townhouse_a", 1, 28.0, 3, "flat", "right", "arch", door_style="arched")
    counts["townhouse_b"] = townhouse("townhouse_b", 2, 22.0, 2, "pitched", "centre", "arch", flowers=True, door_style="double")
    counts["townhouse_c"] = townhouse("townhouse_c", 3, 34.0, 3, "flat", "left", "tall", door_style="panel")
    counts["townhouse_d"] = townhouse("townhouse_d", 4, 18.0, 3, "pitched", "left", "arch", door_style="arched", shutters=True)
    counts["townhouse_e"] = townhouse("townhouse_e", 5, 26.0, 2, "flat", "right", "tall", door_style="double")''')
p.write_text(s, encoding="utf-8"); print("townhouse v5 written")
