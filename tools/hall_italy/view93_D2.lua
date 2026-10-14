-- view93_D2: the church square (Santa Marina 380..433, the sailing club) - high three-quarter view. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(458, groundY(458, -1004) + 24.0, -1004)
local at = Vector3.new(408, groundY(408, -962) + 2.0, -962)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 D2: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
