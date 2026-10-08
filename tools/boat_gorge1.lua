-- boat_gorge1 v1: CHANGES THE PLACE (her ask 06:3x: "set it up so I can test how it looks with the boat" + the waterfall sound
-- 9120552550 louder toward the edge). Five things:
--  1. workspace.River attribute Line (the centre line the boat is held to) keeps its points north of z -200 and continues
--     through the gorge to the brink (59 points from the gorge's own shape file, every 6 studs, centre x and half width);
--  2. workspace.Boat.BoatClient: the south limit moves from the village rim (-205) to the brink (-547.5), so the boat stops
--     with its bow just short of the lip; the bridge limit and everything else untouched;
--  3. workspace.Boat.BoatServer: the watchdog box that removes a boat that leaves the river stretch grows to cover the gorge
--     (x 130..225, z -560..-118);
--  4. the jetty prompt comes back on (BoatPrompt.Enabled = true);
--  5. the waterfall sound: a part at the lip in SouthGorge.FallsB with a looping 3D Sound (rbxassetid://9120552550), Inverse
--     roll-off from 30 studs out to 450, so it swells as the boat comes down the gorge. No scripts added.
-- Re-running is harmless (each step checks before it changes).
local GORGE = "159.5,-200.0,9.5;160.2,-206.0,9.5;163.2,-212.0,9.8;168.2,-218.0,10.1;172.6,-224.0,9.9;175.7,-230.0,10.4;179.6,-236.0,10.9;183.6,-242.0,11.2;187.1,-248.0,11.6;190.3,-254.0,11.9;192.4,-260.0,12.1;192.9,-266.0,12.5;192.2,-272.0,13.0;189.7,-278.0,14.3;186.2,-284.0,15.8;181.2,-290.0,16.1;176.2,-296.0,15.2;171.5,-302.0,14.0;164.2,-308.0,15.0;157.1,-314.0,15.4;150.5,-320.0,15.0;144.1,-326.0,14.5;138.5,-332.0,14.2;133.6,-338.0,14.4;128.9,-344.0,14.4;123.6,-350.0,14.0;118.9,-356.0,13.4;115.1,-362.0,12.6;111.7,-368.0,12.4;110.1,-374.0,12.2;110.0,-380.0,12.2;110.0,-386.0,12.2;110.1,-392.0,12.2;111.6,-398.0,12.0;116.0,-404.0,11.2;120.6,-410.0,10.8;125.1,-416.0,9.9;130.7,-422.0,9.8;136.5,-428.0,10.0;142.5,-434.0,10.0;148.6,-440.0,10.1;154.9,-446.0,10.4;161.1,-452.0,10.6;167.7,-458.0,10.7;174.0,-464.0,10.5;179.4,-470.0,11.0;183.9,-476.0,11.6;188.2,-482.0,12.2;192.6,-488.0,12.9;196.7,-494.0,12.4;199.1,-500.0,11.9;200.4,-506.0,12.4;200.8,-512.0,12.8;198.9,-518.0,13.9;196.5,-524.0,15.0;193.7,-530.0,15.2;190.5,-536.0,15.0;187.4,-542.0,14.5;184.5,-546.5,14.1"
local River = workspace.River
local old = River:GetAttribute("Line") or ""
local keep = {}
for x, z, w in string.gmatch(old, "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
	if tonumber(z) > -200 then keep[#keep + 1] = string.format("%s,%s,%s", x, z, w) end
end
local nOld = #keep
local nNew = 0
for seg in string.gmatch(GORGE, "[^;]+") do keep[#keep + 1] = seg; nNew += 1 end
if not River:GetAttribute("Line_before_gorge") then River:SetAttribute("Line_before_gorge", old) end
River:SetAttribute("Line", table.concat(keep, ";"))
-- 2. the client's south limit
local B = workspace.Boat
local cli, srv = B.BoatClient, B.BoatServer
local cs = cli.Source
local cOld, cNew = "local Z_NORTH, Z_SOUTH = -127 - R, -205 + R + 0.4", "local Z_NORTH, Z_SOUTH = -127 - R, -547.5 + R + 0.6"
local cDone = "already"
if cs:find(cOld, 1, true) then cli.Source = cs:gsub(cOld:gsub("%p", "%%%0"), (cNew:gsub("%%", "%%%%")), 1); cDone = "changed"
elseif not cs:find(cNew, 1, true) then cDone = "NOT FOUND (source differs)" end
-- 3. the server's watchdog box
local ss = srv.Source
local sOld, sNew = "local BOX = {xmin = 140, xmax = 176, zmin = -210, zmax = -118}", "local BOX = {xmin = 130, xmax = 225, zmin = -560, zmax = -118}"
local sDone = "already"
if ss:find(sOld, 1, true) then srv.Source = ss:gsub(sOld:gsub("%p", "%%%0"), (sNew:gsub("%%", "%%%%")), 1); sDone = "changed"
elseif not ss:find(sNew, 1, true) then sDone = "NOT FOUND (source differs)" end
-- 4. the prompt
local prompt = River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.Enabled = true
-- 5. the waterfall sound
local FB = workspace.SouthGorge.FallsB
local sp = FB:FindFirstChild("FallsSound")
if not sp then
	sp = Instance.new("Part"); sp.Name = "FallsSound"; sp.Size = Vector3.new(1, 1, 1); sp.CFrame = CFrame.new(185.37, -8, -551.5)
	sp.Anchored = true; sp.CanCollide = false; sp.CanQuery = false; sp.CanTouch = false; sp.Transparency = 1; sp.CastShadow = false
	sp.Parent = FB
end
local snd = sp:FindFirstChild("Falls") or Instance.new("Sound")
snd.Name = "Falls"; snd.SoundId = "rbxassetid://9120552550"; snd.Looped = true; snd.Volume = 0.8
snd.RollOffMode = Enum.RollOffMode.Inverse; snd.RollOffMinDistance = 30; snd.RollOffMaxDistance = 450
snd.Parent = sp; snd.Playing = true
local last = keep[#keep]
print(string.format("QQ BG1 Line: %d old points (z > -200) + %d gorge points, last %s; client limit %s; server box %s; prompt Enabled=%s; sound %s playing=%s", nOld, nNew, last, cDone, sDone, tostring(prompt.Enabled), snd.SoundId, tostring(snd.Playing)))
print("QQ BG1 DONE")