"""Check model dimensions before user import; actual avatar tests remain required in Play."""
from pathlib import Path
import json,math
D=Path(__file__).resolve().parent;C=json.loads((D/'out/manifest.json').read_text());M={v['name']:v for v in C['meshes']}
assert len(M)==len(C['meshes'])
assert len(C['seats'])==6
for s in C['seats']:
 i=int(s['name'].replace('CounterSeat',''))-1
 chair=M['S1_Chair'+str(i)+'_Indigo']
 assert abs(s['position'][1]-chair['max'][1])<.003
 assert chair['min'][0]<s['position'][0]<chair['max'][0]
 assert chair['min'][2]<s['position'][2]<chair['max'][2]
assert M['S1_StepLower_Stone']['min'][1]+C['origin'][1]<.02
assert M['S1_StepUpper_Stone']['min'][1]+C['origin'][1]<.02
for r in M.values():assert r['triangles']<10000
clear_staff=M['S1_BarTop_Hinoki']['min'][2]-M['S1_RearTop_Hinoki']['max'][2]
clear_front=-max(M['S1_Chair'+str(i)+'_Walnut']['max'][2]for i in range(6))-.15
clear_right=13.165-M['S1_BarTop_Hinoki']['max'][0]
curtain=min(r['min'][1]for n,r in M.items()if n.startswith('S1_Noren'))
assert clear_staff>4.1 and clear_front>4.25 and clear_right>5.5 and curtain>6.5
out={'status':'BLENDER MODEL ONLY; Studio import and Play verification pending','meshes_with_markers':len(M),'triangles':sum(r['triangles']for r in M.values()),'highest_mesh_triangles':max(r['triangles']for r in M.values()),'six_seats_aligned_to_cushion_tops':True,'grounded_steps':True,'staff_aisle_studs':clear_staff,'front_aisle_studs':clear_front,'right_side_route_studs':clear_right,'noren_bottom_above_floor_origin':curtain,'roundtrip':'all names and bounds within .003; see Blender log','real_walk_and_seat_tests':'PENDING IMPORT'}
(D/'layout_checks.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out))
