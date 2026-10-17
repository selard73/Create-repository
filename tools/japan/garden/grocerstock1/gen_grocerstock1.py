"""Distinct shelf merchandise for the existing Mikan grocer. Native meshes only.
Coordinates match grocer2: x across shelf, y up, +z towards customer.
Preserve the three structural shelf meshes and category signs in Studio.
"""
from pathlib import Path
import bpy,bmesh,math,json,random,traceback,sys
from mathutils import Vector
D=Path(__file__).resolve().parent
BASE=D.parent/'gen_mikan2.py'
if not BASE.exists():BASE=D.parent/'mikan_research/gen_mikan2.py'
# Reuse established native geometry helpers without executing the old whole-shop build.
ns={'__file__':str(BASE),'__name__':'grocer_helpers'}
exec(BASE.read_text(encoding='utf-8').split('\ntry:\n')[0],ns)
P=ns['P'];poly=ns['poly'];box=ns['box'];rod=ns['rod'];ring=ns['ring'];ellipsoid=ns['ellipsoid'];leaf=ns['leaf'];mat=ns['mat']
G=ns['G'];COL=ns['COL'];R=random.Random(28001)
OUT=D/'out';OUT.mkdir(parents=True,exist_ok=True);LOG=OUT/'build_log.txt';OBJS=[];ITEMS=[]
COL.update({'TeaGreen':(71,111,83),'TeaBlue':(57,86,107),'TeaRed':(156,75,58),'Tin':(186,181,155),'Gold':(179,146,76),'Kraft':(194,159,110),'Label':(242,230,196),'Soy':(67,37,25),'Amber':(157,101,38),'Oil':(92,73,32),'Ivory':(230,220,188),'Miso':(151,94,49),'Pepper':(166,61,39),'Nori':(36,55,38),'Kombu':(70,73,39),'Udon':(233,218,177),'Soba':(157,135,102),'Mushroom':(118,80,52),'Gills':(194,165,117),'TeaLeaf':(57,77,35)})
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf-8')as f:f.write(str(s)+'\n')
def item(name,cat,x,y,z):ITEMS.append({'name':name,'category':cat,'base':[x,y,z]})
def lathe(g,k,c,profile,n=24):
 vs=[];fs=[]
 for yy,r in profile:
  for j in range(n):
   a=math.tau*j/n;vs.append((c[0]+r*math.cos(a),c[1]+yy,c[2]+r*math.sin(a)))
 for i in range(len(profile)-1):
  for j in range(n):a=i*n+j;b=i*n+(j+1)%n;fs.append((a,b,b+n,a+n))
 fs.extend([tuple(reversed(range(n))),tuple(range((len(profile)-1)*n,len(profile)*n))]);poly(g,k,vs,fs)
def lettering(g,txt,c,w,h,k='Ink'):
 cu=bpy.data.curves.new('product_type','FONT');cu.body=txt.replace('GENMAI','GENMAICHA') if txt=='GENMAI' else txt;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=1;cu.resolution_u=2;cu.extrude=.0005
 ob=bpy.data.objects.new('temporary_type',cu);bpy.context.collection.objects.link(ob);ob.location=P(c);ob.rotation_euler=(math.pi/2,0,0)
 bpy.context.view_layer.update();scale=min(w/max(ob.dimensions.x,.01),h/max(ob.dimensions.z,.01));ob.scale=(scale,scale,scale);bpy.context.view_layer.update()
 me=bpy.data.meshes.new_from_object(ob.evaluated_get(bpy.context.evaluated_depsgraph_get()))
 verts=[ob.matrix_world@v.co for v in me.vertices];poly(g,k,[(v.x,v.z,-v.y)for v in verts],[tuple(p.vertices)for p in me.polygons])
 bpy.data.meshes.remove(me);bpy.data.objects.remove(ob,do_unlink=True);bpy.data.curves.remove(cu)
def panel(g,txt,c,w=.55,h=.28,ink='Ink',paper='Label'):
 box(g,paper,c,(w,h,.012));lettering(g,txt,(c[0],c[1],c[2]+.009),w*.90,h*.62,ink)
def leaf_emblem(g,x,y,z,sz=.10):
 for dx,dy,a in [(-.055,0,-.5),(.055,.035,.55),(.005,.13,0)]:
  ellipsoid(g,'TeaGreen',(x+dx,y+dy,z),(.045,.10,.009),10,5,a)
