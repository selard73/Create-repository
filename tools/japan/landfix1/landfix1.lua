-- landfix1.lua (Oct 22 2026): Japan landscape fixes Shannon flagged ("First we need to fix the landscape").
-- 1. "the 2 mountains and the big stones by the water, are not solid, if you walk toward them you walk into the center of them":
--    JP_Volcano_Sculpted, JP_Fuji_Sculpted, the three JP_Island_Cliffs (the island's sea edge), JP_Waterfall_Rockface and the
--    stream / lake boulders (Natural bank rocks and understory: Stream mossy stone + Lake weathered stone) become solid
--    (CanCollide + CanQuery). The trees in that folder stay passable. CollisionFidelity is set in a SEPARATE call (landfix1_fidelity.lua):
--    one set inside a big installer stays Default (Codex's lesson).
-- 2. "the signs for the 2 lookouts are turned backwards so the player standing on the lookout cannot see them": the words of
--    "VOLCANO LOOKOUT" (TeaHills.Volcano overlook) and "FUJI VIEW" (TeaHills.Fuji photography lookout) move to the board's other
--    face, toward the decks.
-- Every change keeps its old value in a LandFix1Was* attribute. Re-runnable (only changes what still needs it). "QQ LANDFIX1".
local J = workspace:FindFirstChild("JapanMap")
if not J then return "QQ LANDFIX1 ABORT: no JapanMap" end
local out = {}
local function say(s) table.insert(out, "QQ LANDFIX1 " .. s) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before landfix1") end)

local BIG = {"JP_Volcano_Sculpted", "JP_Fuji_Sculpted", "JP_Island_Cliffs_West", "JP_Island_Cliffs_North", "JP_Island_Cliffs_South", "JP_Waterfall_Rockface"}
local function solid(p)
	if p.CanCollide and p.CanQuery then return false end
	if p:GetAttribute("LandFix1WasCanCollide") == nil then
		p:SetAttribute("LandFix1WasCanCollide", p.CanCollide); p:SetAttribute("LandFix1WasCanQuery", p.CanQuery)
	end
	p.CanCollide = true; p.CanQuery = true
	return true
end
local sculpt = J:FindFirstChild("BlenderScenery") and J.BlenderScenery:FindFirstChild("Sculpted terrain")
assert(sculpt, "no BlenderScenery.Sculpted terrain")
local nbig = 0
for _, name in ipairs(BIG) do
	local p = sculpt:FindFirstChild(name)
	assert(p, "missing " .. name)
	if solid(p) then nbig += 1 end
end
say(nbig .. " of " .. #BIG .. " mountain / cliff / rock-face meshes made solid")
local rocks = J:FindFirstChild("Natural landscape repairs") and J["Natural landscape repairs"]:FindFirstChild("Natural bank rocks and understory")
assert(rocks, "no Natural bank rocks and understory")
local nb = 0
for _, group in ipairs(rocks:GetChildren()) do
	if group.Name == "Stream mossy stone" or group.Name == "Lake weathered stone" then
		for _, p in ipairs(group:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 0.5 and p.Name:lower():find("boulder") then
				if solid(p) then nb += 1 end
			end
		end
	end
end
say(nb .. " stream / lake boulders made solid")

local function flip(text)
	for _, d in ipairs(J.TeaHills:GetDescendants()) do
		if d:IsA("TextLabel") and d.Text == text then
			local sg = d:FindFirstAncestorWhichIsA("SurfaceGui")
			if sg then
				if sg:GetAttribute("LandFix1WasFace") == nil then sg:SetAttribute("LandFix1WasFace", sg.Face.Name) end
				local was = sg.Face
				local opp = {Front = Enum.NormalId.Back, Back = Enum.NormalId.Front, Left = Enum.NormalId.Right, Right = Enum.NormalId.Left,
					Top = Enum.NormalId.Bottom, Bottom = Enum.NormalId.Top}
				if sg.Face.Name == sg:GetAttribute("LandFix1WasFace") then sg.Face = opp[was.Name] end
				local part = sg.Adornee or sg.Parent
				local nrm = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(sg.Face))
				say(string.format("%s: words now on the %s face (toward %.0f,%.0f,%.0f)", text, sg.Face.Name, nrm.X, nrm.Y, nrm.Z))
				return
			end
		end
	end
	say(text .. ": sign NOT FOUND")
end
flip("VOLCANO LOOKOUT")
flip("FUJI VIEW")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after landfix1") end)
say("STATUS: EDIT INSTALLED; NOT PUBLISHED - run landfix1_fidelity.lua next")
return table.concat(out, "\n")
