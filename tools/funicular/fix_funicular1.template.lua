-- Oct 4 2026 funicular fixes (Shannon's circled shots: "no wheels in the front part", "at the top it travels through a
-- partition", "the user's name and title sticks out the top when seated"). The cars stay level on a ~17 deg track (stepped
-- cabins, like real funiculars), so:
--  1. both cars ride 2 studs higher (rails ran through the uphill end of the floor); the Top/Bottom stops move up with them
--  2. all four wheels sit ON the rails at both ends, each axle under a bogie frame; a sloped skirt + end panel in the car's
--     colour closes the gap under the downhill end
--  3. the two upright 'Upper terrace path' pieces under the top station stop just under the track bed instead of at the
--     platform top (the car drove through them on the last stretch)
--  4. StarterPlayerScripts.FunicularTags hides the overhead name/title of anyone seated in a car (for every viewer)
-- Re-runnable (keeps its own state in attributes). No asserts after the first edit.
local F=workspace.PortoNocciola:FindFirstChild('15 Funicolare')
if not F then warn('QU@ABORT no funicular') return end
local cars=F:FindFirstChild('Cars')
local rail
for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name=='Continuous steel running rail' then rail=p break end end
if not (cars and rail) then warn('QU@ABORT no cars/rail') return end
local LIFT=2
-- the rail line: its long axis is the part's X
local axis=rail.CFrame.RightVector
if axis.Y<0 then axis=-axis end
local h=Vector3.new(axis.X,0,axis.Z)
local slope=axis.Y/h.Magnitude
local dirH=h.Unit
local c0=rail.Position
local function railTop(p) return c0.Y+rail.Size.Y/2+slope*(Vector3.new(p.X-c0.X,0,p.Z-c0.Z):Dot(dirH)) end

-- 1. lift (once)
if not F:GetAttribute('Lifted') then
	F:SetAttribute('Top',F:GetAttribute('Top')+Vector3.new(0,LIFT,0))
	F:SetAttribute('Bottom',F:GetAttribute('Bottom')+Vector3.new(0,LIFT,0))
	for _,car in ipairs(cars:GetChildren()) do car:PivotTo(car:GetPivot()+Vector3.new(0,LIFT,0)) end
	F:SetAttribute('Lifted',LIFT)
end

-- 2. undercarriage, per car, in the car's own frame (local -Z = uphill)
local DARK=Color3.fromRGB(52,52,56)
local made=0
for _,car in ipairs(cars:GetChildren()) do
	local old=car:FindFirstChild('Undercarriage') if old then old:Destroy() end
	local piv=car:GetPivot()
	local function rLocal(x,z) return railTop(piv*Vector3.new(x,0,z))-piv.Y end    -- rail top in car-local height
	local panelColour=Color3.fromRGB(160,40,36)
	for _,d in ipairs(car:GetChildren()) do if d.Name=='Car lower side panel' and d:IsA('BasePart') then panelColour=d.Color break end end
	local U=Instance.new('Model') U.Name='Undercarriage' U.Parent=car
	local function part(cls,name,size,lcf,col,mat)
		local p=Instance.new(cls) p.Name=name p.Size=size p.CFrame=piv*lcf p.Color=col p.Material=mat or Enum.Material.Metal
		p.Anchored=true p.CanCollide=false p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=U
		return p
	end
	-- wheels onto the rails
	for _,w in ipairs(car:GetChildren()) do
		if w.Name=='Funicular wheel' and w:IsA('BasePart') then
			local l=piv:ToObjectSpace(w.CFrame)
			local x,z=l.X,l.Z
			local y=rLocal(x,z)+w.Size.Y/2
			w.CFrame=piv*CFrame.new(x,y,z)*l.Rotation
			w.Color=DARK
		end
	end
	-- a bogie frame over each axle and two hangers up to the floor
	for _,z in ipairs({-2.8,2.8}) do
		local axleY=(rLocal(-1.3,z)+rLocal(1.3,z))/2+0.55
		part('Part','Bogie frame',Vector3.new(3.1,0.32,1.5),CFrame.new(0,axleY+0.34,z),DARK)
		part('Part','Axle',Vector3.new(2.9,0.18,0.18),CFrame.new(0,axleY,z),DARK)
		local topY=-0.45
		local hb=axleY+0.5
		if topY-hb>0.05 then
			for _,x in ipairs({-0.9,0.9}) do
				part('Part','Bogie hanger',Vector3.new(0.3,topY-hb,0.5),CFrame.new(x,(topY+hb)/2,z),DARK)
			end
		end
	end
	-- the skirt: flat top under the floor, sloped bottom 1 stud above the rails, full height at the downhill end
	local zUp,zDown=-3.9,3.9
	local function skirtBottom(z) return rLocal(0,z)+1.0 end
	local hDown=-0.45-skirtBottom(zDown)
	local zStart=zUp
	if -0.45-skirtBottom(zUp)<0 then          -- where the sloped bottom meets the floor
		local s=(skirtBottom(zDown)-skirtBottom(zUp))/(zDown-zUp)
		zStart=zUp+(-0.45-skirtBottom(zUp))/s
	end
	local len=zDown-zStart
	if hDown>0.1 and len>0.5 then
		for _,x in ipairs({-2.72,2.72}) do
			-- a WedgePart rolled 180 deg about Z: flat top, thin at -Z, full height at +Z
			part('WedgePart','Skirt',Vector3.new(0.15,hDown,len),CFrame.new(x,-0.45-hDown/2,zStart+len/2)*CFrame.Angles(0,0,math.pi),panelColour,Enum.Material.Metal)
		end
		part('Part','Skirt end',Vector3.new(5.6,hDown,0.15),CFrame.new(0,-0.45-hDown/2,zDown),panelColour,Enum.Material.Metal)
		-- a little brass step plate on the uphill end too
		part('Part','Step plate',Vector3.new(2.4,0.12,0.6),CFrame.new(0,-0.5,zUp-0.3),Color3.fromRGB(196,160,80),Enum.Material.Metal)
	end
	made+=1
