-- japan_fix1.lua (job 105): Studio EDIT mode. The script-level fixes from the Japan survey (tools/japan/FINDINGS_japan_2026-10-15.md;
-- Shannon: "please make any fixes for issues you found on the Japan map"). Exact-string patches of NINE live scripts; every anchor is
-- counted in every script before anything changes (one missing or doubled = nothing changed); each original -> ServerStorage.HudBackup.
-- <Name>_pre_japanfix1; every patched source compiled where loadstring runs; a script already carrying JAPANFIX1 is skipped. Also sets
-- workspace.BalloonField's JapanPreview attribute to true (flip it to false in Studio for the ordinary balloon ride). The fixes: the
-- JapanPreviewAccess module optional (no more hanging SpawnReturn / balloon / train); Area "japan" for the owner in Japan; the balloon's
-- tail guarded, its PlayerRemoving safety net back, a landed preview counts as a flight; the reveal's fog / atmosphere / clouds put back
-- on an abort or a respawn; JapanAtmosphere restores the game's own baseline (clouds included) on leaving Japan and does not wait for the
-- waterwheel; the train reads Origin before going busy; the taxi streams the ground first; the hide scripts ignore Japan; the water script
-- owner-only; the visibility script hides smoke, fire, sparkles, highlights too. No DataStore, no publish. Output "QQ JFIX".
if game:GetService("RunService"):IsRunning() then print("QQ JFIX ABORT - Play mode") return end
local SCRIPTS = {{name = "SpawnReturnServer", path = {"Workspace", "SpawnReturn", "SpawnReturnServer"}, patches = {{[====[
local PreviewAccess=require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))
]====], [====[
-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs
local PreviewAccess
do
	local m=game.ServerScriptService:FindFirstChild("JapanPreviewAccess")
	local ok, mod=false, nil
	if m then ok, mod=pcall(require, m) end
	PreviewAccess=(ok and type(mod) == "table") and mod or {IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}
end
]====]}, {[====[
			if root and not (PreviewAccess.IsAllowed(player) and (player:GetAttribute("JapanPreviewInFlight") or PreviewAccess.IsJapan(root.Position))) then
]====], [====[
			if root and PreviewAccess.IsAllowed(player) and not player:GetAttribute("JapanPreviewInFlight") and PreviewAccess.IsJapan(root.Position) then
				if player:GetAttribute("Area") ~= "japan" then player:SetAttribute("Area", "japan") end   -- (JAPANFIX1: Japan is its own area, not the last one she left)
			elseif root and not (PreviewAccess.IsAllowed(player) and (player:GetAttribute("JapanPreviewInFlight") or PreviewAccess.IsJapan(root.Position))) then
]====]}}},
{name = "BalloonServer", path = {"Workspace", "BalloonField", "BalloonServer"}, patches = {{[====[
local PreviewAccess = require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))
]====], [====[
-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs
local PreviewAccess
do
	local m = game.ServerScriptService:FindFirstChild("JapanPreviewAccess")
	local ok, mod = false, nil
	if m then ok, mod = pcall(require, m) end
	PreviewAccess = (ok and type(mod) == "table") and mod or {IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}
end
]====]}, {[====[
	local preview = PreviewAccess.IsAllowed(p)
]====], [====[
	local preview = PreviewAccess.IsAllowed(p) and F:GetAttribute("JapanPreview") ~= false   -- (JAPANFIX1: BalloonField.JapanPreview = false gives her the ordinary ride)
]====]}, {[====[
	if connection and connection.Connected then connection:Disconnect() end
	local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
]====], [====[
	local tailOk, tailErr = pcall(function()   -- (JAPANFIX1: whatever happens in the tail, the balloon is freed below)
	if connection and connection.Connected then connection:Disconnect() end
	local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
]====]}, {[====[
	prompt.Enabled=true
	busy=nil
	if not ok then warn("BalloonServer: "..tostring(flightError))
	elseif not preview and awardItems and p.Parent==Players then awardItems:Fire(p,"balloon_flights",1) end
]====], [====[
	end)
	if not tailOk then warn("BalloonServer tail: "..tostring(tailErr)); p:SetAttribute("JapanPreviewInFlight",nil); if busy==p then pcall(setHome); pcall(function() ev:FireAllClients("phase",p,"home",2) end) end end
	if busy==p then prompt.Enabled=true; busy=nil end   -- (JAPANFIX1: only this rider's balloon - the safety net may have handed it on during a long preview yield)
	if not ok then warn("BalloonServer: "..tostring(flightError))
	elseif awardItems and p.Parent==Players and (not preview or landed) then awardItems:Fire(p,"balloon_flights",1) end   -- (JAPANFIX1: a landed preview is a flight too)
]====]}, {[====[
		task.wait(2)
		setHome()
		ev:FireAllClients("phase",p,"reset",0)
]====], [====[
		task.wait(2)
		if busy==p then setHome(); ev:FireAllClients("phase",p,"reset",0) end   -- (JAPANFIX1: not if the safety net already handed the balloon on)
]====]}, {[====[
	else
		setHome()
		ev:FireAllClients("phase",p,"home",2)
]====], [====[
	else
		if busy==p then setHome(); ev:FireAllClients("phase",p,"home",2) end
]====]}, {[====[
-- The active flight owns cleanup; a disconnect cannot reset another rider's balloon.
]====], [====[
-- The active flight owns cleanup; a disconnect cannot reset another rider's balloon.
Players.PlayerRemoving:Connect(function(p)   -- (JAPANFIX1: the safety net back - a rider who vanishes frees the balloon a second later)
	if busy == p then task.delay(1, function() if busy == p then busy = nil; prompt.Enabled = true; pcall(setHome); ev:FireAllClients("phase", p, "home", 2) end end) end
end)
]====]}}},
{name = "BalloonClient", path = {"Workspace", "BalloonField", "BalloonClient"}, patches = {{[====[
		if previewOwner then prompt.ObjectText = "Your balloon · private Japan preview"; prompt.ActionText = "Fly to Japan"
]====], [====[
		if previewOwner and F:GetAttribute("JapanPreview") ~= false then prompt.ObjectText = "Your balloon · private Japan preview"; prompt.ActionText = "Fly to Japan"   -- (JAPANFIX1)
]====]}, {[====[
		cam.CameraSubject=state.subject
]====], [====[
		cam.CameraSubject=(player.Character and player.Character:FindFirstChildOfClass("Humanoid")) or state.subject   -- (JAPANFIX1: after a respawn the camera follows the new character)
]====]}, {[====[
local function cloudCover()
	signBasket=nil;bb.Enabled=false;sign.Visible=false
]====], [====[
local function cloudCover()
	storming=false;beamOff()   -- (JAPANFIX1: no lightning behind the cloud cover)
	signBasket=nil;bb.Enabled=false;sign.Visible=false
]====]}, {[====[
local function revealJapan(seconds)
	stormOff()
	startPreviewCamera()
]====], [====[
-- JAPANFIX1_20261015: the reveal remembers what it changes; an aborted flight or a respawn puts it back, a landing hands over to JapanAtmosphere
local previewSaved=nil
local function previewRestore(secs)
	local s=previewSaved; previewSaved=nil
	if not s then return end
	TweenService:Create(Lighting,TweenInfo.new(secs or 2),{FogEnd=s.FogEnd,FogStart=s.FogStart}):Play()
	if atmo and s.density then TweenService:Create(atmo,TweenInfo.new(secs or 2),{Density=s.density,Haze=s.haze}):Play() end
	if clouds and s.cover~=nil then TweenService:Create(clouds,TweenInfo.new(secs or 2),{Cover=s.cover,Density=s.cdensity,Color=s.ccolor}):Play() end
end
local function revealJapan(seconds)
	local before=saved   -- (while the storm is still on, its snapshot is the true baseline)
	stormOff()
	startPreviewCamera()
	previewSaved=previewSaved or {FogEnd=before and before.FogEnd or Lighting.FogEnd,FogStart=before and before.FogStart or Lighting.FogStart,
		density=before and before.density or (atmo and atmo.Density),haze=before and before.haze or (atmo and atmo.Haze),
		cover=before and before.cover or (clouds and clouds.Cover),cdensity=before and before.cdensity or (clouds and clouds.Density),ccolor=before and before.ccolor or (clouds and clouds.Color)}
]====]}, {[====[
	showToast("The clouds are clearing… Welcome to Japan, SelBell.",5)
]====], [====[
	showToast("The clouds are clearing… Welcome to Japan, "..player.DisplayName..".",5)
]====]}, {[====[
			black.BackgroundTransparency=1;black.BackgroundColor3=Color3.new(0,0,0);cc.Brightness=0
			showToast("Explore Japan. The airport board takes you back to Provence.",7)
]====], [====[
			black.BackgroundTransparency=1;black.BackgroundColor3=Color3.new(0,0,0);cc.Brightness=0
			previewSaved=nil   -- (JAPANFIX1: JapanAtmosphere owns the lighting from here and restores the baseline when she leaves Japan)
			showToast("Explore Japan. The airport board takes you back to Provence.",7)
]====]}, {[====[
			stormOff(); duckMusic(false, 3); vrCamStop();stopPreviewCamera();black.BackgroundColor3=Color3.new(0,0,0)
]====], [====[
			stormOff(); duckMusic(false, 3); vrCamStop();stopPreviewCamera();previewRestore(2);black.BackgroundColor3=Color3.new(0,0,0)
]====]}, {[====[
player.CharacterAdded:Connect(function() stopPreviewCamera();black.BackgroundColor3]====], [====[
player.CharacterAdded:Connect(function() stopPreviewCamera();previewRestore(1);black.BackgroundColor3]====]}}},
{name = "JapanEnvironment", path = {"Workspace", "JapanMap", "JapanEnvironment"}, patches = {{[====[
local PreviewAccess=require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))
]====], [====[
-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs
local PreviewAccess
do
	local m=game.ServerScriptService:FindFirstChild("JapanPreviewAccess")
	local ok, mod=false, nil
	if m then ok, mod=pcall(require, m) end
	PreviewAccess=(ok and type(mod) == "table") and mod or {IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}
end
]====]}, {[====[
 busy=true;train:SetAttribute('InTransit',true);enablePrompts(false)
 local couldJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
 local start=CFrame.new(point.Position.X,0,map:GetAttribute('Origin').Z+181)
 local finish=CFrame.new(destination.Position.X,0,map:GetAttribute('Origin').Z+181)
]====], [====[
 local origin=map:GetAttribute('Origin')
 if typeof(origin)~='Vector3' then warn('Japan train: JapanMap has no Origin attribute') return end   -- (JAPANFIX1: checked before the train is marked busy)
 busy=true;train:SetAttribute('InTransit',true);enablePrompts(false)
 local couldJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
 local start=CFrame.new(point.Position.X,0,origin.Z+181)
 local finish=CFrame.new(destination.Position.X,0,origin.Z+181)
]====]}, {[====[
    character:PivotTo(CFrame.new(target+Vector3.new(0,4,0)))
]====], [====[
    pcall(player.RequestStreamAroundAsync,player,target,5)   -- (JAPANFIX1: the ground loads before the 5,700-stud hop, as TravelServer does)
    if not (player.Parent and player.Character==character and hrp.Parent) then return end
    character:PivotTo(CFrame.new(target+Vector3.new(0,4,0)))
]====]}}},
{name = "JapanAtmosphere", path = {"StarterPlayer", "StarterPlayerScripts", "JapanAtmosphere"}, patches = {{[====[
local active=false
local saved={}
local function enter()
 saved.ClockTime=Lighting.ClockTime;saved.FogEnd=Lighting.FogEnd;saved.FogStart=Lighting.FogStart
 saved.Atmospheres={}
 for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare};a.Density=.08;a.Haze=0;a.Glare=.08 end end
 Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999
end
local function leave()
 if not saved.ClockTime then return end
 Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart
 for a,values in pairs(saved.Atmospheres or {}) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end
 saved={}
end
]====], [====[
local active=false
-- JAPANFIX1_20261015: the baseline is what the game loaded with (the look pass), taken ONCE here - never at enter(), which used to come
-- after the balloon's reveal had already changed fog, atmosphere and clouds; the Clouds are part of it now
local clouds=workspace.Terrain:FindFirstChildOfClass('Clouds')
local saved={ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,Atmospheres={},Clouds=clouds and {Cover=clouds.Cover,Density=clouds.Density,Color=clouds.Color} or nil}
for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare} end end
local function enter()
 for a in pairs(saved.Atmospheres) do if a.Parent then a.Density=.08;a.Haze=0;a.Glare=.08 end end
 Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999
 if clouds and clouds.Parent then clouds.Cover=.08;clouds.Density=.1;clouds.Color=Color3.new(1,1,1) end
end
local function leave()
 Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart
 for a,values in pairs(saved.Atmospheres) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end
 if clouds and clouds.Parent and saved.Clouds then for k,v in pairs(saved.Clouds) do clouds[k]=v end end
end
]====]}, {[====[
local wheel=map:WaitForChild('TeaHills'):WaitForChild('Waterwheel')
local base=wheel:GetPivot()
]====], [====[
local wheel,base=nil,nil   -- (JAPANFIX1: the lighting no longer waits for the wheel to stream in)
task.spawn(function() local th=map:WaitForChild('TeaHills',60); wheel=th and th:WaitForChild('Waterwheel',600) or nil; if wheel then base=wheel:GetPivot() end end)
]====]}, {[====[
 if active then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end
]====], [====[
 if active and wheel and base then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end
]====]}}},
{name = "HidePortoFromFrance", path = {"StarterPlayer", "StarterPlayerScripts", "HidePortoFromFrance"}, patches = {{[====[
		local z = r.Position.Z
		if not active and z > IN_FRANCE_Z then active = true task.spawn(hideAll)
]====], [====[
		local z = r.Position.Z
		if r.Position.X > 4500 then z = active and IN_FRANCE_Z or OUT_Z end   -- (JAPANFIX1: Japan is neither side - no sweep while there)
		if not active and z > IN_FRANCE_Z then active = true task.spawn(hideAll)
]====]}}},
{name = "HideFranceFromPorto", path = {"StarterPlayer", "StarterPlayerScripts", "HideFranceFromPorto"}, patches = {{[====[
		local z=r.Position.Z
		if not active and z<IN_PORTO_Z then active=true task.spawn(hideAll)
]====], [====[
		local z=r.Position.Z
		if r.Position.X>4500 then z=active and IN_PORTO_Z or OUT_Z end   -- (JAPANFIX1: Japan is neither side - no sweep while there)
		if not active and z<IN_PORTO_Z then active=true task.spawn(hideAll)
]====]}}},
{name = "JapanWaterAppearance", path = {"StarterPlayer", "StarterPlayerScripts", "JapanWaterAppearance"}, patches = {{[====[
local inside=p and p.Position.X>4800]====], [====[
local inside=p and Players.LocalPlayer.UserId==9611145467 and p.Position.X>4800 --[[JAPANFIX1: owner only]]]====]}}},
{name = "JapanPreviewVisibility", path = {"StarterPlayer", "StarterPlayerScripts", "JapanPreviewVisibility"}, patches = {{[====[
instance:IsA('Light') or instance:IsA('Clouds') then instance.Enabled=false]====], [====[
instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then instance.Enabled=false --[[JAPANFIX1]]]====]}, {[====[
instance:IsA('Light') or instance:IsA('Clouds') then property='Enabled';expected=false]====], [====[
instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then property='Enabled';expected=false]====]}}}}
local MARK = "JAPANFIX1"
local function find(path)
	local o = game
	for _, n in ipairs(path) do o = o:FindFirstChild(n); if not o then return nil end end
	return o
