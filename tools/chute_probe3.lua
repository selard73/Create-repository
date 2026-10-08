-- chute_probe3 v1: READ-ONLY. How do the other squirrels talk to players? Lists GUI/instances named like speech/bubble/say/
-- talk/dialogue, remote events with such names, and scripts whose source uses a BillboardGui or a speech-like function; prints
-- short snippets so the same mechanism can be reused for the Sky Diving Squirrel.
local hits = {}
local function scanNames(root, label)
	for _, d in ipairs(root:GetDescendants()) do
		local n = d.Name:lower()
		if n:find("bubble") or n:find("speech") or n:find("say") or n:find("talk") or n:find("dialog") or n:find("quote") or n:find("line") and d:IsA("GuiObject") then
			hits[#hits + 1] = string.format("%s: %s [%s]", label, d:GetFullName(), d.ClassName)
			if #hits > 40 then return end
		end
	end
end
scanNames(workspace, "ws"); scanNames(game:GetService("ReplicatedStorage"), "RS"); scanNames(game:GetService("StarterGui"), "SG"); scanNames(game:GetService("StarterPlayer"), "SP"); scanNames(game:GetService("ServerScriptService"), "SSS")
for i = 1, #hits, 5 do print("QQ P3 " .. table.concat(hits, " | ", i, math.min(i + 4, #hits))) end
print("QQ P3 names total " .. #hits)
local function scanSources(root, label)
	for _, s in ipairs(root:GetDescendants()) do
		if s:IsA("LuaSourceContainer") then
			local ok, src = pcall(function() return s.Source end)
			if ok and src then
				local l = src:lower()
				if l:find("billboardgui") or l:find("bubble") or l:find("speech") or l:find("function say") or l:find("local function talk") or l:find("dialogue") then
					local n, lines = 0, {}
					for line in (src .. "\n"):gmatch("(.-)\n") do
						n += 1
						local ll = line:lower()
						if ll:find("billboardgui") or ll:find("bubble") or ll:find("speech") or ll:find("function say") or ll:find("function talk") or ll:find("dialogue") or ll:find("function note") or ll:find("function show") then
							lines[#lines + 1] = n .. ": " .. line:gsub("^%s+", ""):sub(1, 110)
							if #lines >= 10 then break end
						end
					end
					print(string.format("QQ P3 script %s (%s, %d lines): %s", s:GetFullName(), s.ClassName, n, table.concat(lines, " || ")))
				end
			end
		end
	end
end
scanSources(workspace, "ws"); scanSources(game:GetService("ServerScriptService"), "SSS"); scanSources(game:GetService("StarterPlayer"), "SP"); scanSources(game:GetService("StarterGui"), "SG"); scanSources(game:GetService("ReplicatedStorage"), "RS")
print("QQ P3 DONE")
