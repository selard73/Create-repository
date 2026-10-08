from pathlib import Path
import json,re
P=Path(__file__).parent
hat=Path(r'C:\Users\slard\roblox-props\village\build_hatshop.lua').read_text(encoding='utf8')
data=json.loads((P/'dress_kit.json').read_text())
def vec(v):return 'Vector3.new('+','.join(f'{x:.6f}' for x in v)+')'
cat=(P/'Catalogue.lua').read_text().replace('__CENTRES__','{'+','.join(f'["{k}"]={vec(v["centre"])}' for k,v in data.items())+'}').replace('__SIZES__','{'+','.join(f'["{k}"]={vec(v["size"])}' for k,v in data.items())+'}')
(P/'DressCatalogue.lua').write_text(cat)
server=hat.split('local SERVER = [==[')[1].split(']==]')[0]
client=hat.split('local CLIENT = [==[')[1].split(']==]')[0]
def names(s):
 for a,b in [('HatShop','DressShop'),('HatServer','DressServer'),('HatClient','DressClient'),('HatKit','DressKit'),('HatDebug','DressDebug'),('WornHat','WornDress'),('HatPreview','DressPreview'),('HatId','DressId'),('HatMirrorStay','DressMirrorStay'),('Item_hatwear_','Item_dresswear_'),('Item_hat_','Item_dress_'),('"hatwear_"','"dresswear_"'),('"hat_"','"dress_"')]:s=s.replace(a,b)
 s=s.replace('name:sub(1, 13)','name:sub(1, 15)').replace('name:sub(14)','name:sub(16)').replace('name:sub(1, 9)','name:sub(1, 11)')
 return s
