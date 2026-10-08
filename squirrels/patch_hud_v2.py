"""HUD restyle v2 (Sep 17), after Shannon's mock-up: navy panel in a dark rim with a neon cyan edge and a faint cloudy
texture, pressed tiles for each squirrel, gold + cyan ringed portraits with a little acorn hanging off the ring, dim
"?" tiles for squirrels not found yet, a glossy yellow pill "Open Album" button. The Album and the squirrel Card get
the same theme. Re-runnable: restores make_squirrel_scripts.before_hud2.py first.
Run: python patch_hud_v2.py && python make_squirrel_scripts.py"""
import shutil
from pathlib import Path

D = Path(__file__).parent
p = D / "make_squirrel_scripts.py"
bk = D / "make_squirrel_scripts.before_hud2.py"
if bk.exists(): shutil.copy2(bk, p)
else: shutil.copy2(p, bk)
s = p.read_text(encoding="utf-8")


def replace_between(start, end, new, include_end=False):
    global s
    i = s.index(start)
    j = s.index(end, i + len(start))
    if include_end: j += len(end)
    s = s[:i] + new + s[j:]


def replace_once(old, new):
    global s
    assert s.count(old) == 1, ("expected exactly one occurrence", old[:60], s.count(old))
    s = s.replace(old, new)


