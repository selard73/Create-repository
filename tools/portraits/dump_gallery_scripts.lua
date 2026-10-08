-- v2 read-only: dump the live portrait scripts + gallery facts to Output (QQ lines)
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local G = workspace:FindFirstChild("PortraitGallery", true)
P("G", G and G:GetFullName())
local function prop(o, k) local ok, v = pcall(function() return o[k] end) return ok and (typeof(v) == "EnumItem" and v.Name or v) or "?" end
P("streaming", workspace.StreamingEnabled, prop(workspace, "StreamingTargetRadius"), prop(workspace, "StreamingMinRadius"), prop(workspace, "StreamingIntegrityMode"), prop(workspace, "StreamOutBehavior"))
if not G then return end
for k, v in pairs(G:GetAttributes()) do P("Gattr", k, v) end
for _, c in ipairs(G:GetChildren()) do P("child", c.Name, c.ClassName, c:IsA("Model") and c.ModelStreamingMode.Name or "") end
local srcs = {}
for _, d in ipairs(G:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		P("script", d:GetFullName(), d.ClassName, d:IsA("BaseScript") and d.Enabled or "", d:IsA("Script") and d.RunContext.Name or "", #d.Source)
		srcs[#srcs + 1] = d
	end
end
local seat = G:FindFirstChild("SitterChair") and G.SitterChair:FindFirstChild("PortraitSeat")
P("seat", seat and tostring(seat.Position))
local slots = G:FindFirstChild("Slots")
if slots then
	for _, s in ipairs(slots:GetChildren()) do
		local c = s:FindFirstChild("Canvas", true)
		local pic = c and c:FindFirstChild("Picture")
		local vp = pic and pic:FindFirstChild("Portrait3D")
		P("slot", s.Name, s.ClassName, s:IsA("Model") and s.ModelStreamingMode.Name or "", c and tostring(c.Position), seat and c and math.floor((c.Position - seat.Position).Magnitude) or "",
			pic and pic.ClassName, pic and pic.Enabled, vp and vp.ClassName, vp and vp.Visible, vp and vp:FindFirstChild("World") and vp.World.ClassName)
	end
end
local rs = game.ReplicatedStorage:FindFirstChild("PortraitGalleryModels")
P("models", rs and #rs:GetChildren())
for _, d in ipairs(srcs) do
	local n = 0
	for line in (d.Source .. "\n"):gmatch("(.-)\n") do n += 1; print("QQ@" .. d.Name .. "|" .. n .. "|" .. line) end
end
P("DONE")