server=names(server)
a=server.index('local function showOwnHats');b=server.index('local pending = {}')
server=server[:a]+'''local function uncover(char)
 for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];local was=o:GetAttribute("DressClothingWas");if was~=nil then o[key]=was;o:SetAttribute("DressClothingWas",nil) end end
 for _,p in ipairs(char:GetDescendants()) do
  if p:IsA("BasePart") then local was=p:GetAttribute("DressWas");if was~=nil then p.Transparency=was;p:SetAttribute("DressWas",nil) end end
 end
end
local function cover(char,id)
 for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];if o:GetAttribute("DressClothingWas")==nil then o:SetAttribute("DressClothingWas",o[key]) end;o[key]="" end
 for _,p in ipairs(Cat.covered(char,id)) do if p:GetAttribute("DressWas")==nil then p:SetAttribute("DressWas",p.Transparency) end;p.Transparency=1 end
end
local function dress(player)
 local char=player.Character;if not char then return end
 local id=worn(player);local cur=char:FindFirstChild("WornDress")
 if cur and cur:GetAttribute("DressId")==id and owns(player,id) then cover(char,id);return end
 if cur then cur:Destroy() end;uncover(char)
 if id and owns(player,id) and Cat.attach(kit,id,char,"WornDress") then cover(char,id) end
end
''' +server[b:]
server=server.replace('Vector3.new(0, 0, 1)))','Vector3.new(0, 0, -1)))')
server=server.replace('if not hrp then return end','if not hrp then return end\n local target=toInside and F.DoorPad.Position or F.Room.Door.Position\n if (hrp.Position-target).Magnitude>12 then return end',1)
server=server.replace('elseif prompt.Name == "MirrorPrompt" then ev:FireClient(player, "mirror") end','elseif prompt.Name == "MirrorPrompt" then\n local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")\n if root and (root.Position-prompt.Parent.Position).Magnitude<=13 then ev:FireClient(player,"mirror") end end')
server=server.replace('local busy = {}','local busy, lastCall = {}, {}')
server=server.replace('action.OnServerInvoke = function(player, what, id)','''local function request(player, what, id)
 if type(what)~="string" or type(id)~="string" then return false,"Choose a dress" end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-v3("Spot")).Magnitude>14 then return false,"Visit the boutique mirror" end
 if not player:GetAttribute("SaveLoaded") then return false,"Your wardrobe is still loading" end
 local now=os.clock();if busy[player] or now-(lastCall[player] or 0)<0.25 then return false,"One moment" end;lastCall[player]=now
''')
server=server.replace('if type(price) ~= "number" then','if type(price) ~= "number" or price~=price or price<0 or price%1~=0 then')
server=server.replace('awardItems:Fire(player, "dress_" .. id, 1)','awardItems:Fire(player, "dress_" .. id, 1)\n\t\t\ttask.wait()')
server=server.replace('wear(player, id)                                   -- a new hat goes straight on','wear(player, id)\n\t\t\ttask.wait()')
server=re.sub(r'\s*local passport=game:GetService\("ReplicatedStorage"\):FindFirstChild\("PassportActivity"\);if passport then passport:Fire\(player,"hat",\{hat=Cat.title\(id\),action="buy"\}\) end','',server)
server=server.replace('return false, "?"\nend','return false, "Unknown action"\nend\naction.OnServerInvoke=request')
server=server.replace('savedZoom[p] = nil; busy[p] = nil; moving[p] = nil','savedZoom[p] = nil; busy[p] = nil; moving[p] = nil;lastCall[p]=nil;pending[p]=nil')
server=server.replace('if what == "give" then','if what == "request" then return request(player,id[1],id[2])\n        elseif what == "give" then')
server=server.replace('no such hat','Unknown dress').replace('that one isn\'t yours yet','Buy this dress first')
(P/'DressServer.lua').write_text(server)
client=names(client)
client=client.replace('s.Color = col; s.Thickness', 's.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color = col; s.Thickness')
client=client.replace('RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)','RGB(255, 246, 220), RGB(250, 235, 201), RGB(226, 175, 68)')
client=client.replace('RGB(228, 212, 179), RGB(162, 131, 90)','RGB(242, 229, 203), RGB(218, 174, 83)')
client=client.replace('"Chapelier"','"Boutique"').replace('Tap a hat','Tap a dress').replace('Pick a hat','Pick a dress').replace('"No hat"','"Take off"').replace('"hat off"','"Original outfit"')
# Real pixels for text; bounded responsive geometry instead of scaling text to fractional pixels.
client=client.replace('local W, H = 336, 400','local W, H = 320, 410')
a=client.index('local scale = Instance.new("UIScale")');b=client.index('local title = Instance.new',a)
client=client[:a]+'''local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 W=math.min(350,math.floor(vp.X*.49)-12);H=math.min(480,math.floor(vp.Y)-40)
 panel.Size=UDim2.fromOffset(W,H);panel.Position=UDim2.new(1,-12,.5,8)
end
''' +client[b:]
client=client.replace('UDim2.fromOffset(150, 30)','UDim2.fromOffset(112, 30)').replace('title.TextSize = 26','title.TextSize = 24')
client=client.replace('purse.TextSize = 17','purse.TextSize = 14').replace('UDim2.fromOffset(108, 28)','UDim2.fromOffset(105, 28)')
client=client.replace('1, -54 - 108','1, -54 - 119').replace('0, 92)','0, 106)')
client=client.replace('picked.TextSize = 17','picked.TextSize = 14')
client=client.replace('note.AnchorPoint = Vector2.new(1, 0); note.Position = UDim2.new(1, -12, 0, 8); note.Size = UDim2.fromOffset(120, 18)','note.AnchorPoint = Vector2.new(0, 0); note.Position = UDim2.fromOffset(12, 28); note.Size = UDim2.new(1,-24,0,16)')
client=client.replace('note.FontFace = FONT','note.Font = Enum.Font.BuilderSans').replace('note.TextXAlignment = Enum.TextXAlignment.Right','note.TextXAlignment = Enum.TextXAlignment.Left')
client=client.replace('b.TextSize = 17','b.TextSize = 14').replace('UDim2.fromOffset(12, 38)','UDim2.fromOffset(12, 51)').replace('UDim2.new(1, -104, 0, 38)','UDim2.new(1, -92, 0, 51)').replace('UDim2.new(1, -124, 0, 42)','UDim2.new(1, -112, 0, 42)').replace('UDim2.fromOffset(92, 42)','UDim2.fromOffset(80, 42)')
client=client.replace('0, 104)','0, 154)').replace('nm.TextSize = 17','nm.TextSize = 15').replace('UDim2.fromOffset(150, 20)','UDim2.new(1,-110,0,20)').replace('UDim2.fromOffset(110, 18)','UDim2.fromOffset(95, 18)').replace('pr.TextSize = 14','pr.TextSize = 12')
client=client.replace('UDim2.fromOffset(88, 68); t.Position = UDim2.fromOffset(10 + (k - 1) * 98, 28)','UDim2.new(1/3,-12,0,111); t.Position = UDim2.new((k-1)/3,7,0,32)')
client=client.replace('pic.Size = UDim2.new(1, -8, 1, -8)','pic.Size = UDim2.new(1, -8, 1, -33)')
client=client.replace('tiles[id] = {button = t, stroke = st, tag = tag}','''local color=Instance.new("TextLabel");color.Name="Colour";color.BackgroundTransparency=1;color.Position=UDim2.new(0,2,1,-31);color.Size=UDim2.new(1,-4,0,14);color.Font=Enum.Font.BuilderSans;color.TextSize=11;color.TextColor3=INK;color.Text=s.colours[k].name;color.Parent=t
        tiles[id] = {button = t, stroke = st, tag = tag}''')
