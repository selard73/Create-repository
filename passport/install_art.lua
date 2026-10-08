-- Preserve the game's actual meshes and textures in small, inert UI previews.
do
 local RS=game:GetService("ReplicatedStorage")
 local old=RS:FindFirstChild("PassportArt")
 local art=Instance.new("Folder");art.Name="PassportArt"
 local registry=require(workspace.SquirrelScripts.SquirrelRegistry)
 local lookup={};for _,e in ipairs(registry.squirrels) do lookup[e.id]=e end
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
 for id,e in pairs(lookup)do
  local source=workspace:FindFirstChild(id.."_color",true) or workspace:FindFirstChild(id.."_gray",true)
  local mesh=source and source:FindFirstChildWhichIsA("MeshPart",true)
  if mesh then preview(id,mesh,e.face or {});art[id]:SetAttribute("CharacterName",e.name)end
 end
 preview("coffee",workspace.Speed:FindFirstChild("CoffeeCup",true))
 preview("hat",workspace.HatShop:FindFirstChild("Show_cloche_1",true))
 preview("glace",workspace.Glaces:FindFirstChild("Cart"))
 preview("book",workspace.Bookshop:FindFirstChild("Shelf",true))
 preview("baguette",workspace.Baguette:FindFirstChild("ChaseBaguette",true))
 preview("windmill",workspace.Domaine.Props:FindFirstChild("windmill"))
 preview("church",workspace.Chapel:FindFirstChild("BellRope",true))
 preview("portrait",workspace.PortraitGallery:FindFirstChild("Easel",true))
 for _,m in ipairs(workspace.Trampolines:GetChildren())do if m:IsA("Model")then preview("toadstool",m);break end end
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

 assert(art:FindFirstChild("detective_squirrel"),"Squirrel portrait art missing")
 if old then old:Destroy() end
 art.Parent=RS
 warn("QQ P2 ART: "..#art:GetChildren().." inert previews from the game's original artwork")
end
