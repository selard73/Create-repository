import bpy,json,math,traceback,sys
from pathlib import Path
from mathutils import Vector,Matrix
D=Path(__file__).resolve().parent;O=D/'out';O.mkdir(exist_ok=True);LOG=D/'package_log.txt'
CFG=json.loads((D/'rig_manifest.json').read_text())
ARGS=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
CAFEBLEND=Path(ARGS[0]) if ARGS else D.parent/'cat_cafe1'/'out_catcafe1'/'cat_cafe1_review.blend'
def log(x):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(x)+'\n')
def append_cat(c):
    with bpy.data.libraries.load(str(D/c['name']/'rigged.blend'),link=False) as (src,dst):dst.objects=src.objects;dst.actions=src.actions
    for ob in dst.objects:
        if ob:bpy.context.scene.collection.objects.link(ob)
    arm=next(o for o in dst.objects if o and o.type=='ARMATURE');ob=next(o for o in dst.objects if o and o.type=='MESH')
    ob.name='CC1_'+c['name'];arm.name='CC1_'+c['name']+'_Rig'
    return ob,arm
def cube(name,p):
    bpy.ops.mesh.primitive_cube_add(size=.04,location=p);ob=bpy.context.object;ob.name=name;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return ob
def camshot(name,loc,target,lens=40,ortho=None,res=(1400,950)):
    sc=bpy.context.scene;sc.render.resolution_x,sc.render.resolution_y=res;sc.render.resolution_percentage=100
    cam=bpy.data.objects.new('CatReviewCamera',bpy.data.cameras.new('CatReviewCamera'));sc.collection.objects.link(cam);sc.camera=cam
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
    if ortho:cam.data.type='ORTHO';cam.data.ortho_scale=ortho
    sc.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True);log('RENDER '+name)
def P(p):return (p[0],-p[2],p[1])
try:
    bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene;sc.unit_settings.system='NONE'
    root=bpy.data.objects.new('cat_cafe_cats1',None);sc.collection.objects.link(root);rows=[]
    for i,c in enumerate(CFG):
        ob,arm=append_cat(c);arm.parent=root;arm.location=(i*4.5,0,0)
        rows.append({**c,'mesh_name':ob.name,'source_origin':[i*4.5,0,0]})
    for n,p in [('CC1_Origin',(-4,3,0)),('CC1_Right',(-2,3,0)),('CC1_Front',(-4,1,0))]:cube(n,p).parent=root
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(O/'cat_cafe_cats_rigged.blend'))
    fbx=O/'japan_kit24_cat_cafe_cats1.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',global_scale=1,apply_unit_scale=True,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=False,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,object_types={'MESH','ARMATURE','EMPTY'},mesh_smooth_type='FACE')
    log('EXPORTED 6 skinned cats + 3 alignment markers')
    # Validate the actual FBX, not just the pre-export Blender scene.
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx),use_image_search=True)
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==9
    assert len([o for o in bpy.data.objects if o.type=='ARMATURE'])==6
    checks=[]
    for c in rows:
        ob=bpy.data.objects[c['mesh_name']];arm=next(m.object for m in ob.modifiers if m.type=='ARMATURE')
        assert len(arm.data.bones)==10
        assert len(ob.data.uv_layers)==1
        assert all(0<len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<.00001 for v in ob.data.vertices)
        ps=[ob.matrix_world@v.co for v in ob.data.vertices];lo=[min(p[k] for p in ps) for k in range(3)];hi=[max(p[k] for p in ps) for k in range(3)]
        for k in range(3):
            shift=c['source_origin'][0] if k==0 else 0
            assert abs(lo[k]-c['lo'][k]-shift)<.002 and abs(hi[k]-c['hi'][k]-shift)<.002,(c['name'],k,lo,hi)
        imgs=[n.image for mat in ob.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        assert imgs and all(im.size[0]==2048 and im.size[1]==2048 for im in imgs)
        assert all(im.packed_file or Path(bpy.path.abspath(im.filepath)).exists() for im in imgs)
        # Imported weights must produce actual deformation when a bone moves.
        rest=[(ob.matrix_world@v.co).copy() for v in ob.data.vertices];pb=arm.pose.bones['Head'];pb.rotation_mode='XYZ';pb.rotation_euler.y=.12;bpy.context.view_layer.update()
        ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();delta=max((ob.matrix_world@v.co-rest[v.index]).length for v in me.vertices);ev.to_mesh_clear();pb.matrix_basis=Matrix.Identity(4)
        assert delta>.04,(c['name'],delta)
        checks.append({'name':c['name'],'bones':10,'triangles':c['triangles'],'max_influences':max(len(v.groups) for v in ob.data.vertices),'unweighted':0,'texture':[2048,2048],'roundtrip_pose_delta':delta})
    (O/'export_checks.json').write_text(json.dumps(checks,indent=2));(O/'manifest.json').write_text(json.dumps(rows,indent=2))
    log('ROUNDTRIP_PASS: 6 meshes, 60 bones, zero unweighted vertices, <=4 influences, textures present, posed mesh deformation verified')
    # A native Blender lineup, preserving original textures and poses.
    bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.light='STUDIO';sc.display.shading.color_type='TEXTURE';sc.display.shading.show_shadows=True
    sc.world=bpy.data.worlds.new('ReviewWorld');sc.world.color=(.38,.40,.42);sc.view_settings.view_transform='Standard'
    for i,c in enumerate(CFG):
        ob,arm=append_cat(c);arm.location=((i%3-1)*4.4,(i//3)*4.5,0);arm.rotation_euler.z=math.radians(-16 if i!=3 else -55)
    camshot('cats_lineup',(0,-15,14),(0,2.1,1.05),ortho=14.2,res=(1500,1050))
    # Bring the actual cafe mesh study into Blender and fit all six cats to the saved pads.
    bpy.ops.wm.open_mainfile(filepath=str(CAFEBLEND))
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True;sc.view_settings.view_transform='AgX'
    sc.world=bpy.data.worlds.new('CafeDaylight');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.62,.72,.9,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.38
    for c in CFG:
        ob,arm=append_cat(c);arm.location=P(c['position']);arm.rotation_euler.z=math.radians(c['yaw'])
    def area(name,p,power,size,target):
        d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);sc.collection.objects.link(o);o.location=P(p);o.rotation_euler=(Vector(P(target))-o.location).to_track_quat('-Z','Y').to_euler()
    area('Window daylight',(2,6,4),1800,12,(1,2,-11));area('Front fill',(-15,16,16),2800,16,(0,3,-5))
    for x,z in [(-7.7,-11.9),(1.6,-7.2),(7.2,-16.2)]:
        d=bpy.data.lights.new('Warm pendant','POINT');d.energy=200;d.color=(1,.84,.65);d.shadow_soft_size=.8;o=bpy.data.objects.new('Warm pendant',d);sc.collection.objects.link(o);o.location=P((x,7.05,z))
    bpy.ops.wm.save_as_mainfile(filepath=str(O/'cat_cafe_with_cats_review.blend'))
    camshot('cafe_cats_window',P((-5.8,4.7,-8.9)),P((3.2,3.25,-1.8)),lens=28)
    camshot('cafe_cats_climbing',P((1.4,5.8,-3.6)),P((9.2,4.35,-10.2)),lens=32)
    log('CATPACKAGE_DONE')
except Exception:
    log(traceback.format_exc());log('CATPACKAGE_FAILED')
