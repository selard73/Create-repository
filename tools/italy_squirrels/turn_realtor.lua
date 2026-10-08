-- Oct 5 2026: new Signora Chiave faces due west (-1,0,0) like her installer intended; turn about her feet centre
local col=workspace.realtor_squirrel_color local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local L=Vector3.new(296.9000244140625,-46.779998779296875,-679)
local want=Vector3.new(-1,0,0)
for i=1,3 do
	local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local sz=hl.Z<0 and 1 or -1
	local f=(cm.CFrame-cm.Position):VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(f.X,f.Z)
	local c=CFrame.new(L) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
game:GetService('ChangeHistoryService'):SetWaypoint('Signora Chiave faces west')
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local sz=hl.Z<0 and 1 or -1
local f=(cm.CFrame-cm.Position):VectorToWorldSpace(Vector3.new(0,0,-sz))
warn('QTR@',f,cm.Position)
local t=L+Vector3.new(0,1.6,0)
workspace.CurrentCamera.Focus=CFrame.new(t)
workspace.CurrentCamera.CFrame=CFrame.lookAt(t+want*7+Vector3.new(0,1.5,1.5),t)
