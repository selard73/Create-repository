-- A portable wardrobe backed by the existing saved boutique inventory.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local p=Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local kit=RS:WaitForChild("DressKit")
local Cat=require(kit:WaitForChild("Catalogue"))
local action=RS:WaitForChild("DressShopAction")
local C=Color3.fromRGB
local PAPER,INK,GOLD,PINE=C(255,246,220),C(64,42,22),C(242,192,75),C(29,82,57)
local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function rim(o,w,t)local s=Instance.new("UIStroke");s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Color=GOLD;s.Thickness=w or 1;s.Transparency=t or 0;s.Parent=o;return s end
local function label(parent,name,value,size)
 local l=Instance.new("TextLabel");l.Name=name;l.BackgroundTransparency=1;l.Text=value;l.TextSize=size or 14;l.Font=Enum.Font.FredokaOne;l.TextColor3=INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=parent;return l
end
local function button(parent,name,value)
 local b=Instance.new("TextButton");b.Name=name;b.Text=value;b.Font=Enum.Font.FredokaOne;b.TextSize=13;b.TextColor3=INK;b.BackgroundColor3=GOLD;b.BorderSizePixel=0;b.AutoButtonColor=true;b.Parent=parent;round(b,10);return b
end
local gui=Instance.new("ScreenGui");gui.Name="WardrobeGui";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=9;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local panel=Instance.new("Frame");panel.Name="Panel";panel.AnchorPoint=Vector2.new(.5,0);panel.BackgroundColor3=PAPER;panel.BorderSizePixel=0;panel.Active=true;panel.Visible=false;panel.Parent=gui;round(panel,18)
local edge=rim(panel,3)
local foil=Instance.new("UIGradient");foil.Color=ColorSequence.new(C(194,135,40),C(255,231,150));foil.Rotation=35;foil.Parent=edge
local heading=label(panel,"Heading","Wardrobe",22);heading.Position=UDim2.fromOffset(18,8);heading.Size=UDim2.new(1,-225,0,26)
local subtitle=label(panel,"Subtitle","Purchased outfits & accessories",11);subtitle.Font=Enum.Font.BuilderSans;subtitle.Position=UDim2.fromOffset(19,35);subtitle.Size=UDim2.new(1,-210,0,16);subtitle.TextColor3=C(113,79,45);subtitle.TextTruncate=Enum.TextTruncate.AtEnd
local close=button(panel,"Close","×");close.Size=UDim2.fromOffset(44,44);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-9,0,7);close.TextSize=25;close.BackgroundColor3=C(237,223,195)
local original=button(panel,"OriginalClothing","Original clothing");original.AnchorPoint=Vector2.new(1,0);original.Position=UDim2.new(1,-62,0,7);original.Size=UDim2.fromOffset(137,44);original.BackgroundColor3=C(237,223,195)
local list=Instance.new("ScrollingFrame");list.Name="Items";list.BackgroundTransparency=1;list.BorderSizePixel=0;list.Position=UDim2.fromOffset(14,96);list.ScrollBarThickness=4;list.ScrollBarImageColor3=GOLD;list.ScrollingDirection=Enum.ScrollingDirection.Y;list.CanvasSize=UDim2.new();list.Active=true;list.Parent=panel
local tabs={};local category="all";local busy=false;local cards={};local columns=2;local width=290
local choices={{"all","All"},{"dress","Clothes"},{"eyewear","Sunglasses"},{"necklace","Jewellery"}}
for _,choice in ipairs(choices)do local b=button(panel,"Tab_"..choice[1],choice[2]);tabs[choice[1]]=b end
local empty=label(list,"Empty","",14);empty.TextWrapped=true;empty.TextXAlignment=Enum.TextXAlignment.Center;empty.Size=UDim2.new(1,-12,1,-8);empty.Position=UDim2.fromOffset(6,4)
local function owned(id)return (p:GetAttribute("Item_dress_"..id) or 0)>0 end
local function wearing(id)return (p:GetAttribute("Item_dresswear_"..id) or 0)>0 end
local function picture(id,parent)
 local vf=Instance.new("ViewportFrame");vf.Name="Preview";vf.Size=UDim2.fromOffset(86,92);vf.Position=UDim2.fromOffset(7,6);vf.BackgroundColor3=C(247,233,203);vf.BorderSizePixel=0;vf.Ambient=C(200,190,180);vf.LightColor=C(255,246,230);vf.LightDirection=Vector3.new(-.6,-.5,-1);vf.Parent=parent;round(vf,9)
 local m=Instance.new("Model");for _,part in ipairs(Cat.pieces(kit,id,CFrame.new(),1))do part.Anchored=true;part.Parent=m end;m.Parent=vf
 local cf,size=m:GetBoundingBox();local cam=Instance.new("Camera");cam.FieldOfView=30
 local dist=math.max(size.X/.86,size.Y)/(2*math.tan(math.rad(15)))*1.18
 cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(.22,.1,-1).Unit*dist,cf.Position);cam.Parent=vf;vf.CurrentCamera=cam
