-- medal18 (Oct 20 2026): Shannon: "do you think we really need the medal? you can see the same thing if you click that pill at
-- the very top center" -> "ok; please do that": no medal on phones and tablets (touch layout, the same test HintClient uses);
-- computers keep it. The title pill still opens the badge case everywhere. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local bc = workspace.BadgeCase.BadgeCaseClient
local src = bc.Source
local function replaceOnce(s, find, repl, what)
	local a, b = s:find(find, 1, true)
	assert(a, what .. ": not found - nothing changed")
	assert(not s:find(find, b + 1, true), what .. ": found twice - nothing changed")
	return s:sub(1, a - 1) .. repl .. s:sub(b + 1)
end
src = replaceOnce(src, "local function placeMedal()\n",
	"-- (Oct 20 2026; Shannon: \"do you think we really need the medal? you can see the same thing if you click that pill at the\n" ..
	"-- very top center\" - \"ok; please do that\") phones and tablets: no medal - the title pill opens the same case; computers keep it\n" ..
	"local medalUIS = game:GetService(\"UserInputService\")\n" ..
	"local NO_MEDAL = medalUIS.TouchEnabled and not medalUIS.KeyboardEnabled   -- (the same touch test HintClient uses)\n" ..
	"local function placeMedal()\n", "placeMedal header")
src = replaceOnce(src, "medalBtn.Visible = (isKeeper() or d > 0) and hintButton ~= nil and hintButton.Visible and hintGui.Enabled\n",
	"medalBtn.Visible = (isKeeper() or d > 0) and hintButton ~= nil and hintButton.Visible and hintGui.Enabled and not NO_MEDAL\n", "visible line")
local bk = bc:Clone(); bk.Name = "BadgeCaseClient_pre_medal18"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(bc, function() return src end)
return "medal18 installed"
