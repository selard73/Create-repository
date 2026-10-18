"""Kit36: Lanterns & Umbrellas, fitted to the existing Lantern workshop.
Original meshes, informed by Hiyoshiya timber frontage and Ozeki paper lanterns.
Y up, +Z to street. Keeps existing shell, floor, awning, upper front and plants.
"""
import bpy,bmesh,math,json,traceback,random
from pathlib import Path
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out';OUT.mkdir(exist_ok=True);LOG=D/'build_log.txt'
COL={'Walnut':(79,55,39),'Cedar':(117,83,56),'Hinoki':(166,128,85),'Bamboo':(153,119,72),'Paper':(226,211,180),'Ivory':(236,221,194),'Indigo':(48,69,82),'Rust':(165,76,50),'Moss':(105,119,81),'Plum':(115,73,88),'Ink':(41,38,33),'Brass':(148,113,59),'Glass':(189,211,205),'Stone':(115,113,103),'Wall':(179,163,139),'Leaf':(67,103,62)}
WOOD={'Walnut','Cedar','Hinoki','Bamboo'};G={};OBJECTS=[];LABELS=[];LIGHTS=[]
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf8')as f:f.write(str(s)+'\n')
exec((D/'geometry_helpers.py').read_text(),globals())

def lantern(g,c,r,h,k='Paper',hang=None):
 x,y,z=c
 # Double-walled, gently barrel-shaped washi body, rings and dark end collars.
 profile=[]
 for i in range(17):
  a=i/16;rr=r*(.48+.52*math.sin(math.pi*a)**.65);profile.append((h*(a-.5),rr))
 lathe(g,k,c,profile,32)
 for i in range(1,16):
  a=i/16;rr=r*(.48+.52*math.sin(math.pi*a)**.65)+.006
  torus(g+'Ribs','Bamboo',(x,y+h*(a-.5),z),rr,.014,32,5)
 for yy in[y-h/2,y+h/2]:lathe(g+'Caps','Ink',(x,yy-.045,z),[(0,r*.49),(.09,r*.49)],24)
 if hang is not None:rod(g+'Cord','Ink',(x,y+h/2+.045,z),(x,hang,z),.018,8)
 # An original restrained cream band; no bright neon material.
 if k in {'Rust','Indigo'}:
  lathe(g+'Band','Paper',(x,y-h*.065,z),[(0,r+.012),(h*.13,r+.012)],32)
 return g+'_'+k

def folded(g,c,h,k):
 x,y,z=c;n=32;vs=[];fs=[]
 for j,(hh,rr)in enumerate([(0,.075),(.22,.14),(h*.28,.23),(h*.72,.26),(h,.20)]):
  for i in range(n):
   a=math.tau*i/n;r=rr*(1 if i%2==0 else .80);vs.append((x+r*math.cos(a),y+hh,z+r*math.sin(a)))
 for j in range(4):
  for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
 fs += [tuple(reversed(range(n))),tuple(4*n+i for i in range(n))]
 poly(g,k,vs,fs)
 rod(g+'Shaft','Bamboo',(x,y-.12,z),(x,y+h+.83,z),.055,12)
 lathe(g+'Grip','Walnut',(x,y+h+.34,z),[(0,.075),(.42,.075),(.47,.055)],12)
 lathe(g+'Tie','Paper',(x,y+h*.63,z),[(0,.26),(.12,.26)],32)

def umbrella(g,c,r,k,band=True,stand=True):
 x,y,z=c;n=48;nr=5;vs=[];fs=[]
 def point(a,u,offset=0):return(x+r*u*math.cos(a),y+r*u*math.sin(a),z+.55*(1-u)**1.25+offset)
 for j in range(nr+1):
  for i in range(n):vs.append(point(i*math.tau/n,max(.014,j/nr)))
 for j in range(nr):
  for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
 poly(g,k,vs,fs)
 # Bamboo ribs on the underside and fine alternating seams on the paper face.
 for i in range(n):
  a=i*math.tau/n
  for j in range(nr):rod(g+'Ribs','Bamboo',point(a,max(.06,j/nr),-.035),point(a,(j+1)/nr,-.035),.012,5)
  if i%2==0:
   for j in range(nr):rod(g+'Seams',k,point(a,max(.06,j/nr),.008),point(a,(j+1)/nr,.008),.008,4)
 if band:
  v=[]
  for u in[.72,.84]:
   for i in range(n):v.append(point(i*math.tau/n,u,.012))
  poly(g+'Ring','Paper',v,[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)])
 # Edge binding follows the rim, with a wooden crown and central shaft.
 for i in range(n):rod(g+'Edge','Ink',point(i*math.tau/n,1),point((i+1)*math.tau/n,1),.022,5)
 rod(g+'Shaft','Bamboo',(x,y,z-1.0),(x,y,z+.60),.065,12)
 ell(g+'Crown','Ink',(x,y,z+.62),(.14,.14,.08),16,6)
 if stand:
  box(g+'Stand','Walnut',(x,.12,z-.72),(1.8,.24,1.15))
  rod(g+'Stand','Walnut',(x,.20,z-.78),(x,y,z-.78),.055,10)