end
-- pass 1: every script, every anchor
local work = {}
for _, sc in ipairs(SCRIPTS) do
	local s = find(sc.path)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ JFIX ABORT - missing " .. table.concat(sc.path, ".") .. "; nothing changed") return end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ JFIX " .. sc.name .. " already patched (" .. #o .. " chars)")
	else
		for i, p in ipairs(sc.patches) do
			local a, b = o:find(p[1], 1, true)
			if not a then print("QQ JFIX ABORT - " .. sc.name .. " anchor " .. i .. " not found (" .. #o .. " chars); nothing changed") return end
			if o:find(p[1], b + 1, true) then print("QQ JFIX ABORT - " .. sc.name .. " anchor " .. i .. " matches more than once; nothing changed") return end
		end
		local n = o
		for _, p in ipairs(sc.patches) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
		local ok, f, err = pcall(function() return loadstring(n) end)
		if ok and not f then print("QQ JFIX ABORT - " .. sc.name .. " patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
		table.insert(work, {sc = sc, s = s, o = o, n = n})
	end
end
-- pass 2: backups, then the writes
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
for _, w in ipairs(work) do
	local bname = w.sc.name .. "_pre_japanfix1"
	if not hb:FindFirstChild(bname) then local c = w.s:Clone(); if c then c.Name = bname; if c:IsA("BaseScript") then c.Enabled = false end; c.Parent = hb end end
end
for _, w in ipairs(work) do
	w.s.Source = w.n
	print(string.format("QQ JFIX %s %d -> %d chars (%d patches; backup HudBackup.%s_pre_japanfix1)", w.sc.name, #w.o, #w.n, #w.sc.patches, w.sc.name))
end
local BF = workspace:FindFirstChild("BalloonField")
if BF and BF:GetAttribute("JapanPreview") == nil then BF:SetAttribute("JapanPreview", true); print("QQ JFIX BalloonField.JapanPreview = true (set it false for the ordinary ride)") end
print(string.format("QQ JFIX DONE: %d scripts patched, %d already patched", #work, #SCRIPTS - #work))
