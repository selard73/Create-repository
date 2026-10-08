-- falls_test1: TEMPORARY test on workspace.SouthGorge.Falls (the next falls_water2 run rebuilds everything):
-- why is the flat foam invisible from above? Rapids1 segments lifted 6 studs clear of the water; Rapids2 segments
-- get their attachments swapped (reverses the beam's facing); Rapids3 untouched as the control.
local F = workspace.SouthGorge.Falls
local lifted, flipped = 0, 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") then
		if b.Name:sub(1, 7) == "Rapids1" then
			for _, a in ipairs({b.Attachment0, b.Attachment1}) do a.WorldPosition = a.WorldPosition + Vector3.new(0, 6, 0) end
			lifted += 1
		elseif b.Name:sub(1, 7) == "Rapids2" then
			local a0 = b.Attachment0; b.Attachment0 = b.Attachment1; b.Attachment1 = a0
			flipped += 1
		end
	end
end
print(string.format("QQ FT1 lifted %d Rapids1 segments by 6, flipped %d Rapids2 segments", lifted, flipped))
print("QQ FT1 DONE")
