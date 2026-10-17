# Cat cafe 1: reference-led mesh furnishings for the measured existing machiya.
# Local x along frontage, y up, +z out; target (6014, 1.03985, 7), Ry(-90).
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

# Cat cafe 1: fitted furniture for the measured, retained machiya facade.
OUT=os.path.join(D,'out_catcafe1');os.makedirs(OUT,exist_ok=True)
LOG=os.path.join(OUT,'build_log.txt')
G={};LABELS=[];FIXTURES={};OBJS=[];PREVIEW=[];SEATS=[];CAT_SPOTS=[]
COL.update({'Oak':(163,119,77),'OakLight':(190,150,104),'OakDark':(116,81,52),
 'Wall':(231,223,201),'SageSoft':(132,151,121),'Rose':(170,119,114),
 'Indigo':(66,87,105),'Rope':(194,170,124),'Rug':(207,195,158),
 'Tea':(105,117,58),'White':(236,228,209),'Glass':(200,219,213)})
for k in COL:
 ROBLOX_MATERIAL[k]=('Wood' if k in {'Oak','OakLight','OakDark','Timber','TimberEdge','Cedar','CedarLight','CedarDark','CedarPale'} else 'Fabric' if k in {'SageSoft','Rose','Indigo','Rope','Rug','Cream'} else 'Glass' if k=='Glass' else 'SmoothPlastic')

def cushion(g,c,w,d,k='SageSoft',h=.34):
 # Rounded edges are real geometry, with a shallow seam around the perimeter.
 ellipsoid(g,k,c,(w/2,h/2,d/2),24,8)
 for z in [-d*.37,d*.37]:rod(g,k,(c[0]-w*.32,c[1],c[2]+z),(c[0]+w*.32,c[1],c[2]+z),.023,6)

def torus(g,k,c,major,minor,axis='y',n=24,m=8):
 vs=[];fs=[]
 for i in range(n):
  a=math.tau*i/n
  for j in range(m):
   b=math.tau*j/m;p=((major+minor*math.cos(b))*math.cos(a),minor*math.sin(b),(major+minor*math.cos(b))*math.sin(a))
   if axis=='z':p=(p[0],p[2],p[1])
   if axis=='x':p=(p[1],p[0],p[2])
   vs.append(tuple(c[t]+p[t] for t in range(3)))
 for i in range(n):
  for j in range(m):fs.append((i*m+j,((i+1)%n)*m+j,((i+1)%n)*m+(j+1)%m,i*m+(j+1)%m))
 poly(g,k,vs,fs)

def cup(g,c,k='Ceramic',r=.28):
 x,y,z=c
 rod(g,k,(x,y,z),(x,y+.48,z),r*.75,16,r)
 ring(g,k,(x,y+.49,z),r,.045,.055,20)
 rod(g,'Tea',(x,y+.47,z),(x,y+.475,z),r-.052,16)
 torus(g,k,(x+r+.05,y+.27,z),.17,.045,'z',16,6)
 rod(g,k,(x,y-.07,z),(x,y-.015,z),r*1.5,20)

def teapot(g,c):
 x,y,z=c
 ellipsoid(g,'Ceramic',(x,y+.36,z),(.55,.42,.48),16,9)
 rod(g,'Ceramic',(x,y+.72,z),(x,y+.79,z),.35,20)
 ellipsoid(g,'OakDark',(x,y+.84,z),(.1,.08,.1),10,6)
 rod(g,'Ceramic',(x-.38,y+.3,z),(x-.77,y+.63,z),.18,12,.1)
 torus(g,'OakDark',(x+.43,y+.48,z),.4,.06,'z',18,6)

def panel_label(name,text,c,w,h):
 box(name,'Paper',c,(w,h,.045))
 LABELS.append({'name':name+'_Paper','text':text,'width':w,'height':h,'front':[0,0,1]})

