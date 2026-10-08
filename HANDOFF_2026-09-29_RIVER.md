# 1001 Squirrels: handoff (Sep 29, 2026, evening). Next up: the river build

## Where things stand
- **The game:** "1001 Squirrels" on Roblox, owned by Shannon.
  - Her account: Roblox user `oodlesofpoodlesyay`, display name **SelBell**, user id 9611145467.
  - IDs: place `117372258657114`, universe `10766369535`.
  - Team Create is on, and Drafts Mode is OFF, so script edits go straight into the shared place.
- **Live version: v705**, published Sep 30 at 00:18 UTC (8:18 PM EDT Sep 29). Nothing is waiting to be published.
- **Studio state when this was written:** the place is open in Edit mode and "Enable Studio Access to API Services" is OFF (checked on reopen). Shannon's clipboard has been restored.

### While Claude was paused (Sep 27–28), ChatGPT Codex rebuilt parts of the game
- **Published:** v668 through v702, directly in Studio.
- **Built or changed:**
  - the Passport, plus a wardrobe/suitcase inside it;
  - the Mode et Style boutique: dresses, eyewear and necklaces you can wear;
  - hat fitting: hair is hidden or trimmed under hats;
  - the portrait chair, with an 8-second timer, a reveal and outfit capture;
  - free bookshop books;
  - GUI changes and hang-glider fixes;
  - a Hall of Fame record fix.
- **Codex's own notes:** `HANDOFF_2026-09-27_PASSPORT.md`, `HANDOFF_2026-09-27_PASSPORT_V2.md` and `HANDOFF_2026-09-27_DRESS_SHOP.md` in this folder.
- **Codex's work files:** `C:\Users\slard\Documents\Codex\2026-09-27\hi\work\`.
- **Shannon's rule: keep everything Codex made.** The builders in `roblox-props` (build_glider, build_hatshop, build_portraits, the village builders and so on) are OUT OF DATE compared with the live place. **Never rerun them**, or they will wipe Codex's work. To change a live script:
  1. Dump its current source from the place. `tools/portraits/dump_gallery_scripts.lua` shows how: it prints every line as `QQ@Name|n|line`, and you rebuild the file from the Studio log.
  2. Patch it with exact-text anchors. `backups/portraits_optionC_2026-09-29/p10_patch.lua` is the pattern: it checks everything first, stops and changes nothing if any anchor is missing or appears twice, and records a ChangeHistory entry.

### What was done Sep 29 (live in v705)
- **Portraits** (`Workspace.PortraitGallery`: PortraitServer and PortraitClient; 9 easels by the river)
  - Shannon said they "didn't work". In fact they did.
    - A read-only look at the live `PortraitWall` DataStore showed her 4:59 PM phone sitting saved properly, and it was on easel 1.
    - What confused her: the gallery kept only one painting per person, so a new sitting replaced her old one instead of adding a canvas.
    - Her "side view that vanished" came from a Sep 28 sitting on an old v697 server.
  - **Option C, which she chose:** up to 3 paintings per person (the `PerSitter` attribute = 3); a 4th sitting takes down that person's oldest.
  - Each new painting gets an unused backdrop and companion "turn" (`variant`), so one person's paintings never look like copies. Entries without a variant keep their old look.
  - The reveal uses the same backdrop as the easel.
  - Tested in Studio, including shop outfits. Painting 1 wore a magician outfit, aviators and a top hat; painting 2 wore the Sage Petal dress, cat-eye glasses, pearls and a boater. Both carried over. Pictures are in `backups/portraits_optionC_2026-09-29/test_shots/`.
- **Text fixes:**
  - Store portrait row: "…sets you on an easel by the river – the nine newest stay, up to three of you." It fits in 2 lines, like the old text.
  - Passport: "A portrait costs 80 acorns".
  - Bookshop register screen: "Free to read". It still said 25 acorns.

