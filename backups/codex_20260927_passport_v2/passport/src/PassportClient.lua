local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local p=Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"))
local Art=require(RS:WaitForChild("SquirrelIllustrations"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,GREEN=C(250,241,219),C(64,42,22),C(123,102,75),C(210,159,62),C(63,105,80)
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.Parent=pg
local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.Parent=parent;return l
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-12,0,68);panel.BackgroundColor3=PAPER;panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,16)
local rim=Instance.new("UIStroke");rim.Color=C(118,80,46);rim.Thickness=2;rim.Parent=panel
local binding=Instance.new("Frame");binding.Size=UDim2.new(0,5,1,-26);binding.Position=UDim2.fromOffset(8,13);binding.BackgroundColor3=GOLD;binding.BorderSizePixel=0;binding.Parent=panel;round(binding,3)
local heading=text(panel,"My Passport",24,9,230,27,23)
local summary=text(panel,"Loading your stamps...",24,36,240,18,12,MUTED)
local close=Instance.new("TextButton");close.Name="Close";close.Text="×";close.Font=Enum.Font.GothamBold;close.TextSize=27;close.Size=UDim2.fromOffset(40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-10,0,7);close.BackgroundColor3=C(234,220,189);close.TextColor3=INK;close.BorderSizePixel=0;close.Parent=panel;round(close,12)
local tabs={};local selected="Outing"
for i,name in ipairs({"Outing","Stamps","Clues"}) do
 local b=Instance.new("TextButton");b.Name=name;b.Text=name;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.Position=UDim2.fromOffset(22+(i-1)*90,61);b.Size=UDim2.fromOffset(84,36);b.BorderSizePixel=0;b.Parent=panel;round(b,10);tabs[name]=b
