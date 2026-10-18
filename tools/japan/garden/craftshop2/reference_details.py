"""Original painted motifs, built as thin meshes conforming to the real surface.
Shannon's six references guide palette, variety, timber joinery and fullness.
No lettering, stock artwork, watermarks or brand marks are copied.
"""
def shape(g,k,pts,project):
 # Convex discs/petals/leaves. Fan triangulation avoids a concave fill operation.
 cx=sum(p[0]for p in pts)/len(pts);cy=sum(p[1]for p in pts)/len(pts)
 vs=[project(cx,cy)]+[project(*p)for p in pts]
 poly(g,k,vs,[(0,i+1,(i+1)%len(pts)+1)for i in range(len(pts))])

def dot(g,k,c,r,project,n=10):
 shape(g,k,[(c[0]+r*math.cos(i*math.tau/n),c[1]+r*math.sin(i*math.tau/n))for i in range(n)],project)

def brushline(g,k,a,b,w,project):
 dx,dy=b[0]-a[0],b[1]-a[1];ll=math.hypot(dx,dy);nx,ny=-dy/ll*w/2,dx/ll*w/2
 # Subdivide for close adherence to a curved paper surface.
 for i in range(10):
  u,v=i/10,(i+1)/10;ax,ay=a[0]+dx*u,a[1]+dy*u;bx,by=a[0]+dx*v,a[1]+dy*v
  shape(g,k,[(ax+nx,ay+ny),(bx+nx,by+ny),(bx-nx,by-ny),(ax-nx,ay-ny)],project)

def leaf(g,k,c,s,angle,project):
 pts=[]
 for i in range(12):
  t=math.tau*i/12;xx=s*.60*math.cos(t);yy=s*.24*math.sin(t)
  pts.append((c[0]+xx*math.cos(angle)-yy*math.sin(angle),c[1]+xx*math.sin(angle)+yy*math.cos(angle)))
 shape(g,k,pts,project)

def blossom(g,k,c,s,project):
 for j in range(5):
  a=j*math.tau/5;pts=[]
  for i in range(10):
   t=i*math.tau/10;u=s*(.42+.40*math.cos(t));v=s*.29*math.sin(t)
   pts.append((c[0]+u*math.cos(a)-v*math.sin(a),c[1]+u*math.sin(a)+v*math.cos(a)))
  shape(g,k,pts,project)
 dot(g+'Centers','Gold',c,s*.17,project,8)

def paint_lantern(g,c,r,h,k):
 x,y,z=c
 def project(u,v):
  # u is horizontal arc length; v is height from the shade center.
  a=math.pi/2+u/r;v=max(-h*.44,min(h*.44,v));rr=r*(.48+.52*math.cos(math.pi*v/h)**.65)+.006
  return(x+rr*math.cos(a),y+v,z+rr*math.sin(a))
 small='ShelfLantern'in g or 'RearLantern'in g
 motif=g+'Paint';base='Petal'if k=='Rust'else'Rust'
 # A gently branching plum sprig with one large bloom and three smaller ones.
 scale=min(r,h*.5)
 variant=sum(ord(ch)for ch in g)%3
 if variant==1:
  brushline(motif,'Ink',(-.65*scale,-.35*h),(.55*scale,.30*h),.024,project)
  for j,(u,v)in enumerate([(-.40,-.21),(-.06,-.01),(.27,.17)]):
   leaf(motif,'Indigo'if k!='Rust'else'Petal',((u-.19)*scale,(v+.07)*h),.57*scale,.65,project)
   leaf(motif,'Moss'if k!='Rust'else'Gold',((u+.18)*scale,(v-.02)*h),.52*scale,-.45,project)
  for u,v in[(.55,.36),(-.65,.14)]:dot(motif,'Rust'if k!='Rust'else'Petal',(u*scale,v*h),.075*scale,project,12)
  return
 if variant==2:
  for u,v,ss,kk in[(-.46,.20,.34,'Pink'),(.40,.04,.39,base),(-.16,-.25,.31,base)]:
   blossom(motif,kk,(u*scale,v*h),ss*scale,project)
  for u,v,a in[(-.64,.02,-.3),(.64,-.17,.8),(.16,.31,.5)]:leaf(motif,'Moss',(u*scale,v*h),.43*scale,a,project)
  return
 for a,b,w in[((-.72,-.36),(.50,.38),.027),((-.15,0),(-.43,.35),.016),((.16,.19),(.66,.10),.016)]:
  brushline(motif,'Ink',(a[0]*scale,a[1]*h),(b[0]*scale,b[1]*h),w,project)
 for u,v,ss,kk in[(-.47,.25,.24,base),(.30,.27,.25,'Pink'),(.59,.04,.18,base),(-.41,-.16,.17,'Pink')]:
  blossom(motif,kk,(u*scale,v*h),ss*scale,project)
 for u,v,a in[(-.64,-.22,-.4),(-.20,.17,1.2),(.47,.26,.5)]:leaf(motif,'Moss',(u*scale,v*h),.36*scale,a,project)
 if not small and k!='Rust':
  # A few petals around the sprig give the paper a hand-painted rhythm.
  for u,v in[(.75,-.25),(-.67,.37),(.38,-.32)]:dot(motif,'Pink',(u*scale,v*h),.04*scale,project,8)

