#!/usr/bin/env python3
"""Builds tools/vr/install_vrwindow1.lua (job 40): workspace.VRWindow (Folder, attributes Distance/Width/Follow/Drop/Off)
with VRWindowClient from tools/vr/src. Nothing else is touched; desktop and phone unaffected (the script returns at once
without a headset). Undo: delete workspace.VRWindow. Run from the repo root: python3 tools/vr/make_install_vrwindow.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
client = (ROOT / "tools/vr/src/VRWindowClient.lua").read_text(encoding="utf-8")
lua = r'''-- vr/install_vrwindow1 (job 40): EDIT mode, re-runnable. The VR window: in a headset the flat-screen UI moves onto one
-- floating window that follows the head, visible with Roblox's control panel open or shut. Output lines "QQ VRW".
if game:GetService("RunService"):IsRunning() then warn("QQ VRW ABORT - Play mode") return end
local old = workspace:FindFirstChild("VRWindow"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "VRWindow"
F:SetAttribute("Yaw", 38); F:SetAttribute("Distance", 2.4); F:SetAttribute("Width", 1.9); F:SetAttribute("Follow", 4); F:SetAttribute("Drop", 0.12); F:SetAttribute("Off", false)
local c = Instance.new("Script"); c.Name = "VRWindowClient"; c.RunContext = Enum.RunContext.Client; c.Source = @@CLIENT@@; c.Parent = F
local f, err = loadstring(c.Source); if not f then warn("QQ VRW ABORT - VRWindowClient does not compile: " .. tostring(err)); F:Destroy(); return end
F.Parent = workspace
print(string.format("QQ VRW DONE: workspace.VRWindow with VRWindowClient (%d chars); Yaw 38, Distance 2.4, Width 1.9, Follow 4, Drop 0.12", #c.Source))
'''
lua = lua.replace("@@CLIENT@@", L(client))
(ROOT / "tools/vr/install_vrwindow1.lua").write_text(lua, encoding="utf-8")
print("install_vrwindow1.lua", len(lua.encode()), "chars; client", len(client.encode()))
