-- fountain/fountain_survey1 (job 60): READ-ONLY, EDIT mode. The piazza fountain of Porto Nocciola (Shannon, Oct 10: modes
-- bought in the store - spaghetti with bouncing smiling meatballs, a frog resort, flower petals). Prints what the fountain
-- is made of so the modes can be built on it: the model, its pivot and box, every part (class, material, colour, size,
-- position, transparency, mesh), every emitter / beam / attachment / sound / script in it, and the ground round it.
-- Output lines start with "QQ FTN".
local function v3(v) return string.format("%.1f,%.1f,%.1f", v.X, v.Y, v.Z) end
local hits = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if (d:IsA("Model") or d:IsA("Folder")) then
		local n = d.Name:lower()
		if n:find("fountain", 1, true) or n:find("fontana", 1, true) then table.insert(hits, d) end
	end
end
print("QQ FTN candidates: " .. #hits)
for _, h in ipairs(hits) do
	local ok, cf, size = pcall(function() local m = h:IsA("Model") and h or nil; if m then local c, s = m:GetBoundingBox() return c, s end; local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9); for _, p in ipairs(h:GetDescendants()) do if p:IsA("BasePart") then lo = lo:Min(p.Position - p.Size / 2); hi = hi:Max(p.Position + p.Size / 2) end end return CFrame.new((lo + hi) / 2), hi - lo end)
	print(string.format("QQ FTN %s: %s centre %s size %s", h.ClassName, h:GetFullName(), ok and v3(cf.Position) or "?", ok and v3(size) or "?"))
end
-- the piazza fountain: the candidate nearest the square (Tours: the fountain at about 464,-7,-794)
local best, bd = nil, math.huge
for _, h in ipairs(hits) do
	local ok, cf = pcall(function() return h:IsA("Model") and h:GetBoundingBox() or h:FindFirstChildWhichIsA("BasePart", true).CFrame end)
	if ok and cf then local d = (cf.Position - Vector3.new(464, -7, -794)).Magnitude; if d < bd then best, bd = h, d end end
end
if not best then warn("QQ FTN ABORT - no model or folder named like fountain / fontana in the workspace") return end
print(string.format("QQ FTN piazza fountain = %s (%.0f studs from 464,-7,-794)", best:GetFullName(), bd))
local parts, extras = 0, 0
for _, d in ipairs(best:GetDescendants()) do
	if d:IsA("BasePart") then
		parts += 1
		local mesh = d:IsA("MeshPart") and (" mesh " .. d.MeshId .. " tex " .. d.TextureID) or ""
		local sm = d:FindFirstChildOfClass("SpecialMesh"); if sm then mesh = " specialmesh " .. tostring(sm.MeshType) .. " " .. sm.MeshId end
		print(string.format("QQ FTN part %s [%s] %s %s size %s at %s tr %.2f col %d,%d,%d anch %s%s", d.Name, d.ClassName, d.Material.Name, d:IsA("Part") and d.Shape.Name or "-", v3(d.Size), v3(d.Position), d.Transparency, math.floor(d.Color.R * 255 + 0.5), math.floor(d.Color.G * 255 + 0.5), math.floor(d.Color.B * 255 + 0.5), tostring(d.Anchored), mesh))
	elseif d:IsA("ParticleEmitter") then
		extras += 1
		print(string.format("QQ FTN emitter %s under %s: rate %.1f speed %s life %s size %s tex %s colour %s enabled %s", d.Name, d.Parent:GetFullName(), d.Rate, tostring(d.Speed), tostring(d.Lifetime), tostring(d.Size), d.Texture, tostring(d.Color), tostring(d.Enabled)))
	elseif d:IsA("Beam") or d:IsA("Trail") then
		extras += 1
		print(string.format("QQ FTN %s %s under %s: tex %s width %s enabled %s", d.ClassName, d.Name, d.Parent:GetFullName(), d:IsA("Beam") and d.Texture or "-", d:IsA("Beam") and (d.Width0 .. "/" .. d.Width1) or "-", tostring(d.Enabled)))
	elseif d:IsA("Attachment") then
		extras += 1
		print(string.format("QQ FTN attachment %s under %s at %s (world %s)", d.Name, d.Parent.Name, v3(d.Position), v3(d.WorldPosition)))
	elseif d:IsA("Sound") then
		extras += 1
		print(string.format("QQ FTN sound %s under %s: %s vol %.2f looped %s playing %s", d.Name, d.Parent.Name, d.SoundId, d.Volume, tostring(d.Looped), tostring(d.Playing)))
	elseif d:IsA("LuaSourceContainer") then
		extras += 1
		print(string.format("QQ FTN script %s [%s] under %s: %d chars, enabled %s", d.Name, d.ClassName, d.Parent.Name, #d.Source, tostring(not d:IsA("BaseScript") or d.Enabled)))
	elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
		extras += 1
		print(string.format("QQ FTN light %s under %s", d.ClassName, d.Parent.Name))
	end
end
print(string.format("QQ FTN %d parts, %d emitters/beams/attachments/sounds/scripts/lights; attributes: %s", parts, extras, (function() local t = {} for k, v in pairs(best:GetAttributes()) do table.insert(t, k .. "=" .. tostring(v)) end return table.concat(t, " ") end)()))
-- the ground round it: eight rays 12 studs out, from 20 above the fountain's middle
local okc, cf = pcall(function() return best:IsA("Model") and best:GetBoundingBox() or best:FindFirstChildWhichIsA("BasePart", true).CFrame end)
if okc and cf then
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {best}
	local line = "QQ FTN ground 12 studs out:"
	for i = 0, 7 do
		local a = i * math.pi / 4
		local o = cf.Position + Vector3.new(math.cos(a) * 12, 20, math.sin(a) * 12)
		local hit = workspace:Raycast(o, Vector3.new(0, -60, 0), rp)
		line ..= string.format(" %d:%s", i * 45, hit and string.format("%.1f %s", hit.Position.Y, hit.Instance.Name) or "none")
	end
	print(line)
end
print("QQ FTN DONE")
