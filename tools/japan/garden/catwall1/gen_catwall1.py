"""Shallow mesh knickknacks on the cat cafe's LEFT wall, beside visitor tea tables.
Local decor coordinates u=distance from front along wall, v=height, d=projection into room.
Reference: Gotokuji's own manekineko page; original simple ceramic-cat designs, not copied artwork.
"""
import bpy,bmesh,math,json,traceback,ast
from pathlib import Path
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out';OUT.mkdir(exist_ok=True);LOG=OUT/'build_log.txt'
BASE=Path('C:/Users/slard/Create-repository/tools/japan/garden/gen_cat_cafe1.py')
CAFE=D.parent/'cafe_cats2'/'out'/'cat_cafe_seven_cats_review.blend'
COL={'Oak':(163,119,77),'OakLight':(190,150,104),'OakDark':(116,81,52),'Cream':(236,228,209),'Rose':(170,119,114),'Sage':(132,151,121),'Celadon':(119,142,138),'Ink':(60,46,33),'Terracotta':(180,105,76),'Red':(185,63,55),'Gold':(201,169,91),'Green':(87,127,76),'LeafLight':(132,159,98),'Paper':(231,222,197),'Indigo':(66,87,105)}
G={};OBJS=[]
def log(x):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(x)+'\n')
def P(p):return (-12.55+p[2],p[0],p[1])
def linear(n):
    n=n/255;return n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4
def mat(k):
    name='CW1_'+k;m=bpy.data.materials.get(name)
    if m:return m
    m=bpy.data.materials.new(name);m.use_nodes=True;color=tuple(linear(n) for n in COL[k])+(1,);m.diffuse_color=color
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.70 if k.startswith('Oak') else .45
    return m
# Reuse the already-reviewed native mesh primitives, not the prior generator's execution body.
tree=ast.parse(BASE.read_text());wanted={'geo','poly','box','ellipsoid','rod','ring','leaf','torus'}
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in wanted],type_ignores=[]),str(BASE),'exec'))
def line(g,k,points,r=.018):
    # One continuous tube keeps curved eyes, stems and tails smooth between segments.
    pts=[Vector(p) for p in points];vs=[];fs=[];n=10
    for i,p in enumerate(pts):
        tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        ref=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((1,0,0))
        side=tangent.cross(ref).normalized();up=tangent.cross(side).normalized()
        for j in range(n):vs.append(tuple(p+r*(side*math.cos(j*math.tau/n)+up*math.sin(j*math.tau/n))))
    for i in range(len(pts)-1):
        for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(pts)-1)*n+j for j in range(n)));poly(g,k,vs,fs)

def leaf(g,k,a,b,width):
    # Rounded modeled leaves with thickness, softly tapered at the stem and tip.
    a=Vector(a);b=Vector(b);axis=(b-a).normalized();center=(a+b)/2;length=(b-a).length
    side=axis.cross(Vector((0,0,1))).normalized();normal=axis.cross(side).normalized();vs=[];fs=[];n=12;m=8
    for i in range(m+1):
        t=math.pi*i/m
        for j in range(n):
            q=math.tau*j/n;vs.append(tuple(center+axis*(length*.5*math.cos(t))+side*(width*.5*math.sin(t)*math.cos(q))+normal*(.022*math.sin(t)*math.sin(q))))
    for i in range(m):
        for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    poly(g,k,vs,fs)
def arc(g,k,c,rx,ry,start,end,r=.014,n=12):
    line(g,k,[(c[0]+rx*math.cos(a),c[1]+ry*math.sin(a),c[2]) for a in [start+(end-start)*i/n for i in range(n+1)]],r)
def ear(g,k,c,s):
    u,v,d=c;w,h,t=s
    poly(g,k,[(u-w/2,v,d-t/2),(u+w/2,v,d-t/2),(u+w*.25,v+h,d-t*.15),(u-w/2,v,d+t/2),(u+w/2,v,d+t/2),(u+w*.25,v+h,d+t*.25)],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)])
def lathe(g,k,c,profile,n=24):
    u,v,d=c;vs=[];fs=[]
    for h,r in profile:
        for i in range(n):vs.append((u+r*math.cos(i*math.tau/n),v+h,d+r*math.sin(i*math.tau/n)))
    for j in range(len(profile)-1):
        for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(profile)-1)*n+i for i in range(n)));poly(g,k,vs,fs)
def shelf(g,u,v,w):
    box(g,'OakLight',(u,v,.42),(w,.18,.82));box(g,'Oak',(u,v+.10,.78),(w,.08,.07))
    for du in [-w*.32,w*.32]:
        rod(g,'OakDark',(u+du,v-.06,.65),(u+du,v-.48,.09),.055,8)
        box(g,'OakDark',(u+du,v-.28,.055),(.13,.55,.10))
