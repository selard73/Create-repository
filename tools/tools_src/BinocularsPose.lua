local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local F = script.Parent
local function cfg(name, default) local v = F:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function jointOf(char, part, name) local p = char:FindFirstChild(part); return p and p:FindFirstChild(name) end

-- WHERE THE BINOCULARS ARE, in the UpperTorso's frame - the same two frames BinocularsHold welds them to
local function binoFrame(char, st)
	local torso, head = char:FindFirstChild("UpperTorso"), char:FindFirstChild("Head")
	if not (torso and head) then return nil end
	if st == "eyes" then
		local neck = head:FindFirstChild("Neck")
		local n0, n1
		if neck then n0, n1 = frames(neck) end
		local headF = (n0 and n1) and (n0 * n1:Inverse()) or CFrame.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
		return headF * CFrame.new(0, cfg("EyeUp", 0.05), -(head.Size.Z / 2 + cfg("EyeForward", 0.8)))
	end
	return CFrame.new(0, cfg("ChestUp", 0.15), -(torso.Size.Z / 2 + cfg("ChestForward", 0.75))) * CFrame.Angles(math.rad(cfg("ChestTilt", -25)), 0, 0)
end

-- TWO-BONE IK, in the UpperTorso's frame, on the rig's REAL bones. Roblox composes a joint as Part1 = Part0 *
-- C0 * Transform * C1^-1 (checked to 0.00 studs), so with unrotated rig attachments the elbow sits at S + R1*u
-- and the hand's centre at S + R1*(u + R2*w), where u and w are the bone vectors read off the attachments - and
-- on this game's avatars they are NOT straight down: the upper arm bone runs (0.40, -0.56, 0.07), out as much
-- as down, which is why a straight-down assumption sent the arms over the head. The elbow bends about its X by
-- phi until the bent arm's length is |T - S| (a cos + b sin = c), then the whole arm is turned so its end lands
-- on T, with the bend plane set by a pole vector so the elbows point out, down and a little forward. With the
-- binoculars at the eyes the neck is held at rest, so the head - and the binoculars on it - stay with the hands.
local function solve(char, st)
	local bino = binoFrame(char, st)
	if not bino then return nil end
	local pose = {}
	local arms = 0
	for _, side in ipairs({"Right", "Left"}) do
		local sgn = side == "Right" and 1 or -1
		local sh = jointOf(char, side .. "UpperArm", side .. "Shoulder")
		local el = jointOf(char, side .. "LowerArm", side .. "Elbow")
		local wr = jointOf(char, side .. "Hand", side .. "Wrist")
		if sh and el and wr and frames(sh) and frames(el) and frames(wr) then
			local s0, s1 = frames(sh); local e0, e1 = frames(el); local w0, w1 = frames(wr)
			local S = s0.Position                                        -- the shoulder joint, torso frame
			local u = e0.Position - s1.Position                          -- shoulder to elbow, in the upper arm's frame
			local w = (w0.Position - e1.Position) - w1.Position          -- elbow to the hand's centre, in the lower arm's
			local T = (bino * CFrame.new(sgn * cfg("GripX", 0.95), cfg("GripY", -0.12), cfg("GripZ", 0.3))).Position
			local d = T - S
			local D = d.Magnitude
			-- the elbow bends about the lower arm's X by phi until |u + R2 w| = D: u.(R2 w) = K + A cos + B sin
			local K = u.X * w.X
			local A = u.Y * w.Y + u.Z * w.Z
			local B = u.Z * w.Y - u.Y * w.Z
			local M = (D * D - u.Magnitude ^ 2 - w.Magnitude ^ 2) / 2
			local delta = math.atan2(B, A)
			local alpha = math.acos(math.clamp((M - K) / math.max(math.sqrt(A * A + B * B), 1e-6), -1, 1))
			local function norm(x) return math.atan2(math.sin(x), math.cos(x)) end
			local phi, phi2 = norm(delta + alpha), norm(delta - alpha)
			-- of the two bends take the forward one (0..180); if both are, the one nearer a natural 110 degrees
			local ok1, ok2 = phi > 0 and phi < math.pi, phi2 > 0 and phi2 < math.pi
			if ok2 and (not ok1 or math.abs(phi2 - math.rad(110)) < math.abs(phi - math.rad(110))) then phi = phi2 end
			local R2 = CFrame.Angles(phi, 0, 0)
			local e = u + R2 * w                                         -- the hand, arm bent, before the turn
			local ne = u:Cross(e)
			if ne.Magnitude < 1e-4 then ne = Vector3.new(1, 0, 0) end
			local pole = Vector3.new(sgn * cfg("PoleX", 0.7), cfg("PoleY", -0.6), cfg("PoleZ", -0.35))
			local nd = pole:Cross(d)
			if nd.Magnitude < 1e-4 then nd = Vector3.new(sgn, 0, 0) end
			pose[sh] = CFrame.fromMatrix(Vector3.zero, nd.Unit, d.Unit) * CFrame.fromMatrix(Vector3.zero, ne.Unit, e.Unit):Inverse()
			pose[el] = R2
			pose[wr] = CFrame.new()                                      -- the hand stays in line with the forearm
			arms += 1
		end
	end
	if st == "eyes" then
		local neck = jointOf(char, "Head", "Neck")
		if neck then pose[neck] = CFrame.new() end
	end
	return arms == 2 and pose or nil
end

-- Each character's record: its state, when it changed, the pose it is blending from and the two solutions.
local recs = setmetatable({}, {__mode = "k"})
local complained = false
local function apply(j, cf) j.Transform = cf end
RunService.Stepped:Connect(function()
	local now = os.clock()
	local T = cfg("ZoomTime", 0.25)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		local st = char and char:GetAttribute("BinocularsUp")
		if char and st and not char:GetAttribute("Riding") then
			local rec = recs[char]
			if not rec then rec = {solved = {}}; recs[char] = rec end
			if rec.st ~= st then rec.from = rec.cur; rec.st = st; rec.t0 = now end
			local pose = rec.solved[st]
			if not pose then pose = solve(char, st); rec.solved[st] = pose end
			if pose then
				local alpha = rec.from and math.clamp((now - rec.t0) / math.max(T, 0.05), 0, 1) or 1
				local cur = {}
				for j, cf in pairs(pose) do
					local f = rec.from and rec.from[j]
					cur[j] = (f and alpha < 1) and f:Lerp(cf, alpha) or cf
				end
				rec.cur = cur
				for j, cf in pairs(cur) do
					if j.Parent then
						local ok, err = pcall(apply, j, cf)
						if not ok and not complained then complained = true; warn("BinocularsPose: cannot pose " .. j.ClassName .. ": " .. tostring(err)) end
					end
				end
			end
		elseif char and recs[char] then
			recs[char] = nil
		end
	end
end)
