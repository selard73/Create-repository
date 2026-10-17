from pathlib import Path

D=Path(__file__).resolve().parent
BASE=D.parent/'cafe_interior2'
server=(BASE/'door_server.lua').read_text()
start=server.index('local function nearDoor(')
end=server.index('local function send(',start)
server=server[:start]+'''local entryPrompt=workspace.JapanMap.ShopFronts.CatCafe:WaitForChild("EntranceDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("EnterCafe")
local exitPrompt=room:WaitForChild("ExitDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("ExitCafe")
local function canUseDoor(root,inside)
 local prompt=inside and entryPrompt or exitPrompt
 if not prompt.Enabled or (root.Position-prompt.Parent.WorldPosition).Magnitude>8.5 then return false end
 local q=(inside and streetFrame or roomFrame):PointToObjectSpace(root.Position)
 local x=inside and -9.36 or -11
 return math.abs(q.X-x)<4.5 and q.Y>-.5 and q.Y<8 and (inside and q.Z>=-.3 and q.Z<8 or not inside and q.Z<.3 and q.Z> -8)
end
'''+server[end:]
server=server.replace('local active={};local cooldown={};local mustLeaveDoor={};','local active={};local cooldown={};')
server=server.replace(' if not success then mustLeaveDoor[player]=true end\n','')
server=server.replace('if not c or active[player] or r.Anchored or h.SeatPart or h.Sit then return end','if not c or active[player] or os.clock()<(cooldown[player]or 0) or r.Anchored or h.SeatPart or h.Sit or not canUseDoor(r,inside) then return end')
server=server.replace('cooldown[p]=nil;mustLeaveDoor[p]=nil','cooldown[p]=nil')
start=server.index('task.spawn(function()')
end=server.index('script.Destroying:Connect',start)
server=server[:start]+'''-- A prompt press is the only way to begin. Walking into either door never starts a transition.
local entryConnection=entryPrompt.Triggered:Connect(function(p)begin(p,true)end)
local exitConnection=exitPrompt.Triggered:Connect(function(p)begin(p,false)end)
task.spawn(function()
 while alive and script.Parent do
  local now=os.clock()
  for _,p in ipairs(Players:GetPlayers())do
   local s=active[p]
   if s then
    local c=character(p)
    if c~=s.char or now>s.deadline then finish(p,false,"Doorway is not ready. Please try again.")end
   else
    local c,h,r=character(p)
    if r and p:GetAttribute("InCatCafeInterior") and math.abs(r.Position.Y-roomFrame.Position.Y)>30 then p:SetAttribute("InCatCafeInterior",false)end
   end
  end
  task.wait(.1)
 end
end)
'''+server[end:]
server=server.replace('alive=false;connection:Disconnect();removed:Disconnect()','alive=false;connection:Disconnect();removed:Disconnect();entryConnection:Disconnect();exitConnection:Disconnect()')
(D/'door_server.lua').write_text(server)
camera=(BASE/'camera_client.lua').read_text().replace('Vector3.new(16.80,11.05,-.15)','Vector3.new(16.80,9.15,-.15)')
(D/'camera_client.lua').write_text(camera)
client=(BASE/'door_client.lua').read_text()
bell='''-- Same door bell and volume as the French Bookshop, HatShop and DressShop.
local doorBell=Instance.new("Sound");doorBell.Name="CafeDoorBell"
doorBell.SoundId=bridge:GetAttribute("DoorSound")or"rbxassetid://131845870598154"
doorBell.Volume=bridge:GetAttribute("DoorVolume")or .6;doorBell.PlaybackSpeed=1;doorBell.Looped=false;doorBell.Parent=gui
task.spawn(function()pcall(function()game:GetService("ContentProvider"):PreloadAsync({doorBell})end)end)
'''
assert client.count('gui.Parent=pg\n')==1
client=client.replace('gui.Parent=pg\n','gui.Parent=pg\n'+bell)
finish='  if pending and pending.token==token then pending=nil;fade(1)end'
assert client.count(finish)==1
client=client.replace(finish,'''  if pending and pending.token==token then
   pending=nil
   if action=="FadeIn"then doorBell:Stop();doorBell.TimePosition=0;doorBell:Play()end
   fade(1)
  end''')
(D/'door_client.lua').write_text(client)
template=(BASE/'install.template.lua').read_text()
template=template.replace('CAFEINTERIOR2_ALLOW_EDIT==true','CAFECOZY3_ALLOW_EDIT==true')
marker='verify()\nlocal createdBackup=false'
assert template.count(marker)==1
template=template.replace(marker,(D/'cozy_patch.lua').read_text()+'\n'+(D/'polish_patch.lua').read_text()+'\n'+marker)
template=template.replace('38 wall decor meshes; 34x28 room, 11.3 ceiling','38 original wall decor meshes; 34x28 room, lowered 9.8 ceiling')
template=template.replace('runtime entrance/exit, timeout, respawn and camera tests still required','closed mesh doors; E/tap entry and exit only; no walk-through transition')
template=template.replace('four steaming mugs retained','four original steaming mugs plus two at the new seating nook')
import json
code=template.replace('__DATA__',json.dumps(json.loads((BASE/'out/manifest.json').read_text()),separators=(',',':'))).replace('__CAMERA__',camera).replace('__SERVER__',server).replace('__CLIENT__',client)
(D/'cafe_cozy3.lua').write_text(code)
print('CAFECOZY3_SOURCE_READY: staged existing-mesh redesign with prompt-only doors')
