-- v63 move the "Rue de Noisette" sign (Boundary.Gates.SignVillage) 3 studs west, away from the bridge; camera on it
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local sign
for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "SignVillage" and d.Parent and d.Parent.Name == "Gates" then sign = d break end end
if not sign then P("STOP no sign") return end
local function box(o)
	if o:IsA("Model") then local cf, s = o:GetBoundingBox() return cf.Position, s end
	if o:IsA("BasePart") then return o.Position, o.Size end
	local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, q in ipairs(o:GetDescendants()) do if q:IsA("BasePart") then mn = mn:Min(q.Position); mx = mx:Max(q.Position) end end
	return (mn + mx) / 2, mx - mn
end
local p0, s0 = box(sign)
P("before", sign.ClassName, string.format("%.1f,%.2f,%.1f", p0.X, p0.Y, p0.Z), string.format("%.1f,%.1f,%.1f", s0.X, s0.Y, s0.Z))
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("MoveSign")
local d = Vector3.new(-3, 0, 0)
if sign:IsA("Model") then sign:PivotTo(sign:GetPivot() + d)
elseif sign:IsA("BasePart") then sign.CFrame = sign.CFrame + d
else for _, q in ipairs(sign:GetDescendants()) do if q:IsA("BasePart") then q.CFrame = q.CFrame + d end end end
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
local p1 = box(sign)
P("after", string.format("%.1f,%.2f,%.1f", p1.X, p1.Y, p1.Z))
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
cam.CFrame = CFrame.lookAt(p1 + Vector3.new(-10, 3, 8), p1 + Vector3.new(4, -1, 0))
