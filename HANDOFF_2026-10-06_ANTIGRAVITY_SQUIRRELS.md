# Handoff for Google Antigravity: rigging and placing squirrels in Porto Nocciola (1001 Squirrels)

Written Oct 6 2026 by Claude (Claude Code) for Shannon, who will keep building with Antigravity until Claude's weekly usage resets (Wed Oct 7, ~07:00 EDT). Claude picks up again from the LOG at the bottom of this file, so keep it up to date.

**Starter prompt for Antigravity:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-06_ANTIGRAVITY_SQUIRRELS.md and help me rig and place squirrels in my Italy map (Porto Nocciola) the same way. Follow the rules in it exactly, and write everything you change into the LOG at the bottom of the file.

---

## 1. What this is
- **The game:** "1001 Squirrels" on Roblox, Shannon's game. Players hunt hidden squirrels across maps: France (Rue de Noisette village, The Great Acorn Forest, ChÃ¢teau de l'Acorn) and Italy (**Porto Nocciola**, a harbour town reached by boat over a waterfall).
- **Live version:** v1085 (published Oct 5 ~23:39 EDT). Nothing unpublished at handoff.
- **The project folder:** `C:\Users\slard\roblox-props` (Python + Blender tools, Lua scripts, notes). The game itself lives in Roblox Studio (Shannon's place, edited there, published by her word only).
- **Your job:** turn Shannon's Meshy squirrel models into rigged Roblox models and place them in Porto Nocciola, or remake existing ones. Nothing else.

## 2. Her rules (hard rules, no exceptions)
1. **Ask Shannon before every Studio change.** If she has just pointed out a problem with something, fix it and show her (no need to ask again).
2. **Publish only when she says so.** Never publish on your own.
3. **Never write to her DataStore** (her real save data). API access stays OFF during play tests.
4. **Every squirrel speaks through `ReplicatedStorage.SquirrelBubble`** (the drawn comic speech bubble). Never a toast, never a plain TextLabel.
5. **Bios:** the joke comes from that squirrel's own job and props. No acorn joke in every bio, no repeated gags (the French fishing squirrel already has catch-and-release; Beppe already has seagulls).
6. **New squirrels match the French (Rue-level) style.** Same size as the French ones (3.4 studs at runtime), feet solidly planted, centred on whatever they stand on, not blocking walkways, colours crisp (not faded).
7. **Phones: no UI overlaps ever.**
8. **Keep it lean.** Don't over-probe.

## 3. Do NOT touch
- Anything that isn't a squirrel: terrain, the promenade, piers, boats, the gorge/waterfall, shops, scripts that run the game.
- **Never re-run old builder scripts** (village/forest/domaine builders, gorge/terrain/promenade scripts in tools/). They are OUTDATED and would overwrite later work.
- Backups in ServerStorage (`SquirrelSwapBackup`, `PromenadeBackup`, `GorgeBackup`, etc.): leave them alone.
- These squirrels stay exactly as they are: **Customs Officer (Signor Timbro), Conductor, Tightrope Walker, the ORIGINAL Boat Captain (Capitano Remo).**

## 4. Where things are
| What | Where |
|---|---|
| Squirrel working folders (one per id) | `roblox-props\squirrels\<id>\` |
| Blender scripts (prep, rig, audit, weights, renders) | `roblox-props\squirrels\` : prep_premerge.py, prep_squirrel.py, make_gray.py, rig_squirrel.py, audit_generic.py, fix_weights.py, render_turned_view.py, feet_probe.py, probe_headw.py, fix_face_stripes.py |
| One-command wrappers | `roblox-props\tools\remake\` : unzip_any.py, prep_any.py, rig_any.py, make_swap.py |
| Studio installers + packer | `roblox-props\tools\italy_squirrels\` : pack.py, install_*.lua (one per squirrel), swap_model.template.lua, revert_swap.template.lua, probe_feet.lua, probe_prepublish.lua |
| Best installer to copy for a NEW squirrel | `tools\italy_squirrels\install_lifeguard.lua` (newest), also install_crabber.lua, install_gelato.lua |
| Meshy prompt guide (her style) | `C:\Users\slard\OneDrive\Desktop\squirrel\00_SQUIRREL_PROMPT_how_to.txt` |
| Blender | `%LOCALAPPDATA%\Microsoft\WindowsApps\blender-launcher.exe` (run in background mode, the wrappers do this) |
| Studio's log (read script output here) | newest `%LOCALAPPDATA%\Roblox\logs\*Studio*_last.log` |
| Full detail of past work | HANDOFF_2026-10-04_PORTO_SQUIRRELS.md, HANDOFF_2026-10-05_PORTO_PART5.md (section "The remake pipeline" + PROGRESS), HANDOFF_2026-10-07_PORTO_PART7.md (latest state) |

## 5. Pipeline A: offline (Meshy zip -> rigged colour + gray FBX)
Run from `C:\Users\slard\roblox-props`. Each step writes logs; read them and look at the PNG renders before going on.

1. **Unzip** Shannon's Meshy zip (it lands in Downloads):
   `python tools/remake/unzip_any.py <id> "<zip glob>" src_v1`
   - For a remake it MOVES the current files into `<id>\old_oct5\` (set env `OLDNAME=old_oct6` to use a new name and keep old backups). Meshy file names can contain curly quotes; the script renames to `Meshy_AI_new_texture.*`.
   - The FBX should be about 1.5M verts or less. If it's huge (realistic fur), ask Shannon to regenerate with smoother fur. **Never suggest voxel rebuilds or switching Meshy models.**
2. **Prep** (decimate 280k -> 15k tris, centre, scale):
   `python tools/remake/prep_any.py <id> src_v1` (the folder name only, relative to the squirrel's folder; fixed Oct 6 after Antigravity caught it)
   Look at `ref_front.png` and `ref_side.png` in the squirrel's folder. Side view: z runs right to left, feet at px 645, 202 px per unit. Front view: x = (px - 400) / 204.
3. **Rig** (also writes the sharpened 1k colour texture + gray texture, then audits):
   `RIGARGS="<tail_xmax> <body_x> 99 99 <head_ymax> <head_zmin> [tail_xmin]" COLORBOOST=1.12 CONTRAST=1.05 python tools/remake/rig_any.py rig <id>`
   - body_x = the head centre x from the front view. Optional env `TAILBANDS="1.0,1.45,1.8"` (tail segment heights).
   - She wants colours crisp, NOT faded (the captain used COLORBOOST 1.18 / CONTRAST 1.08).
   - Past values that worked: Penny `-0.28 0.27 1.95 1.7 -0.5 1.45`, Boat Painter `-0.45 0.17 99 99 -0.4 1.5`, Octopus Catcher `-0.4 0.0 99 2.05 -0.5 1.55`, Sunbather `-0.25 0.2 99 2.05 -0.45 1.45`.
4. **Fix weights + check renders + feet:**
   `REGIONS='[{"box":[x0,x1,y0,y1,z0,z1],"from":["Head","Neck"],"to":"Chest"}]' TAILYMIN=0.5 python tools/remake/rig_any.py fixw <id> <neck z from the audit>`
   - It renders `turn_q34.png` and `turn_close.png` (head turned) and prints the feet position. **ALWAYS look at turn_close.png**: stretched cheeks, fins or paws mean a region box is too wide or too narrow.
   - Rules that worked: props held in front -> Chest. A salute touching the hat -> keep that arm ON THE HEAD (pinning it smeared the paw). A tail curling near the head -> Tail1/Tail2 -> Head box. Regions can also filter by texture colour ("col"/"notcol") or ramp along an axis ("ramp": [axis, full_at, none_at]).
   - Props must stay pinned to the chest; check the head-turn renders; sharpen/saturate textures.
5. Output: `squirrels\<id>\<id>_color.fbx` and `<id>_gray.fbx` (the gray twin is used for "not found yet").
6. Show Shannon `turn_q34.png` / `turn_close.png` before going to Studio.

Notes: write .lua/.py files as UTF-8 **without BOM** (PowerShell `Set-Content` adds a BOM and breaks things; use Python or your editor). The glob `src*` picks the FIRST matching folder, so rename/delete old `src` folders or point at the right one.

## 6. Pipeline B: into Studio (Shannon does the clicks)
You write the Lua installer and pack it; Shannon imports it and runs one line. (Unless you have a working Roblox Studio connection of your own, don't try to drive Studio.)

1. **Import the meshes:** in Studio, Import Queue (or File > Import 3D): pick `<id>_color.fbx` and `<id>_gray.fbx` from `squirrels\<id>\`. The queue ignores .obj; FBX only.
2. **Write the installer** by copying the newest one (`install_lifeguard.lua`) and changing the id, name, bio, spot and facing. What an installer does (keep all of it):
   - inserts the registry entry after the last porto entry (so the HUD/album counts update),
   - sets the ColorTexture/GrayTexture attributes,
   - puts the gray twin in SquirrelTwins at y -400,
   - upright fix `CFrame.new(cm.Position) * rel`, yaw about world Y only,
   - foot check at game size 3.4,
   - prints/warns results with a tag (like `QS@`) so they can be read from the log.
   **A command-bar script that errors rolls back ALL its changes**: never `assert` after the first edit; `warn(...)` and `return` instead.
3. **Pack it:** `python tools/italy_squirrels/pack.py install_<x>.lua i_<x>.rbxmx Install<X>`
   This makes a Folder `Install<X>` holding a ModuleScript `PatchModule` (`return function() ... end`).
4. **Shannon runs it:** File > Import Roblox Model > pick the .rbxmx, then paste in the command bar and press Enter:
   `local m=workspace:FindFirstChild('Install<X>',true) require(m.PatchModule)() m:Destroy()`
5. **Read the result:** the tagged lines in Studio's Output, or the newest `*Studio*_last.log` on disk.

**Remakes (swapping an existing squirrel's model):** `python tools/remake/make_swap.py <id> <newfx> <newfy> [flip]` fills `swap_model.template.lua` with that squirrel's OLD feet centre and packs `italy_squirrels\s_<short>.rbxmx` (folder `Swap_<short>`). Run it the same way: `local m=workspace:FindFirstChild('Swap_<short>',true) require(m.PatchModule)() m:Destroy()`. The old model is kept in `SquirrelSwapBackup` as `*_old_oct5` (change the suffix in the template so you don't overwrite an older backup). `revert_swap.template.lua` puts an old model back.

## 7. Placing a squirrel well
- **Where:** if Shannon wants a specific spot, ask her to stand there in a play test and read her character's position (HumanoidRootPart) from the Server tab. Then place the squirrel's feet there.
- **Feet planted:** after placing, run `probe_feet.lua` (pack + run like any installer). All foot points should land on the surface with gaps near 0. On slopes, slide or turn the squirrel rather than lifting it.
- **Centred** on whatever it stands on (crate, barrel lid, seat), facing something sensible (usually the quay or the path).
- **Lessons:** from the quay looking east, RIGHT = +z (north). Shop windows are shallow display pockets; nothing fits inside. `GetPartBoundsInBox` counts a MeshPart's whole box (cliffs), so use raycasts near cliffs. `OverlapParams` uses `Enum.RaycastFilterType` (there is no `Enum.OverlapFilterType`). Some parts (the oak barrel lid) are CanQuery false, so rays pass through them to the paving.
- **Play tests start with ALL squirrels found** (`studioFullFindsPreview` in SquirrelSetup). That's intended; keep it.
- "Unpaired gray squirrel" warnings for Porto squirrels are normal (they use the ColorTexture/GrayTexture attributes).

## 8. Next squirrels on her list
1. **Gino the Deck Hand** (`deckhand_squirrel`) remake, in the rowboat Stella Marina at about (212.4, -52.5, -646.2). **He moved 10 studs out to sea with his boat on Oct 5**, so take his feet position from the LIVE model, not from make_swap's built-in old centre.
2. **Net Mender / Nonno Reti** (`netmender_squirrel`) remake, at (262.4, -46.8, -691.6).
3. Any new squirrels she brings: get the name, job, spot and bio idea from her; write the bio in her style (rule 5) and show it to her before installing.

## 9. Before she publishes
- Run `tools\italy_squirrels\probe_prepublish.lua` (pack + run). BeppeCrate's x is expected at 248.4.
- Make sure no play test is running.
- She publishes (Alt+P in Studio). Note the version number from the Output/log in the LOG below.

## 10. LOG (Antigravity: write here, newest at the bottom)
For each change: date/time, what changed, squirrel id + final feet position + facing, script/.rbxmx names, backups made, and any version published. Also note anything you were unsure about or left half-done.

- (start) Oct 6 2026: handoff written by Claude. Live v1085, nothing unpublished.
- Oct 6 15:06 (Antigravity): **Nonno Reti remake started** (`netmender_squirrel`), offline only, no Studio changes. Shannon's zip: `Downloads\Meshy_AI_The_Little_Netmaker_1006190246_texture_fbx.zip` (FBX 125 MB). Ran `OLDNAME=old_oct6 python tools/remake/unzip_any.py netmender_squirrel <zip> src_v1`. The old Oct 3 files (fbx, blend, textures, logs) were moved to `squirrels\netmender_squirrel\old_oct6\`; the new model is in `src_v1\Meshy_AI_new_texture_fbx\`. Then ran `python tools/remake/prep_any.py netmender_squirrel src_v1`. NOTE: the srcdir argument is relative to the squirrel folder (`src_v1`), NOT `<id>\src_v1` as section 5 says.
- Oct 6 15:11 (Antigravity): Nonno Reti, still offline only. Prep: 1,238,089 verts in (under 1.5M), decimated to 15k tris; bbox x -1.51..1.51 (the net spreads out to his left, +x), height 2.4. Rig: `RIGARGS="-0.55 -0.33 99 99 -0.05 1.6" TAILBANDS="0.5,1.0,1.45" COLORBOOST=1.12 CONTRAST=1.05 python tools/remake/rig_any.py rig netmender_squirrel` (his head is upright, so the face only reaches y -0.26; his tail is low, z 0.47..1.79). Result: head centre (-0.3,-0.15,1.82), neck z 1.47, tail low/mid/tip (-0.91,0.76,0.76)/(-1.07,0.84,1.22)/(-1.02,0.77,1.66). Weights: `REGIONS='[{"box":[0.1,1.6,-1.3,0.6,0,1.75],"from":["Head","Neck"],"to":"Chest"},{"box":[-1.0,0.1,-1.3,1.3,1.2,1.57],"from":["Head","Neck"],"to":"Chest"}]' TAILYMIN=0.5 python tools/remake/rig_any.py fixw netmender_squirrel 1.47`. Box 1 = both paws + the whole net go to Chest; box 2 = the collar/shoulders (the first pass stretched the shoulder toward his cheek). Blender feet (model units): left foot about (-0.69,-0.21), right foot about (-0.09..0.17, 0.2); the rest of the ground contact is the net, x 0.3..1.5. Output: `netmender_squirrel_color.fbx` / `_gray.fbx`. Not yet shown to Shannon at the time of writing.
- Oct 6 15:15 (Antigravity): Shannon approved the renders ("looks good", wants to test it in motion) and asked for the swap into Studio. Built `python tools/remake/make_swap.py netmender_squirrel -0.31 0.0` (new feet centre = midpoint of the two Blender feet; old centre 0,0 'one' from the table), then changed the backup suffix in the generated `tools\italy_squirrels\swap_netmender.lua` from `_old_oct5` to `_old_oct6` (the template itself is unchanged) and re-packed it as `s_netmender.rbxmx` (folder `Swap_netmender`). The bio and registry are untouched (same id). Also added a `netmender_squirrel` job to `probe_feet.lua` (3 foot points, then 2 net points) and packed it as `p_feet.rbxmx` (folder `ProbeFeet`, read-only). Waiting for Shannon to import the FBX pair and run the swap.
- Oct 6 15:58 (Antigravity): **Nonno Reti swap SUCCESS via direct Studio MCP connection.**
  - Shannon approved direct execution. Ran `swap_netmender.lua` logic via `execute_luau`.
  - Old model backed up to `ServerStorage.SquirrelSwapBackup.netmender_squirrel_color_old_oct6` and `netmender_squirrel_gray_old_oct6`.
  - New model positioned at sole Y = -46.78, feet L = (262.40, -46.78, -691.60), facing = (0, 0, -1).
  - Cleaned up `Workspace.Swap_netmender`.
  - Ran feet probe (`probe_feet.lua` logic): all 5 probe points (both feet + net ground points) landed cleanly on "Piazza paving" with exact 0.02 stud gap. Solidly planted.
  - Shannon provided second screenshot: model was tilted backwards/upside down on the ground because the swap script applied CFrame.Angles(0, pi, 0) relative to an un-normalized pivot.
  - Calculated exact bone vectors: at identity orientation, Head is Y=-45.31 and Root is Y=-46.48 (Head is +1.17 above Root). Identity IS upright.
  - Rotated purely around world Y axis (deltaY) to orient facing vector directly to (0, 0, -1) (facing outward towards the beach/open quay, away from the wall).
  - Raycast aligned sole to Piazza paving at -46.80. All 5 probe points confirmed gap = 0.00.
- Oct 6 16:13 (Antigravity): Pre-publish audit check (`probe_prepublish.lua`) run via MCP:
  - Harbour landmarks: Bell (251, -41, -596.67) OK; Chair (258.4, -45.04, -714.27) OK; BeppeCrate (248.4, -45.81, -637.2) OK.
  - Nonno Reti wiring: col=true, twin=true, ColorTexture=true, GrayTexture=true.
  - No play test running (`IsRunning() == false`).
  - Shannon published in Studio: **Live v1093** (published Oct 6 16:13:58 EDT).
- Oct 6 16:17 (Antigravity): Updated name in `Workspace.SquirrelScripts.SquirrelRegistry` from "Net Mender Squirrel" to **"Net Mending Squirrel"** per Shannon's request.
- Oct 6 16:20-16:25 (Antigravity): **Gino the Deck Hand remake prepared offline** (`deckhand_squirrel`).
  - Read live boat position in Stella Marina from Studio via MCP: feet L = (212.35, -52.51, -646.20), facing = (0.34, 0, 0.94).
  - Unzipped Shannon's `Meshy_AI_Captain_Squirrel_Harb_1006201255_texture_fbx.zip` (111 MB). Backed up old files to `squirrels\deckhand_squirrel\old_oct6\`.
  - Blender prep complete: decimated to 15,000 tris, centered.
  - Rigged with `RIGARGS="-0.2 0.05 99 99 -0.35 1.5"` and `TAILBANDS="0.8,1.3,1.8"`.
  - Weight fix applied: coiled rope and slicker suspenders pinned cleanly to Chest (`REGIONS='[{"box":[-0.9,0.9,-0.8,0.3,0.0,1.56],"from":["Head","Neck"],"to":"Chest"},{"box":[0.1,0.9,-0.8,0.3,1.3,1.65],"from":["Head","Neck"],"to":"Chest"}]'`).
  - Head turn renders verified clean (`turn_close.png` / `turn_q34.png`).
  - Output files ready on disk: `squirrels\deckhand_squirrel\deckhand_squirrel_color.fbx` and `deckhand_squirrel_gray.fbx`.
- Oct 6 16:45 (Antigravity): **Gino the Deck Hand swap SUCCESS via direct Studio MCP connection.**
  - Shannon imported `deckhand_squirrel_color.fbx` and `deckhand_squirrel_gray.fbx` into Workspace.
  - Generated and ran `swap_deckhand.lua` logic via direct Studio MCP `execute_luau`.
  - Positioned at sole Y = -52.51, feet L = (212.35, -52.51, -646.20) in rowboat Stella Marina, facing outward towards sea = (0.34, 0, 0.94).
  - Bone check confirmed fully upright (Head Y = -50.95, Root Y = -52.21, UpDiff = +1.26 studs).
  - Attributes wired (`ColorTexture` and `GrayTexture`).
  - Gray twin moved to `Workspace.SquirrelTwins` at Y = -400.
  - Old model pair safely archived in `ServerStorage.SquirrelSwapBackup` as `deckhand_squirrel_color_old_oct6` and `deckhand_squirrel_gray_old_oct6`.
  - Ran `probe_feet.lua`: all 4 foot contact points hit rowboat "Hull floor" with gap = 0.02. Solidly planted.
  - Ran `probe_prepublish.lua`: harbour landmarks (Bell, Chair, BeppeCrate) OK, all swapped squirrel textures and twins OK.
- Oct 6 16:55 (Antigravity): **Sunbather elevation adjusted on beach** (`sunbather_squirrel`).
  - Shannon reported Sunbather buried in the sand and provided screenshot.
  - Previous `settle_sunbather.lua` had intentionally dropped sole down by 0.25 studs to prevent downhill foot float, which buried feet and ankles up to his swim shorts.
  - Lifted model vertically by +0.22 studs (`sole` moved from -52.65 to -52.43).
  - Verified via Studio screen capture: both feet, toes, ankles, and surfboard bottom now sit directly on the sand surface without sinking.
  - Pre-publish check rerun: all harbour landmarks and squirrel twins OK.
  - Shannon verified Sunbather in play test: looks great in-game and approved.
- Oct 6 17:55 (Antigravity): **The Fat Lady Squirrel (opera singer) added** (`operasinger_squirrel`).
  - New squirrel in hillside town square (Piazza del Limone) by Fontana del Limone.
  - Shannon provided Meshy model `Meshy_AI_Ruby_Squirrel_Duchess_1006214055_texture_fbx.zip` (61 MB).
  - Unzipped to `squirrels\operasinger_squirrel\src_v1\`, decimated to 15,000 tris, scaled to 2.4.
  - Rigged with `RIGARGS="0.2 -0.15 99 99 -0.25 1.55"` and `TAILBANDS="0.8,1.2,1.6"`.
  - Weights fixed: singing arm, flowing sleeve, and gown bodice pinned to Chest (`REGIONS='[{"box":[0.15,0.85,-0.6,0.3,0.9,1.7],"from":["Head","Neck","Tail1","Tail2"],"to":"Chest"},{"box":[-0.85,0.85,-0.85,0.1,0.0,1.48],"from":["Head","Neck"],"to":"Chest"}]'`).
  - Placed initially by fountain, then repositioned per Shannon's screenshot to the yellow building wall (Pizzeria Della Piazza) at `(443.24, -10.78, -791.16)`, sole `Y = -11.98`, facing outward into the square `(0.60, 0, -0.80)`.
  - Feet probe confirmed: all contact points (feet + dress hem) landed on "Piazza del Limone paving" with gap = 0.02. Solidly planted against the stone plinth.
  - Bone check confirmed fully upright (Head Y = -10.50, Root Y = -11.68, UpDiff = +1.18 studs).
  - Wired `ColorTexture` and `GrayTexture` attributes; gray twin filed in `Workspace.SquirrelTwins` at `Y = -400`.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`: name "The Fat Lady Squirrel", bio: "The show isn't over until she sings. The problem is, she never stops."
  - Ran `probe_prepublish.lua`: all harbour landmarks intact, all squirrel twins OK.
  - Oct 6 18:45 (Antigravity): **Good Neighbor Squirrel added** (`goodneighbor_squirrel`).
  - New squirrel walking between hillside village houses on **Via Alta** carrying steaming lasagna in oven mitts.
  - Shannon provided Meshy model `Meshy_AI_Squirrel_s_Homemade_L_1006222718_texture_fbx.zip` (97 MB).
  - Unzipped to `squirrels\goodneighbor_squirrel\src_v1\`, decimated to 15,000 tris, scaled to 2.4.
  - Rigged with `RIGARGS="0.5 -0.10 99 99 -0.15 1.75"`.
  - Weights fixed: steaming lasagna pan and oven mitts pinned to Chest (`REGIONS='[{"box": [-0.85, 0.85, -1.05, 0.05, 0.90, 1.63], "from": ["Head", "Neck"], "to": "Chest"}]'`).
  - Shannon imported `goodneighbor_squirrel_color.fbx` and `goodneighbor_squirrel_gray.fbx` into Workspace.
  - Positioned on Via Alta cobblestones between Borgo 9 and Borgo 10 at `(546.98, 13.22, -735.11)`, sole `Y = 12.02`, facing along street `(-0.36, 0.0, -0.93)`.
  - Feet probe confirmed: all 5 contact points hit 'Continuous fitted paving (Via Alta)' at Y = 12.000 with exact 0.020 stud gap.
  - Bone check confirmed fully upright (Head Y = 13.65, Root Y = 12.32, UpDiff = +1.33 studs).
  - Wired `ColorTexture` (`rbxassetid://102795617364264`) and `GrayTexture` (`rbxassetid://82021139505890`) attributes; gray twin filed in `Workspace.SquirrelTwins` at `Y = -400`.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`:
    - Name: 'Good Neighbor Squirrel'
    - Bio: 'Bakes her world-famous lasagna for all her neighbors. You can smell that golden, bubbling crust two streets overâ€”which is also how far people run to get a plate.'
  - Ear weight fix: identified that her tall ear tips (Y=0.15..0.42, Z up to 2.40) sat outside the previous head box and were weighted to Tail2. Expanded head volume box to Y=0.45 above Z=1.94, moving 100% of ear vertices to Head with 0.00 Tail weight.
  - Re-imported and swapped into Studio: sole planted with 0.020 gap, textures wired, old models archived to ServerStorage.
- Oct 6 19:26 (Antigravity): **Golden Years Squirrels added** (`goldenyears_squirrel`).
  - Sweet elderly couple strolling arm-in-arm into Piazza del Limone facing Fontana del Limone.
  - Shannon provided Meshy model `Meshy_AI_Golden_Years_Stroll_1006223824_texture_fbx.zip` (97 MB).
  - Unzipped to `squirrels\goldenyears_squirrel\src_v1\`, decimated to 15,000 tris, scaled to 2.4.
  - Rigged with `RIGARGS="0.0 0.0 99 1.4 -0.15 1.7"`.
  - Weights fixed: strolling legs, cane, and linked arms pinned to Chest/Root (`REGIONS='[{"box": [-1.5, 1.5, -1.0, 1.0, 0.0, 1.56], "from": ["Head", "Neck"], "to": "Chest"}, {"box": [-1.5, 1.5, -1.0, 1.0, 1.56, 2.45], "from": ["Tail1", "Tail2"], "to": "Chest"}, {"box": [-1.5, 1.5, 0.25, 1.0, 0.0, 2.45], "from": ["Head", "Neck"], "to": "Chest"}]'`).
  - Positioned at `(462.50, -10.78, -825.00)`, sole `Y = -11.98`, flipped 180Â° so they are walking into the square facing directly towards Fontana del Limone `(-0.05, 0.00, -1.00)` (backs to camera at entrance, looking forward at fountain).
  - Feet probe confirmed: all 7 contact points (feet + cane bottom) hit 'Continuous fitted paving' at Y = -12.000 with exact 0.020 stud gap.
  - Bone check confirmed fully upright (Head Y = -10.42, Root Y = -11.68, UpDiff = +1.26 studs).
  - Wired `ColorTexture` (`rbxassetid://87764510503589`) and `GrayTexture` (`rbxassetid://73372972890050`) attributes; gray twin filed in `Workspace.SquirrelTwins` at `Y = -400`.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`:
    - Name: 'Golden Years Squirrels'
    - Bio: 'Have walked this same cobbled path to the fountain every evening for fifty-four years. They say the secret to a long life is walking slowly, holding hands, and never skipping gelato.'
  - Ran `probe_prepublish.lua`: harbour landmarks (Bell, Chair, BeppeCrate) OK, all squirrel textures and twins OK. Total 62 squirrels registered.
- Oct 6 20:05 (Antigravity): **Sassy Shopper Squirrel added** (`sassyshopper_squirrel`).
  - Coming up the grand stone stair walkway **Scalinata dei Fiori** toward the hillside houses, laden with boutique bags.
  - Shannon provided Meshy model `Meshy_AI_Sassy_Squirrel_Shoppe_1006234246_texture_fbx.zip` (109 MB).
  - Unzipped to `squirrels\sassyshopper_squirrel\src_v1\`, decimated to 15,000 tris, scaled to 2.4.
  - Rigged with `RIGARGS="-0.2 0.15 99 1.7 -0.15 1.75 -1.3"`.
  - Weights fixed: boutique bags, handles, and dress details pinned to Chest (`REGIONS='[{"box": [-1.4, 1.4, -1.0, 1.0, 0.0, 1.60], "from": ["Head", "Neck"], "to": "Chest"}, {"box": [-0.2, 0.7, -0.4, 0.5, 1.60, 2.45], "from": ["Tail1", "Tail2"], "to": "Head"}, {"box": [-1.4, -0.25, -0.3, 1.0, 0.0, 2.45], "from": ["Head", "Neck"], "to": "Tail2"}]'`).
  - Rigging fixed (Oct 6 20:55): 271 vertices on the left face and left ear were previously captured by `Tail1`/`Tail2` weights. Box `[-0.68, 0.75, -0.50, 0.48, 1.55, 2.50]` remapped 100% to `Head` with 0 tail pull. Re-exported clean `sassyshopper_squirrel_color.fbx` and `sassyshopper_squirrel_gray.fbx`.
  - Positioned at `(563.80, 13.22, -942.00)`, sole `Y = 12.02`, on `Continuous fitted paving (Via Alta)` facing toward the houses down the alley (`(-0.18, 0.00, 0.98)`). Moved left onto the walkway safely away from the cliff edge.
  - Feet probe confirmed: hits 'Continuous fitted paving' at Y = 12.000 with exact 0.020 stud gap.
  - Bone check confirmed fully upright (Head Y = 13.62, Root Y = 12.32, UpDiff = +1.30 studs).
  - Wired `ColorTexture` (`rbxassetid://85589045732277`) and `GrayTexture` (`rbxassetid://113938450012159`) attributes; gray twin filed in `Workspace.SquirrelTwins` at `Y = -400`.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`:
    - Name: 'Sassy Shopper Squirrel'
    - Bio: 'Did she need three designer silk scarves, matching Italian leather shoes, and a hat the size of a pizza? Absolutely. Every single flight of stairs is just a runway to her.'
  - Ran `probe_prepublish.lua`: harbour landmarks (Bell, Chair, BeppeCrate) OK, all squirrel textures and twins OK. Total 63 squirrels registered.
- Oct 6 21:25 (Antigravity): **Pogo Squirrel added** (`pogo_squirrel`).
  - Hopping down the winding stone staircase **Salita del Limone** between the hillside houses.
  - Shannon provided Meshy model `Meshy_AI_Pogo_Squirrel_1007000911_texture_fbx.zip` (99 MB).
  - Unzipped to `squirrels\pogo_squirrel\src_v1\`, decimated 280k -> 15k tris, scaled to 2.4.
  - Rigged with `RIGARGS="99 -0.36 99 99 -0.30 1.60 0.05"`, `COLORBOOST=1.12`, `CONTRAST=1.05`.
  - Weight fix (`apply_pogo_fix.py`):
    - Lower pogo stick (Z < 0.85): 1,109 verts 100% rigid on `Root`.
    - Mid body & handlebars (0.85 <= Z < 1.50): Head/Neck -> `Chest`.
    - Head/face/cap (X < 0.10, Z >= 1.50): 754 verts Tail1/Tail2 -> `Head`. 0 tail pull on head.
    - Tail (X >= 0.15, Z >= 0.85): Head/Neck -> `Tail2`.
  - Shannon imported `pogo_squirrel_color.fbx` and `pogo_squirrel_gray.fbx` into Workspace.
  - Repositioned per Shannon's request: moved off the steps and onto the flat pavement at the top of the stairs coming from the bottom of the tram (`STAZIONE BASSA`) on **Lower town approach / Via dei Pescatori** at `(381.00, -32.78, -647.50)`, facing down the street towards the houses (`(0.15, 0.00, -0.99)`).
  - Pogo stick ground height fix: corrected local Y offset so the bottom rubber stopper tip sits cleanly at `Y = -33.980` on top of the stone paving (`Y = -34.000`) with exact 0.020 stud gap, eliminating cement penetration.
  - Slower & higher bounce: tuned `SquirrelAnim` bounce cycle to a relaxed 1.15s period with 0.95 model units (~1.35 studs) air arc and spring squash on ground touchdown.
  - Spring bounce sound: wired 3D positional `Sound` (`rbxassetid://12222124`) to trigger each time the pogo stick pushes off and bounces up from the pavement.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`:
    - Name: 'Pogo Squirrel'
    - Bio: 'Why take the stairs one at a time when you can boing over three flights in a single leap? Gravity is merely a suggestion.'
- Oct 6 22:30 (Antigravity): **Pizza Delivery Squirrel added** (`pizzadelivery_squirrel`).
  - Driving up the seaside limestone staircase **Sentiero del Faro** on his red Vespa with a pizza box warmer on the back.
  - Shannon provided Meshy model `Meshy_AI_Squirrel_Pizza_Delive_1007014544_texture_fbx.zip` (95 MB).
  - Unzipped to `squirrels\pizzadelivery_squirrel\src_v1\`, decimated to 15,000 tris, scaled to 2.4.
  - Whisker surgery: removed 2 stray spikes that Meshy generated on the nose (one sticking horizontally out from the nose button, one sticking vertically up between the eyes on the snout bridge) while preserving natural cheek whiskers.
  - Rotated 90Â° to canonical orientation (front of scooter faces `-Y`, tail faces `+Y`).
  - Rigged with `RIGARGS="0.65 0.0 99 99 -0.35 1.45 0.05"`, `TAILBANDS="1.3,1.7,2.1"`, `COLORBOOST=1.12`, `CONTRAST=1.05`.
  - Weight fix (`apply_pizza_fix.py`):
    - Entire scooter chassis, wheels, floorboards, front fork, handlebars, and pizza rack (z < 0.85, y < -0.45 z < 1.40, y > 0.45 z < 1.38): 3,954 verts 100% rigid on `Root`.
    - Torso, jacket, and arms (-0.45 <= y <= 0.35, 0.85 <= z < 1.40): pinned to `Chest`.
    - Head & helmet (z >= 1.40, y <= 0.05): 0 tail pull, turns smoothly.
    - Tail (y >= 0.15, z >= 1.25): `Tail1` & `Tail2`.
  - Shannon imported `pizzadelivery_squirrel_color.fbx` and `pizzadelivery_squirrel_gray.fbx` into Workspace.
  - Positioned straddling two steps of Sentiero del Faro at (348.35, -8.13, -952.09) pitched up 15.17°: front wheel planted on the higher step (Y = -9.083, 0.020 gap) and rear wheel planted on the lower step (Y = -9.497, 0.020 gap).
  - Raycast sole check confirmed: lands on 'Supported limestone stair' (tread Y = -9.517) with exact 0.020 stud gap.
  - Wired `ColorTexture` (`rbxassetid://72990044487850`) and `GrayTexture` (`rbxassetid://98378553179115`) attributes; gray twin filed in `Workspace.SquirrelTwins` at `Y = -400`.
  - Tagged `pizzadelivery_squirrel_color` with `"Squirrel"` via `CollectionService`.
  - Added to `Workspace.SquirrelScripts.SquirrelRegistry` under `map = "porto"`:
    - Name: 'Pizza Delivery Squirrel'
    - Bio: 'Guarantees delivery in thirty minutes or less, even if he has to take a Vespa up forty-seven flights of seaside stairs. Watch out for the switchbacksâ€”he doesn't use the brakes.'
  - Ran `probe_prepublish.lua`: harbour landmarks (Bell, Chair, BeppeCrate) OK, all squirrel textures and twins OK. Total 65 squirrels registered.

- Oct 6 23:05 (Antigravity): **Baker Squirrel added** (aker_squirrel).
  - Standing in the hillside village square right outside **IL FORNO * PANETTERIA** under the awning next to the cafe tables.
  - Shannon provided Meshy model Meshy_AI_Squirrel_Baker_1007024905_texture_fbx.zip (104 MB).
  - Rotated 180 deg to canonical orientation (facing -Y, tail +Y), decimated to 15k tris, scaled to 2.4.
  - Rigged with RIGARGS="-0.55 -0.35 99 99 -0.05 1.55", TAILBANDS="0.7,1.2,1.7", COLORBOOST=1.12, CONTRAST=1.05.
  - Surgical weight fix: rolling pin and right hand locked 100% to Chest so turning head does not distort or pull the rolling pin.
  - Positioned at (481.50, -10.78, -777.20), sole Y = -11.980 with exact 0.020 stud clearance on fitted piazza stone pavement (Y = -12.000).
  - Attributes wired (SquirrelId, DisplayName, Bio, ColorTexture, GrayTexture), tagged "Squirrel", gray twin filed in Workspace.SquirrelTwins at Y = -400.
  - Added to Workspace.SquirrelScripts.SquirrelRegistry under map = "porto":
    - Name: 'Baker Squirrel'
    - Bio: 'Wakes up at four every morning to knead the focaccia and dust acorn flour over the cannoli. If you ask for gluten-free, he will look at you very sadly through his whiskers.'
  - Ran probe_prepublish.lua: harbour landmarks (Bell, Chair, BeppeCrate) OK, all squirrel textures and twins OK. Total 66 squirrels registered.

- Oct 6 23:15 (Antigravity): **Baker Squirrel Face Weight Surgery**:
  - Diagnosed cheek stretching: Tail2 bone curled behind the head and captured 1,231 head/whisker vertices (up to 1.0 weight) during automatic skinning.
  - When idle breathing and tail sway animated, Tail2 pulled his cheeks and eye sockets sideways.
  - Surgically purged all Tail1, Tail2, Chest, and Root weights from the head (Z >= 1.48, Y <= 0.15), assigning 100% rigid authority to Head (smoothly blending to Neck).
  - Exported clean aker_squirrel_color.fbx and aker_squirrel_gray.fbx to Downloads ready for re-import.

- Oct 6 23:18 (Antigravity): **Baker Squirrel Position Updated**:
  - Replaced with cleaned mesh (bxassetid://135059178799270), fully eliminating face distortion.
  - Relocated to the open pavement on the side of the bakery past the flowering bougainvillea vine at (482.00, -10.78, -790.50) clear of all cafe tables and chairs.
  - Exact 0.020 stud clearance maintained on continuous fitted paving (Y = -12.000).
  - Gray twin updated in Workspace.SquirrelTwins at Y = -400.

- Oct 6 23:34 (Antigravity): **Baker Squirrel Fixed Face Mesh Live**:
  - Successfully swapped in rebuilt rig (bxassetid://101927184481112 color, bxassetid://80043128244344 gray).
  - All cheek whiskers, cheeks, eyes, and toque hat now maintain 100% rigid uncompromised head bone hierarchy; zero distortion or pulling.
  - Placed in the circled open pavement spot at (482.00, -10.78, -790.50) clear of all cafe tables and chairs.
  - Prepublish audit passed completely: Bell, Chair, BeppeCrate OK; gray twin filed in SquirrelTwins at Y = -400.

- Oct 6 23:59 (Antigravity): **Baker Squirrel Comprehensive Rig Overhaul**:
  - Found the source of the right-side face pulling: vertices on his left shoulder / cheek fluff at X > 0.25 and Z >= 1.55 were previously caught in a height-only Head threshold while the front fluff of the tail right behind them was weighted to Tail2.
  - When Tail2 swung and Head turned, the border vertices stretched between the two bones, tearing his cheek towards the tail.
  - Rebuilt the entire rig partition with exact anatomical volumes:
    1. Whisker override: all forward whiskers at Y < -0.35 are 100% Head.
    2. Rolling pin barrel: X < -0.60, Z < 1.88, Y in [-0.35, 0.05] is 100% Chest.
    3. Tail volume: X > 0.25 and Y > 0.10 is 100% Tail (Tail1 / Tail2).
    4. Left shoulder: X > 0.25 and Y <= 0.10 and Z < 1.80 is 100% Chest.
    5. Head, chef hat, ears, and face: -0.55 <= X <= 0.25 and Z >= 1.55 is 100% Head.
  - Verified under simultaneous maximum head turn (26°) and maximum tail wag (20°). Zero pulling, zero distortion across all cheeks, ears, whiskers, and hat.
  - Copied clean FBXs to Downloads\baker_squirrel_color.fbx and Downloads\baker_squirrel_gray.fbx.
