import bpy,bmesh,json,math,traceback
from pathlib import Path
from mathutils.geometry import tessellate_polygon
root=Path(__file__).resolve().parent
try:
 d=json.loads((root/"repaired_bank_mesh.json").read_text())
 bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
 crest=sorted([v for v in d["vertices"] if abs(v[1]-1.525)<.0001],key=lambda v:math.atan2(v[2],v[0]))
 assert len(crest)==120,len(crest)
 ang=[math.atan2(v[2],v[0]) for v in crest]
 groups=[[] for a in ang]
 for v in d["vertices"]:
  a=math.atan2(v[2],v[0])
  k=min(range(120),key=lambda i:abs(math.atan2(math.sin(a-ang[i]),math.cos(a-ang[i]))))
  groups[k].append(v)
 assert all(len(g)==7 for g in groups),[len(g) for g in groups]
 for g in groups:g.sort(key=lambda v:v[0]**2+v[2]**2)
 rows=[]
 for sector in range(12):
  columns=[groups[(sector*10+j)%120] for j in range(11)]
  verts=[(v[0],-v[2],v[1]) for col in columns for v in col]
  faces=[]
  for j in range(10):
   for k in range(6):faces.append((j*7+k,j*7+k+1,(j+1)*7+k+1,(j+1)*7+k))
   faces.append((j*7,(j+1)*7,(j+1)*7+6,j*7+6))
  faces.append(tuple(range(7)))
  faces.append(tuple(range(70,77)))
  name="JP_RiceCollision_%02d"%(sector+1)
  me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
  bm=bmesh.new();bm.from_mesh(me)
  bmesh.ops.triangulate(bm,faces=list(bm.faces))
  bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
  assert all(e.is_manifold for e in bm.edges)
  vol=bm.calc_volume(signed=True)
  if vol<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces));vol=-vol
  assert vol>0
  bm.to_mesh(me);bm.free()
  ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
  lo=[min(v[i] for v in verts) for i in range(3)];hi=[max(v[i] for v in verts) for i in range(3)]
  c=[(lo[i]+hi[i])/2 for i in range(3)]
  rows.append({"name":name,"center":[c[0],c[2],-c[1]],"size":[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]],"vertices":len(me.vertices),"triangles":len(me.polygons),"volume":vol})
 bpy.ops.object.select_all(action="SELECT")
 bpy.ops.wm.save_as_mainfile(filepath=str(root/"rice_bank_collision1.blend"))
 bpy.ops.export_scene.fbx(filepath=str(root/"rice_bank_collision1.fbx"),use_selection=True,axis_forward="-Z",axis_up="Y",apply_scale_options="FBX_SCALE_ALL",bake_space_transform=True,colors_type="NONE")
 (root/"collision_sections.json").write_text(json.dumps(rows,indent=2))
 (root/"collision_build.log").write_text(json.dumps(rows)+"\nRICECOLLISION_DONE")
except Exception:(root/"collision_build.log").write_text(traceback.format_exc()+"\nRICECOLLISION_FAILED")
