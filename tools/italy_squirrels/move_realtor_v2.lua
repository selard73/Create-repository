-- Oct 4 2026 (Shannon's fix): Signora Chiave to the LEFT (south) of Casa Salvia's door, a stud further into the street,
-- facing the street (-x) so her left side (keys hand) shows toward the door and to players coming down the street from the north.
local col=workspace:FindFirstChild('realtor_squirrel_color')
if not col then warn('QM@ABORT no model') return end
local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local want=Vector3.new(-1,0,0)
for i=1,2 do
	local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local hx=0
for _,v in ipairs({R.RightVector*cm.Size.X,R.UpVector*cm.Size.Y,R.LookVector*cm.Size.Z}) do hx+=math.abs(v.X)*k/2 end
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,workspace.ComingSoonWall,workspace:FindFirstChild('SquirrelTwins')}
local P=Vector3.new(296.9,0,-679.0)
local wall=workspace:Raycast(Vector3.new(P.X-3,-45.3,P.Z),Vector3.new(8,0,0),rp)
if wall then
	local maxX=wall.Position.X-hx-0.15
	if P.X>maxX then P=Vector3.new(maxX,0,P.Z) end
	warn('QM@WALL x',wall.Position.X,wall.Instance:GetFullName(),'hx',hx)
end
local g=workspace:Raycast(Vector3.new(P.X,-40,P.Z),Vector3.new(0,-12,0),rp)
if not g then warn('QM@ABORT no ground') return end
local gy=g.Position.Y
col:PivotTo(col:GetPivot()+Vector3.new(P.X-cm.Position.X,gy+0.02-(cm.Position.Y-cm.Size.Y/2),P.Z-cm.Position.Z))
game:GetService('ChangeHistoryService'):SetWaypoint('Signora Chiave left of door')
local feet={{-0.1,-0.2},{0.25,-0.2},{-0.1,0.3},{0.25,0.3},{0.38,-0.52},{0.72,-0.52},{0.38,-0.27},{0.72,-0.27}}
for _,f in ipairs(feet) do
	local w=cm.Position+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
	local q=workspace:Raycast(Vector3.new(w.X,gy+1.5,w.Z),Vector3.new(0,-3,0),rp)
	warn(string.format('QM@FOOT %.2f,%.2f hit %s y %.2f',f[1],f[2],q and q.Instance.Name or 'none',q and q.Position.Y or 0))
end
local keys=cm.Position+R:VectorToWorldSpace(Vector3.new(sx*0.9,0,0)*k)
warn('QM@PLACED',cm.Position,'ground',gy,'keys side',keys)
local cam=workspace.CurrentCamera
local t=Vector3.new(P.X,gy+1.6,P.Z)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+Vector3.new(-6,2.2,6),t)
