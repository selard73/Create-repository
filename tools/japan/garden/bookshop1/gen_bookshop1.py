"""Kit35: closed Book & Stationery window for the former Kimono atelier.
Original geometry. Kyoto Kyukyodo references informed timber cabinets and real goods.
Y up / +Z toward street. Existing upper building, awning, lantern and plants retained.
"""
import bpy,bmesh,math,json,traceback,random
from pathlib import Path
from mathutils import Vector,Matrix
D=Path(__file__).resolve().parent
OUT=D/'out';OUT.mkdir(exist_ok=True)
LOG=D/'build_log.txt'
COL={'Walnut':(84,58,40),'Cedar':(121,85,56),'Hinoki':(169,129,85),'HinokiEdge':(148,107,66),'Wall':(179,163,132),'Indigo':(49,70,80),'Moss':(104,119,86),'Rust':(163,87,61),'Plum':(113,77,85),'Paper':(224,209,171),'Ivory':(234,221,193),'Celadon':(115,143,125),'Ink':(34,38,34),'Brass':(155,122,67),'Glass':(189,211,205),'Stone':(115,113,103),'Leaf':(70,103,63)}
WOOD={'Walnut','Cedar','Hinoki','HinokiEdge'}
G={};OBJECTS=[];LABELS=[]
R=random.Random(100135)
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf8')as f:f.write(str(s)+'\n')
exec((D/'geometry_helpers.py').read_text(),globals())

def rot_group_since(before,center,angle):
 # rotate a just-created object about local Z (lean a book sideways)
 a=math.radians(angle);co,si=math.cos(a),math.sin(a);cx,cy,cz=center
 for key,(vs,fs)in G.items():
  start=before.get(key,0)
  for i in range(start,len(vs)):
   x,y,z=vs[i];x-=cx;y-=cy;vs[i]=(cx+co*x-si*y,cy+si*x+co*y,z)

def book(g,x,y,z,w,h,d,k,lean=0,front=False):
 before={k:len(v[0])for k,v in G.items()}
 # Closed book stands on its bottom edge. Cream page block, bound spine, two boards.
 box(g,'Paper',(x,y+h/2,z),(w-.06,h-.10,d-.07))
 for xx in[x-w/2,x+w/2]:box(g,k,(xx,y+h/2,z),(.045,h,d))
 box(g,k,(x,y+h/2,z+d/2),(w+.045,h,.055))
 for yy in[y+.16,y+h-.16]:box(g,'Brass',(x,yy,z+d/2+.032),(max(.08,w-.03),.025,.012))
 if front:
  box(g,k,(x,y+h/2,z+d/2+.036),(w-.04,h-.09,.05))
  # Simple original botanical emblem and an inset title slip.
  box(g+'Title','Paper',(x,y+h*.76,z+d/2+.067),(w*.78,.26,.012))
  LABELS.append({'name':g+'Title_Paper','text':'FOREST TALES'if g.endswith('A')else'KYOTO SKETCHES','size':15,'rgb':COL['Walnut'],'position':[x,y+h*.76,z+d/2+.074],'previewSize':.105})
  rod(g,'HinokiEdge',(x-.22,y+.35,z+d/2+.075),(x+.20,y+h*.55,z+d/2+.075),.014,6)
  for i in range(3):
   ell(g,'Paper',(x-.15+i*.13,y+.47+i*.20,z+d/2+.075),(.12,.055,.012),10,4)
   ell(g,'Paper',(x+.07+i*.10,y+.42+i*.20,z+d/2+.075),(.09,.045,.012),10,4)
 else:box(g,'Ivory',(x,y+h*.66,z+d/2+.032),(max(.07,w*.61),.32,.014))
 if lean:rot_group_since(before,(x,y,z),lean)

def flat_book(g,x,y,z,w,d,h,k):
 box(g,'Paper',(x,y+h/2,z),(w-.09,h-.06,d-.08))
 for yy in[y+.015,y+h-.015]:box(g,k,(x,yy,z),(w,.03,d))
 box(g,k,(x,y+h/2,z+d/2),(w,h,.035))
 for xx in[x-w*.32,x+w*.32]:box(g,'Brass',(xx,y+h/2,z+d/2+.022),(.025,h*.55,.01))

def tray(g,c,s):
 x,y,z=c;w,d=s
 box(g,'Hinoki',(x,y+.04,z),(w,.08,d))
 for xx in[x-w/2+.04,x+w/2-.04]:box(g,'HinokiEdge',(xx,y+.14,z),(.08,.22,d))
 for zz in[z-d/2+.04,z+d/2-.04]:box(g,'HinokiEdge',(x,y+.14,zz),(w,.22,.08))

