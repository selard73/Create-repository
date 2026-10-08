-- Porto Nocciola "Next Chapter Coming Soon!" barrier (Oct 3 2026). Command-bar installer; re-run replaces it.
local old=workspace:FindFirstChild('ComingSoonWall') if old then old:Destroy() end
local sp=workspace:FindFirstChild('Spawn_porto') assert(sp,'Spawn_porto missing')
local TS=game:GetService('TextService')
local F=Instance.new('Folder') F.Name='ComingSoonWall' F:SetAttribute('Enabled',true)
local function wall(name,cx,cz,sx,sz)
	local p=Instance.new('Part') p.Name=name p.Anchored=true p.CanCollide=true p.CanQuery=false p.CanTouch=false
	p.CastShadow=false p.Transparency=1 p.Material=Enum.Material.SmoothPlastic
	p.Size=Vector3.new(sx,130,sz) p.CFrame=CFrame.new(cx,-5,cz) p.Parent=F return p
end
wall('SouthWall',243.5,-593.5,191,1)  -- x 148..339 along the grass / quay paving line
wall('EastWall',337.5,-570,1,48)      -- cliff to the south wall, before the funicular platform
wall('WestWall',149.5,-570,1,48)      -- across the pool's far shore
-- floating letters
local W,H,PPS=48,16,25
local sign=Instance.new('Part') sign.Name='Sign' sign.Anchored=true sign.CanCollide=false sign.CanQuery=false sign.CanTouch=false
sign.CastShadow=false sign.Transparency=1 sign.Size=Vector3.new(W,H,0.2)
local pos=Vector3.new(270,-30,-592.6) sign.CFrame=CFrame.lookAt(pos,pos+Vector3.new(0,0,1)) sign.Parent=F
local g=Instance.new('SurfaceGui') g.Name='SignGui' g.Face=Enum.NormalId.Front g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
g.PixelsPerStud=PPS g.LightInfluence=0 g.Brightness=1.4 g.MaxDistance=400 g.Parent=sign
local COLS={Color3.fromRGB(255,212,56),Color3.fromRGB(255,122,98),Color3.fromRGB(64,176,235),Color3.fromRGB(104,214,168),Color3.fromRGB(255,152,196)}
local FONT=Enum.Font.FredokaOne
local idx,ci=0,0
local function line(text,size,y0,h)
	local ws,total={},0
	for i=1,#text do local c=text:sub(i,i) local w=TS:GetTextSize(c,size,FONT,Vector2.new(1000,1000)).X+(c==' ' and 0 or 4) ws[i]=w total+=w end
	local x=(W*PPS-total)/2
	for i=1,#text do
		local c=text:sub(i,i) idx+=1
		local hold=Instance.new('Frame') hold.Name='L'..idx hold.BackgroundTransparency=1 hold.Size=UDim2.fromOffset(ws[i],h) hold.Position=UDim2.fromOffset(x,y0) hold.Parent=g
		if c~=' ' then
			ci+=1
			local t=Instance.new('TextLabel') t.Name='Ch' t.BackgroundTransparency=1 t.Size=UDim2.fromScale(1,1) t.Font=FONT t.TextSize=size t.Text=c
			t.TextColor3=COLS[(ci-1)%#COLS+1] t:SetAttribute('i',idx) t.Parent=hold
			local s=Instance.new('UIStroke') s.Color=Color3.fromRGB(26,70,118) s.Thickness=7 s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=t
		end
		x+=ws[i]
	end
end
line('Next Chapter',118,10,160)
line('Coming Soon!',158,175,215)
local cs=Instance.new('Script') cs.Name='SignWave' cs.RunContext=Enum.RunContext.Client
cs.Source=[[local sign=script.Parent local gui=sign:WaitForChild('SignGui') local L={}
for _,d in ipairs(gui:GetDescendants()) do if d:IsA('TextLabel') then table.insert(L,d) end end
table.sort(L,function(a,b) return a:GetAttribute('i')<b:GetAttribute('i') end)
local base=sign.CFrame
game:GetService('RunService').RenderStepped:Connect(function()
	if not gui.Enabled then return end
	local t=os.clock()
	for k,l in ipairs(L) do l.Position=UDim2.fromOffset(0,math.sin(t*2.2-k*0.45)*10) l.Rotation=math.sin(t*1.5-k*0.6)*4 end
	sign.CFrame=base+Vector3.new(0,math.sin(t*0.9)*0.5,0)
end)]]
cs.Parent=sign
local ss=Instance.new('Script') ss.Name='ComingSoonServer'
ss.Source=[[-- Next Chapter barrier: walls + safety net. Untick the folder's Enabled attribute to switch it off; delete the folder to open Italy.
local F=script.Parent local Players=game:GetService('Players')
local function apply() local on=F:GetAttribute('Enabled')~=false
	for _,p in ipairs(F:GetChildren()) do if p:IsA('BasePart') and p.Name:match('Wall$') then p.CanCollide=on end end
	local s=F:FindFirstChild('Sign') if s and s:FindFirstChild('SignGui') then s.SignGui.Enabled=on end end
F:GetAttributeChangedSignal('Enabled'):Connect(apply) apply()
while true do task.wait(0.5)
	if F:GetAttribute('Enabled')~=false then
		local sp=workspace:FindFirstChild('Spawn_porto')
		for _,pl in ipairs(Players:GetPlayers()) do
			local c=pl.Character local r=c and c:FindFirstChild('HumanoidRootPart')
			if r and sp then local p=r.Position
				if p.Y<-15 and p.Z<-548 and (p.Z<-596 or p.X<146 or p.X>341) then
					c:PivotTo(CFrame.new(sp.Position+Vector3.new(0,4,0)))
				end
			end
		end
	end
end]]
ss.Parent=F
F.Parent=workspace
game:GetService('ChangeHistoryService'):SetWaypoint('Next Chapter Coming Soon barrier')
print('COMINGSOON_OK',#F:GetChildren(),idx)
