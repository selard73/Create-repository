-- rugs2 (Oct 21 2026): Shannon, from her iPad: "we had set the blurred gold text to be not that way a few days ago
-- but it is back to that way now" / "I think you messed something up". She's right - rugs1 put UIStrokes on TEXT
-- objects without ApplyStrokeMode.Border, and a UIStroke on a text object defaults to Contextual: it outlines every
-- LETTER, the fuzzy-gold look she banned on the slingshot note (that old fix is untouched; rugs1 repeated the
-- mistake in new code). Two spots, both now stroke the BOX only:
--   1. TreehouseClient: the first-build tip toast (gold letters got a 2px gold outline).
--   2. DecorClient: the Place/Store buttons in the Treehouse tab (brown outline on the button words).
-- Run in Studio EDIT. Backs both up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

-- ---------- 1. the tip toast ----------
local tc = workspace.Treehouse.TreehouseClient
local old1 = [=[local ts2 = Instance.new("UIStroke"); ts2.Color = GOLD; ts2.Thickness = 2; ts2.Parent = tipNote]=]
local new1 = [=[local ts2 = Instance.new("UIStroke"); ts2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ts2.Color = GOLD; ts2.Thickness = 2; ts2.Parent = tipNote   -- (rugs2: Border, not Contextual - a text object's default strokes the LETTERS, the banned fuzzy gold)]=]
local src = tc.Source
local a, b = src:find(old1, 1, true)
assert(a, "TreehouseClient: tip stroke line not found - nothing changed")
assert(not src:find(old1, b + 1, true), "TreehouseClient: tip stroke line found twice - nothing changed")
local out1 = src:sub(1, a - 1) .. new1 .. src:sub(b + 1)

-- ---------- 2. the Place/Store buttons ----------
local dc = workspace.Treehouse.DecorClient
local old2 = [=[	local bs = Instance.new("UIStroke"); bs.Color = C(200, 150, 90); bs.Thickness = 1.5; bs.Parent = b]=]
local new2 = [=[	local bs = Instance.new("UIStroke"); bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Color = C(200, 150, 90); bs.Thickness = 1.5; bs.Parent = b   -- (rugs2: Border - a TextButton's default strokes its words)]=]
local src2 = dc.Source
local c, d = src2:find(old2, 1, true)
assert(c, "DecorClient: button stroke line not found - nothing changed")
assert(not src2:find(old2, d + 1, true), "DecorClient: button stroke line found twice - nothing changed")
local out2 = src2:sub(1, c - 1) .. new2 .. src2:sub(d + 1)

-- ---------- backups, then write both ----------
local bk1 = tc:Clone(); bk1.Name = "TreehouseClient_pre_rugs2"; bk1.Enabled = false; bk1.Parent = backup
local bk2 = dc:Clone(); bk2.Name = "DecorClient_pre_rugs2"; bk2.Enabled = false; bk2.Parent = backup
SES:UpdateSourceAsync(tc, function() return out1 end)
SES:UpdateSourceAsync(dc, function() return out2 end)
print(string.format("rugs2: TreehouseClient -> %d, DecorClient -> %d chars", #tc.Source, #dc.Source))
return "rugs2 installed"