def tin(g,x,y,z,txt='SENCHA',k='TeaGreen',r=.39,h=1.18):
 item(txt+' tea tin','tea',x,y,z)
 lathe(g,k,(x,y,z),[(0,r*.94),(.05,r),(h-.12,r),(h-.1,r*.98)],28)
 lathe(g,'Tin',(x,y,z),[(h-.10,r*1.025),(h-.03,r*1.025),(h,r*.94)],28)
 ring(g,'Gold',(x,y+.08,z),r+.004,.012,.025,28);ring(g,'Gold',(x,y+h-.13,z),r+.008,.012,.025,28)
 panel(g,txt,(x,y+h*.46,z+r+.008),r*1.52,.31)
 leaf_emblem(g,x,y+h*.70,z+r+.015)
def packet(g,x,y,z,txt,k='Kraft',h=1.20,w=.78,d=.40):
 item(txt+' folded packet','tea' if txt in ['SENCHA','HOJICHA','GENMAI','MATCHA']else'dry',x,y,z)
 vs=[]
 for yy,ww,dd in [(0,w*.91,d*.86),(.12,w,d),(h-.20,w*.94,d*.72),(h,w*.87,.06)]:
  for sx,sz in [(-1,-1),(1,-1),(1,1),(-1,1)]:vs.append((x+sx*ww/2,y+yy,z+sz*dd/2))
 fs=[(3,2,1,0),(12,13,14,15)]
 for j in range(3):
  for i in range(4):fs.append((4*j+i,4*j+(i+1)%4,4*j+(i+1)%4+4,4*j+i+4))
 poly(g,k,vs,fs);box(g,'CedarPale',(x,y+h-.02,z),(.78*w,.065,.09))
 box(g,'TeaGreen'if txt in ['SENCHA','GENMAI']else'TeaRed',(x,y+h*.56,z+d*.5+.005),(w*.64,h*.52,.018))
 panel(g,txt,(x,y+h*.57,z+d*.5+.02),w*.59,.22)
def bottle(g,x,y,z,txt,k='Soy',h=1.48,r=.28,cap='TeaRed'):
 item(txt+' bottle','pantry',x,y,z)
 lathe(g,k,(x,y,z),[(0,r*.80),(.035,r),(.76*h,r),(.82*h,r*.87),(.87*h,r*.48),(.96*h,r*.43),(h,r*.48)],24)
 lathe(g,cap,(x,y,z),[(h,r*.55),(h+.085,r*.55),(h+.105,r*.48)],20)
 ring(g,'Gold',(x,y+h*.89,z),r*.48,.018,.045,20)
 panel(g,txt,(x,y+h*.42,z+r+.008),r*1.72,.38)
 for dy in [.20,.61]:box(g,'Gold',(x,y+h*dy,z+r+.016),(r*1.62,.018,.014))
def miso(g,x,y,z,red=False):
 item(('red'if red else'white')+' miso tub','pantry',x,y,z)
 lathe(g,'TeaRed'if red else'Ivory',(x,y,z),[(0,.37),(.04,.43),(.59,.48),(.66,.48)],24)
 lathe(g,'CedarLight',(x,y,z),[(.66,.51),(.74,.51),(.77,.48)],24)
 for dx in [-.2,0,.2]:box(g,'CedarDark',(x+dx,y+.773,z),(.015,.008,.78))
 panel(g,'RED MISO'if red else'MISO',(x,y+.36,z+.487),.65,.24)
 ring(g,'Gold',(x,y+.09,z),.438,.012,.035,24)
def spice(g,x,y,z):
 item('shichimi spice tin','pantry',x,y,z)
 lathe(g,'Pepper',(x,y,z),[(0,.21),(.04,.235),(.60,.235),(.65,.21)],20)
 lathe(g,'Ink',(x,y,z),[(.65,.235),(.72,.235)],20);panel(g,'7 SPICE',(x,y+.34,z+.24),.37,.25)
def noodles(g,x,y,z,soba=False):
 item('soba bundle'if soba else'udon bundle','dry',x,y,z)
 for j in range(27):
  a=j*2.399;rr=.22*math.sqrt((j+.5)/27);xx=x+rr*math.cos(a);zz=z+rr*math.sin(a);h=1.42+R.uniform(-.045,.045)
  rod(g,'Soba'if soba else'Udon',(xx,y,zz),(xx+.035,y+h,zz),.027,6)
 for yy in [.32,.98]:ring(g,'TeaBlue',(x+.018,y+yy,z),.255,.026,.14,20)
 panel(g,'SOBA'if soba else'UDON',(x,y+.66,z+.26),.44,.36)