def make_room():
 g='C1_Lining'
 # Conceal the inside of the existing rear window recesses without editing ShopBacks.
 box(g,'Wall',(0,4.65,-19.48),(25.0,6.9,.12))
 for x in [-12.60,12.60]:
  box(g,'Wall',(x,4.9,-9.85),(.10,6.35,19.1))
  for j in range(25):box(g,'OakDark',(x,1.0,-.7-j*.75),(.13,2.0,.71))
  box(g,'TimberEdge',(x,2.06,-9.85),(.17,.14,19.1))
 for i in range(33):box(g,'OakDark',(-12+i*.75,1,-19.37),(.71,2,.12))
 box(g,'TimberEdge',(0,2.06,-19.31),(24.8,.14,.14))
 for j in range(34):box('C1_Ceiling','OakLight',(0,8.12,-.4-j*.57),(25.0,.06,.545))
 for z in [-.6,-7.0,-13.0,-19.0]:box('C1_Ceiling','TimberEdge',(0,7.99,z),(25,.20,.24))
 # Soft woven rug under the human seating area.
 box('C1_Rug','SageSoft',(-7.9,.018,-12.5),(9.1,.035,12.0))
 box('C1_Rug','Rug',(-7.9,.041,-12.5),(8.6,.012,11.5))
 for j in range(18):box('C1_Rug','Cream',(-7.9,.050,-17.5+j*.55),(8.2,.008,.03))
 # Threshold reaches the same floor, but keeps the existing 5.6-wide entrance unobstructed.
 box('C1_Threshold','Stone',(-9.36,-.435,1.4),(5.6,.29,.8))
 box('C1_Threshold','Stone',(-9.36,-.155,.7),(5.6,.29,1))
 for i,(x,z) in enumerate([(-7.7,-11.9),(1.6,-7.2),(7.2,-16.2)]):
  g='C1_Lamp'+str(i)
  rod(g,'DarkMetal',(x,8.04,z),(x,7.62,z),.027)
  ellipsoid(g,'Cream',(x,7.32,z),(.67,.35,.67),24,10)
  for yy,rr in [(7.12,.54),(7.3,.67),(7.48,.54)]:ring(g,'OakDark',(x,yy,z),rr+.01,.018,.026,24)
  rod(g,'OakDark',(x,7.64,z),(x,7.70,z),.14,16)

def make_seating():
 g='C1_Bench'
 box(g,'Oak',(-7.9,1.45,-16.85),(8.7,.40,3.0))
 for x in [-11.75,-4.05]:
  for z in [-17.95,-15.75]:box(g,'OakDark',(x,.68,z),(.28,1.36,.28))
 box(g,'Oak',(-7.9,2.60,-18.25),(8.7,2.1,.25))
 for x in [-12.15,-3.65]:
  box(g,'Oak',(x,2.33,-16.85),(.28,.26,3.1))
  for z in [-17.95,-15.75]:box(g,'OakDark',(x,1.85,z),(.20,1.2,.20))
 for i,x in enumerate([-10.65,-7.9,-5.15]):
  cushion(g,(x,1.82,-16.72),2.67,2.48,'SageSoft',.30)
  cushion(g,(x,2.8,-17.94),2.42,.35,'SageSoft',1.45)
  SEATS.append({'name':'BenchSeat'+str(i),'position':[x,1.96,-16.65],'look':[0,0,1]})
 # Two round cafe tables, each paired with a real wooden chair.
 for i,x in enumerate([-10.05,-5.75]):
  z=-11.6;g='C1_Table'+str(i)
  rod(g,'OakLight',(x,2.87,z),(x,3.07,z),1.62,32)
  ring(g,'OakDark',(x,2.88,z),1.62,.04,.09,32)
  for a in [math.pi/6,math.pi*5/6,math.pi*1.5]:
   rod(g,'Oak',(x+math.cos(a)*1.18,.06,z+math.sin(a)*1.18),(x+math.cos(a)*.67,2.9,z+math.sin(a)*.67),.12,8,.09)
  cup('C1_TableGoods'+str(i),(x-.5,3.14,z+.25),'White')
  cup('C1_TableGoods'+str(i),(x+.6,3.14,z-.1),'Ceramic')
  if i==0:teapot('C1_TableGoods'+str(i),(x+.10,3.16,z+.65))
  else:
   rod('C1_TableGoods1','White',(x+.05,3.08,z+.55),(x+.05,3.14,z+.55),.43,24)
   for dx in [-.18,.18]:ellipsoid('C1_TableGoods1','Rose',(x+dx,3.27,z+.55),(.16,.13,.16),12,7)
  cz=-7.7;g='C1_Chair'+str(i)
  box(g,'Oak',(x,1.62,cz),(2.45,.25,2.25))
  for dx in [-.96,.96]:
   for dz in [-.85,.85]:rod(g,'Oak',(x+dx,.04,cz+dz),(x+dx*.88,1.6,cz+dz*.88),.105,8)
  cushion(g,(x,1.84,cz),2.3,2.1,'Rose' if i else 'Indigo',.30)
  for dx in [-1.02,1.02]:rod(g,'Oak',(x+dx,1.6,cz+.95),(x+dx,3.72,cz+1.03),.11,8)
  box(g,'OakLight',(x,3.46,cz+1.02),(2.2,.42,.20))
  for dx in [-.55,0,.55]:box(g,'Oak',(x+dx,2.74,cz+.99),(.11,1.15,.12))
  SEATS.append({'name':'ChairSeat'+str(i),'position':[x,1.99,cz],'look':[0,0,-1]})
 # A simple framed paw relief above the seating.
 g='C1_Art';box(g,'TimberEdge',(-7.9,5.45,-19.12),(5.5,2.7,.17));box(g,'Paper',(-7.9,5.45,-19.01),(5.18,2.4,.08))
 ellipsoid(g,'SageSoft',(-7.9,5.16,-18.94),(.55,.40,.035),16,8)
 for dx,dy in [(-.65,.45),(-.23,.78),(.23,.78),(.65,.45)]:ellipsoid(g,'SageSoft',(-7.9+dx,5.16+dy,-18.94),(.21,.27,.035),12,7)