def paint_umbrella(g,c,r,k):
 x,y,z=c
 def project(u,v):
  d=min(1,math.hypot(u,v)/r);return(x+u,y+v,z+.55*(1-d)**1.25+.027)
 rng=random.Random(sum(ord(a)for a in g))
 if g.endswith('UmbrellaC'):
  # Red-and-ivory alternating wedges with a narrow circular band.
  for wedge in range(0,16,2):
   pts=[]
   for u in[.12,.96]:
    for i in range(7):
     a=math.tau*(wedge+i/6)/16;pts.append((r*u*math.cos(a),r*u*math.sin(a)))
   for i in range(6):poly(g+'PaintStripe','Petal',[project(*p)for p in [pts[i],pts[i+1],pts[i+8],pts[i+7]]],[(0,1,2,3)])
  return
 if k=='Rust':
  # The red parasol uses an airy shower of blossom dots, as in Shannon's photos.
  for batch in range(3):
   for i in range(26):
    a=rng.uniform(0,math.tau);rr=r*rng.uniform(.42,.92)
    blossom(g+'Paint'+str(batch),'Petal',(rr*math.cos(a),rr*math.sin(a)),r*rng.uniform(.023,.038),project)
  for a in[.20,2.2,4.5]:
   brushline(g+'PaintBranches','Gold',(r*.28*math.cos(a),r*.28*math.sin(a)),(r*.80*math.cos(a+.12),r*.80*math.sin(a+.12)),.026,project)
 else:
  # Sweeping original botanical branches across cream/teal parasols.
  color='Pink'if k=='Teal'else'Rust'
  for arm,(a,b)in enumerate([((-.76,-.40),(.62,.55)),((-.18,.02),(-.53,.58)),((.15,.27),(.70,.15))]):
   aa=(a[0]*r,a[1]*r);bb=(b[0]*r,b[1]*r)
   brushline(g+'PaintBranch','Ink',aa,bb,.030,project)
   for i in range(5):
    t=(i+.5)/5;u=aa[0]+(bb[0]-aa[0])*t;v=aa[1]+(bb[1]-aa[1])*t;side=-1 if i%2 else 1
    blossom(g+'PaintFlowers'+str(arm),color,(u+side*.12*r,v+.06*r),r*(.060+.008*(i%2)),project)
    leaf(g+'PaintLeaves','Moss'if k!='Teal'else'Gold',(u-.08*r,v-.08*r),r*.19,side*.8,project)
  for i in range(15):
   a=rng.uniform(0,math.tau);rr=rng.uniform(.67,.90)*r
   dot(g+'PaintPetals','Petal',(rr*math.cos(a),rr*math.sin(a)),r*.016,project,7)

def rich_joinery_and_stock():
 umbrella('C2_BackUmbrellaC',(3.0,5.85,-17.5),1.50,'Rust',False)
 # A full timber lantern cabinet, three rows and a low cupboard, behind the rack.
 for x in[-15.4,-7.0]:box('C2_RearCabinetPosts','Walnut',(x,3.82,-17.6),(.20,7.64,1.84))
 box('C2_RearCabinetBack','Cedar',(-11.2,4.1,-18.52),(8.4,7.1,.10))
 box('C2_BackCabinetBase','Cedar',(-11.2,.50,-17.60),(8.2,1,1.8))
 for x in[-13.3,-9.1]:
  box('C2_CupboardDoors','Walnut',(x,.53,-16.65),(4.03,.85,.08))
  ell('C2_CupboardPulls','Brass',(x+.7,.56,-16.59),(.07,.05,.035),10,4)
 for j,yy in enumerate([1.14,3.28,5.42]):
  box('C2_BackShelf'+str(j),'Hinoki',(-11.2,yy,-17.57),(8.3,.16,1.96))
  for i,(xx,k)in enumerate([(-14.0,'Paper'),(-11.2,'Ivory'),(-8.4,'Paper')]):
   lantern('C2_RearLantern'+str(j)+str(i),(xx,yy+.92,-17.44),.63,1.64,k)
  # Only two modest lights illuminate the cabinet; not a light per stock item.
  if j in[0,2]:LIGHTS.append({'part':'C2_RearLantern'+str(j)+'1_Ivory','position':[-11.2,yy+.92,-17.44],'brightness':.30,'range':7})
 box('C2_RearCabinetCrown','Walnut',(-11.2,7.71,-17.6),(8.65,.22,2.05))
 # Warm timber bands on the existing plaster retain calm areas around the parasols.
 box('C2_BackDado','Cedar',(4.3,.72,-18.73),(21.8,1.44,.10))
 for x in[-6.4,3.2,15.0]:box('C2_BackTimberPosts','Walnut',(x,4.05,-18.65),(.18,8.1,.16))
 box('C2_BackHighRail','Walnut',(4.3,7.95,-18.65),(21.8,.18,.16))
 # Packed shelf contents: shallow folded paper bundles and tied kraft parcels.
 for i,k in enumerate(['Rust','Moss','Paper']):
  xx=-4.70+i*1.75
  box('C2_PaperParcels'+str(i),'Paper',(xx,2.42,-16.8),(1.40,.30,1.40))
  box('C2_ParcelBand'+str(i),k,(xx,2.58,-16.8),(.22,.025,1.43))
 # One red, patterned lantern flanks the window under the existing eave.
 part=lantern('C2_EaveLantern',(14.5,5.70,1.30),.62,2.0,'Rust',8.12)
 LIGHTS.append({'part':part,'position':[14.5,5.70,1.30],'brightness':.3,'range':7})
