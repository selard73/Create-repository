-- install_give44 v1: puts a TEST-ONLY server script in ServerScriptService that, in Studio play tests only, gives every
-- player all 44 squirrel finds (as the attributes the game reads). Delete the script before publishing; it is also inert
-- outside Studio. Re-running replaces it. tools/boat/remove_give44.lua takes it out.
local SSS = game:GetService("ServerScriptService")
local NAME = "ZZ_TEST_Give44_DELETE_BEFORE_PUBLISH"
local old = SSS:FindFirstChild(NAME); if old then old:Destroy() end
local s = Instance.new("Script")
s.Name = NAME
s.Source = [=====[-- ZZ_TEST_Give44 (TEST ONLY - delete this script before publishing; it also does nothing outside Studio).
-- In Studio play tests it gives every player all 44 squirrel finds as the attributes the game reads (Found_forest,
-- Found_village, Found_domaine, FoundIds, SquirrelsFound), so the gates, the shop, the boat and the Sky Diving Squirrel
-- treat them as finished. It never touches the DataStore or SquirrelSetup's own list, and it puts the counts back whenever
-- something lowers them (finding a squirrel, Reset progress). Installed Oct 1 2026 for the waterfall tests.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local folder = workspace:WaitForChild("SquirrelScripts")
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local per, ids, total = {}, {}, 0
for _, e in ipairs(Registry.squirrels) do
	per[e.map] = (per[e.map] or 0) + 1
	ids[#ids + 1] = e.id
	total += 1
end
table.sort(ids)
local idList = table.concat(ids, ",")
local names = {"FoundIds", "SquirrelsFound"}
for _, m in ipairs(Registry.maps) do names[#names + 1] = "Found_" .. m.id end
local function assert44(p)
	if not p.Parent then return end
	for _, m in ipairs(Registry.maps) do
		if p:GetAttribute("Found_" .. m.id) ~= (per[m.id] or 0) then p:SetAttribute("Found_" .. m.id, per[m.id] or 0) end
	end
	if p:GetAttribute("FoundIds") ~= idList then p:SetAttribute("FoundIds", idList) end
	if p:GetAttribute("SquirrelsFound") ~= total then p:SetAttribute("SquirrelsFound", total) end
end
local function setup(p)
	-- wait for SquirrelSetup's own load (with API access off it retries the DataStore for a few seconds) so that its
	-- publish does not overwrite ours
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 20 do task.wait(0.25) end
	task.wait(0.5)
	if not p.Parent then return end
	assert44(p)
	for _, n in ipairs(names) do
		p:GetAttributeChangedSignal(n):Connect(function() task.defer(assert44, p) end)
	end
	print(string.format("ZZ_TEST_Give44: %s has all %d squirrels for this Studio session (nothing is saved)", p.Name, total))
end
Players.PlayerAdded:Connect(setup)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setup, p) end
]=====]
s.Parent = SSS
print("QQ G44 installed " .. s:GetFullName())