def frame():
 # The lower facade is rebuilt within the same existing structural posts.
 box('B1_DisplayBack','Wall',(3.35,3.6,-4.9),(22.55,7.2,.16))
 for x in[-7.87,14.57]:box('B1_Returns','Walnut',(x,3.6,-2.45),(.16,7.2,5.0))
 for x in[-8.02,14.72]:box('B1_JointClosures','Cedar',(x,3.6,-.08),(.20,7.2,.38))
 box('B1_DisplayCeiling','Walnut',(3.35,6.72,-2.5),(22.55,.12,4.8))
 box('B1_Platform','Cedar',(3.35,.80,-2.37),(22.5,1.6,5.0))
 box('B1_DisplayDeck','Hinoki',(3.35,1.70,-2.38),(22.5,.20,4.80))
 # Narrow timber panels and joinery; retain broad calm surfaces around the display.
 box('B1_BaseBacking','Walnut',(3.35,.79,.13),(22.5,1.58,.20))
 box('B1_StonePlinth','Stone',(3.35,-.29,-.10),(22.7,.58,.88))
 for i in range(30):box('B1_BaseBoards','Cedar',(-7.50+i*.75,.80,.25),(.718,1.36,.10))
 for yy in[.10,1.50]:box('B1_BaseRails','Walnut',(3.35,yy,.32),(22.55,.15,.20))
 for xx in[-7.87,3.40,14.57]:box('B1_WindowPosts','Walnut',(xx,4.12,.18),(.20,5.28,.30))
 for yy in[1.68,6.55]:box('B1_WindowRails','Cedar',(3.35,yy,.20),(22.65,.18,.36))
 box('B1_WindowSill','HinokiEdge',(3.35,1.70,.28),(22.7,.18,.60))
 for j,(x,w)in enumerate([(-2.23,10.97),(9,10.96)]):box('B1_Glazing'+str(j),'Glass',(x,4.10,.11),(w,4.71,.035))
 # Small lattice transom, leaving the merchandise clear at eye height.
 box('B1_TransomRail','Walnut',(3.35,5.99,.28),(22.45,.075,.10))
 for i in range(36):box('B1_TransomSlats','Walnut',(-7.50+i*.62,6.24,.28),(.045,.46,.085))
 box('B1_Header','Walnut',(3.35,7.11,-.03),(22.6,.88,.38))
 box('B1_MainSign','Walnut',(3.35,7.14,.25),(17.7,1.13,.16))
 LABELS.append({'name':'B1_MainSign_Walnut','text':'本と文具   Books & Stationery','size':68,'rgb':COL['Paper'],'position':[3.35,7.14,.34],'previewSize':.64})
 # Closed sliding door left. Real glass plus a sealed shallow alcove behind it.
 box('B1_DoorBack','Wall',(-10.95,3.7,-1.8),(5.65,7.4,.12))
 for x in[-13.71,-8.14]:box('B1_DoorAlcoveReturns','Walnut',(x,3.70,-1.08),(.12,7.40,1.75))
 box('B1_DoorSideFill','Walnut',(-14.24,3.7,-.15),(1.05,7.40,.30))
 box('B1_DoorGlass','Glass',(-10.91,4.56,-.25),(5.42,5.30,.055))
 box('B1_DoorLower','Cedar',(-10.91,.95,-.20),(5.46,1.90,.18))
 for x in[-13.67,-8.15]:box('B1_DoorJamb','Walnut',(x,3.70,-.08),(.20,7.40,.40))
 for yy in[.10,1.92,7.27]:box('B1_DoorRails','Walnut',(-10.91,yy,-.08),(5.53,.17,.35))
 for i in range(11):box('B1_DoorSlats','Walnut',(-13.37+i*.49,4.60,-.08),(.064,5.19,.14))
 for yy in[3.57,5.35]:box('B1_DoorCrossbars','Cedar',(-10.91,yy,.005),(5.42,.065,.09))
 # Brass recessed pull and grounded threshold.
 box('B1_DoorPull','Ink',(-8.65,3.18,.015),(.20,.61,.045))
 for x in[-8.73,-8.57]:rod('B1_DoorPull','Brass',(x,2.93,.052),(x,3.43,.052),.023,8)
 box('B1_Threshold','Stone',(-10.91,-.29,.48),(5.9,.58,1.8))
 box('B1_ClosedTag','Paper',(-10.88,4.55,.105),(1.88,.77,.07))
 for x in[-11.45,-10.31]:rod('B1_TagCord','HinokiEdge',(x,4.94,.09),(-10.88,5.20,.09),.014,6)
 LABELS.append({'name':'B1_ClosedTag_Paper','text':'CLOSED','size':33,'rgb':COL['Walnut'],'position':[-10.88,4.55,.148],'previewSize':.22})

