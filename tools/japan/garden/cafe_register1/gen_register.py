"""Kit31: original compact cafe register and shallow change tray, all real meshes.
Reference for scale/details: this game's French bookshop register. Customer=local+Z.
"""
from pathlib import Path
import bpy, bmesh, math, json, traceback
from mathutils import Vector, Matrix
D=Path(__file__).resolve().parent;OUT=D.parent.parent/'outputs';OUT.mkdir(exist_ok=True)
LOG=D/'build_log.txt';COL={'Cream':(205,198,174),'Charcoal':(44,49,43),'Black':(24,31,26),'Keys':(223,218,197),'Sage':(124,146,105),'Rose':(170,94,76),'Brass':(157,126,66),'Paper':(238,229,203),'Display':(157,192,126),'Celadon':(110,144,139)}
objects=[];groups={}
def log(x):
    with LOG.open('a',encoding='utf-8')as f:f.write(str(x)+'\n')
def P(v):return(v[0],-v[2],v[1])
def lin(v):
    v/=255;return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def mat(k):
    m=bpy.data.materials.get('CR1_'+k)
    if m:return m
    m=bpy.data.materials.new('CR1_'+k);m.use_nodes=True
    c=tuple(lin(v)for v in COL[k])+(1,);m.diffuse_color=c
    b=m.node_tree.nodes['Principled BSDF'];b.inputs['Base Color'].default_value=c;b.inputs['Roughness'].default_value=.48
    if k=='Brass':b.inputs['Metallic'].default_value=.55
    if k=='Display':b.inputs['Emission Color'].default_value=c;b.inputs['Emission Strength'].default_value=.25
    return m
def finish(o,g,k,bevel=0):
    o.name=g+'_'+k;o.data.materials.append(mat(k));bpy.context.view_layer.objects.active=o
    if bevel:
        b=o.modifiers.new('Soft cast edges','BEVEL');b.width=bevel;b.segments=3;b.limit_method='ANGLE';bpy.ops.object.modifier_apply(modifier=b.name)
        w=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');w.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=w.name)
    groups.setdefault((g,k),[]).append(o);return o
def box(g,k,c,size,bevel=.015,tilt=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=P(c));o=bpy.context.object;o.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.rotation_euler.x=math.radians(tilt)
    return finish(o,g,k,bevel)
def poly(g,k,verts,faces,bevel=0):
    me=bpy.data.meshes.new(g+k);me.from_pydata([P(v)for v in verts],[],faces);me.update()
    o=bpy.data.objects.new(g+k,me);bpy.context.collection.objects.link(o);return finish(o,g,k,bevel)
def disk(g,k,c,r,depth):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=depth,location=P(c))
    return finish(bpy.context.object,g,k,.005)
def seven_segment(g,x,y,z,scale=.12):
    w=scale;h=scale*1.7;t=scale*.17
    for cy in [y-h/2,y+h/2]:box(g,'Display',(x,cy,z),(w-t,t,.006),.003)
    for cx in [x-w/2,x+w/2]:
        for cy in [y-h*.25,y+h*.25]:box(g,'Display',(cx,cy,z),(t,h*.40,.006),.003)
def build():
    g='CR1_Register'
    box(g,'Charcoal',(0,.145,0),(1.45,.29,1.3),.055)
    box(g,'Black',(0,.13,-.654),(1.30,.205,.022),.018)
    box(g,'Cream',(0,.14,-.669),(1.23,.17,.035),.015)
    box(g,'Brass',(0,.16,-.702),(.42,.045,.045),.012)
    for x in [-.58,.58]:
        for z in [-.48,.48]:box(g,'Black',(x,.025,z),(.17,.05,.18),.015)
    # One closed bevelled wedge, not a pile of slabs: sloped operator keyboard deck.
    verts=[(-.66,.29,-.56),(.66,.29,-.56),(.66,.29,.54),(-.66,.29,.54),(-.66,.45,-.56),(.66,.45,-.56),(.66,.94,.54),(-.66,.94,.54)]
    poly(g,'Cream',verts,[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],.045)
    angle=-math.degrees(math.atan(.49/1.1))
    def deck_y(z):return .45+(z+.56)*.49/1.1
    box(g,'Charcoal',(.10,deck_y(-.17)+.015,-.17),(1.03,.035,.68),.025,angle)
    for row in range(4):
        z=-.42+row*.147
        for col in range(3):
            x=-.22+col*.205
            box(g,'Keys',(x,deck_y(z)+.055,z),(.156,.065,.108),.018,angle)
    for row,k in enumerate(['Rose','Keys','Sage']):
        z=-.39+row*.18;box(g,k,(.43,deck_y(z)+.055,z),(.17,.065,.14),.018,angle)
    # Tall double-sided display: dark operator screen above the keypad and a restrained customer LCD.
    box(g,'Charcoal',(.10,1.01,.365),(1.02,.38,.30),.045)
    box(g,'Black',(.10,1.02,.197),(.83,.235,.025),.012)
    box(g,'Black',(.10,1.02,.529),(.83,.235,.025),.012)
    for x in [-.14,.03,.20,.37]:
        seven_segment(g,x,1.02,.546,.095)
        seven_segment(g,x,1.02,.181,.095)
    # Receipt slot, bent paper strip and a few quiet printed lines; no explanatory sign.
    box(g,'Black',(-.49,deck_y(.09)+.018,.09),(.21,.035,.22),.012,angle)
    receipt=[(-.575,.76,-.015),(-.375,.76,-.015),(-.375,1.04,.045),(-.575,1.04,.045),(-.375,1.15,.135),(-.575,1.15,.135)]
    o=poly(g,'Paper',receipt,[(0,1,2,3),(3,2,4,5)])
    bpy.context.view_layer.objects.active=o
    s=o.modifiers.new('Paper thickness','SOLIDIFY');s.thickness=.008;bpy.ops.object.modifier_apply(modifier=s.name)
    for i in range(4):box(g,'Charcoal',(-.475,.85+i*.038,.001+i*.008),(.13,.005,.008),0)
    # Oval ceramic change tray is a separate model in the combined kit, with two small coins.
    g='CR1_Tray';profile=[(0,.05),(.015,.38),(.04,.49),(.115,.53),(.145,.51),(.137,.455),(.07,.40),(.065,.01)]
    vs=[];fs=[];n=40
    for h,r in profile:
        for j in range(n):a=j*math.tau/n;vs.append((3+1.15*r*math.cos(a),h,.80*r*math.sin(a)))
    for i in range(len(profile)-1):
        for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    fs.append(tuple(reversed(range(n))));fs.append(tuple((len(profile)-1)*n+j for j in range(n)))
    tray=poly(g,'Celadon',vs,fs)
    for p in tray.data.polygons:p.use_smooth=True
    disk(g,'Brass',(2.89,.081,.04),.105,.025);disk(g,'Brass',(3.10,.083,-.035),.085,.025)
    # Join per material so the whole station stays inexpensive to render.
    for (g,k),obs in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in obs:o.select_set(True)
        bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();o=bpy.context.object;o.name=g+'_'+k
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
        w=o.modifiers.new('Final outward normals','WEIGHTED_NORMAL');w.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=w.name)
        objects.append(o)
    for name,pos in [('CR1_Origin',(0,0,0)),('CR1_Right',(2,0,0)),('CR1_Front',(0,0,2))]:
        bpy.ops.mesh.primitive_cube_add(size=.025,location=P(pos));o=bpy.context.object;o.name=name;objects.append(o)
