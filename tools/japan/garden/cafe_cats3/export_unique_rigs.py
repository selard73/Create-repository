"""Roblox-safe unique bone names across a single combined import of seven cats."""
import bpy,json,traceback
from pathlib import Path
from mathutils import Matrix
D=Path(__file__).resolve().parent;O=D/'out';O.mkdir(exist_ok=True);LOG=O/'build_log.txt'
def log(s):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(s)+'\n')
try:
    bpy.context.preferences.edit.use_global_undo=False
    bpy.ops.wm.open_mainfile(filepath=str(D.parent/'cafe_cats2/out/cat_cafe_seven_cats_rigged.blend'))
    rows=json.loads((D.parent/'cafe_cats2/out/manifest.json').read_text());names=set()
    for i,c in enumerate(rows):
        ob=bpy.data.objects[c['mesh_name']];arm=next(m.object for m in ob.modifiers if m.type=='ARMATURE')
        prefix='C%02d_'%(i+1);c['bone_prefix']=prefix;c['mesh_name']=ob.name.replace('CC2_','CC3_');ob.name=c['mesh_name'];arm.name=ob.name+'_Rig'
        if arm.animation_data:arm.animation_data_clear()
        for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
        old_names=[b.name for b in arm.data.bones]
        for name in old_names:
            if ob.vertex_groups.get(name):ob.vertex_groups[name].name=prefix+name
            arm.data.bones[name].name=prefix+name
        assert len(arm.data.bones)==10
        for b in arm.data.bones:assert b.name not in names;names.add(b.name)
        assert {v.name for v in ob.vertex_groups}=={b.name for b in arm.data.bones}
    bpy.data.objects['cat_cafe_cats2'].name='cat_cafe_cats3'
    for n in ['Origin','Right','Front']:bpy.data.objects['CC2_'+n].name='CC3_'+n
    assert len(names)==70
    bpy.context.view_layer.update();bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(O/'cat_cafe_seven_cats_unique_rigs.blend'))
    fbx=O/'japan_kit27_cat_cafe_cats3.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,axis_forward='-Z',axis_up='Y',global_scale=1,apply_unit_scale=True,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=False,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,object_types={'MESH','ARMATURE','EMPTY'},mesh_smooth_type='FACE')
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(fbx),use_image_search=True)
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==10
    arms=[o for o in bpy.data.objects if o.type=='ARMATURE'];assert len(arms)==7
    assert len({b.name for a in arms for b in a.data.bones})==70
    checks=[]
    for c in rows:
        ob=bpy.data.objects[c['mesh_name']];arm=next(m.object for m in ob.modifiers if m.type=='ARMATURE');prefix=c['bone_prefix']
        assert len(arm.data.bones)==10 and all(b.name.startswith(prefix) for b in arm.data.bones)
        assert all(0<len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<.00001 for v in ob.data.vertices)
        ps=[ob.matrix_world@v.co for v in ob.data.vertices]
        for k in range(3):
            shift=c['source_origin'][0] if k==0 else 0
            assert abs(min(p[k] for p in ps)-c['lo'][k]-shift)<.003
            assert abs(max(p[k] for p in ps)-c['hi'][k]-shift)<.003
        imgs=[n.image for mat in ob.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        assert imgs and all(im.size[0]==2048 and im.size[1]==2048 for im in imgs)
        pb=arm.pose.bones[prefix+'Head'];pb.rotation_mode='XYZ';pb.rotation_euler.y=.12;bpy.context.view_layer.update()
        ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();delta=max((ob.matrix_world@v.co-ps[v.index]).length for v in me.vertices);ev.to_mesh_clear();pb.matrix_basis=Matrix.Identity(4)
        assert delta>.04
        # Include exact FBX-imported world bind transforms for a Studio diagnostic.
        bones={}
        for b in arm.data.bones:
            m=arm.matrix_world@b.matrix_local
            bones[b.name]={'parent':b.parent.name if b.parent else None,'blender_world_matrix':[list(r) for r in m]}
        checks.append({'mesh':ob.name,'prefix':prefix,'bones':bones,'pose_delta':delta})
    (O/'manifest.json').write_text(json.dumps(rows,indent=2));(O/'export_checks.json').write_text(json.dumps(checks,indent=2))
    log('CATCATS3_ROUNDTRIP_PASS: 7 cats, 70 globally unique bone names, original geometry/textures/weights preserved, seven deformation checks passed')
    log('CATCATS3_DONE')
except Exception:
    log(traceback.format_exc());log('CATCATS3_FAILED')