def displays():
 # Asymmetric stepped cabinets: books to the left, writing materials to the right.
 box('B1_LeftCabinet','Cedar',(-3.85,2.36,-3.65),(6.7,1.12,1.85))
 box('B1_LeftTop','Hinoki',(-3.85,2.98,-3.65),(6.88,.13,1.97))
 for i in range(4):
  x=-6.38+i*1.69;box('B1_DrawerFaces','HinokiEdge',(x,2.36,-2.70),(1.56,.94,.07));ell('B1_DrawerPulls','Brass',(x,2.37,-2.64),(.075,.055,.025),10,4)
 x=-6.90
 for i in range(13):
  w=[.31,.40,.28,.45,.34][i%5];h=[1.55,1.85,1.65,1.98,1.72][i%5]
  book('B1_ShelfBooks',x+w/2,3.05,-3.28,w,h,.80,['Indigo','Moss','Rust','Plum','Cedar'][i%5],lean=0)
  x+=w+.025
 # Bookends and a pair of face-out picture books at varying heights.
 for xx in[-7.16,-1.65]:box('B1_Bookends','Walnut',(xx,3.61,-3.25),(.10,1.13,.95))
 flat_book('B1_StackA',-5.90,1.80,-1.25,2.0,1.32,.28,'Moss')
 flat_book('B1_StackA',-5.75,2.08,-1.25,2.1,1.37,.24,'Rust')
 flat_book('B1_StackA',-5.86,2.32,-1.24,1.95,1.30,.23,'Indigo')
 book('B1_FeatureBookA',-3.14,1.80,-1.36,1.56,2.13,.19,'Rust',front=True)
 book('B1_FeatureBookB',-.93,1.80,-1.31,1.64,2.41,.20,'Indigo',front=True)
 for x,y,h in[(-3.14,1.8,2.13),(-.93,1.8,2.41)]:
  rod('B1_BookStands','Walnut',(x,y,-1.80),(x,y+h*.69,-1.49),.04,8)
  box('B1_BookStands','Walnut',(x,y+.035,-1.20),(1.28,.07,.44))
 # A gently arched open book on a lectern, with ruled pages.
 x=1.32;y=2.0;z=-1.60
 box('B1_OpenStand','Walnut',(x,1.90,z),(2.50,.20,1.47))
 for side in[-1,1]:
  vs=[]
  for row in range(2):
   for j in range(9):
    u=j/8;vs.append((x+side*u*1.12,y+.08*math.sin(u*math.pi)+.34*(1-row),z-.65+row*1.30))
  poly('B1_OpenBook','Ivory',vs,[(j,j+1,j+10,j+9)for j in range(8)])
  # Readable visual impression of printed paragraphs without nonsense text.
  for i in range(7):
   dz=-.47+i*.135
   rod('B1_PageLines','HinokiEdge',(x+side*.17,y+.34*(.65-dz)/1.3+.047,z+dz),(x+side*.91,y+.34*(.65-dz)/1.3+.052,z+dz),.008,4)
 rod('B1_OpenSpine','Rust',(x,y+.34,z-.65),(x,y,z+.65),.024,8)
 # Writing cabinet in the right-hand half, not another row of book shapes.
 box('B1_RightCabinet','Cedar',(10.38,2.22,-3.65),(6.72,.84,1.84))
 box('B1_RightTop','Hinoki',(10.38,2.70,-3.65),(6.9,.12,1.98))
 for i in range(3):
  xx=8.14+i*2.23;box('B1_PaperDrawer','HinokiEdge',(xx,2.22,-2.70),(2.10,.66,.07));ell('B1_PaperPull','Brass',(xx,2.22,-2.64),(.075,.05,.025),10,4)
 # Hanging calligraphy brushes, with tapered bristles and ties.
 for xx in[7.65,13.18]:rod('B1_BrushRack','Walnut',(xx,2.78,-3.83),(xx,5.58,-3.83),.065,10)
 rod('B1_BrushRack','Walnut',(7.55,5.50,-3.83),(13.28,5.50,-3.83),.075,10)
 for i in range(8):
  xx=8.05+i*.65;yy=5.13-.08*(i%3);length=1.10+.12*(i%3)
  rod('B1_BrushTies','Brass',(xx,5.49,-3.83),(xx,yy,-3.73),.014,6)
  rod('B1_RackBrush','Hinoki',(xx,yy,-3.73),(xx,yy-length,-3.73),.045,10)
  rod('B1_RackBrush','Ink',(xx,yy-length+.03,-3.73),(xx,yy-length-.12,-3.73),.055,10)
  rod('B1_RackBrush','Paper',(xx,yy-length-.11,-3.73),(xx,yy-length-.43,-3.73),.08,12,r2=.006)
 # Upright cylindrical brush pot with a visible hollow mouth.
 lathe('B1_BrushPot','Celadon',(4.75,1.8,-1.57),[(0,.28),(.08,.33),(.78,.34),(.86,.32),(.86,.26),(.15,.25)],28)
 for i in range(5):
  xx=4.75+(i-2)*.13;endx=xx+(i-2)*.09;top=3.45+.12*(i%2)
  rod('B1_PotBrushes','Hinoki',(xx,2.0,-1.57),(endx,top,-1.55),.035,10)
  rod('B1_PotBrushes','Ink',(endx,top,-1.55),(endx,top+.12,-1.55),.048,10)
  rod('B1_PotBrushes','Paper',(endx,top+.12,-1.55),(endx,top+.44,-1.55),.062,12,r2=.006)
 # Inkstone, dark ink cake, white water dropper and bamboo brush rest.
 box('B1_Inkstone','Ink',(6.39,1.89,-1.57),(1.05,.18,1.47))
 for xx in[5.90,6.88]:box('B1_InkstoneRim','Ink',(xx,2.02,-1.57),(.08,.16,1.47))
 for zz in[-2.27,-.87]:box('B1_InkstoneRim','Ink',(6.39,2.02,zz),(1.05,.16,.08))
 box('B1_InkCake','Ink',(7.28,1.89,-1.50),(.32,.18,.95));box('B1_InkCakeMark','Brass',(7.28,1.989,-1.5),(.08,.012,.45))
 lathe('B1_WaterDropper','Ivory',(7.65,1.80,-2.27),[(0,.18),(.06,.27),(.26,.29),(.4,.15),(.46,.06)],20)
 rod('B1_WaterDropper','Ivory',(7.87,2.05,-2.27),(8.02,2.17,-2.27),.045,10,r2=.025)
 # Washi stacks and envelopes in small divided trays.
 for i,(xx,zz,k)in enumerate([(9.15,-1.55,'Moss'),(11.65,-1.55,'Indigo')]):
  tray('B1_PaperTray'+str(i),(xx,1.8,zz),(2.08,1.6))
  for j in range(4):box('B1_PaperStack'+str(i),'Paper',(xx,1.92+j*.035,zz),(1.86,.03,1.34))
  box('B1_PatternedPaper'+str(i),k,(xx,2.065,zz),(1.86,.025,1.34))
  for a in range(4):
   for b in range(3):
    cx=xx-.68+a*.45;cz=zz-.45+b*.44
    for q in range(4):
     ang=q*math.pi/2;ell('B1_PaperMotif'+str(i),'Paper',(cx+.045*math.cos(ang),2.083,cz+.045*math.sin(ang)),(.04,.006,.04),8,4)
  # Small band of cream envelopes beside the sheets, triangle flap seams visible.
  ex=xx+.03;ez=zz+.21
  box('B1_Envelope'+str(i),'Ivory',(ex,2.14,ez),(1.20,.09,.77))
  for dx in[-.55,.55]:rod('B1_EnvelopeSeam'+str(i),'HinokiEdge',(ex+dx,2.192,ez-.35),(ex,2.192,ez+.12),.011,5)
 # Rolled art paper on a stand, tall enough to give the display a varied silhouette.
 tray('B1_RollTray',(5.00,1.8,-3.62),(2.8,1.8))
 for i in range(5):
  xx=4.0+i*.46;h=1.93+.20*(i%3);rr=.18
  lathe('B1_PaperRolls','Paper',(xx,1.95,-3.62),[(0,rr),(h,rr),(h,rr-.04),(.05,rr-.04)],18)
  lathe('B1_RollBands',['Moss','Rust','Indigo'][i%3],(xx,2.5,-3.62),[(0,rr+.005),(.17,rr+.005)],18)
 # Three small postcard pictures on an airy upper shelf; original geometric scenes.
 box('B1_PostcardShelf','Hinoki',(-3.40,5.44,-4.33),(7.6,.10,.82))
 for i,k in enumerate(['Indigo','Moss','Rust']):
  xx=-5.9+i*2.45
  box('B1_Postcards','Paper',(xx,5.98,-4.30),(1.46,1.00,.06))
  poly('B1_PostcardArt'+str(i),k,[(xx-.59,5.61,-4.263),(xx-.14,6.19,-4.263),(xx+.18,5.85,-4.263),(xx+.42,6.05,-4.263),(xx+.59,5.61,-4.263)],[(0,1,2),(0,2,4),(2,3,4)])
  ell('B1_PostcardSun','HinokiEdge',(xx+.38,6.20,-4.26),(.09,.09,.009),12,5)

