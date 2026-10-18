from pathlib import Path
import bpy,bmesh,math,json,traceback
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out';OUT.mkdir(exist_ok=True);LOG=OUT/'build.log'
OBJS=[]
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf-8')as f:f.write(str(s)+'\n')
def P(v):return(v[0],-v[2],v[1])
def material(name,rgb):
 linear=lambda v:(v/255)/12.92 if v/255<=.04045 else ((v/255+.055)/1.055)**2.4
 m=bpy.data.materials.new(name);m.diffuse_color=tuple(linear(v)for v in rgb)+(1,);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=m.diffuse_color;bs.inputs['Roughness'].default_value=.85
 return m
def mesh(name,vs,fs,mat,smooth=False,export=True):
 me=bpy.data.meshes.new(name);me.from_pydata([P(v)for v in vs],[],fs);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 assert all(e.is_manifold for e in bm.edges),(name,'open/nonmanifold edge')
 assert bm.calc_volume(signed=True)>0,(name,'inverted volume')
 bm.to_mesh(me);bm.free()
 ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);me.materials.append(mat)
 for p in me.polygons:p.use_smooth=smooth
 if export:OBJS.append(ob)
 return ob
def box(name,c,s,mat,export=True):
 vs=[(c[0]+x*s[0]/2,c[1]+y*s[1]/2,c[2]+z*s[2]/2)for x,y,z in[(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,False,export)
def cylinders(name,segments,mat):
 vs=[];fs=[]
 for a,b,r in segments:
  a=Vector(a);b=Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,1,0)))
  if u.length<.01:u=axis.cross(Vector((1,0,0)))
  u.normalize();v=axis.cross(u);off=len(vs);n=16
  for c in[a,b]:
   for i in range(n):vs.append(tuple(c+r*(math.cos(i*math.tau/n)*u+math.sin(i*math.tau/n)*v)))
  fs.extend([tuple(off+i for i in reversed(range(n))),tuple(off+n+i for i in range(n))])
  for i in range(n):j=(i+1)%n;fs.append((off+i,off+j,off+n+j,off+n+i))
 return mesh(name,vs,fs,mat,True)
