import bpy
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\boat\prep_v2\boat.blend")
V=[v.co.copy() for v in bpy.data.objects["Boat"].data.vertices]
out=[]
for y0 in (-3.3,-3.1,-2.9,-2.7):
    s=[v for v in V if abs(v.y-y0)<0.06 and v.x<0]           # the -x side (= +X in Roblox, the jetty side)
    top=max(v.z for v in s)
    rim=[v for v in s if v.z>top-0.35]
    xo=min(v.x for v in rim)                                  # outermost at the rim
    band=[v for v in s if abs(v.x-xo)<0.06]
    out.append("y %.1f top %.3f outer_x %.3f outer band z %.3f..%.3f" % (y0, top, xo, min(v.z for v in band), max(v.z for v in band)))
open(r"C:\Users\slard\roblox-props\boat\fit_measure2.txt","w").write("\n".join(out))