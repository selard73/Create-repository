-- tablet2 (Oct 20 2026): Shannon: "can you position the hint above the baguette button?" + "you are only making the changes
-- for ipad, right?" -> HintClient goes back to exactly what it was before tablet1 (phones untouched); ChaseClient, on TABLETS
-- only (touch layout and the screen's short side 600+), puts the Baguette Chase button just under the Hint button.
-- Run in Studio EDIT. Backs ChaseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

-- ---------- 1. HintClient back to its pre-tablet1 source ----------
local hint = workspace.HintShop.HintClient
local was = backup:FindFirstChild("HintClient_pre_tablet1")
assert(was, "no HintClient_pre_tablet1 backup")
assert(not was.Source:find("tablet check", 1, true), "the backup is not the original")

-- ---------- 2. ChaseClient: under Hint on tablets ----------
local chase = workspace.Baguette.ChaseClient
local anchor = [[button.AutoButtonColor = false; button.ClipsDescendants = true; button.Parent = gui
]]
local add = anchor .. [[-- (Oct 20 2026, tablet check; Shannon: "position the hint above the baguette button", tablets only) on a tablet the Hint
-- button (HintClient: 12,64 on the real screen, 104x40) has this corner too and this button was drawn over it: here it sits
-- just under Hint while Hint shows. Phones keep the spot above, as before.
if PHONE then
	task.spawn(function()
		local hg = player:WaitForChild("PlayerGui"):WaitForChild("HintGui", 30)
		local hb = hg and hg:WaitForChild("HintButton", 30)
		if not hb then return end
		local function place()
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.zero
			if math.min(vp.X, vp.Y) >= 600 and hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then
				button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)   -- (both count from under the top bar)
			else
				button.Position = UDim2.new(0, 12, 0, 10)
			end
		end
		for _, prop in ipairs({"Visible", "AbsolutePosition", "AbsoluteSize"}) do hb:GetPropertyChangedSignal(prop):Connect(place) end
		hg:GetPropertyChangedSignal("Enabled"):Connect(place)
		if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place) end
		place()
	end)
end
]]
local src = chase.Source
assert(not src:find("tablet check", 1, true), "ChaseClient already patched")
local a, b = src:find(anchor, 1, true)
assert(a, "ChaseClient: anchor not found - nothing changed")
assert(not src:find(anchor, b + 1, true), "ChaseClient: anchor found twice - nothing changed")
local newChase = src:sub(1, a - 1) .. add .. src:sub(b + 1)

-- ---------- backup, then write ----------
local bk = chase:Clone(); bk.Name = "ChaseClient_pre_tablet2"; bk.Enabled = false; bk.Parent = backup
local original = was.Source
SES:UpdateSourceAsync(hint, function() return original end)
SES:UpdateSourceAsync(chase, function() return newChase end)
print(string.format("tablet2: HintClient restored (%d chars, matches backup: %s); ChaseClient %d -> %d chars",
	#hint.Source, tostring(hint.Source == original), #bk.Source, #chase.Source))
return "tablet2 installed"
