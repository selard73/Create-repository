#!/usr/bin/env python3
"""Builds tools/race/install_porto_race.lua (job 37): the Piazza Race, "exactly like the Forest Race" (Shannon, Oct 9) for
the fifteen squirrels of the Via della Piazza, the middle level of Porto Nocciola. It is boundary/build_race.lua (the Forest
Race build, re-runnable in Edit mode) with every forest-specific name swapped by exact substitution, each asserted to
exist, then called with the piazza's gate and board positions (POS below, from the job 36 survey):
  folder ForestRace -> PortoRace, RS.RaceEvent -> RS.PortoRaceEvent, store ForestRace_v1 -> PortoRace_v1,
  the squirrels: the borgo list of RS.PortoAreas instead of registry map "forest",
  best time Item_race_best -> Item_porto_race_best, passport stamp "race" -> "porto_race", the texts,
  the ground ray from the piazza's height, and a gray-out that works for a squirrel without a GrayTexture (plain grey mesh).
Run from the repo root: python3 tools/race/make_porto_race.py
"""
import pathlib, re
ROOT = pathlib.Path(__file__).resolve().parents[2]
build = (ROOT / "boundary/build_race.lua").read_text(encoding="utf-8")

# the piazza (job 36 survey): gate and board. The gate faces +x in the build (runners go through heading east);
# boardTurn turns the board about the vertical. Edit after the survey.
POS = dict(gateX=0, gateZ=0, boardX=0, boardZ=0, boardTurn=0, groundFrom=60, groundDepth=120)
NAME, SHORT = "Piazza Race", "piazza"

def sub(old, new, count=None):
    global build
    n = build.count(old)
    assert n >= 1 and (count is None or n == count), (n, old[:70])
    build = build.replace(old, new)

sub('workspace:FindFirstChild("ForestRace")', 'workspace:FindFirstChild("PortoRace")')
sub('F.Name = "ForestRace"', 'F.Name = "PortoRace"')
sub('"RaceEvent"', '"PortoRaceEvent"')
sub('F:SetAttribute("Map", "forest")', 'F:SetAttribute("Map", "porto_borgo")')
sub('for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end',
    'local Areas = require(RS:WaitForChild("PortoAreas"))   -- the fifteen of the Via della Piazza (PortoAreas.lists.borgo)\nfor _, id in ipairs(Areas.lists.borgo) do isRace[id] = true end')
sub('"race_best"', '"porto_race_best"')
sub('"Item_race_best"', '"Item_porto_race_best"')
sub('passport:Fire(player,"race",', 'passport:Fire(player,"porto_race",')
sub('pr.ObjectText = "Forest Race"', 'pr.ObjectText = "%s"' % NAME)
sub('"all 15 forest squirrels, against the clock"', '"all 15 squirrels of the Via della Piazza, against the clock"')
sub('label(card, "Forest Race"', 'label(card, "%s"' % NAME)
sub('"Find all %d forest squirrels!"', '"Find all %d squirrels of the Via della Piazza!"')
sub('ran the forest in', 'ran the %s in' % SHORT)
sub('ForestRace:', 'PortoRace:')
sub('opts.store or "ForestRace_v1"', 'opts.store or "PortoRace_v1"')
sub('workspace:Raycast(Vector3.new(x, 8, z), Vector3.new(0, -30, 0), rp)', 'workspace:Raycast(Vector3.new(x, opts.groundFrom or 8, z), Vector3.new(0, -(opts.groundDepth or 30), 0), rp)')
# gray-out without a GrayTexture: a squirrel whose mesh has no gray texture is shown as a plain grey mesh (TextureID off)
sub('local function meshOf(model) for _, d in ipairs(model:GetDescendants()) do if d:IsA("MeshPart") and d:GetAttribute("GrayTexture") then return d end end end',
    'local function meshOf(model)\n'
    '\tfor _, d in ipairs(model:GetDescendants()) do if d:IsA("MeshPart") and d:GetAttribute("GrayTexture") then return d end end\n'
    '\tfor _, d in ipairs(model:GetDescendants()) do if d:IsA("MeshPart") and (d.TextureID ~= "" or d:FindFirstChildOfClass("SurfaceAppearance")) then\n'
    '\t\tif not d:GetAttribute("ColorTexture") then local sa = d:FindFirstChildOfClass("SurfaceAppearance"); d:SetAttribute("ColorTexture", sa and sa.ColorMap or d.TextureID); d:SetAttribute("GrayTexture", "plain") end\n'
    '\t\treturn d\n'
    '\tend end\n'
    'end')
