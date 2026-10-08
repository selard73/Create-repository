local cc=workspace.CurrentCamera warn("QL@CAM",cc.CFrame,"FOCUS",cc.Focus)
local seen={}
for _,d in ipairs(workspace.PortoNocciola:GetDescendants()) do
	local n=d.Name:lower()
	if (d:IsA('Model') or d:IsA('Folder')) and (n:find('cloth') or n:find('laundry') or n:find('washing') or n:find('bucato') or n:find('line')) then
		local ok,cf,sz=pcall(function() if d:IsA('Model') then return d:GetBoundingBox() end end)
		if ok and cf then warn(string.format('QL@M@%s@c(%.1f,%.1f,%.1f)@s(%.1f,%.1f,%.1f)',d:GetFullName(),cf.X,cf.Y,cf.Z,sz.X,sz.Y,sz.Z)) else warn('QL@F@'..d:GetFullName()) end
	elseif d:IsA('BasePart') and (n:find('clothes') or n:find('washing line') or n:find('laundry line') or n:find('rope') or n:find('cord') or n:find('wire')) then
		warn(string.format('QL@P@%s@%s@(%.2f,%.2f,%.2f)@s(%.2f,%.2f,%.2f)@o%s',d:GetFullName(),d.ClassName,d.Position.X,d.Position.Y,d.Position.Z,d.Size.X,d.Size.Y,d.Size.Z,tostring(d.Orientation)))
	end
end
warn('QL@END')
