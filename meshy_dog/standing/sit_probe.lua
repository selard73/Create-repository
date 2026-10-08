-- Sit probe: run in the COMMAND BAR in edit mode (Ctrl+Enter). Poses the dog sitting with the same math as PupAnim
-- and prints where his bones actually went, so the Transform semantics can be checked. Reset with the line at the bottom.
local mesh; for _, p in ipairs(workspace:GetDescendants()) do if p:IsA("MeshPart") and p:FindFirstChild("FrontUpper.L", true) then mesh = p end end
local bones = {}; for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
local names = {}; for n, b in pairs(bones) do table.insert(names, n .. "<" .. b.Parent.Name) end; table.sort(names)
print("BONES:", table.concat(names, " "))
for _, b in pairs(bones) do b.Transform = CFrame.identity end
-- 1) translation semantics: move Hips by +1 along its Transform Y and see which world direction that was
local hips = bones.Hips
hips.Transform = CFrame.new(0, 1, 0)
local d = hips.TransformedWorldCFrame.Position - hips.WorldCFrame.Position
print("T-PROBE moved", d, "| bone local Y in world", hips.WorldCFrame.Rotation * Vector3.yAxis, "| mesh Y in world", mesh.CFrame.Rotation * Vector3.yAxis)
-- 2) rotation semantics: rotate Hips 90 deg about Transform X; see where a child goes
local ch = bones["HindUpper.L"]
local c0 = ch.TransformedWorldCFrame.Position
hips.Transform = CFrame.Angles(math.rad(90), 0, 0)
print("R-PROBE child rel hips before", c0 - hips.WorldCFrame.Position, "after", ch.TransformedWorldCFrame.Position - hips.WorldCFrame.Position, "| bone local X in world", hips.WorldCFrame.Rotation * Vector3.xAxis)
hips.Transform = CFrame.identity
-- 3) full sit with the PupAnim math
local ORDER = {"Hips", "Chest", "Neck", "Head", "Ear.L", "Ear.R", "Tail1", "Tail2",
	"FrontUpper.L", "FrontLower.L", "FrontPaw.L", "FrontUpper.R", "FrontLower.R", "FrontPaw.R",
	"HindUpper.L", "HindLower.L", "HindPaw.L", "HindUpper.R", "HindLower.R", "HindPaw.R"}
local f = bones.Head.WorldPosition - bones.Hips.WorldPosition; f = Vector3.new(f.X, 0, f.Z).Unit
local fwdW, upW = f, Vector3.yAxis; local leftW = upW:Cross(fwdW)
local scale = mesh.Size.Y / 5
local SIT = {Hips = {-30, 0, 0, 0.05, -1.15, 0}, Chest = {4}, Neck = {12}, Head = {12},
	["FrontUpper.L"] = {24}, ["FrontPaw.L"] = {4}, ["FrontUpper.R"] = {24}, ["FrontPaw.R"] = {4},
	["HindUpper.L"] = {-30}, ["HindLower.L"] = {110}, ["HindPaw.L"] = {-150},
	["HindUpper.R"] = {-30}, ["HindLower.R"] = {110}, ["HindPaw.R"] = {-150}, Tail1 = {25}, Tail2 = {10}}
local rest = {}
for n, b in pairs(bones) do rest[n] = b.WorldCFrame.Position end
for _, name in ipairs(ORDER) do
	local b, w = bones[name], SIT[name]
	if b and w then
		local parent = b.Parent
		local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or mesh.CFrame
		local R = (pw * b.CFrame).Rotation
		local lLeft, lUp, lFwd = R:VectorToObjectSpace(leftW), R:VectorToObjectSpace(upW), R:VectorToObjectSpace(fwdW)
		local off = R:VectorToObjectSpace((fwdW * (w[4] or 0) + upW * (w[5] or 0) + leftW * (w[6] or 0)) * scale)
		b.Transform = CFrame.new(off) * CFrame.fromAxisAngle(lUp, math.rad(w[2] or 0)) * CFrame.fromAxisAngle(lLeft, math.rad(w[1] or 0)) * CFrame.fromAxisAngle(lFwd, math.rad(w[3] or 0))
	end
end
for _, n in ipairs({"Hips", "HindUpper.L", "HindLower.L", "HindPaw.L", "FrontUpper.L", "FrontPaw.L", "Head"}) do
	local b = bones[n]
	print(string.format("SIT %-13s rest y %.2f -> posed y %.2f   moved %s", n, rest[n].Y, b.TransformedWorldCFrame.Position.Y, tostring(b.TransformedWorldCFrame.Position - rest[n])))
end
print("scale", scale, "mesh size", mesh.Size)
-- to undo the pose: for _, b in ipairs(workspace:GetDescendants()) do if b:IsA("Bone") then b.Transform = CFrame.identity end end