# ---------------------------------------------------------------- theme + HUD panel
HUD = r'''-- theme (Shannon's mock-up, Sep 17): navy panel in a dark rim with a neon cyan edge, tiles like pressed buttons, gold and
-- cyan ringed portraits with an acorn tag, dim "?" tiles for squirrels not found yet, a glossy yellow pill button
local RGB = Color3.fromRGB
local NAVY, NAVY_DEEP, RIM = RGB(24, 52, 112), RGB(13, 32, 82), RGB(8, 18, 48)
local SLOT, SLOT_LO, SLOT_EDGE = RGB(34, 68, 136), RGB(22, 48, 104), RGB(10, 24, 62)
local CYAN, CYAN_TEXT, CYAN_DIM = RGB(72, 236, 255), RGB(222, 248, 255), RGB(96, 196, 230)
local GOLD, GOLD_LIGHT, GOLD_DARK = RGB(255, 202, 62), RGB(255, 236, 150), RGB(190, 128, 22)
local TEAL, TEAL_EDGE = RGB(46, 178, 203), RGB(94, 226, 246)      -- the button lettering and its rim (sampled from the mock-up)
local BUTTON_GRADIENT = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 226, 96)), ColorSequenceKeypoint.new(0.3, RGB(251, 203, 38)), ColorSequenceKeypoint.new(0.7, RGB(238, 174, 22)), ColorSequenceKeypoint.new(1, RGB(212, 142, 10))})
local BTN_H = 38
local CREAM = RGB(255, 248, 225)
local PANEL = SLOT                                  -- mask tint: hides the square corners of each portrait, so it matches the tile
local TILE, COLS, HUD_W = 62, 5, 358
local PORTRAIT_ZOOM, PORTRAIT_DOWN = 1.15, 0.05    -- the coin shows head, shoulders and paws, not just the face
local hudHolder
local FONT = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)   -- clean rounded bold, like the mock-up
local FONT_BUTTON = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Heavy)
local FONT_TEXT = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
local TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local function maskId() return script.Parent:GetAttribute("MaskImage") or "rbxassetid://77268792392056" end
local function corner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = parent; return c end
local function stroke(parent, color, th, tr) local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = th; st.Transparency = tr or 0; st.Parent = parent; return st end
local function gradient(parent, top, bottom, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(top, bottom); g.Rotation = rot or 90; g.Parent = parent; return g end
-- a faint cloudy texture over a surface (the built-in smoke tile) so panels and tiles read as material, not flat colour
local function texture(parent, z, tileSize, tr, radius, color)
	local t = Instance.new("ImageLabel"); t.Name = "Texture"; t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Image = TEXTURE; t.ScaleType = Enum.ScaleType.Tile; t.TileSize = UDim2.fromOffset(tileSize, tileSize); t.ImageTransparency = tr
	t.ImageColor3 = color or RGB(150, 205, 255); t.ZIndex = z; t.Parent = parent
	corner(t, radius)
	return t
end
-- panel: dark rim with a soft outer glow, the neon line, a navy face with a vertical sheen and texture.
-- Returns the face (content goes in it) and the rim (position and size go on it).
local function neonPanel(parent, z, radius)
	local rim = Instance.new("Frame"); rim.Name = "Rim"; rim.BackgroundColor3 = RIM; rim.ZIndex = z; rim.Parent = parent
	corner(rim, UDim.new(0, radius + 5)); stroke(rim, CYAN, 6, 0.8)
	local rp = Instance.new("UIPadding"); rp.PaddingTop = UDim.new(0, 5); rp.PaddingBottom = UDim.new(0, 5); rp.PaddingLeft = UDim.new(0, 5); rp.PaddingRight = UDim.new(0, 5); rp.Parent = rim
	local face = Instance.new("Frame"); face.Name = "Face"; face.Size = UDim2.fromScale(1, 1); face.BackgroundColor3 = NAVY; face.ZIndex = z + 1; face.Parent = rim
	corner(face, UDim.new(0, radius)); stroke(face, CYAN, 3, 0.05)
	gradient(face, RGB(32, 70, 142), NAVY_DEEP)
	texture(face, z + 1, 180, 0.9, UDim.new(0, radius))
	local sheen = Instance.new("Frame"); sheen.Name = "Sheen"; sheen.Size = UDim2.new(1, -10, 0, 70); sheen.Position = UDim2.fromOffset(5, 5)
	sheen.BackgroundColor3 = RGB(255, 255, 255); sheen.BackgroundTransparency = 0.94; sheen.ZIndex = z + 1; sheen.Parent = face
	corner(sheen, UDim.new(0, radius - 3)); gradient(sheen, RGB(255, 255, 255), RGB(24, 52, 112))
	return face, rim
end
-- a pressed tile a portrait sits in (flat colour on purpose: the portrait mask is tinted to match it)
local function tile(parent, size, z)
	local t = Instance.new("Frame"); t.Name = "Tile"; t.Size = UDim2.fromOffset(size, size); t.BackgroundColor3 = SLOT; t.ZIndex = z; t.Parent = parent
	corner(t, UDim.new(0, 12)); stroke(t, SLOT_EDGE, 2, 0.1)
	texture(t, z, 90, 0.93, UDim.new(0, 12))
	return t
end
-- a little acorn hanging off the bottom of a ring
local function acorn(parent, w, z)
	local a = Instance.new("Frame"); a.Name = "Acorn"; a.Size = UDim2.fromOffset(w, math.floor(w * 1.2)); a.AnchorPoint = Vector2.new(0.5, 0)
	a.Position = UDim2.new(0.5, 0, 1, -math.floor(w * 0.6)); a.BackgroundTransparency = 1; a.ZIndex = z; a.Parent = parent
	local nut = Instance.new("Frame"); nut.Size = UDim2.new(0.78, 0, 0.7, 0); nut.AnchorPoint = Vector2.new(0.5, 1); nut.Position = UDim2.new(0.5, 0, 1, 0)
	nut.BackgroundColor3 = RGB(206, 136, 62); nut.ZIndex = z; nut.Parent = a
	corner(nut, UDim.new(0.5, 0)); stroke(nut, RGB(92, 52, 18), 1, 0.15); gradient(nut, RGB(230, 164, 86), RGB(160, 96, 36))
	local cap = Instance.new("Frame"); cap.Size = UDim2.new(1, 0, 0.42, 0); cap.Position = UDim2.new(0, 0, 0.14, 0)
	cap.BackgroundColor3 = RGB(126, 76, 34); cap.ZIndex = z + 1; cap.Parent = a
	corner(cap, UDim.new(0.5, 0)); stroke(cap, RGB(70, 40, 14), 1, 0.15); gradient(cap, RGB(156, 100, 48), RGB(96, 56, 22))
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.16, 0, 0.22, 0); stem.AnchorPoint = Vector2.new(0.5, 0); stem.Position = UDim2.new(0.5, 0, 0, 0)
	stem.BackgroundColor3 = RGB(88, 52, 20); stem.ZIndex = z; stem.Parent = a
	corner(stem, UDim.new(0.5, 0))
	return a
end
-- the chunky yellow pill button: saturated gold shaded like a tube (lemon highlight on top, amber below), a thick bright
-- cyan rim with a soft glow outside it, and big rounded teal lettering with a dark-teal edge and a shadow so it stands
-- off the button. The background stays white so the gradient shows its own colours (BackgroundColor3 multiplies it);
-- the lettering sits ABOVE the gloss strip so it stays crisp.
-- a glowing neon line on the edge of a rounded object: a bright core plus halo bands fading outward and inward.
-- UIStroke draws outward from its frame's edge, so inset frames put their bands inside the object.
local function neonEdge(target, z)
	-- concentric rings: each frame is expanded so its stroke starts where the previous one ends
	local function ring(expand, th, tr, col)
		local f = Instance.new("Frame"); f.Name = "Glow"; f.Size = UDim2.new(1, 2 * expand, 1, 2 * expand); f.Position = UDim2.fromOffset(-expand, -expand)
		f.BackgroundTransparency = 1; f.ZIndex = z; f.Parent = target
		corner(f, UDim.new(1, 0)); stroke(f, col, th, tr)
	end
	stroke(target, RGB(8, 30, 56), 1.5, 0.15)                     -- dark hairline between the yellow and the line
	ring(1.5, 2.5, 0, RGB(120, 238, 255))                         -- the teal line; no glow (Shannon: the line is enough)
end
local function pillButton(parent, text, height, textSize, z)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, height); b.BackgroundColor3 = RGB(255, 255, 255); b.Text = ""
	b.AutoButtonColor = false; b.ZIndex = z; b.Parent = parent
	corner(b, UDim.new(1, 0))
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = b
	neonEdge(b, z)
	local gloss = Instance.new("Frame"); gloss.Size = UDim2.new(1, -26, 0.3, 0); gloss.Position = UDim2.new(0, 13, 0, 4); gloss.BackgroundColor3 = RGB(255, 250, 215)
	gloss.BackgroundTransparency = 0.78; gloss.ZIndex = z + 1; gloss.Parent = b
	corner(gloss, UDim.new(1, 0))
	-- molded-plastic lettering: the glyph face is shaded light teal (top) to deeper teal (bottom), and its outline is
	-- shaded the same way, pale along the top edges and dark along the bottom edges, so every letter reads as a lit,
	-- rounded solid. Underneath, a soft amber shadow (the yellow going darker) seats it on the button.
	local function glyphs(dx, dy, color, tr, zz)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.Position = UDim2.fromOffset(dx, dy); l.BackgroundTransparency = 1
		l.Text = text; l.FontFace = FONT_BUTTON; l.TextSize = textSize; l.TextColor3 = color; l.TextTransparency = tr; l.ZIndex = zz; l.Parent = b
		return l
	end
	-- extruded lettering (Shannon's crop: the letters have squared-off side walls under the face, like pieces cut from
	-- a slab and set on the button). Copies of the text step down in the side colour to build the wall, a warm contact
	-- shadow pools under the wall, and the flat face goes on top with a hairline edge that is lit on top.
	local shade = glyphs(0, 5, RGB(190, 124, 20), 0.72, z + 2)
	local ss = Instance.new("UIStroke"); ss.Color = RGB(190, 124, 20); ss.Thickness = 1.5; ss.Transparency = 0.82; ss.LineJoinMode = Enum.LineJoinMode.Round; ss.Parent = shade
	local wall = {{1, 3, RGB(40, 148, 184)}, {1, 2, RGB(48, 160, 196)}, {0, 1, RGB(56, 172, 206)}}
	for i, w in ipairs(wall) do
		local side = glyphs(w[1], w[2], w[3], 0, z + 2 + i)
		local ws = Instance.new("UIStroke"); ws.Color = w[3]; ws.Thickness = 0.8; ws.LineJoinMode = Enum.LineJoinMode.Miter; ws.Parent = side
	end
	local label = glyphs(0, 0, RGB(255, 255, 255), 0, z + 6)
	local tg = Instance.new("UIGradient"); tg.Rotation = 90
	tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(140, 232, 248)), ColorSequenceKeypoint.new(0.5, RGB(86, 206, 230)), ColorSequenceKeypoint.new(1, RGB(70, 196, 222))})
	tg.Parent = label
	local ls = Instance.new("UIStroke"); ls.Color = RGB(255, 255, 255); ls.Thickness = 1; ls.Transparency = 0.1; ls.LineJoinMode = Enum.LineJoinMode.Miter; ls.Parent = label
	local lg = Instance.new("UIGradient"); lg.Rotation = 90                     -- the face's squared edge: lit on top, side colour below
	lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(220, 252, 255)), ColorSequenceKeypoint.new(0.5, RGB(70, 182, 214)), ColorSequenceKeypoint.new(1, RGB(44, 150, 186))})
	lg.Parent = ls
	b.MouseEnter:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.6}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.78}):Play() end)
	return b
end
-- a round yellow button with an x, for closing the album and the card
local function closeButton(parent, z, onClick)
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10); close.BackgroundColor3 = RGB(255, 255, 255); close.Text = "x"; close.AutoButtonColor = false
	close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = TEAL; close.ZIndex = z; close.Parent = parent
	corner(close, UDim.new(1, 0)); stroke(close, TEAL_EDGE, 2, 0.05)
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = close
	close.MouseEnter:Connect(function() close.BackgroundColor3 = RGB(255, 255, 235) end)
	close.MouseLeave:Connect(function() close.BackgroundColor3 = RGB(255, 255, 255) end)
	close.MouseButton1Click:Connect(onClick)
	return close
end
ensureHud = function()
	if hud then return end
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	hud = Instance.new("ScreenGui"); hud.Name = "SquirrelHUD"; hud.ResetOnSpawn = false; hud.IgnoreGuiInset = true
	hud.DisplayOrder = 5; hud.Parent = pg
	-- sizes are set by hand in updateCounter (no AutomaticSize: the texture and sheen layers would feed back into it)
	hudHolder = Instance.new("Frame"); hudHolder.Name = "Panel"; hudHolder.AnchorPoint = Vector2.new(1, 0); hudHolder.Position = UDim2.new(1, -10, 0, 8)
	hudHolder.Size = UDim2.fromOffset(HUD_W, 200); hudHolder.BackgroundTransparency = 1; hudHolder.Parent = hud
	local face, rim = neonPanel(hudHolder, 1, 16)
	rim.Size = UDim2.fromScale(1, 1)
	local content = Instance.new("Frame"); content.Name = "Content"; content.Size = UDim2.fromScale(1, 1); content.BackgroundTransparency = 1; content.ZIndex = 3; content.Parent = face
	local ppad = Instance.new("UIPadding"); ppad.PaddingTop = UDim.new(0, 8); ppad.PaddingBottom = UDim.new(0, 10)
	ppad.PaddingLeft = UDim.new(0, 10); ppad.PaddingRight = UDim.new(0, 10); ppad.Parent = content
	local list = Instance.new("UIListLayout"); list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0, 8); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = content
	counter = Instance.new("TextLabel"); counter.Name = "Counter"; counter.Size = UDim2.new(1, 0, 0, 22); counter.BackgroundTransparency = 1; counter.TextWrapped = true
	counter.FontFace = FONT; counter.TextScaled = true; counter.TextColor3 = CYAN_TEXT; counter.TextXAlignment = Enum.TextXAlignment.Center; counter.Text = ""
	counter.ZIndex = 3; counter.LayoutOrder = 1; counter.Parent = content
	local ctc = Instance.new("UITextSizeConstraint"); ctc.MaxTextSize = 16; ctc.MinTextSize = 10; ctc.Parent = counter   -- one line shrinks to fit the panel
	stroke(counter, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	grid = Instance.new("Frame"); grid.Name = "Badges"; grid.Size = UDim2.new(1, 0, 0, TILE)
	grid.BackgroundTransparency = 1; grid.LayoutOrder = 2; grid.ZIndex = 3; grid.Parent = content
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE, TILE); gl.CellPadding = UDim2.fromOffset(4, 4)
	gl.FillDirection = Enum.FillDirection.Horizontal; gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gl.StartCorner = Enum.StartCorner.TopLeft; gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
	local albumBtn = pillButton(content, "Open Album", BTN_H, 24, 3); albumBtn.LayoutOrder = 3
	albumBtn.MouseButton1Click:Connect(function() if album then closeAlbum() else openAlbum() end end)
end
'''
replace_between("local PANEL = Color3.fromRGB(38, 30, 52)\n", "updateCounter = function()", HUD)

