"""Build the boutique from its maintained sources; never regenerate from the hat shop.

Run after editing Catalogue.lua, DressServer.lua, DressClient.lua, displays.lua
or shop_template.lua. Does not contact Roblox or publish the place.
"""
from pathlib import Path
import json

P=Path(__file__).parent
data=json.loads((P/'dress_kit.json').read_text(encoding='utf8'))
def vec(v): return 'Vector3.new('+','.join(f'{x:.6f}' for x in v)+')'
cat=(P/'Catalogue.lua').read_text(encoding='utf8')
for placeholder,field in [('__CENTRES__','centre'),('__SIZES__','size')]:
    assert cat.count(placeholder)==1
    cat=cat.replace(placeholder,'{'+','.join(f'["{k}"]={vec(v[field])}' for k,v in data.items())+'}')
(P/'DressCatalogue.lua').write_text(cat,encoding='utf8')
builder=(P/'shop_template.lua').read_text(encoding='utf8')
for tag,source in [('CAT',cat),('SERVER',(P/'DressServer.lua').read_text(encoding='utf8')),('CLIENT',(P/'DressClient.lua').read_text(encoding='utf8')),('DISPLAYS',(P/'displays.lua').read_text(encoding='utf8')),('WARDROBE',(P/'WardrobeClient.lua').read_text(encoding='utf8'))]:
    assert builder.count('__'+tag+'__')==1
    builder=builder.replace('__'+tag+'__',source)
(P/'build_dressshop.lua').write_text(builder,encoding='utf8')
runner='assert(not game:GetService("RunService"):IsRunning(),"EDIT only")\nlocal build=(function()\n'+builder+'\nend)()\nlocal result=build({})\nwarn("QQ BOUTIQUE INSTALLED: four clothing designs plus accessories; review before publishing")\n'
(P/'run_install.lua').write_text(runner,encoding='utf8')
print('Built boutique: four launch clothing designs, accessories, and preserved future designs.')
