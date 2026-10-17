"""Build the design-review scene from the new shell and existing approved native assets.
Cats are baked to static rest pose ONLY in this Blender review scene; Roblox rigs are reused intact.
"""
from pathlib import Path
import bpy,json,math,traceback,os
from mathutils import Matrix,Vector
D=Path(__file__).resolve().parent;OUT=D/'out';LOG=OUT/'review_build_log.txt'
WORK=Path(os.environ.get('JAPAN_CAFE_REVIEW_ASSETS',str(D.parent)))
if not(WORK/'cat_cafe1/out_catcafe1/cat_cafe1_review.blend').exists():WORK=Path(r'C:\Users\slard\Documents\Codex\2026-10-17\we\work')
LAY=json.loads((D/'layout.json').read_text())
def P(p):return(p[0],-p[2],p[1])
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf-8')as f:f.write(str(s)+'\n')
def append_objects(path,filter):
 with bpy.data.libraries.load(str(path),link=False)as(a,b):b.objects=[n for n in a.objects if filter(n)]
 # Appended FBX children can have an unevaluated matrix_world until their
 # otherwise unlinked parent hierarchy is evaluated. Resolve that hierarchy
 # explicitly before detaching; the furniture source root carries its axis turn.
 def source_world(ob):
  return source_world(ob.parent)@ob.matrix_parent_inverse@ob.matrix_basis if ob.parent else ob.matrix_basis.copy()
 matrices={ob:source_world(ob)for ob in b.objects if ob}
 out=[]
 for ob in b.objects:
  if ob:
   bpy.context.collection.objects.link(ob);ob.parent=None;ob.matrix_world=matrices[ob];ob.hide_render=False;ob.hide_viewport=False;out.append(ob)
 return out
