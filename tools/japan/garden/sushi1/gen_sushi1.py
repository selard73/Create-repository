"""Kit34: fitted six-seat village sushi bar. Local +Z faces the street.
Reference: Sushi Tanji counter; GO TOKYO Edomae counter service.
Original mesh geometry; existing building/roof/main sign remain in Studio.
"""
import bpy,bmesh,math,json,traceback,random
from pathlib import Path
from mathutils import Vector,Matrix
D=Path(__file__).resolve().parent
OUT=D/'out';OUT.mkdir(exist_ok=True)
LOG=D/'build_log.txt'
R=random.Random(100134)
COL={'Walnut':(86,60,43),'WalnutLight':(102,73,51),'Cedar':(135,95,61),'Hinoki':(185,146,99),'HinokiEdge':(166,124,77),'Wall':(195,181,151),'Indigo':(43,64,74),'IndigoLight':(48,70,80),'Paper':(225,211,176),'Ivory':(222,215,191),'Celadon':(108,139,124),'Ink':(39,45,39),'Metal':(132,144,139),'Brass':(153,123,72),'Glass':(187,211,200),'Rice':(235,226,201),'Salmon':(218,118,84),'Tuna':(168,62,61),'FishWhite':(221,196,168),'Stripe':(246,194,158),'Nori':(37,56,40),'Cucumber':(128,163,83),'Egg':(223,185,75),'Ginger':(210,154,138),'Tea':(118,131,71),'Soy':(66,39,26),'Leaf':(66,100,68),'Stone':(119,115,103)}
WOOD={'Walnut','WalnutLight','Cedar','Hinoki','HinokiEdge'}
G={};OBJECTS=[];SEATS=[];LABELS=[]
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf8')as f:f.write(str(s)+'\n')
def P(v):return(v[0],-v[2],v[1])
def lin(v):
 v/=255;return v/12.92 if v<=.04045 else((v+.055)/1.055)**2.4
def mat(k):
 m=bpy.data.materials.get(k)
 if m:return m
 m=bpy.data.materials.new(k);m.use_nodes=True;c=tuple(lin(v)for v in COL[k])+(1,);m.diffuse_color=c
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=c;bs.inputs['Roughness'].default_value=.66
 if k in {'Celadon','Ivory'}:bs.inputs['Roughness'].default_value=.32
 if k in {'Metal','Brass'}:bs.inputs['Metallic'].default_value=.65;bs.inputs['Roughness'].default_value=.4
 if k=='Glass':bs.inputs['Transmission Weight'].default_value=.95;bs.inputs['Roughness'].default_value=.08;bs.inputs['IOR'].default_value=1.45
 return m
def poly(g,k,vs,fs):
 v,f=G.setdefault((g,k),[[],[]]);n=len(v);v.extend(vs);f.extend([tuple(n+i for i in face)for face in fs])
def box(g,k,c,s):
 x,y,z=c;a,b,d=[v/2 for v in s]
 vs=[(x+sx*a,y+sy*b,z+sz*d)for sx,sy,sz in[(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 poly(g,k,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)])
def rod(g,k,a,b,r,n=12,r2=None):
 a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,1,0)))
 if u.length<.01:u=d.cross(Vector((1,0,0)))
 u.normalize();v=d.cross(u);vs=[]
 for c,rr in[(a,r),(b,r if r2 is None else r2)]:
  for j in range(n):vs.append(tuple(c+rr*(u*math.cos(math.tau*j/n)+v*math.sin(math.tau*j/n))))
 poly(g,k,vs,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n)for j in range(n)])
def ell(g,k,c,s,n=16,m=8):
 vs=[];fs=[]
 for i in range(m+1):
  t=math.pi*i/m
  for j in range(n):a=math.tau*j/n;vs.append((c[0]+s[0]*math.sin(t)*math.cos(a),c[1]+s[1]*math.cos(t),c[2]+s[2]*math.sin(t)*math.sin(a)))
 for i in range(m):
  for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 poly(g,k,vs,fs)
def lathe(g,k,c,profile,n=28,sx=1,sz=1):
 vs=[];fs=[]
 for h,r in profile:
  for j in range(n):a=math.tau*j/n;vs.append((c[0]+sx*r*math.cos(a),c[1]+h,c[2]+sz*r*math.sin(a)))
 for i in range(len(profile)-1):
  for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 fs.extend([tuple(reversed(range(n))),tuple((len(profile)-1)*n+j for j in range(n))]);poly(g,k,vs,fs)
