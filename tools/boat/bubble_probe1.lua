-- bubble_probe1 v1: READ-ONLY. Every script that builds a speech bubble (BillboardGui + speak/say/bubble): where it is, its
-- header lines (dates/versions), and the lines that define the look (colours, font, size, offsets, images, tails), so the
-- Sky Diving Squirrel can use exactly the croc-challenge style. Also the Lagoon and Baguette attributes.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local roots = {workspace, game:GetService("StarterGui"), game:GetService("StarterPlayer"), game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("ServerStorage"), game:GetService("StarterPack")}
local keys = {"BillboardGui", "BackgroundColor3", "BackgroundTransparency", "TextColor3", "Font", "TextSize", "TextScaled", "Size =", "Size=", "StudsOffset", "ExtentsOffset", "SizeOffset", "UICorner", "CornerRadius", "ImageLabel", "Image =", "Image=", "ImageColor3", "Tail", "tail", "MaxDistance", "AlwaysOnTop", "LightInfluence", "UIStroke", "Thickness", "UIPadding", "Adornee", "Debris", "TextWrapped", "AutomaticSize", "UISizeConstraint", "TextXAlignment", "ZIndex", "SpeechSounds", "SpeechMax", "Bubble", "bubble", "speak", "say("}
local n = 0
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			local t = src(d)
			if t and t:find("BillboardGui", 1, true) and (t:find("speak", 1, true) or t:find("Bubble", 1, true) or t:find("bubble", 1, true) or t:find("say(", 1, true) or t:find("Say", 1, true)) then
				n += 1
				local lines = {}
				for line in (t .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
				print(string.format("QQ BB === %s [%s] %d lines", d:GetFullName(), d.ClassName, #lines))
				for i = 1, math.min(4, #lines) do print(string.format("QQ BB   hdr %d: %s", i, lines[i]:sub(1, 150))) end
				local shown = 0
				for i, line in ipairs(lines) do
					local l = line
					local hit = false
					for _, k in ipairs(keys) do if l:find(k, 1, true) then hit = true; break end end
					if hit then
						print(string.format("QQ BB   %d: %s", i, l:gsub("^%s+", ""):sub(1, 160)))
						shown += 1
						if shown >= 45 then print("QQ BB   ... (more)"); break end
					end
				end
			end
		end
	end
end
print("QQ BB scripts with bubbles: " .. n)
for _, name in ipairs({"Lagoon", "Baguette", "Boat"}) do
	local f = workspace:FindFirstChild(name)
	if f then
		local attrs = {}
		for k, v in pairs(f:GetAttributes()) do attrs[#attrs + 1] = k .. "=" .. tostring(v):sub(1, 60) end
		table.sort(attrs)
		print("QQ BB attrs " .. name .. ": " .. table.concat(attrs, " | "))
		local kids = {}
		for _, c in ipairs(f:GetChildren()) do if c:IsA("LuaSourceContainer") or c:IsA("Folder") then kids[#kids + 1] = c.Name .. "[" .. c.ClassName .. "]" end end
		print("QQ BB kids " .. name .. ": " .. table.concat(kids, ", "))
	end
end
-- any bubble assets (images) in ReplicatedStorage / StarterGui named like a bubble
for _, root in ipairs({game:GetService("ReplicatedStorage"), game:GetService("StarterGui"), workspace:FindFirstChild("Lagoon") or workspace}) do
	for _, d in ipairs(root:GetDescendants()) do
		local nm = d.Name:lower()
		if (nm:find("bubble") or nm:find("speech") or nm:find("tail")) and not d:IsA("LuaSourceContainer") then
			print(string.format("QQ BB asset %s [%s]%s", d:GetFullName(), d.ClassName, d:IsA("ImageLabel") and (" image " .. d.Image) or ""))
		end
	end
end
print("QQ BB DONE")
