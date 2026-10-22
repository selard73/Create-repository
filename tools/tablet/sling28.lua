-- sling28 (Oct 21 2026): Shannon, after sling24's iPad preview: "can you align the hold to shoot button with the jump
-- button so it looks nicer?" then "that looks perfect". The tablet HOLD TO SHOOT button's centre lines up with the jump
-- button's centre (both y 612 on iPad Air: jump 1010,552 120x120; hold bottom offset -45 -> -100). Tablets only.
-- Run in Studio EDIT. Backs SlingClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local sling = game:GetService("ServerStorage").SlingshotTool.SlingClient
local old = [[UDim2.new(1, -255, 1, -45)]]
local new = [[UDim2.new(1, -255, 1, -100)]]
local src = sling.Source
local a, b = src:find(old, 1, true)
assert(a, "SlingClient: tablet position not found - nothing changed")
assert(not src:find(old, b + 1, true), "SlingClient: tablet position found twice - nothing changed")
local newSrc = src:sub(1, a - 1) .. new .. src:sub(b + 1)
local bk = sling:Clone(); bk.Name = "SlingClient_pre_sling28"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(sling, function() return newSrc end)
print(string.format("sling28: SlingClient %d -> %d chars", #src, #sling.Source))
return "sling28 installed"
