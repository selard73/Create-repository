local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={workspace:FindFirstChild('ComingSoonWall'),workspace:FindFirstChild('SquirrelTwins')}
local names,codes={},0
local function code(n) if not names[n] then codes+=1 names[n]=string.char(64+codes) warn('QH@KEY '..names[n]..' '..n) end return names[n] end
for z=-690,-800,-3 do
	local row={}
	for x=230,350,3 do
		local r=workspace:Raycast(Vector3.new(x,20,z),Vector3.new(0,-120,0),rp)
		if r then
			local n=r.Instance==workspace.Terrain and ('Terrain '..r.Material.Name) or r.Instance.Name
			table.insert(row,code(n)..string.format('%03d',math.floor(-r.Position.Y*10+0.5)%1000))
		else table.insert(row,'----') end
	end
	warn(string.format('QH@z%d %s',z,table.concat(row,' ')))
end
warn('QH@END')
