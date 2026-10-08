-- chute_probe1 v1: READ-ONLY. How does the parachute from the skydiving squirrel work? Lists everything named like
-- parachute / chute / skydiv / glide / drift, where it lives, what attributes players get, and the hang glider's bits.
local hits = {}
local function scan(root, label)
	for _, d in ipairs(root:GetDescendants()) do
		local n = d.Name:lower()
		if n:find("parachute") or n:find("chute") or n:find("skydiv") or n:find("driftdown") or n:find("glider") or n:find("glide") then
			hits[#hits + 1] = string.format("%s: %s [%s]", label, d:GetFullName(), d.ClassName)
			if #hits > 60 then break end
		end
	end
end
scan(workspace, "ws"); scan(game:GetService("ReplicatedStorage"), "RS"); scan(game:GetService("ServerStorage"), "SS")
scan(game:GetService("ServerScriptService"), "SSS"); scan(game:GetService("StarterPlayer"), "SP"); scan(game:GetService("StarterGui"), "SG"); scan(game:GetService("StarterPack"), "SPk")
for i = 1, #hits, 5 do print("QQ CH " .. table.concat(hits, " | ", i, math.min(i + 4, #hits))) end
print("QQ CH total " .. #hits)
-- scripts mentioning a parachute or a saved flag for it
local function grep(root, label)
	for _, s in ipairs(root:GetDescendants()) do
		if s:IsA("LuaSourceContainer") then
			local ok, src = pcall(function() return s.Source end)
			if ok and src then
				local l = src:lower()
				if l:find("parachute") or l:find("chute") or l:find("skydiv") then
					local lines, n = {}, 0
					for line in (src .. "\n"):gmatch("(.-)\n") do
						n += 1
						local ll = line:lower()
						if ll:find("parachute") or ll:find("chute") or ll:find("skydiv") or ll:find("setattribute") and ll:find("has") then
							lines[#lines + 1] = n .. ": " .. line:gsub("^%s+", ""):sub(1, 100)
							if #lines >= 8 then break end
						end
					end
					print(string.format("QQ CH script %s (%s, %d lines): %s", s:GetFullName(), s.ClassName, n, table.concat(lines, " || ")))
				end
			end
		end
	end
end
grep(workspace, "ws"); grep(game:GetService("ServerScriptService"), "SSS"); grep(game:GetService("StarterPlayer"), "SP"); grep(game:GetService("ReplicatedStorage"), "RS"); grep(game:GetService("StarterGui"), "SG")
-- the squirrel registry entry for the parachute squirrel
local reg = workspace:FindFirstChild("SquirrelScripts") and workspace.SquirrelScripts:FindFirstChild("SquirrelRegistry")
if reg then
	local ok, src = pcall(function() return reg.Source end)
	if ok then
		for line in (src .. "\n"):gmatch("(.-)\n") do if line:lower():find("parachute") then print("QQ CH registry: " .. line:gsub("^%s+", ""):sub(1, 200)) end end
	end
end
print("QQ CH DONE")
