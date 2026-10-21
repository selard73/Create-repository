-- phone16 (Oct 20 2026): Shannon: "I want the baguette race to be to the RIGHT of the hint" ... "that's just on mobile".
--  1. ChaseClient: PHONES (short side < 600) - Baguette Chase beside Hint, to its right; TABLETS keep it just under Hint.
--  2. BadgeCaseClient: the Keeper / Wise medal hangs under Hint as designed - but where Baguette Chase sits under Hint (a
--     tablet in France) the medal hangs under Baguette Chase instead ("the medal cannot go between the bagette race and
--     the hint"). If the question note (which picks its own clear spot when it appears) sits where the medal goes, the
--     medal waits until the note has gone. Computers unchanged (there the chase button is not under Hint).
-- Run in Studio EDIT. Backs both scripts up first. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local function replaceOnce(s, find, repl, what)
	local a, b = s:find(find, 1, true)
	assert(a, what .. ": not found - nothing changed")
	assert(not s:find(find, b + 1, true), what .. ": found twice - nothing changed")
	return s:sub(1, a - 1) .. repl .. s:sub(b + 1)
end

-- ---------- 1. ChaseClient ----------
local cc = workspace.Baguette.ChaseClient
local cs = cc.Source
cs = replaceOnce(cs,
	"button.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)   -- to the RIGHT of Hint (Shannon, Oct 20: \"I want the baguette race to be to the RIGHT of the hint\"; both count from under the top bar)",
	"if math.min(vp.X, vp.Y) < 600 then   -- a phone: to the RIGHT of Hint (Shannon, Oct 20: \"I want the baguette race to be to the RIGHT of the hint\" - \"that's just on mobile\")\n" ..
	"\t\t\t\t\tbutton.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)\n" ..
	"\t\t\t\telse                                   -- a tablet: just under Hint (both count from under the top bar)\n" ..
	"\t\t\t\t\tbutton.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)\n" ..
	"\t\t\t\tend",
	"ChaseClient placement")

-- ---------- 2. BadgeCaseClient ----------
local bc = workspace.BadgeCase.BadgeCaseClient
local bs = bc.Source
bs = replaceOnce(bs,
	"\tif hintButton then\n\t\tlocal p, s = hintButton.AbsolutePosition, hintButton.AbsoluteSize\n\t\tmedalBtn.Position = UDim2.fromOffset(math.round(p.X + s.X / 2 - btnGui.AbsolutePosition.X), math.round(p.Y + s.Y + 10 - btnGui.AbsolutePosition.Y))\n\tend\n",
	"\tif hintButton then\n" ..
	"\t\tlocal p, s = hintButton.AbsolutePosition, hintButton.AbsoluteSize\n" ..
	"\t\tlocal top = p.Y + s.Y + 10\n" ..
	"\t\t-- (Oct 20 2026; Shannon: \"the medal cannot go between the bagette race and the hint\") where the Baguette Chase button sits\n" ..
	"\t\t-- just under Hint (a tablet in France - ChaseClient), the medal hangs under that instead; on a phone it sits beside Hint\n" ..
	"\t\tlocal cg = pg:FindFirstChild(\"ChaseGui\"); local join = cg and cg:FindFirstChild(\"Join\")\n" ..
	"\t\tif join and cg.Enabled and join.Visible then\n" ..
	"\t\t\tlocal jp, js = join.AbsolutePosition, join.AbsoluteSize\n" ..
	"\t\t\tif jp.Y > p.Y + 10 and jp.X < p.X + s.X and jp.X + js.X > p.X then top = jp.Y + js.Y + 10 end\n" ..
	"\t\tend\n" ..
	"\t\tlocal cx = p.X + s.X / 2\n" ..
	"\t\tmedalBtn.Position = UDim2.fromOffset(math.round(cx - btnGui.AbsolutePosition.X), math.round(top - btnGui.AbsolutePosition.Y))\n" ..
	"\t\t-- the question note finds its own clear spot when it appears; if it came first and sits where the medal goes, the medal\n" ..
	"\t\t-- waits until it has gone (nothing may overlap on a phone or a tablet)\n" ..
	"\t\tlocal qn = pg:FindFirstChild(\"QuestionNews\"); local note = qn and qn:FindFirstChild(\"QuestionReminder\")\n" ..
	"\t\tif medalBtn.Visible and note and qn.Enabled and note.Visible then\n" ..
	"\t\t\tlocal np, ns = note.AbsolutePosition, note.AbsoluteSize\n" ..
	"\t\t\tif cx - 17 < np.X + ns.X and cx + 17 > np.X and top < np.Y + ns.Y and top + 46 > np.Y then medalBtn.Visible = false end\n" ..
	"\t\tend\n" ..
	"\tend\n",
	"BadgeCaseClient placeMedal")
bs = replaceOnce(bs,
	"-- ---------------------------------------------------------------- a new badge: say so ----",
	"task.spawn(function()                                              -- (Oct 20) the Baguette Chase button and the question note move it too\n" ..
	"\tlocal cg = pg:WaitForChild(\"ChaseGui\", 60); local join = cg and cg:WaitForChild(\"Join\", 30)\n" ..
	"\tif join then\n" ..
	"\t\tfor _, property in ipairs({\"AbsolutePosition\", \"AbsoluteSize\", \"Visible\"}) do join:GetPropertyChangedSignal(property):Connect(placeMedal) end\n" ..
	"\t\tcg:GetPropertyChangedSignal(\"Enabled\"):Connect(placeMedal)\n" ..
	"\tend\n" ..
	"\tlocal qn = pg:WaitForChild(\"QuestionNews\", 60); local note = qn and qn:WaitForChild(\"QuestionReminder\", 30)\n" ..
	"\tif note then for _, property in ipairs({\"Visible\", \"AbsolutePosition\"}) do note:GetPropertyChangedSignal(property):Connect(placeMedal) end end\n" ..
	"\tplaceMedal()\n" ..
	"end)\n\n" ..
	"-- ---------------------------------------------------------------- a new badge: say so ----",
	"BadgeCaseClient hooks")

local b1 = cc:Clone(); b1.Name = "ChaseClient_pre_phone16"; b1.Enabled = false; b1.Parent = backup
local b2 = bc:Clone(); b2.Name = "BadgeCaseClient_pre_phone16"; b2.Enabled = false; b2.Parent = backup
SES:UpdateSourceAsync(cc, function() return cs end)
SES:UpdateSourceAsync(bc, function() return bs end)
return "phone16 installed (ChaseClient, BadgeCaseClient)"
