"""Mikan 2: measured Kyoto produce/pickle grocer, mesh-only kit.
Local x is along the frontage, y up from the existing shop floor, +z OUT.
World transform after import: (6013, 1.03985, -158) * Ry(-90 degrees).
Research: Takakuraya shop / Nishiki market association; Yontora produce shop.
Export once, render the same meshes in a measured existing-shell stand-in.
"""
import bpy, math, os, json, traceback, random
from mathutils import Vector, Matrix
from collections import defaultdict

D=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(D,'out_mikan2')
os.makedirs(OUT,exist_ok=True)
LOG=os.path.join(OUT,'build_log.txt')
R=random.Random(1001)
COL={
 'Timber':(65,47,35),'TimberEdge':(87,62,42),'Cedar':(149,108,65),
 'CedarLight':(177,134,86),'CedarPale':(197,156,103),'CedarDark':(124,86,49),
 'Hoop':(86,75,53),'Tile':(72,76,80),'TileEdge':(93,96,96),'Stone':(120,116,105),
 'Sage':(87,112,86),'Cream':(231,222,197),'Paper':(236,220,179),'Ink':(60,46,33),
 'Orange':(229,137,41),'OrangeLight':(242,165,61),'Leaf':(70,117,58),'LeafLight':(126,163,83),
 'Radish':(225,225,197),'Purple':(78,50,93),'Cucumber':(79,116,48),'PickleRed':(151,65,77),
 'PickleGold':(202,168,74),'PickleBrine':(143,116,64),'Carrot':(218,123,43),
 'Bottle':(79,91,54),'BottleBrown':(111,61,34),'Ceramic':(119,142,138),'Brass':(158,132,75),
 'DarkMetal':(55,59,56),'Black':(30,32,29),'ClothBag':(200,182,144)
}
ROBLOX_MATERIAL={k:('Wood' if k in {'Timber','TimberEdge','Cedar','CedarLight','CedarPale','CedarDark','Hoop'} else
 'Slate' if k in {'Tile','TileEdge','Stone'} else 'Fabric' if k in {'Sage','Cream','ClothBag'} else
 'Metal' if k in {'Brass','DarkMetal'} else 'SmoothPlastic') for k in COL}
G={}; LABELS=[]; FIXTURES={}; OBJS=[]; PREVIEW=[]
def log(s):
 with open(LOG,'a',encoding='utf8') as f:f.write(str(s)+'\n')
 print(s,flush=True)
def P(p):return (p[0],-p[2],p[1])
def linear(n):
 n=n/255
 return n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4
def mat(k):
 m=bpy.data.materials.get(k)
 if m:return m
 m=bpy.data.materials.new(k);m.use_nodes=True
 c=tuple(linear(n) for n in COL[k])+(1,)
 m.diffuse_color=c
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=c
 bs.inputs['Roughness'].default_value=.72
 return m
def geo(group,key):
 return G.setdefault((group,key),[[],[]])
def poly(group,key,vs,fs):
 v,f=geo(group,key);n=len(v);v.extend(vs);f.extend([tuple(n+i for i in face) for face in fs])
def box(g,k,c,s,bevel=0):
 x,y,z=c;a,b,d=[q/2 for q in s]
 vs=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 poly(g,k,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)])
def ellipsoid(g,k,c,s,segments=10,rings=6,angle=0):
 vs=[];fs=[]
 for i in range(rings+1):
  t=math.pi*i/rings
  for j in range(segments):
   a=math.tau*j/segments;xx=s[0]*math.sin(t)*math.cos(a);zz=s[2]*math.sin(t)*math.sin(a)
   vs.append((c[0]+xx*math.cos(angle)+zz*math.sin(angle),c[1]+s[1]*math.cos(t),c[2]-xx*math.sin(angle)+zz*math.cos(angle)))
 for i in range(rings):
  for j in range(segments):fs.append((i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j))
 poly(g,k,vs,fs)
def rod(g,k,a,b,r,n=8,r2=None):
 a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0)))
 if u.length<.01:u=d.cross(Vector((1,0,0)))
 u.normalize();v=d.cross(u).normalized();vs=[]
 for c,rr in [(a,r),(b,r if r2 is None else r2)]:
  for j in range(n):vs.append(tuple(c+rr*(u*math.cos(math.tau*j/n)+v*math.sin(math.tau*j/n))))
 fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
 poly(g,k,vs,fs)
