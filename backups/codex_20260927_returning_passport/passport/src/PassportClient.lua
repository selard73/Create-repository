local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local H=game:GetService("HttpService")
local TextService=game:GetService("TextService")
local p=Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))
local Art=require(F:WaitForChild("PassportVisuals"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,PINE=C(255,246,220),C(84,40,10),C(40,24,10),C(240,196,110),C(27,66,43)
local accents={C(79,106,83),C(176,102,66),C(186,137,48),C(120,86,60),C(143,107,66)}
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,col,w,tr)local s=Instance.new("UIStroke");s.Color=col;s.Thickness=w;s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function gradient(o,a,b,rot)local g=Instance.new("UIGradient");g.Color=ColorSequence.new(a,b);g.Rotation=rot or 90;g.Parent=o;return g end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.ZIndex=parent.ZIndex+1;l.Parent=parent;return l
end
local function gildedHeading(label,dark)
 -- Keep glyphs crisp at phone sizes; gold glow belongs on the surrounding frames.
 label.TextStrokeTransparency=1
 if dark then label.TextColor3=C(255,225,128) end
end
local function button(parent,name,txt,x,y,w,h)
 local b=Instance.new("TextButton");b.Name=name;b.Text=txt;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.TextColor3=INK;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.BorderSizePixel=0;b.BackgroundColor3=PAPER;b.ZIndex=parent.ZIndex+1;b.Parent=parent;round(b,11);return b
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-14,0,68);panel.BackgroundColor3=C(255,255,255);panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,18)
panel.BackgroundColor3=PAPER
-- Match the existing Baguette Chase: cream, brown type, one travelling gold rim.
local edge=stroke(panel,C(255,255,255),4)
local ring=Instance.new("UIGradient");ring.Name="Ring"
ring.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(196,136,36)),ColorSequenceKeypoint.new(.55,C(228,170,58)),ColorSequenceKeypoint.new(.85,C(255,222,120)),ColorSequenceKeypoint.new(1,C(255,250,215))});ring.Parent=edge
RunService.RenderStepped:Connect(function(dt)if panel.Visible then ring.Rotation=(ring.Rotation+dt*120)%360 end end)
local header=Instance.new("Frame");header.Name="Cover";header.Position=UDim2.fromOffset(5,5);header.Size=UDim2.new(1,-10,0,47);header.BackgroundTransparency=1;header.BorderSizePixel=0;header.ZIndex=2;header.Parent=panel
local heading=text(header,"Official Passport",49,3,230,24,21,PAPER);heading.TextWrapped=false;heading.TextTruncate=Enum.TextTruncate.AtEnd
gildedHeading(heading,false);heading.TextColor3=INK;heading.TextXAlignment=Enum.TextXAlignment.Center
local summary=text(header,"French Squirrel Country",50,26,250,15,11,C(110,70,30),Enum.Font.GothamMedium);summary.TextXAlignment=Enum.TextXAlignment.Center;summary.TextWrapped=false;summary.TextTruncate=Enum.TextTruncate.AtEnd
local close=button(header,"Close","×",0,3,40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-3,0,3);close.TextColor3=INK;close.BackgroundColor3=C(236,226,206);close.BackgroundTransparency=0;close.TextSize=25
local back=button(header,"Back","‹",3,3,40,40);back.TextColor3=INK;back.BackgroundColor3=C(236,226,206);back.BackgroundTransparency=0;back.TextSize=27;back.Visible=false
local tabs={};local selected="Outings";local detail=nil;local returnScroll=Vector2.zero
for _,name in ipairs({"Outings","Completed","Clues"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(14,93);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.ZIndex=3;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,9);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local rows={};local journal={};local render,fit
local function refreshData()
 local ok,v=pcall(function()return H:JSONDecode(p:GetAttribute("PassportJournal") or "{}")end)
 journal=ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function item(id)return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function isPending(id)
 local b=journal._batch and journal._batch.data or {}
 return table.find(J.ids(b.ids),id) and not table.find(J.ids(b.done),id)
end
local function stamp(parent,record,accent)
 local seal=Instance.new("Frame");seal.Name="PassportStamp";seal.Size=UDim2.fromOffset(63,35);seal.Position=UDim2.new(0,9,1,-44);seal.BackgroundTransparency=1;seal.Rotation=-11;seal.ZIndex=5;seal.Parent=parent;round(seal,17);stroke(seal,accent,1.5,.48)
 local inner=Instance.new("Frame");inner.Size=UDim2.new(1,-5,1,-5);inner.Position=UDim2.fromOffset(2.5,2.5);inner.BackgroundTransparency=1;inner.Parent=seal;round(inner,15);stroke(inner,accent,1,.7)
 local a=text(seal,"COMPLETED",0,4,63,13,8,accent,Enum.Font.GothamBold);a.TextXAlignment=Enum.TextXAlignment.Center;a.TextTransparency=.2
 local visited=record.data.visited or record.at
 local date=visited>1000000 and os.date("!%d %b %Y",math.floor(visited)) or "SOUVENIR"
 local b=text(seal,date,0,18,63,10,7,accent,Enum.Font.GothamBold);b.TextXAlignment=Enum.TextXAlignment.Center;b.TextTransparency=.3
end
local function artTile(parent,id,size,accent,record)
 local tile=Instance.new("Frame");tile.Name="PortraitTile";tile.Size=UDim2.fromOffset(size,size);tile.Position=UDim2.fromOffset(10,10);tile.BackgroundColor3=C(255,255,255);tile.BorderSizePixel=0;tile.ZIndex=4;tile.ClipsDescendants=true;tile.Parent=parent;round(tile,12)
 gradient(tile,accent:Lerp(C(255,255,255),.78),accent:Lerp(PAPER,.5),45);stroke(tile,accent,1,.4)
 local art=Art.draw(tile,id,size,record);art.Position=UDim2.fromOffset(0,0)
 return tile
end
local function addRow(id,title,body,record,onTap,expanded,footer)
 local width=math.max(180,scroll.AbsoluteSize.X-5)
 local accent=accents[(#rows%#accents)+1]
 local mobile=UIS.TouchEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500)
 local tx=expanded and 16 or 81;local y=expanded and (mobile and 82 or 98) or 34;local fontSize=expanded and (mobile and 13 or 14) or 13
 local bodyWidth=width-tx-(expanded and 16 or 13);local bh=TextService:GetTextSize(body,fontSize,Enum.Font.BuilderSans,Vector2.new(bodyWidth,10000)).Y+5
 local bodyHeight=(record or expanded) and bh or math.min(34,bh)
 local height=math.max(record and 113 or expanded and (mobile and 137 or 165) or 102,y+bodyHeight+(expanded and 16 or record and 12 or 30))
 local r=Instance.new(onTap and "TextButton" or "Frame");r.Name="Entry_"..id;r.Size=UDim2.new(1,-5,0,height);r.LayoutOrder=#rows+1;r.BackgroundColor3=C(255,255,255);r.BorderSizePixel=0;r.ZIndex=3;r.Parent=scroll;round(r,13)
 if r:IsA("TextButton")then r.Text="";r.AutoButtonColor=true end
 r.BackgroundColor3=C(255,250,234);stroke(r,C(220,170,59),1,expanded and .2 or .35)
 if expanded then
  local rim=Instance.new("Frame");rim.Name="DescriptionGoldGlow";rim.BackgroundTransparency=1;rim.Position=UDim2.fromOffset(2,2);rim.Size=UDim2.new(1,-4,1,-4);rim.ZIndex=3;rim.Parent=r;round(rim,11)
  stroke(rim,C(255,205,79),expanded and 5 or 4,expanded and .83 or .91)
  local foil=Instance.new("Frame");foil.Name="DescriptionGoldEdge";foil.BackgroundTransparency=1;foil.Position=UDim2.fromOffset(1,1);foil.Size=UDim2.new(1,-2,1,-2);foil.ZIndex=3;foil.Parent=r;round(foil,12)
  gradient(stroke(foil,GOLD,1,expanded and .24 or .5),C(255,226,138),C(205,144,36),35)
 end
 local tile=artTile(r,id,expanded and (mobile and 60 or 76) or 60,accent,record)
 if expanded then tile.Position=UDim2.fromOffset(14,12)end
 local titleX=expanded and (mobile and 88 or 106) or tx
 local titleLabel=text(r,title,titleX,expanded and 13 or 9,width-titleX-(onTap and 29 or 16),expanded and (mobile and 56 or 66) or 23,expanded and (mobile and 18 or 20) or 16)
 gildedHeading(titleLabel,false)
 if not expanded then titleLabel.TextWrapped=false;titleLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 local bodyLabel=text(r,body,tx,y,bodyWidth,bodyHeight,fontSize,MUTED,Enum.Font.BuilderSans);bodyLabel.Name="Description";bodyLabel.TextYAlignment=Enum.TextYAlignment.Top
 if expanded then bodyLabel.TextXAlignment=Enum.TextXAlignment.Center end
 if not record and not expanded then bodyLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 if record then stamp(r,record,accent)
 elseif not expanded then
  local foot=text(r,footer or (onTap and "Tap for details" or ""),tx,height-25,width-tx-12,18,10,accent,Enum.Font.GothamBold);foot.TextWrapped=false;foot.TextTruncate=Enum.TextTruncate.AtEnd
 end
 if onTap then local arrow=text(r,"›",width-30,8,20,26,24,accent);arrow.TextXAlignment=Enum.TextXAlignment.Center;r.Activated:Connect(onTap)end
 rows[#rows+1]=r;return r
end
local function openDetail(id)
 if selected=="Completed" or (journal[id] and not isPending(id)) then return end
 returnScroll=scroll.CanvasPosition;detail=id;scroll.CanvasPosition=Vector2.zero;fit();render()
end
local moreBusy=false
render=function()
 if not panel.Visible then return end
 refreshData();local previous=scroll.CanvasPosition
 -- A newly finished outing closes its description and moves to Completed.
 if detail and journal[detail] and not isPending(detail) then detail=nil;fit()end
 for _,r in ipairs(rows)do r:Destroy()end;table.clear(rows)
 local total=0;for _,e in ipairs(catalogue)do if journal[e.id]then total+=1 end end
 local outings=item("passport_outings")
 heading.Text=detail and "How to do it" or "Official Passport";heading.TextSize=detail and 19 or 21
 summary.Text=detail and J.byId[detail].name or "French Squirrel Country"
 for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail end
 back.Visible=detail~=nil
 if detail then
  local e=J.byId[detail];addRow(e.id,e.name,e.detail,nil,nil,true,"Complete this outing to earn its stamp")
 elseif not p:GetAttribute("PassportReady")then
  addRow("find","Opening your Passport","Loading your progress...")
 elseif selected=="Outings" then
  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  summary.Text=string.format("%d of %d completed · %d left to explore",#done,#ids,#ids-#done)
  if #ids==0 then
   summary.Text=total>=21 and "21 adventures completed" or "More adventures to unlock"
   local need=workspace.Boundary:GetAttribute("Need") or 10
   local hint=(p:GetAttribute("Found_forest") or 0)<need and ("Find "..need.." forest squirrels to unlock the Rue and its outings.") or (p:GetAttribute("Found_village") or 0)<need and ("Find "..need.." squirrels on the Rue to unlock the château and its outings.") or "Bring a friend into this server to play the baguette chase. Check Clues for today's Golden Squirrel."
   addRow("keeper",total>=21 and "All outings completed!" or "Keep exploring",total>=21 and "Beat your best race time, take on the daily question, or check Clues for today's Golden Squirrel." or hint,nil,nil,true,"Your results are saved in Completed")
  end
  for _,id in ipairs(ids)do if not table.find(done,id)then local e=J.byId[id];addRow(e.id,e.name,e.hint,nil,function()openDetail(id)end)end end
  if J.batchDone(batch)then
   summary.Text=total>=21 and "21 adventures completed" or string.format("%d of %d outings completed",#done,#ids)
   local card=Instance.new("Frame");card.Name="BatchComplete";card.BackgroundColor3=C(255,255,255);card.BorderSizePixel=0;card.Size=UDim2.new(1,-5,0,104);card.LayoutOrder=1;card.ZIndex=3;card.Parent=scroll;round(card,13);gradient(card,C(255,251,218),C(246,225,157));stroke(card,GOLD,1,.3);rows[#rows+1]=card
   text(card,"Well done, Squirrel Adventurer!",13,7,scroll.AbsoluteSize.X-31,25,17,INK)
   text(card,total>=21 and "Check Clues for daily finds and bonus challenges." or "Ready to explore more of Squirrel Country?",13,32,scroll.AbsoluteSize.X-31,18,11,MUTED,Enum.Font.Gotham)
   local b=button(card,"CompleteMore",moreBusy and "Opening..." or total>=21 and "Open Clues  ›" or "Explore more  ›",12,55,280,40);b.Size=UDim2.new(1,-24,0,40);b.BackgroundColor3=C(255,255,255);gradient(b,C(255,223,104),C(234,172,37));stroke(b,C(167,110,25),1,.4)
   b.Activated:Connect(function()
    if total>=21 then selected="Clues";scroll.CanvasPosition=Vector2.zero;render();return end
    if moreBusy then return end;moreBusy=true;b.Text="Opening..."
    local ok,accepted,message=pcall(function()return F.PassportAction:InvokeServer("more")end);moreBusy=false
    if ok and accepted then scroll.CanvasPosition=Vector2.zero;render()else b.Text=message or "Try again in a moment" end
   end)
  end
 elseif selected=="Completed"then
  summary.Text=string.format("%d %s completed",total,total==1 and "adventure" or "adventures")
  if total==0 then addRow("find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end
  local entries={};for _,e in ipairs(catalogue)do if journal[e.id]then entries[#entries+1]=e end end
  table.sort(entries,function(a,b)return(journal[a.id].data.visited or journal[a.id].at)>(journal[b.id].data.visited or journal[b.id].at)end)
  for _,e in ipairs(entries)do addRow(e.id,e.name,J.describe(e.id,journal[e.id],p.DisplayName),journal[e.id])end
 else
  summary.Text="Daily finds & bonus challenges"
  local daily=workspace:FindFirstChild("Daily");local goldName=daily and daily:GetAttribute("GoldName")or"";local goldArea=daily and daily:GetAttribute("GoldArea")or""
  addRow("gold","Today's Golden Squirrel",goldName~="" and(goldName.." is hiding in "..goldArea..".")or"Today's clue is getting ready.",nil,not journal.gold and function()openDetail("gold")end or nil,false,"A fresh Golden Squirrel each day")
  local e=J.byId.keeper
  addRow("keeper",e.name,journal.keeper and "Your honour is recorded in Completed. Visit your statue at the Hall of Fame!" or e.hint,nil,not journal.keeper and function()openDetail("keeper")end or nil,false,"BONUS · never holds up your outings")
  addRow("gold","Your golden cover","Enjoy three different activities in a day. Five such days earn a golden cover. Missing a day never takes progress away.\n\nProgress: "..math.min(outings,5).." / 5 days.",nil,nil,true)
 end
 scroll.CanvasPosition=previous
end
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 350 or 412,vp.X-28)
 local height=math.min(560,math.max(140,vp.Y-68-(mobile and 92 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 local top=detail and 60 or 93
 scroll.Position=UDim2.fromOffset(14,top);scroll.Size=UDim2.fromOffset(width-25,height-top-10)
 local hx=49
 heading.Position=UDim2.fromOffset(hx,3);summary.Position=UDim2.fromOffset(hx,26)
 heading.Size=UDim2.fromOffset(width-hx-62,24);summary.Size=UDim2.fromOffset(width-hx-62,15)
 local tw=(width-36)/3
 for i,name in ipairs({"Outings","Completed","Clues"})do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
end
back.Activated:Connect(function()detail=nil;fit();render();scroll.CanvasPosition=returnScroll end)

local suppressed={};local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel");local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then if suppressed[g]==nil then suppressed[g]=g.Enabled end;g.Enabled=false end end
 else for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end;table.clear(suppressed) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
local openedAt=0
local function closePage()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end end
local function openPage()
 pg:SetAttribute("OpenPanel","passport");panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function()if panel.Visible then closePage() else openPage() end end);close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  g:GetPropertyChangedSignal("Enabled"):Connect(function()if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren())do watchGui(g)end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings") and not pending then pending=true;task.defer(function()pending=false;render()end)end
end)
local cameraConnection
local function cameraChanged()
 if cameraConnection then cameraConnection:Disconnect() end;fit()
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()fit();render()end)end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed)if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB)then closePage()end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") or char:GetAttribute("MillRiding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage()end
end)
task.spawn(function()while gui.Parent do task.wait(30);if panel.Visible and selected=="Clues" then render()end end end)
print("Passport: outings and completed stamps ready")