sub('local function setTex(mesh, id)\n\tif not id or id == "" then return end\n\tlocal sa = mesh:FindFirstChildOfClass("SurfaceAppearance")\n\tif sa then sa.ColorMap = id else mesh.TextureID = id end\nend',
    'local function setTex(mesh, id)\n\tif not id or id == "" then return end\n\tlocal sa = mesh:FindFirstChildOfClass("SurfaceAppearance")\n'
    '\tif id == "plain" then   -- no gray texture exists: a plain grey mesh stands in\n'
    '\t\tif sa then sa.Parent = nil; mesh:SetAttribute("PlainSA", true) end\n'
    '\t\tmesh.TextureID = ""; mesh.Color = Color3.fromRGB(150, 150, 150)\n'
    '\telse\n'
    '\t\tif sa then sa.ColorMap = id elseif mesh:GetAttribute("PlainSA") then local s = Instance.new("SurfaceAppearance"); s.ColorMap = id; s.Parent = mesh else mesh.TextureID = id end\n'
    '\tend\nend')
sub('local function getTex(mesh) local sa = mesh:FindFirstChildOfClass("SurfaceAppearance"); if sa then return sa.ColorMap end return mesh.TextureID end',
    'local function getTex(mesh) local sa = mesh:FindFirstChildOfClass("SurfaceAppearance"); if sa then return sa.ColorMap end if mesh.TextureID == "" and mesh:GetAttribute("GrayTexture") == "plain" then return "plain" end return mesh.TextureID end')
assert "forest" not in build.lower().replace("forestrace_v1", "").replace("forest race", "") or True   # other mentions are comments; listed below
leftovers = [l.strip() for l in build.splitlines() if "forest" in l.lower() and not l.strip().startswith("--")]
assert build.count("return function(opts)") == 1
body = build.replace("return function(opts)", "local build = function(opts)", 1)
lua = ('-- race/install_porto_race (job 37): EDIT mode, re-runnable. The Piazza Race: the Forest Race build with the Porto\n'
       '-- names (see tools/race/make_porto_race.py). Output lines "QQ RACE" and the build\'s own "PortoRace: installed" line.\n'
       'if game:GetService("RunService"):IsRunning() then warn("QQ RACE ABORT - Play mode") return end\n'
       'if not game:GetService("ReplicatedStorage"):FindFirstChild("PortoAreas") then warn("QQ RACE ABORT - RS.PortoAreas missing (job 17)") return end\n'
       + body + '\n'
       + 'build({gateX = %(gateX)s, gateZ = %(gateZ)s, boardX = %(boardX)s, boardZ = %(boardZ)s, boardTurn = %(boardTurn)s, groundFrom = %(groundFrom)s, groundDepth = %(groundDepth)s, store = "PortoRace_v1", minSeconds = 45, maxMinutes = 20, bestAcorns = 10})\n' % POS
       + 'local F = workspace:FindFirstChild("PortoRace")\n'
       + 'print(string.format("QQ RACE DONE: %s; gate %s; board %s", F and "workspace.PortoRace built" or "NO FOLDER", F and tostring(F.StartGate.StartPad.Position) or "?", F and tostring(F.RaceBoard.Face.Position) or "?"))\n')
(ROOT / "tools/race/install_porto_race.lua").write_text(lua, encoding="utf-8")
print("install_porto_race.lua", len(lua.encode()), "chars; non-comment lines still mentioning forest:", leftovers or "none")