# ---------------------------------------------------------------- the album
ALBUM = r'''openAlbum = function()
	closeAlbum(); ensureHud()
	album = Instance.new("Frame"); album.Name = "Album"; album.Size = UDim2.fromScale(1, 1); album.BackgroundColor3 = Color3.new(0, 0, 0)
	album.BackgroundTransparency = 0.45; album.ZIndex = 30; album.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 30; backdrop.Parent = album; backdrop.MouseButton1Click:Connect(closeAlbum)
	local panel, rim = neonPanel(album, 31, 22)
	rim.AnchorPoint = Vector2.new(0.5, 0.5); rim.Position = UDim2.fromScale(0.5, 0.5); rim.Size = UDim2.new(0, 600, 0.82, 0)
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -80, 0, 44); title.Position = UDim2.new(0, 24, 0, 12)
	title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextSize = 28
	title.FontFace = FONT; title.TextColor3 = CYAN_TEXT
	local all, allTotal = 0, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels
	for _ in pairs(foundIds) do all += 1 end
	title.Text = string.format("Squirrel Album   %d / %d", all, allTotal); title.ZIndex = 33; title.Parent = panel
	stroke(title, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	closeButton(panel, 34, closeAlbum)
	local scroll = Instance.new("ScrollingFrame"); scroll.Position = UDim2.new(0, 18, 0, 64); scroll.Size = UDim2.new(1, -36, 1, -80)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = CYAN; scroll.ZIndex = 33
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 12); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
	-- squirrels present on this map, by id, for faces and cards
	local here = {}
	for model, st in pairs(squirrels) do here[idOf(model)] = {model = model, st = st} end
	for mi, map in ipairs(Registry.maps) do
		local mapFound, mapTotal = 0, 0
		for _, e in ipairs(Registry.squirrels) do if e.map == map.id then mapTotal += 1; if foundIds[e.id] then mapFound += 1 end end end
		local section = Instance.new("Frame"); section.Size = UDim2.new(1, 0, 0, 0); section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundTransparency = 1; section.LayoutOrder = mi; section.ZIndex = 33; section.Parent = scroll
		local sl = Instance.new("UIListLayout"); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Padding = UDim.new(0, 6); sl.Parent = section
		local head = Instance.new("TextLabel"); head.Size = UDim2.new(1, 0, 0, 24); head.BackgroundTransparency = 1
		head.AutomaticSize = Enum.AutomaticSize.Y; head.TextWrapped = true; head.LayoutOrder = 1
		head.TextXAlignment = Enum.TextXAlignment.Left; head.TextSize = 18; head.ZIndex = 33
		head.FontFace = FONT; head.TextColor3 = CYAN_TEXT
		head.Text = string.format("%s   %d / %d", map.name, mapFound, mapTotal); head.Parent = section
		stroke(head, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
		local grid = Instance.new("Frame"); grid.LayoutOrder = 2; grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y; grid.BackgroundTransparency = 1; grid.ZIndex = 33; grid.Parent = section
		local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE + 6, TILE + 24); gl.CellPadding = UDim2.fromOffset(4, 6)
		gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
		local order = 0
		for _, e in ipairs(Registry.squirrels) do
			if e.map == map.id then
				order += 1
				local cell = Instance.new("Frame"); cell.BackgroundTransparency = 1; cell.LayoutOrder = order; cell.ZIndex = 33; cell.Parent = grid
				local isFound = foundIds[e.id] == true
				local t = tile(cell, TILE, 34); t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0, 0)
				local box = circleWindow(t, CIRCLE, 35, isFound)
				box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
				if isFound then acorn(box, 15, 44) end
				local h = here[e.id]
				if isFound and h then
					makeViewport(box, h.st, faceCamera(h.st))
				else
					local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1
					q.Text = isFound and e.name:sub(1, 1) or "?"; q.TextSize = isFound and 26 or 30
					q.FontFace = FONT; q.TextColor3 = isFound and CYAN_TEXT or CYAN_DIM; q.TextTransparency = isFound and 0 or 0.15; q.ZIndex = 43; q.Parent = box
				end
				local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 20); name.Position = UDim2.new(0, 0, 0, TILE + 3)
				name.BackgroundTransparency = 1; name.Text = isFound and e.name or ""; name.TextWrapped = true; name.TextScaled = true
				name.FontFace = FONT_TEXT; name.TextColor3 = CYAN_TEXT; name.ZIndex = 34; name.Parent = cell
				local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
				if isFound and h then
					local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
					btn.ZIndex = 45; btn.Parent = cell
					btn.MouseButton1Click:Connect(function() closeAlbum(); openCard(h.model, h.st) end)
				end
			end
		end
	end
	local sc = Instance.new("UIScale"); sc.Scale = 0.85; sc.Parent = rim
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

'''
replace_between("openAlbum = function()\n", "local badgeOrder = 0", ALBUM)

