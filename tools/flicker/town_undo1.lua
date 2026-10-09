-- flicker/town_undo1: EDIT mode. Puts back everything town_fix1 cut, pass by pass. Each union in workspace with attr
-- CSGJob = "town1" is swapped for its backup entry in ServerStorage.CSGBackup_Town (matched by CSGBackupId). If that entry
-- is itself an earlier cut (CSGIntermediate) it is pointed back at its own original (CSGRestoreFrom) and, when that earlier
-- cut was made by square_fix1 (CSGPrevJob = "square1"), handed back to square_undo1.lua. Output lines start with "QQ TWU".
local JOB, BACKUP = "town1", "CSGBackup_Town"
if game:GetService("RunService"):IsRunning() then warn("QQ TWU ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild(BACKUP)
if not backup then warn("QQ TWU nothing to undo: no ServerStorage." .. BACKUP) return end

local function entryById(id)
	if not id then return nil end
	for _, p in ipairs(backup:GetChildren()) do
		if p:GetAttribute("CSGJob") == JOB and p:GetAttribute("CSGBackupId") == id then return p end
	end
	return nil
end

local restored, round, stuck, handedBack = 0, 0, {}, 0
while round < 10 do
	round += 1
	local todo = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("UnionOperation") and d:GetAttribute("CSGJob") == JOB and not stuck[d] then table.insert(todo, d) end
	end
	local progress = 0
	-- parts that were retired whole (fully hidden): straight back to where they were
	for _, e in ipairs(backup:GetChildren()) do
		if e:GetAttribute("CSGRemoved") == JOB and not stuck[e] then
			local ref = e:FindFirstChild("CSGOrigParentRef")
			local parent = ref and ref.Value
			if not parent then
				stuck[e] = true
				warn(string.format("QQ TWU retired part %s has no parent to go back to (%s) - left in the backup", e.Name, tostring(e:GetAttribute("CSGOrigParent"))))
			else
				if ref then ref:Destroy() end
				e:SetAttribute("CSGRemoved", nil); e:SetAttribute("CSGOrigParent", nil)
				local more = ""
				if e:GetAttribute("CSGIntermediate") then
					local prev = e:GetAttribute("CSGPrevJob") or JOB
					e:SetAttribute("CSGBackupId", e:GetAttribute("CSGRestoreFrom")); e:SetAttribute("CSGJob", prev)
					e:SetAttribute("CSGRestoreFrom", nil); e:SetAttribute("CSGIntermediate", nil); e:SetAttribute("CSGPrevJob", nil)
					if prev == JOB then more = " (earlier pass, one more round)" else handedBack += 1; more = " (an earlier " .. prev .. " cut: run its undo to go further back)" end
				else
					e:SetAttribute("CSGJob", nil); e:SetAttribute("CSGBackupId", nil)
				end
				e.Parent = parent
				restored += 1; progress += 1
				print(string.format("QQ TWU round %d: %s put back whole%s", round, e:GetFullName(), more))
			end
		end
	end
	if #todo == 0 and progress == 0 then break end
	for _, u in ipairs(todo) do
		local e = entryById(u:GetAttribute("CSGBackupId"))
		if not e then
			stuck[u] = true
			warn(string.format("QQ TWU no original for %s (id %s) - left in place", u:GetFullName(), tostring(u:GetAttribute("CSGBackupId"))))
		else
			for _, ch in ipairs(u:GetChildren()) do ch.Parent = e end
			e:SetAttribute("CSGOrigParent", nil)
			local more = ""
			if e:GetAttribute("CSGIntermediate") then
				local prev = e:GetAttribute("CSGPrevJob") or JOB
				e:SetAttribute("CSGBackupId", e:GetAttribute("CSGRestoreFrom"))
				e:SetAttribute("CSGJob", prev)
				e:SetAttribute("CSGRestoreFrom", nil); e:SetAttribute("CSGIntermediate", nil); e:SetAttribute("CSGPrevJob", nil)
				if prev == JOB then more = " (earlier pass, one more round)" else handedBack += 1; more = " (an earlier " .. prev .. " cut: run its undo to go further back)" end
			else
				e:SetAttribute("CSGJob", nil); e:SetAttribute("CSGBackupId", nil); e:SetAttribute("CSGRestoreFrom", nil); e:SetAttribute("CSGIntermediate", nil); e:SetAttribute("CSGPrevJob", nil)
			end
			e.Parent = u.Parent
			u:Destroy()
			restored += 1; progress += 1
			if restored <= 30 or restored % 50 == 0 then print(string.format("QQ TWU round %d: %s <- [%s]%s", round, e:GetFullName(), e.ClassName, more)) end
		end
	end
	if progress == 0 then break end
end
local left = 0
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("UnionOperation") and d:GetAttribute("CSGJob") == JOB then left += 1 end end
if #backup:GetChildren() == 0 then backup:Destroy() end
print(string.format("QQ TWU DONE: %d swaps over %d round(s), %d %s union(s) still in the world, %d handed back to an earlier job's undo, backup entries left: %d",
	restored, round, left, JOB, handedBack, backup.Parent and #backup:GetChildren() or 0))
