-- hud35 (Oct 21 2026, late, after her hud34 publish): "please make the other mentioned fixes now":
--   1. PHONES - her note "on the phone it needs to go under the hint button instead": the Baguette Chase button sits just
--      under Hint on a phone as on a tablet (it sat to the RIGHT of Hint on phones since Oct 20). Tablets unchanged.
--   2. The camera's album panel starts under the Hint button, which is the Baguette Chase button's spot on computers and
--      tablets (and now phones): it now starts under that button too whenever it shows. On a phone that would run the
--      panel into the joystick ring (screen y 282 on a 667x375 phone), so there it sits BESIDE the Hint / Baguette
--      Chase column instead, level with Hint. Nothing may overlap on a phone.
-- Run in Studio EDIT. Backs both scripts up to ServerStorage.HudBackup as <name>_pre_hud35 first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local jobs = {}
local function patch(script, edits)
	local src = script.Source
	assert(not src:find("hud35", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	table.insert(jobs, {script = script, src = src})
end

-- ---------- 1. ChaseClient: phones put the button under Hint too ----------
patch(workspace.Baguette.ChaseClient, {
	{[==[				if math.min(vp.X, vp.Y) < 600 then   -- a phone: to the RIGHT of Hint (Shannon, Oct 20: "I want the baguette race to be to the RIGHT of the hint" - "that's just on mobile")
					button.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)
				else                                   -- a tablet: just under Hint (both count from under the top bar)
					button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)
				end]==],
	[==[				-- just under Hint on every touch screen - phones too since hud35 (Oct 21 2026; Shannon: "on the phone it needs
				-- to go under the hint button instead"; it sat to the right of Hint on phones from Oct 20). Counted from under the top bar.
				button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)]==], "the phone/tablet placement"},
})

-- ---------- 2. CameraClient: the album panel clears the Baguette Chase button ----------
patch(workspace.PhotoGame.CameraClient, {
	{[==[	if b and b:IsA("GuiObject") and b.Visible then
		local inset = game:GetService("GuiService"):GetGuiInset()
		return math.max(84, math.floor(b.AbsolutePosition.Y + inset.Y + b.AbsoluteSize.Y + 8))
	end
	return 84
end]==],
	[==[	local inset = game:GetService("GuiService"):GetGuiInset()
	local top = 84
	if b and b:IsA("GuiObject") and b.Visible then
		top = math.max(84, math.floor(b.AbsolutePosition.Y + inset.Y + b.AbsoluteSize.Y + 8))
	end
	-- (hud35, Oct 21 2026) the Baguette Chase button sits just under Hint on the left (every screen now): start under it too
	local cg = pg:FindFirstChild("ChaseGui"); local j = cg and cg.Enabled and cg:FindFirstChild("Join")
	if j and j:IsA("GuiObject") and j.Visible and j.AbsoluteSize.Y > 0 and j.AbsolutePosition.X < 12 + panelWidth() then
		top = math.max(top, math.floor(j.AbsolutePosition.Y + inset.Y + j.AbsoluteSize.Y + 8))
	end
	return top
end]==], "panelTop"},
	{[==[	wanted.Size = UDim2.fromOffset(width, h)]==],
	[==[	wanted.Size = UDim2.fromOffset(width, h)
	-- (hud35) a phone: under Hint and the Baguette Chase button the panel would run into the joystick, so it sits BESIDE that
	-- column instead, level with Hint (nothing may overlap on a phone)
	if UIS.TouchEnabled and top + h > v.Y - 100 then
		local hg = pg:FindFirstChild("HintGui"); local hb = hg and hg.Enabled and hg:FindFirstChild("HintButton")
		local cg = pg:FindFirstChild("ChaseGui"); local j = cg and cg.Enabled and cg:FindFirstChild("Join")
		local right, y = 12, 84
		local inset = game:GetService("GuiService"):GetGuiInset()
		if hb and hb.Visible then right = math.max(right, hb.AbsolutePosition.X + hb.AbsoluteSize.X); y = hb.AbsolutePosition.Y + inset.Y end
		if j and j.Visible then right = math.max(right, j.AbsolutePosition.X + j.AbsoluteSize.X) end
		wanted.Position = UDim2.fromOffset(right + 8, y)
	end]==], "the panel size"},
})

for _, j in ipairs(jobs) do
	local bk = j.script:Clone(); bk.Name = j.script.Name .. "_pre_hud35"; bk.Enabled = false; bk.Parent = backup
end
local out = {}
for _, j in ipairs(jobs) do
	SES:UpdateSourceAsync(j.script, function() return j.src end)
	table.insert(out, string.format("%s -> %d chars", j.script.Name, #j.script.Source))
end
print("hud35: " .. table.concat(out, "; "))
return "hud35 installed: " .. table.concat(out, "; ")