def nori(g,x,y,z,stack=False):
 item('nori seaweed sheets','dry',x,y,z)
 # Thin layered sheets with irregular edges; pale paper belly-band.
 for j in range(4):
  yy=y+.02+j*.045 if stack else y
  if stack:box(g,'Nori',(x,yy,z),(.99,.038,.72))
  else:
   vs=[]
   for a in range(5):
    for b in range(3):vs.append((x-.44+a*.22,y+b*.55,z+j*.035+.018*math.sin(a*2+b)))
   fs=[]
   for a in range(4):
    for b in range(2):i=a*3+b;fs.extend([(i,i+3,i+4,i+1),(i+1,i+4,i+3,i)])
   poly(g,'Nori',vs,fs)
 if stack:
  box(g,'Label',(x,y+.19,z),(.35,.012,.76));panel(g,'NORI',(x,y+.10,z+.37),.65,.16)
 else:panel(g,'NORI',(x,y+.48,z+.135),.75,.35)
def kombu(g,x,y,z):
 item('tied kombu strips','dry',x,y,z)
 for j in range(5):
  vs=[]
  for row in range(9):
   yy=y+row*.145
   for side in [-1,1]:vs.append((x+j*.065+side*.10+.025*math.sin(row*1.3+j),yy,z+j*.028+.025*math.cos(row*1.5)))
  fs=[]
  for row in range(8):i=row*2;fs.extend([(i,i+1,i+3,i+2),(i+2,i+3,i+1,i)])
  poly(g,'Kombu',vs,fs)
 panel(g,'KOMBU',(x+.12,y+.48,z+.18),.49,.29)
 rod(g,'ClothBag',(x-.1,y+.84,z+.16),(x+.36,y+.84,z+.16),.018,6)
def mushroom(g,c,r=.18):
 x,y,z=c;rod(g,'Gills',(x,y-.10,z),(x,y+.04,z),r*.25,8)
 ellipsoid(g,'Gills',(x,y+.015,z),(r,.05,r),12,5)
 ellipsoid(g,'Mushroom',(x,y+.08,z),(r,.105,r),14,6)
 for a in [math.pi/4,-math.pi/4]:
  rod(g,'Gills',(x-math.cos(a)*r*.56,y+.175,z-math.sin(a)*r*.56),(x+math.cos(a)*r*.56,y+.175,z+math.sin(a)*r*.56),.012,5)
def mushroom_basket(g,x,y,z):
 item('basket of dried shiitake','dry',x,y,z)
 box(g,'CedarDark',(x,y+.04,z),(1.35,.08,.92))
 for zz in [-.46,.46]:
  for row in range(3):box(g,'CedarLight',(x,y+.10+row*.14,z+zz),(1.39,.10,.045))
 for xx in [-.68,.68]:
  for row in range(3):box(g,'Cedar',(x+xx,y+.10+row*.14,z),(.045,.10,.92))
 for j in range(15):mushroom(g,(x+R.uniform(-.47,.47),y+.35+R.uniform(0,.16),z+R.uniform(-.27,.27)),R.uniform(.14,.20))
 panel(g,'SHIITAKE',(x,y+.24,z+.49),1.08,.22)
def tea_tray(g,x,y,z):
 item('loose-leaf tea sample tray','tea',x,y,z)
 box(g,'CedarLight',(x,y+.04,z),(1.55,.08,.83))
 for zz in [-.40,.40]:box(g,'Cedar',(x,y+.14,z+zz),(1.55,.20,.05))
 for xx in [-.75,.75]:box(g,'Cedar',(x+xx,y+.14,z),(.05,.20,.83))
 for i in range(80):
  xx=x+R.uniform(-.66,.66);zz=z+R.uniform(-.32,.32);a=R.random()*math.tau
  rod(g,'TeaLeaf',(xx,y+.12+R.uniform(0,.06),zz),(xx+.10*math.cos(a),y+.17,zz+.10*math.sin(a)),.012,5)
 panel(g,'LOOSE TEA',(x,y+.16,z+.44),1.1,.20)
