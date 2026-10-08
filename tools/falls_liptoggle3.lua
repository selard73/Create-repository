-- falls_liptoggle3 v1 (EDIT, temporary): hides the Back beam, the LipStrands beam AND the LipPlate together for 2.5 s (is the
-- stray sheet their west part showing where the strands are thin?), then everything back.
local F = workspace.SouthGorge.FallsB
local plate, back, lip = F:FindFirstChild("LipPlate"), F:FindFirstChild("Back", true), F:FindFirstChild("LipStrands", true)
print("QQ LT3 Back + LipStrands + LipPlate hidden")
if plate then plate.Transparency = 1 end; if back then back.Enabled = false end; if lip then lip.Enabled = false end
task.wait(2.5)
if plate then plate.Transparency = 0 end; if back then back.Enabled = true end; if lip then lip.Enabled = true end
print("QQ LT3 restored")
