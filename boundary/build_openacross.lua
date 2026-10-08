-- OpenAcross: when a section unlocks, the whole line between it and the next one opens, not just the gateway.
-- Until now the only way through was the bridge gate or the garden gate; the rest of the divide stayed solid even
-- after you had earned your way past. This tags the two INNER divides - the river line between the forest and Rue de
-- Noisette, and the fence line between the Rue and the estate - and turns them walk-through for a player who has
-- found enough squirrels. The OUTER edge of the map (the forest's west, the north and south runs, the estate's far
-- side) is never tagged, so the world still holds you in.
-- Collision is turned off on the CLIENT, so it opens for the player who earned it and stays shut for everyone else.
-- Run in edit mode: require(workspace.OpenAcross.PatchModule)()  (packed by village/make_patch.py)
return function()
	local B
	for _, b in ipairs(workspace:GetChildren()) do
		if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
	end
	assert(B, "OpenAcross: no Boundary with a Walls folder")

	-- A wall built along z faces x, and only two such lines sit INSIDE the map: the river bank (x about 130..145)
	-- and the estate fence (x 352). Everything else is the outer edge and stays solid.
	local tagged = {village = 0, domaine = 0}
	for _, p in ipairs(B.Walls:GetChildren()) do
		if p:IsA("BasePart") then
			p:SetAttribute("Opens", nil)
			local lv = p.CFrame.LookVector
			local alongZ = math.abs(lv.X) > math.abs(lv.Z)       -- the wall runs north-south
			local x = p.Position.X
			if alongZ then
				if math.abs(x - 352) < 8 then
					p:SetAttribute("Opens", "domaine")            -- past it lies the estate; needs the Rue's squirrels
					tagged.domaine += 1
				elseif x > 95 and x < 175 then
					p:SetAttribute("Opens", "village")            -- past it lies the Rue; needs the forest's squirrels
					tagged.village += 1
				end
			end
		end
	end

	-- The bridge gate stands on its own with no fence either side, so an open leaf just looks like a gate abandoned
	-- in the grass. Once the crossing is earned it goes away and leaves the posts and the signpost. The garden gate
	-- sits in a picket run, where an open leaf reads properly, so it keeps its.
	local G = B:FindFirstChild("Gates")
	if G and G:FindFirstChild("VillageGate") then G.VillageGate:SetAttribute("HideWhenOpen", true) end
	if G and G:FindFirstChild("DomaineGate") then G.DomaineGate:SetAttribute("HideWhenOpen", nil) end

	local old = workspace:FindFirstChild("OpenAcrossUI"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "OpenAcrossUI"; F.Parent = workspace
	local CLIENT = [==[
-- BoundaryOpen (client): the divide a player has earned their way past stops blocking them.
-- Only this player's copy of the wall changes, so two players at different stages each get the right map.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local boundary
for _, b in ipairs(workspace:GetChildren()) do
	if b.Name == "Boundary" and b:FindFirstChild("Walls") then boundary = b end
end
if not boundary then return end
local NEED = boundary:GetAttribute("Need") or 10
local BEHIND = {village = "forest", domaine = "village"}   -- which section's squirrels open this divide

local function refresh()
	for _, p in ipairs(boundary.Walls:GetChildren()) do
		local opens = p:IsA("BasePart") and p:GetAttribute("Opens")
		if opens then
			local need = BEHIND[opens]
			local found = need and player:GetAttribute("Found_" .. need) or 0
			p.CanCollide = not (found >= NEED)
		end
	end
end

-- a gate marked HideWhenOpen has nothing to lean against, so it is taken away rather than left swung open
local function gateLeaves()
	local G = boundary:FindFirstChild("Gates")
	if not G then return end
	for _, g in ipairs(G:GetChildren()) do
		local needMap = g:GetAttribute("NeedMap")
		local leaf = g:FindFirstChild("Leaf")
		if needMap and leaf and g:GetAttribute("HideWhenOpen") then
			local gone = (player:GetAttribute("Found_" .. needMap) or 0) >= NEED
			for _, p in ipairs(leaf:GetDescendants()) do
				if p:IsA("BasePart") then p.Transparency = gone and 1 or 0; p.CanQuery = not gone end
			end
		end
	end
end

refresh()
gateLeaves()
for _, m in ipairs({"forest", "village"}) do
	player:GetAttributeChangedSignal("Found_" .. m):Connect(refresh)
	player:GetAttributeChangedSignal("Found_" .. m):Connect(function() task.delay(1.6, gateLeaves) end)
end
boundary.Walls.ChildAdded:Connect(function() task.defer(refresh) end)
player.CharacterAdded:Connect(function() task.delay(0.5, function() refresh(); gateLeaves() end) end)   -- a fresh character, the same open map
]==]
	local s = Instance.new("Script"); s.Name = "BoundaryOpen"; s.RunContext = Enum.RunContext.Client; s.Source = CLIENT; s.Parent = F
	print(string.format("OpenAcross: %d river-line sections and %d estate-fence sections will open once earned; the outer edge left solid",
		tagged.village, tagged.domaine))
end
