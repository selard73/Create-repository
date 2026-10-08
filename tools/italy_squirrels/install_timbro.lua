-- Signor Timbro (customs_squirrel) install, Oct 3 2026. Needs customs_squirrel_color + _gray imported (Import 3D) first.
local CH = game:GetService('ChangeHistoryService')
local col = workspace:FindFirstChild('customs_squirrel_color'); assert(col, 'no color import')
local gry = workspace:FindFirstChild('customs_squirrel_gray'); assert(gry, 'no gray import')
local cm, gm = col:FindFirstChild('Squirrel'), gry:FindFirstChild('Squirrel'); assert(cm and gm and cm:IsA('MeshPart'), 'mesh')
local SS = workspace.SquirrelScripts
local reg = SS.SquirrelRegistry; local champ = workspace.Champion.ChampionServer
local daily; for _, x in ipairs(workspace:FindFirstChild('Daily', true):GetDescendants()) do if x.Name == 'DailyServer' then daily = x end end
assert(daily, 'daily')
-- 1. exact-anchor source patches (abort before changing anything if an anchor is missing)
local function sub1(src, pat, rep, what) local out, n = src:gsub(pat, rep); assert(n == 1, what .. ' anchor count ' .. n); return out end
local rs = reg.Source
assert(not rs:find('customs_squirrel', 1, true), 'registry already has Timbro')
rs = sub1(rs, '(%{id = "domaine",[^\n]*\n)', '%1\t\t{id = "porto",   name = "Porto Nocciola"},\n', 'registry map')
rs = sub1(rs, '(squirrels = %{\n)', '%1\t\t{id = "customs_squirrel",      map = "porto", name = "Signor Timbro",\n\t\t bio = "Stamps every passport that comes into Porto Nocciola, including the ones that arrive by waterfall. Always asks if you have anything to declare, then waits very politely while you drip."},\n', 'registry squirrel')
local cs = champ.Source
assert(not cs:find('frenchFound', 1, true), 'champion already patched')
cs = sub1(cs, '(local function totalSquirrels%(%))', [[-- Keeper is per map (Shannon, Oct 3 2026): this French Keeper counts only the three French maps.
local FRENCH = {forest = true, village = true, domaine = true}
local FRENCH_ID, NOT_FRENCH = {}, {}
do
	local ok, R = pcall(require, workspace.SquirrelScripts.SquirrelRegistry)
	if ok then for _, q in ipairs(R.squirrels) do if FRENCH[q.map] then FRENCH_ID[q.id] = true else NOT_FRENCH[q.id] = true end end end
end
local function frenchFound(player)
	local s = player:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(FRENCH_ID) == nil then return tonumber(player:GetAttribute("SquirrelsFound")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if FRENCH_ID[id] then n += 1 end end
	return n
end
%1]], 'champion total fn')
cs = sub1(cs, '(local id = m:GetAttribute%("SquirrelId"%))', '%1; if id and NOT_FRENCH[id] then id = nil end', 'champion id')
cs = sub1(cs, 'local last = tonumber%(player:GetAttribute%("SquirrelsFound"%)%) or 0', 'local last = frenchFound(player)', 'champion last')
cs = sub1(cs, 'local now = tonumber%(player:GetAttribute%("SquirrelsFound"%)%) or 0', 'task.wait(0.2); local now = frenchFound(player)', 'champion now')
local ds = daily.Source
ds = sub1(ds, 'local list = Registry%.squirrels\n', 'local list = {}; for _, q in ipairs(Registry.squirrels) do if q.map ~= "porto" then table.insert(list, q) end end -- French only until Italy is complete (Oct 3 2026)\n', 'daily list')
-- 2. the squirrel: textures, gray twin parked, placed on the landing grass facing the spawn
cm:SetAttribute('ColorTexture', cm.TextureID); cm:SetAttribute('GrayTexture', gm.TextureID)
local twins = workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent = twins; gry:PivotTo(gry:GetPivot() + Vector3.new(0, -400 - gry:GetPivot().Y, 0)) else gry:Destroy() end
local function bone(m, n) for _, d in ipairs(m:GetDescendants()) do if d:IsA('Bone') and d.Name == n then return d end end end
local head = bone(col, 'Head'); assert(head, 'head bone')
local spot, look = Vector3.new(247, 0, -588), Vector3.new(232, 0, -580)
local face = (head.WorldPosition - cm.Position) * Vector3.new(1, 0, 1)
local want = (look - spot) * Vector3.new(1, 0, 1)
local ang = math.atan2(want.X, want.Z) - math.atan2(face.X, face.Z)
col:PivotTo(col:GetPivot() * CFrame.Angles(0, ang, 0))
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {col, workspace:FindFirstChild('ComingSoonWall')}
local hit = workspace:Raycast(spot + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp); assert(hit, 'ground')
local bottom = cm.Position.Y - cm.Size.Y / 2
col:PivotTo(col:GetPivot() + Vector3.new(spot.X - cm.Position.X, hit.Position.Y - bottom, spot.Z - cm.Position.Z))
-- 3. write the sources
reg.Source = rs; champ.Source = cs; daily.Source = ds
CH:SetWaypoint('Signor Timbro + per-map Keeper')
local f2 = (head.WorldPosition - cm.Position) * Vector3.new(1, 0, 1)
print('TIMBRO_OK', cm.Position, 'ground', hit.Instance.Name, hit.Position.Y, 'face', f2.Unit, 'want', want.Unit)
