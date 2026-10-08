-- falls_topfix3 v1: CHANGES THE PLACE (FallsB only). After falls_cornerfix3 a thin teal band shows just under the lip: the
-- river's flat end face (z -547.8..-548.5) sits in FRONT of the fall body where the body curls down from the brink line
-- (its surface is only at z -547.7 three studs down). The body's top now starts 1.4 studs south of the brink with a gentler
-- curl, so from y -1.1 down the opaque pale body is in front of the water face; the strands keep curling from the brink
-- itself, so from above the lip still reads as water turning over. Re-running is harmless.
local B = workspace.SouthGorge.FallsB
local rig = B.Rig
local ZC, WATER_Y = -547.5, -0.9
local XL = (169.4583 + 201.2856) / 2
local a = rig:FindFirstChild("TopK")
if a then a.WorldCFrame = CFrame.fromMatrix(Vector3.new(XL, WATER_Y - 0.2, ZC - 1.4), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) end
local back = rig:FindFirstChild("Back")
if back then back.CurveSize0 = 1.5 end
-- the wisps too: their top a little forward so their faint texture does not sit behind the water face either
local w = rig:FindFirstChild("TopW")
if w then w.WorldCFrame = CFrame.fromMatrix(Vector3.new(XL, WATER_Y, ZC - 0.6), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) end
print(string.format("QQ TF3 Back top at z %.1f c0 %.1f; Wisps top z %.1f", a and a.WorldPosition.Z or 0, back and back.CurveSize0 or 0, w and w.WorldPosition.Z or 0))
print("QQ TF3 DONE")
