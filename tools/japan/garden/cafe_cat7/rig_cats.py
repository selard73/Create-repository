"""Purpose-made idle rigs for Shannon's six supplied Meshy cats; no source texture repainting.
Coordinates traced from orthographic geometry studies. Paws remain on Root; no walking animation.
"""
import bpy,sys,json,math,traceback
import numpy as np
from pathlib import Path
from mathutils import Vector,Quaternion,Matrix
D=Path(__file__).resolve().parent;LOG=D/'rig_log.txt';CFG=json.loads((D/'rig_config.json').read_text())
def log(x):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(x)+'\n')
def smooth(a,b,x):
    t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)
def path_nearest(p,path):
    best=(1e9,0,0)
    for i,(a,b) in enumerate(zip(path,path[1:])):
        a,b=Vector(a),Vector(b);ab=b-a;t=max(0,min(1,(p-a).dot(ab)/ab.length_squared));dist=(p-a-t*ab).length
        if dist<best[0]:best=dist,i,t
    return best
def rig(ob,c):
    bones={'Root':((0,0,0),(0,0,.2),None),'Body':(c['body'],c['chest'],'Root'),'Chest':(c['chest'],c['head'],'Body'),'Head':(c['head'],c['headtip'],'Chest'),'Ear.L':(*c['earL'],'Head'),'Ear.R':(*c['earR'],'Head')}
    for i in range(4):bones['Tail'+str(i+1)]=(c['tail'][i],c['tail'][i+1],'Body' if i==0 else 'Tail'+str(i))
    arm=bpy.data.objects.new(c['name']+'_Rig',bpy.data.armatures.new(c['name']+'_Skeleton'));bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for n,(h,t,p) in bones.items():
        b=arm.data.edit_bones.new(n);b.head=h;b.tail=t;b.use_deform=True
        if p:b.parent=arm.data.edit_bones[p]
    bpy.ops.object.mode_set(mode='OBJECT');ob.parent=arm;mod=ob.modifiers.new('CatSkin','ARMATURE');mod.object=arm
    groups={n:ob.vertex_groups.new(name=n) for n in bones}
    for v in ob.data.vertices:
        x,y,z=v.co
        body=smooth(.13,.7,z)
        chest=body*(1-smooth(c['chest'][1]-.3,c['chest'][1]+.35,y))*.72
        w={'Root':1-body,'Body':body-chest,'Chest':chest}
        hz,slope=c['headplane'];h=smooth(-.14,.14,z-(hz+slope*(y-c['head'][1])))*(1-smooth(c['head_y_limit']-.25,c['head_y_limit']+.06,y))
        w={k:v*(1-h) for k,v in w.items()};w['Head']=h
        for side,ec in [('L',c['earL']),('R',c['earR'])]:
            base,tip=map(Vector,ec);u=(v.co-base).dot((tip-base).normalized());radial=(v.co-base-u*(tip-base).normalized()).length
            ear=smooth(-.035,.2,u)*(1-smooth(.18,.34,radial))*h
            ear=min(w['Head'],ear);w['Head']-=ear;w['Ear.'+side]=ear
        dist,i,t=path_nearest(v.co,c['tail'])
        if c.get('tail_mode')=='whisker':
            tail=(1-smooth(.24,.40,dist))*smooth(.42,.68,y)*(1-smooth(.30,.45,z))
            tail=max(tail,(1-smooth(.28,.38,dist))*(1-smooth(-.14,.10,x))*(1-smooth(.30,.42,z)))
        elif c.get('tail_mode')=='blush':tail=(1-smooth(.14,.23,dist))*smooth(.35,.60,y)*smooth(.22,.43,x)
        elif c.get('tail_mode')=='adorable':tail=(1-smooth(.13,.26,dist))*smooth(.60,.80,y)*(1-smooth(-.25,-.05,x))
        else:tail=smooth(c['tail_start'],c['tail_end'],y)
        w={k:v*(1-tail) for k,v in w.items()}
        # Blend across neighbouring segments, not isolated rigid bands.
        u=i+t;centre=u-.5;left=math.floor(centre);f=centre-left
        for j,amount in [(max(0,min(3,left)),1-f),(max(0,min(3,left+1)),f)]:
            name='Tail'+str(j+1);w[name]=w.get(name,0)+tail*amount
        # Keep planted feet motionless, including their lowest fur vertices.
        if z<.10 and tail<.25:w={'Root':1.0}
        w=sorted(((k,v) for k,v in w.items() if v>1e-5),key=lambda q:-q[1])[:4];total=sum(v for _,v in w)
        for k,weight in w:groups[k].add([v.index],weight/total,'REPLACE')
    counts={n:sum(1 for v in ob.data.vertices for g in v.groups if g.group==groups[n].index and g.weight>1e-5) for n in bones}
    assert all(counts.values()),counts
    return arm,bones,counts
def reset(arm):
    for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
def turn(arm,name,axis,deg):
    pb=arm.pose.bones[name];a=pb.bone.matrix_local.to_3x3().inverted()@Vector(axis)
    pb.rotation_mode='QUATERNION';pb.rotation_quaternion=Quaternion(a,math.radians(deg))
