local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local H=game:GetService("HttpService")
local TextService=game:GetService("TextService")
local p=Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))
local NORMAL=0;for _,e in ipairs(catalogue)do if not e.bonus then NORMAL+=1 end end
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
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,68);panel.BackgroundColor3=C(255,255,255);panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,18)
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
for _,name in ipairs({"Outings","Completed","Clues","Wardrobe"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
-- per-city pages once a second city is opened: French Squirrel Country | Porto Nocciola (Item_porto, awarded on the first landing)
local CITIES={{id="france",name="French Squirrel Country"},{id="italy",name="Porto Nocciola"}};local city="france";local cityTabs={}
for _,c in ipairs(CITIES)do cityTabs[c.id]=button(panel,"City_"..c.id,c.name,0,90,95,26);cityTabs[c.id].TextSize=12;cityTabs[c.id].Visible=false end
local function hasCities()return (tonumber(p:GetAttribute("Item_porto")) or 0)>=1 end
local function cityOf(id)local e=J.byId[id];return (e and e.area=="porto") and "italy" or "france" end
local function showCities()return hasCities() and not detail and selected~="Wardrobe" end
tabs.Wardrobe.Visible=false
local wardrobe=Instance.new("Frame");wardrobe.Name="WardrobeContent";wardrobe.BackgroundTransparency=1;wardrobe.Visible=false;wardrobe.ZIndex=3;wardrobe.Parent=panel
local function hasWardrobe()return pg:GetAttribute("HasWardrobe")==true end
-- Warm leather, brass straps and a pine luggage tag, drawn crisply at small sizes.
local case=Instance.new("Frame");case.Name="Suitcase";case.Size=UDim2.fromOffset(27,19);case.Position=UDim2.new(.5,-49,.5,-7);case.BackgroundColor3=C(183,98,48);case.BorderSizePixel=0;case.Parent=tabs.Wardrobe;round(case,4);stroke(case,C(121,65,29),1)
gradient(case,C(220,151,77),C(166,80,36))
local handle=Instance.new("Frame");handle.Size=UDim2.fromOffset(11,6);handle.Position=UDim2.fromOffset(8,-5);handle.BackgroundTransparency=1;handle.Parent=case;round(handle,2);stroke(handle,C(121,65,29),2)
for _,x in ipairs({5,20})do local strap=Instance.new("Frame");strap.Size=UDim2.fromOffset(3,19);strap.Position=UDim2.fromOffset(x,0);strap.BackgroundColor3=C(255,211,111);strap.BorderSizePixel=0;strap.Parent=case end
local tag=Instance.new("Frame");tag.Size=UDim2.fromOffset(7,9);tag.Position=UDim2.fromOffset(14,4);tag.Rotation=14;tag.BackgroundColor3=PINE;tag.BorderSizePixel=0;tag.Parent=case;round(tag,2)
tabs.Wardrobe.Text="      Wardrobe"
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(14,93);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.None;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.ZIndex=3;scroll.Parent=panel
-- Place cards in paired rows when the middle of the screen has enough room.
-- Each pair uses its tallest card, so completed descriptions and stamps never overlap.
local columns,contentWidth,rowWidth=1,320,315
local function arrangeRows(list)
 local y=3
 for first=1,#list,columns do
  local height=0
  for col=0,columns-1 do
   local card=list[first+col]
   if card then
    card.Position=UDim2.fromOffset(3+col*(rowWidth+12),y)
    card.Size=UDim2.fromOffset(rowWidth,card.Size.Y.Offset)
    height=math.max(height,card.Size.Y.Offset)
   end
  end
  y+=height+12
 end
 scroll.CanvasSize=UDim2.fromOffset(0,math.max(0,y-9))
end
local rows={};local journal={};local render,fit
local function refreshData()
 local ok,v=pcall(function()return H:JSONDecode(p:GetAttribute("PassportJournal") or "{}")end)
 journal=ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function item(id)return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function isPending(id)
 local b=journal._batch and journal._batch.data or {}
 return not journal[id] and table.find(J.ids(b.ids),id) and not table.find(J.ids(b.done),id)
end
local function stamp(parent,record,accent)
 local seal=Instance.new("Frame");seal.Name="PassportStamp";seal.Size=UDim2.fromOffset(63,35);seal.Position=UDim2.new(0,9,1,-44);seal.BackgroundTransparency=1;seal.Rotation=-11;seal.ZIndex=5;seal.Parent=parent;round(seal,17);stroke(seal,accent,1.5,.48)
 local inner=Instance.new("Frame");inner.Size=UDim2.new(1,-5,1,-5);inner.Position=UDim2.fromOffset(2.5,2.5);inner.BackgroundTransparency=1;inner.Parent=seal;round(inner,15);stroke(inner,accent,1,.7)
 local a=text(seal,"COMPLETED",0,4,63,13,8,accent,Enum.Font.GothamBold);a.TextXAlignment=Enum.TextXAlignment.Center;a.TextTransparency=.2
 local visited=record.data.visited or record.at
 local date=visited>1000000 and os.date("!%d %b %Y",math.floor(visited)) or "EARLIER VISIT"
 local b=text(seal,date,0,18,63,10,7,accent,Enum.Font.GothamBold);b.TextXAlignment=Enum.TextXAlignment.Center;b.TextTransparency=.3
end
local function artTile(parent,id,size,accent,record)
 local tile=Instance.new("Frame");tile.Name="PortraitTile";tile.Size=UDim2.fromOffset(size,size);tile.Position=UDim2.fromOffset(10,10);tile.BackgroundColor3=C(255,255,255);tile.BorderSizePixel=0;tile.ZIndex=4;tile.ClipsDescendants=true;tile.Parent=parent;round(tile,12)
 gradient(tile,accent:Lerp(C(255,255,255),.78),accent:Lerp(PAPER,.5),45);stroke(tile,accent,1,.4)
 local art=Art.draw(tile,id,size,record);art.Position=UDim2.fromOffset(0,0)
 return tile
end
local function addRow(id,title,body,record,onTap,expanded,footer)
 local width=rowWidth
 local accent=accents[(#rows%#accents)+1]
 local mobile=UIS.TouchEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500)
 local wideDetail=expanded and width>=520
 local tx=wideDetail and 112 or expanded and 16 or 81
 local y=wideDetail and 47 or expanded and (mobile and 82 or 98) or 34
 local fontSize=expanded and (mobile and 13 or 14) or 13
 local bodyWidth=width-tx-(expanded and 16 or 13);local bh=TextService:GetTextSize(body,fontSize,Enum.Font.BuilderSans,Vector2.new(bodyWidth,10000)).Y+5
 local bodyHeight=(record or expanded) and bh or math.min(34,bh)
 local height=math.max(record and 113 or expanded and (mobile and 137 or 165) or 102,y+bodyHeight+(expanded and 16 or record and 12 or 30))
 if wideDetail then height=math.max(126,y+bodyHeight+20)end
 local r=Instance.new(onTap and "TextButton" or "Frame");r.Name="Entry_"..id;r.Size=UDim2.fromOffset(width,height);r.LayoutOrder=#rows+1;r.BackgroundColor3=C(255,255,255);r.BorderSizePixel=0;r.ZIndex=3;r.Parent=scroll;round(r,13)
 if r:IsA("TextButton")then r.Text="";r.AutoButtonColor=true end
 r.BackgroundColor3=C(255,250,234);stroke(r,C(220,170,59),1,expanded and .2 or .35)
 if expanded then
  local rim=Instance.new("Frame");rim.Name="DescriptionGoldGlow";rim.BackgroundTransparency=1;rim.Position=UDim2.fromOffset(2,2);rim.Size=UDim2.new(1,-4,1,-4);rim.ZIndex=3;rim.Parent=r;round(rim,11)
  stroke(rim,C(255,205,79),expanded and 5 or 4,expanded and .83 or .91)
  local foil=Instance.new("Frame");foil.Name="DescriptionGoldEdge";foil.BackgroundTransparency=1;foil.Position=UDim2.fromOffset(1,1);foil.Size=UDim2.new(1,-2,1,-2);foil.ZIndex=3;foil.Parent=r;round(foil,12)
  gradient(stroke(foil,GOLD,1,expanded and .24 or .5),C(255,226,138),C(205,144,36),35)
 end
 local tile=artTile(r,id,wideDetail and 80 or expanded and (mobile and 60 or 76) or 60,accent,record)
 if expanded then tile.Position=UDim2.fromOffset(14,wideDetail and math.floor((height-80)/2) or 12)end
 local titleX=wideDetail and tx or expanded and (mobile and 88 or 106) or tx
 local titleLabel=text(r,title,titleX,expanded and 13 or 9,width-titleX-(onTap and 29 or 16),wideDetail and 28 or expanded and (mobile and 56 or 66) or 23,expanded and (mobile and 18 or 20) or 16)
 gildedHeading(titleLabel,false)
 if not expanded then titleLabel.TextWrapped=false;titleLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 local bodyLabel=text(r,body,tx,y,bodyWidth,bodyHeight,fontSize,MUTED,Enum.Font.BuilderSans);bodyLabel.Name="Description";bodyLabel.TextYAlignment=Enum.TextYAlignment.Top
 if expanded then bodyLabel.TextXAlignment=wideDetail and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center end
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
 if selected=="Wardrobe" and not hasWardrobe()then selected="Outings";fit()end
 refreshData();local previous=scroll.CanvasPosition
 -- A newly finished outing closes its description and moves to Completed.
 if detail and journal[detail] and not isPending(detail) then detail=nil;fit()end
 for _,r in ipairs(rows)do r:Destroy()end;table.clear(rows)
 local total=0;for _,e in ipairs(catalogue)do if journal[e.id]then total+=1 end end
 local outings=item("passport_outings")
 heading.Text=detail and "How to do it" or "Official Passport";heading.TextSize=detail and 19 or 21
 summary.Text=detail and J.byId[detail].name or "French Squirrel Country"
 for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail and (name~="Wardrobe" or hasWardrobe()) end
 for id,b in pairs(cityTabs)do b.Visible=showCities();b.BackgroundColor3=id==city and C(245,170,60) or C(236,226,206);b.TextColor3=INK end
 wardrobe.Visible=not detail and selected=="Wardrobe";scroll.Visible=not wardrobe.Visible
 back.Visible=detail~=nil
 if detail then
  local e=J.byId[detail];addRow(e.id,e.name,e.detail,nil,nil,true,"Complete this outing to earn its stamp")
 elseif selected=="Wardrobe"then
  summary.Text="Your outfits & accessories"
 elseif not p:GetAttribute("PassportReady")then
  addRow("find","Opening your Passport","Loading your progress...")
 elseif selected=="Outings" then
  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  if showCities() then local fi,fd={},{} for _,id in ipairs(ids)do if cityOf(id)==city then fi[#fi+1]=id end end for _,id in ipairs(done)do if cityOf(id)==city then fd[#fd+1]=id end end ids,done=fi,fd end
  summary.Text=string.format("%d of %d completed · %d left to explore",#done,#ids,#ids-#done)
  if #ids==0 and showCities() and city=="italy" then
   summary.Text="Porto Nocciola";addRow("porto","Porto Nocciola is new","Your Italian outings are the boat trip, the falls, the parachute landing and the arrival itself. More arrive as the harbour grows.",nil,nil,true,"More to come")
  elseif #ids==0 then
   summary.Text=total>=NORMAL and (NORMAL.." adventures completed") or "More adventures to unlock"
   local need=workspace.Boundary:GetAttribute("Need") or 10
   local hint=(p:GetAttribute("Found_forest") or 0)<need and ("Find "..need.." forest squirrels to unlock the Rue and its outings.") or (p:GetAttribute("Found_village") or 0)<need and ("Find "..need.." squirrels on the Rue to unlock the château and its outings.") or "Bring a friend into this server to play the baguette chase. Check Clues for today's Golden Squirrel."
   addRow("keeper",total>=NORMAL and "All outings completed!" or "Keep exploring",total>=NORMAL and "Beat your best race time, take on the daily question, or check Clues for today's Golden Squirrel." or hint,nil,nil,true,"Your results are saved in Completed")
  end
  for _,id in ipairs(ids)do if not journal[id] and not table.find(done,id)then local e=J.byId[id];addRow(e.id,e.name,e.hint,nil,function()openDetail(id)end)end end
  if J.batchDone(batch) and not (showCities() and city=="italy" and #ids==0) then
   summary.Text=total>=NORMAL and (NORMAL.." adventures completed") or string.format("%d of %d outings completed",#done,#ids)
   local card=Instance.new("Frame");card.Name="BatchComplete";card.BackgroundColor3=C(255,255,255);card.BorderSizePixel=0;card.Size=UDim2.new(1,-5,0,104);card.LayoutOrder=1;card.ZIndex=3;card.Parent=scroll;round(card,13);gradient(card,C(255,251,218),C(246,225,157));stroke(card,GOLD,1,.3);rows[#rows+1]=card
   text(card,"Well done, Squirrel Adventurer!",13,7,rowWidth-26,25,17,INK)
   text(card,total>=NORMAL and "Check Clues for daily finds and bonus challenges." or "Ready to explore more of Squirrel Country?",13,32,rowWidth-26,18,11,MUTED,Enum.Font.Gotham)
   local b=button(card,"CompleteMore",moreBusy and "Opening..." or total>=NORMAL and "Open Clues  ›" or "Explore more  ›",12,55,280,40);b.Size=UDim2.new(1,-24,0,40);b.BackgroundColor3=C(255,255,255);gradient(b,C(255,223,104),C(234,172,37));stroke(b,C(167,110,25),1,.4)
   b.Activated:Connect(function()
    if total>=NORMAL then selected="Clues";scroll.CanvasPosition=Vector2.zero;render();return end
    if moreBusy then return end;moreBusy=true;b.Text="Opening..."
    local ok,accepted,message=pcall(function()return F.PassportAction:InvokeServer("more")end);moreBusy=false
    if ok and accepted then scroll.CanvasPosition=Vector2.zero;render()else b.Text=message or "Try again in a moment" end
   end)
  end
 elseif selected=="Completed"then
  summary.Text=string.format("%d %s completed",total,total==1 and "adventure" or "adventures")
  local entries={};for _,e in ipairs(catalogue)do if journal[e.id] and (not showCities() or cityOf(e.id)==city) then entries[#entries+1]=e end end
  if showCities() then summary.Text=string.format("%d %s completed in %s",#entries,#entries==1 and "adventure" or "adventures",city=="italy" and "Porto Nocciola" or "French Squirrel Country") end
  if #entries==0 then addRow((showCities() and city=="italy") and "porto" or "find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end
  table.sort(entries,function(a,b)return(journal[a.id].data.visited or journal[a.id].at)>(journal[b.id].data.visited or journal[b.id].at)end)
  for _,e in ipairs(entries)do addRow(e.id,e.name,J.describe(e.id,journal[e.id],p.DisplayName),journal[e.id])end
 else
  if showCities() and city=="italy" then
   summary.Text="Porto Nocciola · coming soon"
   addRow("porto","Italian clues: coming soon","Italian squirrels and a daily Italian question are on their way to Porto Nocciola. Check back once the harbour opens.",nil,nil,true,"Coming soon")
  else
  summary.Text="Daily finds & bonus challenges"
  local function questionRow(board,title)
   local state=pg:GetAttribute(board=="forest" and "QuestionForest" or "QuestionPoste")
   local body=state=="open" and "A fresh question is ready. A right answer earns 25 acorns and a place in the grand-prize draw." or state=="right" and "Answered correctly! Check back for the prize draw. New questions arrive at 6pm Eastern." or state=="wrong" and "Answered for today. Try the next question at 6pm Eastern." or "Checking today's question… Tap to open it."
   addRow(board=="forest" and "riddle" or "book",title,body,nil,function()local t=RS:FindFirstChild("QuestionToggle");if t then t:Fire(board)end end,false,state=="open" and "Answer today's question  ›" or "View question & reset time  ›")
  end
  questionRow("forest","Daily forest question")
  local need=(workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need"))or 10
  if (p:GetAttribute("Found_forest")or 0)>=need then questionRow("poste","La Poste question")end
  local daily=workspace:FindFirstChild("Daily");local goldName=daily and daily:GetAttribute("GoldName")or"";local goldArea=daily and daily:GetAttribute("GoldArea")or""
  addRow("gold","Today's Golden Squirrel",goldName~="" and(goldName.." is hiding in "..goldArea..".")or"Today's clue is getting ready.",nil,not journal.gold and function()openDetail("gold")end or nil,false,"A fresh Golden Squirrel each day")
  local e=J.byId.keeper
  addRow("keeper",e.name,journal.keeper and "Your honour is recorded in Completed. Visit your statue at the Hall of Fame!" or e.hint,nil,not journal.keeper and function()openDetail("keeper")end or nil,false,"BONUS · never holds up your outings")
  addRow("gold","Your golden cover","Enjoy three different activities in a day. Five such days earn a golden cover. Missing a day never takes progress away.\n\nProgress: "..math.min(outings,5).." / 5 days.",nil,nil,true)
  end
 end
 arrangeRows(rows)
 scroll.CanvasPosition=previous
end
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 -- Keep the HUD and movement/reset controls outside the page on every screen.
 local topSafe,bottomSafe=68,mobile and 92 or 84
 local width=math.min(960,math.floor(mobile and vp.X-28 or vp.X*.9))
 local availableHeight=math.max(1,vp.Y-topSafe-bottomSafe)
 local height=math.min(620,availableHeight)
 panel.Position=UDim2.new(.5,0,0,topSafe+math.floor((availableHeight-height)/2))
 panel.Size=UDim2.fromOffset(width,height)
 local sub=showCities()
 local top=detail and 60 or (sub and 124 or 93)
 contentWidth=width-28
 columns=not detail and contentWidth>=560 and 2 or 1
 rowWidth=math.floor((contentWidth-6-(columns-1)*12)/columns)
 scroll.Position=UDim2.fromOffset(14,top);scroll.Size=UDim2.fromOffset(contentWidth,math.max(1,height-top-10))
 local hx=49
 heading.Position=UDim2.fromOffset(hx,3);summary.Position=UDim2.fromOffset(hx,26)
 heading.Size=UDim2.fromOffset(width-hx-62,24);summary.Size=UDim2.fromOffset(width-hx-62,15)
 wardrobe.Position=UDim2.fromOffset(14,93);wardrobe.Size=UDim2.fromOffset(contentWidth,math.max(1,height-103))
 local names=hasWardrobe() and {"Outings","Completed","Clues","Wardrobe"}or{"Outings","Completed","Clues"}
 local tw=(width-28-(#names-1)*4)/#names
 for i,name in ipairs(names)do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
 local cw=(width-28-4)/2
 for i,c in ipairs(CITIES)do cityTabs[c.id].Position=UDim2.fromOffset(14+(i-1)*(cw+4),90);cityTabs[c.id].Size=UDim2.fromOffset(cw,26);cityTabs[c.id].Visible=sub end
end
back.Activated:Connect(function()detail=nil;fit();render();scroll.CanvasPosition=returnScroll end)

local suppressed={};local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel");local quiet=active=="passport" or active=="shop" or active=="book" or active=="wardrobe" or active=="portrait" or active=="question"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then if suppressed[g]==nil then suppressed[g]=g.Enabled end;g.Enabled=false end end
 else for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end;table.clear(suppressed) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
pg:GetAttributeChangedSignal("HasWardrobe"):Connect(function()fit();render()end)
local openedAt=0
local function closePage()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end end
local function openPage()
 pg:SetAttribute("OpenPanel","passport");panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function()if panel.Visible then closePage() else openPage() end end);close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
for id,b in pairs(cityTabs) do b.Activated:Connect(function()city=id;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  g:GetPropertyChangedSignal("Enabled"):Connect(function()if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren())do watchGui(g)end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings" or name=="Item_porto") and not pending then pending=true;task.defer(function()pending=false;fit();render()end)end
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
-- travel-passport v1 (Oct 1 2026)