end

-- 3. the upright path pieces under the top station: keep them, stop them under the track bed
local trimmed={}
local base=workspace.PortoNocciola:FindFirstChild('12 Country landscape')
if base then
	for _,p in ipairs(base:GetDescendants()) do
		if p:IsA('BasePart') and (p.Position-Vector3.new(700,6,-661)).Magnitude<4 and not p:GetAttribute('FunicularTrim') then
			-- which local axis is vertical?
			local cf=p.CFrame
			local ax={{cf.RightVector,'X'},{cf.UpVector,'Y'},{cf.LookVector,'Z'}}
			local best,bi=0,nil
			for i,a in ipairs(ax) do if math.abs(a[1].Y)>best then best=math.abs(a[1].Y) bi=i end end
			local sz=p.Size
			local len=({sz.X,sz.Y,sz.Z})[bi]
			local top=p.Position.Y+len/2
			-- the lowest track-bed bottom over this piece's footprint, minus a margin
			local lowBed=math.huge
			for _,b in ipairs(F:GetChildren()) do
				if b:IsA('BasePart') and b.Name=='Stone funicular track bed' and (Vector3.new(b.Position.X,0,b.Position.Z)-Vector3.new(p.Position.X,0,p.Position.Z)).Magnitude<16 then
					lowBed=math.min(lowBed,b.Position.Y-b.Size.Y/2-1.2)
				end
			end
			local newTop=math.min(lowBed,railTop(p.Position)-3.5)
			if newTop<top then
				local cut=top-newTop
				p:SetAttribute('FunicularTrim',cut) p:SetAttribute('OldSize',p.Size) p:SetAttribute('OldCFrame',p.CFrame)
				local d=({Vector3.new(cut,0,0),Vector3.new(0,cut,0),Vector3.new(0,0,cut)})[bi]
				p.Size=p.Size-d
				p.CFrame=p.CFrame-Vector3.new(0,cut/2,0)
				table.insert(trimmed,p.Name..' -'..string.format('%.1f',cut))
			end
		end
	end
end

-- 4. hide overhead names/titles of seated funicular riders
local SPS=game.StarterPlayer.StarterPlayerScripts
local oldT=SPS:FindFirstChild('FunicularTags') if oldT then oldT:Destroy() end
local tags=Instance.new('LocalScript') tags.Name='FunicularTags' tags.Source=[==[%TAGS%]==] tags.Parent=SPS
game:GetService('ChangeHistoryService'):SetWaypoint('Funicular fixes 1')
warn('QU@OK cars',made,'slope',slope,'top attr',F:GetAttribute('Top'),'trimmed',table.concat(trimmed,', '))
local cam=workspace.CurrentCamera
local car=cars:FindFirstChild('Car_Rosso')
if car then
	local p=car:GetPivot()
	cam.Focus=CFrame.new(p.Position)
	cam.CFrame=CFrame.lookAt(p.Position+p.RightVector*-11+Vector3.new(0,2.5,0)+p.LookVector*-3,p.Position+Vector3.new(0,-0.5,0))
end
