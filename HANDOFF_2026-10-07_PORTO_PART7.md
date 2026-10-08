# Handoff: Porto Nocciola, part 7 (written Oct 5 2026, ~23:45 EDT, for Wednesday Oct 7)

**Starter prompt for the new chat:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-07_PORTO_PART7.md and continue 1001 Squirrels. Check weekly usage first. Ask me before every Studio edit (fixes of something I just flagged: just do them and show me).

## READ FIRST (added Oct 6)
Shannon kept building squirrels with Google Antigravity until the reset. Before anything else, read the LOG at the bottom of HANDOFF_2026-10-06_ANTIGRAVITY_SQUIRRELS.md: the place may have new/remade squirrels and a newer live version than v1085. Re-check the live version and registry count before trusting anything below.

## Where things stand
- **Live: v1085** (published Oct 5 ~23:39 EDT). Nothing unpublished.
- Weekly usage at handoff: 67% (her rule: stop at 70%; the week resets Wed Oct 7 ~07:00 EDT). Check with mcp__ccd_session_mgmt__get_usage.
- Full log of Oct 5: HANDOFF_2026-10-05_PORTO_PART6.md (PROGRESS section at the end, every script and number).
- Picture page for the promenade work: https://claude.ai/artifact/YSbsn4xrathGudHtQj7AJo (source + images in roblox-props/italy/promenade/). Make a new page for new work.

## Done on Oct 5 (all live)
- **v1080, promenade +10 studs** (her picks: +10, wall into the water with a sandy foot): the curved quay wall, paving, foundations, bollards, edge lanterns, north bench, both net racks went 10 out to sea. The fish stall (with the Fish Market Squirrel), two lanterns and the Bottega bench went 5 out. Both piers and all four boats (Rosina, Stella Marina, Azzurra, La Limonaia, with their ropes and squirrels) went 10 out, so the piers keep their full length. Also: solid ground under the new strip, a sandy foot along the wall (none beside piers/boats), a grass bank at the north corner, the south corner standing in the water beside the beach, the old foundations copied back under the old paving line (solid ends), AlleyCrates back in their alley, the crab SellSpot moved with Beppe, and 49 world-position attributes shifted with their owners (aquarium fish RestCFrame, drying-net fish).
- **v1085, her follow-up flags:** the lamp in front of ALL THINGS BELLA removed (in storage). The BELLA lemon tree is now in the Bottega/BELLA alley, a little way in and clear of the Bottega wall (Terracotta planter at 262.3,-46.1,-664.6; she said "that looks perfect"). The little decorative tide pool by the Sentiero del Faro path wall removed (in storage). Rock filled in under the upper flight of the Sentiero del Faro stair (its stepped underside used to hang over a dark gap seen from the Cala della Sabbia tide pools) and carried down into the sea.

