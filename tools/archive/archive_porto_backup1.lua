-- archive_porto_backup1.lua - Studio EDIT mode. Removes ServerStorage.PortoEnvironmentBackup_20261001 from the place (Shannon,
-- Oct 15 2026: publishes hang; survey104 / probe_serverstorage: that one folder is 291,576 of ServerStorage's 318,798 instances - 91%
-- of what is not the live game, four times the live Porto map - and it rides every save and publish). It is Codex's Oct 1-3 "Before..."
-- copies of Porto's buildings, nothing the live game reads. Every earlier save of the place still holds it (the place's version
-- history on Roblox), so this is recoverable. Prints the instance counts before and after; then SHE saves (File > Save to Roblox) and
-- publishes. Output "QQ ARCHIVE".
if game:GetService("RunService"):IsRunning() then print("QQ ARCHIVE ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local function count(o) return #o:GetDescendants() end
local before = count(SS)
local f = SS:FindFirstChild("PortoEnvironmentBackup_20261001")
if not f then print(string.format("QQ ARCHIVE nothing to do: no PortoEnvironmentBackup_20261001 (ServerStorage %d descendants)", before)) return end
local n = count(f)
local kids = {}
for _, c in ipairs(f:GetChildren()) do table.insert(kids, c.Name) end
print(string.format("QQ ARCHIVE PortoEnvironmentBackup_20261001: %d descendants in %d children (%s%s)", n, #kids, table.concat(kids, ", ", 1, math.min(8, #kids)), #kids > 8 and ", ..." or ""))
f:Destroy()
local after = count(SS)
local total = #game:GetDescendants()
print(string.format("QQ ARCHIVE DONE: ServerStorage %d -> %d descendants; the whole place now %d instances. NEXT: File > Save to Roblox, wait for it, then Publish.", before, after, total))
