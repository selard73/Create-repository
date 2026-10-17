"""Render one view per Blender process to keep memory bounded."""
from pathlib import Path
import bpy,math,sys,traceback
from mathutils import Vector
D=Path(__file__).resolve().parent;OUT=D/'out';view=sys.argv[sys.argv.index('--')+1];LOG=OUT/(view+'.log')
def P(p):return(p[0],-p[2],p[1])
def log(s):
 print(s,flush=True)
 with LOG.open('a',encoding='utf-8')as f:f.write(str(s)+'\n')
views={'cafe_larger_interior':((-10,5.7,-3.5),(2,3.7,-20),24),'cafe_larger_seating':((-1.6,5.4,-11),(-11.3,3.3,-23),30),'cafe_larger_cat_corner':((4.2,5.5,-9.3),(14,4.1,-18.7),28),'cafe_larger_floorplan':((0,48,-14),(0,0,-14),40)}
try:
 LOG.write_text('');assert view in views;bpy.ops.wm.open_mainfile(filepath=str(OUT/'cafe_interior2_review.blend'));bpy.context.preferences.edit.use_global_undo=False
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=48;sc.cycles.use_denoising=False;sc.render.threads_mode='FIXED';sc.render.threads=4;sc.render.resolution_x=1200;sc.render.resolution_y=814;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
 sc.render.use_simplify=True
 for setting in ['texture_limit','texture_limit_render']:
  if hasattr(sc.cycles,setting):setattr(sc.cycles,setting,'1024')
 if view!='cafe_larger_floorplan':
  sc.render.resolution_x=1000;sc.render.resolution_y=720;sc.cycles.use_denoising=True;sc.cycles.denoiser='OPENIMAGEDENOISE';sc.cycles.denoising_prefilter='FAST'
 sc.world=bpy.data.worlds.new('Soft daylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.65,.72,.85,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.4
 def area(name,c,power,size,target):
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;ob=bpy.data.objects.new(name,data);sc.collection.objects.link(ob);ob.location=P(c);ob.rotation_euler=(Vector(P(target))-ob.location).to_track_quat('-Z','Y').to_euler()
 area('Shoji daylight',(4.5,6,-.4),1700,13,(1,3,-16));area('Soft room fill',(-5,9,-11),900,12,(0,2,-18))
 for i,(x,z)in enumerate([(-10.8,-17.5),(1.6,-8.5),(9.7,-22.3)]):
  data=bpy.data.lights.new('Warm paper pendant','POINT');data.energy=330;data.color=(1,.84,.65);data.shadow_soft_size=.85;ob=bpy.data.objects.new('LIGHT_'+str(i),data);sc.collection.objects.link(ob);ob.location=P((x,10.25,z))
 camera=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));sc.collection.objects.link(camera);sc.camera=camera
 loc,target,lens=views[view];camera.location=P(loc);camera.rotation_euler=(Vector(P(target))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.lens=lens
 if view=='cafe_larger_floorplan':
  for ob in bpy.data.objects:
   if ob.name.startswith(('CI2_Ceiling','CI2_Beams','C1_Lamp')):ob.hide_render=True
  camera.data.type='ORTHO';camera.data.ortho_scale=40;sc.render.resolution_x=1300;sc.render.resolution_y=1100
 sc.render.filepath=str(OUT/(view+'.png'));bpy.ops.render.render(write_still=True);log('RENDER '+view);log('CAFEINTERIOR2_RENDER_DONE')
except Exception:log(traceback.format_exc());log('CAFEINTERIOR2_RENDER_FAILED')
