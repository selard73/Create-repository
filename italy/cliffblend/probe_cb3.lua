-- cb1 read-only: terrain height maps either side of the falls cliff, the cliff mesh's own top/front, and parts in the zones
local T=workspace.Terrain
local rpT=RaycastParams.new() rpT.FilterType=Enum.RaycastFilterType.Include rpT.FilterDescendantsInstances={T}
local rock=workspace:FindFirstChild('SouthGorge') and workspace.SouthGorge:FindFirstChild('Rock')
local rpM=RaycastParams.new() rpM.FilterType=Enum.RaycastFilterType.Include rpM.FilterDescendantsInstances={rock}
local MAT={Grass='G',Sandstone='S',Limestone='L',Rock='R',Slate='T',Sand='s',Mud='M',Ground='D',Water='W',Pebble='P',LeafyGrass='g',Basalt='B',Cobblestone='C',Pavement='V'}
local function zone(tag,x0,x1) -- cb3 re-measure after ct1/ct2
	for z=-620,-532,4 do
		local hs,ms,mm={}, {}, {}
		for x=x0,x1,4 do
			local h=workspace:Raycast(Vector3.new(x,140,z),Vector3.new(0,-220,0),rpT)
			table.insert(hs,h and math.floor(h.Position.Y+0.5) or -99)
			table.insert(ms,h and (MAT[h.Material.Name] or '?') or '.')
			local m=rock and workspace:Raycast(Vector3.new(x,140,z),Vector3.new(0,-220,0),rpM)
			table.insert(mm,m and math.floor(m.Position.Y+0.5) or -99)
		end
		warn('QC@'..tag..'H '..z..' '..table.concat(hs,','))
		warn('QC@'..tag..'M '..z..' '..table.concat(ms,''))
		warn('QC@'..tag..'R '..z..' '..table.concat(mm,','))
	end
end
zone('W',-404,48)
warn('QC@END')
