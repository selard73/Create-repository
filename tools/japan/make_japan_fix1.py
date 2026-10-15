#!/usr/bin/env python3
"""Builds tools/japan/japan_fix1.lua (job 105): the script-level fixes from the Japan survey (tools/japan/FINDINGS_japan_2026-10-15.md),
Shannon's "please make any fixes for issues you found on the Japan map". Exact-string patches of nine live scripts, all counted before
anything changes (one missing or doubled anchor = nothing changed), each original cloned to ServerStorage.HudBackup.<Name>_pre_japanfix1,
every patched source compiled where loadstring runs; a script already carrying JAPANFIX1 is skipped. Self-test here: the same patches
applied to the Oct 15 exports (tools/japan/studio_2026-10-15/, checksummed against Studio) and compiled with the luau CLI.
THE FIXES: (1) SpawnReturnServer, BalloonServer, JapanEnvironment no longer hang on a missing JapanPreviewAccess module (FindFirstChild +
a stub that allows nobody); (2) the owner's Area becomes "japan" in Japan instead of freezing; (3) BalloonServer: the end-of-flight tail
runs under pcall, the PlayerRemoving safety net is back, a landed preview counts as a flight, and BalloonField's JapanPreview attribute
(false) gives her the ordinary ride again (the client's prompt text follows it); (4) BalloonClient: the reveal remembers fog / atmosphere
/ clouds and puts them back on an aborted flight or a respawn, hands over to JapanAtmosphere on a landing, no lightning behind the cloud
cover, the camera follows the new Humanoid after a respawn, the toast uses her display name; (5) JapanAtmosphere keeps the game's
baseline from script load (clouds included) and restores it on leaving Japan; it no longer waits for the waterwheel before it works;
(6) JapanEnvironment reads Origin before marking the train busy and streams the ground in before the 5,700-stud taxi hop; (7) the two
hide scripts treat Japan as neither side (no 70k-instance sweep when she crosses z -260 / -560 inside Japan); (8) JapanWaterAppearance
is owner-gated; (9) JapanPreviewVisibility also hides Smoke / Fire / Sparkles / Highlight. Run from the repo root (LUAU_COMPILE=path)."""
import pathlib, subprocess, os
HERE = pathlib.Path(__file__).resolve().parent
EXP = HERE / "studio_2026-10-15"
MARK = "JAPANFIX1"

def fallback(indent, spaced):
    eq = " = " if spaced else "="
    return (f"{indent}-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs\n"
            f"{indent}local PreviewAccess\n{indent}do\n"
            f"{indent}\tlocal m{eq}game.ServerScriptService:FindFirstChild(\"JapanPreviewAccess\")\n"
            f"{indent}\tlocal ok, mod{eq}false, nil\n{indent}\tif m then ok, mod{eq}pcall(require, m) end\n"
            f"{indent}\tPreviewAccess{eq}(ok and type(mod) == \"table\") and mod or {{IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}}\n"
            f"{indent}end\n")

