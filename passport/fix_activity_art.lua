assert(not game:GetService('RunService'):IsRunning(),'EDIT only')
local function norm(s)return s:gsub('^%s+',''):gsub('%s+$','')end
local target=workspace.Passport.PassportVisuals
assert(norm(target.Source)==norm([====[-- Real game artwork, softly lit. No live scripts, physics or per-frame rendering work.
local V={}
local RS=game:GetService("ReplicatedStorage")
local C=Color3.fromRGB
local art=RS:WaitForChild("PassportArt")
local map={find="detective_squirrel",riddle="squirrel_scientist",rescue="super_squirrel",race="cyclist_squirrel",hoop="super_squirrel",book="spy_squirrel",coffee="coffee",cheese="chevre_squirrel",church="church_mouse",glace="glace",bubbles="florist_squirrel",hat="hat",portrait="painter_squirrel",baguette="baguette",toadstool="toadstool",windmill="windmill",chickens="farmer_fernand",climb="ranger_squirrel",zipline="parachute_squirrel",glider="parachute_squirrel",gold="fairy_squirrel",keeper="tourist_squirrel"}
function V.draw(parent,id,size,record)
 local source=art:FindFirstChild(map[id] or id) or art:FindFirstChild("detective_squirrel")
 if (id=="find" or id=="gold") and record and record.data.name then
  for _,o in ipairs(art:GetChildren())do if o:GetAttribute("CharacterName")==record.data.name then source=o;break end end
 end
 local holder=Instance.new("Frame");holder.Name="GameArtwork";holder.Size=UDim2.fromOffset(size,size);holder.BackgroundTransparency=1;holder.ZIndex=parent.ZIndex+1;holder.Parent=parent
 local vp=Instance.new("ViewportFrame");vp.Name="OriginalGameArt";vp.Size=UDim2.fromScale(1,1);vp.BackgroundTransparency=1;vp.Ambient=C(200,203,218);vp.LightColor=C(255,246,221);vp.LightDirection=Vector3.new(-.4,-1,-.6);vp.ZIndex=holder.ZIndex;vp.Parent=holder
 local copy=source:Clone();local world=Instance.new("WorldModel");world.Parent=vp;copy.Parent=world
 if id=="coffee" then
  -- A directional key light and warm shadow preserve the cup's curved shape.
  vp.Ambient=C(104,95,78);vp.LightColor=C(255,239,211);vp.LightDirection=Vector3.new(-.7,-.8,-.4)
  local cup=copy:FindFirstChild("Cup",true);local brew=copy:FindFirstChild("Brew",true);local saucer=copy:FindFirstChild("Saucer",true)
  if cup then cup.Color=C(241,229,202);cup.Material=Enum.Material.SmoothPlastic;cup.Reflectance=.08 end
  if saucer then saucer.Color=C(212,187,145);saucer.Material=Enum.Material.SmoothPlastic end
  if cup and brew then
   -- In the world model the dark surface sits inside the solid cylinder. Lift it only in this UI copy.
   brew.Position=Vector3.new(cup.Position.X,cup.Position.Y+cup.Size.X/2+.012,cup.Position.Z);brew.Color=C(75,39,20)
  end
 end
 local cam=Instance.new("Camera");cam.FieldOfView=30;cam.Parent=vp;vp.CurrentCamera=cam
 local cf,sz=copy:GetBoundingBox();local centre=cf.Position
 if source:GetAttribute("Portrait") then
  local mesh=copy:FindFirstChildWhichIsA("MeshPart",true);local h=mesh.Size.Y;local fwd=source:GetAttribute("Front");local left=Vector3.yAxis:Cross(fwd)
  centre=mesh.Position+Vector3.new(0,(.15+(source:GetAttribute("up") or 0))*h,0)+fwd*(.3*h)
  local head=mesh:FindFirstChild("Head",true);if head then centre+=left*(head.WorldPosition-centre):Dot(left)end
  centre+=left*((source:GetAttribute("side") or 0)*h)
  cam.FieldOfView=24;cam.CFrame=CFrame.lookAt(centre+fwd*((source:GetAttribute("dist") or 1.35)*1.18*h)+Vector3.new(0,(source:GetAttribute("camUp") or .05)*h,0),centre)
 else
  local radius=sz.Magnitude*.52;local dist=radius/math.sin(math.rad(cam.FieldOfView/2))*1.02
  cam.CFrame=CFrame.lookAt(centre+(id=="coffee" and Vector3.new(.35,.85,1) or Vector3.new(.65,.35,1)).Unit*dist,centre)
 end
 return holder
end
return V
]====]),"PassportVisuals changed")
local source=[====[-- Real game artwork, softly lit. No live scripts, physics or per-frame rendering work.
local V={}
local RS=game:GetService("ReplicatedStorage")
local C=Color3.fromRGB
local art=RS:WaitForChild("PassportArt")
local map={find="detective_squirrel",riddle="squirrel_scientist",rescue="super_squirrel",race="cyclist_squirrel",hoop="hoop",book="book",coffee="coffee",cheese="chevre_squirrel",church="church_mouse",glace="glace",bubbles="florist_squirrel",hat="hat",portrait="painter_squirrel",baguette="baguette",toadstool="toadstool",windmill="windmill",chickens="farmer_fernand",climb="ranger_squirrel",zipline="zipline",glider="glider",gold="fairy_squirrel",keeper="tourist_squirrel"}
V.artwork=table.freeze(map)
function V.draw(parent,id,size,record)
 -- Activity artwork stays distinct even when a found squirrel is also pictured elsewhere.
 -- The personal completion text still names the actual squirrel found.
 local key=assert(map[id],"Unknown passport activity: "..tostring(id))
 local source=assert(art:FindFirstChild(key),"Missing passport artwork: "..id)
 local holder=Instance.new("Frame");holder.Name="GameArtwork";holder.Size=UDim2.fromOffset(size,size);holder.BackgroundTransparency=1;holder.ZIndex=parent.ZIndex+1;holder.Parent=parent
 local vp=Instance.new("ViewportFrame");vp.Name="OriginalGameArt";vp.Size=UDim2.fromScale(1,1);vp.BackgroundTransparency=1;vp.Ambient=C(200,203,218);vp.LightColor=C(255,246,221);vp.LightDirection=Vector3.new(-.4,-1,-.6);vp.ZIndex=holder.ZIndex;vp.Parent=holder
 local copy=source:Clone();local world=Instance.new("WorldModel");world.Parent=vp;copy.Parent=world
 if id=="baguette" then
  -- The world prize is hidden between rounds; its Passport preview is always visible.
  for _,part in ipairs(copy:GetDescendants())do if part:IsA("BasePart")then part.Transparency=0 end end
 end
 if id=="coffee" then
  -- A directional key light and warm shadow preserve the cup's curved shape.
  vp.Ambient=C(104,95,78);vp.LightColor=C(255,239,211);vp.LightDirection=Vector3.new(-.7,-.8,-.4)
  local cup=copy:FindFirstChild("Cup",true);local brew=copy:FindFirstChild("Brew",true);local saucer=copy:FindFirstChild("Saucer",true)
  if cup then cup.Color=C(241,229,202);cup.Material=Enum.Material.SmoothPlastic;cup.Reflectance=.08 end
  if saucer then saucer.Color=C(212,187,145);saucer.Material=Enum.Material.SmoothPlastic end
  if cup and brew then
   -- In the world model the dark surface sits inside the solid cylinder. Lift it only in this UI copy.
   brew.Position=Vector3.new(cup.Position.X,cup.Position.Y+cup.Size.X/2+.012,cup.Position.Z);brew.Color=C(75,39,20)
  end
 end
 local cam=Instance.new("Camera");cam.FieldOfView=30;cam.Parent=vp;vp.CurrentCamera=cam
 local cf,sz=copy:GetBoundingBox();local centre=cf.Position
 if source:GetAttribute("Portrait") then
  local mesh=copy:FindFirstChildWhichIsA("MeshPart",true);local h=mesh.Size.Y;local fwd=source:GetAttribute("Front");local left=Vector3.yAxis:Cross(fwd)
  centre=mesh.Position+Vector3.new(0,(.15+(source:GetAttribute("up") or 0))*h,0)+fwd*(.3*h)
  local head=mesh:FindFirstChild("Head",true);if head then centre+=left*(head.WorldPosition-centre):Dot(left)end
  centre+=left*((source:GetAttribute("side") or 0)*h)
  cam.FieldOfView=24;cam.CFrame=CFrame.lookAt(centre+fwd*((source:GetAttribute("dist") or 1.35)*1.18*h)+Vector3.new(0,(source:GetAttribute("camUp") or .05)*h,0),centre)
 else
  local radius=sz.Magnitude*.52;local dist=radius/math.sin(math.rad(cam.FieldOfView/2))*1.02
  cam.CFrame=CFrame.lookAt(centre+(source:GetAttribute("ViewDirection") or (id=="coffee" and Vector3.new(.35,.85,1) or Vector3.new(.65,.35,1))).Unit*dist,centre)
 end
 return holder
end
return V
]====]
assert(loadstring(source))
local RS=game:GetService('ReplicatedStorage')
local oldArt=RS.PassportArt
local art=oldArt:Clone()
 local function preview(id,source,face)
  if not source then return end
  local model=Instance.new("Model");model.Name=id
  local copy=source:Clone();copy.Parent=model
  for _,d in ipairs(model:GetDescendants()) do
   for _,tag in ipairs(game:GetService("CollectionService"):GetTags(d))do game:GetService("CollectionService"):RemoveTag(d,tag)end
   if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Constraint") or d:IsA("JointInstance") or d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("Highlight") then d:Destroy()
   elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false end
  end
  if not model:FindFirstChildWhichIsA("BasePart",true) then model:Destroy();return end
  if source:IsA("MeshPart") and face then
   local head=copy:FindFirstChild("Head",true);local root=copy:FindFirstChild("Root",true)
   local fwd=source.CFrame.LookVector
   if head and root then local f=head.WorldPosition-root.WorldPosition;f=Vector3.new(f.X,0,f.Z);if f.Magnitude>.05 then fwd=f.Unit end end
   model:SetAttribute("Front",fwd);model:SetAttribute("Portrait",true)
   for k,v in pairs(face)do model:SetAttribute(k,v)end
   local colour=source:GetAttribute("ColorTexture")
   if colour then local sa=copy:FindFirstChildOfClass("SurfaceAppearance");if sa then sa.ColorMap=colour else copy.TextureID=colour end end
  end
  model.Parent=art
 end
 -- Activity-specific props: keep the superhero exclusively on Swamp rescue.
 local hoop=Instance.new('Model');hoop.Name='PassportHoopSource'
 local keep={Board=true,BoardTrim=true,Bracket=true,Ring=true,String=true,NetRing=true}
 for _,p in ipairs(workspace.Hoop:GetChildren())do if p:IsA('BasePart') and keep[p.Name]then p:Clone().Parent=hoop end end
 assert(hoop:FindFirstChild('Board') and hoop:FindFirstChild('Ring'),'Hoop artwork missing')
 preview('hoop',hoop)
 art.hoop:SetAttribute('ViewDirection',workspace.Hoop.Board.CFrame.LookVector+Vector3.new(.12,.48,0))
 hoop:Destroy()
 preview('glider',assert(workspace.HangGlider:FindFirstChild('Display'),'Glider display missing'))
 local sail=workspace.HangGlider.Display:FindFirstChild('GliderSail')
 if sail then art.glider:SetAttribute('ViewDirection',sail.CFrame:VectorToWorldSpace(Vector3.new(.3,.9,1)))end
 -- Same steel trolley, orange cap and rubber grips as the ride's ZipHandle.
 local zip=Instance.new('Model');zip.Name='PassportZipHandleSource'
 local C=Color3.fromRGB;local steel,rubber,orange=C(150,150,156),C(38,36,40),C(226,120,40)
 local function zp(name,size,pos,col,shape)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos;p.Color=col;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true
  if shape then p.Shape=shape end;p.Parent=zip;return p
 end
 for _,side in ipairs({-1,1})do zp('Cheek',Vector3.new(.14,.95,1.7),Vector3.new(side*.32,1.3,0),steel)end
 zp('Cap',Vector3.new(.78,.14,1.7),Vector3.new(0,1.86,0),orange)
 for _,z in ipairs({-.5,.5})do zp('Wheel',Vector3.new(.5,.62,.62),Vector3.new(0,1.45,z),rubber,Enum.PartType.Cylinder)end
 zp('Stem',Vector3.new(.16,1.15,.16),Vector3.new(0,.35,0),steel)
 zp('Bar',Vector3.new(2,.16,.16),Vector3.new(0,-.3,0),steel)
 for _,side in ipairs({-1,1})do
  zp('Strap',Vector3.new(.12,.66,.12),Vector3.new(side*.85,-.6,0),steel)
  zp('Grip',Vector3.new(.7,.3,.3),Vector3.new(side*.85,-.93,0),rubber,Enum.PartType.Cylinder)
 end
 preview('zipline',zip);zip:Destroy()

local mapping={}
for activity,key in source:match('local map=(%b{})'):gmatch('(%w+)="([%w_]+)"')do
 assert(not mapping[key],"Duplicate activity illustration: "..key)
 assert(art:FindFirstChild(key),"Missing art: "..key);mapping[key]=activity
end
local n=0;for _ in pairs(mapping)do n+=1 end;assert(n==22,'All 22 activities must have unique art')
for _,o in ipairs(art:GetDescendants())do assert(not o:IsA('LuaSourceContainer') and not o:IsA('ProximityPrompt') and not o:IsA('ClickDetector'),'Inert previews only')end
local checkSource=source:gsub('local art=RS:WaitForChild%("PassportArt"%)','local art=...')
local V=assert(loadstring(checkSource))(art)
local holder=Instance.new('Frame')
for id in pairs(V.artwork)do local card=V.draw(holder,id,60,{data={name='Nacho Libre Squirrel'}});assert(card:FindFirstChild('OriginalGameArt'));card:Destroy()end
holder:Destroy();oldArt.Parent=nil;art.Parent=RS;target.Source=source;oldArt:Destroy()
warn('QQ PASSPORT ART PASS: 22 unique activity illustrations; superhero exclusive to rescue; all previews render with completion records')
