import bpy,bmesh,json,traceback,sys,math
from pathlib import Path
root=Path(__file__).resolve().parent
log=root/"build.log"
try:
    raw=json.loads((root/"original_bank_mesh.json").read_text())
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    verts=[]
    profile={-.45:-.20,.05:1.60,.35:2.65,.45:2.85}
    center_y=1.325
    for x,y,z in raw["vertices"]:
        k=min(profile,key=lambda k:abs(y-k))
        assert abs(y-k)<.001
        verts.append((x,-z,profile[k]-center_y))
    me=bpy.data.meshes.new("RiceBank_Grounded_NoBakedTint")
    me.from_pydata(verts,[],[[i-1 for i in f] for f in raw["faces"]]); me.update()
    bm=bmesh.new(); bm.from_mesh(me)
    # Original FBX seam has seven pairs offset by 0.0105-0.0132 studs.
    # The next nearest pair is 0.3389 studs, so this weld affects only the seam.
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.015)
    boundaries=[e for e in bm.edges if e.is_boundary]
    # There should be an outer and an inner closed loop, both at ground level.
    assert len(boundaries)==240, (len(bm.verts),len(boundaries))
    assert all(abs(v.co.z-(-.20-center_y))<.001 for e in boundaries for v in e.verts)
    bmesh.ops.bridge_loops(bm,edges=boundaries)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges)
    vol=bm.calc_volume(signed=True)
    if vol<0:
        bmesh.ops.reverse_faces(bm,faces=list(bm.faces)); vol=bm.calc_volume(signed=True)
    assert vol>0
    bm.to_mesh(me); bm.free(); me.update()
    ob=bpy.data.objects.new("JP_Rice_Bank_Grounded1",me); bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active=ob; ob.select_set(True)
    # Planar UVs per face, in stud scale, for material-compatible export.
    uv=me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        poly.use_smooth=True
        axis=max(range(3),key=lambda i:abs(poly.normal[i]))
        axes=[i for i in range(3) if i!=axis]
        for li in poly.loop_indices:
            co=me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv=(co[axes[0]]/5,co[axes[1]]/5)
    # Preserve sharp underside versus gently rounded embankment top.
    for poly in me.polygons:
        if poly.normal.z<-.8: poly.use_smooth=False
    mat=bpy.data.materials.new("Natural earth - no vertex tint")
    mat.diffuse_color=(.35,.25,.14,1); me.materials.append(mat)
    out={"vertices":[[v.co.x,v.co.z,-v.co.y] for v in me.vertices],
         "faces":[[i+1 for i in p.vertices] for p in me.polygons],
         "uvs":[[[uv.data[li].uv.x,uv.data[li].uv.y] for li in p.loop_indices] for p in me.polygons],
         "centerY":center_y,"size":[59,3.05,52]}
    (root/"repaired_bank_mesh.json").write_text(json.dumps(out,separators=(",",":")))
    stats={"vertices":len(me.vertices),"triangles":len(me.polygons),"closedManifold":True,"positiveVolume":vol,
           "footprint":[59,52],"worldY":[-.20,2.85],"vertexColorAttributes":len(me.color_attributes)}
    (root/"geometry_checks.json").write_text(json.dumps(stats,indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(root/"rice_bank_grounded1.blend"))
    bpy.ops.export_scene.fbx(filepath=str(root/"rice_bank_grounded1.fbx"),use_selection=True,axis_forward="-Z",axis_up="Y",apply_scale_options="FBX_SCALE_ALL",bake_space_transform=True,colors_type="NONE")
    log.write_text(json.dumps(stats)+"\nRICEBANK_DONE")
except Exception:
    log.write_text(traceback.format_exc()+"\nRICEBANK_FAILED")
