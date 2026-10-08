-- Oct 5 2026 PROMENADE +10, step 2c: sandy foot v3 written voxel by voxel (FillBlock leaves full Water cells alone).
-- Per wall row: the cell straddling the wall and the next cell out get Sand: y[-60,-56] occ 1, y[-56,-52] occ 0.42
-- (surface ~ centre + 4*occ = -52.3, a hand above the water at -52.9), y[-52,-48] Air. None beside the Rosina,
-- Pescatori pier/gangway/Stella Marina, Reti pier/La Limonaia. Backup: ServerStorage.PromenadeBackup.TerrainBefore.
local T=workspace.Terrain
local W=workspace.PortoNocciola['01 Curved waterfront']
local stones={}
for _,p in ipairs(W:GetChildren()) do
	if p:IsA('BasePart') and (p.Name=='Seawall ashlar' or p.Name=='Rounded coping stone') then
		local cf,s=p.CFrame,p.Size/2
		local mn,mx=Vector3.new(1e9,1e9,1e9),Vector3.new(-1e9,-1e9,-1e9)
		for _,k in ipairs({Vector3.new(1,1,1),Vector3.new(1,1,-1),Vector3.new(1,-1,1),Vector3.new(1,-1,-1),Vector3.new(-1,1,1),Vector3.new(-1,1,-1),Vector3.new(-1,-1,1),Vector3.new(-1,-1,-1)}) do
			local w=cf:PointToWorldSpace(s*k) mn=mn:Min(w) mx=mx:Max(w) end
		table.insert(stones,{mn,mx})
	end
end
local function wallX(z)
	local best
	for _,b in ipairs(stones) do if b[1].Z-0.6<=z and z<=b[2].Z+0.6 then best=math.min(best or 1e9,b[1].X) end end
	return best
end
local cells={} local n=0
for z=-600,-703,-1 do
	local ok=(z>=-622.5) or (z<=-651.5 and z>=-679.5)
	local xw=wallX(z)
	if ok and xw then
		local iz=math.floor(z/4)
		for i,x in ipairs({xw-0.5,xw-3.5,xw+0.6}) do   -- v3b: inner cell (at the wall) 0.62, outer cell 0.3 so the foot is one continuous ledge; v3c: + the cell under the wall face (no water seam)
			local occ=(i==2) and 0.3 or 0.62
			local key=math.floor(x/4)..','..iz
			if not cells[key] then cells[key]={math.floor(x/4),iz,occ} n+=1 else cells[key][3]=math.max(cells[key][3],occ) end
		end
	end
end
local S,A=Enum.Material.Sand,Enum.Material.Air
for _,c in pairs(cells) do
	local x0,z0=c[1]*4,c[2]*4
	local reg=Region3.new(Vector3.new(x0,-60,z0),Vector3.new(x0+4,-48,z0+4))
	T:WriteVoxels(reg,4,{{{S},{S},{A}}},{{{1},{c[3]},{0}}})
end
warn('PRM2C@DONE foot cells',n)