def render(name,eye,target):
    sc=bpy.context.scene;cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));sc.collection.objects.link(cam);sc.camera=cam
    cam.location=P(eye);cam.rotation_euler=(Vector(P(target))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=48
    sc.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True);log('RENDER '+name)
try:
    bpy.ops.wm.read_factory_settings(use_empty=True);build()
    root=bpy.data.objects.new('cafe_register1',None);bpy.context.collection.objects.link(root)
    manifest={'root':'cafe_register1','materials':{k:list(v)for k,v in COL.items()},'meshes':[]}
    for o in objects:
        o.parent=root
        points=[o.matrix_world@v.co for v in o.data.vertices];q=[(p.x,p.z,-p.y)for p in points]
        manifest['meshes'].append({'name':o.name,'min':[min(p[i]for p in q)for i in range(3)],'max':[max(p[i]for p in q)for i in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)})
    assert all(v['triangles']<10000 for v in manifest['meshes'])
    (D/'manifest.json').write_text(json.dumps(manifest,indent=2))
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in objects:o.select_set(True)
    fbx=OUT/'japan_kit31_cafe_register.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(D/'cafe_register1.blend'))
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx))
    for record in manifest['meshes']:
        o=bpy.data.objects[record['name']];q=[(p.x,p.z,-p.y)for p in[o.matrix_world@v.co for v in o.data.vertices]]
        assert all(abs(min(p[i]for p in q)-record['min'][i])<.003 and abs(max(p[i]for p in q)-record['max'][i])<.003 for i in range(3)),record['name']
    log('ROUNDTRIP_PASS: names and bounds within .003 studs')
    # Model review on a dark wood counter; not represented as an in-game screenshot.
    for o in bpy.data.objects:
        if o.name.startswith('CR1_Origin')or o.name.startswith('CR1_Right')or o.name.startswith('CR1_Front'):o.hide_render=True
        if o.type=='MESH'and o.name.startswith('CR1_Tray'):o.matrix_world=Matrix.Translation(Vector(P((-2.7,0,1.05))))@o.matrix_world
    bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,-.13));board=bpy.context.object;board.dimensions=(8,6,.26);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    wood=bpy.data.materials.new('Counter walnut');wood.use_nodes=True;nodes=wood.node_tree.nodes;b=nodes.get('Principled BSDF');b.inputs['Roughness'].default_value=.68
    tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=3;tex.inputs['Detail'].default_value=2
    coord=nodes.new('ShaderNodeTexCoord');scale=nodes.new('ShaderNodeVectorMath');scale.operation='MULTIPLY';scale.inputs[1].default_value=(.35,7,3)
    ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.035,.015,.007,1);ramp.color_ramp.elements[1].color=(.16,.085,.035,1)
    wood.node_tree.links.new(coord.outputs['Generated'],scale.inputs[0]);wood.node_tree.links.new(scale.outputs[0],tex.inputs['Vector']);wood.node_tree.links.new(tex.outputs['Fac'],ramp.inputs[0]);wood.node_tree.links.new(ramp.outputs[0],b.inputs['Base Color']);board.data.materials.append(wood)
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.render.resolution_x=1200;sc.render.resolution_y=900;sc.render.resolution_percentage=100
    sc.world=bpy.data.worlds.new('Warm studio');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.40,.32,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.45
    sc.view_settings.view_transform='AgX'
    for name,pos,power,size in [('Key',(-3,-2,5),320,4),('Fill',(3,3,3),140,3)]:
        light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=size;o=bpy.data.objects.new(name,light);sc.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,.5))-o.location).to_track_quat('-Z','Y').to_euler()
    render('cafe_register_model_customer',(3.3,3.6,4.6),(0,.40,.45))
    render('cafe_register_model_server',(-2.2,2.9,-3.2),(0,.5,.25))
    log('CAFEREGISTER_DONE '+str(fbx))
except Exception:
    log(traceback.format_exc());log('CAFEREGISTER_FAILED');raise
