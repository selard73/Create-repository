-- bubble_probe3 v1: READ-ONLY. Verbatim: CrocClient lines 105-200 (the croc-challenge floating text + its call sites),
-- ChaseClient 252-292 (the baguette chase hint bubble), MusicClient 98-106 (the quiet rule), ZipServer lines near Riding.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local function lines(t) local out = {}; for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end; return out end
local function dump(tag, d, a, b)
	local t = d and src(d); if not t then print("QQ B3 missing " .. tag); return end
	local L = lines(t)
	print(string.format("QQ B3 === %s %s lines %d-%d of %d", tag, d:GetFullName(), a, b, #L))
	for i = a, math.min(b, #L) do print(string.format("QQ B3 %d: %s", i, L[i]:sub(1, 190))) end
end
dump("croc", workspace.Lagoon:FindFirstChild("CrocClient"), 105, 200)
dump("chase", workspace.Baguette:FindFirstChild("ChaseClient"), 252, 292)
dump("music", workspace.MapMusic:FindFirstChild("MusicClient"), 98, 106)
local zs = workspace:FindFirstChild("Zipline") and workspace.Zipline:FindFirstChild("ZipServer")
if zs then
	local L = lines(src(zs) or "")
	for i, l in ipairs(L) do if l:find("Riding", 1, true) then print(string.format("QQ B3 zip %d: %s", i, l:gsub("^%s+", ""):sub(1, 160))) end end
end
-- who calls the croc text helpers (names + call lines with offsets)
local cc = workspace.Lagoon:FindFirstChild("CrocClient")
if cc then
	local L = lines(src(cc) or "")
	local n = 0
	for i, l in ipairs(L) do
		if (l:find("praise", 1, true) or l:find("floatText", 1, true) or l:find("shout", 1, true) or l:find("say(", 1, true) or l:find("speak(", 1, true)) and i > 200 then
			print(string.format("QQ B3 call %d: %s", i, l:gsub("^%s+", ""):sub(1, 170))); n += 1
			if n >= 14 then break end
		end
	end
end
print("QQ B3 DONE")
