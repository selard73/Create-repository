"""pack.py SRC.lua OUT.rbxmx FOLDERNAME : Folder + ModuleScript PatchModule 'return function() ... end' (Import Roblox Model, then
local m=workspace:FindFirstChild('<FOLDERNAME>',true) require(m.PatchModule)() m:Destroy())"""
import sys
from pathlib import Path
src=Path(sys.argv[1]).read_text(encoding='utf-8'); assert ']]>' not in src
body="return function()\n"+src+"\nend\n"
xml='<roblox version="4"><Item class="Folder" referent="RBX0"><Properties><string name="Name">'+sys.argv[3]+'</string></Properties><Item class="ModuleScript" referent="RBX1"><Properties><string name="Name">PatchModule</string><ProtectedString name="Source"><![CDATA['+body+']]></ProtectedString></Properties></Item></Item></roblox>'
Path(sys.argv[2]).write_text(xml,encoding='utf-8'); print('packed',sys.argv[2],len(xml))