def make_counter():
 g='C1_Counter';x,z=7.3,-17.3
 box(g,'OakDark',(x,1.39,z),(8.3,2.78,2.6))
 for i in range(12):box(g,'Oak',(x-3.88+i*.705,1.40,z+1.34),(.66,2.65,.11))
 box(g,'OakLight',(x,2.95,z),(8.7,.25,3.05))
 box(g,'TimberEdge',(x,.15,z+1.42),(8.5,.16,.13))
 # Back shelves with ceramics and tea jars.
 g='C1_Shelves'
 for x in [3.55,11.1]:box(g,'TimberEdge',(x,5.05,-19.08),(.18,4.85,.18))
 for y in [3.6,4.8,6.0]:box(g,'OakLight',(7.3,y,-18.72),(7.8,.15,.8))
 for i in range(5):
  x=4.2+i*1.35
  rod('C1_TeaJars','Ceramic' if i%2 else 'White',(x,6.1,-18.65),(x,6.78,-18.65),.33,16)
  rod('C1_TeaJars','OakDark',(x,6.79,-18.65),(x,6.86,-18.65),.35,16)
  for y in [3.74,4.94]:cup('C1_Cups',(x,y,-18.65),'White' if i%2 else 'Ceramic',.22)
 teapot('C1_TeaService',(5.3,3.1,-17.1))
 cup('C1_TeaService',(6.65,3.13,-16.8),'White')
 # Modest glass pastry cover, with real tray and timber base.
 box('C1_Pastry','OakDark',(9.0,3.12,-17.0),(3.25,.16,1.8))
 box('C1_Pastry','White',(9.0,3.23,-17.0),(2.95,.08,1.5))
 for xx in [-.7,0,.7]:
  for zz in [-.35,.35]:ellipsoid('C1_Pastry','Rose' if zz<0 else 'Cream',(9+xx,3.43,-17+zz),(.28,.20,.27),12,7)
 for xx in [-1.7,1.7]:box('C1_PastryCover','Glass',(9+xx,3.65,-17),(.055,1.0,1.95))
 box('C1_PastryCover','Glass',(9,4.15,-17),(3.45,.055,1.95))
 box('C1_PastryCover','Glass',(9,3.65,-16.03),(3.45,1.0,.055))
 panel_label('C1_CounterMenu','TEA  &  COFFEE',(3.95,3.62,-16.45),1.55,.75)

