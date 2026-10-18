"""Corrected grocer merchandise: surface-conforming printed paper labels."""
from pathlib import Path
import sys,subprocess
TASK_DIR=Path(__file__).resolve().parent
OLD=TASK_DIR.parent/'grocerstock1/gen_grocerstock1.py'
if not OLD.exists():OLD=Path(r'C:\Users\slard\Create-repository\tools\japan\garden\grocerstock1\gen_grocerstock1.py')
exec(OLD.read_text().split('\ntry:\n')[0],globals())
D=TASK_DIR;OUT=D/'out';OUT.mkdir(parents=True,exist_ok=True);LOG=OUT/'build_log.txt'
LABEL_PATCHES=[];SURFACE_CHECKS=[]
COL['PlainPaper']=COL['Label']
original_box=box
def box(g,k,c,s,bevel=0):
    return original_box(g,'PlainPaper' if k=='Label' else k,c,s,bevel)
def lettering(*a,**kw):pass
def leaf_emblem(*a,**kw):pass

def surface_grid(point,cols=28,rows=2,us=None):
    us=us or[i/cols for i in range(cols+1)];cols=len(us)-1
    vs=[];uv=[];fs=[]
    for j in range(rows+1):
        v=j/rows
        for u in us:
            vs.append(point(u,v));uv.append((u,v))
    for j in range(rows):
        for i in range(cols):
            a=j*(cols+1)+i;fs.append((a,a+1,a+cols+2,a+cols+1))
    return vs,fs,uv

def label_surface(g,text,w,h,point,cols=28,rows=2,us=None):
    vs,fs,uv=surface_grid(point,cols,rows,us)
    LABEL_PATCHES.append({'group':g,'text':'GENMAICHA'if text=='GENMAI'else text,'w':w,'h':h,'tea':'Tea'in g,'vs':vs,'fs':fs,'localUV':uv})

def radial_poly(r,n,theta):
    a=math.pi/2-theta;step=math.tau/n;middle=(math.floor(a/step)+.5)*step
    return r*math.cos(math.pi/n)/math.cos(a-middle)

def curved_label(g,text,x,y,z,w,h,radius,n=24):
    # Paper follows the same polygon facets as the underlying lathed container.
    mid=radius(0);angle=w/mid
    def point(u,v):
        yy=(v-.5)*h;theta=(u-.5)*angle
        r=radial_poly(radius(yy),n,theta)+.0015
        return(x+r*math.sin(theta),y+yy,z+r*math.cos(theta))
    us=[i/40 for i in range(41)]
    for k in range(-n,n+1):
        theta=math.pi/2-k*math.tau/n
        if -angle/2<theta<angle/2:us.append(.5+theta/angle)
    us=sorted(set(round(u,12)for u in us))
    # Include every container facet boundary so paper never cuts across a corner.
    gap=math.inf
    for yy in[0,.5,1]:
        for a,b in zip(us,us[1:]):
            pa,pb=point(a,yy),point(b,yy)
            for t in[0,.25,.5,.75,1]:
                px=(pa[0]+t*(pb[0]-pa[0]))-x;pz=(pa[2]+t*(pb[2]-pa[2]))-z
                theta=math.atan2(px,pz);gap=min(gap,math.hypot(px,pz)-radial_poly(radius((yy-.5)*h),n,theta))
    assert gap>.0014,(text,gap)
    label_surface(g,text,w,h,point,40,4,us)
    SURFACE_CHECKS.append({'text':text,'type':'curved','radialClearance':.0015,'minimumSampledClearance':gap,'arcDegrees':math.degrees(angle)})

def panel(g,txt,c,w=.55,h=.28,ink='Ink',paper='Label'):
    # Flat labels remain only on flat sheets/basket faces; no extruded lettering.
    label_surface(g,txt,w,h,lambda u,v:(c[0]+(u-.5)*w,c[1]+(v-.5)*h,c[2]),1,1)

def tin(g,x,y,z,txt='SENCHA',k='TeaGreen',r=.39,h=1.18):
    item(txt+' tea tin','tea',x,y,z)
    lathe(g,k,(x,y,z),[(0,r*.94),(.05,r),(h-.12,r),(h-.1,r*.98)],28)
    lathe(g,'Tin',(x,y,z),[(h-.10,r*1.025),(h-.03,r*1.025),(h,r*.94)],28)
    ring(g,'Gold',(x,y+.08,z),r+.004,.012,.025,28);ring(g,'Gold',(x,y+h-.13,z),r+.008,.012,.025,28)
    curved_label(g,txt,x,y+h*.46,z,r*2.6,min(.42,h*.47),lambda yy:r,28)