end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(22,104);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local activeRows={}
local function item(id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local d=workspace:FindFirstChild("Daily");local offset=d and d:GetAttribute("DayOffsetHours") or 9
 return math.floor((workspace:GetServerTimeNow()-offset*3600)/86400)
end
local function unlocked(area)
 local boundary=workspace:FindFirstChild("Boundary");local need=boundary and boundary:GetAttribute("Need") or 10
 if area=="village" then return (p:GetAttribute("Found_forest") or 0)>=need end
 if area=="domaine" then return (p:GetAttribute("Found_village") or 0)>=need end
 return true
end
local function availability(entry)
 if not unlocked(entry.area) then return false,entry.area=="village" and "Find 10 forest squirrels to open the Rue." or "Find 10 Rue squirrels to open the Château." end
 if entry.item and item(entry.item)<=0 then return false,"Needs your "..({slingshot="slingshot",ziphandle="zipline handle",glider="hang glider"})[entry.item].." from the Acorn Store." end
 return true,entry.hint
end
local function row(title,body,icon,status,done,height)
 local width=scroll.AbsoluteSize.X-(icon and 69 or 12)-19
 local bodyHeight=game:GetService("TextService"):GetTextSize(body,13,Enum.Font.Gotham,Vector2.new(width,1000)).Y
 height=math.max(height or 103,bodyHeight+61)
 local r=Instance.new("Frame");r.Name=title;r.Size=UDim2.new(1,-5,0,height or 103);r.BackgroundColor3=done and C(229,235,211) or C(238,225,196);r.BorderSizePixel=0;r.LayoutOrder=#activeRows+1;r.Parent=scroll;round(r,11)
 if icon then local a=Art.draw(r,icon,55);a.Position=UDim2.fromOffset(6,10) end
 local tx=icon and 69 or 12
 local w=scroll.AbsoluteSize.X-tx-19
 local t=text(r,title,tx,9,w,23,16);t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextWrapped=false
 local b=text(r,body,tx,34,w,(height or 103)-59,13,MUTED,Enum.Font.Gotham);b.TextYAlignment=Enum.TextYAlignment.Top
 local s=text(r,status or "",tx,(height or 103)-22,w,17,11,done and GREEN or MUTED)
 table.insert(activeRows,r)
end
local function render()
 if not panel.Visible then return end
 local previous=scroll.CanvasPosition
 for _,r in ipairs(activeRows) do r:Destroy() end;table.clear(activeRows)
 local day=today();local n,total=0,0
 for _,e in ipairs(catalogue) do local d=item("passport_"..e.id);if d>0 then total+=1 end;if d==day then n+=1 end end
 local outings=item("passport_outings")
 heading.Text=outings>=5 and "My Golden Passport" or "My Passport"
 heading.TextSize=outings>=5 and 20 or 23
 rim.Color=outings>=5 and GOLD or C(118,80,46)
 summary.Text=p:GetAttribute("PassportReady") and string.format("Today %d/3  ·  %d/%d stamps  ·  %d outings",math.min(n,3),total,#catalogue,outings) or "Loading your stamps..."
 for name,b in pairs(tabs) do b.BackgroundColor3=name==selected and GREEN or C(234,220,189);b.TextColor3=name==selected and PAPER or INK end
 if selected=="Outing" then
  local done=item("passport_outing_last")==day
  summary.Text=done and string.format("Outing complete!  ·  %d %s",outings,outings==1 and "outing" or "outings") or string.format("Enjoy 3 different activities today  ·  %d/3",math.min(n,3))
  local entries={}
  for i,e in ipairs(catalogue) do
   local usable=availability(e)
   if usable then table.insert(entries,{entry=e,index=i,done=item("passport_"..e.id)==day}) end
  end
  table.sort(entries,function(a,b) if a.done~=b.done then return not a.done end return a.index<b.index end)
  for _,v in ipairs(entries) do local e=v.entry;row(e.name,e.hint,e.icon,v.done and "Stamped today" or (e.area=="forest" and "Great Acorn Forest" or e.area=="domaine" and "Château de l'Acorn" or e.area=="gold" and "Today's Golden Squirrel" or "Rue de Noisette"),v.done) end
 elseif selected=="Stamps" then
  for _,e in ipairs(catalogue) do local usable,hint=availability(e);local stamp=item("passport_"..e.id)>0
   row(e.name,hint,e.icon,stamp and "Collected · yours to keep" or usable and "Waiting for a memory" or "A future adventure",stamp)
  end
 else
  local daily=workspace:FindFirstChild("Daily")
  local goldName=daily and daily:GetAttribute("GoldName") or ""
  local goldArea=daily and daily:GetAttribute("GoldArea") or ""
  local found=item("daily_gold")==day
  row("Today's Golden Squirrel",goldName~="" and (tostring(goldName).." is hiding in "..tostring(goldArea)..".") or "Today's clue is getting ready. Check back in a moment.","rescue",found and "Found today!" or "One golden visitor each day",found)
  row("Grand Keeper of the Great Acorn","Be the first eligible player to complete all 44 squirrels that day. The fountain statue and permanent Hall of Fame honour the winner.","bell",p:GetAttribute("ChampionTitle") or "Visit the Hall of Fame beside the Château",false,138)
  row("A moment on canvas","The painter by the river can paint your portrait. Find your picture in the riverside gallery.","portrait",tostring(workspace:FindFirstChild("Shop") and workspace.Shop:GetAttribute("Price_portrait") or "?").." acorns · optional",false,112)
  row("A fresh page tomorrow","Outings and Golden Squirrel clues refresh together. Your collected stamps and golden cover stay with you.","book","No missed-day penalty",false,112)
  row("Your golden passport","Enjoy 3 different activities in a day to complete an outing. Complete 5 outings for a golden cover. Missed days never erase progress.",outings>=5 and "goldpassport" or "passport",string.format("%d/5 outings · %d/%d permanent stamps",math.min(outings,5),total,#catalogue),outings>=5,130)
 end
 scroll.CanvasPosition=previous
end
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 338 or 390,vp.X-24)
 local top=68
 local height=math.min(540,math.max(140,vp.Y-top-(mobile and 96 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 scroll.Size=UDim2.fromOffset(width-32,height-113)
 heading.Size=UDim2.fromOffset(width-78,27);summary.Size=UDim2.fromOffset(width-40,18)
 local tw=(width-52)/3
 for i,name in ipairs({"Outing","Stamps","Clues"}) do tabs[name].Position=UDim2.fromOffset(22+(i-1)*(tw+4),61);tabs[name].Size=UDim2.fromOffset(tw,36) end
 if panel.Visible then task.defer(render) end
end
local hidden={}
local suppressed={}
local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel")
 local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do
   if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then
    if suppressed[g]==nil then suppressed[g]=g.Enabled end
    g.Enabled=false
   end
  end
 else
  for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end
  table.clear(suppressed)
 end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels)
pg.ChildAdded:Connect(function() task.defer(coordinatePanels) end)
local openedAt=0
local function closePage()
 panel.Visible=false
 if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end
 for o,was in pairs(hidden) do if o.Parent then o.Visible=was end end;table.clear(hidden)
end
local function openPage()
 pg:SetAttribute("OpenPanel","passport")
 for _,g in ipairs(pg:GetChildren()) do
  if g.Name=="ShopPanel" then g.Enabled=false end
  -- Leave established controls in place, while removing labels behind the open page.
  if g.Name=="DailyGui" then local pill=g:FindFirstChild("GoldPill");if pill and pill.Visible then hidden[pill]=true;pill.Visible=false end end
 end
 panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function() if panel.Visible then closePage() else openPage() end end)
close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function() selected=name;scroll.CanvasPosition=Vector2.zero;render() end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  if g.Enabled and panel.Visible then closePage() end
  g:GetPropertyChangedSignal("Enabled"):Connect(function() if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren()) do watchGui(g) end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name:sub(1,14)=="Item_passport_" or name:sub(1,6)=="Found_" or name=="PassportReady" or name=="ChampionTitle") and not pending then
  pending=true;task.defer(function() pending=false;render() end)
 end
end)
local function cameraChanged() fit();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed) if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then closePage() end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage() end
end)
task.spawn(function() while gui.Parent do task.wait(30);if panel.Visible then render() end end end)
print("Passport: responsive journal ready")