def torus(g,k,c,r,t,n=28,m=6):
 vs=[];fs=[]
 for i in range(n):
  a=i*math.tau/n
  for j in range(m):b=j*math.tau/m;vs.append((c[0]+(r+t*math.cos(b))*math.cos(a),c[1]+t*math.sin(b),c[2]+(r+t*math.cos(b))*math.sin(a)))
 for i in range(n):
  for j in range(m):fs.append((i*m+j,((i+1)%n)*m+j,((i+1)%n)*m+(j+1)%m,i*m+(j+1)%m))
 poly(g,k,vs,fs)
def bowl(g,k,c,r=.4,h=.2):
 lathe(g,k,c,[(0,r*.4),(.035,r*.5),(h*.7,r*.94),(h,r),(h+.025,r-.04),(h*.7,r-.08),(.055,r*.35)],24)
def tea(g,c,k='Celadon'):
 x,y,z=c;lathe(g,k,c,[(0,.19),(.045,.24),(.51,.29),(.56,.285),(.56,.24),(.12,.19)],24)
 rod(g,'Tea',(x,y+.48,z),(x,y+.49,z),.237,24)
def dish(g,c,r=.42):
 bowl(g,'Ink',c,r,.09)
 rod(g,'Soy',(c[0],c[1]+.075,c[2]),(c[0],c[1]+.08,c[2]),r*.72,24)
def nigiri(g,c,kind='Salmon',scale=1,rice=True):
 x,y,z=c;s=scale
 if rice:
  ell(g,'Rice',(x,y+.11*s,z),(.23*s,.13*s,.44*s),16,8)
  for j in range(16):
   a=j*math.tau/16;ell(g,'Rice',(x+.22*s*math.cos(a),y+.10*s,z+.41*s*math.sin(a)),(.035*s,.032*s,.055*s),8,4)
 else:y-=.17*s
 ell(g,kind,(x,y+.245*s,z),(.275*s,.075*s,.49*s),20,8)
 if kind=='Salmon':
  # Thin curved bands follow the actual top of the fish, not floating labels.
  for zz in[-.30,-.14,.02,.18,.34]:
   pts=[]
   for j in range(9):
    xx=-.21+j*.0525;z0=zz+xx*.25;q=max(.01,1-(xx/.275)**2-(z0/.49)**2)
    pts.append((x+xx*s,y+(.245+.075*math.sqrt(q)+.004)*s,z+z0*s))
   for a,b in zip(pts,pts[1:]):rod(g,'Stripe',a,b,.013*s,5)
 if kind=='Egg'and rice:box(g,'Nori',(x,y+.325*s,z),(.55*s,.015*s,.12*s))
def maki(g,c):
 x,y,z=c;lathe(g,'Nori',c,[(0,.24),(.28,.24),(.28,.19),(.04,.19)],20)
 rod(g,'Rice',(x,y+.025,z),(x,y+.277,z),.192,20)
 rod(g,'Cucumber',(x-.045,y+.277,z),(x-.045,y+.286,z),.07,10)
 rod(g,'Salmon',(x+.085,y+.277,z+.03),(x+.085,y+.288,z+.03),.07,10)
def rice_tub(g,c):
 x,y,z=c
 lathe(g,'Hinoki',c,[(0,.65),(.12,.7),(.65,.82),(.69,.82),(.69,.72),(.16,.58)],32)
 for yy,rr in[(.17,.73),(.54,.81)]:torus(g,'Brass',(x,y+yy,z),rr,.035)
 rod(g,'Rice',(x,y+.49,z),(x,y+.50,z),.69,28)
 for i in range(28):
  a=i*2.4;r=.56*math.sqrt(i/28);ell(g,'Rice',(x+r*math.cos(a),y+.515,z+r*math.sin(a)),(.06,.025,.035),8,4)
 rod(g,'HinokiEdge',(x+.2,y+.57,z),(x+.48,y+.87,z+.48),.065,8)
 ell(g,'HinokiEdge',(x+.14,y+.55,z-.1),(.17,.04,.25),14,6)
