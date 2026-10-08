local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[local shade = glyphs(0, 5, RGB(190, 124, 20), 0.72, z + 2)]====], [====[local shade = glyphs(0, 3, RGB(176, 114, 16), 0.84, z + 2)]====]},
	{[====[local wall = {{1, 3, RGB(92, 55, 22)}, {1, 2, RGB(107, 66, 28)}, {0, 1, RGB(122, 77, 34)}}]====], [====[local wall = {{0, 1, RGB(104, 62, 26)}}]====]},
	{[====[tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(124, 76, 30)), ColorSequenceKeypoint.new(0.5, RGB(94, 55, 20)), ColorSequenceKeypoint.new(1, RGB(74, 42, 14))})]====], [====[tg.Color = ColorSequence.new(RGB(88, 50, 20))                               -- flat face: the shading was doing too much]====]},
	{[====[lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 242, 206)), ColorSequenceKeypoint.new(0.5, RGB(156, 101, 38)), ColorSequenceKeypoint.new(1, RGB(112, 67, 25))})]====], [====[lg.Color = ColorSequence.new(RGB(255, 246, 220))                            -- one clean cream hairline, not a bevel]====]},
	{[====[local ls = Instance.new("UIStroke"); ls.Color = RGB(255, 255, 255); ls.Thickness = 1; ls.Transparency = 0.1;]====], [====[local ls = Instance.new("UIStroke"); ls.Color = RGB(255, 255, 255); ls.Thickness = 1; ls.Transparency = 0.25;]====]},
	{[====[title.FontFace = FONT; title.TextColor3 = GOLD_LIGHT]====], [====[title.FontFace = FONT; title.TextColor3 = RGB(58, 36, 16)                   -- darkest thing on the page, so it leads]====]},
	{[====[disc.BackgroundColor3 = found and RGB(28, 58, 120) or SLOT_LO]====], [====[disc.BackgroundColor3 = found and RGB(206, 230, 242) or SLOT_LO]====]},
	{[====[if found then gradient(disc, RGB(38, 78, 152), RGB(12, 30, 74)) end]====], [====[if found then gradient(disc, RGB(210, 234, 246), RGB(244, 233, 202)) end    -- sky at the top, warm ground below]====]},
	{[====[stroke(ringFrame(4, z + 5), EDGE, 2, 0.05)                                  -- the cyan ring]====], [====[stroke(ringFrame(4, z + 5), EDGE, 2, 0.05)                                  -- the gold ring]====]},
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
		warn(string.format("QQ RESTYLE3 ABORTED - replacement %d landed %d times, script untouched", k, counts[k]))
		return
	end
end
anim.Source = src
warn(string.format("QQ restyle3 applied: %d replacements", total))
