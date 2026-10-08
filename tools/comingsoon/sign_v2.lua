-- Sign v2 (Oct 3 2026, her notes: one subdued colour, clear font, bigger, over the quay paving in front of where players are stopped)
local F=workspace.ComingSoonWall local old=F:FindFirstChild('Sign') if old then old:Destroy() end
local W,H,PPS=48,16,12.5
local sign=Instance.new('Part') sign.Name='Sign' sign.Anchored=true sign.CanCollide=false sign.CanQuery=false sign.CanTouch=false
sign.CastShadow=false sign.Transparency=1 sign.Size=Vector3.new(W,H,0.2)
local pos=Vector3.new(185,-36,-629) sign.CFrame=CFrame.lookAt(pos,Vector3.new(232,-36,-578)) sign.Parent=F
local g=Instance.new('SurfaceGui') g.Name='SignGui' g.Face=Enum.NormalId.Front g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
g.PixelsPerStud=PPS g.LightInfluence=0 g.Brightness=1 g.MaxDistance=500 g.Parent=sign
local function line(text,y,h)
	local t=Instance.new('TextLabel') t.Name='Line' t.BackgroundTransparency=1 t.Size=UDim2.new(1,0,h,0) t.Position=UDim2.new(0,0,y,0)
	t.FontFace=Font.new('rbxasset://fonts/families/BuilderSans.json',Enum.FontWeight.Bold) t.TextScaled=true t.Text=text
	t.TextColor3=Color3.fromRGB(242,235,218) t.Parent=g
	local s=Instance.new('UIStroke') s.Color=Color3.fromRGB(46,52,60) s.Thickness=3 s.Transparency=0.15 s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=t
end
line('Next Chapter',0.02,0.46)
line('Coming Soon!',0.52,0.46)
local cs=Instance.new('Script') cs.Name='SignFloat' cs.RunContext=Enum.RunContext.Client
cs.Source=[[local sign=script.Parent local gui=sign:WaitForChild('SignGui') local base=sign.CFrame
game:GetService('RunService').RenderStepped:Connect(function()
	if gui.Enabled then sign.CFrame=base+Vector3.new(0,math.sin(os.clock()*0.8)*0.35,0) end
end)]]
cs.Parent=sign
game:GetService('ChangeHistoryService'):SetWaypoint('Coming soon sign v2')
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(236,-38,-572),Vector3.new(234,-30,-615))
print('SIGN_V2_OK')
-- Oct 3 19:30 also: SideWall (1x130x34) at (260.5,-5,-577) across the grass strip east of the quay steps (steps x 253-260),
-- and ComingSoonServer safety net bound p.X>341 -> p.X>262.