def make_room():
 # Dark wide boards, restrained shallow seams. No dirty edge gradients.
 for i in range(17):box('S1_Floor','WalnutLight',(-12.4+i*1.55,.035,-8.9),(1.53,.07,17.5))
 for x in[-13.22,13.22]:
  box('S1_SideWalls','Wall',(x,5.18,-8.95),(.11,7.55,17.65))
  box('S1_SideBacking','Walnut',(x,1.10,-8.95),(.10,2.05,17.65))
  for j in range(18):box('S1_SideWainscot','Walnut',(x,1.10,-.55-j*.97),(.16,2.05,.94))
  box('S1_SideRails','Cedar',(x,2.2,-8.95),(.20,.15,17.65))
 box('S1_RearWall','Wall',(0,5.18,-17.72),(26.2,7.55,.12))
 box('S1_RearBacking','Walnut',(0,1.1,-17.66),(26.2,2.05,.08))
 for j in range(26):box('S1_RearWainscot','Walnut',(-12.5+j,1.1,-17.6),(.97,2.05,.15))
 box('S1_RearRail','Cedar',(0,2.2,-17.5),(26.2,.15,.18))
 box('S1_Ceiling','WalnutLight',(0,9,-8.8),(26.2,.12,17.4))
 for z in[-.15,-6,-12,-17.6]:box('S1_CeilingBeams','Walnut',(0,8.85,z),(26.3,.22,.3))
 # Full-width shallow step; no merchandise or seats on the street.
 box('S1_StepLower','Stone',(0,-.78,.99),(26,.50,1.7))
 box('S1_StepUpper','Stone',(0,-.54,.25),(26,1.00,.85))
 # Framed side panels give the open shop a deliberate frontage.
 for i,x in enumerate([-11.75,11.75]):
  box('S1_Facade'+str(i),'Walnut',(x,1.35,-.02),(2.65,2.6,.25))
  for dx in[-1.28,1.28]:box('S1_Facade'+str(i),'Cedar',(x+dx,4.15,-.02),(.14,8.3,.21))
  box('S1_Facade'+str(i),'Cedar',(x,2.7,-.02),(2.7,.18,.22))
  for dx in[-.9,-.45,0,.45,.9]:box('S1_Facade'+str(i),'Walnut',(x+dx,5.13,-.02),(.085,4.65,.13))
  for yy in[3.45,5.2,6.95]:box('S1_Facade'+str(i),'Walnut',(x,yy,.06),(2.55,.065,.09))
 # Softly curved cloth mesh panels, hung forward of the beam, with 6.65 clear below.
 for i in range(8):
  cx=-9.1+i*2.6;vs=[];fs=[]
  for row in range(6):
   for j in range(13):
    u=j/12;v=row/5;x=cx+(u-.5)*2.54;y=7.66-v*(1.01+.04*math.sin(math.pi*u));z=.31+.045*math.sin(u*math.tau*2)+.035*v*v
    vs.append((x,y,z))
  for row in range(5):
   for j in range(12):a=row*13+j;fs.append((a,a+1,a+14,a+13))
  poly('S1_Noren'+str(i),'Indigo'if i%3 else'IndigoLight',vs,fs)
 rod('S1_CurtainRail','Walnut',(-10.45,7.77,.25),(10.45,7.77,.25),.085,12)