def ring(g,k,c,r,thick,h,n=24):
 vs=[];fs=[]
 for rr,yy in [(r-thick,c[1]-h/2),(r,c[1]-h/2),(r,c[1]+h/2),(r-thick,c[1]+h/2)]:
  for j in range(n):vs.append((c[0]+rr*math.cos(math.tau*j/n),yy,c[2]+rr*math.sin(math.tau*j/n)))
 for a,b in [(0,1),(1,2),(2,3),(3,0)]:
  for j in range(n):fs.append((a*n+j,a*n+(j+1)%n,b*n+(j+1)%n,b*n+j))
 poly(g,k,vs,fs)
def leaf(g,k,a,b,width):
 a,b=Vector(a),Vector(b);d=b-a;side=Vector((d.z,0,-d.x))
 if side.length<.01:side=Vector((1,0,0))
 side.normalize();mid=a+d*.52+Vector((0,.12,0));l=mid-side*width/2;r=mid+side*width/2
 poly(g,k,[tuple(a),tuple(l),tuple(mid+Vector((0,.05,0))),tuple(r),tuple(b)],[(0,1,2),(0,2,3),(1,4,2),(2,4,3),(2,1,0),(3,2,0),(2,4,1),(3,4,2)])
def tub(g,c,r=1.6,h=2.7):
 x,y,z=c;N=24
 # Open, separately articulated staves, with a real inner surface and visible lip.
 for j in range(N):
  a=math.tau*j/N+.006;b=math.tau*(j+1)/N-.006
  vs=[]
  for yy,rr in [(y,r*.88),(y+h*.5,r*.97),(y+h,r)]:
   for rad in [rr-.13,rr]:
    for ang in [a,b]:vs.append((x+rad*math.cos(ang),yy,z+rad*math.sin(ang)))
  fs=[(0,2,3,1),(8,9,11,10)]
  for t in [0,4]:fs += [(t,t+1,t+5,t+4),(t+2,t+6,t+7,t+3),(t,t+4,t+6,t+2),(t+1,t+3,t+7,t+5)]
  poly(g,['CedarLight','CedarPale','Cedar'][j%3],vs,fs)
 for yy in [.25,h*.48,h-.26]:ring(g,'Hoop',(x,y+yy,z),r*(.88+.12*yy/h)+.045,.065,.12)
 rod(g,'CedarDark',(x,y+.08,z),(x,y+.2,z),r*.84,24)
def crate(g,c,w=4.6,d=2.1,h=.65):
 x,y,z=c
 for i in range(5):box(g,'CedarLight',(x-w/2+w*(i+.5)/5,y+.06,z),(w/5-.025,.12,d))
 for dz in [-d/2,d/2]:
  for j in range(2):box(g,'Cedar',(x,y+.21+j*.28,z+dz),(w,.21,.11))
 for dx in [-w/2,w/2]:
  for j in range(2):box(g,'CedarLight',(x+dx,y+.21+j*.28,z),(.11,.21,d))
 for dx in [-w/2+.14,w/2-.14]:
  for dz in [-d/2+.1,d/2-.1]:box(g,'CedarDark',(x+dx,y+h/2,z+dz),(.17,h,.17))
def produce(g,kind,c,scale=1,angle=0):
 x,y,z=c;s=scale
 if kind=='mikan':
  ellipsoid(g,'Orange' if R.random()<.65 else 'OrangeLight',c,(.34*s,.29*s,.34*s),12,7)
  rod(g,'Leaf',(x,y+.25*s,z),(x,y+.34*s,z),.055*s,6)
  if R.random()<.25:leaf(g,'Leaf',(x,y+.3*s,z),(x+.33*s,y+.4*s,z+.1*s),.16*s)
 elif kind=='cabbage':
  ellipsoid(g,'LeafLight',c,(.55*s,.46*s,.52*s),12,8)
  for j in range(6):
   a=math.tau*j/6;leaf(g,'Leaf' if j%2 else 'LeafLight',(x,y-.25*s,z),(x+.65*s*math.cos(a),y+.3*s,z+.65*s*math.sin(a)),.6*s)
 elif kind in ('daikon','carrot'):
  dx,dz=math.sin(angle),math.cos(angle);k='Radish' if kind=='daikon' else 'Carrot'
  a=(x-dx*.75*s,y,z-dz*.75*s);b=(x+dx*.55*s,y+.08*s,z+dz*.55*s)
  rod(g,k,a,b,.05*s,10,.23*s if kind=='daikon' else .17*s)
  for j in [-1,0,1]:leaf(g,'Leaf',b,(b[0]+dx*.5*s+j*.24*s,b[1]+.25*s,b[2]+dz*.6*s),.25*s)
 elif kind in ('eggplant','cucumber'):
  k='Purple' if kind=='eggplant' else 'Cucumber';sz=(.26,.23,.58) if kind=='eggplant' else (.16,.16,.65)
  ellipsoid(g,k,c,tuple(t*s for t in sz),10,7,angle)
  rod(g,'Leaf',(x+math.sin(angle)*.48*s,y,z+math.cos(angle)*.48*s),(x+math.sin(angle)*.7*s,y+.08*s,z+math.cos(angle)*.7*s),.07*s,6)
