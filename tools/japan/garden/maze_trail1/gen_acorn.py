"""Kit30: a small, fallen honey-gold acorn; all three pieces are real meshes."""
from pathlib import Path
import bpy, math, json, traceback
from mathutils import Vector, Matrix
D=Path(__file__).resolve().parent
OUT=D.parent.parent/'outputs'
OUT.mkdir(exist_ok=True)
LOG=D/'gen_log.txt'
def log(s):
    with LOG.open('a',encoding='utf-8') as f:f.write(s+'\n')
def lin(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
try:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    root=bpy.data.objects.new('maze_trail_acorn',None);bpy.context.collection.objects.link(root)
    pieces=[]
    def lathe(name,profile,color,n=20,ripple=0):
        verts=[];faces=[]
        for k,(z,r) in enumerate(profile):
            for j in range(n):
                a=j*2*math.pi/n
                rr=r*(1+ripple*math.cos(a*10+z*40))
                verts.append((rr*math.cos(a),rr*math.sin(a),z))
        for k in range(len(profile)-1):
            for j in range(n):
                a=k*n+j;b=k*n+(j+1)%n;c=b+n;d=a+n
                faces.extend(((a,b,c),(a,c,d)))
        faces.extend([tuple(reversed(range(n))),tuple((len(profile)-1)*n+j for j in range(n))])
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.parent=root
        mat=bpy.data.materials.new(name);mat.diffuse_color=tuple(lin(c/255) for c in color)+(1,);obj.data.materials.append(mat)
        for p in mesh.polygons:p.use_smooth=True
        pieces.append(obj);return obj
    lathe('TrailAcorn_Nut',[(0,.025),(.06,.14),(.18,.28),(.34,.35),(.53,.375),(.69,.34),(.76,.28)],[231,169,69])
    lathe('TrailAcorn_Cap',[(.64,.36),(.67,.415),(.73,.425),(.82,.39),(.91,.30),(.97,.17),(.99,.04)],[133,88,43],40,.022)
    lathe('TrailAcorn_Stem',[(.94,.055),(1.06,.05),(1.14,.032)],[96,64,36],10)
    # Fallen acorn; bake the pose so the ground footprint remains consistent after import.
    rot=Matrix.Rotation(math.radians(68),4,'Y')
    for ob in pieces:
        ob.data.transform(rot)
    low=min(v.co.z for ob in pieces for v in ob.data.vertices)
    for ob in pieces:
        for v in ob.data.vertices:v.co.z-=low
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for ob in pieces:ob.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0]
    fbx=OUT/'japan_kit30_maze_acorn_trail.fbx'
    bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(D/'maze_acorn.blend'))
    (D/'mesh_manifest.json').write_text(json.dumps({'pieces':[{ 'name':p.name,'vertices':len(p.data.vertices),'polygons':len(p.data.polygons)} for p in pieces],'fbx':str(fbx)},indent=2))
    log('MAZEACORN_DONE '+str(fbx))
except Exception:
    log(traceback.format_exc());log('MAZEACORN_FAILED');raise
