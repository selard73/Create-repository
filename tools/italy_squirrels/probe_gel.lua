local gel=workspace.PortoNocciola['02 Pastel waterfront']['Gelateria al Limone']
for _,p in ipairs(gel:GetDescendants()) do
	if p:IsA('BasePart') and p.Position.Z<-628 and p.Position.Z>-638.5 and p.Position.X<274 and p.Position.Y<-40 then
		warn(string.format('QO@%s@(%.2f,%.2f,%.2f)@(%.2f,%.2f,%.2f)@%s',p.Name,p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,tostring(p.Orientation)))
	end
end
warn('QO@END')
