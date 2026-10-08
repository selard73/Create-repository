-- falls_weststrands1 v3 (EDIT): the west end of the fall at the lip read as a flat pale sheet from the going-over camera
-- (the Back beam + LipPlate + LipStrands showing where Strands1/2 run thin). Adds FallsB.Strands3: a copy of Strands1
-- shifted 5 studs west and 22 wide, on its own attachments, with a slightly different texture speed, so the west stretch
-- pours like the rest. Safe to re-run (replaces an earlier Strands3). falls_weststrands1_undo: destroy Strands3 + its attachments.
local F = workspace.SouthGorge.FallsB
local s1 = F:FindFirstChild("Strands1", true)
if not s1 then print("QQ WS no Strands1"); return end
local old = F:FindFirstChild("Strands3", true); if old then old:Destroy() end
for _, n in ipairs({"S3a", "S3b"}) do local a = F:FindFirstChild(n, true); if a then a:Destroy() end end
local a0, a1 = s1.Attachment0, s1.Attachment1
local rig = a0.Parent
local na = Instance.new("Attachment"); na.Name = "S3a"; na.Parent = rig                      -- parent first: WorldPosition is read against the parent
na.WorldCFrame = a0.WorldCFrame + Vector3.new(-5, 0, -2.5)      -- in front of the LipPlate (z -548.9), which hides the top of Strands1/2
local nb = Instance.new("Attachment"); nb.Name = "S3b"; nb.Parent = rig
nb.WorldCFrame = a1.WorldCFrame + Vector3.new(-5, 0, -0.3)
local s3 = s1:Clone(); s3.Name = "Strands3"; s3.Attachment0 = na; s3.Attachment1 = nb
s3.Width0 = 22; s3.Width1 = 22; s3.TextureSpeed = s1.TextureSpeed * 1.08; s3.ZOffset = (s1.ZOffset or 0) - 0.05
s3.Parent = s1.Parent
print(string.format("QQ WS Strands3 added: centre x %.1f, width 22, texture speed %.2f (Strands1 %.2f), from y %.1f to %.1f", na.WorldPosition.X, s3.TextureSpeed, s1.TextureSpeed, na.WorldPosition.Y, nb.WorldPosition.Y))
