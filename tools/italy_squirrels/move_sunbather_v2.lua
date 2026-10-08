-- Oct 5 2026 (Shannon: "the sunbather moved closer to the water"): from mid-beach (278.7,-727.1) south to the sand just
-- above the bay's waterline (~z -743 at x 279), same facing (west, to the open sea). Feet all on Sand, 1 stud of sand
-- kept between him and the water.
local col=workspace.sunbather_squirrel_color local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition)
local sz,sx=hl.Z<0 and 1 or -1,1
local k=3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local feet={{-0.58,-0.6},{-0.3,-0.6},{-0.58,-0.28},{-0.3,-0.28},{0.02,-0.65},{0.3,-0.65},{0.02,-0.3},{0.3,-0.3}}
local fc=R:VectorToWorldSpace(Vector3.new(sx*-0.14,0,sz*-0.47)*k)
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
local function sandAt(x,z) local q=workspace:Raycast(Vector3.new(x,-30,z),Vector3.new(0,-30,0),rp) return q and q.Material==Enum.Material.Sand and q.Position.Y end
local best
for dx=-2,2,0.5 do for z=-746,-734,0.5 do
	local c=Vector3.new(279+dx,0,z)
	local hi,lo,ok=-1e9,1e9,true
	for _,f in ipairs(feet) do
		local w=c-fc+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local y=sandAt(w.X,w.Z)
		if not y then ok=false break end
		for _,o in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do if not sandAt(w.X+o[1],w.Z+o[2]) then ok=false end end
		if not ok then break end
		hi=math.max(hi,y) lo=math.min(lo,y)
	end
	if ok and hi-lo<0.6 then
		local score=(hi-lo)*6+(z+746)*0.5+math.abs(dx)*0.2
		if not best or score<best.s then best={s=score,c=c,y=hi,spread=hi-lo} end
	end
end end
if not best then warn('QSB@ABORT no sand spot near the water') return end
local L=Vector3.new(best.c.X,best.y,best.c.Z)
local before=cm.Position
col:PivotTo(col:GetPivot()+Vector3.new(L.X-fc.X-cm.Position.X,L.Y+0.02-(cm.Position.Y-cm.Size.Y/2),L.Z-fc.Z-cm.Position.Z))
game:GetService('ChangeHistoryService'):SetWaypoint('Sunbather closer to the water')
warn('QSB@MOVED from',before,'to',cm.Position,'feet',L,'spread',best.spread)
local cam=workspace.CurrentCamera
local t=L+Vector3.new(0,1.6,0)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(L+Vector3.new(-10,4.5,6),t)
