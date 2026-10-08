-- Drift: two per-squirrel options on the live SquirrelAnim, for squirrels whose model does not suit the idle rig.
--   NoHeadAnim  the head bone never poses (the sky diver's muzzle and goggles smear when it turns)
--   DriftDown   he hangs in the air until he is found, then parachutes down, rocking, and lands upright
-- Paste into the Studio command bar in edit mode. Idempotent.
local anim = workspace.SquirrelScripts.SquirrelAnim
local CR, LF = string.char(13) .. string.char(10), string.char(10)
local src = anim.Source:gsub(CR, LF)
local done = {}
local function swap(old, new, label)
	local i, j = src:find(old, 1, true)
	if not i then print("DRIFT> anchor missing: " .. label) return false end
	src = src:sub(1, i - 1) .. new .. src:sub(j + 1)
	done[#done + 1] = label
	return true
end

if not src:find("noHead =", 1, true) then
	swap([==[		found = false, revealT = -1, want = {},]==],
[==[		found = false, revealT = -1, want = {},
		noHead = model:GetAttribute("NoHeadAnim") == true,
		driftDown = model:GetAttribute("DriftDown") == true, dr = nil, landed = false,]==], "flags")
end

if not src:find("if not st.noHead then", 1, true) then
	swap([==[		pose(st, "Neck", 0, st.lookYaw * 0.35, 0)
		pose(st, "Head", math.sin(t * 0.9) * 1.5, st.lookYaw * 0.65, st.tilt)]==],
[==[		if not st.noHead then
			pose(st, "Neck", 0, st.lookYaw * 0.35, 0)
			pose(st, "Head", math.sin(t * 0.9) * 1.5, st.lookYaw * 0.65, st.tilt)
		end]==], "head anim optional")
end

if not src:find("groundDropOf", 1, true) then
	swap([==[applyInitial = function()]==],
[==[-- how far a squirrel's lowest corner sits above the ground below him
local function groundDropOf(mesh)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {mesh:FindFirstAncestorOfClass("Model") or mesh}
	local hit = workspace:Raycast(mesh.Position + Vector3.new(0, 4, 0), Vector3.new(0, -500, 0), rp)
	local gy = hit and hit.Position.Y or 0
	local lo = math.huge
	for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		local w = mesh.CFrame:PointToWorldSpace(Vector3.new(sx * mesh.Size.X / 2, sy * mesh.Size.Y / 2, sz * mesh.Size.Z / 2))
		if w.Y < lo then lo = w.Y end
	end end end
	return lo - gy
end
-- upright, feet on the ground, keeping the way he is facing
local function setDown(mesh)
	local fl = Vector3.new(mesh.CFrame.LookVector.X, 0, mesh.CFrame.LookVector.Z)
	if fl.Magnitude < 0.05 then fl = Vector3.new(0, 0, -1) end
	local p = mesh.CFrame.Position
	mesh.CFrame = CFrame.lookAt(p, p + fl.Unit)
	mesh.CFrame = mesh.CFrame - Vector3.new(0, groundDropOf(mesh), 0)
end
applyInitial = function()]==], "ground helpers")
end

if not src:find("st.landed = true", 1, true) then
	swap([==[		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end]==],
[==[		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end
			if st.driftDown and not st.landed then setDown(st.mesh); st.landed = true end]==], "already-found lands")
end

if not src:find("st.dr = {", 1, true) then
	swap([==[	st.found = true; st.revealT = 0]==],
[==[	st.found = true; st.revealT = 0
	if st.driftDown and not st.landed then
		local drop = groundDropOf(mesh)
		if drop > 1 then
			st.dr = {t = 0, dur = 4.2, from = mesh.CFrame, drop = drop}
			st.revealT = -1              -- no reveal hop in mid-air; he bounces when he touches down
		end
	end]==], "reveal starts the drift")
end

if not src:find("-- parachuting down", 1, true) then
	swap([==[		-- an occasional little hop]==],
[==[		-- parachuting down to the ground after being found
		if st.dr then
			local d = st.dr
			d.t += dt
			local k = math.min(d.t / d.dur, 1)
			local ease = k * k * (3 - 2 * k)                        -- eases off as he nears the grass
			local fade = 1 - ease
			local base = d.from
			local sway = math.sin(d.t * 1.7) * fade * 0.9           -- side to side under the canopy
			local pos = base.Position + Vector3.new(0, -d.drop * ease, 0)
				+ base.RightVector * sway + base.LookVector * (ease * 1.8)
			local fl = Vector3.new(base.LookVector.X, 0, base.LookVector.Z)
			if fl.Magnitude < 0.05 then fl = Vector3.new(0, 0, -1) end
			mesh.CFrame = CFrame.lookAt(pos, pos + fl.Unit)
				* CFrame.Angles(math.rad(-12 * fade), 0, math.rad(math.sin(d.t * 1.7 + 0.4) * fade * 5))
			if k >= 1 then
				setDown(mesh)
				st.dr = nil; st.landed = true; st.revealT = 0       -- the landing bounce
			end
		end
		-- an occasional little hop]==], "drift in the heartbeat")
end

if #done == 0 then print("DRIFT> nothing to change (already applied)") return end
anim.Source = src
local chute = workspace:FindFirstChild("parachute_squirrel_color")
if chute then
	chute:SetAttribute("NoHeadAnim", true)
	chute:SetAttribute("DriftDown", true)
end
print("DRIFT> " .. table.concat(done, ", ") .. "; sky diver flags set: " .. tostring(chute ~= nil))
