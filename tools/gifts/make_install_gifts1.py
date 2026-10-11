#!/usr/bin/env python3
"""install_gifts1.lua: the Gifts system (Shannon, Oct 10 2026) - workspace.Gifts {GiftsServer, GiftsClient} and the
remotes ReplicatedStorage.GiftsAction (RemoteFunction) / GiftsEvent (RemoteEvent). Re-runnable: an existing Gifts folder
is replaced (its scripts kept in ServerStorage.HudBackup.Gifts_pre_<n>). Attributes on the folder (tune live):
GroupId 969906332, CommunityAcorns 150, BoostMaxGain 150, LikeReward "backpack", BoostOn true, PopupDelay 180 (the fallback;
the card normally follows the first squirrel found), FirstFind true, AutoPopup true.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src" / "GiftsServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "GiftsClient.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER and "]===]" not in CLIENT
# the phone interact pill beside the head (workspace.PromptUI.PromptClient): with the HUD column at the right edge it fell back
# over the Purse / Squirrels squares (runner 6, Oct 11); it now tries the head's left side first. Exact string, guarded.
P_OLD = """	if not best then best = {math.clamp(x0, 4, math.max(4, vs.X - w - 4)), math.clamp(y0, h + 4, vs.Y - 4)} end
	headStack.Position = UDim2.fromOffset(best[1], best[2])"""
P_NEW = """	-- (Oct 11: no room right of the head - on a phone the HUD column stands at the right edge - so try the head's left side,
	-- and fall back there rather than over the column)
	local xl = (on and p.Z > 0) and (p.X - 30 - w) or 4
	if not best then
		for _, d in ipairs({{0, 0}, {0, -12}, {0, -24}, {-16, 0}, {0, 16}, {0, 48}}) do
			if fits(xl + d[1], y0 + d[2]) then best = {xl + d[1], y0 + d[2]} break end
		end
	end
	if not best then best = {math.clamp(xl, 4, math.max(4, vs.X - w - 4)), math.clamp(y0, h + 4, vs.Y - 4)} end
	headStack.Position = UDim2.fromOffset(best[1], best[2])"""
P_MARK = "so try the head's left side"
for x in (P_OLD, P_NEW): assert "]==]" not in x
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
-- the phone pill patch, checked before anything changes
local pu = workspace:FindFirstChild("PromptUI"); local pc = pu and pu:FindFirstChild("PromptClient")
local P_OLD, P_NEW = [==[{P_OLD}]==], [==[{P_NEW}]==]
local pcOut, pcNote = nil, nil
if not pc then pcNote = "PromptClient not found, pill left"
elseif pc.Source:find([==[{P_MARK}]==], 1, true) then pcNote = "PromptClient already patched (" .. #pc.Source .. ")"
else
	local n, i = 0, 1
	while true do local a, b = pc.Source:find(P_OLD, i, true); if not a then break end; n += 1; i = b + 1 end
	if n ~= 1 then print(string.format("QQ GIFTS ABORT: PromptClient (%d chars) pill anchor found %d times (need 1); nothing changed", #pc.Source, n)) return end
	local a, b = pc.Source:find(P_OLD, 1, true); pcOut = pc.Source:sub(1, a - 1) .. P_NEW .. pc.Source:sub(b + 1)
	local f, err = loadstring(pcOut); if not f then print("QQ GIFTS ABORT: the patched PromptClient does not compile: " .. tostring(err)) return end
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
local defaults = {{GroupId = 969906332, CommunityAcorns = 150, BoostMaxGain = 150, LikeReward = "backpack", BoostOn = true, PopupDelay = 180, FirstFind = true, AutoPopup = true}}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local s = Instance.new("Script"); s.Name = "GiftsServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "GiftsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
if pcOut then
	local hb2 = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb2.Name = "HudBackup"; hb2.Parent = SS
	if not hb2:FindFirstChild("PromptClient_pre_pill2") then local bk = pc:Clone(); bk.Name = "PromptClient_pre_pill2"; bk.Enabled = false; bk.Parent = hb2 end
	local was = #pc.Source; pc.Source = pcOut
	pcNote = string.format("PromptClient %d -> %d, the phone pill tries the head's left side (backup HudBackup.PromptClient_pre_pill2)", was, #pc.Source)
end
print(string.format("QQ GIFTS DONE: workspace.Gifts (GiftsServer %d, GiftsClient %d chars; GroupId %s, CommunityAcorns %s, BoostMaxGain %s, LikeReward %s, PopupDelay %s, FirstFind %s, AutoPopup %s, BoostOn %s)%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("GroupId")), tostring(F:GetAttribute("CommunityAcorns")), tostring(F:GetAttribute("BoostMaxGain")), tostring(F:GetAttribute("LikeReward")), tostring(F:GetAttribute("PopupDelay")), tostring(F:GetAttribute("FirstFind")), tostring(F:GetAttribute("AutoPopup")), tostring(F:GetAttribute("BoostOn")),
	(old and ("; the old Gifts folder is HudBackup." .. old.Name) or "") .. "; " .. tostring(pcNote)))
'''
(HERE / "install_gifts1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_gifts1.lua written:", len(INSTALLER))