def label(name,text,c,w=1.4,h=.65,post=0):
 if post:box(name+'_stem','CedarDark',(c[0],c[1]-.5*post,c[2]-.03),(.08,post,.08))
 box(name,'Paper',c,(w,h,.055));LABELS.append({'name':name+'_Paper','text':text,'width':w,'height':h,'front':[0,0,1]})
def board_goods(g,kind,c,w=4.6,d=2.1):
 crate(g,c,w,d)
 if kind in ('mikan','cabbage'):
  nx=6 if kind=='mikan' else 3
  for j in range(2):
   for i in range(nx):produce(g,kind,(c[0]-w/2+.5+i*(w-1)/(nx-1),c[1]+.46,c[2]-.48+j*.88),.85 if kind=='mikan' else .9,R.random())
  if kind=='mikan':
   for i in range(5):produce(g,kind,(c[0]-1.55+i*.75,c[1]+.9,c[2]),.87)
 else:
  for i in range(6):produce(g,kind,(c[0]-w/2+.45+i*(w-.9)/5,c[1]+.43,c[2]),.9,(R.random()-.5)*.18)

def make_facade():
 # Shallow wall-supported tile eave. No street posts.
 g='M2_Facade'
 vs=[(x,y,z) for x in [-13,13] for y,z in [(9.64,-.15),(9.80,-.15),(9.23,2.15),(9.07,2.15)]]
 poly(g,'Tile',vs,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
 for i in range(40):
  x=-12.7+i*.65
  rod(g,'TileEdge',(x,9.82,-.1),(x,9.26,2.14),.085,8)
  rod(g,'Tile',(x,9.16,2.1),(x,9.16,2.24),.12,10)
 for z,y in [(0,9.48),(2.0,8.98)]:box(g,'Timber',(0,y,z),(26,.3,.3))
 for x in [-11.8,-4.8,4.8,11.8]:rod(g,'TimberEdge',(x,8.35,.05),(x,9.02,1.85),.105,4)
 # Flush frame, small slatted cheeks, no detached sign.
 for x in [-12.05,11.95]:
  box(g,'Timber',(x,4.1,-.08),(.25,8.2,.32))
  for j in range(4):box(g,'TimberEdge',(x+(.12*j if x<0 else -.12*j),3.8,-.04),(.055,6.9,.16))
 # A short split noren over the left entry, fully above avatar head height.
 for i in range(3):
  x=-10.7+i*1.9;vs=[]
  for iy in range(5):
   for ix in range(7):
    xx=x-.86+1.72*ix/6;yy=8.28-1.02*iy/4;zz=.12+.045*math.sin(ix*2.0)+.02*iy
    vs.append((xx,yy,zz))
  fs=[]
  for iy in range(4):
   for ix in range(6):a=iy*7+ix;fs.append((a,a+1,a+8,a+7));fs.append((a+7,a+8,a+1,a))
  poly(g,'Sage',vs,fs)
 rod(g,'Timber',(-11.8,8.35,.04),(-5.9,8.35,.04),.065)
 for x in [-11.25,11.15]:
  rod(g,'DarkMetal',(x,8.7,.2),(x,8.7,.85),.045)
  rod(g,'DarkMetal',(x,8.7,.85),(x,7.9,.85),.028)
  ellipsoid(g,'Cream',(x,7.04,.85),(.5,.86,.5),16,12)
  for j in range(11):
   yy=-.72+j*.144;rr=.5*math.sqrt(max(.01,1-(yy/.86)**2))
   ring(g,'CedarDark',(x,7.04+yy,.85),rr+.008,.014,.023,20)
  for yy in [6.2,7.88]:rod(g,'Timber',(x,yy-.045,.85),(x,yy+.045,.85),.25,16)
 # Measured 0.58 rise from lane to shop floor, in two comfortable treads.
 box('M2_Threshold','Stone',(-8.7,-.435,1.42),(6.4,.29,.8))
 box('M2_Threshold','Stone',(-8.7,-.155,.72),(6.4,.29,1.0))

def make_produce():
 g='M2_Produce'
 for x in [-3.7,3.5,10.7]:
  for z in [-.65,-3.75]:box(g,'TimberEdge',(x,1.22,z),(.28,2.44,.28))
 for y,z in [(2.03,-1.25),(3.18,-3.0)]:
  box(g,'CedarDark',(3.5,y,z),(15.0,.16,2.28))
 for x in [-3.5,10.5]:rod(g,'TimberEdge',(x,.3,-.7),(x,2.9,-3.7),.1,4)
 box(g,'TimberEdge',(3.5,.45,-.75),(14.6,.16,.16))
 kinds=['mikan','cabbage','eggplant','daikon','carrot','cucumber']
 txt=['みかん  MIKAN','キャベツ  CABBAGE','なす  EGGPLANT','大根  DAIKON','にんじん  CARROTS','きゅうり  CUCUMBER']
 for row in range(2):
  for i in range(3):
   idx=row*3+i;x=-1.45+i*4.95;y=2.13+row*1.15;z=-1.23-row*1.9
   board_goods(g,kinds[idx],(x,y,z),4.6,1.95)
   label('M2_Label_produce'+str(idx),txt[idx],(x,y+.25,z+1.04),2.0,.49)
 # Tidy nested empty produce boxes under the display.
 for x in [-1.4,3.5,8.4]:crate(g,(x,0,-2.9),3.6,1.7,.65)
 FIXTURES['produce']={'min':[-4.0,0,-4.25],'max':[11.1,4.65,-.15]}

def make_pickles():
 for i,(z,kind,text) in enumerate([(-7.6,'cucumber','胡瓜漬  CUCUMBER'),(-12.1,'gold','大根漬  DAIKON'),(-16.6,'red','しば漬  SHIBAZUKE')]):
  g='M2_Pickle'+str(i);x=9.7;tub(g,(x,0,z),1.6,2.7)
  rod(g,'PickleBrine',(x,2.35,z),(x,2.42,z),1.43,24)
  for j in range(28):
   a=R.random()*math.tau;rr=math.sqrt(R.random())*1.15;cx=x+rr*math.cos(a);cz=z+rr*math.sin(a)
   if kind=='cucumber':produce(g,'cucumber',(cx,2.55+R.random()*.12,cz),.64,R.random()*math.tau)
   else:ellipsoid(g,'PickleGold' if kind=='gold' else 'PickleRed',(cx,2.5+R.random()*.18,cz),(.23,.1,.32),8,4,R.random()*math.tau)
  label('M2_Label_pickle'+str(i),text,(x,3.35,z-.55),2.25,.65,.9)
  # Resting wooden tongs on the rim.
  for dx in [-.045,.045]:rod(g,'CedarPale',(x-1.3+dx,2.88,z-.65),(x-.8+dx,2.84,z+.75),.035,4)
  FIXTURES['pickle'+str(i)]={'min':[x-1.65,0,z-1.65],'max':[x+1.65,3.7,z+1.65]}

def make_pantry():
 g='M2_Pantry';x0,x1=-5.6,11.7
 for x in [x0,x0+5.8,x0+11.6,x1]:box(g,'TimberEdge',(x,3.35,-20.22),(.22,6.7,.35))
 for y in [.35,2.25,4.15,6.05]:
  box(g,'Cedar',(3.05,y,-20.15),(17.6,.16,2.25))
  box(g,'CedarDark',(3.05,y+.06,-18.99),(17.6,.22,.08))
 for y in [.43,2.33,4.23]:
  for i in range(13):
   x=-4.95+i*1.27;z=-20.0;kind=(i+int(y))%4
   if kind==0:
    # Folded paper grocery packets with a paper label band.
    box(g,'ClothBag',(x,y+.55,z),(.68,1.1,.7));box(g,'CedarPale',(x,y+1.08,z),(.72,.08,.72))
    box(g,'Paper',(x,y+.58,z+.356),(.5,.4,.025))
   elif kind==1:
    rod(g,'BottleBrown',(x,y,z),(x,y+.8,z),.27,12,.25)
    rod(g,'BottleBrown',(x,y+.8,z),(x,y+1.16,z),.11,10)
    rod(g,'Timber',(x,y+1.16,z),(x,y+1.27,z),.135,10)
    ring(g,'Paper',(x,y+.44,z),.276,.012,.32,12)
   elif kind==2:
    rod(g,'Ceramic',(x,y,z),(x,y+.8,z),.36,14,.32)
    rod(g,'CedarLight',(x,y+.8,z),(x,y+.92,z),.36,14)
    box(g,'Paper',(x,y+.42,z+.33),(.44,.35,.035))
   else:
    box(g,'Sage',(x,y+.48,z),(.64,.96,.62));box(g,'Paper',(x,y+.48,z+.32),(.36,.62,.025))
 for i,(x,txt) in enumerate([(-2.65,'お茶  TEA'),(3.05,'調味料  PANTRY'),(8.7,'乾物  DRY GOODS')]):label('M2_Label_pantry'+str(i),txt,(x,6.43,-18.98),3.1,.55)
 FIXTURES['pantry']={'min':[-5.75,0,-21.3],'max':[11.85,6.75,-18.9]}

def make_counter():
 g='M2_Counter';x,z=-8.5,-15.0
 for dx in [-2.25,2.25]:
  for dz in [-1.4,1.4]:box(g,'TimberEdge',(x+dx,1.45,z+dz),(.26,2.9,.26))
 box(g,'CedarLight',(x,3.02,z),(5.1,.25,3.4))
 for j in range(10):box(g,'Cedar',(x-2.15+j*.48,1.55,z+1.45),(.44,2.55,.12))
 for dz in [-1.4,1.4]:box(g,'TimberEdge',(x,2.87,z+dz),(4.7,.2,.16))
 # Antique weighing scale with a shallow pan, dial and sturdy base.
 box(g,'DarkMetal',(x-1.1,3.28,z+.1),(1.4,.26,1.2))
 rod(g,'DarkMetal',(x-1.1,3.4,z+.1),(x-1.1,4.08,z+.1),.17,12)
 ellipsoid(g,'Brass',(x-1.1,4.16,z+.1),(.72,.16,.62),16,6)
 ring(g,'Brass',(x-1.1,4.23,z+.1),.66,.045,.08,24)
 rod(g,'Cream',(x-1.1,3.68,z+.35),(x-1.1,3.68,z+.48),.34,20)
 rod(g,'DarkMetal',(x-1.1,3.68,z+.49),(x-1.24,3.89,z+.49),.018,6)
 for j in range(4):box(g,'Paper',(x+.9,3.19+j*.035,z+.25),(1.45,.03,1.0))
 box(g,'CedarDark',(x+1.7,3.3,z-.8),(.7,.35,.65))
 FIXTURES['counter']={'min':[-11.05,0,-16.7],'max':[-5.95,4.35,-13.3]}

def make_lining():
 g='M2_Lining'
 box(g,'Cream',(0,6.1,-21.45),(24.25,7.3,.1))
 # Warm low timber lining, fitted just inside existing walls; no change to shop backs.
 for side in [-1,1]:
  x=side*12.18
  for i in range(27):box(g,'CedarDark' if i%4 else 'Cedar',(x,1.18,-.55-i*.77),(.12,2.36,.72))
  box(g,'TimberEdge',(x,2.43,-10.7),(.17,.16,21.0))
 for i in range(30):box(g,'CedarDark' if i%4 else 'Cedar',(-11.9+i*.8,1.18,-21.64),(.75,2.36,.13))
 box(g,'TimberEdge',(0,2.43,-21.6),(24.3,.16,.18))
 # Fitted ceiling boards above the existing exposed beams.
 for i in range(39):box('M2_Ceiling','CedarLight',(0,10.01,-.6-i*.54),(24.2,.08,.515))
 for z in [-7.5,-16.5]:
  rod(g,'DarkMetal',(-1,9.97,z),(-1,8.45,z),.035)
  ellipsoid(g,'Cream',(-1,8.1,z),(.62,.35,.62),16,8)
  ring(g,'Timber',(-1,8.12,z),.62,.035,.05)

def create_objects():
 for (g,k),(vs,fs) in G.items():
  me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v) for v in vs],[],fs);me.update()
  o=bpy.data.objects.new(g+'_'+k,me);bpy.context.scene.collection.objects.link(o);me.materials.append(mat(k))
  # Repair winding and weld pole duplicates without flattening intentionally open details.
  import bmesh
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  uv=bm.loops.layers.uv.new('UVMap')
  for f in bm.faces:
   ax=max(range(3),key=lambda i:abs(f.normal[i]))
   for l in f.loops:
    c=l.vert.co;u,v=((c.y,c.z),(c.x,c.z),(c.x,c.y))[ax];l[uv].uv=(u/4,v/4)
  bm.to_mesh(me);bm.free()
  if k in {'Orange','OrangeLight','Purple','Cucumber','Radish','Carrot','Bottle','BottleBrown','Ceramic','Brass','PickleRed','PickleGold'} or (k=='Cream' and g=='M2_Facade'):
   for face in me.polygons:face.use_smooth=True
  # Small bevels are actual exported geometry, not a render-only effect.
  if k in {'Timber','TimberEdge','Cedar','CedarDark','CedarLight','CedarPale','Stone'}:
   bpy.context.view_layer.objects.active=o;o.select_set(True)
   mod=o.modifiers.new('Soft hand-worked edges','BEVEL');mod.width=.025;mod.segments=1
   bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
  OBJS.append(o)
 for name,c in [('M2_Origin',(0,0,0)),('M2_Right',(2,0,0)),('M2_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.06,location=P(c));o=bpy.context.object;o.name=name;OBJS.append(o)
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)

def add_context():
 # Measured shell only. The original roof is approximated here; Studio preview is authoritative.
 def block(name,c,s,col):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.name='CTX_'+name;o.scale=(s[0],s[2],s[1]);o.data.materials.append(mat(col));PREVIEW.append(o);return o
 block('Floor',(0,-.15,-11.0),(25,.3,22.5),'CedarDark')
 block('BackWall',(0,4.56,-22),(25,10.9,.4),'Cream')
 for x in [-12.5,12.5]:block('SideWall',(x,4.56,-11),(.4,10.9,22),'Cedar')
 for x in [-12.5,12.5]:
  for z in [0,-22]:block('Post',(x,4.56,z),(.52,11.2,.52),'Timber')
 for z in [-2,-6,-10,-14,-18]:block('Beam',(0,9.81,z),(25.8,.28,.3),'Timber')
 for name,yz in [('RoofA',[(9.81,2),(13.3,-11)]),('RoofB',[(13.3,-11),(9.81,-24)])]:
  vs=[P((x,y+dy,z)) for x in [-15,15] for y,z in yz for dy in [0,.15]]
  me=bpy.data.meshes.new(name);me.from_pydata(vs,[],[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]);me.update()
  o=bpy.data.objects.new('CTX_'+name,me);bpy.context.scene.collection.objects.link(o);me.materials.append(mat('Tile'));PREVIEW.append(o)
 block('Lane',(0,-.75,12),(85,.35,26),'Stone')
 block('Sign',(4.25,8.41015,.5),(13,1.9,.13),'Timber')
 # Preview lettering only; the real existing sign remains in Studio.
 preview_text('MIKAN  GREENGROCER',(4.25,8.35,.58),.56,'Paper',13)
 for a in LABELS:
  o=bpy.data.objects.get(a['name']);c=o.dimensions # panel centre from vertex geometry
  pts=[o.matrix_world@v.co for v in o.data.vertices];mn=Vector(tuple(min(p[i] for p in pts) for i in range(3)));mx=Vector(tuple(max(p[i] for p in pts) for i in range(3)));p=(mn+mx)/2
  # Use short English on Blender mockup; Studio labels carry both languages.
  text=a['text'].split('  ')[-1];preview_text(text,(p.x,p.z,-p.y+.04),min(.19,a['height']*.32),'Ink',a['width']*.92)
def preview_text(text,c,size,key,width):
 cu=bpy.data.curves.new('caption','FONT');cu.body=text;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=size;cu.extrude=.001
 o=bpy.data.objects.new('CTX_text',cu);bpy.context.scene.collection.objects.link(o);o.location=P(c);o.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat(key));PREVIEW.append(o)

