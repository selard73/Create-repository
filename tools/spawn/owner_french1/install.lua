-- Shannon approved the pictured owner-only French arrival preview on Oct 18, 2026.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and not Run:IsRunning(),"Stopped Studio only")
assert(_G.OWNER_FRENCH_START1_ALLOW_EDIT==true,"Explicit approval required")
assert(game.PlaceId==117372258657114,"Wrong place")
local f=workspace.SpawnReturn;local s=f.SpawnReturnServer
local before=s.Source
assert(not before:find("OWNER_FRENCH_START1_20261018",1,true),"Already installed")
assert(f:GetAttribute("OwnerStartArea")==nil,"Existing owner override; inspect first")
local anchor=[====[local function target(player)                                    -- never past a gate that is still shut
]====]
local added=[====[	-- OWNER_FRENCH_START1_20261018: Shannon requested a temporary French start in Studio and live servers.
	-- Clear OwnerStartArea on SpawnReturn to restore her usual saved-arrival behavior.
	local ownerArea = script.Parent:GetAttribute("OwnerStartArea")
	if player.UserId == 9611145467 and RANK[ownerArea] then return ownerArea end
]====]
local a,b=before:find(anchor,1,true);assert(a and not before:find(anchor,b+1,true),"Unexpected spawn source")
local after=before:sub(1,b)..added..before:sub(b+1)
local root=game.ServerStorage.HudBackup
assert(not root:FindFirstChild("SpawnReturnServer_pre_ownerFrench1"),"Backup exists")
local backup=s:Clone();backup.Name="SpawnReturnServer_pre_ownerFrench1";backup.Disabled=true;backup.Parent=root
local ok,err=pcall(function()
 f:SetAttribute("OwnerStartArea","forest");s.Source=after
 assert(s.Source==after and f:GetAttribute("OwnerStartArea")=="forest")
end)
if not ok then s.Source=before;f:SetAttribute("OwnerStartArea",nil);backup:Destroy();error(err)end
print("QQ OWNER FRENCH START1: account9611145467 uses Spawn_forest in Studio and live; other players unchanged; clear OwnerStartArea to disable; original script backed up; EDIT INSTALLED, NOT PUBLISHED")

