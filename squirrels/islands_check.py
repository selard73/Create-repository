# islands_check.py - Blender (background): the separate pieces (face islands) of a squirrel's exported mesh, with their size
# and where they sit, to find a stray fragment (Shannon, Sep 27: "something weird on the ground by the squirrel in front
# of the bookstore" - the philosopher squirrel is one MeshPart whose box is 3.7 studs deep).
# Usage: blender --background --python islands_check.py -- <fbx path>
import sys
import bpy
import bmesh

path = sys.argv[sys.argv.index("--") + 1]
OUT = open(path + ".islands.txt", "w")
_print = print
def print(*a):
    OUT.write(" ".join(str(x) for x in a) + "\n"); OUT.flush()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path)
for ob in bpy.context.scene.objects:
    if ob.type != "MESH":
        continue
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    mw = ob.matrix_world
    seen, islands = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, comp = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            comp.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        islands.append(comp)
    allv = [mw @ v.co for v in bm.verts]
    lo = [min(v[i] for v in allv) for i in range(3)]
    hi = [max(v[i] for v in allv) for i in range(3)]
    print("QQISL object %s: %d faces, %d islands, bbox %s .. %s" % (ob.name, len(bm.faces), len(islands), [round(x, 3) for x in lo], [round(x, 3) for x in hi]))
    islands.sort(key=len)
    for comp in islands[:12]:
        vs = {v for f in comp for v in f.verts}
        pts = [mw @ v.co for v in vs]
        a = [min(p[i] for p in pts) for i in range(3)]
        b = [max(p[i] for p in pts) for i in range(3)]
        c = [round((a[i] + b[i]) / 2, 3) for i in range(3)]
        s = [round(b[i] - a[i], 3) for i in range(3)]
        print("QQISL   island %d faces, centre %s size %s" % (len(comp), c, s))
    print("QQISL   biggest island %d faces" % len(islands[-1]))
    bm.free()
OUT.write("DONE\n"); OUT.close()
