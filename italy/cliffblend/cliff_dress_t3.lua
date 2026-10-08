-- ct3 Oct 4 2026 (cliff blend, step 3): (A) a grassy lip of terrain on top of the SouthCliff piece, set back ~2 studs
-- from its front edge, so the dead-straight top line breaks up (the falls/river gap x 163..207 is left alone);
-- (B) kit trees (cypress, olive, squat pine - no round bushes) along the crest and the new limestone shoulders, plus a few
-- olives at the foot of the west join; (C) limestone-tinted boulders at the foot of the west join.
-- New trees/boulders go in workspace.SouthGorge.CliffBlendDress (delete that folder to undo B+C; the terrain lip is in
-- ServerStorage.CliffBlendBackup3).
local T=workspace.Terrain
local SS=game:GetService('ServerStorage')
local G=workspace.SouthGorge local rock=G.Rock
local GRASS=Enum.Material.Grass local WATER=Enum.Material.Water
local function n1(x) return math.sin(x*0.071)*0.6+math.sin(x*0.193+1.3)*0.4 end
-- ---------- (A) crest lip
local rpM=RaycastParams.new() rpM.FilterType=Enum.RaycastFilterType.Include
local ups={} for _,p in ipairs(rock:GetChildren()) do if p:IsA('BasePart') and p.Name:find('^SouthCliff_') and not p.Name:find('_Lo') then table.insert(ups,p) end end
rpM.FilterDescendantsInstances=ups
local R=Region3.new(Vector3.new(52,24,-604),Vector3.new(324,64,-528)):ExpandToGrid(4)
if not SS:FindFirstChild('CliffBlendBackup3') then
	local mn=R.CFrame.Position-R.Size/2 local mx=R.CFrame.Position+R.Size/2
	local tr=T:CopyRegion(Region3int16.new(Vector3int16.new(mn.X/4,mn.Y/4,mn.Z/4),Vector3int16.new(mx.X/4-1,mx.Y/4-1,mx.Z/4-1)))
	tr.Name='CliffBlendBackup3' tr:SetAttribute('Corner',mn) tr.Parent=SS
end
local mat,occ=T:ReadVoxels(R,4)
local x0=R.CFrame.Position.X-R.Size.X/2 local y0=R.CFrame.Position.Y-R.Size.Y/2 local z0=R.CFrame.Position.Z-R.Size.Z/2
local crest={} local lipCells=0
for i=1,mat.Size.X do
	local x=x0+(i-0.5)*4
	if x<163 or x>207 then
		local zf,yt
		for z=-602,-532,2 do
			local h=workspace:Raycast(Vector3.new(x,90,z),Vector3.new(0,-80,0),rpM)
			if h and h.Position.Y>30 then zf=z yt=h.Position.Y break end
		end
		if zf then
			table.insert(crest,{x=x,z=zf,y=yt})
			for k=1,mat.Size.Z do
				local z=z0+(k-0.5)*4
				local back=z-zf
				if back>=2 and back<=18 then
					local t=(back-2)/16
					local bump=(1.0+2.2*(0.5+0.5*n1(x*1.31+z*0.7)))*(1-t*t)
					local S=yt+bump
					for j=1,mat.Size.Y do
						local yb=y0+(j-1)*4
						if yb>=yt-4 and yb<S and mat[i][j][k]~=WATER then
							local o=math.clamp((S-yb)/4,0,1)
							if o>occ[i][j][k] then occ[i][j][k]=o mat[i][j][k]=GRASS lipCells+=1 end
						end
					end
				end
			end
		end
	end
end
T:WriteVoxels(R,4,mat,occ)
-- ---------- (B) trees  (C) boulders
local C=Color3.fromRGB
local KITS={pine_squat='ForestKit',pine_tall='ForestKit',olive_tree='DomaineKit',cypress='DomaineKit',rock_big='ForestKit',rock_cluster='ForestKit'}
local COLOURS={pine_squat={Foliage=C(72,120,74),Trunk=C(104,78,56)},pine_tall={Foliage=C(72,120,74),Trunk=C(104,78,56)},
	olive_tree={Olive=C(152,170,132),OTrunk=C(108,88,66)},cypress={Cypress=C(54,88,58),OTrunk=C(108,88,66)}}
local old=G:FindFirstChild('CliffBlendDress') if old then old:Destroy() end
local DF=Instance.new('Folder') DF.Name='CliffBlendDress' DF.Parent=G
local tp=RaycastParams.new() tp.FilterType=Enum.RaycastFilterType.Include tp.FilterDescendantsInstances={T} tp.IgnoreWater=false
local function aabb(m)
	local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,q in ipairs(m:GetDescendants()) do if q:IsA('BasePart') then
		local cf,s=q.CFrame,q.Size/2
		local ext=Vector3.new(math.abs(cf.RightVector.X)*s.X+math.abs(cf.UpVector.X)*s.Y+math.abs(cf.LookVector.X)*s.Z,
			math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z,
			math.abs(cf.RightVector.Z)*s.X+math.abs(cf.UpVector.Z)*s.Y+math.abs(cf.LookVector.Z)*s.Z)
		lo=lo:Min(cf.Position-ext) hi=hi:Max(cf.Position+ext) end end
	return lo,hi
