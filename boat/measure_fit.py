import bpy
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\slard\roblox-props\boat\prep_v2\boat.blend")
b=bpy.data.objects["Boat"]; V=[v.co.copy() for v in b.data.vertices]
out=[]
post=[v for v in V if v.y < -3.55 and v.z > 1.85]
out.append("POST n=%d x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f" % (len(post), min(v.x for v in post), max(v.x for v in post), min(v.y for v in post), max(v.y for v in post), min(v.z for v in post), max(v.z for v in post)))
for lo,hi in ((-3.6,-3.3),(-3.3,-3.0),(-3.0,-2.7)):
    s=[v for v in V if lo<=v.y<hi and v.z>1.7]
    if s: out.append("BOWRIM y %.1f..%.1f zmax %.3f xmax %.3f" % (lo,hi,max(v.z for v in s),max(abs(v.x) for v in s)))
for lo,hi in ((2.6,2.9),(2.9,3.2),(3.2,3.5)):
    s=[v for v in V if lo<=v.y<hi and abs(v.x)>1.2 and v.z>1.5]
    if s:
        top=max(v.z for v in s); xs=[abs(v.x) for v in s if v.z>top-0.12]
        out.append("STERNRIM y %.1f..%.1f top %.3f |x| %.3f..%.3f" % (lo,hi,top,min(xs),max(xs)))
s=[v for v in V if 3.3<=v.y and v.z>1.5]
out.append("TRANSOM ymax %.3f" % max(v.y for v in s))
for lo,hi in ((-0.3,0.3),):
    s=[v for v in V if lo<=v.y<hi and v.z>1.5]
    top=max(v.z for v in s); xs=[abs(v.x) for v in s if v.z>top-0.12]
    out.append("MIDRIM top %.3f |x| %.3f..%.3f" % (top,min(xs),max(xs)))
open(r"C:\Users\slard\roblox-props\boat\fit_measure.txt","w").write("\n".join(out))