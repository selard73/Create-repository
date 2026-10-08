-- Oct 7 2026: the Butterfly Catcher's butterflies. Each client flutters its own copies round a point by her net: CentreLocal
-- (attribute) = that point in her mesh's local studs at Studio size (EditSizeY), scaled with her in play.
-- StreamingEnabled: the butterflies may stream in after this script starts, so the list is rebuilt until all three are here.
local RunService = game:GetService("RunService")
local holder = script.Parent
local cm, lastLook, lastScan = nil, -10, -10
local flies = {}
local function scan()
	flies = {}
	for _, m in ipairs(holder:GetChildren()) do
		local b, l, r = m:FindFirstChild("Body"), m:FindFirstChild("LeftWing"), m:FindFirstChild("RightWing")
		if m:IsA("Model") and b and l and r then
			table.insert(flies, {body = b, l = l, r = r, ph = m:GetAttribute("Phase") or 0,
				rad = m:GetAttribute("Radius") or 1.2, sp = m:GetAttribute("Speed") or 1})
		end
	end
end
local function findHer()
	local sq = workspace:FindFirstChild(holder:GetAttribute("Squirrel") or "butterfly_squirrel_color")
	cm = sq and sq:FindFirstChild("Squirrel")
end
local function pathAt(f, a)
	return Vector3.new(math.cos(a) * f.rad, 0.45 * math.sin(a * 2.3), math.sin(a * 1.3) * f.rad * 0.8)
end
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if #flies < 3 and now - lastScan > 1 then lastScan = now scan() end
	if (not cm or not cm.Parent) and now - lastLook > 2 then lastLook = now findHer() end
	local base = holder:GetAttribute("Rest")
	local cl, editY = holder:GetAttribute("CentreLocal"), holder:GetAttribute("EditSizeY")
	if cm and cm.Parent and cl and editY then base = cm.CFrame:PointToWorldSpace(cl * (cm.Size.Y / editY)) end
	if not base then return end
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - base).Magnitude > 120 then return end
	for _, f in ipairs(flies) do
		if f.body.Parent then
			local a = now * 0.9 * f.sp + f.ph
			local p = base + pathAt(f, a) + Vector3.new(0, 0.12 * math.sin(now * 9 + f.ph), 0)
			local dir = (pathAt(f, a + 0.05) - pathAt(f, a)) * Vector3.new(1, 0, 1)
			local cf = dir.Magnitude > 1e-4 and CFrame.lookAt(p, p + dir) or CFrame.new(p)
			local flap = 0.15 + 0.95 * math.abs(math.sin(now * 16 + f.ph))
			f.body.CFrame = cf
			f.l.CFrame = cf * CFrame.Angles(0, 0, -flap) * CFrame.new(-f.l.Size.X / 2, 0, 0)
			f.r.CFrame = cf * CFrame.Angles(0, 0, flap) * CFrame.new(f.r.Size.X / 2, 0, 0)
		else
			lastScan = -10 flies = {}
			break
		end
	end
end)
