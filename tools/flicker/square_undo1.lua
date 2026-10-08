-- flicker/square_undo1: EDIT mode. Puts back everything square_fix1 cut: each union with attr CSGJob = "square1" is
-- replaced by its original from ServerStorage.CSGBackup_Square (matched by CSGBackupId); the original's children come
-- back from the union. Prints what it restored. Output lines start with "QQ SQU".

if game:GetService("RunService"):IsRunning() then warn("QQ SQU ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("CSGBackup_Square")
if not backup then warn("QQ SQU nothing to undo: no ServerStorage.CSGBackup_Square") return end

local originals = {}
for _, p in ipairs(backup:GetChildren()) do
	if p:GetAttribute("CSGJob") == "square1" and p:GetAttribute("CSGBackupId") then originals[p:GetAttribute("CSGBackupId")] = p end
end

local restored, orphans = 0, 0
local unions = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("UnionOperation") and d:GetAttribute("CSGJob") == "square1" then table.insert(unions, d) end
end
local seen = {}
for _, u in ipairs(unions) do
	local id = u:GetAttribute("CSGBackupId")
	local orig = id and originals[id]
	if not orig then
		orphans += 1
		warn(string.format("QQ SQU no original for %s (id %s) - union left in place", u:GetFullName(), tostring(id)))
	else
		if not seen[id] then
			seen[id] = true
			for _, ch in ipairs(u:GetChildren()) do ch.Parent = orig end
			orig:SetAttribute("CSGJob", nil); orig:SetAttribute("CSGBackupId", nil); orig:SetAttribute("CSGOrigParent", nil)
			orig.Parent = u.Parent
			restored += 1
			print(string.format("QQ SQU restored %s", orig:GetFullName()))
		end
		u:Destroy()
	end
end
if #backup:GetChildren() == 0 then backup:Destroy() end
print(string.format("QQ SQU DONE: %d restored, %d unions without an original, %d unions removed", restored, orphans, #unions - orphans))
