-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
if not game:GetService("RunService"):IsStudio()then pcall(function() store = DSS:GetDataStore("PortraitWall") end)end
local portraitModels=RS:FindFirstChild("PortraitGalleryModels") or Instance.new("Folder");portraitModels.Name="PortraitGalleryModels";portraitModels.Parent=RS
-- Per-painting crops: keep this requested close-up on the existing sitting only.
local portraitCrops={["9611145467:1790618485"]="waist"}
local list = {}                                              -- {id=, name=, t=, look=}, newest first
local dressKit = RS:FindFirstChild("DressKit")
local dressModule = dressKit and dressKit:FindFirstChild("Catalogue")
local okCat, Cat = false, nil
if dressModule then okCat, Cat = pcall(require, dressModule) end
if not okCat then Cat = nil end
local hatKit=RS:FindFirstChild("HatKit")
local HatCat=hatKit and require(hatKit:WaitForChild("Catalogue"))
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function wornLook(player)
 local look,ids={},{}
 if Cat then for _,id in ipairs(Cat.order)do
  if item(player,"dress_"..id)>0 and item(player,"dresswear_"..id)>0 then ids[#ids+1]=id end
 end end
 if #ids>0 then look.boutique=table.concat(ids,",")end
 if HatCat then for name,value in pairs(player:GetAttributes())do
  local id=name:match("^Item_hatwear_(.+)$")
  if id and (tonumber(value)or 0)>0 and item(player,"hat_"..id)>0 and HatCat.byId[id]then look.hat=id;break end
 end end
 return next(look)and look or nil
end
-- A sitting stores appearance data, never the live character's pose or seat.
local appearanceNumbers={"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Face","Shirt","Pants","GraphicTShirt","HeadScale","HeightScale","WidthScale","DepthScale","BodyTypeScale","ProportionScale","MoodAnimation","StaticFacialAnimation"}
local appearanceColors={"HeadColor","TorsoColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor"}
local function saveDescription(desc)
 local data={version=1,properties={},colors={},accessories={}}
 for _,key in ipairs(appearanceNumbers)do
  local ok,value=pcall(function()return desc[key]end)
  if ok and type(value)=="number"then data.properties[key]=value end
 end
 for _,key in ipairs(appearanceColors)do local c=desc[key];data.colors[key]={c.R,c.G,c.B}end
 for _,accessory in ipairs(desc:GetAccessories(true))do
  local copy={}
  for key,value in pairs(accessory)do
   if typeof(value)=="EnumItem"then copy[key]={enum=value.Name}
   elseif typeof(value)=="Vector3"then copy[key]={vector={value.X,value.Y,value.Z}}
   else assert(type(value)=="number"or type(value)=="boolean"or type(value)=="string","Unsupported accessory appearance");copy[key]=value end
  end
  data.accessories[#data.accessories+1]=copy
 end
 return data
end
local function restoreDescription(data)
 assert(type(data)=="table"and data.version==1,"Unsupported portrait appearance")
 local desc=Instance.new("HumanoidDescription")
 for _,key in ipairs(appearanceNumbers)do if data.properties[key]~=nil then desc[key]=data.properties[key]end end
 for _,key in ipairs(appearanceColors)do local c=assert(data.colors[key]);desc[key]=Color3.new(c[1],c[2],c[3])end
 local accessories={}
 for _,entry in ipairs(data.accessories)do
  local copy={}
  for key,value in pairs(entry)do
   if type(value)=="table"and value.enum then copy[key]=assert(Enum.AccessoryType[value.enum])
   elseif type(value)=="table"and value.vector then copy[key]=Vector3.new(table.unpack(value.vector))
   else copy[key]=value end
  end
  accessories[#accessories+1]=copy
 end
 desc:SetAccessories(accessories,true)
 return desc
end
local function validateBody(model,desc,rig)
 local names=rig==Enum.HumanoidRigType.R6 and {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}or
  {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
 for _,name in ipairs(names)do local p=model:FindFirstChild(name);assert(p and p:IsA("BasePart"),"Portrait is missing "..name)end
 local accessories=0
 for _,a in ipairs(model:GetChildren())do if a:IsA("Accessory")then
  assert(a:FindFirstChild("Handle"),"Portrait accessory did not load");accessories+=1
 end end
 assert(accessories>=#desc:GetAccessories(true),"Portrait accessories did not finish loading")
end

local function applyLook(model, look)
	if type(look) ~= "table" or type(look.boutique) ~= "string" then return end
	assert(Cat and dressKit,"Portrait wardrobe is unavailable")
	for id in look.boutique:gmatch("[^,]+") do
		assert(Cat.byId and Cat.byId[id],"Portrait clothing is unavailable: "..id)
		do
			local slot = Cat.slot(id)
			local worn = Cat.attach(dressKit, id, model, Cat.models[slot])
			assert(worn,"Portrait clothing did not fit: "..id)
			do
				if type(Cat.clothing) == "function" then
					for _, entry in ipairs(Cat.clothing(model, id)) do entry[1][entry[2]] = "" end
				end
				if type(Cat.covered) == "function" then
					for _, part in ipairs(Cat.covered(model, id)) do part.Transparency = 1 end
				end
			end
		end
	end
end
local function applyHat(model,look)
 local id=type(look)=="table"and look.hat
 if not id then return end
 assert(HatCat and HatCat.byId[id],"Portrait hat is unavailable")
 local head=assert(model:FindFirstChild("Head"))
 local fit,scale=HatCat.fit(head,HatCat.byId[id].style.id)
 local hair,why=HatCat.clippedHair(head,HatCat.byId[id].style.id,fit)
 assert(hair,why)
 local pieces=assert(HatCat.pieces(hatKit,id,head.CFrame*fit,scale))
 for _,a in ipairs(model:GetChildren())do if a:IsA("Accessory")then
  local h=a:FindFirstChild("Handle")
  if HatCat.isHairAccessory(a)or a.AccessoryType==Enum.AccessoryType.Hat or (h and h:FindFirstChild("HatAttachment",true))then
   for _,p in ipairs(a:GetDescendants())do if p:IsA("BasePart")then p.Transparency=1 end end
  end
 end end
 local hat=Instance.new("Model");hat.Name="WornHat";hat:SetAttribute("HatId",id)
 for _,p in ipairs(pieces)do p.Parent=hat end
 for _,p in ipairs(hair)do p.Parent=hat end
 hat.Parent=model
end
local function assemblePortrait(model)
 local root=model:FindFirstChild("HumanoidRootPart")
 if not root then return end
 root.CFrame=CFrame.new()
 local placed={[root]=true}
 local joints={}
 for _,d in ipairs(model:GetDescendants())do if d:IsA("JointInstance") or d:IsA("AnimationConstraint")then joints[#joints+1]=d end end
 -- Newly generated heads/accessories may still carry their asset positions.
 -- Resolve the rig from its root before freezing it outside the physics world.
 for _=1,#joints do
  local progress=false
  for _,j in ipairs(joints)do
   local a,b,c0,c1,transform
   if j:IsA("AnimationConstraint")then
    local a0,a1=j.Attachment0,j.Attachment1
    if a0 and a1 then a,b,c0,c1=a0.Parent,a1.Parent,a0.CFrame,a1.CFrame end
    transform=CFrame.new()
   else a,b,c0,c1=j.Part0,j.Part1,j.C0,j.C1;transform=CFrame.new() end
   if a and b then
    if placed[a] and not placed[b] then b.CFrame=a.CFrame*c0*transform*c1:Inverse();placed[b]=true;progress=true
    elseif placed[b] and not placed[a] then a.CFrame=b.CFrame*c1*transform:Inverse()*c0:Inverse();placed[a]=true;progress=true end
   end
  end
  if not progress then break end
 end
end
local building,pendingPortraits={},{}
local function portraitKey(e)return "Painting_"..tostring(e.id).."_"..tostring(e.receipt or e.t or 0)end
local function prepareModel(e,description)
 local key=portraitKey(e)
 while building[key]do task.wait(.1)end
 local existing=portraitModels:FindFirstChild(key)
 if existing then return existing end
 building[key]=true
 local result,lastError
 for attempt=1,3 do
  local model
  local ok,err=xpcall(function()
   local desc=description or(e.appearance and restoreDescription(e.appearance))or Players:GetHumanoidDescriptionFromUserIdAsync(tonumber(e.id)or 0)
   local rig=e.rig=="R6"and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
   model=Players:CreateHumanoidModelFromDescriptionAsync(desc,rig)
   validateBody(model,desc,rig)
   model.Name=key;assemblePortrait(model)
   local hum=assert(model:FindFirstChildOfClass("Humanoid"));hum.Sit=false
   hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
   hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
   applyLook(model,e.look);applyHat(model,e.look)
   if Cat and type(e.look)=="table"and type(e.look.boutique)=="string"then
    for id in e.look.boutique:gmatch("[^,]+")do if Cat.byId[id]and Cat.skin then
     for _,entry in ipairs(Cat.skin(model,id))do entry[1].Color=entry[2]end
    end end
   end
   model:SetAttribute("PortraitCrop",portraitCrops[tostring(e.id)..":"..tostring(e.t)])
   model:SetAttribute("PortraitKey",key)
   for _,d in ipairs(model:GetDescendants())do
    if d:IsA("BaseScript")or d:IsA("Animator")or d:IsA("Tool")then d:Destroy()
    elseif d:IsA("BasePart")then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.LocalTransparencyModifier=0 end
   end
   local count=0
   for _,d in ipairs(model:GetDescendants())do if d:IsA("BasePart")then count+=1 end end
   assert(model:FindFirstChild("Head")and model:FindFirstChild("HumanoidRootPart")and count>=7,"Incomplete portrait avatar")
   model:SetAttribute("PortraitPartCount",count)
   local visualCount=0
   for _,d in ipairs(model:GetDescendants())do
    if d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("Decal")or d:IsA("SurfaceAppearance")then visualCount+=1 end
   end
   model:SetAttribute("PortraitVisualCount",visualCount)
   model.Parent=portraitModels
   result=model
  end,debug.traceback)
  if ok then break end
  lastError=err;if model then model:Destroy()end
  if attempt<3 then task.wait(attempt)end
 end
 building[key]=nil
 if not result then error("Could not prepare portrait: "..tostring(lastError))end
 return result
end
local function retireUnusedModels()
 task.delay(60,function()
  local wanted={};for _,e in ipairs(list)do wanted[portraitKey(e)]=true end
  for _,m in ipairs(portraitModels:GetChildren())do
   if not wanted[m.Name]and not building[m.Name]and not pendingPortraits[m.Name]then m:Destroy()end
  end
 end)
end
local function renderPortrait(vp,e)
 if not vp then return end
 local token=(tonumber(vp:GetAttribute("RenderToken"))or 0)+1
 vp:SetAttribute("RenderToken",token)
 if not e then vp:SetAttribute("GalleryModelKey",nil);vp.Visible=false;return end
 task.spawn(function()
  local ok,model=pcall(prepareModel,e)
  if vp:GetAttribute("RenderToken")~=token then return end
  if not ok then warn("PortraitServer: "..tostring(model));return end
  vp:SetAttribute("GalleryModelKey",model.Name);vp.Visible=true
 end)
end

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local vp = gui:FindFirstChild("Portrait3D")
			-- Each sitting has an immutable model key; moving slots never changes its appearance.
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			if vp then vp.Size = img.Size; vp.Position = img.Position end
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = ""; img.Visible = true; wash.Visible = true; renderPortrait(vp, e)
			else
				img.Image = ""; img.Visible = false; wash.Visible = false; renderPortrait(vp, nil)
			end
		end
		if plaque then
			local sg = plaque:FindFirstChildWhichIsA("SurfaceGui")
			local t = sg and sg:FindFirstChild("Name")
			if t then t.Text = e and tostring(e.name) or "" end
		end
	end
end

local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end

local listLoaded = false
local function load()
	if not store then listLoaded = true return end
	local attempt=0
	while true do
		attempt+=1
		local ok,saved=pcall(function()return store:GetAsync("latest")end)
		if ok then
			if type(saved)=="table"then list=merge(saved,nil);show()end
			listLoaded=true;return
		end
		warn("PortraitServer: gallery load failed; retrying: "..tostring(saved))
		task.wait(math.min(attempt*5,60))
	end
end

local function newEntry(player)
 local char=assert(player.Character,"Character is not ready")
 local hum=assert(char:FindFirstChildOfClass("Humanoid"),"Character is not ready")
 local look=wornLook(player)
 -- Do not silently photograph a wardrobe change that has not finished applying.
 if look and look.boutique then for id in look.boutique:gmatch("[^,]+")do
  local worn=char:FindFirstChild(Cat.models[Cat.slot(id)])
  assert(worn and worn:GetAttribute("DressId")==id,"Clothing is still changing")
 end end
 if look and look.hat then local worn=char:FindFirstChild("WornHat");assert(worn and worn:GetAttribute("HatId")==look.hat,"Hat is still changing")end
 return {id=player.UserId,name=player.DisplayName,t=os.time(),receipt=game:GetService("HttpService"):GenerateGUID(false),look=look,rig=hum.RigType.Name,appearance=saveDescription(hum:GetAppliedDescription())}
end
local function hang(player,late,entry)
 entry=entry or newEntry(player)
 local ok,model=pcall(prepareModel,entry)
 if not ok then warn("PortraitServer: "..tostring(model));return false end
 local savedOk,savedList=not store,nil
 if store then
  for attempt=1,3 do
   local err
   savedOk,err=pcall(function()return store:UpdateAsync("latest",function(saved)return merge(saved,entry)end)end)
   if savedOk then savedList=err;break end
   warn("PortraitServer: gallery save attempt "..attempt.." failed: "..tostring(err))
   if attempt<3 then task.wait(attempt)end
  end
 end
 list=type(savedList)=="table"and merge(savedList,nil)or merge(list,entry)
 show();retireUnusedModels()
 if not savedOk then return false end
 local canvas=slots:FindFirstChild("Slot1")and slots.Slot1:FindFirstChild("Canvas",true)
 local em=canvas and canvas:FindFirstChild("Sparkle")and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
 if em then em:Emit(70)end
 local passport=RS:FindFirstChild("PassportActivity");if passport and player.Parent then passport:Fire(player,"portrait",{})end
 if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 return true
end

local function paintedKey(uid)return "painted_u"..tostring(uid)end
local function pendingKey(uid)return "pending_u"..tostring(uid)end
local function remember(player,target)
 if not store then return true end
 local ok,err=pcall(function()store:UpdateAsync(paintedKey(player.UserId),function(old)return math.max(tonumber(old)or 0,target)end)end)
 if not ok then warn("PortraitServer: painted receipt save failed: "..tostring(err))end
 return ok
end
local seat=G:WaitForChild("SitterChair"):WaitForChild("PortraitSeat")
local active,prepared,unsettled={},{},{}
local function cancelPreparation(player)
 local prep=prepared[player];prepared[player]=nil
 if prep then pendingPortraits[portraitKey(prep.entry)]=nil;retireUnusedModels()end
 if not active[player]and G:GetAttribute("SessionUser")==player.UserId then G:SetAttribute("SessionUser",nil)end
end
local preparePurchase=G:FindFirstChild("PortraitPrepare")or Instance.new("BindableFunction")
preparePurchase.Name="PortraitPrepare";preparePurchase.Parent=G
preparePurchase.OnInvoke=function(player,action)
 if action=="cancel"then cancelPreparation(player);return true end
 if active[player]or unsettled[player]then return false,"your paid portrait is still being saved; no new purchase needed"end
 if G:GetAttribute("SessionUser")~=player.UserId then return false,"the painter is busy"end
 local ok,err=xpcall(function()
  assert(listLoaded,"Gallery is still loading")
  local char=assert(player.Character);local hum=assert(char:FindFirstChildOfClass("Humanoid"))
  assert(hum.Health>0 and player:HasAppearanceLoaded(),"Character appearance is still loading")
  local entry=newEntry(player)
  prepared[player]={entry=entry,target=item(player,"portrait")+1,character=char}
  pendingPortraits[portraitKey(entry)]=true
  prepareModel(entry)
  -- Save the immutable likeness before charging. A reconnect can finish this
  -- exact sitting once the purchase count proves it was paid for.
  if store then
   local receipt={entry=entry,target=prepared[player].target}
   local saved,lastError=false,nil
   for attempt=1,3 do
    saved,lastError=pcall(function()store:UpdateAsync(pendingKey(player.UserId),function()return receipt end)end)
    if saved then break end
    if attempt<3 then task.wait(attempt)end
   end
   assert(saved,"Could not reserve portrait save: "..tostring(lastError))
  end
  assert(player.Parent and player.Character==char and hum.Health>0,"Character changed during preparation")
 end,debug.traceback)
 if not ok then cancelPreparation(player);warn("Portrait preparation: "..tostring(err));return false,"the painter couldn't prepare your portrait. No acorns were taken; please try again."end
 return true
end
G:SetAttribute("SessionUser",nil)
G:SetAttribute("PortraitReady",store~=nil or game:GetService("RunService"):IsStudio())

local function deliver(player,entry,target,late)
 unsettled[player]=true;pendingPortraits[portraitKey(entry)]=true
 local attempt=0
 while true do
  attempt+=1
  local ok,result=pcall(function()
   if not hang(player,late or attempt>1,entry)then return false end
   return remember(player,target)
  end)
  if ok and result then break end
  warn("PortraitServer: paid receipt awaiting retry "..entry.receipt..": "..tostring(result))
  if attempt==1 and player.Parent then done:FireClient(player,"deferred",{})end
  -- The pending receipt remains durable if the server closes between retries.
  task.wait(math.min(10*2^(math.min(attempt-1,5)),120))
 end
 unsettled[player]=nil;pendingPortraits[portraitKey(entry)]=nil;retireUnusedModels()
end
local function sitting(player,target)
 if active[player]then return end
 active[player]=true
 local prep=prepared[player];prepared[player]=nil
 local entry=prep and prep.entry
 local hum,oldJump
 local ok,err=xpcall(function()
  while not listLoaded do task.wait(.2)end
  entry=entry or newEntry(player)
  pendingPortraits[portraitKey(entry)]=true
  local paintedModel=prepareModel(entry)
  if not player.Parent then return end
  local char=player.Character;hum=char and char:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health<=0 then return end
  G:SetAttribute("SessionUser",player.UserId);player:SetAttribute("PortraitSitting",true)
  oldJump=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping);hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  seat.Disabled=false;char:PivotTo(seat.CFrame*CFrame.new(0,2.8,0));task.wait(.15);seat:Sit(hum)
  local finish=workspace:GetServerTimeNow()+8
  done:FireClient(player,"painting",{finish=finish,duration=8})
  while workspace:GetServerTimeNow()<finish do
   if not player.Parent or not hum.Parent or hum.Health<=0 then return end
   task.wait(.1)
  end
  done:FireClient(player,"reveal",{id=entry.id,name=entry.name,modelKey=paintedModel.Name})
  task.wait(4)
 end,debug.traceback)
 if hum and hum.Parent then
  if oldJump~=nil then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,oldJump)end
  if hum.SeatPart==seat then hum.Sit=false end
 end
 seat.Disabled=true;player:SetAttribute("PortraitSitting",nil)
 if G:GetAttribute("SessionUser")==player.UserId then G:SetAttribute("SessionUser",nil)end
 active[player]=nil
 if not ok then warn("Portrait sitting: "..tostring(err))end
 -- Finishing the paid image does not depend on the player staying in the chair,
 -- keeping this character alive, or even remaining connected.
 if entry then unsettled[player]=true;task.spawn(deliver,player,entry,prep and prep.target or target,false)end
 if player.Parent then done:FireClient(player,"sessionEnd",{})end
end
local itemEv=RS:WaitForChild("AwardItems",30)
if itemEv and itemEv:IsA("BindableEvent")then
 itemEv.Event:Connect(function(player,id,n)
  if id~="portrait"or(tonumber(n)or 0)<=0 or typeof(player)~="Instance"or not player:IsA("Player")then return end
  task.defer(sitting,player,item(player,"portrait"))
 end)
else warn("PortraitServer: no AwardItems event - portraits cannot be bought")end
local function owed(player)
 if not store then return end
 while player.Parent and not(player:GetAttribute("SaveLoaded")and listLoaded)do task.wait(.5)end
 if not player.Parent then return end
 local bought=item(player,"portrait")
 if bought<=0 or active[player]or prepared[player]or unsettled[player]then return end
 local ok,painted,receipt=pcall(function()return store:GetAsync(paintedKey(player.UserId)),store:GetAsync(pendingKey(player.UserId))end)
 if not ok then task.delay(15,owed,player);return end
 if active[player]or prepared[player]or unsettled[player]then return end
 painted=tonumber(painted)
 local onWall=false
 for _,e in ipairs(list)do if tonumber(e.id)==player.UserId then onWall=true end end
 if painted==nil and onWall and not receipt then remember(player,bought);return end
 if bought<=(painted or 0)then return end
 local entry=type(receipt)=="table"and receipt.target<=bought and receipt.target>(painted or 0)and receipt.entry or nil
 local target=entry and receipt.target or bought
 if not entry then
  -- Only legacy purchases lack a saved likeness. New purchases always carry one.
  local good,result=pcall(newEntry,player)
  if not good then task.delay(15,owed,player);return end
  entry=result
 end
 unsettled[player]=true
 task.wait(5)
 deliver(player,entry,target,true)
end
Players.PlayerRemoving:Connect(function(player)
 -- A paid sitting owns its snapshot until delivery; only unpaid preparation is canceled.
 if not active[player]then cancelPreparation(player)end
end)
Players.PlayerAdded:Connect(function(p)task.spawn(owed,p)end)
for _,p in ipairs(Players:GetPlayers())do task.spawn(owed,p)end
show();task.spawn(load)
print("PortraitServer: ready - saved appearance, prepayment validation, automatic delivery retry")

