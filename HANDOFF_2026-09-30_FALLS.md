# HANDOFF — 1001 Squirrels: the south gorge ends in a WATERFALL (Sep 30 2026, evening)

Starter prompt for the next chat (paste it):

> Please read C:\Users\slard\roblox-props\HANDOFF_2026-09-30_FALLS.md and the memory notes it points to. We are
> finishing the waterfall at the end of the south gorge in 1001 Squirrels (Roblox Studio is open on the live place,
> Team Create, nothing published). Start with the three fixes under "HER LAST NOTES", one Studio step at a time, asking
> before each edit.

Read first: memory `new-maps-travel-plan.md` (the running log; the last ~8 entries are this evening), `ask-before-studio-edits.md`,
`roblox-map-build-quality-bar.md`, `phone-ui-no-overlap.md`, `chasing-rainbows-squirrels.md` (standing rules).
Previous handoff: `HANDOFF_2026-09-30_ITALY.md`. Her plan doc: Claude Doc "1001 Squirrels — Italian Harbour Map Plan"
https://claude.ai/artifact/QGBF9Na9PNVYRvWqsG5P5q.

## Standing rules (hers)
- ASK before every edit to the shared place (probes/read-only scripts are fine). Publish ONLY on her word. Never touch her
  save data / DataStore. API access stays OFF in play tests. Keep Codex's work. Phones: no UI overlaps ever.
- Restore her editor camera and her clipboard after every Studio session (see "Driving Studio").
- Quality bar: new areas detailed and finished first time; measure, don't eyeball; she can't see SendUserFile images —
  pictures go on artifact pages.

## Where things stand (NOT published; the boat prompt is still off: Workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt Enabled=false)
Decided Sep 30 ~19:40: the gorge OPENS onto a waterfall (the earlier cave/headwall was my misread and is gone). Italy
(Porto Nocciola) sits at the FOOT of the falls, 50 studs below France: the trip is one continuous ride, gorge -> lip ->
fall (boat breaks up; parachute drift to a beach target, or splash and swim) -> harbour. No map card outbound; the
card stays for the Captain's trip home by sea.

Built in Studio today (all approved step by step):
- `workspace.SouthGorge.Rock`: 18 wall chunks (unchanged, verified vertex-for-vertex) + 18 cliff pieces
  `SouthCliff_W01..W04 / E01..E04 / L01` each with a `_Lo` half (two textures: strata.png above river-bed level =
  the walls' asset rbxassetid://131222358558225, strata_low.png below = rbxassetid://76323404883364). Arms collide
  (PreciseConvexDecomposition); the sill face (L01) does not (the boat passes over it). DoubleSided on W08/W09/E08/E09
  and the first cliff chunks. Old headwall pieces parked in `ServerStorage.GorgeBackup.OldEnd`.
- `workspace.Baseplate` (Union) CUT away south of z -546.5 (now 2048 x 16 x 1570.5); clone `GorgeBackup.Baseplate_before_cut`,
  original parked as `GorgeBackup.Baseplate_original_pre_cut`. Name/texture/attributes/collision kept.
- Terrain south of the ridge rewritten (`tools/gorge_terrain_t10_write.lua`, 44 chunks backed up as `GorgeBackup.TerrainSouthB_NN`):
  plateau + 7-stud hollow behind the arms, plain at -48, cove + plunge pool, sea at -52.9 (to z -1556, x +-1400),
  hillside beyond the arms matching the arms' end faces (Sandstone where steep). Fix passes t11 (substrate under the
  lip) and t12 (bank cells beside the corners) and a re-run of t5 (the gorge carve) after t10 refilled part of the
  east wall's hollow. Probes clean: lip 0 pokes, walls 2 touches < 0.7.
