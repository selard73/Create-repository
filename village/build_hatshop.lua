-- HatShop: go into the CHAPELIER and buy a hat to wear. Shannon (Sep 26 roadmap): "wearable hats for acorns; first shelf =
-- the styles already modelled for the Chapelier window x a few colours; the work = fitting every head size, a try-on
-- mirror, saving what you own" - and (Sep 27, before bed): "If you finish, you can go on to the hat store also."
--
-- THE SHOP, the Librairie's way (village/build_bookshop.lua): the townhouse is one solid mesh, so the inside is a room
-- built high over the shop (y 340; the Librairie's is at 300 next door). The prompt on the Chapelier's street door fades
-- to black and the server moves you in; the door inside takes you back out. The room is tagged SkyRoom, so RoomHide keeps
-- it off every screen but the ones inside. Inside: the street wall in the shopfront's sage green with the display window
-- and the mustard awning seen through it; the HAT WALL at the back - seven bays, one per style, the three colourways on
-- round shelves, a brass price plaque under each; a tall arched MIRROR on the west wall; the counter with a till and hat
-- boxes on the east; a hat tree, a pouf, a rug and three low pendant lamps.
--
-- THE HATS (village/gen_hat_kit.py -> ReplicatedStorage.HatKit): the window's seven styles - top hat, boater, cloche, sun
-- hat, bowler, fedora, beret - three colourways each, 21 hats. The Catalogue module in the kit holds the names, colours,
-- default prices and the fitting (the server and every client share it). Prices are attributes on workspace.HatShop
-- (Price_<style>), so re-pricing is editing numbers in Properties.
-- THE MIRROR: its prompt ("Try on hats") turns you to face it and swings the camera round to be the mirror, with the
-- Chapelier's panel beside you: every hat as a little 3D picture, tap one and it is on your head (on your screen only)
-- until you buy it (acorns, once; you wear it straight away) or wear one you own; "No hat" takes it off. Everything else
-- on screen steps aside while you are at the mirror, so nothing overlaps on a phone.
-- WEARING: owned hats are ledger items Item_hat_<id>; the one worn is Item_hatwear_<id> = 1 (both saved with the rest
-- of the progress through AwardItems - nothing here touches the DataStore). The server puts the worn hat on as an
-- Accessory at the head's HatAttachment, sized to the head (a hat is made for a head 1.2 wide), hides the avatar's own
-- hats while it is on; hair remains visible. Reapplied on respawn, visible to everyone.
-- Run in edit mode (re-runnable); needs ReplicatedStorage.HatKit (scratchpad kit_hats.lua).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local C = Color3.fromRGB
	local rng = Random.new(opts.seed or 2710)
	local kit = RS:FindFirstChild("HatKit")
	assert(kit and kit:FindFirstChild("Hat_top"), "HatShop: import the hats first (kit_hats.lua)")

	-- ---------------------------------------------------------------- the catalogue ----
	local CAT = [==[
-- Catalogue: the Chapelier's hats (workspace.HatShop, village/build_hatshop.lua). Seven styles - the ones in the shop
-- window - three colourways each; a hat's id is "<style>_<n>". Its pieces are Hat_<style> (crown and brim) and
-- Band_<style> (the ribbon; the sun hat's flowers; the beret's stalk) in ReplicatedStorage.HatKit, made for a head 1.2
-- wide with y 0 where the crown meets the brim (village/gen_hat_kit.py).
local C = Color3.fromRGB
local M = {}
M.styles = {
	{id = "top", name = "Top hat", price = 150, sink = 0.36, colours = {
		{name = "black", crown = C(36, 34, 38), band = C(172, 42, 50)},
		{name = "midnight", crown = C(42, 50, 94), band = C(224, 180, 82)},
		{name = "lavender", crown = C(172, 152, 204), band = C(250, 242, 226)}}},
	{id = "boater", name = "Boater", price = 90, sink = 0.28, tilt = 4, colours = {
		{name = "straw & navy", crown = C(228, 200, 144), band = C(44, 58, 112)},
		{name = "straw & red", crown = C(228, 200, 144), band = C(182, 50, 54)},
		{name = "cream & lilac", crown = C(242, 230, 204), band = C(162, 132, 192)}}},
	{id = "cloche", name = "Cloche", price = 70, sink = 0.175, tilt = 6, colours = {   -- shallow tilt clears rear hair while keeping the front above the eyes
		{name = "rose", crown = C(206, 122, 132), band = C(250, 240, 226)},
		{name = "sage", crown = C(128, 158, 118), band = C(226, 184, 92)},
		{name = "navy", crown = C(48, 58, 102), band = C(234, 152, 162)}}},
	{id = "sun", name = "Sun hat", price = 110, sink = 0.16, tilt = 14, colours = {    -- (0.3 put the wide brim over the eyes)
		{name = "straw", crown = C(232, 206, 152), band = C(234, 140, 162)},
		{name = "white", crown = C(246, 242, 232), band = C(240, 196, 82)},
		{name = "peach", crown = C(242, 182, 150), band = C(172, 142, 204)}}},
	{id = "bowler", name = "Bowler", price = 80, sink = 0.36, colours = {
		{name = "black", crown = C(32, 32, 36), band = C(64, 62, 68)},
		{name = "brown", crown = C(112, 76, 50), band = C(198, 162, 112)},
		{name = "grey", crown = C(122, 122, 128), band = C(132, 42, 54)}}},
	{id = "fedora", name = "Fedora", price = 100, sink = 0.36, tilt = 6, colours = {
		{name = "grey", crown = C(112, 114, 120), band = C(36, 34, 38)},
		{name = "tan", crown = C(178, 144, 102), band = C(98, 64, 42)},
		{name = "green", crown = C(72, 102, 74), band = C(224, 180, 82)}}},
	{id = "beret", name = "Beret", price = 50, sink = 0.1, colours = {
		{name = "red", crown = C(188, 46, 52), band = C(188, 46, 52)},
		{name = "navy", crown = C(42, 52, 98), band = C(42, 52, 98)},
		{name = "black", crown = C(36, 34, 38), band = C(36, 34, 38)}}},
}
-- each piece's bounding-box centre in the hat's own frame (village/hats/hat_kit.json)
M.centre = {
	Hat_top = Vector3.new(0, 0.775, 0),       Band_top = Vector3.new(0, 0.22, 0),
	Hat_boater = Vector3.new(0, 0.31, 0),     Band_boater = Vector3.new(0, 0.23, 0),
	Hat_cloche = Vector3.new(0, 0.43, 0),     Band_cloche = Vector3.new(0, 0.21, 0),
	Hat_sun = Vector3.new(0, 0.24, 0),        Band_sun = Vector3.new(0.1015, 0.2401, 0),
	Hat_bowler = Vector3.new(0, 0.475, 0),    Band_bowler = Vector3.new(0, 0.21, 0),
	Hat_fedora = Vector3.new(0, 0.535, 0),    Band_fedora = Vector3.new(0, 0.23, 0),
	Hat_beret = Vector3.new(0.0142, 0.24, -0.0039), Band_beret = Vector3.new(0, 0.58, 0),
}
M.byStyle, M.byId, M.order = {}, {}, {}
for _, s in ipairs(M.styles) do
	M.byStyle[s.id] = s
	for i, c in ipairs(s.colours) do
		local id = s.id .. "_" .. i
		M.byId[id] = {id = id, style = s, colour = c, index = i}
		table.insert(M.order, id)
	end
end
function M.title(id)
	local h = M.byId[id]
	return h and (h.style.name .. " - " .. h.colour.name) or ""
end
-- Preserve the original hair; only its above-brim portion is masked while a hat is worn.
function M.isHairAccessory(acc)
 if not acc:IsA("Accessory") then return false end
 if acc.AccessoryType == Enum.AccessoryType.Hair then return true end
 local handle = acc:FindFirstChild("Handle")
 return handle ~= nil and handle:FindFirstChild("HairAttachment", true) ~= nil
end
-- Classic heads render narrower than their collision box.
local function headWidth(head)
 if head:IsA("Part") and head:FindFirstChildOfClass("SpecialMesh") then return head.Size.Y * 1.25 end
 return head.Size.X
end
-- Crown opening diameters from gen_hat_kit.py, rather than the decorative brim.
local opening = {top=1.4, boater=1.7, cloche=1.6, sun=1.7, bowler=1.56, fedora=1.64, beret=1.4}
-- Render meshes for Roundy (6340213), Blockhead (6340101), and Diamond (8330576).
local function headProfile(head)
 local mesh=head:FindFirstChildOfClass('SpecialMesh')
 local uri=head:IsA('MeshPart') and head.MeshId or (mesh and mesh.MeshId or '')
 local id=uri:match('id=(%d+)') or uri:match('rbxassetid://(%d+)')
 if id=='10382778666' then return 'round' end
 if id=='5560742512' then return 'block' end
 if id=='5591363207' then return 'diamond' end
end
function M.fit(head, styleId)
 local style = M.byStyle[styleId]
 local profile = headProfile(head)
 local hasHair = false
 if head.Parent then
  for _, acc in ipairs(head.Parent:GetChildren()) do
   if M.isHairAccessory(acc) then hasHair = true; break end
  end
 end
 local allowance = (hasHair and 0.12 or 0.04) * head.Size.Y
 local diameter = opening[styleId] or 1.6
 local sx = math.clamp((headWidth(head) + 2 * allowance) / diameter, 0.25, 3.2)
 local sz = math.clamp((head.Size.Z + 2 * allowance) / diameter, 0.25, 3.2)
 local sy = math.sqrt(sx * sz)
 if profile=='block' then
  -- An ellipse must enclose the square's diagonal, not just its side widths.
  -- Keep the original crown height while giving each corner a small fabric margin.
  sx=math.max(sx,(head.Size.X*math.sqrt(2)+.10*head.Size.Y)/diameter)
  sz=math.max(sz,(head.Size.Z*math.sqrt(2)+.10*head.Size.Y)/diameter)
 end
 local scale = Vector3.new(sx, sy, sz)
 local att = head:FindFirstChild('HatAttachment')
 local top = att and att.CFrame.Position or Vector3.new(0, head.Size.Y / 2, 0)
 if profile=='round' or profile=='diamond' then
  -- These attachments are below the visible crown; use the real head top.
  top=Vector3.new(top.X,math.max(top.Y,head.Size.Y*.5),top.Z)
 end
 local lift = hasHair and 0.1 * head.Size.Y or 0
 local brimY=top.Y-((style and style.sink) or .35)*head.Size.Y+lift
 if profile then
  -- Keep the eye line clear even without hair's extra lift. The cloche's
  -- downward brim needs a little more height than a flat brim.
  brimY=math.max(brimY,(styleId=='cloche' and .40 or .34)*head.Size.Y)
 end
 if profile=='block' and styleId=='beret' then brimY=brimY+.10*head.Size.Y end
 local cf=CFrame.new(top.X,brimY,top.Z)
 if style and style.tilt then cf=cf*CFrame.Angles(math.rad(style.tilt),0,0) end
 if styleId=='beret' then cf=cf*CFrame.Angles(0,0,math.rad(profile=='block' and -8 or -14)) end
 return cf,scale
end

-- Keep the original hairstyle below the brim; build a temporary clipped copy above it.
-- GeometryService preserves mesh UVs, so bangs, colour and texture remain unchanged.
local hairCache=setmetatable({},{__mode='k'})
local reportedHair=setmetatable({},{__mode='k'})
function M.clearHairCache(head)
 local cache=hairCache[head]
 if cache then for _,entry in pairs(cache)do for _,p in ipairs(entry.parts)do p:Destroy()end end end
 hairCache[head]=nil
end
local function hairSources(head)
 local out={}
 for _,acc in ipairs(head.Parent and head.Parent:GetChildren()or {})do
  if M.isHairAccessory(acc)then
   for _,p in ipairs(acc:GetDescendants())do if p:IsA('BasePart')then out[#out+1]=p end end
  end
 end
 return out
end
local function stripJoints(p)
 for _,o in ipairs(p:GetDescendants())do
  if o:IsA('JointInstance')or o:IsA('WeldConstraint')or o:IsA('Attachment')or o:IsA('BaseScript')then o:Destroy()end
 end
end
function M.clippedHair(head,styleId,fitCF)
 local sources=hairSources(head)
 local cache=hairCache[head]
 if not cache then cache={};hairCache[head]=cache end
 local entry=cache[styleId]
 if entry then
  local same=#entry.sources==#sources and entry.headSize==head.Size and entry.fitCF==fitCF
  for i,p in ipairs(sources)do if entry.sources[i]~=p or entry.sizes[i]~=p.Size then same=false;break end end
  if not same then for _,p in ipairs(entry.parts)do p:Destroy()end;cache[styleId]=nil;entry=nil end
 end
 if not entry then
  local made={}
  local sourceFrame=head.CFrame
  local frames,sizes={},{}
  for i,p in ipairs(sources)do frames[i]=sourceFrame:ToObjectSpace(p.CFrame);sizes[i]=p.Size end
  local ok,err=pcall(function()
   for index,src in ipairs(sources)do
    local originalTransparency=src:GetAttribute('HatHairWas')or src.Transparency
    if originalTransparency<1 then
     local mesh=src:FindFirstChildOfClass('SpecialMesh')
     local input,cutter
     local fitted,fitError=pcall(function()
     if src:IsA('MeshPart')or not mesh then input=src:Clone()
     elseif mesh.MeshType==Enum.MeshType.FileMesh and mesh.MeshId~='' then
      input=game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri(mesh.MeshId))
      input.Size=input.Size*mesh.Scale
      input.CFrame=sourceFrame*frames[index]*CFrame.new(mesh.Offset)
      input.TextureID=mesh.TextureId;input.Color=src.Color;input.Material=src.Material
     else error('Unsupported hair geometry')end
     stripJoints(input)
     input.Anchored=true;input.CFrame=frames[index]*(mesh and CFrame.new(mesh.Offset)or CFrame.new())
     input.Transparency=originalTransparency;input.LocalTransparencyModifier=0
     local low,high=math.huge,-math.huge
     for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
      local v=fitCF:PointToObjectSpace(input.CFrame:PointToWorldSpace(input.Size*Vector3.new(x,y,z)*.5))
      low=math.min(low,v.Y);high=math.max(high,v.Y)
     end end end
     local line=.015*head.Size.Y
     if styleId=='cloche' then
      -- Its brim drops 0.22 model studs below the crown's base. Cutting at
      -- the crown base leaves a visible hair ring through the back of the brim.
      local _,hatScale=M.fit(head,styleId)
      line=-.24*hatScale.Y
     end
     if high<=line then made[#made+1]=input
     elseif low>=line then input:Destroy()
     else
      local span=math.max(20,input.Size.Magnitude*4+input.Position.Magnitude*2)
      cutter=Instance.new('Part');cutter.Size=Vector3.new(span,span,span)
      cutter.CFrame=fitCF*CFrame.new(0,span/2+line,0)
      local success,result=pcall(function()
       return game:GetService('GeometryService'):SubtractAsync(input,{cutter},{SplitApart=false,CollisionFidelity=Enum.CollisionFidelity.Box})
      end)
      cutter:Destroy();input:Destroy()
      if not success then error(result)end
      for _,p in ipairs(result)do stripJoints(p);p.Transparency=originalTransparency;made[#made+1]=p end
     end
     end)
     if not fitted then
      if cutter then cutter:Destroy()end
      if input then input:Destroy()end
      -- Some legacy/non-manifold meshes cannot be cut by Roblox. Preserve their
      -- original hairstyle instead of hiding it, distorting it or blocking owned hats.
      local kept=src:Clone();stripJoints(kept);kept.Anchored=true;kept.CFrame=frames[index]
      kept.Transparency=originalTransparency;kept.LocalTransparencyModifier=0
      kept:SetAttribute('HatHairPreserved',true);made[#made+1]=kept
      if not reportedHair[src]then reportedHair[src]=true;warn('Hat fitting: preserving uncut hair '..src.Parent.Name..': '..tostring(fitError))end
     end
    end
   end
  end)
  if not ok then for _,p in ipairs(made)do p:Destroy()end;return nil,tostring(err)end
  if not head.Parent or hairCache[head]~=cache then for _,p in ipairs(made)do p:Destroy()end;return nil,'Avatar changed during fitting' end
  local previous=cache[styleId]
  if previous then for _,p in ipairs(previous.parts)do p:Destroy()end end
  entry={parts=made,sources=sources,sizes=sizes,headSize=head.Size,fitCF=fitCF};cache[styleId]=entry
 end
 local out={}
 for _,template in ipairs(entry.parts)do
  local p=template:Clone();local preserved=p:GetAttribute('HatHairPreserved')==true
  p.Name=preserved and 'PreservedHair'or 'ClippedHair';p:SetAttribute('HatClippedHair',not preserved)
  p.CFrame=head.CFrame*p.CFrame;p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.LocalTransparencyModifier=0
  out[#out+1]=p
 end
 return out,sources
end

-- the hat's two pieces, coloured, scaled s and placed with the hat's own frame at cf (world): {crown, band}
function M.pieces(kit, id, cf, s)
	local h = M.byId[id]
	if not h then return nil end
	local out = {}
	for _, prefix in ipairs({"Hat_", "Band_"}) do
		local src = kit:FindFirstChild(prefix .. h.style.id)
		if src then
			local p = src:Clone()
			p.Size = src.Size * s
			p.CFrame = cf * CFrame.new(M.centre[src.Name] * s)
			p.Color = (prefix == "Hat_") and h.colour.crown or h.colour.band
			p.Material = Enum.Material.Fabric
			p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
			p.CastShadow = true
			table.insert(out, p)
		end
	end
	return out
end
return M
]==]
	local oldCat = kit:FindFirstChild("Catalogue"); if oldCat then oldCat:Destroy() end
	local cm = Instance.new("ModuleScript"); cm.Name = "Catalogue"; cm.Source = CAT; cm.Parent = kit
	local Cat = loadstring(CAT)()

	local old = workspace:FindFirstChild("HatShop"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "HatShop"
	for _, s in ipairs(Cat.styles) do F:SetAttribute("Price_" .. s.id, (opts.prices and opts.prices[s.id]) or s.price) end

	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function soft(p) p.CanCollide = false; return p end

	-- ---------------------------------------------------------------- the street door ----
	-- the CHAPELIER sign is on the townhouse_e at x 312 looking +z; its door (DoorShop) is at x 303, the window x 305..323
	local SX, DX, DZ = opts.signX or 312, opts.doorX or 303, opts.doorZ or -139.15
	local shop
	local props = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props")
	if props then
		for _, m in ipairs(props:GetChildren()) do
			local t = m:IsA("Model") and m.Name == "townhouse_e" and m:FindFirstChild("SignText")
			if t and math.abs(t.Position.X - SX) < 2 then shop = m end
		end
	end
	local function shopColour(name, fallback)
		local p = shop and shop:FindFirstChild(name, true)
		return (p and p:IsA("BasePart")) and p.Color or fallback
	end
	local FACADE = shopColour("Shopfront", C(106, 140, 108))
	local AWNING, STRIPE = shopColour("Awning", C(226, 176, 80)), shopColour("AwningStripe", C(250, 247, 240))
	local DOORC, GLASSC = shopColour("DoorShop", C(112, 74, 46)), shopColour("GlassDoor", C(232, 240, 244))
	local groundY = 0.65
	do
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local ground = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground")
		if ground then rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {ground, workspace.Terrain} end
		local hit = workspace:Raycast(Vector3.new(DX, 20, DZ + 2), Vector3.new(0, -40, 0), rp)
		if hit then groundY = hit.Position.Y end
	end
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), CFrame.new(DX, groundY + 2.9, DZ), C(255, 246, 220), nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local mat = part("Doormat", Vector3.new(3.0, 0.12, 1.6), CFrame.new(DX, groundY + 0.06, DZ + 1.2), C(46, 70, 52), Enum.Material.Fabric)
	mat.CanCollide = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Chapelier"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad

	-- ---------------------------------------------------------------- the room ----
	local W, D, H = opts.width or 24, opts.depth or 22, 11
	local O = Vector3.new(SX, opts.roomY or 340, DZ - 0.45 - D / 2)         -- floor centre; the street wall's inner face at the facade
	local room = Instance.new("Model"); room.Name = "Room"; room.Parent = F
	local function at(x, y, z) return CFrame.new(O.X + x, O.Y + y, O.Z + z) end
	local dxr = DX - SX                                                       -- the door's x in room terms (-9)
	local PLASTER, WOOD, DARK, PARQUET = C(238, 227, 204), C(122, 86, 54), C(70, 48, 32), C(156, 112, 72)
	local BRASS, IRON, CREAM, VELVET = C(218, 178, 88), C(46, 46, 51), C(255, 246, 220), C(150, 40, 58)
	part("Floor", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, -0.3, 0), PARQUET, Enum.Material.WoodPlanks, room)
	part("Ceiling", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, H + 0.3, 0), C(232, 222, 202), Enum.Material.SmoothPlastic, room)
	part("WallN", Vector3.new(W, H, 0.6), at(0, H / 2, -D / 2 - 0.3), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallE", Vector3.new(0.6, H, D + 1.2), at(W / 2 + 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallW", Vector3.new(0.6, H, D + 1.2), at(-W / 2 - 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	-- a sage wainscot to the height of a chair back, capped with a dark rail, round the three plaster walls
	local WAIN = 3.1
	for _, w in ipairs({{0, -D / 2 + 0.08, W, 0.16}, {W / 2 - 0.08, 0, 0.16, D}, {-W / 2 + 0.08, 0, 0.16, D}}) do
		soft(part("Wainscot", Vector3.new(w[3], WAIN, w[4]), at(w[1], WAIN / 2, w[2]), FACADE, Enum.Material.Wood, room))
		soft(part("Rail", Vector3.new(math.max(w[3], 0.3), 0.22, math.max(w[4], 0.3)), at(w[1], WAIN + 0.1, w[2]), DARK, Enum.Material.Wood, room))
		soft(part("Skirting", Vector3.new(math.max(w[3], 0.26), 0.36, math.max(w[4], 0.26)), at(w[1], 0.18, w[2]), DARK, Enum.Material.Wood, room))
	end

	-- the street wall, in the shopfront's green: the display window (16 wide, y 1.4..8.4), wall, then the door at x -9
	local zS = D / 2 + 0.3
	local wx0, wx1, wy0, wy1 = -4.6, 11.4, 1.4, 8.4
	local ddx0, ddx1 = dxr - 1.7, dxr + 1.7
	local function wall(x0, x1, y0, y1) part("WallS", Vector3.new(x1 - x0, y1 - y0, 0.6), at((x0 + x1) / 2, (y0 + y1) / 2, zS), FACADE, Enum.Material.SmoothPlastic, room) end
	wall(-W / 2, W / 2, wy1, H)                              -- the band over the window and the door
	wall(-W / 2, ddx0, 0, wy1)                               -- west pier
	wall(ddx0, ddx1, 0, wy1)                                 -- behind the door (it is mounted on the wall)
	wall(ddx1, wx0, 0, wy1)                                  -- between the door and the window
	wall(wx0, wx1, 0, wy0)                                   -- under the window
	wall(wx1, W / 2, 0, wy1)                                 -- east pier
	local pane = part("Window", Vector3.new(wx1 - wx0, wy1 - wy0, 0.25), at((wx0 + wx1) / 2, (wy0 + wy1) / 2, zS), GLASSC, Enum.Material.Glass, room)
	pane.Transparency = 0.2; pane.CastShadow = false          -- under 0.25, so the camera treats the glass as solid
	for _, fx in ipairs({wx0 - 0.1, wx1 + 0.1}) do part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(fx, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	part("Frame", Vector3.new(wx1 - wx0 + 0.8, 0.4, 0.8), at((wx0 + wx1) / 2, wy1 + 0.1, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Sill", Vector3.new(wx1 - wx0 + 0.8, 0.4, 1.0), at((wx0 + wx1) / 2, wy0 - 0.1, zS - 0.1), CREAM, Enum.Material.SmoothPlastic, room)
	for k = 1, 3 do part("Mullion", Vector3.new(0.25, wy1 - wy0, 0.5), at(wx0 + (wx1 - wx0) * k / 4, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	-- the mustard awning outside the window, seen through the glass
	do
		local tilt = math.rad(37)
		local n, wA, cx = 12, 18, (wx0 + wx1) / 2
		for i = 0, n - 1 do
			local sx = cx - wA / 2 + wA / n * (i + 0.5)
			soft(part("Awning", Vector3.new(wA / n + 0.02, 0.12, 4.0), at(sx, 7.85, zS + 2.05) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and AWNING or STRIPE, Enum.Material.Fabric, room))
		end
		soft(part("AwningRod", Vector3.new(wA, 0.15, 0.15), at(cx, 6.55, zS + 3.8), IRON, Enum.Material.Metal, room))
	end
	-- the door, the Chapelier's own brown with its glass, on the wall
	local doorZ = zS - 0.3
	part("DoorFrame", Vector3.new(3.8, 7.1, 0.2), at(dxr, 3.55, doorZ - 0.1), DARK, Enum.Material.Wood, room)
	local door = part("Door", Vector3.new(3.4, 6.8, 0.2), at(dxr, 3.4, doorZ - 0.2), DOORC, Enum.Material.Wood, room)
	local dglass = part("DoorGlass", Vector3.new(2.4, 3.6, 0.1), at(dxr, 4.4, doorZ - 0.32), GLASSC, Enum.Material.Glass, room); dglass.Transparency = 0.2
	for _, px in ipairs({-0.72, 0.72}) do soft(part("Panel", Vector3.new(1.2, 1.6, 0.06), at(dxr + px, 1.3, doorZ - 0.32), C(92, 62, 46), Enum.Material.Wood, room)) end
	soft(part("Knob", Vector3.new(0.3, 0.3, 0.3), at(dxr + 1.2, 3.4, doorZ - 0.42), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Rue de Noisette"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 7; exit.RequiresLineOfSight = false; exit.Parent = door
	-- a bell over the door on a curled bracket (shops like this have one)
	soft(part("BellBracket", Vector3.new(0.12, 0.12, 1.0), at(dxr + 1.3, 7.5, doorZ - 0.8), IRON, Enum.Material.Metal, room))
	soft(part("ShopBell", Vector3.new(0.45, 0.45, 0.45), at(dxr + 1.3, 7.25, doorZ - 1.25), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))

	-- the hats, anchored, for show: the same two pieces as a worn hat, at scale s, resting on y (its lowest point)
	local function showHat(id, x, y, z, s, yaw, parent)
		local h = Cat.byId[id]
		local low = math.huge
		for _, prefix in ipairs({"Hat_", "Band_"}) do
			local src = kit:FindFirstChild(prefix .. h.style.id)
			if src then low = math.min(low, (Cat.centre[src.Name].Y - src.Size.Y / 2) * s) end
		end
		local cf = at(x, y - low, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
		local m = Instance.new("Model"); m.Name = "Show_" .. id
		for _, p in ipairs(Cat.pieces(kit, id, cf, s)) do p.Anchored = true; p.Parent = m end
		m.Parent = parent or room
		return m
	end

	-- the window display inside: a ledge with three hats on stands, like the one outside
	do
		local ledgeZ = zS - 0.3 - 0.9
		local wc = (wx0 + wx1) / 2
		part("Ledge", Vector3.new(wx1 - wx0, 0.3, 1.7), at(wc, wy0 + 0.15, ledgeZ), WOOD, Enum.Material.Wood, room)
		for i, e in ipairs({{"sun_1", -5.2}, {"top_2", 0}, {"cloche_1", 5.2}}) do
			local sx = wc + e[2]
			soft(part("StandFoot", Vector3.new(0.2, 1.1, 1.1), at(sx, wy0 + 0.4, ledgeZ) * CFrame.Angles(0, 0, math.rad(90)), BRASS, Enum.Material.Metal, room, Enum.PartType.Cylinder))
			soft(part("StandPole", Vector3.new(0.14, 1.5, 0.14), at(sx, wy0 + 1.2, ledgeZ), BRASS, Enum.Material.Metal, room))
			soft(part("StandHead", Vector3.new(1.0, 1.1, 1.0), at(sx, wy0 + 2.3, ledgeZ), CREAM, Enum.Material.SmoothPlastic, room, Enum.PartType.Ball))
			showHat(e[1], sx, wy0 + 2.3 + 0.55 - 0.35, ledgeZ, 0.85, 180 + (i - 2) * 12)
		end
	end

	-- THE HAT WALL: seven bays along the back wall, one per style, its three colourways on round shelves, a brass
	-- price plaque under each, and CHAPELIER in gold across the top
	local HATWALL = Instance.new("Model"); HATWALL.Name = "HatWall"; HATWALL.Parent = room
	local BAY, bz = 3.15, -D / 2 + 0.55
	local plaques = {}
	for i, s in ipairs(Cat.styles) do
		local bx = (i - 4) * BAY
		soft(part("Upright", Vector3.new(0.22, 8.4, 0.5), at(bx - BAY / 2, 4.2, bz - 0.2), DARK, Enum.Material.Wood, HATWALL))
		if i == #Cat.styles then soft(part("Upright", Vector3.new(0.22, 8.4, 0.5), at(bx + BAY / 2, 4.2, bz - 0.2), DARK, Enum.Material.Wood, HATWALL)) end
		for k, y in ipairs({2.1, 4.5, 6.9}) do
			part("Shelf", Vector3.new(0.16, 2.3, 2.3), at(bx, y, bz + 0.4) * CFrame.Angles(0, 0, math.rad(90)), WOOD, Enum.Material.Wood, HATWALL, Enum.PartType.Cylinder)
			soft(part("Bracket", Vector3.new(0.16, 0.5, 1.2), at(bx, y - 0.32, bz - 0.05), DARK, Enum.Material.Wood, HATWALL))
			showHat(s.id .. "_" .. k, bx, y + 0.08, bz + 0.5, 0.72, 180 + rng:NextNumber(-10, 10), HATWALL)
		end
		local pl = soft(part("Plaque", Vector3.new(2.5, 0.62, 0.08), at(bx, 1.05, -D / 2 + 0.22), BRASS, Enum.Material.Metal, HATWALL))
		pl.CFrame = pl.CFrame * CFrame.Angles(0, math.pi, 0)     -- (on the wainscot; its front face looks into the shop)
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Front; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 90; g.LightInfluence = 0.3; g.Parent = pl
		local l = Instance.new("TextLabel"); l.Name = "Words"; l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -10, 1, -8); l.Position = UDim2.fromOffset(5, 4)
		l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = C(70, 46, 22); l.Text = s.name .. " - " .. tostring(F:GetAttribute("Price_" .. s.id)); l.Parent = g
		plaques[s.id] = l                                                        -- (the price as built; the panel reads it live)
	end
	do
		local sign = soft(part("WallSign", Vector3.new(12, 1.4, 0.12), at(0, 9.45, bz - 0.35), DARK, Enum.Material.Wood, HATWALL))
		sign.CFrame = sign.CFrame * CFrame.Angles(0, math.pi, 0)
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Front; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 60; g.LightInfluence = 0.3; g.Parent = sign
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -20, 1, -10); l.Position = UDim2.fromOffset(10, 5)
		l.Font = Enum.Font.Antique; l.TextScaled = true; l.TextColor3 = BRASS; l.Text = "CHAPELIER"; l.Parent = g
	end

	-- THE MIRROR on the west wall: an arched glass in a gilded frame, a little rug where you stand, a sign over it
	local MZ = opts.mirrorZ or -2.6
	local mx = -W / 2 + 0.2
	local MIR = Instance.new("Model"); MIR.Name = "Mirror"; MIR.Parent = room
	part("FrameSlab", Vector3.new(0.3, 5.8, 4.5), at(mx + 0.05, 1.0 + 2.9, MZ), BRASS, Enum.Material.Metal, MIR)
	part("FrameTop", Vector3.new(0.3, 4.5, 4.5), at(mx + 0.05, 6.8, MZ) * CFrame.Angles(0, 0, 0), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Cylinder)
	local glass = part("Glass", Vector3.new(0.12, 5.4, 3.8), at(mx + 0.22, 1.2 + 2.7, MZ), C(206, 220, 230), Enum.Material.Glass, MIR)
	glass.Reflectance = 0.35
	local gtop = part("GlassTop", Vector3.new(0.12, 3.8, 3.8), at(mx + 0.22, 6.6, MZ), C(206, 220, 230), Enum.Material.Glass, MIR, Enum.PartType.Cylinder)
	gtop.Reflectance = 0.35
	soft(part("Crest", Vector3.new(0.3, 0.9, 0.9), at(mx + 0.1, 9.05, MZ), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Ball))
	local spot = Vector3.new(O.X - 3.2, O.Y, O.Z + MZ)                      -- where you stand to look in it
	soft(part("MirrorRug", Vector3.new(0.1, 4.2, 4.2), CFrame.new(spot.X, O.Y + 0.08, spot.Z) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, MIR, Enum.PartType.Cylinder))
	local ask = Instance.new("ProximityPrompt"); ask.Name = "MirrorPrompt"; ask.ActionText = "Try on hats"; ask.ObjectText = "Mirror"
	ask.KeyboardKeyCode = Enum.KeyCode.E; ask.HoldDuration = 0; ask.MaxActivationDistance = 10; ask.RequiresLineOfSight = false; ask.Parent = glass
	do
		local card = soft(part("MirrorSign", Vector3.new(0.08, 0.8, 3.0), at(mx + 0.3, 10.1, MZ), CREAM, Enum.Material.SmoothPlastic, MIR))
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Right; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 80; g.LightInfluence = 0.3; g.Parent = card
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -10, 1, -6); l.Position = UDim2.fromOffset(5, 3)
		l.Font = Enum.Font.Antique; l.TextScaled = true; l.TextColor3 = C(70, 46, 22); l.Text = "Essayez !"; l.Parent = g
	end
	-- a hat tree beside the mirror with two hats hung on it
	do
		local tx, tz = -W / 2 + 1.3, MZ + 4.2
		part("TreeFoot", Vector3.new(0.3, 1.8, 1.8), at(tx, 0.15, tz) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.Wood, room, Enum.PartType.Cylinder)
		part("TreePole", Vector3.new(0.3, 6.2, 0.3), at(tx, 3.2, tz), DARK, Enum.Material.Wood, room)
		for k = 0, 3 do
			local a = math.rad(45 + k * 90)
			soft(part("Hook", Vector3.new(0.14, 0.14, 0.9), at(tx + math.cos(a) * 0.35, 5.7, tz + math.sin(a) * 0.35) * CFrame.Angles(0, -a, 0) * CFrame.Angles(math.rad(30), 0, 0), DARK, Enum.Material.Wood, room))
		end
		showHat("fedora_2", tx, 6.35, tz, 0.72, 20)
		showHat("boater_1", tx + 0.25, 5.25, tz + 0.55, 0.62, -30)
	end

	-- the counter on the east side: a till, striped hat boxes, a little lamp
	do
		local cx, cz = W / 2 - 2.4, 2.6
		part("Counter", Vector3.new(1.6, 3.4, 7.0), at(cx, 1.7, cz), WOOD, Enum.Material.Wood, room)
		part("CounterTop", Vector3.new(1.9, 0.2, 7.3), at(cx, 3.5, cz), DARK, Enum.Material.Wood, room)
		soft(part("Front", Vector3.new(0.1, 2.6, 6.4), at(cx - 0.85, 1.6, cz), FACADE, Enum.Material.Wood, room))
		part("Till", Vector3.new(1.0, 0.8, 1.3), at(cx, 4.0, cz - 1.8), BRASS, Enum.Material.Metal, room)
		soft(part("TillTop", Vector3.new(0.7, 0.35, 1.1), at(cx + 0.15, 4.55, cz - 1.8) * CFrame.Angles(0, 0, math.rad(-20)), BRASS, Enum.Material.Metal, room))
		soft(part("LampPole", Vector3.new(0.1, 1.2, 0.1), at(cx, 4.2, cz + 2.4), BRASS, Enum.Material.Metal, room))
		local shade = soft(part("LampShade", Vector3.new(0.6, 0.8, 0.8), at(cx, 4.9, cz + 2.4) * CFrame.Angles(0, 0, math.rad(90)), C(240, 214, 160), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.5; pl.Range = 8; pl.Color = C(255, 214, 160); pl.Parent = shade
		-- hat boxes: striped rounds stacked on the counter's end and on the floor behind it
		local function hatBox(x, y, z, r, h, c1, c2)
			part("HatBox", Vector3.new(h, r * 2, r * 2), at(x, y + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), c1, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
			soft(part("BoxLid", Vector3.new(0.22, r * 2 + 0.1, r * 2 + 0.1), at(x, y + h - 0.08, z) * CFrame.Angles(0, 0, math.rad(90)), c2, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder))
		end
		hatBox(cx, 3.6, cz + 0.6, 0.62, 0.7, C(240, 226, 196), C(172, 42, 50))
		hatBox(cx, 4.3, cz + 0.6, 0.5, 0.55, C(128, 158, 118), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0, cz - 2.4, 0.7, 0.8, C(206, 122, 132), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0.8, cz - 2.4, 0.6, 0.7, C(240, 226, 196), C(42, 50, 94))
		hatBox(W / 2 - 0.9, 0, cz + 4.8, 0.65, 0.75, C(42, 50, 94), C(224, 180, 82))
	end

	-- a round rug in the middle, a velvet pouf to sit on, and three low pendant lamps (dim - the Librairie's were
	-- "way way way too bright" before they were cut to a third)
	-- (east of the mirror's own rug, and a little lower, so the two never overlap or flicker)
	soft(part("Rug", Vector3.new(0.1, 9, 9), at(3.9, 0.05, -1) * CFrame.Angles(0, 0, math.rad(90)), C(160, 60, 64), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	soft(part("RugBorder", Vector3.new(0.08, 9.6, 9.6), at(3.9, 0.03, -1) * CFrame.Angles(0, 0, math.rad(90)), C(218, 178, 88), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	local pouf = part("Pouf", Vector3.new(1.5, 2.4, 2.4), at(4.6, 0.75, -0.5) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, room, Enum.PartType.Cylinder)
	local seat = Instance.new("Seat"); seat.Name = "PoufSeat"; seat.Size = Vector3.new(2.0, 0.2, 2.0); seat.CFrame = at(4.6, 1.55, -0.5); seat.Transparency = 1; seat.Anchored = true; seat.Parent = room
	for i, lx in ipairs({-5, 1.5, 8}) do
		local ly = H - 2.3
		soft(part("Cord", Vector3.new(0.06, 2.0, 0.06), at(lx, H - 1.0, -2), IRON, Enum.Material.Metal, room))
		local sh = soft(part("Shade", Vector3.new(0.7, 1.4, 1.4), at(lx, ly, -2) * CFrame.Angles(0, 0, math.rad(90)), (i == 2) and C(224, 180, 82) or C(106, 140, 108), Enum.Material.Metal, room, Enum.PartType.Cylinder))
		local bulb = soft(part("Bulb", Vector3.new(0.4, 0.4, 0.4), at(lx, ly - 0.4, -2), C(255, 240, 200), Enum.Material.Neon, room, Enum.PartType.Ball))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.55; pl.Range = 16; pl.Color = C(255, 222, 176); pl.Shadows = false; pl.Parent = bulb
	end

	-- ---------------------------------------------------------------- plumbing ----
	local action = RS:FindFirstChild("HatShopAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "HatShopAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("HatShopEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "HatShopEvent"; ev.Parent = RS end
	F:SetAttribute("RoomX", O.X); F:SetAttribute("RoomY", O.Y); F:SetAttribute("RoomZ", O.Z)
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	F:SetAttribute("DoorSound", opts.doorSound or "rbxassetid://131845870598154"); F:SetAttribute("DoorVolume", opts.doorVolume or 0.6)   -- the Librairie's door (Shannon's pick)
	F:SetAttribute("InsideZoom", 16)
	F:SetAttribute("InX", O.X + dxr); F:SetAttribute("InY", O.Y + 3.4); F:SetAttribute("InZ", O.Z + D / 2 - 5.5)
	F:SetAttribute("OutX", DX); F:SetAttribute("OutY", groundY + 3.4); F:SetAttribute("OutZ", DZ + 2.6)
	F:SetAttribute("SpotX", spot.X); F:SetAttribute("SpotY", spot.Y); F:SetAttribute("SpotZ", spot.Z)
	F:SetAttribute("MirrorX", O.X + mx); F:SetAttribute("MirrorZ", O.Z + MZ)
	if not F:FindFirstChild("HatDebug") then local d = Instance.new("BindableFunction"); d.Name = "HatDebug"; d.Parent = F end   -- Studio tests

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[-- HatServer: the doors, buying, wearing, and dressing everyone in the hat they chose
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("HatShopAction")
local ev = RS:WaitForChild("HatShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("HatKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_hat_" .. id) or 0) > 0 end
local function worn(player)                                -- the Item_hatwear_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 13) == "Item_hatwear_" and (tonumber(v) or 0) > 0 and Cat.byId[name:sub(14)] then return name:sub(14) end
	end
	return nil
end

-- ---- wearing: the chosen hat as an Accessory at the head's HatAttachment, sized to the head; the avatar's own hats
-- are hidden while it is on; hair stays visible (and any old hair hiding is repaired)
local function isCoveredHeadwear(acc)
	if not acc:IsA("Accessory") or acc.Name == "WornHat" then return false end
	if Cat.isHairAccessory(acc) then return false end
	if acc.AccessoryType == Enum.AccessoryType.Hat then return true end
	local handle = acc:FindFirstChild("Handle")
	return handle ~= nil and handle:FindFirstChild("HatAttachment", true) ~= nil
end
local function showOwnHats(char, show)
	for _, acc in ipairs(char:GetChildren()) do
		if isCoveredHeadwear(acc) then
			for _, h in ipairs(acc:GetDescendants()) do
				if h:IsA("BasePart") then
				if show then
					local was = h:GetAttribute("HatShopWas")
					if was ~= nil then h.Transparency = was; h:SetAttribute("HatShopWas", nil) end
				elseif h:GetAttribute("HatShopWas") == nil then
					h:SetAttribute("HatShopWas", h.Transparency); h.Transparency = 1
				end
				end
			end
		end
	end
end
local fitRevision={}
local function showHair(char,show)
 for _,acc in ipairs(char:GetChildren())do if Cat.isHairAccessory(acc)then
  for _,p in ipairs(acc:GetDescendants())do if p:IsA('BasePart')then
   if show then local was=p:GetAttribute('HatHairWas');if was~=nil then p.Transparency=was;p:SetAttribute('HatHairWas',nil)end
   elseif p:GetAttribute('HatHairWas')==nil then p:SetAttribute('HatHairWas',p.Transparency);p.Transparency=1 end
  end end
 end end
end
local function undress(char)
	local old = char and char:FindFirstChild("WornHat")
	if old then old:Destroy() end
	if char then showOwnHats(char, true);showHair(char,true) end
end
local function dress(player)
 fitRevision[player]=(fitRevision[player]or 0)+1
 local revision=fitRevision[player]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not (hum and head) then return end
	local id = worn(player)
		-- Refit after appearance loads as well as when the selected hat changes.
	if not id or not owns(player, id) then undress(char);return end
	local h = Cat.byId[id]
	local fitCF, s = Cat.fit(head, h.style.id)
 local hair,why=Cat.clippedHair(head,h.style.id,fitCF)
 if not hair then warn('HatServer: hair fit failed',why);return end
 if player.Character~=char or not head.Parent or fitRevision[player]~=revision or worn(player)~=id then for _,p in ipairs(hair)do p:Destroy()end;return end
 undress(char)
 local pieces = Cat.pieces(kit, id, head.CFrame * fitCF, s)
 for _,p in ipairs(hair)do pieces[#pieces+1]=p end
	if not pieces or not pieces[1] then return end
	local acc = Instance.new("Accessory"); acc.Name = "WornHat"; acc.AccessoryType = Enum.AccessoryType.Hat
	acc:SetAttribute("HatId", id)
	local handle = pieces[1]; handle.Name = "Handle"; handle.Parent = acc
	for i = 2, #pieces do
		local p = pieces[i]; p.Parent = acc
		local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p
	end
	-- the handle's HatAttachment is where the head's will be, so the Humanoid puts the hat exactly here
	local headAtt = head:FindFirstChild("HatAttachment")
	local a = Instance.new("Attachment"); a.Name = "HatAttachment"
	a.CFrame = handle.CFrame:ToObjectSpace(headAtt and headAtt.WorldCFrame or head.CFrame * CFrame.new(0, head.Size.Y / 2, 0))
	a.Parent = handle
	showOwnHats(char, false);showHair(char,false)
	if headAtt then
		hum:AddAccessory(acc)
	else                                                    -- a head with no HatAttachment: weld it where it is
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = handle; w.Parent = handle
		acc.Parent = char
	end
end
local pending = {}
local function redress(player)                             -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.2, function() pending[player] = nil; dress(player) end)
end

-- ---- the doors: fade, move, unfade (the client draws the fade; the server moves you while it is dark); inside, the
-- camera is leashed so it cannot be scrolled out through the walls
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom, moving = {}, {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InHatShop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "MirrorPrompt" then ev:FireClient(player, "mirror") end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy = {}
local function wear(player, id)
	local cur = worn(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "hatwear_" .. cur, -1) end
	if id then awardItems:Fire(player, "hatwear_" .. id, 1) end
end
action.OnServerInvoke = function(player, what, id)
	if what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if not owns(player, id) then return false, "that one isn't yours yet" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
   local head=player.Character and player.Character:FindFirstChild('Head')
   if not head then return false,'Try again when your avatar is ready' end
   local fitCF=Cat.fit(head,Cat.byId[id].style.id)
   local fitted,fitError=Cat.clippedHair(head,Cat.byId[id].style.id,fitCF)
   if not fitted then warn('HatServer: purchase fit failed',fitError);return false,'Could not fit this hat. Please try again.' end
   for _,p in ipairs(fitted)do p:Destroy()end
   have=player:GetAttribute('Acorns')or 0
   if have<price then return false,'not enough acorns' end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "hat_" .. id, 1)
			wear(player, id)                                   -- a new hat goes straight on
			local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"hat",{hat=Cat.title(id),action="buy"}) end
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("HatServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("HatShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "?"
end

local function watch(player)
 player.CharacterRemoving:Connect(function(char) fitRevision[player]=(fitRevision[player]or 0)+1;local head=char:FindFirstChild('Head');if head then Cat.clearHairCache(head)end end)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 13) == "Item_hatwear_" or name:sub(1, 9) == "Item_hat_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil;fitRevision[p]=nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("HatDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "give" then awardItems:Fire(player, "hat_" .. id, 1) return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("HatServer: ready")
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
-- HatClient: the door fades, and the mirror - the camera turns round to be the mirror, the Chapelier's panel beside
-- you, every hat a little 3D picture; tap one to try it on (on your screen only), then buy it or wear it
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("HatShopEvent")
local action = RS:WaitForChild("HatShopAction")
local kit = RS:WaitForChild("HatKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local RGB = Color3.fromRGB
-- the Acorn Store's own colours, so this reads as another page of the same book
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_EDGE = RGB(228, 212, 179), RGB(162, 131, 90)
local INK, INK_DIM, GOLD, BTN_INK = RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, col, th, tr) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th; s.Transparency = tr or 0; s.Parent = o; return s end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- ---- the fade for the doors, and the door's sound
local fadeGui = Instance.new("ScreenGui"); fadeGui.Name = "HatShopFade"; fadeGui.ResetOnSpawn = false; fadeGui.IgnoreGuiInset = true; fadeGui.DisplayOrder = 20; fadeGui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Parent = fadeGui
local doorSfx = Instance.new("Sound"); doorSfx.SoundId = F:GetAttribute("DoorSound") or ""; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.6; doorSfx.Parent = fadeGui

-- ---- the panel
local gui = Instance.new("ScreenGui"); gui.Name = "HatShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 18; gui.Enabled = false; gui.Parent = pg
local W, H = 336, 400
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -16, 0.5, 0)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Parent = gui
corner(panel, 22); stroke(panel, RIM, 4)
local scale = Instance.new("UIScale"); scale.Parent = panel
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 24) / H, (vp.X * 0.5) / W), 0.45, 1)
end
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(20, 14); title.Size = UDim2.fromOffset(150, 30); title.BackgroundTransparency = 1
title.Text = "Chapelier"; title.TextXAlignment = Enum.TextXAlignment.Left; title.FontFace = FONT; title.TextSize = 26; title.TextColor3 = RGB(58, 36, 16); title.Parent = panel
local purse = Instance.new("TextLabel"); purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -56, 0, 16); purse.Size = UDim2.fromOffset(108, 28)
purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0; purse.FontFace = FONT; purse.TextSize = 17; purse.TextColor3 = INK; purse.Text = ""; purse.Parent = panel
corner(purse, 10); stroke(purse, SLOT_EDGE, 2, 0.3)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 14); close.Size = UDim2.fromOffset(32, 32)
close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0; close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"; close.AutoButtonColor = false; close.Parent = panel
corner(close, 10); stroke(close, SLOT_EDGE, 2, 0.3)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(14, 54); list.Size = UDim2.new(1, -28, 1, -54 - 108)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
-- the foot of the panel: the hat you are trying, what it costs, and the buttons
local foot = Instance.new("Frame"); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 14, 1, -12); foot.Size = UDim2.new(1, -28, 0, 92)
foot.BackgroundColor3 = FACE_DEEP; foot.BorderSizePixel = 0; foot.Parent = panel
corner(foot, 14); stroke(foot, SLOT_EDGE, 2, 0.45)
local picked = Instance.new("TextLabel"); picked.Position = UDim2.fromOffset(12, 6); picked.Size = UDim2.new(1, -24, 0, 22); picked.BackgroundTransparency = 1
picked.FontFace = FONT; picked.TextSize = 17; picked.TextColor3 = RGB(58, 36, 16); picked.TextXAlignment = Enum.TextXAlignment.Left; picked.TextTruncate = Enum.TextTruncate.AtEnd
picked.Text = "Tap a hat to try it on"; picked.Parent = foot
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(1, 0); note.Position = UDim2.new(1, -12, 0, 8); note.Size = UDim2.fromOffset(120, 18); note.BackgroundTransparency = 1
note.FontFace = FONT; note.TextSize = 13; note.TextXAlignment = Enum.TextXAlignment.Right; note.TextTransparency = 1; note.Text = ""; note.Parent = foot
local function button(text, pos, size, colour)
	local b = Instance.new("TextButton"); b.Position = pos; b.Size = size; b.BackgroundColor3 = colour; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.FontFace = FONT; b.TextSize = 17; b.TextColor3 = BTN_INK; b.Text = text; b.Parent = foot
	corner(b, 10); stroke(b, RGB(150, 98, 36), 2, 0.2)
	return b
end
local main = button("", UDim2.fromOffset(12, 38), UDim2.new(1, -124, 0, 42), GOLD)
local bare = button("No hat", UDim2.new(1, -104, 0, 38), UDim2.fromOffset(92, 42), RGB(214, 202, 176))
local function say(text, good)
	note.Text = text; note.TextColor3 = good and RGB(64, 112, 48) or RGB(150, 52, 30); note.TextTransparency = 0
	TweenService:Create(note, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), {TextTransparency = 1}):Play()
end

-- a little 3D picture of a hat
local function picture(id, parent)
	local vf = Instance.new("ViewportFrame"); vf.Size = UDim2.fromScale(1, 1); vf.BackgroundTransparency = 1; vf.Ambient = RGB(200, 190, 180)
	vf.LightColor = RGB(255, 246, 230); vf.LightDirection = Vector3.new(-0.4, -1, -0.6); vf.Parent = parent
	local m = Instance.new("Model")
	for _, p in ipairs(Cat.pieces(kit, id, CFrame.new(), 1)) do p.Anchored = true; p.Parent = m end
	m.Parent = vf
	local cf, size = m:GetBoundingBox()
	local cam = Instance.new("Camera"); cam.FieldOfView = 30
	local dist = math.max(size.X, size.Y * 1.4) / (2 * math.tan(math.rad(15))) * 1.12
	local dir = Vector3.new(0, math.sin(math.rad(24)), math.cos(math.rad(24)))
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	cam.Parent = vf; vf.CurrentCamera = cam
	return vf
end

local tiles, sections = {}, {}
local selected
local function owned(id) return (player:GetAttribute("Item_hat_" .. id) or 0) > 0 end
local function wornId()
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 13) == "Item_hatwear_" and (tonumber(v) or 0) > 0 then return name:sub(14) end
	end
end
local function priceOf(styleId) return F:GetAttribute("Price_" .. styleId) end
for i, s in ipairs(Cat.styles) do
	local sec = Instance.new("Frame"); sec.Name = s.id; sec.Size = UDim2.new(1, -6, 0, 104); sec.BackgroundColor3 = FACE_DEEP; sec.BorderSizePixel = 0
	sec.LayoutOrder = i; sec.Parent = list
	corner(sec, 14); stroke(sec, SLOT_EDGE, 2, 0.45)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(12, 6); nm.Size = UDim2.fromOffset(150, 20); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 17; nm.TextColor3 = RGB(58, 36, 16); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Text = s.name; nm.Parent = sec
	local pr = Instance.new("TextLabel"); pr.AnchorPoint = Vector2.new(1, 0); pr.Position = UDim2.new(1, -12, 0, 8); pr.Size = UDim2.fromOffset(110, 18)
	pr.BackgroundTransparency = 1; pr.FontFace = FONT; pr.TextSize = 14; pr.TextColor3 = INK_DIM; pr.TextXAlignment = Enum.TextXAlignment.Right; pr.Parent = sec
	sections[s.id] = {frame = sec, price = pr}
	for k = 1, #s.colours do
		local id = s.id .. "_" .. k
		local t = Instance.new("TextButton"); t.Name = id; t.Text = ""; t.AutoButtonColor = false; t.BackgroundColor3 = FACE; t.BorderSizePixel = 0
		t.Size = UDim2.fromOffset(88, 68); t.Position = UDim2.fromOffset(10 + (k - 1) * 98, 28); t.Parent = sec
		corner(t, 12)
		local st = stroke(t, SLOT_EDGE, 2, 0.35)
		local pic = picture(id, t); pic.Size = UDim2.new(1, -8, 1, -8); pic.Position = UDim2.fromOffset(4, 2)
		local tag = Instance.new("TextLabel"); tag.AnchorPoint = Vector2.new(0.5, 1); tag.Position = UDim2.new(0.5, 0, 1, -3); tag.Size = UDim2.fromOffset(70, 14)
		tag.BackgroundTransparency = 1; tag.FontFace = FONT; tag.TextSize = 11; tag.TextColor3 = RGB(64, 112, 48); tag.Text = ""; tag.Parent = t
		tiles[id] = {button = t, stroke = st, tag = tag}
	end
end

-- ---- trying on: the hat on YOUR head, on your screen only, while the one you wear (and your own hats) step aside
local preview
local previewRevision=0
local previewReady
local hiddenParts = {}
local function isCoveredHeadwear(acc)
	if not acc:IsA("Accessory") or acc.Name == "WornHat" then return acc:IsA("Accessory") and acc.Name == "WornHat" end
	if Cat.isHairAccessory(acc) then return false end
	if acc.AccessoryType == Enum.AccessoryType.Hat then return true end
	local handle = acc:FindFirstChild("Handle")
	return handle ~= nil and handle:FindFirstChild("HatAttachment", true) ~= nil
end
local function hideWorn(hide)
	local char = player.Character
	if hide and char then
		for _, acc in ipairs(char:GetChildren()) do
			if isCoveredHeadwear(acc) or Cat.isHairAccessory(acc) then
				for _, p in ipairs(acc:GetDescendants()) do
					if p:IsA("BasePart") then if hiddenParts[p] == nil then hiddenParts[p] = p.LocalTransparencyModifier end; p.LocalTransparencyModifier = 1 end
				end
			end
		end
	else
		for p, was in pairs(hiddenParts) do if p.Parent then p.LocalTransparencyModifier = was end end
		hiddenParts = {}
	end
end
local function clearPreview()
 previewRevision=previewRevision+1;previewReady=nil
	if preview then preview:Destroy(); preview = nil end
end
local function tryOn(id)
	clearPreview();hideWorn(false)
 local revision=previewRevision
 main.Text="Fitting..."
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head or not id then return end
	local h = Cat.byId[id]
 local fitCF, s = Cat.fit(head, h.style.id)
 local hair,why=Cat.clippedHair(head,h.style.id,fitCF)
 if revision~=previewRevision or player.Character~=char or selected~=id then if hair then for _,p in ipairs(hair)do p:Destroy()end end;return end
 if not hair then selected=nil;say('Could not fit this hat. Try again.',false);warn('HatClient: hair fit failed',why);return end
 local pieces=Cat.pieces(kit,id,head.CFrame*fitCF,s)
 for _,p in ipairs(hair)do pieces[#pieces+1]=p end
 local m = Instance.new("Model"); m.Name = "HatPreview"
	for _, p in ipairs(pieces) do
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = p; w.Parent = p
		p.Parent = m
	end
	m.Parent = char
	preview = m;previewReady=id
	hideWorn(true)
end

local function refresh()
	purse.Text = tostring(player:GetAttribute("Acorns") or 0) .. "  acorns"
	local have = player:GetAttribute("Acorns") or 0
	local on = wornId()
	for _, s in ipairs(Cat.styles) do
		local p = priceOf(s.id)
		sections[s.id].price.Text = p and (tostring(p) .. " acorns") or ""
	end
	for id, t in pairs(tiles) do
		local mine, wearing = owned(id), (id == on)
		t.tag.Text = wearing and "wearing" or (mine and "yours" or "")
		t.tag.TextColor3 = wearing and RGB(170, 110, 20) or RGB(64, 112, 48)
		local sel = (id == selected)
		t.stroke.Color = sel and GOLD or (wearing and RGB(200, 150, 48) or SLOT_EDGE)
		t.stroke.Thickness = sel and 3 or 2; t.stroke.Transparency = sel and 0 or 0.35
		t.button.BackgroundColor3 = sel and RGB(255, 248, 228) or FACE
	end
	if not selected then
		picked.Text = on and ("You're wearing the " .. Cat.title(on):lower()) or "Tap a hat to try it on"
		main.Text = "Pick a hat"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
	else
		local h = Cat.byId[selected]
		picked.Text = Cat.title(selected)
		if previewReady~=selected and selected~=on then
   main.Text="Fitting...";main.BackgroundColor3=RGB(214,202,176);main.TextColor3=INK_DIM
		elseif selected == on then
			main.Text = "You're wearing it"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
		elseif owned(selected) then
			main.Text = "Wear it"; main.BackgroundColor3 = GOLD; main.TextColor3 = BTN_INK
		else
			local p = priceOf(h.style.id) or 0
			main.Text = "Buy - " .. tostring(p) .. " acorns"
			local can = have >= p
			main.BackgroundColor3 = can and GOLD or RGB(214, 202, 176); main.TextColor3 = can and BTN_INK or INK_DIM
		end
	end
	bare.BackgroundColor3 = on and RGB(214, 202, 176) or RGB(228, 218, 196)
end
for id, t in pairs(tiles) do
	t.button.MouseButton1Click:Connect(function()
		selected = id
		tryOn(id)
		refresh()
	end)
end

local busy = false
main.MouseButton1Click:Connect(function()
	if busy or not selected or previewReady~=selected then return end
	local on = wornId()
	if selected == on then return end
	busy = true
	local what = owned(selected) and "wear" or "buy"
	if what == "buy" then
		local p = priceOf(Cat.byId[selected].style.id) or 0
		if (player:GetAttribute("Acorns") or 0) < p then busy = false; say("not enough acorns", false) return end
	end
	main.Text = "..."
	local want = selected
	local ok, res, why = pcall(function() return action:InvokeServer(what, want) end)
	busy = false
	if not ok then say("the shop did not answer", false)
	elseif res then
		say(what == "buy" and "it's yours!" or "on it goes", true)
		-- the real one arrives from the server in a moment: then the try-on steps down, so there are never two
		task.spawn(function()
			local char = player.Character
			for _ = 1, 40 do
				local w = char and char:FindFirstChild("WornHat")
				if w and w:GetAttribute("HatId") == want then break end
				task.wait(0.05)
			end
			if selected == want and preview then clearPreview(); hideWorn(false) end
		end)
	else say(tostring(why or "no"), false) end
	refresh()
end)
bare.MouseButton1Click:Connect(function()
	if busy then return end
	selected = nil
	clearPreview(); hideWorn(false)
	busy = true
	pcall(function() action:InvokeServer("wear", "") end)
	busy = false
	say("hat off", true)
	refresh()
end)

-- ---- at the mirror: stand on the rug facing it, the camera becomes the mirror, the rest of the screen steps aside
local open = false
local savedGuis, backpackWas, camWas = {}, nil, nil
-- you stay on the rug while the panel is open: the walking keys (and a pad's stick and jump) are swallowed here, at a
-- higher priority than the controls; on a phone the joystick is hidden with the rest of the screen. (This game's
-- PlayerScripts has no PlayerModule to switch the controls off with - waiting for one stalled this script.)
local CAS = game:GetService("ContextActionService")
local FREEZE = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left,
	Enum.KeyCode.Right, Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA}
local function stepAside(on)
	if on then
		savedGuis = {}
		for _, g in ipairs(pg:GetChildren()) do
			if (g:IsA("ScreenGui") or g:IsA("BillboardGui")) and g ~= gui and g ~= fadeGui and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		-- and your own name tag over your head (on a phone the mirror's framing put it beside Roblox's buttons)
		local char = player.Character
		for _, g in ipairs(char and char:GetDescendants() or {}) do
			if g:IsA("BillboardGui") and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		pcall(function() backpackWas = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		CAS:BindActionAtPriority("HatMirrorStay", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value + 100, table.unpack(FREEZE))
	else
		for g in pairs(savedGuis) do if g.Parent then g.Enabled = true end end
		savedGuis = {}
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, backpackWas ~= false) end)
		CAS:UnbindAction("HatMirrorStay")
	end
end
local function mirrorPrompt() return F:FindFirstChild("MirrorPrompt", true) end
local function setOpen(on)
	if on == open then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	local cam = workspace.CurrentCamera
	if on and not (hrp and hum and head and cam) then return end
	open = on
	local mp = mirrorPrompt()
	if on then
		if mp then mp.Enabled = false end
		-- on the rug, facing the glass
		local spot = v3("Spot")
		local toMirror = (Vector3.new(F:GetAttribute("MirrorX"), 0, F:GetAttribute("MirrorZ")) - Vector3.new(spot.X, 0, spot.Z)).Unit
		local legs = hum.HipHeight + hrp.Size.Y / 2
		local at = spot + Vector3.new(0, legs + 0.05, 0)
		hrp.CFrame = CFrame.lookAt(at, at + toMirror)
		hrp.AssemblyLinearVelocity = Vector3.zero
		stepAside(true)
		gui.Enabled = true
		fit()
		-- the camera stands where the glass is, looking back at your face; you on the left, the panel on the right
		task.defer(function()
			local hp = head.Position
			local camRight = (-toMirror):Cross(Vector3.new(0, 1, 0))
			camWas = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			local eye = hp + toMirror * 6.2 + camRight * 0.6 + Vector3.new(0, 0.1, 0)      -- (nearly level: from above, a brim hid the eyes)
			cam.CFrame = CFrame.lookAt(eye, hp + camRight * 1.75 - Vector3.new(0, 0.3, 0))
		end)
		selected = nil
		refresh()
	else
		gui.Enabled = false
		clearPreview(); hideWorn(false)
		selected = nil
		stepAside(false)
		cam.CameraType = (camWas and camWas ~= Enum.CameraType.Scriptable) and camWas or Enum.CameraType.Custom
		if mp then mp.Enabled = true end
	end
end
close.MouseButton1Click:Connect(function() setOpen(false) end)
player.CharacterRemoving:Connect(function(char)
 if open then setOpen(false)else clearPreview();hideWorn(false)end
 local head=char:FindFirstChild('Head');if head then Cat.clearHairCache(head)end
end)
player.CharacterAdded:Connect(function() if open then open = true; setOpen(false) end end)
player:GetAttributeChangedSignal("Acorns"):Connect(function() if open then refresh() end end)
player.AttributeChanged:Connect(function(name) if open and (name:sub(1, 9) == "Item_hat_" or name:sub(1, 13) == "Item_hatwear_") then refresh() end end)
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end)

ev.OnClientEvent:Connect(function(what, a)
	if what == "fade" then
		doorSfx.TimePosition = 0; doorSfx:Play()
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1}):Play()
	elseif what == "mirror" then
		setOpen(true)
	end
end)
]==]

	local s = Instance.new("Script"); s.Name = "HatServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "HatClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	-- the room hangs over the map: RoomHide keeps it off every screen but the ones inside
	local boxCF, boxSize = room:GetBoundingBox()
	room:SetAttribute("BoxCF", boxCF); room:SetAttribute("BoxSize", boxSize)
	CS:AddTag(room, "SkyRoom")
	F.Parent = workspace
	local pieces = 0
	for _, p in ipairs(F:GetDescendants()) do if p:IsA("BasePart") then pieces += 1 end end
	print(string.format("HatShop: the Chapelier's room at %.0f,%.0f,%.0f (%d pieces), door at %.1f,%.2f,%.1f, %d hats in %d styles",
		O.X, O.Y, O.Z, pieces, DX, groundY, DZ, #Cat.order, #Cat.styles))
	return F
end
