-- Oct 5 2026 read-only: locate her new flags. Squirrel positions in Porto, tide-pool / pebble containers, the BELLA tree + lamp.
local function f(v) return string.format('%.1f,%.1f,%.1f',v.X,v.Y,v.Z) end
for _,m in ipairs(workspace:GetChildren()) do
	if m:IsA('Model') and m.Name:match('_squirrel_color$') then
		local p=m:GetPivot().Position
		if p.X>150 and p.X<420 and p.Z<-560 and p.Z>-900 then warn('QF7@sq',m.Name,f(p)) end
	end
end
local seen={}
for _,d in ipairs(workspace:GetDescendants()) do
	local n=d.Name:lower()
	if (d:IsA('Model') or d:IsA('Folder')) and (n:match('tide') or n:match('pebble') or n:match('rock pool') or n:match('rockpool') or n:match('pool')) then
		local key=d.Parent and d.Parent:GetFullName()..'/'..d.Name
		if not seen[key] then seen[key]=true
			local ok,cf,sz=pcall(function() return d:GetBoundingBox() end)
			if d:IsA('Model') and ok then warn('QF7@box',d:GetFullName(),f(cf.Position),'size',f(sz))
			else warn('QF7@box',d:GetFullName(),d.ClassName,#d:GetChildren()) end
		end
	end
end
local Z=workspace.PortoNocciola['06 Piazza details and planting']
for _,c in ipairs(Z:GetChildren()) do
	if c:IsA('Model') and (c.Name=='Lemon tree' or c.Name=='Quay lantern') then
		local cf,sz=c:GetBoundingBox() warn('QF7@z06',c.Name,f(cf.Position),'size',f(sz),'moved',tostring(c:GetAttribute('PromOldPivot')~=nil))
	end
end
warn('QF7@DONE')
