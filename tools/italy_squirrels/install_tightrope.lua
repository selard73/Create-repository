-- Oct 4 2026: tightrope squirrel standing on the MIDDLE clothesline across the alley between Casa Azzurra and Casa Rosa
-- ('08 Coastal finishing' Continuous laundry cord at z ~ -651, x 283.45..294.10), in the gap between Hanging shirt 2-2 and dress 2-3,
-- facing WEST along the rope. Placement only (registry entry waits for Shannon's name/bio pick).
-- No asserts after the first edit (a failing command-bar module rolls everything back): warn + return instead.
local id='tightrope_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QR@ABORT missing import') return end
-- the rope: middle line segments
local segs={}
for _,d in ipairs(workspace.PortoNocciola['08 Coastal finishing']:GetChildren()) do
	if d:IsA('BasePart') and d.Name=='Continuous laundry cord' and d.Position.Z>-660 and d.Position.Z<-640 then table.insert(segs,d) end
end
if #segs<5 then warn('QR@ABORT rope not found',#segs) return end
local X=287.9
local best
for _,d in ipairs(segs) do
	local a=d.CFrame*Vector3.new(0,0,-d.Size.Z/2) local b=d.CFrame*Vector3.new(0,0,d.Size.Z/2)
	if (a.X-X)*(b.X-X)<=0 then local t=(X-a.X)/(b.X-a.X) best={p=a:Lerp(b,t),r=d.Size.X/2,dir=(b-a).Unit} end
end
if not best then warn('QR@ABORT no segment at x',X) return end
local L=best.p+Vector3.new(0,best.r,0)             -- top of the cord
local along=Vector3.new(best.dir.X,0,best.dir.Z).Unit
local want=along.X<0 and along or -along           -- face WEST along the rope
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local function axes()
	local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
	return hl.Z<0 and 1 or -1, tl.X<0 and 1 or -1
end
-- face by the mesh's own forward axis (Blender -Y -> local -sz*Z), not the head bone (off-centre on this rig)
for i=1,2 do
	local sz,sx=axes()
	local R=cm.CFrame-cm.Position
	local fwd=R:VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(fwd.X,fwd.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local sz,sx=axes()
local k=3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
-- standing foot (feet_probe, Blender units): x -0.49..-0.27, y -0.69..-0.33, centre (-0.37,-0.51)
local foot=R:VectorToWorldSpace(Vector3.new(sx*-0.37,0,sz*-0.51)*k)
col:PivotTo(col:GetPivot()+Vector3.new(L.X-foot.X-cm.Position.X,L.Y+0.01-(cm.Position.Y-cm.Size.Y/2),L.Z-foot.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
game:GetService('ChangeHistoryService'):SetWaypoint('Tightrope squirrel on the middle line')
local fw=R:VectorToWorldSpace(Vector3.new(0,0,-sz))
warn('QR@PLACED',cm.Position,'rope top',L,'facing',fw,'foot runtime at',cm.Position+foot)
local cam=workspace.CurrentCamera
local t=L+Vector3.new(0,1.4,0)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(Vector3.new(L.X-1.5,L.Y+0.6,L.Z-9),t)
