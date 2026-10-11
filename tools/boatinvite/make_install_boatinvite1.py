#!/usr/bin/env python3
"""install_boatinvite1.lua (job 89, Shannon Oct 11 2026): the one-click trip to the boat after the last French squirrel.
1. workspace.BoatInvite {BoatInviteEvent (RemoteEvent), BoatInviteServer, BoatInviteClient (RunContext Client)} and
   ReplicatedStorage.BoatTake (BindableEvent). Attributes: Need 44, RevealDelay 6, JoinDelay 25, Place "The River Dock", Enabled.
2. workspace.Boat.BoatServer, three exact-string patches (backup ServerStorage.HudBackup.BoatServer_pre_invite1):
   a. take(), first line: everyone who has found all 44 gets the parachute packed when they board, so the live script's
      three "talk to Sky Diving Squirrel first" warnings never stop them (no detour);
   b. after the prompt hookup: RS.BoatTake boards a player exactly as the jetty prompt does;
   c. the jetty sign (built by BoatServer at run time, her words): its last line "See Sky Diving Squirrel first." is dropped.
   d. the Sky Diving Squirrel no longer lends a chute; his lines say nothing about a parachute or the falls (and point at the boat).
3. workspace.Boat.BoatClient: the jetty prompt reads "Take the boat" / "Bateau" for everyone with all 44 (no "(no parachute!)",
   no "see the Sky Diving Squirrel first"); backup HudBackup.BoatClient_pre_invite1. The waterfall stays a surprise.
4. workspace.Passport.Catalogue: the boat outings' hints and details no longer mention the waterfall or the parachute
   (backup HudBackup.Catalogue_pre_invite1).
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
# the Sky Diving Squirrel no longer lends a chute (everyone with all 44 gets it at boarding), so his talk changes (Shannon:
# "if you don't now get the parachute from the skydiving squirrel, that dialogue does not make sense"); nothing about a
# parachute, the falls or a drop: the waterfall stays a surprise
SKY = [
    ('local CHUTE_LINES = {"All 44 found! Take my spare chute.", "I packed it myself, so it will probably open.", "The river ends in a big drop... you will want it."}',
     'local CHUTE_LINES = {"All 44! Now THAT is a high score.", "I once jumped out of a plane and landed in a pie shop. Best day of my life.", "Seen the boat at the river dock? Take it. Trust me."}'),
    ('local CHUTE_NO = "Find all %d squirrels first (%d so far), then come and see me about the falls!"',
     'local CHUTE_NO = "Find all %d squirrels (%d so far) and I will tell you my best skydiving story!"'),
    ('local CHUTE_AGAIN = "You already have my chute on your back. Go on, the falls are waiting!"',
     'local CHUTE_AGAIN = "Still here? The boat at the river dock is waiting for you!"'),
    ('p:SetAttribute("HasChute", true)\n', '-- (Oct 11: no lending; the boat packs it)\n'),
    ('if p.Character then attachPack(p.Character) end', '-- (no pack from him any more)'),
]
# the Passport's boat outings (workspace.Passport.Catalogue; Shannon: "yes please reword the hint, no mention of waterfall or
# parachute"); ids, names, icons and the stamping are unchanged
CAT = [
    (' Steer down the river and see where it goes. The Sky Diving Squirrel in the forest has something you will want before you leave.',
     ' Steer down the river and see where it goes. Hold on to your hat!'),
    ('hint="Ride the river all the way to the waterfall."', 'hint="Ride the river all the way to the end."'),
    ('detail="The river leaves French Squirrel Country through a gorge and ends in a great waterfall. Keep going past the brink and over you go, boat and all. Wet or dry, you arrive at Porto Nocciola."',
     'detail="The river leaves French Squirrel Country through a gorge. Keep going all the way to the very end, boat and all, and see where it takes you."'),
    ('hint="Float down to Porto Nocciola under the Sky Diving Squirrel\'s parachute."', 'hint="Arrive at Porto Nocciola with dry feet."'),
    ('detail="After you have found all 44 squirrels, talk to the Sky Diving Squirrel in the forest and he lends you his spare parachute. Wear it over the falls and steer your way down to the shore."',
     'detail="Once you have found all 44 squirrels, take the boat all the way down the river. How you reach the shore is a surprise!"'),
    ('Porto Nocciola lies at the foot of the falls.', 'Porto Nocciola lies where the river ends.'),
]
# BoatClient's jetty prompt text (runner 6 read these from the live BoatClient, lines 339-340)
C1 = '(may and not player:GetAttribute("HasChute")) and "Take the boat (no parachute!)" or "Take the boat"'
D1 = '"Take the boat"'
C2 = '(player:GetAttribute("HasChute") and "Bateau" or "Bateau - see the Sky Diving Squirrel first")'
D2 = '"Bateau"'
for s in (A1, I1, A2, I2, A3, R3, C1, D1, C2, D2) + tuple(x for pair in SKY + CAT for x in pair): assert "]==]" not in s
SKYLUA = '{' + ', '.join('{[==[' + a + ']==], [==[' + b + ']==]}' for a, b in SKY) + '}'
CATLUA = '{' + ', '.join('{[==[' + a + ']==], [==[' + b + ']==]}' for a, b in CAT) + '}'
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
-- BoatClient's jetty prompt (no "no parachute!" / "see the Sky Diving Squirrel first": the waterfall stays a surprise), checked first
local bc = boatF:FindFirstChild("BoatClient")
if not (bc and bc:IsA("BaseScript")) then print("QQ BOATINV ABORT: workspace.Boat.BoatClient not found; nothing changed") return end
local C1, D1 = [==[{C1}]==], [==[{D1}]==]
local C2, D2 = [==[{C2}]==], [==[{D2}]==]
local function count0(s, sub) if sub == "" then return 0 end; local n, i = 0, 1; while true do local a, b = s:find(sub, i, true); if not a then return n end; n += 1; i = b + 1 end end
local bcSrc, bcOut, bcNote = bc.Source, nil, nil
if count0(bcSrc, C1) == 0 and count0(bcSrc, C2) == 0 and bcSrc:find("Bateau - see the Sky Diving", 1, true) == nil and bcSrc:find("(no parachute!)", 1, true) == nil then
	bcNote = "BoatClient already plain (" .. #bcSrc .. ")"
elseif count0(bcSrc, C1) ~= 1 or count0(bcSrc, C2) ~= 1 then
	print(string.format("QQ BOATINV ABORT: BoatClient (%d chars) prompt-text anchors found %d and %d (need 1 and 1); nothing changed", #bcSrc, count0(bcSrc, C1), count0(bcSrc, C2))) return
else
	local a, b = bcSrc:find(C1, 1, true); bcOut = bcSrc:sub(1, a - 1) .. D1 .. bcSrc:sub(b + 1)
	a, b = bcOut:find(C2, 1, true); bcOut = bcOut:sub(1, a - 1) .. D2 .. bcOut:sub(b + 1)
	local f, err = loadstring(bcOut); if not f then print("QQ BOATINV ABORT: the patched BoatClient does not compile: " .. tostring(err) .. "; nothing changed") return end
end
-- the Passport's boat outings, checked before anything changes
local pf = workspace:FindFirstChild("Passport"); local cat = pf and pf:FindFirstChild("Catalogue")
if not (cat and cat:IsA("ModuleScript")) then print("QQ BOATINV ABORT: workspace.Passport.Catalogue not found; nothing changed") return end
local CAT = {CATLUA}
local catOut, catNote = cat.Source, nil
if catOut:find(CAT[2][2], 1, true) and not catOut:find(CAT[2][1], 1, true) then
	catNote = "Passport outings already reworded"; catOut = nil
else
	for i, pair in ipairs(CAT) do
		local n = count0(catOut, pair[1])
		if n ~= 1 then print(string.format("QQ BOATINV ABORT: Passport.Catalogue anchor %d found %d times (need 1); nothing changed", i, n)) return end
		local a, b = catOut:find(pair[1], 1, true); catOut = catOut:sub(1, a - 1) .. pair[2] .. catOut:sub(b + 1)
	end
	local f, err = loadstring(catOut); if not f then print("QQ BOATINV ABORT: the reworded Catalogue does not compile: " .. tostring(err) .. "; nothing changed") return end
end
-- the BoatServer patches, all checked before anything changes
local A1, I1 = [==[{A1}]==], [==[{I1}]==]
local A2, I2 = [==[{A2}]==], [==[{I2}]==]
local A3, R3 = [==[{A3}]==], [==[{R3}]==]
local function count(s, sub) if sub == "" then return 0 end; local n, i = 0, 1; while true do local a, b = s:find(sub, i, true); if not a then return n end; n += 1; i = b + 1 end end
local src, bsNote = bs.Source, nil
local oldLen = #src
if src:find([==[{MARK}]==], 1, true) then
	bsNote = "BoatServer already patched (" .. oldLen .. ")"
else
	if count(src, A1) ~= 1 or count(src, A2) ~= 1 then print(string.format("QQ BOATINV ABORT: BoatServer (%d chars) anchors found take=%d prompt=%d (need 1 and 1); nothing changed", oldLen, count(src, A1), count(src, A2))) return end
	local out = src
	local SKY = {SKYLUA}
	for i, pair in ipairs(SKY) do
		local n = count(out, pair[1])
		if n ~= 1 then print(string.format("QQ BOATINV ABORT: BoatServer Sky Diving Squirrel anchor %d found %d times (need 1); nothing changed", i, n)) return end
		local a, b = out:find(pair[1], 1, true); out = out:sub(1, a - 1) .. pair[2] .. out:sub(b + 1)
	end
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
if bcOut then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("BoatClient_pre_invite1") then local bk = bc:Clone(); bk.Name = "BoatClient_pre_invite1"; bk.Enabled = false; bk.Parent = hb end
	local was = #bc.Source; bc.Source = bcOut
	bcNote = string.format("BoatClient %d -> %d, the jetty prompt reads 'Take the boat' / 'Bateau' (backup HudBackup.BoatClient_pre_invite1)", was, #bc.Source)
end
if catOut then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("Catalogue_pre_invite1") then local bk = cat:Clone(); bk.Name = "Catalogue_pre_invite1"; bk.Parent = hb end
	local was = #cat.Source; cat.Source = catOut
	catNote = string.format("Passport.Catalogue %d -> %d, 6 boat-outing texts reworded (backup HudBackup.Catalogue_pre_invite1)", was, #cat.Source)
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
print(string.format("QQ BOATINV DONE: workspace.BoatInvite (server %d, client %d chars; Need %s, RevealDelay %s, JoinDelay %s, Enabled %s); RS.BoatTake; %s; %s; %s; %s%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("Need")), tostring(F:GetAttribute("RevealDelay")), tostring(F:GetAttribute("JoinDelay")), tostring(F:GetAttribute("Enabled")),
	bsNote, bcNote, catNote, signNote, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
(HERE / "install_boatinvite1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_boatinvite1.lua written:", len(INSTALLER))
