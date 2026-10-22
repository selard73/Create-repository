-- sling24 (Oct 21 2026, France iPad check): on a TABLET the slingshot's round "HOLD TO SHOOT" button (measured onto a
-- phone's free strip, Oct 10) lands ON the bigger, further-in jump button (iPad: Shoot 965-1065 x 617-717 vs jump
-- 1010-1130 x 552-672) - a tap to jump shot instead. Tablets only (short side >= 600): the button moves left into the
-- open strip between Roblox's hotbar and the jump button. Phones and computers unchanged.
-- Run in Studio EDIT. Backs SlingClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

local sling = game:GetService("ServerStorage").SlingshotTool.SlingClient
local anchor = [[hold.Visible = touchAim; hold.Parent = gui
]]
local add = anchor .. [[-- (Oct 21 2026, France iPad check) on a TABLET the bigger jump button reaches the measured phone spot, and a tap to
-- jump fired a shot instead. On tablets the button sits further left, in the open strip between Roblox's hotbar and
-- the jump button; phones keep the measured spot (Oct 10).
do
	local function placeHold()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.zero
		hold.Position = (math.min(vp.X, vp.Y) >= 600) and UDim2.new(1, -255, 1, -45) or UDim2.new(1, -115, 1, -45)
	end
	placeHold()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeHold) end
end
]]
local src = sling.Source
assert(not src:find("France iPad check", 1, true), "SlingClient already patched")
local a, b = src:find(anchor, 1, true)
assert(a, "SlingClient: anchor not found - nothing changed")
assert(not src:find(anchor, b + 1, true), "SlingClient: anchor found twice - nothing changed")
local newSrc = src:sub(1, a - 1) .. add .. src:sub(b + 1)

local bk = sling:Clone(); bk.Name = "SlingClient_pre_sling24"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(sling, function() return newSrc end)
print(string.format("sling24: SlingClient %d -> %d chars (backup %d)", #src, #sling.Source, #bk.Source))
return "sling24 installed"
