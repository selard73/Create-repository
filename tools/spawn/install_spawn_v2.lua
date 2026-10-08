-- Oct 4 2026 (Shannon): respawn at the LAST DAIS TOUCHED (saved), Studio tests start at Porto, and in Studio her
-- character walks through the ComingSoonWall only. Exact-anchor patches; nothing is written if any anchor is missing.
local function count(s,p) local n,i=0,1 while true do local a,b=s:find(p,i,true) if not a then return n end n+=1 i=b+1 end end
local SR=workspace.SpawnReturn.SpawnReturnServer
local SS=workspace.SquirrelScripts.SquirrelSetup
local CW=workspace.ComingSoonWall.ComingSoonServer
local E={
{SR,[==[local Players = game:GetService("Players")
]==],[==[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DAIS = {"forest", "village", "domaine", "porto"}           -- a player respawns at the last of these daises they stood on
local function daisAt(pos)
	for _, id in ipairs(DAIS) do
		local sp = workspace:FindFirstChild("Spawn_" .. id)
		if sp then
			local d = pos - sp.Position
			if math.abs(d.X) < 6 and math.abs(d.Z) < 6 and d.Y > -2 and d.Y < 9 then return id end
		end
	end
end
]==]},
{SR,[==[	local area = player:GetAttribute("Area") or player:GetAttribute("SavedArea") or "forest"
]==],[==[	-- Shannon's Studio tests start in Italy (SpawnReturn attribute StudioStartPorto = false turns it off; never in a live game)
	if RunService:IsStudio() and script.Parent:GetAttribute("StudioStartPorto") ~= false then return "porto" end
	-- the last dais they touched (saved as their area); older saves fall back to the last section they were in
	local area = player:GetAttribute("Dais") or player:GetAttribute("SavedArea") or player:GetAttribute("Area") or "forest"
]==]},
{SR,[==[		task.wait(2)
]==],[==[		task.wait(0.5)
]==]},
{SR,[==[				local id = areaAt(root.Position)
]==],[==[				local dais = daisAt(root.Position)
				if dais and dais ~= player:GetAttribute("Dais") then
					player:SetAttribute("Dais", dais)
					pcall(aim, player)
				end
				local id = areaAt(root.Position)
]==]},
{SS,[==[local area = player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil]==],
    [==[local area = player:GetAttribute("Dais") or player:GetAttribute("SavedArea") or player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil   -- the last dais touched (Oct 4 2026)]==]},
{SS,[==[Players.PlayerAdded:Connect(watchArea)
]==],[==[local function watchDais(player)                                   -- the last dais touched is what gets saved now
	player:GetAttributeChangedSignal("Dais"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Dais") ~= player:GetAttribute("SavedArea") then dirty[player.UserId] = true end
	end)
end
Players.PlayerAdded:Connect(watchDais)
for _, player in ipairs(Players:GetPlayers()) do watchDais(player) end
Players.PlayerAdded:Connect(watchArea)
]==]},
{CW,[==[local F=script.Parent local Players=game:GetService('Players')
]==],[==[local F=script.Parent local Players=game:GetService('Players')
-- Studio tests only (Oct 4 2026): Shannon's character walks through these walls - only these - and is never sent back
local STUDIO_PASS=game:GetService('RunService'):IsStudio()
if STUDIO_PASS then
	local PS=game:GetService('PhysicsService')
	pcall(function() PS:RegisterCollisionGroup('ComingSoonWall') end) pcall(function() PS:RegisterCollisionGroup('WallPass') end)
	PS:CollisionGroupSetCollidable('ComingSoonWall','WallPass',false)
	for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:match('Wall$') then p.CollisionGroup='ComingSoonWall' end end
	local function tag(c) for _,d in ipairs(c:GetDescendants()) do if d:IsA('BasePart') then d.CollisionGroup='WallPass' end end
		c.DescendantAdded:Connect(function(d) if d:IsA('BasePart') then d.CollisionGroup='WallPass' end end) end
	local function hook(pl) pl.CharacterAdded:Connect(tag) if pl.Character then tag(pl.Character) end end
	Players.PlayerAdded:Connect(hook) for _,pl in ipairs(Players:GetPlayers()) do hook(pl) end
end
]==]},
{CW,[==[	if F:GetAttribute('Enabled')~=false then
]==],[==[	if F:GetAttribute('Enabled')~=false and not STUDIO_PASS then
]==]},
}
local src={}
for _,e in ipairs(E) do src[e[1]]=src[e[1]] or e[1].Source assert(count(src[e[1]],e[2])==1,'anchor ~=1 in '..e[1].Name..': '..e[2]:sub(1,60)) end
for _,e in ipairs(E) do local s=src[e[1]] local a,b=s:find(e[2],1,true) src[e[1]]=s:sub(1,a-1)..e[3]..s:sub(b+1) end
for scr,s in pairs(src) do scr.Source=s end
workspace.SpawnReturn:SetAttribute('StudioStartPorto',true)
game:GetService('ChangeHistoryService'):SetWaypoint('Last-dais respawn + Studio Porto start + Studio wall pass')
print('SPAWN_V2_OK',#E)
