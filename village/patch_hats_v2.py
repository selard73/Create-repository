"""Hat shop v2: six recognisable hat styles on head forms at the glass, bands in contrasting colours, stacked hat
boxes, a back shelf. (Shannon: 'the hat store does not look good' - the old hats were tiny blobs on tall poles.)"""
from pathlib import Path
p = Path(__file__).parent / "gen_village.py"
s = p.read_text(encoding="utf-8")
d0 = s.index("def disp_hats(name, seed):")
d1 = s.index("def disp_cheese(name, seed):")
s = s[:d0] + r'''def _hat(o, k, x, y, z, style, rnd):
    """A hat sitting at height y (its brim), centred on (x, z); its own Hat<k> and Band<k> pieces."""
    c = (x, 0, z); ht, bt = [], []
    def crown(rings, cap=True): tube(o, f"Hat{k}", rings, (x, y + 0.5, z), cap_top=cap, tris_out=ht)
    def brim(r_out, r_in, y0, y1): tube(o, f"Hat{k}", [ring(c, r_in, y0, 12), ring(c, r_out, y1, 12)], (x, y0, z), tris_out=ht)
    def disc(r, y0, h): tube(o, f"Hat{k}", [ring(c, r, y0, 12), ring(c, r, y0 + h, 12)], (x, y0 + h / 2, z), cap_top=True, cap_bottom=True, tris_out=ht)
    def band(r, y0, h=0.22): tube(o, f"Band{k}", [ring(c, r, y0, 12), ring(c, r, y0 + h, 12)], (x, y0 + h / 2, z), tris_out=bt)
    if style == "top":
        disc(1.05, y, 0.08)
        crown([ring(c, 0.64, y + 0.08, 12), ring(c, 0.62, y + 0.7, 12), ring(c, 0.68, y + 1.4, 12)])
        band(0.66, y + 0.1)
    elif style == "boater":
        disc(1.3, y, 0.07)
        crown([ring(c, 0.74, y + 0.07, 12), ring(c, 0.74, y + 0.55, 12)])
        band(0.76, y + 0.1, 0.2)
    elif style == "cloche":
        disc(0.98, y, 0.06)
        crown([ring(c, 0.76, y + 0.06, 12), ring(c, 0.74, y + 0.5, 12), ring(c, 0.55, y + 0.85, 12), ring(c, 0.22, y + 1.02, 12)])
        band(0.77, y + 0.12, 0.2)
    elif style == "sun":
        disc(1.7, y, 0.06)
        crown([ring(c, 0.78, y + 0.06, 12), ring(c, 0.74, y + 0.45, 12), ring(c, 0.5, y + 0.7, 12)])
        band(0.8, y + 0.1, 0.2)
        icoblob(o, f"Band{k}", (x + 0.7, y + 0.25, z + 0.35), 0.16, rnd, 0.1, tris_out=bt)     # a bow
        icoblob(o, f"Band{k}", (x + 0.95, y + 0.25, z + 0.2), 0.16, rnd, 0.1, tris_out=bt)
    elif style == "bowler":
        brim(1.08, 0.72, y + 0.12, y)
        disc(0.74, y, 0.1)
        crown([ring(c, 0.72, y + 0.1, 12), ring(c, 0.7, y + 0.45, 12), ring(c, 0.52, y + 0.75, 12), ring(c, 0.2, y + 0.9, 12)])
        band(0.73, y + 0.12, 0.2)
    else:  # beret
        icoblob(o, f"Hat{k}", (x, y + 0.22, z), 0.95, rnd, 0.05, (1.0, 0.32, 1.0), tris_out=ht)
        box(o, f"Hat{k}", (x, y + 0.6, z), 0.08, 0.2, 0.08, tris_out=ht)
    o.add_flat(f"Hat{k}", ht)
    if bt: o.add_flat(f"Band{k}", bt)

def _head_form(o, x, z, h, po, hd):
    """Stand: base disc, pole and a pale head block; returns the height where the hat brim sits."""
    tube(o, "Post", [ring((x, 0, z), 0.55, 0, 8), ring((x, 0, z), 0.55, 0.1, 8)], (x, 0.05, z), cap_top=True, cap_bottom=True, tris_out=po)
    tube(o, "Post", [ring((x, 0, z), 0.07, 0.1, 6), ring((x, 0, z), 0.07, h, 6)], (x, h / 2, z), tris_out=po)
    tube(o, "Head", [ring((x, 0, z), 0.3, h, 10), ring((x, 0, z), 0.62, h + 0.5, 10), ring((x, 0, z), 0.62, h + 1.0, 10), ring((x, 0, z), 0.3, h + 1.35, 10)], (x, h + 0.7, z), cap_top=True, cap_bottom=True, tris_out=hd)
    return h + 1.1

def _hat_box(o, k, x, y, z, r, h):
    tube(o, f"Wrap{k}", [ring((x, 0, z), r, y, 12), ring((x, 0, z), r, y + h, 12)], (x, y + h / 2, z), cap_top=True, cap_bottom=True)
    tube(o, f"Wrap{k + 1}", [ring((x, 0, z), r + 0.05, y + h - 0.18, 12), ring((x, 0, z), r + 0.05, y + h + 0.02, 12)], (x, y + h, z), cap_top=True, tris_out=None)

def disp_hats(name, seed):
    rnd = random.Random(seed); o = Obj(); po, hd, pt = [], [], []
    styles = ["top", "sun", "cloche", "boater", "bowler", "beret"]
    # front row at the glass: three hats on short head forms, second row taller behind
    k = 0
    for (x, z, h, st) in ((-1.9, -1.4, 1.5, "sun"), (0.0, -1.3, 1.3, "top"), (1.9, -1.4, 1.6, "cloche"),
                          (-1.0, 0.3, 2.6, "boater"), (1.0, 0.3, 2.5, "bowler")):
        k += 1
        y = _head_form(o, x, z, h, po, hd)
        _hat(o, k, x, y, z, st, rnd)
    # stacked hat boxes at the sides
    _hat_box(o, 21, -2.4, 0.0, 0.8, 0.7, 0.75); _hat_box(o, 23, -2.35, 0.77, 0.85, 0.6, 0.6)
    _hat_box(o, 25, 2.4, 0.0, 0.9, 0.65, 0.7)
    # back shelf with a beret, a boater box and two more hats
    _shelf_unit(o, pt, w=5.6, d=1.1, z=1.95, levels=(3.4,), top=4.6, name="Plank")
    k += 1; _hat(o, k, -1.9, 3.46, 1.95, "beret", rnd)
    k += 1; _hat(o, k, 0.0, 3.46, 1.95, "sun", rnd)
    k += 1; _hat(o, k, 1.9, 3.46, 1.95, "boater", rnd)
    _hat_box(o, 27, -1.9, 0.0, 1.95, 0.6, 0.6); _hat_box(o, 29, 1.9, 0.0, 1.95, 0.55, 0.5)
    o.add_flat("Post", po); o.add_flat("Head", hd); o.add_flat("Plank", pt)
    return o.write(OUT / f"{name}.obj")

''' + s[d1:]
p.write_text(s, encoding="utf-8"); print("hats v2 written")
