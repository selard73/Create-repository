-- phone11 (Oct 20 2026): the Hint-on-top / Baguette-Chase-under layout (tablet2) for phones too (Shannon: "yes please").
-- On a Galaxy S22 Ultra the chase button covered Hint completely (both 12,64..104). Computers unchanged. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local cc = workspace.Baguette.ChaseClient
local src = cc.Source
local function replaceOnce(s, find, repl, what)
	local a, b = s:find(find, 1, true)
	assert(a, what .. ": not found - nothing changed")
	assert(not s:find(find, b + 1, true), what .. ": found twice - nothing changed")
	return s:sub(1, a - 1) .. repl .. s:sub(b + 1)
end
src = replaceOnce(src, "if math.min(vp.X, vp.Y) >= 600 and hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then", "if hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then", "tablet condition")
src = replaceOnce(src, "-- just under Hint while Hint shows. Phones keep the spot above, as before.", "-- just under Hint while Hint shows. (Later Oct 20: phones too - it covered Hint on every phone; measured from the Hint\n-- button itself, so it lands right on every screen size.)", "comment")
local bk = cc:Clone(); bk.Name = "ChaseClient_pre_phone11"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(cc, function() return src end)
return "phone11 installed"
