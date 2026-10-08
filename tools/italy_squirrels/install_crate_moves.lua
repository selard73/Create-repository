-- Oct 4 2026 (Shannon): a wooden fish crate for Beppe beside the PESCE FRESCO stand (up to the level of the fish),
-- and Nonno Reti moved to the far net drying rack. Re-runnable (replaces BeppeCrate).
local CH=game:GetService('ChangeHistoryService')
local market=workspace.PortoNocciola:FindFirstChild('03 Fish market') assert(market,'market')
local old=market:FindFirstChild('BeppeCrate') if old then old:Destroy() end
local C=Color3.fromRGB
local SPOT=Vector3.new(245.2,0,-645)
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances={workspace.ComingSoonWall,workspace.fishmonger_squirrel_color,workspace.netmender_squirrel_color}
local g=workspace:Raycast(SPOT+Vector3.new(0,-38,0),Vector3.new(0,-30,0),rp) assert(g,'ground')
local Y0=g.Position.Y
-- the crate: 2.6 x 2.0 x 2.6, slatted sides with gaps, darker corner posts, a lid of four boards, a faded stencil
local W,H,D=2.6,2.0,2.6
local m=Instance.new('Model') m.Name='BeppeCrate'
local base=CFrame.new(SPOT.X,Y0,SPOT.Z)
local function part(name,size,cf,col,mat)
	local p=Instance.new('Part') p.Name=name p.Anchored=true p.Size=size p.CFrame=base*cf p.Color=col
	p.Material=mat or Enum.Material.WoodPlanks p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=m return p
end
local POST,SLAT,SLAT2,LID=C(112,78,48),C(184,148,104),C(170,134,92),C(194,160,116)
for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
	part('Post',Vector3.new(0.26,H-0.16,0.26),CFrame.new(sx*(W/2-0.13),(H-0.16)/2,sz*(D/2-0.13)),POST,Enum.Material.Wood)
end end
local slatH,gap=0.5,0.12
for i=0,2 do
	local y=0.08+slatH/2+i*(slatH+gap)
	local col=(i%2==0) and SLAT or SLAT2
	part('SlatFront',Vector3.new(W-0.04,slatH,0.1),CFrame.new(0,y,D/2-0.05),col)
	part('SlatBack',Vector3.new(W-0.04,slatH,0.1),CFrame.new(0,y,-D/2+0.05),col)
	part('SlatLeft',Vector3.new(0.1,slatH,D-0.24),CFrame.new(-W/2+0.05,y,0),col)
	part('SlatRight',Vector3.new(0.1,slatH,D-0.24),CFrame.new(W/2-0.05,y,0),col)
end
part('Floor',Vector3.new(W-0.2,0.08,D-0.2),CFrame.new(0,0.04,0),SLAT2)
local lidW=(D-0.09)/4
for i=0,3 do
	local z=-D/2+lidW/2+i*(lidW+0.03)
	part('Lid',Vector3.new(W,0.14,lidW),CFrame.new(0,H-0.07,z),(i%2==0) and LID or SLAT)
end
-- rope handles on the sides
for _,sx in ipairs({-1,1}) do
	local r=part('RopeHandle',Vector3.new(0.08,0.08,0.7),CFrame.new(sx*(W/2+0.03),H*0.62,0),C(205,180,130),Enum.Material.Fabric)
end
-- faded stencil on the front (faces the quay)
local front=m:FindFirstChild('SlatFront')
local tag=part('Stencil',Vector3.new(W-0.3,1.1,0.02),CFrame.new(0,0.95,D/2+0.005),SLAT) tag.Transparency=1 tag.CanCollide=false tag.CanQuery=false
local sg=Instance.new('SurfaceGui') sg.Face=Enum.NormalId.Back sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud=50 sg.LightInfluence=1 sg.Parent=tag
local t=Instance.new('TextLabel') t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Text='PESCE\nPORTO NOCCIOLA' t.TextScaled=true
t.Font=Enum.Font.Antique t.TextColor3=C(44,74,110) t.TextTransparency=0.35 t.Parent=sg
m.Parent=market
local top=Y0+H
-- placing a squirrel: upright, face a point, feet down on the given surface (feet checked at game size, 3.4 tall)
local function place(id,spot,look,feet,onCrate)
	local col=workspace[id..'_color'] local cm=col.Squirrel
	local Bn={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then Bn[d.Name]=d end end
	local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
	local want=(look-spot)*Vector3.new(1,0,1)
	for i=1,2 do
		local face=(Bn.Head.WorldPosition-cm.Position)*Vector3.new(1,0,1)
		local a=math.atan2(want.X,want.Z)-math.atan2(face.X,face.Z)
		local c=CFrame.new(cm.Position) col:PivotTo(c*CFrame.Angles(0,a,0)*c:Inverse()*col:GetPivot())
	end
	local gp=RaycastParams.new() gp.FilterType=Enum.RaycastFilterType.Exclude gp.FilterDescendantsInstances={col,workspace.ComingSoonWall}
	local h=workspace:Raycast(spot+Vector3.new(0,(onCrate and top or Y0)+8,0)-Vector3.new(0,spot.Y,0),Vector3.new(0,-30,0),gp) assert(h,'surface '..id)
	col:PivotTo(col:GetPivot()+Vector3.new(spot.X-cm.Position.X,h.Position.Y+0.02-(cm.Position.Y-cm.Size.Y/2),spot.Z-cm.Position.Z))
	local hl=cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition) local tl=cm.CFrame:PointToObjectSpace(Bn.Tail1.WorldPosition)
	local sz,sx,k=hl.Z<0 and 1 or -1,tl.X<0 and 1 or -1,3.4/cm.Size.Y
	local R=cm.CFrame-cm.Position local bottom=cm.Position.Y-cm.Size.Y/2 local out=''
	for _,f in ipairs(feet) do
		local w=Vector3.new(cm.Position.X,0,cm.Position.Z)+R:VectorToWorldSpace(Vector3.new(sx*f[1],0,sz*f[2])*k)
		local q=workspace:Raycast(Vector3.new(w.X,bottom+3,w.Z),Vector3.new(0,-10,0),gp)
		out=out..string.format(' %.2f%s',q and (bottom-q.Position.Y) or 99,q and q.Instance.Name:sub(1,4) or '')
	end
	print('PLACED2',id,'on',h.Instance.Name,'bottom',string.format('%.2f',bottom),'feet',out)
end
place('fishmonger_squirrel',Vector3.new(245.2,0,-645),Vector3.new(238,0,-620),{{-0.85,-0.82},{0.32,-0.82},{-0.85,0.45},{0.32,0.45}},true)
place('netmender_squirrel',Vector3.new(242.6,0,-691.6),Vector3.new(252,0,-684),{{-0.82,-1.48},{0.59,-1.48},{-0.82,0.31},{0.59,0.31}},false)
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={m,workspace.fishmonger_squirrel_color}
local hits=workspace:GetPartBoundsInBox(base*CFrame.new(0,H/2+0.05,0),Vector3.new(W,H-0.2,D),op)
local s='' for i=1,math.min(#hits,5) do s=s..hits[i].Name..' ' end
print('CRATE top',string.format('%.2f',top),'overlaps',#hits,s)
CH:SetWaypoint('Beppe crate + Nonno Reti at the far net rack')
