-- pills29 (Oct 21 2026): Shannon, after pills25 put the coffee counter under the map button: "can you put that counter
-- to the left of the upper side of the passport icon, under the gift icon?" On TABLETS the pills sit left of the HUD
-- column, top level with the Passport icon's top (screen y 64, right edge x 1114 - the Gift icon ends at y 56 above
-- them). Phones and computers keep y 102 at the right edge.
-- Run in Studio EDIT. Backs SpeedClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local speed = workspace.Speed.SpeedClient
local src = speed.Source

-- 1. pillTop() returns the x offset too
local old1 = [[	return (touch and math.min(vp.X, vp.Y) >= 600) and 232 or 102
end]]
local new1 = [[	local tab = touch and math.min(vp.X, vp.Y) >= 600
	-- (Oct 21 2026, Shannon) tablets: left of the Passport icon's top, under the Gift icon; others: the old spot
	return tab and 64 or 102, tab and -66 or -12
end]]
local a, b = src:find(old1, 1, true)
assert(a, "SpeedClient: pillTop return not found - nothing changed")
assert(not src:find(old1, b + 1, true), "SpeedClient: pillTop return found twice - nothing changed")
src = src:sub(1, a - 1) .. new1 .. src:sub(b + 1)

-- 2. the loop reads both
local old2 = "local y = pillTop()"
local c, d = src:find(old2, 1, true)
assert(c, "SpeedClient: y line not found - nothing changed")
assert(not src:find(old2, d + 1, true), "SpeedClient: y line found twice - nothing changed")
src = src:sub(1, c - 1) .. "local y, px = pillTop()" .. src:sub(d + 1)

-- 3. both pills use the x (exactly two spots)
local n
src, n = src:gsub("UDim2%.new%(1, %-12, 0, y%)", "UDim2.new(1, px, 0, y)")
assert(n == 2, "SpeedClient: expected 2 pill position spots, found " .. n .. " - nothing changed")

local bk = workspace.Speed.SpeedClient:Clone(); bk.Name = "SpeedClient_pre_pills29"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(speed, function() return src end)
print(string.format("pills29: SpeedClient -> %d chars", #speed.Source))
return "pills29 installed"
