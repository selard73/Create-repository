-- Oct 4 2026 funicular fix 2 (Shannon's circle: "at the top, it still looks like the car is passing right through that white
-- thing"): the top station's 'Station end crossing' (a limestone walkway at platform height across BOTH tracks, just below the
-- top stop) is cut where the cars run - its two ends stay as platform edges; the original goes to
-- ServerStorage.FunicularBackup. Also every upright 'Upper terrace path' piece round the top stop (not only the two near the
-- middle) now ends under the track bed. No asserts after the first edit.
local F=workspace.PortoNocciola['15 Funicolare']
local st
for _,c in ipairs(F:GetChildren()) do if c:IsA('Model') and c.Name:find('ALTA') then st=c end end
if not st then warn('QV@ABORT no top station') return end
local A,B=F:GetAttribute('Bottom'),F:GetAttribute('Top')
local d=Vector3.new(B.X-A.X,0,B.Z-A.Z).Unit
local r=Vector3.new(-d.Z,0,d.X)
local half=0
for _,car in ipairs(F.Cars:GetChildren()) do
	local _,sz=car:GetBoundingBox()
	half=math.max(half,math.abs(car:GetAttribute('Offset'))+math.min(sz.X,sz.Z)/2)
end
half+=0.35
local bk=game.ServerStorage:FindFirstChild('FunicularBackup') or Instance.new('Folder')
bk.Name='FunicularBackup' bk.Parent=game.ServerStorage
local cut=0
for _,p in ipairs(st:GetChildren()) do
	if p:IsA('BasePart') and p.Name=='Station end crossing' then
		local cf=p.CFrame
		-- the long local axis that runs across the track
		local axes={{cf.RightVector,p.Size.X,'X'},{cf.LookVector,p.Size.Z,'Z'}}
		local ax=math.abs(axes[1][1]:Dot(r))>math.abs(axes[2][1]:Dot(r)) and axes[1] or axes[2]
		local u=ax[1] if u:Dot(r)<0 then u=-u end
		local L=ax[2]
		-- across-track coordinate of the crossing's centre, measured from the track centre line
		local c0=Vector3.new(p.Position.X-B.X,0,p.Position.Z-B.Z):Dot(r)
		local lo,hi=c0-L/2,c0+L/2
		local pieces={}
		if lo<-half then table.insert(pieces,{lo,-half}) end
		if hi>half then table.insert(pieces,{half,hi}) end
		for i,seg in ipairs(pieces) do
			local q=p:Clone()
			q.Name='Station end crossing ('..(i==1 and 'left' or 'right')..' platform edge)'
			local len=seg[2]-seg[1]
			local mid=(seg[1]+seg[2])/2
			q.Size=(ax[3]=='X') and Vector3.new(len,p.Size.Y,p.Size.Z) or Vector3.new(p.Size.X,p.Size.Y,len)
			q.CFrame=cf+u*(mid-c0)
			q.Parent=st
		end
		p.Parent=bk
		cut+=1
		warn('QV@CROSSING across',lo,hi,'gap',-half,half,'kept',#pieces)
	end
end
-- upright path pieces round the top stop
local rail
for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name=='Continuous steel running rail' then rail=p break end end
local axis=rail.CFrame.RightVector if axis.Y<0 then axis=-axis end
local h=Vector3.new(axis.X,0,axis.Z) local slope=axis.Y/h.Magnitude local dirH=h.Unit local c0=rail.Position
local function railTop(p) return c0.Y+rail.Size.Y/2+slope*(Vector3.new(p.X-c0.X,0,p.Z-c0.Z):Dot(dirH)) end
local trimmed={}
for _,p in ipairs(workspace.PortoNocciola['12 Country landscape']:GetDescendants()) do
	if p:IsA('BasePart') and (Vector3.new(p.Position.X-B.X,0,p.Position.Z-B.Z)).Magnitude<16 then
		local cf=p.CFrame
		local ax={{cf.RightVector,p.Size.X},{cf.UpVector,p.Size.Y},{cf.LookVector,p.Size.Z}}
		local bi,best=1,0
		for i,a in ipairs(ax) do if math.abs(a[1].Y)>best then best=math.abs(a[1].Y) bi=i end end
		local len=ax[bi][2]
		local top=p.Position.Y+len/2
		local newTop=railTop(p.Position)-3.5
		if len>20 and best>0.95 and top>newTop then
			local cutBy=top-newTop
			if not p:GetAttribute('OldSize') then p:SetAttribute('OldSize',p.Size) p:SetAttribute('OldCFrame',p.CFrame) end
			p:SetAttribute('FunicularTrim',(p:GetAttribute('FunicularTrim') or 0)+cutBy)
			local dv=({Vector3.new(cutBy,0,0),Vector3.new(0,cutBy,0),Vector3.new(0,0,cutBy)})[bi]
			p.Size=p.Size-dv
			p.CFrame=p.CFrame-Vector3.new(0,cutBy/2,0)
			table.insert(trimmed,string.format('%s @(%.0f,%.0f) -%.1f',p.Name,p.Position.X,p.Position.Z,cutBy))
		end
	end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Funicular fix 2')
warn('QV@OK crossings cut',cut,'half',half,'trimmed',#trimmed,table.concat(trimmed,'; '))
local cam=workspace.CurrentCamera
local t=B+Vector3.new(0,1,0)-d*9
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t-d*12+r*9+Vector3.new(0,6,0),t)
