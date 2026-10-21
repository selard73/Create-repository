-- phone13 (Oct 20 2026): on a PHONE with the Keeper / Wise medal showing, Baguette Chase sits BESIDE Hint (a column of Hint,
-- medal, Baguette Chase ran into the "Today's forest question is ready!" note - QuestionNews.QuestionReminder x 104-564
-- y 148-196 - on an iPhone 7); tablets keep Hint / medal / Baguette Chase stacked. Verified on the iPhone 7: no overlaps.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local cc = workspace.Baguette.ChaseClient
local cs = cc.Source
local old = "\t\t\t\tif medal and medal.Visible and bb.Enabled then bottom = math.max(bottom, medal.AbsolutePosition.Y + 44) end\n\t\t\t\tbutton.Position = UDim2.fromOffset(12, bottom + 8)\n"
local new = "\t\t\t\tif medal and medal.Visible and bb.Enabled then\n" ..
	"\t\t\t\t\tif math.min(vp.X, vp.Y) < 600 then                                 -- a phone: three down the side ran into the question note -\n" ..
	"\t\t\t\t\t\tbutton.Position = UDim2.fromOffset(hb.AbsolutePosition.X + hb.AbsoluteSize.X + 8, hb.AbsolutePosition.Y + 5)   -- beside Hint\n" ..
	"\t\t\t\t\t\treturn\n" ..
	"\t\t\t\t\tend\n" ..
	"\t\t\t\t\tbottom = math.max(bottom, medal.AbsolutePosition.Y + 44)\n" ..
	"\t\t\t\tend\n" ..
	"\t\t\t\tbutton.Position = UDim2.fromOffset(12, bottom + 8)\n"
local a, b = cs:find(old, 1, true)
assert(a and not cs:find(old, b + 1, true), "ChaseClient: medal lines not found once - nothing changed")
assert(cs:find("local vp = cam and cam.ViewportSize or Vector2.zero", 1, true), "ChaseClient: no vp in place() - nothing changed")
cs = cs:sub(1, a - 1) .. new .. cs:sub(b + 1)
local bk = cc:Clone(); bk.Name = "ChaseClient_pre_phone13"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(cc, function() return cs end)
return "phone13 installed"
