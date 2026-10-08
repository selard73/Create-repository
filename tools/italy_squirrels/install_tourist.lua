-- Oct 4 2026: Penny the Tourist (italytourist_squirrel) on the causeway's south landing, west side, facing NW over the beach to the boatyard.
-- No asserts after the first edit (a failing command-bar module rolls everything back): warn + return instead.
local id='italytourist_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QT@ABORT missing import') return end
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local anchor='have to stand on the roof."},\n'
local a,b=rs:find(anchor,1,true)
if not a or rs:find(id,1,true) then warn('QT@ABORT registry anchor/dup') return end
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local want=Vector3.new(-0.7,0,0.7).Unit
for i=1,2 do
	local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={col,gry,workspace:FindFirstChild('ComingSoonWall'),workspace:FindFirstChild('SquirrelTwins')}
-- feet (Blender units, feet_probe): A x -0.07..0.30 y -0.80..-0.26, B x 0.29..0.86 y -0.13..0.16; plus the runtime footprint corners
local feet={{0,-0.7},{0.25,-0.7},{0,-0.35},{0.25,-0.35},{0.35,0.05},{0.8,0.05},{0.6,-0.1},{0.8,0.12}}
local hs=cm.Size*k/2
local corners={{-1,-1},{1,-1},{-1,1},{1,1}}
local function check(c)
	local bad=0
	for _,f in ipairs(feet) do
		local w=c+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-12,0),rp)
		if not q or q.Instance==workspace.Terrain or math.abs(q.Position.Y+46.8)>0.15 then bad+=1 end
	end
	for _,s in ipairs(corners) do
		local w=c+R:VectorToWorldSpace(Vector3.new(s[1]*hs.X,0,s[2]*hs.Z))
		local q=workspace:Raycast(Vector3.new(w.X,-40,w.Z),Vector3.new(0,-12,0),rp)
		if not q or q.Instance==workspace.Terrain or math.abs(q.Position.Y+46.8)>0.15 then bad+=1 end
	end
	return bad
end
local P
for dx=0,4,0.5 do
	local c=Vector3.new(304.5+dx,0,-757)
	local n=check(c)
	warn('QT@TRY',c,'bad',n)
	if n==0 then P=c break end
end
if not P then warn('QT@ABORT no clean spot on the landing') return end
local g=workspace:Raycast(Vector3.new(P.X,-40,P.Z),Vector3.new(0,-12,0),rp)
if not g then warn('QT@ABORT no ground') return end
local gy=g.Position.Y
col:PivotTo(col:GetPivot()+Vector3.new(P.X-cm.Position.X,gy+0.02-(cm.Position.Y-cm.Size.Y/2),P.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
local add='\t\t{id = "italytourist_squirrel", map = "porto", name = "Penny the Tourist",\n\t\t bio = "A red squirrel from Savannah, Georgia, who won the trip in a pecan-pie contest. Lemon sundress, sunflower hat, red sunglasses, camera on a strap. She has learned one word of Italian, ciao, and uses it for hello, goodbye, thank you and \'is this seat taken?\'"},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Penny the Tourist')
warn('QT@PLACED',cm.Position,'ground',gy,g.Instance:GetFullName())
local cam=workspace.CurrentCamera
local t=Vector3.new(P.X,gy+1.6,P.Z)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+want*5+Vector3.new(0,1,0),t)
