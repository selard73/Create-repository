-- view93_A1: the lighthouse terrace beside the Guardian's statue (plinth 488,-1158) - standing, at eye height, the way a player walks up. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(516, groundY(516, -1128) + 5.5, -1128)
local at = Vector3.new(484, groundY(484, -1152) + 4.0, -1152)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 A1: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
