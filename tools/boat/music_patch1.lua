-- music_patch1 v1: MapMusic.MusicClient goes quiet while the character has the NoMusic attribute (the boat sets it when a
-- player takes the boat, and never clears it: "the music should stop once in the boat and not start again" - Shannon,
-- Oct 1 2026). Same one-line change in the builder boundary/build_music.lua. Safe to re-run.
local s = workspace:FindFirstChild("MapMusic") and workspace.MapMusic:FindFirstChild("MusicClient")
if not s then print("QQ MU no MusicClient"); return end
local src = s.Source
local a = "char:GetAttribute(\"Riding\") or char:GetAttribute(\"InBookshop\")"
local b = "char:GetAttribute(\"Riding\") or char:GetAttribute(\"NoMusic\") or char:GetAttribute(\"InBookshop\")"
if src:find(b, 1, true) then
	print("QQ MU MusicClient already reads NoMusic")
else
	local i, j = src:find(a, 1, true)
	if not i then print("QQ MU pattern not found in MusicClient; nothing changed"); return end
	s.Source = src:sub(1, i - 1) .. b .. src:sub(j + 1)
	print("QQ MU MusicClient patched: quiet while the character has NoMusic")
end
