-- Oct 4 2026 crab game fix 1: see-through net (SurfaceAppearance, alpha = transparency), bigger float, thicker rope,
-- client looks the sell prompt up again while it is missing (streaming).
local kit=game.ReplicatedStorage.CrabGame
local function seeThrough(net)
	local id=net.TextureID~='' and net.TextureID or net:GetAttribute('NetTexture')
	if not id or id=='' then warn('QX@NOTEX',net:GetFullName()) return end
	net:SetAttribute('NetTexture',id)
	local sa=net:FindFirstChildOfClass('SurfaceAppearance') or Instance.new('SurfaceAppearance')
	sa.AlphaMode=Enum.AlphaMode.Transparency sa.ColorMap=id sa.Parent=net
	net.TextureID=''
end
seeThrough(kit.Trap.TrapNet)
local pv=workspace:FindFirstChild('TrapPreview') if pv then seeThrough(pv.TrapNet) end
local b=kit.Buoy b.Float.Size=Vector3.new(0.95,0.95,0.95) b.Band.Size=Vector3.new(0.2,1.0,1.0)
b.Band.CFrame=b.Float.CFrame*CFrame.Angles(0,0,math.rad(90)) b.Float.LineEnd.Position=Vector3.new(0,0.42,0)
kit.Line.Width0=0.1 kit.Line.Width1=0.1
local cli=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CrabClient')
if cli then cli.Source=[==[%CLIENT%]==] end
game:GetService('ChangeHistoryService'):SetWaypoint('Crab game fix 1')
warn('QX@OK net',kit.Trap.TrapNet:FindFirstChildOfClass('SurfaceAppearance') and kit.Trap.TrapNet.SurfaceAppearance.ColorMap,'client',cli and #cli.Source)
