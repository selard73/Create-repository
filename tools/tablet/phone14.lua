-- phone14 (Oct 20 2026): on a phone with the medal, Baguette Chase goes beside Hint - unless the question note
-- (QuestionNews.QuestionReminder, which picks its own clear spot when it appears) is already sitting there, as on an iPhone XR
-- (802x414) when the note came first (note x 171-631 y 64-112): then under the medal instead, for the rest of the visit.
-- Verified on the iPhone XR in that order: Hint 64-104, medal 114-148, Baguette Chase 166-196, note 64-112 - no overlaps.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local cc = workspace.Baguette.ChaseClient
local cs = cc.Source
local function replaceOnce(s, find, repl, what)
	local a, b = s:find(find, 1, true)
	assert(a, what .. ": not found - nothing changed")
	assert(not s:find(find, b + 1, true), what .. ": found twice - nothing changed")
	return s:sub(1, a - 1) .. repl .. s:sub(b + 1)
end
cs = replaceOnce(cs,
	"\t\t\t\t\tif math.min(vp.X, vp.Y) < 600 then                                 -- a phone: three down the side ran into the question note -\n" ..
	"\t\t\t\t\t\tbutton.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)   -- beside Hint\n" ..
	"\t\t\t\t\t\treturn\n" ..
	"\t\t\t\t\tend\n",
	"\t\t\t\t\tif math.min(vp.X, vp.Y) < 600 and not underMedal then             -- a phone: three down the side ran into the question note -\n" ..
	"\t\t\t\t\t\tlocal bx, by = hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5   -- beside Hint\n" ..
	"\t\t\t\t\t\tlocal qn = player.PlayerGui:FindFirstChild(\"QuestionNews\"); local note = qn and qn:FindFirstChild(\"QuestionReminder\")\n" ..
	"\t\t\t\t\t\tlocal np, ns = note and note.AbsolutePosition, note and note.AbsoluteSize\n" ..
	"\t\t\t\t\t\tif note and qn.Enabled and note.Visible and bx < np.X + ns.X and bx + math.max(button.AbsoluteSize.X, 130) > np.X and by < np.Y + ns.Y and by + 30 > np.Y then\n" ..
	"\t\t\t\t\t\t\tunderMedal = true                                             -- (the note got there first on this screen: under the medal, for this visit)\n" ..
	"\t\t\t\t\t\telse\n" ..
	"\t\t\t\t\t\t\tbutton.Position = UDim2.fromOffset(bx, by)\n" ..
	"\t\t\t\t\t\t\treturn\n" ..
	"\t\t\t\t\t\tend\n" ..
	"\t\t\t\t\tend\n",
	"phone branch")
cs = replaceOnce(cs, "\t\tlocal function place()\n", "\t\tlocal underMedal = false\n\t\tlocal function place()\n", "place() header")
cs = replaceOnce(cs,
	"\t\t\tbb:GetPropertyChangedSignal(\"Enabled\"):Connect(place)\n",
	"\t\t\tbb:GetPropertyChangedSignal(\"Enabled\"):Connect(place)\n" ..
	"\t\t\tlocal qn = player.PlayerGui:WaitForChild(\"QuestionNews\", 30); local note = qn and qn:WaitForChild(\"QuestionReminder\", 30)\n" ..
	"\t\t\tif note then for _, prop in ipairs({\"Visible\", \"AbsolutePosition\"}) do note:GetPropertyChangedSignal(prop):Connect(place) end end\n",
	"medal hook")
local bk = cc:Clone(); bk.Name = "ChaseClient_pre_phone14"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(cc, function() return cs end)
return "phone14 installed"
