-- survey104.lua - READ-ONLY adversarial survey of Codex's Japan map (Studio EDIT mode; changes nothing, saves nothing). Job 104
-- (Shannon, Oct 15 2026: "codex made a 3rd map for Japan and I wanted you to do an adversarial survey of it to find things wrong so
-- we can fix them"). Runner 7's first look (survey104_probe) found workspace.JapanMap (20,373 parts, bulk at x 5200..7100,
-- z -1270..450, a mountain to y 306), JapanEnvironment + 3 AutomaticFoodSeatContact scripts, a private-preview gate in
-- ServerScriptService, four LocalScripts in StarterPlayerScripts, ~25 JapanBefore* backups in ServerStorage. This script looks for
-- what is WRONG: parts of Japan lying back in France / Porto, unanchored and floating and buried things, holes in the ground, scripts
-- elsewhere that Codex patched for Japan (BalloonServer, SpawnReturnServer, Travel...), sounds that play everywhere, signs' text, the
-- Area attribute's reach, the preview gate's shape (from its Source - nothing is required/run), memory and the size of the backups.
-- Round 2 (after the adversarial review): no NotScriptable reads, no require(), the model pass walks each part once, the body runs
-- under pcall so a fault still prints what was gathered, and the script RETURNS its lines too. Prints "QQ JAPAN ..." lines (capped
-- lists); send them all unchanged. Then export the scripts it lists.
local Stats = game:GetService("Stats")
local SS = game:GetService("ServerStorage")
local out, N = {}, 0
local function say(fmt, ...) N += 1; table.insert(out, "QQ JAPAN " .. string.format(fmt, ...)) end
local function v3(v) return v and string.format("(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z) or "-" end
local function path(o) return (o:GetFullName():gsub("^Workspace%.", "")) end
local function cut(s, n) s = s:gsub("\n", " / "); if #s > n then s = s:sub(1, n - 3) .. "..." end; return s end
local function adler32(s)
	local a, b = 1, 0
	for i = 1, #s do a = (a + s:byte(i)) % 65521; b = (b + a) % 65521 end
	return b * 65536 + a
end
local SGN = {-1, 1}
local function extents(list)
	local lo, hi, n = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9), 0
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then
			n += 1
			local h = p.Size / 2
			for _, sx in ipairs(SGN) do for _, sy in ipairs(SGN) do for _, sz in ipairs(SGN) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	if n == 0 then return nil end
	return lo, hi, n
end
local function isBackupFolder(name) return name:find("^JapanBefore") ~= nil or name == "JapanIntegrationBackup" or name == "HudBackup" end
local function inBackup(d)
	local a = d
	while a and a ~= game do
		if a.Parent == SS and isBackupFolder(a.Name) then return true end
		a = a.Parent
	end
	return false
end

