-- Oct 4 2026: install the crab game (Shannon approved the whole plan; golden crab = 100 acorns).
-- Needs the imported trap model workspace.crabtrap (TrapFrame + TrapNet from italy/crabtrap/crabtrap.fbx).
-- Builds ReplicatedStorage.CrabGame (CrabEvent, Trap, Buoy, Line, Crab), workspace.CrabGame (settings, CrabServer, SellSpot
-- prompt at Beppe's crate), StarterPlayerScripts.CrabClient; adds the crab trap to the Acorn Store (ShopServer, ShopClient,
-- Price/Sell attributes) and its icon to SquirrelIllustrations. Every source edit is an exact-anchor insert; a missing anchor
-- warns and skips. Re-runnable (rebuilds its own pieces, never inserts twice). No asserts after the first edit.
local RS=game.ReplicatedStorage
local SPS=game.StarterPlayer.StarterPlayerScripts
local imp=workspace:FindFirstChild('crabtrap')
local frameP=imp and imp:FindFirstChild('TrapFrame',true)
local netP=imp and imp:FindFirstChild('TrapNet',true)
if not (frameP and netP) and not (RS:FindFirstChild('CrabGame') and RS.CrabGame:FindFirstChild('Trap')) then warn('QK@ABORT no imported crabtrap') return end
local crabT=RS:FindFirstChild('TidePoolCrab')
if not crabT then warn('QK@ABORT no TidePoolCrab') return end
local beppeCrate=workspace.PortoNocciola:FindFirstChild('BeppeCrate',true)
if not beppeCrate then warn('QK@ABORT no BeppeCrate') return end

-- ReplicatedStorage kit
local kit=RS:FindFirstChild('CrabGame')
local oldTrap=kit and kit:FindFirstChild('Trap')
if not kit then kit=Instance.new('Folder') kit.Name='CrabGame' kit.Parent=RS end
for _,n in ipairs({'CrabEvent','Buoy','Line','Crab'}) do local o=kit:FindFirstChild(n) if o then o:Destroy() end end
local re=Instance.new('RemoteEvent') re.Name='CrabEvent' re.Parent=kit
if frameP and netP then
	if oldTrap then oldTrap:Destroy() end
	local trap=Instance.new('Model') trap.Name='Trap'
	for _,p in ipairs({frameP,netP}) do p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Parent=trap end
	frameP.Color=Color3.fromRGB(118,122,126) frameP.Material=Enum.Material.Metal frameP.TextureID=''
	pcall(function() netP.DoubleSided=true end)
	trap.PrimaryPart=frameP
	trap.Parent=kit
	imp:Destroy()
end
-- the float: a red ball with a white band, a line end on top
local buoy=Instance.new('Model') buoy.Name='Buoy'
local ball=Instance.new('Part') ball.Name='Float' ball.Shape=Enum.PartType.Ball ball.Size=Vector3.new(0.7,0.7,0.7)
ball.Color=Color3.fromRGB(214,56,44) ball.Material=Enum.Material.SmoothPlastic ball.Anchored=true ball.CanCollide=false ball.CanQuery=false ball.CanTouch=false ball.Parent=buoy
local band=Instance.new('Part') band.Name='Band' band.Shape=Enum.PartType.Cylinder band.Size=Vector3.new(0.16,0.74,0.74)
band.CFrame=ball.CFrame*CFrame.Angles(0,0,math.rad(90)) band.Color=Color3.fromRGB(250,248,240) band.Material=Enum.Material.SmoothPlastic
band.Anchored=false band.CanCollide=false band.CanQuery=false band.CanTouch=false band.Massless=true band.Parent=buoy
local w=Instance.new('WeldConstraint') w.Part0=ball w.Part1=band w.Parent=ball
local le=Instance.new('Attachment') le.Name='LineEnd' le.Position=Vector3.new(0,0.3,0) le.Parent=ball
buoy.PrimaryPart=ball buoy.Parent=kit
-- the rope
local line=Instance.new('Beam') line.Name='Line' line.Color=ColorSequence.new(Color3.fromRGB(150,118,78)) line.Width0=0.06 line.Width1=0.06
line.FaceCamera=true line.Segments=12 line.LightInfluence=1 line.Transparency=NumberSequence.new(0) line.Parent=kit
-- a crab for the catch (the tide-pool crab, smaller)
local crab=crabT:Clone() crab.Name='Crab'
pcall(function() crab:ScaleTo(0.65) end)
crab.Parent=kit

