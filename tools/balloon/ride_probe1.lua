-- ride_probe1.lua (Studio EDIT mode; re-runnable). Job 79. A TEMPORARY readout for one test ride.
-- Shannon (Oct 10, VR): from the balloon "the funicolare and scenery at the very rear like the mountains still come in and out"
-- after job 77 kept the funicolare loaded for the rider. This tells loading apart from drawing: while BalloonField's attribute
-- Probe is true, a small sign floats in front of the camera showing, for the funicolare (all 288 parts) and for each far
-- section of the town (12 sentinel parts picked here, spread across it, TAGGED RideProbe_<section> - names repeat all over
-- the town, so a name path finds the wrong sibling; a tag travels with its own part), how many are present on THIS client
-- right now, plus the distance to the funicolare. 288/288 and 12/12 while a thing looks missing = loaded but not drawn;
-- dropping counts = streamed out. Cheap: GetTagged a few times a tick, no walk of the 67,000-part town (runner's notes).
-- Remove: set Probe false (the sign goes); tools/balloon/ride_probe_remove1.lua deletes the script and the tags.
local bf = workspace:FindFirstChild("BalloonField")
if not bf then print("QQ PROBE ABORT: workspace.BalloonField not found") return end
local SECTIONS = {
	{"Landscape", "PortoNocciola/12 Country landscape"}, {"Hillside", "PortoNocciola/13 Hillside town"},
	{"Coast", "PortoNocciola/14 Lighthouse coast"}, {"Planting", "PortoNocciola/16 Mediterranean planting"},
}
local function model(path) local m = workspace; for seg in string.gmatch(path, "[^/]+") do m = m and m:FindFirstChild(seg) end return m end
local CS = game:GetService("CollectionService")
local lit, found = {}, {}
for _, sec in ipairs(SECTIONS) do
	local tag = "RideProbe_" .. sec[1]
	for _, o in ipairs(CS:GetTagged(tag)) do CS:RemoveTag(o, tag) end   -- (a re-run picks afresh)
	local m = model(sec[2])
	if m then
		local parts = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then local s = d.Size; if s.Magnitude > 1.5 and s.Magnitude < 40 then table.insert(parts, d) end end
		end
		table.sort(parts, function(a, b) return a.Position.X < b.Position.X end)   -- spread across the section
		local n = 0
		for i = 1, 12 do local p = parts[math.floor((i - 0.5) / 12 * #parts) + 1]; if p and not CS:HasTag(p, tag) then CS:AddTag(p, tag); n += 1 end end
		table.insert(lit, string.format("{label = %q, tag = %q, total = %d}", sec[1], tag, n))
		table.insert(found, string.format("%s %d tagged of %d parts", sec[1], n, #parts))
	else table.insert(found, sec[1] .. " MISSING") end
end
local SRC = [===[
local RunService = game:GetService("RunService")
local CS = game:GetService("CollectionService")
local F = script.Parent
local cam = workspace.CurrentCamera
local SENTINELS = {@@SENTINELS@@}
local function funi() local t = workspace:FindFirstChild("PortoNocciola"); return t and t:FindFirstChild("15 Funicolare") end
local most = {}
local holder = Instance.new("Part"); holder.Name = "RideProbeHolder"; holder.Anchored = true; holder.CanCollide = false; holder.CanQuery = false; holder.CanTouch = false
holder.Transparency = 1; holder.Size = Vector3.new(0.2, 0.2, 0.2); holder.Parent = cam
local gui = Instance.new("BillboardGui"); gui.Name = "RideProbe"; gui.Size = UDim2.fromScale(3.4, 1.5); gui.AlwaysOnTop = true; gui.LightInfluence = 0; gui.Adornee = holder; gui.Parent = holder
local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundColor3 = Color3.fromRGB(20, 20, 30); label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(255, 246, 220); label.Font = Enum.Font.Code; label.TextScaled = true; label.TextWrapped = true; label.Text = "probe"; label.Parent = gui
local last = 0
RunService.RenderStepped:Connect(function()
	local on = F:GetAttribute("Probe") == true
	gui.Enabled = on
	if not on then return end
	cam = workspace.CurrentCamera
	local cf = cam.CFrame
	holder.CFrame = CFrame.new(cf.Position + cf.LookVector * 6 + Vector3.new(0, -0.9, 0))
	if os.clock() - last < 0.5 then return end
	last = os.clock()
	local lines = {}
	local fm = funi()
	if fm then
		local n = 0; for _, d in ipairs(fm:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
		most.F = math.max(most.F or 0, n)
		table.insert(lines, string.format("Funicolare %d/%d  %.0f studs", n, most.F, (fm:GetPivot().Position - cf.Position).Magnitude))
	else table.insert(lines, "Funicolare: not here") end
	for _, s in ipairs(SENTINELS) do
		local n = #CS:GetTagged(s.tag)
		most[s.label] = math.max(most[s.label] or 0, n)
		table.insert(lines, string.format("%s %d/%d of %d", s.label, n, most[s.label], s.total))
	end
	label.Text = table.concat(lines, "\n")
end)
]===]
SRC = SRC:gsub("@@SENTINELS@@", function() return table.concat(lit, ", ") end)
local f, err = loadstring(SRC); if not f then print("QQ PROBE ABORT: the probe does not compile: " .. tostring(err)) return end
local old = bf:FindFirstChild("RideProbe"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "RideProbe"; s.RunContext = Enum.RunContext.Client; s.Source = SRC; s.Parent = bf
bf:SetAttribute("Probe", true)
print(string.format("QQ PROBE DONE: BalloonField.RideProbe installed (%d chars; sentinels: %s), BalloonField.Probe = true; set it false to hide, delete the script to remove", #SRC, table.concat(found, "; ")))
