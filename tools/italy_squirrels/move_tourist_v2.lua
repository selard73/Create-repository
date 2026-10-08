-- Oct 4 2026 (her fix): Penny to where Shannon's character stood in the play test (309.1, -721.0) facing (-0.974,0,0.227).
local id='italytourist_squirrel'
local col=workspace:FindFirstChild(id..'_color')
local gry=workspace.SquirrelTwins:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QT@ABORT missing') return end
local rs=''
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local want=Vector3.new(-0.974,0,0.227).Unit
for i=1,2 do
	local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,gry,workspace:FindFirstChild('ComingSoonWall'),workspace:FindFirstChild('SquirrelTwins')}
-- feet (Blender units, feet_probe): A x -0.07..0.30 y -0.80..-0.26, B x 0.29..0.86 y -0.13..0.16; plus the runtime footprint corners
local feet={{0,-0.7},{0.25,-0.7},{0,-0.35},{0.25,-0.35},{0.35,0.05},{0.8,0.05},{0.6,-0.1},{0.8,0.12}}
local hs=cm.Size*k/2
local corners={{-1,-1},{1,-1},{-1,1},{1,1}}
local function check(c)
	local bad=0
	for _,f in ipairs(feet) do
		local w=c+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-12,0),rp)
		if not q or q.Instance==workspace.Terrain or math.abs(q.Position.Y+46.8)>0.15 then bad+=1 end
	end
	for _,s in ipairs(corners) do
		local w=c+R:VectorToWorldSpace(Vector3.new(s[1]*hs.X,0,s[2]*hs.Z))
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-12,0),rp)
		if not q or q.Instance==workspace.Terrain or math.abs(q.Position.Y+46.8)>0.15 then bad+=1 end
	end
	return bad
end
local P
for _,dx in ipairs({0,0.5,-0.5,1,-1}) do
	local c=Vector3.new(309.1+dx,0,-721.0)
	local n=check(c)
	warn('QT@TRY',c,'bad',n)
	if n==0 then P=c break end
end
if not P then warn('QT@ABORT no clean spot on the landing') return end
local g=workspace:Raycast(Vector3.new(P.X,-40,P.Z),Vector3.new(0,-12,0),rp)
if not g then warn('QT@ABORT no ground') return end
local gy=g.Position.Y
col:PivotTo(col:GetPivot()+Vector3.new(P.X-cm.Position.X,gy+0.02-(cm.Position.Y-cm.Size.Y/2),P.Z-cm.Position.Z))
game:GetService('ChangeHistoryService'):SetWaypoint('Penny to her spot')
warn('QT@PLACED',cm.Position,'ground',gy,g.Instance:GetFullName())
local cam=workspace.CurrentCamera
local t=Vector3.new(P.X,gy+1.6,P.Z)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+want*5+Vector3.new(0,1,0),t)
