-- view93_E2: Prato dei Fiori, the coastal meadow between the church and the lighthouse - high three-quarter view. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(566, groundY(566, -1132) + 24.0, -1132)
local at = Vector3.new(520, groundY(520, -1080) + 2.0, -1080)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 E2: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
