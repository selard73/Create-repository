local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[	hold.BackgroundTransparency = 1; hold.Parent = gui
]====], [====[	hold.BackgroundTransparency = 1
	-- a full-screen frame to measure against: AbsolutePosition comes back in the inset-adjusted space (the HUD icon
	-- sitting 8px down reports -50), so the flight target has to be worked out relative to this, not used raw
	local root = Instance.new("Frame"); root.Name = "Root"; root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1; root.Parent = gui
	hold.Parent = root
]====]},
	{[====[		local to = icon and (icon.AbsolutePosition + icon.AbsoluteSize / 2)
			or Vector2.new(vpSize.X - 40, 40)
]====], [====[		local o = root.AbsolutePosition
		local to = icon and (icon.AbsolutePosition + icon.AbsoluteSize / 2 - o)
			or Vector2.new(vpSize.X - 42, 42)
]====]},
	{[====[local flight = TweenInfo.new(0.72,]====], [====[local flight = TweenInfo.new(0.9,]====]},
	{[====[local fade = TweenInfo.new(0.55,]====], [====[local fade = TweenInfo.new(0.7,]====]},
	{[====[		task.delay(0.62, function()                 -- the icon catches it]====], [====[		task.delay(0.82, function()                 -- the icon catches it]====]},
	{[====[		task.delay(0.85, function()]====], [====[		task.delay(1.1, function()]====]},
	{[====[	task.delay(25, function()]====], [====[	task.delay(2.2, function()]====]},
}
local counts, total = {}, 0
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
	counts[k] = n; total += n
end
for k = 1, #R do
	if counts[k] ~= 1 then
		warn(string.format("QQ REVEALFIX ABORTED - replacement %d landed %d times, untouched", k, counts[k]))
		return
	end
end
anim.Source = src
warn(string.format("QQ reveal fix applied: %d replacements", total))
