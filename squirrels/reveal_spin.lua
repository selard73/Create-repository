local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[	local spin
	spin = RunService.RenderStepped:Connect(function(dt)
		if not gui.Parent then spin:Disconnect() return end
		ang += dt * 1.15
		rays.Rotation += dt * 9
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang), 0.2, math.cos(ang)) * dist, centre)
	end)
]====], [====[	-- exactly one revolution over the hold, eased in and out, finishing back where it started - which is face-on,
	-- because ang was taken from the squirrel's own forward vector. Then it holds that pose for the flight.
	local HOLD = 2.2
	local spin, t = nil, 0
	spin = RunService.RenderStepped:Connect(function(dt)
		if not gui.Parent then spin:Disconnect() return end
		t = math.min(t + dt, HOLD)
		local k = t / HOLD
		local turn = (k * k * (3 - 2 * k)) * math.pi * 2
		rays.Rotation += dt * 9
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang + turn), 0.2, math.cos(ang + turn)) * dist, centre)
	end)
]====]},
	{[====[	task.delay(2.2, function()                      -- long enough to read the name, short enough not to nag]====], [====[	task.delay(HOLD, function()                     -- it leaves the moment the turn is complete]====]},
}
local total = 0
local function sub(s, old, new)
	local o, i, n = {}, 1, 0
	while true do
		local a, b = string.find(s, old, i, true)
		if not a then break end
		o[#o + 1] = string.sub(s, i, a - 1); o[#o + 1] = new; i = b + 1; n += 1
	end
	o[#o + 1] = string.sub(s, i)
	return table.concat(o), n
end
for k, r in ipairs(R) do
	local n
	src, n = sub(src, r[1], r[2])
	if n ~= 1 then warn(string.format("QQ SPIN ABORTED - %d landed %d", k, n)) return end
	total += n
end
anim.Source = src
warn("QQ one full revolution: " .. total .. " replacements")
