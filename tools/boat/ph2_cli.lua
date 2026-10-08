-- ph2 (PLAY, CLIENT, test only; Device Simulator): onto the jetty, hold the boat prompt once (warning 1), then list the note's
-- rect, the prompt button's rect and every visible screen element the note overlaps (real screen space)
local plr = game.Players.LocalPlayer
local ch = plr.Character
ch:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.GettingUp)
ch:PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1.5)
local pr = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
pr:InputHoldBegin(); task.wait(0.8); pr:InputHoldEnd()
task.wait(1.0)
local pg = plr:WaitForChild("PlayerGui")
local inset = game:GetService("GuiService"):GetGuiInset()
local vp = workspace.CurrentCamera.ViewportSize
local toast = pg.BoatUI:FindFirstChildOfClass("TextLabel")
local function rect(o) local p = o.AbsolutePosition + inset; local s = o.AbsoluteSize; return p.X, p.Y, p.X + s.X, p.Y + s.Y end
local function shown(o)
	local x = o
	while x and x ~= pg do
		if x:IsA("BillboardGui") or x:IsA("SurfaceGui") then return false end
		if x:IsA("GuiObject") and not x.Visible then return false end
		if x:IsA("LayerCollector") and not x.Enabled then return false end
		x = x.Parent
	end
	return true
end
local ax0, ay0, ax1, ay1 = rect(toast)
print(("QQ PH2 screen %dx%d inset %d note visible=%s %d,%d - %d,%d order %d '%s'"):format(vp.X, vp.Y, inset.Y, tostring(toast.Visible), ax0, ay0, ax1, ay1, pg.BoatUI.DisplayOrder, toast.Text))
for _, o in ipairs(pg.PromptTouch:GetDescendants()) do
	if o:IsA("TextButton") and o.Name == "Pill" and shown(o) then
		local x0, y0, x1, y1 = rect(o)
		print(("QQ PH2 prompt button %s %d,%d - %d,%d"):format(o:GetFullName(), x0, y0, x1, y1))
	end
end
local n = 0
for _, o in ipairs(pg:GetDescendants()) do
	if o:IsA("GuiObject") and o ~= toast and not o:IsDescendantOf(toast) and shown(o) and o.AbsoluteSize.X > 2 and o.AbsoluteSize.Y > 2 then
		local drawn = o.BackgroundTransparency < 1 or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 1) or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 1)
		local x0, y0, x1, y1 = rect(o)
		local full = (x1 - x0) >= 0.9 * vp.X and (y1 - y0) >= 0.9 * vp.Y
		if drawn and not full and x0 < ax1 and x1 > ax0 and y0 < ay1 and y1 > ay0 then
			n += 1
			print(("QQ PH2 OVERLAP %s  %d,%d - %d,%d"):format(o:GetFullName(), x0, y0, x1, y1))
		end
	end
end
print("QQ PH2 overlaps " .. n)
