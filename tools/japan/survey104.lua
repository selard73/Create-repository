-- survey104.lua - READ-ONLY adversarial survey of Codex's Japan map (Studio EDIT mode; changes nothing, saves nothing). Job 104
-- (Shannon, Oct 15 2026: "codex made a 3rd map for Japan and I wanted you to do an adversarial survey of it to find things wrong so
-- we can fix them"). Runner 7's first look (survey104_probe) found workspace.JapanMap (20,373 parts, bulk at x 5200..7100,
-- z -1270..450, a mountain to y 306), JapanEnvironment + 3 AutomaticFoodSeatContact scripts, a private-preview gate in
-- ServerScriptService, four LocalScripts in StarterPlayerScripts, ~25 JapanBefore* backups in ServerStorage. This script looks for
-- what is WRONG: parts of Japan lying back in France / Porto, unanchored and floating and buried things, holes in the ground, scripts
-- elsewhere that Codex patched for Japan (BalloonServer, SpawnReturnServer, Travel...), sounds that play everywhere, prompts the
-- game's PromptClient will not draw (Style Default), signs' text, the Area attribute's reach, the preview gate's shape, memory and
-- the size of the backups. Prints "QQ JAPAN ..." lines (capped lists); send them all unchanged. Then export the scripts it lists.
local Stats = game:GetService("Stats")
local out, N = {}, 0
local function say(fmt, ...) N += 1; table.insert(out, "QQ JAPAN " .. string.format(fmt, ...)) end
local function v3(v) return string.format("(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z) end
local function path(o) return (o:GetFullName():gsub("^Workspace%.", "")) end
local function adler32(s)
	local a, b = 1, 0
	for i = 1, #s do a = (a + s:byte(i)) % 65521; b = (b + a) % 65521 end
	return b * 65536 + a
end
local function extents(list)
	local lo, hi, n = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9), 0
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then
			n += 1
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	if n == 0 then return nil end
	return lo, hi, n
end
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ JAPAN ABORT - workspace.JapanMap not found") return end
local T = workspace.Terrain
local all = J:GetDescendants()
local parts = {}
for _, d in ipairs(all) do if d:IsA("BasePart") then table.insert(parts, d) end end
local lo, hi = extents(parts)
say("JapanMap %s: %d descendants, %d parts, box %s..%s; StreamingEnabled %s (min %d target %d, mode %s)", J.ClassName, #all, #parts, v3(lo), v3(hi),
	tostring(workspace.StreamingEnabled), workspace.StreamingMinRadius, workspace.StreamingTargetRadius, tostring(workspace.StreamingIntegrityMode))

