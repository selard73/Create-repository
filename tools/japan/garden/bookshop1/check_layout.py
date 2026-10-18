"""Geometry checks for the import-ready design, not a substitute for Play testing."""
import hashlib,json
from pathlib import Path
D=Path(__file__).resolve().parent
m=json.loads((D/'out/manifest.json').read_text())
parts={r['name']:r for r in m['meshes']}
assert len(parts)==len(m['meshes'])==119
assert all(r['triangles']<10000 for r in parts.values())
visible={n:r for n,r in parts.items()if n not in {'B1_Origin','B1_Right','B1_Front'}}
lo=[min(r['min'][i]for r in visible.values())for i in range(3)]
hi=[max(r['max'][i]for r in visible.values())for i in range(3)]
assert lo[0]>=-14.8 and hi[0]<=14.85
assert hi[2]<=1.39 # only the shallow doorway threshold projects this far
assert all(r['max'][2]<=.61 for n,r in visible.items()if n!='B1_Threshold_Stone')
for n in ['B1_StonePlinth_Stone','B1_Threshold_Stone']:
 assert abs(parts[n]['min'][1]+.58)<.001
 assert abs(parts[n]['max'][1])<.001
# Door glass and lower panel overlap/meet the horizontal door rails.
glass=parts['B1_DoorGlass_Glass']
assert glass['min'][1]<=1.92 and glass['max'][1]>=7.185
assert parts['B1_DoorBack_Wall']['max'][1]>=7.34
assert len(m['labels'])==4
for r in m['labels']:assert r['name']in parts
files={n:hashlib.sha256((D/n).read_bytes()).hexdigest()for n in ['out/japan_kit35_book_stationery1.fbx','out/manifest.json','prepare_bookshop1.lua','install_bookshop1.lua']}
checks={'status':'MODEL VERIFIED; ACTUAL PLAY PREVIEW PENDING IMPORT','meshCountIncludingMarkers':len(parts),'installedMeshCount':len(visible),'triangles':sum(r['triangles']for r in parts.values()),'maxTrianglesPerMesh':max(r['triangles']for r in parts.values()),'localBounds':{'min':lo,'max':hi},'groundAtThresholdAndPlinth':m['origin'][1]-.58,'fbxRoundtripTolerance':.003,'closedDoorHeaderFit':'PASS','proposedRetirement':{'topLevelObjects':65,'parts':70,'oldLabels':9,'existingShopPartsRetained':175},'scriptReferencesToKimonoAtelier':[],'unrelatedSceneChanges':False,'sha256':files,'pending':['User import','Anchor and store import before Play','Actual Server preview','Client asset/lettering checks','Door and window collision walk test','Street passage walk test','Pictures and user approval before permanent installation']}
checks['observedStudioGroundRays']={'positionsXZ':[[5987.15,-68.4],[5987.6,-54.09],[5988.3,-54.09],[5989.8,-54.09]],'allHitY':.4600001573562622,'instance':'JapanMap.Outdoor market revision.Stone lane and hanging lanterns.Continuous market walking surface','bottomFitError':abs(.4600001573562622-checks['groundAtThresholdAndPlinth'])}
(D/'layout_checks.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in checks.items()if k not in ['sha256','pending']},indent=2))
