-- bubble_probe2 v1: READ-ONLY. (a) every speech-bubble implementation (BillboardGui + speak/say/bubble): header lines and the
-- lines that define the look; (b) the music client: how it goes quiet (Riding) and who else reads Riding; (c) the river line's
-- x range against the boat watchdog box (x 130..225); (d) every script that can move a player back (boundary, spawn return,
-- champion): the teleport lines.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local function lines(t) local out = {}; for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end; return out end
local function matching(tag, d, keys, maxn, from, to)
	local t = src(d); if not t then return end
	local L = lines(t)
	print(string.format("QQ BB === %s [%s] %d lines", d:GetFullName(), d.ClassName, #L))
	for i = 1, math.min(3, #L) do print(string.format("QQ BB   hdr %d: %s", i, L[i]:sub(1, 150))) end
	local shown = 0
	for i = from or 1, math.min(to or #L, #L) do
		local l = L[i]
		for _, k in ipairs(keys) do
			if l:find(k, 1, true) then
				print(string.format("QQ BB   %s %d: %s", tag, i, l:gsub("^%s+", ""):sub(1, 170)))
				shown += 1
				break
			end
		end
		if shown >= maxn then print("QQ BB   ... (more)"); break end
	end
end
local roots = {workspace, game:GetService("StarterGui"), game:GetService("StarterPlayer"), game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("ServerStorage")}
local all = {}
for _, root in ipairs(roots) do for _, d in ipairs(root:GetDescendants()) do if d:IsA("LuaSourceContainer") then all[#all + 1] = d end end end
-- (a) bubbles
local lookKeys = {"BillboardGui", "BackgroundColor3", "BackgroundTransparency", "TextColor3", "Font", "TextSize", "TextScaled", "Size =", "StudsOffset", "ExtentsOffset", "SizeOffset", "UICorner", "CornerRadius", "ImageLabel", "Image =", "ImageColor3", "ScaleType", "SliceCenter", "MaxDistance", "AlwaysOnTop", "UIStroke", "UIPadding", "Adornee", "TextWrapped", "AutomaticSize", "UISizeConstraint", "ZIndex", "SpeechSounds", "SpeechMax", "local function speak", "local function say", "local function bubble", "function Bubble", "Debris"}
local nb = 0
for _, d in ipairs(all) do
	local t = src(d)
	if t and t:find("BillboardGui", 1, true) and (t:find("speak", 1, true) or t:find("Bubble", 1, true) or t:find("bubble", 1, true) or t:find("say(", 1, true)) then
		nb += 1
		matching("look", d, lookKeys, 40)
	end
end
print("QQ BB bubble scripts: " .. nb)
-- (b) music + Riding
for _, d in ipairs(all) do
	local t = src(d)
	if t and t:find("MapMusic", 1, true) and (d:IsA("LocalScript") or t:find("RunContext", 1, true) or d.Name:find("Client")) then
		matching("music", d, {"Riding", "Attribute", "silent", "quiet", "Volume", "zone", "band", "local function", "Playing", "fade", "Stop", ":Play", "Area", "Seat", "boat", "Boat"}, 45)
	end
end
local nr = 0
for _, d in ipairs(all) do
	local t = src(d)
	if t and t:find("Riding", 1, true) then
		nr += 1
		matching("riding", d, {"Riding"}, 6)
	end
end
print("QQ BB scripts mentioning Riding: " .. nr)
-- (c) the river line vs the box
local River = workspace:FindFirstChild("River")
local line = River and River:GetAttribute("Line") or ""
local n, xmin, xmax, zmin, zmax, outside = 0, math.huge, -math.huge, math.huge, -math.huge, {}
for x, z, w in string.gmatch(line, "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
	x, z, w = tonumber(x), tonumber(z), tonumber(w)
	n += 1
	xmin = math.min(xmin, x - w); xmax = math.max(xmax, x + w); zmin = math.min(zmin, z); zmax = math.max(zmax, z)
	if x - w < 130 or x + w > 225 then outside[#outside + 1] = string.format("z%.0f x%.1f w%.1f", z, x, w) end
end
print(string.format("QQ BB river line: %d points, x(+-w) %.1f..%.1f, z %.1f..%.1f; outside the box x130..225: %d", n, xmin, xmax, zmin, zmax, #outside))
for i = 1, #outside, 6 do print("QQ BB   outside: " .. table.concat(outside, "; ", i, math.min(i + 5, #outside))) end
-- (d) things that move a player
local movers = {"Boundary.PatchModule", "Boundary.GateServer", "Boundary.GateClient", "SpawnReturn.SpawnReturnServer", "Champion.ChampionServer", "OpenAcrossUI.BoundaryOpen", "River.RiverCurrent", "Reset.PatchModule"}
for _, path in ipairs(movers) do
	local a, b = path:match("^(.-)%.(.+)$")
	local d = workspace:FindFirstChild(a) and workspace[a]:FindFirstChild(b, true)
	if d then matching("move", d, {"PivotTo", "MoveTo", "CFrame =", "SetPrimaryPartCFrame", "Spawn", "outside", "bounce", "teleport", "LoadCharacter", "Health = 0", "SquirrelsFound", "task.delay", "Region", "zmin", "zmax", "-251", "z <", "z >"}, 28) else print("QQ BB missing " .. path) end
end
print("QQ BB DONE")
