-- Oct 4 2026: crab catcher (crabcatcher_squirrel, Meshy "Crab Catcher Chip", 19k tris) on the rock lip at the SOUTH edge of
-- the kidney tide pool (pool centre 295.15,-771.1), facing NORTH into the pool, trap held out over the water.
-- Placement + registry (Enzo the Crab Catcher). No asserts after the first edit: warn + return.
local id='crabcatcher_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QC@ABORT missing import') return end
local pools=workspace:FindFirstChild('PortoNocciola') and workspace.PortoNocciola:FindFirstChild('Natural tide pools',true)
local shelf=pools and pools:FindFirstChild('TidePoolShelf')
local water=pools and pools:FindFirstChild('TidePoolWater')
if not (shelf and water) then warn('QC@ABORT no tide pool shelf') return end
local POOL=Vector3.new(295.15,0,-771.1)
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local function axes()
	local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition)
	return hl.Z<0 and 1 or -1, 1
end
local function face(want)
	for i=1,3 do
		local sz=axes()
		local R=cm.CFrame-cm.Position
		local fwd=R:VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
		local ang=math.atan2(want.X,want.Z)-math.atan2(fwd.X,fwd.Z)
		local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
	end
end
-- feet (feet_probe, Blender units): L x -0.51..-0.11 y -0.45..0.05, R x 0.10..0.47 y -0.45..0.03; centre (-0.02,-0.2)
local feet={{-0.47,-0.38},{-0.15,-0.38},{-0.47,0.0},{-0.15,0.0},{0.13,-0.42},{0.44,-0.42},{0.13,0.0},{0.44,0.0}}
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={shelf,water}
local k=3.4/cm.Size.Y
local best
for dx=-0.75,0.75,0.25 do for dz=-0.75,0.75,0.25 do
	local c=Vector3.new(296.43+dx,0,-774.62+dz)          -- c = where the feet centre goes
	local want=(POOL-c).Unit
	face(want)
	local sz=axes() local sx=1
	local R=cm.CFrame-cm.Position
	local fc=R:VectorToWorldSpace(Vector3.new(sx*-0.02,0,sz*-0.2)*k)
	local hi,lo,ok=-1e9,1e9,true
	for _,f in ipairs(feet) do
		local w=c-fc+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-20,0),rp)
		if not q or q.Instance~=shelf then ok=false break end
		hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y)
	end
	if ok then
		local score=(hi-lo)*10+math.abs(dx)*0.3+math.abs(dz)*0.3
		if not best or score<best.s then best={s=score,c=c,y=hi,spread=hi-lo,want=want} end
	end
end end
if not best then warn('QC@ABORT no flat rock spot') return end
face(best.want)
local sz=axes()
local R=cm.CFrame-cm.Position
local fc=R:VectorToWorldSpace(Vector3.new(-0.02,0,sz*-0.2)*k)
local L=Vector3.new(best.c.X,best.y,best.c.Z)
col:PivotTo(col:GetPivot()+Vector3.new(L.X-fc.X-cm.Position.X,L.Y+0.02-(cm.Position.Y-cm.Size.Y/2),L.Z-fc.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
game:GetService('ChangeHistoryService'):SetWaypoint('Crab catcher at the kidney pool')
warn('QC@PLACED',cm.Position,'feet centre',L,'foot spread',best.spread,'facing',R:VectorToWorldSpace(Vector3.new(0,0,-sz)))
local cam=workspace.CurrentCamera
local t=L+Vector3.new(0,1.6,0)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(L+Vector3.new(-2.5,3.2,9),t)
-- registry: Enzo the Crab Catcher (bio C, Shannon's pick), after Sandro
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local a,b=rs:find('Porto Nocciola is a very calm harbour."},\n',1,true)
if not a or rs:find('crabcatcher_squirrel',1,true) then warn('QC@REG_SKIP anchor/dup',a) return end
local add='\t\t{id = "crabcatcher_squirrel",  map = "porto", name = "Enzo the Crab Catcher",\n\t\t bio = "Walks sideways along the rocks so the crabs will think he\'s one of them. So far it has only fooled the tourists."},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Enzo registry')
local n=0 for _ in reg.Source:gmatch('map = "porto"') do n+=1 end
warn('QC@REG porto entries',n,'enzo',reg.Source:find('Enzo the Crab Catcher',1,true)~=nil)
