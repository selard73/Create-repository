"""Packs builder.lua into export/DomaineBuilder.rbxmx: a Folder 'DomaineBuilder' (attributes: Enabled, Seed, MapId, MapName,
HideSquirrels, StreetEndX, StreetZ, GroundY) with a ModuleScript 'BuildModule'.
Studio: File > Import Roblox Model > export/DomaineBuilder.rbxmx, then require(workspace.DomaineBuilder.BuildModule)().
Run: python make_domaine_scripts.py"""
import xml.dom.minidom as md
from pathlib import Path

D = Path(__file__).parent
src = (D / "builder.lua").read_text(encoding="utf-8")
# the runtime scripts the builder installs (wind, hens + pump, tractor) are kept as their own files and injected here
for tag, fn in (("@@CLIENT@@", "script_client.lua"), ("@@LIFE@@", "script_life.lua"), ("@@DRIVE@@", "script_drive.lua"), ("@@DRIVECLIENT@@", "script_drive_client.lua"), ("@@GARDEN@@", "script_garden.lua")):
    body = (D / fn).read_text(encoding="utf-8")
    assert "]=]" not in body, fn
    assert tag in src, tag
    src = src.replace(tag, body)
assert "]]>" not in src
xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties>
      <string name="Name">DomaineBuilder</string>
      <Attributes name="AttributesSerialize">
        <Attribute name="Enabled"><bool>true</bool></Attribute>
        <Attribute name="Seed"><double>7</double></Attribute>
        <Attribute name="MapId"><string>domaine</string></Attribute>
        <Attribute name="MapName"><string>Château de l'Acorn</string></Attribute>
        <Attribute name="HideSquirrels"><bool>true</bool></Attribute>
        <Attribute name="StreetEndX"><double>350</double></Attribute>
        <Attribute name="StreetZ"><double>-120</double></Attribute>
        <Attribute name="GroundY"><double>0.55</double></Attribute>
      </Attributes>
    </Properties>
    <Item class="ModuleScript" referent="RBX1">
      <Properties>
        <string name="Name">BuildModule</string>
        <ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString>
      </Properties>
    </Item>
  </Item>
</roblox>
'''
md.parseString(xml.encode("utf-8"))
(D / "export").mkdir(exist_ok=True)
(D / "export" / "DomaineBuilder.rbxmx").write_text(xml, encoding="utf-8")
print("wrote export/DomaineBuilder.rbxmx", len(src), "chars of Lua")