def pose(arm,kind):
    reset(arm)
    if kind=='look':
        turn(arm,'Head',(0,0,1),15);turn(arm,'Ear.L',(0,1,0),-8);turn(arm,'Tail2',(0,0,1),7);turn(arm,'Tail3',(0,0,1),8)
    if kind=='curious':
        turn(arm,'Head',(0,1,0),-7);turn(arm,'Ear.R',(0,1,0),8);turn(arm,'Tail3',(0,0,1),-10);turn(arm,'Tail4',(0,0,1),-6);arm.pose.bones['Chest'].scale=(1.008,1.006,1.008)
def render(ob,arm,c,out):
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.light='STUDIO';sc.display.shading.color_type='TEXTURE';sc.display.shading.show_shadows=True
    sc.world.color=(.28,.31,.33);sc.view_settings.view_transform='Standard';sc.render.resolution_x=1000;sc.render.resolution_y=800;sc.render.resolution_percentage=100
    cam=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO'
    centre=Vector((0,0,c['height']*.48));span=max(ob.dimensions);cam.data.ortho_scale=max(3.0,span*1.12)
    cam.location=centre+Vector((5,-8,3.4));cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler()
    for tag in ['rest','look','curious']:
        pose(arm,tag);bpy.context.view_layer.update();sc.render.filepath=str(out/(tag+'.png'));bpy.ops.render.render(write_still=True)
    reset(arm);bpy.data.objects.remove(cam,do_unlink=True)
try:
    manifest=[]
    for c in CFG:
        out=D/c['name'];bpy.ops.wm.open_mainfile(filepath=str(out/'prepared.blend'));ob=bpy.data.objects[c['name']]
        arm,bones,counts=rig(ob,c)
        # Scale geometry and bone coordinates together, without residual object scale.
        s=c['height']/ob.dimensions.z;low=min(v.co.z for v in ob.data.vertices)
        for v in ob.data.vertices:v.co.z-=low;v.co*=s
        bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
        for b in arm.data.edit_bones:b.head=(b.head-Vector((0,0,low)))*s;b.tail=(b.tail-Vector((0,0,low)))*s
        bpy.ops.object.mode_set(mode='OBJECT');bpy.context.view_layer.update()
        rest=np.array([v.co[:] for v in ob.data.vertices]);rootgroup=ob.vertex_groups['Root'].index
        foot=np.array([v.co.z<.065 and any(g.group==rootgroup and g.weight>.999 for g in v.groups) for v in ob.data.vertices]);maxfeet=0
        for tag in ['look','curious']:
            pose(arm,tag);bpy.context.view_layer.update();ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();pp=np.array([v.co[:] for v in me.vertices]);ev.to_mesh_clear()
            maxfeet=max(maxfeet,float(np.linalg.norm(pp[foot]-rest[foot],axis=1).max()))
            assert np.isfinite(pp).all()
        assert maxfeet<.02,(c['name'],maxfeet)
        reset(arm);bpy.context.view_layer.update()
        p=np.array([v.co[:] for v in ob.data.vertices]);row={**c,'triangles':sum(len(p.vertices)-2 for p in ob.data.polygons),'vertices':len(ob.data.vertices),'bone_count':len(bones),'bone_vertex_counts':counts,'max_foot_displacement':maxfeet,'max_influences':max(len(v.groups) for v in ob.data.vertices),'lo':p.min(0).tolist(),'hi':p.max(0).tolist(),'bones':{n:{'head':list(b.head_local),'tail':list(b.tail_local),'parent':b.parent.name if b.parent else None} for n,b in arm.data.bones.items()}}
        assert row['max_influences']<=4;assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in ob.data.vertices)
        (out/'rig.json').write_text(json.dumps(row,indent=2));manifest.append(row)
        # An editable looping idle action for Blender review; runtime uses the same tested amplitudes.
        for frame in [1,31,61,91,121]:
            t=(frame-1)/120*2*math.pi
            reset(arm);turn(arm,'Head',(0,0,1),8*math.sin(t))
            for j in range(2,5):turn(arm,'Tail'+str(j),(0,0,1),4*math.sin(t+j*.5))
            arm.pose.bones['Chest'].scale=(1+.006*math.sin(t),1+.004*math.sin(t),1+.006*math.sin(t))
            for pb in arm.pose.bones:pb.keyframe_insert('rotation_quaternion',frame=frame);pb.keyframe_insert('scale',frame=frame)
        action=arm.animation_data.action;action.name=c['name']+'_GentleIdle';action.use_fake_user=True;arm.animation_data_clear();reset(arm)
        bpy.ops.wm.save_as_mainfile(filepath=str(out/'rigged.blend'));render(ob,arm,c,out)
        log(c['name']+': 10 bones, '+str(row['triangles'])+' tris, grounded paw delta '+str(maxfeet))
    (D/'rig_manifest.json').write_text(json.dumps(manifest,indent=2));log('CATRIG_DONE')
except Exception:
    log(traceback.format_exc());log('CATRIG_FAILED')
