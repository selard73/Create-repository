local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[	hold.BackgroundTransparency = 1
	-- a full-screen frame to measure against: AbsolutePosition comes back in the inset-adjusted space (the HUD icon
	-- sitting 8px down reports -50), so the flight target has to be worked out relative to this, not used raw
	local root = Instance.new("Frame"); root.Name = "Root"; root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1; root.Parent = gui
	hold.Parent = root
]====], [====[	hold.BackgroundTransparency = 1; hold.Parent = gui
]====]},
	{[====[		local icon = menuIcon()
		local o = root.AbsolutePosition
		local to = icon and (icon.AbsolutePosition + icon.AbsoluteSize / 2 - o)
			or Vector2.new(vpSize.X - 42, 42)
		local flight = TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(hold, flight, {Position = UDim2.fromOffset(to.X, to.Y)}):Play()
]====], [====[		local icon = menuIcon()
		-- the acorn sits in the top-right corner on every screen, so aim there by fraction: AbsolutePosition is
		-- reported in the inset-adjusted space and would send the squirrel sailing over the top of the screen
		local flight = TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(hold, flight, {Position = UDim2.fromScale(0.955, 0.052)}):Play()
]====]},
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
	if counts[k] ~= 1 then warn(string.format("QQ ABORTED - %d landed %d", k, counts[k])) return end
end
anim.Source = src
warn("QQ reveal flight simplified: " .. total)
