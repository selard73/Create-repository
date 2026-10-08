-- Oct 4 2026: Vito the Boat Painter standing on the boatyard's oak barrel by the Nuova Alba (the one at x ~274.8), facing the hull.
-- No asserts after the first edit (a failing command-bar module rolls everything back): warn + return instead.
local id='boatpainter_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QV@ABORT missing import') return end
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local anchor='named after a very sour-faced tourist."},\n'
local a,b=rs:find(anchor,1,true)
if not a or rs:find(id,1,true) then warn('QV@ABORT registry anchor/dup') return end
local yard=workspace.PortoNocciola['05 Boatyard and nets']
local boat=yard:FindFirstChild('Nuova Alba')
if not boat then warn('QV@ABORT no boat') return end
local barrel,lid
for _,m in ipairs(yard:GetChildren()) do
	if m.Name=='Oak barrel' and m:IsA('Model') then
		local c=m:GetBoundingBox()
		if c.X>270 then barrel=m end
	end
end
if not barrel then warn('QV@ABORT no east barrel') return end
lid=barrel:FindFirstChild('Barrel lid',true)
if not lid then warn('QV@ABORT no lid') return end
local top=lid.Position.Y+lid.Size.X/2
local L=Vector3.new(lid.Position.X,top,lid.Position.Z)
local bcf=boat:GetBoundingBox()
local side=(L-bcf.Position):Dot(bcf.RightVector)>0 and 1 or -1
local want=(-side*bcf.RightVector)*Vector3.new(1,0,1)
want=want.Unit
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
for i=1,2 do
	local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
-- feet clusters (Blender units, feet_probe): L x -0.69..-0.34 y -0.61..-0.27, R x 0.39..0.70 y -0.59..-0.18; centre (0.02,-0.43)
local fc=R:VectorToWorldSpace(Vector3.new(sx*0.02,0,sz*-0.43)*k)
local c=Vector3.new(L.X-fc.X,0,L.Z-fc.Z)
col:PivotTo(col:GetPivot()+Vector3.new(c.X-cm.Position.X,top+0.02-(cm.Position.Y-cm.Size.Y/2),c.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
local add='\t\t{id = "boatpainter_squirrel",  map = "porto", name = "Vito the Boat Painter",\n\t\t bio = "Gives the Nuova Alba a fresh coat every spring. His overalls have had more coats than the boat."},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Vito the Boat Painter')
-- report: runtime foot points (scaled about the mesh centre) and what they stand on
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,gry}
local feet={{-0.65,-0.58},{-0.38,-0.58},{-0.65,-0.3},{-0.38,-0.3},{0.42,-0.55},{0.68,-0.55},{0.42,-0.22},{0.68,-0.22}}
for _,f in ipairs(feet) do
	local w=cm.Position+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
	local q=workspace:Raycast(Vector3.new(w.X,top+1,w.Z),Vector3.new(0,-4,0),rp)
	warn(string.format('QV@FOOT %.2f,%.2f r=%.2f hit %s y %.2f',f[1],f[2],(Vector3.new(w.X,0,w.Z)-Vector3.new(L.X,0,L.Z)).Magnitude,q and q.Instance.Name or 'none',q and q.Position.Y or 0))
end
warn('QV@PLACED',cm.Position,'top',top,'want',want,'lid',L)
workspace.CurrentCamera.CFrame=CFrame.lookAt(L+want*4+Vector3.new(0,2.5,0)+want:Cross(Vector3.yAxis)*4,L+Vector3.new(0,1.6,0))
