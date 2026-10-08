local anim = workspace.SquirrelScripts.SquirrelAnim
local src = anim.Source
local R = {
	{[====[local FACE, FACE_DEEP, RIM = RGB(62, 48, 78), RGB(42, 32, 54), RGB(26, 19, 34)]====], [====[local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)]====]},
	{[====[local SLOT, SLOT_LO, SLOT_EDGE = RGB(45, 34, 57), RGB(35, 26, 45), RGB(24, 17, 31)]====], [====[local SLOT, SLOT_LO, SLOT_EDGE = RGB(228, 212, 179), RGB(210, 191, 153), RGB(162, 131, 90)]====]},
	{[====[local EDGE, INK, INK_DIM = RGB(240, 200, 90), RGB(255, 246, 220), RGB(186, 166, 140)]====], [====[local EDGE, INK, INK_DIM = RGB(203, 150, 48), RGB(64, 42, 22), RGB(132, 108, 80)]====]},
	{[====[local BTN_INK, BTN_RIM = RGB(84, 48, 18), RGB(120, 74, 28)        -- the button lettering and its rim, in acorn brown]====], [====[local BTN_INK, BTN_RIM = RGB(84, 48, 18), RGB(150, 98, 36)        -- the button lettering and its rim, in acorn brown]====]},
	{[====[t.ImageColor3 = color or RGB(255, 228, 186)]====], [====[t.ImageColor3 = color or RGB(188, 158, 110)]====]},
	{[====[gradient(face, RGB(76, 59, 94), FACE_DEEP)]====], [====[gradient(face, RGB(253, 247, 232), FACE_DEEP)]====]},
	{[====[stroke(target, RGB(58, 33, 12), 1.5, 0.15)]====], [====[stroke(target, RGB(96, 58, 22), 1.5, 0.15)]====]},
	{[====[ring(1.5, 2.5, 0, RGB(255, 222, 130))]====], [====[ring(1.5, 2.5, 0, RGB(255, 231, 160))]====]},
	{[====[RGB(30, 20, 14)]====], [====[RGB(255, 250, 233)]====]},
	{[====[local wall = {{1, 3, RGB(40, 148, 184)}, {1, 2, RGB(48, 160, 196)}, {0, 1, RGB(56, 172, 206)}}]====], [====[local wall = {{1, 3, RGB(92, 55, 22)}, {1, 2, RGB(107, 66, 28)}, {0, 1, RGB(122, 77, 34)}}]====]},
	{[====[tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(140, 232, 248)), ColorSequenceKeypoint.new(0.5, RGB(86, 206, 230)), ColorSequenceKeypoint.new(1, RGB(70, 196, 222))})]====], [====[tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(124, 76, 30)), ColorSequenceKeypoint.new(0.5, RGB(94, 55, 20)), ColorSequenceKeypoint.new(1, RGB(74, 42, 14))})]====]},
	{[====[lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(220, 252, 255)), ColorSequenceKeypoint.new(0.5, RGB(70, 182, 214)), ColorSequenceKeypoint.new(1, RGB(44, 150, 186))})]====], [====[lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 242, 206)), ColorSequenceKeypoint.new(0.5, RGB(156, 101, 38)), ColorSequenceKeypoint.new(1, RGB(112, 67, 25))})]====]},
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
local hard = {1, 2, 3, 10, 11, 12}           -- palette lines and the three button-lettering lines must all land
for _, k in ipairs(hard) do
	if counts[k] ~= 1 then
		warn(string.format("QQ RESTYLE2 ABORTED - replacement %d landed %d times, script untouched", k, counts[k]))
		return
	end
end
local aqua = select(2, string.gsub(src, "RGB%(%d+, 1[4-9]%d, 1[8-9]%d%)", ""))
anim.Source = src
warn(string.format("QQ restyle2 applied: %d replacements", total))
