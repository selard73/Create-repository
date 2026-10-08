"""Original dress meshes; smooth 48-sided shells, separate trims, centred for Roblox's OBJ importer."""
from pathlib import Path
import math,json
OUT=Path(__file__).parent
N=48
class Mesh:
 def __init__(self,name): self.name=name;self.v=[];self.f=[]
 def tube(self,rings):
  base=len(self.v);self.v.extend(p for ring in rings for p in ring)
  for r in range(len(rings)-1):
   for i in range(N):
    a=base+r*N+i;b=base+r*N+(i+1)%N;c=b+N;d=a+N
    self.f.extend([(a,b,c),(a,c,d)] if rings[r+1][0][1]<rings[r][0][1] else [(a,c,b),(a,d,c)])
def ring(x,z,y,power=1,pleat=0):
 result=[]
 for i in range(N):
  t=2*math.pi*i/N;c=math.cos(t);s=math.sin(t);p=1+pleat*math.cos(t*12)
  result.append((math.copysign(abs(c)**power,c)*x*p,y,math.copysign(abs(s)**power,s)*z*p))
 return result
groups=[]
for style,length,flare,pleat in [('rue',1.65,1.5,.015),('cafe',1.95,1.7,.04),('chateau',2.5,1.9,.012)]:
 body=Mesh('Bodice_'+style)
 body.tube([ring(.9,.55,-1,.6),ring(.91,.57,-.65,.6),ring(1.02,.61,.2,.6),ring(1.02,.58,.78,.6),ring(.39,.35,1,.85)])
 skirt=Mesh('Skirt_'+style)
 skirt.tube([ring(.94,.58,0,.6),ring(1.1,.68,-.35,.7,pleat/2),ring(flare*.82,flare*.64,-length*.65,1,pleat),ring(flare,flare*.78,-length,1,pleat),ring(flare-.045,flare*.78-.045,-length+.045,1,pleat)])
 belt=Mesh('Belt_'+style);belt.tube([ring(.95,.6,-.03,.6),ring(.96,.605,.13,.6)])
 hem=Mesh('Hem_'+style);hem.tube([ring(flare+.008,flare*.78+.008,-length+.01,1,pleat),ring(flare*.979,flare*.78*.979,-length+.085,1,pleat)])
 collar=Mesh('Collar_'+style);collar.tube([ring(.395,.355,1.012,.85),ring(.48,.397,.955,.85)])
 groups.extend([body,skirt,belt,hem,collar])
data={}; vi=1
with (OUT/'DressesSmooth.obj').open('w') as f:
 f.write('# 1001 Squirrels: original wearable boutique dress kit\n')
 for g in groups:
  lo=[min(p[k] for p in g.v) for k in range(3)];hi=[max(p[k] for p in g.v) for k in range(3)]
  center=[(a+b)/2 for a,b in zip(lo,hi)];size=[b-a for a,b in zip(lo,hi)]
  data[g.name]={'centre':center,'size':size,'triangles':len(g.f)}
  f.write('g '+g.name+'\ns 1\n')
  for x,y,z in g.v:f.write(f'v {-(x-center[0]):.6f} {y-center[1]:.6f} {-(z-center[2]):.6f}\n')
  normals=[[0.,0.,0.] for _ in g.v]
  for a,b,c in g.f:
   u=[g.v[b][k]-g.v[a][k] for k in range(3)];v=[g.v[c][k]-g.v[a][k] for k in range(3)]
   n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
   for idx in (a,b,c):
    for k in range(3):normals[idx][k]+=n[k]
  for n in normals:
   length=math.sqrt(sum(x*x for x in n)) or 1
   f.write(f'vn {-n[0]/length:.6f} {n[1]/length:.6f} {-n[2]/length:.6f}\n')
  for a,b,c in g.f:f.write(f'f {a+vi}//{a+vi} {b+vi}//{b+vi} {c+vi}//{c+vi}\n')
  vi+=len(g.v)
(OUT/'dress_kit.json').write_text(json.dumps(data,indent=2))
print('15 meshes:',sum(len(g.f) for g in groups),'triangles')
