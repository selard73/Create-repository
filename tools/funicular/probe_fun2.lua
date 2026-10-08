-- READ-ONLY probe 2 (Oct 4 2026): FunicularServer source, Car_Rosso's parts in the car's own frame, the seats, and every
-- part (anywhere) the cars pass through along the track (the "partition" at the top). QF2@ lines.
local F=workspace.PortoNocciola['15 Funicolare']
local function dump(tag,s) for i=1,#s,450 do warn('QF2@'..tag..'@'..string.format('%06d',i)..'@'..s:sub(i,i+449)) end end
dump('SRV',F.FunicularServer.Source)
local car=F.Cars.Car_Rosso
local cf,size=car:GetBoundingBox()
warn('QF2@CAR box',cf.Position,size,'pivot',car:GetPivot().Position,'primary',car.PrimaryPart and car.PrimaryPart.Name)
local a={} for k,v in pairs(car:GetAttributes()) do table.insert(a,k..'='..tostring(v)) end warn('QF2@CARATTR',table.concat(a,' '))
local piv=car:GetPivot()
for _,p in ipairs(car:GetDescendants()) do
	if p:IsA('BasePart') or p:IsA('Seat') then
		local l=piv:ToObjectSpace(p.CFrame)
		warn(string.format('QF2@PART@%s@%s@local(%.2f,%.2f,%.2f)@size(%.2f,%.2f,%.2f)@%s@T%.2f',p.Name,p.ClassName,l.X,l.Y,l.Z,p.Size.X,p.Size.Y,p.Size.Z,p.Material.Name,p.Transparency))
	end
end
for _,c in ipairs(F:GetChildren()) do
	if not c.Name:find('track bed') then
		local s=''
		if c:IsA('Model') or c:IsA('Folder') then local n=0 for _ in ipairs(c:GetDescendants()) do n+=1 end s=' items '..n end
		if c:IsA('Model') then local b,z=c:GetBoundingBox() s=s..string.format(' c(%.1f,%.1f,%.1f) s(%.1f,%.1f,%.1f)',b.X,b.Y,b.Z,z.X,z.Y,z.Z) end
		warn('QF2@CHILD@'..c.Name..'@'..c.ClassName..s)
	end
end
-- what the moving car sweeps through near the top: boxes along the path's last 40 studs
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={F.Cars,workspace.Terrain}
local top=F.Cars.Car_Crema:GetPivot()
local _,csz=F.Cars.Car_Crema:GetBoundingBox()
local seen={}
for _,carM in ipairs({F.Cars.Car_Crema,F.Cars.Car_Rosso}) do
	local b,z=carM:GetBoundingBox()
	for _,h in ipairs(workspace:GetPartBoundsInBox(b,z*0.9,op)) do
		if not seen[h] and h.CanCollide~=nil then seen[h]=true
			warn(string.format('QF2@HIT@%s@%s@c(%.1f,%.1f,%.1f)@s(%.1f,%.1f,%.1f)@T%.2f@coll %s',carM.Name,h:GetFullName(),h.Position.X,h.Position.Y,h.Position.Z,h.Size.X,h.Size.Y,h.Size.Z,h.Transparency,tostring(h.CanCollide)))
		end
	end
end
warn('QF2@END')
