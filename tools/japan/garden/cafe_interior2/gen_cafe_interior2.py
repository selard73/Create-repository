"""New mesh shell for the separate cat-cafe interior; reused furnishings stay full size.
Build geometry only. Render individual views in fresh processes using render_interior.py.
"""
from pathlib import Path
import bpy,bmesh,ast,math,json,traceback
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out';OUT.mkdir(parents=True,exist_ok=True);LOG=OUT/'build_log.txt'
BASE=Path(r'C:\Users\slard\Create-repository\tools\japan\garden\gen_cat_cafe1.py')
LAYOUT=json.loads((D/'layout.json').read_text());G={};OBJS=[]
COL={'Oak':(163,119,77),'OakLight':(190,150,104),'OakDark':(116,81,52),'Timber':(65,47,35),'TimberEdge':(87,62,42),'Wall':(231,223,201),'Paper':(236,220,179),'Cream':(236,228,209),'SageSoft':(132,151,121),'Rug':(207,195,158),'Washilight':(237,232,209),'Ink':(60,46,33),'Indigo':(66,87,105)}
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf-8')as f:f.write(str(s)+'\n')
def P(p):return(p[0],-p[2],p[1])
def linear(n):
 n=n/255;return n/12.92 if n<=.04045 else((n+.055)/1.055)**2.4
def mat(k):
 n='CI2_'+k;m=bpy.data.materials.get(n)
 if m:return m
 m=bpy.data.materials.new(n);m.use_nodes=True;c=tuple(linear(n)for n in COL[k])+(1,);m.diffuse_color=c
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=c;b.inputs['Roughness'].default_value=.68
 return m
tree=ast.parse(BASE.read_text(encoding='utf-8'));wanted={'geo','poly','box','ellipsoid','rod','ring','torus','cushion'}
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name in wanted],type_ignores=[]),str(BASE),'exec'))

def build():
 # Individually convex wall meshes keep their default collisions from closing the room.
 box('CI2_FloorBase','OakDark',(0,-.20,-14),(34.4,.18,28.4))
 for i in range(34):
  x=-16.5+i
  for j in range(7):
   z=-2-4*j
   box('CI2_Floor', ['Oak','OakLight','OakDark'][(i*7+j*3)%11%3],(x,-.065,z),(.975,.13,3.98))
 box('CI2_LeftWall','Wall',(-17.1,5.65,-14),(.2,11.3,28.4))
 box('CI2_RightWall','Wall',(17.1,5.65,-14),(.2,11.3,28.4))
 box('CI2_BackWall','Wall',(0,5.65,-28.1),(34.4,11.3,.2))
 box('CI2_FrontLeft','Wall',(-15.6,5.65,.10),(3.2,11.3,.2))
 box('CI2_FrontRight','Wall',(4.6,5.65,.10),(25.2,11.3,.2))
 box('CI2_DoorHeader','Wall',(-11,9.65,.10),(6,3.3,.2))
 # Safe, sealed doorway recess; players transition before reaching the end.
 box('CI2_VestibuleFloor','Oak',(-11,-.065,1.4),(6.4,.13,2.8))
 for x,k in [(-14.1,'Left'),(-7.9,'Right')]:box('CI2_Vestibule'+k,'Wall',(x,5.65,1.4),(.2,11.3,2.8))
 box('CI2_VestibuleEnd','Wall',(-11,5.65,2.7),(6.4,11.3,.2))
 box('CI2_CeilingBase','OakDark',(0,11.39,-12.7),(34.4,.18,31))
 for j in range(42):box('CI2_Ceiling','OakLight',(0,11.29,-.34-j*.66),(34,.06,.63))
 for z in [-.3,-7.0,-14,-21,-27.7]:box('CI2_Beams','TimberEdge',(0,11.02,z),(34,.44,.26))
 for x in [-16.85,16.85]:
  for z in [-.3,-7,-14,-21,-27.7]:box('CI2_Posts','TimberEdge',(x,5.55,z),(.24,11.1,.28))
 # Low wainscot, a high picture rail and a generous plain cream wall above.
 for x,k in [(-16.98,'Left'),(16.98,'Right')]:
  for j in range(37):box('CI2_'+k+'Wainscot','OakDark',(x,.9,-.4-j*.75),(.06,1.8,.71))
  for y in [1.86,9.4]:box('CI2_'+k+'Rail','TimberEdge',(x,y,-14),(.11,.12,28))
 for j in range(45):box('CI2_BackWainscot','OakDark',(-16.5+j*.75,.9,-27.98),(.71,1.8,.06))
 for y in [1.86,9.4]:box('CI2_BackRail','TimberEdge',(0,y,-27.96),(34,.12,.11))
 # Opaque shoji daylight panels: no view outside the separate room or through walls.
 for j in range(5):
  x=-5.4+j*4.75
  box('CI2_Shoji','Washilight',(x,4.75,-.045),(4.54,5.5,.06))
  for dx in [-2.34,2.34]:box('CI2_WindowFrame','TimberEdge',(x+dx,4.75,-.11),(.12,5.72,.12))
  for yy in [1.93,7.57]:box('CI2_WindowFrame','TimberEdge',(x,yy,-.11),(4.8,.12,.12))
  for dx in [-1.55,-.77,0,.77,1.55]:box('CI2_Lattice','Oak',(x+dx,4.75,-.13),(.045,5.5,.08))
  for yy in [3.05,4.15,5.25,6.35]:box('CI2_Lattice','Oak',(x,yy,-.13),(4.54,.045,.08))
 for x in [-14,-8]:box('CI2_DoorFrame','Timber',(x,4.1,-.04),(.25,8.2,.28))
 box('CI2_DoorFrame','Timber',(-11,8.1,-.04),(6.25,.25,.28))
 for x in [-12.5,-9.5]:
  box('CI2_Noren','SageSoft',(x,6.8,-.04),(2.94,2.38,.045))
  ellipsoid('CI2_NorenPaw','Cream',(x,6.7,-.08),(.28,.24,.018),16,8)
  for dx,dy in [(-.3,.24),(-.11,.40),(.11,.40),(.3,.24)]:ellipsoid('CI2_NorenPaw','Cream',(x+dx,6.7+dy,-.08),(.09,.12,.018),12,6)
 box('CI2_Rug','SageSoft',(-10.8,.018,-19.4),(11.5,.035,14.4))
 box('CI2_Rug','Rug',(-10.8,.041,-19.4),(11.0,.012,13.9))
 for j in range(24):box('CI2_Rug','Cream',(-10.8,.050,-25.9+j*.55),(10.6,.008,.025))

