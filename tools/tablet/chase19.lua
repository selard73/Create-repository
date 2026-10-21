-- chase19 (Oct 20 2026): with Baguette Chase beside Hint on a phone, its ChaseGui (DisplayOrder 8) drew OVER the centred
-- windows (PostOffice / ShopPanel / SquirrelHUD at 7) - on the iPhone XR it poked through the mayor's letter. On touch
-- screens the ChaseGui now sits at 6 (the HUD's own level), under every window, dimmed by their shades like Hint.
-- (The chase's info window is ChaseInfoGui at 30 - unchanged.) Computers unchanged. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local cc = workspace.Baguette.ChaseClient
local src = cc.Source
local anchor = "local button = Instance.new(\"TextButton\"); button.Name = \"Join\";"
local a, b = src:find(anchor, 1, true)
assert(a and not src:find(anchor, b + 1, true), "ChaseClient: Join line not found once - nothing changed")
assert(src:sub(1, a):find("local PHONE", 1, true), "ChaseClient: PHONE is not defined before the Join line - nothing changed")
local add = "if PHONE then gui.DisplayOrder = 6 end   -- (Oct 20 2026: under the centred windows on a touch screen - beside Hint it poked through the mayor's letter)\n"
src = src:sub(1, a - 1) .. add .. src:sub(a)
local bk = cc:Clone(); bk.Name = "ChaseClient_pre_chase19"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(cc, function() return src end)
return "chase19 installed"