def packet(g,x,y,z,txt,k='Kraft',h=1.20,w=.78,d=.40):
    item(txt+' folded packet','tea',x,y,z)
    profile=[(0,w*.91,d*.86),(.12,w,d),(h-.20,w*.94,d*.72),(h,w*.87,.06)]
    vs=[]
    for yy,ww,dd in profile:
        for sx,sz in[(-1,-1),(1,-1),(1,1),(-1,1)]:vs.append((x+sx*ww/2,y+yy,z+sz*dd/2))
    fs=[(3,2,1,0),(12,13,14,15)]
    for j in range(3):
        for i in range(4):fs.append((4*j+i,4*j+(i+1)%4,4*j+(i+1)%4+4,4*j+i+4))
    poly(g,k,vs,fs);box(g,'CedarPale',(x,y+h-.02,z),(.78*w,.065,.09))
    def front(yy):
        for a,b in zip(profile,profile[1:]):
            if a[0]<=yy<=b[0]:return z+(a[2]+(b[2]-a[2])*(yy-a[0])/(b[0]-a[0]))/2
        raise ValueError('label outside packet')
    col='TeaGreen'if txt in['SENCHA','GENMAI']else'TeaRed'
    band=lambda u,v:(x+(u-.5)*w*.82,y+h*(.24+.58*v),front(h*(.24+.58*v))+.0015)
    bvs,bfs,_=surface_grid(band,1,12);poly(g,col,bvs,bfs)
    cy=h*.57;ph=.31;pw=w*.73
    label_surface(g,txt,pw,ph,lambda u,v:(x+(u-.5)*pw,y+cy+(v-.5)*ph,front(cy+(v-.5)*ph)+.003),1,6)
    SURFACE_CHECKS.append({'text':txt,'type':'sloped_packet','clearance':.003})

def bottle(g,x,y,z,txt,k='Soy',h=1.48,r=.28,cap='TeaRed'):
    item(txt+' bottle','pantry',x,y,z)
    lathe(g,k,(x,y,z),[(0,r*.80),(.035,r),(.76*h,r),(.82*h,r*.87),(.87*h,r*.48),(.96*h,r*.43),(h,r*.48)],24)
    lathe(g,cap,(x,y,z),[(h,r*.55),(h+.085,r*.55),(h+.105,r*.48)],20)
    ring(g,'Gold',(x,y+h*.89,z),r*.48,.018,.045,20)
    curved_label(g,txt,x,y+h*.42,z,r*2.8,.47,lambda yy:r,24)

def miso(g,x,y,z,red=False):
    item(('red'if red else'white')+' miso tub','pantry',x,y,z)
    lathe(g,'TeaRed'if red else'Ivory',(x,y,z),[(0,.37),(.04,.43),(.59,.48),(.66,.48)],24)
    lathe(g,'CedarLight',(x,y,z),[(.66,.51),(.74,.51),(.77,.48)],24)
    for dx in[-.2,0,.2]:box(g,'CedarDark',(x+dx,y+.773,z),(.015,.008,.78))
    curved_label(g,'RED MISO'if red else'MISO',x,y+.36,z,1.15,.33,lambda yy:.43+(.36+yy-.04)/.55*.05)
    ring(g,'Gold',(x,y+.09,z),.438,.012,.035,24)

def spice(g,x,y,z):
    item('shichimi spice tin','pantry',x,y,z)
    lathe(g,'Pepper',(x,y,z),[(0,.21),(.04,.235),(.60,.235),(.65,.21)],20)
    lathe(g,'Ink',(x,y,z),[(.65,.235),(.72,.235)],20)
    curved_label(g,'7 SPICE',x,y+.34,z,.66,.33,lambda yy:.235,20)

def noodles(g,x,y,z,soba=False):
    item('soba bundle'if soba else'udon bundle','dry',x,y,z)
    for j in range(27):
        a=j*2.399;rr=.22*math.sqrt((j+.5)/27);xx=x+rr*math.cos(a);zz=z+rr*math.sin(a);h=1.42+R.uniform(-.045,.045)
        rod(g,'Soba'if soba else'Udon',(xx,y,zz),(xx+.035,y+h,zz),.027,6)
    for yy in[.32,.98]:ring(g,'TeaBlue',(x+.018,y+yy,z),.255,.026,.14,20)
    curved_label(g,'SOBA'if soba else'UDON',x+.016,y+.66,z,.70,.42,lambda yy:.252,20)

