-- temporary: park Car_Rosso mid-track (the ride's own formula) for a side photo; restore_photo.lua puts it back
local F=workspace.PortoNocciola['15 Funicolare']
local car=F.Cars.Car_Rosso
if not car:GetAttribute('PhotoFrom') then car:SetAttribute('PhotoFrom',car:GetPivot()) end
local A,B=F:GetAttribute('Bottom'),F:GetAttribute('Top')
local d=Vector3.new(B.X-A.X,0,B.Z-A.Z).Unit
local r=Vector3.new(-d.Z,0,d.X)
car:PivotTo(CFrame.new(A:Lerp(B,1)+r*car:GetAttribute('Offset'))*CFrame.lookAt(Vector3.zero,d).Rotation)
local p=car:GetPivot()
local cam=workspace.CurrentCamera
cam.Focus=CFrame.new(p.Position)
cam.CFrame=CFrame.lookAt(p*Vector3.new(-9,3.5,6),p*Vector3.new(0,2,0))
warn('QP@PARKED',p.Position)
