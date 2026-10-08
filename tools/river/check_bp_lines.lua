-- v42 read-only: the lines that mention Baseplate in the running scripts
for _, s in ipairs(game:GetDescendants()) do
	if s:IsA("BaseScript") then
		local ok, src = pcall(function() return s.Source end)
		if ok and src:find("Baseplate") then
			local n = 0
			for line in (src .. "\n"):gmatch("(.-)\n") do
				n += 1
				if line:find("Baseplate") then print("QQ bpl", s.Name, n, (line:gsub("^%s+", "")):sub(1, 170)) end
			end
		end
	end
end
print("QQ DONE42")
