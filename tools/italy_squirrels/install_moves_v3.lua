-- Oct 4 2026 (Shannon's circled screenshots): Nonno Reti between the oak barrel and the Bottega del Pescatore corner;
-- Gino on the floor of the rowboat Stella Marina between the bow seat and the middle seat. Searches small offsets and
-- turns around each spot and keeps the one where every foot point (at game size 3.4) lands on the target surface.
local function bones(col) local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end return B end
local function best(id,centre,look,spread,radius,feet,surfaceMax,surfaceMin,include)
	local col=workspace[id..'_color'] local cm=col.Squirrel local B=bones(col)
	local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
	local gp=RaycastParams.new()
	if include then gp.FilterType=Enum.RaycastFilterType.Include gp.FilterDescendantsInstances=include
	else gp.FilterType=Enum.RaycastFilterType.Exclude gp.FilterDescendantsInstances={col,workspace.ComingSoonWall} end
	local base=math.atan2((look-centre).X,(look-centre).Z)
	local top
	for _,da in ipairs(spread) do
		local want=base+math.rad(da)
		for i=1,2 do
			local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
			local a=want-math.atan2(face.X,face.Z)
			local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,a,0)*c:Inverse()*col:GetPivot())
		end
		local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(B.Tail1.WorldPosition)
		local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
		local R=cm.CFrame-cm.Position
		for dx=-radius,radius+1e-6,0.2 do for dz=-radius,radius+1e-6,0.2 do
			local c=centre+Vector3.new(dx,0,dz)
			local hs={} local ok=true local hi=-1e9
			for _,f in ipairs(feet) do
				local w=c+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
				local q=workspace:Raycast(Vector3.new(w.X,surfaceMax+4,w.Z),Vector3.new(0,-14,0),gp)
				if not q or q.Position.Y>surfaceMax or q.Position.Y<surfaceMin then ok=false break end
				hi=math.max(hi,q.Position.Y) table.insert(hs,q.Position.Y)
			end
			if ok then
				local spreadY=0 for _,y in ipairs(hs) do spreadY=math.max(spreadY,hi-y) end
				local score=math.abs(da)*0.02+math.sqrt(dx*dx+dz*dz)+spreadY*5
				if not top or score<top.score then top={score=score,da=da,c=c,y=hi,spreadY=spreadY} end
			end
		end end
	end
	assert(top,'no planted spot for '..id)
	local want=base+math.rad(top.da)
	for i=1,2 do
		local face=(B.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
		local a=want-math.atan2(face.X,face.Z)
		local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,a,0)*c:Inverse()*col:GetPivot())
	end
	col:PivotTo(col:GetPivot()+Vector3.new(top.c.X-cm.Position.X,top.y+0.02-(cm.Position.Y-cm.Size.Y/2),top.c.Z-cm.Position.Z))
	warn('MOVED',id,string.format('at (%.2f,%.2f,%.2f) turn %d feet spread %.2f',cm.Position.X,top.y,cm.Position.Z,top.da,top.spreadY))
end
local st=workspace.PortoNocciola:FindFirstChild('Stella Marina',true) assert(st,'Stella Marina')
best('netmender_squirrel',Vector3.new(262.4,0,-691.6),Vector3.new(250,0,-684),{0,-15,15,-30,30},0.8,
	{{-0.82,-1.48},{0.59,-1.48},{-0.82,0.31},{0.59,0.31}},-46.3,-47.2,nil)
best('deckhand_squirrel',Vector3.new(222.75,0,-646.2),Vector3.new(222.75,0,-630),{0,180,-20,20,160,200,90,-90,70,-70,110,-110},0.6,
	{{-0.52,-0.74},{-0.21,-0.46},{0.72,-0.50},{1.0,-0.19},{-0.52,-0.46},{1.0,-0.50},{-0.52,-0.6},{1.0,-0.35}},-52.3,-52.8,{st})
game:GetService('ChangeHistoryService'):SetWaypoint('Nonno by the Bottega barrel, Gino in the Stella Marina')
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(229,-45,-640),Vector3.new(222.8,-51,-646))
