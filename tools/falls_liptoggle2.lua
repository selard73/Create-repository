-- falls_liptoggle2 v1 (EDIT, temporary): from the parked going-over camera, hides the Wisps, Strands1 and Strands2 beams
-- one at a time for 2 s each, then all three together, then puts everything back, so the stray sheet can be named.
local F = workspace.SouthGorge.FallsB
local function beam(n) return F:FindFirstChild(n, true) end
local w, s1, s2 = beam("Wisps"), beam("Strands1"), beam("Strands2")
local function restore() for _, b in ipairs({w, s1, s2}) do if b then b.Enabled = true end end end
print("QQ LT2 1: Wisps off"); if w then w.Enabled = false end
task.wait(2); restore()
print("QQ LT2 2: Strands1 off"); if s1 then s1.Enabled = false end
task.wait(2); restore()
print("QQ LT2 3: Strands2 off"); if s2 then s2.Enabled = false end
task.wait(2); restore()
print("QQ LT2 4: all three off"); for _, b in ipairs({w, s1, s2}) do if b then b.Enabled = false end end
task.wait(2); restore()
print("QQ LT2 restored")
