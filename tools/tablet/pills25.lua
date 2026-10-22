-- pills25 (Oct 21 2026, France iPad check): the "Coffee zoomies" / "Zoomies" countdown pills (SpeedClient, top right at
-- y 102/130) sit ON the Passport button on a TABLET (pill y 102-126 vs Passport 64-112; the tablet HUD column runs
-- acorns, Passport, squirrels, map down to ~y 221). Tablets only: the pills start at y 232, under the map button.
-- Phones and computers unchanged (phones get their own look later if she asks).
-- Run in Studio EDIT. Backs SpeedClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

local speed = workspace.Speed.SpeedClient
local anchor = [[local function mmss(secs) secs = math.max(0, secs) return string.format("%d:%02d", math.floor(secs / 60), math.floor(secs % 60)) end
]]
local add = anchor .. [[-- (Oct 21 2026, France iPad check) on a TABLET the right-hand HUD column (acorns, Passport, squirrels, map) reaches
-- further down than a phone's, and y 102 put these pills ON the Passport button. On tablets they start under the map
-- button instead; phones and computers keep 102.
local UIS_P = game:GetService("UserInputService")
local function pillTop()
	local ok, pi = pcall(function() return UIS_P.PreferredInput end)
	local touch = (ok and pi ~= nil) and (pi == Enum.PreferredInput.Touch) or (UIS_P.TouchEnabled and not UIS_P.MouseEnabled)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	return (touch and math.min(vp.X, vp.Y) >= 600) and 232 or 102
end
]]
local src = speed.Source
assert(not src:find("France iPad check", 1, true), "SpeedClient already patched")
local a, b = src:find(anchor, 1, true)
assert(a, "SpeedClient: anchor not found - nothing changed")
assert(not src:find(anchor, b + 1, true), "SpeedClient: anchor found twice - nothing changed")
local src2 = src:sub(1, a - 1) .. add .. src:sub(b + 1)

local old2 = "local y = 102"
local c, d = src2:find(old2, 1, true)
assert(c, "SpeedClient: y line not found - nothing changed")
assert(not src2:find(old2, d + 1, true), "SpeedClient: y line found twice - nothing changed")
local newSrc = src2:sub(1, c - 1) .. "local y = pillTop()" .. src2:sub(d + 1)

local bk = speed:Clone(); bk.Name = "SpeedClient_pre_pills25"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(speed, function() return newSrc end)
print(string.format("pills25: SpeedClient %d -> %d chars (backup %d)", #src, #speed.Source, #bk.Source))
return "pills25 installed"
