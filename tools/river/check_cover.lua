-- v41 read-only: before laying terrain grass over the whole map: which scripts mention the Baseplate, and which parts
-- lie so low (top below 0.15, inside the map) that grass at +0.08 could show through them
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
for _, s in ipairs(game:GetDescendants()) do
	if s:IsA("LuaSourceContainer") then
		local ok, src = pcall(function() return s.Source end)
		if ok and src and src:find("Baseplate") then P("script", s:GetFullName(), s.ClassName, s:IsA("BaseScript") and s.Enabled or "") end
	end
end
local low, n = {}, 0
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Name ~= "Baseplate" and d.Transparency < 1 then
		local p = d.Position
		local top = p.Y + d.Size.Y / 2
		if p.X > -140 and p.X < 710 and p.Z > -260 and p.Z < 40 and top < 0.15 and top > -0.5 and d.Size.X * d.Size.Z > 1 then
			local m = d:FindFirstAncestorOfClass("Model")
			local k = (m and m:GetFullName() or d.Parent:GetFullName()) .. "." .. d.Name
			if not low[k] then low[k] = 0; n += 1 end
			low[k] += 1
		end
	end
end
for k, c in pairs(low) do P("low", k, c) end
P("lowcount", n)
local bp = workspace.Baseplate
P("bp", bp.ClassName, bp.Material.Name, bp.Color:ToHex(), tostring(bp.Size))
P("DONE41")
