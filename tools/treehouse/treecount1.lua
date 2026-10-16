-- treecount1.lua (runner 7, Oct 16 2026). Shannon: "are we able to check how many people have completed the treehouse thus far?" /
-- "please add treehouse counter". Patches workspace.Treehouse.TreehouseServer (exact strings, each anchor counted once; the original
-- cloned to ServerStorage.HudBackup.TreehouseServer_pre_treecount1; compiled before writing; idempotent by the TREECOUNT1 marker).
-- What it adds: one analytics event "TreehouseBuilt" per builder, ever - when a player finishes ("built now") and, for players who
-- finished before this existed, the next time they join ("built before"). Once per player through the save (Item_tree_counted, the same
-- AwardItems ledger the treehouse already uses for its pieces; no DataStore code). Creator Dashboard > Analytics > Custom events >
-- TreehouseBuilt (Field 1 = built now / built before, Field 2 = device). Events leave only a published place. Studio EDIT, then
-- publish. Output "QQ TREECOUNT1".
local s = workspace:FindFirstChild("Treehouse") and workspace.Treehouse:FindFirstChild("TreehouseServer")
if not (s and s:IsA("Script")) then print("QQ TREECOUNT1 ABORT: workspace.Treehouse.TreehouseServer not found") return end
local src = s.Source
if src:find("TREECOUNT1", 1, true) then print("QQ TREECOUNT1 already applied (marker present) - nothing changed") return end
print(string.format("QQ TREECOUNT1 source: %d bytes (expected 4806)", #src))
local EDITS = {
	{[==[local Players = game:GetService("Players")]==],
	 [==[local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")   -- TREECOUNT1: the builders counted for the Creator Dashboard
local RunService = game:GetService("RunService")]==]},
	{[==[local function has(p, id) return]==],
	 [==[local K1, K2 = Enum.AnalyticsCustomFieldKeys.CustomField01.Name, Enum.AnalyticsCustomFieldKeys.CustomField02.Name
local function counted(p, how)                     -- TREECOUNT1: one "TreehouseBuilt" event per builder, ever (Item_tree_counted on the save)
	if (tonumber(p:GetAttribute("Item_tree_counted")) or 0) >= 1 or (got[p] and got[p].counted) then return end
	got[p] = got[p] or {}; got[p].counted = true
	awardItems:Fire(p, "tree_counted", 1)
	local fields = {[K1] = how, [K2] = tostring(p:GetAttribute("FunnelDevice") or "unknown")}
	local ok, err = pcall(function() AnalyticsService:LogCustomEvent(p, "TreehouseBuilt", 1, fields) end)
	if RunService:IsStudio() then print("Treehouse: counted " .. p.Name .. " (" .. how .. ")" .. (ok and "" or (" - " .. tostring(err)))) end
end
local function has(p, id) return]==]},
	{[==[	if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n) end
end)]==],
	 [==[	if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n); counted(p, "built now") end
end)]==]},
	{[==[		if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n) end        -- (all twelve on the save but never paid: paid now)]==],
	 [==[		local before = (tonumber(p:GetAttribute("Item_tree_done")) or 0) >= 1
		if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n); counted(p, "built now") end        -- (all twelve on the save but never paid: paid now)
		if before then counted(p, "built before") end                                -- TREECOUNT1: finished before the counter existed]==]},
}
local out = src
for i, e in ipairs(EDITS) do
	local a, b = e[1], e[2]
	local n, pos = 0, 1
	while true do local f = out:find(a, pos, true); if not f then break end; n += 1; pos = f + 1 end
	if n ~= 1 then print(string.format("QQ TREECOUNT1 ABORT: anchor %d found %d times (want 1) - the script differs; nothing changed", i, n)) return end
	local f = out:find(a, 1, true)
	out = out:sub(1, f - 1) .. b .. out:sub(f + #a)
end
local fn, err = loadstring(out)
if not fn then print("QQ TREECOUNT1 ABORT: the patched script does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bk = s:Clone(); bk.Name = "TreehouseServer_pre_treecount1"; bk.Enabled = false; bk.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before treecount1") end)
s.Source = out
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after treecount1") end)
print(string.format("QQ TREECOUNT1 DONE: TreehouseServer patched (%d -> %d bytes): a TreehouseBuilt analytics event per builder (built now / built before); backup HudBackup.TreehouseServer_pre_treecount1. Publish, then restart servers.", #src, #out))
