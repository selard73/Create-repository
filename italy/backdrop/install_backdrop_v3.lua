-- bd3 Oct 4 2026: backdrop v3 after the play-test look from the lighthouse - the band's west end showed as a hard edge and
-- the painting read pale/lavender in game lighting. Now 13 panels x -900..1700 (ends beyond any Porto view), y -10..170
-- (no gap under it where the ridge ends), and a slightly darker, bluer tint. Same three uploaded images; the client script
-- BackdropGorgeHide (installed by bd2) keeps hiding the panels marked Gorge during the boat trip.
local ids={A='rbxassetid://123119554624880',B='rbxassetid://118783745036627',C='rbxassetid://83249831555757'}
local TINT=Color3.new(0.82,0.88,0.95)
local old=workspace:FindFirstChild('PortoBackdrop') if old then old:Destroy() end
local M=Instance.new('Model') M.Name='PortoBackdrop' M.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
M:SetAttribute('Built','Oct 4 2026 one-way mountain backdrop v3')
local order={'A','B','C'} local n=0
for cx=1600,-800,-200 do
	n+=1
	local key=order[(n-1)%3+1]
	local p=Instance.new('Part') p.Name='Panel_'..cx..'_'..key p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
	p.CastShadow=false p.Transparency=1 p.Size=Vector3.new(200.4,180,1)
	local c=Vector3.new(cx,80,-285)
	p.CFrame=CFrame.lookAt(c,c+Vector3.new(0,0,-1))
	local g=Instance.new('SurfaceGui') g.Name='Paint' g.Face=Enum.NormalId.Front g.LightInfluence=0 g.Brightness=1
	g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud=5 g.MaxDistance=0 g.AlwaysOnTop=false g.ClipsDescendants=true g.Parent=p
	local im=Instance.new('ImageLabel') im.Name='Mountains' im.Size=UDim2.fromScale(1,1) im.BackgroundTransparency=1 im.Image=ids[key]
	im.ImageColor3=TINT im.ScaleType=Enum.ScaleType.Stretch im.Parent=g
	if cx==0 or cx==200 then p:SetAttribute('Gorge',true) end
	p.Parent=M
end
M.Parent=workspace
game:GetService('ChangeHistoryService'):SetWaypoint('Porto backdrop v3')
warn('QD@V3 panels',n)
local cam=workspace.CurrentCamera
local t=Vector3.new(250,10,-560)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(Vector3.new(440,72,-984),t)
