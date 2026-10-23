-- stalls3c (Oct 23 2026): her "I don't like the way the ice looks, seems like there should be more variety and color" -> her pick
-- "Do the quick recolour now so it's more colourful for Sunday; I'll make Meshy ones later". flavours.py v2 (after her reference
-- photos: the ice coloured right through) made eight colour maps from the blue one; here each served cup gets its flavour:
--   kakigori_b : blue, rainbow bear (kept), strawberry          kakigori_b2: mango, matcha, melon          kakigori_b3: grape, orange, peach
-- The bear mounds on b2 / b3 lose their faces (to HudBackup.Stalls3cRemoved) and take the blue mound's roughness. The straw mounds'
-- red drizzle (KG_SyrupRed.001) follows the flavour. Undo: Stalls3cWasColorMap / Stalls3cWasRoughnessMap / Stalls3cWasColor attrs.
local SS = game:GetService("ServerStorage")
local ice = workspace.JapanMap["Outdoor market revision"]["Shaved ice stall"]
if ice:GetAttribute("Stalls3c") then return "QQ STALLS3C already done" end
local MAP = {
	blue = "rbxassetid://105519777114505", strawberry = "rbxassetid://103604310008321", mango = "rbxassetid://85964280077006",
	matcha = "rbxassetid://88766334570206", melon = "rbxassetid://120470485138148", grape = "rbxassetid://127649436006571",
	orange = "rbxassetid://90247942182554", peach = "rbxassetid://92898390622500",
}
local BLUE_ROUGH = "rbxassetid://119451577163728"
local PLAN = {
	kakigori_b = {KG_MoundBlue = "blue", KG_MoundStraw = "strawberry"},
	kakigori_b2 = {KG_MoundBlue = "mango", KG_MoundBear = "matcha", KG_MoundStraw = "melon"},
	kakigori_b3 = {KG_MoundBlue = "grape", KG_MoundBear = "orange", KG_MoundStraw = "peach"},
}
local DRIZZLE = {melon = Color3.fromRGB(96, 186, 66), peach = Color3.fromRGB(240, 128, 142)}
local FACE = {["KG_FaceSnow.001"] = true, KG_Choco = true, KG_Pink = true, KG_Cookie = true}
local hb = SS:FindFirstChild("HudBackup")
local bk = hb:FindFirstChild("Stalls3cRemoved") or Instance.new("Folder"); bk.Name = "Stalls3cRemoved"; bk.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls3c") end)
local out, n, faces = {}, 0, 0
for setName, plan in pairs(PLAN) do
	local set = ice:FindFirstChild(setName)
	assert(set, "no " .. setName)
	local straw
	for _, p in ipairs(set:GetDescendants()) do
		if p:IsA("BasePart") and plan[p.Name] then
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			assert(sa, p.Name .. " has no SurfaceAppearance")
			if p:GetAttribute("Stalls3cWasColorMap") == nil then
				p:SetAttribute("Stalls3cWasColorMap", sa.ColorMap); p:SetAttribute("Stalls3cWasRoughnessMap", sa.RoughnessMap)
			end
			sa.ColorMap = MAP[plan[p.Name]]
			if p.Name == "KG_MoundBear" then sa.RoughnessMap = BLUE_ROUGH end
			p:SetAttribute("Flavour", plan[p.Name])
			if p.Name == "KG_MoundStraw" then straw = plan[p.Name] end
			n += 1
		end
	end
	if plan.KG_MoundBear then
		for _, p in ipairs(set:GetDescendants()) do
			if p:IsA("BasePart") and FACE[p.Name] then p:SetAttribute("Stalls3cFrom", p:GetFullName()); p.Parent = bk; faces += 1 end
		end
	end
	if straw and DRIZZLE[straw] then
		local d = set:FindFirstChild("KG_SyrupRed.001", true)
		if d then if d:GetAttribute("Stalls3cWasColor") == nil then d:SetAttribute("Stalls3cWasColor", d.Color) end d.Color = DRIZZLE[straw] end
	end
	table.insert(out, setName .. ": " .. (plan.KG_MoundBlue or "") .. ", " .. (plan.KG_MoundBear or "rainbow bear") .. ", " .. (plan.KG_MoundStraw or ""))
end
ice:SetAttribute("Stalls3c", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls3c") end)
return string.format("QQ STALLS3C %d cups recoloured, %d bear-face pieces to HudBackup.Stalls3cRemoved | %s - EDIT INSTALLED; NOT PUBLISHED", n, faces, table.concat(out, " | "))