def lights():
 for i,x in enumerate([-4.0,10.5]):
  z=-2.4;g='B1_WindowLamp'+str(i)
  rod(g,'Ink',(x,6.65,z),(x,6.37,z),.020,8)
  lathe(g,'Paper',(x,5.94,z),[(0,.17),(.07,.40),(.24,.46),(.42,.29),(.47,.12)],24)
  for yy,rr in[(6.01,.40),(6.18,.46),(6.36,.29)]:torus(g,'HinokiEdge',(x,yy,z),rr,.012,24,5)

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
  if k in WOOD|{'Stone'}:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Soft edge','BEVEL');mod.width=.015;mod.segments=2;mod.limit_method='ANGLE';bpy.ops.object.modifier_apply(modifier=mod.name)
  if g=='B1_OpenBook':
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Page block','SOLIDIFY');mod.thickness=.055;bpy.ops.object.modifier_apply(modifier=mod.name)
  OBJECTS.append(o)
 for name,pos in[('B1_Origin',(0,0,0)),('B1_Right',(2,0,0)),('B1_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.05,location=P(pos));o=bpy.context.object;o.name=name;OBJECTS.append(o)

def render():
 def block(name,k,c,s):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.name='CTX_'+name;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat(k));return o
 # Observed existing architecture represented for context only, excluded from FBX.
 block('Lane','Stone',(0,-.71,5),(43,.26,12))
 block('Foundation','Stone',(0,-.65,-8),(30.8,.45,23))
 for x in[-15,15]:block('ExistingPosts','Walnut',(x,9.80,0),(.52,21.7,.52))
 block('ExistingLintel','Cedar',(0,7.61,0),(30,.55,.50))
 block('ExistingUpperBeam','Walnut',(0,8.61,.20),(30.25,.35,.48))
 block('ExistingUpperWall','Cedar',(0,12.8,-.35),(30,8,.20))
 block('ExistingBalconyFloor','Walnut',(0,9.11,1.4),(29,.32,2.7))
 for yy in[9.56,11.1]:block('ExistingBalconyRail','Walnut',(0,yy,2.66),(29,.14,.16))
 for i in range(40):block('ExistingBalconySlat','Cedar',(-14.2+i*.72,10.32,2.66),(.08,1.6,.10))
 for z,y,w in[(.1,8.7,31.2),(1.3,8.45,31.4),(2.5,8.2,31.6),(3.7,7.95,31.8)]:block('AwningTile','Indigo',(0,y,z),(w,.14,1.35))
 for i in range(13):block('EaveRafters','Walnut',(-14.5+i*2.4,8.23,1.4),(.13,.18,3.8))
 block('ExistingGutter','Walnut',(0,8.31,3.90),(31.4,.14,.17))
 # Existing plants/lantern are retained; proxy silhouettes are not exported.
 for x in[-14,13.7]:
  bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=.53,radius2=.72,depth=1.45,location=P((x,.01,2.3)));o=bpy.context.object;o.name='CTX_ExistingPot';o.data.materials.append(mat('Rust'))
  for dx,yy,dz in[(-.38,1.42,0),(.30,1.57,.1),(0,2.13,0)]:
   bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=P((x+dx,yy,2.3+dz)));o=bpy.context.object;o.scale=(.7,.63,.85);o.name='CTX_ExistingLeaves';o.data.materials.append(mat('Leaf'))
 # Small paper lantern already present at the left edge of the display.
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=1,location=P((-6.1,6.06,2.5)));o=bpy.context.object;o.scale=(.72,.72,1.1);o.name='CTX_ExistingLantern';o.data.materials.append(mat('Paper'))
 for k in WOOD:
  m=mat(k);n=m.node_tree.nodes;l=m.node_tree.links;bs=n['Principled BSDF'];tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=3;tex.inputs['Detail'].default_value=2
  co=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='MULTIPLY';scale.inputs[1].default_value=(.2,5,3);l.new(co.outputs['Object'],scale.inputs[0]);l.new(scale.outputs[0],tex.inputs['Vector'])
  ramp=n.new('ShaderNodeValToRGB');c=tuple(lin(v)for v in COL[k]);ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[0].color=tuple(v*.88 for v in c)+(1,);ramp.color_ramp.elements[1].position=.85;ramp.color_ramp.elements[1].color=tuple(min(1,v*1.10)for v in c)+(1,);l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color'])
 for r in LABELS:
  cu=bpy.data.curves.new('Preview text','FONT');cu.body=r['text'];cu.align_x='CENTER';cu.align_y='CENTER';cu.size=r['previewSize'];cu.font=bpy.data.fonts.load('C:/Windows/Fonts/YuGothR.ttc')
  o=bpy.data.objects.new('CTX_Text',cu);bpy.context.collection.objects.link(o);o.location=P(r['position']);o.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat('Paper'if 'MainSign'in r['name']else'Walnut'))
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.resolution_x=1600;sc.render.resolution_y=1000;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
 sc.world=bpy.data.worlds.new('Daylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.72,.85,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.55
 def area(name,p,energy,size,target):
  d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=P(p);o.rotation_euler=(Vector(P(target))-o.location).to_track_quat('-Z','Y').to_euler()
 area('Daylight',(0,9,12),2600,20,(0,3,0));area('WarmWindow',(-2,5.9,-1.9),320,7,(0,1.8,-3));area('WarmWindow2',(10,5.9,-1.9),260,6,(10,1.8,-3))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 for name,eye,target,lens in[('01_storefront',(-5,6.1,36),(0,3.7,-.7),40),('02_window',(3.5,5.0,15.5),(3.35,3.8,-2.4),33),('03_writing_goods',(10.2,4.6,6.1),(9.0,3.20,-2.65),45)]:
  sc.render.resolution_y=760 if name=='01_storefront'else 1000
  cam.location=P(eye);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens;sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);log('RENDER '+name)
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bookshop1_review.blend'))