local ok, err = pcall(function()
	local J = workspace:FindFirstChild("JapanMap")
	if not J then say("ABORT - workspace.JapanMap not found") return end
	local T = workspace.Terrain
	local all = J:GetDescendants()
	local parts = {}
	for _, d in ipairs(all) do if d:IsA("BasePart") then table.insert(parts, d) end end
	local lo, hi = extents(parts)
	say("JapanMap %s: %d descendants, %d parts, box %s..%s; workspace.StreamingEnabled %s", J.ClassName, #all, #parts, v3(lo), v3(hi), tostring(workspace.StreamingEnabled))

	-- ---------- (1) the shape: top-level children by size, and the parts of Japan that reach back west (x < 4500 = France / Porto) ----------
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
		say("  %s (%s): %d parts; box %s..%s", k.c.Name, k.c.ClassName, k.n, v3(k.lo), v3(k.hi))
	end
	local west, westN = {}, 0
	for _, p in ipairs(parts) do
		if p.Position.X - p.Size.Magnitude / 2 < 4500 then westN += 1; if #west < 15 then table.insert(west, string.format("%s at %s size %s%s", path(p), v3(p.Position), v3(p.Size), p.Transparency >= 1 and " INVISIBLE" or "")) end end
	end
	say("parts of JapanMap reaching west of x 4500 (France / Porto's ground): %d", westN)
	for _, l in ipairs(west) do say("  WEST %s", l) end

	-- ---------- (2) every script that is Japan's or mentions Japan (outside the backups) ----------
	local services = {"Workspace", "ServerScriptService", "ServerStorage", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService", "TextChatService"}
	local scripts, backupScripts = {}, 0
	for _, sname in ipairs(services) do
		local okS, svc = pcall(game.GetService, game, sname)
		if okS and svc then
			for _, d in ipairs(svc:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					if inBackup(d) then backupScripts += 1
					else
						local src = d.Source
						local named = d.Name:lower():find("japan") ~= nil
						local mentions = src:lower():find("japan", 1, true) ~= nil
						if named or mentions then table.insert(scripts, {d = d, src = src, named = named}) end
					end
				end
			end
		end
	end
	table.sort(scripts, function(a, b) return a.d:GetFullName() < b.d:GetFullName() end)
	say("scripts named Japan* or whose Source mentions 'japan' (backups excluded; %d scripts sit in the backups): %d", backupScripts, #scripts)
	for i, s in ipairs(scripts) do
		if i > 60 then say("  ... and %d more scripts", #scripts - 60) break end
		local d = s.d
		local how = d:IsA("BaseScript") and (d.ClassName .. "/" .. (tostring(d.RunContext):gsub("^Enum.RunContext.", "")) .. (d.Enabled and "" or " DISABLED")) or d.ClassName
		say("  SCRIPT %s [%s] %d chars adler32 %d%s", d:GetFullName(), how, #s.src, adler32(s.src), s.named and "" or " (patched: mentions Japan)")
	end
	-- the preview gate's shape, read from its Source (never required: a module can do anything when it loads)
	local SSS = game:GetService("ServerScriptService")
	local acc = SSS:FindFirstChild("JapanPreviewAccess")
	if acc and acc:IsA("ModuleScript") then
		local src = acc.Source
		local keys = {}
		for k in src:gmatch("\n%s*([%w_%.]+)%s*=") do if #keys < 40 then table.insert(keys, k) end end
		local ids = 0
		for _ in src:gmatch("%d%d%d%d%d%d%d+") do ids += 1 end
		say("JapanPreviewAccess (ModuleScript, %d chars, adler32 %d): assignments %s; %d long numbers (user ids?)", #src, adler32(src), table.concat(keys, ", "), ids)
	else say("JapanPreviewAccess: %s", acc and acc.ClassName or "not found") end

	-- ---------- (3) the backups' weight ----------
	local ssAll = #SS:GetDescendants()
	local bFolders, bDesc, wFolders, wDesc = 0, 0, 0, 0
	for _, c in ipairs(SS:GetChildren()) do
		if isBackupFolder(c.Name) and c.Name:find("^Japan") then bFolders += 1; bDesc += #c:GetDescendants()
		elseif c.Name:find("^Japan") then wFolders += 1; wDesc += #c:GetDescendants() end
	end
	say("ServerStorage: %d descendants in all; %d Japan backup folders hold %d (%.0f%%), %d other Japan* folders hold %d - all of it is in the place file and in server memory",
		ssAll, bFolders, bDesc, ssAll > 0 and bDesc / ssAll * 100 or 0, wFolders, wDesc)
	local okM, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
	local tags = {}
	for _, tag in ipairs({"Instances", "BaseParts", "GraphicsParts", "GraphicsTexture", "GraphicsMeshParts", "Sounds", "Script"}) do
		local okT, v = pcall(function() return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[tag]) end)
		if okT then table.insert(tags, string.format("%s %.0f", tag, v)) end
	end
	say("Studio memory now: total %s MB; %s", okM and string.format("%.0f", mem) or "?", table.concat(tags, ", "))

	-- ---------- (4) physics: unanchored, huge, invisible-solid; floating and buried models ----------
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
	-- parts per Model, one walk per part up its ancestors (no extents on the big container models)
	local pc = {}
	for _, p in ipairs(parts) do
		local a = p.Parent
		while a and a ~= J do if a:IsA("Model") then pc[a] = (pc[a] or 0) + 1 end; a = a.Parent end
	end
	-- the top-most models of at most 400 parts (a prop, a tree, a house - not the district they stand in)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local floating, buried, modelsChecked, floatN, buryN = {}, {}, 0, 0, 0
	local JAPAN_X = 4500
	for m, n in pairs(pc) do
		if n <= 400 then
			local par = m.Parent
			local top = true
			while par and par ~= J do if par:IsA("Model") and (pc[par] or 0) <= 400 then top = false break end; par = par.Parent end
			if top then
				local l, h = extents(m:GetDescendants())
				if l and l.X > JAPAN_X then
					modelsChecked += 1
					local cx, cz = (l.X + h.X) / 2, (l.Z + h.Z) / 2
					local width = math.max(h.X - l.X, h.Z - l.Z)
					rp.FilterDescendantsInstances = {m}
					if width < 60 then
						local hit = workspace:Raycast(Vector3.new(cx, l.Y + 0.5, cz), Vector3.new(0, -12.5, 0), rp)
						if not hit then
							local up = workspace:Raycast(Vector3.new(cx, h.Y + 0.2, cz), Vector3.new(0, 6, 0), rp)
							if not up then floatN += 1; if #floating < 14 then table.insert(floating, string.format("%s (%d parts) bottom y %.1f at (%.0f,%.0f), %.0f wide", path(m), n, l.Y, cx, cz, width)) end end
						end
					end
					local t = workspace:Raycast(Vector3.new(cx, 400, cz), Vector3.new(0, -800, 0))
					if t and t.Instance == T and t.Material ~= Enum.Material.Water and h.Y < t.Position.Y - 0.5 then
						buryN += 1; if #buried < 10 then table.insert(buried, string.format("%s (%d parts) top y %.1f under terrain y %.1f at (%.0f,%.0f)", path(m), n, h.Y, t.Position.Y, cx, cz)) end
					end
				end
			end
		end
	end
	say("top-most models of <= 400 parts east of x %d checked: %d; FLOATING (nothing within 12 studs under the bottom centre, nothing 6 above - bridges, arches and sunk props can trip it: verify by eye) %d; BURIED under terrain (terrain only, water ignored) %d", JAPAN_X, modelsChecked, floatN, buryN)
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
	say("seats %d (%d disabled); ProximityPrompts %d (%s; Default in Edit is normal - PromptClient turns every prompt in workspace Custom at run time); ClickDetectors %d; Humanoids (NPCs) %d; SpawnLocations %d",
		seats, seatsOff, prompts, table.concat(sl, ", "), clicks, humanoids, spawns)
	for _, l in ipairs(promptList) do say("  PROMPT %s", l) end
	for _, l in ipairs(spawnList) do say("  SPAWN %s", l) end

	-- ---------- (7) words on signs ----------
	local texts, textN, fonts, nonAscii, seenText = {}, 0, {}, 0, {}
	for _, d in ipairs(all) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
			textN += 1; fonts[d.Font.Name] = true
			if d.Text:find("[\128-\255]") then nonAscii += 1 end
			if not seenText[d.Text] then seenText[d.Text] = true; if #texts < 30 then table.insert(texts, cut(d.Text, 80)) end end
		end
	end
	local fl = {}
	for k in pairs(fonts) do table.insert(fl, k) end
	table.sort(fl)
	say("text labels %d (%d with non-ASCII characters); fonts: %s", textN, nonAscii, table.concat(fl, ", "))
	say("  TEXTS: %s", table.concat(texts, " | "))

	-- ---------- (8) effects, sounds, lights (music the Japan LocalScripts make at run time is invisible to an Edit survey) ----------
	local eff = {}
	local function tick(k) eff[k] = (eff[k] or 0) + 1 end
	local sounds, loud, global, globalN = 0, {}, {}, 0
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
			local positional = par and (par:IsA("BasePart") or par:IsA("Attachment"))
			if not positional then
				globalN += 1
				if #global < 12 then table.insert(global, string.format("%s (%s, vol %.2f%s%s) under %s - heard everywhere, France included", d.Name, d.SoundId, d.Volume, d.Looped and " looped" or "", d.Playing and " PLAYING" or "", par and par.ClassName or "?")) end
			elseif d.Playing and d.Looped then
				local mode = d.RollOffMode.Name
				local far = ((mode == "Linear" or mode == "LinearSquare") and d.RollOffMaxDistance > 600) or ((mode == "Inverse" or mode == "InverseTapered") and d.RollOffMinDistance > 60)
				if far and #loud < 8 then table.insert(loud, string.format("%s vol %.2f %s min %d max %d on %s", d.Name, d.Volume, mode, d.RollOffMinDistance, d.RollOffMaxDistance, path(par))) end
			end
		elseif d:IsA("MeshPart") and d.MeshId ~= "" then if not meshIds[d.MeshId] then meshIds[d.MeshId] = true; meshUnique += 1 end
		end
	end
	local el = {}
	for k, v in pairs(eff) do table.insert(el, k .. " " .. v) end
	table.sort(el)
	say("effects: %s; sounds %d (%d not on a part or attachment); unique mesh ids %d", table.concat(el, ", "), sounds, globalN, meshUnique)
	for _, l in ipairs(global) do say("  SOUND-GLOBAL %s", l) end
	for _, l in ipairs(loud) do say("  SOUND-FAR %s", l) end

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
			if #jp >= 40 then break end
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
	say("Area today (SpawnReturnServer.areaAt in the repo): z < -300 is 'porto', else the French ids by x - Japan at z -1270..450 straddles that line; what Codex's live SpawnReturnServer does with x > 4500 is in its export")
	local sq = {}
	for _, d in ipairs(all) do
		if d:IsA("Model") then local n = d.Name:lower(); if n:find("squirrel") or n:find("_color$") then if #sq < 12 then table.insert(sq, path(d)) end end end
	end
	say("squirrel-like models under JapanMap: %d%s", #sq, #sq > 0 and (" - " .. table.concat(sq, "; ")) or " (none; the registry has no Japan entries either)")
end)
for _, l in ipairs(out) do print(l) end
if ok then print(string.format("QQ JAPAN END (%d lines)", N)) else print("QQ JAPAN ERROR after " .. N .. " lines: " .. tostring(err)) end
return table.concat(out, "\n") .. (ok and "" or ("\nQQ JAPAN ERROR " .. tostring(err)))
