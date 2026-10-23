-- church1.lua (Oct 23 2026): Shannon: "139851043401845 this track for inside the church please" + "and this one 136179244635591".
-- MapMusic.MusicClient gets a church interior override like the tea house and the cat cafe: inside the nave's box (the plaster's
-- inner faces, floor to ridge) the area is "japan_church"; its attribute lists both tracks, so they play back to back and go round
-- again (the existing "id1,id2" lists). Outside the box (the steps, the lawn) the countryside track carries on as before.
-- Follows the same isPreview() gate as the other Japan music (the gate comes off with the rest when Japan opens).
-- Backup: HudBackup.MusicClient_pre_church1 (disabled). Patched by exact find/replace, each found once. "QQ CHURCH1".
local SS = game:GetService("ServerStorage")
local folder = workspace:FindFirstChild("MapMusic")
local mc = folder and folder:FindFirstChild("MusicClient")
local hb = SS:FindFirstChild("HudBackup")
if not (mc and hb) then return "QQ CHURCH1 ABORT: MapMusic.MusicClient or HudBackup missing" end
local src = mc.Source
if src:find("CHURCH1_MUSIC", 1, true) then return "QQ CHURCH1 already installed" end
local function count(s, needle) local n, i = 0, 1 while true do local a, b = s:find(needle, i, true) if not a then return n end n += 1 i = b + 1 end end
local A = "\t-- Interior override: evaluated before the surrounding Japan districts.\n"
local A2 = "\t-- CHURCH1_MUSIC_20261023: inside the church (the nave, floor to ridge); the steps and the lawn stay on the countryside track\n" ..
	"\tlocal churchFrame = folder:GetAttribute(\"JapanChurchFrame\")\n" ..
	"\tlocal churchHalf = folder:GetAttribute(\"JapanChurchHalfSize\")\n" ..
	"\tif isPreview() and typeof(churchFrame) == \"CFrame\" and typeof(churchHalf) == \"Vector3\" then\n" ..
	"\t\tlocal p = churchFrame:PointToObjectSpace(pos)\n" ..
	"\t\tif math.abs(p.X) <= churchHalf.X and math.abs(p.Y) <= churchHalf.Y and math.abs(p.Z) <= churchHalf.Z then\n" ..
	"\t\t\treturn \"japan_church\"\n" ..
	"\t\tend\n" ..
	"\tend\n" .. A
local B = "\"japan_teahouse\", \"japan_catcafe\"}) do"
local B2 = "\"japan_teahouse\", \"japan_catcafe\", \"japan_church\"}) do"
assert(count(src, A) == 1, "anchor A not found once")
assert(count(src, B) == 1, "anchor B not found once")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before church1") end)
local old = hb:FindFirstChild("MusicClient_pre_church1")
if not old then old = mc:Clone(); old.Name = "MusicClient_pre_church1"; old.Enabled = false; old.Parent = hb end
src = src:gsub(A:gsub("%p", "%%%0"), (A2:gsub("%%", "%%%%")), 1)
src = src:gsub(B:gsub("%p", "%%%0"), (B2:gsub("%%", "%%%%")), 1)
mc.Source = src
-- the nave: inner plaster faces x 6100.2..6129.8, z -309.6..-252.0, floor 2.1 up to the ridge
folder:SetAttribute("JapanChurchFrame", CFrame.new(6115, 14, -280.8))
folder:SetAttribute("JapanChurchHalfSize", Vector3.new(14.8, 13, 28.8))
folder:SetAttribute("japan_church", "81756301202358,139851043401845,136179244635591")   -- church1b: her "this soundtrack plays first 81756301202358"
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after church1") end)
return "QQ CHURCH1 MusicClient patched (church override + live audition key), backup HudBackup.MusicClient_pre_church1; japan_church = 139851043401845,136179244635591 (back to back, round again); box (6115, 14, -280.8) half (14.8, 13, 28.8) - EDIT INSTALLED; NOT PUBLISHED"
