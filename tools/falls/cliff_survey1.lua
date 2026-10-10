-- cliff_survey1.lua - READ-ONLY survey (Studio EDIT mode). Job 82. Changes nothing.
-- Shannon (Oct 10): on the waterfall cliff's face, "several places on the right hand side of the cliff toward the top where
-- there are bald spots or holes with something else showing through; also the right side of where the waterfall starts
-- shows through (you can see the water behind it); earlier we tried to patch this by putting an extra piece over top but it
-- did not fully block it." Lists every piece of workspace.SouthGorge.Rock (the cliff pieces SouthCliff_*, their _Lo halves,
-- the wall chunks by the lip) and the Falls' crest beams, with the numbers needed to find the gaps. Prints "QQ CLIFF" lines.
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local function ori(cf) local x, y, z = cf:ToOrientation() return string.format("(%.0f,%.0f,%.0f)", math.deg(x), math.deg(y), math.deg(z)) end
local out = {}
local function say(fmt, ...) table.insert(out, "QQ CLIFF " .. string.format(fmt, ...)) end
local SG = workspace:FindFirstChild("SouthGorge")
if not SG then print("QQ CLIFF ABORT: workspace.SouthGorge not found") return end
local Rock = SG:FindFirstChild("Rock")
if not Rock then print("QQ CLIFF ABORT: SouthGorge.Rock not found") return end
local function describe(p)
	local extra = ""
	if p:IsA("MeshPart") then extra = string.format(" mesh %s tex %s fidelity %s", p.MeshId, p.TextureID, p.CollisionFidelity.Name) end
	local tex = {}
	for _, c in ipairs(p:GetChildren()) do if c:IsA("Texture") or c:IsA("Decal") then table.insert(tex, c.ClassName .. ":" .. c.Face.Name) end end
	say("%s (%s): pos %s size %s ori %s transp %.2f doubleSided %s canCollide %s%s%s", p.Name, p.ClassName, v3(p.Position), v3(p.Size), ori(p.CFrame),
		p.Transparency, tostring(p.DoubleSided), tostring(p.CanCollide), extra, #tex > 0 and (" faces " .. table.concat(tex, ",")) or "")
end
local parts = {}
for _, d in ipairs(Rock:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end
table.sort(parts, function(a, b) return a.Name < b.Name end)
local kids = {}
for _, c in ipairs(Rock:GetChildren()) do table.insert(kids, c.Name .. ":" .. c.ClassName) end
say("SouthGorge.Rock: %d parts; children: %s", #parts, table.concat(kids, ", "))
-- the lip: the Falls model's crest beam
local Falls = SG:FindFirstChild("Falls")
local crestPos
if Falls then
	for _, d in ipairs(Falls:GetDescendants()) do
		if d:IsA("Beam") and (d.Name == "Crest" or d.Name == "Body" or d.Name:find("Sheet")) then
			local a0, a1 = d.Attachment0, d.Attachment1
			say("Falls beam %s: width0 %.1f width1 %.1f from %s to %s", d.Name, d.Width0, d.Width1, a0 and v3(a0.WorldPosition) or "?", a1 and v3(a1.WorldPosition) or "?")
			if d.Name == "Crest" and a0 then crestPos = a0.WorldPosition end
		end
	end
else say("SouthGorge.Falls: missing") end
-- the cliff pieces (and anything named like a patch)
for _, p in ipairs(parts) do
	local n = p.Name
	if n:find("SouthCliff") or n:find("Patch") or n:find("Fix") or n:find("Cover") or n:find("Cap") then describe(p) end
end
if crestPos then
	say("crest at %s; other Rock parts within 80 studs of it:", v3(crestPos))
	for _, p in ipairs(parts) do
		if not p.Name:find("SouthCliff") and (p.Position - crestPos).Magnitude < 80 then describe(p) end
	end
	-- anything parked over the cliff by an earlier patch, outside Rock and Falls
	local near = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and not d:IsDescendantOf(Rock) and not d:IsDescendantOf(Falls) and (d.Position - crestPos).Magnitude < 60 and d.Size.Magnitude > 4 then
			table.insert(near, string.format("%s %s size %s", (d:GetFullName():gsub("^Workspace%.", "")), v3(d.Position), v3(d.Size)))
		end
	end
	say("other big parts within 60 studs of the crest (%d): %s", #near, table.concat(near, " | "))
	-- the river's water behind the lip
	local River = workspace:FindFirstChild("River")
	if River then
		for _, d in ipairs(River:GetDescendants()) do
			if d:IsA("BasePart") and (d.Position - crestPos).Magnitude < 120 and d.Size.Magnitude > 10 then
				say("River part %s: pos %s size %s transp %.2f", (d:GetFullName():gsub("^Workspace%.", "")), v3(d.Position), v3(d.Size), d.Transparency)
			end
		end
	end
end
for _, l in ipairs(out) do print(l) end
print(string.format("QQ CLIFF END (%d lines)", #out))