end
local missing={}
local function kit(name,x,y,z,scale,yaw,tint)
	local home=workspace:FindFirstChild(KITS[name]) local src=home and home:FindFirstChild(name)
	if not src then missing[name]=(missing[name] or 0)+1 return nil end
	local m=src:Clone()
	if scale and scale~=1 then m:ScaleTo(m:GetScale()*scale) end
	local lo,hi=aabb(m) local c=(lo+hi)/2
	m:PivotTo(CFrame.new(c)*CFrame.Angles(0,math.rad(yaw),0)*CFrame.new(-c)*m:GetPivot())
	lo,hi=aabb(m)
	m:PivotTo(m:GetPivot()+Vector3.new(x-(lo.X+hi.X)/2,y-lo.Y,z-(lo.Z+hi.Z)/2))
	local col=COLOURS[name] or {}
	for _,q in ipairs(m:GetDescendants()) do if q:IsA('BasePart') then
		q.Anchored=true q.Transparency=0 q.CanCollide=false q.CanQuery=false q.CanTouch=false
		if tint then q.Color=tint q.Material=Enum.Material.Plastic elseif col[q.Name] then q.Color=col[q.Name] end end end
	m.Parent=DF return m
end
local rng=Random.new(1004)
local function ground(x,z) local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-300,0),tp) return h end
local function level(x,z,y0,tol)
	for _,d in ipairs({Vector3.new(1.5,0,0),Vector3.new(-1.5,0,0),Vector3.new(0,0,1.5),Vector3.new(0,0,-1.5)}) do
		local h=ground(x+d.X,z+d.Z) if not h or h.Material==WATER or math.abs(h.Position.Y-y0)>tol then return false end end
	return true
end
local placed,skip=0,0
local function tree(x,z,minY)
	local h=ground(x,z)
	if not h or h.Material==WATER or h.Material==Enum.Material.Sand or h.Position.Y<minY or not level(x,z,h.Position.Y,2.5) then skip+=1 return end
	local r=rng:NextNumber() local name=(r<0.5) and 'cypress' or (r<0.8) and 'olive_tree' or 'pine_squat'
	local sc=(name=='cypress') and rng:NextNumber(0.85,1.05) or (name=='olive_tree') and rng:NextNumber(0.95,1.2) or rng:NextNumber(1.15,1.45)
	if kit(name,x,h.Position.Y-0.15,z,sc,rng:NextNumber(0,360)) then placed+=1 end
end
-- crest: behind the lip, every ~14 studs with jitter
for _,c in ipairs(crest) do
	if rng:NextNumber()<0.32 then tree(c.x+rng:NextNumber(-1.5,1.5),c.z+rng:NextNumber(7,15),30) end
end
-- limestone shoulders and the ridge just above them, both sides
for x=-60,40,9 do if rng:NextNumber()<0.6 then tree(x+rng:NextNumber(-3,3),-546+rng:NextNumber(0,9),25) end end
for x=340,470,9 do if rng:NextNumber()<0.6 then tree(x+rng:NextNumber(-3,3),-546+rng:NextNumber(0,9),25) end end
-- a few olives at the foot of the west join (on the flat grass by the pool)
for _,p in ipairs({{8,-604},{22,-610},{-6,-612},{34,-602}}) do
	local h=ground(p[1],p[2]) if h and h.Material~=WATER and level(p[1],p[2],h.Position.Y,1.5) then if kit('olive_tree',p[1],h.Position.Y-0.15,p[2],rng:NextNumber(1.0,1.25),rng:NextNumber(0,360)) then placed+=1 end end
end
-- (C) boulders at the foot of the west join
local LIM=C(196,168,120) local nb=0
for i=1,9 do
	local x=rng:NextNumber(4,46) local z=rng:NextNumber(-600,-586)
	local h=ground(x,z)
	if h and h.Material~=WATER then if kit((i%3==0) and 'rock_cluster' or 'rock_big',x,h.Position.Y-0.6,z,rng:NextNumber(0.8,1.6),rng:NextNumber(0,360),LIM) then nb+=1 end end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Cliff blend dress t3')
local ms={} for k,v in pairs(missing) do table.insert(ms,k..'='..v) end
warn('QB@T3 lip cells',lipCells,'crest cols',#crest,'trees',placed,'skipped',skip,'boulders',nb,'missing',table.concat(ms,','))
local cam=workspace.CurrentCamera
local t=Vector3.new(185,10,-565)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(Vector3.new(240,-30,-720),t)
