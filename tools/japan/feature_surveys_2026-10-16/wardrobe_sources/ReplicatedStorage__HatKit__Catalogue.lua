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
