-- Oct 4 2026: sunbather on the beach ('07 Cove and tide pools') beside the north-west umbrella (~280.5,-718.3) and its towel
-- (~284,-719), just outside the shade, facing WEST to the open sea. Placement only; registry waits for her name/bio pick.
-- No asserts after the first edit: warn + return.
local id='sunbather_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QS@ABORT missing import') return end
local want=Vector3.new(-1,0,0)
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local function axes()
	local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
	return hl.Z<0 and 1 or -1, 1  -- sx fixed: the FBX import mapping is the same for every squirrel (proved by Tito's foot on the rope); the old tail-side guess flips for tails on +x
end
-- face by the mesh's own forward axis (Blender -Y -> local -sz*Z), not the head bone (off-centre on this rig)
for i=1,3 do
	local sz,sx=axes()
	local R=cm.CFrame-cm.Position
	local fwd=R:VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(fwd.X,fwd.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local sz,sx=axes()
local k=3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
-- feet (feet_probe, Blender units): L x -0.62..-0.24 y -0.66..-0.22, R x -0.01..0.34 y -0.72..-0.26; centre (-0.14,-0.47)
local feet={{-0.58,-0.6},{-0.3,-0.6},{-0.58,-0.28},{-0.3,-0.28},{0.02,-0.65},{0.3,-0.65},{0.02,-0.3},{0.3,-0.3}}
local fc=R:VectorToWorldSpace(Vector3.new(sx*-0.14,0,sz*-0.47)*k)
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,gry,workspace:FindFirstChild('SquirrelTwins'),workspace:FindFirstChild('ComingSoonWall')}
local best
for dx=-1.5,1.5,0.25 do for dz=-1.5,1.0,0.25 do
	local c=Vector3.new(281.8+dx,0,-721.8+dz)          -- c = where the feet centre goes
	local hi,lo,ok=-1e9,1e9,true
	for _,f in ipairs(feet) do
		local w=c-fc+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-15,0),rp)
		if not q or q.Instance~=workspace.Terrain or q.Material~=Enum.Material.Sand then ok=false break end
		hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y)
	end
	if ok then
		local score=(hi-lo)*10+math.abs(dx)*0.3+math.abs(dz)*0.3
		if not best or score<best.s then best={s=score,c=c,y=hi,spread=hi-lo} end
	end
end end
if not best then warn('QS@ABORT no sand spot') return end
local L=Vector3.new(best.c.X,best.y,best.c.Z)
col:PivotTo(col:GetPivot()+Vector3.new(L.X-fc.X-cm.Position.X,L.Y+0.02-(cm.Position.Y-cm.Size.Y/2),L.Z-fc.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
game:GetService('ChangeHistoryService'):SetWaypoint('Sunbather on the beach')
warn('QS@PLACED',cm.Position,'feet centre',L,'foot spread',best.spread,'facing',R:VectorToWorldSpace(Vector3.new(0,0,-sz)))
local cam=workspace.CurrentCamera
local t=L+Vector3.new(0,1.8,0)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(L+Vector3.new(-9,3,-4),t)
