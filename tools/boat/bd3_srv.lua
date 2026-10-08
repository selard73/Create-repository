-- bd3 (PLAY, SERVER, read-only): did the driven boat get the ring + cleat?
for _, m in ipairs(workspace.Boat:GetChildren()) do
	if m:IsA("Model") then
		local n = {}
		for _, c in ipairs(m:GetChildren()) do n[c.Name] = (n[c.Name] or 0) + 1 end
		local t = {} for k, v in pairs(n) do table.insert(t, k .. "x" .. v) end
		local ring = m:FindFirstChild("BowPlate"); local vis = m:FindFirstChild("Visual")
		warn("QQ BD3 " .. m.Name .. " " .. table.concat(t, " ") .. (ring and vis and (" plate-local " .. tostring(vis.CFrame:PointToObjectSpace(ring.Position))) or ""))
	end
end
