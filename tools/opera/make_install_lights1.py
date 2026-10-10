#!/usr/bin/env python3
"""Builds tools/opera/install_lights1.lua (job 68): workspace.OperaLights (Folder + OperaLightsClient) - the house lights go
down and spotlights come up over the opera singer and Nino the accordion player, for the player who pressed Listen, until the
aria ends. Nothing else is touched (PortoActivities' prompt and sound are read, not changed). Re-runnable.
Run from the repo root: python3 tools/opera/make_install_lights1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
client = (ROOT / "tools/opera/src/OperaLightsClient.lua").read_text(encoding="utf-8")
lua = r'''-- opera/install_lights1 (job 68): EDIT mode, re-runnable. The opera spotlight: for the player who presses Listen, the world
-- dims and warm spotlights come up over the singer and the accordion player until the aria ends. workspace.OperaLights
-- (Folder; attributes to tune) + OperaLightsClient. Undo: delete workspace.OperaLights. Output "QQ OPERA".
if game:GetService("RunService"):IsRunning() then warn("QQ OPERA ABORT - Play mode") return end
local singer = workspace:FindFirstChild("operasinger_squirrel_color")
local prompt = singer and singer:FindFirstChild("OperaPrompt", true)
local nino = workspace:FindFirstChild("accordion_squirrel_color")
if not nino then for _, d in ipairs(workspace:GetChildren()) do if d:IsA("Model") and d.Name:lower():find("accordion", 1, true) and d.Name:lower():find("color", 1, true) then nino = d break end end end
local old = workspace:FindFirstChild("OperaLights"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "OperaLights"
F:SetAttribute("Singer", "operasinger_squirrel_color"); F:SetAttribute("Accordion", nino and nino.Name or "accordion_squirrel_color")
F:SetAttribute("PromptName", "OperaPrompt"); F:SetAttribute("SoundName", "OperaSong")
F:SetAttribute("SpotHeight", 9); F:SetAttribute("SpotAngle", 55); F:SetAttribute("SpotBrightness", 18); F:SetAttribute("FillBrightness", 2.5); F:SetAttribute("BeamStrength", 0.26); F:SetAttribute("PoolStrength", 0.5)
F:SetAttribute("DimBrightness", 0.16); F:SetAttribute("DimExposure", 0.35); F:SetAttribute("DimAmbient", 0.5); F:SetAttribute("DimSun", 1.0); F:SetAttribute("FadeDown", 1.6); F:SetAttribute("FadeUp", 2.2); F:SetAttribute("Reach", 45)
local c = Instance.new("Script"); c.Name = "OperaLightsClient"; c.RunContext = Enum.RunContext.Client; c.Source = @@CLIENT@@; c.Parent = F
local f, err = loadstring(c.Source); if not f then warn("QQ OPERA ABORT - OperaLightsClient does not compile: " .. tostring(err)); F:Destroy(); return end
F.Parent = workspace
print(string.format("QQ OPERA DONE: workspace.OperaLights with OperaLightsClient (%d chars); singer %s (prompt %s); accordion player %s", #c.Source, singer and "found" or "NOT FOUND (operasinger_squirrel_color)", prompt and "found" or "not found yet (PortoActivities makes it at run time)", nino and nino:GetFullName() or "NOT FOUND - the spotlight will be on the singer only"))
'''
lua = lua.replace("@@CLIENT@@", L(client))
(ROOT / "tools/opera/install_lights1.lua").write_text(lua, encoding="utf-8")
print("install_lights1.lua", len(lua.encode()), "chars; client", len(client.encode()))
