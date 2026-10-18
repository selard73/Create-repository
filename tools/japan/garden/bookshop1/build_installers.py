"""Generate guarded preparation and Play-preview installers from the verified mesh manifest."""
from pathlib import Path
import json
D=Path(__file__).resolve().parent
C=json.loads((D/'out/manifest.json').read_text())
C['retiredRoots']=65
C['retiredParts']=70
data='local CONFIG=game:GetService("HttpService"):JSONDecode([==['+json.dumps(C,separators=(',',':'))+']==])\n'
common=r'''
local function key(n)return(n:gsub("%.%d+$",""))end
local expected={};for _,r in ipairs(CONFIG.meshes)do expected[r.name]=r end
local function collect(model)
 local parts={};local count=0
 for _,p in ipairs(model:GetDescendants())do
  assert(not p:IsA("LuaSourceContainer"),"Unexpected script in kit")
  if p:IsA("BasePart")then
   if p:IsA("MeshPart")then local n=key(p.Name);assert(expected[n]and not parts[n],"Unexpected/duplicate mesh: "..n);assert(p.MeshId~="","Missing mesh asset");parts[n]=p;count+=1
   else assert(p.Name=="RootPart"and p.Transparency==1,"Unexpected visible non-mesh")end
  end
 end
 for n in pairs(expected)do assert(parts[n],"Missing mesh: "..n)end
 local o=parts.B1_Origin.Position;local r=parts.B1_Right.Position-o;local f=parts.B1_Front.Position-o
 assert(math.abs(r.Magnitude-2)<.03 and math.abs(f.Magnitude-2)<.03 and math.abs(r.Unit:Dot(f.Unit))<.001,"Import scale/orientation differs")
 local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
 for n,p in pairs(parts)do
  local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
  for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
   local q=frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)));lo=lo:Min(q);hi=hi:Max(q)
  end end end
  local m=expected[n];assert((lo-Vector3.new(table.unpack(m.min))).Magnitude<.08 and(hi-Vector3.new(table.unpack(m.max))).Magnitude<.08,"Bounds differ: "..n)
 end
 return parts,frame,count
end
'''
prepare=r'''-- Run only after Shannon imports kit35 and asks to anchor/prepare it.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning()and game.PlaceId==117372258657114,"Prepare in stopped correct Studio before Play")
'''+data+common+r'''
local kit=assert(game.ServerStorage:FindFirstChild("JapanGardenKit"))
assert(not kit:FindFirstChild("bookshop1")and not kit:FindFirstChild("bookshop1_raw"),"Source already stored; inspect instead")
local candidates={}
for _,v in ipairs(workspace:GetChildren())do if v:IsA("Model")and v.Name~="JapanMap"then
 for _,p in ipairs(v:GetDescendants())do if p:IsA("MeshPart")and key(p.Name)=="B1_Origin"then table.insert(candidates,v);break end end
end end
assert(#candidates>=1 and #candidates<=2,"Expected one kit35 or two identical imports")
local raw=candidates[1];local parts,frame,count=collect(raw)
for i=2,#candidates do
 local dp,df,dc=collect(candidates[i]);assert(dc==count,"Duplicate import differs")
 for n,p in pairs(parts)do
  local q=dp[n];assert(q.MeshId==p.MeshId and(q.Size-p.Size).Magnitude<.001,"Duplicate asset differs: "..n)
  local a=frame:ToObjectSpace(p.CFrame);local b=df:ToObjectSpace(q.CFrame)
  assert((a.Position-b.Position).Magnitude<.001 and a.RightVector:Dot(b.RightVector)>.99999 and a.UpVector:Dot(b.UpVector)>.99999,"Duplicate transform differs")
 end
 assert(not kit:FindFirstChild("bookshop1_raw_duplicate"..i),"Duplicate backup already exists")
end
local source=Instance.new("Model");source.Name="bookshop1"
for n,p in pairs(parts)do
 local q=p:Clone();q.Name=n
 for _,v in ipairs(q:GetDescendants())do if v:IsA("JointInstance")or v:IsA("WeldConstraint")then v:Destroy()end end
 q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.Parent=source
end
source.WorldPivot=frame;source:SetAttribute("BookshopKitVersion","bookshop1")
for _,v in ipairs(candidates)do for _,p in ipairs(v:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true;p.CanTouch=false end end end
raw:SetAttribute("OriginalImportName",raw.Name);raw.Name="bookshop1_raw";raw.Parent=kit;source.Parent=kit
for i=2,#candidates do local v=candidates[i];v:SetAttribute("OriginalImportName",v.Name);v.Name="bookshop1_raw_duplicate"..i;v.Parent=kit end
print("QQ BOOKSHOP1 PREPARED: "..count.." real mesh sources anchored and stored; "..#candidates.." identical raw imports retained; JapanMap unchanged")
'''
install=(D/'install_body.txt').read_text(encoding='utf8').replace('--CONFIG--',data).replace('--COMMON--',common)
(D/'prepare_bookshop1.lua').write_text(prepare,encoding='utf8')
(D/'install_bookshop1.lua').write_text(install,encoding='utf8')
print('Prepared guarded bookshop source/preview installers for',len(C['meshes']),'meshes')
