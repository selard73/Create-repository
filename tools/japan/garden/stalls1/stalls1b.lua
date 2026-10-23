-- stalls1b.lua (Oct 22 2026): Shannon, in the game after stalls1: "there is an issue with the top of the cups ... the cup and the
-- ice are bleeding into each other ... everything else looks good". The v3 heap started under the rim and bulged wider than the
-- cup. Kit japan_kit38_kakigori4.fbx (gen_stalls3.py: hollow cups, the heap starts inside the rim and overhangs above it) is
-- ONLY the kakigori_b set: this swaps it on the Shaved ice stall's counter. The v3 set goes to HudBackup.Stalls1Originals as
-- kakigori_b_v3; the stored kit copy is renamed kakigori_b_v3. Re-runnable (aborts if no new import is found). "QQ STALLS1B".
local SS = game:GetService("ServerStorage")
local J = workspace.JapanMap
local mk = J["Outdoor market revision"]
local KIT, hb = SS.JapanGardenKit, SS.HudBackup
local shaved = mk:FindFirstChild("Shaved ice stall")
local old = shaved and shaved:FindFirstChild("kakigori_b")
if not old then return "QQ STALLS1B ABORT: no kakigori_b set on the Shaved ice stall (run stalls1 first)" end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
-- the new import
local new, wrapper
for _, top in ipairs(workspace:GetChildren()) do
	if top:IsA("Model") and top ~= J then
		local m = top.Name == "kakigori_b" and top or top:FindFirstChild("kakigori_b", true)
		if m and m:IsA("Model") and not m:GetAttribute("Stalls1Set") then new, wrapper = m, (m ~= top and top or nil); break end
	end
