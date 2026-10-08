-- Oct 4 2026 (Shannon's go): Rocco the Lifeguard (lifeguard_squirrel, Meshy "Lifeguard Squirrel", 7k tris) on her first
-- play-test spot on the sand point (260.76, -715.4), facing the water toward her second spot; his white lifeguard chair
-- beside him (his left, as in the preview) and the red SALVATAGGIO rowboat on her second spot (253.74, -726.55), bow to the
-- water, tilted to the grass. Registry after Tonio (bio A). No asserts after the first edit: warn + return.
local id='lifeguard_squirrel'
local col,gry=workspace:FindFirstChild(id..'_color'),workspace:FindFirstChild(id..'_gray')
local chair,boat=workspace:FindFirstChild('lifeguard_chair'),workspace:FindFirstChild('rescue_boat')
if not (col and gry and chair and boat) then warn('QL@ABORT missing import',col,gry,chair,boat) return end
local SPOT=Vector3.new(260.76,0,-715.4)
local BOATAT=Vector3.new(253.74,0,-726.55)
local WANT=((BOATAT-SPOT)*Vector3.new(1,0,1)).Unit                 -- Rocco looks toward the boat and the water beyond
local LEFT=-WANT:Cross(Vector3.yAxis)
local BOW=Vector3.new(-0.87,0,-0.5).Unit                           -- boat front toward the harbour water
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances={col,gry,chair,boat,workspace:FindFirstChild('SquirrelTwins')}
local function ground(p) local q=workspace:Raycast(Vector3.new(p.X,-30,p.Z),Vector3.new(0,-40,0),rp) return q and q.Position.Y, q and q.Instance end

-- ---------- Rocco (same placement code as Tonio)
local cm,gm=col.Squirrel,gry.Squirrel
local Bn={} for _,x in ipairs(col:GetDescendants()) do if x:IsA('Bone') then Bn[x.Name]=x end end
local rel=cm.CFrame:Inverse()*col:GetPivot() col:PivotTo(CFrame.new(cm.Position)*rel)
local function axes()
	local hl=cm.CFrame:PointToObjectSpace(Bn.Head.WorldPosition)
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
-- feet (feet_probe): L x -0.56..-0.23 y -0.45..-0.04, R x 0.10..0.37 y -0.53..-0.10; centre (-0.09,-0.28)
local feet={{-0.52,-0.40},{-0.27,-0.40},{-0.52,-0.08},{-0.27,-0.08},{0.13,-0.50},{0.34,-0.50},{0.13,-0.14},{0.34,-0.14}}
local k=3.4/cm.Size.Y
face(WANT)
local sz=axes()
local R=cm.CFrame-cm.Position
local fc=R:VectorToWorldSpace(Vector3.new(-0.09,0,sz*-0.28)*k)
local best
for dx=-0.3,0.3,0.1 do for dz=-0.3,0.3,0.1 do
	local c=SPOT+Vector3.new(dx,0,dz)
	local hi,lo,ok=-1e9,1e9,true
	for _,f in ipairs(feet) do
		local w=c-fc+R:VectorToWorldSpace(Vector3.new(f[1],0,sz*f[2])*k)
		local y=ground(w)
		if not y then ok=false break end
		hi=math.max(hi,y) lo=math.min(lo,y)
	end
	if ok then
		local score=(hi-lo)*10+math.abs(dx)+math.abs(dz)
		if not best or score<best.s then best={s=score,c=c,y=hi,spread=hi-lo} end
	end
end end
if not best then warn('QL@ABORT no ground for Rocco') return end
local L=Vector3.new(best.c.X,best.y,best.c.Z)
col:PivotTo(col:GetPivot()+Vector3.new(L.X-fc.X-cm.Position.X,L.Y+0.02-(cm.Position.Y-cm.Size.Y/2),L.Z-fc.Z-cm.Position.Z))
cm:SetAttribute('ColorTexture',cm.TextureID) cm:SetAttribute('GrayTexture',gm.TextureID)
local twins=workspace:FindFirstChild('SquirrelTwins')
if twins then gry.Parent=twins gry:PivotTo(gry:GetPivot()+Vector3.new(0,-400-gry:GetPivot().Y,0)) end
warn('QL@ROCCO feet centre',L,'spread',best.spread,'facing',R:VectorToWorldSpace(Vector3.new(0,0,-sz)))

-- ---------- props: colours, solid frame/hull, decorative bits not solid
local COL={Chair_Wood={0.94,0.93,0.89},Umbrella_Red={0.80,0.13,0.13},Umbrella_White={0.97,0.97,0.96},Umbrella_Pole={0.78,0.78,0.76},
	Buoy_Red={0.84,0.16,0.14},Buoy_White={0.97,0.97,0.96},Boat_Hull={0.78,0.11,0.11},Boat_Trim={0.97,0.97,0.96},
	Boat_Wood={0.62,0.45,0.28},Boat_Text={0.98,0.98,0.98}}
local SOLID={Chair_Wood=true,Boat_Hull=true}
local function dress(m)
	local n=0
	for _,p in ipairs(m:GetDescendants()) do
		if p:IsA('BasePart') then
			local key for name in pairs(COL) do if p.Name:find(name,1,true) then key=name end end
			if key then local c=COL[key] p.Color=Color3.new(c[1],c[2],c[3]) n+=1 end
			p.Material=Enum.Material.Plastic p.Anchored=true
			p.CanCollide=SOLID[key or '']==true p.CanTouch=false p.CastShadow=true
			if p:IsA('MeshPart') and p.TextureID~='' then p.TextureID='' end
		end
	end
	return n
end
local function part(m,name) for _,p in ipairs(m:GetDescendants()) do if p:IsA('BasePart') and p.Name:find(name,1,true) then return p end end end
local nc,nb=dress(chair),dress(boat)

-- chair: front = away from the umbrella pole (pole stands at the back of the seat)
local cw,pole=part(chair,'Chair_Wood'),part(chair,'Umbrella_Pole')
if not (cw and pole) then warn('QL@ABORT chair parts') return end
local cf0,size0=chair:GetBoundingBox()
local front=((cw.Position-pole.Position)*Vector3.new(1,0,1)).Unit
local ang=math.atan2(WANT.X,WANT.Z)-math.atan2(front.X,front.Z)
local c=CFrame.new(cw.Position)
chair:PivotTo(c*CFrame.Angles(0,ang,0)*c:Inverse()*chair:GetPivot())
local CH=SPOT+LEFT*2.6+WANT*0.3
local hs={} for _,o in ipairs({{1,1},{1,-1},{-1,1},{-1,-1}}) do local y=ground(CH+LEFT*o[1]*1.2+WANT*o[2]*1.2) if y then table.insert(hs,y) end end
if #hs<4 then warn('QL@ABORT chair ground') return end
local gy=(hs[1]+hs[2]+hs[3]+hs[4])/4
local bcf,bsz=chair:GetBoundingBox()
chair:PivotTo(chair:GetPivot()+Vector3.new(CH.X-cw.Position.X,(gy-0.15)-(bcf.Position.Y-bsz.Y/2),CH.Z-cw.Position.Z))
warn('QL@CHAIR at',CH,'ground',gy,'spread',math.max(unpack(hs))-math.min(unpack(hs)),'coloured',nc)

-- boat: long axis of the hull, bow = from the lettering's centre toward the hull's centre (letters sit sternward)
local hull,text=part(boat,'Boat_Hull'),part(boat,'Boat_Text')
if not (hull and text) then warn('QL@ABORT boat parts') return end
local hcf=hull.CFrame
local ax=hcf.RightVector local sx=hull.Size.X
if hull.Size.Z>sx then ax=hcf.LookVector sx=hull.Size.Z end
ax=(ax*Vector3.new(1,0,1)).Unit
if (hull.Position-text.Position):Dot(ax)<0 then ax=-ax end
local a2=math.atan2(BOW.X,BOW.Z)-math.atan2(ax.X,ax.Z)
local hc=CFrame.new(hull.Position)
boat:PivotTo(hc*CFrame.Angles(0,a2,0)*hc:Inverse()*boat:GetPivot())
-- tilt to the ground: heights under bow/stern and both sides
local side=BOW:Cross(Vector3.yAxis).Unit
local yb,ys=ground(BOATAT+BOW*2.6),ground(BOATAT-BOW*2.6)
local yp,yq=ground(BOATAT+side*1.0),ground(BOATAT-side*1.0)
local y0=ground(BOATAT)
if not (yb and ys and yp and yq and y0) then warn('QL@ABORT boat ground') return end
local pitch=math.atan2(yb-ys,5.2) local roll=math.atan2(yp-yq,2.0)
pitch=math.clamp(pitch,-0.25,0.25) roll=math.clamp(roll,-0.2,0.2)
hc=CFrame.new(hull.Position)
local tilt=CFrame.fromAxisAngle(side,pitch)*CFrame.fromAxisAngle(BOW,-roll)   -- +pitch about BOWxY lifts the bow; ground higher on +side -> lift +side
boat:PivotTo(hc*tilt*hc:Inverse()*boat:GetPivot())
local gmid=(yb+ys+yp+yq+y0)/5
local hcf2,hsz=hull.CFrame,hull.Size
-- lowest hull point after the tilt: check the 8 box corners
local low=1e9 for _,sx2 in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz2 in ipairs({-1,1}) do
	low=math.min(low,(hcf2*CFrame.new(hsz.X/2*sx2,hsz.Y/2*sy,hsz.Z/2*sz2)).Position.Y) end end end
boat:PivotTo(boat:GetPivot()+Vector3.new(BOATAT.X-hull.Position.X,(gmid-0.18)-low,BOATAT.Z-hull.Position.Z))
warn('QL@BOAT at',BOATAT,'ground',y0,'pitch',math.deg(pitch),'roll',math.deg(roll),'bow',BOW,'coloured',nb)

-- keep the props together under PortoNocciola
local post=Instance.new('Model') post.Name='Lifeguard Post' post:SetAttribute('Built','Oct 4 2026 Rocco the Lifeguard')
post.Parent=workspace:FindFirstChild('PortoNocciola') or workspace
chair.Name='Lifeguard Chair' chair.Parent=post boat.Name='Rescue Boat SALVATAGGIO' boat.Parent=post
game:GetService('ChangeHistoryService'):SetWaypoint('Rocco the Lifeguard + chair + boat')

local cam=workspace.CurrentCamera
local mid=(L+BOATAT*Vector3.new(1,0,1)+Vector3.new(0,L.Y,0))/2+Vector3.new(0,2,0)
cam.Focus=CFrame.new(mid)
cam.CFrame=CFrame.lookAt(BOATAT+Vector3.new(0,L.Y,0)+WANT*9+side*5+Vector3.new(0,6,0),mid)

-- registry: Rocco the Lifeguard (bio A, Shannon's pick), after Tonio
local reg=workspace.SquirrelScripts.SquirrelRegistry
local rs=reg.Source
local a,b=rs:find('the funicolare is free."},\n',1,true)
if not a or rs:find('lifeguard_squirrel',1,true) then warn('QL@REG_SKIP anchor/dup',a) return end
local add='\t\t{id = "lifeguard_squirrel",    map = "porto", name = "Rocco the Lifeguard",\n\t\t bio = "Has blown his whistle at every single wave this summer. Not one of them has listened."},\n'
reg.Source=rs:sub(1,b)..add..rs:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Rocco registry')
local n=0 for _ in reg.Source:gmatch('map = "porto"') do n+=1 end
local t=0 for _ in reg.Source:gmatch('{id = ') do t+=1 end
warn('QL@REG porto entries',n,'total',t,'rocco',reg.Source:find('Rocco the Lifeguard',1,true)~=nil)
