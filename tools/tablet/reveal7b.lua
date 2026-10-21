-- reveal7b (Oct 20 2026): after reveal7's first real pick-up on the iPad: one sparkle sat on the name ("Scallop sh*ll!") and
-- at 2.5 s it was already fading when you looked. Sparkles now on the top and sides only (160..380 degrees); 3.0 s, rare 3.8 s.
local SES = game:GetService("ScriptEditorService")
local sgc = workspace.SeaGlass.SeaGlassClient
local src = sgc.Source
local function replaceOnce(s, find, repl, what)
	local a, b = s:find(find, 1, true)
	assert(a, what .. ": not found - nothing changed")
	assert(not s:find(find, b + 1, true), what .. ": found twice - nothing changed")
	return s:sub(1, a - 1) .. repl .. s:sub(b + 1)
end
src = replaceOnce(src, "local a = (i / n) * math.pi * 2 + 0.3", "local a = math.rad(160 + (i - 1) * 220 / math.max(1, n - 1))   -- (top and sides only: one sat on the name - Oct 20)", "star angle")
src = replaceOnce(src, "local life = rare and 3.2 or 2.5", "local life = rare and 3.8 or 3.0", "reveal life")
SES:UpdateSourceAsync(sgc, function() return src end)
return "reveal7b installed"
