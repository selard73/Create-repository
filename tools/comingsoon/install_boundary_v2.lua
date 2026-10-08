-- bw2 Oct 4 2026 (Shannon's red line): the harbour opens, the hillside town is the "More Squirrels Coming Soon" area.
-- Old walls (South/East/West/Side, which penned players on the arrival grass) removed - backup in ServerStorage first.
-- New invisible wall along her line (from her Studio screenshot, ray-cast from the same camera), starting out at sea,
-- past the foot of the big limestone stairs, along the foot of the town, across the funicular track just uphill of the
-- boarding platforms, then up the cliff to the arrival plateau. Sign: "More Squirrels / Coming Soon!" above the stairs.
local F=workspace:FindFirstChild('ComingSoonWall')
if not F then warn('QW@ABORT no ComingSoonWall') return end
-- her line (x,z), ordered by z
local LINE={{268,-1140},{281,-989},{288,-953},{292,-881},{300,-855},{309,-828},{314,-794},{317,-773},{324,-768},{333,-764},
	{339,-744},{342,-723},{347,-698},{347,-672},{343,-652},{343,-634},{353,-622},{358,-591},{358,-540}}
local function xline(z)
	if z<=LINE[1][2] then return LINE[1][1] end
	for i=1,#LINE-1 do local a,b=LINE[i],LINE[i+1]
		if z>=a[2] and z<=b[2] then local t=(z-a[2])/math.max(b[2]-a[2],1e-6) return a[1]+(b[1]-a[1])*t end end
	return LINE[#LINE][1]
end
-- pre-check: every harbour squirrel must stay on the harbour side
local bad={}
for _,m in ipairs(workspace:GetChildren()) do
	if m:IsA('Model') and m.Name:find('_squirrel_color') then
		local p=m:GetPivot().Position
		if p.Z<-540 and p.Z>-1200 and p.X>150 and p.X<800 and p.Y<0 and p.X>xline(p.Z)-1 then table.insert(bad,m.Name..' '..tostring(p)) end
	end
end
if #bad>0 then warn('QW@ABORT squirrels on the town side:',table.concat(bad,' | ')) return end
-- backup
local SS=game:GetService('ServerStorage')
if not SS:FindFirstChild('ComingSoonWall_v1032') then local c=F:Clone() c.Name='ComingSoonWall_v1032'
	for _,s in ipairs(c:GetDescendants()) do if s:IsA('Script') then s.Disabled=true end end c.Parent=SS end
-- old walls out
local removed={}
for _,n in ipairs({'SouthWall','EastWall','WestWall','SideWall'}) do local p=F:FindFirstChild(n) if p then p:Destroy() table.insert(removed,n) end end
for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:match('^Seg%d+Wall$') then p:Destroy() end end
-- new segments
for i=1,#LINE-1 do
	local a=Vector3.new(LINE[i][1],0,LINE[i][2]) local b=Vector3.new(LINE[i+1][1],0,LINE[i+1][2])
	local mid=(a+b)/2 local len=(b-a).Magnitude
	local p=Instance.new('Part') p.Name=string.format('Seg%02dWall',i) p.Anchored=true p.CanCollide=true p.CanQuery=false p.CanTouch=false
	p.CastShadow=false p.Transparency=1 p.Material=Enum.Material.SmoothPlastic
	p.Size=Vector3.new(1,130,len+1.2)
	p.CFrame=CFrame.lookAt(Vector3.new(mid.X,-5,mid.Z),Vector3.new(b.X,-5,b.Z))
	p.Parent=F
end
-- server: Studio pass for Shannon (as before), Enabled switch, safety net only for players who got past without earning the funicular
local srv=F:FindFirstChild('ComingSoonServer')
if not srv then warn('QW@ABORT no ComingSoonServer') return end
srv.Source=[==[-- More Squirrels Coming Soon barrier (Oct 4 2026): invisible walls along the foot of the hillside town + safety net.
-- Untick the folder's Enabled attribute to switch it off; delete the folder to open the town.
-- Players with all 15 harbour squirrels (Found_porto >= 15) may ride the funicular up and roam the town; the owner always may.
local F=script.Parent local Players=game:GetService('Players')
local NEED=15
local LINE={{268,-1140},{281,-989},{288,-953},{292,-881},{300,-855},{309,-828},{314,-794},{317,-773},{324,-768},{333,-764},
	{339,-744},{342,-723},{347,-698},{347,-672},{343,-652},{343,-634},{353,-622},{358,-591},{358,-540}}
local function xline(z)
	if z<=LINE[1][2] then return LINE[1][1] end
	for i=1,#LINE-1 do local a,b=LINE[i],LINE[i+1]
		if z>=a[2] and z<=b[2] then local t=(z-a[2])/math.max(b[2]-a[2],1e-6) return a[1]+(b[1]-a[1])*t end end
	return LINE[#LINE][1]
end
local SAFE=Vector3.new(320,-40,-604)            -- the quay by the funicular entrance and Tonio
-- Studio tests only: Shannon's character walks through these walls and is never sent back
local STUDIO_PASS=game:GetService('RunService'):IsStudio()
if STUDIO_PASS then
	local PS=game:GetService('PhysicsService')
	pcall(function() PS:RegisterCollisionGroup('ComingSoonWall') end) pcall(function() PS:RegisterCollisionGroup('WallPass') end)
	PS:CollisionGroupSetCollidable('ComingSoonWall','WallPass',false)
	for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:match('Wall$') then p.CollisionGroup='ComingSoonWall' end end
	local function tag(c) for _,d in ipairs(c:GetDescendants()) do if d:IsA('BasePart') then d.CollisionGroup='WallPass' end end
		c.DescendantAdded:Connect(function(d) if d:IsA('BasePart') then d.CollisionGroup='WallPass' end end) end
	local function hook(pl) pl.CharacterAdded:Connect(tag) if pl.Character then tag(pl.Character) end end
	Players.PlayerAdded:Connect(hook) for _,pl in ipairs(Players:GetPlayers()) do hook(pl) end
end
local function apply() local on=F:GetAttribute('Enabled')~=false
	for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:match('Wall$') then p.CanCollide=on end end
	local s=F:FindFirstChild('Sign') if s and s:FindFirstChild('SignGui') then s.SignGui.Enabled=on end end
F:GetAttributeChangedSignal('Enabled'):Connect(apply) apply()
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
while true do task.wait(0.5)
	if F:GetAttribute('Enabled')~=false and not STUDIO_PASS then
		for _,pl in ipairs(Players:GetPlayers()) do
			local c=pl.Character local r=c and c:FindFirstChild('HumanoidRootPart') local h=c and c:FindFirstChildOfClass('Humanoid')
			if r and h and not h.SeatPart and pl.UserId~=game.CreatorId and (pl:GetAttribute('Found_porto') or 0)<NEED then
				local p=r.Position
				if p.Z<-540 and p.Z>-1300 and p.X<820 and p.Y>-80 and p.Y<200 and p.X>xline(p.Z)+1.5 then
					rp.FilterDescendantsInstances={c}
					local q=workspace:Raycast(SAFE+Vector3.new(0,30,0),Vector3.new(0,-80,0),rp)
					c:PivotTo(CFrame.new((q and q.Position or SAFE)+Vector3.new(0,3.5,0)))
				end
			end
		end
	end
end
]==]
-- sign: same look, new words, above the foot of the big stairs facing the harbour
local sign=F:FindFirstChild('Sign')
local n=0
if sign then
	for _,t in ipairs(sign:GetDescendants()) do if t:IsA('TextLabel') and t.Text=='Next Chapter' then t.Text='More Squirrels' n+=1 end end
	local pos=Vector3.new(318,-18,-800)
	local face=Vector3.new(-0.97,0,0.24).Unit
	sign.CFrame=CFrame.lookAt(pos,pos+face)
end
game:GetService('ChangeHistoryService'):SetWaypoint('More Squirrels boundary')
local segs=0 for _,p in ipairs(F:GetChildren()) do if p.Name:match('^Seg%d+Wall$') then segs+=1 end end
warn('QW@OK removed',table.concat(removed,','),'segments',segs,'sign text changed',n,'server',#srv.Source)
local cam=workspace.CurrentCamera
local t=Vector3.new(316,-30,-798)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(Vector3.new(268,-30,-770),t)
