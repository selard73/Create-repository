-- plan_probe1 v1: READ-ONLY. Facts for the next build: the Map screen (how areas are drawn), the squirrel Registry maps, the
-- Passport tabs + activity ids + Journal API, the spawns and SpawnReturn order, the Boundary areas, and what exists south.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local function lines(t) local out = {}; for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end; return out end
local function grep(tag, d, keys, maxn)
	local t = d and src(d); if not t then print("QQ PL " .. tag .. ": missing"); return end
	local L = lines(t); local n = 0
	print(string.format("QQ PL === %s (%d lines)", tag, #L))
	for i, l in ipairs(L) do
		for _, k in ipairs(keys) do
			if l:find(k, 1, true) then print(string.format("QQ PL  %d: %s", i, l:gsub("^%s+", ""):sub(1, 170))); n += 1; break end
		end
		if n >= maxn then print("QQ PL  ..."); break end
	end
end
local function find(path) local cur = workspace; for seg in path:gmatch("[^%.]+") do cur = cur and cur:FindFirstChild(seg); end; return cur end
grep("HudBarClient", find("HudBarUI.HudBarClient"), {"AREAS", "areas = ", "{id = ", "Image = ", "ImageLabel", "rbxassetid", "MapImage", "local function refreshMap", "Map\"", "needs = ", "name = "}, 40)
grep("HudBar.PatchModule", find("HudBar.PatchModule"), {"AREAS", "{id = ", "Image = ", "rbxassetid", "name = "}, 16)
local reg = workspace.SquirrelScripts:FindFirstChild("SquirrelRegistry")
grep("SquirrelRegistry", reg, {"maps", "{id = ", "id = \"", "map = \"", "return"}, 30)
if reg then
	local ok, R = pcall(require, reg)
	if ok and type(R) == "table" then
		local per = {}
		for _, e in ipairs(R.squirrels or {}) do per[e.map] = (per[e.map] or 0) + 1 end
		local parts = {}
		for _, m in ipairs(R.maps or {}) do parts[#parts + 1] = string.format("%s(%s)=%d", tostring(m.id), tostring(m.name or m.title), per[m.id] or 0) end
		print("QQ PL Registry maps: " .. table.concat(parts, ", ") .. "; squirrels " .. #(R.squirrels or {}))
	end
end
grep("PassportClient", find("Passport.PassportClient"), {"Outings", "Completed", "Clues", "local TABS", "tabs = ", "tab = ", "local function tab", "makeTab", "TextButton"}, 40)
grep("PassportServer", find("Passport.PassportServer"), {"\"find\"", "\"keeper\"", "\"zipline\"", "\"glider\"", "kinds", "ACTIVITIES", "local function activity", "OnEvent", "PassportActivity"}, 30)
grep("Journal", find("Passport.Journal"), {"function Journal.", "function M.", "return {", "outings", "clues", "completed", "area"}, 30)
local sp = {}
for _, c in ipairs(workspace:GetChildren()) do if c.Name:find("^Spawn_") then local p = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart", true); sp[#sp + 1] = string.format("%s[%s] %s", c.Name, c.ClassName, p and string.format("(%.0f,%.0f,%.0f)", p.Position.X, p.Position.Y, p.Position.Z) or "?") end end
print("QQ PL spawns: " .. table.concat(sp, "; "))
grep("SpawnReturnServer", find("SpawnReturn.SpawnReturnServer"), {"ORDER", "NEED", "SavedArea", "Area"}, 12)
grep("Boundary.PatchModule areas", find("Boundary.PatchModule"), {"{id = ", "needMap", "name = ", "back = "}, 14)
local names = {}
for _, c in ipairs(workspace:GetChildren()) do local n = c.Name:lower(); if n:find("porto") or n:find("ital") or n:find("harbour") or n:find("harbor") or n:find("south") or n:find("cove") or n:find("nocciola") then names[#names + 1] = c.Name .. "[" .. c.ClassName .. "]" end end
print("QQ PL south things: " .. table.concat(names, ", "))
local sg = workspace:FindFirstChild("SouthGorge")
if sg then local k = {}; for _, c in ipairs(sg:GetChildren()) do k[#k + 1] = c.Name end; print("QQ PL SouthGorge children: " .. table.concat(k, ", ")) end
print("QQ PL DONE")
