from pathlib import Path
import json
d=Path(__file__).resolve().parent
repo=Path(r'C:\Users\slard\Create-repository')
manifest=json.loads((d/'out/manifest.json').read_text())
camera=(repo/'tools/japan/garden/catcafe1_camera_client.lua').read_text(encoding='utf-8')
for a,b in [('Vector3.new(-12.45,.12,-19.32)','Vector3.new(-16.80,.12,-27.80)'),('Vector3.new(12.45,8.0,-.15)','Vector3.new(16.80,11.05,-.15)'),('math.abs(p.X)>12.9 or p.Y< -.5 or p.Y>8.5 or p.Z< -19.9 or p.Z>0','math.abs(p.X)>17.3 or p.Y< -.5 or p.Y>12.0 or p.Z< -28.3 or p.Z>1.5')]:
 assert camera.count(a)==1,a
 camera=camera.replace(a,b)
(d/'camera_client.lua').write_text(camera,encoding='utf-8')
code=(d/'install.template.lua').read_text().replace('__DATA__',json.dumps(manifest,separators=(',',':'))).replace('__CAMERA__',camera).replace('__SERVER__',(d/'door_server.lua').read_text()).replace('__CLIENT__',(d/'door_client.lua').read_text())
(d/'cafe_interior2.lua').write_text(code,encoding='utf-8')
prep=(d.parent/'grocerstock1/prepare.template.lua').read_text()
for a,b in [('kit28','kit29'),('grocerstock1','cafe_interior2'),('GS1_','CI2_'),('GrocerStockVersion','CafeInteriorSourceVersion'),('"stock1"','"interior2"'),('GROCERSTOCK1','CAFEINTERIOR2')]:prep=prep.replace(a,b)
prep=prep.replace('__CONFIG__',json.dumps(manifest,separators=(',',':')))
(d/'prepare_cafe_interior2.lua').write_text(prep,encoding='utf-8')
print('CAFEINTERIOR2_SCRIPTS_READY: guarded installer, source preparation, transition and camera sources')
