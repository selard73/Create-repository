# Handoff to Codex - 1001 Squirrels, Japan map (Oct 17 2026, 05:30 UTC)

## Current cat cafe roof fix (Oct 19)
The four original cedar corner posts and two matching front facade beams were extended to top Y20.25 so they tuck under the existing tiled roof. Saved in Studio with Notes, not published by Codex. Shannon checks after publishing. Guarded replay source: tools/japan/garden/cafe_roof_supports1.lua.

## Shannon's Oct 18 workflow update (supersedes standing rules 1 and 2 below)
For a mechanical change such as the 44th-squirrel boat invitation, play-test to confirm it works before installing. For a visual change, install and save first; Shannon checks it after she publishes. She still publishes herself. Do not keep asking for preview approval. The no-publish, no-DataStore-write, no-extra-Studio, real-mesh, reference/style, and announced-avatar-movement rules remain.
The ramen counter and stools face the street; Shannon stopped the glass-door proposal. Do not add a glass door across the open counter. The rejected vertical OPEN plaque was removed from the live scene.
The original red OPEN sign was later restored above the side entry, mounted on its timber lintel at Y8.30 with bottom Y7.75; it is saved for Shannon to publish. No door.


Shannon (Roblox user selard73 / Studio account CozyGameMode, display name SelBell, user id 9611145467) builds "1001 Squirrels" on
Roblox (placeId 117372258657114, universe 10766369535). Claude's credits are out until Wednesday Oct 21 ~11:00 UTC; Codex takes over
the Japan map until then. This file is the whole picture. Read it, then `tools/cloud/JOB.md` (every job's result, newest at the end)
and `HANDOFF_2026-10-17_RUNNER7.md` / `HANDOFF_2026-10-16_RUNNER7.md` (the two previous days).

## Her standing rules (current workflow)
1. **Visual changes:** install and save them in Studio; Shannon checks after she publishes.
2. **Mechanical changes:** confirm the behavior in a play test before installing and saving.
3. **Never publish** - she presses Alt+P, then restarts servers. **Never write DataStores. Never launch Studio** (a second instance
   freezes it). Never move her avatar/camera without saying so first.
4. **Japan = real meshes only, stylised like the France / Porto maps; the grass stays as it is; Meshy only as a last resort.** No builds
   out of plain Roblox parts.
5. **She imports FBX herself** with File > Import 3D from `OneDrive\Desktop\Japan garden kit\` (one combined file per batch). After the
   import: anchor the parts and move the Models into `ServerStorage.JapanGardenKit` BEFORE any play test (Import 3D leaves them loose
   in workspace and physics knocks them over).
6. **Match the thing's own style and the real-world form; build to her references** (tools/japan/reference_2026-10-16 and
   reference_2026-10-17). Each instance should differ ("the rear for each should vary"). Find the CAUSE of a fault, not the symptom.
7. Phones: nothing may overlap on a phone screen. Sizes: an R15 avatar is ~6.3 tall (doors ~10, seats ~1.9).
8. She uses Edge, not Chrome. Her Desktop is `C:\Users\slard\OneDrive\Desktop`.

## State right now
LIVE (published Oct 16-17): canal walls + stepping stones + koi + boat; canal falls r3 + taiko-bridge ends (bridgeend1); the church;
iris flower cards; the palace pond (pondfix1: stone wall, bed, 10 Meshy koi, teal water); the bamboo maze (bamboomaze1, daily
layout) + its once-a-day 25-acorn exit reward (mazereward1); the moon bridge's two ends (moonbridgeend3, a real taiko-bashi end);
wayfinding (wayfinding1: 4 fingerposts, a map board at the arrival court, 6 indigo station banners); the island's floating ground fixed
(islandbase1: solid terrain under the whole grass sheet + an earth/sand shore; propground1: 25 floating props set down; walkfix1:
wedges under the 6 sloping walkways + a block under the volcano lookout deck); the shop BACKS (shopbacks2, 164 pieces behind the 10
market shops: lattice doors/windows set into the walls, upper-floor windows, lanterns, lattice bands, tile awnings, yard things, each
shop different).
PUBLISHED BUT UNVERIFIED: the Mikan greengrocer FRONT (shopfront_mikan1 at 30d5769, kit21: a 30-wide tiled awning on timber posts,
a carved sign, jar shelves, baskets on benches on the lane, potted bamboo, a standing lantern, side banners). Studio logged
PublishSuccessful at 05:17, 05:22 and 05:26 UTC Oct 17; she did not see it live after the first two (the backs showed). Roblox's games
API "updated" lagged at 05:17. **First job: she checks in a FRESH server (Shut Down All Servers on the game page, rejoin).** If it is
still missing: in the live game F9 > Server, look for `workspace.JapanMap.ShopFronts.Mikan`; if absent, re-run shopfront_mikan1 in
Edit (it is re-runnable), Save to Roblox, she publishes; if present but invisible, kit21's mesh assets may still be processing on
Roblox's side (wait, then publish again).

## Her queue (in this order unless she says otherwise)
1. The OTHER SHOP FRONTS, each from a reference, like the greengrocer: tools/japan/reference_2026-10-17/SHOPFRONTS.md lists her three
   photos (a Kyoto machiya front; the grocery front - done; a Takayama all-dark-timber front, saved as a .webp). Shops (in
   `JapanMap."Outdoor market revision"`): Sushi bar, Rice and provisions, Paper umbrella craft, Calligraphy teahouse, Mikan greengrocer
   (done), Ramen kitchen, Lantern workshop, Kimono atelier, Kimono shop, Cat cafe. Fronts face the stone lane at x 6000 (west row
   fronts at x ~5994, east row at x ~6006). Ask her for a reference per shop or propose one; vary them.
2. "The map feels too big" - her chosen plan (option 3): fill the empty lawns with the planned features: koi feeding at the palace pond
   (PondLife's 10 koi exist; a food tub "5 acorns", a frenzy, a first-feed-of-the-day reward - plan in tools/japan/PLAN_japan_features_2026-10-16.md),
   a photographer on the west lawn with the volcano behind, archery on the palace court, the cat cafe in the market (her Meshy cats);
   then trim the south strip below the railway and the north margin to sea / cliff (terrain only).
3. Small: denser slats on the shop-back lattice panels (they can read as a fence from afar); the church's arch seam; the falls' mist a
   touch less bright.

## Where everything is
- Repo `C:\Users\slard\Create-repository` (GitHub selard73/Create-repository), work branch **claude/epic-hawking-188q4l** (push there;
  no `gh`, plain git). .gitignore drops *.fbx / *.png / *.jpg: add kits and pictures with `git add -f`. The repo is PUBLIC - no keys.
- Log of every job: `tools/cloud/JOB.md` (CRLF; append a section per job with the installer's "QQ ..." output lines verbatim).
- Japan tools: `tools/japan/` (islandbase1.lua, propground1.lua, walkfix1.lua, surveys) and `tools/japan/garden/` (gen_*.py Blender
  generators -> out_*/ kits; the installers *.lua; check_*.py preview renders; shots_*/ pictures). Helpers: tools/japan/tools/
  combine_fbx.py (several FBX -> one kit with an Empty per piece), mesh_receiver.py, prep_meshy_koi.py.
- Blender (Store install) runs headless through `python C:\Users\slard\roblox-props\meshy\run_blender.py <log> <MARK> <script.py>
  [args]` - one job at a time; the script writes <MARK>_DONE / _FAILED in its log. FBX export: axis_forward "-Z", axis_up "Y",
  FBX_SCALE_ALL, bake_space_transform; to embed a texture: path_mode "COPY", embed_textures True.
- Studio: the Roblox Studio MCP (execute_luau on Edit / Server / Client datamodels, start_stop_play, screen_capture). HttpService is
  OFF in the place; installers are fetched from raw.githubusercontent.com at a commit SHA by switching HttpEnabled on and back off
  inside the same call, checked by length + adler32 against `git show <sha>:<path>` (LF), and run through a ModuleScript wrapper
  `return function(print) <file> end` with a collecting print. loadstring is not available. The same code on the play-test Server =
  the preview. Studio's log: `%LOCALAPPDATA%\Roblox\logs\*_Studio_*_last.log` ("Place published" lines = her publishes).
- Backups of everything replaced: `ServerStorage.HudBackup.*` (PondReplaced, MazeReplaced, MoonBridgeReplaced, IslandBase_pre1,
  MikanFrontReplaced, ...). Moved things carry attributes (PropGroundWasCF, WalkFixWasCFrame, IslandBaseWasY, *WasIn).

## Hard-won lessons (Oct 16-17)
- Imported FBX pieces often come in turned 180 (sometimes not): place by bounding box, DETECT the turn from a marker part, and add a
  side check after placing (turn the piece round if it landed on the wrong side of its wall).
- A kit piece's pivot must sit at its GROUND LINE, not its lowest vertex (windows / awnings / lanterns dropped to the floor once).
  CFrame.Angles(0, +pi/2, 0) sends local +z to world +x.
- CollisionFidelity set inside an installer stays Default: set PreciseConvexDecomposition on the PLACED MeshParts in a separate call.
- Japan's lawn = one 4-stud grass mesh sheet (JM_JR_BasinGround_1..8, top -0.04) over an invisible CanCollide floor at y 0; the sea is
  at -6 under it (now with a solid Ground row at -4 beneath). A "ground" ray must accept the first CanCollide hit, not the first visible
  one. Terrain water is flat only inside a square of four water-cell centres.
- Props over water: a rock keeps 40 % out of the water and gets a Sand shoal filled under it.
- Blender: bmesh.ops.triangulate fills concave caps - use mathutils.geometry.tessellate_polygon. Picture cards: embed the PNG in the
  FBX and show it with a SurfaceAppearance AlphaMode Transparency.
- A play-test Client script made at run time runs; a Gifts card pops at 180 s in a test (hide GiftsGui / GiftsToast / DailyGui before
  pictures). Studio's screen_capture omits Roblox's own UI.
- GitHub pushes can fail when the PC is low on memory ("could not read Username for https://github.com"): commit locally, push later.
- She reads small pictures badly: close and low, the exact thing, before/after from the same spot.
- Two rounds were rejected hard ("really really bad", "that looks terrible, what are you doing?") when I bolted a generic thing onto
  her build (white stone landings on a red bridge; a plank door stuck onto a wall). Build to the form of the real thing and her photo.

## Starter prompt for Codex
> Read HANDOFF_2026-10-17_CODEX.md in C:\Users\slard\Create-repository (branch claude/epic-hawking-188q4l) and the last sections of
> tools/cloud/JOB.md. You are working solo with Shannon on 1001 Squirrels' Japan map, following the standing rules in the handoff.
> First: confirm with her whether the greengrocer front shows in a fresh server; then continue with the other shop fronts, one at a
> time, each from a reference, previewed in a play test with pictures and installed only on her yes.
