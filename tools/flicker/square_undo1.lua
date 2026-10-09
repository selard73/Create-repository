-- flicker/square_undo1: EDIT mode. Puts back everything square_fix1 cut, pass by pass. Each union in workspace with attr
-- CSGJob = "square1" is swapped for its backup entry in ServerStorage.CSGBackup_Square (matched by CSGBackupId). If that
-- entry is itself a cut union from an earlier pass (a part cut twice), it is swapped again next round: by CSGRestoreFrom
-- when the pass recorded it, else by the one same-named non-union original from the same parent (the Oct 8 passes 1 and
-- 2 on the Piazza slab predate CSGRestoreFrom). Loops until the originals are back. Output lines start with "QQ SQU".
if game:GetService("RunService"):IsRunning() then warn("QQ SQU ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("CSGBackup_Square")
if not backup then warn("QQ SQU nothing to undo: no ServerStorage.CSGBackup_Square") return end

local function entries()
	local list = {}
	for _, p in ipairs(backup:GetChildren()) do if p:GetAttribute("CSGJob") == "square1" then table.insert(list, p) end end
	return list
end
local function entryById(id)
	if not id then return nil end
	for _, p in ipairs(entries()) do if p:GetAttribute("CSGBackupId") == id then return p end end
	return nil
end
local function originalByName(u)   -- fallback for a twice-cut part whose first pass did not record CSGRestoreFrom
	local found = {}
	for _, p in ipairs(entries()) do
		if not p:IsA("UnionOperation") and p.Name == u.Name and p:GetAttribute("CSGOrigParent") == u.Parent:GetFullName() then table.insert(found, p) end
	end
	return found[1], #found
end
local function isIntermediate(e)
	if e:GetAttribute("CSGIntermediate") then return true end
	return e:IsA("UnionOperation") and e:GetAttribute("CSGCutFrom") == e.Name   -- a cut made by this job, before the attr existed
end

local restored, round, stuck = 0, 0, {}
while round < 10 do
	round += 1
	local todo = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("UnionOperation") and d:GetAttribute("CSGJob") == "square1" and not stuck[d] then table.insert(todo, d) end
	end
	if #todo == 0 then break end
	local progress = 0
	for _, u in ipairs(todo) do
		local e = entryById(u:GetAttribute("CSGBackupId"))
		local nCand = 0
		if not e then e, nCand = originalByName(u); if nCand ~= 1 then e = nil end end
		if not e then
			stuck[u] = true
			warn(string.format("QQ SQU no original for %s (id %s, %d same-named candidates) - left in place", u:GetFullName(), tostring(u:GetAttribute("CSGBackupId")), nCand))
		else
			for _, ch in ipairs(u:GetChildren()) do ch.Parent = e end
			e:SetAttribute("CSGOrigParent", nil)
			if isIntermediate(e) then
				-- back in the world but still a cut: point it at its own original (or leave it to the name fallback) and go round again
				e:SetAttribute("CSGBackupId", e:GetAttribute("CSGRestoreFrom"))
				e:SetAttribute("CSGRestoreFrom", nil); e:SetAttribute("CSGIntermediate", nil)
			else
				e:SetAttribute("CSGJob", nil); e:SetAttribute("CSGBackupId", nil); e:SetAttribute("CSGRestoreFrom", nil); e:SetAttribute("CSGIntermediate", nil)
			end
			e.Parent = u.Parent
			u:Destroy()
			restored += 1; progress += 1
			print(string.format("QQ SQU round %d: %s <- %s [%s]%s", round, e:GetFullName(), e.Name, e.ClassName, isIntermediate(e) and " (earlier pass, one more round)" or ""))
		end
	end
	if progress == 0 then break end
end
local left = 0
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("UnionOperation") and d:GetAttribute("CSGJob") == "square1" then left += 1 end end
if #backup:GetChildren() == 0 then backup:Destroy() end
print(string.format("QQ SQU DONE: %d swaps over %d round(s), %d cut union(s) still in the world, backup entries left: %d", restored, round, left, backup.Parent and #backup:GetChildren() or 0))
