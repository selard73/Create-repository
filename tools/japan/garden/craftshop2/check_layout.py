from pathlib import Path
import json, math
D=Path(__file__).resolve().parent
c=json.loads((D/'out/manifest.json').read_text())
parts=[p for p in c['meshes']if p['name']not in {'C2_Origin','C2_Right','C2_Front'}]
assert len(parts)>157 and len({p['name']for p in parts})==len(parts)
assert max(p['triangles']for p in parts)<10000
assert all(p['min'][i]<p['max'][i]for p in parts for i in range(3))
bounds={'min':[min(p['min'][i]for p in parts)for i in range(3)],'max':[max(p['max'][i]for p in parts)for i in range(3)]}
assert bounds['min'][0]>-16 and bounds['max'][0]<16
assert bounds['min'][2]>-18.8 and bounds['max'][2]<2.1
threshold=next(p for p in parts if p['name']=='C2_Threshold_Stone')
assert abs(threshold['min'][1]+c['origin'][1]-.460000157)<.002
colliders={'C2_WindowBase','C2_WindowDeck','C2_Glazing0','C2_Glazing1','C2_Glazing2','C2_Threshold','C2_WorkTop','C2_StockCabinet','C2_CabinetTop','C2_LeftShelf0','C2_LeftShelf1','C2_LeftShelf2','C2_BackUmbrellaA','C2_BackUmbrellaB','C2_BackUmbrellaC','C2_BackShelf0','C2_BackShelf1','C2_BackShelf2','C2_BackCabinetBase'}
# The planned walking corridor is tested against actual imported-mesh AABBs,
# expanded for a 1.1-stud character radius. This is a layout check, not a Play test.
route=[(-11.6,1.5),(-11.6,-6.0),(-6.8,-6.0),(-2,-9.5),(3.8,-9.5),(3.8,-13),(-6,-13)]
for a,b in zip(route,route[1:]):
 for t in [i/50 for i in range(51)]:
  x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t
  for p in parts:
   group=p['name'].rsplit('_',1)[0]
   if group not in colliders or group=='C2_Threshold':continue
   lo,hi=p['min'],p['max']
   if hi[1]<.2 or lo[1]>6.5:continue
   assert not(lo[0]-1.1<x<hi[0]+1.1 and lo[2]-1.1<z<hi[2]+1.1),(a,b,p['name'])
check={'stage':'Blender geometry only; Roblox asset appearance and walking still require imported Play preview','sourceMeshes':len(c['meshes']),'placedMeshes':len(parts),'triangles':sum(p['triangles']for p in c['meshes']),'maxTriangles':max(p['triangles']for p in parts),'bounds':bounds,'thresholdBottomWorldY':threshold['min'][1]+c['origin'][1],'observedLaneY':.460000157,'plannedWalkingRouteXZ':route,'characterRadius':1.1,'entryClearWidth':4.525,'entryHeaderClearHeight':7.205,'ceilingLocalBottom':8.185,'openUmbrellaTopMax':7.77,'preservedOriginalParts':130,'retiredFixtureRoots':131,'retiredFixtureParts':136,'retiredLabels':14,'otherPremises':'Shannon explicitly deferred replacement; Paper umbrella craft unchanged','referenceFiles':['9.png','7.png','8.png','4.png','3.png','0.png'],'paint':'Original curved thin-mesh floral/leaf patterns, no copied image pixels or branding','previewLimit':'Materials, paper illumination and existing shell are approximations in Blender; verify in Roblox after import'}
(D/'layout_checks.json').write_text(json.dumps(check,indent=2),encoding='utf8')
print(json.dumps(check,indent=2))
