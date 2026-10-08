-- StowServer (workspace.Shop): Equip / Store for the things you own that ride in the hotbar (Oct 4 2026, Shannon: "On the
-- acorn store, if you bought something, you should have a button to equip (which puts it at the bottom of the screen) or
-- store (which would take it off the bottom of the screen)"). Storing is saved like any item: Item_stow_<id> = 1 through
-- AwardItems. Each tool's own giver (SlingServer, BinocularsServer, CrabServer) skips a stored tool and hands it back the
-- moment it is equipped again (they watch Item_stow_<id>); storing takes it out of the backpack and the hand here.
local RS = game:GetService("ReplicatedStorage")
local awardItems = RS:WaitForChild("AwardItems")
local ev = RS:WaitForChild("HotbarStow")
local TOOLS = {binoculars = "Binoculars", slingshot = "Slingshot", crabtrap = "Crab trap"}

ev.OnServerEvent:Connect(function(p, id, stow)
	local toolName = type(id) == "string" and TOOLS[id]
	if not toolName then return end
	if (p:GetAttribute("Item_" .. id) or 0) <= 0 then return end          -- only what is yours
	local cur = p:GetAttribute("Item_stow_" .. id) or 0
	local want = stow == true and 1 or 0
	if cur ~= want then awardItems:Fire(p, "stow_" .. id, want - cur) end
	if want == 1 then
		local pack = p:FindFirstChildOfClass("Backpack")
		local t = pack and pack:FindFirstChild(toolName)
		if t then t:Destroy() end
		t = p.Character and p.Character:FindFirstChild(toolName)
		if t and t:IsA("Tool") then t:Destroy() end
	end
end)
print("StowServer: ready")
