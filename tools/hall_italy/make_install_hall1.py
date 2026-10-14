#!/usr/bin/env python3
"""Builds tools/hall_italy/install_hall1.lua (job 94): the Belvedere dei Guardiani, the Italian Hall of Fame on the Prato dei
Fiori. The installer (install_hall1.template.lua) builds the architecture and embeds src/HallServer.lua, which builds the
pedestals and statues from the Guardian list at run time. Set the site below from the job 93 survey (the terrace's centre
and the way its FRONT faces: yaw 0 = north, -z; yaw -90 = east, +x; the crescent bulges the other way, toward the sea).
Run from the repo root: python3 tools/hall_italy/make_install_hall1.py
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
# THE SITE (job 93 survey, site E window; provisional until the runner's numbers are in)
CX, CZ, YAW = 500, -1080, -90
SERVER = (HERE / "src/HallServer.lua").read_text(encoding="utf-8")
TEMPLATE = (HERE / "install_hall1.template.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER, "the server source must not close the long string"
out = TEMPLATE
for key, val in {"@@CX@@": str(CX), "@@CZ@@": str(CZ), "@@YAW@@": str(YAW), "@@SERVER_LEN@@": str(len(SERVER)), "@@SERVER@@": SERVER}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_hall1.lua").write_text(out, encoding="utf-8")
print(f"install_hall1.lua {len(out.encode())} bytes; HallServer {len(SERVER)} chars; site ({CX}, {CZ}) yaw {YAW}")
