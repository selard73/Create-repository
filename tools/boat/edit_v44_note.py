"""edit_v44_note.py: the jetty note board (her note, Oct 1 2026): new words, the post moved behind the board, and the board
always rebuilt from the current script. Run from tools/boat, then python build_install.py v44 "..." ."""
from pathlib import Path

p = Path("BoatServer.server.v2.lua")
s = p.read_text(encoding="utf-8")
if "her words, Oct 1" in s:
    raise SystemExit("already edited")

old_if = '\tif jetty and not jetty:FindFirstChild("ChuteNote") then\n'
new_if = ('\tlocal oldNote = jetty and jetty:FindFirstChild("ChuteNote"); if oldNote then oldNote:Destroy() end   -- v44: always the current board\n'
          '\tif jetty then\n')
assert s.count(old_if) == 1, "if"
s = s.replace(old_if, new_if)

old_post = ('local post = Instance.new("Part"); post.Name = "Post"; post.Size = Vector3.new(0.3, 3.8, 0.3); post.Color = Color3.fromRGB(96, 68, 42)\n'
            '\t\tpost.Material = Enum.Material.Wood; post.Anchored = true; post.CanCollide = false; post.CFrame = CFrame.new(163.75, 2.4, -150.0); post.Parent = board')
new_post = ('local post = Instance.new("Part"); post.Name = "Post"; post.Size = Vector3.new(0.3, 4.9, 0.3); post.Color = Color3.fromRGB(96, 68, 42)\n'
            '\t\t-- v44 (her note, Oct 1: "the post holding up this sign is covering the text"): the post stands BEHIND the board (-x), from the\n'
            '\t\t-- deck to just under the board\'s top edge, so the face (+x, the street side) is clear\n'
            '\t\tpost.Material = Enum.Material.Wood; post.Anchored = true; post.CanCollide = false; post.CFrame = CFrame.new(163.75 - 0.125 - 0.15 - 0.02, 2.95, -150.0); post.Parent = board')
assert s.count(old_post) == 1, "post"
s = s.replace(old_post, new_post)

NL = "\\" + "n"   # a Lua newline escape inside the string literal
old_t = 't.Text = "Sailing to Italy? The river ends in a WATERFALL!' + NL + 'Squirrels who have found all 44 can borrow a parachute from the Sky Diving Squirrel in the forest. Ask him first!"'
new_t = ('t.Text = "Sailing to Italy today?' + NL + 'If you have found all 44 squirrels, you can take the boat.' + NL +
         'You might want to check in with Sky Diving Squirrel before you leave."   -- her words, Oct 1')
assert s.count(old_t) == 1, "text"
s = s.replace(old_t, new_t)

p.write_text(s, encoding="utf-8")
print("BoatServer.server.v2.lua: jetty note board updated")
