local cnt={}
local ex={}
for _,d in ipairs(workspace:GetDescendants()) do
	local isB=d:IsA('BasePart') or d:IsA('Beam') or d:IsA('RopeConstraint')
	if isB then
		local p
		if d:IsA('BasePart') then p=d.Position elseif d:IsA('Beam') and d.Attachment0 then p=d.Attachment0.WorldPosition elseif d:IsA('RopeConstraint') and d.Attachment0 then p=d.Attachment0.WorldPosition end
		if p and p.X>282 and p.X<296 and p.Z>-645 and p.Z<-590 and p.Y>-42 and p.Y<-24 then
			local par=d.Parent and d.Parent:GetFullName():gsub('Workspace.PortoNocciola.','') or '?'
			if not par:find('^02 Pastel waterfront%.Casa') then
				local key=par..' / '..d.ClassName..' '..d.Name
				cnt[key]=(cnt[key] or 0)+1
				if not ex[key] then ex[key]=string.format('(%.1f,%.1f,%.1f) s%s',p.X,p.Y,p.Z,d:IsA('BasePart') and tostring(d.Size) or '') end
			end
		end
	end
end
for k,n in pairs(cnt) do warn('QV@'..n..'x '..k..' '..ex[k]) end
warn('QV@END')
