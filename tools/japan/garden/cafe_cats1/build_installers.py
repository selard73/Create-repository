from pathlib import Path
import json,math,numpy as np
D=Path(__file__).resolve().parent
rows=json.loads((D/'out'/'manifest.json').read_text());cfg=[];fits=[]
for c in rows:
    cfg.append({k:c[k] for k in ['name','label','mesh_name','source_origin','position','yaw','spot']})
    points=[];t=math.radians(c['yaw'])
    vertices=np.load(D/c['name']/'points.npy');scale=c['height']/(vertices[:,2].max()-vertices[:,2].min())
    for x,y,_ in vertices*scale:
        z=-y;points.append((math.cos(t)*x+math.sin(t)*z,-math.sin(t)*x+math.cos(t)*z))
    bounds=[[float(min(p[k] for p in points)),float(max(p[k] for p in points))] for k in range(2)]
    usable=[4.4,2.7] if c['spot'].startswith('Window') else [4,3.3] if c['spot']=='CubbyTop' else [3.1,3.2]
    # Each complete mesh lies within its furniture pad rectangle and the room envelope.
    for k in range(2):assert bounds[k][0]>=-usable[k]/2-.025 and bounds[k][1]<=usable[k]/2+.025,(c['name'],bounds,usable)
    assert c['position'][0]+bounds[0][1]<12.45
    assert c['position'][1]+c['height']<8.0
    fits.append({'name':c['name'],'spot':c['spot'],'height':c['height'],'horizontal_bounds_on_pad':bounds,'pad_size':usable,'within_pad':True})
(D/'out'/'placement_checks.json').write_text(json.dumps(fits,indent=2))
client=(D/'catcafe_cats1_client.lua').read_text()
source=(D/'catcafe_cats1_template.lua').read_text().replace('__CONFIG__',json.dumps(cfg,separators=(',',':'))).replace('__CLIENT__',client)
(D/'catcafe_cats1.lua').write_text(source)
print('6/6 cats fit their pad rectangles and room; installer built')
