-- vending1b.lua (Oct 22 2026): Shannon on the new drinks machine: "the color is too bright" + "remember, all of the other
-- things in the map are old Japanese". Real old towns (Kyoto Gion, Takayama) dress their vending machines to fit the street:
-- dark wood, plain colours. JapanMap.LanternStreet.DrinksVendingMachine gets that look: dark wood body/frame/header (cream
-- words like a carved signboard), warm paper-coloured display light, indigo (cold) / vermilion (hot) price strips, dark iron
-- fittings, the blue wave graphic and side swooshes painted out, a stone base, a dark wood bin with an ink-on-cream plate.
-- The drinks keep their colours. Each changed part keeps its first colour/material in Vending1bWas*. Re-runnable.
local F = workspace.JapanMap.LanternStreet:FindFirstChild("DrinksVendingMachine")
if not F then return "QQ VENDING1B ABORT: no DrinksVendingMachine" end
local C = Color3.fromRGB
local W, SP, MET, SL = Enum.Material.Wood, Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Slate
local DARK, DARKER = C(74, 52, 36), C(58, 41, 29)
local OLD = {
	VM_Body = {W, DARK}, VM_Frame = {W, DARKER}, VM_Header = {W, C(52, 37, 26)}, VM_Backlight = {SP, C(232, 220, 196)},
	VM_Shelf = {W, C(150, 118, 84)}, VM_Graphic = {W, DARKER}, VM_GraphicWave = {W, DARKER}, VM_SideStripe = {W, DARK},
	VM_ICPad = {SP, C(118, 132, 140)}, VM_StripBlue = {SP, C(46, 58, 98)}, VM_StripRed = {SP, C(150, 52, 38)},
	VM_PriceTag = {SP, C(232, 224, 204)}, VM_Button = {SP, C(176, 164, 142)}, VM_Chrome = {MET, C(92, 90, 88)},
	VM_Trim = {MET, C(72, 70, 68)}, VM_Kick = {SP, C(38, 32, 28)}, VM_Flap = {SP, C(44, 40, 36)}, VM_Pad = {SL, C(118, 116, 110)},
	BIN_Body = {W, DARK}, BIN_Lid = {W, DARKER}, BIN_Label = {SP, C(232, 224, 204)},
}
local n = 0
for _, p in ipairs(F:GetDescendants()) do
	if p:IsA("BasePart") then
		local d = OLD[(p.Name:gsub("%.%d+$", ""))]
		if d then
			if p:GetAttribute("Vending1bWasColor") == nil then
				p:SetAttribute("Vending1bWasColor", p.Color); p:SetAttribute("Vending1bWasMaterial", p.Material.Name)
			end
			p.Material = d[1]; p.Color = d[2]
			n += 1
		end
	elseif p:IsA("SurfaceLight") and p.Name == "DisplayLight" then
		p.Brightness = 0.4; p.Color = C(255, 232, 196)
	elseif p:IsA("SurfaceGui") then
		local onBin = p.Parent.Name:find("BIN_") ~= nil
		p.LightInfluence = 0.8
		for _, t in ipairs(p:GetChildren()) do
			if t:IsA("TextLabel") then
				t.Font = Enum.Font.Garamond
				t.TextColor3 = onBin and C(52, 37, 26) or C(236, 224, 196)
			end
		end
	end
end
F:SetAttribute("VendingVersion", "vending1b")
return "QQ VENDING1B: " .. n .. " parts in old-town colours (dark wood, paper light, indigo/vermilion strips, stone base)"
