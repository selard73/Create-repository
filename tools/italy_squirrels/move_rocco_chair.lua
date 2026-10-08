-- Oct 5 2026 (Shannon: "I want the lifeguard standing on top of his guard chair"): Rocco's feet on the chair seat
-- (top ~ -43.23), nudged away from the umbrella pole, same facing; the umbrella (pole + canopy) raised 1.9 so his
-- 3.4-stud body fits under it.
local post=workspace.PortoNocciola['Lifeguard Post']
local ch=post['Lifeguard Chair']
local wood,pole=ch.Chair_Wood,ch.Umbrella_Pole
local col=workspace.lifeguard_squirrel_color local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition)
local sz=hl.Z<0 and 1 or -1
local k=3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local fc=R:VectorToWorldSpace(Vector3.new(-0.09,0,sz*-0.28)*k)
local feet={{-0.52,-0.40},{-0.27,-0.40},{-0.52,-0.08},{-0.27,-0.08},{0.13,-0.50},{0.34,-0.50},{0.13,-0.14},{0.34,-0.14}}
local ip=RaycastParams.new() ip.FilterType=Enum.RaycastFilterType.Include ip.FilterDescendantsInstances={wood}
local away=((wood.Position-pole.Position)*Vector3.new(1,0,1)).Unit
local best
for s=0,0.8,0.1 do for t=-0.4,0.4,0.1 do
	local side=Vector3.new(-away.Z,0,away.X)
	local c=Vector3.new(wood.Position.X,0,wood.Position.Z)+away*s+side*t
	local hi,lo,n=-1e9,1e9,0
	for _,f in ipairs(feet) do
		local w=c-fc+R:VectorToWorldSpace(Vector3.new(f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-30,w.Z),Vector3.new(0,-20,0),ip)
		if q then n+=1 hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y) end
	end
	if n==#feet then
		local score=(hi-lo)*10+math.abs(t)*0.5+math.abs(s-0.35)*0.5
		if not best or score<best.sc then best={sc=score,c=c,y=hi,spread=hi-lo} end
	end
end end
if not best then warn('QR@ABORT feet do not all land on the seat') return end
local before=cm.Position
local L=Vector3.new(best.c.X,best.y,best.c.Z)
col:PivotTo(col:GetPivot()+Vector3.new(L.X-fc.X-cm.Position.X,L.Y+0.02-(cm.Position.Y-cm.Size.Y/2),L.Z-fc.Z-cm.Position.Z))
-- umbrella up 1.9 (pole longer from the same foot, canopy lifted)
local UP=1.9
if not pole:GetAttribute('OrigSizeY') then
	pole:SetAttribute('OrigSizeY',pole.Size.Y)
	pole.Size=pole.Size+Vector3.new(0,UP,0) pole.CFrame=pole.CFrame+Vector3.new(0,UP/2,0)
	for _,n in ipairs({'Umbrella_Red','Umbrella_White'}) do local p=ch:FindFirstChild(n) if p then p.CFrame=p.CFrame+Vector3.new(0,UP,0) end end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Rocco on his chair')
local head=L.Y+3.4
warn('QR@MOVED from',before,'to',cm.Position,'feet',L,'spread',best.spread,'head top ~',head,'canopy bottom',ch.Umbrella_Red.Position.Y-ch.Umbrella_Red.Size.Y/2)
local cam=workspace.CurrentCamera
local t2=L+Vector3.new(0,1.5,0)
local fwd=R:VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
cam.Focus=CFrame.new(t2)
cam.CFrame=CFrame.lookAt(L+fwd.Unit*11+Vector3.new(3,2,0),t2)