- Trees: 181 in `SouthGorge.Trees` (rebuilt from gorge_trees1's own table after my pivot mistake; seated by geometry).
- `workspace.SouthGorge.Falls` (Atomic Model, scenery only, no scripts) from `tools/falls_water2.lua`: 44 beams
  (39 rapids segments in 3 chains following the river from 52 studs up, Crest, Body, Sheet, Sheet2, MistBank) and
  13 emitters (Foam x4, Churn x2, RiverMist x3, Spray, Mist, Plume). Our streak texture = rbxassetid://129457182364461
  (italy/falls/falls.png, uploaded via the Import 3D carrier trick: a tiny quad's material map -> MeshPart.TextureID).

## HER LAST NOTES (Sep 30 ~22:48, three circled screenshots) = the next three tasks
1. "The top forward view is still looking weird on the sides at the cliff edge point" (boat's-eye at the lip, both
   corners circled). Cause: the Crest/Sheet/Body beams are exactly river-width (31-32) so their ends stop at the walls
   and the river's teal cut-off face shows beside them; the roll's top stands 0.35 above the water. Fix: widths 36 so
   the ends bury in the rock; TopC at WATER_Y - 0.05 (start the roll AT the surface); re-check from gorge_view_q_boat
   and gorge_view_p_lip.
2. "The bottom of the waterfall is too uniform; it looks like a sheet." Fix: split the Sheet into 4 ribbons of
   different widths/speeds/TextureLength with ragged, differing bottoms (bottom z -5..-8, bottom transparency
   0.6..0.9); Body transparency rising to ~0.85 by t 0.9 so it dissolves; a Splash emitter at the impact (Size 2->6,
   Speed 8-14 up, Spread 60, Lifetime 0.6-1.1, Acceleration (0,-20,0)); a flat FoamRing emitter on the pool
   (VelocityPerpendicular, Size 4-8, slow outward); more mist bank near the waterline.
3. "At the part where the rapids start, you need rocks or something to explain why the rapids start." Fix: a line of
   half-sunk boulders across the river at the rapids' head (z ~ -497..-493, the RIVER table gives centre x ~199 and
   half width ~12 there) with a CLEAR CHANNEL >= 12 studs in the middle for the boat (rocks CanCollide false anyway),
   plus 4-5 smaller mid-stream rocks along the run; stagger the three foam layers' starts (56/44/32 studs) so the
   foam begins behind the rocks. `tools/falls_probe4.lua` (written, NOT yet run) lists boulder sources to clone
   (SandstoneClimb's SandBoulder parts, DomaineKit, Village.Props riverside rocks).
Then her verdict, then: boat autopilot + break-up at the lip, the parachute drop (kept-forever flag, steerable, beach
target = the cove's east shore), Captain-by-sea return, harbour quay/town, Italian planting, extend the sea, and a
waterfall sound (she picks the audio in the Toolbox, like the engine sound 15067494918).

## Other open items (ask her)
- Three white slabs in the sky seen from the harbour = Workspace.HatShop / DressShop / Bookshop interiors parked at
  y 300-400 over the village. Not mine to move without asking (raise them or hide behind cloud).
- Two faint grey marks on the sea's horizon from the lip = the sea terrain's far edge at z -1556 (extend with the harbour build).
- The long grass hillside beyond the arms reads dark (south-facing, in shadow); Hillside Town will reshape it.
- 6 trees sit on the rock's top strip up to 2.5 above the terrain beside them (same as before today).
- Was the v744 publish at 10:18 hers? (the boat is live for players; the gorge is not).

## Design constants (game coords: x east, y up, z north; downstream = -z)
ZC = -547.5 (the walls' last column = the brink line); corners x 169.4583 (W) / 201.2856 (E); CXE = 183.84;
WATER_Y = -0.9; SEA_Y = -52.9; PLAIN_Y = -48; Y_FOOT = -64; ARM_L = 130; COVE_A/L = 40/110; crest T0 = 40.72.
River centre/width upstream of the lip every 4 studs: `tools/river_table.lua.txt` (from gorge_shape.centre_x/half_width).
Generators: `italy/gorge_real/gorge_shape.py` (the whole shape incl. the falls section), `gen_gorge_real.py` (meshes,
preview), `make_south_lua.py` (the t10 terrain pass), `make_t2_lua.py` (t2/t5 passes), `render_gorge_real.py`
(Blender previews; GORGE_SUN=-0.3,-0.75,0.55 lights the south face; GORGE_HIDE=Falls,Mist,Foam renders dry).

## Driving Studio (what works)
- Put a script on the clipboard with `powershell -File tools\setclip.ps1 -Path <file>` (it first saves whatever of
  hers is on the clipboard into tools\clipboard_saves\, images as PNG). Then bring Studio to the front (SetForegroundWindow
  on RobloxStudioBeta as the LAST action of a PowerShell call), click the command bar input (~700,722 in the current
  layout), ctrl+a, ctrl+v, ctrl+Home, zoom to find the Run button (long scripts ~ (1314,642); 4-line ~ (1317,697);
  5-line ~ (1317,682); it moves with the panel layout — always zoom first), wait, read `print("QQ ...")` lines from the
  newest `%LOCALAPPDATA%\Roblox\logs\*Studio*.log`. Studio is windowed; the viewport is ~[298,208]-[1352,495] now.
- If she is using Studio (camera moves, selection boxes), STOP and ask; a `type` action pastes via the clipboard, so
  never setclip while a batch is typing.
- Camera: `tools/cam_save.lua` prints her camera; `tools/cam_restore_shannon2.lua` = her overhead view of the falls
  (Sep 30 22:20); `tools/gorge_camrestore.lua` = her original 12:13 view. Her clipboard at hand-off time =
  `tools/clipboard_saves/shannon_clipboard_20260930_224801.png` (restored).
- Views: `tools/gorge_view_*.lua` (o harbour, p lip, q boat, r geo, s side, t wide, u brink, v rapids, a-n older).
- Probes: gorge_check3 (walls), check4 (old headwall), check5/6 (cliff arms + lip), probe9-13, falls_probe1-4.

## Roblox lessons learned today (do not re-learn)
- Terrain: a full voxel cell's rendered surface reaches ~2 studs past its boundary (sideways too). Keep terrain
  >= 5.5 studs behind a mesh face; after any waterline/beach pass re-run the carve pass (t5) and the probe.
- Beams: width runs along the attachment's SecondaryAxis (Y), the curve along its Axis (X); no TextureOffset
  property; TextureSpeed is repeats/s (studs/s = speed x TextureLength); beams sort by their attachments' parent
  part. FLAT beams lying on terrain water are drawn UNDER the water when seen from above (ZOffset, height, facing
  and sort position do not help); camera-facing beams and particles draw after the water — so overhead foam comes
  from flat particles (Orientation VelocityPerpendicular), beams carry the low angles.
- A beam texture's alpha gaps let whatever is behind show (the river's teal end face) — use a plain (untextured)
  beam to cover solid areas. The gorge water sits in the walls' shadow: scene-lit things go navy; foam needs
  LightEmission ~0.4 / LightInfluence ~0.2. Particle Size keypoints over 10 are not needed; keep <= 10.
- Trees: NEVER use Model:GetPivot() for a kit clone's position (the pivot swung up to 150 studs away); use the parts'
  world aabb (gorge_trees1/2 do).
- Import 3D uploads an OBJ material's texture and puts the asset id in MeshPart.TextureID (identical images dedupe to
  the same id) — the way to get our own textures into the place.
- Baseplate (Union): SubtractAsync works (2.4 s); clone it to ServerStorage first; copy name/children/attributes.
- The hidden shop interiors float at y 300-400 over the village and show from any high or distant viewpoint.

## Pages (artifacts, for her review)
Falls page (preview + Studio shots + the water): https://claude.ai/artifact/G6ndq3Srm1yUcRrSTcvGy8
Gorge end (headwall era, superseded): 3d5cCon2KGNHUhzcEHZnpo. Step pages: PVRRjhQ9tRx5J9hfNEzpEf, 4WEzwkwrpRymSwwognr9wM,
PPGZdhwLdz9BUS8gbjG571. Build plan 62SbSofx2AikVKHCSSf1hq, layout KGbdkv3NE1mY3tij2LCzxV, reference board 8Qpp2yz2uEA5wBzPUC9aT6.

## UPDATE Sep 30 23:42 (next chat: read this block first; memory `new-maps-travel-plan.md` has the same in its last two entries)
Her three notes are DONE and approved, still NOT published, boat prompt still off, her camera restored (cam_restore_shannon4 =
her overhead of the rapids) and her clipboard image restored (clipboard_saves/shannon_clipboard_20260930_233142.png).
1. Lip sides: falls_fix1 (36 wide, centred on the corners' midpoint 185.37, roll at the water) - "fixed". Later superseded at
   the crest only by falls_plug2 (see 2).
2. Fall's bottom: the live Falls model = tools/falls_water3_v1.lua (4 ribbons, ragged bottoms, Body fading, Splash, FoamRing,
   MistBank2, foam starts 56/44/32) PLUS tools/falls_plug2.lua (crest 32 wide ending AT the corners + white-mint PlugE/PlugW
   4 wide beyond each corner). Any rebuild = run falls_water3_v1 THEN falls_plug2. Rejected by her: v2 (40-wide lip beams,
   "corners too neat") and v3 (strands + corner spray + edge mist, "that looks terrible"); kept as falls_water3_v3.* only.
   tools/falls_water3.lua currently IS v3 - do not run it. The teal sliver at the east corner was the crest's own teal top
   beyond the corner (not terrain water); measured by falls_probe7.
3. Rocks: tools/falls_rocks2.lua v2 (seed 11) -> workspace.SouthGorge.RapidsRocks, 20 forest-kit rocks (rock_big/rock_cluster
   meshes = the village river's FishRocks shapes, FishRocks grey), random layout, 13.4-stud boat lane (boat is 4.1 wide).
   Templates in workspace.ForestKit are Transparency 1: clones must set Transparency 0 (baked in). Approved: "good, keep them".
Page: https://claude.ai/artifact/G6ndq3Srm1yUcRrSTcvGy8 v8+ (newest shots at the top; page_patch.py + page_figs.py rebuild it).
New helpers: tools/studio_front.ps1 (bring Studio forward), tools/restoreclip_image.ps1 -Path <png>, cam_restore_shannon3/4,
gorge_view_w_lipclose / x_rapidshead / z_foot (good), gorge_view_y_runabove (BAD: inside the east rim).
Bash tool note: its eval wrapper breaks on apostrophes inside heredocs - write Lua/py files with the Write tool or a PowerShell
here-string. Run button: long (1316,642), 4-line (1317,698), 5-line (1316,688), 8-line (1316,653); command bar click (700,705).
Next (her list): boat autopilot + break-up at the lip, parachute drop, Captain-by-sea return, harbour quay/town, Italian planting,
extend the sea, waterfall sound (she picks the audio). Open: the fall still reads as one white column from the foot - if she
wants strands, mock it up (Blender or an A/B in Studio with her watching) rather than iterating live.

## UPDATE Oct 1 00:02: the fall is now CANDIDATE B (her pick after a live A/B) - read memory new-maps-travel-plan.md "FALL SETTLED"
Live: workspace.SouthGorge.FallsB (tools/falls_candB.lua; textures 117176915627441 strands / 93498154460566 wisps; width 31.6 top,
35 bottom; nothing past the corners) + the old Falls model keeps only the rapids (its fall part parked in
ServerStorage.GorgeBackup.FallsA_fallpart). East corner water pocket filled with Sandstone terrain (backup
GorgeBackup.CornerFillE_before, Region3int16 50..52/-4..0/-138..-135). Sill face SouthCliff_L01(+_Lo) tinted wet (attribute OrigColor;
falls_wetface_revert.lua). Rocks (RapidsRocks, 20 forest-kit, random) approved. Her camera restored (cam_restore_shannon4), her
clipboard image restored (clipboard_saves/shannon_clipboard_20260930_235213.png). Still not published; boat prompt off.
Rebuild recipe if ever needed: falls_water2/3 scripts are HISTORY now; run falls_candB.lua (needs the two texture ids, or re-import
italy/falls/falls2_carrier.obj) then falls_keepB.lua. Open: thin sliver of the roll's end at the top right from the low foot angle;
west corner pocket unfilled; her rapids reference (foam patches on dark water) not acted on yet.

## UPDATE Oct 1 00:24: lip corners + rapids done (memory new-maps-travel-plan.md "LIP + RAPIDS FIXED" has the detail)
- Lip: FallsB.Crest disabled (falls_topfix); strands/body curl from the surface; FallsB.LipPlate = an OPAQUE pale Part
  31.5 x 9 x 0.3 at z -548.9 hides the river's end face (terrain water paints over ANY beam, ordinary or FaceCamera - only
  opaque geometry or a matching colour hides it); Back top at z -549.5, LipStrands (FaceCamera, strand texture) in front.
- Corners: terrain fills UNDONE (pasted back from GorgeBackup.CornerFillE/W_before); workspace.SouthGorge.LipRocks =
  two SandCliffKit boulders (LipRockE/LipRockW) at the corners, CanCollide on; Rock_18/Rock_20 parked in
  GorgeBackup.RapidsRocks_removed.
- Rapids: 30 Rapids beams on the patchy foam texture rbxassetid://136006912117321 (italy/falls/falls2_foam.png), foam boxes rate 18.
- Her rule update: for fix-ups of something she flagged, just do it and show; ask only for new builds/publishes.
- Camera restored (cam_restore_shannon4); clipboard image restored (clipboard_saves/shannon_clipboard_20261001_001441.png).
- Rebuild recipe for the fall now: falls_candB.lua -> falls_keepB.lua -> falls_wetface.lua -> falls_topfix.lua ->
  falls_lipplate.lua -> falls_lipcover.lua is SUPERSEDED (lipplate removes LipCover; LipStrands stays) -> falls_cornerfix3.lua.

## UPDATE Oct 1 06:45: PUBLISHED v803 (her word). Boat reaches the brink and stops; falls sound in. NEXT BUILD = the going-over.
Her spec: "when the boat goes over the falls, it should eject the passenger and when the boat hits the water below, it should break
into many pieces." Pieces to touch: workspace.Boat.BoatServer (watchdog loop: detect hull z < -547.5 -> unseat the driver + throw
them forward, Move/AlignOrientation off, let it fall; on y < SEA_Y+1 spawn ~16 floating wood/army-green fragment parts + the bench
+ motor with random velocities, splash + sound, fade after ~15 s, then clear(p)), BoatClient (drop the -547.5 limit once the
autopilot takes over near the lip, or keep it and let the server take control in the last 10 studs), a "Welcome to Porto Nocciola"
note, the player swims to the cove's east shore (beach target zd 30..120 east of the axis). Play-test in Studio with API OFF.
Setup details of v803 are in memory new-maps-travel-plan.md "PUBLISHED v803".

## UPDATE Oct 1 07:40: the GOING-OVER is built and play-tested, installed in the shared place, NOT published (v804 live has the boat
stopping at the lip). Memory new-maps-travel-plan.md "GOING-OVER BUILT" has every detail: scripts tools/boat/BoatServer.server.v2.lua +
BoatClient.client.v2.lua, installer install_boat_i6.lua (v13), v1 backup in ServerStorage.GorgeBackup.BoatScripts_v1, the Studio
play-test harness (bt2_chute_srv / bt_jetty_take_cli / bt_lip_nochute), and the lessons (lift from hull mass; chute within 0.4 s;
pieces anchored, not physics). To publish: her word, then click the viewport + Alt+P. Page v13 has the play-test frames (go1..go6).
Still to do from her list: harbour quay/town, Italian planting, extend the sea, Captain-by-sea return; optional: parachute pack worn
always (not only in the boat), a splash sound at the crash, the west corner water pocket (never seen).

