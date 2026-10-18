"""Generate guarded source preparation and preview operations for kit36."""
from pathlib import Path
import json
D=Path(__file__).resolve().parent
base=Path(r'C:\Users\slard\Create-repository\tools\japan\garden\bookshop1')
src=(base/'build_installers.py').read_text(encoding='utf8')
# Reuse the proven source/marker/bounds validation, not any bookshop scene mutation.
common=src.split("common=r'''",1)[1].split("'''",1)[0].replace('B1_','C2_')
prepare=src.split("prepare=r'''",1)[1].split("'''+data+common+r'''",1)
prefix=prepare[0].replace('kit35','kit36')
body=prepare[1].split("'''",1)[0].replace('B1_','C2_').replace('bookshop1','craftshop2').replace('BookshopKitVersion','CraftshopKitVersion').replace('kit35','kit36').replace('BOOKSHOP1','CRAFTSHOP2')
C=json.loads((D/'out/manifest.json').read_text(encoding='utf8'))
C.update(retiredRoots=131,retiredParts=136,retiredLabels=14)
data='local CONFIG=game:GetService("HttpService"):JSONDecode([==['+json.dumps(C,separators=(',',':'))+']==])\n'
(D/'prepare_craftshop2.lua').write_text(prefix+data+common+body,encoding='utf8')
install=(D/'install_body.txt').read_text(encoding='utf8').replace('--CONFIG--',data).replace('--COMMON--',common)
(D/'install_craftshop2.lua').write_text(install,encoding='utf8')
print('Prepared guarded installers for',len(C['meshes']),'source meshes')
