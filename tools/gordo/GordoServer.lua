-- GordoServer (workspace.Gordo; gordo1, Oct 22 2026): Gordo moves into your treehouse. Shannon: "Gordo squirrel, moves in
-- to 'watch the house while you are way' once the player has traveled to Italy- after about 1 minute of Italy game play, a
-- funny message pops up about it. when they return home to the treehouse, Gordo is in there to meet them and periodically
-- says funny things using the speech bubble."
-- A player's seconds in Italy (Area "porto") count while their treehouse room stands (its walls are up - the stage
-- TreehouseClient draws them at); at ItalySeconds (60) the ledger gets Item_gordo_home = 1 (RS.AwardItems, never a
-- DataStore) and RS.GordoMovedIn tells the player (GordoClient's note). The first time he greets them at home the client
-- says "met" and it becomes 2, so the first-ever greeting is said once. GordoClient draws him and does the talking.
-- A bare coloured copy of Gordo waits in RS.GordoHome for the clients (the forest Gordo may be streamed out at home).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local award = RS:WaitForChild("AwardItems")
local ITALY_SECS = tonumber(F:GetAttribute("ItalySeconds")) or 60

local ev = RS:FindFirstChild("GordoMovedIn")
if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "GordoMovedIn"; ev.Parent = RS end

-- the copy for the house: the forest Gordo's mesh with its bones, in colour
task.spawn(function()
	if RS:FindFirstChild("GordoHome") then return end
	local src = workspace:WaitForChild("gordo_squirrel_color", 60)
	local mesh
	for _, mp in ipairs(src and src:GetDescendants() or {}) do
		if mp:IsA("MeshPart") and mp:FindFirstChild("Head", true) and mp:FindFirstChild("Root", true) then mesh = mp break end
	end
	if not mesh then warn("GordoServer: no Gordo mesh to copy") return end
	local t0 = os.clock()
	while not mesh:GetAttribute("ColorTexture") and os.clock() - t0 < 20 do task.wait(1) end   -- (SquirrelSetup keeps the colour there)
	local copy = mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	copy.TextureID = mesh:GetAttribute("ColorTexture") or mesh.TextureID
	copy.Anchored = true; copy.CanCollide = false; copy.CanQuery = false; copy.CanTouch = false
	copy.Name = "GordoHome"; copy.Parent = RS
end)

local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local IDS = {}
local function readPieces()
	local ok, t = pcall(function() return HttpService:JSONDecode(workspace:WaitForChild("Treehouse"):GetAttribute("Pieces") or "") end)
	table.clear(IDS)
	if ok and type(t) == "table" then for _, pc in ipairs(t) do if pc.id then table.insert(IDS, pc.id) end end end
end
readPieces()
local function hasRoom(p)                                       -- the walls are up (TreehouseClient's STAGES.walls)
	if #IDS == 0 then return false end
	local n = 0
	for _, id in ipairs(IDS) do if item(p, "tree_" .. id) >= 1 then n += 1 end end
	return n >= math.max(4, math.round(#IDS * 0.58))
end

local secs, done = {}, {}
task.spawn(function()
	while true do
		task.wait(1)
		for _, p in ipairs(Players:GetPlayers()) do
			if not done[p] and p:GetAttribute("SaveLoaded") == true and p:GetAttribute("Area") == "porto" and item(p, "gordo_home") < 1 and hasRoom(p) then
				secs[p] = (secs[p] or 0) + 1
				if secs[p] >= ITALY_SECS then
					done[p] = true
					award:Fire(p, "gordo_home", 1)
					ev:FireClient(p, "moved")
					print(string.format("GordoServer: Gordo moved into %s's treehouse", p.Name))
				end
			end
		end
	end
end)
ev.OnServerEvent:Connect(function(p, what)
	if what == "met" and item(p, "gordo_home") == 1 then award:Fire(p, "gordo_home", 1) end   -- (1 -> 2: the first greeting is said)
end)
Players.PlayerRemoving:Connect(function(p) secs[p] = nil; done[p] = nil end)
print(string.format("GordoServer: ready - Gordo moves in after %d s in Italy", ITALY_SECS))
