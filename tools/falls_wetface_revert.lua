-- falls_wetface_revert v1 (WET=false): CHANGES THE PLACE (reversible tint): the sill face right behind the fall (workspace.SouthGorge.Rock
-- SouthCliff_L01 and SouthCliff_L01_Lo) is tinted dark like wet rock, the way the cliff behind Skogafoss is black and wet,
-- so the white strands read against it. The original colours are kept in an attribute "OrigColor"; falls_wetface_revert
-- puts them back. MODE: set WET = true to tint, false to revert.
local WET = false
local R = workspace.SouthGorge.Rock
local out = {}
for _, n in ipairs({"SouthCliff_L01", "SouthCliff_L01_Lo"}) do
	local p = R:FindFirstChild(n)
	if p then
		if WET then
			if p:GetAttribute("OrigColor") == nil then p:SetAttribute("OrigColor", p.Color) end
			p.Color = Color3.fromRGB(74, 70, 66)
		else
			local c = p:GetAttribute("OrigColor"); if c then p.Color = c end
		end
		out[#out + 1] = string.format("%s -> %s", n, tostring(p.Color))
	else
		out[#out + 1] = n .. " MISSING"
	end
end
print("QQ WF " .. (WET and "wet" or "reverted") .. ": " .. table.concat(out, "; "))
print("QQ WF DONE")