def render():
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
 sc.render.resolution_x=1400;sc.render.resolution_y=900;sc.render.resolution_percentage=100
 if not sc.world:sc.world=bpy.data.worlds.new('Market daylight')
 sc.world.color=(.55,.55,.55);sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.6,.7,.9,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
 sc.view_settings.view_transform='AgX'
 def light(name,loc,power,size):
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);sc.collection.objects.link(o);o.location=P(loc);o.rotation_euler=(Vector(P((0,2,-5)))-o.location).to_track_quat('-Z','Y').to_euler()
 light('Front daylight',(-15,22,18),4500,20)
 light('Open frontage fill',(3,10,10),2200,14)
 for z in [-7.5,-16.5]:
  data=bpy.data.lights.new('Shop lamp','POINT');data.energy=310;data.color=(1,.83,.64);data.shadow_soft_size=1.4;o=bpy.data.objects.new('Shop lamp',data);sc.collection.objects.link(o);o.location=P((-1,7.7,z))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 for fn,loc,target,lens in [('01_front',(18,6.3,27),(0,4,-2),37),('02_inside',(-8.7,5.4,-1.8),(3,3.3,-14),24),('03_barrels',(1.6,5.2,-4.8),(9.6,2.1,-11.5),32),('04_produce',(2,5.0,7.5),(3.5,2.5,-2.2),34)]:
  cam.location=P(loc);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
  sc.render.filepath=os.path.join(OUT,fn+'.png');bpy.ops.render.render(write_still=True);log('RENDER '+fn)

