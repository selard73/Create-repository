local h=workspace.PortoNocciola['02 Pastel waterfront']['Casa Salvia']
local cf,sz=h:GetBoundingBox()
warn('QZ@BBOX',cf,sz)
for _,d in ipairs(h:GetDescendants()) do
	if d:IsA('BasePart') and d.Position.Y<-40 and (d.Name:lower():find('door') or d.Name:lower():find('step') or d.Name:lower():find('threshold') or d.Size.Magnitude>10) then
		warn(string.format('QZ@P@%s@(%.2f,%.2f,%.2f)@(%.2f,%.2f,%.2f)@o%s@%s',d:GetFullName():gsub('Workspace.PortoNocciola.02 Pastel waterfront.Casa Salvia.',''),d.Position.X,d.Position.Y,d.Position.Z,d.Size.X,d.Size.Y,d.Size.Z,tostring(d.Orientation),d.Parent.Name))
	end
end
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={}
for x=cf.X-sz.X/2-6,cf.X+sz.X/2+2,2 do
	local line={}
	for z=cf.Z-sz.Z/2-6,cf.Z+sz.Z/2+6,2 do
		local r=workspace:Raycast(Vector3.new(x,-20,z),Vector3.new(0,-40,0),rp)
		table.insert(line,r and string.format('%.1f',r.Position.Y) or 'nil')
	end
	warn(string.format('QZ@G x%.0f z%.0f..: %s',x,cf.Z-sz.Z/2-6,table.concat(line,' ')))
end
warn('QZ@END')