def make_cat_areas():
 # Long window perch reserved for Shannon's cats, distinct from visitor seats.
 g='C1_WindowBench'
 box(g,'OakLight',(3.1,1.89,-1.82),(16.9,.22,2.85))
 for x in [-4.85,.45,5.75,11.05]:
  for z in [-2.8,-.85]:box(g,'Oak',(x,.90,z),(.23,1.8,.23))
 box(g,'OakDark',(3.1,.5,-2.65),(16.65,.15,.15))
 for i,x in enumerate([-2.55,3.1,8.75]):
  cushion('C1_WindowBeds',(x,2.15,-1.82),4.45,2.75,['SageSoft','Rose','Indigo'][i],.34)
  CAT_SPOTS.append({'name':'Window'+str(i),'position':[x,2.32,-1.82],'usable':[4.4,2.7],'note':'Adjust after Meshy cats are imported'})
 # Broad wall platforms and scratching post stay out of the central aisle.
 for i,(z,y) in enumerate([(-5.5,1.55),(-8.9,3.0),(-12.5,4.4)]):
  g='C1_Climb'+str(i)
  box(g,'OakLight',(10.9,y,z),(3.35,.22,3.5))
  for zz in [z-1.2,z+1.2]:rod(g,'OakDark',(12.48,y-.85,zz),(10.1,y-.15,zz),.09,4)
  cushion(g,(10.9,y+.2,z),3.15,3.28,'SageSoft',.18)
  CAT_SPOTS.append({'name':'Climb'+str(i),'position':[10.9,y+.29,z],'usable':[3.1,3.2],'note':'Cat size check pending'})
 g='C1_Scratcher'
 rod(g,'OakDark',(10.65,0,-8.9),(10.65,3.0,-8.9),.28,16)
 for i in range(23):ring(g,'Rope',(10.65,.18+i*.115,-8.9),.32,.10,.085,20)
 # A low cubby with a real round entrance, not a solid painted hole.
 g='C1_Cubby';x,z=4.8,-8.7;w,h,depth=4.4,3.7,3.7
 # One connected hollow shell avoids coplanar faces at panel joins.
 cy=h/2;angles=[math.tau*j/40 for j in range(40)]
 for hw,hh in [(w/2,h/2),(w/2-.2,h/2-.2)]:
  a=math.atan2(hh,hw);angles.extend([a,math.pi-a,math.pi+a,math.tau-a])
 angles=sorted(set(angles));N=len(angles);vs=[];fs=[]
 for typ,zz in [('outer',z+depth/2),('outer',z-depth/2),('inner',z-depth/2+.2),('inner',z+depth/2-.15),('circle',z+depth/2),('circle',z+depth/2-.15)]:
  for a in angles:
   co,si=math.cos(a),math.sin(a)
   hw,hh=(w/2,h/2)if typ=='outer'else(w/2-.2,h/2-.2)
   rr=1.36 if typ=='circle'else min(hw/max(abs(co),1e-6),hh/max(abs(si),1e-6))
   vs.append((x+rr*co,cy+rr*si,zz))
 for a,b in [(0,1),(2,3),(0,4),(4,5),(5,3)]:
  for j in range(N):q=(j+1)%N;fs.append((a*N+j,a*N+q,b*N+q,b*N+j))
 fs.extend([tuple(range(N,2*N)),tuple(reversed(range(2*N,3*N)))])
 poly(g,'OakLight',vs,fs)
 torus(g,'OakDark',(x,cy,z+depth/2+.025),1.39,.065,'z',40,8)
 cushion('C1_CubbyBeds',(x,.42,z),3.8,3.2,'Rose',.32)
 cushion('C1_CubbyBeds',(x,3.89,z),4.05,3.35,'Indigo',.32)
 CAT_SPOTS.extend([{'name':'CubbyInside','position':[x,.58,z],'usable':[3.8,3.2],'openingHeight':2.72},{'name':'CubbyTop','position':[x,4.05,z],'usable':[4.0,3.3]}])
 # Small bowl station beside the wall, away from visitor drinks.
 box('C1_Bowls','Oak',(10.9,.15,-15),(2.7,.28,1.15))
 for i,xx in enumerate([10.15,11.65]):
  ring('C1_Bowls','Ceramic',(xx,.42,-15),.47,.085,.34,24)
  rod('C1_Bowls','Ceramic',(xx,.25,-15),(xx,.29,-15),.43,24)
  if i:
   rod('C1_Bowls','Glass',(xx,.40,-15),(xx,.415,-15),.37,24)
  else:
   for j in range(13):
    a=j*2.4;r=.28*math.sqrt(j/13);ellipsoid('C1_Bowls','OakDark',(xx+r*math.cos(a),.38,-15+r*math.sin(a)),(.07,.045,.07),7,4)

