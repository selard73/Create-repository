-- hud20 (Oct 20 2026): Shannon: "on phone and ipad, can you switch the icon for the acorn and passport and reposition the
-- acorn animation?" -> on touch screens the purse goes to the top of the HUD column (LayoutOrder -2, above Passport's -1);
-- computers unchanged. The acorn flight already aims at the purse wherever it is (acorn17). Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local hc = workspace.HudBarUI.HudBarClient
local src = hc.Source
local old = "purse.BackgroundTransparency = 0; purse.BorderSizePixel = 0; purse.LayoutOrder = 0\n"
local a, b = src:find(old, 1, true)
assert(a and not src:find(old, b + 1, true), "HudBarClient: purse line not found once - nothing changed")
local add = old .. "do local u = game:GetService(\"UserInputService\"); if u.TouchEnabled and not u.KeyboardEnabled then purse.LayoutOrder = -2 end end   -- (Oct 20 2026, Shannon: phones and iPads - the acorns at the top of the column, Passport under them)\n"
src = src:sub(1, a - 1) .. add .. src:sub(b + 1)
local bk = hc:Clone(); bk.Name = "HudBarClient_pre_hud20"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(hc, function() return src end)
return "hud20 installed"