# Garments photographed from the front at waist height.
client=client.replace('local dir = Vector3.new(0, math.sin(math.rad(24)), math.cos(math.rad(24)))','local dir = Vector3.new(0.22,0.1,-1).Unit')
a=client.index('local function hideWorn(hide)');b=client.index('local function refresh()',a)
client=client[:a]+'''local hiddenClothing={}
local function hideWorn(hide)
 local char=player.Character
 if hide and char then
  for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];if hiddenClothing[o]==nil then hiddenClothing[o]={key,o[key]} end;o[key]="" end
  local all=Cat.covered(char,selected);local w=char:FindFirstChild("WornDress")
  if w then for _,p in ipairs(w:GetDescendants()) do if p:IsA("BasePart") then table.insert(all,p) end end end
  for _,p in ipairs(all) do if hiddenParts[p]==nil then hiddenParts[p]=p.LocalTransparencyModifier end;p.LocalTransparencyModifier=1 end
 else
  for o,v in pairs(hiddenClothing) do if o.Parent then o[v[1]]=o:GetAttribute("DressClothingWas")~=nil and "" or v[2] end end;hiddenClothing={}
  for p,was in pairs(hiddenParts) do if p.Parent then p.LocalTransparencyModifier=was end end;hiddenParts={}
 end
end
local function clearPreview() if preview then preview:Destroy();preview=nil end end
local function tryOn(id)
 clearPreview();hideWorn(false)
 local char=player.Character;if not char then return end
 preview=Cat.attach(kit,id,char,"DressPreview");hideWorn(true)
end

''' +client[b:]
client=client.replace('main.Text = "You\'re wearing it"','main.Text = "Wearing"')
client=client.replace('if busy or not selected then return end','if busy or not selected then return end')
client=client.replace('selected = id\n\t\ttryOn(id)','if busy then return end\n\t\tselected = id\n\t\ttryOn(id)')
client=client.replace('if selected == want and preview then','if selected == want and preview then')
# Hat mirror is a headshot. Dresses need the whole character, offset into the left half.
client=client.replace("task.defer(function()", "task.defer(function()\n            if not open or player.Character~=char then return end")
client=client.replace('local hp = head.Position','local hp = hrp.Position - Vector3.new(0,.2,0)')
client=client.replace('toMirror * 6.2 + camRight * 0.6 + Vector3.new(0, 0.1, 0)','toMirror * 7.3 + camRight * 0.4 + Vector3.new(0, 0.2, 0)')
client=client.replace('hp + camRight * 1.75 - Vector3.new(0, 0.3, 0)','hp + camRight * 2.7')
# Close on Escape and when door travel starts; restore all previous UI state.
client=client.replace('if what == "fade" then','if what == "fade" then\n        if open then setOpen(false) end')
client=client.replace('close.MouseButton1Click:Connect(function() setOpen(false) end)','''close.MouseButton1Click:Connect(function() setOpen(false) end)
game:GetService("UserInputService").InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Escape and open then setOpen(false) end end)''')
client=client.replace('pcall(function() action:InvokeServer("wear", "") end)\n\tbusy = false\n\tsay("Original outfit", true)','local ok,res,why=pcall(function() return action:InvokeServer("wear", "") end)\n\tbusy = false\n\tsay(ok and res and "Original outfit" or tostring(why or "Try again"),ok and res)')
(P/'DressClient.lua').write_text(client)

