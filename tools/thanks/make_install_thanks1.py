#!/usr/bin/env python3
"""install_thanks1.lua (job 92): workspace.Thanks {ThanksEvent (RemoteEvent), Gifts (Folder of StringValues: Name = username,
Value = acorns, optional attributes Id / Note), ThanksServer, ThanksClient (RunContext Client)}. Attributes: Title, DefaultNote,
Delay 8, MaxGift 5000. Re-runnable: an old Thanks folder's Gifts are carried over and the old scripts go to HudBackup.
Edit NAMES / ACORNS below (or add StringValues in Studio later) before generating."""
import pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "ThanksServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "ThanksClient.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER and "]===]" not in CLIENT
# the first three gifts: usernames go here (Shannon supplies them); Id "note1" so a later gift can be "note2"
NAMES = [n for n in (HERE / "names.txt").read_text(encoding="utf-8").split() if n.strip()] if (HERE / "names.txt").exists() else []
ACORNS = 1000
GIFT_ID = "note1"
NOTE = "Thank you for writing to the mayor! Your letter made our day."
for n in NAMES: assert all(ch.isalnum() or ch == "_" for ch in n), n
lines = "\n".join('\t{name = "%s", acorns = %d},' % (n, ACORNS) for n in NAMES)   # (a value in the f-string: single braces)
INSTALLER = f'''-- install_thanks1.lua (Studio EDIT mode; re-runnable). Job 92: acorn thank-you gifts paid the next time a named player joins.
-- workspace.Thanks: Gifts (StringValues: Name = username, Value = acorns; attributes Id, Note), ThanksServer ({len(SERVER)} chars),
-- ThanksClient ({len(CLIENT)} chars), ThanksEvent. To add a gift later: a StringValue under workspace.Thanks.Gifts, no code. Undo:
-- delete workspace.Thanks (gifts already paid stay paid: Item_thanks_<id> on the player's save). No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
for _, need in ipairs({{"AwardItems", "AwardAcorns"}}) do if not RS:FindFirstChild(need) then print("QQ THANKS ABORT: ReplicatedStorage." .. need .. " not found") return end end
local SERVER = [===[
{SERVER}]===]
local CLIENT = [===[
{CLIENT}]===]
for _, pair in ipairs({{{{"server", SERVER}}, {{"client", CLIENT}}}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ THANKS ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local GIFTS = {{
{lines}
}}
local old = workspace:FindFirstChild("Thanks")
local F = Instance.new("Folder"); F.Name = "Thanks"
F:SetAttribute("Title", "A thank-you from the mayor"); F:SetAttribute("DefaultNote", [==[{NOTE}]==]); F:SetAttribute("Delay", 8); F:SetAttribute("MaxGift", 5000)
local gifts = Instance.new("Folder"); gifts.Name = "Gifts"; gifts.Parent = F
local carried = 0
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local og = old:FindFirstChild("Gifts")
	if og then for _, v in ipairs(og:GetChildren()) do if v:IsA("StringValue") then v:Clone().Parent = gifts; carried += 1 end end end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Thanks_pre_" .. n) do n += 1 end
	old.Name = "Thanks_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local added = 0
for _, g in ipairs(GIFTS) do
	local dup = false
	for _, v in ipairs(gifts:GetChildren()) do if v.Name:lower() == g.name:lower() and (v:GetAttribute("Id") or "") == "{GIFT_ID}" then dup = true end end
	if not dup then local v = Instance.new("StringValue"); v.Name = g.name; v.Value = tostring(g.acorns); v:SetAttribute("Id", "{GIFT_ID}"); v.Parent = gifts; added += 1 end
end
local ev = Instance.new("RemoteEvent"); ev.Name = "ThanksEvent"; ev.Parent = F
local s = Instance.new("Script"); s.Name = "ThanksServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "ThanksClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local names = {{}}
for _, v in ipairs(gifts:GetChildren()) do table.insert(names, v.Name .. "=" .. v.Value) end
print(string.format("QQ THANKS DONE: workspace.Thanks (server %d, client %d chars); gifts: %s (%d added, %d carried over)%s", #s.Source, #c.Source, table.concat(names, ", "), added, carried, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
(HERE / "install_thanks1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_thanks1.lua written:", len(INSTALLER), "gifts:", NAMES or "(none yet: put usernames in tools/thanks/names.txt, one per line)")
