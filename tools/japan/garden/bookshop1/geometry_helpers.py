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
