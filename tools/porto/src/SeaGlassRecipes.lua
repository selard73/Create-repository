-- SeaGlassRecipes (workspace.SeaGlass, shared by server and client): what Bella's beach holds and what she makes with you.
-- Item ids are Item_<id> on the player (saved like everything else through AwardItems).
local R = {}
R.kinds = {
	{id = "seaglass_green",  name = "Green sea glass",   short = "green",   colour = Color3.fromRGB(96, 190, 120),  glass = true, weight = 30},
	{id = "seaglass_brown",  name = "Brown sea glass",   short = "brown",   colour = Color3.fromRGB(150, 100, 60),  glass = true, weight = 25},
	{id = "seaglass_white",  name = "Frosted sea glass", short = "white",   colour = Color3.fromRGB(236, 241, 241), glass = true, weight = 20},
	{id = "seaglass_blue",   name = "Blue sea glass",    short = "blue",    colour = Color3.fromRGB(80, 140, 210),  glass = true, weight = 17},
	{id = "seaglass_purple", name = "Purple sea glass",  short = "purple",  colour = Color3.fromRGB(160, 100, 200), glass = true, weight = 8, rare = true},
	{id = "shell_scallop",   name = "Scallop shell",     short = "scallop", colour = Color3.fromRGB(240, 205, 180), shell = "scallop", weight = 22},
	{id = "shell_spiral",    name = "Spiral shell",      short = "spiral",  colour = Color3.fromRGB(225, 190, 150), shell = "spiral",  weight = 16},
	{id = "shell_cowrie",    name = "Cowrie shell",      short = "cowrie",  colour = Color3.fromRGB(215, 170, 130), shell = "cowrie",  weight = 16},
}
R.byId = {}
for _, k in ipairs(R.kinds) do R.byId[k.id] = k end
-- needs: item id -> count. pay: acorns Bella gives you for it. keep: it is yours instead (Item_<keep> = 1, once).
R.recipes = {
	{id = "suncatcher", name = "Sea glass suncatcher", needs = {seaglass_green = 2, seaglass_blue = 1, seaglass_white = 1}, pay = 60,
		line = "Hang it in a window and the whole room goes green and blue!"},
	{id = "necklace", name = "Shell necklace", needs = {shell_cowrie = 2, shell_spiral = 1, seaglass_white = 1}, pay = 70,
		line = "Cowries, a spiral and a frosted bead. Bellissima!"},
	{id = "vase", name = "Sea glass vase", needs = {seaglass_green = 3, seaglass_brown = 2, shell_scallop = 1}, pay = 80,
		line = "Mosaic all the way round, with a scallop for the front. My best seller!"},
	{id = "parfum", name = "Parfum bottle", needs = {seaglass_purple = 1, seaglass_white = 2, seaglass_blue = 1}, keep = "parfum_bottle",
		line = "The purple one! A bottle like this deserves a scent of its own. Keep it safe for France."},
}
R.byRecipe = {}
for _, r in ipairs(R.recipes) do R.byRecipe[r.id] = r end
function R.needsText(r)
	local parts = {}
	for _, k in ipairs(R.kinds) do
		local n = r.needs[k.id]
		if n then table.insert(parts, n .. " " .. k.short) end
	end
	return table.concat(parts, ", ")
end
return R
