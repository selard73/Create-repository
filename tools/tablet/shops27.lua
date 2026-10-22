-- shops27 (Oct 21 2026, France iPad check): the hat and dress shop panels were phone-sized on the iPad (two rows of a
-- seven-hat list; the Chapelier panel 826-1166 x 207-612). TABLETS only (touch + short side >= 600):
--   1. HatClient: panel 336x560 (was x400) and its fit() may scale up to 1.15 - more hats on screen.
--   2. DressClient: fit() caps rise to 420x640 (were 350x480) - more styles on screen.
-- Phones and computers unchanged.
-- Run in Studio EDIT. Backs both up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

-- ---------- 1. HatClient fit(): taller panel on tablets ----------
local hat = workspace.HatShop.HatClient
local oldH = [[local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 24) / H, (vp.X * 0.5) / W), 0.45, 1)
end]]
local newH = [[local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	-- (Oct 21 2026, France iPad check: the panel was phone-sized on the iPad - two rows of hats) a touch screen with a
	-- tablet's short side gets a taller panel and may grow a little past 1; phones and computers are unchanged
	local tablet = game:GetService("UserInputService").TouchEnabled and math.min(vp.X, vp.Y) >= 600
	local h = tablet and 560 or H
	if panel.Size.Y.Offset ~= h then panel.Size = UDim2.fromOffset(W, h) end
	scale.Scale = math.clamp(math.min((vp.Y - 24) / h, (vp.X * 0.5) / W), 0.45, tablet and 1.15 or 1)
end]]
local srcH = hat.Source
assert(not srcH:find("France iPad check", 1, true), "HatClient already patched")
local a, b = srcH:find(oldH, 1, true)
assert(a, "HatClient: fit() not found - nothing changed")
assert(not srcH:find(oldH, b + 1, true), "HatClient: fit() found twice - nothing changed")
local outH = srcH:sub(1, a - 1) .. newH .. srcH:sub(b + 1)

-- ---------- 2. DressClient fit(): higher caps on tablets ----------
local dress = workspace.DressShop.DressClient
local oldD = [[ W=math.min(350,math.floor(vp.X*.49)-12);H=math.min(480,math.floor(vp.Y)-40)]]
local newD = [[ local big=game:GetService("UserInputService").TouchEnabled and math.min(vp.X,vp.Y)>=600   -- (Oct 21 2026, France iPad check: the iPad got the phone panel)
 W=math.min(big and 420 or 350,math.floor(vp.X*.49)-12);H=math.min(big and 640 or 480,math.floor(vp.Y)-40)]]
local srcD = dress.Source
assert(not srcD:find("France iPad check", 1, true), "DressClient already patched")
local c, d = srcD:find(oldD, 1, true)
assert(c, "DressClient: size line not found - nothing changed")
assert(not srcD:find(oldD, d + 1, true), "DressClient: size line found twice - nothing changed")
local outD = srcD:sub(1, c - 1) .. newD .. srcD:sub(d + 1)

-- ---------- backups, then write both ----------
local bkH = hat:Clone(); bkH.Name = "HatClient_pre_shops27"; bkH.Enabled = false; bkH.Parent = backup
local bkD = dress:Clone(); bkD.Name = "DressClient_pre_shops27"; bkD.Enabled = false; bkD.Parent = backup
SES:UpdateSourceAsync(hat, function() return outH end)
SES:UpdateSourceAsync(dress, function() return outD end)
print(string.format("shops27: HatClient %d -> %d, DressClient %d -> %d chars", #srcH, #hat.Source, #srcD, #dress.Source))
return "shops27 installed"