def make_textured_labels(atlas_path,layout):
    img=bpy.data.images.load(str(atlas_path));img.pack()
    material=bpy.data.materials.new('PrintedLabel');material.use_nodes=True;material.diffuse_color=(1,1,1,1)
    bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.83
    tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Linear';material.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    groups={}
    for row,entry in zip(LABEL_PATCHES,layout):
        assert row['text']==entry['text']
        data=groups.setdefault(row['group'],[[],[],[]]);vs,fs,uvs=data;offset=len(vs)
        vs.extend([P(v)for v in row['vs']]);fs.extend([tuple(offset+i for i in f)for f in row['fs']])
        u0,v0,u1,v1=entry['uv'];uvs.extend([(u0+u*(u1-u0),v0+v*(v1-v0))for u,v in row['localUV']])
    for g,(vs,fs,uvs)in groups.items():
        me=bpy.data.meshes.new(g+'_Label');me.from_pydata(vs,[],fs);me.update();layer=me.uv_layers.new(name='UVMap')
        for face in me.polygons:
            for li in face.loop_indices:layer.data[li].uv=uvs[me.loops[li].vertex_index]
        ob=bpy.data.objects.new(g+'_Label',me);bpy.context.collection.objects.link(ob);me.materials.append(material);OBJS.append(ob)

try:
    LOG.write_text('');bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.edit.use_global_undo=False
    build_stock()
    layout=[{k:p[k]for k in['text','w','h','tea']}for p in LABEL_PATCHES]
    layout_path=OUT/'label_layout.json';layout_path.write_text(json.dumps(layout,indent=2))
    atlas_path=OUT/'grocer_labels2.png'
    subprocess.run([r'C:\Users\slard\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe',str(D/'make_label_atlas.py'),str(layout_path),str(atlas_path)],check=True)
    layout=json.loads(layout_path.read_text());create_stock_meshes();make_textured_labels(atlas_path,layout)
    root=bpy.data.objects.new('grocerstock2',None);bpy.context.collection.objects.link(root)
    for ob in OBJS:ob.name=ob.name.replace('GS1_','GS2_');ob.parent=root
    manifest={'root':'grocerstock2','materials':{k:{'rgb':[255,255,255]if k=='Label'else list(v),'material':'Wood'if k.startswith('Cedar')else'SmoothPlastic'}for k,v in COL.items()},'items':ITEMS,'meshes':[],'labels':layout,'surfaceChecks':SURFACE_CHECKS,'removeOld':['M2_Pantry_'+k for k in['ClothBag','CedarPale','Paper','BottleBrown','Timber','Ceramic','CedarLight','Sage']]}
    for ob in OBJS:
        q=[(p.x,p.z,-p.y)for p in[ob.matrix_world@v.co for v in ob.data.vertices]];lo=[min(v[i]for v in q)for i in range(3)];hi=[max(v[i]for v in q)for i in range(3)];tri=sum(len(p.vertices)-2 for p in ob.data.polygons)
        assert tri<10000,(ob.name,tri)
        if ob.name not in['GS2_Origin','GS2_Right','GS2_Front']:assert lo[0]>-5.5 and hi[0]<11.62 and lo[1]>.40 and hi[1]<6.01 and lo[2]>-21.22 and hi[2]<-19.02,(ob.name,lo,hi)
        manifest['meshes'].append({'name':ob.name,'min':lo,'max':hi,'triangles':tri,'textured':ob.name.endswith('_Label')})
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    bpy.ops.object.select_all(action='SELECT');fbx=OUT/'japan_kit32_grocer_stock2.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,object_types={'EMPTY','MESH'},path_mode='COPY',embed_textures=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'grocerstock2_source.blend'))
    log('EXPORTED '+str(len(OBJS))+' meshes, '+str(len(ITEMS))+' product groups; '+str(len(LABEL_PATCHES))+' printed labels; '+str(sum(m['triangles']for m in manifest['meshes']))+' triangles')
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(OBJS)
    texture_count=0
    for m in manifest['meshes']:
        ob=bpy.data.objects[m['name']];q=[(p.x,p.z,-p.y)for p in[ob.matrix_world@v.co for v in ob.data.vertices]]
        for i in range(3):assert abs(min(v[i]for v in q)-m['min'][i])<.003 and abs(max(v[i]for v in q)-m['max'][i])<.003,m['name']
        if m['textured']:
            assert ob.data.uv_layers and any(n.type=='TEX_IMAGE'and n.image for slot in ob.material_slots for n in slot.material.node_tree.nodes);texture_count+=1
        if m['name'] in['GS2_Origin','GS2_Right','GS2_Front']:ob.hide_render=True
    assert texture_count==9
    log('ROUNDTRIP_PASS: exact mesh names/count, bounds within .003; all nine printed-label meshes have UVs and embedded image material')
    review_context();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'grocerstock2_shelf_review.blend'))
    log('GROCERLABELS_DONE')
except Exception:log(traceback.format_exc());log('GROCERLABELS_FAILED')
