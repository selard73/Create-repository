-- Oct 5 2026 (Shannon): Enzo to where her character stood in the play test (HRP 305.83,-48.49,-805.06, she faced the sea
-- (-0.25,0,-0.97)); Enzo faces back the other way (toward the pools/stairs). Beppe 0.3 studs to the viewer's right on
-- his crate (viewer on the quay looking at him = +z).
local out={}
-- Enzo
do
	local col=workspace.crabcatcher_squirrel_color local cm=col.Squirrel
	local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
	local function fwdOf()   -- Enzo's head-side test points backwards (see turn_enzo.lua): his front is +sz*Z
		local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local sz=hl.Z<0 and 1 or -1
		return -((cm.CFrame-cm.Position):VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)).Unit
	end
	local want=Vector3.new(0.2515,0,0.9679)
	for i=1,3 do
		local f=fwdOf()
		local ang=math.atan2(want.X,want.Z)-math.atan2(f.X,f.Z)
		local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
	end
	local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances={col,workspace:FindFirstChild('SquirrelTwins'),workspace:FindFirstChild('ComingSoonWall')}
	local k=3.4/cm.Size.Y
	local R=cm.CFrame-cm.Position
	local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local sz=hl.Z<0 and 1 or -1
	local fc=R:VectorToWorldSpace(Vector3.new(-0.15,0,0)*k)
	local spot=Vector3.new(305.83,0,-805.06)
	local hi,lo,hit=-1e9,1e9,{}
	for _,f in ipairs({{-0.55,-0.15},{-0.3,0.2},{0.05,-0.15},{0.3,0.2},{-0.15,0}}) do
		local w=spot-fc+R:VectorToWorldSpace(Vector3.new(f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-42,w.Z),Vector3.new(0,-20,0),rp)
		if q then hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y) table.insert(hit,q.Instance.Name..'/'..q.Material.Name) end
	end
	if hi<-1e8 then warn('QM@ENZO_ABORT no ground') else
		col:PivotTo(col:GetPivot()+Vector3.new(spot.X-fc.X-cm.Position.X,hi+0.02-(cm.Position.Y-cm.Size.Y/2),spot.Z-fc.Z-cm.Position.Z))
		table.insert(out,string.format('ENZO feet (%.2f,%.2f,%.2f) spread %.2f on %s',spot.X,hi,spot.Z,hi-lo,table.concat(hit,',')))
	end
end
-- Beppe
do
	local col=workspace.fishmonger_squirrel_color
	local d=Vector3.new(0.078,0,0.997)*0.3
	col:PivotTo(col:GetPivot()+d)
	local cm=col.Squirrel
	local bc=workspace.PortoNocciola['03 Fish market'].BeppeCrate
	local lid={} for _,p in ipairs(bc:GetChildren()) do if p.Name=='Lid' then table.insert(lid,p) end end
	local ip=RaycastParams.new() ip.FilterType=Enum.RaycastFilterType.Include ip.FilterDescendantsInstances=lid
	local miss=0 local bottom=cm.Position.Y-cm.Size.Y/2
	for dx=-0.4,0.4,0.4 do for dz=-0.4,0.4,0.4 do
		if not workspace:Raycast(Vector3.new(253.18+d.X+dx,bottom+2,-636.81+d.Z+dz),Vector3.new(0,-4,0),ip) then miss+=1 end
	end end
	table.insert(out,'BEPPE moved +0.3 to viewer right; lid misses around feet '..miss..'/9')
end
game:GetService('ChangeHistoryService'):SetWaypoint('Enzo to her spot, Beppe nudged')
for _,l in ipairs(out) do warn('QM@'..l) end
