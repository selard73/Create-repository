-- survey72.lua - READ-ONLY survey (Studio EDIT mode, execute as one script). Changes nothing, saves nothing.
-- Shannon's VR notes of Oct 10 morning: (1) the interact pill is missing in VR for the piazza race and the opera singer,
-- (2) every Club Rana frog is tipped onto its face, (3) from the balloon only the funicolare's rails show.
-- Prints "QQ S72 ..." lines; send them all (unchanged) to the cloud session.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local function ori(cf) local x, y, z = cf:ToOrientation() return string.format("(%.0f,%.0f,%.0f)", math.deg(x), math.deg(y), math.deg(z)) end
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local function attrs(o) local ok, s = pcall(function() return HttpService:JSONEncode(o:GetAttributes()) end) return ok and s or "?" end
local out = {}
local function say(fmt, ...) table.insert(out, "QQ S72 " .. string.format(fmt, ...)) end

-- ---------- (1) prompts ----------
local pu = workspace:FindFirstChild("PromptUI"); local pc = pu and pu:FindFirstChild("PromptClient")
say("PromptClient: %s, %d chars; PromptUI attrs %s", pc and (pc.ClassName .. "/" .. tostring(pc.RunContext)) or "MISSING", pc and #pc.Source or 0, pu and attrs(pu) or "-")
local function promptLine(tag, p)
	local par = p.Parent
	say("%s: %s | Style %s Enabled %s Dist %d LoS %s Hold %.1f Key %s Pad %s UIOffset %s Excl %s attrs %s | parent %s%s", tag, p:GetFullName(), p.Style.Name,
		tostring(p.Enabled), p.MaxActivationDistance, tostring(p.RequiresLineOfSight), p.HoldDuration, p.KeyboardKeyCode.Name, p.GamepadKeyCode.Name,
		tostring(p.UIOffset), p.Exclusivity.Name, attrs(p), par and par.ClassName or "nil", (par and par:IsA("BasePart")) and (" at " .. v3(par.Position) .. " size " .. v3(par.Size)) or "")
end
local nPrompts, nCustom = 0, 0
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		nPrompts += 1; if d.Style == Enum.ProximityPromptStyle.Custom then nCustom += 1 end
		local full = d:GetFullName():lower()
		if d.Name == "OperaPrompt" then promptLine("Opera", d)
		elseif full:find("race") and not full:find("forestrace") then promptLine("Race", d) end
	end
end
say("prompts in workspace: %d (%d saved as Style Custom)", nPrompts, nCustom)
local ol = workspace:FindFirstChild("OperaLights"); say("OperaLights: %s attrs %s", ol and "present" or "missing", ol and attrs(ol) or "-")

-- ---------- (2) the frog asset ----------
local A = RS:FindFirstChild("FountainModeAssets")
local frog = A and A:FindFirstChild("Frog")
if frog then
	local body = frog:FindFirstChild("Body", true)
	local bb, bs = frog:GetBoundingBox()
	say("Frog: PrimaryPart %s; GetPivot ori %s at %s; WorldPivot ori %s; bbox ori %s size %s; parts %d", tostring(frog.PrimaryPart and frog.PrimaryPart.Name),
		ori(frog:GetPivot()), v3(frog:GetPivot().Position), ori(frog.WorldPivot), ori(bb), v3(bs), #frog:GetDescendants())
	for _, d in ipairs(frog:GetDescendants()) do
		if d:IsA("BasePart") then
			local rel = body and body.CFrame:PointToObjectSpace(d.Position) or Vector3.zero
			say("Frog part %s (%s): ori %s size %s | offset from Body: world %s, in Body's own axes %s | PivotOffset %s%s", d.Name, d.ClassName, ori(d.CFrame), v3(d.Size),
				body and v3(d.Position - body.Position) or "-", v3(rel), ori(d.PivotOffset), d:IsA("MeshPart") and (" MeshSize " .. v3(d.MeshSize)) or "")
		end
	end
else say("Frog: MISSING in ReplicatedStorage.FountainModeAssets") end
for _, n in ipairs({"LilyPad", "Lotus", "Petals", "Flowers"}) do
	local a = A and A:FindFirstChild(n)
	if a then
		local p = a:IsA("BasePart") and a or a:FindFirstChildWhichIsA("BasePart", true)
		if p then say("asset %s (%s): first part %s ori %s size %s", n, a.ClassName, p.Name, ori(p.CFrame), v3(p.Size)) end
	else say("asset %s: missing", n) end
end
local hb = SS:FindFirstChild("HudBackup")
if hb then local names = {} for _, c in ipairs(hb:GetChildren()) do if c.Name:lower():find("rog") or c.Name:lower():find("ountain") then table.insert(names, c.Name) end end say("HudBackup frog/fountain items: %s", table.concat(names, ", ")) end
-- a stray imported frog still in workspace?
for _, m in ipairs(workspace:GetChildren()) do if m:IsA("Model") and m:FindFirstChild("EyeL", true) then say("a frog-like model still in workspace: %s at %s, pivot ori %s", m.Name, v3(m:GetPivot().Position), ori(m:GetPivot())) end end

-- ---------- (3) the funicolare and streaming ----------
do
	local function prop(n) local ok, v = pcall(function() return workspace[n] end) return ok and tostring(v) or "n/a" end
	say("Streaming: Enabled %s MinRadius %s TargetRadius %s Integrity %s OutBehavior %s", prop("StreamingEnabled"), prop("StreamingMinRadius"), prop("StreamingTargetRadius"), prop("StreamingIntegrityMode"), prop("StreamOutBehavior"))
end
local tops = {}
for _, d in ipairs(workspace:GetDescendants()) do
	local n = d.Name:lower()
	if (d:IsA("Model") or d:IsA("Folder")) and (n:find("unic") or n == "car_rosso" or n == "car_crema") then
		local inner = false
		for _, t in ipairs(tops) do if d:IsDescendantOf(t) then inner = true break end end
		if not inner then table.insert(tops, d) end
	end
end
local bf = workspace:FindFirstChild("BalloonField"); local centre = bf and bf:FindFirstChild("Center", true)
say("BalloonField: %s; Center %s; attrs %s", bf and "present" or "missing", centre and v3(centre.Position) or "-", bf and attrs(bf) or "-")
local function bboxOf(parts)
	if #parts == 0 then return nil end
	local lo, hi = parts[1].Position, parts[1].Position
	for _, p in ipairs(parts) do local h = p.Size / 2; lo = Vector3.new(math.min(lo.X, p.Position.X - h.X), math.min(lo.Y, p.Position.Y - h.Y), math.min(lo.Z, p.Position.Z - h.Z)); hi = Vector3.new(math.max(hi.X, p.Position.X + h.X), math.max(hi.Y, p.Position.Y + h.Y), math.max(hi.Z, p.Position.Z + h.Z)) end
	return lo, hi
end
for _, t in ipairs(tops) do
	local parts, anch, rails, others = {}, 0, {}, {}
	for _, d in ipairs(t:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d); if d.Anchored then anch += 1 end
			local n = d.Name:lower(); local full = d:GetFullName():lower()
			if n:find("rail") or n:find("track") or n:find("binar") or n:find("rotaia") or full:find("rail") or full:find("track") then table.insert(rails, d) else table.insert(others, d) end
		end
	end
	local mode = "-"; pcall(function() mode = t.ModelStreamingMode.Name end)
	local lo, hi = bboxOf(parts)
	say("Funicolare top '%s' (%s): streaming mode %s; %d parts (%d anchored); bbox %s..%s; %s", t:GetFullName(), t.ClassName, mode, #parts, anch, lo and v3(lo) or "-", hi and v3(hi) or "-",
		centre and lo and string.format("centre is %.0f studs from the balloon pad", ((lo + hi) / 2 - centre.Position).Magnitude) or "")
	local kids = {}
	for _, c in ipairs(t:GetChildren()) do
		local cnt = c:IsA("BasePart") and 1 or 0
		for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then cnt += 1 end end
		local m = ""; pcall(function() if c:IsA("Model") then m = "/" .. c.ModelStreamingMode.Name end end)
		table.insert(kids, string.format("%s:%s%s:%d", c.Name, c.ClassName, m, cnt))
	end
	say("  children (%d): %s", #kids, table.concat(kids, ", "))
	local rlo, rhi = bboxOf(rails); local olo, ohi = bboxOf(others)
	say("  rail-named parts %d bbox %s..%s; other parts %d bbox %s..%s", #rails, rlo and v3(rlo) or "-", rhi and v3(rhi) or "-", #others, olo and v3(olo) or "-", ohi and v3(ohi) or "-")
	table.sort(parts, function(a, b) return a.Size.Magnitude > b.Size.Magnitude end)
	local big = {}
	for i = 1, math.min(6, #parts) do local p = parts[i]; table.insert(big, string.format("%s %s %s", p:GetFullName():gsub("^Workspace%.", ""), v3(p.Size), p.ClassName)) end
	say("  biggest parts: %s", table.concat(big, " | "))
	local scripts = {}
	for _, d in ipairs(t:GetDescendants()) do if d:IsA("LuaSourceContainer") then table.insert(scripts, d.Name .. "(" .. d.ClassName .. (d:IsA("BaseScript") and ("/" .. tostring(d.RunContext)) or "") .. ")") end end
	say("  scripts inside: %s", #scripts > 0 and table.concat(scripts, ", ") or "none")
end
if #tops == 0 then say("Funicolare: no Model/Folder named like *unic* or Car_Rosso/Car_Crema found in workspace") end
-- scripts anywhere whose code mentions the funicolare (is any of it built or hidden by a script?)
local refs = {}
for _, root in ipairs({workspace, game:GetService("ServerScriptService"), game:GetService("StarterPlayer"), game:GetService("StarterGui"), RS}) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and #refs < 12 then
			local ok, src = pcall(function() return d.Source end)
			if ok and src and (src:lower():find("funic") or src:find("Car_Rosso")) then table.insert(refs, d:GetFullName()) end
		end
	end
end
say("scripts mentioning the funicolare: %s", #refs > 0 and table.concat(refs, ", ") or "none")

for _, l in ipairs(out) do print(l) end
print(string.format("QQ S72 END (%d lines)", #out))