try:
 LOG.write_text('',encoding='utf-8');bpy.ops.wm.read_factory_settings(use_empty=True)
 sage=material('Sage',(87,112,86));timber=material('Timber',(65,47,35));marker=material('Marker',(230,20,170))
 vs=[];fs=[];nu=24;nv=6;w=(4.7-.4)/3
 for panel in range(3):
  cx=-8.35+(panel-1)*(w+.2);off=len(vs);N=(nu+1)*(nv+1)
  for side in[-1,1]:
   for iy in range(nv+1):
    v=iy/nv
    for ix in range(nu+1):
     u=ix/nu
     vs.append((cx+(u-.5)*w,8.28-1.02*v,.355+.035*math.sin(u*math.tau*2)+.05*v+side*.006))
  for iy in range(nv):
   for ix in range(nu):
    a=off+iy*(nu+1)+ix;b=a+1;c=a+nu+2;d=a+nu+1
    fs.extend([(a,b,c,d),(a+N,d+N,c+N,b+N)])
  boundary=list(range(nu+1))+[j*(nu+1)+nu for j in range(1,nv+1)]+[nv*(nu+1)+i for i in range(nu-1,-1,-1)]+[j*(nu+1)for j in range(nv-1,0,-1)]
  for aa,bb in zip(boundary,boundary[1:]+boundary[:1]):
   a=off+aa;b=off+bb;fs.append((a,a+N,b+N,b))
 cloth=mesh('GC1_Cloth_Sage',vs,fs,sage,True)
 cylinders('GC1_Rail_Timber',[((-10.875,8.35,.355),(-5.825,8.35,.355),.07)],timber)
 cylinders('GC1_Mounts_Timber',[((x,8.35,.04),(x,8.35,.355),.05)for x in[-10.65,-6.05]],timber)
 for name,c in [('Origin',(0,0,0)),('Right',(2,0,0)),('Front',(0,0,2))]:box('GC1_'+name,c,(.05,.05,.05),marker)
 manifest={'version':'front1','materials':{'Sage':{'rgb':[87,112,86],'material':'Fabric'},'Timber':{'rgb':[65,47,35],'material':'Wood'}},'meshes':[]}
 for ob in OBJS:
  pts=[ob.matrix_world@v.co for v in ob.data.vertices];q=[(p.x,p.z,-p.y)for p in pts];ob.data.calc_loop_triangles()
  manifest['meshes'].append({'name':ob.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':len(ob.data.loop_triangles),'vertices':len(ob.data.vertices)})
 lo=next(x['min']for x in manifest['meshes']if x['name']=='GC1_Cloth_Sage')
 assert lo[2]>.30 and lo[0]>-10.71 and lo[1]>7.25
 manifest['checks']={'closedManifold':True,'consistentOutwardNormals':True,'clothBeamClearance':lo[2]-.25,'clothLanternXClearance':lo[0]-(-10.75),'clothFloorClearance':lo[1],'originalRodRetainedAsRearMount':True}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
 for ob in bpy.context.selected_objects:ob.select_set(False)
 for ob in OBJS:ob.select_set(True)
 fbx=OUT/'japan_kit33_grocer_curtain1.fbx'
 bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'MESH'},apply_unit_scale=True,apply_scale_options='FBX_SCALE_ALL',axis_forward='-Z',axis_up='Y',bake_space_transform=True,use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False)
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'curtain_source.blend'))
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
 objs={o.name:o for o in bpy.data.objects if o.type=='MESH'};assert set(objs)=={x['name']for x in manifest['meshes']}
 for row in manifest['meshes']:
  ob=objs[row['name']];pts=[ob.matrix_world@v.co for v in ob.data.vertices];q=[(p.x,p.z,-p.y)for p in pts]
  for i in range(3):assert abs(min(p[i]for p in q)-row['min'][i])<.003 and abs(max(p[i]for p in q)-row['max'][i])<.003
 log('QQ GROCER CURTAIN MODEL:6 source meshes,3 visible batches; '+str(sum(x['triangles']for x in manifest['meshes']))+' triangles; closed manifold cloth with consistent outward normals')
 log('QQ GROCER CURTAIN CLEARANCE: cloth-to-beam '+str(round(manifest['checks']['clothBeamClearance'],3))+' studs; lanternX '+str(round(manifest['checks']['clothLanternXClearance'],3))+' studs; floor '+str(round(lo[1],3))+' studs')
 log('QQ GROCER CURTAIN FBX: roundtrip names/count and bounds passed')
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'curtain_source.blend'))
 for o in bpy.data.objects:
  if o.name in ['GC1_Origin','GC1_Right','GC1_Front']:o.hide_render=True
 timber=bpy.data.materials['Timber']
 box('Context_original_beam',(0,7.6101465,0),(25,.55,.5),timber,False)
 cylinders('Context_original_rod',[((-11.8,8.35,.04),(-5.9,8.35,.04),.065)],timber)
 box('Context_left_post',(-12.05,4.1,-.08),(.25,8.2,.32),timber,False)
 wall=material('Context_wall',(195,175,143));box('Context_back_wall',(-8,6,-2),(12,5,.12),wall,False)
 # Existing lantern envelope included only as model-review context, never exported.
 cream=material('Context_lantern',(231,222,197))
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=P((-11.25,7.04,.85)))
 lamp=bpy.context.object;lamp.name='Context_lantern';lamp.scale=(.5,.5,.86);lamp.data.materials.append(cream)
 for poly in lamp.data.polygons:poly.use_smooth=True
 for j in range(11):
  yy=-.72+j*.144;rr=.5*math.sqrt(max(.01,1-(yy/.86)**2))
  bpy.ops.mesh.primitive_torus_add(major_radius=rr+.008,minor_radius=.012,major_segments=32,minor_segments=8,location=P((-11.25,7.04+yy,.85)))
  bpy.context.object.data.materials.append(timber)
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
 sc.render.threads_mode='FIXED';sc.render.threads=4
 sc.render.resolution_x=1400;sc.render.resolution_y=850;sc.render.resolution_percentage=100
 sc.view_settings.view_transform='AgX';sc.world=bpy.data.worlds.new('World');sc.world.use_nodes=True
 sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.7,.78,.9,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.55
 for name,pos,power,size in [('Daylight',(-9,11,6),700,7),('Side light',(-4,9,2),250,4)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=size;ob=bpy.data.objects.new(name,data);sc.collection.objects.link(ob);ob.location=P(pos);ob.rotation_euler=(Vector(P((-8.5,7.7,0)))-ob.location).to_track_quat('-Z','Y').to_euler()
 cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
 cam.location=P((-7.5,7.9,8.5));cam.rotation_euler=(Vector(P((-8.7,7.65,.1)))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=38
 sc.render.filepath=str(OUT/'grocer_curtain1_model.png');bpy.ops.render.render(write_still=True)
 log('GROCERCURTAIN_DONE')
except Exception:log(traceback.format_exc());log('GROCERCURTAIN_FAILED')