def build_objects():
 import bmesh
 for (g,k),(vs,fs) in G.items():
  me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v)for v in vs],[],fs);me.update()
  o=bpy.data.objects.new(g+'_'+k,me);bpy.context.scene.collection.objects.link(o);me.materials.append(mat(k))
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
  uv=bm.loops.layers.uv.new('UVMap')
  for f in bm.faces:
   ax=max(range(3),key=lambda i:abs(f.normal[i]))
   for l in f.loops:
    c=l.vert.co;u,v=((c.y,c.z),(c.x,c.z),(c.x,c.y))[ax];l[uv].uv=(u/4,v/4)
  bm.to_mesh(me);bm.free()
  if k in {'SageSoft','Rose','Indigo','Cream','Ceramic','White','Glass'}:
   for f in me.polygons:f.use_smooth=True
  if k in {'Oak','OakLight','OakDark','Timber','TimberEdge','Stone'}:
   bpy.context.view_layer.objects.active=o;o.select_set(True)
   mod=o.modifiers.new('Soft exported edges','BEVEL');mod.width=.025;mod.segments=1
   bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
  if k=='Glass':
   bs=me.materials[0].node_tree.nodes['Principled BSDF'];bs.inputs['Transmission Weight'].default_value=.90;bs.inputs['Roughness'].default_value=.12;bs.inputs['IOR'].default_value=1.45
  OBJS.append(o)
 for name,c in [('C1_Origin',(0,0,0)),('C1_Right',(2,0,0)),('C1_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.06,location=P(c));o=bpy.context.object;o.name=name;OBJS.append(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)

def text_preview(txt,c,size,k='Ink'):
 cu=bpy.data.curves.new('preview caption','FONT');cu.body=txt;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=size
 o=bpy.data.objects.new('CTX_Text',cu);bpy.context.scene.collection.objects.link(o);o.location=P(c);o.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat(k));PREVIEW.append(o)

def context():
 def block(name,c,s,k):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.name='CTX_'+name;o.scale=(s[0],s[2],s[1]);o.data.materials.append(mat(k));PREVIEW.append(o)
 block('Retained floor',(0,-.15,-10),(26,.3,20.5),'OakDark')
 for x in [-13,13]:block('Retained wall',(x,4.0,-10),(.4,8.2,20),'OakDark')
 block('Retained back',(0,4,-20),(26,8.2,.4),'Wall')
 block('Retained ceiling',(0,8.36,-10),(26,.35,20),'Timber')
 # Measured facade stand-in, to show the existing window/door relationship.
 for x in [-12.16,-6.56,13]:block('Entrance frame',(x,3.31,-.25),(.24,7.7,.42),'Timber')
 block('Window base',(3.12,.76,0),(18.86,2,.3),'TimberEdge')
 for j in range(25):block('Window lattice',(-6.2+j*.775,3.98,.13),(.065,4.3,.075),'Timber')
 for y in [1.82,3.22,4.62,6.12]:block('Window rail',(3.12,y,.13),(18.86,.09,.08),'Timber')
 for x in [-13,13]:block('Corner post',(x,5,-.05),(.52,10,.52),'Timber')
 block('Main sign',(3.12,7.11,.36),(12,1.15,.13),'Timber')
 text_preview('CAT CAFE',(3.12,7.1,.44),.53,'Paper')
 block('Pavement',(0,-.75,6),(44,.35,12),'Stone')
 text_preview('TEA & COFFEE',(3.95,3.62,-16.41),.16)

def render_views():
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
 sc.render.resolution_x=1400;sc.render.resolution_y=950;sc.render.resolution_percentage=100
 sc.world=bpy.data.worlds.new('Daylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.62,.72,.9,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.38
 sc.view_settings.view_transform='AgX'
 def area(name,c,power,size,target):
  d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=P(c);o.rotation_euler=(Vector(P(target))-o.location).to_track_quat('-Z','Y').to_euler()
 area('Window daylight',(2,6,4),1800,12,(1,2,-11))
 area('Front soft fill',(-15,16,16),2800,16,(0,3,-5))
 for x,z in [(-7.7,-11.9),(1.6,-7.2),(7.2,-16.2)]:
  d=bpy.data.lights.new('Warm cafe pendant','POINT');d.energy=200;d.color=(1,.84,.65);d.shadow_soft_size=.8;o=bpy.data.objects.new('Warm cafe pendant',d);sc.collection.objects.link(o);o.location=P((x,7.05,z))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 for name,loc,target,lens in [('01_inside',(-8.4,5.7,-2.5),(2.3,3.1,-12.3),22),('02_seating',(1.2,5.6,-7.2),(-8.0,2.7,-15.3),30),('03_cat_window',(-7.6,5.3,-11),(5.9,2.8,-3.1),25),('04_layout',(0,33,-9.5),(0,0,-9.5),40)]:
  if name=='04_layout':
   for o in bpy.data.objects:
    if o.name.startswith('C1_Ceiling')or o.name.startswith('C1_Lamp')or o.name=='CTX_Retained ceiling':o.hide_render=True
  cam.location=P(loc);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
  sc.render.filepath=os.path.join(OUT,name+'.png');bpy.ops.render.render(write_still=True);log('RENDER '+name)

try:
 open(LOG,'w').close();bpy.ops.wm.read_factory_settings(use_empty=True)
 make_room();make_seating();make_counter();make_cat_areas();build_objects()
 root=bpy.data.objects.new('cat_cafe1',None);bpy.context.scene.collection.objects.link(root)
 for o in OBJS:o.parent=root
 manifest={'root':'cat_cafe1','origin':[6014,1.03985,7],'yaw':-90,'materials':{k:{'rgb':list(v),'material':ROBLOX_MATERIAL[k]}for k,v in COL.items()},'labels':LABELS,'seats':SEATS,'catSpots':CAT_SPOTS,'meshes':[]}
 for o in OBJS:
  q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  record={'name':o.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
  assert record['triangles']<10000,(o.name,record['triangles'])
  if not o.name.startswith(('C1_Threshold','C1_Origin','C1_Right','C1_Front')):assert record['max'][2]<.02,record['name']
  manifest['meshes'].append(record)
 json.dump(manifest,open(os.path.join(OUT,'manifest.json'),'w'),indent=2,ensure_ascii=False)
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in OBJS:o.select_set(True)
 bpy.context.view_layer.objects.active=OBJS[0]
 fbx=os.path.join(OUT,'japan_kit23_cat_cafe1.fbx')
 bpy.ops.export_scene.fbx(filepath=fbx,use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'EMPTY','MESH'})
 log('EXPORTED '+str(len(OBJS))+' meshes; '+str(sum(r['triangles']for r in manifest['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=fbx,axis_forward='-Z',axis_up='Y')
 assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(manifest['meshes'])
 for r in manifest['meshes']:
  o=bpy.data.objects.get(r['name']);assert o is not None,r['name']
  q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  for i in range(3):assert abs(min(p[i]for p in q)-r['min'][i])<.003 and abs(max(p[i]for p in q)-r['max'][i])<.003,r['name']
  if r['name']in{'C1_Origin','C1_Right','C1_Front'}:o.hide_render=True
 log('ROUNDTRIP_PASS: all mesh names and bounds within 0.003 studs')
 # Match the transparent glass material assigned by the Roblox installer.
 for material in bpy.data.materials:
  if material.name.startswith('Glass') and material.use_nodes:
   for node in material.node_tree.nodes:
    if node.type=='BSDF_PRINCIPLED':
     node.inputs['Transmission Weight'].default_value=.9;node.inputs['Alpha'].default_value=.2;node.inputs['Roughness'].default_value=.1
 context();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'cat_cafe1_review.blend'));render_views()
 log('CATCAFE1_DONE')
except Exception:
 log(traceback.format_exc());log('CATCAFE1_FAILED')
