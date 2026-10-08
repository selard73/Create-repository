-- falls_probe3: READ-ONLY. The foam beams as they really are in the place: positions, widths, settings, parents.
local F = workspace.SouthGorge:FindFirstChild("Falls")
if not F then print("QQ FP3 no Falls model") return end
local n, shown = 0, 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") and b.Name:sub(1, 6) == "Rapids" then
		n += 1
		if shown < 4 or b.Name == "Rapids3_13" or b.Name == "Rapids1_01" then
			shown += 1
			local a0, a1 = b.Attachment0, b.Attachment1
			local tk = b.Transparency.Keypoints
			print(string.format("QQ FP3 %s enabled %s parent %s | A0 %s (%s) A1 %s (%s) | w %.1f/%.1f tr %.2f..%.2f tex '%s' tlen %.0f speed %.2f seg %d zoff %.2f glow %.2f li %.2f | A0 look %s up %s right %s",
				b.Name, tostring(b.Enabled), b.Parent and b.Parent:GetFullName() or "nil",
				a0 and tostring(a0.WorldPosition) or "nil", a0 and a0:GetFullName() or "", a1 and tostring(a1.WorldPosition) or "nil", a1 and a1:GetFullName() or "",
				b.Width0, b.Width1, tk[1].Value, tk[#tk].Value, b.Texture, b.TextureLength, b.TextureSpeed, b.Segments, b.ZOffset, b.LightEmission, b.LightInfluence,
				a0 and tostring(a0.WorldCFrame.LookVector) or "", a0 and tostring(a0.WorldCFrame.UpVector) or "", a0 and tostring(a0.WorldCFrame.RightVector) or ""))
		end
	end
end
local rr = F:FindFirstChild("RapidsRig")
print(string.format("QQ FP3 rapids beams %d; RapidsRig %s; Falls class %s streaming mode %s", n, rr and tostring(rr.Position) or "none", F.ClassName, tostring(pcall(function() return F.ModelStreamingMode end))))
-- for comparison the fall's Sheet
local sh = F:FindFirstChild("Sheet", true)
if sh then print(string.format("QQ FP3 Sheet A0 %s A1 %s w %.1f/%.1f | A0 look %s up %s right %s", tostring(sh.Attachment0.WorldPosition), tostring(sh.Attachment1.WorldPosition), sh.Width0, sh.Width1, tostring(sh.Attachment0.WorldCFrame.LookVector), tostring(sh.Attachment0.WorldCFrame.UpVector), tostring(sh.Attachment0.WorldCFrame.RightVector))) end
print("QQ FP3 DONE")