## Next (her list)
1. **Remakes:** Gino the Deck Hand (deckhand_squirrel, now in the Stella Marina at about 212.4,-52.5,-646.2) and the Net Mender (netmender_squirrel, 262.4,-46.8,-691.6). She sends the Meshy zips. Pipeline: PART5 "The remake pipeline" + tools/remake/make_swap.py. NOTE: Gino moved 10 out with his boat, so take his feet position from the live model, not from make_swap's built-in old centre.
2. **Keep as they are:** Customs Officer, Conductor, Tightrope Walker, the ORIGINAL Boat Captain.
3. **Ideas backlog** (end of PART5): sea-glass + shell crafting game for ALL THINGS BELLA, whale in the distance, evil squid in the cave holding 3 young squirrels (rescue game), scooter race, fountain modes, pogo stick race.
   - **NEW Oct 6 (her idea): the PARFUM LOOP across maps.** Make a parfum bottle at ALL THINGS BELLA (Porto), carry it home to France, collect lavender (Château de l'Acorn field) + something grown in the garden (watering-can beds), make the parfum in a shop and fill the bottle. She asked what I think; I said yes and suggested building on what exists (distiller's hut with copper still in the lavender field, the PARFUMERIE sign on Rue de Noisette, the garden's flower bed, the beehives, the BELLA lemon tree as an Italian citrus note). Open questions to her: where the parfum is made, what the finished parfum does, and whether it goes before or after the remakes. Needs a save field for the bottle/ingredients (careful, API off, never her DataStore). Show a picture/plan page before building.
   - **NEW Oct 6 (her idea): MESSAGE IN A BOTTLE.** Like the La Poste mailbox (letters to "the mayor", PostClient/PostServer), but at a bottle stand on a Porto beach: send a bottle out to sea, and the next day a bottle washes up with an automated, random, funny reply; bottles can also be found on the beach. My suggestions to her: fill-in-the-blank message cards (no typing on phones, no player text to filter, and replies can answer what they picked) with free typing as an option; a big hand-written bank of reply pieces signed by sea characters (lighthouse keeper, crab, whale, the evil squid, a squirrel in Japan = teasers for later builds); "next day" tied to the existing Daily reset; one bottle a day; collected bottles kept in a Passport page; save fields done carefully (API off, never her DataStore) + a Studio time-skip for testing. Open questions to her: cards or free typing, which beach + stand keeper squirrel, random beach finds too, reward.
     **HER ANSWERS (Oct 6):** (1) fill-in-the-blank YES, but the PLAYER is not stranded: they send a note TO someone who is stranded, or just send it out somewhere; (2) beach + stand keeper: TBD; (3) yes, random bottles with silly messages wash up too, but the point of sending your own is that the reply relates to what you sent; (4) no reward, just the fun of it. Next step: draft card templates + reply bank for her to review (page), before any build.
4. **VR note (Oct 6):** VR is ON and she says the game works really well on a headset. Only drawback: the squirrel dialogue (SquirrelBubble, a screen-layer UI) and the race timers only show when the Roblox VR control panel is up. Possible fix to offer: for VR players (VRService.VREnabled), show the bubble/timer as 3D world UI (BillboardGui/SurfaceGui) instead of ScreenGui. Ask before building.
5. Possible polish she may raise: the new rock under the lighthouse stair is chunky beside the Crab Catcher (305.6,-805.5); I offered a smaller one or a grassy top.

## Undo kit (only if she asks)
- ServerStorage.PromenadeBackup: clones of everything moved, the Removed folder (BELLA lamp, the 13 tide-pool parts), and terrain backups TerrainBefore (corner 51,-18,-179), TerrainStairBefore (74,-16,-203) and TerrainStairBefore2 (75,-16,-210). Restore terrain with Terrain:PasteRegion(region, Vector3int16 corner, true).
- tools/italy_squirrels/revert_promenade1.lua restores PromOldCF/PromOldSize/PromOldPivot/PromOld_<attr> and removes PromenadeFill copies.

## Lessons from Oct 5 (keep)
- **The auto-mode classifier** blocks running even read-only probes in her shared place until she says "yes, run" or gives an explicit OK. Writing a build script for an unconfirmed change was blocked too. Get a clear yes first.
- **When you move anything, also shift its CFrame/Vector3 attributes.** Scripts use them at runtime: the aquarium fish snap to RestCFrame (StarterPlayerScripts.PortoMarketAquariumMotion), and the drying-net fish use tie points. Scan for attributes with |position| > 150. Also check for helper parts outside the model, like CrabGame.SellSpot next to Beppe.
- **Moving a whole model drags along everything inside it.** The fish market model held the alley crates. Check the model's bounding box before moving it.
- **FillBlock never replaces full Water cells.** It leaves a shelf of land over water. To put land into the sea, use ReadVoxels/WriteVoxels: either set the cells directly, or after a fill, turn the water/air under land cells into that land's material ("close under").
- **Thin terrain at the waterline:** occupancy below 0.5 renders as separate blobs. A sandy foot needs about 0.62 in the cell under the wall face and the next one out, or a water seam shows.
- **Straight-down camera shots:** set workspace.CurrentCamera.CameraType = Scriptable first (otherwise Studio ignores the roll), and set it back to Fixed afterwards. The helper `_G.cv(x,y,z, tx,ty,tz, fov)` was defined in the command bar (Scriptable + lookAt). Redefine it if Studio was restarted.
- **Photo mocks for plans:** tools/italy_squirrels/mock8.py / mock10.py / annotate*.py (zone shifts on a top-down capture). She liked having a NOW vs PLAN page before building.
- She can't see SendUserFile images; use the artifact page.

## Roblox Studio MCP (added to the plan Oct 6)
Shannon showed the Studio MCP connector: `claude mcp add --transport stdio Roblox_Studio -- "cmd.exe" "/c" "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"`. If Roblox_Studio tools exist in the new chat, use them to run scripts and read output instead of the click-and-type route below (still ask her before every edit). Keep the click route as a fallback.

## How to drive Studio (layout as of Oct 5 night; Studio windowed on monitor "XV270 X1 (2)", frame 1456x819)
- `powershell -ExecutionPolicy Bypass -File tools/studio_front.ps1` first (the desktop sometimes steals focus).
- Scripts: write .lua with the Write tool, then `python tools/italy_squirrels/pack.py X.lua x.rbxmx NAME`. Then File (96,118), zoom to confirm the menu, Import Roblox Model (143,247), zoom to confirm the dialog, file box (500,468), type the name, Enter. Then the command bar (670,746): ctrl+a, type `local m=workspace:FindFirstChild('NAME',true) require(m.PatchModule)() m:Destroy()` in chunks of 15 characters or fewer, zoom to check, Run (1328,746). Read `warn` lines from the newest %LOCALAPPDATA%\Roblox\logs\*Studio*_last.log.
- Short one-off commands can be typed straight into the command bar (same chunking).
- Viewport capture: zoom region [84,218,1356,556] with save_to_disk.
- Publish: check the log for StopPlaySolo (no play test running), click the title (700,99), Alt+P, then confirm "Published new changes" and "Add publish notes to vNNNN" in the log.
- Pre-publish check: tools/italy_squirrels/probe_prepublish.lua (BeppeCrate expected x 248.4 since the promenade build).

## Her rules (keep)
- Ask before every Studio edit; flagged fixes: just do + show. Publish only on her word. Never write her DataStore; API access stays OFF for play tests.
- Every squirrel speaks through ReplicatedStorage.SquirrelBubble. No acorn joke in every bio. Phones: no UI overlaps.
- New builds detailed and finished first time; show pictures (artifact page) before building big things.
- Stop at 70% weekly usage (rest saved for Ethan).
