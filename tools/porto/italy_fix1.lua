-- porto/italy_fix1 (job 18): EDIT mode. Fixes from the job 17 play test (Oct 9 2026):
--   SeaGlassServer: 4 of 8 finds lay on the seabed (the spot ray ignored water) -> the ray stops at the water surface.
--   SeaGlassClient: Bella's panel covered the HUD on a phone and sat under the Daily card -> UIScale on short screens,
--                   DisplayOrder 16 (Daily card 15, GoldenReveal 18).
--   PassportClient: the Porto Outings tab showed only "Porto Nocciola is new" -> it lists every Porto outing not yet
--                   stamped; the French batch card stays on the French tab.
-- First a READ-ONLY probe of the harbour bell (QQ BELL lines). Patches: exact finds with length guards, every result
-- compiled before anything is written; originals -> ServerStorage.HudBackup.*_pre_fix1. Output lines start with "QQ FIX".
if game:GetService("RunService"):IsRunning() then warn("QQ FIX ABORT - Play mode") return end

-- ---------- the bell probe (read-only) ----------
local function path(i) return i:GetFullName() end
local PPS = game:GetService("ProximityPromptService")
print(string.format("QQ BELL service Enabled=%s MaxPromptsVisible=%d StreamingEnabled=%s", tostring(PPS.Enabled), PPS.MaxPromptsVisible, tostring(workspace.StreamingEnabled)))
local nb = 0
for _, d in ipairs(workspace:GetDescendants()) do
	local n = d.Name:lower()
	if n:find("bell") and not n:find("bella") and (d:IsA("Model") or d:IsA("BasePart")) and not (d.Parent and d.Parent.Name:lower():find("bell")) then
		nb += 1
		if nb > 8 then break end
		local extra = d:IsA("Model") and ("PrimaryPart=" .. tostring(d.PrimaryPart and d.PrimaryPart.Name)) or d:IsA("BasePart") and string.format("Anchored=%s CanQuery=%s Transparency=%.2f", tostring(d.Anchored), tostring(d.CanQuery), d.Transparency) or ""
		print(string.format("QQ BELL %s | %s | %s | pivot %s", path(d), d.ClassName, extra, tostring(d:GetPivot().Position)))
		for _, c in ipairs(d:GetDescendants()) do
			if c:IsA("ProximityPrompt") or c:IsA("ClickDetector") then
				local parent = c.Parent
				print(string.format("QQ BELL   %s | parent %s (%s) | Enabled=%s Max=%.1f Hold=%.2f LOS=%s Style=%s Excl=%s Key=%s Click=%s Action=%q Object=%q",
					path(c), parent.Name, parent.ClassName, tostring(c.Enabled), c.MaxActivationDistance, c:IsA("ProximityPrompt") and c.HoldDuration or 0,
					c:IsA("ProximityPrompt") and tostring(c.RequiresLineOfSight) or "-", c:IsA("ProximityPrompt") and tostring(c.Style) or "-",
					c:IsA("ProximityPrompt") and tostring(c.Exclusivity) or "-", c:IsA("ProximityPrompt") and tostring(c.KeyboardKeyCode) or "-",
					c:IsA("ProximityPrompt") and tostring(c.ClickablePrompt) or "-", c:IsA("ProximityPrompt") and c.ActionText or "", c:IsA("ProximityPrompt") and c.ObjectText or ""))
			elseif c:IsA("LuaSourceContainer") then
				local en = c:IsA("BaseScript") and tostring(c.Enabled) or "-"
				local rc = c:IsA("Script") and tostring(c.RunContext) or "-"
				print(string.format("QQ BELL   %s | %s Enabled=%s RunContext=%s | %d chars", path(c), c.ClassName, en, rc, #c.Source))
				if #c.Source <= 2500 then print("QQ BELL   SOURCE " .. c.Name .. ":\n" .. c.Source) end
			elseif c:IsA("Sound") then
				print(string.format("QQ BELL   %s | Sound %s Volume=%.2f", path(c), c.SoundId, c.Volume))
			end
		end
	end
end
if nb == 0 then print("QQ BELL no model or part named *bell* in workspace") end

-- ---------- the patches ----------
local SS = game:GetService("ServerStorage")
local SG = workspace:FindFirstChild("SeaGlass")
local P = workspace:FindFirstChild("Passport")
local Sv, Cl, Pc = SG and SG:FindFirstChild("SeaGlassServer"), SG and SG:FindFirstChild("SeaGlassClient"), P and P:FindFirstChild("PassportClient")
for _, pair in ipairs({{Sv, "SeaGlass.SeaGlassServer"}, {Cl, "SeaGlass.SeaGlassClient"}, {Pc, "Passport.PassportClient"}}) do
	if not (pair[1] and pair[1]:IsA("LuaSourceContainer")) then warn("QQ FIX ABORT - missing " .. pair[2]) return end
end
local LEN = {[Sv] = 8223, [Cl] = 10372, [Pc] = 28101}
for s, n in pairs(LEN) do
	if #s.Source ~= n then warn(string.format("QQ FIX ABORT - %s.Source is %d chars, expected %d (already fixed, or changed since job 17); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {
	{Sv, "SeaGlassServer", {{[===[
tparams.IgnoreWater = true]===], [===[
tparams.IgnoreWater = false -- a ray that meets the sea stops at its surface (Material Water), so no piece lies underwater]===]}}},
	{Cl, "SeaGlassClient", {{[===[
gui.DisplayOrder = 7;]===], [===[
gui.DisplayOrder = 16;]===]}, {[===[
	panel.Size = UDim2.fromOffset(math.min(380, v.X - 24), math.min(h, v.Y - 16))
]===], [===[
	local sc = panel:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = panel
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
]===]}}},
	{Pc, "PassportClient", {{[===[
if showCities() then local fi,fd={},{} for _,id in ipairs(ids)do if cityOf(id)==city then fi[#fi+1]=id end end for _,id in ipairs(done)do if cityOf(id)==city then fd[#fd+1]=id end end ids,done=fi,fd end]===], [===[
if showCities() then local fi,fd={},{} for _,id in ipairs(ids)do if cityOf(id)==city then fi[#fi+1]=id end end for _,id in ipairs(done)do if cityOf(id)==city then fd[#fd+1]=id end end ids,done=fi,fd end
  if showCities() and city=="italy" then ids,done={},{} for _,e in ipairs(catalogue)do if e.area=="porto" then ids[#ids+1]=e.id;if journal[e.id]then done[#done+1]=e.id end end end end]===]}, {[===[
if J.batchDone(batch) and not (showCities() and city=="italy" and #ids==0) then]===], [===[
if J.batchDone(batch) and not (showCities() and city=="italy") then]===]}}},
}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, list = pt[1], pt[2], pt[3]
	local o = s.Source
	for i, p in ipairs(list) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ FIX ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ FIX ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ FIX ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder")
backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_fix1"
	if b:IsA("BaseScript") then b.Enabled = false end
	b.Parent = backup
	s.Source = o
end
print(string.format("QQ FIX DONE: SeaGlassServer %d, SeaGlassClient %d, PassportClient %d chars; backups ServerStorage.HudBackup.*_pre_fix1",
	#Sv.Source, #Cl.Source, #Pc.Source))
