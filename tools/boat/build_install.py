"""build_install.py VERSION "NOTE": regenerates tools/boat/install_boat_i6.lua from BoatServer.server.v2.lua and
BoatClient.client.v2.lua (both embedded in [=====[ ]=====] long strings). Run from tools/boat."""
import io, sys
ver, note = sys.argv[1], sys.argv[2]
srv = io.open("BoatServer.server.v2.lua", encoding="utf-8-sig").read()
cli = io.open("BoatClient.client.v2.lua", encoding="utf-8-sig").read()
for name, src in (("server", srv), ("client", cli)):
    if "]=====]" in src:
        raise SystemExit("long-string terminator inside the " + name + " source")
    if not src.endswith("\n"):
        raise SystemExit(name + " source does not end with a newline")
out = []
out.append("-- install_boat_i6 " + ver + " (" + note + "): sets workspace.Boat.BoatServer and\n")
out.append("-- workspace.Boat.BoatClient with v2 (tools/boat/BoatServer.server.v2.lua / BoatClient.client.v2.lua): past the brink the boat\n")
out.append("-- falls, the passenger is thrown out (parachute if they found the Sky Diving Squirrel), the hull breaks up on the pool, two\n")
out.append("-- pieces wash along the shore, a welcome note. Everything else about the boat is unchanged. BoatEvent and the folder stay.\n")
out.append("-- The previous sources are kept in ServerStorage.GorgeBackup.BoatScripts_v1 (BoatServer_v1 / BoatClient_v1) the first time.\n")
out.append('local B = workspace.Boat\n')
out.append('local SS = game:GetService("ServerStorage")\n')
out.append('local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"\n')
out.append('local bk = GB:FindFirstChild("BoatScripts_v1")\n')
out.append('if not bk then\n')
out.append('\tbk = Instance.new("Folder"); bk.Name = "BoatScripts_v1"; bk.Parent = GB\n')
out.append('\tlocal a = B.BoatServer:Clone(); a.Name = "BoatServer_v1"; a.Disabled = true; a.Parent = bk\n')
out.append('\tlocal b = B.BoatClient:Clone(); b.Name = "BoatClient_v1"; b.Disabled = true; b.Parent = bk\n')
out.append('end\n')
out.append('B.BoatServer.Source = [=====[' + srv + ']=====]\n')
out.append('B.BoatClient.Source = [=====[' + cli + ']=====]\n')
out.append('B:SetAttribute("Built", "i6 2026-10-01 over the falls ' + ver + '")\n')
out.append('local ns, nc = 0, 0\n')
out.append('for _ in (B.BoatServer.Source .. "\\n"):gmatch("(.-)\\n") do ns += 1 end\n')
out.append('for _ in (B.BoatClient.Source .. "\\n"):gmatch("(.-)\\n") do nc += 1 end\n')
out.append('print(string.format("QQ I6 ' + ver + ' installed: BoatServer %d lines, BoatClient %d lines; backup %s", ns, nc, bk:GetFullName()))\n')
out.append('print("QQ I6 DONE")\n')
text = "".join(out)
io.open("install_boat_i6.lua", "w", encoding="utf-8", newline="\n").write(text)
print("install_boat_i6.lua", ver, len(text), "chars; server", srv.count("\n"), "lines; client", cli.count("\n"), "lines")
