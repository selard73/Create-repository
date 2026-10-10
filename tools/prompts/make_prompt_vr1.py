#!/usr/bin/env python3
"""prompt_vr1.lua: PromptClient patched so that IN VR the interact pill sits in the world beside the thing itself.

Shannon (Oct 10, VR): "the interact button for the race and the opera singer in the square is missing completely".
PromptUI draws every pill on a BillboardGui over the player's OWN head (2.4 studs up, out to the right) - behind a
headset's eyes, so in VR no pill ever showed. Patch (exact strings, length guard, backup HudBackup.PromptClient_pre_vr1):
  1. VRService.VREnabled read once.
  2. showVR(prompt, key): a BillboardGui on the prompt's own part, sized in studs (0.6-0.8 tall), with the badge for
     the controller button, the object and action texts, the hold fill; pressed with the pointer (press = hold begins,
     release = hold ends, a tap on a hold-pill completes the hold), with a click fallback.
  3. PromptShown hands VR to showVR; the daily-card blocker hides VR pills too; the phone loop skips them.
"""
import pathlib, re
HERE = pathlib.Path(__file__).resolve().parent
SRC = (HERE.parent / "prompts_src" / "PromptClient.lua").read_bytes().decode("utf-8")
assert len(SRC) == 23746, len(SRC)

def patch(src, old, new, count=1):
    assert src.count(old) == count, (src.count(old), old[:80])
    return src.replace(old, new)

NEW = SRC

# 1. VR flag
NEW = patch(NEW, 'local UIS = game:GetService("UserInputService")\n',
            'local UIS = game:GetService("UserInputService")\n'
            'local VR = game:GetService("VRService").VREnabled\n')

# 1b. the VR hold bookkeeping, before release() (the global InputEnded handler below it uses vrHolds)
NEW = patch(NEW, 'local function release()\n',
            'local vrHolds = {}            -- [prompt] = {began, finish}: VR pills being pressed right now (job 73)\n'
            'local vrPressSeen = false     -- the pointer has delivered a press to a pill (so its click is never a second one)\n'
            'local function release()\n')
