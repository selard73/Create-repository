# Handoff - 1001 Squirrels, Japan map (Oct 16 2026, evening) - runner 7, single session

Shannon (selard73; Studio account CozyGameMode, display name SelBell, user id 9611145467) builds "1001 Squirrels" on Roblox. From Oct 16
she works with ONE session on her PC ("you no longer need to check in with cloud, you are now working solo with me only"): that session
designs, builds (Blender), previews in Studio play tests with pictures, and installs in Studio Edit on her word. The cloud thread
(HANDOFF_2026-10-16_CLOUD.md) is retired; its queue is below.

## Standing rules (hers - follow exactly)
- **Ask before every Studio edit** ("do what you think is best" covers a batch she named). Read-only surveys and play-test previews need
  no ask. **Never publish** - she presses Alt+P, then restarts servers.
- **Never write DataStores** (game code awarding items through the existing AwardItems ledger is fine). **Never launch Studio**
  (no open_application; it opens a second instance).
- **Preview first, with pictures**, by her eyes (natural camera); install only on her yes. When she says what she wants, do it - no
  option menus. Nothing may overlap on a phone screen.
- **Japan: meshes only, no Roblox-part builds** ("the no was not to build anything using roblox parts"); stylised like France/Porto;
  the grass stays as it is; Meshy only as a last resort (her Meshy koi are fine). "We already have a lot of trees."
