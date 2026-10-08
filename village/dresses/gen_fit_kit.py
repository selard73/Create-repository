from pathlib import Path
import math,json
P=Path(__file__).parent;N=64
class Mesh:
 def __init__(self,name):self.name=name;self.v=[];self.f=[]
 def tube(self,rings):
  self.v=[p for r in rings for p in r]
  for j in range(len(rings)-1):
   for i in range(N):
    a=j*N+i;b=j*N+(i+1)%N;c=b+N;d=a+N
    self.f.extend([(a,b,c),(a,c,d)] if rings[j+1][0][1]<rings[j][0][1] else [(a,c,b),(a,d,c)])
def ring(x,z,y,power=1,pleat=0,shift=0,back=None):
 points=[(math.copysign(abs(math.cos(t))**power,math.cos(t))*x*(1+pleat*math.cos(t*12)),y,math.copysign(abs(math.sin(t))**power,math.sin(t))*z*(1+pleat*math.cos(t*12))+shift) for t in [i*math.tau/N for i in range(N)]]
 if back is None:return points
 rear=max(p[2] for p in points)
 return [(x,y,z*back/rear if z>0 else z) for x,y,z in points]
groups=[]
body=Mesh('Bodice_outfit');body.tube([ring(.93,.58,-1,.6),ring(.96,.60,-.65,.6),ring(1.06,.65,.2,.6),ring(1.06,.65,.89,.6),ring(1.06,.64,.97,.6),ring(.39,.34,1.04,.85)]);groups.append(body)
profiles={}
for style,length,flare,pleat in [('rue',1.65,1.5,.015),('cafe',1.95,1.7,.04),('chateau',2.5,1.9,.012)]:
 profile=[(0,.94,.58,0,.58),(.12,1.30,.95,-.10,.52),(.32,max(1.95,flare),1.58,-.20,.44),(.70,max(1.92,flare*1.08),1.65,-.35,.40),(1,max(1.86,flare*1.10),1.62,-.40,.38)]
 profiles[style]=profile
 skirt=Mesh('SeatedSkirt_'+style);skirt.tube([ring(x,z,-t*length,1 if t else .6,pleat*.4 if t else 0,shift,back) for t,x,z,shift,back in profile]);groups.append(skirt)
 _,x,z,shift,back=profile[-1];hem=Mesh('SeatedHem_'+style);hem.tube([ring(x+.009,z+.009,-length+.012,1,pleat*.4,shift,back+.009),ring(x+.012,z+.012,-length+.075,1,pleat*.4,shift,back+.012)]);groups.append(hem)
data=json.loads((P/'dress_kit.json').read_text());vi=1
with (P/'BoutiqueFit.obj').open('w') as f:
 for g in groups:
  lo=[min(v[k] for v in g.v) for k in range(3)];hi=[max(v[k] for v in g.v) for k in range(3)];center=[(a+b)/2 for a,b in zip(lo,hi)]
  data[g.name]={'centre':center,'size':[b-a for a,b in zip(lo,hi)],'triangles':len(g.f)}
  f.write('g '+g.name+'\ns 1\n')
  for x,y,z in g.v:f.write(f'v {-(x-center[0]):.6f} {y-center[1]:.6f} {-(z-center[2]):.6f}\n')
  normals=[[0.,0.,0.] for _ in g.v]
  for a,b,c in g.f:
   u=[g.v[b][k]-g.v[a][k] for k in range(3)];v=[g.v[c][k]-g.v[a][k] for k in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
   for idx in (a,b,c):
    for k in range(3):normals[idx][k]+=n[k]
  for n in normals:
   d=math.sqrt(sum(x*x for x in n)) or 1;f.write(f'vn {-n[0]/d:.6f} {n[1]/d:.6f} {-n[2]/d:.6f}\n')
  for a,b,c in g.f:f.write(f'f {a+vi}//{a+vi} {b+vi}//{b+vi} {c+vi}//{c+vi}\n')
  vi+=len(g.v)
(P/'dress_kit.json').write_text(json.dumps(data,indent=2));(P/'seated_profiles.json').write_text(json.dumps(profiles));print('Created 7 smooth fit meshes')
