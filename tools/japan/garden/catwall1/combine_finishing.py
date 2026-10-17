"""One import for the seven waiting cats and requested left-wall knickknacks."""
import bpy,json,traceback
from pathlib import Path
from mathutils import Matrix
D=Path(__file__).resolve().parent;O=D/'out';LOG=O/'combined_log.txt'
def log(s):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(s)+'\n')
try:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.edit.use_global_undo=False
    top=bpy.data.objects.new('cafe_finishing1',None);bpy.context.scene.collection.objects.link(top)
    for path in [D.parent/'cafe_cats2/out/cat_cafe_seven_cats_rigged.blend',O/'catwall1_source.blend']:
        with bpy.data.libraries.load(str(path),link=False) as (src,dst):dst.objects=src.objects;dst.actions=src.actions
        for ob in dst.objects:
            if ob:bpy.context.scene.collection.objects.link(ob)
            if ob and ob.parent is None:ob.parent=top
    bpy.context.view_layer.update();before={}
    for o in bpy.data.objects:
        if o.type=='MESH':
            p=[o.matrix_world@v.co for v in o.data.vertices];before[o.name]={'lo':[min(v[k] for v in p) for k in range(3)],'hi':[max(v[k] for v in p) for k in range(3)],'tris':sum(len(f.vertices)-2 for f in o.data.polygons)}
    assert len(before)==51;assert len([o for o in bpy.data.objects if o.type=='ARMATURE'])==7
    bpy.ops.object.select_all(action='SELECT');fbx=O/'japan_kit26_cafe_finishing1.fbx'
    bpy.ops.wm.save_as_mainfile(filepath=str(O/'cafe_finishing1_source.blend'))
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',global_scale=1,apply_unit_scale=True,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=False,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,object_types={'MESH','ARMATURE','EMPTY'},mesh_smooth_type='FACE')
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx),use_image_search=True)
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==51;assert len([o for o in bpy.data.objects if o.type=='ARMATURE'])==7
    skinchecks=[]
    for name,info in before.items():
        o=bpy.data.objects[name];p=[o.matrix_world@v.co for v in o.data.vertices]
        for k in range(3):assert abs(min(v[k] for v in p)-info['lo'][k])<.003 and abs(max(v[k] for v in p)-info['hi'][k])<.003,name
        if name.startswith('CC2_') and name not in ['CC2_Origin','CC2_Right','CC2_Front']:
            arm=next(m.object for m in o.modifiers if m.type=='ARMATURE');assert len(arm.data.bones)==10
            assert all(0<len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<.00001 for v in o.data.vertices)
            imgs=[n.image for mat in o.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image];assert imgs and all(im.size[0]==2048 and im.size[1]==2048 for im in imgs)
            rest=[(o.matrix_world@v.co).copy() for v in o.data.vertices];pb=arm.pose.bones['Head'];pb.rotation_mode='XYZ';pb.rotation_euler.y=.12;bpy.context.view_layer.update()
            ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();delta=max((o.matrix_world@v.co-rest[v.index]).length for v in me.vertices);ev.to_mesh_clear();pb.matrix_basis=Matrix.Identity(4);assert delta>.04
            skinchecks.append({'mesh':name,'bones':10,'pose_delta':delta})
    checks={'meshes':51,'wall_placed_meshes':38,'cats':7,'armatures':7,'bones':70,'triangles':sum(i['tris'] for i in before.values()),'bounds_tolerance':.003,'skinchecks':skinchecks}
    (O/'combined_checks.json').write_text(json.dumps(checks,indent=2));log('FINISHING1_ROUNDTRIP_PASS: 51 meshes, 7 cats, 70 bones; wall bounds, textures, weights and actual skin deformation preserved')
    log('FINISHING1_DONE')
except Exception:
    log(traceback.format_exc());log('FINISHING1_FAILED')
