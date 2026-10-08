-- Oct 5 2026 (Shannon: "we should be able to ring this bell"): the brass harbour bell on the Capitaneria del Porto rings.
-- ProximityPrompt "Ring" (phones + PC), a bell sound everyone nearby hears, and the bell swings on its arm and settles.
-- Sound = the place's own bell sample, pitched down (placeholder until she picks one: change HarbourBell.Ding.SoundId).
local cap=workspace.PortoNocciola['02 Pastel waterfront']['Capitaneria del Porto']
local bell=cap:FindFirstChild('Brass harbour bell')
if not bell then warn('QHB@ABORT no bell') return end
if cap:FindFirstChild('HarbourBellScript') then warn('QHB@SKIP already installed') return end
local snd=Instance.new('Sound') snd.Name='Ding' snd.SoundId='rbxassetid://16480570986' snd.Volume=0.9 snd.PlaybackSpeed=0.62
snd.RollOffMode=Enum.RollOffMode.InverseTapered snd.RollOffMinDistance=12 snd.RollOffMaxDistance=90 snd.Parent=bell
local pp=Instance.new('ProximityPrompt') pp.Name='RingPrompt' pp.ActionText='Ring' pp.ObjectText='Harbour bell'
pp.HoldDuration=0 pp.MaxActivationDistance=10 pp.RequiresLineOfSight=false pp.KeyboardKeyCode=Enum.KeyCode.E pp.Parent=bell
bell:SetAttribute('HomeCFrame',bell.CFrame)
local s=Instance.new('Script') s.Name='HarbourBellScript'
s.Source=[[
-- Oct 5 2026: the harbour bell rings and swings (Shannon's ask). Sound: Ding under the bell (swap its SoundId to change it).
local TweenService = game:GetService("TweenService")
local bell = script.Parent:WaitForChild("Brass harbour bell")
local ding = bell:WaitForChild("Ding")
local prompt = bell:WaitForChild("RingPrompt")
local home = bell:GetAttribute("HomeCFrame") or bell.CFrame
local pivot = CFrame.new(home.Position + Vector3.new(0, bell.Size.Y / 2 + 0.1, 0))   -- where it hangs from the arm
local rel = pivot:Inverse() * home
local busy = false
local angle = Instance.new("NumberValue")
angle.Changed:Connect(function(a) bell.CFrame = pivot * CFrame.Angles(math.rad(a), 0, 0) * rel end)
prompt.Triggered:Connect(function()
	if busy then return end
	busy = true
	ding.TimePosition = 0
	ding:Play()
	for _, step in ipairs({{24, 0.18}, {-18, 0.32}, {12, 0.3}, {-7, 0.28}, {3, 0.24}, {0, 0.22}}) do
		local tw = TweenService:Create(angle, TweenInfo.new(step[2], Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = step[1]})
		tw:Play(); tw.Completed:Wait()
	end
	bell.CFrame = home
	task.wait(0.3)
	busy = false
end)
]]
s.Parent=cap
game:GetService('ChangeHistoryService'):SetWaypoint('Harbour bell rings')
warn('QHB@OK',bell:GetFullName(),bell.Anchored)
local cam=workspace.CurrentCamera
local t=bell.Position
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+Vector3.new(-7,1.5,4),t)
