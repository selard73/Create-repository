#!/usr/bin/env python3
"""vr_ride1.lua: in VR the balloon ride hazes the far view and runs lighter (Shannon, Oct 10).

The readout of job 79 showed everything loaded (288/288, 12/12) while the funicolare and the far hills still "came in and
out" on the headset: the Quest's renderer at a low automatic quality step drops distant objects, and the step bounces.
Patch of the live 32702-char BalloonClient (exact strings; backup HudBackup.BalloonClient_pre_vrride1):
  - snapshot(): the storm's one-time Lighting snapshot, now shared;
  - hazeOn() at boarding, VR only: shadows off for the ride (VRShadowsOff true), fog from VRHazeStart 350 to VRHazeEnd 900
    (0 = none; with an Atmosphere present its Haze goes to VRHazeAtmo 2.5 instead); the storm overrides it later and
    stormOff (run at home on every ride) puts everything back from the snapshot, shadows included;
  - the wind streaks at VRWindRate 36 instead of 90, every bolt only with VRBoltShare 0.5 in VR.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SRC = (HERE / "src" / "BalloonClient.lua").read_text(encoding="utf-8")
assert len(SRC) == 32702, len(SRC)

def patch(src, old, new):
    assert src.count(old) == 1, (src.count(old), old[:80])
    return src.replace(old, new)

NEW = SRC
# the snapshot, shared
SNAP = ('\tif not saved then saved = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,\n'
        '\t\tdensity = atmo and atmo.Density, haze = atmo and atmo.Haze, color = atmo and atmo.Color, cover = clouds and clouds.Cover, cdensity = clouds and clouds.Density, ccolor = clouds and clouds.Color} end\n')
assert NEW.count(SNAP) == 1
NEW = patch(NEW, 'local function stormOn(secs)\n' + SNAP,
            '-- the lighting as it was before the ride touched it (the storm and, in VR, the haze share one snapshot)\n'
            'local function snapshot()\n' + SNAP + 'end\n'
            'local function stormOn(secs)\n\tsnapshot()\n')
# lighter in VR: the wind streaks and the lightning
NEW = patch(NEW, 'wind.Enabled = false; wind.Rate = 90; wind.Lifetime',
            'wind.Enabled = false; wind.Rate = VR and num("VRWindRate", 36) or 90; wind.Lifetime')
NEW = patch(NEW, '\t\t\tbolt(b and b.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero)\n',
            '\t\t\tif not VR or math.random() < num("VRBoltShare", 0.5) then bolt(b and b.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero) end   -- (fewer bolts on a headset)\n')
# the shadows come back with the rest
NEW = patch(NEW, '\tLighting.Ambient = saved.Ambient\n',
            '\tLighting.Ambient = saved.Ambient\n'
            '\tif saved.shadows ~= nil then Lighting.GlobalShadows = saved.shadows end\n')
# hazeOn after stormOff, called at boarding
NEW = patch(NEW, '\tsaved = nil\nend\n\n-- ---------- smooth flight ----------\n',
            '\tsaved = nil\nend\n'
            '-- IN VR THE FAR VIEW IS HAZED AND THE RIDE RUNS LIGHTER (Shannon, Oct 10: on the headset the funicolare and the far hills\n'
            '-- "come in and out" with everything loaded - the Quest\'s renderer at a low quality step, and the step bounces). A haze\n'
            '-- hides the popping; no shadows, fewer streaks and bolts keep the frame rate up so the step holds. Attributes on the\n'
            '-- folder: VRHazeStart 350, VRHazeEnd 900 (0 = no haze; with an Atmosphere present, which makes the Lighting fog a dead letter,\n'
            '-- its Density goes to at least VRHazeDensity 0.55 and its Haze to VRHazeAtmo 2.5 instead), VRShadowsOff true, VRWindRate 36,\n'
            '-- VRBoltShare 0.5. The storm takes over later; stormOff (at home, and on a respawn) puts it all back.\n'
            'local function hazeOn()\n'
            '\tif not VR then return end\n'
            '\tsnapshot()\n'
            '\tif F:GetAttribute("VRShadowsOff") ~= false then if saved.shadows == nil then saved.shadows = Lighting.GlobalShadows end; Lighting.GlobalShadows = false end\n'
            '\tlocal hEnd = num("VRHazeEnd", 900)\n'
            '\tif hEnd <= 0 then return end\n'
            '\tif atmo then TweenService:Create(atmo, TweenInfo.new(3, Enum.EasingStyle.Sine), {Haze = num("VRHazeAtmo", 2.5), Density = math.max(atmo.Density, num("VRHazeDensity", 0.55))}):Play()\n'
            '\telse TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), {FogStart = math.min(num("VRHazeStart", 350), hEnd - 50), FogEnd = hEnd}):Play() end\n'
            'end\n'
            '\n-- ---------- smooth flight ----------\n')
NEW = patch(NEW, 'player.CharacterAdded:Connect(function() flying = false; if storming then stormOff() end;',
            'player.CharacterAdded:Connect(function() flying = false; if storming or saved then stormOff() end;')   # (the VR haze too - review)
NEW = patch(NEW, '\t\tif name == "board" then flying = true; vrCamStart() end\n',
            '\t\tif name == "board" then flying = true; vrCamStart(); hazeOn() end\n')
assert ']===]' not in NEW
OLD_LEN, NEW_LEN = len(SRC), len(NEW)

INSTALLER = f'''-- vr_ride1.lua (Studio EDIT mode; re-running is a no-op). Job 80.
-- In VR the balloon ride hazes the far view and runs lighter (Shannon, Oct 10: the funicolare and the far hills "come in and
-- out" on the headset with everything loaded - the Quest's renderer, not streaming). workspace.BalloonField.BalloonClient
-- {OLD_LEN} -> {NEW_LEN} chars (exact-string patch; backup HudBackup.BalloonClient_pre_vrride1). Attributes to tune on
-- BalloonField: VRHazeStart 350, VRHazeEnd 900 (0 = no haze), VRShadowsOff true, VRWindRate 36, VRBoltShare 0.5.
-- Undo: BalloonClient.Source = HudBackup.BalloonClient_pre_vrride1.Source. No publish.
local SS = game:GetService("ServerStorage")
local bf = workspace:FindFirstChild("BalloonField"); local bc = bf and bf:FindFirstChild("BalloonClient")
if not bc then print("QQ VRRIDE ABORT: workspace.BalloonField.BalloonClient not found") return end
local NEW = [===[
{NEW}]===]
if #bc.Source == {NEW_LEN} and bc.Source == NEW then print("QQ VRRIDE DONE (already installed): BalloonClient {NEW_LEN}") return end
if #bc.Source ~= {OLD_LEN} then print(string.format("QQ VRRIDE ABORT: BalloonClient is %d chars, expected {OLD_LEN} (not the job 56 text; export it first); nothing changed", #bc.Source)) return end
local f, err = loadstring(NEW); if not f then print("QQ VRRIDE ABORT: the new client does not compile: " .. tostring(err)) return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("BalloonClient_pre_vrride1") then local b = Instance.new("ModuleScript"); b.Name = "BalloonClient_pre_vrride1"; b.Source = bc.Source; b.Parent = hb end
bc.Source = NEW
for k, v in pairs({{VRHazeStart = 350, VRHazeEnd = 900, VRHazeAtmo = 2.5, VRHazeDensity = 0.55, VRWindRate = 36, VRBoltShare = 0.5}}) do if bf:GetAttribute(k) == nil then bf:SetAttribute(k, v) end end
if bf:GetAttribute("VRShadowsOff") == nil then bf:SetAttribute("VRShadowsOff", true) end
local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
print(string.format("QQ VRRIDE DONE: BalloonClient %d -> %d chars (backup HudBackup.BalloonClient_pre_vrride1); haze %s; Lighting has %s", {OLD_LEN}, #bc.Source,
	atmo and "by Atmosphere.Haze (an Atmosphere is present)" or "by Lighting fog 350..900", atmo and ("an Atmosphere (Density " .. tostring(atmo.Density) .. ", Haze " .. tostring(atmo.Haze) .. ")") or "no Atmosphere"))
'''
(HERE / "vr_ride1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
(HERE / "src" / "BalloonClient_vrride1.lua").write_text(NEW, encoding="utf-8", newline="\n")
print("vr_ride1.lua written:", OLD_LEN, "->", NEW_LEN)
