-- cards26 (Oct 21 2026, France iPad check; Shannon: "the baguette race instructions should be farther down" / "that book
-- opens up too high"): two windows sat at the top of the iPad screen with the bottom third empty. TABLETS only:
--   1. ChaseClient: the Baguette Chase info card keeps its centred spot (the top-of-screen spot stays for phones,
--      where the card nearly fills the height).
--   2. BookClient: the one-page book reader is centred vertically (phones keep y 72; computers unchanged).
-- Run in Studio EDIT. Backs both up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

-- ---------- 1. ChaseClient: the card stays centred on tablets ----------
local chase = workspace.Baguette.ChaseClient
local oldC = [[	modal.Size = UDim2.fromOffset(600, 0); modal.AnchorPoint = Vector2.new(0.5, 0); modal.Position = UDim2.new(0.5, 0, 0, 4)]]
local newC = [[	modal.Size = UDim2.fromOffset(600, 0)
	-- (Oct 21 2026, France iPad check; Shannon: the card sat too high on the iPad) the top-of-screen spot is for
	-- phones, where the card nearly fills the height; a tablet keeps the centred spot it has everywhere else
	local vpM = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
	if math.min(vpM.X, vpM.Y) < 600 then
		modal.AnchorPoint = Vector2.new(0.5, 0); modal.Position = UDim2.new(0.5, 0, 0, 4)
	end]]
local srcC = chase.Source
assert(not srcC:find("France iPad check", 1, true), "ChaseClient already patched")
local a, b = srcC:find(oldC, 1, true)
assert(a, "ChaseClient: modal line not found - nothing changed")
assert(not srcC:find(oldC, b + 1, true), "ChaseClient: modal line found twice - nothing changed")
local outC = srcC:sub(1, a - 1) .. newC .. srcC:sub(b + 1)

-- ---------- 2. BookClient: the reader centres on tablets ----------
local book = workspace.Bookshop.BookClient
local oldB = [[ book.AnchorPoint=Vector2.new(.5,0);book.Position=UDim2.new(.5,0,0,72)]]
local newB = [[ book.AnchorPoint=Vector2.new(.5,0);book.Position=UDim2.new(.5,0,0,(mobile and math.min(vp.X,vp.Y)>=600) and math.floor((vp.Y-h)/2) or 72)   -- (Oct 21 2026, France iPad check: centred on tablets - it sat high on the iPad)]]
local srcB = book.Source
assert(not srcB:find("France iPad check", 1, true), "BookClient already patched")
local c, d = srcB:find(oldB, 1, true)
assert(c, "BookClient: position line not found - nothing changed")
assert(not srcB:find(oldB, d + 1, true), "BookClient: position line found twice - nothing changed")
local outB = srcB:sub(1, c - 1) .. newB .. srcB:sub(d + 1)

-- ---------- backups, then write both ----------
local bkC = chase:Clone(); bkC.Name = "ChaseClient_pre_cards26"; bkC.Enabled = false; bkC.Parent = backup
local bkB = book:Clone(); bkB.Name = "BookClient_pre_cards26"; bkB.Enabled = false; bkB.Parent = backup
SES:UpdateSourceAsync(chase, function() return outC end)
SES:UpdateSourceAsync(book, function() return outB end)
print(string.format("cards26: ChaseClient %d -> %d, BookClient %d -> %d chars", #srcC, #chase.Source, #srcB, #book.Source))
return "cards26 installed"
