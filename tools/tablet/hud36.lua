-- hud36 (Oct 21 2026, late): Shannon: "on phone and tablet, please change the icons for the acorns and for the squirrels,
-- the acorns should be top right corner, the squirrels should be under that." Touch screens (phones and tablets) only:
-- the HUD column reads acorns (corner), squirrels, then the rest. Before: phones had the squirrels in the corner and the
-- acorns under them (Oct 20, GiftsClient squirrelsUp); tablets had acorns, Passport, squirrels. Computers unchanged (a row).
--   HudBarClient: on touch, squirrels LayoutOrder 1 -> -1 (just under the purse at -2), the Passport -1 -> 0 (under them;
--   on phones it leaves the column for the top row anyway). GiftsClient: the phone-only squirrelsUp (-3, above the purse)
--   goes.
-- Run in Studio EDIT. Backs both scripts up to ServerStorage.HudBackup as <name>_pre_hud36 first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local jobs = {}
local function patch(script, edits)
	local src = script.Source
	assert(not src:find("hud36", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	table.insert(jobs, {script = script, src = src})
end

patch(workspace.HudBarUI.HudBarClient, {
	{[==[if u.TouchEnabled and not u.KeyboardEnabled then purse.LayoutOrder = -2 end end   -- (Oct 20 2026, Shannon: phones and iPads - the acorns at the top of the column, Passport under them)]==],
	[==[if u.TouchEnabled and not u.KeyboardEnabled then purse.LayoutOrder = -2; squirrelBtn.LayoutOrder = -1 end end   -- (Oct 20 2026, Shannon: phones and iPads - the acorns at the top of the column) (hud36, Oct 21: "the acorns should be top right corner, the squirrels should be under that")]==], "the touch column order"},
	{[==[local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"]==],
	[==[local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"
do local u = game:GetService("UserInputService"); if u.TouchEnabled and not u.KeyboardEnabled then passportBtn.LayoutOrder = 0 end end   -- (hud36) touch: under the acorns and the squirrels]==], "the Passport button"},
})

patch(workspace.Gifts.GiftsClient, {
	{[==[						-- (Shannon: "on phone, switch the position of the acorn with the squirrel") the squirrels on top, the acorns under them
						local function squirrelsUp(c) if c:IsA("TextButton") and c.Name == "TextButton" and c.LayoutOrder == 1 then c.LayoutOrder = -3 end end
						for _, c in ipairs(bar:GetChildren()) do squirrelsUp(c) end
						bar.ChildAdded:Connect(squirrelsUp)
]==],
	[==[						-- (hud36, Oct 21 2026) the squirrels no longer jump above the acorns on a phone: Shannon now wants the acorns in the
						-- corner and the squirrels under them on phones and tablets alike (HudBarClient sets that order)
]==], "the phone squirrelsUp"},
})

for _, j in ipairs(jobs) do
	local bk = j.script:Clone(); bk.Name = j.script.Name .. "_pre_hud36"; bk.Enabled = false; bk.Parent = backup
end
local out = {}
for _, j in ipairs(jobs) do
	SES:UpdateSourceAsync(j.script, function() return j.src end)
	table.insert(out, string.format("%s -> %d chars", j.script.Name, #j.script.Source))
end
print("hud36: " .. table.concat(out, "; "))
return "hud36 installed: " .. table.concat(out, "; ")
