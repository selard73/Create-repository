-- boundaries3.lua (Oct 23 2026): PART 3 of the Japan boundaries - the scripts and the folder's settings.
--   JapanGateServer: new, on PortoGateServer's pattern - Found_japan_<area> per player from FoundIds + the registry
--     (map "japan", e.area = lantern / teahills / palace), and the safety net: anyone outside the OpenPolygon who may not be
--     there yet is walked back to the nearest GateNBack on the open side with a note. Tea Hills needs Need in Lantern Street,
--     Palace Grounds needs Need in Tea Hills; an area with ComingSoon_<area> = true is shut to everyone (no squirrels there yet).
--   JapanGateClient: PortoGateClient cloned and patched (names, attributes, the coming-soon state, the gates' sign text).
-- Settings on workspace.JapanGates: Need 10, Enabled true, ComingSoon_teahills / ComingSoon_palace true, OpenPolygon (the T:
-- Lantern Street between the stream and the canal bank fence from the mountains to the path edge z 117, plus everything south
-- of z 117 - the path, the stations, the train, the arrival lawn; a jog round the farm bridge's deck). "QQ BOUNDARIES3".
local G = workspace:FindFirstChild("JapanGates")
if not (G and G:GetAttribute("Boundaries2Gates")) then return "QQ BOUNDARIES3 ABORT: run parts 1 and 2 first" end
if G:FindFirstChild("JapanGateServer") then return "QQ BOUNDARIES3 already installed" end
local PC = workspace.PortoGates:FindFirstChild("PortoGateClient")
if not PC then return "QQ BOUNDARIES3 ABORT: no PortoGateClient to clone" end
local out = {}
local function say(s) table.insert(out, "QQ BOUNDARIES3 " .. s) end
local function count(s, needle) local n, i = 0, 1 while true do local a, b = s:find(needle, i, true) if not a then return n end n += 1 i = b + 1 end end
local function patch(src, old, new, label)
	assert(count(src, old) == 1, "patch '" .. label .. "' anchor found " .. count(src, old) .. " times")
	local a, b = src:find(old, 1, true)
	return src:sub(1, a - 1) .. new .. src:sub(b + 1)
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before boundaries3") end)
local NL = "\n"
-- ------------------------------------------------------------------ settings
G:SetAttribute("Need", 10)
G:SetAttribute("Enabled", true)
G:SetAttribute("ComingSoon_teahills", true)
G:SetAttribute("ComingSoon_palace", true)
G:SetAttribute("OpenPolygon", "5765,-430;5765,62;5745,62;5745,78;5765,78;5765,117;5300,117;5300,700;6700,700;6700,117;6126.5,117;6126.5,-226;6132.5,-242;6132.5,-430")
G:SetAttribute("Built", "Oct 23 2026 Japan area gates: Lantern Street first, Tea Hills second, Palace Grounds last")
for _, g in ipairs(G.Gates:GetChildren()) do
	if g:GetAttribute("ToName") == "the Palace" then g:SetAttribute("ToName", "Palace Grounds") end
	local label = g:FindFirstChild("Label", true)
	if label then label.Text = g:GetAttribute("ToName") .. "\nCOMING SOON" end
end
-- ------------------------------------------------------------------ the server
local server = Instance.new("Script"); server.Name = "JapanGateServer"
server.Source = [=[-- JapanGateServer (Oct 23 2026): Japan's area gates, server side, on PortoGateServer's pattern.
-- (1) Found_japan_lantern / _teahills / _palace: how many squirrels each player has found in each Japan area, from the
--     FoundIds list SquirrelSetup publishes and the registry's e.area, for the gates and the map.
-- (2) The safety net behind the fences: a player standing outside the OpenPolygon who may not be there yet (Tea Hills needs
--     Need found in Lantern Street, Palace Grounds needs Need in Tea Hills; a ComingSoon_<area> area is shut to all) is
--     walked back to the nearest GateNBack on the open side with a note. The owner passes (testing) unless NoOwnerBypass
--     is set, or StudioFreshJapan in Studio; GateBypass on a player passes too. Seated players are skipped.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local root = script.Parent
local NEED = root:GetAttribute("Need") or 10
local NL = string.char(10)
local AREA = {}
pcall(function()
	local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
	for _, e in ipairs(Registry.squirrels) do if e.map == "japan" and e.area then AREA[e.id] = e.area end end
end)
local function recount(player)
	local n = {lantern = 0, teahills = 0, palace = 0}
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do
		local a = AREA[id] or AREA[(id:gsub("_2$", ""))]
		if a and n[a] then n[a] += 1 end
	end
	for a, c in pairs(n) do if player:GetAttribute("Found_japan_" .. a) ~= c then player:SetAttribute("Found_japan_" .. a, c) end end
end
local function hook(p) recount(p) p:GetAttributeChangedSignal("FoundIds"):Connect(function() recount(p) end) end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(hook, p) end

local function parse(s)
	local t = {}
	for x, z in string.gmatch(s or "", "([%-%d%.]+),([%-%d%.]+)") do table.insert(t, Vector2.new(tonumber(x), tonumber(z))) end
	return t
end
local function inside(poly, p)
	local c, j = false, #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if ((a.Y > p.Y) ~= (b.Y > p.Y)) and (p.X < (b.X - a.X) * (p.Y - a.Y) / (b.Y - a.Y) + a.X) then c = not c end
		j = i
	end
	return c
end
local open = parse(root:GetAttribute("OpenPolygon"))
root:GetAttributeChangedSignal("OpenPolygon"):Connect(function() open = parse(root:GetAttribute("OpenPolygon")) end)
local function inJapan(p) return p.X > 5300 and p.X < 6700 and p.Z > -430 and p.Z < 700 and p.Y > -30 and p.Y < 200 end
local function backTo(names, pos)
	local best, bd
	for _, n in ipairs(names) do
		local cf = root:GetAttribute(n)
		if typeof(cf) == "CFrame" then local d = (cf.Position - pos).Magnitude if not bd or d < bd then best, bd = cf, d end end
	end
	return best
end
local function gold(t) return '<font color="#FFD65A">' .. t .. '</font>' end
local function bounce(player, char, cf, text)
	local h = char:FindFirstChildOfClass("Humanoid")
	if h and h.SeatPart then h.Sit = false task.wait(0.2) end
	char:PivotTo(cf)
	player:SetAttribute("JapanGateBounceText", text)
	player:SetAttribute("JapanGateBounce", os.clock())
end
local SOON = {teahills = "Tea Hills", palace = "Palace Grounds"}
while true do
	task.wait(0.5)
	if root:GetAttribute("Enabled") ~= false and #open > 2 then
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local owner = player.UserId == game.CreatorId and not root:GetAttribute("NoOwnerBypass")
				and not (RunService:IsStudio() and root:GetAttribute("StudioFreshJapan"))
			if hrp and hum and hum.Health > 0 and not hum.SeatPart and not owner and not player:GetAttribute("GateBypass") then
				local p = hrp.Position
				if inJapan(p) and not inside(open, Vector2.new(p.X, p.Z)) then
					local area = (p.X < 5950) and "teahills" or "palace"
					local soon = root:GetAttribute("ComingSoon_" .. area) == true
					local needArea = (area == "teahills") and "lantern" or "teahills"
					local fromName = (area == "teahills") and "Lantern Street" or "Tea Hills"
					local n = player:GetAttribute("Found_japan_" .. needArea) or 0
					if soon or n < NEED then
						local cf = backTo(area == "teahills" and {"Gate1Back", "Gate5Back"} or {"Gate2Back", "Gate3Back", "Gate4Back", "Gate6Back"}, p)
						if cf then
							local text = soon and (SOON[area] .. " is coming soon!" .. NL .. gold("Lantern Street first - more of Japan is on its way"))
								or string.format("Find %d squirrels in %s before going on to %s" .. NL .. gold("%d / %d found so far"), NEED, fromName, SOON[area], n, NEED)
							bounce(player, char, cf, text)
						end
					end
				end
			end
		end
	end
end
]=]
server.Parent = G
say("JapanGateServer written (" .. select(2, server.Source:gsub(NL, NL)) .. " lines)")
-- ------------------------------------------------------------------ the client: PortoGateClient, patched
local client = PC:Clone(); client.Name = "JapanGateClient"
local src = client.Source
src = patch(src, "-- PortoGateClient (Oct 8 2026): Porto's gates and walls for this player, like France (Boundary GateClient + BoundaryOpen).",
	"-- JapanGateClient (Oct 23 2026): PortoGateClient for Japan's gates - the same opening, note card and safety-net message, plus" .. NL ..
	"-- the coming-soon state (ComingSoon_<area> on the folder: the gate stays shut, the note and the sign say so) and the sign boards." .. NL ..
	"-- PortoGateClient (Oct 8 2026): Porto's gates and walls for this player, like France (Boundary GateClient + BoundaryOpen).", "header")
src = patch(src, 'local NAMES = {porto_harbour = "The Harbour", porto_borgo = "Via della Piazza", porto_groves = "The Groves"}',
	'local NAMES = {japan_lantern = "Lantern Street", japan_teahills = "Tea Hills", japan_palace = "Palace Grounds"}', "names")
src = patch(src, 'if e.map == "porto" and e.area then local k = "porto_" .. e.area', 'if e.map == "japan" and e.area then local k = "japan_" .. e.area', "registry")
src = patch(src, 'if old.Name == "PortoGateNote" then', 'if old.Name == "JapanGateNote" then', "old gui")
src = patch(src, 'gui.Name = "PortoGateNote"', 'gui.Name = "JapanGateNote"', "gui name")
src = patch(src, 'player:GetAttributeChangedSignal("PortoGateBounce"):Connect(function()', 'player:GetAttributeChangedSignal("JapanGateBounce"):Connect(function()', "bounce signal")
src = patch(src, 'player:GetAttribute("PortoGateBounceText")', 'player:GetAttribute("JapanGateBounceText")', "bounce text")
src = patch(src, 'for _, a in ipairs({"porto_harbour", "porto_borgo"}) do', 'for _, a in ipairs({"japan_lantern", "japan_teahills"}) do', "walls areas")
src = patch(src, [[		local n = found(area)
		local ok = isOpen(area)
		if ok then
			noteText = "The way to " .. toName .. " is open!" .. NL .. gold(string.format("%d / %d found in %s", n, TOTAL[area] or n, fromName))
		else
			noteText = string.format("Find %d squirrels in %s to open this gate", NEED, fromName) .. NL .. gold(string.format("%d / %d found so far", n, NEED))
		end]],
[[		local n = found(area)
		-- JAPAN: an area with no squirrels yet is "coming soon" - shut for everyone (Enabled = false still opens all, for testing)
		local soon = root:GetAttribute("Enabled") ~= false and root:GetAttribute("ComingSoon_" .. tostring(g:GetAttribute("ToArea"))) == true
		local ok = isOpen(area) and not soon
		if soon then
			noteText = toName .. " is coming soon!" .. NL .. gold("Lantern Street first - more of Japan is on its way")
		elseif ok then
			noteText = "The way to " .. toName .. " is open!" .. NL .. gold(string.format("%d / %d found in %s", n, TOTAL[area] or n, fromName))
		else
			noteText = string.format("Find %d squirrels in %s to open this gate", NEED, fromName) .. NL .. gold(string.format("%d / %d found so far", n, NEED))
		end
		local label = g:FindFirstChild("Label", true)
		if label then label.Text = toName .. NL .. (soon and "COMING SOON" or (ok and "OPEN" or string.format("%d / %d found", n, NEED))) end]], "refresh")
-- the coming-soon flags must refresh the gates too
src = patch(src, '	root:GetAttributeChangedSignal("Enabled"):Connect(refresh)' .. NL .. '	refresh()',
	'	root:GetAttributeChangedSignal("Enabled"):Connect(refresh)' .. NL .. '	root:GetAttributeChangedSignal("ComingSoon_" .. tostring(g:GetAttribute("ToArea"))):Connect(refresh)' .. NL .. '	refresh()', "soon signal")
client.Source = src
client.Parent = G
say("JapanGateClient cloned from PortoGateClient and patched (9 patches, each found once); RunContext " .. client.RunContext.Name)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after boundaries3") end)
say("DONE part 3 (scripts + settings) - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
