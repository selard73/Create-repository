"""patch_falls.py - one-off patch (Sep 30 2026, evening): the gorge's end becomes a WATERFALL, not a cave.
Swaps gen_gorge_real.py's headwall-and-cave block for the cliff-and-falls block in falls_block.py.txt (everything
between the two '# ====' marker lines). The other edits (terrain preview, water, materials, writing) were made
directly."""
import os
HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, "gen_gorge_real.py")
g = open(path, encoding="utf-8").read()
m0 = "# ================================================================ the headwall and its cave ================"
m1 = "# ================================================================ the aqueduct ================"
if m0 in g:
    i0, i1 = g.index(m0), g.index(m1)
    assert i0 < i1
    block = open(os.path.join(HERE, "falls_block.py.txt"), encoding="utf-8").read()
    g = g[:i0] + block + g[i1:]
    open(path, "w", encoding="utf-8", newline="\n").write(g)
    print("swapped the headwall block for the falls block")
else:
    print("no headwall block found (already patched?)")
