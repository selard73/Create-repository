-- PortraitClient: the word to the sitter when their portrait is set up
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local G = script.Parent
local done = G:WaitForChild("PortraitDone")
-- Nearby chair interaction uses the shared desktop/touch prompt design.
-- Open the existing store row; only its purchase button spends acorns.
task.spawn(function()
 local pg=player:WaitForChild("PlayerGui")
 local prompt
 local function offerAvailable(shop,seat)
  local char=player.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local daily=pg:FindFirstChild("DailyGui")
  local card=daily and daily:FindFirstChild("DailyCard")
  return shop and shop:GetAttribute("Open")~=false
   and (shop:GetAttribute("Selling")==true or shop:GetAttribute("Sell_portrait")==true)
   and type(shop:GetAttribute("Price_portrait"))=="number"
   and G:GetAttribute("PortraitReady")==true and not G:GetAttribute("SessionUser")
   and not seat.Occupant and hum and hum.Health>0
   and not player:GetAttribute("PortraitSitting") and not pg:GetAttribute("OpenPanel")
   and not (daily and daily.Enabled and card and card.Visible)
 end
 while G:IsDescendantOf(workspace) do
  local chair=G:FindFirstChild("SitterChair")
  local seat=chair and chair:FindFirstChild("PortraitSeat")
  local shop=workspace:FindFirstChild("Shop")
  local openAt=shop and shop:FindFirstChild("OpenAt")
  if prompt and prompt.Parent~=seat then prompt:Destroy();prompt=nil end
  if seat and openAt and not prompt then
   local p=Instance.new("ProximityPrompt");p.Name="PortraitChairPrompt"
   p.Style=Enum.ProximityPromptStyle.Custom;p.ActionText="Sit for a portrait"
   p.KeyboardKeyCode=Enum.KeyCode.E;p.GamepadKeyCode=Enum.KeyCode.ButtonX
   p.MaxActivationDistance=8;p.RequiresLineOfSight=true;p.HoldDuration=0
   p.ClickablePrompt=true;p.Enabled=false
   p.Triggered:Connect(function()
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position-seat.Position).Magnitude>p.MaxActivationDistance+1 then return end
    if offerAvailable(shop,seat) and openAt.Parent==shop then
     p.Enabled=false;openAt:Fire("portrait")
    end
   end)
   p.Parent=seat;prompt=p
  end
  if prompt then
   local text=tostring(shop and shop:GetAttribute("Price_portrait") or "").." acorns"
   if prompt.ObjectText~=text then prompt.Enabled=false;prompt.ObjectText=text
   else prompt.Enabled=openAt~=nil and offerAvailable(shop,seat) and true or false end
  end
  task.wait(.2)
 end
 if prompt then prompt:Destroy()end
end)


local C = Color3.fromRGB

local gui = Instance.new("ScreenGui"); gui.Name = "PortraitNote"; gui.ResetOnSpawn = false; gui.DisplayOrder = 7; gui.Parent = player:WaitForChild("PlayerGui")
-- the note hugs its words and wraps inside its box, in crisp BuilderSans, with the gold line round the box (not round
-- the letters)
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 0); note.Position = UDim2.new(0.5, 0, 0, 70)
note.Size = UDim2.fromOffset(0, 0); note.AutomaticSize = Enum.AutomaticSize.XY; note.TextWrapped = true
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold); note.TextSize = 20
note.TextColor3 = C(255, 214, 90); note.TextTransparency = 1; note.Text = ""; note.Parent = gui
local nmax = Instance.new("UISizeConstraint"); nmax.MaxSize = Vector2.new(460, math.huge); nmax.Parent = note
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 16); np.PaddingRight = UDim.new(0, 16)
np.PaddingTop = UDim.new(0, 9); np.PaddingBottom = UDim.new(0, 9); np.Parent = note
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 14); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
done.OnClientEvent:Connect(function(what, late)
	if what ~= "hung" and what ~= "deferred" then return end
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	nmax.MaxSize = Vector2.new(math.clamp(vw - 40, 240, 460), math.huge)
	note.Text = ((type(late)=="table"and late.late or late==true)and "Sorry for the wait! "or "") .. "The painter has finished your portrait - it stands on an easel in his gallery by the river."
	if what=="deferred"then note.Text="Your paid portrait is still being prepared. You do not need to buy it again; the painter is retrying automatically, even if you leave."end
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(5, function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.6)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end)

