-- Oct 4 2026 (Shannon): Beppe's crate a little smaller and right of the fish stand; a few storage crates in the alley
-- between the Gelateria al Limone and Casa Azzurra. Re-runnable (replaces BeppeCrate and AlleyCrates).
local market=workspace.PortoNocciola['03 Fish market']
for _,n in ipairs({'BeppeCrate','AlleyCrates'}) do local o=market:FindFirstChild(n) if o then o:Destroy() end end
local C=Color3.fromRGB
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances={workspace.ComingSoonWall,workspace.fishmonger_squirrel_color,workspace.netmender_squirrel_color}
local function groundAt(x,z) local g=workspace:Raycast(Vector3.new(x,-38,z),Vector3.new(0,-30,0),rp) assert(g,'ground '..x..','..z) return g.Position.Y end
local POST,SLAT,SLAT2,LID=C(112,78,48),C(184,148,104),C(170,134,92),C(194,160,116)
-- one crate: W x H x D, its bottom centre at cf; stencil text faces local +Z
local function crate(parent,name,W,H,D,cf,text,tint)
	local m=Instance.new('Model') m.Name=name
	local function part(n,size,c,col,mat)
		local p=Instance.new('Part') p.Name=n p.Anchored=true p.Size=size p.CFrame=cf*c p.Color=col
		p.Material=mat or Enum.Material.WoodPlanks p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=m return p
	end
	local s1,s2,lid=tint and SLAT2 or SLAT,tint and C(158,124,86) or SLAT2,tint and SLAT or LID
	for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
		part('Post',Vector3.new(0.22,H-0.14,0.22),CFrame.new(sx*(W/2-0.11),(H-0.14)/2,sz*(D/2-0.11)),POST,Enum.Material.Wood)
	end end
	local n=3 local gap=0.1 local sh=(H-0.14-0.06-gap*(n-1))/n
	for i=0,n-1 do
		local y=0.06+sh/2+i*(sh+gap) local col=(i%2==0) and s1 or s2
		part('SlatFront',Vector3.new(W-0.04,sh,0.09),CFrame.new(0,y,D/2-0.045),col)
		part('SlatBack',Vector3.new(W-0.04,sh,0.09),CFrame.new(0,y,-D/2+0.045),col)
		part('SlatLeft',Vector3.new(0.09,sh,D-0.2),CFrame.new(-W/2+0.045,y,0),col)
		part('SlatRight',Vector3.new(0.09,sh,D-0.2),CFrame.new(W/2-0.045,y,0),col)
	end
	part('Floor',Vector3.new(W-0.18,0.06,D-0.18),CFrame.new(0,0.03,0),s2)
	local lw=D/4
	for i=0,3 do part('Lid',Vector3.new(W,0.14,lw-0.01),CFrame.new(0,H-0.07,-D/2+lw/2+i*lw),(i%2==0) and lid or s1) end
	for _,sx in ipairs({-1,1}) do part('RopeHandle',Vector3.new(0.07,0.07,0.6),CFrame.new(sx*(W/2+0.03),H*0.62,0),C(205,180,130),Enum.Material.Fabric) end
	if text then
		local t=part('Stencil',Vector3.new(W-0.3,H*0.55,0.02),CFrame.new(0,H*0.48,D/2+0.005),s1) t.Transparency=1 t.CanCollide=false t.CanQuery=false
		local sg=Instance.new('SurfaceGui') sg.Face=Enum.NormalId.Back sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud=50 sg.LightInfluence=1 sg.Parent=t
		local l=Instance.new('TextLabel') l.BackgroundTransparency=1 l.Size=UDim2.fromScale(1,1) l.Text=text l.TextScaled=true
		l.Font=Enum.Font.Antique l.TextColor3=C(44,74,110) l.TextTransparency=0.35 l.Parent=sg
	end
	m.Parent=parent return m
end
-- Beppe's crate: right end of the stand (counter ends at x 259), 2.1 x 1.7 x 2.1, stencil toward the quay
local bx,bz=260.3,-645
local by=groundAt(bx,bz)
local bc=crate(market,'BeppeCrate',2.1,1.7,2.1,CFrame.new(bx,by,bz),'PESCE\nPORTO NOCCIOLA')
local top=by+1.7
-- storage crates in the alley (x 264..282, z -637..-643), against the Casa Azzurra side, leaving the lane walkable
local al=Instance.new('Folder') al.Name='AlleyCrates' al.Parent=market
local function put(name,x,z,W,H,D,rot,text,tint,stackOn)
	local y=stackOn and stackOn or groundAt(x,z)
	return crate(al,name,W,H,D,CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(rot),0),text,tint)
end
put('Crate1',267.6,-641.9,2.2,1.8,2.2,4,'LIMONI',false)
local y2=groundAt(267.6,-641.9)+1.8
put('Crate2',267.7,-641.8,1.9,1.5,1.9,-11,nil,true,y2)
put('Crate3',270.3,-642.0,2.0,1.6,2.0,-6,'OLIO',true)
put('Crate4',277.4,-641.7,2.3,1.9,2.3,9,'PESCE',false)
-- Beppe onto his crate, feet centred on the lid, facing the quay
local col=workspace.fishmonger_squirrel_color local cm=col.Squirrel
local Bn={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then Bn[d.Name]=d end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local look=Vector3.new(250,0,-630) local want=(look-Vector3.new(bx,0,bz))*Vector3.new(1,0,1)
for i=1,2 do
	local face=(Bn.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
	local a=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
	local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,a,0)*c:Inverse()*col:GetPivot())
end
local hl=cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(Bn.Tail1.WorldPosition)
local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local fc=R:VectorToWorldSpace(Vector3.new(sx*(-0.265),0,sz*(-0.185))*k)
col:PivotTo(col:GetPivot()+Vector3.new(bx-fc.X-cm.Position.X,top+0.02-(cm.Position.Y-cm.Size.Y/2),bz-fc.Z-cm.Position.Z))
local gp=RaycastParams.new() gp.FilterType=Enum.RaycastFilterType.Include gp.FilterDescendantsInstances={bc}
local bottom=cm.Position.Y-cm.Size.Y/2 local out=''
for _,f in ipairs({{-0.85,-0.82},{0.32,-0.82},{-0.85,0.45},{0.32,0.45}}) do
	local w=Vector3.new(cm.Position.X,0,cm.Position.Z)+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
	local q=workspace:Raycast(Vector3.new(w.X,bottom+3,w.Z),Vector3.new(0,-10,0),gp)
	out=out..string.format(' %.2f%s',q and (bottom-q.Position.Y) or 99,q and q.Instance.Name:sub(1,4) or '')
end
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={al,bc,col}
local ov='' for _,m in ipairs(al:GetChildren()) do local cf,s=m:GetBoundingBox() ov=ov..m.Name..'='..#workspace:GetPartBoundsInBox(cf,s*0.92,op)..' ' end
local cf,s=bc:GetBoundingBox() ov=ov..'Beppe='..#workspace:GetPartBoundsInBox(cf,s*0.92,op)
game:GetService('ChangeHistoryService'):SetWaypoint('Crates v2: Beppe right of the stand + alley storage')
warn('CRATES_V2 top',string.format('%.2f',top),'feet',out,'overlaps',ov)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(252,-42,-634),Vector3.new(261,-44.5,-645))
