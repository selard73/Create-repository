import bpy
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\boat\prep_v2\boat.blend")
V=[v.co.copy() for v in bpy.data.objects["Boat"].data.vertices]
out=[]
for y0 in (1.7,1.9,2.1,2.3,2.5,2.7):
    s=[v for v in V if abs(v.y-y0)<0.05 and v.x<-0.8 and v.z>1.6]
    if not s: continue
    top=max(v.z for v in s)
    flat=[v for v in s if v.z>top-0.03]
    out.append("y %.1f top %.3f flat x %.3f..%.3f  outer %.3f" % (y0, top, min(v.x for v in flat), max(v.x for v in flat), min(v.x for v in s)))
open(r"C:\Users\slard\roblox-props\boat\fit_measure3.txt","w").write("\n".join(out))