try:
 LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True)
 frame();displays();lights();build_objects()
 root=bpy.data.objects.new('bookshop1',None);bpy.context.collection.objects.link(root)
 manifest={'root':'bookshop1','origin':[5987,1.03985318,-65],'yaw':90,'materials':{k:{'rgb':v,'material':'Wood'if k in WOOD else'Plaster'if k=='Wall'else'Slate'if k=='Stone'else'Metal'if k=='Brass'else'SmoothPlastic'}for k,v in COL.items()},'labels':LABELS,'meshes':[]}
 for o in OBJECTS:
  o.parent=root;q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  rec={'name':o.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
  assert rec['triangles']<10000,rec;manifest['meshes'].append(rec)
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in OBJECTS:o.select_set(True)
 fbx=OUT/'japan_kit35_book_stationery1.fbx';bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False)
 log('EXPORTED '+str(len(OBJECTS))+' meshes, '+str(sum(x['triangles']for x in manifest['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
 assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(manifest['meshes'])
 for rec in manifest['meshes']:
  o=bpy.data.objects[rec['name']];q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  assert all(abs(min(p[i]for p in q)-rec['min'][i])<.003 and abs(max(p[i]for p in q)-rec['max'][i])<.003 for i in range(3)),rec['name']
  if rec['name']in{'B1_Origin','B1_Right','B1_Front'}:o.hide_render=True
 log('ROUNDTRIP_PASS: all names and bounds within .003 studs')
 for k in['Glass']:
  # Approximate the .96 transparent SmoothPlastic pane used by the installer.
  m=mat(k);nodes=m.node_tree.nodes;links=m.node_tree.links;bs=nodes['Principled BSDF'];bs.inputs['Transmission Weight'].default_value=0;bs.inputs['Roughness'].default_value=.4
  transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader');mix.inputs[0].default_value=.04;links.new(transparent.outputs[0],mix.inputs[1]);links.new(bs.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes['Material Output'].inputs['Surface'])
 render();log('BOOKSHOP1_DONE')
except Exception:
 log(traceback.format_exc());log('BOOKSHOP1_FAILED');raise