-- workspace.CrabGame: settings, the server, Beppe's sell spot
local G=workspace:FindFirstChild('CrabGame')
if not G then G=Instance.new('Folder') G.Name='CrabGame' G.Parent=workspace end
for _,n in ipairs({'CrabServer','SellSpot'}) do local o=G:FindFirstChild(n) if o then o:Destroy() end end
G:SetAttribute('ZoneMin',Vector3.new(280,-58,-814)) G:SetAttribute('ZoneMax',Vector3.new(318,-43,-758))
G:SetAttribute('SeaY',-52.9) G:SetAttribute('Bucket',6) G:SetAttribute('CrabPay',3) G:SetAttribute('GoldPay',100)
G:SetAttribute('GoldChance',0.05) G:SetAttribute('WaitMin',10) G:SetAttribute('WaitMax',15)
local spotCF,spotSize=beppeCrate:GetBoundingBox()
local spot=Instance.new('Part') spot.Name='SellSpot' spot.Size=Vector3.new(1,1,1) spot.Transparency=1
spot.Anchored=true spot.CanCollide=false spot.CanQuery=false spot.CanTouch=false
spot.CFrame=CFrame.new(spotCF.Position+Vector3.new(0,spotSize.Y/2+0.2,0)) spot.Parent=G
local pr=Instance.new('ProximityPrompt') pr.Name='SellPrompt' pr.ActionText='Sell crabs' pr.ObjectText='Beppe the Fishmonger'
pr.HoldDuration=0.25 pr.MaxActivationDistance=9 pr.RequiresLineOfSight=false pr.Parent=spot
local srv=Instance.new('Script') srv.Name='CrabServer' srv.Source=[==[%SERVER%]==] srv.Parent=G
local oldc=SPS:FindFirstChild('CrabClient') if oldc then oldc:Destroy() end
local cli=Instance.new('LocalScript') cli.Name='CrabClient' cli.Source=[==[%CLIENT%]==] cli.Parent=SPS

-- the Acorn Store
local shop=workspace.Shop
shop:SetAttribute('Price_crabtrap',40) shop:SetAttribute('Sell_crabtrap',true)
local function insert(scr,anchor,add,dupKey)
	local s=scr.Source
	if s:find(dupKey,1,true) then warn('QK@SKIP already there',scr:GetFullName()) return true end
	local a=s:find(anchor,1,true)
	if not a then warn('QK@MISSING anchor in',scr:GetFullName()) return false end
	scr.Source=s:sub(1,a-1)..add..s:sub(a)
	return true
end
local ok1=insert(shop.ShopServer,'\tzoomies    = {repeatable = true, clock = "zoomiesuntil"',
	'\tcrabtrap   = {once = true},                           -- Oct 4 2026: the crab game at Porto Nocciola (workspace.CrabGame)\n','crabtrap')
local ok2=insert(shop.ShopClient,'\t{id = "backpack",',
	'\t{id = "crabtrap",   name = "Crab trap",       blurb = "Yours to keep. Cast it off the rocks in the Crab Catching Area at Porto Nocciola, then sell your catch to Beppe.", once = true},\n','"crabtrap"')
local ok3=insert(RS.SquirrelIllustrations,' else -- A friendly squirrel profile',
	' elseif id=="crabtrap" then\n'..
	'  local grey,orange=C(120,124,128),C(222,106,52)\n'..
	'  circle(.17,.17,.66,grey);circle(.22,.22,.56,green)\n'..
	'  for _,r in ipairs({45,-45,0,90}) do line(.25,.485,.5,.03,cream,r) end\n'..
	'  circle(.37,.37,.26,grey);circle(.42,.42,.16,C(48,84,64))\n'..
	'  circle(.60,.62,.20,orange);circle(.55,.57,.09,orange);circle(.76,.57,.09,orange)\n'..
	' elseif id=="crab" or id=="goldcrab" then\n'..
	'  local orange=id=="goldcrab" and gold or C(222,106,52)\n'..
	'  shape(.26,.44,.48,.28,orange,.5);circle(.12,.28,.2,orange);circle(.68,.28,.2,orange)\n'..
	'  circle(.38,.36,.08,cream);circle(.54,.36,.08,cream)\n'..
	'  for i=0,2 do line(.14,.6+i*.07,.16,.035,orange,20);line(.70,.6+i*.07,.16,.035,orange,-20) end\n','id=="crabtrap"')
game:GetService('ChangeHistoryService'):SetWaypoint('Crab game installed')
warn('QK@OK store',ok1,ok2,ok3,'trap',kit:FindFirstChild('Trap')~=nil,'sell spot',spot.Position,'server',#srv.Source,'client',#cli.Source)
