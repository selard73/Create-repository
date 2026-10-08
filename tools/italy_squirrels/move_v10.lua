-- Oct 4 2026: (1) all 15 quay-step parts + Timbro 8 studs west (middle of the stone-wall stretch); (2) travel trunk against the
-- cliff between the dais and the old steps. No asserts after the first change: a failing command-bar script makes Studio undo everything.
local wf=workspace.PortoNocciola['01 Curved waterfront']
local DX=-8
local parts={}
for _,p in ipairs(wf:GetChildren()) do if p:IsA('BasePart') and p.Name:sub(1,15)=='Realigned stair' then table.insert(parts,p) end end
if #parts~=15 then warn('QM@ABORT steps found',#parts) return end
for _,p in ipairs(parts) do p.CFrame=p.CFrame+Vector3.new(DX,0,0) end
local t=workspace.customs_squirrel_color t:PivotTo(t:GetPivot()+Vector3.new(DX,0,0))
warn('QM@STEPS moved',#parts,'Timbro',t.Squirrel.Position)
local cart=workspace.Travel.Points.TravelCart_porto
local cpv=cart:GetPivot() local cf0,sz0=cart:GetBoundingBox()
local bottomOff=cf0.Position.Y-sz0.Y/2-cpv.Position.Y
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
local xp=RaycastParams.new() xp.FilterType=Enum.RaycastFilterType.Exclude xp.FilterDescendantsInstances={cart,workspace.ComingSoonWall,workspace.Terrain}
local R=cpv-cpv.Position local hx,hz=sz0.X/2,sz0.Z/2
local placed
for _,c in ipairs({{253,-575},{252,-574},{254,-576},{251,-575},{253,-573},{250,-574},{255,-577},{252,-577}}) do
	local g=workspace:Raycast(Vector3.new(c[1],-20,c[2]),Vector3.new(0,-40,0),rp)
	if g then
		local ok=true
		for _,h in ipairs({0.8,2.0,3.4}) do
			local o=Vector3.new(c[1],g.Position.Y+h,c[2])
			for a=0,315,45 do
				local d=Vector3.new(math.sin(math.rad(a)),0,math.cos(math.rad(a)))
				local l=R:VectorToObjectSpace(d) local reach=math.min(math.abs(l.X)>1e-3 and hx/math.abs(l.X) or 1e9, math.abs(l.Z)>1e-3 and hz/math.abs(l.Z) or 1e9)+0.6
				if workspace:Raycast(o,d*reach,xp) then ok=false end
			end
		end
		if ok then cart:PivotTo(CFrame.new(c[1],g.Position.Y-bottomOff+0.02,c[2])*R) placed=c break end
	end
end
warn('QM@CART',placed and (placed[1]..','..placed[2]) or 'NOT MOVED (no clear spot)',cart:GetBoundingBox().Position)
game:GetService('ChangeHistoryService'):SetWaypoint('Steps + Timbro west, trunk against the cliff')
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(226,-41,-580),Vector3.new(250,-46,-584))
