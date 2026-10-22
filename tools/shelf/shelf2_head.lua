-- shelf2 (Oct 22 2026): the trophies' gold, and look closer. Shannon on the live trophies: "the trophies do look flat",
-- "they look orangy" + "can we also make them so if you click on them it zooms in and makes them bigger so its easier to
-- see them well?"
--   The gold: many devices (lower graphics levels - most players are on tablets) draw a SurfaceAppearance's colour map
--     only, and her Meshy trophies kept all their shine in the metal map: the colour alone is flat beige-orange, and the
--     warm shelf light pushed it to orange. Their colour maps now carry the shine, baked in Blender from her full-detail
--     models (roblox-props/meshy/bake_gold.py + gold_grade.py; ids in gold_maps_uploaded.txt), with a soft roughness map
--     and no metal or normal map - the same polished gold on every device.
--   ShelfClient: tap or click a trophy - a card like the portrait viewer's zooms in on it, big and slowly turning (drag to
--     turn it), with its name and what it was for; the light under the bookcase crown is a soft white now.
--   The leftover test trophies in ServerStorage.TrophyTests_unused go (one had a placeholder metal map: the "Invalid
--     TexturePack source textures" error on every server start).
-- Run in Studio EDIT. Backs ShelfClient and the three SurfaceAppearances up to ServerStorage.HudBackup first.
local SES = game:GetService("ScriptEditorService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local sc = workspace.Treehouse:FindFirstChild("ShelfClient")
assert(sc, "no workspace.Treehouse.ShelfClient - nothing changed")
assert(not sc.Source:find("(shelf2", 1, true), "ShelfClient already has shelf2 - nothing changed")
assert(sc.Source:find("ShelfClient: ready", 1, true), "ShelfClient is not the shelf1 one - nothing changed")
assert(not backup:FindFirstChild("ShelfClient_pre_shelf2"), "a ShelfClient_pre_shelf2 backup already exists - nothing changed")
local tm = RS:FindFirstChild("TrophyModels")
local GOLD = {
	Acorn = {colour = "rbxassetid://88318723091937", rough = "rbxassetid://140279110578248"},
	Key = {colour = "rbxassetid://132717411386890", rough = "rbxassetid://126060939237550"},
	Rescue = {colour = "rbxassetid://114942291163293", rough = "rbxassetid://108003065913145"},
}
for name in pairs(GOLD) do
	assert(tm and tm:FindFirstChild(name) and tm[name]:FindFirstChildOfClass("SurfaceAppearance"), "ReplicatedStorage.TrophyModels." .. name .. " or its SurfaceAppearance is missing - nothing changed")
end
-- backups
local b = sc:Clone(); b.Name = "ShelfClient_pre_shelf2"; b.Enabled = false; b.Parent = backup
local saBackup = Instance.new("Folder"); saBackup.Name = "TrophySA_pre_shelf2"; saBackup.Parent = backup
for name in pairs(GOLD) do
	local c = tm[name]:FindFirstChildOfClass("SurfaceAppearance"):Clone(); c.Name = name; c.Parent = saBackup
end
-- the gold
for name, ids in pairs(GOLD) do
	local mp = tm[name]
	for _, old in ipairs(mp:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
	local sa = Instance.new("SurfaceAppearance"); sa.ColorMap = ids.colour; sa.RoughnessMap = ids.rough; sa.Parent = mp
end
-- the leftover test trophies
local tests = SS:FindFirstChild("TrophyTests_unused")
if tests then tests:Destroy() end
-- look closer
SES:UpdateSourceAsync(sc, function() return [==[
@@SHELF@@]==] end)
print(string.format("shelf2: ShelfClient %d chars; TrophyModels gold maps set; test trophies %s", #sc.Source, tests and "removed" or "were already gone"))
return "shelf2 installed"
