-- Oct 5 2026 read-only: dump script sources to the Studio log (chunks, newlines as \1) for local reading.
local list={workspace.Honours.TitleServer,workspace.Honours.TitleClient,workspace.Champion.ChampionServer,workspace.Champion.ChampionClient}
for _,s in ipairs(list) do
	local src=s.Source:gsub('\n','\1')
	local n=0
	for i=1,#src,1500 do n+=1 warn('QD@'..s.Name..'#'..string.format('%04d',n)..'|'..src:sub(i,i+1499)) end
	warn('QD@'..s.Name..'#END '..n)
end
-- sunbather / lifeguard surroundings: beach props + water edge
local PN=workspace.PortoNocciola
local cove=PN:FindFirstChild('07 Cove and tide pools')
if cove then for _,c in ipairs(cove:GetChildren()) do local p=c:IsA('Model') and c:GetPivot().Position or (c:IsA('BasePart') and c.Position) if p then warn('QD@COVE',c.Name,c.ClassName,p) end end end
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
local row={}
for x=250,300,2 do
	local line={}
	for z=-745,-700,3 do
		local r=workspace:Raycast(Vector3.new(x,0,z),Vector3.new(0,-80,0),rp)
		table.insert(line, r and (r.Material==Enum.Material.Water and 'W' or r.Material==Enum.Material.Sand and 's' or 'o') or '.')
	end
	warn('QD@GRID x='..x..' '..table.concat(line))
end
-- chair top surface
local ch=PN['Lifeguard Post']['Lifeguard Chair']
local ip=RaycastParams.new() ip.FilterType=Enum.RaycastFilterType.Include ip.FilterDescendantsInstances={ch.Chair_Wood}
for dx=-1.2,1.2,0.4 do local l={} for dz=-1.2,1.2,0.4 do
	local r=workspace:Raycast(Vector3.new(258.4+dx,-30,-714.27+dz),Vector3.new(0,-30,0),ip)
	table.insert(l,r and string.format('%.2f',r.Position.Y) or '  -  ')
end warn('QD@CHAIR dx='..dx..' '..table.concat(l,' ')) end
warn('QD@CHAIRCF',ch.Chair_Wood.CFrame,'pole',ch.Umbrella_Pole.CFrame)
