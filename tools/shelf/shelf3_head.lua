-- shelf3 (Oct 22 2026): the trophy itself comes to you, no card. Shannon, of shelf2's card: "I don't want the tap to open
-- a card, it want it to just pull the trophy itself forward and enlarged so you can see it better, no card there."
--   ShelfClient: tap or click a trophy - it floats off the shelf (with its base and plaque) to the middle of your view,
--     grows to about half the screen's height and slowly turns; tap again, walk, Esc or open any panel and it flies back.
--     Your own title tag hides on your screen while one is out. The card (TrophyViewer) is gone. The gold (shelf2) stays.
-- Run in Studio EDIT. Backs ShelfClient up to ServerStorage.HudBackup.ShelfClient_pre_shelf3 first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local sc = workspace.Treehouse:FindFirstChild("ShelfClient")
assert(sc, "no workspace.Treehouse.ShelfClient - nothing changed")
assert(sc.Source:find("(shelf2", 1, true), "ShelfClient is not the shelf2 one - nothing changed")
assert(not sc.Source:find("(shelf3", 1, true), "ShelfClient already has shelf3 - nothing changed")
assert(not backup:FindFirstChild("ShelfClient_pre_shelf3"), "a ShelfClient_pre_shelf3 backup already exists - nothing changed")
local b = sc:Clone(); b.Name = "ShelfClient_pre_shelf3"; b.Enabled = false; b.Parent = backup
SES:UpdateSourceAsync(sc, function() return [==[
@@SHELF@@]==] end)
print(string.format("shelf3: ShelfClient %d chars", #sc.Source))
return "shelf3 installed"