## UPDATE Oct 1 08:12: parachute gate done (v18 installed, NOT published): the Sky Diving Squirrel lends the pack after all 44 (Talk prompt,
line "I packed it myself", his sound), jetty note board, pack worn until it opens, never saved; canopy = rainbow gore petals (her reference).
Memory "PARACHUTE GATE" has it all. Publish = her word + Alt+P. Optional: a nicer squirrel sound id from her; splash sound at the crash.

## UPDATE Oct 1 08:45: v21 = steerable parachute + Studio-only "all 44" test script; Shannon testing herself; NOT published.
- Steering: BoatClient flyChute (tools/boat/BoatClient.client.v2.lua, spliced from flychute_v21.lua): ControlModule move vector
  relative to the camera (W into the screen, A/D sideways, S back, thumbstick), STEER 12 / DRIFT 4.5 / SINK 6, a steer toast when
  the canopy opens, "Dry feet! Welcome to Porto Nocciola!" on land. The installer is generated now: python build_install.py v21 "note".
- Test script: ServerScriptService.ZZ_TEST_Give44_DELETE_BEFORE_PUBLISH (install_give44.lua / remove_give44.lua): in Studio play
  tests every player gets Found_* 15/14/15, FoundIds all, SquirrelsFound 44 once SaveLoaded is set, re-asserted on any change; no
  DataStore. DELETE BEFORE PUBLISHING (run remove_give44.lua on the command bar, or delete it in the Explorer).