end
local refresh
local function send(what,id)
 if busy then return end;busy=true;refresh()
 local ok,accepted,why=pcall(function()return action:InvokeServer(what,id)end)
 busy=false
 subtitle.Text=ok and accepted and (what=="original" and "Original clothing restored" or what=="off" and "Accessory put away" or "Ready for your next adventure!") or tostring(ok and why or "Please try again")
 refresh()
end
local function createCard(id)
 local d=Cat.byId[id]
 local card=Instance.new("Frame");card.Name="Item_"..id;card.BackgroundColor3=C(255,250,234);card.BorderSizePixel=0;card.Parent=list;round(card,12);local stroke=rim(card,1,.3)
 local glow=Instance.new("Frame");glow.Name="GoldHighlight";glow.BackgroundTransparency=1;glow.Position=UDim2.fromOffset(2,2);glow.Size=UDim2.new(1,-4,1,-4);glow.Parent=card;round(glow,10);rim(glow,3,.88)
 picture(id,card)
 local name=label(card,"Name",d.style.name,14);name.Position=UDim2.fromOffset(103,7);name.Size=UDim2.new(1,-113,0,30);name.TextWrapped=true
 local colour=label(card,"Colour",d.colour.name,12);colour.Font=Enum.Font.BuilderSans;colour.Position=UDim2.fromOffset(103,38);colour.Size=UDim2.new(1,-113,0,14);colour.TextColor3=C(113,79,45)
 local wear=button(card,"Wear","Wear it");wear.Position=UDim2.fromOffset(103,56);wear.Size=UDim2.new(1,-113,0,44)
 wear.Activated:Connect(function()if not wearing(id)then send("wear",id)elseif Cat.slot(id)~="dress" then send("off",Cat.slot(id))end end)
 cards[id]={frame=card,button=wear,stroke=stroke};return cards[id]
end
refresh=function()
 if not panel.Visible then return end
 local loaded=p:GetAttribute("SaveLoaded");local count=0
 for _,id in ipairs(Cat.order)do
  local mine=owned(id);local show=loaded and mine and (category=="all" or Cat.slot(id)==category)
  local c=cards[id];if show and not c then c=createCard(id)end
  if c then
   c.frame.Visible=show
   if show then
    c.frame.Position=UDim2.fromOffset(3+(count%columns)*(width+12),3+math.floor(count/columns)*116);c.frame.Size=UDim2.fromOffset(width,104);count+=1
    local on=wearing(id);c.button.Text=busy and "..." or on and (Cat.slot(id)=="dress" and "Wearing" or "Put away") or "Wear it"
    c.button.BackgroundColor3=on and PINE or GOLD;c.button.TextColor3=on and PAPER or INK;c.button.Active=not busy;c.button.AutoButtonColor=not busy;c.stroke.Transparency=on and 0 or .3
   end
  end
 end
 empty.Visible=count==0
 empty.Text=not loaded and "Opening your saved wardrobe..." or category=="all" and "Your suitcase is ready!\nOutfits and accessories you buy at the boutique will appear here." or "Nothing packed in this category yet.\nYour boutique purchases will appear here."
 list.CanvasSize=UDim2.fromOffset(0,math.ceil(count/columns)*116)
 for id,b in pairs(tabs)do b.BackgroundColor3=id==category and PINE or C(237,223,195);b.TextColor3=id==category and PAPER or INK end
 original.Active=not busy