try:
 open(LOG,'w').close();bpy.ops.wm.read_factory_settings(use_empty=True)
 make_facade();make_produce();make_pickles();make_pantry();make_counter();make_lining();create_objects()
 root=bpy.data.objects.new('mikan_grocer2',None);bpy.context.scene.collection.objects.link(root)
 for o in OBJS:o.parent=root
 manifest={'root':'mikan_grocer2','origin':[6013,1.03985,-158],'yaw':-90,'materials':{k:{'rgb':list(v),'material':ROBLOX_MATERIAL[k]} for k,v in COL.items()},'labels':LABELS,'fixtures':FIXTURES,'meshes':[]}
 for o in OBJS:
  vs=[o.matrix_world@v.co for v in o.data.vertices];q=[(p.x,p.z,-p.y) for p in vs]
  mn=[min(p[i] for p in q) for i in range(3)];mx=[max(p[i] for p in q) for i in range(3)];tris=sum(len(p.vertices)-2 for p in o.data.polygons)
  manifest['meshes'].append({'name':o.name,'min':mn,'max':mx,'triangles':tris})
  assert tris<10000,(o.name,tris)
 # All movable merchandise and furniture are inside the original facade; only eave/threshold project.
 for m in manifest['meshes']:
  if any(m['name'].startswith('M2_'+p) for p in ['Produce','Pickle','Pantry','Counter']):assert m['max'][2]<=.01,m['name']
 json.dump(manifest,open(os.path.join(OUT,'manifest.json'),'w'),indent=2,ensure_ascii=False)
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in OBJS:o.select_set(True)
 bpy.context.view_layer.objects.active=OBJS[0]
 bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'japan_kit22_mikan_grocer2.fbx'),use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'EMPTY','MESH'})
 log('EXPORTED '+str(len(OBJS))+' meshes; '+str(sum(m['triangles'] for m in manifest['meshes']))+' triangles')
 # Validate the exported file itself, and render its round-trip geometry.
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=os.path.join(OUT,'japan_kit22_mikan_grocer2.fbx'),axis_forward='-Z',axis_up='Y')
 OBJS=[o for o in bpy.data.objects if o.type=='MESH']
 assert len(OBJS)==len(manifest['meshes']),('round-trip mesh count',len(OBJS))
 for record in manifest['meshes']:
  o=bpy.data.objects.get(record['name']);assert o is not None,record['name']
  q=[(p.x,p.z,-p.y) for p in [o.matrix_world@v.co for v in o.data.vertices]]
  for i in range(3):
   assert abs(min(p[i] for p in q)-record['min'][i])<.003,(record['name'],'min',i)
   assert abs(max(p[i] for p in q)-record['max'][i])<.003,(record['name'],'max',i)
 log('ROUNDTRIP_PASS: all exported mesh names and bounds match within 0.003 studs')
 for o in OBJS:
  if o.name in {'M2_Origin','M2_Right','M2_Front'}:o.hide_render=True
 add_context();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'mikan2_review.blend'));render()
 log('MIKAN2_DONE')
except Exception:
 log(traceback.format_exc());log('MIKAN2_FAILED')
