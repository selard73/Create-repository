import bpy,sys,json,math,traceback,gc
import numpy as np
from pathlib import Path
from mathutils import Vector
D=Path(__file__).resolve().parent
LOG=D/'inspect_log.txt'
def log(x):
    with LOG.open('a',encoding='utf-8') as f:f.write(str(x)+'\n')
def bounds(o):
    a=np.empty(len(o.data.vertices)*3,dtype=np.float32);o.data.vertices.foreach_get('co',a);a=a.reshape(-1,3)
    return a,a.min(0),a.max(0)
try:
    cats=json.loads((D/'archives.json').read_text());stats=[]
    for cat in cats:
        name=cat['name'].rsplit('_',1)[0]; out=D/name;out.mkdir(exist_ok=True)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.preferences.edit.use_global_undo=False
        fbx=next(Path(cat['directory']).rglob('*.fbx'))
        log('IMPORT_START '+str(fbx))
        bpy.ops.import_scene.fbx(filepath=str(fbx),use_image_search=False,use_custom_normals=False,use_anim=False)
        log('IMPORT_FINISHED')
        for mesh in bpy.data.meshes:mesh.materials.clear()
        for mat in list(bpy.data.materials):bpy.data.materials.remove(mat)
        for img in list(bpy.data.images):bpy.data.images.remove(img)
        gc.collect()
        log('Released imported materials/textures; explicit colour map loaded after reduction')
        original=[{'name':o.name,'type':o.type,'dims':list(o.dimensions)} for o in bpy.context.scene.objects]
        log({'cat':name,'imported':original})
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        bpy.ops.object.select_all(action='DESELECT')
        for o in meshes:o.select_set(True)
        bpy.context.view_layer.objects.active=meshes[0]
        if len(meshes)>1:bpy.ops.object.join()
        ob=bpy.context.object;ob.name=name
        ob.parent=None
        for m in list(ob.modifiers):ob.modifiers.remove(m)
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        log('Applied transform')
        for o in list(bpy.data.objects):
            if o!=ob:bpy.data.objects.remove(o,do_unlink=True)
        a,lo,hi=bounds(ob);original_tris=sum(len(p.vertices)-2 for p in ob.data.polygons)
        shift=np.array([(lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2]])
        a=(a-shift)*(2.4/(hi[2]-lo[2]));ob.data.vertices.foreach_set('co',a.flatten());ob.data.update()
        np.save(out/'full_points.npy',a)
        log('Saved full points; source triangles '+str(original_tris))
        try:bpy.ops.mesh.customdata_custom_splitnormals_clear()
        except:pass
        if original_tris>9000:
            log('DECIMATE_START')
            dec=ob.modifiers.new('MobileBudget','DECIMATE');dec.ratio=9000/original_tris;dec.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=dec.name)
            log('DECIMATE_FINISHED')
        for p in ob.data.polygons:p.use_smooth=True
        mat=bpy.data.materials.new(name+'_Fur');mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value=.8
        png=fbx.with_suffix('.png');img=bpy.data.images.load(str(png),check_existing=False);raw_size=list(img.size)
        img.scale(2048,2048);img.filepath_raw=str(out/(name+'_color.png'));img.file_format='PNG';img.save();img.pack()
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
        mat.node_tree.nodes.active=tex
        ob.data.materials.clear();ob.data.materials.append(mat)
        a,lo,hi=bounds(ob);np.save(out/'points.npy',a)
        stats.append({'name':name,'original':original,'source_triangles':original_tris,'triangles':sum(len(p.vertices)-2 for p in ob.data.polygons),'vertices':len(ob.data.vertices),'lo':lo.tolist(),'hi':hi.tolist(),'raw_texture_size':raw_size,'uv_layers':len(ob.data.uv_layers)})
        log(stats[-1]);(D/'inspection.json').write_text(json.dumps(stats,indent=2))
        sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.light='STUDIO';sc.display.shading.color_type='TEXTURE'
        sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=False;sc.display.shading.background_type='WORLD'
        sc.world=bpy.data.worlds.new('StudioWorld');sc.world.color=(.16,.18,.2)
        sc.view_settings.view_transform='Standard';sc.render.image_settings.file_format='PNG';sc.render.resolution_x=650;sc.render.resolution_y=700;sc.render.resolution_percentage=100
        cam=bpy.data.cameras.new('Camera');co=bpy.data.objects.new('Camera',cam);sc.collection.objects.link(co);sc.camera=co;cam.type='ORTHO';cam.ortho_scale=3.15
        target=Vector((0,0,1.2))
        for tag,vec in [('front',(0,-7,1.2)),('back',(0,7,1.2)),('side',(7,0,1.2)),('threequarter',(5,-7,4.0))]:
            co.location=vec;co.rotation_euler=(target-co.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(out/(tag+'.png'));bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(co,do_unlink=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out/'prepared.blend'))
        log(name+' prepared and rendered')
    log('CATINSPECT_DONE')
except Exception:
    log(traceback.format_exc());log('CATINSPECT_FAILED')
