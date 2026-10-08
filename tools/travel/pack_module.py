"""pack_module.py NAME SOURCE.lua [NOTE]: packs a Studio installer as export/NAME.rbxmx = a Folder NAME with a ModuleScript
PatchModule whose source is "return function() <installer> end". In Studio: Explorer > right-click Workspace > Insert >
Import Roblox Model > the file, then require(workspace.NAME.PatchModule)() and workspace.NAME:Destroy(). Run from tools/travel."""
import sys
from pathlib import Path

name, src_path = sys.argv[1], sys.argv[2]
note = sys.argv[3] if len(sys.argv) > 3 else src_path
src = Path(src_path).read_text(encoding="utf-8")
assert "]]>" not in src, "CDATA terminator inside the source"
body = "-- " + name + ".PatchModule: " + note + "\nreturn function()\n" + src + "\nend\n"
xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
       'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
       '  <Item class="Folder" referent="RBX0"><Properties><string name="Name">' + name + '</string></Properties>\n'
       '    <Item class="ModuleScript" referent="RBX1"><Properties><string name="Name">PatchModule</string>'
       '<ProtectedString name="Source"><![CDATA[' + body + ']]></ProtectedString></Properties></Item>\n'
       '  </Item>\n</roblox>\n')
out = Path(__file__).parent / "export" / (name + ".rbxmx")
out.write_text(xml, encoding="utf-8")
print("packed", out, len(body), "chars")
