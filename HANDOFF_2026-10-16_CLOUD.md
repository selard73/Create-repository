# Handoff: 1001 Squirrels - the CLOUD thread, Oct 16 2026 -> the next cloud thread

## >>> READ THIS FIRST <<<
- You are the CLOUD thread: you write Studio installers / patches / Blender generators in this repo, commit and push to
  `claude/youthful-curie-8azx86`, and hand them to RUNNER 7 (Claude Code session `session_01JuVhpFbJPyyCZ9K5dZyPhB`, via
  `mcp__claude-code-remote__send_message`). Runner 7 runs on Shannon's PC with Roblox Studio: it pulls by commit, checks length +
  adler32, previews in play, installs in Edit only on her word, and pushes logs / pictures / surveys to `claude/epic-hawking-188q4l`,
  which you merge (`git fetch origin claude/epic-hawking-188q4l && git merge origin/claude/epic-hawking-188q4l`; JOB.md conflicts:
  keep both sides).
- `tools/cloud/JOB.md` is the job log (every job, every result). The plans: `tools/japan/PLAN_japan_features_2026-10-16.md` (the
  feature list with her decisions) and `tools/japan/PLAN_japan_restyle_2026-10-16.md`.
- Shannon (selard73, Roblox owner id 9611145467, SelBell) publishes herself and restarts servers. Never publish, never write
  DataStores (saves only via `ReplicatedStorage.AwardItems` / `AwardAcorns`), no model identifiers in commits.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` + `Claude-Session: https://claude.ai/code/session_01MKXFUzLgdDUZA4QuK93pku`
  (use whatever the system reminder of the new session says).