# ---------------------------------------------------------------- portraits in the HUD
BADGES = r'''-- the coin: a portrait window that sits proud of its tile. Layers, bottom up: drop shadow, dark disc, the 3D render
-- (makeViewport puts it at z + 2), the mask (transparent circle tinted like the tile), a soft cyan glow, the cyan ring,
-- the gold bevel (a gradient-lit stroke, light on top, dark amber below), a thin highlight on the inner lip.
-- Squirrels not found yet get a plain dim ring instead.
circleWindow = function(parent, size, z, found)
	local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(size, size); box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 0); box.BackgroundTransparency = 1; box.ZIndex = z; box.Parent = parent
	local function ringFrame(inset, zz)
		local f = Instance.new("Frame"); f.Size = UDim2.new(1, -2 * inset, 1, -2 * inset); f.Position = UDim2.fromOffset(inset, inset)
		f.BackgroundTransparency = 1; f.ZIndex = zz; f.Parent = box
		corner(f, UDim.new(1, 0))
		return f
	end
	if found then
		local shadow = ringFrame(-1, z); shadow.Name = "Shadow"; shadow.Position = UDim2.fromOffset(-1, 3)
		shadow.BackgroundColor3 = RGB(0, 0, 0); shadow.BackgroundTransparency = 0.5
	end
	local disc = Instance.new("Frame"); disc.Name = "Disc"; disc.Size = UDim2.fromScale(1, 1); disc.BackgroundColor3 = found and RGB(28, 58, 120) or SLOT_LO; disc.ZIndex = z + 1; disc.Parent = box
	corner(disc, UDim.new(1, 0))
	if found then gradient(disc, RGB(38, 78, 152), RGB(12, 30, 74)) end
	local mask = Instance.new("ImageLabel"); mask.Name = "Mask"; mask.Size = UDim2.fromScale(1, 1); mask.BackgroundTransparency = 1
	mask.Image = maskId(); mask.ImageColor3 = PANEL; mask.ScaleType = Enum.ScaleType.Fit; mask.ZIndex = z + 3; mask.Parent = box
	if found then
		stroke(ringFrame(3, z + 4), CYAN, 6, 0.78)                                  -- soft glow
		stroke(ringFrame(4, z + 5), CYAN, 2, 0.05)                                  -- the cyan ring
		stroke(ringFrame(-1, z + 5), RGB(90, 56, 8), 1.5, 0.35)                     -- dark edge under the bevel
		local bevel = stroke(ringFrame(0, z + 6), GOLD, 4)
		local gg = Instance.new("UIGradient"); gg.Rotation = 90
		gg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 244, 190)), ColorSequenceKeypoint.new(0.35, RGB(252, 206, 70)), ColorSequenceKeypoint.new(1, RGB(160, 100, 16))})
		gg.Parent = bevel
		stroke(ringFrame(2, z + 7), RGB(255, 252, 230), 1, 0.55)                    -- highlight on the inner lip
	else
		stroke(ringFrame(1, z + 5), CYAN_DIM, 2, 0.45)
	end
	return box, disc, mask
end
addBadge = function(model, st)
	ensureHud()
	if badges[model] then return badges[model] end
	badgeOrder += 1
	local cell = Instance.new("Frame"); cell.Name = model.Name; cell.BackgroundTransparency = 1; cell.LayoutOrder = badgeOrder; cell.ZIndex = 3; cell.Parent = grid
	local t = tile(cell, TILE, 3)
	local box = circleWindow(t, CIRCLE, 4, false)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Text = "?"
	q.FontFace = FONT; q.TextSize = 30; q.TextColor3 = CYAN_DIM; q.TextTransparency = 0.15; q.ZIndex = 12; q.Parent = box
	local b = {cell = cell, tile = t, box = box, filled = false}
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 16; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() if b.filled then openCard(model, st) end end)
	btn.MouseEnter:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -4)}):Play() end end)
	btn.MouseLeave:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -2)}):Play() end end)
	badges[model] = b
	updateCounter()
	return b
end
fillBadge = function(model, st)
	local b = addBadge(model, st)
	if b.filled then return end
	b.filled = true
	b.box:Destroy()                                   -- the "?" window goes; a proper coin takes its place
	local box = circleWindow(b.tile, CIRCLE, 4, true)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	b.box = box
	makeViewport(box, st, faceCamera(st))             -- z 6: over the disc (5), under the mask (7) and the rings (8 to 11)
	acorn(box, 15, 13)
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = b.cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end
'''
replace_between("-- a square that shows a circle: backing disc, 3D render, mask (transparent circle, tinted like the panel), ring\n", "ensureBadges = function()", BADGES)

