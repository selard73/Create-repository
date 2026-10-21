-- acorn17 (Oct 20 2026): Shannon, on a phone: "the acorn collection animation is flying to the wrong place, please make it
-- animate to be filling the acorn icon ... right now it looks like its filling up the gift icon". AcornClient aimed at a
-- fixed sum from the old three-square bar; the bar is a column on the right now with the Gift button beside it. Aim at the
-- purse button itself (HudBar.Bar.Purse), on every device; the old sum stays as the fallback. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local ac = workspace.AcornSystem.AcornClient
local src = ac.Source
local old = "\tlocal to = UDim2.fromOffset(cam.ViewportSize.X - 10 - 160 + 24, 8 + 24)\n"
local new = old ..
	"\t-- (Oct 20 2026; Shannon, on a phone: \"it looks like its filling up the gift icon\") the bar is a column on the right now,\n" ..
	"\t-- with the Gift button beside it, so the sum above landed on the gift: aim at the purse button itself. Its real screen\n" ..
	"\t-- spot is AbsolutePosition plus the inset (true for every gui, inset or not); the sum stays as the fallback.\n" ..
	"\tlocal hud = pg:FindFirstChild(\"HudBar\"); local bar = hud and hud:FindFirstChild(\"Bar\"); local purse = bar and bar:FindFirstChild(\"Purse\")\n" ..
	"\tif purse and hud.Enabled and purse.Visible and purse.AbsoluteSize.X > 0 then\n" ..
	"\t\tlocal c = purse.AbsolutePosition + game:GetService(\"GuiService\"):GetGuiInset() + purse.AbsoluteSize / 2\n" ..
	"\t\tto = UDim2.fromOffset(c.X, c.Y)\n" ..
	"\tend\n"
local a, b = src:find(old, 1, true)
assert(a and not src:find(old, b + 1, true), "AcornClient: target line not found once - nothing changed")
src = src:sub(1, a - 1) .. new .. src:sub(b + 1)
local bk = ac:Clone(); bk.Name = "AcornClient_pre_acorn17"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(ac, function() return src end)
return "acorn17 installed"
