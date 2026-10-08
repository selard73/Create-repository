-- Oct 5 2026: save her camera (log) then look straight down on the beach (sunbather / lifeguard)
local cam=workspace.CurrentCamera
warn('QCAM@SAVED',cam.CFrame)
cam.CFrame=CFrame.lookAt(Vector3.new(274,25,-723),Vector3.new(274,-48,-723.01),Vector3.new(1,0,0))
cam.Focus=CFrame.new(274,-48,-723)
