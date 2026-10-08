-- undo of falls_weststrands1: removes FallsB.Strands3 and its attachments
local F = workspace.SouthGorge.FallsB
for _, n in ipairs({"Strands3", "S3a", "S3b"}) do local o = F:FindFirstChild(n, true); if o then o:Destroy() end end
print("QQ WS Strands3 removed")
