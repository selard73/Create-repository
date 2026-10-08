-- chute_probe2 v1: READ-ONLY. (a) How does SquirrelSetup store which squirrels a player has found (so the boat can ask
-- "has this player found parachute_squirrel?"); (b) what the Sky Diving Squirrel model is made of (is there a chute mesh
-- to reuse for the player's parachute?); (c) how the hang glider's client takes over a character (pattern to borrow).
local setup = workspace.SquirrelScripts:FindFirstChild("SquirrelSetup")
if setup then
	local ok, src = pcall(function() return setup.Source end)
	if ok then
		local n, lines = 0, {}
		for line in (src .. "\n"):gmatch("(.-)\n") do
			n += 1
			local l = line:lower()
			if (l:find("found") and (l:find("attribute") or l:find("datastore") or l:find("table") or l:find("remote") or l:find("function"))) or l:find("bindable") or l:find("getfound") or l:find("isfound") or l:find("^local found") then
				lines[#lines + 1] = n .. ": " .. line:gsub("^%s+", ""):sub(1, 120)
				if #lines >= 24 then break end
			end
		end
		print(string.format("QQ C2 SquirrelSetup %d lines", n))
		for i = 1, #lines, 4 do print("QQ C2   " .. table.concat(lines, " || ", i, math.min(i + 3, #lines))) end
	end
end
local sq = workspace:FindFirstChild("parachute_squirrel_color")
if sq then
	local parts = {}
	for _, d in ipairs(sq:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts + 1] = string.format("%s[%s] %.1fx%.1fx%.1f%s", d.Name, d.ClassName, d.Size.X, d.Size.Y, d.Size.Z, d:IsA("MeshPart") and (" mesh " .. d.MeshId:sub(-16)) or "") end
	end
	print("QQ C2 parachute_squirrel_color parts (" .. #parts .. "): " .. table.concat(parts, "; ", 1, math.min(14, #parts)))
	local attrs = {}
	for k, v in pairs(sq:GetAttributes()) do attrs[#attrs + 1] = k .. "=" .. tostring(v) end
	print("QQ C2 its attributes: " .. table.concat(attrs, ", "))
end
local gc = workspace:FindFirstChild("HangGlider") and workspace.HangGlider:FindFirstChild("GliderClient")
if gc then
	local ok, src = pcall(function() return gc.Source end)
	if ok then
		local n, lines = 0, {}
		for line in (src .. "\n"):gmatch("(.-)\n") do
			n += 1
			local l = line:lower()
			if l:find("linearvelocity") or l:find("bodyvelocity") or l:find("vectorforce") or l:find("platformstand") or l:find("humanoidstate") or l:find("steer") or l:find("sink") or l:find("gravity") then
				lines[#lines + 1] = n .. ": " .. line:gsub("^%s+", ""):sub(1, 110)
				if #lines >= 16 then break end
			end
		end
		print(string.format("QQ C2 GliderClient %d lines", n))
		for i = 1, #lines, 4 do print("QQ C2   " .. table.concat(lines, " || ", i, math.min(i + 3, #lines))) end
	end
end
-- a player attribute that already lists finds?
local p = game.Players:GetPlayers()[1]
if p then
	local attrs = {}
	for k, v in pairs(p:GetAttributes()) do attrs[#attrs + 1] = k .. "=" .. tostring(v):sub(1, 60) end
	print("QQ C2 player attrs: " .. table.concat(attrs, ", "))
else
	print("QQ C2 no player in edit mode (expected)")
end
print("QQ C2 DONE")