end
if not new then return "QQ STALLS1B ABORT: no new kakigori_b import in the workspace - import japan_kit38_kakigori4.fbx first" end
if not find(new, "KG_MoundBlue") then return "QQ STALLS1B ABORT: that import has no textured mounds - wrong file" end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls1b") end)
for _, p in ipairs(new:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
local stored = KIT:FindFirstChild("kakigori_b")
if stored then stored.Name = "kakigori_b_v3" end
new.Parent = KIT
if wrapper and #wrapper:GetDescendants() == 0 then wrapper:Destroy() end
-- where the old set stands, and how it faces
local oldPivot = old:GetPivot()
local oldBox = old:GetBoundingBox()
local base = Vector3.new(oldBox.Position.X, oldBox.Position.Y - 0, oldBox.Position.Z)
local counter = shaved["Service counter"]
local top = counter.Position.Y + counter.Size.Y / 2
local slv = shaved:GetPivot().LookVector
local facing = Vector3.new(slv.X, 0, slv.Z).Unit     -- the STALL's look (the old set's pivot may itself have been flipped - first run put the bear's face to the wall)
local bk = hb:FindFirstChild("Stalls1Originals") or Instance.new("Folder"); bk.Name = "Stalls1Originals"; bk.Parent = hb
old.Name = "kakigori_b_v3"; old.Parent = bk
-- dress + place (same as stalls1's placeSet)
local C = Color3.fromRGB
local SP, GL, MET, WD = Enum.Material.SmoothPlastic, Enum.Material.Glass, Enum.Material.Metal, Enum.Material.Wood
local LOOK = {
	KG_Chrome = {MET, C(200, 204, 210)}, KG_Wood = {WD, C(140, 102, 64)}, KG_Snow = {SP, C(252, 252, 255)},
	KG_SyrupRed = {SP, C(220, 30, 46)}, KG_SyrupGreen = {SP, C(76, 184, 64)}, KG_SyrupBlue = {SP, C(46, 140, 230)}, KG_SyrupYellow = {SP, C(250, 209, 51)},
	KG_Orange = {SP, C(250, 140, 38)}, KG_Pink = {SP, C(242, 140, 166)}, KG_Cup = {SP, C(245, 240, 224)}, KG_CupStripe = {SP, C(46, 115, 204)},
	KG_Cookie = {SP, C(199, 140, 71)}, KG_Choco = {SP, C(56, 31, 20)}, KG_MiniStick = {WD, C(217, 191, 140)}, KG_MiniFlag1 = {SP, C(250, 250, 250)},
	KG_MiniFlag2 = {SP, C(250, 250, 250)}, KG_Cream = {SP, C(252, 250, 242)}, KG_Straw = {SP, C(242, 140, 166)},
}
local unknown = {}
local m = new:Clone(); m.Name = "kakigori_b"
for _, p in ipairs(m:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = true
		if p:IsA("MeshPart") then p.DoubleSided = false end
		if p:FindFirstChildWhichIsA("SurfaceAppearance") or (p:IsA("MeshPart") and p.TextureID ~= "") then
			p.Material = Enum.Material.Plastic; p.Color = C(255, 255, 255); p.Transparency = 0
		else
			local d = LOOK[key(p)]
			if not d then unknown[key(p)] = true; d = {SP, C(200, 200, 200)} end
			p.Material = d[1]; p.Color = d[2]; p.Transparency = d[3] or 0
		end
	end
end
m.WorldPivot = CFrame.new(m:GetPivot().Position)
local cf, sz = m:GetBoundingBox()
m.WorldPivot = CFrame.new(cf.Position.X, cf.Position.Y - sz.Y / 2, cf.Position.Z)
local at = Vector3.new(oldBox.Position.X, top, oldBox.Position.Z)
m:PivotTo(CFrame.lookAt(at, at + facing))
local marker = find(m, "KG_Choco")
if marker and ((marker.Position - m:GetBoundingBox().Position):Dot(facing) < 0) then m:PivotTo(CFrame.lookAt(at, at - facing)) end
m:SetAttribute("Stalls1Set", true); m:SetAttribute("Stalls1bVersion", "kakigori4")
m.Parent = shaved
-- the 氷 cards on the mini flags
local function thinFaces(p)
	local s = p.Size
	if s.Z <= s.X and s.Z <= s.Y then return Enum.NormalId.Front, Enum.NormalId.Back
	elseif s.X <= s.Y then return Enum.NormalId.Right, Enum.NormalId.Left else return Enum.NormalId.Top, Enum.NormalId.Bottom end
end
local cards = 0
for _, p in ipairs(m:GetDescendants()) do
	if p:IsA("BasePart") and key(p):match("^KG_MiniFlag") then
		local a, b = thinFaces(p)
		for _, face in ipairs({a, b}) do
			local sg = Instance.new("SurfaceGui"); sg.Name = "Kori" .. face.Name; sg.Face = face
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 400; sg.LightInfluence = 0.8; sg.Parent = p
			local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = C(250, 250, 247); bg.BorderSizePixel = 0; bg.Parent = sg
			local band = Instance.new("Frame"); band.Position = UDim2.fromScale(0, 0.78); band.Size = UDim2.fromScale(1, 0.22); band.BackgroundColor3 = C(38, 97, 191); band.BorderSizePixel = 0; band.Parent = bg
			for i = 0, 3 do
				local w = Instance.new("Frame"); w.AnchorPoint = Vector2.new(0.5, 0.5); w.Position = UDim2.fromScale(0.125 + i * 0.25, 0); w.Size = UDim2.fromScale(0.28, 0.5)
				w.BackgroundColor3 = C(250, 250, 247); w.BorderSizePixel = 0; w.Parent = band
				local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(1, 0); cr.Parent = w
			end
			local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromScale(0.08, 0.06); t.Size = UDim2.fromScale(0.84, 0.68)
			t.Font = Enum.Font.Garamond; t.TextScaled = true; t.TextColor3 = C(204, 31, 26); t.Text = "氷"; t.Parent = bg
		end
		cards += 1
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls1b") end)
local unk = {}; for k in pairs(unknown) do table.insert(unk, k) end
return string.format("QQ STALLS1B: served set swapped at (%.1f, %.1f, %.1f), %d flag cards; old set in HudBackup.Stalls1Originals.kakigori_b_v3%s - EDIT INSTALLED; NOT PUBLISHED",
	at.X, at.Y, at.Z, cards, #unk > 0 and ("; UNKNOWN " .. table.concat(unk, ", ")) or "")
