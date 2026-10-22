-- welcome1b (Oct 22 2026, right after welcome1): the question banner landed on the daily card. Both now wait for a
-- newcomer's first squirrel, so they arrived together: the reminder (QuestionClient) a moment after the find, the card
-- (DailyClient) 6 s after it - top centre, one over the other (seen in the welcome1 install test). Now DailyClient marks
-- PlayerGui attribute DailyCardPending from the moment a claimable day arrives until the card has slid away, and the
-- reminder waits while it is set. Run in Studio EDIT. Backups <name>_pre_welcome1b.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(welcome1b", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
local dc, qc = workspace.Daily.DailyClient, workspace.DailyQuestion.QuestionClient
local dcSrc = patched(dc, {
	{[==[		if a.claimable and not shown then afterFirstFind(function() if not shown then showCard(a) end end) end   -- (welcome1)]==],
	 [==[		if a.claimable and not shown then                                -- (welcome1)
			pg:SetAttribute("DailyCardPending", true)                      -- (welcome1b: the question reminder waits for the card)
			afterFirstFind(function() if not shown then showCard(a) else pg:SetAttribute("DailyCardPending", nil) end end)
		end]==], "the card's timing"},
	{[==[	t.Completed:Connect(function() card.Visible = false; shown = false end)]==],
	 [==[	t.Completed:Connect(function() card.Visible = false; shown = false; pg:SetAttribute("DailyCardPending", nil) end)   -- (welcome1b)]==], "the card's hide"},
})
local qcSrc = patched(qc, {
	{[==[ if (tonumber(player:GetAttribute("SquirrelsFound"))or 0)<1 then return true end -- (welcome1) not before a first squirrel]==],
	 [==[ if (tonumber(player:GetAttribute("SquirrelsFound"))or 0)<1 then return true end -- (welcome1) not before a first squirrel
 if pg:GetAttribute("DailyCardPending") then return true end -- (welcome1b) nor while a daily card is on its way or up]==], "the reminder's wait"},
})
for _, s in ipairs({dc, qc}) do local b = s:Clone(); b.Name = s.Name .. "_pre_welcome1b"; b.Enabled = false; b.Parent = backup end
SES:UpdateSourceAsync(dc, function() return dcSrc end)
SES:UpdateSourceAsync(qc, function() return qcSrc end)
print(string.format("welcome1b: DailyClient %d chars, QuestionClient %d chars", #dc.Source, #qc.Source))
return "welcome1b installed"
