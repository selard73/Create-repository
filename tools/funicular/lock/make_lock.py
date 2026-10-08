from pathlib import Path
here=Path(__file__).parent
old=(here.parent/'live'/'SRV.lua').read_text(encoding='utf-8')
new=old
def rep(a,b):
    global new
    assert new.count(a)==1, a
    new=new.replace(a,b)
rep("local cars=rail.Cars:GetChildren()\n",
"""local cars=rail.Cars:GetChildren()
-- Oct 4 2026 (Shannon): locked until the player has found all 15 harbour squirrels (Found_porto, set by SquirrelSetup).
-- The owner may always ride (testing); set the rail attribute NoOwnerBypass=true to try the lock as her.
-- A turned-away player gets RS.FunicularLocked; TonioTalk makes Tonio explain (and stands them up if seated).
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local NEED=15
local lockEv=RS:FindFirstChild('FunicularLocked') or Instance.new('RemoteEvent')
lockEv.Name='FunicularLocked' lockEv.Parent=RS
local function mayRide(player)
 if player.UserId==game.CreatorId and not rail:GetAttribute('NoOwnerBypass') then return true end
 return (player:GetAttribute('Found_porto') or 0)>=NEED
end
local lastNote={}
local function refuse(player)
 local t=os.clock()
 if t-(lastNote[player] or 0)<3 then return end
 lastNote[player]=t
 lockEv:FireClient(player)
end
Players.PlayerRemoving:Connect(function(p) lastNote[p]=nil end)
""")
rep("   local c=player.Character;","   if not mayRide(player) then refuse(player) return end\n   local c=player.Character;")
rep("""  end)
 end end
end
""","""  end)
  seat:GetPropertyChangedSignal('Occupant'):Connect(function()
   local h=seat.Occupant
   local player=h and Players:GetPlayerFromCharacter(h.Parent)
   if player and not mayRide(player) then
    task.defer(function() local w=seat:FindFirstChild('SeatWeld') if w then w:Destroy() end end)
    lockEv:FireClient(player)
   end
  end)
 end end
end
""")
(here/'SRV_locked.lua').write_text(new,encoding='utf-8')

tt=(here.parent.parent/'italy_squirrels'/'TonioTalk.client.lua').read_text(encoding='utf-8')
a="""-- tagged: the server tells this player which squirrel they just found"""
assert tt.count(a)==1
tt2=tt.replace(a,"""-- the funicular turned this player away (FunicularServer, under 15 harbour squirrels): anyone sitting gets up again,
-- and Tonio explains (at most every 3 seconds, so pressing Board again and again does not spam him)
task.spawn(function()
	local lockEv = RS:WaitForChild("FunicularLocked", 60)
	if not lockEv then return end
	lockEv.OnClientEvent:Connect(function()
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Sit then h.Sit = false h.Jump = true end
		if os.clock() - lastSaid > 3 then speak() end
	end)
end)

"""+a)
(here/'TonioTalk_v2.client.lua').write_text(tt2,encoding='utf-8')

for s in (new,tt2): assert ']==]' not in s
inst="""-- fl1 Oct 4 2026: funicular locked until 15 harbour squirrels (Shannon's yes). Backs up the old ride script first.
local srv=workspace.PortoNocciola['15 Funicolare'].FunicularServer
local OLD=[==["""+old+"""]==]
local NEW=[==["""+new+"""]==]
local function trim(s) return (s:gsub('%s+$','')) end
if trim(srv.Source)~=trim(OLD) then warn('QY@STOP live FunicularServer differs from SRV.lua',#srv.Source,#OLD) return end
local bk=game.ServerStorage:FindFirstChild('FunicularBackup') or Instance.new('Folder',game.ServerStorage)
bk.Name='FunicularBackup'
if not bk:FindFirstChild('FunicularServer_v1025') then local c=srv:Clone() c.Name='FunicularServer_v1025' c.Disabled=true c.Parent=bk end
srv.Source=NEW
local SPS=game.StarterPlayer.StarterPlayerScripts
local tt=SPS:FindFirstChild('TonioTalk')
if not tt then warn('QY@STOP no TonioTalk') return end
if not bk:FindFirstChild('TonioTalk_v1025') then local c=tt:Clone() c.Name='TonioTalk_v1025' c.Disabled=true c.Parent=bk end
tt.Source=[==["""+tt2+"""]==]
game:GetService('ChangeHistoryService'):SetWaypoint('FunicularLock')
warn('QY@OK fl1',#srv.Source,#tt.Source)
"""
(here/'install_lock.lua').write_text(inst,encoding='utf-8')
print(len(new),len(tt2),len(inst))
