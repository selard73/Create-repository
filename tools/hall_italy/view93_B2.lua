-- view93_B2: Piazza del Limone (the fountain 464,-794) - high three-quarter view. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(502, groundY(502, -832) + 24.0, -832)
local at = Vector3.new(464, groundY(464, -794) + 2.0, -794)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 B2: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
