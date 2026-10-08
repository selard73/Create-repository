-- bm1 (PLAY, SERVER, read-only): watch the driven boat's engine sound for 10 s
for i = 1, 20 do
	for _, m in ipairs(workspace.Boat:GetChildren()) do
		local e = m:IsA("Model") and m.PrimaryPart and m.PrimaryPart:FindFirstChild("Engine")
		if e then warn(("QQ BM1 playing %s loaded %s vol %.2f pitch %.2f speed %.1f"):format(tostring(e.IsPlaying), tostring(e.IsLoaded), e.Volume, e.PlaybackSpeed, (m.PrimaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude)) end
	end
	task.wait(0.5)
end
