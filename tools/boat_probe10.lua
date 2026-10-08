-- boat_probe10 v1: READ-ONLY. Before publishing: how does the boat ride end today? Prints the BoatServer/BoatClient source
-- lines about stops, limits, the river line and speeds; the River attributes; the prompt state; the boat's position.
local function grepSource(s, label)
	if not s then print("QQ BP " .. label .. " MISSING"); return end
	local ok, src = pcall(function() return s.Source end)
	if not ok then print("QQ BP " .. label .. " source not readable: " .. tostring(src)); return end
	local n, hits = 0, {}
	for line in (src .. "\n"):gmatch("(.-)\n") do
		n += 1
		local l = line:lower()
		if l:find("stop") or l:find("clamp") or l:find("limit") or l:find("line") or l:find("zmin") or l:find("zmax") or l:find("bound") or l:find("rim") or l:find("edge") or l:find("fall") or l:find("gorge") or l:find("-300") or l:find("-126") then
			hits[#hits + 1] = string.format("%d: %s", n, line:gsub("^%s+", ""):sub(1, 110))
		end
	end
	print(string.format("QQ BP %s: %d lines; hits %d", label, n, #hits))
	for i = 1, #hits, 6 do print("QQ BP   " .. table.concat(hits, " || ", i, math.min(i + 5, #hits))) end
end
local boatFolder = workspace:FindFirstChild("Boat")
if boatFolder then
	grepSource(boatFolder:FindFirstChild("BoatServer"), "BoatServer")
	grepSource(boatFolder:FindFirstChild("BoatClient"), "BoatClient")
	local kids = {}
	for _, c in ipairs(boatFolder:GetChildren()) do kids[#kids + 1] = c.Name .. "[" .. c.ClassName .. "]" end
	print("QQ BP workspace.Boat children: " .. table.concat(kids, ", "))
else
	print("QQ BP workspace.Boat MISSING")
end
local river = workspace:FindFirstChild("River")
if river then
	local attrs = {}
	for k, v in pairs(river:GetAttributes()) do attrs[#attrs + 1] = k .. "=" .. tostring(v):sub(1, 160) end
	print("QQ BP River attributes: " .. table.concat(attrs, " | "))
	local kids = {}
	for _, c in ipairs(river:GetChildren()) do kids[#kids + 1] = c.Name .. "[" .. c.ClassName .. "]" end
	print("QQ BP River children: " .. table.concat(kids, ", "))
	local bp = river:FindFirstChild("BoatPreview")
	local prompt = bp and bp:FindFirstChild("BoatPrompt", true)
	print(string.format("QQ BP prompt %s Enabled=%s; boat at %s", prompt and prompt:GetFullName() or "MISSING", prompt and tostring(prompt.Enabled) or "?", bp and bp:FindFirstChild("Boat") and tostring(bp.Boat.Position) or "?"))
end
-- anything named like a stop or buoy
local stops = {}
for _, d in ipairs(workspace:GetDescendants()) do
	local n = d.Name:lower()
	if (n:find("stop") or n:find("buoy") or n:find("barrier")) and d:IsA("BasePart") then stops[#stops + 1] = string.format("%s at (%.0f, %.0f, %.0f) size %s", d:GetFullName(), d.Position.X, d.Position.Y, d.Position.Z, tostring(d.Size)) end
end
print("QQ BP stop-like parts (" .. #stops .. "): " .. table.concat(stops, " | ", 1, math.min(8, #stops)))
print("QQ BP DONE")