- Verified in one play test (bt_full_cli.lua, then hold W): HUD 44/44, chute handed over with the bubbles, boat at the brink, launch,
  dome-mesh canopy, W steered the player to the east grass, dry landing, camera back, no errors in the log.
- Her test: press Play; after ~6 s the HUD reads 44/44; the Sky Diving Squirrel in the forest, hold Talk; the jetty prompt; drive
  south with W to the brink; over the edge hold W (east shore) or A/D; the note on landing. Shift+F5 stops.
- Publish when she says: run remove_give44.lua, then click the viewport + Alt+P. Page v14 has the frames.
- Clipboard restored to her text 9120552550. Memory: new-maps-travel-plan.md "STEERABLE CHUTE + SELF-TEST SETUP".

## UPDATE Oct 1 09:35: v31 installed (NOT published): drawn speech bubble for the Sky Diving Squirrel, boat box fix, music off in the boat.
- Bubble = an image (italy/bubble/bubble_blob.png via gen_bubble.py; asset rbxassetid://98516368118872, uploaded with the Import 3D
  carrier bubble_carrier.obj): her reference shape (irregular white blob, thin brown outline, small tail), soft shadow copy, BuilderSans
  Medium 16 text, scale-in / fade-out, up-right of him, his Talk prompt hidden while he speaks. Code tools/boat/bubble_v31.lua.
