-- Oct 5 2026 read-only survey for widening the harbour promenade (+8 studs out to sea, -X).
-- Lists every top-level model/part inside the box between the shop fronts and the water, with world AABBs,
-- plus terrain material columns across the quay edge, and squirrels on the strip.
-- Output: warn lines 'QPR@...' (read from the Studio log).
local BOX_MIN=Vector3.new(196,-60,-720)   -- x from the boats' outer side
local BOX_MAX=Vector3.new(272,-25,-580)   -- to just inside the shop fronts
local P=workspace:FindFirstChild('PortoNocciola')
local function inBox(cf,sz)
	local p=cf.Position
	local h=sz/2
	return p.X+h.X>BOX_MIN.X and p.X-h.X<BOX_MAX.X and p.Z+h.Z>BOX_MIN.Z and p.Z-h.Z<BOX_MAX.Z and p.Y+h.Y>BOX_MIN.Y and p.Y-h.Y<BOX_MAX.Y
end
local function aabb(inst)
	local mn=Vector3.new(1e9,1e9,1e9) local mx=-mn local n=0
	local list=inst:IsA('BasePart') and {inst} or inst:GetDescendants()
	for _,d in ipairs(list) do
		if d:IsA('BasePart') and d.Transparency<1 then
			local cf,s=d.CFrame,d.Size/2
			for _,c in ipairs({Vector3.new(1,1,1),Vector3.new(1,1,-1),Vector3.new(1,-1,1),Vector3.new(1,-1,-1),Vector3.new(-1,1,1),Vector3.new(-1,1,-1),Vector3.new(-1,-1,1),Vector3.new(-1,-1,-1)}) do
				local w=cf:PointToWorldSpace(s*c) mn=mn:Min(w) mx=mx:Max(w)
			end
			n+=1
		end
	end
	if n==0 then return nil end
	return mn,mx,n
end
local function f(v) return string.format('%.1f,%.1f,%.1f',v.X,v.Y,v.Z) end
-- walk: section folders -> children; report models whole, big folders one level deeper
local count=0
local function report(inst,depth)
	local mn,mx,n=aabb(inst)
	if not mn then return end
	local c=(mn+mx)/2 local s=mx-mn
	if not inBox(CFrame.new(c),s) then return end
	-- big containers: go one level deeper
	if (inst:IsA('Folder') or (inst:IsA('Model') and (s.X>40 or s.Z>40) and n>12)) and depth<3 then
		warn('QPR@group',depth,inst:GetFullName(),'n',n,'min',f(mn),'max',f(mx))
		for _,ch in ipairs(inst:GetChildren()) do report(ch,depth+1) end
		return
	end
	count+=1
	local sq=inst:FindFirstChild('SquirrelId',true) or inst:GetAttribute('SquirrelId')
	warn('QPR@item',inst.ClassName,inst:GetFullName(),'n',n,'min',f(mn),'max',f(mx))
end
if P then
	for _,sec in ipairs(P:GetChildren()) do report(sec,0) end
end
-- other workspace roots that might sit on the quay (squirrels, crab game, music zones...)
for _,r in ipairs(workspace:GetChildren()) do
	if r~=P and r~=workspace.Terrain and not r:IsA('Camera') and r.Name~='Baseplate' and r.Name~='SouthGorge' then
		local mn,mx=aabb(r)
		if mn and inBox(CFrame.new((mn+mx)/2),mx-mn) then
			local s=mx-mn
			if s.X>60 or s.Z>60 then
				for _,ch in ipairs(r:GetChildren()) do
					local a,b=aabb(ch)
					if a and inBox(CFrame.new((a+b)/2),b-a) then warn('QPR@root',ch:GetFullName(),'min',f(a),'max',f(b)) end
				end
			else
				warn('QPR@root',r:GetFullName(),'min',f(mn),'max',f(mx))
			end
		end
	end
end
-- ground profile: every 1 stud in x along 7 z-lines, top hit (part or terrain) + material
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={}
for _,z in ipairs({-600,-615,-628,-637,-646,-660,-672,-685,-700}) do
	local row={}
	for x=200,270,1 do
		local r=workspace:Raycast(Vector3.new(x,-20,z),Vector3.new(0,-60,0),rp)
		if r then
			local who=r.Instance==workspace.Terrain and ('T:'..r.Material.Name) or (r.Instance.Name:sub(1,14))
			table.insert(row,string.format('%d:%.1f:%s',x,r.Position.Y,who))
		else table.insert(row,x..':none') end
	end
	warn('QPR@ray z',z,table.concat(row,' | '))
end
-- terrain-only profile (ignore parts) to see what is under the paving / the water edge
local rp2=RaycastParams.new() rp2.FilterType=Enum.RaycastFilterType.Include rp2.FilterDescendantsInstances={workspace.Terrain}
for _,z in ipairs({-600,-637,-660,-685,-700}) do
	local row={}
	for x=200,270,2 do
		local r=workspace:Raycast(Vector3.new(x,-20,z),Vector3.new(0,-60,0),rp2)
		table.insert(row,r and string.format('%d:%.1f:%s',x,r.Position.Y,r.Material.Name) or (x..':none'))
	end
	warn('QPR@terr z',z,table.concat(row,' | '))
end
-- squirrels: anything with a squirrel id attribute in the box
for _,d in ipairs(workspace:GetDescendants()) do
	if d:IsA('Model') and (d:GetAttribute('SquirrelId') or d.Name:lower():match('squirrel')) then
		local ok,cf,sz=pcall(function() return d:GetBoundingBox() end)
		if ok and inBox(cf,sz) and sz.Magnitude<30 then warn('QPR@squirrel',d:GetFullName(),f(cf.Position),'size',f(sz)) end
	end
end
warn('QPR@DONE items',count)