-- ---------- (1) the shape: top-level children by size, and the parts of Japan that lie back west (x < 4500 = France / Porto) ----------
local kids = {}
for _, c in ipairs(J:GetChildren()) do
	local ds = c:GetDescendants(); if c:IsA("BasePart") then table.insert(ds, c) end
	local l, h, n = extents(ds)
	table.insert(kids, {c = c, n = n or 0, d = #ds, lo = l, hi = h})
end
table.sort(kids, function(a, b) return a.d > b.d end)
say("top-level children: %d", #kids)
for i, k in ipairs(kids) do
	if i > 24 then say("  ... and %d more children", #kids - 24) break end
	say("  %s (%s): %d parts; box %s..%s", k.c.Name, k.c.ClassName, k.n, k.lo and v3(k.lo) or "-", k.hi and v3(k.hi) or "-")
end
local west, westN = {}, 0
for _, p in ipairs(parts) do
	if p.Position.X < 4500 then westN += 1; if #west < 15 then table.insert(west, string.format("%s at %s size %s%s", path(p), v3(p.Position), v3(p.Size), p.Transparency >= 1 and " INVISIBLE" or "")) end end
end
say("parts of JapanMap west of x 4500 (in France / Porto's ground): %d", westN)
for _, l in ipairs(west) do say("  WEST %s", l) end

-- ---------- (2) every script that is Japan's or mentions Japan (outside the backups) ----------
local services = {"Workspace", "ServerScriptService", "ServerStorage", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService", "TextChatService"}
local scripts, backupScripts, backupDesc, backupFolders = {}, 0, 0, 0
for _, sname in ipairs(services) do
	local ok, svc = pcall(game.GetService, game, sname)
	if ok and svc then
		local list = svc:GetDescendants()
		for _, d in ipairs(list) do
			if d:IsA("LuaSourceContainer") then
				local inBackup = false
				local a = d
				while a and a ~= game do
					if a.Parent == game:GetService("ServerStorage") and (a.Name:find("^JapanBefore") or a.Name == "JapanIntegrationBackup" or a.Name == "HudBackup") then inBackup = true break end
					a = a.Parent
				end
				if inBackup then backupScripts += 1
				else
					local src = d.Source
					local named = d.Name:lower():find("japan") ~= nil
					local mentions = src:lower():find("japan", 1, true) ~= nil
					if named or mentions then
						table.insert(scripts, {d = d, src = src, named = named, mentions = mentions})
					end
				end
			end
		end
	end
end
table.sort(scripts, function(a, b) return a.d:GetFullName() < b.d:GetFullName() end)
say("scripts named Japan* or whose Source mentions 'japan' (backups excluded; %d scripts sit in the backups): %d", backupScripts, #scripts)
for _, s in ipairs(scripts) do
	local d = s.d
	local how = d:IsA("BaseScript") and (d.ClassName .. "/" .. (d:IsA("Script") and tostring(d.RunContext):gsub("^Enum.RunContext.", "") or "Local") .. (d.Enabled and "" or " DISABLED")) or d.ClassName
	say("  SCRIPT %s [%s] %d chars adler32 %d%s", d:GetFullName(), how, #s.src, adler32(s.src), s.named and "" or " (patched: mentions Japan)")
end
-- the preview gate's shape
local SSS = game:GetService("ServerScriptService")
local acc = SSS:FindFirstChild("JapanPreviewAccess")
if acc and acc:IsA("ModuleScript") then
	local ok, m = pcall(require, acc)
	if ok and type(m) == "table" then
		local keys = {}
		for k, v in pairs(m) do
			local vs = type(v) == "table" and ("table[" .. #v .. "]") or (type(v) == "function" and "function" or tostring(v))
			table.insert(keys, tostring(k) .. "=" .. vs)
		end
		table.sort(keys)
		say("JapanPreviewAccess requires: %s", table.concat(keys, "; "))
	else say("JapanPreviewAccess require failed: %s", tostring(m)) end
else say("JapanPreviewAccess: %s", acc and acc.ClassName or "not found") end

-- ---------- (3) the backups' weight ----------
local SS = game:GetService("ServerStorage")
local ssAll = #SS:GetDescendants()
for _, c in ipairs(SS:GetChildren()) do
	if c.Name:find("^Japan") then backupFolders += 1; backupDesc += #c:GetDescendants() end
end
say("ServerStorage: %d descendants in all; %d Japan* folders hold %d of them (%.0f%%) - every one is in the place file and in server memory",
	ssAll, backupFolders, backupDesc, ssAll > 0 and backupDesc / ssAll * 100 or 0)
local okM, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
local tags = {}
for _, tag in ipairs({"Instances", "PhysicsParts", "GraphicsParts", "GraphicsTexture", "GraphicsMeshParts", "Sounds", "Script"}) do
	local ok, v = pcall(function() return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[tag]) end)
	if ok then table.insert(tags, string.format("%s %.0f", tag, v)) end
end
say("Studio memory now: total %s MB; %s", okM and string.format("%.0f", mem) or "?", table.concat(tags, ", "))

-- ---------- (4) physics: unanchored, huge, invisible-solid, floating and buried models ----------
local unanch, huge, invisSolid, neon, shadow, defaultNames = {}, {}, 0, 0, 0, 0
local counts = {}
local function bump(k) counts[k] = (counts[k] or 0) + 1 end
for _, p in ipairs(parts) do
	if not p.Anchored then if #unanch < 10 then table.insert(unanch, path(p) .. " at " .. v3(p.Position)) end; bump("unanchored") end
	if p.Size.Magnitude > 400 then if #huge < 8 then table.insert(huge, path(p) .. " size " .. v3(p.Size)) end; bump("huge") end
	if p.Transparency >= 1 and p.CanCollide then invisSolid += 1 end
	if p.Material == Enum.Material.Neon then neon += 1 end
	if p.CastShadow then shadow += 1 end
	if p.Name == "Part" or p.Name == "MeshPart" or p.Name == "Union" or p.Name == "UnionOperation" or p.Name == "WedgePart" then defaultNames += 1 end
	bump(p.ClassName)
end
say("unanchored parts: %d (a loose part falls, and a player can push it away for everyone)", counts.unanchored or 0)
for _, l in ipairs(unanch) do say("  LOOSE %s", l) end
say("huge parts (size > 400): %d", counts.huge or 0)
for _, l in ipairs(huge) do say("  HUGE %s", l) end
say("invisible solid parts (Transparency 1, CanCollide): %d; Neon parts %d; CastShadow parts %d of %d; default-named parts %d (%.0f%%); classes: MeshPart %d, Part %d, Union %d, Wedge %d, Truss %d",
	invisSolid, neon, shadow, #parts, defaultNames, #parts > 0 and defaultNames / #parts * 100 or 0, counts.MeshPart or 0, counts.Part or 0, counts.UnionOperation or 0, counts.WedgePart or 0, counts.TrussPart or 0)
-- floating / buried: per Model with at most 400 parts (buildings, props, trees)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local floating, buried, modelsChecked = {}, {}, 0
local floatN, buryN = 0, 0
local JAPAN_X = 4500
for _, m in ipairs(all) do
	if m:IsA("Model") then
		local ds = m:GetDescendants()
		local l, h, n = extents(ds)
		if l and n <= 400 and n >= 1 and l.X > JAPAN_X then
			modelsChecked += 1
			local cx, cz = (l.X + h.X) / 2, (l.Z + h.Z) / 2
			rp.FilterDescendantsInstances = {m}
			local hit = workspace:Raycast(Vector3.new(cx, l.Y - 0.2, cz), Vector3.new(0, -12, 0), rp)
			local width = math.max(h.X - l.X, h.Z - l.Z)
			if not hit and width < 60 then
				-- nothing within 12 studs under the model's bottom centre: floating (unless hung from above - a lantern, a sign)
				local up = workspace:Raycast(Vector3.new(cx, h.Y + 0.2, cz), Vector3.new(0, 6, 0), rp)
				if not up then floatN += 1; if #floating < 14 then table.insert(floating, string.format("%s (%d parts) bottom y %.1f at (%.0f,%.0f), %.0f wide", path(m), n, l.Y, cx, cz, width)) end end
			end
			local t = workspace:Raycast(Vector3.new(cx, 400, cz), Vector3.new(0, -800, 0))
			if t and t.Instance == T and h.Y < t.Position.Y - 0.5 then buryN += 1; if #buried < 10 then table.insert(buried, string.format("%s (%d parts) top y %.1f under terrain y %.1f at (%.0f,%.0f)", path(m), n, h.Y, t.Position.Y, cx, cz)) end end
		end
	end
end
say("models checked for floating / buried (<= 400 parts, east of x %d): %d; floating %d; buried under terrain %d", JAPAN_X, modelsChecked, floatN, buryN)
for _, l in ipairs(floating) do say("  FLOATING %s", l) end
for _, l in ipairs(buried) do say("  BURIED %s", l) end

-- ---------- (5) the ground: a 50-stud grid over the bulk, what a ray from y 400 finds ----------
local void, voidList, mats, partHits, total = 0, {}, {}, 0, 0
for x = 5200, 7100, 50 do
	for z = -1270, 450, 50 do
		total += 1
		local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0))
		if not r then void += 1; if #voidList < 15 then table.insert(voidList, string.format("(%d,%d)", x, z)) end
		elseif r.Instance == T then mats[r.Material.Name] = (mats[r.Material.Name] or 0) + 1
		else partHits += 1 end
	end
end
local ml = {}
for k, v in pairs(mats) do table.insert(ml, k .. " " .. v) end
table.sort(ml)
say("ground grid (x 5200..7100, z -1270..450, every 50): %d rays; void (nothing to y -400) %d; parts %d; terrain: %s", total, void, partHits, table.concat(ml, ", "))
if #voidList > 0 then say("  VOID at %s", table.concat(voidList, " ")) end

-- ---------- (6) things to touch: seats, prompts, click detectors, NPCs ----------
local seats, seatsOff, prompts, styles, promptList, clicks, humanoids, spawns, spawnList = 0, 0, 0, {}, {}, 0, 0, 0, {}
for _, d in ipairs(all) do
	if d:IsA("Seat") or d:IsA("VehicleSeat") then seats += 1; if d.Disabled then seatsOff += 1 end
	elseif d:IsA("ProximityPrompt") then
		prompts += 1; styles[d.Style.Name] = (styles[d.Style.Name] or 0) + 1
		if #promptList < 20 then table.insert(promptList, string.format("%s/%s [%s%s] on %s", d.ObjectText, d.ActionText, d.Style.Name, d.Enabled and "" or " off", d.Parent and path(d.Parent) or "?")) end
	elseif d:IsA("ClickDetector") then clicks += 1
	elseif d:IsA("Humanoid") then humanoids += 1
	elseif d:IsA("SpawnLocation") then spawns += 1; if #spawnList < 6 then table.insert(spawnList, path(d) .. " at " .. v3(d.Position) .. (d.Enabled and "" or " off")) end
	end
end
local sl = {}
for k, v in pairs(styles) do table.insert(sl, k .. " " .. v) end
say("seats %d (%d disabled); ProximityPrompts %d (%s) - the game's PromptClient draws only Style Custom, a Default one shows Roblox's own box; ClickDetectors %d; Humanoids (NPCs) %d; SpawnLocations %d",
	seats, seatsOff, prompts, table.concat(sl, ", "), clicks, humanoids, spawns)
for _, l in ipairs(promptList) do say("  PROMPT %s", l) end
for _, l in ipairs(spawnList) do say("  SPAWN %s", l) end

-- ---------- (7) words on signs ----------
local texts, textN, fonts, nonAscii = {}, 0, {}, 0
local seenText = {}
for _, d in ipairs(all) do
	if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
		textN += 1; fonts[d.Font.Name] = true
		if d.Text:find("[\128-\255]") then nonAscii += 1 end
		if not seenText[d.Text] then seenText[d.Text] = true; if #texts < 30 then table.insert(texts, d.Text:gsub("\n", " / ")) end end
	end
end
local fl = {}
for k in pairs(fonts) do table.insert(fl, k) end
table.sort(fl)
say("text labels %d (%d with non-ASCII characters); fonts: %s", textN, nonAscii, table.concat(fl, ", "))
say("  TEXTS: %s", table.concat(texts, " | "))

-- ---------- (8) effects, sounds, lights ----------
local eff = {}
local function tick(k) eff[k] = (eff[k] or 0) + 1 end
local sounds, loud, global = 0, {}, {}
local meshIds, meshUnique = {}, 0
for _, d in ipairs(all) do
	if d:IsA("ParticleEmitter") then tick("ParticleEmitter") elseif d:IsA("Fire") then tick("Fire") elseif d:IsA("Smoke") then tick("Smoke")
	elseif d:IsA("Beam") then tick("Beam") elseif d:IsA("Trail") then tick("Trail")
	elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then tick("Light")
	elseif d:IsA("Decal") then tick("Decal") elseif d:IsA("Texture") then tick("Texture") elseif d:IsA("SurfaceAppearance") then tick("SurfaceAppearance")
	elseif d:IsA("SurfaceGui") then tick("SurfaceGui") elseif d:IsA("BillboardGui") then tick("BillboardGui")
	elseif d:IsA("Highlight") then tick("Highlight")
	elseif d:IsA("Sound") then
		sounds += 1
		local par = d.Parent
		local onPart = par and par:IsA("BasePart")
		if not onPart then table.insert(global, string.format("%s (%s, vol %.2f%s%s) under %s - heard everywhere, France included", d.Name, d.SoundId, d.Volume, d.Looped and " looped" or "", d.Playing and " PLAYING" or "", par and par.ClassName or "?"))
		elseif d.Playing and d.Looped and d.RollOffMaxDistance > 600 then table.insert(loud, string.format("%s vol %.2f max %d on %s", d.Name, d.Volume, d.RollOffMaxDistance, path(par))) end
	elseif d:IsA("MeshPart") and d.MeshId ~= "" then if not meshIds[d.MeshId] then meshIds[d.MeshId] = true; meshUnique += 1 end
	end
end
local el = {}
for k, v in pairs(eff) do table.insert(el, k .. " " .. v) end
table.sort(el)
say("effects: %s; sounds %d; unique mesh ids %d", table.concat(el, ", "), sounds, meshUnique)
for _, l in ipairs(global) do say("  SOUND-GLOBAL %s", l) end
for i, l in ipairs(loud) do if i > 8 then break end; say("  SOUND-FAR %s", l) end

-- ---------- (9) the globals Japan's scripts touch: Lighting and the water ----------
local L = game:GetService("Lighting")
local lk = {}
for _, c in ipairs(L:GetChildren()) do table.insert(lk, c.Name .. ":" .. c.ClassName .. (c:IsA("PostEffect") and (c.Enabled and "" or "(off)") or "")) end
say("Lighting children: %s; ClockTime %.1f; Terrain water refl %.2f transp %.2f wave %.2f (LookWas_* present: %s)", table.concat(lk, ", "), L.ClockTime,
	T.WaterReflectance, T.WaterTransparency, T.WaterWaveSize, tostring(T:GetAttribute("LookWas_WaterReflectance") ~= nil))

-- ---------- (10) how a player gets there: travel, spawn pads, gates; and the Area attribute ----------
local Tr = workspace:FindFirstChild("Travel")
if Tr then
	local names = {}
	for _, c in ipairs(Tr:GetChildren()) do table.insert(names, c.Name .. ":" .. c.ClassName) end
	say("workspace.Travel children: %s", table.concat(names, ", "))
	local jp = {}
	for _, d in ipairs(Tr:GetDescendants()) do
		local n = d.Name:lower()
		if n:find("japan") or n:find("tokyo") or n:find("kyoto") then table.insert(jp, path(d)) end
		for k, v in pairs(d:GetAttributes()) do if type(v) == "string" and v:lower():find("japan") then table.insert(jp, path(d) .. "." .. k .. "=" .. v) end end
	end
	say("Travel things named for Japan: %s", #jp > 0 and table.concat(jp, "; ") or "none")
else say("workspace.Travel: not found") end
local pads = workspace:FindFirstChild("SpawnPads")
if pads then
	local l = {}
	for _, p in ipairs(pads:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("Area") then table.insert(l, p.Name .. "(" .. tostring(p:GetAttribute("Area")) .. ") " .. v3(p.Position)) end end
	say("SpawnPads with an Area attribute: %s", table.concat(l, "; "))
end
local B = workspace:FindFirstChild("Boundary")
if B then
	local l = {}
	for _, c in ipairs(B:GetChildren()) do table.insert(l, c.Name) end
	say("Boundary children: %s", table.concat(l, ", "))
end
say("Area today (SpawnReturnServer.areaAt): z < -300 is 'porto', else the French ids by x - Japan at z -1270..450 straddles that line; what Codex's live SpawnReturnServer does with x > 4500 is in its export")
-- squirrel-like models in Japan
local sq = {}
for _, d in ipairs(all) do
	if d:IsA("Model") then local n = d.Name:lower(); if n:find("squirrel") or n:find("_color$") then if #sq < 12 then table.insert(sq, path(d)) end end end
end
say("squirrel-like models under JapanMap: %d%s", #sq, #sq > 0 and (" - " .. table.concat(sq, "; ")) or " (none; the registry has no Japan entries either)")
for _, l in ipairs(out) do print(l) end
print(string.format("QQ JAPAN END (%d lines)", N))