def build_stock():
 z=-19.85
 for i,x in enumerate([-4.62,-3.54,-2.45,-1.30,-.28]):tin('GS1_TeaTop',x,4.23,z,['SENCHA','HOJICHA','SENCHA','GENMAI','MATCHA'][i],['TeaGreen','TeaRed','TeaGreen','TeaBlue','Ivory'][i],r=.36 if i!=3 else .40,h=[1.23,1.13,1.23,1.15,.72][i])
 for i,x in enumerate([-4.70,-3.62,-2.52]):packet('GS1_TeaMid',x,2.33,z,['SENCHA','HOJICHA','GENMAI'][i],h=[1.29,1.19,1.25][i])
 tin('GS1_TeaMid',-1.2,2.33,z,'MATCHA','Ivory',r=.36,h=.66);tin('GS1_TeaMid',-.27,2.33,z,'MATCHA','TeaGreen',r=.32,h=.66)
 tin('GS1_TeaLow',-4.5,.43,z,'SENCHA','TeaBlue',r=.48,h=1.42);packet('GS1_TeaLow',-3.15,.43,z,'HOJICHA',h=1.34,w=.95);tea_tray('GS1_TeaLow',-1.17,.43,-19.72)
 for i,x in enumerate([.84,1.70,2.60]):bottle('GS1_PantryTop',x,4.23,z,'SOY','Soy',h=1.38,r=.27)
 for x in [3.90,4.90]:bottle('GS1_PantryTop',x,4.23,z,'MIRIN','Amber',h=1.45,r=.31,cap='Ivory')
 for x,red in [(1.03,False),(2.30,True),(3.57,False)]:miso('GS1_PantryMid',x,2.33,z,red)
 bottle('GS1_PantryMid',4.95,2.33,z,'SESAME','Oil',h=1.07,r=.28,cap='Ink')
 for x in [1.0,2.07]:bottle('GS1_PantryLow',x,.43,z,'VINEGAR','Ivory',h=1.34,r=.34,cap='TeaBlue')
 for x in [3.44,4.12,4.80,5.45]:spice('GS1_PantryLow',x,.43,z)
 for i,x in enumerate([6.63,7.35,8.07,9.07,9.79,10.51]):noodles('GS1_DryTop',x,4.23,z,i>=3)
 nori('GS1_DryMid',6.98,2.33,z);nori('GS1_DryMid',8.12,2.33,z+.02)
 for x in [9.22,10.16,10.98]:kombu('GS1_DryMid',x,2.33,z)
 mushroom_basket('GS1_DryLow',7.23,.43,z);mushroom_basket('GS1_DryLow',8.98,.43,z)
 for j in range(3):nori('GS1_DryLow',10.72,.43+j*.20,z,True)
def create_stock_meshes():
 for (g,k),(vs,fs) in G.items():
  me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v)for v in vs],[],fs);me.update()
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.000005);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  bmesh.ops.triangulate(bm,faces=bm.faces[:]);uv=bm.loops.layers.uv.new('UVMap')
  for face in bm.faces:
   axis=max(range(3),key=lambda i:abs(face.normal[i]))
   for lp in face.loops:q=lp.vert.co;u,v=((q.y,q.z),(q.x,q.z),(q.x,q.y))[axis];lp[uv].uv=(u,v)
  bm.to_mesh(me);bm.free();ob=bpy.data.objects.new(g+'_'+k,me);bpy.context.collection.objects.link(ob);me.materials.append(mat(k))
  if k in ['Soy','Amber','Oil','Ivory','Mushroom','Gills','TeaGreen','TeaBlue','TeaRed','Tin','Gold']:
   for face in me.polygons:face.use_smooth=True
  OBJS.append(ob)
 for name,c in [('GS1_Origin',(0,0,0)),('GS1_Right',(2,0,0)),('GS1_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.05,location=P(c));ob=bpy.context.object;ob.name=name;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);OBJS.append(ob)
def review_context():
 # Exact retained shelf geometry from the original generator; never exported again.
 def ctx(c,s,key,name):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));ob=bpy.context.object;ob.name='CTX_'+name;ob.scale=(s[0],s[2],s[1]);ob.data.materials.append(mat(key))
 for x in [-5.6,.2,6,11.7]:ctx((x,3.35,-20.22),(.22,6.7,.35),'TimberEdge','upright')
 for y in [.35,2.25,4.15,6.05]:ctx((3.05,y,-20.15),(17.6,.16,2.25),'Cedar','shelf');ctx((3.05,y+.06,-18.99),(17.6,.22,.08),'CedarDark','shelf_lip')
 ctx((3,4,-21.5),(20,9,.2),'Cream','wall');ctx((3,-.12,-17),(21,.24,10),'CedarDark','floor')
 for x,text in [(-2.65,'TEA'),(3.05,'PANTRY'),(8.7,'DRY GOODS')]:
  ctx((x,6.43,-18.98),(3.1,.55,.055),'Paper','category')
  cu=bpy.data.curves.new('category','FONT');cu.body=text;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=.24
  ob=bpy.data.objects.new('CTX_label',cu);bpy.context.collection.objects.link(ob);ob.location=P((x,6.43,-18.94));ob.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat('Ink'))
