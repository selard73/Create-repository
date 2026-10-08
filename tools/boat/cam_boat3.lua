-- b3 READ-ONLY: top-down editor camera over the south stretch + screen points for the jetty sketch + quay heights
local cam = workspace.CurrentCamera
cam.FieldOfView = 14
cam.CFrame = CFrame.lookAt(Vector3.new(160, 330, -160), Vector3.new(160, 0, -160), Vector3.new(0, 0, 1))
task.wait(0.3)
print(("QQ VP %.0f %.0f"):format(cam.ViewportSize.X, cam.ViewportSize.Y))
local pts = {
	{"jA", 160.4, -146}, {"jB", 163.9, -146}, {"jC", 163.9, -168}, {"jD", 160.4, -168},  -- jetty deck
	{"gA", 163.9, -165}, {"gB", 168.0, -165}, {"gC", 168.0, -169.5}, {"gD", 163.9, -169.5}, -- step from the sidewalk
	{"stopN", 146, -127}, {"stopN2", 165, -127}, {"stopS", 150, -203}, {"stopS2", 170, -203},
	{"bridge", 156, -120}, {"board", 168.2, -135.6},
}
for _, p in ipairs(pts) do
	local v = cam:WorldToViewportPoint(Vector3.new(p[2], 0, p[3]))
	print(("QQ PT %s %.0f %.0f"):format(p[1], v.X, v.Y))
end
local rp = RaycastParams.new(); rp.IgnoreWater = true
for _, q in ipairs({{165.5, -140}, {165.5, -150}, {165.5, -167}, {166.5, -167}, {162.5, -150}}) do
	local r = workspace:Raycast(Vector3.new(q[1], 20, q[2]), Vector3.new(0, -40, 0), rp)
	print(("QQ H %.1f %.1f -> %s %.2f"):format(q[1], q[2], r and r.Instance:GetFullName() or "none", r and r.Position.Y or -99))
end
print("QQ DONE b3")
