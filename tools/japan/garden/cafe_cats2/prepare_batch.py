"""Prepare seven-cat packaging from the six validated rigs plus the new seventh rig."""
from pathlib import Path
import json,shutil
D=Path(__file__).resolve().parent;OLD=D.parent/'cafe_cats1';NEW=D.parent/'cafe_cat7'
rows=json.loads((OLD/'rig_manifest.json').read_text())+json.loads((NEW/'rig_manifest.json').read_text())
(D/'rig_manifest.json').write_text(json.dumps(rows,indent=2))
(D/'rig_config.json').write_text(json.dumps(json.loads((OLD/'rig_config.json').read_text())+json.loads((NEW/'rig_config.json').read_text()),indent=2))
(D/'inspection.json').write_text(json.dumps(json.loads((OLD/'inspection.json').read_text())+json.loads((NEW/'inspection.json').read_text()),indent=2))
package=(OLD/'package_cats.py').read_text()
package=package.replace("with bpy.data.libraries.load(str(D/c['name']/'rigged.blend'),link=False)","paths=[D/c['name']/'rigged.blend',D.parent/'cafe_cats1'/c['name']/'rigged.blend',D.parent/'cafe_cat7'/c['name']/'rigged.blend']\n    blend=next(p for p in paths if p.exists())\n    with bpy.data.libraries.load(str(blend),link=False)")
package=package.replace('CC1_','CC2_').replace('cat_cafe_cats1','cat_cafe_cats2').replace('japan_kit24_','japan_kit25_').replace('cat_cafe_cats_rigged','cat_cafe_seven_cats_rigged').replace('cat_cafe_with_cats_review','cat_cafe_seven_cats_review')
package=package.replace('6 skinned cats','7 skinned cats').replace('6 meshes, 60 bones','7 meshes, 70 bones').replace("if o.type=='MESH'])==9","if o.type=='MESH'])==10").replace("if o.type=='ARMATURE'])==6","if o.type=='ARMATURE'])==7")
start=package.index('    # A native Blender lineup')
end=package.index('    # Bring the actual cafe',start)
package=package[:start]+package[end:]
package=package.replace("camshot('cafe_cats_window',P((-5.8,4.7,-8.9)),P((3.2,3.25,-1.8)),lens=28)","camshot('cafe_seventh_kitten',P((4.6,3.35,-2.0)),P((10.65,2.8,-5.5)),lens=48)")
package=package.replace("camshot('cafe_cats_climbing',P((1.4,5.8,-3.6)),P((9.2,4.35,-10.2)),lens=32)","camshot('cafe_seven_cats_corner',P((0.7,4.5,-1.9)),P((9.2,4.0,-9.0)),lens=26)")
(D/'package_cats.py').write_text(package)
build=(OLD/'build_installers.py').read_text().replace("vertices=np.load(D/c['name']/'points.npy')","paths=[D/c['name']/'points.npy',D.parent/'cafe_cats1'/c['name']/'points.npy',D.parent/'cafe_cat7'/c['name']/'points.npy'];vertices=np.load(next(p for p in paths if p.exists()))").replace('6/6','7/7').replace('catcafe_cats1','catcafe_cats2')
(D/'build_installers.py').write_text(build)
for name in ['catcafe_cats1_client.lua','catcafe_cats1_template.lua','prepare_catcafe_cats1.lua']:
    text=(OLD/name).read_text().replace('CC1_','CC2_').replace('catcafe_cats1','catcafe_cats2').replace('cat_cafe_cats1','cat_cafe_cats2').replace('CATCAFE_CATS1','CATCAFE_CATS2').replace('CATCATS1','CATCATS2').replace('kit24','kit25').replace('Kit24','Kit25').replace("'cats1'","'cats2'")
    text=text.replace("'CC2_Blush_Eared_Kitten','CC2_Origin'","'CC2_Blush_Eared_Kitten','CC2_Adorable_Tabby_Kitten','CC2_Origin'")
    text=text.replace('count==9 and bones==60','count==10 and bones==70').replace('count==6 and boneCount==60','count==7 and boneCount==70').replace('6 skinned cats, 60 bones','7 skinned cats, 70 bones').replace('9 anchored meshes, 60 bones','10 anchored meshes, 70 bones').replace('6 anchored skinned cats, 60 bones','7 anchored skinned cats, 70 bones').replace('2 shelves','3 shelves')
    text=text.replace("not previous or previous:GetAttribute('CafeCatsVersion')=='cats2'","not previous or previous:GetAttribute('CafeCatsVersion')=='cats2' or previous:GetAttribute('CafeCatsVersion')=='cats1'")
    (D/name.replace('cats1','cats2')).write_text(text)
print('Prepared the seven-cat batch scripts; no Studio changes')
