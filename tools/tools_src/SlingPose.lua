local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local H = script.Parent
local function cfg(name, default) local v = H:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function jointOf(char, part, name) local p = char:FindFirstChild(part); return p and p:FindFirstChild(name) end

-- THE LEFT ARM, hand drawn back to the right cheek: two-bone IK on the rig's real bones in the UpperTorso's frame
-- (the same solver as BinocularsPose: Part1 = Part0 * C0 * Transform * C1^-1, bones read off the attachments)
local function solve(char)
	local torso = char:FindFirstChild("UpperTorso")
	local sh, el, wr = jointOf(char, "LeftUpperArm", "LeftShoulder"), jointOf(char, "LeftLowerArm", "LeftElbow"), jointOf(char, "LeftHand", "LeftWrist")
	if not (torso and sh and el and wr and frames(sh) and frames(el) and frames(wr)) then return nil end
	local s0, s1 = frames(sh); local e0, e1 = frames(el); local w0, w1 = frames(wr)
	local S = s0.Position
	local u = e0.Position - s1.Position
	local w = (w0.Position - e1.Position) - w1.Position
	local T = Vector3.new(cfg("DrawHandX", 0.45), cfg("DrawHandY", 1.15), cfg("DrawHandZ", -0.45))
	local d = T - S
	local D = d.Magnitude
	local K = u.X * w.X
	local A = u.Y * w.Y + u.Z * w.Z
	local B = u.Z * w.Y - u.Y * w.Z
	local M = (D * D - u.Magnitude ^ 2 - w.Magnitude ^ 2) / 2
	local delta = math.atan2(B, A)
	local alpha = math.acos(math.clamp((M - K) / math.max(math.sqrt(A * A + B * B), 1e-6), -1, 1))
	local function norm(x) return math.atan2(math.sin(x), math.cos(x)) end
	local phi, phi2 = norm(delta + alpha), norm(delta - alpha)
	local ok1, ok2 = phi > 0 and phi < math.pi, phi2 > 0 and phi2 < math.pi
	if ok2 and (not ok1 or math.abs(phi2 - math.rad(110)) < math.abs(phi - math.rad(110))) then phi = phi2 end
	local R2 = CFrame.Angles(phi, 0, 0)
	local e = u + R2 * w
	local ne = u:Cross(e); if ne.Magnitude < 1e-4 then ne = Vector3.new(1, 0, 0) end
	local pole = Vector3.new(cfg("DrawPoleX", -0.8), cfg("DrawPoleY", -0.1), cfg("DrawPoleZ", 0.4))
	local nd = pole:Cross(d); if nd.Magnitude < 1e-4 then nd = Vector3.new(-1, 0, 0) end
	return {
		[sh] = CFrame.fromMatrix(Vector3.zero, nd.Unit, d.Unit) * CFrame.fromMatrix(Vector3.zero, ne.Unit, e.Unit):Inverse(),
		[el] = R2,
		[wr] = CFrame.new(),
	}
end

-- THE STRETCHED BAND. The tool's pouch and bands are hidden on this screen and redrawn from the prong tips to the
-- pulling hand, with an acorn sitting in the pouch. Local parts, this client's alone.
local TIP = {Vector3.new(-0.468, 1.900, 0), Vector3.new(0.468, 1.900, 0)}      -- the prong tips, handle frame
local FORK = Vector3.new(0, 1.72, 0)
local folder = Instance.new("Folder"); folder.Name = "SlingDraw_local"; folder.Parent = workspace
local function newPart(name, size, color, material, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = material
	if shape then p.Shape = shape end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Parent = folder
	return p
end
local function makeVisual()
	return {
		pouch = newPart("Pouch", Vector3.new(0.34, 0.24, 0.12), Color3.fromRGB(96, 64, 40), Enum.Material.Fabric),
		nut = newPart("Acorn", Vector3.new(0.42, 0.42, 0.42), Color3.fromRGB(128, 84, 42), Enum.Material.SmoothPlastic, Enum.PartType.Ball),
		bands = {newPart("Band", Vector3.new(1, 0.09, 0.09), Color3.fromRGB(40, 36, 36), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder),
			newPart("Band", Vector3.new(1, 0.09, 0.09), Color3.fromRGB(40, 36, 36), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)},
	}
end
local function killVisual(v)
	v.pouch:Destroy(); v.nut:Destroy(); v.bands[1]:Destroy(); v.bands[2]:Destroy()
end
local function updateVisual(v, char, tool)
	local handle = tool:FindFirstChild("Handle")
	local hand = char:FindFirstChild("LeftHand")
	if not (handle and hand) then return end
	local fork = handle.CFrame:PointToWorldSpace(FORK)
	local toFork = fork - hand.Position
	local pouch = hand.Position + (toFork.Magnitude > 0.01 and toFork.Unit * 0.22 or Vector3.zero)
	v.pouch.CFrame = CFrame.lookAt(pouch, fork)
	v.nut.Position = pouch
	for i, tip in ipairs(TIP) do
		local a = handle.CFrame:PointToWorldSpace(tip)
		local len = (pouch - a).Magnitude
		v.bands[i].Size = Vector3.new(math.max(len, 0.1), 0.09, 0.09)
		v.bands[i].CFrame = CFrame.lookAt((a + pouch) / 2, pouch) * CFrame.Angles(0, math.rad(90), 0)
	end
end
local function setToolHidden(tool, hidden)
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") and (p.Name == "Pouch" or p.Name == "Band") then p.LocalTransparencyModifier = hidden and 1 or 0 end
	end
end

-- Each drawing character's record: on/off, when that changed, the solved pose, the local band parts
local recs = setmetatable({}, {__mode = "k"})
local function drop(char, rec)
	if rec.visual then killVisual(rec.visual); rec.visual = nil end
	local tool = char:FindFirstChild("Slingshot")
	if tool then setToolHidden(tool, false) end
	recs[char] = nil
end
RunService.Stepped:Connect(function()
	local now = os.clock()
	local B = math.max(cfg("DrawBlend", 0.12), 0.02)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		if char then
			local on = char:GetAttribute("SlingshotDraw") == true
			local rec = recs[char]
			if on and not rec then rec = {on = true, t0 = now, pose = solve(char)}; recs[char] = rec
			elseif rec and rec.on ~= on then rec.on = on; rec.t0 = now end
			if rec then
				if not rec.pose then rec.pose = solve(char) end            -- parts still arriving: try again
				local k = math.clamp((now - rec.t0) / B, 0, 1)
				local alpha = rec.on and k or (1 - k)
				if alpha <= 0 or not rec.pose then
					if not rec.on then drop(char, rec) end
				else
					-- blended with what the animator just wrote, so the arm swings up and back down smoothly
					for j, cf in pairs(rec.pose) do
						if j.Parent then pcall(function() j.Transform = j.Transform:Lerp(cf, alpha) end) end
					end
				end
			end
		end
	end
	for char, rec in pairs(recs) do if not char.Parent then drop(char, rec) end end
end)
RunService.RenderStepped:Connect(function()
	for char, rec in pairs(recs) do
		local tool = char:FindFirstChild("Slingshot")
		if rec.on and tool then
			if not rec.visual then rec.visual = makeVisual(); setToolHidden(tool, true) end
			updateVisual(rec.visual, char, tool)
		elseif rec.visual then
			killVisual(rec.visual); rec.visual = nil
			if tool then setToolHidden(tool, false) end
		end
	end
end)
