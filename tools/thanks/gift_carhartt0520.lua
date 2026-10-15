-- thanks/gift_carhartt0520.lua (Studio EDIT; re-runnable). A 1000-acorn thank-you for Carhartt0520 (Roblox id 4348272918), who wrote
-- to the mayor at La Poste ("hello how are you", Oct 15 2026). One StringValue under workspace.Thanks.Gifts (job 92's system: paid once
-- on their next join through the game's own ledger, flagged Item_thanks_carhartt0520_1, the card "A thank-you from the mayor" with the
-- Note). No publish. Output "QQ THANKS".
if game:GetService("RunService"):IsRunning() then print("QQ THANKS ABORT - Play mode") return end
local F = workspace:FindFirstChild("Thanks")
local gifts = F and F:FindFirstChild("Gifts")
if not gifts then print("QQ THANKS ABORT - workspace.Thanks.Gifts is not here (job 92's install_thanks1.lua)") return end
local NAME, ACORNS, ID = "Carhartt0520", 1000, "carhartt0520_1"
local NOTE = "You wrote to the mayor. The mayor wrote back. Everybody wins. Especially you."
for _, v in ipairs(gifts:GetChildren()) do
	if v:IsA("StringValue") and v.Name:lower() == NAME:lower() and (v:GetAttribute("Id") or "") == ID then
		v.Value = tostring(ACORNS); v:SetAttribute("Note", NOTE)
		print("QQ THANKS DONE (already there, note refreshed): " .. v.Name .. " = " .. v.Value .. " acorns, Id " .. ID) return
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before gift Carhartt0520") end)
local v = Instance.new("StringValue"); v.Name = NAME; v.Value = tostring(ACORNS); v:SetAttribute("Id", ID); v:SetAttribute("Note", NOTE); v.Parent = gifts
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after gift Carhartt0520") end)
local n = 0
for _, g in ipairs(gifts:GetChildren()) do if g:IsA("StringValue") then n += 1 end end
print(string.format("QQ THANKS DONE: workspace.Thanks.Gifts.%s = %d acorns, Id %s, with its note (%d gifts listed; paid on their next join, once)", NAME, ACORNS, ID, n))
