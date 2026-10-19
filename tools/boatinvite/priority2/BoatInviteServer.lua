-- BoatInviteServer (workspace.BoatInvite): the one-click trip to the boat (Shannon, Oct 11 2026: "when the player finds the
-- last squirrel on the France map, we need a way to get their character to the dock where the boat is in a non awkward way";
-- "they should be able to take the boat with one click"). The card (BoatInviteClient) sends "go"; this checks the player has
-- found all 44 French squirrels, fades their screen with the luggage cart's fade (workspace.Travel.TravelEvent), puts them on
-- the jetty facing the moored boat, and fires ReplicatedStorage.BoatTake, which BoatServer answers by boarding them exactly
-- as its own jetty prompt does (the parachute is packed for everyone who has found all 44).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function need() local v = F:GetAttribute("Need"); return type(v) == "number" and v or 44 end
local function found(p) local n = 0; for _, m in ipairs(MAPS) do n += tonumber(p:GetAttribute("Found_" .. m)) or 0 end; return n end
local busy, last = {}, {}

local function travelEvent() local t = workspace:FindFirstChild("Travel"); return t and t:FindFirstChild("TravelEvent") end
local function note(p, text) local tev = travelEvent(); if tev then tev:FireClient(p, "note", text) end end

-- the jetty deck (x 160.4..163.9) beside the moored boat, found by a ray down; facing the boat
local function jettySpot()
	local River = workspace:FindFirstChild("River")
	local preview = River and River:FindFirstChild("BoatPreview")
	local visual = preview and preview:FindFirstChildWhichIsA("MeshPart", true)
	if not visual then return nil end
	local x, z = 162.2, math.clamp(visual.Position.Z + 3, -164, -148)   -- (a little up the deck from the boat: clear of the BATEAUX sign at -166..-168.5)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	local skip = {preview}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local boat = workspace:FindFirstChild("Boat"); if boat then table.insert(skip, boat) end
	rp.FilterDescendantsInstances = skip
	local top                                                    -- the highest of three rays (one may fall between two planks onto a stringer)
	for _, dz in ipairs({0, 0.45, -0.45}) do
		local hit = workspace:Raycast(Vector3.new(x, visual.Position.Y + 10, z + dz), Vector3.new(0, -25, 0), rp)   -- (from low: no tree or bridge above counts)
		if hit and (not top or hit.Position.Y > top) then top = hit.Position.Y end
	end
	top = top or visual.Position.Y + 2
	if top > visual.Position.Y + 8 or top < visual.Position.Y - 4 then top = visual.Position.Y + 2 end
	local pos = Vector3.new(x, top + 3.2, z)
	return CFrame.lookAt(pos, Vector3.new(visual.Position.X, pos.Y, visual.Position.Z))
end

local previewLast = {}
ev.OnServerEvent:Connect(function(p, what)
	if what == "preview" then
		if p:GetAttribute("SaveLoaded") ~= true or found(p) < need() or F:GetAttribute("Enabled") == false then return end
		local now = os.clock()
		if previewLast[p] and now - previewLast[p] < 10 then return end
		previewLast[p] = now
		local river = workspace:FindFirstChild("River")
		local model = river and river:FindFirstChild("BoatPreview")
		local visual = model and model:FindFirstChild("Boat")
		if not (visual and visual:IsA("BasePart")) then return end
		local position = visual.Position
		-- Load scenery only; the player is not moved until they choose Take the boat.
		pcall(function() p:RequestStreamAroundAsync(position, 3) end)
		if p.Parent == Players then ev:FireClient(p, "preview", position) end
		return
	end
	if what ~= "go" or busy[p] or os.clock() - (last[p] or 0) < 8 then return end
	if found(p) < need() and p.UserId ~= game.CreatorId then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	if hum.SeatPart then note(p, "Hop off first, then the boat is yours.") return end
	local take = RS:FindFirstChild("BoatTake")
	local cf = jettySpot()
	if not (take and take:IsA("BindableEvent") and cf) then note(p, "The boat is at the river dock, by the bridge.") return end
	busy[p] = true; last[p] = os.clock()
	local tev = travelEvent()
	if tev then tev:FireClient(p, "fade", F:GetAttribute("Place") or "The River Dock") end
	task.wait(0.45)                                              -- the screen is dark before anything moves (as the luggage cart)
	if char.Parent and root.Parent and hum.Health > 0 then
		pcall(function() p:RequestStreamAroundAsync(cf.Position, 3) end)
		root.AssemblyLinearVelocity = Vector3.zero
		char:PivotTo(cf)
		task.wait(0.25)
		take:Fire(p)                                             -- BoatServer boards them (its own checks: all 44, a free slot)
		print(string.format("BoatInvite: %s -> the boat", p.Name))
	end
	if tev then tev:FireClient(p, "arrived") end
	task.delay(2, function() busy[p] = nil end)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; last[p] = nil; previewLast[p] = nil end)
print("BoatInviteServer: ready")
