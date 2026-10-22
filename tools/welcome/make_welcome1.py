"""Builds welcome1.lua (the installer, WelcomeClient inlined) and two play-test previews in the scratchpad that apply the SAME
edits to runtime copies of the scripts: p_welcome_server.lua (HintServer, the board, the hens' eyes) and p_welcome_client.lua
(HintClient, DailyClient, WelcomeClient). Run: python -I make_welcome1.py <scratchpad dir>"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
def read(p): return io.open(os.path.join(HERE, p), encoding="utf-8").read().replace("\r\n", "\n")
head = read("welcome1_head.lua")
welcome = read("src/WelcomeClient.lua")
assert "]==]" not in welcome
io.open(os.path.join(HERE, "welcome1.lua"), "w", encoding="utf-8", newline="\n").write(head.replace("@@WELCOME@@", welcome))
block = head.split("--@@EDITS_BEGIN\n")[1].split("--@@EDITS_END\n")[0]
RUN = '''local function swap(name)                                          -- PREVIEW: a runtime copy running the patched source
	local pair = EDITS[name]
	local src = patched(pair[1], pair[2])
	local copy = pair[1]:Clone(); copy.Name = pair[1].Name .. "_preview"
	pair[1].Enabled = false
	copy.Source = src
	copy.Parent = pair[1].Parent
	copy.Enabled = true
end
'''
server = block + RUN + '''swap("HintServer")
local at = moveBoard()
local n = eyes()
return string.format("preview: HintServer patched copy running; board #2 at %.0f,%.0f,%.0f; %d hens with eyes", at.X, at.Y, at.Z, n)
'''
client = block + RUN + '''local pg = game:GetService("Players").LocalPlayer.PlayerGui
for _, g in ipairs({"HintGui", "DailyGui"}) do if pg:FindFirstChild(g) then pg[g]:Destroy() end end
swap("HintClient")
swap("DailyClient")
local wc = Instance.new("Script"); wc.Name = "WelcomeClient_preview"; wc.RunContext = Enum.RunContext.Client
wc.Source = [==[
''' + welcome + ''']==]
wc.Parent = workspace
return "preview: HintClient + DailyClient patched copies and WelcomeClient running"
'''
def strip(s): return "\n".join(l for l in s.split("\n") if not l.lstrip().startswith("--"))
for name, s in (("p_welcome_server.lua", server), ("p_welcome_client.lua", client)):
    io.open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n").write(strip(s))
print("installer", len(head.replace("@@WELCOME@@", welcome)), "| previews", len(strip(server)), len(strip(client)))