-- Inspect the whole painting, including its scene and companions, from its easel.
local pg=player:WaitForChild("PlayerGui")
local UIS=game:GetService("UserInputService")
local viewer=Instance.new("ScreenGui");viewer.Name="PortraitViewer";viewer.IgnoreGuiInset=true;viewer.ResetOnSpawn=false;viewer.DisplayOrder=10;viewer.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;viewer.Parent=pg
local page=Instance.new("Frame");page.Name="Page";page.AnchorPoint=Vector2.new(.5,0);page.BackgroundColor3=C(255,246,220);page.BorderSizePixel=0;page.Active=true;page.Visible=false;page.Parent=viewer
local function rounded(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
rounded(page,16)
local outline=Instance.new("UIStroke");outline.Color=C(233,184,65);outline.Thickness=3;outline.Parent=page
local foil=Instance.new("UIGradient");foil.Color=ColorSequence.new(C(193,132,34),C(255,231,147));foil.Rotation=35;foil.Parent=outline
local painting=Instance.new("Frame");painting.Name="Painting";painting.BackgroundColor3=C(246,240,226);painting.BorderSizePixel=0;painting.ClipsDescendants=true;painting.Parent=page
local inner=Instance.new("UIStroke");inner.Color=C(184,135,44);inner.Thickness=2;inner.Parent=painting
local function text(name,value,size,col)
 local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Font=Enum.Font.FredokaOne;t.TextSize=size;t.TextColor3=col;t.BackgroundTransparency=1;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.TextWrapped=true;t.Parent=page;return t
end
local heading=text("Heading","Garden portrait",18,C(64,42,22))
local sitter=text("Sitter","",16,C(64,42,22))
local caption=text("Caption","From the painter's gallery",12,C(113,79,45));caption.Font=Enum.Font.BuilderSans
local close=Instance.new("TextButton");close.Name="Close";close.Text="×";close.Font=Enum.Font.FredokaOne;close.TextSize=25;close.TextColor3=C(64,42,22);close.BackgroundColor3=C(237,223,195);close.BorderSizePixel=0;close.Size=UDim2.fromOffset(44,44);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-8,0,8);close.Parent=page;rounded(close,11)
local current,canvas,source,revealSource
local paintings={};local connections={}
local function disconnect()
 for _,c in ipairs(connections)do c:Disconnect()end;table.clear(connections)
end
local function clearPainting()for _,o in ipairs(paintings)do o:Destroy()end;table.clear(paintings)end
local function closePortrait()
 page.Visible=false;current=nil;canvas=nil;source=nil;disconnect();clearPainting()
 if revealSource then revealSource:Destroy();revealSource=nil end
 if pg:GetAttribute("OpenPanel")=="portrait" then pg:SetAttribute("OpenPanel",nil)end
