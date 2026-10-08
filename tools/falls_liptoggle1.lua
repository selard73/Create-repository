-- falls_liptoggle1 v1 (EDIT, temporary): from the parked going-over camera, hides one candidate at a time for 2 s each -
-- the opaque LipPlate, the Back beam, the LipStrands beam - then puts everything back, so the stray sheet can be named.
local F = workspace.SouthGorge.FallsB
local plate, back, lip = F:FindFirstChild("LipPlate"), F:FindFirstChild("Back", true), F:FindFirstChild("LipStrands", true)
local function restore() if plate then plate.Transparency = 0 end; if back then back.Enabled = true end; if lip then lip.Enabled = true end end
print("QQ LT 1: LipPlate hidden"); if plate then plate.Transparency = 1 end
task.wait(2); restore()
print("QQ LT 2: Back beam off"); if back then back.Enabled = false end
task.wait(2); restore()
print("QQ LT 3: LipStrands off"); if lip then lip.Enabled = false end
task.wait(2); restore()
print(string.format("QQ LT restored; plate colour %s material %s", plate and tostring(plate.Color) or "?", plate and tostring(plate.Material) or "?"))
