-- balloon/balloon_undo1: EDIT mode. Removes workspace.BalloonField and RS.BalloonEvent; the template goes back to the
-- workspace as balloon_meshy (so install_field1 can run again). Output "QQ FIELD".
if game:GetService("RunService"):IsRunning() then warn("QQ FIELD ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local F = workspace:FindFirstChild("BalloonField"); if F then F:Destroy() end
local e = RS:FindFirstChild("BalloonEvent"); if e then e:Destroy() end
local t = SS:FindFirstChild("BalloonTemplate")
if t then t.Name = "balloon_meshy"; t:PivotTo(CFrame.new(554.4, 4.4, -1105.2)); t.Parent = workspace end
print("QQ FIELD UNDONE: field and event removed; template back in the workspace as balloon_meshy")