def make_counter():
 box('S1_BarBody','Walnut',(-2.4,1.45,-9.4),(19.4,2.75,2.7))
 for i in range(26):box('S1_BarSlats','Cedar',(-11.97+i*.765,1.48,-8.02),(.12,2.52,.09))
 box('S1_BarTop','Hinoki',(-2.4,3.05,-9.15),(19.8,.32,3.85))
 box('S1_BarEdge','HinokiEdge',(-2.4,2.91,-7.26),(19.7,.10,.13))
 rod('S1_Footrail','Brass',(-11.85,.65,-7.32),(7.05,.65,-7.32),.07,16)
 for x in[-11.5,-6.8,-2.1,2.6,6.7]:rod('S1_Footrail','Brass',(x,.65,-7.32),(x,.65,-8.03),.055,12)
 # Low glass neta case leaves clear dining depth in front.
 box('S1_DisplayBase','Walnut',(-3.2,3.29,-10.1),(13.4,.16,1.6))
 for x in[-9.88,3.48]:box('S1_DisplayFrame','Brass',(x,3.90,-10.1),(.055,1.1,1.6))
 for z in[-10.88,-9.32]:
  box('S1_DisplayFrame','Brass',(-3.2,4.44,z),(13.4,.045,.045))
 box('S1_CaseFront','Glass',(-3.2,3.9,-9.30),(13.35,1.08,.03))
 box('S1_CaseTop','Glass',(-3.2,4.46,-10.1),(13.35,.03,1.58))
 for i,x in enumerate([-9.90,3.50]):box('S1_CaseEnd'+str(i),'Glass',(x,3.91,-10.1),(.03,1.08,1.6))
 for i,x in enumerate([-8.6,-5.9,-3.2,-.5,2.2]):
  g='S1_FishTray'+str(i);box(g,'Ivory',(x,3.40,-10.1),(2.43,.07,1.3));box(g,'Leaf',(x,3.445,-10.1),(2.19,.014,1.1))
  if i<4:
   for dx in[-.65,0,.65]:nigiri(g,(x+dx,3.46,-10.1),['Salmon','Tuna','FishWhite','Egg'][i],.85,False)
  else:
   for dx in[-.75,-.25,.25,.75]:
    ell(g,'FishWhite',(x+dx,3.54,-10.1),(.17,.08,.43),16,8)
    ell(g,'Salmon',(x+dx,3.55,-9.67),(.18,.045,.14),12,6)
 # The actual chef work surface sits on the rear side, with unobstructed preparation space.
 box('S1_ChefBoard','Hinoki',(5.38,3.29,-10.1),(2.65,.16,1.85))
 nigiri('S1_InProgress',(5.05,3.37,-10.15),'Tuna')
 box('S1_Knife','Metal',(5.9,3.40,-10.15),(.12,.035,.74));box('S1_Knife','Walnut',(5.9,3.41,-9.65),(.15,.10,.34))
def make_seats():
 for i,x in enumerate([-10.6,-7.3,-4,-.7,2.6,5.9]):
  z=-5.58;g='S1_Chair'+str(i)
  box(g,'Walnut',(x,1.72,z),(2.12,.22,1.95))
  for dx in[-.83,.83]:
   for dz in[-.73,.73]:rod(g,'Walnut',(x+dx,.075,z+dz),(x+dx*.89,1.64,z+dz*.89),.095,8)
  for dx in[-.83,.83]:rod(g,'Walnut',(x+dx,1.6,z+.76),(x+dx,3.32,z+.93),.09,8)
  box(g,'Cedar',(x,3.12,z+.90),(1.9,.43,.14))
  ell(g,'Indigo',(x,1.86,z),(1.0,.13,.89),24,8)
  for dx in[-.83,.83]:rod(g,'Cedar',(x+dx,.64,z-.73),(x+dx,.64,z+.73),.055,8)
  SEATS.append({'name':'CounterSeat'+str(i+1),'position':[x,1.99,z],'look':[0,0,-1]})
  # Each guest has a small personal setting, not a giant market tray.
  g='S1_Setting'+str(i);z=-8.18
  box(g,'Ink',(x,3.255,z),(1.72,.085,.90))
  if i in[0,2,4]:
   nigiri(g,(x-.39,3.30,z),'Salmon');nigiri(g,(x+.37,3.30,z),'Tuna'if i!=4 else'Egg')
  elif i in[1,5]:
   for dx in[-.52,0,.52]:maki(g,(x+dx,3.30,z))
  else:nigiri(g,(x,3.30,z),'FishWhite')
  for dx in[-.06,.06]:rod(g,'Hinoki',(x-.54+dx,3.25,-7.60),(x+.47+dx,3.25,-7.60),.023,8)
  box(g,'Celadon',(x+.22,3.24,-7.60),(.14,.08,.26))
  tea(g,(x+1.12,3.21,-8.64),'Celadon'if i%2==0 else'Ivory')
  dish(g,(x-1.10,3.21,-8.65),.28)
  ell(g,'Ginger',(x+.65,3.33,z),(.12,.065,.11),12,6)
