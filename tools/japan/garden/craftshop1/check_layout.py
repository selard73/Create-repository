from pathlib import Path
import json, math
D=Path(__file__).resolve().parent
c=json.loads((D/'out/manifest.json').read_text())
parts=[p for p in c['meshes']if p['name']not in {'C1_Origin','C1_Right','C1_Front'}]
assert len(parts)==157 and len({p['name']for p in parts})==157
assert max(p['triangles']for p in parts)<10000
assert all(p['min'][i]<p['max'][i]for p in parts for i in range(3))
bounds={'min':[min(p['min'][i]for p in parts)for i in range(3)],'max':[max(p['max'][i]for p in parts)for i in range(3)]}
assert bounds['min'][0]>-16 and bounds['max'][0]<16
assert bounds['min'][2]>-18.8 and bounds['max'][2]<1.3
threshold=next(p for p in parts if p['name']=='C1_Threshold_Stone')
assert abs(threshold['min'][1]+c['origin'][1]-.460000157)<.002
colliders={'C1_WindowBase','C1_WindowDeck','C1_Glazing0','C1_Glazing1','C1_Glazing2','C1_Threshold','C1_WorkTop','C1_StockCabinet','C1_CabinetTop','C1_LeftShelf0','C1_LeftShelf1','C1_BackUmbrellaA','C1_BackUmbrellaB'}
# The planned walking corridor is tested against actual imported-mesh AABBs,
# expanded for a 1.1-stud character radius. This is a layout check, not a Play test.
route=[(-11.6,1.5),(-11.6,-6.0),(-6.8,-6.0),(-2,-9.5),(3.8,-9.5),(3.8,-13),(-6,-13)]
for a,b in zip(route,route[1:]):
 for t in [i/50 for i in range(51)]:
  x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t
  for p in parts:
   group=p['name'].rsplit('_',1)[0]
   if group not in colliders or group=='C1_Threshold':continue
   lo,hi=p['min'],p['max']
   if hi[1]<.2 or lo[1]>6.5:continue
   assert not(lo[0]-1.1<x<hi[0]+1.1 and lo[2]-1.1<z<hi[2]+1.1),(a,b,p['name'])
check={'stage':'Blender geometry only; Roblox asset appearance and walking still require imported Play preview','sourceMeshes':160,'placedMeshes':len(parts),'triangles':sum(p['triangles']for p in c['meshes']),'maxTriangles':max(p['triangles']for p in parts),'bounds':bounds,'thresholdBottomWorldY':threshold['min'][1]+c['origin'][1],'observedLaneY':.460000157,'plannedWalkingRouteXZ':route,'characterRadius':1.1,'entryClearWidth':4.525,'entryHeaderClearHeight':7.205,'ceilingLocalBottom':8.185,'openUmbrellaTopMax':7.77,'preservedOriginalParts':130,'retiredFixtureRoots':131,'retiredFixtureParts':136,'retiredLabels':14,'otherPremises':'Paper umbrella craft replacement awaiting Shannon preference; not altered by this installer'}
(D/'layout_checks.json').write_text(json.dumps(check,indent=2),encoding='utf8')
print(json.dumps(check,indent=2))
