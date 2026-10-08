-- ab5_A_foot v1: toggle + camera combo (see the parts below)
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

local G = workspace.SouthGorge
local A_BEAMS = {Crest = 1, Body = 1, Sheet2 = 1, Ribbon1 = 1, Ribbon2 = 1, Ribbon3 = 1, Ribbon4 = 1, MistBank = 1, MistBank2 = 1, PlugE = 1, PlugW = 1}
local A_PARTS = {Spray = 1, Mist = 1, Plume = 1, Splash = 1, FoamRing = 1}
local na, nbb = 0, 0
for _, d in ipairs(G.Falls:GetDescendants()) do
	if d:IsA("Beam") and A_BEAMS[d.Name] then d.Enabled = true; na += 1 elseif d:IsA("ParticleEmitter") and A_PARTS[d.Parent.Name] then d.Enabled = true; na += 1 end
end
local B = G:FindFirstChild("FallsB")
if B then for _, d in ipairs(B:GetDescendants()) do if d:IsA("Beam") or d:IsA("ParticleEmitter") then d.Enabled = false; nbb += 1 end end end
print(string.format("QQ SA A on (%d), B off (%d)", na, nbb))
print("QQ SA DONE")

