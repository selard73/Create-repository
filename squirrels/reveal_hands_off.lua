local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[		task.delay(0.82, function()                 -- the icon catches it
			if icon then
				local s = icon:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", icon)
				s.Scale = 1
				TweenService:Create(s, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.28}):Play()
				task.delay(0.17, function()
					TweenService:Create(s, TweenInfo.new(0.34, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale = 1}):Play()
				end)
			end
		end)
]====], [====[]====]},
	{[====[		local icon = menuIcon()
]====], [====[		local icon = menuIcon()                     -- only to know the acorn is up; it is never touched
]====]},
	{[====[	gui.Parent = pg
	revealGui = gui
]====], [====[	gui.Parent = pg
	revealGui = gui
	game:GetService("Debris"):AddItem(gui, 8)   -- a backstop: the overlay can never be left on screen
]====]},
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
	if n ~= 1 then warn(string.format("QQ ABORTED - %d landed %d", k, n)) return end
	total += n
end
anim.Source = src
warn("QQ reveal no longer touches the HUD: " .. total)
