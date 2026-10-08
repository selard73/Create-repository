local bc=workspace.PortoNocciola['03 Fish market'].BeppeCrate
local col=workspace.fishmonger_squirrel_color local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local face=((B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)).Unit
local Ry=CFrame.Angles(0,math.rad(cm.Orientation.Y),0)
if Ry:VectorToWorldSpace(Vector3.new(0,0,1)):Dot(face)<0 then Ry=Ry*CFrame.Angles(0,math.pi,0) end
-- the crate's own axes: a Lid board's CFrame rotation (built axis-aligned with the crate)
local lid for _,p in ipairs(bc:GetChildren()) do if p.Name=='Lid' then lid=p break end end
local cur=lid.CFrame-lid.CFrame.Position
local cf=bc:GetBoundingBox()
local centre=Vector3.new(cf.Position.X,0,cf.Position.Z)
local delta=Ry*cur:Inverse()
for _,p in ipairs(bc:GetDescendants()) do if p:IsA('BasePart') then
	local off=p.Position-Vector3.new(centre.X,p.Position.Y,centre.Z)
	p.CFrame=CFrame.new(Vector3.new(centre.X,p.Position.Y,centre.Z)+delta:VectorToWorldSpace(off))*(delta*(p.CFrame-p.CFrame.Position))
end end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local gp=RaycastParams.new() gp.FilterType=Enum.RaycastFilterType.Include gp.FilterDescendantsInstances={bc}
local bottom=cm.Position.Y-cm.Size.Y/2 local out=''
for _,f in ipairs({{-0.85,-0.82},{0.32,-0.82},{-0.85,0.45},{0.32,0.45},{-0.27,-0.19}}) do
	local w=Vector3.new(cm.Position.X,0,cm.Position.Z)+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
	local q=workspace:Raycast(Vector3.new(w.X,bottom+3,w.Z),Vector3.new(0,-10,0),gp)
	out=out..string.format(' %.2f%s',q and (bottom-q.Position.Y) or 99,q and q.Instance.Name:sub(1,4) or '')
end
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={bc,col}
local c2,s2=bc:GetBoundingBox()
game:GetService('ChangeHistoryService'):SetWaypoint('Beppe crate squared under him')
warn('CRATE_SQUARED feet',out,'overlaps',#workspace:GetPartBoundsInBox(c2,s2*0.92,op))
