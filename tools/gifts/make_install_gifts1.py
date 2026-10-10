#!/usr/bin/env python3
"""install_gifts1.lua: the Gifts system (Shannon, Oct 10 2026) - workspace.Gifts {GiftsServer, GiftsClient} and the
remotes ReplicatedStorage.GiftsAction (RemoteFunction) / GiftsEvent (RemoteEvent). Re-runnable: an existing Gifts folder
is replaced (its scripts kept in ServerStorage.HudBackup.Gifts_pre_<n>). Attributes on the folder (tune live):
GroupId 969906332, CommunityAcorns 150, BoostMaxGain 150, LikeReward "backpack", BoostOn true, PopupDelay 90, AutoPopup true.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src" / "GiftsServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "GiftsClient.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER and "]===]" not in CLIENT
INSTALLER = f'''-- install_gifts1.lua (Studio EDIT mode; re-runnable). Job 87. The Gifts system: like + favourite + notifications -> the
-- Backpack (on trust), join the community -> acorns (checked), invite a friend -> double acorns while you play together
-- (checked by the friend's join data). workspace.Gifts with GiftsServer ({len(SERVER)} chars) and GiftsClient ({len(CLIENT)} chars);
-- ReplicatedStorage.GiftsAction / GiftsEvent. Undo: delete workspace.Gifts and the two remotes. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
for _, need in ipairs({{"AwardItems", "AwardAcorns"}}) do if not RS:FindFirstChild(need) then print("QQ GIFTS ABORT: ReplicatedStorage." .. need .. " not found (the shop / acorn system must be in)") return end end
local SERVER = [===[
{SERVER}]===]
local CLIENT = [===[
{CLIENT}]===]
for _, pair in ipairs({{{{"server", SERVER}}, {{"client", CLIENT}}}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ GIFTS ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local act = RS:FindFirstChild("GiftsAction"); if not act then act = Instance.new("RemoteFunction"); act.Name = "GiftsAction"; act.Parent = RS end
local ev = RS:FindFirstChild("GiftsEvent"); if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "GiftsEvent"; ev.Parent = RS end
local old = workspace:FindFirstChild("Gifts")
local attrs = {{}}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Gifts_pre_" .. n) do n += 1 end
	old.Name = "Gifts_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "Gifts"
local defaults = {{GroupId = 969906332, CommunityAcorns = 150, BoostMaxGain = 150, LikeReward = "backpack", BoostOn = true, PopupDelay = 90, AutoPopup = true}}
for k, v in pairs(defaults) do F:SetAttribute(k, attrs[k] ~= nil and attrs[k] or v) end
local s = Instance.new("Script"); s.Name = "GiftsServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "GiftsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ GIFTS DONE: workspace.Gifts (GiftsServer %d, GiftsClient %d chars; GroupId %s, CommunityAcorns %s, BoostMaxGain %s, LikeReward %s, PopupDelay %s)%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("GroupId")), tostring(F:GetAttribute("CommunityAcorns")), tostring(F:GetAttribute("BoostMaxGain")), tostring(F:GetAttribute("LikeReward")), tostring(F:GetAttribute("PopupDelay")),
	old and ("; the old Gifts folder is HudBackup." .. old.Name) or ""))
'''
(HERE / "install_gifts1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_gifts1.lua written:", len(INSTALLER))
