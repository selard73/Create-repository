-- Oct 5 2026 PROMENADE fixes for her 5 flags (+1 found on the way):
-- 1+5) solid quay ends: copies of the 6 original 'Quay foundation' blocks back at their ORIGINAL spots (PromenadeFill), so the
--      old-line paving no longer floats over an open gap at the north and south ends;
-- 2) AlleyCrates (inside '03 Fish market') back into the alley (+5 X);
-- 3) aquarium fish: RestCFrame attributes are absolute (StarterPlayerScripts.PortoMarketAquariumMotion pivots each fish to it)
--    -> every CFrame/Vector3 world-position attribute on anything that moved is shifted by that thing's own move;
-- 4) terrain: no water/air left under land in the north-bank and south-beach boxes (the sand/grass there was a thin shelf);
-- +) Workspace.CrabGame.SellSpot (Beppe's crab sale spot) follows Beppe (-5 X).
local P=workspace.PortoNocciola
local T=workspace.Terrain
if P:GetAttribute('PromFix5') then warn('PRM5@ABORT already ran') return end
local W=P['01 Curved waterfront'] local FM=P['03 Fish market']
-- 1+5) foundations
local nf=0
for _,p in ipairs(W:GetChildren()) do
	if p:IsA('BasePart') and p.Name=='Quay foundation' and p:GetAttribute('PromOldCF') then
		local c=p:Clone() c.CFrame=p:GetAttribute('PromOldCF')
		for k in pairs(c:GetAttributes()) do c:SetAttribute(k,nil) end
		c:SetAttribute('PromenadeFill',true) c.Parent=W nf+=1
	end
end
-- 2) alley crates back
local nc=0
local AC=FM:FindFirstChild('AlleyCrates')
if AC then for _,d in ipairs(AC:GetDescendants()) do if d:IsA('BasePart') then d:SetAttribute('PromOldCF',d.CFrame+Vector3.new(5,0,0)) d.CFrame=d.CFrame+Vector3.new(5,0,0) nc+=1 end end end
-- 3) world-position attributes follow their owner's move
local na=0
local function shiftAttrs(inst,delta)
	local list=inst:GetDescendants() table.insert(list,1,inst)
	for _,x in ipairs(list) do
		if not (AC and x:IsDescendantOf(AC)) then
			for k,v in pairs(x:GetAttributes()) do
				if k:sub(1,4)~='Prom' and (typeof(v)=='CFrame' or typeof(v)=='Vector3') then
					local pos=(typeof(v)=='CFrame') and v.Position or v
					if pos.Magnitude>150 and x:GetAttribute('PromOld_'..k)==nil then
						x:SetAttribute('PromOld_'..k,v) x:SetAttribute(k,v+delta) na+=1
						warn('PRM5@attr',x:GetFullName(),k,'shift',delta)
					end
				end
			end
		end
	end
end
local roots={P,workspace:FindFirstChild('fishmonger_squirrel_color'),workspace:FindFirstChild('deckhand_squirrel_color'),
	workspace:FindFirstChild('octopus_squirrel_color'),workspace:FindFirstChild('seacaptain_squirrel_color')}
for _,r in ipairs(roots) do
	if r then
		local list=r:GetDescendants() table.insert(list,1,r)
		for _,x in ipairs(list) do
			if x:IsA('Model') and x:GetAttribute('PromOldPivot') then shiftAttrs(x,x:GetPivot().Position-x:GetAttribute('PromOldPivot').Position) end
		end
	end
end
-- +) crab sell spot
local CG=workspace:FindFirstChild('CrabGame') local ss=CG and CG:FindFirstChild('SellSpot')
if ss and not ss:GetAttribute('PromOldCF') then ss:SetAttribute('PromOldCF',ss.CFrame) ss.CFrame=ss.CFrame+Vector3.new(-5,0,0) end
-- 4) terrain: water/air under land -> sand, in the two boxes this build touched
local function closeUnder(lo,hi)
	local reg=Region3.new(lo,hi)
	local mats,occ=T:ReadVoxels(reg,4)
	local sx,sy,sz=#mats,#mats[1],#mats[1][1]
	local changed=0
	for ix=1,sx do for iz=1,sz do
		local land=false
		for iy=sy,1,-1 do
			local m=mats[ix][iy][iz]
			if m~=Enum.Material.Air and m~=Enum.Material.Water and occ[ix][iy][iz]>0.25 then land=true
			elseif land and (m==Enum.Material.Water or m==Enum.Material.Air) then mats[ix][iy][iz]=Enum.Material.Sand occ[ix][iy][iz]=1 changed+=1 end
		end
	end end
	T:WriteVoxels(reg,4,mats,occ)
	return changed
end
local cN=closeUnder(Vector3.new(208,-64,-604),Vector3.new(240,-44,-584))
local cS=closeUnder(Vector3.new(216,-64,-716),Vector3.new(244,-44,-696))
-- report scripts that hard-code the moved squirrels' / stall's old coordinates (report only)
for _,s in ipairs(game:GetDescendants()) do
	if s:IsA('LuaSourceContainer') and not s:IsDescendantOf(game:GetService('ServerStorage')) then
		local ok,src=pcall(function() return s.Source end)
		if ok and src then for _,k in ipairs({'253.7','222.3','-646.2','216.0','-627.9','202.4','-668.4','-636.8','253.4'}) do
			if string.find(src,k,1,true) then warn('PRM5@script',s:GetFullName(),'has',k) break end end end
	end
end
P:SetAttribute('PromFix5',true)
warn('PRM5@DONE foundations',nf,'crates parts',nc,'attrs',na,'sellspot',ss~=nil,'terrain cells north',cN,'south',cS)