def make_back():
 box('S1_RearCabinet','Walnut',(0,1.59,-16.56),(24.2,3.06,2.10))
 box('S1_RearTop','Hinoki',(0,3.24,-16.55),(24.45,.22,2.35))
 for i in range(8):
  x=-10.5+i*3
  box('S1_RearDoors','Cedar',(x,1.72,-15.48),(2.85,2.68,.12))
  rod('S1_RearHandles','Ink',(x+.95,1.67,-15.37),(x+.95,2.05,-15.37),.035,8)
 rice_tub('S1_RiceTub',(-7.7,3.35,-16.4))
 # Open inset sink with visible bowl, rim, faucet and a little folded towel.
 x=8.8;z=-16.5
 box('S1_SinkBasin','Metal',(x,3.39,z),(2.35,.08,1.55))
 for dx in[-1.15,1.15]:box('S1_SinkRim','Metal',(x+dx,3.55,z),(.10,.27,1.65))
 for dz in[-.78,.78]:box('S1_SinkRim','Metal',(x,3.55,z+dz),(2.35,.27,.10))
 rod('S1_Faucet','Metal',(x,3.4,z-.87),(x,4.45,z-.87),.065,12)
 rod('S1_Faucet','Metal',(x,4.45,z-.87),(x,4.45,z-.20),.065,12)
 rod('S1_Faucet','Metal',(x,4.45,z-.20),(x,4.28,z-.20),.065,12)
 box('S1_Towel','Paper',(6.78,3.4,-16.1),(1.2,.10,.72))
 for j in range(15):rod('S1_Mat','HinokiEdge',(-4.4+j*.075,3.39,-16.8),(-4.4+j*.075,3.39,-15.9),.028,8)
 for i,x in enumerate([-2.4,-1.3,.2]):
  for j in range(5):bowl('S1_DishStacks','Ivory',(x,3.35+j*.10,-16.4),.44,.12)
 for i,x in enumerate([1.65,2.65,3.65]):
  g='S1_Jars';lathe(g,['Celadon','Soy','Ivory'][i],(x,3.35,-16.5),[(0,.24),(.1,.35),(.85,.32),(1.01,.20)],24)
  rod(g,'Walnut',(x,4.36,-16.5),(x,4.43,-16.5),.23,24)
 # Asymmetrical crockery shelves, separate from the compact menu.
 for yy in[5.0,6.45]:
  box('S1_Shelves','Walnut',(-7.7,yy,-17.03),(8.3,.15,1.05))
  for xx in[-11,-4.4]:rod('S1_ShelfBraces','Cedar',(xx,yy-.57,-17.5),(xx,yy-.10,-16.62),.055,6)
 for i in range(6):
  tea('S1_ShelfCups',(-10.9+i*.92,5.08,-16.98),'Celadon'if i%2 else'Ivory')
 for i,x in enumerate([-10.4,-8.6,-6.9]):
  for j in range(3):bowl('S1_ShelfBowls','Celadon'if i%2 else'Ivory',(x,6.53+j*.11,-17.02),.48,.2)
 # Six tangible wooden menu strips. Lettering is added flat in Studio.
 for i,(text,jp)in enumerate(zip(['NIGIRI','MAKI','TAMAGO','TUNA','SALMON','GREEN TEA'],['にぎり','巻き','玉子','まぐろ','サーモン','お茶'])):
  x=-1.8+i*1.10;g='S1_Menu'+str(i)
  box(g,'Hinoki',(x,5.98,-17.50),(.92,2.35,.07))
  LABELS.append({'name':g+'_Hinoki','text':text,'jp':'\n'.join(jp),'front':[0,0,1]})
 # Original stylised fish relief framed over the sink; no copied restaurant artwork.
 g='S1_FishArt';box(g,'Paper',(8.9,6.12,-17.48),(4.05,2.25,.08))
 for x in[6.82,10.98]:box(g,'Walnut',(x,6.12,-17.41),(.12,2.47,.15))
 for y in[4.94,7.3]:box(g,'Walnut',(8.9,y,-17.41),(4.25,.12,.15))
 ell(g,'Indigo',(8.55,6.13,-17.40),(1.15,.49,.045),24,10)
 poly(g,'Indigo',[(9.4,6.13,-17.34),(10.1,6.65,-17.34),(10.1,5.61,-17.34)],[(0,1,2),(2,1,0)])
 ell(g,'Paper',(7.86,6.25,-17.34),(.06,.06,.02),10,6)
 for i in range(3):rod(g,'Cedar',(8.25+i*.38,5.95,-17.33),(8.25+i*.38,6.33,-17.33),.018,6)