end
local portraitFrameWatches=setmetatable({},{__mode="k"})
local function frameViewport(vp,model)
 if not vp or not model or not model:FindFirstChild("Head")then return false end
 local cam=vp:FindFirstChild("PortraitCamera")
 if not cam then cam=Instance.new("Camera");cam.Name="PortraitCamera";cam.FieldOfView=28;cam.Parent=vp end
 local points={};local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
 for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")and part.Transparency<.99 then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
   points[#points+1]=p;low=low:Min(p);high=high:Max(p)
  end end end
 end end
 if #points==0 then return false end
 local focus=(low+high)/2
 local direction=Vector3.new(.18,.06,-1).Unit
 local orientation=CFrame.lookAt(focus+direction,focus).Rotation
 local aspect=vp.AbsoluteSize.Y>0 and vp.AbsoluteSize.X/vp.AbsoluteSize.Y or .78
 local tanY=math.tan(math.rad(cam.FieldOfView/2));local tanX=tanY*math.max(.1,aspect)
 local dist=0
 for _,p in ipairs(points)do
  local localPoint=orientation:VectorToObjectSpace(p-focus)
  dist=math.max(dist,math.abs(localPoint.X)/tanX+localPoint.Z,math.abs(localPoint.Y)/tanY+localPoint.Z)
 end
 dist*=1.10
 local torso=model:FindFirstChild("UpperTorso")or model:FindFirstChild("Torso")
 if model:GetAttribute("PortraitCrop")=="waist"and torso then
  local waist=torso.Position.Y-torso.Size.Y/2
  local height=math.max(model.Head.Size.Y*1.6,high.Y-waist)
  focus=Vector3.new(torso.Position.X,waist+height/2,focus.Z)
  dist=height/(2*tanY)*1.10
 end
 cam.CFrame=CFrame.lookAt(focus+direction*dist,focus)
 vp.CurrentCamera=cam;vp.Visible=true
 if not portraitFrameWatches[vp]then
  portraitFrameWatches[vp]=true
  vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
   local world=vp:FindFirstChild("World")or vp:FindFirstChildOfClass("WorldModel")
   local currentModel=world and world:FindFirstChildOfClass("Model")
   if currentModel then frameViewport(vp,currentModel)end
  end)
 end
 return true
end


local function fitPortrait()
 if not canvas then return end
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local available=math.max(80,math.min(600,vp.Y-148))
 local ratio=canvas.Size.X/math.max(.01,canvas.Size.Y)
 local side=vp.X<600 and 154 or 190
 local imageH=math.min(available-24,(vp.X-side-52)/ratio)
 local imageW=math.floor(imageH*ratio);imageH=math.floor(imageH)
 local w=imageW+side+36;local h=imageH+24
 page.Size=UDim2.fromOffset(w,h);page.Position=UDim2.new(.5,0,0,68+math.floor((available-h)/2))
 painting.Position=UDim2.fromOffset(12,12);painting.Size=UDim2.fromOffset(imageW,imageH)
 local left=imageW+28
 heading.Position=UDim2.fromOffset(left,58);heading.Size=UDim2.fromOffset(side-8,46)
 sitter.Position=UDim2.fromOffset(left,110);sitter.Size=UDim2.fromOffset(side-8,math.max(24,h-150));sitter.TextSize=vp.Y<500 and 15 or 20;sitter.TextTruncate=Enum.TextTruncate.AtEnd
 caption.Position=UDim2.fromOffset(left,h-30);caption.Size=UDim2.fromOffset(side-8,22)
