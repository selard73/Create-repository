-- Puts a UFO model back together if its pieces were dragged apart. Select the model, paste, Enter.
-- Works when ufo_setup.lua (Sep 10 or later) has been run on that model; otherwise re-import ufo.obj.
local model = workspace:FindFirstChild("UFO") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the UFO model first")
local padBase = model:FindFirstChild("PadBase"); assert(padBase, "no PadBase in the model")
local n, missing = 0, 0
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") and p ~= padBase then
		local off = p:GetAttribute("HomeOffset")
		if off then p.CFrame = padBase.CFrame * off; n += 1 else missing += 1 end
	end
end
if missing > 0 then
	print("Reassembled", n, "pieces, but", missing, "have no saved position. Delete the model, re-import ufo.obj and run ufo_setup.lua.")
else
	print("Reassembled", n, "pieces around the pad")
end
