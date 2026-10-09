-- race/passport_race1 (job 38): EDIT mode. The Passport outing "Piazza Race" (porto_race). Exact finds in
-- workspace.Passport.Catalogue (11291), Journal (14168), PassportVisuals (4105); compiled before writing; originals ->
-- ServerStorage.HudBackup.*_pre_race1. Output lines "QQ PRACE".
if game:GetService("RunService"):IsRunning() then warn("QQ PRACE ABORT - Play mode") return end
local P = workspace:FindFirstChild("Passport")
local Cat, Jr, Vis = P and P:FindFirstChild("Catalogue"), P and P:FindFirstChild("Journal"), P and P:FindFirstChild("PassportVisuals")
if not (Cat and Jr and Vis) then warn("QQ PRACE ABORT - missing Passport.Catalogue / Journal / PassportVisuals") return end
for s, n in pairs({[Cat] = 11291, [Jr] = 14168, [Vis] = 4105}) do
	if #s.Source ~= n then warn(string.format("QQ PRACE ABORT - %s is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {{Cat, "Catalogue", [===[
 {id="keeper",name="Keeper of the Great Acorn"]===], [===[
 {id="porto_race",name="Piazza Race",area="porto",icon="flag",hint="Race to find all 15 squirrels of the Via della Piazza.",detail="Start at the gate by the piazza and find all fifteen squirrels of the Via della Piazza against the clock. Beat your own best time for a few acorns; the ten fastest go on the board."},
 {id="keeper",name="Keeper of the Great Acorn"]===]}, {Jr, "Journal", [===[
 elseif id=="keeper" then return "First to complete all 44 squirrels that day!]===], [===[
 elseif id=="porto_race" then return string.format("Found all fifteen squirrels of the Via della Piazza in %d:%05.2f%s",math.floor((d.cs or 0)/6000),((d.cs or 0)%6000)/100,(d.improvement or 0)>0 and " - a personal best!" or ".")
 elseif id=="keeper" then return "First to complete all 44 squirrels that day!]===]}, {Vis, "PassportVisuals", [===[
porto_beach="surfing_squirrel"}]===], [===[
porto_beach="surfing_squirrel",porto_race="super_squirrel"}]===]}}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, f, r = pt[1], pt[2], pt[3], pt[4]
	local o = s.Source
	local a, b = o:find(f, 1, true)
	if not a then warn("QQ PRACE ABORT - " .. name .. " find not found; nothing changed") return end
	if o:find(f, b + 1, true) then warn("QQ PRACE ABORT - " .. name .. " find matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. r .. o:sub(b + 1)
	local fn, err = loadstring(o)
	if not fn then warn("QQ PRACE ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do local b = s:Clone(); b.Name = s.Name .. "_pre_race1"; b.Parent = backup; s.Source = o end
print(string.format("QQ PRACE DONE: Catalogue %d, Journal %d, PassportVisuals %d chars; backups ServerStorage.HudBackup.*_pre_race1", #Cat.Source, #Jr.Source, #Vis.Source))