def lucky_cat(u,v,d):
    g='CW1_LuckyCat'
    ellipsoid(g,'Cream',(u,v+.34,d),(.29,.34,.23),20,12)
    ellipsoid(g,'Cream',(u,v+.77,d+.01),(.31,.265,.24),24,14)
    for s in [-1,1]:
        ear(g,'Cream',(u+s*.22,v+.92,d),(.20,.25,.16));ear(g,'Rose',(u+s*.22,v+.95,d+.075),(.12,.16,.025))
        ellipsoid(g,'Cream',(u+s*.15,v+.07,d+.14),(.14,.10,.16),16,9)
        arc(g,'Ink',(u+s*.115,v+.79,d+.249),.075,.045,0,math.pi,.014)
        for j in [-1,1]:line(g,'Ink',[(u+s*.18,v+.71+j*.025,d+.238),(u+s*.29,v+.72+j*.05,d+.20)],.009)
    # A raised paw and red collar are the reference's distinctive beckoning-cat features.
    ellipsoid(g,'Cream',(u-.34,v+.63,d+.03),(.115,.27,.125),16,10)
    ellipsoid(g,'Cream',(u-.35,v+.88,d+.045),(.12,.13,.13),16,10)
    ellipsoid(g,'Cream',(u+.26,v+.36,d+.11),(.11,.23,.12),16,10)
    torus(g,'Red',(u,v+.55,d),.23,.035,'y',24,7)
    ellipsoid(g,'Gold',(u,v+.49,d+.233),(.065,.07,.035),12,8)
    ellipsoid(g,'Rose',(u,v+.72,d+.254),(.035,.025,.015),10,6)
    line(g,'Ink',[(u,v+.695,d+.25),(u,v+.665,d+.25),(u-.045,v+.65,d+.24)],.01)
    line(g,'Ink',[(u,v+.665,d+.25),(u+.045,v+.65,d+.24)],.01)
def planter(u,v,d):
    g='CW1_CatPlanter'
    lathe(g,'Celadon',(u,v,d),[(0,.20),(.06,.26),(.36,.32),(.43,.30),(.43,.25),(.36,.24),(.09,.16)],24)
    for s in [-1,1]:
        ear(g,'Celadon',(u+s*.23,v+.35,d+.13),(.16,.20,.10));arc(g,'Ink',(u+s*.10,v+.23,d+.306),.05,.035,0,math.pi,.012)
    ellipsoid(g,'Rose',(u,v+.16,d+.305),(.027,.018,.01),8,5)
    # An intentionally stylized ornamental vine, with modeled leaves and soft drooping stems.
    for j in range(4):
        a=j*1.7;end=(u+math.cos(a)*.48,v+.72+(j%2)*.12,d+math.sin(a)*.24)
        line(g,'Green',[(u,v+.33,d),end],.019)
        for sign in [-1,1]:leaf(g,'LeafLight',(end[0]-.1*sign,end[1]-.14,end[2]),(end[0]+.2*sign,end[1]+.1,end[2]+.05),.25)
    path=[(u,v+.38,d+.1),(u+.12,v+.50,d+.33),(u+.35,v+.20,d+.40),(u+.41,v-.20,d+.41),(u+.29,v-.57,d+.39),(u+.38,v-.82,d+.38)]
    line(g,'Green',path,.018)
    for i,p in enumerate(path[2:]):
        for s in [-1,1]:leaf(g,'LeafLight' if i%2 else 'Green',p,(p[0]+s*.22,p[1]-.13,p[2]+.03),.18)
def books(u,v,d):
    g='CW1_Books'
    for i,(k,h) in enumerate([('Indigo',.74),('Rose',.88),('Sage',.68)]):
        x=u+i*.27;box(g,'Paper',(x,v+h/2,d),(.18,h-.07,.38))
        for s in [-1,1]:box(g,k,(x+s*.115,v+h/2,d),(.035,h,.43))
        box(g,k,(x,v+h/2,d+.21),(.25,h,.04))
        for dy in [.12,h-.12]:box(g,'Gold',(x,v+dy,d+.237),(.18,.025,.009))
        ellipsoid(g,'Cream',(x,v+h*.52,d+.239),(.035,.05,.008),10,6)
