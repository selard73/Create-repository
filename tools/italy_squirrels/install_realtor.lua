-- Oct 4 2026: Signora Chiave (realtor) on the paving in front of Casa Salvia, between the right-hand door jamb and the alley corner,
-- facing the street, turned ~20 deg toward the door (keys paw on the door side).
-- No asserts after the first edit (a failing command-bar module rolls everything back): warn + return instead.
local id='realtor_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QW@ABORT missing import') return end
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local anchor='more coats than the boat."},\n'
local a,b=rs:find(anchor,1,true)
if not a or rs:find(id,1,true) then warn('QW@ABORT registry anchor/dup') return end
local house=workspace.PortoNocciola['02 Pastel waterfront']:FindFirstChild('Casa Salvia')
if not house then warn('QW@ABORT no Casa Salvia') return end
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local want=Vector3.new(-0.94,0,-0.34).Unit
for i=1,2 do
	local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
-- runtime half-extent along world X (box of the scaled mesh)
local hx=0
for _,v in ipairs({R.RightVector*cm.Size.X,R.UpVector*cm.Size.Y,R.LookVector*cm.Size.Z}) do hx+=math.abs(v.X)*k/2 end
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,gry,workspace.ComingSoonWall}
local P=Vector3.new(298.2,0,-668.8)
local wall=workspace:Raycast(Vector3.new(P.X-3,-45.3,P.Z),Vector3.new(8,0,0),rp)
if wall then
	local maxX=wall.Position.X-hx-0.15
	if P.X>maxX then P=Vector3.new(maxX,0,P.Z) end
	warn('QW@WALL x',wall.Position.X,wall.Instance:GetFullName(),'hx',hx)
end
local g=workspace:Raycast(Vector3.new(P.X,-40,P.Z),Vector3.new(0,-12,0),rp)
if not g then warn('QW@ABORT no ground') return end
local gy=g.Position.Y
col:PivotTo(col:GetPivot()+Vector3.new(P.X-cm.Position.X,gy+0.02-(cm.Position.Y-cm.Size.Y/2),P.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
local add='\t\t{id = "realtor_squirrel",      map = "porto", name = "Signora Chiave",\n\t\t bio = "Every house she sells has a sea view. For some of them you have to stand on the roof."},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Signora Chiave')
-- feet (Blender units, feet_probe): L x -0.17..0.31 y -0.27..0.37, R x 0.32..0.78 y -0.57..-0.22; runtime positions
local feet={{-0.1,-0.2},{0.25,-0.2},{-0.1,0.3},{0.25,0.3},{0.38,-0.52},{0.72,-0.52},{0.38,-0.27},{0.72,-0.27}}
for _,f in ipairs(feet) do
	local w=cm.Position+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
	local q=workspace:Raycast(Vector3.new(w.X,gy+1.5,w.Z),Vector3.new(0,-3,0),rp)
	warn(string.format('QW@FOOT %.2f,%.2f hit %s y %.2f',f[1],f[2],q and q.Instance.Name or 'none',q and q.Position.Y or 0))
end
warn('QW@PLACED',cm.Position,'ground',gy,'P',P)
local cam=workspace.CurrentCamera
local t=Vector3.new(P.X,gy+1.6,P.Z)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+Vector3.new(-8,2.5,-3),t)
