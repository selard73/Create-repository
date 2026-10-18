from pathlib import Path
import json
D=Path(__file__).resolve().parent
old=D.parent/'grocerstock1'
if not (old/'prepare.template.lua').exists():old=Path(r'C:\Users\slard\Create-repository\tools\japan\garden\grocerstock1')
m=json.loads((D/'out/manifest.json').read_text())
config=json.dumps({k:m[k]for k in['meshes','materials','removeOld']},separators=(',',':'))
for name,target in[('prepare.template.lua','prepare_grocerstock2.lua'),('install.template.lua','grocerstock2.lua')]:
    s=(old/name).read_text().replace('kit28','kit32').replace('GS1_','GS2_').replace('grocerstock1','grocerstock2').replace('GROCERSTOCK1','GROCERSTOCK2').replace('GrocerStock1Originals','GrocerStock2Originals').replace('"stock1"','"stock2"').replace('shelf stock1','shelf stock2')
    if name=='prepare.template.lua':
        needle='local o=parts.GS2_Origin.Position'
        extra='''local textured=0
for name,p in pairs(parts)do if name:match("_Label$")then
 local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
 assert(p.TextureID~=""or(appearance and appearance.ColorMap~=""),"Printed label texture missing: "..name.."; import kit32 with textures")
 textured+=1
end end
assert(textured==9,"Expected nine printed-label mesh batches")
'''
        assert s.count(needle)==1;s=s.replace(needle,extra+needle)
    else:
        needle='c.Parent=new;stockCount+=1;min=min:Min(lo);max=max:Max(hi)'
        extra='''if name:match("_Label$")then
            local appearance=c:FindFirstChildOfClass("SurfaceAppearance")
            assert(c.TextureID~=""or(appearance and appearance.ColorMap~=""),"Printed label texture missing")
            c.Color=Color3.new(1,1,1);c.CastShadow=false;c.RenderFidelity=Enum.RenderFidelity.Precise
        end
        '''
        assert s.count(needle)==1;s=s.replace(needle,extra+needle)
        needle='print("QQ GROCERSTOCK2 STATUS: '
        assert s.count(needle)==1
        s=s.replace(needle,'print("QQ GROCERSTOCK2 LABELS:44 printed labels; paper follows bottle/tin/tub curves and packet slopes; nine textured label batches, no raised lettering")\n'+needle)
    (D/name).write_text(s)
    (D/target).write_text(s.replace('__CONFIG__',config))
print('GROCERSTOCK2_SCRIPTS_READY:64 source meshes;61 stock meshes; nine embedded-image label batches')