- She imports FBX herself with **Import 3D**: give her ONE combined file in `OneDrive\Desktop\Japan garden kit\`
  (tools/japan/tools/combine_fbx.py), then move the imported Models into ServerStorage.JapanGardenKit.
- Sizes: an R15 avatar is ~6.3 tall - doors ~10 tall, seats ~1.9 above the floor ("the door comes up to my knees").
- She uses **Edge**, not Chrome: Claude in Chrome can't reach her browser. The app's built-in browser pane works but is NOT signed in to
  Roblox (she must sign in there herself).
- Weekly usage: stop at 70% and write a Codex handoff (her rule).

## Where things are
- Repo `C:\Users\slard\Create-repository` (selard73/Create-repository); work branch **claude/epic-hawking-188q4l** (push there).
  Log of every job: `tools/cloud/JOB.md` (CRLF; append, keep QQ lines verbatim). Merge conflicts in it: keep both sides.
- Studio MCP id `d2da2bee-2f50-4546-b312-b300a907c883` (1001 Squirrels, placeId 117372258657114).
- Blender (Store install): `python C:\Users\slard\roblox-props\meshy\run_blender.py <log> <MARK> <script.py> args` - one job at a time,
  the script writes `<MARK>_DONE` / `_FAILED` in its log. FBX export: axis_forward "-Z", axis_up "Y", FBX_SCALE_ALL,
  bake_space_transform; embed textures with path_mode "COPY", embed_textures=True.
- Helpers: `tools/japan/tools/combine_fbx.py` (several FBX -> one, an Empty per piece), `mesh_receiver.py` (localhost:34991 receiver
  for Studio HttpService POSTs - how to pull a mesh's geometry out of Studio), `prep_meshy_koi.py` (decimate/scale a Meshy model).
- Install pattern (every script): push to the branch, take length + adler32 of `git show <sha>:<path>`, and in Studio fetch the raw
  file at that SHA with HttpService (HttpEnabled on, then restored), check the checksum, run it in a ModuleScript wrapper whose print
  is captured; the same code runs on the Server datamodel in a play test as the preview (discarded on stop).

## Done and PUBLISHED today (Oct 16) - Japan canal + church + more
- **Canal** (JapanMap.MomijiGarden): flagstone walls (Pavement + JM_PhotographicPath) with lower copies to a Slate bed at -4; water at
  1.3 (a water row's surface = its bottom + 4 x LiquidOccupancy); teal water over the canal only (StarterPlayerScripts.
  JapanWaterAppearance, patches CANALWATER1/2); 3 taiko bridges (garden bridge at z -203) **raised 1.6** with taller landings
  (canalfix1); water stairs turned round; stepping-stone paths; her Meshy koi swimming 0.2 under in meanders (CanalLife client script,
  Atomic streaming); one moored boat (my Blender Yanagawa boat, 0.72 scale, house browns); lanterns darker stone + dimmed glow; the maple
  moved off the garden bridge path to (6138, -186).
- **Waterfall r2** (canalfalls2.lua, gen_falls2.py): rocks stand IN the canal's south end in place of WallS2/WallS3; the water comes out
  of a cleft, down a rock chute, straight into the canal; 2 scrolling Beams + mist + spray. Her rule: rocks at the edge, an entry for the
  water - never water lying on a flat coping.
- **Church** (JapanMap.Church, church_install2.lua r4, gen_church.py out4): Goto-islands style at (6115, -280.8) behind the falls, door
  north to the canal, tower on the east corner (Fuji visible from the bridge); doors (E) swing in and close after 12 s; 30 pew seats
  facing the altar; bell = the French chapel's sound rbxassetid://9113804436 (BellSound attribute); ChurchScript (server) runs doors +
  bell. Known: a hairline seam above the door arch - close it on the next rebuild.
- **Black rocks by the stream**: JP_Waterfall_Rockface, JP_Onsen_Shore, JP_Koi_Pond_Shore rebuilt without their dark VERTEX COLOURS
  (darkrockfix1, ApplyMesh; originals in HudBackup.DarkRockOriginals).
- **Irises**: the 510 part irises by the railway -> 41 picture-card clumps scattered in drifts (planting3.lua; kit iris_card imported
  with its picture; SurfaceAppearance AlphaMode Transparency).
- **Treehouse counter** (treecount1): custom event "TreehouseBuilt" once per builder (Field 1 "built now"/"built before", Field 2
  device). Her dashboard: Analytics > Custom dashboards > Dashboard #1 > chart TreehouseBuilt (Source Custom events, Event type
  TreehouseBuilt, Count; Breakdown Custom field 1). As of tonight: 1 = her own "built before" on joining. Interact_Item / name
  tree_done also records finishes since Oct 14.
- Backups (ServerStorage.HudBackup): MomijiGardenReplaced, MomijiGarden_prev, Falls2Replaced, IrisReplaced, DarkRockOriginals,
  Church_prev, TreehouseServer_pre_treecount1, JapanWaterAppearance_pre_canalwater1/2, JapanGardenKit_old_walls, *_old kit pieces.

## Hard-won lessons
- Imported FBX pieces often come in **turned 180**: place by bounding box and DETECT the turn from a marker part (door, altar, foam),
  then undo it; never assume.
- **bmesh.ops.triangulate fills concave caps** (arches) - cut caps with mathutils.geometry.tessellate_polygon.
- Japan's black-looking Blender meshes = **dark vertex colours** multiplied over any colour/material/texture. Fix = dump geometry via
  EditableMesh -> POST to mesh_receiver -> rebuild in Blender without colours -> she imports -> old:ApplyMesh(new).
- A picture card: embed the PNG in the FBX (Import 3D uploads it); show it through a SurfaceAppearance with AlphaMode Transparency
  (a plain TextureID draws the clear background black).
- An installer's `Triggered:Connect` does nothing live - leave a Script in the model. CollisionFidelity can't be set in a play test
  (set it on the kit in Edit first).
- Coplanar faces flicker: keep layered pieces >= 0.05 apart and let trims stand past the faces they meet.
- Always measure the water SURFACE in previews; the play-test player is the owner and Studio never loads/saves her store.

## Next (her queue, in this order unless she says otherwise)
1. **Dark rocks still to fix**: JP_Volcano_Sculpted, JP_Ridgeline_1/2, JP_Island_Cliffs_North/South/West, JP_Rice_Berm_1-3 - same
   vertex-colour pipeline (tools/japan/rocks/rebuild_dark_meshes.py; ~37k vertices).
2. **Koi feeding at the palace pond** ("Koi pond set piece", round terrain pond ~56 across at (6322, 21), surface 3.9, a moon bridge):
   Meshy koi 0.2 under instead of the 8 part koi on the surface, a koi-food tub "5 acorns", a frenzy where the food lands, a
   first-feed-of-the-day reward. Survey: tools/japan/feature_surveys_2026-10-16/SURVEY.md.
3. **Bamboo maze** at the far end of the tea field (x 5375..5470, z -290..-180, ~95 wide): one Blender bamboo-hedge mesh replacing the 102
   part-built clumps, a real maze built around the "Volcano overlook" boardwalk, new layout daily, prize stone, "lost?" hint.
4. **Kimono** through the existing wardrobe (DressKit styles + colour sets with a contrasting obi, a try-on mirror at the Kimono shop;
   DressServer checks ONE Spot - small server change). Sources in feature_surveys_2026-10-16/wardrobe_sources/.
5. **Propeller cap** (hat with a spinner, hover flight) - confirm price/maps with her first. Sushi memory match: ON HOLD.
6. Small: the church's arch seam; the falls' mist could glow a touch less.
- The scheduled task `squirrels-dashboard-oct17` expects her Chrome - it will not reach Edge; read the dashboard through the built-in
  browser once she has signed in there, or ask her for screenshots.

## Starter prompt for the next session
> Read HANDOFF_2026-10-16_RUNNER7.md in C:\Users\slard\Create-repository (branch claude/epic-hawking-188q4l) and the last entries of
> tools/cloud/JOB.md. You are working solo with Shannon on 1001 Squirrels' Japan map. Follow the standing rules in the handoff, then ask
> her which item from the "Next" list to start.
