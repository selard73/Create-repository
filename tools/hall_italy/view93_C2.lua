-- view93_C2: the harbour front (benches and lemon trees between the piers and the town) - high three-quarter view. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(334, groundY(334, -606) + 24.0, -606)
local at = Vector3.new(285, groundY(285, -655) + 2.0, -655)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 C2: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