def make_lights():
 for i,x in enumerate([-8.7,-2.4,4.0]):
  g='S1_Pendant'+str(i);z=-8.2
  rod(g,'Ink',(x,8.9,z),(x,8.36,z),.025,8)
  lathe(g,'Paper',(x,7.63,z),[(0,.18),(.10,.48),(.35,.65),(.63,.58),(.78,.25)],36)
  for yy,rr in[(7.74,.49),(7.98,.65),(8.24,.58)]:torus(g,'HinokiEdge',(x,yy,z),rr,.019,36,5)
  rod(g,'Walnut',(x,8.41,z),(x,8.46,z),.15,16)
 # One welcoming exterior lantern stays clear of the curtain and entrance.
 g='S1_EntryLantern';x=12.35;z=.85
 rod(g,'Ink',(x,8.25,z),(x,7.20,z),.03,8)
 lathe(g,'Paper',(x,5.7,z),[(0,.27),(.15,.52),(1.27,.52),(1.45,.27)],32)
 for yy in range(9):torus(g,'HinokiEdge',(x,5.86+yy*.14,z),.525,.014,32,5)
 for yy in[5.70,7.15]:rod(g,'Ink',(x,yy-.035,z),(x,yy+.035,z),.29,24)
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
   bpy.context.view_layer.objects.active=o;o.select_set(True);mod=o.modifiers.new('Soft handmade edges','BEVEL');mod.width=.022;mod.segments=2;mod.limit_method='ANGLE';bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
  if 'Noren'in g:
   bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.018;bpy.ops.object.modifier_apply(modifier=mod.name)
  if k not in WOOD|{'Wall','Metal','Glass','Stone'}:
   for f in me.polygons:f.use_smooth=True
  # Roblox's Wood grain follows the part's X axis. Rotate the object basis,
  # counter-rotate its vertices, and preserve exactly the same visible geometry.
  angle,axis=(math.pi/2,'Z')if g=='S1_Floor'else(-math.pi/2,'Y')if g in{'S1_BarSlats','S1_SideWainscot','S1_RearWainscot','S1_RearDoors'}else(0,'Z')
  if angle:
   o.data.transform(Matrix.Rotation(-angle,4,axis));o.rotation_euler=Matrix.Rotation(angle,4,axis).to_euler()
  OBJECTS.append(o)
 for name,pos in[('S1_Origin',(0,0,0)),('S1_Right',(2,0,0)),('S1_Front',(0,0,2))]:
  bpy.ops.mesh.primitive_cube_add(size=.05,location=P(pos));o=bpy.context.object;o.name=name;OBJECTS.append(o)