- Boat: BoatServer watchdog BOX x limits from River.Line (the gorge bend at x 110 used to send the boat home). Music: take() sets
  NoMusic on the character; MapMusic.MusicClient (and boundary/build_music.lua) go quiet on it. Both verified in play.
- Installer generated by tools/boat/build_install.py VERSION "note"; test script ZZ_TEST_Give44 still in ServerScriptService (delete
  before publishing: tools/boat/remove_give44.lua). Memory new-maps-travel-plan.md "BUBBLE FINAL + TWO BUG FIXES" has every number.
- Pending her word: this bubble, and whether the croc praise + chase hint pills should switch to it. Clipboard restored to her
  reference image (clipboard_saves/shannon_clipboard_20261001_092324.png).

## UPDATE Oct 1 09:40: the owner never takes a Grand Keeper slot (tools/boat/champion_patch1.lua applied to Champion.ChampionServer;
builder village/build_champion.lua patched too; NOT published yet). crown() returns early for game.CreatorId and for ids in the
Champion folder attribute NoKeeperUserIds. Other players unchanged; her past wins stay in the hall. Verified in a play test.

## UPDATE Oct 1 09:50: bubble APPROVED as v32 (tools/boat/bubble_v32.lua): the blob image drawn flat in a ScreenGui pinned to the
squirrel (world-space GUIs get tone-mapped and looked cream), 12% smaller, faint shadow, BuilderSans Medium 15. Still NOT published;
the ZZ_TEST_Give44 script is still in ServerScriptService (remove before publishing). Open: switch the croc praise + chase hint
bubbles to this look (her word), the page frames for v32, then her publish word.

## UPDATE Oct 1 10:25: v37 installed (NOT published): olive tactical pack with orange trim, rider pose under the chute (through the rig
attachments - the joints are AnimationConstraints now, C0 is read only), boat notes 72 px from the top, river drift = leaf and twig
decals (assets 101757587087924 / 118085542281363; tools/river v27), the lip's angled sheet fixed (LipStrands.FaceCamera off, plate
tinted; tools/falls_lipfacecam1.lua). Memory new-maps-travel-plan.md "ROUND Oct 1 10:25" has the numbers. Still in: ZZ_TEST_Give44
(remove before publishing). Pending her word on the croc/chase bubbles and on publishing.

## PUBLISHED v829 Oct 1 10:54 (her word). Everything in this file since v804 is live, plus one bubble for every squirrel:
ReplicatedStorage.SquirrelBubble (tools/bubble/) used by BoatClient v38, CrocClient praiseBubble and ChaseClient speak (patched live and in
the builders). ZZ_TEST_Give44 removed before the publish. Her camera and clipboard restored. Memory new-maps-travel-plan.md "PUBLISHED v829".