def frontage():
 # Shop opening retains the existing 6-stud entrance at the left.
 for x in[-15.2,-8.8,15.2]:box('C1_FrontPosts','Walnut',(x,3.72,0),(.25,7.44,.40))
 box('C1_Header','Walnut',(0,7.48,0),(30.65,.55,.46))
 box('C1_MainSign','Walnut',(2.4,7.15,.30),(21.2,1.06,.18))
 LABELS.append({'name':'C1_MainSign_Walnut','text':'提灯・和傘   Lanterns & Umbrellas','size':87,'rgb':COL['Paper'],'position':[2.4,7.15,.40],'previewSize':.61})
 # Narrow window rails keep the varied stock visible instead of a dense grid.
 box('C1_WindowBase','Cedar',(3.2,.77,-.08),(23.7,1.54,.25))
 for i in range(32):box('C1_BaseBoards','Cedar',(-8.25+i*.736,.77,.10),(.704,1.42,.12))
 for yy in[.10,1.48]:box('C1_BaseRails','Walnut',(3.2,yy,.19),(23.7,.14,.20))
 box('C1_WindowSill','Hinoki',(3.2,1.58,-.02),(23.9,.18,.64))
 for j,(x,w)in enumerate([(-4.85,7.60),(3.26,8.42),(11.32,7.25)]):
  box('C1_Glazing'+str(j),'Glass',(x,4.03,-.05),(w,4.71,.045))
 for x in[-.98,7.54]:box('C1_WindowMullions','Walnut',(x,4.06,.05),(.12,4.93,.18))
 box('C1_WindowRail','Walnut',(3.2,6.47,.05),(23.8,.15,.24))
 # Display deck gives products real support; viewed from the interior too.
 box('C1_WindowDeck','Cedar',(3.2,1.48,-2.0),(23.7,.20,3.48))
 for x in[-8.3,14.7]:box('C1_DisplayLegs','Walnut',(x,.72,-2.4),(.20,1.44,2.0))
 # A shallow step, grounded on the existing market paving at world Y .46.
 box('C1_Threshold','Stone',(-12,-.29,.42),(6.15,.58,1.55))
 # Retracted lattice door at the inside edge of the entrance.
 for x in[-15.0,-13.5]:box('C1_RetractedDoor','Walnut',(x,3.5,-.65),(.10,7,.13))
 for yy in[.12,1.6,6.88]:box('C1_RetractedDoor','Walnut',(-14.25,yy,-.65),(1.60,.12,.13))
 for x in[-14.73,-14.45,-14.17,-13.89]:box('C1_DoorSlats','Cedar',(x,4.25,-.65),(.055,5.2,.08))
 box('C1_DoorFoot','Cedar',(-14.25,.8,-.65),(1.43,1.45,.10))

def window_stock():
 # Three lantern heights, two silhouettes, ample separation from the sign.
 for i,(x,y,r,h,k)in enumerate([(-6.2,4.65,.70,1.90,'Paper'),(-3.6,4.20,.86,1.70,'Rust'),(-.8,4.82,.65,2.05,'Paper')]):
  lantern('C1_WindowLantern'+str(i),(x,y,-1.85),r,h,k,6.95)
  LIGHTS.append({'part':'C1_WindowLantern'+str(i)+'_'+k,'position':[x,y,-1.85],'brightness':.25,'range':6})
 # Table lantern with an original tiny branch silhouette and a miniature folded pair.
 box('C1_WindowPlinth','Walnut',(2.0,1.72,-1.8),(3.0,.28,2.18))
 lantern('C1_DeskLantern',(2,2.56,-1.8),.61,1.38,'Ivory')
 for xx in[1.52,2.48]:rod('C1_DeskLanternFeet','Ink',(xx,1.86,-1.8),(xx,1.99,-1.8),.04,8)
 box('C1_FrontUmbrellaRack','Cedar',(5.0,1.91,-2.2),(2.25,.6,1.6))
 for i in range(3):folded('C1_FrontFolded'+str(i),(4.22+i*.76,2.22,-2.2),2.85,['Indigo','Moss','Plum'][i])
 umbrella('C1_WindowUmbrella',(10.8,3.82,-1.85),2.12,'Indigo',True,False)
 box('C1_WindowUmbrellaFoot','Walnut',(10.8,1.72,-2.45),(1.8,.28,1.0))
 rod('C1_WindowUmbrellaSupport','Walnut',(10.8,1.86,-2.45),(10.8,3.82,-2.45),.055,10)