def context_and_render():
 # These retained-shell proxies are excluded from the kit.
 def block(name,k,c,s):
  bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.name='CTX_'+name;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat(k));return o
 block('Pavement','Stone',(0,-1.1,5),(43,.25,10))
 for x in[-13.5,13.5]:block('ExistingPost','Walnut',(x,5.3,0),(.52,12,.52))
 block('RetainedBeam','Walnut',(0,7.61,0),(27,.55,.5))
 block('RetainedSign','Walnut',(4.59,8.41,.5),(13,1.9,.13))
 def txt(body,c,size,k,japanese=False):
  cu=bpy.data.curves.new('Preview lettering','FONT');cu.body=body;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=size
  if japanese:cu.font=bpy.data.fonts.load('C:/Windows/Fonts/YuGothR.ttc');cu.space_line=.85
  o=bpy.data.objects.new('CTX_Text',cu);bpy.context.collection.objects.link(o);o.location=P(c);o.rotation_euler=(math.pi/2,0,0);cu.materials.append(mat(k))
 txt('SUSHI BAR',(4.59,8.41,.58),.85,'Paper')
 for spec in LABELS:
  idx=int(spec['name'].split('_')[1].replace('Menu',''));txt(spec['text'],(-1.8+idx*1.10,5.03,-17.45),.13,'Ink');txt(spec['jp'],(-1.8+idx*1.10,6.13,-17.45),.40,'Ink',True)
 # Procedural grain is a review approximation of the Wood material used in Studio.
 for k in WOOD:
  m=mat(k);n=m.node_tree.nodes;l=m.node_tree.links;bs=n['Principled BSDF'];tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=2.4;tex.inputs['Detail'].default_value=2
  co=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='MULTIPLY';scale.inputs[1].default_value=(.2,5,3);l.new(co.outputs['Object'],scale.inputs[0]);l.new(scale.outputs[0],tex.inputs['Vector'])
  ramp=n.new('ShaderNodeValToRGB');c=tuple(lin(v)for v in COL[k]);ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[0].color=tuple(v*.82 for v in c)+(1,);ramp.color_ramp.elements[1].position=.85;ramp.color_ramp.elements[1].color=tuple(min(1,v*1.10)for v in c)+(1,);l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color'])
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.resolution_x=1400;sc.render.resolution_y=950;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
 sc.world=bpy.data.worlds.new('Daylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.72,.85,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.4
 def area(name,p,energy,size,target):
  d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=P(p);o.rotation_euler=(Vector(P(target))-o.location).to_track_quat('-Z','Y').to_euler()
 area('Daylight',(0,7,4),2100,15,(0,2,-10));area('Fill',(-12,10,8),1600,12,(0,3,-7))
 for x in[-8.7,-2.4,4]:
  d=bpy.data.lights.new('Warm pendant','POINT');d.energy=150;d.color=(1,.87,.70);d.shadow_soft_size=.5;o=bpy.data.objects.new('Warm pendant',d);sc.collection.objects.link(o);o.location=P((x,7.5,-8.2))
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 for name,eye,target,lens in[('01_inside',(8.3,5.7,-1.6),(-3.4,3.6,-11.5),24),('02_counter',(-7.8,5.15,-3.6),(-1.6,3.65,-10.7),32),('03_front',(-13,7.0,23),(0,3.7,-8),35),('04_layout',(0,31,-8.9),(0,0,-8.9),34)]:
  if name=='04_layout':
   for o in bpy.data.objects:
    if o.name.startswith(('S1_Ceiling','S1_Pendant','CTX_Text','CTX_RetainedSign','CTX_RetainedBeam','S1_Noren')):o.hide_render=True
  cam.location=P(eye);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
  sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);log('RENDER '+name)
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'sushi1_review.blend'))
try:
 LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True)
 make_room();make_counter();make_seats();make_back();make_lights();build_objects()
 root=bpy.data.objects.new('sushi_bar1',None);bpy.context.collection.objects.link(root)
 manifest={'root':'sushi_bar1','origin':[5984,1.03985318,-25],'yaw':90,'materials':{k:{'rgb':v,'material':'Wood'if k in WOOD else'Fabric'if k.startswith('Indigo') else'Plaster'if k=='Wall'else'Slate'if k=='Stone'else'Metal'if k in{'Metal','Brass'}else'Glass'if k=='Glass'else'SmoothPlastic'}for k,v in COL.items()},'seats':SEATS,'labels':LABELS,'meshes':[]}
 for o in OBJECTS:
  o.parent=root;q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  rec={'name':o.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)}
  assert rec['triangles']<10000,rec
  manifest['meshes'].append(rec)
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in OBJECTS:o.select_set(True)
 fbx=OUT/'japan_kit34_sushi_bar1.fbx';bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False)
 log('EXPORTED '+str(len(OBJECTS))+' meshes, '+str(sum(x['triangles']for x in manifest['meshes']))+' triangles')
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
 for rec in manifest['meshes']:
  o=bpy.data.objects[rec['name']];q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
  assert all(abs(min(p[i]for p in q)-rec['min'][i])<.003 and abs(max(p[i]for p in q)-rec['max'][i])<.003 for i in range(3)),rec['name']
  if rec['name']in{'S1_Origin','S1_Right','S1_Front'}:o.hide_render=True
 log('ROUNDTRIP_PASS: names and bounds within .003 studs')
 for k in['Glass']:
  m=mat(k);bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Transmission Weight'].default_value=.95;bs.inputs['Roughness'].default_value=.08
 context_and_render();log('SUSHI1_DONE')
except Exception:
 log(traceback.format_exc());log('SUSHI1_FAILED');raise
