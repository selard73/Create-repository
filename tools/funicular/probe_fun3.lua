-- READ-ONLY probe 3: station parts (both), rails, the rail Top/Bottom attributes, car pivots, rail-top heights under the car.
local F=workspace.PortoNocciola['15 Funicolare']
local a={} for k,v in pairs(F:GetAttributes()) do table.insert(a,k..'='..tostring(v)) end warn('QF3@ATTR',table.concat(a,' | '))
for _,c in ipairs(F.Cars:GetChildren()) do warn('QF3@CARPIV',c.Name,c:GetPivot().Position,'offset',c:GetAttribute('Offset')) end
for _,st in ipairs(F:GetChildren()) do
	if st:IsA('Model') and st.Name:find('STAZIONE') then
		for _,p in ipairs(st:GetDescendants()) do
			if p:IsA('BasePart') then
				local o=p.CFrame
				warn(string.format('QF3@ST@%s@%s@%s@c(%.2f,%.2f,%.2f)@s(%.2f,%.2f,%.2f)@top %.2f@rot(%.0f,%.0f,%.0f)@T%.2f',st.Name:sub(1,5),p.Name,p.ClassName,p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,p.Position.Y+p.Size.Y/2,
					math.deg(select(1,o:ToEulerAnglesYXZ())),math.deg(select(2,o:ToEulerAnglesYXZ())),math.deg(select(3,o:ToEulerAnglesYXZ())),p.Transparency))
			end
		end
	end
end
for _,p in ipairs(F:GetChildren()) do
	if p:IsA('BasePart') and (p.Name:find('rail') and not p.Name:find('sleeper') and not p.Name:find('pier') or p.Name:find('cable')) then
		local look=p.CFrame.LookVector local up=p.CFrame.UpVector
		warn(string.format('QF3@RAIL@%s@c(%.2f,%.2f,%.2f)@s(%.2f,%.2f,%.2f)@look(%.3f,%.3f,%.3f)@up(%.3f,%.3f,%.3f)',p.Name,p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,look.X,look.Y,look.Z,up.X,up.Y,up.Z))
	end
end
-- rail top under each car at its four wheel spots (rays straight down, rails only)
local rails={} for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:find('running rail') then table.insert(rails,p) end end
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances=rails
for _,c in ipairs(F.Cars:GetChildren()) do
	local piv=c:GetPivot()
	for _,z in ipairs({-3.9,-2.8,0,2.8,3.9}) do
		local s=''
		for _,x in ipairs({-1.3,1.3}) do
			local w=piv*Vector3.new(x,0,z)
			local q=workspace:Raycast(w+Vector3.new(0,10,0),Vector3.new(0,-30,0),rp)
			s=s..string.format(' x%.1f:%s',x,q and string.format('%.2f',piv:PointToObjectSpace(q.Position).Y) or '-')
		end
		warn('QF3@RAILY',c.Name,'z',z,s)
	end
end
-- the two upright path pieces at the top
for _,p in ipairs(workspace.PortoNocciola['12 Country landscape']:GetDescendants()) do
	if p:IsA('BasePart') and (p.Position-Vector3.new(700,6,-661)).Magnitude<4 then
		local o=p.CFrame
		warn(string.format('QF3@PATH@%s@c(%.2f,%.2f,%.2f)@s(%.2f,%.2f,%.2f)@up(%.2f,%.2f,%.2f)@look(%.2f,%.2f,%.2f)@%s',p:GetFullName(),p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,o.UpVector.X,o.UpVector.Y,o.UpVector.Z,o.LookVector.X,o.LookVector.Y,o.LookVector.Z,p.ClassName))
	end
end
warn('QF3@END')
