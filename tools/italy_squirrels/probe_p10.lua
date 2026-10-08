local cf=workspace.PortoNocciola['08 Coastal finishing']
local segs={}
for _,d in ipairs(cf:GetDescendants()) do
	if d:IsA('BasePart') and d.Name=='Continuous laundry cord' then table.insert(segs,d) end
end
table.sort(segs,function(a,b) if math.abs(a.Position.Z-b.Position.Z)>3 then return a.Position.Z<b.Position.Z end return a.Position.X<b.Position.X end)
for _,d in ipairs(segs) do
	local a=d.CFrame*Vector3.new(0,0,-d.Size.Z/2) local b=d.CFrame*Vector3.new(0,0,d.Size.Z/2)
	warn(string.format('QC@%s@(%.2f,%.2f,%.2f)->(%.2f,%.2f,%.2f)@len %.2f@par %s',d.Name,a.X,a.Y,a.Z,b.X,b.Y,b.Z,d.Size.Z,d.Parent.Name))
end
local g=cf:FindFirstChild('Hanging garments')
if g then
	local rows={}
	for _,m in ipairs(g:GetChildren()) do
		local c=m:IsA('Model') and m:GetBoundingBox()
		if c then warn(string.format('QC@G %s (%.1f,%.1f,%.1f)',m.Name,c.X,c.Y,c.Z)) end
	end
end
warn('QC@END '..#segs)
