-- view93_A2: the lighthouse terrace beside the Guardian's statue (plinth 488,-1158) - high three-quarter view. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(452, groundY(452, -1105) + 24.0, -1105)
local at = Vector3.new(484, groundY(484, -1152) + 2.0, -1152)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 A2: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