def rack(g,x,z,w):
 for xx in[x-w/2,x+w/2]:box(g,'Walnut',(xx,1.30,z),(.14,2.60,1.5))
 for yy in[.22,2.15]:box(g,'Cedar',(x,yy,z),(w,.15,1.55))
 box(g,'Walnut',(x,2.28,z-.56),(w,.18,.13))
 for i in range(6):box(g+'Dividers','Walnut',(x-w/2+(i+.5)*w/6,2.25,z),(.055,.20,1.35))

def interior():
 # Back-left folded rack and a framed, slightly smaller natural-paper umbrella.
 rack('C1_BackRack',-10.6,-15.9,6.2)
 for i in range(6):folded('C1_BackFolded'+str(i),(-13.1+i*1.0,.32,-15.8),3.9+.12*(i%2),['Rust','Indigo','Paper','Moss','Plum','Rust'][i])
 umbrella('C1_BackUmbrellaA',(-2.6,5.15,-17.15),2.30,'Paper',False)
 umbrella('C1_BackUmbrellaB',(8.8,4.77,-16.50),3.0,'Rust',True)
 # Low drawers below the left paper display, with folded paper boxes.
 box('C1_StockCabinet','Cedar',(-2.8,1.05,-16.9),(6.4,2.1,2.7))
 box('C1_CabinetTop','Hinoki',(-2.8,2.18,-16.9),(6.6,.16,2.85))
 for x in[-4.42,-1.18]:
  for y in[.58,1.52]:box('C1_Drawers','Hinoki',(x,y,-15.51),(3.0,.79,.09));ell('C1_DrawerPulls','Brass',(x,y,-15.43),(.09,.06,.04),12,5)
 # Right-hand artisan workbench, with a staff lane behind and clear browsing aisle.
 box('C1_WorkTop','Hinoki',(10.45,2.80,-10.10),(7.8,.27,3.50))
 for x in[7.0,13.9]:
  for z in[-11.43,-8.78]:box('C1_WorkLegs','Walnut',(x,1.32,z),(.27,2.64,.27))
 box('C1_WorkShelf','Cedar',(10.45,.68,-10.10),(7.2,.16,2.96))
 # Unfinished lantern skeleton held on a wooden jig.
 box('C1_JigFoot','Walnut',(8.18,3.01,-10.25),(1.65,.14,1.2))
 rod('C1_JigPole','Walnut',(8.18,3.08,-10.25),(8.18,5.26,-10.25),.06,10)
 for j in range(13):
  y=3.35+j*.14;r=.35+.40*math.sin(math.pi*j/12)
  torus('C1_UnfinishedRibs','Bamboo',(8.18,y,-10.25),r,.016,32,5)
 for i in range(6):
  a=math.tau*i/6
  for j in range(12):
   r1=.35+.4*math.sin(math.pi*j/12);r2=.35+.4*math.sin(math.pi*(j+1)/12)
   rod('C1_UnfinishedStays','Bamboo',(8.18+r1*math.cos(a),3.35+j*.14,-10.25+r1*math.sin(a)),(8.18+r2*math.cos(a),3.35+(j+1)*.14,-10.25+r2*math.sin(a)),.012,5)
 # Paper sheets, brush and paste bowl lie on the work surface.
 for i in range(5):box('C1_WorkPaper','Paper',(11.0,2.96+i*.027,-10.0),(2.10,.025,1.72))
 for i in range(7):rod('C1_BambooBundle','Bamboo',(11.0+i*.12,2.96,-11.3),(13.1+i*.12,2.96,-9.25),.023,6)
 lathe('C1_PasteBowl','Ivory',(12.60,2.94,-8.98),[(0,.17),(.1,.30),(.30,.34),(.33,.31),(.12,.22)],24)
 rod('C1_PasteBrush','Walnut',(11.55,3.13,-9.34),(12.18,3.13,-8.91),.035,10)
 rod('C1_PasteBrush','Paper',(12.18,3.13,-8.91),(12.43,3.13,-8.74),.075,10,r2=.055)
 for i,k in enumerate(['Paper','Indigo','Rust']):
  box('C1_SupplyBox'+str(i),k,(8.3+i*2.05,1.22,-10.1),(1.75,.86,2.20));box('C1_BoxLid'+str(i),'Hinoki',(8.3+i*2.05,1.69,-10.1),(1.84,.09,2.29))
 # Left wall showroom shelves face the clear central aisle.
 for j,yy in enumerate([1.55,4.15]):
  box('C1_LeftShelf'+str(j),'Cedar',(-14.1,yy,-8.5),(2.6,.18,7.0))
  for zz in[-11.3,-5.7]:box('C1_LeftBrackets','Walnut',(-14.8,yy-.35,zz),(.8,.6,.15))
  for i,(zz,k)in enumerate([(-10.5,'Paper'),(-7.8,'Ivory'),(-5.8,'Rust')]):
   lantern('C1_ShelfLantern'+str(j)+str(i),(-14.0,yy+.76,zz),.52,1.30,k)
 # Hanging samples above displays, not above the entry or central walking route.
 for i,(x,y,z,r,h,k)in enumerate([(-10.4,6.45,-15.8,.75,1.85,'Ivory'),(11.1,6.66,-10.1,.74,1.90,'Paper'),(13.9,6.61,-15.5,.63,1.75,'Paper')]):
  part=lantern('C1_Hanging'+str(i),(x,y,z),r,h,k,8.12)
  LIGHTS.append({'part':part,'position':[x,y,z],'brightness':.50,'range':12})

