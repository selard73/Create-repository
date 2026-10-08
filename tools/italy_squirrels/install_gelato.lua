-- Oct 4 2026: Giulia the Gelato Squirrel inside Gelateria al Limone, behind the right-hand display window, facing out.
-- No asserts after the first edit (a failing command-bar module rolls everything back): warn + return instead.
local id='gelato_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
if not (col and gry) then warn('QN@ABORT missing import') return end
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local anchor='The fishermen say it was Beppe."},\n'
local a,b=rs:find(anchor,1,true)
if not a or rs:find(id,1,true) then warn('QN@ABORT registry anchor/dup') return end
local gel=workspace.PortoNocciola['02 Pastel waterfront']:FindFirstChild('Gelateria al Limone')
if not gel then warn('QN@ABORT no gelateria') return end
-- the right-hand display window (as seen from the quay, i.e. the more southern one: smaller z)
local wins={}
for _,d in ipairs(gel:GetDescendants()) do if d:IsA('Model') and d.Name:find('glazed display window') then local c=d:GetBoundingBox() table.insert(wins,{d,c.Position}) end end
if #wins==0 then warn('QN@ABORT no windows') return end
table.sort(wins,function(p,q) return p[2].Z<q[2].Z end)
local win=wins[1][2]
warn('QN@WINDOWS',#wins,'chosen',wins[1][1].Name,win)
local cm,gm=col.Squirrel,gry.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local look=Vector3.new(win.X-20,0,win.Z)
local function turn(want)
	for i=1,2 do
		local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
		local ang=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
		local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*col:GetPivot())
	end
end
turn(Vector3.new(-1,0,0))
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local feet={{-0.55,-0.75},{-0.2,-0.75},{-0.55,-0.4},{-0.2,-0.4},{0.6,-0.6},{0.95,-0.6},{0.6,-0.3},{0.95,-0.3}}
local gp=RaycastParams.new() gp.FilterType=Enum.RaycastFilterType.Exclude gp.FilterDescendantsInstances={col,gry,workspace.ComingSoonWall}
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={col,gry,workspace.ComingSoonWall}
local best
for dx=1.6,5.0,0.2 do for dz=-1.6,1.6,0.2 do
	local c=Vector3.new(win.X+dx,0,win.Z+dz)
	local f0=workspace:Raycast(Vector3.new(c.X,win.Y+1,c.Z),Vector3.new(0,-8,0),gp)
	if f0 then
		local ok,hi,lo=true,-1e9,1e9
		for _,f in ipairs(feet) do
			local w=c+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
			local q=workspace:Raycast(Vector3.new(w.X,f0.Position.Y+1.5,w.Z),Vector3.new(0,-3,0),gp)
			if not q then ok=false break end hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y)
		end
		if ok and hi-lo<0.08 then
			local body=workspace:GetPartBoundsInBox(CFrame.new(c.X,hi+1.9,c.Z),Vector3.new(2.6,3.0,2.6),op)
			if #body==0 then
				local score=math.abs(dz)*2+math.abs(dx-2.4)
				if not best or score<best.s then best={s=score,c=c,y=hi} end
			end
		end
	end
end end
if not best then warn('QN@ABORT no clear planted spot behind the window') return end
col:PivotTo(col:GetPivot()+Vector3.new(best.c.X-cm.Position.X,best.y+0.02-(cm.Position.Y-cm.Size.Y/2),best.c.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
local add='\t\t{id = "gelato_squirrel",      map = "porto", name = "Giulia the Gelato Squirrel",\n\t\t bio = "Names a new flavour every morning after the first customer through the door. Today\'s special is Lemon Surprise, named after a very sour-faced tourist."},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Giulia the Gelato Squirrel')
warn('QN@PLACED',cm.Position,'floor',best.y)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(win.X-9,win.Y+1,win.Z+1),Vector3.new(best.c.X,best.y+1.5,best.c.Z))