- Tools here: Luau compile check `/tmp/.../scratchpad/luau/luau-compile --null file.lua` (rebuild it if the scratchpad is gone);
  Blender = the `bpy==5.2.2` pip package in a venv (`python -m venv bpyenv && bpyenv/bin/pip install bpy==5.2.2`), headless Cycles
  CPU only (Workbench needs libEGL). FBX export `axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
  bake_space_transform=True`; Roblox axes from Blender: x = x, y = z, z = -y. `.gitignore` drops *.fbx/*.png/*.jpg -> `git add -f`.

## Shannon's standing taste rules (learned the hard way today)
- "Do not build anything from roblox parts ... if you build it has to be in blender" (parts only for invisible seats/supports).
- NOT realistic: "on same par with the italy and france maps". Faceted low-poly works for HARD shapes (stone, wood, bridges, rocks,
  buildings). It FAILS for organic things: moss caps, reeds, lilies, low-poly blossoms ("look like lucky charms"). For flowers use a
  rendered picture on a crossed card (planting 2, which she liked). Meshy foliage = "too too many parts"; Meshy is fine for creatures
  (her koi). "We already have a lot of trees." Grass stays as it is.
- Look tests with pictures before anything is installed; runner 7 measures (raycasts, voxels) - believe its numbers over your maths.

## Hard-won technical lessons
- TERRAIN WATER: a water row's surface = its BOTTOM + 4 x occupancy (the [0..4] row at 0.325 = 1.3). The earlier "row top - 2 + 4 x
  occ" rule is for SOLID surfaces. Region bounds must include the cell columns you mean to write; pad only where a wall covers the
  cell, or water leaks onto the lawn.
- Imported FBX pieces may come in turned 180: place by bounding box (pieces.json from the generator), and if a piece is reversed,
  turn it about its OWN bbox centre (a yaw about the box-derived origin MOVES it).
- Re-runnable installers must find things the first run retired (read them back from HudBackup.*Replaced).
- Dark meshes = baked dark VERTEX COLOURS (not the material variant). Fix = rebuild the mesh without vertex colours + ApplyMesh
  (runner 7's darkrockfix1 / rebuild_dark_meshes.py).
- Water motion = Beams with a scrolling texture + ParticleEmitters, not a glass ribbon mesh.
- Animated models (koi, boats) need ModelStreamingMode Atomic or they stream in piecemeal.

## DONE today (Oct 16) - all INSTALLED in Edit by runner 7; she publishes
- The Momiji canal (job 125 batch 3, final 3k): stone walls in the palace flagstone (Pavement + JM_PhotographicPath) down to a Slate
  bed at -4, water 1.3 (5.3 deep), teal canal water (canalwater1 + canalwater2 patches of StarterPlayerScripts.JapanWaterAppearance),
  3 taiko bridges with landings + water steps, 112 stepping-slab path stones, 5 Meshy koi meandering (CanalLife client script), ONE
  boat (runner 7's Yanagawa boat at 0.72), runner 7's canal_falls with Beams + mist/spray, darker lanterns, the floating maple set
  down, the black pine OUT. garden_look3.lua (make_garden_look3.py) is re-runnable; backups in HudBackup.MomijiGardenReplaced /
  MomijiGarden_prev.
- darkrockfix1 (runner 7): JP_Waterfall_Rockface, JP_Onsen_Shore, JP_Koi_Pond_Shore without the dark vertex colours.
- Earlier today (all published): Homebase treehouse rounds, the message-in-a-bottle game, croc portraits, gifts, Shademade guest,
  Japan geo rounds.

## IN FLIGHT (waiting on someone)
1. CHURCH (her word: "please build what you describe") - commit 114f625. tools/japan/church/gen_church.py -> out/church_shell.fbx +
   church_interior.fbx (Goto-islands style: white plaster, dark timber, tiled roof, arched coloured windows, rose window, bell tower
   with louvres + cross; ten pews, altar, lectern, candles, bell rope); church_install1.lua (10925 B, adler32 2183932199) at site A
   (6101, -266, yaw 0, door north to the canal), 30 pew Seats, swinging door leaves, bell rope (BELL_SOUND "" until she picks one).
   WAITING: runner 7's import + preview with pictures, then her word. One church on EVERY map: the interior kit shared, a shell per
   map (Italy Romanesque chapel + campanile, France village church with a slate spire) - later.
2. FLOWER CARDS for the railway strip (she liked the render: "that looks really nice") - commit 95933a1. planting2.lua (5090 B,
   adler32 2185845249; ABORTS while IMAGE is 0) + out_iris/flower_card.fbx + iris_card.png. WAITING: SHE uploads iris_card.png as an
   image asset (the id goes into IMAGE) and imports flower_card.fbx; then runner 7 previews (85 cards replace 510 iris parts).
3. Her answers today, NOT yet started (all "yes"):
   - BAMBOO MAZE at the far end of the tea field: replace the 102 part-built "Bamboo clump" Models (3,506 parts) with ONE Blender
     bamboo-hedge segment mesh, and build a REAL maze ~95 x 110 at x 5375..5470, z -290..-180 AROUND and UNDER the "Volcano
     overlook" boardwalk (5425, 7, -200) - the boardwalk becomes a lookout over the maze. Layout seeded by the DATE (new maze daily),
     a prize stone at the centre (acorns once a day), a "lost?" hint after 3 min. Survey: tools/japan/feature_surveys_2026-10-16.
   - KOI FEEDING at the palace pond ("Koi pond set piece", round terrain pond 56 across at (6322, 21), surface 3.9, a moon bridge
     across): replace the 8 part koi floating on the surface with 8-10 Meshy koi (kit koi_meshy, facing 0 with CanalLife's lookAt)
     swimming 0.2 under; a koi-food tub (Blender) "Koi food - 5 acorns"; throw a pinch at the edge -> frenzy (koi race to the spot,
     splashes, churned foam, a low rumble + camera shake within 20), a FIRST-FEED-OF-THE-DAY reward.
   - KIMONO via the existing wardrobe: new DressKit styles (slot 'dress') with kimono meshes (Bodice_kimono / Skirt_kimono / Belt =
     the obi ...), fabrics = COLOUR SETS (indigo, cherry, plum, gold ... with a contrasting obi), Price_<styleId>, a try-on mirror at
     the Kimono shop (6022, 12.2, -38). DressServer checks the distance to ONE Spot -> a small server change for a second spot.
     Sources: tools/japan/feature_surveys_2026-10-16/wardrobe_sources/ (DressServer, DressClient, WardrobeClient, DressKit/HatKit
     Catalogues). Owned = Item_dress_<style>_<n>, worn = Item_dresswear_<...>, both via AwardItems.
   - PROPELLER CAP (a quiet Doraemon tribute, kept generic): a HatKit hat with a two-blade spinner, sold from a blue-and-white gadget
     vending machine in Lantern Street; hold Jump to rise, hover, WASD at 1.6x, ~25 s flight meter recharging on the ground, ~60
     ceiling. Defaults pencilled: 300 acorns, every map - CONFIRM with her.
   - SUSHI MEMORY MATCH: ON HOLD (her word).
   - Later from the plan: photographer with the volcano backdrop + a treehouse photo frame, archery at the palace targets, the cat
     cafe with Meshy cats (she generates them).
4. Open housekeeping: the volcano, ridgelines and island cliffs have the same dark vertex colours (runner 7's pipeline); the falls'
   mist could glow ~0.1 less; Lantern Street town restyle (machiya fronts, lantern strings) - later.
5. Oct 17: the dashboard read (runner 14:00Z; a check-in was scheduled 17:16Z) -> what brings players back.

## Suggested next order
Church preview -> flower cards (when her upload lands) -> koi feeding -> bamboo maze -> kimono -> propeller cap -> the rest of the plan.

**Starter prompt for the new cloud chat:**
> Read HANDOFF_2026-10-16_CLOUD.md in the repo (branch claude/youthful-curie-8azx86) and continue as the cloud thread for 1001 Squirrels. Merge runner 7's branch claude/epic-hawking-188q4l first and read the latest JOB.md entries.