try:
 LOG.write_text('');bpy.ops.wm.open_mainfile(filepath=str(OUT/'cafe_interior2_shell.blend'));bpy.context.preferences.edit.use_global_undo=False
 for n in ['CI2_Origin','CI2_Right','CI2_Front']:bpy.data.objects[n].hide_render=True
 root=bpy.data.objects.get('cafe_interior2')
 for ob in list(root.children):w=ob.matrix_world.copy();ob.parent=None;ob.matrix_world=w
 bpy.data.objects.remove(root,do_unlink=True)
 furniture=append_objects(WORK/'cat_cafe1/out_catcafe1/cat_cafe1_review.blend',lambda n:n.rsplit('_',1)[0]in LAY['groups'])
 for ob in furniture:
  group=ob.name.rsplit('_',1)[0];ob.matrix_world=Matrix.Translation(P(LAY['groups'][group]))@ob.matrix_world
 wall=append_objects(WORK/'catwall1/out/catwall1_source.blend',lambda n:n.startswith('CW1_')and n not in ['CW1_Origin','CW1_Right','CW1_Front'])
 for ob in wall:ob.matrix_world=Matrix.Translation(P(LAY['wallDecorDelta']))@ob.matrix_world
 before=set(bpy.data.objects);bpy.ops.import_scene.fbx(filepath=str(WORK/'cafe_cats3/out/japan_kit27_cat_cafe_cats3.fbx'));imported=set(bpy.data.objects)-before
 specs=json.loads((WORK/'cafe_cats3/out/manifest.json').read_text());specs={c['name']:c for c in specs}
 origin=bpy.data.objects['CC3_Origin'].matrix_world.translation
 right=(bpy.data.objects['CC3_Right'].matrix_world.translation-origin).normalized()
 front=(bpy.data.objects['CC3_Front'].matrix_world.translation-origin).normalized()
 source_frame=Matrix((right,-front,right.cross(-front))).transposed().to_4x4();source_frame.translation=origin
 cats=[]
 for c in LAY['cats']:
  if c.get('outside'):continue
  spec=specs[c['name']];original=bpy.data.objects[spec['mesh_name']]
  mesh=bpy.data.meshes.new_from_object(original.evaluated_get(bpy.context.evaluated_depsgraph_get()),preserve_all_data_layers=True,depsgraph=bpy.context.evaluated_depsgraph_get())
  ob=bpy.data.objects.new('REVIEW_CAT_'+c['name'],mesh);bpy.context.collection.objects.link(ob)
  source=(spec['source_origin'][0]+4,0,3)
  source_matrix=source_frame@Matrix.Translation(P(source))
  delta=Matrix.Translation(P(c['position']))@Matrix.Rotation(math.radians(c['yaw']),4,'Z')@Matrix.Scale(c['scale'],4)@source_matrix.inverted()
  ob.matrix_world=delta@original.matrix_world;cats.append(ob)
 for ob in imported:bpy.data.objects.remove(ob,do_unlink=True)
 # A review-only rendering of the existing menu's SurfaceGui.
 cu=bpy.data.curves.new('menu','FONT');cu.body='TEA & COFFEE';cu.align_x='CENTER';cu.align_y='CENTER';cu.size=.16
 ob=bpy.data.objects.new('REVIEW_MENU',cu);bpy.context.collection.objects.link(ob);ob.location=P((6.85,3.62,-24.61));ob.rotation_euler=(math.pi/2,0,0)
 ink=bpy.data.materials.new('ReviewInk');ink.diffuse_color=(.055,.035,.02,1);cu.materials.append(ink)
 # Verify furniture dimensions were not enlarged and all six cats lie inside the room.
 source_manifest=json.loads((WORK/'cat_cafe1/out_catcafe1/manifest.json').read_text())
 source_bounds={m['name']:m for m in source_manifest['meshes']}
 furniture_bounds={}
 for ob in furniture:
  assert all(abs(s-1)<.001 for s in ob.scale),('Furniture scaled',ob.name,ob.scale[:])
  q=[(v.x,v.z,-v.y)for v in[ob.matrix_world@p.co for p in ob.data.vertices]];lo=[min(v[i]for v in q)for i in range(3)];hi=[max(v[i]for v in q)for i in range(3)]
  source=source_bounds[ob.name];delta=LAY['groups'][ob.name.rsplit('_',1)[0]]
  assert all(abs(lo[i]-source['min'][i]-delta[i])<.003 and abs(hi[i]-source['max'][i]-delta[i])<.003 for i in range(3)),('Review source transform differs',ob.name,lo,hi)
  assert lo[0]>-17.3 and hi[0]<17.3 and lo[2]>-28.3 and hi[2]<.2 and lo[1]>-.1 and hi[1]<11.5,('Furniture outside room',ob.name,lo,hi)
  furniture_bounds[ob.name]={'min':lo,'max':hi}
 bounds={}
 for ob in cats:
  q=[(v.x,v.z,-v.y)for v in[ob.matrix_world@p.co for p in ob.data.vertices]];lo=[min(v[i]for v in q)for i in range(3)];hi=[max(v[i]for v in q)for i in range(3)]
  assert lo[0]>-17 and hi[0]<17 and lo[2]>-28 and hi[2]<0 and lo[1]>-.1 and hi[1]<10,(ob.name,lo,hi)
  bounds[ob.name]={'min':lo,'max':hi}
 (OUT/'review_checks.json').write_text(json.dumps({'furnitureMeshes':len(furniture),'furnitureBounds':furniture_bounds,'wallDecorMeshes':len(wall),'insideCats':bounds,'floorArea':952,'ceilingHeight':11.3},indent=2))
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'cafe_interior2_review.blend'));log(f'REVIEW_ASSEMBLY_PASS: {len(furniture)} full-size furniture meshes; {len(wall)} wall-decor meshes; six supplied cats inside, seated greeter reserved outside')
 log('CAFEINTERIOR2_REVIEW_DONE')
except Exception:log(traceback.format_exc());log('CAFEINTERIOR2_REVIEW_FAILED')
