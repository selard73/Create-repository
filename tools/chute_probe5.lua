-- chute_probe5 v1: READ-ONLY. The ChaseClient bubble constants (NAVY, CREAM, FONT) and the Lagoon speech attributes.
local cc = workspace.Baguette:FindFirstChild("ChaseClient")
local ok, src = pcall(function() return cc.Source end)
if ok then
	local n = 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		n += 1
		if line:find("^local NAVY") or line:find("^local CREAM") or line:find("^local FONT") or line:find("^local GOLD") then print("QQ P5 " .. n .. ": " .. line:sub(1, 160)) end
	end
end
local lag = workspace:FindFirstChild("Lagoon")
if lag then
	local a = {}
	for k, v in pairs(lag:GetAttributes()) do if tostring(k):find("Speech") then a[#a + 1] = k .. "=" .. tostring(v) end end
	print("QQ P5 Lagoon: " .. table.concat(a, " | "))
end
print("QQ P5 DONE")