# Reuse the established room shell, doors, mirror and warm shop lighting.
start=hat.index('\tlocal function part(');end=hat.index('\t-- ---------------------------------------------------------------- server ----')
room=hat[start:end]
a=room.index('\tlocal SX, DX, DZ');b=room.index('\tlocal function shopColour',a)
room=room[:a]+'''\tlocal SX, DX, DZ=304,295,-100.6
 local shop
 for _,m in ipairs(workspace.Village.Props:GetChildren()) do
  local t=m:FindFirstChild("SignText",true)
  if t then for _,l in ipairs(t:GetDescendants()) do if l:IsA("TextLabel") and l.Text=="MODE ET STYLE" then shop=m end end end
 end
 assert(shop,"MODE ET STYLE storefront missing")
''' +room[b:]
room=room.replace('opts.roomY or 340','opts.roomY or 390')
room=room.replace('local DX', 'local DX').replace('DZ + 1.2','DZ - 1.2').replace('DZ + 2.6','DZ - 2.6')
room=room.replace('C(106, 140, 108)','C(38, 94, 65)').replace('C(150, 40, 58)','C(155, 72, 48)')
a=room.index('\t-- the hats, anchored');b=room.index('\t-- THE MIRROR',a)
room=room[:a]+(P/'displays.lua').read_text()+room[b:]
a=room.index('\t-- a hat tree');b=room.index('\t-- the counter',a)
room=room[:a]+'''\t-- Fabric rolls in a brass basket beside the mirror.
 for i,col in ipairs({C(230,185,81),C(169,78,50),C(44,91,63)}) do
  local x,z=-10.4+(i-2)*.45,3.3
  soft(part("FabricRoll",Vector3.new(3.1,.44,.44),at(x,1.7,z)*CFrame.Angles(0,0,math.rad(86+i*2)),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end
 part("FabricBasket",Vector3.new(1.8,.8,1.1),at(-10.4,.4,3.3),WOOD,Enum.Material.Wood,room)
''' +room[b:]
room=names(room).replace('Try on hats','Try on dresses').replace('Chapelier','Mode et Style').replace('CHAPELIER','MODE ET STYLE')
# Tailor's ribbons on the counter alongside the till.
room+='''
 for i,col in ipairs({C(230,187,86),C(245,230,197),C(153,58,64)}) do
  soft(part("RibbonSpool",Vector3.new(.3,.5,.5),at(9.6,3.85,1+i*.5)*CFrame.Angles(0,0,math.pi/2),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end
'''
builder='''-- Mode et Style dress boutique, original 9-dress collection. Draft; publish separately after review.
return function(opts)
 opts=opts or {};local RS=game:GetService("ReplicatedStorage");local CS=game:GetService("CollectionService");local C=Color3.fromRGB;local rng=Random.new(2710)
 local kit=assert(RS:FindFirstChild("DressKit"),"Import Dresses.obj and run kit installer first")
 local CAT=[====[\n'''+cat+'''\n]====]
 local SERVER=[====[\n'''+server+'''\n]====]
 local CLIENT=[====[\n'''+client+'''\n]====]
 local Cat=assert(loadstring(CAT))();assert(loadstring(SERVER));assert(loadstring(CLIENT))
 for name in pairs(Cat.sizes) do assert(kit:FindFirstChild(name),"Missing dress mesh "..name) end
 local F=Instance.new("Folder");F.Name="DressShop"
 for _,s in ipairs(Cat.styles) do F:SetAttribute("Price_"..s.id,(opts.prices and opts.prices[s.id]) or s.price) end
'''+room+'''
 local old=workspace:FindFirstChild("DressShop");if old then old:Destroy() end
 local oldCat=kit:FindFirstChild("Catalogue");if oldCat then oldCat:Destroy() end
 local cm=Instance.new("ModuleScript");cm.Name="Catalogue";cm.Source=CAT;cm.Parent=kit
 local s=Instance.new("Script");s.Name="DressServer";s.RunContext=Enum.RunContext.Server;s.Source=SERVER;s.Parent=F
 local c=Instance.new("Script");c.Name="DressClient";c.RunContext=Enum.RunContext.Client;c.Source=CLIENT;c.Parent=F
 local cf,sz=room:GetBoundingBox();room:SetAttribute("BoxCF",cf);room:SetAttribute("BoxSize",sz);CS:AddTag(room,"SkyRoom")
 F.Parent=workspace
 return F
end
'''
(P/'build_dressshop.lua').write_text(builder)
runner='''-- DRESS SHOP v1: EDIT ONLY; isolated boutique, no village rebuild.
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local build=(function()\n'''+builder+'''\nend)()
local f=build({})
warn("QQ DRESS BUILD PASS "..f:GetFullName().." / nine dresses")
'''
(P/'run_install.lua').write_text(runner)
print('Built dress shop runner',len(runner))