# 2. showVR before keyName (release/pressed/dailyBlocked are defined above it)
SHOW_VR = r'''-- IN VR THE PILL SITS IN THE WORLD beside the thing itself (Shannon, Oct 10: the race's and the singer's buttons were
-- "missing completely" - the pill rode on her own head, out of sight behind the headset's eyes). A BillboardGui on the
-- prompt's own part, sized in studs so it reads at arm's length; pointed at and pressed with the controller (the fill
-- grows while a hold-pill is held, and a quick tap completes the hold); the controller button on the badge works too,
-- as the engine handles that on its own.
local function showVR(prompt, key)
	local action, object = prompt.ActionText, prompt.ObjectText
	local wA = TextService:GetTextSize(action, 15, FONT, Vector2.new(500, 40)).X
	local wO = object ~= "" and TextService:GetTextSize(object, 11, FONT, Vector2.new(500, 40)).X or 0
	local H = object ~= "" and 0.8 or 0.6                                          -- studs
	local badgeW = key and H * 0.62 or 0
	local W = math.max(1.8, math.min(6, math.max(wA / 38, wO / 44) + badgeW + 0.35))
	local bgui = Instance.new("BillboardGui"); bgui.Name = "PromptVR"; bgui.Adornee = prompt.Parent
	bgui.Size = UDim2.fromScale(W, H); bgui.AlwaysOnTop = true; bgui.LightInfluence = 0; bgui.Active = true; bgui.ResetOnSpawn = false
	bgui.MaxDistance = prompt.MaxActivationDistance + 15; bgui.Enabled = not dailyBlocked
	bgui.ExtentsOffsetWorldSpace = Vector3.new(0, 1, 0); bgui.StudsOffsetWorldSpace = Vector3.new(0, 0.9 - prompt.UIOffset.Y / 40, 0)
	bgui.Parent = pg
	local btn = Instance.new("TextButton"); btn.Name = "Pill"; btn.Size = UDim2.fromScale(1, 1); btn.BackgroundColor3 = C(38, 30, 52); btn.BackgroundTransparency = 0.12
	btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.Active = true; btn.ClipsDescendants = true; btn.Parent = bgui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.3, 0); c.Parent = btn
	local s = Instance.new("UIStroke"); s.Color = C(240, 200, 90); s.Thickness = 2; s.Parent = btn
	local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = C(240, 200, 90); fill.BackgroundTransparency = 0.7; fill.BorderSizePixel = 0; fill.ZIndex = 1; fill.Parent = btn
	local left = 0.05
	if key then
		local kb = Instance.new("TextLabel"); kb.AnchorPoint = Vector2.new(0, 0.5); kb.Position = UDim2.fromScale(0.04, 0.5); kb.Size = UDim2.fromScale(1, 0.62)
		kb.BackgroundColor3 = C(255, 246, 220); kb.Text = key; kb.Font = FONT; kb.TextScaled = true; kb.TextColor3 = C(38, 30, 52); kb.ZIndex = 2; kb.Parent = btn
		local ar = Instance.new("UIAspectRatioConstraint"); ar.AspectRatio = 1; ar.DominantAxis = Enum.DominantAxis.Height; ar.Parent = kb
		local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0.25, 0); kc.Parent = kb
		local kp = Instance.new("UIPadding"); kp.PaddingTop = UDim.new(0.14, 0); kp.PaddingBottom = UDim.new(0.14, 0); kp.Parent = kb
		left = 0.04 + badgeW / W + 0.04
	end
	local a = Instance.new("TextLabel"); a.BackgroundTransparency = 1; a.Font = FONT; a.TextScaled = true; a.TextColor3 = C(255, 246, 220)
	a.TextXAlignment = Enum.TextXAlignment.Left; a.Text = action; a.ZIndex = 2
	if object ~= "" then
		local o = Instance.new("TextLabel"); o.Position = UDim2.fromScale(left, 0.1); o.Size = UDim2.fromScale(1 - left - 0.04, 0.3); o.BackgroundTransparency = 1
		o.Font = FONT; o.TextScaled = true; o.TextColor3 = C(200, 190, 210); o.TextXAlignment = Enum.TextXAlignment.Left; o.Text = object; o.ZIndex = 2; o.Parent = btn
		a.Position = UDim2.fromScale(left, 0.42); a.Size = UDim2.fromScale(1 - left - 0.04, 0.46)
	else
		a.Position = UDim2.fromScale(left, 0.2); a.Size = UDim2.fromScale(1 - left - 0.04, 0.6)
	end
	a.Parent = btn
	-- the press: the pointer's trigger counts as MouseButton1 (a finger as Touch). The hold begins on the press and ends
	-- after the release - or after the prompt's HoldDuration if the press was shorter, so a tap works on a hold-pill. A
	-- release anywhere ends it too (the pointer slid off the pill: vrHolds, below). If this pointer never delivers a
	-- press, its click (which arrives on the release) does the whole hold instead - once a press has been seen, never.
	local seq = 0
	local function endAfter(secs)
		seq += 1; local my = seq
		task.delay(secs, function()
			if my ~= seq then return end
			if s.Parent then s.Color = C(240, 200, 90) end
			pcall(function() prompt:InputHoldEnd() end)
		end)
	end
	local function finish()                                   -- the release: end the hold once it has lasted long enough
		local h = vrHolds[prompt]; if not h then return end
		vrHolds[prompt] = nil
		endAfter(math.max(0, prompt.HoldDuration - (os.clock() - h.began)) + 0.05)
	end
	btn.InputBegan:Connect(function(io)
		if dailyBlocked then return end
		if io.UserInputType ~= Enum.UserInputType.MouseButton1 and io.UserInputType ~= Enum.UserInputType.Touch then return end
		vrPressSeen = true
		seq += 1; vrHolds[prompt] = {began = os.clock(), finish = finish}; s.Color = C(255, 246, 220)
		pcall(function() prompt:InputHoldBegin() end)
	end)
	btn.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then finish() end
	end)
	btn.MouseButton1Click:Connect(function()
		if dailyBlocked or vrPressSeen or vrHolds[prompt] then return end
		s.Color = C(255, 246, 220)
		pcall(function() prompt:InputHoldBegin() end)
		endAfter(math.max(0, prompt.HoldDuration) + 0.1)
	end)
	return {pill = btn, fill = fill, stroke = s, holder = bgui, vr = true}
end
'''
NEW = patch(NEW, 'local function keyName(prompt, inputType)\n', SHOW_VR + 'local function keyName(prompt, inputType)\n')