# ---------------------------------------------------------------- the card
CARD_TOP = r'''	local panel, prim = neonPanel(card, 21, 22)
	prim.AnchorPoint = Vector2.new(0.5, 0.5); prim.Position = UDim2.fromScale(0.5, 0.5); prim.Size = UDim2.fromOffset(432, 566)
	local big = tile(panel, 326, 22); big.AnchorPoint = Vector2.new(0.5, 0); big.Position = UDim2.new(0.5, 0, 0, 16)
	local ring = circleWindow(big, 288, 22, true)
	ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.new(0.5, 0, 0.5, -6)
	acorn(ring, 44, 31)
'''
replace_between('\tlocal panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)\n\tpanel.Size = UDim2.fromOffset(420, 540)',
                '\tlocal rs = Instance.new("UIStroke"); rs.Thickness = 3; rs.Color = Color3.fromRGB(255, 205, 90); rs.Parent = ringLine\n', CARD_TOP, include_end=True)
replace_once("hint.Position = UDim2.new(0, 0, 0, 334)", "hint.Position = UDim2.new(0, 0, 0, 350)")
replace_once('hint.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); hint.TextColor3 = Color3.fromRGB(190, 180, 210)',
             "hint.FontFace = FONT_TEXT; hint.TextColor3 = CYAN_DIM")
