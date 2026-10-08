-- champion_probe1 v1: READ-ONLY. Where "Grand Keeper of the Great Acorn" is awarded: the lines in every script that mention
-- it, ChampionServer's claim logic (lines 560-676) and its DataStore use, and the Champion folder's attributes.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local function lines(t) local out = {}; for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end; return out end
local roots = {workspace, game:GetService("ServerScriptService"), game:GetService("StarterGui"), game:GetService("StarterPlayer"), game:GetService("ReplicatedStorage")}
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			local t = src(d)
			if t and (t:find("Grand Keeper", 1, true) or t:find("GrandKeeper", 1, true)) then
				local L = lines(t)
				print(string.format("QQ CH === %s [%s] %d lines", d:GetFullName(), d.ClassName, #L))
				local n = 0
				for i, l in ipairs(L) do
					if l:find("Grand Keeper", 1, true) or l:find("GrandKeeper", 1, true) or l:find("CreatorId", 1, true) or l:find("Async", 1, true) or l:find("GetDataStore", 1, true) then
						print(string.format("QQ CH   %d: %s", i, l:gsub("^%s+", ""):sub(1, 170))); n += 1
						if n >= 30 then break end
					end
				end
			end
		end
	end
end
local cs = workspace:FindFirstChild("Champion") and workspace.Champion:FindFirstChild("ChampionServer")
if cs then
	local L = lines(src(cs) or "")
	print("QQ CH ChampionServer " .. #L .. " lines; 560-676:")
	for i = 560, math.min(676, #L) do print(string.format("QQ CH %d: %s", i, L[i]:sub(1, 180))) end
	local attrs = {}
	for k, v in pairs(workspace.Champion:GetAttributes()) do attrs[#attrs + 1] = k .. "=" .. tostring(v):sub(1, 50) end
	table.sort(attrs)
	print("QQ CH Champion attrs: " .. table.concat(attrs, " | "))
end
print("QQ CH DONE")