# 3a. PromptShown hands VR over
NEW = patch(NEW, '\tlocal key = (not touch) and keyName(prompt, inputType) or nil\n',
            '\tlocal key = (not touch) and keyName(prompt, inputType) or nil\n'
            '\tif VR and not touch then                           -- VR: the pill in the world, by the thing itself\n'
            '\t\tif live[prompt] then local o = live[prompt]; (o.holder or o.pill):Destroy(); if o.hl then o.hl:Destroy() end end\n'
            '\t\tlive[prompt] = showVR(prompt, key)\n'
            '\t\treturn\n'
            '\tend\n')
# 3b. the daily-card / panel blocker hides VR pills too
NEW = patch(NEW, ' for _, rec in pairs(live) do if rec.hl then rec.hl.Enabled = not blocked end end\n',
            ' for _, rec in pairs(live) do if rec.hl then rec.hl.Enabled = not blocked end; if rec.vr then rec.holder.Enabled = not blocked end end\n')
# 3c'. a release anywhere ends open VR holds too
NEW = patch(NEW, 'UIS.InputEnded:Connect(function(io)                   -- a finger that slides off the pill still ends the hold\n'
            '\tif io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then release() end\n',
            'UIS.InputEnded:Connect(function(io)                   -- a finger that slides off the pill still ends the hold\n'
            '\tif io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then\n'
            '\t\trelease()\n'
            '\t\tfor _, h in pairs(vrHolds) do h.finish() end          -- (a VR pill the pointer slid off)\n'
            '\tend\n')
# 3c''. a hidden prompt is no longer held
NEW = patch(NEW, '\tif pressed and pressed.prompt == prompt then pressed = nil end\n',
            '\tif pressed and pressed.prompt == prompt then pressed = nil end\n'
            '\tvrHolds[prompt] = nil\n')
# 3c. the phone's half-second placer skips VR pills
NEW = patch(NEW, '\t\tfor _, rec in pairs(live) do if rec.holder then placeTouch() break end end\n',
            '\t\tfor _, rec in pairs(live) do if rec.holder and not rec.vr then placeTouch() break end end\n')
assert ']===]' not in NEW and ']===]' not in SRC
OLD_LEN, NEW_LEN = len(SRC), len(NEW)

INSTALLER = f'''-- prompt_vr1.lua (Studio EDIT mode, run once; re-running is a no-op). Job 73.
-- workspace.PromptUI.PromptClient: in VR the interact pill is drawn in the world beside the thing itself (it rode on the
-- player's own head, unseen behind a headset's eyes - Shannon: the race's and the singer's buttons "missing completely").
-- Exact-string patch of the live {OLD_LEN}-char source -> {NEW_LEN} chars; backup ServerStorage.HudBackup.PromptClient_pre_vr1.
-- Undo: PromptClient.Source = HudBackup.PromptClient_pre_vr1.Source. Nothing else changes; no publish.
local SS = game:GetService("ServerStorage")
local pu = workspace:FindFirstChild("PromptUI"); local pc = pu and pu:FindFirstChild("PromptClient")
if not pc then print("QQ PVR ABORT: workspace.PromptUI.PromptClient not found") return end
local NEW = [===[
{NEW}]===]
if #pc.Source == {NEW_LEN} and pc.Source == NEW then print("QQ PVR DONE (already installed): PromptClient {NEW_LEN}") return end
if #pc.Source ~= {OLD_LEN} then print(string.format("QQ PVR ABORT: PromptClient is %d chars, expected {OLD_LEN} (not the exported copy; export again)", #pc.Source)) return end
local f, err = loadstring(NEW); if not f then print("QQ PVR ABORT: the new client does not compile: " .. tostring(err)) return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("PromptClient_pre_vr1") then local b = Instance.new("ModuleScript"); b.Name = "PromptClient_pre_vr1"; b.Source = pc.Source; b.Parent = hb end
pc.Source = NEW
print(string.format("QQ PVR DONE: PromptClient %d -> %d chars (backup HudBackup.PromptClient_pre_vr1); VR pills in the world", {OLD_LEN}, #pc.Source))
'''
(HERE / "prompt_vr1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
(HERE / "src").mkdir(exist_ok=True)
(HERE / "src" / "PromptClient_vr1.lua").write_text(NEW, encoding="utf-8", newline="\n")
print("prompt_vr1.lua written:", OLD_LEN, "->", NEW_LEN)