end
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local h=math.min(570,math.max(120,vp.Y-160));local w=math.min(900,vp.X-28)
 panel.Position=UDim2.new(.5,0,0,68);panel.Size=UDim2.fromOffset(w,h);list.Size=UDim2.new(1,-28,1,-106)
 columns=w>=590 and 2 or 1;width=math.floor((w-34-(columns-1)*12)/columns)
 for i,choice in ipairs(choices)do local b=tabs[choice[1]];b.Position=UDim2.fromOffset(14+(i-1)*(w-24)/4,56);b.Size=UDim2.fromOffset((w-24)/4-6,38)end
 refresh()
end
local function closePanel()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="wardrobe" then pg:SetAttribute("OpenPanel",nil)end end
local function toggle()
 if panel.Visible then closePanel();return end
 pg:SetAttribute("OpenPanel","wardrobe");panel.Visible=true;subtitle.Text="Purchased outfits & accessories";fit()
end
close.Activated:Connect(closePanel)
original.Activated:Connect(function()send("original","")end)
for id,b in pairs(tabs)do b.Activated:Connect(function()category=id;list.CanvasPosition=Vector2.zero;refresh()end)end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if pg:GetAttribute("OpenPanel")~="wardrobe" then closePanel()end end)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then closePanel()end end)
p.CharacterAdded:Connect(closePanel)
local queued=false
p.AttributeChanged:Connect(function(name)
 if name=="SaveLoaded" or name:sub(1,11)=="Item_dress_" or name:sub(1,15)=="Item_dresswear_" then
  if not queued then queued=true;task.defer(function()queued=false;refresh()end)end
 end
end)
local cameraConnection
local function cameraChanged()if cameraConnection then cameraConnection:Disconnect()end;fit();if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)end end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
local function hookHud(hud)
 local bar=hud:WaitForChild("Bar",30);if not bar or bar:FindFirstChild("Wardrobe")then return end
 -- Five matching 48px controls fit alongside the native Roblox controls on phones.
 bar.AutomaticSize=Enum.AutomaticSize.X
 local b=button(bar,"Wardrobe","");b.LayoutOrder=-2;b.Size=UDim2.fromOffset(48,48);b.BackgroundColor3=C(38,30,52);b:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,14);rim(b,2,.35)
 local function piece(name,x,y,w,h,r)
  local f=Instance.new("Frame");f.Name=name;f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.BackgroundTransparency=1;f.BorderSizePixel=0;f.Parent=b;round(f,r);local s=rim(f,1.6);s.Color=PAPER;return f
 end
 piece("Handle",19,5,10,6,2);piece("Case",10,10,28,19,4)
 for _,x in ipairs({17,30})do local strap=Instance.new("Frame");strap.Name="Strap";strap.Position=UDim2.fromOffset(x,11);strap.Size=UDim2.fromOffset(1,17);strap.BackgroundColor3=PAPER;strap.BorderSizePixel=0;strap.Parent=b end
 local caption=label(b,"Caption","Wardrobe",9);caption.TextColor3=C(255,214,90);caption.TextXAlignment=Enum.TextXAlignment.Center;caption.Size=UDim2.fromOffset(48,14);caption.Position=UDim2.fromOffset(0,32)
 b.Activated:Connect(toggle)
 hud:GetPropertyChangedSignal("Enabled"):Connect(function()if not hud.Enabled then closePanel()end end)
end
pg.ChildAdded:Connect(function(g)if g.Name=="HudBar" then task.spawn(hookHud,g)end end)
local hud=pg:FindFirstChild("HudBar");if hud then task.spawn(hookHud,hud)end
print("Wardrobe: saved boutique outfits and accessories ready")
