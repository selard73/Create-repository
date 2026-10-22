-- chase31 (Oct 21 2026): two of Shannon's calls on the Baguette Chase, after chase30's preview:
--   1. "now its a little too low" - the TABLET card spot goes from centred 0.45 to 0.35 (iPad: card ~y 222-427).
--      Phones keep the top spot, computers keep their usual 0.45.
--   2. "the join button should go away once you have joined ... if the instructions button is up to keep chasing or
--      leave, that join button should be gone" - the sign's "Join the baguette chase" prompt hides, on this screen
--      only, while the info card is open OR while you are already in the chase. ALL devices (it is behaviour, not
--      layout). It comes back when the card closes and you have left the chase.
-- Run in Studio EDIT. Backs ChaseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local chase = workspace.Baguette.ChaseClient
local src = chase.Source

-- 1. the tablet spot: 0.45 -> 0.35 (only inside placeModal's else branch; the creation line has no "else" before it)
local old1 = [[		else
			modal.AnchorPoint = Vector2.new(0.5, 0.5); modal.Position = UDim2.fromScale(0.5, 0.45)
		end]]
local new1 = [[		else
			modal.AnchorPoint = Vector2.new(0.5, 0.5); modal.Position = UDim2.fromScale(0.5, 0.35)   -- (Shannon: 0.45 "a little too low")
		end]]
local a, b = src:find(old1, 1, true)
assert(a, "ChaseClient: placeModal else branch not found - nothing changed")
assert(not src:find(old1, b + 1, true), "ChaseClient: else branch found twice - nothing changed")
src = src:sub(1, a - 1) .. new1 .. src:sub(b + 1)

-- 2. the join prompt hides while the card is open or you are in the chase
local anchor2 = [[local xk = Instance.new("UICorner"); xk.CornerRadius = UDim.new(1, 0); xk.Parent = mx
]]
local add2 = anchor2 .. [[-- (Oct 21 2026, Shannon: "the join button should go away once you have joined" and while the card is up) the sign's
-- JOIN prompt hides, on this screen only, while the info card is open or while you are already in the chase - on
-- every device. Back when the card closes and you are out.
do
	local function promptNow()
		local sign = F:FindFirstChild("Stand")
		sign = sign and sign:FindFirstChild("Sign")
		local pr = sign and sign:FindFirstChild("ChasePrompt")
		if pr then pr.Enabled = not (modal.Visible or inChase()) end
	end
	modal:GetPropertyChangedSignal("Visible"):Connect(promptNow)
	player:GetAttributeChangedSignal("InChase"):Connect(promptNow)
	F.DescendantAdded:Connect(function(d) if d.Name == "ChasePrompt" then task.defer(promptNow) end end)
	promptNow()
end
]]
local c, d = src:find(anchor2, 1, true)
assert(c, "ChaseClient: close-button line not found - nothing changed")
assert(not src:find(anchor2, d + 1, true), "ChaseClient: close-button line found twice - nothing changed")
src = src:sub(1, c - 1) .. add2 .. src:sub(d + 1)

local bk = workspace.Baguette.ChaseClient:Clone(); bk.Name = "ChaseClient_pre_chase31"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(chase, function() return src end)
print(string.format("chase31: ChaseClient -> %d chars", #chase.Source))
return "chase31 installed"