def sleeping_cat(u,v,d):
    g='CW1_SleepingCat'
    ellipsoid(g,'Rose',(u,v+.065,d),(.72,.07,.30),24,8)
    ellipsoid(g,'Cream',(u+.07,v+.24,d),(.54,.21,.26),24,12)
    ellipsoid(g,'Cream',(u-.37,v+.32,d+.045),(.25,.22,.23),20,12)
    ear(g,'Cream',(u-.52,v+.44,d+.04),(.16,.17,.14));ear(g,'Cream',(u-.22,v+.46,d+.02),(.16,.17,.14))
    for du in [-.46,-.28]:arc(g,'Ink',(u+du,v+.34,d+.267),.055,.025,math.pi,2*math.pi,.012)
    ellipsoid(g,'Rose',(u-.37,v+.29,d+.275),(.025,.018,.01),8,5)
    arc(g,'Terracotta',(u+.13,v+.15,d+.24),.39,.09,math.pi*.95,math.pi*2.5,.055,24)
def vase(u,v,d):
    g='CW1_BudVase'
    lathe(g,'Terracotta',(u,v,d),[(0,.17),(.08,.23),(.31,.23),(.50,.13),(.63,.11),(.65,.13),(.65,.08),(.49,.08)],24)
    for j,(du,h) in enumerate([(-.18,1.1),(.17,1.23)]):
        tip=(u+du,v+h,d+.01*j);line(g,'OakDark',[(u,v+.58,d),(u+du*.5,v+.87,d),tip],.018)
        for i in range(5):
            a=i*math.tau/5;ellipsoid(g,'Rose',(tip[0]+.105*math.cos(a),tip[1]+.105*math.sin(a),tip[2]),(.085,.085,.04),10,6)
        ellipsoid(g,'Gold',(tip[0],tip[1],tip[2]+.043),(.047,.047,.018),10,6)
        leaf(g,'Green',(u+du*.3,v+.79,d),(u+du*.3+.18,v+.95,d+.03),.13)
def picture(u,v):
    g='CW1_CatPortrait'
    box(g,'OakDark',(u,v,.08),(1.88,2.10,.15));box(g,'Paper',(u,v,.171),(1.64,1.86,.045))
    # Raised original artwork: a smiling cat with small paw prints, all actual mesh geometry.
    ellipsoid(g,'Sage',(u,v-.14,.215),(.55,.50,.035),24,12)
    ear(g,'Sage',(u-.37,v+.22,.21),(.34,.38,.05));ear(g,'Sage',(u+.37,v+.22,.21),(.34,.38,.05))
    ear(g,'Rose',(u-.37,v+.28,.244),(.18,.20,.015));ear(g,'Rose',(u+.37,v+.28,.244),(.18,.20,.015))
    for s in [-1,1]:
        arc(g,'Ink',(u+s*.21,v-.04,.256),.105,.06,0,math.pi,.016)
        ellipsoid(g,'Rose',(u+s*.30,v-.22,.254),(.07,.04,.009),12,7)
        for i in [-1,1]:line(g,'Cream',[(u+s*.36,v-.18+i*.035,.258),(u+s*.56,v-.14+i*.07,.246)],.012)
    ellipsoid(g,'Rose',(u,v-.15,.26),(.045,.03,.01),12,6)
    line(g,'Ink',[(u,v-.18,.26),(u,v-.24,.26),(u-.06,v-.27,.26)],.012)
    line(g,'Ink',[(u,v-.24,.26),(u+.06,v-.27,.26)],.012)
    for x,y in [(u-.57,v+.71),(u+.55,v-.70)]:
        ellipsoid(g,'Rose',(x,y,.205),(.08,.065,.01),12,6)
        for dx,dy in [(-.09,.09),(-.035,.13),(.035,.13),(.09,.09)]:ellipsoid(g,'Rose',(x+dx,y+dy,.206),(.03,.04,.01),8,5)
def build():
    shelf('CW1_FrontShelf',6.3,5.05,4.8);shelf('CW1_BackShelf',14.1,5.95,5.5)
    lucky_cat(5.05,5.17,.43);planter(7.75,5.17,.43)
    # A tiny saucer and stacked tea cups complete the lower ledge.
    lathe('CW1_MiniCups','Rose',(6.40,5.17,.43),[(0,.20),(.045,.25),(.06,.20),(.1,.13),(.28,.17),(.30,.17),(.30,.135),(.12,.09)],20)
    torus('CW1_MiniCups','Rose',(6.60,5.36,.43),.10,.023,'z',16,6)
    books(12.14,6.06,.40);sleeping_cat(14.42,6.06,.42);vase(16.10,6.06,.42);picture(10.10,5.95)
    for (g,k),(vs,fs) in G.items():
        me=bpy.data.meshes.new(g+'_'+k);me.from_pydata([P(v) for v in vs],[],fs);me.update()
        ob=bpy.data.objects.new(g+'_'+k,me);bpy.context.scene.collection.objects.link(ob);me.materials.append(mat(k))
        bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
        uv=bm.loops.layers.uv.new('UVMap')
        for face in bm.faces:
            ax=max(range(3),key=lambda i:abs(face.normal[i]))
            for lp in face.loops:
                q=lp.vert.co;a,b=((q.y,q.z),(q.x,q.z),(q.x,q.y))[ax];lp[uv].uv=(a/2,b/2)
        bm.to_mesh(me);bm.free()
        if k.startswith('Oak') or g=='CW1_Books':
            bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
            mod=ob.modifiers.new('Soft edges','BEVEL');mod.width=.012;mod.segments=2;mod.limit_method='ANGLE';bpy.ops.object.modifier_apply(modifier=mod.name)
        else:
            for p in me.polygons:p.use_smooth=True
        OBJS.append(ob)
    for name,p in [('CW1_Origin',(0,0,0)),('CW1_Right',(2,0,0)),('CW1_Front',(0,0,2))]:
        bpy.ops.mesh.primitive_cube_add(size=.05,location=(p[0],-p[2],p[1]));o=bpy.context.object;o.name=name;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);OBJS.append(o)