end
local function copyPainting()
 if not current or not source or (source~=revealSource and not source:IsDescendantOf(G))then closePortrait();return end
 local portrait=source:FindFirstChild("Portrait")
 local pv=source:FindFirstChild("Portrait3D");local pw=pv and pv:FindFirstChild("World");local hasViewport=pv and pv.Visible and pw and #pw:GetChildren()>0
 if not portrait or not portrait.Visible or (portrait.Image=="" and not hasViewport) then closePortrait();return end
 clearPainting()
 for _,child in ipairs(source:GetChildren())do
  if child:IsA("GuiObject")then
   local copy=child:Clone();copy.Parent=painting
   if copy:IsA("ViewportFrame")then
    local world=copy:FindFirstChild("World");local model=world and world:FindFirstChildOfClass("Model")
    if model then frameViewport(copy,model)end
   end
   paintings[#paintings+1]=copy
  end
 end
 local plaque=current:FindFirstChild("Plaque")
 local sg=plaque and plaque:FindFirstChildOfClass("SurfaceGui")
 local name=sg and sg:FindFirstChild("Name")
 sitter.Text=name and name.Text or ""
end
local function showPortrait(slot)
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="portrait" then return end
 local c=slot:FindFirstChild("Canvas",true);local s=c and c:FindFirstChild("Picture");local img=s and s:FindFirstChild("Portrait")
 local pv=s and s:FindFirstChild("Portrait3D");local pw=pv and pv:FindFirstChild("World");local hasViewport=pv and pv.Visible and pw and #pw:GetChildren()>0
 if not img or not img.Visible or (img.Image=="" and not hasViewport) then return end
 closePortrait();current=slot;canvas=c;source=s
 heading.Text="Garden portrait";caption.Text="From the painter's gallery"
 pg:SetAttribute("OpenPanel","portrait");copyPainting();fitPortrait();page.Visible=true
 connections[#connections+1]=slot.AncestryChanged:Connect(function()if not slot:IsDescendantOf(G)then closePortrait()end end)
 connections[#connections+1]=img:GetPropertyChangedSignal("Image"):Connect(function()task.defer(copyPainting)end)
 connections[#connections+1]=img:GetPropertyChangedSignal("Visible"):Connect(function()task.defer(copyPainting)end)
end
close.Activated:Connect(closePortrait)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then closePortrait()end end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if pg:GetAttribute("OpenPanel")~="portrait" and page.Visible then closePortrait()end end)
player.CharacterAdded:Connect(closePortrait)
local cameraConnection
local function cameraChanged()if cameraConnection then cameraConnection:Disconnect()end;fitPortrait();if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPortrait)end end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
-- ViewportFrames render on a world surface only when the SurfaceGui lives in
-- PlayerGui. Keep the server-owned Picture as the replicated template, and
-- mount a local copy onto its canvas with Adornee. Saved portraits use this
-- same path, so fixing the display does not require another purchase.
local galleryPictures=Instance.new("Folder");galleryPictures.Name="PortraitGalleryPictures";galleryPictures.Parent=pg
local portraitModels=game:GetService("ReplicatedStorage"):WaitForChild("PortraitGalleryModels")
local function portraitComplete(model)
 if not model or not model:FindFirstChild("Head")or not model:FindFirstChild("HumanoidRootPart")then return false end
 local expected=model:GetAttribute("PortraitPartCount")
 if type(expected)~="number"then return false end
 local count,visualCount=0,0
 for _,d in ipairs(model:GetDescendants())do
  if d:IsA("BasePart")then count+=1 end
  if d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("Decal")or d:IsA("SurfaceAppearance")then visualCount+=1 end
 end
 return count>=expected and visualCount>=(model:GetAttribute("PortraitVisualCount")or math.huge)
end
local boundCanvases={}
local slots=G:WaitForChild("Slots")
local function hookCanvas(c)
 if c.Name~="Canvas" or not c:IsA("BasePart") or boundCanvases[c] then return end
 local slot=c.Parent
 while slot and slot.Parent~=slots do slot=slot.Parent end
 if not slot or not slot:IsA("Model") then return end
 boundCanvases[c]=true
 task.spawn(function()
  local picture=c:WaitForChild("Picture",10)
  if not picture or not c:IsDescendantOf(slots) then boundCanvases[c]=nil;return end
  local listeners,watched={},{}
  local mounted,queued,stopped=nil,false,false
  local installedModel
  local function connect(signal,fn) local con=signal:Connect(fn);listeners[#listeners+1]=con;return con end
  local function cleanup()
   stopped=true
   for _,con in ipairs(listeners) do con:Disconnect() end
   for _,con in pairs(watched) do con:Disconnect() end
   if mounted then mounted:Destroy();mounted=nil end
   boundCanvases[c]=nil
  end
  local refresh,schedule
  refresh=function()
   queued=false
   if stopped or not c:IsDescendantOf(slots) then return end
   local vp=picture:FindFirstChild("Portrait3D")
   local world=vp and vp:FindFirstChild("World")
   local key=vp and vp:GetAttribute("GalleryModelKey")
   local stored=key and portraitModels:FindFirstChild(key)
   if vp and vp.Visible then
    if not portraitComplete(stored)then schedule();return end
    if stored~=installedModel then
     world:ClearAllChildren();local sitter=stored:Clone();sitter.Name="PaintedSitter";sitter.Parent=world;installedModel=stored
    end
   elseif world then world:ClearAllChildren();installedModel=nil end
   local model=world and world:FindFirstChild("PaintedSitter")
   -- A model can arrive over several replication frames. Keep the previous
   -- picture until the new sitter has a usable camera target.
   if vp and vp.Visible and (not model or not frameViewport(vp,model)) then return end
   local copy=picture:Clone();copy.Name=slot.Name;copy.Adornee=c;copy.Enabled=true;copy.ResetOnSpawn=false
   local cv=copy:FindFirstChild("Portrait3D")
   local cm=cv and cv:FindFirstChild("World") and cv.World:FindFirstChild("PaintedSitter")
   if cm then frameViewport(cv,cm) end
   copy.Parent=galleryPictures
   picture.Enabled=false -- local only; the server continues updating its template
   if mounted then mounted:Destroy() end
   mounted=copy
   if current==slot and source==picture and page.Visible then copyPainting() end
  end
  schedule=function()
   if queued or stopped then return end
   queued=true;task.delay(.1,refresh)
  end
  local function watch(obj)
   if watched[obj] or not obj:IsA("GuiObject") then return end
   watched[obj]=obj.Changed:Connect(function(property)
    if property=="Visible" or property=="Image" or property=="Size" or property=="Position" then schedule() end
   end)
  end
  connect(portraitModels.ChildAdded,schedule)
  connect(portraitModels.DescendantAdded,function(obj)
   local key=picture.Portrait3D:GetAttribute("GalleryModelKey")
   if key and obj:FindFirstAncestor(key)then installedModel=nil;schedule()end
  end)
  connect(portraitModels.ChildRemoved,schedule)
  connect(picture.Portrait3D:GetAttributeChangedSignal("RenderToken"),schedule)
  connect(picture.Portrait3D:GetAttributeChangedSignal("GalleryModelKey"),schedule)
  for _,obj in ipairs(picture:GetDescendants()) do watch(obj) end
  connect(picture.DescendantAdded,function(obj)watch(obj);schedule()end)
  connect(picture.DescendantRemoving,function(obj)
   if watched[obj] then watched[obj]:Disconnect();watched[obj]=nil end
   schedule()
  end)
  connect(c.AncestryChanged,function()if not c:IsDescendantOf(slots) then cleanup() end end)
  local click=c:FindFirstChild("ViewPortrait")
  if not click then click=Instance.new("ClickDetector");click.Name="ViewPortrait";click.MaxActivationDistance=48;click.Parent=c end
  connect(click.MouseClick,function(who)if who==player then showPortrait(slot)end end)
  schedule()
 end)
end
for _,c in ipairs(slots:GetDescendants())do hookCanvas(c)end
slots.DescendantAdded:Connect(hookCanvas)
print("Portrait viewer: river canvases mounted in PlayerGui; tap or click to inspect")

local function renderPreparedLook(vp,key)
 if not vp or type(key)~="string"then return false end
 local world=vp:FindFirstChild("World");if not world then return false end
 local model,deadline=nil,os.clock()+20
 repeat
  model=portraitModels:FindFirstChild(key)
  if portraitComplete(model)then break end
  task.wait(.1)
 until os.clock()>deadline
 if not portraitComplete(model)then return false end
 world:ClearAllChildren()
 local copy=model:Clone();copy.Name="PaintedSitter";copy.Parent=world
 return frameViewport(vp,copy)
end

local function configurePicture(gui,e)
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local vp = gui:FindFirstChild("Portrait3D")
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
				img.Image = ""; img.Visible = true; wash.Visible = true
				if not renderPreparedLook(vp,e.modelKey)then return false end
			else
				img.Image = ""; img.Visible = false; wash.Visible = false; if vp then vp.Visible = false end
			end
		end
return true
end
-- A compact progress card lets the sitter see the painter and their seated avatar.
local progress=Instance.new("Frame");progress.Name="PaintingProgress";progress.AnchorPoint=Vector2.new(.5,1);progress.Size=UDim2.fromOffset(300,64);progress.Position=UDim2.new(.5,0,1,-100);progress.BackgroundColor3=C(255,246,220);progress.BorderSizePixel=0;progress.Visible=false;progress.Parent=viewer;rounded(progress,13)
local pr=Instance.new("UIStroke");pr.Color=C(236,181,55);pr.Thickness=2;pr.Parent=progress
local progressText=Instance.new("TextLabel");progressText.Name="Caption";progressText.Size=UDim2.new(1,-20,0,29);progressText.Position=UDim2.fromOffset(10,5);progressText.BackgroundTransparency=1;progressText.Font=Enum.Font.FredokaOne;progressText.TextSize=16;progressText.TextColor3=C(64,42,22);progressText.Parent=progress
local track=Instance.new("Frame");track.Size=UDim2.new(1,-24,0,12);track.Position=UDim2.fromOffset(12,40);track.BackgroundColor3=C(219,199,155);track.BorderSizePixel=0;track.Parent=progress;rounded(track,6)
local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=C(255,199,62);fill.BorderSizePixel=0;fill.Parent=track;rounded(fill,6)
local fg=Instance.new("UIGradient");fg.Color=ColorSequence.new(C(215,151,31),C(255,227,128));fg.Parent=fill
local paintingUntil,duration=0,8
local publishedPortraits={}
game:GetService("RunService").Heartbeat:Connect(function()
 if progress.Visible then local left=math.max(0,paintingUntil-workspace:GetServerTimeNow());fill.Size=UDim2.fromScale(math.clamp(1-left/duration,0,1),1);progressText.Text=left>0 and ("Painting your portrait · "..math.ceil(left).."s")or"Adding the finishing touches…" end
end)
done.OnClientEvent:Connect(function(what,info)
 if what=="painting"then
  closePortrait();pg:SetAttribute("OpenPanel","portrait");paintingUntil=info.finish;duration=info.duration;progress.Visible=true
 elseif what=="reveal"then
  progress.Visible=false;closePortrait()
  local slot=slots:FindFirstChild("Slot1");local c=slot and slot:FindFirstChild("Canvas",true)
  if not c or not c:FindFirstChild("Picture")then return end
  current=G;canvas=c;source=c.Picture:Clone();revealSource=source
  if not configurePicture(source,info)then closePortrait();return end
  pg:SetAttribute("OpenPanel","portrait");copyPainting();fitPortrait();page.Visible=true
  heading.Text="Your portrait!";sitter.Text=info.name;caption.Text=publishedPortraits[info.modelKey]and "Saved to the river gallery"or "Next stop: the river gallery"
  local ding=Instance.new("Sound");ding.Name="PortraitRevealChime";ding.SoundId=G:GetAttribute("RevealSound")or"rbxassetid://9116394876";ding.Volume=G:GetAttribute("RevealVolume")or.32;ding.PlaybackSpeed=G:GetAttribute("RevealSpeed")or.88;ding.Parent=viewer;ding:Play();game:GetService("Debris"):AddItem(ding,6)
 elseif what=="hung"then
  if type(info)=="table"then publishedPortraits[info.modelKey]=true end
  if revealSource then caption.Text="Saved to the river gallery"end
 elseif what=="deferred"then
  progress.Visible=false
  if revealSource then caption.Text="Save pending — no new purchase needed"end
 elseif what=="sessionEnd"then
  progress.Visible=false
  if not page.Visible and pg:GetAttribute("OpenPanel")=="portrait"then pg:SetAttribute("OpenPanel",nil)end
 end
end)
player.CharacterAdded:Connect(function()progress.Visible=false end)

-- Humanoid state enablement is local too; restore the player's own jump state after the sitting.
local sittingHum,wasJumping
local function syncSitting()
 if player:GetAttribute("PortraitSitting")then
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum and hum~=sittingHum then sittingHum=hum;wasJumping=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping);hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)end
 elseif sittingHum then
  if sittingHum.Parent then sittingHum:SetStateEnabled(Enum.HumanoidStateType.Jumping,wasJumping)end
  sittingHum=nil;wasJumping=nil
 end
end
player:GetAttributeChangedSignal("PortraitSitting"):Connect(syncSitting);syncSitting()

