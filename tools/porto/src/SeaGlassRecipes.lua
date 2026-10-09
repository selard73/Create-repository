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
	{id = "pearl",          name = "Pearl",             short = "pearl",   colour = Color3.fromRGB(246, 242, 236), pearl = true, weight = 0, rare = true},   -- never on a beach: one oyster at the back of the Grotta (Oct 9 2026)
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
	{id = "shellbox", name = "Shell box with a pearl", needs = {shell_scallop = 2, shell_spiral = 1, shell_cowrie = 1, pearl = 1}, keep = "shell_box",
		line = "A pearl from the Grotta! It needs a box of shells to live in. Keep it with your treasures."},
}
R.byRecipe = {}
for _, r in ipairs(R.recipes) do R.byRecipe[r.id] = r end
-- what each thing looks like (Oct 9 2026, the reveal): a Model of anchored parts round a hidden Core at its middle
local function part(m, shape, size, colour, material, cf, transparency)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = colour; p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.CFrame = cf; p.Parent = m
	return p
end
local function glass(m, size, colour, cf) local p = part(m, Enum.PartType.Ball, size, colour, Enum.Material.Glass, cf, 0.15); p.Reflectance = 0.1 return p end
function R.build(id)
	local m = Instance.new("Model"); m.Name = "Made_" .. tostring(id)
	local core = part(m, Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), nil, CFrame.new(), 1); core.Name = "Core"; m.PrimaryPart = core
	local K = R.byId
	local STRING = Color3.fromRGB(230, 220, 200)
	if id == "suncatcher" then
		part(m, Enum.PartType.Cylinder, Vector3.new(0.12, 2.6, 2.6), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		for i, kid in ipairs({"seaglass_green", "seaglass_blue", "seaglass_white", "seaglass_green", "seaglass_blue", "seaglass_green"}) do
			local a = math.rad(i * 60); local x, z = 0.95 * math.cos(a), 0.95 * math.sin(a)
			part(m, Enum.PartType.Cylinder, Vector3.new(0.9, 0.04, 0.04), STRING, nil, CFrame.new(x, 0.1, z) * CFrame.Angles(0, 0, math.rad(90)))
			glass(m, Vector3.new(0.42, 0.26, 0.34), K[kid].colour, CFrame.new(x, -0.45, z) * CFrame.Angles(0, a, 0))
		end
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_blue.colour, CFrame.new(0, 0.6, 0))
		part(m, Enum.PartType.Cylinder, Vector3.new(1.2, 0.04, 0.04), STRING, nil, CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "necklace" then
		for i = 1, 14 do
			local a = math.rad(i * 360 / 14); local r = 1.05
			local kid = (i % 3 == 0) and "shell_spiral" or "shell_cowrie"
			part(m, Enum.PartType.Ball, Vector3.new(0.34, 0.24, 0.26), K[kid].colour, Enum.Material.Sandstone, CFrame.new(r * math.cos(a), 0.15 * math.cos(a), r * math.sin(a)) * CFrame.Angles(0, -a, math.rad(20)))
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.05, 2.2, 2.2), STRING, nil, CFrame.new() * CFrame.Angles(math.rad(90), 0, 0), 0.3)
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_white.colour, CFrame.new(-1.05, -0.3, 0))
	elseif id == "vase" then
		part(m, Enum.PartType.Cylinder, Vector3.new(2.0, 1.1, 1.1), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new() * CFrame.Angles(0, 0, math.rad(90)))
		for row = 0, 4 do
			for i = 1, 8 do
				local a = math.rad(i * 45 + row * 20)
				local kid = (row % 2 == 0) and ((i % 3 == 0) and "seaglass_brown" or "seaglass_green") or ((i % 2 == 0) and "seaglass_green" or "seaglass_brown")
				glass(m, Vector3.new(0.3, 0.26, 0.18), K[kid].colour, CFrame.new(0.58 * math.cos(a), -0.75 + row * 0.37, 0.58 * math.sin(a)) * CFrame.Angles(0, -a, 0))
			end
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.1, 0.6, 0.6), K.shell_scallop.colour, Enum.Material.Sandstone, CFrame.new(0, 0.1, -0.62))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.3, 0.8, 0.8), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "parfum" then
		local body = part(m, Enum.PartType.Block, Vector3.new(0.9, 1.1, 0.5), K.seaglass_white.colour, Enum.Material.Glass, CFrame.new(0, -0.2, 0), 0.25); body.Reflectance = 0.15
		glass(m, Vector3.new(0.36, 0.36, 0.36), K.seaglass_blue.colour, CFrame.new(0.3, -0.5, 0.2))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.35, 0.3, 0.3), Color3.fromRGB(230, 200, 120), Enum.Material.Metal, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_purple.colour, CFrame.new(0, 0.9, 0))
	elseif id == "shellbox" then
		part(m, Enum.PartType.Block, Vector3.new(1.6, 0.8, 1.1), Color3.fromRGB(150, 110, 70), Enum.Material.Wood, CFrame.new(0, -0.3, 0))
		part(m, Enum.PartType.Block, Vector3.new(1.66, 0.22, 1.16), Color3.fromRGB(170, 128, 82), Enum.Material.Wood, CFrame.new(0, 0.21, 0))
		for i, kid in ipairs({"shell_scallop", "shell_spiral", "shell_cowrie", "shell_scallop", "shell_cowrie", "shell_spiral"}) do
			local a = math.rad(i * 60 + 20)
			part(m, Enum.PartType.Ball, Vector3.new(0.34, 0.16, 0.3), K[kid].colour, Enum.Material.Sandstone, CFrame.new(0.55 * math.cos(a), 0.37, 0.32 * math.sin(a)) * CFrame.Angles(0, -a, 0))
		end
		local pearl = part(m, Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4), K.pearl and K.pearl.colour or Color3.fromRGB(246, 242, 236), Enum.Material.SmoothPlastic, CFrame.new(0, 0.5, 0)); pearl.Reflectance = 0.35
	else
		glass(m, Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(200, 200, 220), CFrame.new())
	end
	return m
end
function R.needsText(r)
	local parts = {}
	for _, k in ipairs(R.kinds) do
		local n = r.needs[k.id]
		if n then table.insert(parts, n .. " " .. k.short) end
	end
	return table.concat(parts, ", ")
end
return R
