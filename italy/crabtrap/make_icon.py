"""Hotbar icon for the crab trap Tool (Oct 4 2026): render crabtrap.fbx 3/4 view on a transparent background (icon.png,
512 px), then write icon_carrier.fbx = one quad textured with it (Import Queue -> its MeshPart.TextureID is the uploaded
image, which goes on Tool.TextureId).  Run: blender -b --python make_icon.py"""
import bpy, math, os, traceback
D = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(D, "icon_log.txt")
def log(m): open(LOG, "a").write(str(m) + "\n")
try:
    open(LOG, "w").close()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(D, "crabtrap.fbx"))
    net_img = bpy.data.images.load(os.path.join(D, "net.png"))
    for o in bpy.data.objects:
        if o.type != "MESH": continue
        m = bpy.data.materials.new(o.name + "_icon"); m.use_nodes = True; nt = m.node_tree; b = nt.nodes["Principled BSDF"]
        if o.name.startswith("TrapNet"):
            t = nt.nodes.new("ShaderNodeTexImage"); t.image = net_img
            nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); nt.links.new(t.outputs["Alpha"], b.inputs["Alpha"])
            try: m.surface_render_method = "DITHERED"
            except Exception: pass
        else:
            b.inputs["Base Color"].default_value = (0.62, 0.64, 0.67, 1); b.inputs["Roughness"].default_value = 0.45
        o.data.materials.clear(); o.data.materials.append(m)
    sc = bpy.context.scene
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 2.9
    # the trap's axis is along the model's long side; look at it three-quarter, a little from above
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    import mathutils
    lo = mathutils.Vector((1e9,) * 3); hi = mathutils.Vector((-1e9,) * 3)
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ mathutils.Vector(c); lo = mathutils.Vector(map(min, lo, w)); hi = mathutils.Vector(map(max, hi, w))
    ctr = (lo + hi) / 2; log(f"bounds {tuple(round(v,2) for v in lo)} {tuple(round(v,2) for v in hi)}")
    d = mathutils.Vector((2.6, -3.4, 2.0)).normalized() * 8
    cam.location = ctr + d
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    for ang, e in (((0.8, 0.2, 0.6), 3.0), ((-0.4, 0.6, -2.4), 1.2)):
        L = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); L.data.energy = e; L.rotation_euler = ang; sc.collection.objects.link(L)
    sc.world = bpy.data.worlds.new("W"); sc.world.color = (0.6, 0.6, 0.6)
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
    sc.render.resolution_x = sc.render.resolution_y = 512
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
    sc.render.filepath = os.path.join(D, "icon.png"); bpy.ops.render.render(write_still=True)
    log("ICON_DONE")
    # carrier quad
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new("CrabIconCarrier")
    me.from_pydata([(-1, 0, -1), (1, 0, -1), (1, 0, 1), (-1, 0, 1)], [], [(0, 1, 2, 3)])
    uv = me.uv_layers.new(name="UVMap")
    for i, lp in enumerate(me.loops): uv.data[i].uv = [(0, 0), (1, 0), (1, 1), (0, 1)][lp.vertex_index]
    ob = bpy.data.objects.new("CrabIconCarrier", me); bpy.context.collection.objects.link(ob)
    m = bpy.data.materials.new("CrabIcon"); m.use_nodes = True; nt = m.node_tree
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(os.path.join(D, "icon.png"))
    nt.links.new(t.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"]); me.materials.append(m)
    ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(D, "icon_carrier.fbx"), use_selection=True, path_mode="COPY", embed_textures=True)
    log("CARRIER_DONE")
except Exception:
    log(traceback.format_exc())
