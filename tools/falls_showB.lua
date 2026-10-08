-- falls_showB v1: CHANGES THE PLACE (toggle only): shows candidate B and hides the live fall part of A. Rapids untouched.
local G = workspace.SouthGorge
local A_BEAMS = {Crest = 1, Body = 1, Sheet2 = 1, Ribbon1 = 1, Ribbon2 = 1, Ribbon3 = 1, Ribbon4 = 1, MistBank = 1, MistBank2 = 1, PlugE = 1, PlugW = 1}
local A_PARTS = {Spray = 1, Mist = 1, Plume = 1, Splash = 1, FoamRing = 1}
local na, nbb = 0, 0
for _, d in ipairs(G.Falls:GetDescendants()) do
	if d:IsA("Beam") and A_BEAMS[d.Name] then d.Enabled = false; na += 1 elseif d:IsA("ParticleEmitter") and A_PARTS[d.Parent.Name] then d.Enabled = false; na += 1 end
end
local B = G:FindFirstChild("FallsB")
if B then for _, d in ipairs(B:GetDescendants()) do if d:IsA("Beam") or d:IsA("ParticleEmitter") then d.Enabled = true; nbb += 1 end end end
print(string.format("QQ SB A off (%d), B on (%d)", na, nbb))
print("QQ SB DONE")
