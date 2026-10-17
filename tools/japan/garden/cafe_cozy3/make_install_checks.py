from pathlib import Path
import json
D=Path(__file__).resolve().parent
rows=json.loads((D/'preview_manifest.json').read_text())
assert len(rows)==610
for start in range(0,len(rows),100):
    data=json.dumps(rows[start:start+100],separators=(',',':'))
    code='''local expected=game:GetService("HttpService"):JSONDecode([==[DATA]==])
local parts={};local total=0
for _,root in ipairs({workspace.JapanMap.ShopFronts.CatCafe,workspace.JapanMap.ShopFronts.CatCafeInterior})do
 for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then assert(not parts[p:GetFullName()]);parts[p:GetFullName()]=p;total+=1 end end
end
assert(total==610,"Unexpected installed cafe part count")
for _,e in ipairs(expected)do
 local p=assert(parts[e.name],"Missing "..e.name)
 local cf={p.CFrame:GetComponents()};local size={p.Size.X,p.Size.Y,p.Size.Z};local color={p.Color.R,p.Color.G,p.Color.B}
 for i,v in ipairs(e.cf)do assert(math.abs(v-cf[i])<=.0002,"Transform mismatch: "..e.name)end
 for i,v in ipairs(e.size)do assert(math.abs(v-size[i])<=.0002,"Size mismatch: "..e.name)end
 for i,v in ipairs(e.color)do assert(math.abs(v-color[i])<=.00006,"Color mismatch: "..e.name)end
 assert(p.Material.Name==e.material and p.CanCollide==e.collide and p.Anchored,"Material/collision/anchoring mismatch: "..e.name)
 assert(p.MaterialVariant==e.variant and p.Transparency==e.transparency and p.CanTouch==e.touch and p.CanQuery==e.query,"Surface/physical flag mismatch: "..e.name)
 if e.mesh and e.mesh~=""then assert(p:IsA("MeshPart")and p.MeshId==e.mesh,"Mesh mismatch: "..e.name)end
 if e.collision and e.collision~=""then assert(p.CollisionFidelity.Name==e.collision,"Collision fidelity mismatch: "..e.name)end
end
return "QQ CAFECOZY3 INSTALLED MATCH: batch START-END; geometry, colors, materials, collision, anchoring and mesh IDs match approved preview"
'''.replace('DATA',data).replace('START',str(start+1)).replace('END',str(min(start+100,len(rows))))
    (D/f'check_install_{start//100}.lua').write_text(code,encoding='utf-8')
print('Seven bounded checks prepared for all610 installed cafe parts')