replace_once("title.Position = UDim2.new(0, 20, 0, 352)", "title.Position = UDim2.new(0, 20, 0, 368)")
replace_once('title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold); title.TextColor3 = Color3.fromRGB(255, 232, 170)\n\ttitle.ZIndex = 22; title.Parent = panel',
             "title.FontFace = FONT; title.TextColor3 = GOLD_LIGHT\n\ttitle.ZIndex = 22; title.Parent = panel")
replace_once("bio.Position = UDim2.new(0, 22, 0, 398)", "bio.Position = UDim2.new(0, 22, 0, 414)")
replace_once('bio.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); bio.TextColor3 = Color3.fromRGB(245, 240, 250)',
             "bio.FontFace = Font.new(\"rbxasset://fonts/families/Nunito.json\", Enum.FontWeight.SemiBold); bio.TextColor3 = CYAN_TEXT")
CARD_CLOSE_OLD = '''	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10); close.BackgroundColor3 = Color3.fromRGB(255, 205, 90); close.Text = "x"
	close.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); close.TextSize = 20; close.TextColor3 = Color3.fromRGB(38, 30, 52)
	close.ZIndex = 23; close.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = close
	close.MouseButton1Click:Connect(closeCard)
	local sc = Instance.new("UIScale"); sc.Scale = 0.7; sc.Parent = panel
'''
replace_once(CARD_CLOSE_OLD, "\tcloseButton(panel, 23, closeCard)\n\tlocal sc = Instance.new(\"UIScale\"); sc.Scale = 0.7; sc.Parent = prim\n")

