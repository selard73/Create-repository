-- ph1 (PLAY, CLIENT, read-only): wait for the boat note to show, then list every visible screen element it overlaps
local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local inset = game:GetService("GuiService"):GetGuiInset()
local toast
for _ = 1, 120 do
	local g = pg:FindFirstChild("BoatUI"); toast = g and g:FindFirstChildOfClass("TextLabel")
	if toast and toast.Visible then break end
	task.wait(0.25)
end
if not (toast and toast.Visible) then warn("QQ PH1 no note showed"); return end
task.wait(0.4)
local vp = workspace.CurrentCamera.ViewportSize
local function rect(o) local p = o.AbsolutePosition + inset; local s = o.AbsoluteSize; return p.X, p.Y, p.X + s.X, p.Y + s.Y end
local function shown(o)
	local x = o
	while x and x ~= pg do
		if x:IsA("BillboardGui") or x:IsA("SurfaceGui") then return false end        -- world-space, not screen rects
		if x:IsA("GuiObject") and not x.Visible then return false end
		if x:IsA("LayerCollector") and not x.Enabled then return false end
		x = x.Parent
	end
	return true
end
local ax0, ay0, ax1, ay1 = rect(toast)
warn(("QQ PH1 screen %dx%d note %d,%d - %d,%d '%s'"):format(vp.X, vp.Y, ax0, ay0, ax1, ay1, toast.Text))
local n = 0
for _, o in ipairs(pg:GetDescendants()) do
	if o:IsA("GuiObject") and o ~= toast and not o:IsDescendantOf(toast) and shown(o) and o.AbsoluteSize.X > 2 and o.AbsoluteSize.Y > 2 then
		local drawn = o.BackgroundTransparency < 1 or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 1) or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 1)
		local x0, y0, x1, y1 = rect(o)
		local full = (x1 - x0) >= 0.9 * vp.X and (y1 - y0) >= 0.9 * vp.Y
		if drawn and not full and x0 < ax1 and x1 > ax0 and y0 < ay1 and y1 > ay0 then
			n += 1
			warn(("QQ PH1 OVERLAP %s  %d,%d - %d,%d"):format(o:GetFullName(), x0, y0, x1, y1))
		end
	end
end
warn("QQ PH1 overlaps " .. n)
