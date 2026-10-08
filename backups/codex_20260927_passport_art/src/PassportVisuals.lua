-- Real game artwork, softly lit. No live scripts, physics or per-frame rendering work.
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