def render_review(only=None):
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.render.threads_mode='FIXED';sc.render.threads=4;sc.render.resolution_x=1600;sc.render.resolution_y=1000;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
 if not sc.world:sc.world=bpy.data.worlds.new('Shop daylight')
 sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.66,.72,.82,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
 for name,loc,power,size in [('Window',(1,10,-9),1250,9),('Soft left',(-8,6,-15),600,7),('High fill',(8,9,-17),750,6)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);sc.collection.objects.link(ob);ob.location=P(loc);ob.rotation_euler=(Vector(P((3,3,-20)))-ob.location).to_track_quat('-Z','Y').to_euler()
 camera=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));sc.collection.objects.link(camera);sc.camera=camera;camera.data.sensor_fit='HORIZONTAL'
 for name,loc,target,lens in [('grocer_shelf_overview',(3.0,5.0,-1.8),(3,3.4,-20),34),('grocer_tea_detail',(-2.7,4.2,-11.1),(-2.7,3.4,-19.9),45),('grocer_pantry_detail',(3.05,4.2,-11.1),(3.05,3.4,-19.9),45),('grocer_dry_goods_detail',(8.75,4.2,-11.1),(8.75,3.4,-19.9),45)]:
  if only and only!=name:continue
  sc.render.resolution_x,sc.render.resolution_y=(1600,780) if name=='grocer_shelf_overview' else (1000,1200)
  camera.location=P(loc);camera.rotation_euler=(Vector(P(target))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.lens=lens;sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);log('RENDER '+name)
try:
 LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.edit.use_global_undo=False
 build_stock();create_stock_meshes();root=bpy.data.objects.new('grocerstock1',None);bpy.context.collection.objects.link(root)
 for ob in OBJS:ob.parent=root
 manifest={'root':'grocerstock1','materials':{k:{'rgb':list(v),'material':'Wood'if k.startswith('Cedar')else'SmoothPlastic'}for k,v in COL.items()},'items':ITEMS,'meshes':[],'removeOld':['M2_Pantry_'+k for k in ['ClothBag','CedarPale','Paper','BottleBrown','Timber','Ceramic','CedarLight','Sage']]}
 for ob in OBJS:
  q=[(p.x,p.z,-p.y)for p in [ob.matrix_world@v.co for v in ob.data.vertices]];lo=[min(p[i]for p in q)for i in range(3)];hi=[max(p[i]for p in q)for i in range(3)];tri=sum(len(p.vertices)-2 for p in ob.data.polygons)
  assert tri<10000,(ob.name,tri)
  if ob.name not in ['GS1_Origin','GS1_Right','GS1_Front']:assert lo[0]>-5.48 and hi[0]<11.60 and lo[1]>=.429 and hi[1]<5.98 and lo[2]>-21.2 and hi[2]<-19.02,(ob.name,lo,hi)
  manifest['meshes'].append({'name':ob.name,'min':lo,'max':hi,'triangles':tri})
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));fbx=OUT/'japan_kit28_grocer_stock1.fbx'
 bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'EMPTY','MESH'})
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'grocerstock1_source.blend'));log('EXPORTED '+str(len(OBJS))+' meshes, '+str(len(ITEMS))+' product groups, '+str(sum(m['triangles']for m in manifest['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx));assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(OBJS)
 for m in manifest['meshes']:
  ob=bpy.data.objects[m['name']];q=[(p.x,p.z,-p.y)for p in [ob.matrix_world@v.co for v in ob.data.vertices]]
  for i in range(3):assert abs(min(p[i]for p in q)-m['min'][i])<.003 and abs(max(p[i]for p in q)-m['max'][i])<.003,m['name']
  if m['name'] in ['GS1_Origin','GS1_Right','GS1_Front']:ob.hide_render=True
 log('ROUNDTRIP_PASS: mesh names, counts and bounds agree within .003 studs')
 review_context();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'grocerstock1_shelf_review.blend'))
 if '--geometry-only' not in sys.argv:render_review()
 log('GROCERSTOCK1_DONE')
except Exception:log(traceback.format_exc());log('GROCERSTOCK1_FAILED')