replace_once("\tvp.ZIndex = 23; vp.Parent = ring\n", "\tvp.ZIndex = 24; vp.Parent = ring\n")            # the card render: over the disc, under the mask
replace_once("\tvp.ZIndex = parent.ZIndex + 1; vp.Parent = parent\n", "\tvp.ZIndex = parent.ZIndex + 2; vp.Parent = parent\n")
# portraits show a little more squirrel (shoulders and paws at the rim), same centring
replace_once('\tlocal dist = (model and model:GetAttribute("FaceDist")) or tw.dist or 1.35\n',
             '\tlocal dist = ((model and model:GetAttribute("FaceDist")) or tw.dist or 1.35) * PORTRAIT_ZOOM\n')
replace_once("\tlocal centre = bottom + Vector3.new(0, (0.70 + up) * H, 0) + fwd * (0.30 * H)\n",
             "\tlocal centre = bottom + Vector3.new(0, (0.70 + up - PORTRAIT_DOWN) * H, 0) + fwd * (0.30 * H)\n")

# ---------------------------------------------------------------- sizes
replace_once("local CIRCLE = 52\n", "local CIRCLE = 46            -- portrait diameter inside a 62 px tile\n")
# the panel height follows the counter lines and the rows of tiles for the map the player is on
replace_once('''	for model, b in pairs(badges) do
		local e = regById[idOf(model)]
		b.cell.Visible = (e == nil) or (e.map == mapId)
	end
end''', '''	local visible = 0
	for model, b in pairs(badges) do
		local e = regById[idOf(model)]
		b.cell.Visible = (e == nil) or (e.map == mapId)
		if b.cell.Visible then visible += 1 end
	end
	local rows = math.max(1, math.ceil(visible / COLS))
	local lines = select(2, counter.Text:gsub("\\n", "")) + 1
	counter.Size = UDim2.new(1, 0, 0, 22 * lines)
	grid.Size = UDim2.new(1, 0, 0, rows * (TILE + 4) - 4)
	if hudHolder then hudHolder.Size = UDim2.fromOffset(HUD_W, 10 + 8 + 22 * lines + 8 + rows * (TILE + 4) - 4 + 8 + BTN_H + 10) end
end''')

p.write_text(s, encoding="utf-8")
print("hud v2 patched; leftovers:", s.count("Color3.fromRGB(38, 30, 52)"), "old panel colour refs;", s.count("Color3.fromRGB(255, 205, 90)"), "old gold refs")
