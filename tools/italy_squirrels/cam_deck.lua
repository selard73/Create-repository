-- Oct 5 2026: look down at the Azzurra deck from above the stern-side
local cam=workspace.CurrentCamera
cam.CameraType=Enum.CameraType.Fixed
cam.CFrame=CFrame.lookAt(Vector3.new(211,-43.5,-660),Vector3.new(203,-52,-668))
cam.Focus=CFrame.new(203,-52,-668)