def render(name,loc,target,lens=32):
    sc=bpy.context.scene;cam=bpy.data.objects.new('WallReviewCamera',bpy.data.cameras.new('WallReviewCamera'));sc.collection.objects.link(cam);sc.camera=cam
    cam.location=(loc[0],-loc[2],loc[1]);at=Vector((target[0],-target[2],target[1]));cam.rotation_euler=(at-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
    sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True);log('RENDER '+name)
try:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.edit.use_global_undo=False;build()
    root=bpy.data.objects.new('catwall1',None);bpy.context.scene.collection.objects.link(root)
    for o in OBJS:o.parent=root
    manifest={'root':'catwall1','reference':'https://gotokuji.jp/en/manekineko/','materials':{k:{'rgb':list(v),'material':'Wood' if k.startswith('Oak') else 'SmoothPlastic'} for k,v in COL.items()},'meshes':[]}
    for o in OBJS:
        points=[o.matrix_world@v.co for v in o.data.vertices];lo=[min((p.x,p.z,-p.y)[i] for p in points) for i in range(3)];hi=[max((p.x,p.z,-p.y)[i] for p in points) for i in range(3)]
        tri=sum(len(p.vertices)-2 for p in o.data.polygons);assert tri<10000,(o.name,tri)
        if o.name not in ['CW1_Origin','CW1_Right','CW1_Front']:
            assert lo[0]>=-12.56 and hi[0]<=-11.55,(o.name,lo,hi)
            assert lo[1]>3.8 and hi[1]<7.7,(o.name,lo,hi)
            assert lo[2]>-17.0 and hi[2]<-3.8,(o.name,lo,hi)
        manifest['meshes'].append({'name':o.name,'min':lo,'max':hi,'triangles':tri})
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    bpy.ops.object.select_all(action='SELECT');fbx=OUT/'japan_kit26_catwall1.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'MESH','EMPTY'})
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'catwall1_source.blend'))
    log('EXPORTED '+str(len(OBJS))+' meshes; '+str(sum(x['triangles'] for x in manifest['meshes']))+' triangles')
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(OBJS)
    for m in manifest['meshes']:
        o=bpy.data.objects[m['name']];p=[o.matrix_world@v.co for v in o.data.vertices]
        for i in range(3):
            assert abs(min((q.x,q.z,-q.y)[i] for q in p)-m['min'][i])<.003
            assert abs(max((q.x,q.z,-q.y)[i] for q in p)-m['max'][i])<.003
    log('ROUNDTRIP_PASS: all mesh names and bounds within .003 studs')
    # Review using the existing furniture study, with all seven prepared cats intact.
    bpy.ops.wm.open_mainfile(filepath=str(CAFE))
    with bpy.data.libraries.load(str(OUT/'catwall1_source.blend'),link=False) as (src,dst):dst.objects=src.objects
    for ob in dst.objects:
        if ob:bpy.context.scene.collection.objects.link(ob)
        if ob and ob.name in ['CW1_Origin','CW1_Right','CW1_Front']:ob.hide_render=True
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.render.resolution_x=1500;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
    light=bpy.data.lights.new('WallReviewSoftFill','AREA');light.energy=420;light.shape='DISK';light.size=7
    fill=bpy.data.objects.new('WallReviewSoftFill',light);sc.collection.objects.link(fill);fill.location=(-5,10,6.4);fill.rotation_euler=(Vector((-12.3,10,5.7))-fill.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'catwall1_cafe_review.blend'))
    render('cafe_left_wall',(-1.1,5.25,-10.3),(-12.2,5.6,-10.3),lens=25)
    render('cafe_wall_details',(-8.7,5.8,-4.2),(-12.1,5.9,-6.2),lens=39)
    log('CATWALL1_DONE')
except Exception:
    log(traceback.format_exc());log('CATWALL1_FAILED')