SCRIPTS = [
 {"name": "SpawnReturnServer", "path": ["Workspace", "SpawnReturn", "SpawnReturnServer"], "patches": [
   ('local PreviewAccess=require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))\n', fallback("", False)),
   ('\t\t\tif root and not (PreviewAccess.IsAllowed(player) and (player:GetAttribute("JapanPreviewInFlight") or PreviewAccess.IsJapan(root.Position))) then\n',
    '\t\t\tif root and PreviewAccess.IsAllowed(player) and not player:GetAttribute("JapanPreviewInFlight") and PreviewAccess.IsJapan(root.Position) then\n'
    '\t\t\t\tif player:GetAttribute("Area") ~= "japan" then player:SetAttribute("Area", "japan") end   -- (JAPANFIX1: Japan is its own area, not the last one she left)\n'
    '\t\t\telseif root and not (PreviewAccess.IsAllowed(player) and (player:GetAttribute("JapanPreviewInFlight") or PreviewAccess.IsJapan(root.Position))) then\n'),
 ]},
 {"name": "BalloonServer", "path": ["Workspace", "BalloonField", "BalloonServer"], "patches": [
   ('local PreviewAccess = require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))\n', fallback("", True)),
   ('\tlocal preview = PreviewAccess.IsAllowed(p)\n',
    '\tlocal preview = PreviewAccess.IsAllowed(p) and F:GetAttribute("JapanPreview") ~= false   -- (JAPANFIX1: BalloonField.JapanPreview = false gives her the ordinary ride)\n'),
   ('\tif connection and connection.Connected then connection:Disconnect() end\n\tlocal weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end\n',
    '\tlocal tailOk, tailErr = pcall(function()   -- (JAPANFIX1: whatever happens in the tail, the balloon is freed below)\n'
    '\tif connection and connection.Connected then connection:Disconnect() end\n\tlocal weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end\n'),
   ('\tprompt.Enabled=true\n\tbusy=nil\n\tif not ok then warn("BalloonServer: "..tostring(flightError))\n\telseif not preview and awardItems and p.Parent==Players then awardItems:Fire(p,"balloon_flights",1) end\n',
    '\tend)\n\tif not tailOk then warn("BalloonServer tail: "..tostring(tailErr)); p:SetAttribute("JapanPreviewInFlight",nil); if busy==p then pcall(setHome); pcall(function() ev:FireAllClients("phase",p,"home",2) end) end end\n'
    '\tif busy==p then prompt.Enabled=true; busy=nil end   -- (JAPANFIX1: only this rider\'s balloon - the safety net may have handed it on during a long preview yield)\n'
    '\tif not ok then warn("BalloonServer: "..tostring(flightError))\n'
    '\telseif awardItems and p.Parent==Players and (not preview or landed) then awardItems:Fire(p,"balloon_flights",1) end   -- (JAPANFIX1: a landed preview is a flight too)\n'),
   ('\t\ttask.wait(2)\n\t\tsetHome()\n\t\tev:FireAllClients("phase",p,"reset",0)\n',
    '\t\ttask.wait(2)\n\t\tif busy==p then setHome(); ev:FireAllClients("phase",p,"reset",0) end   -- (JAPANFIX1: not if the safety net already handed the balloon on)\n'),
   ('\telse\n\t\tsetHome()\n\t\tev:FireAllClients("phase",p,"home",2)\n',
    '\telse\n\t\tif busy==p then setHome(); ev:FireAllClients("phase",p,"home",2) end\n'),
   ("-- The active flight owns cleanup; a disconnect cannot reset another rider's balloon.\n",
    "-- The active flight owns cleanup; a disconnect cannot reset another rider's balloon.\n"
    "Players.PlayerRemoving:Connect(function(p)   -- (JAPANFIX1: the safety net back - a rider who vanishes frees the balloon a second later)\n"
    "\tif busy == p then task.delay(1, function() if busy == p then busy = nil; prompt.Enabled = true; pcall(setHome); ev:FireAllClients(\"phase\", p, \"home\", 2) end end) end\n"
    "end)\n"),
 ]},
 {"name": "BalloonClient", "path": ["Workspace", "BalloonField", "BalloonClient"], "patches": [
   ('\t\tif previewOwner then prompt.ObjectText = "Your balloon · private Japan preview"; prompt.ActionText = "Fly to Japan"\n',
    '\t\tif previewOwner and F:GetAttribute("JapanPreview") ~= false then prompt.ObjectText = "Your balloon · private Japan preview"; prompt.ActionText = "Fly to Japan"   -- (JAPANFIX1)\n'),
   ('\t\tcam.CameraSubject=state.subject\n',
    '\t\tcam.CameraSubject=(player.Character and player.Character:FindFirstChildOfClass("Humanoid")) or state.subject   -- (JAPANFIX1: after a respawn the camera follows the new character)\n'),
   ('local function cloudCover()\n\tsignBasket=nil;bb.Enabled=false;sign.Visible=false\n',
    'local function cloudCover()\n\tstorming=false;beamOff()   -- (JAPANFIX1: no lightning behind the cloud cover)\n\tsignBasket=nil;bb.Enabled=false;sign.Visible=false\n'),
   ('local function revealJapan(seconds)\n\tstormOff()\n\tstartPreviewCamera()\n',
    '-- JAPANFIX1_20261015: the reveal remembers what it changes; an aborted flight or a respawn puts it back, a landing hands over to JapanAtmosphere\n'
    'local previewSaved=nil\n'
    'local function previewRestore(secs)\n'
    '\tlocal s=previewSaved; previewSaved=nil\n'
    '\tif not s then return end\n'
    '\tTweenService:Create(Lighting,TweenInfo.new(secs or 2),{FogEnd=s.FogEnd,FogStart=s.FogStart}):Play()\n'
    '\tif atmo and s.density then TweenService:Create(atmo,TweenInfo.new(secs or 2),{Density=s.density,Haze=s.haze}):Play() end\n'
    '\tif clouds and s.cover~=nil then TweenService:Create(clouds,TweenInfo.new(secs or 2),{Cover=s.cover,Density=s.cdensity,Color=s.ccolor}):Play() end\n'
    'end\n'
    'local function revealJapan(seconds)\n'
    '\tlocal before=saved   -- (while the storm is still on, its snapshot is the true baseline)\n'
    '\tstormOff()\n\tstartPreviewCamera()\n'
    '\tpreviewSaved=previewSaved or {FogEnd=before and before.FogEnd or Lighting.FogEnd,FogStart=before and before.FogStart or Lighting.FogStart,\n'
    '\t\tdensity=before and before.density or (atmo and atmo.Density),haze=before and before.haze or (atmo and atmo.Haze),\n'
    '\t\tcover=before and before.cover or (clouds and clouds.Cover),cdensity=before and before.cdensity or (clouds and clouds.Density),ccolor=before and before.ccolor or (clouds and clouds.Color)}\n'),
   ('\tshowToast("The clouds are clearing… Welcome to Japan, SelBell.",5)\n',
    '\tshowToast("The clouds are clearing… Welcome to Japan, "..player.DisplayName..".",5)\n'),
   ('\t\t\tblack.BackgroundTransparency=1;black.BackgroundColor3=Color3.new(0,0,0);cc.Brightness=0\n\t\t\tshowToast("Explore Japan. The airport board takes you back to Provence.",7)\n',
    '\t\t\tblack.BackgroundTransparency=1;black.BackgroundColor3=Color3.new(0,0,0);cc.Brightness=0\n'
    '\t\t\tpreviewSaved=nil   -- (JAPANFIX1: JapanAtmosphere owns the lighting from here and restores the baseline when she leaves Japan)\n'
    '\t\t\tshowToast("Explore Japan. The airport board takes you back to Provence.",7)\n'),
   ('\t\t\tstormOff(); duckMusic(false, 3); vrCamStop();stopPreviewCamera();black.BackgroundColor3=Color3.new(0,0,0)\n',
    '\t\t\tstormOff(); duckMusic(false, 3); vrCamStop();stopPreviewCamera();previewRestore(2);black.BackgroundColor3=Color3.new(0,0,0)\n'),
   ('player.CharacterAdded:Connect(function() stopPreviewCamera();black.BackgroundColor3',
    'player.CharacterAdded:Connect(function() stopPreviewCamera();previewRestore(1);black.BackgroundColor3'),
 ]},
 {"name": "JapanEnvironment", "path": ["Workspace", "JapanMap", "JapanEnvironment"], "patches": [
   ('local PreviewAccess=require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))\n', fallback("", False)),
   (" busy=true;train:SetAttribute('InTransit',true);enablePrompts(false)\n local couldJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)\n local start=CFrame.new(point.Position.X,0,map:GetAttribute('Origin').Z+181)\n local finish=CFrame.new(destination.Position.X,0,map:GetAttribute('Origin').Z+181)\n",
    " local origin=map:GetAttribute('Origin')\n if typeof(origin)~='Vector3' then warn('Japan train: JapanMap has no Origin attribute') return end   -- (JAPANFIX1: checked before the train is marked busy)\n"
    " busy=true;train:SetAttribute('InTransit',true);enablePrompts(false)\n local couldJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)\n local start=CFrame.new(point.Position.X,0,origin.Z+181)\n local finish=CFrame.new(destination.Position.X,0,origin.Z+181)\n"),
   ("    character:PivotTo(CFrame.new(target+Vector3.new(0,4,0)))\n",
    "    pcall(player.RequestStreamAroundAsync,player,target,5)   -- (JAPANFIX1: the ground loads before the 5,700-stud hop, as TravelServer does)\n"
    "    if not (player.Parent and player.Character==character and hrp.Parent) then return end\n"
    "    character:PivotTo(CFrame.new(target+Vector3.new(0,4,0)))\n"),
 ]},
 {"name": "JapanAtmosphere", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanAtmosphere"], "patches": [
   ("local active=false\nlocal saved={}\nlocal function enter()\n saved.ClockTime=Lighting.ClockTime;saved.FogEnd=Lighting.FogEnd;saved.FogStart=Lighting.FogStart\n saved.Atmospheres={}\n for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare};a.Density=.08;a.Haze=0;a.Glare=.08 end end\n Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999\nend\nlocal function leave()\n if not saved.ClockTime then return end\n Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart\n for a,values in pairs(saved.Atmospheres or {}) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end\n saved={}\nend\n",
    "local active=false\n"
    "-- JAPANFIX1_20261015: the baseline is what the game loaded with (the look pass), taken ONCE here - never at enter(), which used to come\n"
    "-- after the balloon's reveal had already changed fog, atmosphere and clouds; the Clouds are part of it now\n"
    "local clouds=workspace.Terrain:FindFirstChildOfClass('Clouds')\n"
    "local saved={ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,Atmospheres={},Clouds=clouds and {Cover=clouds.Cover,Density=clouds.Density,Color=clouds.Color} or nil}\n"
    "for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare} end end\n"
    "local function enter()\n"
    " for a in pairs(saved.Atmospheres) do if a.Parent then a.Density=.08;a.Haze=0;a.Glare=.08 end end\n"
    " Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999\n"
    " if clouds and clouds.Parent then clouds.Cover=.08;clouds.Density=.1;clouds.Color=Color3.new(1,1,1) end\n"
    "end\n"
    "local function leave()\n"
    " Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart\n"
    " for a,values in pairs(saved.Atmospheres) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end\n"
    " if clouds and clouds.Parent and saved.Clouds then for k,v in pairs(saved.Clouds) do clouds[k]=v end end\n"
    "end\n"),
   ("local wheel=map:WaitForChild('TeaHills'):WaitForChild('Waterwheel')\nlocal base=wheel:GetPivot()\n",
    "local wheel,base=nil,nil   -- (JAPANFIX1: the lighting no longer waits for the wheel to stream in)\n"
    "task.spawn(function() local th=map:WaitForChild('TeaHills',60); wheel=th and th:WaitForChild('Waterwheel',600) or nil; if wheel then base=wheel:GetPivot() end end)\n"),
   (" if active then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end\n",
    " if active and wheel and base then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end\n"),
 ]},
 {"name": "HidePortoFromFrance", "path": ["StarterPlayer", "StarterPlayerScripts", "HidePortoFromFrance"], "patches": [
   ("\t\tlocal z = r.Position.Z\n\t\tif not active and z > IN_FRANCE_Z then active = true task.spawn(hideAll)\n",
    "\t\tlocal z = r.Position.Z\n\t\tif r.Position.X > 4500 then z = active and IN_FRANCE_Z or OUT_Z end   -- (JAPANFIX1: Japan is neither side - no sweep while there)\n\t\tif not active and z > IN_FRANCE_Z then active = true task.spawn(hideAll)\n"),
 ]},
 {"name": "HideFranceFromPorto", "path": ["StarterPlayer", "StarterPlayerScripts", "HideFranceFromPorto"], "patches": [
   ("\t\tlocal z=r.Position.Z\n\t\tif not active and z<IN_PORTO_Z then active=true task.spawn(hideAll)\n",
    "\t\tlocal z=r.Position.Z\n\t\tif r.Position.X>4500 then z=active and IN_PORTO_Z or OUT_Z end   -- (JAPANFIX1: Japan is neither side - no sweep while there)\n\t\tif not active and z<IN_PORTO_Z then active=true task.spawn(hideAll)\n"),
 ]},
 {"name": "JapanWaterAppearance", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanWaterAppearance"], "patches": [
   ("local inside=p and p.Position.X>4800", "local inside=p and Players.LocalPlayer.UserId==9611145467 and p.Position.X>4800 --[[JAPANFIX1: owner only]]"),
 ]},
 {"name": "JapanPreviewVisibility", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanPreviewVisibility"], "patches": [
   ("instance:IsA('Light') or instance:IsA('Clouds') then instance.Enabled=false",
    "instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then instance.Enabled=false --[[JAPANFIX1]]"),
   ("instance:IsA('Light') or instance:IsA('Clouds') then property='Enabled';expected=false",
    "instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then property='Enabled';expected=false"),
 ]},
]