## TONIGHT'S TASK: make the river real water with a slow one-way current
Shannon wants the river to be real water like the swamp, flowing slowly in one direction. Honest points already agreed with her:
- **Roblox Terrain water cannot really flow.** Fake it convincingly:
  1. a slowly scrolling ripple texture on the surface, laid in segments along the river so each scrolls downstream;
  2. leaves or petals drifting downstream (client side, along the river's centre line);
  3. a gentle push downstream when a player swims in it.
- **Flow direction:** toward the edge of town where the boats will eventually leave. **Show Shannon the direction on a top-down picture of the map BEFORE filling in any water.**
- **Depth:** make it deep enough for boats later, and swimmable.
- **Leave alone:** the bridge(s), the painter and his gallery by the river, the portrait chair, and anything else that touches the river.
- **Publish only on her word.**

### Known facts about the river (from Claude's memory notes, from before Codex)
- **It isn't terrain.** It's a mesh from `village/gen_village.py` (`river.obj`): a water MeshPart plus sand bank MeshParts `BankL`/`BankR`.
  - The mesh covers a winding area of about 1600 × 95 studs.
  - It imports mirrored and off-centre. At the bridge the centre line is x ≈ 155.5; the west sand runs x ~141.6–147.1 and the east sand x ~163.9–167.5.
- **Heights:** water top ≈ 0.15, bank top ≈ 0.25, the Street 0.30, and the ground is Baseplate grass at about 0.
  - The banks use `PreciseConvexDecomposition` collision. With default collision, players floated.
- **Nearby paths:** an arched bridge crosses between the Walkway (x 110–144) and the Street (x 170–350).
- **The painter's gallery** is by the river: seat (194.5, 1.8, -17.8), easels at x 189–217, z -4 to -15, painter squirrel near (187, -20).
- **How the swamp did it:** `forest/build_lagoon.lua` built the Lagoon (x 89–139, z -208 to -152).
  - The ground was one Part, so a hole was cut into it (a union) and Terrain was written with `WriteVoxelChannels` (solid + LiquidOccupancy), water at y -1.
  - The river will probably need the same idea: cut a channel in the ground Part(s) along the river, or swap a wide strip of ground for terrain, then fill a bed and water.
- **Boundary:** invisible walls plus dressed edges from `boundary/build_boundary.lua`.
- **Check first, read-only, in Studio:**
  - the river parts: names, sizes, positions, and the path of the centre line;
  - the ground part(s) under the river;
  - what touches the river (bridge, mill ride, zipline, gallery, docks);
  - where the river crosses the boundary walls.

  Then propose the plan and the flow direction to Shannon with a picture, before changing anything.

### Survey results (Sep 29 evening, read-only; nothing changed in the place)
- Scripts, output and the picture are in `tools/river/`: `survey_river.lua` -> `survey_out.txt`, `cam_topdown3.lua`, `rim_walls.lua`, `draw_flow.py` -> `river_flow_proposal.png`, and `cam_restore.lua`, which puts back her editor camera.
- **The live river** is `Workspace.Village.Props.river`, made of three MeshParts: Water, BankL and BankR.
  - It is 1600 studs long, running along z from -920 to +680, and winds on a regular S-curve.
  - It sits ON TOP of the Baseplate, a 2048-stud slab whose top is y 0. The water top is at y ~0.1 and the sand at ~0.2.
  - `VillageKit.river` is only the invisible kit stencil, so leave it alone.
- **Inside the map** the river is only about 210 studs long, between the village rim walls at z -205 (south) and z +5 (north).
  - From z -190 to -46 the water runs straight at x 148–164, with sand at 142–147 and 164–169.
  - It then bends east past the painter and the spawn, reaching water x ~180–200 by z +14.
  - The rest of the mesh runs out into empty space past both rim walls.
- **Things touching it:** the bridge (centre 156,-120, 30×8); the fishing squirrel (165.6,-55); spy_squirrel (166.6,-114.5); the DailyQuestion board (168,-135); the Boundary gate sign (142,-128..-113); the riverside rock and bush props; and the 46 "Opens" divide walls along x 142.
- **Under the river** is nearly all Baseplate. Near the east bank there are Village.Ground PlotN, PlotS and Street, from x ~170.
- **Proposed to Shannon:** a current flowing NORTH to SOUTH, entering behind the painter and leaving through the south rim toward a future gorge/boat route. The reverse was offered too. WAITING FOR HER PICK.

### BUILT Sep 29 evening (in Studio, NOT published)
Shannon picked a north-to-south current. Every script is in `tools/river/`, and each run was checked by line 1's vN tag.

**The channel (v7, then v10)**
- The Baseplate union is cut along the whole 1600-stud river.
- The ORIGINAL (the lagoon union with no channel) is kept in `ServerStorage.RiverBackup.Baseplate`.
- The live Baseplate has the attribute `RiverChannel = "v10 banks"`.

**The river mesh**
- `Village.Props.river` Water, BankL and BankR are HIDDEN: Transparency 1, no collision. Each keeps an `OldTransparency` attribute.

**The terrain (`build_banks30.lua` is the current one; it does not re-cut)**
- Water sits at y -0.9. The bed is about 6 deep in the middle.
- The banks wander (a noise wobble of ±1.5), with three kinds: grassy slope, pebble beach, and short steep earth bank.
- Mud at the waterline, and islets under the rocks and bushes that stand in the water.
- "Pads" keep level ground under anything that stands near the edge.
- Along the lagoon, the west bank stays narrow and the lagoon's own cells are not touched.

**TERRAIN TRAP (measured, `calib_write.lua` + `calib_measure.lua`)**
- A solid surface draws at **cell centre + 4 × occupancy**, not at the cell bottom + 4 × occupancy. Write `occ = (h - (yb + 2)) / 4`.
- Liquid is linear: `lq = (WATER_Y - yb) / 4`.
- Fill water under the banks too. The solid hides it, and it stops raised water edges.
- `ReadVoxelChannels` returns a `Size` field. Never write that table back as it is: name the channels.

**The quay**
- The village side along the plots (z -171..-69) is a stone quay, `workspace.River.Quay`: a cobblestone wall face at x 163.9, a limestone kerb, and no kerb under the bridge deck (z -125..-115).
- The ground under the paving there is set low (-1.5), so it never pokes through.

**The current: `StarterPlayerScripts.RiverCurrent` (LocalScript)**
- It reads `workspace.River`:
  - `Line`: the centre line, downstream order, z 80 → -300;
  - `WaterY`;
  - `FlowSpeed` 2.6, `PushSpeed` 4, `PushAccel` 14.
- 28 leaves and petals plus 26 faint streaks drift downstream (the stretch z 60..-250).
- Swimmers get a nudge downstream.
- Tested in Play at `PushAccel` 6: the swimmer drifted about 0.5 studs/s south. It was then raised to 14, which is NOT re-tested.
- Installer: `install_current.lua`, the v26 run.

**Test tip:** a drop into the river needs the gates open (`Found_forest` / `Found_village` = 15 on the test player).

**Round 2 (Shannon's six close-ups, Sep 29 ~22:10 EDT). All fixed in Studio, NOT published.**
- **Current scripts:**
  - `build_banks39.lua` is the current bank builder. It checks `RiverChannel = "v31 lip"`.
  - `build_banks31.lua` holds the cut code. The channel is now cut per side, only to each bank's lip + 1, from `RiverBackup.Baseplate`.
  - `settle_props.lua` (v37) lowers things that float, only downward. Use `settle_dry.lua` to report first.
- **Terrain trap 2:** terrain smooths each 4-stud cell with its neighbours, so small raised patches and islets vanish or sit lower than written.
  - Fix: write the terrain, raycast every column's centre, correct, and repeat 5 rounds (v34+). The mean error goes from 0.55 to 0.30.
  - The pads ("level ground") must use only the parts that really stand on the ground: underside < 0.7 and within 0.35 of their model's lowest part. Otherwise a canvas on an easel lifts the ground by a stud.
- **Results:**
  - The kerb now runs under the bridge.
  - The rock islet sits just above the waterline, and the rocks were lowered onto it.
  - The fishing squirrel, painter, easel, tourist and a couple of bushes were settled by 0.1 to 0.9.
  - The gallery easels stand on grass with the water edge pushed back.
- **Clipboard:** her clipboard was an image, restored from `clipboard_saves/shannon_clipboard_20260929_220046.png`.

**Round 3 (Sep 29 ~22:55 EDT, NOT published).** `build_banks59.lua` is the current builder; it checks `RiverChannel = "v52 wide"`. `build_banks52.lua` holds the latest cut.
- **ONE GROUND:** terrain grass (6,978 columns) now covers the whole map (x -136..712, z -260..40) at y 0.08, wherever there was no terrain yet. There is no Baseplate/terrain seam anywhere inside the map.
  - Runtime scripts that name the Baseplate (Croc, Domaine, Tractor) only use it as a ground list, so this is safe.
- **PEBBLE IS NOT A TERRAIN MATERIAL.** Roblox silently stores it as Grass, and that caused the "pure green to the water" look. The beaches are Sand now.
- **Banks:** wet Mud within 1.5 studs of the water, then Sand (Ground on steep banks) out to 6 studs, which is wide enough to show in 4-stud cells, then Grass. The level-ground pads keep the band's material.
- **The channel** is re-cut to each bank's lip + 6 (lip + 1 beside the lagoon), so near the river everything is terrain.
- **Quay ends:** the east bank swings out to meet the wall face over 16 studs, as earth.
- **Keep-out:** a wider level zone (3.5 flat) round the painter, his easel and the PortraitGallery, which pushes the water's edge back. Nothing was moved.
- **The fishing squirrel** stands on `workspace.River.FishRocks`: a sunk boulder, a rock in the water and a small side rock (`fish_rocks.lua` v48). He was set on the boulder by his real underside.
- **Rock islets** sit at WATER_Y - 0.35, so the rocks rise out of the water.
- **Settle (v45)** counts `workspace.River` parts as ground.
- **Clipboard:** her clipboard was an image, restored from `clipboard_saves/shannon_clipboard_20260929_222607.png`.

**Round 4 (Sep 29 ~23:10 EDT, NOT published).** `build_banks60.lua` is the current builder; it checks `RiverChannel = "v52 wide"`.
- **Ground under the paving:** the ground now sits flush under ALL paving (Village.Ground slabs + Walkway) at the slab's underside - 0.1, including along the quay, so there are no gaps under the slab ends.
  - Along the quay, that ground is never spread in front of the wall.
- **Gallery:** the level keep-zone round the painter, easel and PortraitGallery is 6 studs flat, so the water stays well back. Ground raised from where the water was is Sand.
- **Clipboard:** restored from `clipboard_saves/shannon_clipboard_20260929_230643.png`.

**Round 5 (Sep 29 ~23:17 EDT, NOT published):**
- She said the shore looks OK.
- The "Rue de Noisette" sign (the Model `...Boundary.Gates.SignVillage`) moved 3 studs west (-x), away from the bridge: its bbox centre went from 137.7,-128.5 to 134.7,-128.5 (`move_sign.lua` v63). Note: `workspace.Boundary` finds a different folder, so find the sign by name.
- **Clipboard:** restored from `clipboard_saves/shannon_clipboard_20260929_231617.png`.

**PUBLISHED v723 (Sep 30 03:25 UTC = 11:25 PM EDT Sep 29), on Shannon's word.** It includes everything above plus:
- **The bridge gate** (`...Gates.VillageGate`) moved 4 studs west onto land (bbox centre now 137.6,-120).
- **Its two Posts** were stretched down into the ground (`move_gate.lua` v65). The leaf Uprights were restored (v66).
- **The sign** moved 3 more studs west, to x ~131.7.

Checks:
- **Swim test** (Play, API off) at PushAccel 14: the swimmer drifts about 1.0 stud/s south, and can still swim upstream. 54 drifters were running.
- **API access** was switched ON to publish, then OFF and saved. On reopening the dialog it was still OFF.
- **Clipboard:** her clipboard image was restored from `clipboard_saves/shannon_clipboard_20260929_232002.png`.
- **Live servers** keep the old version until they empty, so she needs to rejoin.

**After v723 (Sep 29 ~23:35 EDT, in Studio, NOT published yet):** a forest-side quay by the bridge.
- `build_banks67.lua` is now the current builder.
- The west bank for z -132..-108 is kind "quayW".
- The wall face is at x 144.3: `River.Quay` WallW, KerbW ×2 (not under the deck, z -125..-115), WallEndWS/WN.
- Grass stays behind the wall; the walkway ends at the wall.
- The bank transitions back to natural over 16 studs.
- **Clipboard:** restored from `clipboard_saves/shannon_clipboard_20260929_233153.png`.

**Forest-quay fixes (Sep 29 ~23:45 EDT, Studio only, NOT published).** `build_banks73.lua` is now the current builder.
- **Grass came up through the walkway:** the correction rounds were overshooting. Now, any column under a Village.Ground slab is capped at the slab top - 0.35, and its H may rise at most 0.1 above target.
- **KerbW** is a top edge (0.2..0.75), plus a KerbSkirtW on the land side only (x 142.6..143.05, down to -1). The forest side sees only white; the water sees the stone wall under the white top.
- **CapW:** a thin white capstone under the deck, 0.0..0.32, measured to sit just under the planks.
- **Clipboard:** restored from `clipboard_saves/shannon_clipboard_20260929_233909.png`.

**Kerbs to the bridge + solid sign (Sep 29 ~23:49 EDT, Studio only, NOT published).** `build_banks76.lua` is now the current builder.
- The forest KerbW/KerbSkirtW now end exactly at the measured deck sides (z -124.0 / -116.0). CapW spans only under the deck.
- The Rue de Noisette sign parts are CanCollide = true (5 parts), set in `kerb_to_bridge.lua` v75. A rebuild does not touch the sign.
- **Clipboard:** restored from `clipboard_saves/shannon_clipboard_20260929_234735.png`.

**PUBLISHED v726 (Sep 30 03:52 UTC = 11:52 PM EDT Sep 29), on Shannon's word ("perfect! Please publish").**
- It includes the forest-side quay, the capstone, kerbs to the deck sides, the walkway grass fix and the solid sign.
- API access was switched ON to publish, then OFF and saved. It was still OFF on reopening the dialog.
- Nothing is unpublished now.

**Open with Shannon**
- Which sign to move "in front of the post": the Rue de Noisette sign by the forest walkway, or the Daily Question board by the quay?
- Publishing, only on her word.

## The whole plan (agreed with Shannon Sep 29)
1. **The river:** real water with a slow current (tonight).
2. **The edge of the map:** today there is open, empty space outside the build area. Ring the map with hills, forest and a hazy distance. The river leaves through a gorge, and the road leaves through a pass or tunnel, so the exits feel like real routes out of town.
3. **Boat dock and boat ride:** the boat goes down the river, out of town, through a transition, to **an Italian fishing river on the coast** (map 2).
4. **Taxi stand and taxi ride:** the taxi drives a road out of town to an **airport front**: terminal, control tower and runway lights. **Do NOT build an airplane.** Then comes a **flight transition screen** (clouds passing a plane window, a map line from France to Japan), and the player arrives in **Japan** (map 3).
5. **The Italy map.**
6. **The Japan map.**
- **Unlocking:** both the boat and the taxi unlock only after a player has found all 44 squirrels. The player picks one route or the other. Before that, show a friendly note like "Find all 44 squirrels to set sail" or "…to hail a taxi".
- **Where the new maps go:** build them as **new areas inside this same place**, not separate places. That way acorns, the passport, the shops and saving all keep working. StreamingEnabled is on, so phones only load what's near them.
- **Expectations:** each new map is a big build. Start with an arrival area that grows over time.

## Studio workflow that works now
- **Computer-use access:** Studio updates change the exe path, so ask for `request_access(["Roblox Studio"])` again after an update.
  - Studio and the Roblox player usually sit on display **"XV270 X1 (2)"**. Use `switch_display`.
  - Shannon plays on this same PC. **Take a screenshot to confirm Studio is in front before clicking.** If she's in the game, don't take over the mouse.
- **Command bar:**
  1. Run `powershell -File tools/setclip.ps1 -Path <script>`. It keeps her clipboard first, now in `tools/clipboard_saves/`.
  2. Click in the command bar, then Ctrl+A, Ctrl+V, Ctrl+Home.
  3. Zoom in and check that line 1 shows the script's `-- vN` tag.
  4. Click **Run**, at the right end of the command bar. Its height (and the Run button) moves with the text, so take a screenshot first.
  - Studio sometimes overwrites the clipboard. If a paste shows old text, check `Get-Clipboard` and set it again.
  - Restore her clipboard at the end, from `tools/clipboard_saves/shannon_clipboard.txt` or the newest timestamped file.
- **Output:** print or warn lines starting with `QQ`, and read them from the newest `%LOCALAPPDATA%\Roblox\logs\*Studio*.log`.
- **Play tests:**
  - Keep API access OFF.
  - The Client and Server tabs sit above the viewport.
  - Open the area gates by setting `Found_forest` / `Found_village` to the totals from `workspace.SquirrelScripts.SquirrelRegistry`.
  - Acorns in Studio are never saved.
- **Faking an item in a test:** fire `ReplicatedStorage.AwardItems:Fire(player, "<item>", n)` to set `Item_<item>` attributes. The shops redress the character when `Item_dress_*`, `Item_dresswear_*`, `Item_hat_*` or `Item_hatwear_*` change.
- **Testing DataStore scripts safely:** in the Play copy only, disable the script, splice a mock `store` into its Source (`tools/portraits/test_liveList_srv.lua`), and re-enable it.
- **Checking the live game:**
  - This PC's Roblox Player logs (`%LOCALAPPDATA%\Roblox\logs\*Player*.log`) record each live join: `Server Prefix …_<server start UTC>_RCC` tells you which server and version, and they include client prints.
  - The in-game Developer Console (F9, Server tab) shows server output to the owner.
  - The Roblox UI needs slow clicks: mouse down, wait 0.15 s, mouse up.
- **Publishing (only on Shannon's word):**
  1. Stop Play.
  2. File > Experience Settings > Security: turn "Enable Studio Access to API Services" ON and Save. Save again if Roblox returns a 500 error.
  3. File > Publish to Roblox. The Output should say `Add publish notes to vNNN` and `Published new changes…`.
  4. Turn the setting OFF, Save, then reopen the dialog to check it stayed off.
  - Servers that are already running keep the old version until they empty. Tell Shannon to rejoin.

## Standing rules
- **Save data:** never write to Shannon's real save data. She plays the live game. API access stays OFF in Play tests. A read-only look at a DataStore with API access on briefly is allowed; turn it off after and check on reopen.
- **Publish only** when Shannon says so.
- **Ideas first:** give honest feedback on a new idea before building it.
- **Keep Codex's work.** Change only what she asks for.
- **Phones:** nothing may overlap. Check with the Device Simulator or measure. No pulsing animations; text must stay crisp.
- **New maps** should be detailed and finished the first time. No bedrooms or bathrooms in interiors.
- **Credits:** she's watching usage. Keep steps lean, and at a natural stopping point save notes so a later chat can continue.

## Files
- `backups/portraits_optionC_2026-09-29/`: the live scripts before Sep 29 (PortraitServer and PortraitClient, ShopClient, Passport Catalogue), the patch, and test pictures.
- `backups/autorecovery_2026-09-28/`: Team Create auto-recovery files from Sep 28. The recovery prompt was ignored.
- `tools/portraits/`: gallery dump, read-only PortraitWall lookup, test harnesses, camera helper and edit-mode check.
- `HANDOFF_2026-09-27.md`: the pre-Codex handoff, covering the glider, lift, climb, hat store and older workflow.
- **Claude's memory:** `C:\Users\slard\.claude\projects\C--Users-slard\memory\`
  - `codex-era-1001-squirrels.md`: this era;
  - `chasing-rainbows-squirrels.md`: the full history of the game.

## Starter prompt for the new chat
> Please read C:\Users\slard\roblox-props\HANDOFF_2026-09-29_RIVER.md and start tonight's task: turning the river in 1001 Squirrels into real water with a slow one-way current. Check how the river is built first, then show me the flow direction on the map before you change anything.