def build_objects():
 for(g,k),(vs,fs)in G.items():
  me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v)for v in vs],[],fs);me.update()
  o=bpy.data.objects.new(g+'_'+k,me);bpy.context.collection.objects.link(o);me.materials.append(mat(k))
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.000001);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  uv=bm.loops.layers.uv.new('UVMap')
  for f in bm.faces:
   ax=max(range(3),key=lambda i:abs(f.normal[i]))
   for l in f.loops:
    c=l.vert.co;u,v=((c.y,c.z),(c.x,c.z),(c.x,c.y))[ax];l[uv].uv=(u/4,v/4)
  bm.to_mesh(me);bm.free()
  if k in WOOD|{'Stone'} and 'Ribs'not in g and 'Bundle'not in g:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Soft joinery edges','BEVEL');mod.width=.012;mod.segments=1;mod.limit_method='ANGLE';bpy.ops.object.modifier_apply(modifier=mod.name)
  if 'Umbrella'in g and (g.endswith(('A','B'))or g=='C1_WindowUmbrella'):
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Paper thickness','SOLIDIFY');mod.thickness=.012;bpy.ops.object.modifier_apply(modifier=mod.name)
  OBJECTS.append(o)
 for name,pos in[('C1_Origin',(0,0,0)),('C1_Right',(2,0,0)),('C1_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.05,location=P(pos));o=bpy.context.object;o.name=name;OBJECTS.append(o)

def render():
 def block(name,k,c,s):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.name='CTX_'+name;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat(k));return o
 block('Lane','Stone',(0,-.71,4),(42,.26,10));block('OriginalFloor','Cedar',(0,-.15,-9.50),(32,.30,19.5))
 block('OriginalBack','Wall',(0,3.91,-19),(32,9.3,.40))
 for x in[-16,16]:block('OriginalSide','Cedar',(x,3.91,-9.5),(.40,9.3,19))
 block('Ceiling','Walnut',(0,8.36,-9.5),(32,.35,19))
 block('ExistingUpper','Cedar',(0,12.0,-.18),(32,7.0,.35))
 for x in[-11,0,11]:
  block('UpperWindow','Indigo',(x,11.5,.05),(9.0,4.2,.10))
  for xx in[x-4.6,x+4.6]:block('UpperFrame','Walnut',(xx,11.5,.12),(.16,4.4,.18))
  for yy in[9.3,13.7]:block('UpperFrame','Walnut',(x,yy,.12),(9.3,.16,.18))
 for z,y in[(.10,8.5),(1.15,8.24),(2.20,7.98)]:block('TileAwning','Indigo',(0,y,z),(33,.14,1.25))
 for x in[-16,16]:block('OriginalPost','Walnut',(x,6.5,0),(.4,13,.4))
 for k in WOOD:
  m=mat(k);n=m.node_tree.nodes;l=m.node_tree.links;bs=n['Principled BSDF'];tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=3;tex.inputs['Detail'].default_value=2
  co=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='MULTIPLY';scale.inputs[1].default_value=(2,2,.15);l.new(co.outputs['Object'],scale.inputs[0]);l.new(scale.outputs[0],tex.inputs['Vector'])
  ramp=n.new('ShaderNodeValToRGB');c=tuple(lin(v)for v in COL[k]);ramp.color_ramp.elements[0].color=tuple(v*.90 for v in c)+(1,);ramp.color_ramp.elements[1].color=tuple(min(1,v*1.08)for v in c)+(1,);l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color'])
 for r in LABELS:
  cu=bpy.data.curves.new('Preview text','FONT');cu.body=r['text'];cu.align_x='CENTER';cu.align_y='CENTER';cu.size=r['previewSize'];cu.font=bpy.data.fonts.load('C:/Windows/Fonts/YuGothR.ttc')
  o=bpy.data.objects.new('CTX_Text',cu);bpy.context.collection.objects.link(o);o.location=P(r['position']);o.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat('Paper'))
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=20;sc.cycles.use_denoising=True;sc.render.resolution_x=1500;sc.render.resolution_y=950;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
 sc.world=bpy.data.worlds.new('Daylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.72,.85,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.50
 def area(name,p,energy,size,target):
  d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=P(p);o.rotation_euler=(Vector(P(target))-o.location).to_track_quat('-Z','Y').to_euler()
 area('Daylight',(0,9,14),3000,20,(0,3,-3));area('Interior',(-3,7,-10),1100,12,(0,2,-12));area('Window',(3,6,-2.5),450,10,(3,2,-3))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 for name,eye,target,lens in[('01_front',(-4,6.2,36),(0,4,-1.8),40),('02_inside',(-6.5,5.7,-5.2),(1.4,3.6,-14.0),20),('03_window',(3.5,4.7,12),(3.5,3.8,-2.5),30)]:
  sc.render.resolution_y=780 if name=='01_front'else 950;cam.location=P(eye);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens;sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);log('RENDER '+name)
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'craftshop1_review.blend'))

