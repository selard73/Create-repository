from pathlib import Path
import json
d=Path(__file__).resolve().parent
m=json.loads((d/'out/manifest.json').read_text())
config=json.dumps({k:m[k] for k in ['meshes','materials','removeOld']},separators=(',',':'))
for template,dest in [('prepare.template.lua','prepare_grocerstock1.lua'),('install.template.lua','grocerstock1.lua')]:
    (d/dest).write_text((d/template).read_text().replace('__CONFIG__',config),encoding='utf-8')
print('GROCERSTOCK1_SCRIPTS_READY: exact manifest embedded in preparation and installer')
