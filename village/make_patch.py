"""Packs a patch module into export/<Name>.rbxmx: a Folder <Name> holding a ModuleScript 'PatchModule' whose source is the
given Lua file (which must `return function() ... end`).
Studio: File > Import Roblox Model > export/<Name>.rbxmx, then require(workspace.<Name>.PatchModule)() in edit mode.
Run: python make_patch.py PatchBookshop patch_bookshop.lua"""
import sys
from pathlib import Path

D = Path(__file__).parent
name, lua = sys.argv[1], sys.argv[2]
src = (D / lua).read_text(encoding="utf-8")
assert "]]>" not in src
xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0"><Properties><string name="Name">{name}</string></Properties>
    <Item class="ModuleScript" referent="RBX1"><Properties><string name="Name">PatchModule</string><ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString></Properties></Item>
  </Item>
</roblox>
'''
out = D / "export" / f"{name}.rbxmx"
out.write_text(xml, encoding="utf-8")
print("wrote", out, len(src), "chars of Lua")
