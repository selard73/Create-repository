local yard=workspace.PortoNocciola['05 Boatyard and nets']
local b=yard['Oak barrel']
local cf,sz=b:GetBoundingBox()
warn(string.format('QR@BBOX@%s@(%.2f,%.2f,%.2f)',tostring(cf),sz.X,sz.Y,sz.Z))
for _,p in ipairs(b:GetDescendants()) do
	if p:IsA('BasePart') then
		warn(string.format('QR@PART@%s@%s@(%.2f,%.2f,%.2f)@(%.2f,%.2f,%.2f)@o%s@%s',p.Name,p.ClassName,p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,tostring(p.Orientation),p:IsA('Part') and tostring(p.Shape) or ''))
	end
end
local boat=yard['Nuova Alba']
local bc,bs=boat:GetBoundingBox()
warn(string.format('QR@BOAT@%s@(%.2f,%.2f,%.2f)',tostring(bc),bs.X,bs.Y,bs.Z))
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={b}
for dx=-1.2,1.21,0.3 do for dz=-1.2,1.21,0.3 do
	local r=workspace:Raycast(Vector3.new(cf.X+dx,-30,cf.Z+dz),Vector3.new(0,-30,0),rp)
	if r then warn(string.format('QR@RAY@%.1f,%.1f@%.3f@%s',dx,dz,r.Position.Y,r.Instance.Name)) end
end end
local rp2=RaycastParams.new() rp2.FilterType=Enum.RaycastFilterType.Exclude rp2.FilterDescendantsInstances={b}
for _,o in ipairs({{0,-1.5},{0,1.5},{-1.5,0},{1.5,0},{0,-2.5},{0,2.5},{-2.5,0},{2.5,0}}) do
	local r=workspace:Raycast(Vector3.new(cf.X+o[1],-30,cf.Z+o[2]),Vector3.new(0,-30,0),rp2)
	if r then warn(string.format('QR@NEAR@%.1f,%.1f@%.3f@%s',o[1],o[2],r.Position.Y,r.Instance:GetFullName())) end
end
warn('QR@END')
