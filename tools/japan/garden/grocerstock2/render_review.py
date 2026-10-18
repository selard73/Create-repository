from pathlib import Path
import bpy,math,sys,traceback
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out'
name=sys.argv[-1] if sys.argv[-1]in['bottles','packets','overview']else'bottles'
log=OUT/('render_'+name+'.log')
def write(s):
    print(s,flush=True)
    with log.open('a')as f:f.write(str(s)+'\n')
def P(q):return(q[0],-q[2],q[1])
try:
    log.write_text('');bpy.ops.wm.open_mainfile(filepath=str(OUT/'grocerstock2_shelf_review.blend'))
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=16;sc.cycles.use_denoising=True;sc.render.threads_mode='FIXED';sc.render.threads=4
    sc.render.resolution_x=1500;sc.render.resolution_y=1000;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
    if not sc.world:sc.world=bpy.data.worlds.new('Shop daylight')
    sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.66,.72,.82,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
    for label,loc,power,size in[('Window',(1,10,-9),1250,9),('Soft left',(-8,6,-15),600,7),('High fill',(8,9,-17),750,6)]:
        data=bpy.data.lights.new(label,'AREA');data.energy=power;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(label,data);sc.collection.objects.link(ob);ob.location=P(loc);ob.rotation_euler=(Vector(P((3,3,-20)))-ob.location).to_track_quat('-Z','Y').to_euler()
    cam=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.sensor_fit='HORIZONTAL'
    eye,target,lens={'bottles':((5.9,5.8,-15.8),(2.7,4.95,-19.85),48),'packets':((-.1,3.6,-16.0),(-3.2,3.02,-19.85),48),'overview':((3,5,-1.8),(3,3.4,-20),34)}[name]
    if name=='overview':sc.render.resolution_x=1600;sc.render.resolution_y=780
    cam.location=P(eye);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
    sc.render.filepath=str(OUT/('grocer_labels2_'+name+'.png'));bpy.ops.render.render(write_still=True)
    write('GROCERREVIEW_DONE')
except Exception:write(traceback.format_exc());write('GROCERREVIEW_FAILED')
