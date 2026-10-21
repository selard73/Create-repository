-- phone15 (Oct 20 2026): Shannon: "I want the baguette race to be to the RIGHT of the hint" (after phone12-14 stacked it under
-- the medal: "the medal cannot go between the bagette race and the hint; that looks bad"). ChaseClient rebuilt from
-- HudBackup.ChaseClient_pre_phone12 (Hint-anchored placement on phones + tablets) with the button BESIDE Hint (to its right,
-- centred on it); the phone12-14 medal logic is gone - the Keeper / Wise medal keeps its own spot under Hint (BadgeCaseClient,
-- unchanged). Computers unchanged. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local was = backup:FindFirstChild("ChaseClient_pre_phone12")
assert(was, "no ChaseClient_pre_phone12 backup")
local cs = was.Source
local old = "button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)   -- (both count from under the top bar)"
local new = "button.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)   -- to the RIGHT of Hint (Shannon, Oct 20: \"I want the baguette race to be to the RIGHT of the hint\"; both count from under the top bar)"
local a, b = cs:find(old, 1, true)
assert(a and not cs:find(old, b + 1, true), "ChaseClient backup: placement line not found once - nothing changed")
cs = cs:sub(1, a - 1) .. new .. cs:sub(b + 1)
local cc = workspace.Baguette.ChaseClient
local bk = cc:Clone(); bk.Name = "ChaseClient_pre_phone15"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(cc, function() return cs end)
return "phone15 installed"
