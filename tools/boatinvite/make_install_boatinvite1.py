#!/usr/bin/env python3
"""install_boatinvite1.lua (job 89, Shannon Oct 11 2026): the one-click trip to the boat after the last French squirrel.
1. workspace.BoatInvite {BoatInviteEvent (RemoteEvent), BoatInviteServer, BoatInviteClient (RunContext Client)} and
   ReplicatedStorage.BoatTake (BindableEvent). Attributes: Need 44, RevealDelay 6, JoinDelay 25, Place "The River Dock", Enabled.
2. workspace.Boat.BoatServer, three exact-string patches (backup ServerStorage.HudBackup.BoatServer_pre_invite1):
   a. take(), first line: everyone who has found all 44 gets the parachute packed when they board, so the live script's
      three "talk to Sky Diving Squirrel first" warnings never stop them (no detour);
   b. after the prompt hookup: RS.BoatTake boards a player exactly as the jetty prompt does;
   c. the jetty sign (built by BoatServer at run time, her words): its last line "See Sky Diving Squirrel first." is dropped.
Re-runnable: an existing BoatInvite folder goes to HudBackup (attributes kept); an already patched BoatServer is left alone.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src" / "BoatInviteServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "BoatInviteClient.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER and "]===]" not in CLIENT
A1 = 'local function take(p)\n'
I1 = '\tif not hasChute(p) and found(p) >= NEED then p:SetAttribute("HasChute", true) end   -- (Oct 11, Shannon: one click; all 44 found = the parachute is packed, before any "see Sky Diving Squirrel" warning)\n'
A2 = 'if prompt then prompt.Triggered:Connect(take) else warn("BoatServer: no BoatPrompt on River.BoatPreview") end\n'
I2 = '''-- one click from the "to the boat" card (Oct 11, Shannon): workspace.BoatInvite puts the player on the jetty, then fires this
do
	local be = game:GetService("ReplicatedStorage"):FindFirstChild("BoatTake")
	if not (be and be:IsA("BindableEvent")) then be = Instance.new("BindableEvent"); be.Name = "BoatTake"; be.Parent = game:GetService("ReplicatedStorage") end
	be.Event:Connect(function(p) if typeof(p) == "Instance" and p:IsA("Player") and p.Parent == game:GetService("Players") then take(p) end end)
end
'''
A3 = '\\nSee Sky Diving Squirrel first.'   # (her sign's last line, as written in the source: a backslash-n escape inside the string)
R3 = ''
MARK = 'all 44 found = the parachute is packed'
for s in (A1, I1, A2, I2, A3, R3): assert "]==]" not in s
INSTALLER = f'''-- install_boatinvite1.lua (Studio EDIT mode; re-runnable). Job 89. The one-click trip to the boat after the last French
-- squirrel: workspace.BoatInvite (server {len(SERVER)}, client {len(CLIENT)} chars) + RS.BoatTake, and three exact-string
-- patches to workspace.Boat.BoatServer (backup HudBackup.BoatServer_pre_invite1). Undo: delete workspace.BoatInvite and
-- RS.BoatTake, put the backup's Source back, and the jetty sign's old text (printed below). No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SERVER = [===[
{SERVER}]===]
local CLIENT = [===[
{CLIENT}]===]
for _, pair in ipairs({{{{"server", SERVER}}, {{"client", CLIENT}}}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ BOATINV ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local boatF = workspace:FindFirstChild("Boat"); local bs = boatF and boatF:FindFirstChild("BoatServer")
if not (bs and bs:IsA("Script")) then print("QQ BOATINV ABORT: workspace.Boat.BoatServer not found; nothing changed") return end
if not workspace:FindFirstChild("Travel") then print("QQ BOATINV ABORT: workspace.Travel (the luggage cart fade) not found; nothing changed") return end
-- the BoatServer patches, all checked before anything changes
local A1, I1 = [==[{A1}]==], [==[{I1}]==]
local A2, I2 = [==[{A2}]==], [==[{I2}]==]
local A3, R3 = [==[{A3}]==], [==[{R3}]==]
local function count(s, sub) local n, i = 0, 1; while true do local a, b = s:find(sub, i, true); if not a then return n end; n += 1; i = b + 1 end end
local src, bsNote = bs.Source, nil
local oldLen = #src
if src:find([==[{MARK}]==], 1, true) then
	bsNote = "BoatServer already patched (" .. oldLen .. ")"
else
	if count(src, A1) ~= 1 or count(src, A2) ~= 1 then print(string.format("QQ BOATINV ABORT: BoatServer (%d chars) anchors found take=%d prompt=%d (need 1 and 1); nothing changed", oldLen, count(src, A1), count(src, A2))) return end
	local out = src
	local a, b = out:find(A1, 1, true); out = out:sub(1, b) .. I1 .. out:sub(b + 1)
	a, b = out:find(A2, 1, true); out = out:sub(1, b) .. I2 .. out:sub(b + 1)
	local signSrc = count(out, A3) == 1
	if signSrc then a, b = out:find(A3, 1, true); print("QQ BOATINV sign: dropping the line 'See Sky Diving Squirrel first.'"); out = out:sub(1, a - 1) .. R3 .. out:sub(b + 1) end
	local f, err = loadstring(out); if not f then print("QQ BOATINV ABORT: the patched BoatServer does not compile: " .. tostring(err) .. "; nothing changed") return end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("BoatServer_pre_invite1") then local bk = bs:Clone(); bk.Name = "BoatServer_pre_invite1"; bk.Enabled = false; bk.Parent = hb end
	bs.Source = out
	bsNote = string.format("BoatServer %d -> %d (backup HudBackup.BoatServer_pre_invite1; the sign's last line %s)", oldLen, #bs.Source, signSrc and "dropped" or "NOT FOUND, left")
end
local signNote = "the jetty sign is built by BoatServer at run time"
-- RS.BoatTake and the BoatInvite folder
local take = RS:FindFirstChild("BoatTake"); if not (take and take:IsA("BindableEvent")) then take = Instance.new("BindableEvent"); take.Name = "BoatTake"; take.Parent = RS end
local old = workspace:FindFirstChild("BoatInvite")
local attrs = {{}}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("BoatInvite_pre_" .. n) do n += 1 end
	old.Name = "BoatInvite_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "BoatInvite"
local defaults = {{Need = 44, RevealDelay = 6, JoinDelay = 25, Place = "The River Dock", Enabled = true}}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local e = Instance.new("RemoteEvent"); e.Name = "BoatInviteEvent"; e.Parent = F
local s = Instance.new("Script"); s.Name = "BoatInviteServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "BoatInviteClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ BOATINV DONE: workspace.BoatInvite (server %d, client %d chars; Need %s, RevealDelay %s, JoinDelay %s, Enabled %s); RS.BoatTake; %s; %s%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("Need")), tostring(F:GetAttribute("RevealDelay")), tostring(F:GetAttribute("JoinDelay")), tostring(F:GetAttribute("Enabled")),
	bsNote, signNote, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
(HERE / "install_boatinvite1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_boatinvite1.lua written:", len(INSTALLER))