# ---- self-test on the exports ----
chk = HERE / "check"; chk.mkdir(exist_ok=True)
luau = os.environ.get("LUAU_COMPILE")
for sc in SCRIPTS:
    src = (EXP / (sc["name"] + ".lua")).read_text(encoding="utf-8")
    assert MARK not in src, sc["name"]
    out = src
    for i, (f, r) in enumerate(sc["patches"]):
        assert out.count(f) == 1, f"{sc['name']} anchor {i + 1}: {out.count(f)} matches"
        out = out.replace(f, r)
    assert MARK in out
    (chk / (sc["name"] + "_japanfix1.lua")).write_text(out, encoding="utf-8")
    if luau:
        res = subprocess.run([luau, "--null", str(chk / (sc["name"] + "_japanfix1.lua"))], capture_output=True, text=True)
        assert "Error" not in (res.stdout + res.stderr), sc["name"] + "\n" + res.stdout + res.stderr
    print(f"self-test {sc['name']}: {len(src)} -> {len(out)} chars, {len(sc['patches'])} patches" + (", compiles" if luau else ""))

def L(s):
    assert "]====]" not in s
    return "[====[\n" + s + "]====]"
entries = []
for sc in SCRIPTS:
    pats = ", ".join("{" + L(f) + ", " + L(r) + "}" for f, r in sc["patches"])
    entries.append('{name = "%s", path = {%s}, patches = {%s}}' % (sc["name"], ", ".join('"%s"' % p for p in sc["path"]), pats))
lua = r'''-- japan_fix1.lua (job 105): Studio EDIT mode. The script-level fixes from the Japan survey (tools/japan/FINDINGS_japan_2026-10-15.md;
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
local SCRIPTS = {@@ENTRIES@@}
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
'''
assert lua.count("@@ENTRIES@@") == 1
lua = lua.replace("@@ENTRIES@@", ",\n".join(entries))
(HERE / "japan_fix1.lua").write_text(lua, encoding="utf-8")
print("japan_fix1.lua", len(lua.encode()), "bytes")
