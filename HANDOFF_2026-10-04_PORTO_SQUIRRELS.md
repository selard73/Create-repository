# Handoff: Porto Nocciola squirrels (Oct 4 2026, ~06:40)

**Starter prompt for the new chat:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-04_PORTO_SQUIRRELS.md and continue adding Italian squirrels to 1001 Squirrels the same way. Ask me before every Studio edit (fixes of something I just flagged: just do them and show me).

## Where things stand
- **Live: v981** (published Oct 4 06:37). Nothing unpublished.
- Porto Nocciola has **5 squirrels**, registry total **49** (44 French + 5 porto):
  | id | name | spot |
  |---|---|---|
  | customs_squirrel | Signor Timbro | on the white quay steps (cliff side), steps now at x ~248.5 |
  | fishmonger_squirrel | Beppe the Fishmonger | centred on BeppeCrate, just north of the PESCE FRESCO stand's front-right post (crate centre 253.4, -637.2) |
  | deckhand_squirrel | Gino the Deck Hand | floor of rowboat "Stella Marina" between bow and middle seat (222.35, -646.2) |
  | netmender_squirrel | Nonno Reti | by the oak barrel / Bottega del Pescatore corner (262.4, -691.6), facing south |
  | gelato_squirrel | Giulia the Gelato Squirrel | paving in front of Gelateria al Limone, window RIGHT of the door (262.2, -625.6), facing the quay |
- Also live: ComingSoonWall (players held to the spawn grass; Studio: she passes through it), travel trunk at (253,-575) by the cliff, AlleyCrates (4 storage crates between Gelateria and Casa Azzurra), respawn at the LAST DAIS TOUCHED (attr `Dais`, saved), Studio-only start at Porto (`SpawnReturn.StudioStartPorto`), French-only Keeper (per map; Italian Keeper switches on once Harbour Front is complete) and French-only Daily, mailbox says "mayor", hats appear in Passport > Wardrobe.
- Studio play tests start with ALL squirrels found (Codex's `studioFullFindsPreview` in SquirrelSetup, her uid) - she said keep it.

## The squirrel pipeline (works - don't experiment)
1. Meshy zip in Downloads -> `squirrels/<id>/src/`. Fine if the FBX is <= ~1.5M verts. Huge files (7.7M tris) = realistic fur in her 2D art; she regenerates with smoother fur. NEVER suggest voxel rebuilds (she hated it) or switching Meshy models.
2. `prep_squirrel.py` (staged decimate) -> `run_rig_batch.py <id>` pattern (1k texture from src*, `make_gray.py`, `rig_squirrel.py`, `audit_generic.py`) -> `fix_weights.py <dir> <id> <head_zcut> 0 -9 0.30 [regions]` (props held near the head: region rule to Chest) -> `render_turned_view.py` check. Careful: glob `src*` picks the FIRST folder - delete/rename old src or point at the right one.
3. Studio: File > Import (3D) or the Import Queue folder icon; type the FBX path in short chunks. Import colour + gray.
4. Install via a PatchModule .rbxmx (Folder + ModuleScript `return function() ... end`) -> File > Import Roblox Model -> run `local m=game:FindFirstChild('<Name>',true) require(m.PatchModule)() m:Destroy()` typed in <=15-char chunks, then click Run (1427,745). Installer pattern: `tools/italy_squirrels/install_gelato.lua` (registry insert after the last porto entry, ColorTexture/GrayTexture attrs, gray twin to SquirrelTwins y -400, upright fix `CFrame.new(cm.Position)*rel`, yaw about world Y, foot check at game size 3.4).
5. Show her ONE view, publish only on her word (click 3D view, Alt+P, confirm "Published new changes" + version in `%LOCALAPPDATA%\Roblox\logs\*Studio*_last.log`).

## Studio gotchas (all hit this session)
- **Clipboard paste into Studio is broken**: `type` text >~16 chars goes via clipboard and silently drops or pastes OLD text. Type in <=15-char chunks; use .rbxmx import for scripts. Read results from the Studio log (warn/print with a QQ@ tag) instead of the Output panel.
- **A command-bar/module script that errors rolls back ALL its changes** - never assert after the first edit; warn + return.
- Never `open_application` Roblox Studio when it's open (she says it glitches). If clicks fail because Snipping Tool/Edge is "frontmost", ask her to click Studio.
- Floating Output window can cover the File menu - close it first.
- Shop windows are shallow display pockets with a painted backing - nothing fits inside.
- From the quay looking east, RIGHT = +z (north). Her screenshots are from Studio play tests - believe them.
- GetPartBoundsInBox counts a MeshPart's whole AABB (cliffs) - use raycasts near cliffs.

## Her style rules
- Bios: joke from the squirrel's own job/props, no repeated gags (fishing squirrel in France already has the catch-and-release joke; seagulls used by Beppe).
- Squirrels same size as French (3.4 runtime), feet solidly planted, not blocking walkways, centred on things they stand on.
- Keep work lean; don't over-probe. Stop at 70% weekly usage (rest is for Ethan).

## Update Oct 4 afternoon (live v1005)
- Porto squirrels now 11 (registry 55): + Vito the Boat Painter (boatyard barrel), Signora Chiave (realtor, Casa Salvia), Penny the Tourist (causeway north end), Tito the Tightrope Walker (middle clothesline), Capitano Remo (on the Azzurra), Sandro the Sunbather (beach). Installers in tools/italy_squirrels (install_*.lua, reg_*.lua, move_*.lua).
- Natural tide pools replaced Codex's ring basins (backup ServerStorage.TidePoolBackup): mesh from roblox-props/italy/tidepools (gen_tidepools.py -> obj2fbx.py -> Import Queue FBX; the queue IGNORES .obj), placed by tidepools_place/swap3 scripts. Wading + 4 rigged crabs = StarterPlayerScripts.TidePoolLife (source italy/tidepools/TidePoolLife.client.lua; crab rig italy/crab/rig_crab.py; template ReplicatedStorage.TidePoolCrab).
- Lessons: terrain voxels (4 studs) can't make small pools; Roblox lights textures much brighter than Blender; verify the File menu/dialog opened before typing; computer-use 'type' over 15 chars goes through the clipboard; installers' old tail-side mirror guess is wrong for tails on +x (use sx=1); for 'where my character is standing' read LocalPlayer HRP in a play test.
- Studio window is now a smaller window: File (134,88), Import Roblox Model (185,216), file-name box (550,437), command bar (700,716), Run (1368,716), Import Queue folder (137,565), Stop (266,110), Play (207,110).
