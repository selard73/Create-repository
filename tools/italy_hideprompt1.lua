-- italy_hideprompt1: switch off the moored boat's drive prompt until Italy exists (Shannon OK'd Sep 30). Undo: set Enabled = true.
local p = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
p.Enabled = false
print("QQ HP1 BoatPrompt Enabled", p.Enabled, p:GetFullName())
