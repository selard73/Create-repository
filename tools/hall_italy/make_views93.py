#!/usr/bin/env python3
"""Writes tools/hall_italy/view93_<site><n>.lua (job 93): one small EDIT-mode script per picture of a candidate site for
the Italian Hall of Fame. Each moves ONLY the editor camera: a standing view at eye height from the way a player walks up,
and a high three-quarter view. The camera's height comes from a ray at run time (ground + 5.5 for the eye, + 24 for the
high view), so no view starts under paving or inside a slope. Run from the repo root: python3 tools/hall_italy/make_views93.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/hall_italy"

# site: (what it is, look-at x/z, eye view from x/z, high view from x/z)
VIEWS = {
    "A": ("the lighthouse terrace beside the Guardian's statue (plinth 488,-1158)", (484, -1152), (516, -1128), (452, -1105)),
    "B": ("Piazza del Limone (the fountain 464,-794)", (464, -794), (430, -790), (502, -832)),
    "C": ("the harbour front (benches and lemon trees between the piers and the town)", (285, -655), (236, -692), (334, -606)),
    "D": ("the church square (Santa Marina 380..433, the sailing club)", (408, -962), (446, -950), (458, -1004)),
    "E": ("Prato dei Fiori, the coastal meadow between the church and the lighthouse", (520, -1080), (468, -1042), (566, -1132)),
}
TEMPLATE = '''-- view93_{id}{n}: {what} - {kind}. Moves ONLY the editor camera (Studio EDIT mode); changes nothing.
local cam = workspace.CurrentCamera
local function groundY(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	return h and h.Position.Y or 0
end
cam.FieldOfView = 70
local eye = Vector3.new({ex}, groundY({ex}, {ez}) + {up}, {ez})
local at = Vector3.new({tx}, groundY({tx}, {tz}) + {tup}, {tz})
cam.CFrame = CFrame.lookAt(eye, at)
print(string.format("QQ VIEW93 {id}{n}: camera at (%.0f, %.1f, %.0f) looking at (%.0f, %.1f, %.0f)", eye.X, eye.Y, eye.Z, at.X, at.Y, at.Z))
'''
n = 0
for sid, (what, (tx, tz), eye, high) in VIEWS.items():
    for k, (kind, (ex, ez), up, tup) in enumerate([("standing, at eye height, the way a player walks up", eye, 5.5, 4.0), ("high three-quarter view", high, 24.0, 2.0)], start=1):
        text = TEMPLATE.format(id=sid, n=k, what=what, kind=kind, ex=ex, ez=ez, up=up, tx=tx, tz=tz, tup=tup)
        (OUT / f"view93_{sid}{k}.lua").write_text(text, encoding="utf-8")
        n += 1
print(f"{n} view scripts written to {OUT}")
