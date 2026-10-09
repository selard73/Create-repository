-- porto/groves_music2 (job 21): EDIT mode. Shannon, Oct 9: the Groves music -> 130260682627466 (it was 1848102847 since
-- job 15). Finds every attribute on workspace.MapMusic and every Sound under it that holds 1848102847 and puts the new id
-- in the same format (number, or "rbxassetid://..." string). The id it replaces goes to attr PrevSoundId_groves.
-- Output lines start with "QQ GRV".
if game:GetService("RunService"):IsRunning() then warn("QQ GRV ABORT - Play mode") return end
local OLD, NEW = "1848102847", "130260682627466"
local M = workspace:FindFirstChild("MapMusic")
if not M then warn("QQ GRV ABORT - no workspace.MapMusic") return end
local hits = {}
for k, v in pairs(M:GetAttributes()) do
	if k ~= "OldSoundId_Oct9" and k ~= "PrevSoundId_groves" and tostring(v):find(OLD, 1, true) then table.insert(hits, {M, k, v}) end
end
for _, d in ipairs(M:GetDescendants()) do
	if d:IsA("Sound") and d.SoundId:find(OLD, 1, true) then table.insert(hits, {d, "SoundId", d.SoundId}) end
end
if #hits == 0 then
	for k, v in pairs(M:GetAttributes()) do print("QQ GRV attr " .. k .. " = " .. tostring(v)) end
	warn("QQ GRV ABORT - nothing on MapMusic holds " .. OLD .. " (attributes listed above); nothing changed") return
end
for _, h in ipairs(hits) do
	local obj, key, v = h[1], h[2], h[3]
	local new = type(v) == "number" and tonumber(NEW) or (tostring(v):gsub(OLD, NEW))
	if key == "SoundId" then obj.SoundId = new else obj:SetAttribute(key, new) end
	M:SetAttribute("PrevSoundId_groves", tostring(v))
	print(string.format("QQ GRV DONE: %s.%s %s -> %s", obj:GetFullName(), key, tostring(v), tostring(new)))
end
