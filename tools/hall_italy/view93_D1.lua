-- view93_D1: the church square (Santa Marina 380..433, the sailing club) - standing, at eye height, the way a player walks up. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new(446, groundY(446, -950) + 5.5, -950)
local at = Vector3.new(408, groundY(408, -962) + 4.0, -962)
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 D1: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