def meshes():
 for(g,k),(vs,fs)in G.items():
  me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v)for v in vs],[],fs);me.update()
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.000005);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  bmesh.ops.triangulate(bm,faces=bm.faces[:]);uv=bm.loops.layers.uv.new('UVMap')
  for f in bm.faces:
   axis=max(range(3),key=lambda a:abs(f.normal[a]))
   for lp in f.loops:q=lp.vert.co;u,v=((q.y,q.z),(q.x,q.z),(q.x,q.y))[axis];lp[uv].uv=(u/4,v/4)
  bm.to_mesh(me);bm.free();ob=bpy.data.objects.new(g+'_'+k,me);bpy.context.collection.objects.link(ob);me.materials.append(mat(k));OBJS.append(ob)
 for n,c in [('CI2_Origin',(0,0,0)),('CI2_Right',(2,0,0)),('CI2_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.05,location=P(c));o=bpy.context.object;o.name=n;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);OBJS.append(o)

try:
 LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.edit.use_global_undo=False
 build();meshes();root=bpy.data.objects.new('cafe_interior2',None);bpy.context.collection.objects.link(root)
 for o in OBJS:o.parent=root
 mf={'root':'cafe_interior2','layout':LAYOUT,'materials':{k:{'rgb':list(v),'material':'Wood'if k in ['Oak','OakLight','OakDark','Timber','TimberEdge']else'Fabric'if k in ['SageSoft','Rug']else'SmoothPlastic'}for k,v in COL.items()},'meshes':[]}
 for ob in OBJS:
  q=[(v.x,v.z,-v.y)for v in[ob.matrix_world@p.co for p in ob.data.vertices]];lo=[min(v[i]for v in q)for i in range(3)];hi=[max(v[i]for v in q)for i in range(3)];tri=sum(len(p.vertices)-2 for p in ob.data.polygons)
  assert tri<10000,(ob.name,tri)
  mf['meshes'].append({'name':ob.name,'min':lo,'max':hi,'triangles':tri,'collide':any(ob.name.startswith('CI2_'+p)for p in ['Floor','LeftWall','RightWall','BackWall','FrontLeft','FrontRight','DoorHeader','Vestibule','CeilingBase'])})
 (OUT/'manifest.json').write_text(json.dumps(mf,indent=2));fbx=OUT/'japan_kit29_cat_cafe_interior2.fbx'
 bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'EMPTY','MESH'})
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'cafe_interior2_shell.blend'));log('EXPORTED '+str(len(OBJS))+' shell meshes; '+str(sum(m['triangles']for m in mf['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx));assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(OBJS)
 for m in mf['meshes']:
  ob=bpy.data.objects[m['name']];q=[(v.x,v.z,-v.y)for v in[ob.matrix_world@p.co for p in ob.data.vertices]]
  for i in range(3):assert abs(min(v[i]for v in q)-m['min'][i])<.003 and abs(max(v[i]for v in q)-m['max'][i])<.003,m['name']
 log('ROUNDTRIP_PASS: all shell names, counts and bounds within .003 studs')
 log('CAFEINTERIOR2_DONE')
except Exception:log(traceback.format_exc());log('CAFEINTERIOR2_FAILED')
