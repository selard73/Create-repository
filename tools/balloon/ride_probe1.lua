-- ride_probe1.lua (Studio EDIT mode; re-runnable). Job 79. A TEMPORARY readout for one test ride.
-- Shannon (Oct 10, VR): from the balloon "the funicolare and scenery at the very rear like the mountains still come in and out"
-- after job 77 kept the funicolare loaded for the rider. This tells loading apart from drawing: while BalloonField's attribute
-- Probe is true, a small sign floats in front of the camera with how many parts of the funicolare, the backdrop and the town
-- are present on THIS client right now (and the most seen so far), plus the distance to the funicolare. If the funicolare
-- reads 288/288 while it is visibly missing, it is loaded and the headset is not drawing it; if it reads 0 or "not here",
-- it has been streamed out. Remove: set Probe false (the sign goes), or delete workspace.BalloonField.RideProbe.
local bf = workspace:FindFirstChild("BalloonField")
if not bf then print("QQ PROBE ABORT: workspace.BalloonField not found") return end
local SRC = [===[
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local F = script.Parent
local cam = workspace.CurrentCamera
local function model(path)
	local m = workspace
	for seg in string.gmatch(path, "[^/]+") do m = m and m:FindFirstChild(seg) end
	return m
end
local function count(m) if not m then return nil end local n = 0 for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end return n end
local WATCH = {{"Funicolare", "PortoNocciola/15 Funicolare"}, {"Backdrop", "PortoBackdrop"}, {"Town", "PortoNocciola"}}
local most = {}
local holder = Instance.new("Part"); holder.Name = "RideProbeHolder"; holder.Anchored = true; holder.CanCollide = false; holder.CanQuery = false; holder.CanTouch = false
holder.Transparency = 1; holder.Size = Vector3.new(0.2, 0.2, 0.2); holder.Parent = cam
local gui = Instance.new("BillboardGui"); gui.Name = "RideProbe"; gui.Size = UDim2.fromScale(3.2, 1.1); gui.AlwaysOnTop = true; gui.LightInfluence = 0; gui.Adornee = holder; gui.Parent = holder
local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundColor3 = Color3.fromRGB(20, 20, 30); label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(255, 246, 220); label.Font = Enum.Font.Code; label.TextScaled = true; label.TextWrapped = true; label.Text = "probe"; label.Parent = gui
local last = 0
RunService.RenderStepped:Connect(function()
	local on = F:GetAttribute("Probe") == true
	gui.Enabled = on
	if not on then return end
	cam = workspace.CurrentCamera
	local cf = cam.CFrame
	holder.CFrame = CFrame.new(cf.Position + cf.LookVector * 6 + Vector3.new(0, -0.8, 0))
	if os.clock() - last < 0.5 then return end
	last = os.clock()
	local lines = {}
	for _, w in ipairs(WATCH) do
		local m = model(w[2]); local n = count(m)
		if n then most[w[1]] = math.max(most[w[1]] or 0, n) end
		table.insert(lines, string.format("%s %s/%s", w[1], n and tostring(n) or "not here", tostring(most[w[1]] or "?")))
	end
	local funi = model("PortoNocciola/15 Funicolare")
	if funi then table.insert(lines, string.format("%.0f studs to the funicolare", (funi:GetPivot().Position - cf.Position).Magnitude)) end
	label.Text = table.concat(lines, "\n")
end)
]===]
local old = bf:FindFirstChild("RideProbe"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "RideProbe"; s.RunContext = Enum.RunContext.Client; s.Source = SRC; s.Parent = bf
bf:SetAttribute("Probe", true)
print(string.format("QQ PROBE DONE: BalloonField.RideProbe installed (%d chars), BalloonField.Probe = true; set it false to hide, delete the script to remove", #SRC))