try:
 LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True)
 frontage();window_stock();interior();build_objects()
 root=bpy.data.objects.new('craftshop1',None);bpy.context.collection.objects.link(root)
 manifest={'root':'craftshop1','origin':[5983.5,1.03985318,-117],'yaw':90,'materials':{k:{'rgb':v,'material':'Wood'if k in WOOD else'Slate'if k=='Stone'else'Metal'if k=='Brass'else'SmoothPlastic'}for k,v in COL.items()},'labels':LABELS,'lights':LIGHTS,'meshes':[]}
 for o in OBJECTS:
  o.parent=root;q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  rec={'name':o.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
  assert rec['triangles']<10000,rec;manifest['meshes'].append(rec)
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in OBJECTS:o.select_set(True)
 fbx=OUT/'japan_kit36_lanterns_umbrellas1.fbx';bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False)
 log('EXPORTED '+str(len(OBJECTS))+' meshes, '+str(sum(x['triangles']for x in manifest['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
 assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(manifest['meshes'])
 for rec in manifest['meshes']:
  o=bpy.data.objects[rec['name']];q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  assert all(abs(min(p[i]for p in q)-rec['min'][i])<.003 and abs(max(p[i]for p in q)-rec['max'][i])<.003 for i in range(3)),rec['name']
  if rec['name']in{'C1_Origin','C1_Right','C1_Front'}:o.hide_render=True
 log('ROUNDTRIP_PASS: all names and bounds within .003 studs')
 m=mat('Glass');nodes=m.node_tree.nodes;links=m.node_tree.links;bs=nodes['Principled BSDF'];bs.inputs['Transmission Weight'].default_value=0;bs.inputs['Roughness'].default_value=.4
 transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader');mix.inputs[0].default_value=.05;links.new(transparent.outputs[0],mix.inputs[1]);links.new(bs.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes['Material Output'].inputs['Surface'])
 render();log('CRAFTSHOP1_DONE')
except Exception:
 log(traceback.format_exc());log('CRAFTSHOP1_FAILED');raise
