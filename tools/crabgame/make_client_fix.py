"""make_client_fix.py N "note": wrap the current CrabClient.client.lua into fixN.lua (sets StarterPlayerScripts.CrabClient.Source)
and pack it as ../italy_squirrels/cgN+1.rbxmx (folder CrabFixN). Reads the source raw - no escape processing anywhere."""
import sys, os
from pathlib import Path
D = Path(__file__).parent
n, note = sys.argv[1], sys.argv[2]
cli = (D / "CrabClient.client.lua").read_text(encoding="utf-8")
assert "]==]" not in cli and "]]>" not in cli
# a quoted string must never contain a raw newline: every line has an even number of double quotes outside comments
for i, line in enumerate(cli.split("\n"), 1):
    code = line.split("--")[0]
    if code.count('"') % 2:
        raise SystemExit(f"odd quotes on line {i}: {line!r}")
fx = (f"-- Oct 4 2026 crab game fix {n}: {note}\n"
      "local cli=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CrabClient')\n"
      "if cli then cli.Source=[==[" + cli + "]==] end\n"
      f"game:GetService('ChangeHistoryService'):SetWaypoint('Crab game fix {n}')\n"
      f"warn('QX@OK{n} client',cli and #cli.Source)\n")
(D / f"fix{n}.lua").write_text(fx, encoding="utf-8")
body = "return function()\n" + fx + "\nend\n"
xml = ('<roblox version="4"><Item class="Folder" referent="RBX0"><Properties><string name="Name">CrabFix' + n +
       '</string></Properties><Item class="ModuleScript" referent="RBX1"><Properties><string name="Name">PatchModule</string>'
       '<ProtectedString name="Source"><![CDATA[' + body + ']]></ProtectedString></Properties></Item></Item></roblox>')
out = D.parent / "italy_squirrels" / f"cg{int(n) + 1}.rbxmx"
out.write_text(xml, encoding="utf-8")
print("packed", out, len(xml))
