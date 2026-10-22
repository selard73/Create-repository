"""Builds funnel2: applies funnel2_head.lua's FunnelServer edits to src/FunnelServer.lua (the live source, Oct 22), writes the
installer funnel2.lua (SquirrelStats + StatsClient inlined) and the play-test previews p_*.lua in the scratchpad.
Run: python -I make_funnel2.py <scratchpad dir>"""
import io, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
def read(p): return io.open(os.path.join(HERE, p), encoding="utf-8").read().replace("\r\n", "\n")
head = read("funnel2_head.lua")
server = read("src/FunnelServer.lua")
stats = read("src/SquirrelStats.lua")
client = read("src/StatsClient.lua")
# the edit pairs, in order: {[==[old]==], [==[new]==], "what"}
pairs = re.findall(r"\{\[==\[(.*?)\]==\],\s*\[==\[(.*?)\]==\], \"[^\"]+\"\}", head, re.S)
assert len(pairs) == 4, len(pairs)
for old, new in pairs:
    assert server.count(old) == 1, old[:60]
    server = server.replace(old, new)
for s in (stats, client):
    assert "]==]" not in s
inst = head.replace("@@STATS@@", stats).replace("@@CLIENT@@", client)
io.open(os.path.join(HERE, "funnel2.lua"), "w", encoding="utf-8", newline="\n").write(inst)
io.open(os.path.join(HERE, "src", "FunnelServer_funnel2.lua"), "w", encoding="utf-8", newline="\n").write(server)
def strip(s): return "\n".join(l for l in s.split("\n") if not l.lstrip().startswith("--"))
def rep(s, old, new):
    assert s.count(old) == 1, old
    return s.replace(old, new)
# previews: the live FunnelServer is switched off first; script.Parent becomes workspace.Funnel
pf = rep(server, "local F = script.Parent\n", 'local F = workspace.Funnel\nif F:FindFirstChild("FunnelServer") then F.FunnelServer.Enabled = false end\n')
pf = rep(pf, 'print("Funnel: ready (11 steps; events leave only a published place)")', 'return "preview FunnelServer (11 steps) running"')
ps = rep(stats, "local F = script.Parent\n", "local F = workspace.Funnel\n")
ps = rep(ps, 'print("Stats: ready (SquirrelFound, StillMissing, QuitInFrance, AreaFPS/AreaMemory; events leave only a published place)")',
         '_G.StatsLeave = leaving\nreturn "preview SquirrelStats running"')
pc = rep(client, "local ev = script.Parent:WaitForChild(\"StatsEvent\", 60)", "local ev = workspace.Funnel:WaitForChild(\"StatsEvent\", 60)")
pc = pc + '\nreturn "preview StatsClient running"\n'
for name, s in (("p_funnel_server.lua", pf), ("p_stats_server.lua", ps), ("p_stats_client.lua", pc)):
    io.open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n").write(strip(s))
print("installer", len(inst), "| server", len(server), "| previews", len(strip(pf)), len(strip(ps)), len(strip(pc)))
