-- bd1 Oct 4 2026 (Shannon: hide the French map from Porto): one-way painted mountain backdrop. Seven 200x140 panels in a
-- straight band at z -285 (south of every French wall: village -205, forest -215, Château -250, Sandstone Climb -273),
-- x -300..1100, y 30..170. Each panel is an invisible part with a SurfaceGui on its south face only (unlit), showing tiles
-- A/B/C of a seamless panorama; from France you see the back, which is nothing. The model streams persistently so far
-- corners of Porto still see it. A client script hides the gorge panels while the player is Riding (the boat trip passes
-- through the band inside the gorge and would otherwise see the painting behind it).
local ids={} local carriers={}
for _,key in ipairs({'A','B','C'}) do
	local m=workspace:FindFirstChild('bd_'..key)
	if m then
		table.insert(carriers,m)
		for _,p in ipairs(m:GetDescendants()) do
			if p:IsA('MeshPart') then
				local tex=p.TextureID
				local sa=p:FindFirstChildOfClass('SurfaceAppearance') if (tex=='' or not tex) and sa then tex=sa.ColorMap end
				if tex and tex~='' then ids[key]=tex end
			end
		end
	end
end
if not (ids.A and ids.B and ids.C) then warn('QD@ABORT texture ids',ids.A,ids.B,ids.C) return end
local old=workspace:FindFirstChild('PortoBackdrop') if old then old:Destroy() end
local M=Instance.new('Model') M.Name='PortoBackdrop' M.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
M:SetAttribute('Built','Oct 4 2026 one-way mountain backdrop')
-- tiles in decreasing x so they read left->right for a viewer in Porto facing north
local order={'A','B','C'}
local n=0
for cx=1000,-200,-200 do
	n+=1
	local key=order[(n-1)%3+1]
	local p=Instance.new('Part') p.Name='Panel_'..cx..'_'..key p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
	p.CastShadow=false p.Transparency=1 p.Size=Vector3.new(200.4,140,1)
	local c=Vector3.new(cx,100,-285)
	p.CFrame=CFrame.lookAt(c,c+Vector3.new(0,0,-1))       -- Front face looks south, toward Porto
	local g=Instance.new('SurfaceGui') g.Name='Paint' g.Face=Enum.NormalId.Front g.LightInfluence=0 g.Brightness=1
	g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud=5 g.MaxDistance=0 g.AlwaysOnTop=false g.ClipsDescendants=true g.Parent=p
	local im=Instance.new('ImageLabel') im.Name='Mountains' im.Size=UDim2.fromScale(1,1) im.BackgroundTransparency=1 im.Image=ids[key]
	im.ScaleType=Enum.ScaleType.Stretch im.Parent=g
	if cx==0 or cx==200 then p:SetAttribute('Gorge',true) end
	p.Parent=M
end
M.Parent=workspace
-- client: hide the gorge panels during the boat trip
local SPS=game.StarterPlayer.StarterPlayerScripts
local oc=SPS:FindFirstChild('BackdropGorgeHide') if oc then oc:Destroy() end
local cs=Instance.new('LocalScript') cs.Name='BackdropGorgeHide'
cs.Source=[==[-- BackdropGorgeHide (Oct 4 2026): the painted mountain band (workspace.PortoBackdrop) crosses the gorge; while you ride the
-- boat through it, the two gorge panels are hidden so you never see the painting from behind the band.
local Players=game:GetService('Players') local player=Players.LocalPlayer
local M=workspace:WaitForChild('PortoBackdrop',60) if not M then return end
local shown=true
while true do
	task.wait(0.3)
	local c=player.Character
	local riding=c and c:GetAttribute('Riding') and true or false
	local want=not riding
	if want~=shown then
		shown=want
		for _,p in ipairs(M:GetChildren()) do if p:GetAttribute('Gorge') then local g=p:FindFirstChild('Paint') if g then g.Enabled=want end end end
	end
end
]==]
cs.Parent=SPS
for _,m in ipairs(carriers) do m:Destroy() end
local bc=workspace:FindFirstChild('backdrop_carrier') if bc then bc:Destroy() end   -- the merged first upload
game:GetService('ChangeHistoryService'):SetWaypoint('Porto backdrop')
warn('QD@OK panels',n,ids.A,ids.B,ids.C)
local cam=workspace.CurrentCamera
local t=Vector3.new(250,10,-560)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(Vector3.new(440,72,-984),t)
