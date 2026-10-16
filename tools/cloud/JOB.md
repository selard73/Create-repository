# Jobs 7, 8 and 9, in this order. Ask Shannon before each Studio edit; send each result to the cloud session
# "Cloud session handoff" as ONE message per job (every Output line with the job's QQ tag, unchanged).

## Job 7: phone check of the camera (a play test in the Device Simulator; nothing edited unless Shannon says so)

Shannon, Oct 9, after today's publish: on the phone "it says my camera is equipped but it does not show at the bottom
of the screen like it did before" / "the camera is not even there". On desktop the camera works (she took a photo today).

1. Device Simulator ON (her usual phone preset, 667x375 or similar). Studio in Edit mode first.
2. Play test as the owner (Play, not Run). Wait for the game to load; go to Porto if needed.
3. Try to equip the camera from the game's own hotbar at the bottom (ShopClient HOTBAR) and from the backpack.
   With a screen capture of each: is the camera slot in the hotbar at all? does equipping show the "Tap to raise the
   camera" toast? does tapping raise the lens? does the "Postcards wanted" panel appear?
4. Read the Output / client log for every error or warning from CameraClient, ShopClient, StowServer, or anything
   mentioning "Camera". Copy the first error in full (message + script + line).
5. Stop the play test. Studio back in Edit mode, Device Simulator back as it was.
6. Send: the answers to step 3, the errors from step 4 verbatim, the capture paths.
7. ONLY IF CameraClient itself errors at load or on equip: tell Shannon; with her yes restore it
   (CameraClient.Source = ServerStorage.HudBackup.CameraClient_v3_pre_vraim.Source), repeat 2-5, send that too,
   and SKIP job 8 (its guard will refuse anyway). Do not publish.

## Job 8: camera patch 2, VR zoom + photos with ground, sea and the whale (Studio EDIT; ask Shannon first)

Shannon: VR "does not allow to zoom out or zoom in, make the right controller stick for zoom"; photos "only picking
up certain things ... not the whale or the ocean ... not the beach". Terrain can't be copied into a photo, so the
patch stands it in with tiles coloured like the ground/sea; far subjects (the whale) are gathered from a box along
the line of sight; right stick up/down zooms the VR shot with a floating square viewfinder sized to the shot.
Desktop and phone photos get the ground/sea tiles too; nothing else changes there.

1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/camera/vrzoom_patch.lua
   Six exact-string replacements on workspace.PhotoGame.CameraClient.Source. It refuses to run unless the Source is
   the job 6 text (60574 chars) and every find matches once; compiles the result before writing; original to
   ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom. Reference, the patched script (byte-identical to the result):
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/italy/camera/CameraClient_v3.lua
2. Tell Shannon what it changes; wait for her yes. Run it (Edit mode, execute_luau). Send the `QQ VRZ` line.
3. Then a quick desktop play test is welcome if Shannon wants one: take a "view" photo of the sea from the quay and
   check the polaroid shows water; stop the play test. No publish; Shannon does that.

## Job 9: seat the floating squirrels (DRY first, then Studio EDIT with Shannon's yes)

Shannon: "the diver squirrel is floating, his feet are not on the surface of the ground" (the Snorkel Squirrel on
the sand spit, moved Oct 8; others may be too).

1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/squirrels/seat_squirrels1.lua
2. Run it as is (DRY = true, ONLY = nil): it lists every squirrel model in Porto (tagged "Squirrel" or named
   *squirrel*) with the gap between its feet and the ground below. Send the `QQ SEAT` lines.
3. Show Shannon the FLOATING ones (gap > 0.15). She names the ones to seat (the diver / snorkel squirrel for sure).
   For each: set `DRY = false` and `ONLY = "<part of its name, lower-case>"`, run, send the `QQ SEAT` lines.
   Each moved model gets attr SeatOct9OrigCF (its pivot before). No publish.

## Job 10: the town-wide floor cut (Studio EDIT, big: up to ~900 floor parts; Shannon said yes in the cloud thread, ask her again here)

Same method as the square (jobs 3-4), floors only (paving, foundations, footings, landings, stairs, thresholds, quays,
promenade, floors); roofs, walls, rocks, the fountain, boats, cars, gates and terrain are never touched. Originals go to
ServerStorage.CSGBackup_Town; every union carries CSGJob = "town1"; town_undo1.lua walks every pass back.

1. Fetch and read both:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/town_fix1.lua
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/town_undo1.lua
   (town_fix1 changed since job 5: box from x 200, floor-only lowers, gentler tilted cutters, hidden parts retired whole,
   no re-cutting on reruns, ids with seconds.)
2. Run town_fix1 once as is (DRY = true): the fresh plan. Send the `QQ TWN` lines. Tell Shannon the counts and wait for her yes.
3. With her yes: set `DRY = false`, run. It cuts up to 600 parts within a 240 s budget, then re-surveys. Send the `QQ TWN` lines.
4. If the CUTS line says fewer were done than planned, run again (same settings) for the rest, and send that output too.
   Stop and report instead if a run shows more than 10% FAILED, or anything looks wrong in Studio.
5. Do not publish; Shannon does, then checks the quay, the streets and the funicular stop in VR.

## Job 11: send the store's tool-equip code (READ-ONLY; for the phone 3-slot fix)

Job 7 showed the phone hotbar has 3 slots and Shannon carries 4 tools, so the 4th (the camera) gets no slot. The fix
will live in the HotbarStow handler: on small screens, equipping a 4th tool stores the oldest other one.
Send ONE message to the cloud session with, verbatim (exact text, tabs kept, no analysis):
1. From StowServer (wherever it lives: say its full path): the TOOLS table, the RS.HotbarStow OnServerEvent handler
   (the whole function that handles "store" / "equip" or whatever its verbs are), and any helper it calls to give or
   take a tool. Also its total Source length in chars.
2. From workspace.Shop.ShopClient: the lines that fire RS.HotbarStow (the Equip / Store buttons), about 30 lines
   around each call, and its total Source length.
3. One line: how ShopClient shows the "equipped" state of a tool in its rows (attribute name or event).

## Job 12: the phone 3-slot hotbar fix (Studio EDIT: StowServer replaced, ShopClient patched; ask Shannon first)

Job 7 + job 11: Roblox's hotbar shows 3 tools on a phone-sized screen; Shannon owns 4. Fix: the store sends its slot
count with every Equip/Store; equipping past it stores the tool equipped longest ago and says so on the row; a phone
asks on arrival to trim the bar to 3 (ties: crab trap goes first, then slingshot, binoculars, camera).

1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/shop/phone_slots_patch.lua
   It refuses to run unless StowServer is 1534 chars and ShopClient 33513 chars (the job 11 texts) and both finds hit
   once; compiles both results before writing; backups to ServerStorage.HudBackup.StowServer_pre_slots / ShopClient_pre_slots.
2. Tell Shannon; with her yes run it (Edit mode, execute_luau). Send the `QQ SLOT` line.
3. Optional if she wants it checked before publishing: Device Simulator play test with 4 tools (set Item_camera and
   Item_crabtrap = 1 as in job 7): about 4 s after spawn one tool should go to the bag and the camera stay on the bar;
   Equip the stored one in the store and another should go. Stop the play test, Studio back in Edit. No publish.

## Job 13: move the diver back onto flat sand (DRY first, then Studio EDIT with Shannon's yes)

Shannon: "the scuba diver squirrel is half fixed, he just needs to be moved back a little, his flippers are flat but he
is sitting on a curved surface; if he is moved back to where it is flat, he will be flush with the ground."
1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/squirrels/diver_flat1.lua
2. Run as is (DRY = true): it prints the ground slope at each half-stud inland and the spot it would move him to.
   Send the `QQ DIVE` lines. If no spot is flatter than 0.08 within 6 studs, say so and stop.
3. With Shannon's yes: `DRY = false`, run, send the `QQ DIVE` lines. (Attr FlatOct9OrigCF keeps where he was.)

## Job 14: send the game's conventions for the sea glass game AND the Italy passport page (READ-ONLY)

Shannon wants (a) the sea glass / shell game with the seaglass squirrel ("Bella") on the Spiaggia at (399.6,-48.8,-1054.8)
and (b) the Porto activities on the passport, built exactly like the French ones. Send ONE message (or two if it is long)
with, verbatim where asked (exact text, tabs kept), no analysis:
1. The Passport: paths of workspace.Passport.Catalogue, Journal, the server script and PassportClient, with each one's
   Source length. The FULL Source of Catalogue (all entries). From Journal: the whole J.describe function. From the
   server script: the "mark" function (how an activity fired on RS.PassportActivity is recorded; how needAll and the
   Found_<area> counts work; the attribute or key that records each activity as done). From PassportClient: how the
   city tabs decide which entries show (the CITIES table and the lines that filter entries by area), and the
   hint-progress lines for "photos". The children names of RS.PassportArt and the PassportVisuals mapping (where it
   lives, verbatim if under 3000 chars).
2. Every place the game fires the passport: grep all scripts (workspace, ServerScriptService, ReplicatedStorage,
   ServerStorage) for "PassportActivity" and list each as: script full path | the id string fired | the data keys.
3. How a found squirrel is recorded on the player (the attribute or key pattern, e.g. Found_<id>) and the Porto squirrel
   REGISTRY ids with display names: from SquirrelRegistry (its path), the entries whose area is porto/italy, as
   id | name | area (verbatim table rows if under 6000 chars, else id|name|area one per line).
4. The CRAB game: the full Source of CrabServer if under 12000 chars, else its first 60 lines + the functions that
   spawn a crab, award the catch (the RS.AwardItems call, how acorns are paid when a crab is sold to the fish seller,
   the gold crab), and the ProximityPrompt setup. Also the paths of its client script and modules.
5. SquirrelBubble: the module path and one real call from any script (the line with its arguments).
6. The seaglass squirrel: full path, pivot, PrimaryPart name, and its children names (one level); its registry id.
7. AwardItems: the Source of the script handling RS.AwardItems if under 6000 chars; else the part that saves Item_*
   (is there a whitelist of saved keys?) and how acorns are added (the function or event other scripts use).
8. The shore around the seaglass squirrel: the terrain materials hit by a 7x7 grid of downward rays over x 370..430,
   z -1085..-1025 (just the material name per cell, one row per z line), so the finds can be scattered on sand.
9. Bells and the opera: any part/model/sound in Porto whose name contains "bell" or "campan" (path + whether it has a
   ProximityPrompt or ClickDetector or a Sound); the opera duet models' paths (Subjects "opera": model + model2) and
   any Sound under them; the funicular's server script path and whether it has any "ride complete" moment;
   the Polpo (octopus) server script path and the line where a rescue completes; SpeedServer's PassportActivity line.

## Job 15: new music for the TOP section of Porto (Studio EDIT: one sound id; ask Shannon first)

Shannon: "replace the top map music with this 1848102847".
1. Find Porto's music zones (MapMusic: polygons such as GrottaPolygon, the harbour, Via della Piazza, The Groves, the
   upper town) and list each with its current sound id(s) (attribute or Sound.SoundId) in one short table.
2. Pick the zone that covers the TOP section (the upper town / The Groves, y above the square), show Shannon the table
   and your pick, and wait for her yes (she may point at a different zone).
3. With her yes: note the old id in an attribute (OldSoundId_Oct9) on the same object, set the new id
   rbxassetid://1848102847 in the same format the others use, and send one line to the cloud session with the zone
   name, old id and new id. No publish.

## Job 16: SKIP, Shannon found the opera sound herself: 9042832054. Nothing to do here.

(original text, no longer needed:)

Shannon lost the opera sound she had picked. Search the audio library the way the Grotta sounds were found (Pro SFX /
Creator Store search): "opera aria", "soprano", "opera duet", "Italian opera". Pick THREE candidates that are allowed
for use in this game (usable by this experience, not restricted), 20-90 s long, with a clear singing voice. Send one
line each to the cloud session and to Shannon: id | title | length | why it fits. Do not place them in the game;
Shannon previews them in Studio and picks one.

## Job 17: the Italy passport page + Bella's beach game (Studio EDIT, one installer; ask Shannon first)

What it does (all exact-string patches with guards, or new instances; originals -> ServerStorage.HudBackup.*_pre_italy):
- Passport: 11 Porto outings added to the Catalogue (friends of the harbour / Via della Piazza / Groves, the harbour bell,
  cappuccino, a lemon, Beppe's crabs, the funicular, the opera, the Grotta rescue, Bella's beach finds), their Journal
  lines, their pictures (existing PassportArt models reused), progress lines on the Italy tab.
- PolpoServer: its rescue now stamps porto_polpo instead of the French swamp "rescue".
- New workspace.PortoPassport.PortoActivities: fires the outings (finds per area from FoundIds; cappuccino echo of
  "coffee" in Porto; lemon and crab sales from the item ledger; the brass harbour bell's prompt; a funicular ride; a
  "Listen" prompt + Sound 9042832054 on the opera singer).
- New RS.PortoAreas module; new workspace.SeaGlass (server, client, Recipes, RemoteEvent, Pieces): sea glass and shells
  on the sand round the seaglass squirrel (Bella), pickup prompts, Bella's prompt + panel, four recipes.
1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/porto/install_italy.lua
   It refuses to run unless Catalogue is 7793, Journal 12486, PassportVisuals 3783 and PassportClient 27056 chars and
   every find hits once; it compiles every patched Source and every new script before writing anything.
2. Tell Shannon; with her yes run it (Edit mode, execute_luau). Send the `QQ ITA` line (or the ABORT line).
3. Then a desktop play test as the owner, in Porto: (a) are there sea glass / shell pieces on the sand near the
   seaglass squirrel (workspace.SeaGlass.Pieces should hold 8 "Find" models)? pick one up: toast + Item_<kind> +1;
   (b) walk to the squirrel, use her prompt: the panel opens, Make buttons grey until you have the pieces;
   (c) at the opera singer in the piazza: "Listen" plays the aria; (d) the harbour office bell: ring it;
   (e) open the Passport, Porto Nocciola tab: the new outings listed, bell and opera stamped. Note any error in the
   Output (first error verbatim). Stop the play test; Studio back to Edit. Send the findings. No publish.

## Job 18: fixes from the job 17 play test + a look at the harbour bell (Studio EDIT, one script; ask Shannon first)

- Sea glass: 4 of 8 finds lay on the seabed (the spot ray ignored water); now the ray stops at the water surface.
- Bella's panel: shrinks to fit on a phone (keeps the top HUD bar and jump button clear) and draws above the Daily card.
- Passport, Porto tab of Outings: lists every Porto outing not yet stamped instead of "Porto Nocciola is new".
- Harbour bell: READ-ONLY probe first (QQ BELL lines: the prompt, its parent, the bell's own script); nothing changed there.
1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/porto/italy_fix1.lua
   It refuses to run unless SeaGlassServer is 8223, SeaGlassClient 10372 and PassportClient 28101 chars and every find
   hits once; compiles each result first; backups ServerStorage.HudBackup.*_pre_fix1.
2. Tell Shannon; with her yes run it (Edit mode, execute_luau). Send every `QQ BELL` and `QQ FIX` line in ONE message.
3. Quick play test (Device Simulator as it is): (a) workspace.SeaGlass.Pieces: the 8 Find positions, all on dry sand?
   (b) Bella's panel: top HUD bar and jump button visible? (c) Passport > Outings > Porto Nocciola: the unstamped outings
   listed? Stop the play test; Studio back in Edit. Send the findings in the same message. No publish.

## Job 19: map music silent while the opera singer sings (Studio EDIT, one script; ask Shannon first; AFTER job 18)

Shannon: "the background music should go silent when she is singing, then pause for 2 seconds after she stops, then
resume". While the aria plays, everyone within earshot (80 studs) gets NoMusic (the same switch the boat uses);
2 s after it ends the music comes back. Characters already on NoMusic (the boat) are not touched.
1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/porto/opera_hush1.lua
   It refuses to run unless workspace.PortoPassport.PortoActivities is 7202 chars and the find hits once.
2. Tell Shannon; with her yes run it (Edit mode). Send the `QQ HUSH` line.
3. Play test: at the singer, Listen: the map music fades out while she sings, ~2 s silence after, then it fades back.
   Stop the play test; Studio back in Edit. Send the findings. No publish.

## Job 20: map music back for players who arrive in Porto by travel or the boat (Studio EDIT; ask Shannon first)

TravelServer (arrival in Porto) and BoatServer (boarding) set NoMusic from before Porto had music; nothing cleared it,
so arrivals heard no music until a respawn. A watcher in PortoActivities clears it once the character stands on its own
feet past the dock line (not seated, not falling, not silenced by the opera).
1. Fetch and read tools/porto/porto_music1.lua (commit URL in the cloud session's message). READ-ONLY scan first
   (QQ MUS lines); it stops if another enabled script sets NoMusic. PortoActivities must be 8292 chars.
2. Tell Shannon; with her yes run it (Edit mode). Send every `QQ MUS` line.
3. Play test: start in France, travel to Porto with the map/travel board; on the quay the Porto music should play
   within ~1 s (char NoMusic nil). If quick, also: set NoMusic = true on the character by hand while standing on the
   quay; it should clear within ~1 s. Stop; Studio back in Edit. Send the findings. No publish.

## Job 21: new Groves music 130260682627466 (Studio EDIT, tiny; ask Shannon first; AFTER job 20)

Shannon: "please change the grove music to this: 130260682627466" (it was 1848102847 since job 15).
1. Fetch and read tools/porto/groves_music2.lua (commit URL in the cloud session's message). It swaps every place on
   workspace.MapMusic that holds 1848102847 to the new id in the same format; the replaced id goes to PrevSoundId_groves.
2. Tell Shannon; with her yes run it (Edit mode). Send the `QQ GRV` lines. No publish.

## Job 22: survey the far shore for the hot air balloon field (READ-ONLY)

Shannon: the empty far shore across the harbour is where hot air balloons fly and take off; her own balloon unlocks
after all 44 Porto squirrels and carries her to the next map.
1. Ask Shannon to aim the Studio camera at the middle of the spot she means (or select a part there), in Edit mode.
2. Fetch and run tools/balloon/balloon_survey1.lua (commit URL in the cloud session's message). Send every `QQ BAL` line.

## Job 23: import the balloon into Studio (Shannon imports by hand), then a READ-ONLY check

The balloon is Shannon's Meshy model, cleaned in Blender (broken ropes cut, new cables/frame/burner, 54 studs tall,
basket floor at the origin): tools/balloon/model_meshy/balloon_meshy.fbx (textures embedded).
1. Download it to Shannon's PC (Desktop or Downloads):
   curl -L -o balloon_meshy.fbx https://raw.githubusercontent.com/selard73/Create-repository/<commit>/tools/balloon/model_meshy/balloon_meshy.fbx
   (the commit is in the cloud session's message). Tell Shannon where it is.
2. Shannon, in Studio (Edit mode): File > Import 3D, pick balloon_meshy.fbx; keep the default options (one model with
   Envelope, Basket, Rigging, Burner, Flame and the embedded textures); Insert. Put it anywhere; it gets moved later.
3. Fetch and run tools/balloon/balloon_check1.lua. Send every `QQ BLN` line, and a screenshot path of the balloon in
   the viewport if you can take one. Nothing else is changed.

## Job 24: READ-ONLY dump for Shannon's VR bug list (sent to the runner directly; text in the cloud session's message)

PortoKeeper attributes + PortoKeeperServer source; ChampionServer's hallHas / totalSquirrels / SquirrelsFound trigger;
PortraitClient length; PassportServer's eligible / OnServerInvoke / Found_* line. Nothing changed.

## Job 25: the Passport gives five outings at a time PER MAP (Studio EDIT; ask Shannon first)

Shannon: "I thought it was just supposed to give you 5 then when you finish those give you 5 more, but here it seems to
just give all of them". _batch = the French page, new _batch_porto = the Porto page (opens once Item_porto >= 1); "Explore
more" turns that map's page. tools/passport/pages1.lua patches Passport.Journal (13882), PassportServer (any length),
PassportClient (28273); every find once or nothing changes. Send the `QQ PAGE` lines. Play test: Passport > Outings >
Porto Nocciola shows at most five outings and a "Well done / Explore more" card when they are all stamped; the French tab
unchanged. No publish.

## Job 26: the Grand Keeper statue once per player, counted on France's 44 only (Studio EDIT; ask Shannon first)

Shannon: "you could only get one statue once as a player in each map; it has given me the statue twice in the France
map". tools/champion/once1.lua patches workspace.Champion.ChampionServer (4 finds). Send the `QQ ONCE` lines. No publish.

## Job 27: gallery portraits in VR (Studio EDIT; ask Shannon first)

Shannon: "in the french section, the portraits had the characters in them blinking in and out" (VR). In a headset the
ViewportFrame sitters are replaced by the sitter's avatar bust picture. tools/portraits/vr1.lua patches
workspace.PortraitGallery.PortraitClient (3 finds). Send the `QQ VRP` lines. Shannon checks in VR after publishing.

## Job 28: the Guardian of the Harbour fires for a player who already has all 44 (Studio EDIT; ask Shannon first)

Job 24 showed PortoKeeperServer crowns only when Found_porto changes across 44 in the live server; Shannon had them all
before the Guardian stood (Oct 7). tools/porto_keeper/guardian1.lua: the count comes from FoundIds (Porto registry ids),
FoundIds changes are watched, and a player arriving with all 44 is crowned if no Guardian stands yet. It also prints
game.CreatorType / CreatorId (the owner exclusion applies only to CreatorType User). Send the `QQ GUARD` lines. No publish.
Job 26 note: Studio's ChampionServer already counts France only (Oct 3); once1.lua now changes only hallHas (once per player).

## Job 30: passport pages, the one-line fix to job 25 (Studio EDIT; ask Shannon first)

mark() read the stamped outing's page but wrote it back under the French key, so every Porto stamp copied the Porto page
over the French page (job 25 test: both pages identical, French tab "Keep exploring", Porto header 0 of 5).
tools/passport/pages2.lua (PassportServer 9188 chars, 2 finds). Send the `QQ PAGE2` line, then a play test: French tab
shows French outings again, Porto tab its own five with the stamped ones counted. No publish.

## Job 31: READ-ONLY surveys: Porto's sand patches (beach_survey1) and the Grotta (grotta_survey1). Done / pending.

## Job 32: sea glass and shells on both beaches, more of them (Studio EDIT; ask Shannon first)

Shannon: "more shells scattered on both of the beaches, not just the one beach by Bella". tools/porto/seaglass2.lua patches
workspace.SeaGlass.SeaGlassServer (8319 chars, 3 finds): boxes per beach (BoxMin/Max, Box2Min/Max ...) with their own
counts; sets Count 12 (Bella's beach) and Box2 = the harbour beach x 238..326 z -752..-700 with Count2 12. Send the
`QQ SG2` line; a quick play test: "SeaGlassServer: beach 1 ... beach 2 ..." lines, pieces on both beaches, pickup works
on the harbour beach too. No publish.

## Job 33: the balloon field (Studio EDIT, one installer; ask Shannon first; AFTER its review)

tools/balloon/install_field1.lua: the imported balloon becomes ServerStorage.BalloonTemplate (anchored, colours, Neon flame);
workspace.BalloonField on the far shore with BalloonServer / BalloonClient and RS.BalloonEvent: two drifting show balloons,
one tethered, and YourBalloon on its pad (Board at 44/44 Porto squirrels: rise, gust, storm, "To Be Continued", home).
Undo: tools/balloon/balloon_undo1.lua. Send the `QQ FIELD` line; play test as the owner (88/88): Board, the whole flight
(about 65 s), the return; the show balloons drift; no errors. No publish.

## Job 34: Bella's reveal, the pearl and the shell box (Studio EDIT; ask Shannon first)

tools/porto/seaglass3.lua (Recipes 2701, SeaGlassClient 10622, SeaGlassServer 9327; every find once): the made thing rises
and spins in front of you with sparkles; a pearl in an open oyster at the back of the Grotta (PearlSpot 515,-44,-1121,
floor found by a ray), one per player, back after 300 s; recipe "Shell box with a pearl". Send the `QQ SG3` line and the
"SeaGlassServer: the pearl waits at ..." line from a play test; take the pearl; make something at Bella and describe the
reveal. No publish.

## Job 35: the Daily Acorns card collects itself after 15 s (Studio EDIT; ask Shannon first)

tools/daily/daily_auto1.lua patches workspace.Daily.DailyClient (4 finds; AutoCollect attribute, 15 s). Send the `QQ AUTO`
line. No publish.

## Job 36: READ-ONLY surveys for the Piazza Race (the town squirrels; the site by the policeman). Done.

## Job 37: the Piazza Race (Studio EDIT, one installer, re-runnable; ask Shannon first)

Shannon: "create a race exactly like the Forest Race... in the neighbourhood area for the middle-level squirrels"; "the
leaderboard and the start should be next to the sailing club by where the policeman is". tools/race/install_porto_race.lua
= the Forest Race build with the Porto names: workspace.PortoRace (StartGate at 452,-12,-960 facing east, RaceBoard at
452,-976), RS.PortoRaceEvent, store PortoRace_v1, the 15 squirrels of RS.PortoAreas.lists.borgo, Item_porto_race_best,
passport "porto_race". Send the `QQ RACE` and "PortoRace: installed" lines. Play test: Start the race at the gate, the
15 town squirrels go grey on your screen, click two or three (count ticks), Quit; no errors. No publish.

## Job 38: the Passport outing "Piazza Race" (Studio EDIT; ask Shannon first; after job 37)

tools/race/passport_race1.lua (Catalogue 11291, Journal 14168, PassportVisuals 4105). Send the `QQ PRACE` line. No publish.

## Job 39: fixes to job 34 (Studio EDIT; ask Shannon first)

The pearl's oyster was inside rock: PearlSpot -> 506,-46,-1116 (open sand beside the cages). The shell box SELLS for 150
acorns (Shannon: not a keepsake, it sells for more because of the rare pearl). Bella's prompt hidden while her panel is
open (it drew over the buttons on phones). tools/porto/seaglass4.lua (Recipes 8069, SeaGlassServer 12114, SeaGlassClient
12895). Send the `QQ SG4` line and, from a play test, the "pearl waits at" line and whether the oyster is on the sand and
reachable. No publish.

## Job 40: the VR window (Studio EDIT; ask Shannon first; after its review)

tools/vr/install_vrwindow1.lua: workspace.VRWindow with VRWindowClient. In a headset, every ScreenGui's children move onto
one floating window 38 degrees to the right of the body's facing (Shannon: in the periphery when facing forward, in full
view when the head turns right), so pop-ups show with Roblox's control panel open or shut. Desktop/phone unchanged.
Attributes Yaw, Distance, Width, Follow, Drop, Off. Send the `QQ VRW` line; Shannon tests in the headset after publishing.

## Job 41: Bella's panel steps aside for the reveal (Studio EDIT; ask Shannon first; after job 39)

tools/porto/seaglass5.lua (SeaGlassClient after job 39). Send the `QQ SG5` line. No publish.

## Job 37b: the Piazza Race gate and board smaller and turned (Studio EDIT, re-run; ask Shannon first)

Shannon (VR): the race sign and leaderboard are "overwhelming, the wrong direction, huge". The re-run of
tools/race/install_porto_race.lua scales both to 60% and turns them 180 degrees (fronts toward the policeman's side;
runners now go west through the gate), set back on the cobbles; StartX/Y/Z follow the pad. Send the `QQ RACE` line.

## Job 37c: the Piazza Race gate and board in the piazza (Studio EDIT, re-run; ask Shannon first) - replaces 37b

Shannon: "the start should be in the piazza, the huge drop-off to the right of the opera singer and accordion player,
where the patio drops off; the leaderboard right next to it". Job 36c: the floor ends at x ~431 with a 23-stud drop.
Re-run tools/race/install_porto_race.lua: gate along the edge at 431.5,-12,-812 (60%, facing into the piazza; the pad on
the piazza side), board at 431.5,-824. Send the `QQ RACE` line; play test: Start works at the pad; nothing hangs over
the edge; the banner and board read from the piazza.

## Job 42: READ-ONLY dump of ShopClient's ITEMS / MAPS_OF / row block. Done.

## Job 43: keepsakes in the Acorn Store (Studio EDIT; ask Shannon first)

Shannon: "where do you see that you have the perfume bottle in your inventory?" tools/shop/keepsakes1.lua patches
workspace.Shop.ShopClient (34513 chars, 5 finds): row "Parfum bottle" on the Porto tab, shown once owned (the pearl sells, not a keepsake),
labelled "yours", never for sale. Send the `QQ KEEP` line; play test: with Item_parfum_bottle = 1 the row shows on the
Porto tab as "yours"; with 0 it is hidden; France tab unchanged; no errors. No publish.

## Job 44: the Wardrobe tab on the VR window (Studio EDIT; ask Shannon first)

tools/vr/wardrobe_vr1.lua: WardrobeClient's lookup of PassportGui.Page also looks on the VR window's canvas. Send the
`QQ WARD` line. No publish.

## Job 45: balloon round 3 (Studio EDIT, full re-run of the installer; ask Shannon first)

Shannon after her phone flight ("the balloon is my most favorite feature"): rise toast "Up you go, traveler!", gust toast
"Oh no! Looks like we are in for some bad weather!", the map music drops to 40% as the balloon climbs and comes back at
home, the lighthouse's light turns (a Neon beam, local) once the storm is dark and goes off on the ground, and /promo
(owner or Studio, desktop) films the next flight with the screen UI hidden for her promo video. Also the runner's join-time
fix (wind.Enabled before wind exists). Run tools/balloon/install_field1.lua in full (it rebuilds the field; sound ids kept;
it now measures the Faro's lantern -> attribute LightAt). Send the `QQ FIELD` line including "lantern ... from ...". No publish.
Result: applied in place (runner): BalloonClient 26755 / BalloonServer 10373; lantern (520, 71.7, -1178) from
PortoNocciola."14 Lighthouse coast"."Faro di Porto Nocciola"."Lantern roof"; backup HudBackup.BalloonClient_pre_fbd12c5. Not published.

## Job 48: Bella's game on a phone (Studio EDIT; ask Shannon first)

Shannon (mobile): "the speech bubble is still behind the picker screen and the reveal is behind the speech bubble ... picker
to the far right, speech bubble to the left (ok over the hint and medal bar for a moment), reveal in the middle".
tools/porto/seaglass6.lua: on a phone (touch, viewport under 560 high) with the panel open, Bella's words sit at the left of
the screen (her bubble follows an invisible anchor held there), the reveal rises in the middle just in front of her, the
panel hugs the right edge. Desktop/tablet/VR unchanged. Four exact finds, length about 13331 (±60), backup
HudBackup.SeaGlassClient_pre_seaglass6. Send the `QQ SG6` line. No publish.
Note (runner pre-check): Studio's SeaGlassClient is 13322 chars and never received seaglass5's reveal lines (the "left and
low" base and the 1.8 lift); seaglass6's find 4 now matches the first-written base line and brings the left-and-low base
with it. The repo src keeps the 1.8 lift, which Studio does not have.
Result job 48: QQ SG6 DONE 13322 -> 15059; backup HudBackup.SeaGlassClient_pre_seaglass6. Not published.

## Job 46: balloon round 4 - smooth flight, no /promo (Studio EDIT, installer re-run or in-place; ask Shannon first)

Shannon filming: "the camera is jittery" (her liftoff shot). The server moves the balloon every heartbeat but a client is
sent ~20 positions a second; BalloonClient now keeps the last positions and draws the flying balloon 0.1 s behind them,
smoothly, from Stepped (the rider's weld follows) and again before the frame is drawn; nothing is written at "home" (the
server's home pose arrives first). The /promo camera is gone (it would not record; see job 49). Also the review fix
(smoothStop). tools/balloon/install_field1.lua in full (or in place: the client only; server unchanged). `QQ FIELD` line. No publish.

## Job 47: the ground under the balloon field (Studio EDIT, terrain; ask Shannon first)

Shannon: "if I turn the camera in a certain direction on this part of land I can see under the ground".
tools/balloon/field_ground1.lua: 80 studs round BalloonField.Center, 24 under / 12 over: the three voxels under each
column's cap are made solid in the cap's material where they are air, pockets with rock below are filled, water ends a
column, the void under the land mass is left alone. Reads first; writes nothing if nothing to fill. Backup
HudBackup.FieldGround_pre1 (TerrainRegion, corner in attributes CX/CY/CZ; undo = PasteRegion). Send the `QQ GROUND` lines. No publish.

## Job 49: "Balloon flight" in the F8 filming menu (Studio EDIT; ask Shannon first)

/promo would not record (Win+Alt+R / Win+G dead once it ran); the F8 FilmMode tours record. tools/film/balloon_tour1.lua
patches workspace.FilmMode.Tours (3266 chars, 1 find) and FilmClient (19539 chars, 2 finds): a "Balloon flight" button;
press it, climb aboard, and from liftoff the camera runs the shot plan (grass, circle, chase, storm close-up, the sign) with
the UI hidden except BalloonGui; back to normal 2 s after being set down; F8 cancels. Backups FilmClient_pre_balloon1 /
Tours_pre_balloon1. Send the `QQ FILM` line. No publish. Sources: tools/film/src (runner's export + *_balloon1 patched copies).
Job 46 addendum (Shannon's phone screenshot): the "Your balloon is ready" sign that hung over the balloon is gone ("messy
and all over the place ... not permanent"); the word at the 44th squirrel now floats up the screen once and off the top.

## Job 50: Bella's panel inside the screen (Studio EDIT; ask Shannon first)

Shannon's phone: "its too far right getting cut off". tools/porto/seaglass7.lua (SeaGlassClient after job 48, about 15059
chars, 1 find): the panel's face moves into an inner frame that carries the phone scale; the panel keeps a plain pixel
size anchored at the right, and is nudged left a frame later if its right edge is still past the screen. Backup
HudBackup.SeaGlassClient_pre_seaglass7. Send the `QQ SG7` line. No publish.
Job 46 addendum 2 (review): the wind streaks now travel along the gust (EmissionDirection Front; they went straight up), and the
storm's Brightness drop is its own 2.2 s tween so the lightning flashes are not overwritten by the 9 s tween.
Results (runner, Edit mode, not play-tested, not published): 46 BalloonClient 26395 (backup BalloonClient_pre_080d05e);
47 190 voxels filled in 187 columns, y -74..-42, first at 42,-50,-582 (backup FieldGround_pre1, corner 6,-19,-182);
49 Tours 3414 / FilmClient 24618 (backups *_pre_balloon1); 50 SeaGlassClient 15822 (backup _pre_seaglass7).

## Job 51: Bella's panel anchored by its right edge (Studio EDIT; ask Shannon first)

Runner's note on job 50: Studio still builds the panel with AnchorPoint (0.5, 0.5) (seaglass5's anchoring line never
reached it), so Position (1, -4) hung half the panel off a phone screen; job 50's clamp pulled it back a frame later.
tools/porto/seaglass8.lua sets AnchorPoint (1, 0.5) in the layout itself (1 find, about 15822 chars, backup
HudBackup.SeaGlassClient_pre_seaglass8). Send the `QQ SG8` line. No publish.
Job 51 withdrawn (folded into job 52 before it ran).

## Job 52: Bella's game on a phone, round two (Studio EDIT; ask Shannon first) - in place of job 51

Shannon's phone: the panel's right edge has "zero space"; the speech bubble is too low; the reveal is "behind my character
low and small ... sit on top of everything ... prominent for a moment before it fades". tools/porto/seaglass9.lua
(SeaGlassClient after job 50, about 15822 chars, 3 finds): the layout anchors the panel by its right edge 14 px in; the
bubble's anchor is a third of the way down the screen; on a phone the reveal also comes up in a spinning window in the
middle of the screen (ViewportFrame, ZIndex 30) for five seconds, then fades; the world reveal and its sound stay. Backup
HudBackup.SeaGlassClient_pre_seaglass9. Send the `QQ SG9` line. No publish.
Result job 52: QQ SG9 DONE 15822 -> 18296; backup HudBackup.SeaGlassClient_pre_seaglass9. Not published; Shannon tests in the phone simulator.
Shannon (phone simulator): "Bella is perfect on the phone now."

## Job 53: Bella's reveal window on desktop too; panel 30 px in on a desktop (Studio EDIT; ask Shannon first)

Shannon on desktop: "make the same change for the reveal that we did on phone, you cannot see the reveal; edge the picker
modal a little to the left". tools/porto/seaglass10.lua (SeaGlassClient after job 52, about 18296 chars, 3 finds): the
reveal window on every flat screen (VR keeps the world reveal), half the screen height on a desktop; the panel 30 px in on
a desktop (14 on a phone, "perfect"). Backup HudBackup.SeaGlassClient_pre_seaglass10. Send the `QQ SG10` line. No publish.

## Job 54: the balloon in VR - stand-off camera, notes in the world (Studio EDIT, client in place; ask Shannon first)

Shannon (VR): the ride's view "tied directly to the player ... very close up to the basket, cannot zoom out or reorient";
the notes "super super tiny". BalloonClient (tools/balloon/install_field1.lua, client only; server unchanged): in a
headset the flight's camera stands 30 studs off the balloon, a little above, turning slowly round it; a flick of the right
thumbstick turns it 30 degrees; normal camera again on the ground (attributes VRCamDistance 30 / VRCamHeight 4 to tune).
The ride's words are a sign over the basket; the 44th-squirrel word is a card in front of you that floats up; BalloonGui
is marked VRWindowSkip. Flat screens unchanged. `QQ FIELD` line. No publish.

## Job 55: squirrel speech bubbles beside the speaker's head in VR (Studio EDIT; ask Shannon first)

Shannon (VR): "the speech bubbles do not work well with the head turn thing either, better just have those come up beside
the speaker's head in the game only". tools/bubble/bubble_vr1.lua patches ReplicatedStorage.SquirrelBubble (expects 5785
chars = the repo copy; 1 find): in a headset the same paper bubble is a BillboardGui up and to the right of the speaker's
head; flat screens unchanged. Backup HudBackup.SquirrelBubble_pre_vr1. Send the `QQ BUB` line. No publish.

Next (not built yet; Shannon's bigger VR ask): the pop-ups that are not game things (the picker, the control panel, the
rest of the VR window) grabbable with the controller and left where she puts them, instead of following the head.
Results (runner, Edit mode, not tested, not published): 53 SeaGlassClient 18492 (backup _pre_seaglass10); 54 BalloonClient
32028 (backup BalloonClient_pre_f4d950f); 55 SquirrelBubble 8415 (backup SquirrelBubble_pre_vr1).
Shannon (VR, Oct 10): the balloon ride works; "when it put me back on land the balloon stayed in the air"; Bella's words and
picker "work really well"; the reveal "spawns halfway in the stairway"; remove the yellow/blue VR test pads.

## Job 56: the balloon lands for everyone (Studio EDIT, client in place; ask Shannon first)

BalloonClient (tools/balloon/install_field1.lua, client only, 32702 chars): a server position more than 40 studs from the
last one (set down at home) is taken at once instead of glided to, and 0.8 s after "home" the balloon is put on its pad
if it is not there (whatever order the home position and the event arrived in). `QQ FIELD` line. No publish.

## Job 57: Bella's reveal in VR, front and centre (Studio EDIT; ask Shannon first)

tools/porto/seaglass11.lua (SeaGlassClient after job 53, about 18492 chars, 2 finds; the lift line in either form): in
a headset the made thing appears 2.8 studs in front of the eyes where she looks at that moment, 1.5x, rising only a
little. Backup HudBackup.SeaGlassClient_pre_seaglass11. Send the `QQ SG11` line. No publish.

## Job 58: remove the VR test switches (Studio EDIT; ask Shannon first)

tools/film/vrtest_remove1.lua: workspace.FilmMode.VRTestClient -> ServerStorage.HudBackup (disabled); any pad left in the
workspace with a Shadows / Plain floor prompt or a VRTest* name -> HudBackup.VRTestPads. Send the `QQ VRT` line. No publish.
Result job 56 (runner 3): BalloonClient 32028 -> 32702 (= 8b21dcf), server unchanged; backup HudBackup.BalloonClient_pre_8b21dcf. Not published.

## Job 59: export the Acorn Store scripts (READ-ONLY + git push; no Studio edit)

For the Italian fountain modes (job 61) the store's current text is needed. Save workspace.Shop.ShopServer.Source and
workspace.Shop.ShopClient.Source (and any other LuaSourceContainer under workspace.Shop, plus the Shop folder's attributes
and child list in Shop_attrs.txt) to tools/shop/src/, commit and push to claude/epic-hawking-188q4l (pull first).

## Job 60: survey the piazza fountain (READ-ONLY, EDIT mode)

tools/fountain/fountain_survey1.lua: finds the fountain in the square (about 464,-7,-794) and prints its parts, emitters,
beams, attachments, sounds, scripts and the ground round it. Send every `QQ FTN` line (there may be 30-60).

## Job 61 (to come): the fountain's modes - spaghetti + smiling meatballs, a frog resort, flower petals (Shannon, Oct 10)

Bought in the Acorn Store like the French fountain colour (the whole server's fountain for ten minutes). Built after jobs
59 and 60; the frogs are a Blender model Shannon imports (like the balloon).
Results (runner 3): 57 SeaGlassClient 18853 (backup _pre_seaglass11; Studio's lift line was the 2.4 form); 58 VRTestClient ->
HudBackup (disabled; the pads were made at run time, none in the workspace). Not published.
Shannon: frog croak 73626983091367 ("the same sound several times over so it sounds like there are more of them") - a croak is
answered by one to three others round the pond at varied pitch. Published Oct 10 00:57 UTC: jobs 56-58 live.
Job 61 build: tools/fountain/src/FountainModeClient.lua (the modes, client-local within Reach), tools/fountain/make_install_modes1.py
-> install_modes1.lua (FountainModes folder + client, assets from the imports, store rows via exact patches of the job 59 texts).
Shannon (VR, after publishing 56-58): "the balloon works really well in the vr now"; Bella's reveal "a little too big and in
your face now, but good enough" (to tone down later: seaglass11's VR block, scale 1.5 and 2.8 studs in front); pads gone.

## Job 62: Bella's reveal in VR a touch smaller (Studio EDIT; ask Shannon first)

Shannon: "maybe slightly smaller please". tools/porto/seaglass12.lua (SeaGlassClient after job 57, about 18853 chars, 2
finds): 1.15x instead of 1.5x, 3.3 studs off instead of 2.8. Backup HudBackup.SeaGlassClient_pre_seaglass12. `QQ SG12`. No publish.
Job 61 step 1 (Shannon, by hand): File > Import 3D of tools/fountain/model/frog.fbx and flowers.fbx at commit 93f25f4
(defaults); each lands in the workspace as a Model named after the file ("frog": Body, EyeL, EyeR, Sunglasses, SunHat,
SwimRing on one colour atlas; "flowers": Flower_A/B/C_Petals/_Centre, Leaf, LilyPad, Lotus_Petals, Lotus_Centre, flat
colours). Step 2 (runner, after the review): install_modes1.lua moves them into ReplicatedStorage.FountainModeAssets.
Result job 62: SeaGlassClient 18853 -> 18916; backup HudBackup.SeaGlassClient_pre_seaglass12. Not published.
Job 61 review (28 agents): noodle attachments parented before placing, X axis up, top strands bend down into the bowl;
carpet petals, the drink and its table flat the right way (a Cylinder's axis is Size.X); ladder rungs across the rails;
a resting meatball faces the fountain; sound ids formatted as whole numbers. All applied.

## Job 61 step 2: install the fountain modes (Studio EDIT; ask Shannon first; after her two imports)

tools/fountain/install_modes1.lua at commit 54ac93e (reviewed): workspace.FountainModes + FountainModeClient (26103 chars),
the imported "frog" / "flowers" Models -> ReplicatedStorage.FountainModeAssets (Frog, LilyPad, Lotus, Flowers), the Acorn
Store rows (ShopServer 9261 -> 10669, ShopClient 35014 -> 37163; backups HudBackup.ShopServer_pre_modes1 / ShopClient_pre_modes1;
Price_spaghetti/frogs/petals 25, Sell_* true). Re-runnable (the store patch is skipped once applied; assets are kept).
Send the `QQ FMODE DONE` line (it names the assets found and the measured rim). Then Shannon publishes and buys each mode
in the store's Porto tab (25 acorns each; the whole server's fountain for ten minutes, one at a time). No publish by the runner.
Result job 61 (runner 3, d6e3c38): FountainModes + client 26103; assets Frog, LilyPad, Lotus, Flowers (10 parts coloured);
ShopServer 10669 / ShopClient 37163 (backups *_pre_modes1); RimY -9.99 at r 6.0, GroundY -12.04. Not play-tested, not published.

## Job 63: the spaghetti fountain redone, modes last two minutes (Studio EDIT, re-run; ask Shannon first)

Shannon: the spaghetti "looks very very bad ... the pasta is not moving, it should be individual pasta pieces coming out and
falling down like the water does; the pink sauce looks gruesome"; and "whatever you do for this fountain should only last
about 2 minutes". Re-run tools/fountain/install_modes1.lua (it rebuilds FountainModes with the new client - noodle pieces
pour from the water's own emitters, real strands and meatballs tossed out of the spout, an opaque tomato sauce - sets
Minutes 2, keeps the assets, and turns the three store blurbs from ten to two minutes). Send the `QQ FMODE DONE` line. No publish.
Shannon: "the frogs look cute"; the petals "are a blur, falling too quickly, they should be falling in slow dreamy motion" ->
petal emitters at 0.4x the water's speed, pull 5, drag 1.2, life 4.5-6.3 s, rate 0.3x, slow spin (attributes PetalSpeed/
PetalFall/PetalDrag/PetalLife). Folded into the job 63 re-run (commit below).

## Job 64: the store's one "Fountain magic" row with three choices; the slow petals; the spaghetti redo (Studio EDIT, re-run; ask Shannon first)

Shannon: "on the store menu they should not be separate things, they should be on one line item with different choices".
tools/fountain/install_modes1.lua now puts the store back to the job 59 texts from the pre_modes1 backups and patches it
afresh: one item fountainmode (Price_fountainmode 25, Sell_fountainmode) with three choice buttons (Spaghetti / Frogs /
Petals) on the Porto tab, the countdown on that row; ShopServer 9261 -> 10916, ShopClient 35014 -> 38670; the first
version's Price_/Sell_ spaghetti/frogs/petals attributes are removed. Same run rebuilds FountainModes (client 27800: the
slow petals, the spaghetti redo, Minutes 2). Supersedes job 63 if not yet run. Send the `QQ FMODE DONE` line. No publish.
Result job 63 (13a7229, Shannon asked for it before 64): FountainModeClient 27800, Minutes 2, slow petals; store blurbs say two
minutes (ShopClient 37163, the job 61 three-row version). Job 64 (one row) restores from the pre_modes1 backups first. Not published.
Shannon (petals, twice): "a blurry mess ... not individual petals"; "it has to be real looking flower petals falling down".
The petal fountain is now real shapes: petal parts (meshes Petal_A/B/C once petals.fbx is imported; flat ovals until then)
that fly out of the jets and over the rim, tumble, drift down against drag, land on water/stone/paving, rest, fade.
Job 65 (after job 64 and her import of petals.fbx): re-run install_modes1 so the Petals asset is adopted and the client updated.
Shannon (spaghetti, third look): "flying up and everywhere, it should be a slow ooze down of strands, no projectiles";
the sauce "still does not look like meat sauce" -> strands are chains of noodle pieces creeping along fixed paths (spout ->
bowl, bowl edge -> basin, outer rim -> paving) at a stud a second; meatballs sit in the sauce, one rolls slowly down a
strand now and then; the sauce is deep tomato-brown with mince, herb, noodles lying in it and steam.

## Job 65: petals.fbx imported, then the re-run (Studio EDIT; ask Shannon first)

Step 1 (Shannon): File > Import 3D of tools/fountain/model/petals.fbx (commit below) - a Model "petals" with Petal_A/B/C.
Step 2 (runner): re-run tools/fountain/install_modes1.lua at that commit: adopts "petals" into the assets (Petals), colours
them, rebuilds FountainModes with the client (real petal meshes in the petal fountain; the spaghetti ooze). Store unchanged
if job 64 is in (the one-row version; it is restored and re-patched identically). `QQ FMODE DONE`. No publish.
Shannon: the frog mode is "Club Rana" (the sign, the store button and the "in use" text; the item id frogs stays). In job 65.
Result job 65 (runner 3, 9916430): FountainModeClient 32701; assets Frog, LilyPad, Lotus, Flowers, Petals; ShopServer 10916,
ShopClient 38793 (one "Fountain magic" row, three choices, the three-row patch undone first); Minutes 2, SignText CLUB RANA.
Not play-tested; the runner is asking Shannon for a Device Simulator test of the row and the modes before publishing. Not published.
Shannon (spaghetti, fourth look): meatballs "textured, sinking into the sauce"; the sauce "a solid plastic slab, should look
like thick liquid"; "spaghetti is long strands" (not a necklace of short pieces) -> strands are continuous overlapping
tubes from the spout over the bowl's edge into the basin (NoodleLong 12, NoodleBowl 6, NoodleOver 5) with a travelling
wobble; the sauce Glass, 0.1 see-through, glossy, simmering bubbles; meatballs Material Ground, sunk to 0.12 above the surface.

## Job 66: the spaghetti round five (Studio EDIT, re-run; ask Shannon first)

Re-run tools/fountain/install_modes1.lua at the commit below (only FountainModes is rebuilt; the store is restored and
re-patched identically; assets kept). `QQ FMODE DONE`. No publish.
Shannon's two pictures (a spaghetti fountain: curtains of strands over every tier, coils heaped in the water, meatballs perched
on the rims and heaps, steam; and a dense cascade of strands): strands 36 long / 14 bowl / 18 over, every third sliding and
wobbling, the rest hanging still; coils on the basin (10) and bowl (4); meatballs on the rim (7), the bowl's edge (3) and the
heaps (3), Ground material; the water stays water (attribute Sauce false; true gives the glossy simmering sauce). Job 66.
Shannon's tap picture + "more petals, a wider radius, to the bottom": the spout pours a straight bundle (26) into the bowl's
heap (6 coils), curtains from the bowl's edge (40), over the rim (18); petals 60/s, up to 420, spread 55 deg, 6-10 studs/s,
a fifth of them off the basin's rim down to the paving, the ground carpet to 5.5 studs out. Job 66 commit below.
Result job 66 (runner 3, 53cca9a): FountainModeClient 37269; store unchanged from job 65 (10916 / 38793); Sauce false; assets
unchanged. Job 65 was published by Shannon at 03:26 UTC (the one-row store, Club Rana, petal meshes); 66 not yet published.
Shannon: "scrap the spaghetti fountain all together ... keep the frogs and the flowers".

## Job 67: the fountain without the spaghetti (Studio EDIT, re-run; ask Shannon first)

Re-run tools/fountain/install_modes1.lua at the commit below: FountainModes rebuilt with the client minus spaghetti (24809
chars); the store restored from the pre_modes1 backups and re-patched with two choices, Club Rana / Petals (ShopServer
9261 -> 10901, ShopClient 35014 -> 38666). `QQ FMODE DONE`. No publish.

## Job 68: the opera spotlight (Studio EDIT; ask Shannon first)

Shannon: "just for the player who presses the button to hear the opera singer: for a moment dim the lights in the world
and put a spotlight on her and the accordion player until she finishes singing, then bring the lights up again".
tools/opera/install_lights1.lua: workspace.OperaLights + OperaLightsClient (client-local: on this player's Listen, a
colour-correction and Lighting dim over 1.6 s, warm spotlights with visible beams and light pools over the singer and
Nino, until OperaSong stops / the player walks 45 studs away / respawns; up again over 2.2 s). Attributes to tune on the
folder. Undo: delete workspace.OperaLights. Send the `QQ OPERA` line. No publish.
Result job 67 (runner 3, c25ae2e): FountainModeClient 24809 (no spaghetti); store two choices (ShopServer 10901, ShopClient 38666);
assets unchanged. Not published.
Result job 68 (runner 3, a5cfc03): workspace.OperaLights + OperaLightsClient 7690; singer and accordion_squirrel_color found.
Not play-tested; Shannon tests after publishing. The Fountain magic row (two 100 px buttons) still unmeasured on a phone.

## Job 69: opera lights round two (Studio EDIT, re-run; ask Shannon first)

Shannon: "the spotlights should be brighter, the darkness of the world a little less dark; the listen button should go away
after you press it, it is very glowy and still there". Re-run tools/opera/install_lights1.lua: SpotBrightness 18 (+ a warm
fill light on each performer), BeamStrength 0.26, PoolStrength 0.5; DimBrightness 0.16, DimExposure 0.35, ambient blended
halfway (DimAmbient 0.5), the sun left at 1.0; the Listen prompt hidden on this client while the aria plays. `QQ OPERA`. No publish.
Result job 69 (runner 3, ce74f19): OperaLightsClient 8757, attributes as planned. Jobs 67 and 68 were published at 03:59 UTC;
69 not yet published. Not play-tested.

## Diagnosis (runner 3, Oct 10): phone slingshot / binoculars "not responding" in Porto; the slingshot's hoop note in Italy

Nothing changed yet (Shannon's word awaited). Findings: SlingClient's help text always mentions the hoop; a phone shot
aims at the nearest AcornHoop and all three are in France (400+ studs from Porto), so in Porto the acorn lobs away towards
France at 72 degrees and still costs an acorn ("nothing happened"). Both tool clients decide touch mode ONCE at start with
UIS.TouchEnabled and not UIS.MouseEnabled (MouseEnabled flickered true in the emulator; UIS.PreferredInput is safer).
Roblox's capture bar (screenshot/record buttons) can sit over the HOLD TO SHOOT button on a phone, and PromptTouch's
stack covers the same area when a prompt is near. In the 667x375 emulator both tools worked. Proposed fix when she says
so: in Porto (no hoop within range) a touch shot flies where the camera looks and the note says so; touch mode by
PreferredInput, re-checked on LastInputTypeChanged; the HOLD button moved clear of the capture bar.
Job 70 result: tools/tools_src/ exported (SlingClient 16373, SlingServer 17641, SlingPose, BinocularsClient 7981, BinocularsHold,
BinocularsServer, BinocularsPose, DailyClient 14785, QuestionClient 28363). Shannon on her phone: no HOLD button, binoculars
dead -> the tools started in mouse mode (MouseEnabled true on her phone).

## Job 71: the slingshot and the binoculars on a phone; the hoop note in Porto (Studio EDIT; ask Shannon first)

tools/tools_src/phone_tools1.lua (4 exact patches, all checked before any write; backups HudBackup.*_pre_phone1):
SlingClient 16373 -> 18368 (touch by UIS.PreferredInput, switching to touch when a finger arrives; HOLD button at the
bottom middle, 130 px; away from every hoop (HoopRange 150, new attribute on workspace.Hoop) the acorn goes where you
look - a point shot at the spot in the middle of the screen within 120 studs, else a lob that way - and the note says so);
BinocularsClient 7981 -> 8602 (the same touch test, following the last input used); DailyClient 14785 -> 15020 and
QuestionClient 28363 -> 28598 (phone layout by PreferredInput). Send the `QQ PHONE` line. No publish.
Job 71 layout (runner's phone measurements, 667x375): the HOLD button in the strip between Roblox's hotbar and the jump
button (AnchorPoint 1,1 at 1,-115,1,-45; 100 px; text 18), the draw bar at -150 and the help note at -170, above it. One install.
Result job 71 (runner 3, 142634f): SlingClient 18486, BinocularsClient 8602, DailyClient 15020, QuestionClient 28598; backups
*_pre_phone1; Hoop.HoopRange 150. Phone-preset play test: touch mode with MouseEnabled true (Shannon's case), HOLD at x 452..552
y 230..330 with no overlaps, a held shot landed within 0.6 studs of the screen-centre point, binoculars toggle on a tap, no
errors. Not covered: the touch switch at run time, other screen sizes, a prompt's touch button over the note. Not published.
Shannon (phone, after publishing at 04:39 UTC): the slingshot and binoculars "appear to be fine at this time". Jobs 69 and 71 live.

## Job 72: VR morning survey + PromptClient export (READ-ONLY; no Studio edit; git push)

Shannon in VR (Oct 10 morning): (1) "the interact button for the race and the opera singer in the square is missing
completely", (2) "all of the frogs in Club Rana are tipped up on their faces with their backsides in the air", (3) "you can
see the rails only from the funicolare when you are up in the balloon, not the whole funicolare".
1. Pull the branch. Save workspace.PromptUI.PromptClient.Source (exact bytes) to tools/prompts_src/PromptClient.lua, commit and
   push to claude/epic-hawking-188q4l (as jobs 59 and 70 did). The cloud session patches the live copy from that file.
2. Run tools/cloud/survey72.lua (Edit mode; it reads only: prompt settings, the Frog asset's part orientations, the
   funicolare's models and streaming settings). Send every `QQ S72` line in one message, with the pushed commit's SHA.

Result job 72 (runner 4, 84833b8): PromptClient exported (23746, byte-equal). Facts: 73 prompts, Custom at run time only; the
race StartPrompt on PortoRace.StartGate.StartPad (Hold 0.3, Pad ButtonX, PhoneSpot sign); OperaPrompt made at run time by
PortoActivities on the singer. Frog asset: every part Orientation 0 but PivotOffset (90,0,0) -> Model:PivotTo(level) lays it on
its face (eyes at Body-local (+-0.2,0.3,-0.4): face -Z, up +Y). Streaming on; "15 Funicolare" (Model, Default, 288 anchored
parts) 240-600 studs from the balloon field; rails/cables are 375-stud parts (they stay in range), the rest small.

## Job 73: the interact pill in VR, beside the thing itself (Studio EDIT; ask Shannon first)

tools/prompts/prompt_vr1.lua: exact-string patch of workspace.PromptUI.PromptClient (23746 -> 30345; backup
HudBackup.PromptClient_pre_vr1): in VR each shown prompt gets a BillboardGui pill on its own part (0.6-0.8 studs tall, the
controller button on the badge, the object and action texts, the hold fill), pressed with the pointer (a tap completes a
hold-pill; a release anywhere ends the hold), hidden while the daily card / a panel is open; flat screens unchanged.
Generator tools/prompts/make_prompt_vr1.py. Review round 1: the click fallback is off once the pointer has delivered a press.
Send the `QQ PVR` line. No publish. Undo: PromptClient.Source = HudBackup.PromptClient_pre_vr1.Source.

## Job 74: Club Rana frogs upright (Studio EDIT, re-run; ask Shannon first)

Re-run tools/fountain/install_modes1.lua at the commit below: FountainModes rebuilt with the client (25442 chars) that
flattens the imported parts' PivotOffset before setting each frog, lily pad and lotus down (the frog's pivot is its Body,
upright, face -Z; review: the deck-chair frog faces out of the chair, reclined 20 degrees; the swimmer sits in the water,
not above it; a pad frog bobs with its own pad). Assets kept; the store
restored from its pre_modes1 backups and re-patched identically (10901 / 38666).
Send the `QQ FMODE DONE` line. No publish.

## Job 75: the funicolare stays loaded from the balloon (Studio EDIT; ask Shannon first)

tools/porto/funicolare_persist1.lua: workspace.PortoNocciola["15 Funicolare"].ModelStreamingMode = Atomic (the whole 288-part
model comes in whenever its long rails are in range, as they are from the balloon; review: not Persistent, which would load it
and the cars' every-frame moves for every player in every map); the old value kept in the attribute StreamingWas. Send the `QQ FUNI` line. No publish.
Ask Shannon once for all three edits (73, 74, 75), then run them in that order and send one message with the three lines.
Result jobs 73-75 (runner 4, 2249420; Shannon's one yes for all three; not published): PromptClient 23746 -> 30345 (backup
PromptClient_pre_vr1 = the job 72 export); FountainModes rebuilt, client 25442, assets unchanged, store 10901 / 38666 byte-equal
to before; "15 Funicolare" Atomic (was Default, kept in StreamingWas). Not play-tested; Shannon publishes and tests in VR.

Shannon (Oct 10, after publishing 73-75, desktop screenshot): the top-tier frog "floating in mid air"; the far rim frog "half
suspended on water"; from the balloon "the far side where the funicolare is fades in and out" (Atomic pops the whole model as
the rails cross the headset's streaming range). The VR pills and the other frogs: no complaint.

## Job 76: frogs with a footing (Studio EDIT, re-run; ask Shannon first)

Re-run tools/fountain/install_modes1.lua at the commit below: the client (28552 chars) now finds each rim frog and the top
frog a solid footing by raycast - from the spot asked for, stepping in and out along its line from the centre, the first
place where its whole footprint rests on the fountain's own stone at one height (water, the upper bowl, anything else
refused); the three keep trying for 30 s in case the stone has not streamed in yet; none found -> a warning, no frog there. Assets kept; store restored and re-patched identically (10901 / 38666). Send the `QQ FMODE DONE` line. No publish.

## Job 77: the funicolare stays loaded for the balloon rider (Studio EDIT; ask Shannon first)

tools/balloon/ride_persist1.lua: "15 Funicolare" -> ModelStreamingMode PersistentPerPlayer (everyone else: streams as one
whole, as Atomic did); BalloonField attribute RidePersistent = "PortoNocciola/15 Funicolare" (";"-separated paths; more can
be added later); BalloonServer 10373 -> 11362 (ridePersist(p, true) at boarding, (p, false) at home; the early return
before boarding now re-enables the Board prompt (a pre-existing hole, review); backup
HudBackup.BalloonServer_pre_ride1). Generator tools/balloon/make_ride_persist1.py. Send the `QQ RIDE` line. No publish.
Ask Shannon once for both edits (76, 77), run them in that order, one message with the two lines.
Runner 4 dry run (read-only, before 76): the rim's flat top is r 6.0..6.8 (a 1.2) / 6.0..6.6 (a 4.9), 0.6-0.8 wide; RimR 6.0 is its
inner edge; the top frog's footing is the upper bowl's stone floor at -5.24 beside the spout (the column top is too narrow). So
the rim frogs ask at RimR + 0.3, the footprint along the line is 0.6 wide and the levelness allowance 0.12 (the inner slope is
0.18 lower). Commit below.
Result jobs 76-77 (runner 4, 1f3136d; one yes; not published): FountainModeClient 28552 (dry run: both rim frogs at r 6.30 on
stone, the five rays level; the top frog on the upper bowl's floor at -5.24 beside the spout); store byte-equal; "15 Funicolare"
PersistentPerPlayer, BalloonField.RidePersistent set, BalloonServer 11362 (backup BalloonServer_pre_ride1). Shannon publishes and tests.

Shannon (Oct 10, after publishing 76-77): the top frog "still floating on water with his face stuck in the spout"; "the funicolare
and scenery at the very rear like the mountains still come in and out" on the ride - "first you see it, then you change
locations, then you don't, then you see part of it" (she reads it as loading, i.e. streaming).

## Job 78: the top frog on a lily pad in the upper bowl (Studio EDIT, re-run; ask Shannon first)

Re-run tools/fountain/install_modes1.lua at the commit below: client 29110 - the top frog sits on a lily pad afloat on the
upper bowl's water, 1.1 studs in from the bowl's edge on the deck's side, facing out; the pad bobs and the frog with it. The
two rim frogs unchanged (r 6.3 on stone). Send the `QQ FMODE DONE` line. No publish.

## Job 79: a temporary readout for one balloon ride (Studio EDIT; ask Shannon first)

tools/balloon/ride_probe1.lua: workspace.BalloonField.RideProbe (client) + attribute Probe = true: a small sign in front of the
camera with the funicolare's parts present on this client (now / most seen, 288 when all) and, for each far section of the
town (12 Country landscape, 13 Hillside town, 14 Lighthouse coast, 16 Mediterranean planting), how many of 12 sentinel parts
the installer picked across it and tagged RideProbe_<section> are present (CollectionService; a name path finds a same-named
sibling - runner's dry run); tools/balloon/ride_probe_remove1.lua takes it all out; plus the distance to the funicolare (runner: no PortoBackdrop model exists; the
town is 67,000 parts, not to be walked every tick). Shannon reads it on one ride: "Funicolare 288/288" while it looks missing = loaded but not drawn; 0 or
"not here" = streamed out. Afterwards Probe = false hides it; delete the script to remove. Send the `QQ PROBE` line. No publish.
Ask Shannon once for both edits (78, 79), run them in that order, one message with the two lines.
Result jobs 78-79 (runner 4; 78 at 317e119, 79 at 841cd42; one yes; not published): FountainModeClient 29110; store byte-equal.
Play test (desktop): the top frog on its pad in the upper bowl, level, facing out, clear of the spout; rim frogs at r 6.28/6.30
on stone; Shannon on the screenshots: "club rana looks good". RideProbe 2559 chars, Probe true, 12 sentinels tagged per far
section; on a desktop at spawn everything reads full (288/288, 12/12 x4) - the headset's numbers decide. Remover:
tools/balloon/ride_probe_remove1.lua. Shannon publishes and takes one ride reading the sign.

Shannon's ride with the readout (Oct 10): every count full the whole ride (Funicolare 288/288, 12/12 x4) while the funicolare
and the far hills still came and went -> the Quest's renderer at a low automatic quality step, not streaming. Her pick: haze
the far view and lighten the ride in VR (merging the funicolare's small parts kept in reserve).

## Job 80: the VR ride hazed and lighter (Studio EDIT; ask Shannon first)

tools/balloon/vr_ride1.lua: BalloonClient 32702 -> 34420 chars, backup HudBackup.BalloonClient_pre_vrride1 (review: a respawn
before the storm clears the haze too; with an Atmosphere its Density goes to 0.55):
in VR, at boarding, shadows off for the ride and Lighting fog 350..900 (or the Atmosphere's Haze 2.5 if the place has one);
the wind streaks at 36/s and half the bolts; the storm takes over as before and the end of the ride puts everything back
from the one snapshot. Attributes on BalloonField: VRHazeStart/End, VRHazeAtmo, VRShadowsOff, VRWindRate, VRBoltShare.
Generator tools/balloon/make_vr_ride1.py. Send the `QQ VRRIDE` line. No publish.

## Job 81: the ride readout out again (Studio EDIT; ask Shannon first)

tools/balloon/ride_probe_remove1.lua: deletes BalloonField.RideProbe, the Probe attribute and the 48 RideProbe_* tags. Send
the `QQ PROBE GONE` line. No publish. Ask Shannon once for both (80, 81); one message with the two lines.
Result jobs 80-81 (runner 4, c5d9528; one yes; not published): BalloonClient 34420 (backup BalloonClient_pre_vrride1); the readout
and its 48 tags gone. The place HAS an Atmosphere (Density 0.30, Haze 0; Lighting's FogStart/End 350/1100 are dead letters),
so the VR haze is by Atmosphere Density/Haze. Runner's desktop preview from the pad + 89 studs: 0.55/2.5 far too thick (the
town gone); 0.46/2.0 the far hill town hazed, lighthouse faint, waterfront clear; 0.40/1.2 the town clear, far hills and
horizon soft. Shannon picks the strength; the runner sets VRHazeDensity / VRHazeAtmo on her yes (attributes, no script).
Shannon on the haze pictures: "I don't like any of these" -> "for right now, please undo any changes where that is concerned,
we will just keep it as it". Runner 4 undid job 80 (BalloonClient back to 32702 from the backup; the seven VR* attributes
removed); job 81 stays done; job 77 stays (the funicolare persists for the rider). The balloon ride is as it was live.

## Job 82: survey the waterfall cliff's face (READ-ONLY, EDIT mode)

tools/falls/cliff_survey1.lua: every piece of SouthGorge.Rock (SouthCliff_* and _Lo halves, the wall chunks by the lip), the
Falls' crest beams, other parts parked near the crest by earlier patches, the River parts behind the lip. Send every `QQ CLIFF`
line. Plus pictures (Studio, Edit mode, no change): (a) from the foot of the falls (Porto side) looking up at the whole face,
(b) a close look at the right-hand side of the face toward the top, (c) the right side of the lip from the river just above the
fall, (d) the same spots from behind / above where the face is see-through. Send the picture paths and what you see.
Result job 82 (runner 4, c2388a6): "right" seen from Porto = the WEST pieces (W01 beside the falls, W02 beyond). The dark
spots are Terrain (Grass): the plateau's vertical side stands 0.6-8 studs behind the west cliff's top slabs and shows through
openings in the meshes; at (107,36) and (155,37) the terrain stands 0.4-0.8 IN FRONT of the mesh; a dark patch at the top of
the east cliff by the notch too. The lip: the Body sheet (36 wide) is 2.2 studs wider than FallsB.LipPlate (31.5) on each side;
LipRockW covers the corner itself; no blue part near the lip (the river is terrain water). Pictures on Shannon's PC
(C:\Users\slard\Create-repository-shots\cliff-*.jpg).

## Job 83: the cliff's bald spots and the lip's right edge (Studio EDIT; ask Shannon first)

tools/falls/cliff_fix1.lua: (1) a backing WALL of sandstone blocks (4 studs wide, 1.6 thick, y 24 up to the slabs' top) built
from measurements at run time, one stud behind the furthest-back face point of each segment, along the west cliff's top band
(x 100..168) and the east cliff's by the notch (x 200..244), in SouthGorge.Rock.CliffBacking: every opening between slabs
shows sandstone, the recess under the top slabs is filled (review: a shifted copy of the mesh shares its openings - dropped);
(2) the terrain standing in front of the face or closer behind it than the wall is carved back with thin Air boxes (region
backed up first: HudBackup.CliffTop_pre1); (3) FallsB.LipPlate widened to the Body sheet's crest width (SizeWas kept). Send
the `QQ CLIFFFIX` line, then pictures from the same spots as job 82 (b2, d and c4 above all). No publish. Also: identify the
three small pale grey blocks floating in the sky above the notch in every picture (what and where they are).
Runner 4 dry run of 35353a3 (job 83 round one): no block in front of the collision face, but 22 of 26 blocks topped above
their cover (the slabs' tops run 41.9-43.6, the grass behind 40-45) and two stood in the open at the notch; the 279 thin Air
carves reached y 43.1 under a grass top only 0-2 studs higher (the edge would sag). Round two (c4e4439): bands W 100..160 and
E 208..244; blocks 0.5 behind the face, thinned to the terrain (0.3..1.6 or skipped), tops 0.25 under the lowest cover over
nine downward rays (open sky -> no block); no carving except the pokes in front at y <= 40; the terrain's exposed side in the
band (y 24..44) ReplaceMaterial Grass/LeafyGrass/Ground -> Sandstone instead (shape untouched; the grass top row kept).
Runner 4 play-test preview of c4e4439 (pictures tools/falls/shots/cliff-preview-*.jpg, ebe59bd): the dark patches by the
corner are gone (the openings show tan); only 2 of 26 blocks found room (the terrain is within a stud of the face nearly
everywhere), the material swap does the work; the plateau's top turned sandy in a 10-20 stud rim behind the edge; the pale
lip plate at 36 covers the teal strip Shannon saw. Shannon on the six before/after pictures: "Good, do the whole cliff" -
her yes covers the whole-face version if the preview looks the same or better. Round three (commit below): bands W 42..160
and E 208..328, backup region x 36..336.
Runner 4 dry run of 85f17df: one sandstone box per band took the whole band's z range (48-52 deep, the sandy rim would reach
30-46 studs back under the trees); at the west end x 42..54 a Limestone outcrop stands 4-7 studs in front of the mesh on
purpose and would have been drilled. Round four (commit below): the sandstone swap per 8-stud segment (face z - 2 .. + 8);
only Grass pokes no deeper than 2 studs shaved (Limestone/Rock left); backup region z -592..-520.
Result job 83 (runner 4, febeab4, installed under Shannon's "do the whole cliff"; preview matched; not published): 8 backing
blocks (the terrain is within a stud of the face nearly everywhere, so the material swap does the work), 29 sandstone
segments along both cliffs (rim on top 4-20 studs deep), 37 shallow grass pokes shaved, limestone outcrops untouched,
LipPlate 36 (SizeWas kept), backup HudBackup.CliffTop_pre1 (paste at voxel 9,5,-148). Pictures tools/falls/shots/cliff-r4-*
and cliff-installed-*: no dark patch anywhere along the top; the corner by the falls clean; the pale plate beside the sheet.
Noted: x 155..160 (the W band's last partial segment) not swapped, looks clean. Shannon publishes when she likes.
Shannon on the installed job 83 (play pictures): "it doesn't look fixed in those pictures, I can still see bald spots" - the
openings read as patches whatever the colour behind them; also a dark bare patch on the grass hill beyond the west outcrop.

## Job 84: the openings closed with the cliff's own rock (Studio EDIT; preview first, then ask Shannon)

tools/falls/cliff_fix2.lua, on top of job 83: the terrain carved back to 3.2 studs behind the face in rows y 26..38 (soft
materials only; the top rows and the limestone untouched; job 83's backup covers it); a BACK COPY of each of the eight
cliff pieces 1.5 studs behind the original, 0.8 lower and 0.3 away from the notch (a gap between slabs looks onto a solid
slab of the same banded rock; the shift keeps the copies' gaps from lining up with the originals'); a STRATA PLATE wearing
the cliff's own texture 2.6 studs behind each 8-stud segment's face, under its cover, for whatever stays open; the hill
beyond the west outcrop probed for its surface material (reported, not changed). Everything in SouthGorge.Rock.CliffBacking2,
no collision. Send the `QQ CLIFF2` line and play pictures from the b2, whole-wide, far-right and above spots. No publish.
Runner 4 play-test preview of job 84 (52773f8; pictures tools/falls/shots/cliff-j84-preview-*.jpg): the corner by the falls
reads as continuous banded rock, the west cliff's top bands whole, the west end whole; left: a smooth tan lump of sandy
ground on the top edge at the right of b2 and a rounded brown lump at the top of the east cliff's corner by the notch (the
sandstone-swapped ground where the bands stop short of the notch); the dark patch on the grass hill beyond the west outcrop
is further west than the probe (x < 8). 28 strata plates (5 tops 0.1-0.4 above their cover), 8 copies; from above a copy is
the first hit on 16 of 2572 rays (east side). Shown to Shannon; not installed.
Result job 84 (runner 4, 52773f8, installed at Shannon's "install it so I can look in Studio"; not published): 8 back copies +
28 strata plates in SouthGorge.Rock.CliffBacking2; 254 carves; job 83's blocks, sandstone and LipPlate kept; the terrain
backup CliffTop_pre1 (before both jobs) still there. Shannon flies the Studio camera along the cliff and gives her verdict.

Shannon (Oct 10 evening): "the thing that needs to be fixed right now is the blue bulge at the right corner of the top of the
falls; the fix last time was adding clumps on top of it; it worked on the left side but not on the right, you might just need
some more clumps".

## Job 85: more clumps on the lip's right corner (Studio EDIT; dry run / preview, then ask Shannon)

tools/falls/lip_clumps1.lua: from six viewpoints on the Porto side it finds every spot in the corner box (x 156..180, y -11..4,
z -553..-539) where the river's terrain Water is the first thing seen, sets a smaller clone of LipRockW (0.45-0.8 of its size,
turned at random, nudged toward the viewer) on the densest spot, looks again, up to 12 clumps until no water shows. Clumps
in SouthGorge.LipRocks as LipClump_N, anchored, no collision. Send the `QQ LIPCLUMP` line(s) and pictures from the c3 and c4
spots. Undo: delete LipClump_*. No publish.
Result job 85 (runner 4, 73f0c4a v2, installed at Shannon's "Install, and ask for the sliver too"; not published): 364 water
sightings before, 0 after; LipClump_1 (166.1,-9.9,-550.2) size (9.3,5.7,6.9), LipClump_2 (163.8,-7.7,-549.0) size (5.7,3.5,4.3),
no collision. Pictures tools/falls/shots/lip-j85-preview-c3/c4.jpg. Left: a thin blue line between LipRockW's underside and
LipClump_1's top at x 167-168, y -7 (the pale LipPlate seen through the gap, not water).
Runner 4 handover (78%+, no new jobs): PlaceVersion loaded 1301; jobs 81, 83, 84, 85 unpublished (Shannon presses Alt+P; the
runner cannot publish); play-test previews paste the script body as code (no loadstring there); pictures in
C:\Users\slard\Create-repository-shots and tools/falls/shots/ (git add -f); the dark patch on the hill west of the outcrop
(x < 8) still open; her API access off.

## Job 86: the sliver at the lip's right corner (Studio EDIT; ask Shannon first) - for runner 5

tools/falls/lip_sliver1.lua: a third small clump (0.38 of LipRockW) in the gap at (167.4,-7.1,-550.4), and the LipPlate's
colour to the sheet's white (ColorWas kept). Send the `QQ SLIVER` line and a picture from the c4 spot. No publish.
Shannon's verdict from the live game (Oct 10, published 19:26Z), her words: "the balloon ride is fine the cliff's bald spots
look fixed the blue bulge is mostly fixed but there is still a small section to the left between the 2 clods covering it.
(the thin blue sliver on the left is still there." -> cliff done (83 + 84); balloon as is; job 86 (the sliver) next, runner 5.

Shannon (Oct 10 evening): "next and as soon as possible, we need popups some place earlier in the game to encourage players
to like and set notifications, join the community and invite friends to play" ... "a system, like we were talking about
earlier, like to gift the backpack or double acorns for players with invites in same game".
Code map (4 readers, Oct 10): items persist only through RS.AwardItems:Fire(player, id, n) -> Item_<id> (saved); acorns are
the Acorns attribute for the screen PLUS RS.AwardAcorns:Fire(player, n) for the save (two lines everywhere; the Robux packs
are 150/500/1200); the daily card is the popup precedent (DailyGui, navy/gold/cream, DisplayOrder 15); OpenPanel on PlayerGui;
HUD buttons can be parented into pg.HudBar.Bar from outside. Roblox APIs: NO way to check a like or an EXPERIENCE favourite
(AvatarEditorService is assets/bundles only) and CanPromptOptInAsync false is ambiguous -> the like row is on trust;
GroupService:GetGroupsAsync verifies the community; SocialService:PromptGameInvite + Player:GetJoinData().ReferredByPlayerId
for invites (sanctioned by Roblox's referral guide).

## Job 87: the Gifts system (Studio EDIT; preview, then ask Shannon)

tools/gifts/install_gifts1.lua (from make_install_gifts1.py; src/GiftsServer.lua, src/GiftsClient.lua): workspace.Gifts +
RS.GiftsAction / GiftsEvent. The card "Gifts for squirrel friends" pops up once per session 90 s after the save loads
(while the first two gifts are unclaimed, no panel or daily card up); a Gifts button in the HUD bar opens it any time.
Row 1: like + favourite + notifications -> the Backpack (Roblox's notifications prompt, then "open the Roblox menu, press
the thumbs-up and the star", then Claim; on trust). Row 2: join the community -> 150 acorns (GroupService:PromptJoinAsync,
then the server checks GetGroupsAsync). Row 3: invite a friend (SocialService invite prompt) -> while the friend who came
on your invite is in the same server, BOTH earn double acorns: every ledger gain under 140 is paid again (Robux packs never),
an "x2" rides on the purse, a toast says who with. Attributes on workspace.Gifts. Send the `QQ GIFTS` line; play-test: the
card at 90 s (set PopupDelay 5 for the test), the HUD button, the Join flow with Shannon's account (she owns the community:
AlreadyMember -> 150 acorns once), the Claim (backpack on the back). No publish.
Result job 86 (runner 5): v1 installed at Shannon's yes (LipClump_3 at 167.4,-7.1,-550.4 scale 0.38; LipPlate whitened,
ColorWas kept); runner 5's rays found the sliver is terrain WATER 0.2-0.5 in front of the plate at x 168.3..169.2, y -6..-7
(inside the sheet's x range, hidden from job 85's count by its stand-in). v2 (1c2164f): the clump at 168.2,-7.0,-550.3 scale
0.46, the plate left alone; previewed next, installed on her yes with the plate put back from ColorWas. Not published.
Result job 86 v2 (runner 5, 1c2164f, Shannon's yes; not published): LipClump_3 at (168.2,-7.0,-550.3) size (5.3,3.3,3.9), the
plate back to 212,236,240 (ColorWas cleared). Preview: no blue from four viewpoints; water-first rays 142 -> 3, those behind
the sheet's edge. The lip's right corner is done. Next: job 87 after the review.
Job 87 review (2 agents): blocking - the client dropped the server's second return value (every reply nil) and refused to
open while OpenPanel was "map"/"collection" (the HUD never clears those); should-fix - a double community grant across the
web-call yield, "state" calls restarting the rate limit, stale state under deferred signals, the footer note over "Later",
blank buttons before the first state, the installer flipping false attributes back to true; nits - the HUD bar's fixed
216 px (now 272), phone y 78, shorter row titles, re-link on rejoin, no count while the save is unknown, BoostMaxGain 150.
All applied (commit below). Known limit kept: a single in-game gain of 150 or more is not doubled (the Robux packs start at 150).
Preview job 87 (runner 5, 7788820, play test on the phone emulator; NOT installed): the card at 5 s, Join -> 110 to 260
acorns and Item_gift_community 1, Turn on -> Claim -> Item_gift_like 1, Item_backpack 1, WornBackpack; the invite sheet
opens; Later / the HUD button / the map hand-over all fine; pictures in tools/gifts/shots/gifts-j87-phone-*.jpg. Shannon,
watching: "can you make those buttons more sparkly?" and, on the timing (visits run 8-15 min before the Italian map, the
runner proposed first squirrel found or 3 minutes): "yes, please do 3 minutes".
Revision 2 (this commit): the three gold buttons sparkle (a pale sheen sweeping across every ~2.7 s via a UIGradient
Offset tween, a light rim UIStroke breathing, four little four-point twinkles per button popping in and out at the ends
of the button, away from the word; all of it off once a row turns green). The popup now follows the FIRST SQUIRREL FOUND
this session (player attributes SquirrelsFound / FoundIds rising by 1-2 after the save's baseline; FindSettle 5 s later),
with PopupDelay as the fallback, now 180 s; FirstFind false turns the find trigger off. Play test: find one squirrel and
expect the card about 5 s later; with FirstFind false and PopupDelay 15 expect it at 15 s (then PopupDelay back to 180,
FirstFind back to true); two pictures a second apart show the sheen moving.
Result job 87 rev 2/3 (runner 5, play-test previews, NOT installed yet): rev 2 (010f19e) - Shannon: "I don't like the
graphics you did, the moving glow is ok but those little flower things that are wannabe sparkles look really dumb"; the early
card in that run was her tap on the screen ("I tapped the screen"). Rev 3 (cd54d02): twinkles gone, the sheen and the rim stay;
the trigger prints what armed it and what fired it. Logged runs: FoundIds + SquirrelsFound 0 -> 1 on the test server -> "popup
due after a find at 20.9s (found 0 -> 1 ...)" and the card 5.3 s later; FirstFind false + PopupDelay 15 -> "the fallback", card
at 15.4 s (an 88 -> 89 step did not bring it early). After Join: the row green, no sheen, 150 acorns. Pictures
tools/gifts/shots/gifts-j87r3-phone-*.jpg (and j87r2 sparkle a/b). Waiting for her install yes.
Rev 3 verdict (Shannon): "I want a sparkle gold outline around the buttons, they are quite plain". Rev 4 (this commit): a
3 px gold outline on each gold button with a bright glint travelling round it (a UIGradient on the UIStroke, Rotation 0 -> 360
every 2.4 s), the face sheen kept and widened a little; green (done) buttons plain. No twinkle shapes.
Rev 4 verdict (Shannon, live): "no, those buttons are UGLY", "The glow should be on the outline of the buttons not the text".
Runner 5 measured why: a UIStroke on a TextButton defaults to ApplyStrokeMode Contextual, so rev 3's and rev 4's rims stroked
the LETTERS, never the button. Also seen on the real phone screen (the capture tool leaves CoreGui out): Roblox's tool hotbar
(y 305..375 on the 667x375 phone) lay over the card's bottom and "Later". Rev 5 (this commit): ApplyStrokeMode Border (the
glinting gold ring is on the button's edge); the phone card is 216 tall (rows 44, footer 32 = "Later" only, ending at y 294,
above the hotbar) with one-line gift texts, and a note takes the subtitle's line for a few seconds instead of a footer.
Result job 87 (runner 5, rev 5 at 598bb2a, Shannon's yes; INSTALLED in Edit, not published): workspace.Gifts (GiftsServer
8379, GiftsClient 19711; GroupId 969906332, CommunityAcorns 150, BoostMaxGain 150, LikeReward backpack, PopupDelay 180,
FirstFind true, AutoPopup true, BoostOn true), RS.GiftsAction / GiftsEvent, HttpEnabled back off, PlaceVersion 1301. Preview
measured: rims Border on all three, the ring on the edges; phone card y 20..236 inset, "Later" 206..232, hotbar from 247
(11 px clear, real screen checked); notes one line each; Turn on -> Claim -> Item_gift_like 1 + Item_backpack 1; Join ->
160 -> 260 acorns, Item_gift_community 1, "Thank you" green. Not checked: desktop layout, the acorn ding, x2 with a second
player. Pictures tools/gifts/shots/gifts-j87r5-phone-*.jpg. Unpublished in Studio: job 86 v2 and job 87.
PUBLISHED by Shannon at 00:51:58Z Oct 11 (games API "updated"; "I have published the updates"): the live game carries job 86 v2
and job 87 rev 5. Nothing unpublished in Studio.
Live finding (Shannon, during the job 88 play test): "the interact button is sitting above the gift modal"; "the gift modal
should always be on top of anything else on the screen until it is closed" (PromptTouch DisplayOrder 30 over GiftsGui 15;
picture tools/gifts/shots/gifts-live-pill-over-card.jpg). Rev 6 (this commit): GiftsGui DisplayOrder 100 (above every other
ScreenGui, FilmMenu 60 included); its full-screen shade then also takes the taps the pill would have had.
Shannon (phone emulator): "with that gift icon at the top that row on mobile is suddenly very crowded up there, could we
maybe stack those icons down the right side instead and maybe keep the gift icon top to the left of the passport?" Rev 7
(this commit, GiftsClient, phones only): the bar's UIListLayout turns Vertical (Passport, Purse, Squirrels, Map down the right
edge at x 609..657, y 8..224 on the 667x375 phone), the gift box sits on the top row at x 553..601 (left of the Passport),
the squirrel Panel and the MapPanel (anchored top-right at y 114, placed once by HudBarClient) move 56 px left so their right
edge is at 601, re-applied if HudBarClient puts a rebuilt Panel back; the x2 badge sits left of the purse. Desktop unchanged.
Preview rev 7 (runner 5, 8e5e653, NOT installed): the column itself is clean (Bar x 609..657, y 8..224; gift box 553..601;
no overlap with the title pill 216..451, Hint, jump, hotbar, or Roblox's capture bar at x 557..601, y 125..249 - 8 px clear),
but the panels moved 56 px left made two new overlaps: SquirrelHUD.Panel (x 76..601) over the Hint button by 40 px, and the
MapPanel's +/- buttons under the capture bar. Pictures tools/gifts/shots/gifts-j87r7-phone-*. Runner 5 stopped there (memory).
Rev 8 (this commit): the panels stay where HudBarClient puts them (right edge 657, y 114); while the squirrel panel or the map
is open the column FOLDS AWAY - only that panel's own toggle stays, parked on the top row at x 497..545 (left of the gift box;
found by its "Tip" label text), the Passport stays at the top of the column, Purse and the other toggle hide - and the column
returns when the panel closes (Visible watched on SquirrelHUD.Panel and HudBar.MapPanel, re-hooked on a rebuilt SquirrelHUD).
Desktop unchanged. Runner 6 (session_01TQwZKeCYsD9TwPfGwTDoud, "runner 6 ready" at 7fc8f73) previews this one.
Preview rev 8 (runner 6, eec1019, NOT installed): the column, the fold and the card all measured as written (pictures
tools/gifts/shots/gifts-j87r8-phone-*). Shannon: "when you click the icon boxes, the modal should open to the right and under
them, not on top of them"; of three sketches she chose "squares stay, list beside them". Rev 9 (this commit): no fold; the
squares never move; SquirrelHUD.Panel and HudBar.MapPanel keep HudBarClient's y (64, under the top row) but their right edge
moves to -118 from the screen's right (x 549 on the phone: left of the column at 609 and of Roblox's capture bar at its
default spot 557..601), and their UIScale is capped to the room between the Hint button (ends 116) and that edge: on the
phone the squirrel list becomes 425 x 177 (scale 0.764, was 524 x 219), the map stays 295 x 219 at x 254..549. Position,
Size, Scale and ViewportSize changes are followed, so HudBarClient's own refits are re-capped. Desktop unchanged.
Result job 87 rev 9 (runner 6, 89d4fbe, Shannon's "Install as shown"; INSTALLED in Edit, NOT published): QQ GIFTS DONE ...
GiftsClient 23760 ...; the old Gifts folder is HudBackup.Gifts_pre_1. Preview, 0 overlaps in every state (phone + real
screen): column 609..657, gift box 553..601; squirrel list 124..549 y 64..241 (scale 0.7644; portraits 47 px, a tap opens the
card); map 254..549 y 64..283 with +/-/Me at 517..541; panel switching clean; HudBarClient-style refits re-capped at once; the
card at DisplayOrder 100. Pictures tools/gifts/shots/gifts-j87r9-phone-*. Unpublished in Studio: job 87 rev 9.
Shannon after the install: "maybe move the gift icon a little over to the left so there is a little room between it and the
passport icon". Rev 10 (this commit): the gift box's right edge 20 px left of the Passport instead of 8 (phone x 541..589;
COLUMN_X -78). Nothing else changed.

## Job 88: squirrel chatter - the Porto squirrels and both church mice talk to passers-by (Studio EDIT; preview, then ask Shannon)

Shannon, Oct 11: "church mice at both churches tell players that Jesus loves them as they walk by, with an Italian and French
flair"; the treasure hunter "quirky and cryptic and cute about finding treasure"; the old couple "sweet about staying together
for so many years"; "they should not talk to the player all at once, it should not be predictable, it should be scattered";
the fish seller "something about crabbing"; the lifeguard "not going swimming right after pizza"; "the things everyone says
should be a little funny". Housekeeping note 4 (Oct 10).
tools/chatter/install_chatter1.lua (from make_install_chatter1.py; src/ChatterLines.lua, src/ChatterClient.lua): a folder
workspace.SquirrelChatter with ChatterLines (44 speakers: the 43 Porto squirrels less Tonio, who has TonioTalk, plus the
French church_mouse; 200 lines) and ChatterClient (RunContext Client). Every 0.5 s: for each speaker with a model in
workspace (<id>_color once found, else <id>_gray), within Range 10 studs of the player -> an "arrival" the first tick, and
ONE arrival may speak by Chance 0.55 after 0.4-2.6 s; then Gap ~9 s of silence for everyone and Cooldown ~120 s (+-30%) for that
speaker; a failed roll rests the speaker 20 s; standing among them, one pipes up every Linger ~45 s. Nobody speaks while any
SquirrelBubble is showing (screen: PlayerGui.SquirrelBubbleGui children; VR: the SquirrelBubbleVR billboard on the part).
A speaker talks once you have found it (FoundIds), the mice too (Shannon: "the church mice should only say it after
they are found"); TalkUnfound true lets hidden ones talk. Attributes on
the folder: Range, Chance, Cooldown, Gap, Linger, Secs 4.2, TalkUnfound, Enabled. QQ CHATTER line names any speaker id with
no model in workspace. Play test: walk the piazza (the old couple, the mouse by the Chiesa di Santa Marina), the quay
(Beppe, Rocco), the Groves (treasure hunter); expect one bubble at a time, not every squirrel, not on every pass; in the
French village the church mouse by the church. No publish.
Job 88 review (3 readers + 11 refuters; 11 confirmed, 1 refuted): VR - the "someone talking" test only saw the picked
squirrel's own billboard (two bubbles at once with Beppe/Enzo/Tonio/Bella in VR) -> it now looks through every speaker's
colour and gray models plus Tonio and Polpo; a line dropped at speak time (player walked on, or a bubble came up) still
charged the full Cooldown/Gap, and with a 0.4-2.6 s pause about half of a walk-through's picks were dropped -> the pause is
0.2-1.2 s, the rests are charged only when the line is said (a drop leaves the 20 s rest); the clock keeper (balcony, ~28
studs up) and Tito (washing line, ~14 up) could never come within Range 10 -> per-speaker `range` in ChatterLines (34, 20).
Lines: Beppe's "Got crabs?" double meaning -> "Caught any crabs?"; the French mouse had two of the cousin's lines word for
word -> his own sermon gag; Officer Acorn's "looking up", the postcard "keeps the family away", three earnest sea-glass
lines, the Good Neighbor without her lasagna, the old couple's "sixty years" against the registry's fifty-four -> rewritten.
Refuted: the treasure hunter's "pirate buried his heart" (fine for a child in context). 196 lines, longest 90.
Second pass (3 verifiers): Polpo is workspace.Grotta.PolpoBrontolone (fixed by path); a dropped linger pick brought the
next one at once (the linger clock now restarts on every pick); OTHER scripts' bubbles (Enzo's tip, Tonio's walk-up, Beppe's
sale, Polpo, the postcard) are drawn with no check and could land ON a chatter bubble -> the installer now also patches
RS.SquirrelBubble (vr1 8415 -> vr2 8854, tools/bubble/SquirrelBubble.module.vr2.lua; backup HudBackup.SquirrelBubble_pre_vr2):
Bubble.talking() (any bubble up, screen or VR) and newest-wins (a new bubble destroys any other), the client uses talking()
when present; a squirrel found while standing at it now gets its arrival roll 2 s after the reveal; after someone else's
bubble the chatter holds the floor Gap/2; on a flat screen a line is dropped unless the speaker is in the viewport (the clock
keeper 28 studs up would otherwise speak off-screen). In a play test the module patch only takes effect for scripts that
require the module after it (the chatter itself); the old scripts keep the old copy until a play test starts after the Edit install.
Preview rev 1 (runner 5, 34790c0, test server): QQ CHATTER DONE ... 44 speakers, 196 lines ... every speaker has a model.
Old couple at 7 studs for 9 s: silent (the roll); the opera singer spoke; 120 s standing between the opera singer and the
accordion: one line (the accordion's) at 83 s; never two bubbles. Problems: the opera singer's Listen pill (PromptTouch 30)
over her bubble's top half; the church mouse's bubble half off the left edge while the Gifts card's shade was over it.
Rev 3 (this commit): no line while the speaker's own interact pill is up (ProximityPromptService PromptShown/Hidden, a shown
prompt within PillRange 8 studs of the speaker), while any panel is open (PlayerGui OpenPanel, the daily card), or on a flat
screen unless the speaker sits where the bubble has room (x 8..68 % of the viewport, y 30..95 %).
Preview rev 3 (runner 5, 0c9e6d4, test server, quick-look Chance 1 / Cooldown 10 / Gap 3 / Linger 8): the SquirrelBubble
swap ran (8415 -> 8854, Bubble.talking a function on the client); pill rule PASS (opera singer silent with her Listen pill
up; her prompt reaches 17 studs, so with the pill rule she chats only from beyond it); Gifts card up -> silent, closed ->
the old couple's line within 2 s PASS; never two bubbles; but Rocco spoke under a "Cowrie shell / Pick up" pill (phones draw
every pill by the player's head, anywhere on the screen), and a line dropped at arrival cost a long wait. SHANNON, watching:
"those voice boxes are spaced wrong, that is over top of the speaker, not to his side"; "the speech bubble locations are all
jacked up. They should be placed to the side of the squirrels, so you know they are saying it but it does not cover them in
any way" (the module centred the bubble just above the head: old couple at 333,199 -> bubble x 247..476, y 41..211; part of
what she saw was the runner's camera rig behind her avatar). Rev 4 (this commit): SquirrelBubble vr2 is now 10015 chars and
draws the screen bubble with its tail tip at the head's upper right (AnchorPoint 0,1), mirrored to the upper left at the
screen's right edge, clamped inside the screen under the HUD row (TOP_GUARD 24 inset px); the installer swaps the whole Source
when it equals vr1 exactly (else aborts). Chatter: on a touch device ANY shown pill blocks a line; a picked line waits up to
PendingSecs 6 for its moment (speaker in view x 8..92 %, no pill, no panel, nobody talking) instead of resting the squirrel.
Rev 4 verification (3 verifiers): the placement used the part's centre plus 0.55*Size.X along the camera's right, so
side-on the long squirrels (Nonno Reti 2.3 x 3.4 x 4.25, Giulia, Beppe) were 19-49 px inside it and on a phone (Y clamp
engaged) the paper lay over them; the right-edge clamp could push a phone bubble under the HUD column; with no room either
side the clamp pushed the bubble back over the speaker; the weak-keyed `current` could lose a live VR billboard; on desktop
pills are also drawn by the player's head (PromptUI on the Head), so the per-speaker pill test missed them; the touch early
return skipped the stale-prompt sweep; a pending line followed another script's bubble with no gap. The installer's V1/V2
equality was proven byte for byte. Rev 5 (this commit): vr2 regenerated from vr1 by tools/bubble/make_vr2.py (11491 chars):
the bubble placed off the speaker part's PROJECTED BOX (8 corners each frame), right of it or left of it mirrored, the side
kept for the bubble's life unless it stops fitting, never clamped into the speaker (overhangs the screen edge instead), the
bottom at the box's top when that fits under the HUD row (then leaning a third over so the tail meets the head) else alongside
at body level, clear of the phone HUD column (62 px) where it runs beside it; `current` a plain table cleared explicitly.
Simulated (23040 cases: 4 squirrel boxes x 5 distances x 4 pitches x 12 yaws x 3 view positions x 4 bubble sizes x phone and
desktop, the real bubble mask): 0 touch the squirrel's silhouette; 239 overhang a screen edge (no room either side; the
chatter never starts a line there). Chatter: any shown pill blocks on any screen (VR: within PillRange), stale prompts are
swept first (gone, disabled, or farther than their reach + 4 from the player), a pending line waits Gap/2 after someone else's
bubble; every compile check now runs before the bubble swap.
Shannon, on the rev 5 preview: "you are making the speech bubbles TERRIBLE; why is it so hard? you have the original speech
bubbles before correct". Rev 6 (this commit): the installer no longer touches RS.SquirrelBubble at all (the live vr1, 8415, is
what she calls correct; vr2 and make_vr2.py stay in the repo unused). Her rev 3 complaint was mostly the runner's test camera
behind her avatar, not the module. The chatter uses its own checks (the bubble ScreenGui's children on a screen, the speakers'
billboards in VR) and on a screen speaks only when the speaker stands at x 8..68 %, y 40..95 % of the view, so the original
up-and-right bubble has room and stays under the top row.
JOB 88 CANCELLED (Shannon, Oct 11): "the original speech bubbles were right, all of these new ones are very very wrong";
"remove ANY new speech bubbles completely, we are just going to keep the ones we had originally before tonight". Nothing from
job 88 is to be installed: no workspace.SquirrelChatter, RS.SquirrelBubble stays vr1 (8415). Runner 6 asked to stop the preview
and confirm Edit is clean (undo on her yes if anything got in). tools/chatter and tools/bubble/*vr2* stay in the repo, unused.
Confirmed by runner 6: Edit is clean (no SquirrelChatter, RS.SquirrelBubble = vr1 8415, no job 88 backups); nothing from job 88
was ever installed. Studio holds Gifts rev 9, unpublished; rev 10 (c991424) not previewed. Runner 6 idle until Wednesday.

## Job 89: one click to the boat after the last French squirrel (Studio EDIT; preview, then ask Shannon)

Shannon, Oct 11: "when the player finds the last squirrel on the France map, we need a way to get their character to the dock
where the boat is in a non awkward way (incase they miss that the boat is there)"; her pick of three: "card, then fade"; and "I do
want to remove the flow if they don't have the backpack also, they should be able to take the boat with one click" (read as the
parachute pack: the jetty sign sent players back to the forest to borrow it from the Sky Diving Squirrel first).
tools/boatinvite/install_boatinvite1.lua (make_install_boatinvite1.py; src/BoatInviteServer.lua, src/BoatInviteClient.lua):
- workspace.BoatInvite + RS.BoatTake (BindableEvent). The card (DisplayOrder 20, daily-card look, phone y 78..246): "All 44
  found! The boat to Italy is waiting at the river dock. Your parachute is packed for the waterfall!" [Take the boat] [Later].
  Shown 6 s after the 44th French find (Found_forest + Found_village + Found_domaine) at a clear moment (no OpenPanel, the
  squirrel's reveal card closed, no daily card, not seated, in France), and once per visit 25 s after joining while Item_porto
  is 0. [Take the boat] = one click: the luggage cart's fade ("The River Dock", workspace.Travel.TravelEvent), the player on the
  jetty deck beside the moored boat, then RS.BoatTake -> BoatServer's own take(): aboard and off down the river.
- workspace.Boat.BoatServer, exact-string patches (abort with nothing changed unless both anchors are found once; backup
  HudBackup.BoatServer_pre_invite1): in take(), everyone with all 44 gets HasChute (the parachute packed) on boarding, by the
  card or by the jetty prompt; after the prompt hookup, RS.BoatTake calls take(); the jetty sign's "Ask him first!" text
  becomes "Every squirrel who has found all 44 gets a parachute packed for the drop. Hold on tight!" (source and live sign;
  the old text is printed for undo). The Sky Diving Squirrel still lends his chute to anyone who talks to him.
- Gifts rev 10 also gains "boat" in its MODAL list, so the gifts popup waits for the boat card.
Preview plan: on the test server set Item_porto 0 (her save has 88/88) and rejoin-style wait 25 s: the card; Later closes it;
then Found_domaine -1 and +1 to see the post-find card after 6 s; [Take the boat]: fade, aboard, the boat leaves, the parachute
opens over the falls; once also with a parachute already borrowed; the jetty sign's new text. Phone emulator + real screen.
PUBLISHED v1317 at 01:59:55Z Oct 11 (runner 6, from the Studio log): Gifts rev 9 is live (the phone HUD column); job 88 was
never in Edit. Job 89 preview waits for Studio to be opened. Preview plan changed: the test server gets only BoatInvite and a
stand-in RS.BoatTake (prints); the real BoatServer patch is checked after the Edit install in a new play test (undo: the backup).
Job 89 rev 3 (Shannon: "don't say parachute packed for the waterfall"): the card reads only "All 44 found!" / "The boat to Italy is
waiting at the river dock." [Take the boat] [Later]. Rev 2 (76f6758) also: the grant first in take(), the sign's last line dropped.
Job 89 rev 4 (runner 6's read-only search: the jetty prompt in BoatClient read "Take the boat (no parachute!)" / "Bateau - see
the Sky Diving Squirrel first"; Shannon: "the waterfall should be a surprise"; "if you don't now get the parachute from the
skydiving squirrel, that dialogue does not make sense"): the installer also patches BoatClient's prompt text to "Take the boat" /
"Bateau" (backup HudBackup.BoatClient_pre_invite1), and BoatServer's Sky Diving Squirrel: no lending (his SetAttribute and
attachPack lines commented out) and new lines - at 44: "All 44! Now THAT is a high score." / "I once jumped out of a plane and
landed in a pie shop. Best day of my life." / "Seen the boat at the river dock? Take it. Trust me."; under 44: "Find all %d
squirrels (%d so far) and I will tell you my best skydiving story!"; again: "Still here? The boat at the river dock is waiting
for you!". Every anchor checked before any change. Still mentioning the waterfall/parachute, NOT changed (ask her): the
Passport's boat outings (Catalogue 24-27: "...the Sky Diving Squirrel in the forest has something you will want before you
leave", "Ride the river all the way to the waterfall", "Float down to Porto Nocciola under the Sky Diving Squirrel's
parachute" + "talk to the Sky Diving Squirrel ... he lends you his spare parachute"). The journal lines after the ride are fine.
Job 89 rev 5 (Shannon: "yes please reword the hint, no mention of waterfall or parachute"): the installer also rewords the
Passport's boat outings in workspace.Passport.Catalogue (6 exact substrings, backup HudBackup.Catalogue_pre_invite1; ids, names,
icons and stamping unchanged): boat "... see where it goes. Hold on to your hat!"; falls hint "Ride the river all the way to the
end." + detail "The river leaves French Squirrel Country through a gorge. Keep going all the way to the very end, boat and all,
and see where it takes you."; chute hint "Arrive at Porto Nocciola with dry feet." + detail "Once you have found all 44
squirrels, take the boat all the way down the river. How you reach the shore is a surprise!"; porto "Porto Nocciola lies where
the river ends." (checked against passport/src/Catalogue.lua: each anchor once, the result compiles).
Runner 6 (Oct 11): its own read-only anchor count hung Studio (an empty needle in find(); nothing written; Edit = v1317); step-1
preview done before that: the card 6 s after the 44th find, x 174..494 y 78..246, 0 overlaps; Later closes; [Take the boat] =
fade, BoatTake fired, she stood on the jetty facing the boat. CONFIRMED the jetty prompt read "Bateau - see the Sky Diving Squirrel
first" / "(no parachute!)" (rev 4 covers it). NEW live since Gifts rev 9: on the phone the interact pill beside the head (PromptTouch
HeadStack) fell back over the Purse/Squirrels squares (x ~365..662). Fixes (this commit): the boat installer's count helpers
return 0 for an empty needle; Gifts rev 11 = rev 10 + a guarded exact-string patch of workspace.PromptUI.PromptClient (30345 ->
30763, tools/prompts/src/PromptClient_pill2.lua, backup HudBackup.PromptClient_pre_pill2): when no spot right of the head fits,
the pill tries the head's left side and falls back there instead of over the column.
Result job 89 + Gifts rev 11 (runner 6, 4969902, Shannon's "Install both, then test"; INSTALLED in Edit, NOT published): QQ GIFTS
DONE ... GiftsClient 23839 ...; PromptClient 30345 -> 30763 (backup HudBackup.PromptClient_pre_pill2); QQ BOATINV DONE:
BoatInvite (server 4533, client 5777); RS.BoatTake; BoatServer 40801 -> 41494; BoatClient 21191 -> 21020; Passport.Catalogue
11607 -> 11390; the sign's last line dropped. All 16 anchors counted once each beforehand. HttpEnabled was found TRUE after the
restart (the frozen call's switch-back never saved) and put back to false. Rev 6 of BoatInvite (this commit): the boat card's
DisplayOrder 20 -> 100, so no interact pill (30) can sit on it; a re-run of the installer changes only the BoatInvite folder
(BoatServer, BoatClient and the Catalogue report "already").
Verification job 89 + Gifts rev 11 (runner 6, play test after the Edit install, phone emulator): ALL PASS. Gift box 541..589, 0
overlaps; the Sky Diving Squirrel says "All 44! Now THAT is a high score.", no pack; the jetty sign without its last line; the card
6 s after the 44th find (the Talk pill at DisplayOrder 30 lay over its corner: 9a1fcbe fixes it, to install on her yes); [Take the
boat] one click: in the BoatSeat at once, HasChute + ChutePack, no warnings, over the falls the parachute opened, landed in Porto,
Item_porto 1 (the Gifts card's 180 s fallback came up on landing); the jetty prompt "Bateau" / "Take the boat"; the pill fix puts a
long pill LEFT of the head (5..305); the Passport outings reworded. Pictures tools/boatinvite/shots/boatinv-j89v-phone-*.jpg.
Job 89 re-run at 9a1fcbe INSTALLED in Edit on her yes: BoatInvite client 5901 with DisplayOrder 100 (old folder
HudBackup.BoatInvite_pre_1); BoatServer 41494, BoatClient 21020, Catalogue 11390 unchanged. Studio holds, unpublished: Gifts rev 11
+ PromptClient pill2 + job 89. She publishes next.
PUBLISHED v1322 at 12:52:07Z Oct 11 (Studio log, runner 6): Gifts rev 11 + PromptClient pill2 + job 89 (card at DisplayOrder 100,
to be confirmed as BoatInviteClient 5901 in Edit when Studio is next open).
Open question (Shannon): the Italy Guardian plinth (workspace.PortoKeeper, a clone of the French Champion plinth) shows "Darkknight"
with no statue. Runner 6's read-only survey is blocked until Studio is open; the logs show no PortoKeeper/Champion errors. Two
readings: the clone kept the French plaque's text and PortoKeeperServer never rewrote it, or Darkknight holds the Porto record and
the statue build failed. Plaque texts (Edit) + both servers' plaque code decide it.

## Job 90: the Guardian of the Harbour statue (Studio EDIT; test, then ask Shannon)

Shannon: "Darkknight was the first to complete the french map ... has a statue there, but in the Italy section, there is still no
statue but it has a plaque that also says Darkknight." Runner 6's read-only survey: the two monuments write only their own
plaques; both read "This could be you" in Edit, so the name is written at run time: Darkknight holds PortoKeeper_v1 "first" too.
PortoKeeperServer.buildStatue writes the plaque FIRST, then asks workspace.Champion.MakeStatue with a plain FindFirstChild at
server start; if ChampionServer has not made it yet (or the call fails) nothing is built and the key rests on the plinth, silently.
Shannon: "yes" to the fix. tools/porto_keeper/statue_retry1.lua (guarded, backup HudBackup.PortoKeeperServer_pre_statue1):
(a) that lookup waits (WaitForChild 30 s each) when the exact expression is found once, else left with a note; (b) appended: for
the first minute of a server, every 20 s, if a Guardian is recorded and no Figure stands, buildStatue(first) again (pcall).
Aborts with nothing changed unless "local function buildStatue(", "local first", "local F = script.Parent" each occur once and the
figure is built as name = "Figure". Test plan: a play test with KeeperDebug:Invoke(player) (the same MakeStatue path) BEFORE the
install, to see that the statue builds by the lighthouse; on her yes install in Edit; a NEW play test: KeeperDebug, then delete
PortoKeeper.Figure inside the first minute and watch the retry rebuild it within 20 s. She publishes; the next live server builds
Darkknight's statue.
Result job 90 (runner 6, c8c4e91, Shannon's "figure out what went wrong and fix it"; INSTALLED in Edit, NOT published): counts 1/1/1/1/1;
QQ STATUE DONE: PortoKeeperServer 11263 -> 11893; the MakeStatue lookup now waits; the retry appended. Live facts (Shannon, F9 on
a live server): the plaque reads GUARDIAN OF THE HARBOUR / OF PORTO NOCCIOLA / Darkknight / "First to find all 44 squirrels of
Porto Nocciola, on October 11, 2026", key resting, no figure; only "PortoKeeper: ready" in the log, no "MakeStatue failed" - so the
Invoke gave nil without erroring (makeFigure refused in the start-up burst) or mk was nil; the retry covers both. Pre-install
play test: KeeperDebug built the Porto statue with the key in the raised hand, 3 rounds, even alongside the French statue.
Job 90 retry test PASSED (runner 6, fresh play test): KeeperDebug crowned at 11.2 s, Figure destroyed at 11.2 s, the retry rebuilt it
at 31.6 s ("no statue yet for SelBell; building it again" -> "the statue of SelBell stands by the lighthouse"); KeeperDebug:Invoke(nil)
cleared it. Note: the retry ticks at 20/40/60 s only. She may publish; the next live server should raise Darkknight's statue.
Next report (Shannon): "the portraits in the French section have the characters in them continuously blinking in and out on mobile
and vr (but not on desktop)" - runner 6 surveying read-only (theory: the sitter models streaming in and out on low-memory clients).
Job 90 CONFIRMED live (Shannon): "that statue is there now".

## Job 91: the French gallery portraits blink on phones and VR (read-only survey first)

Shannon: "the portraits in the French section have the characters in them continuously blinking in and out on mobile and vr (but
not on desktop)". Runner 6's survey + village/build_portraits.lua's CLIENT: hookCanvas mounts a CLONE of each canvas's SurfaceGui
into PlayerGui and connects Canvas.AncestryChanged -> cleanup() (the mounted copy destroyed); slots.DescendantAdded -> hookCanvas
(mounted again). The slot models are ModelStreamingMode Default, so on low-memory clients (phones, Quest) the canvases stream out
and back in, and each cycle removes and re-adds the whole portrait. The Oct 9 VR fix (bust image instead of the viewport) did not
stop the blinking in VR, which points at the mount, not the rendering. Proposed fix (no script change): ModelStreamingMode
Persistent on each slot Model under workspace.PortraitGallery.Slots.
Result job 91 (runner 6, Shannon's yes "Try the streaming change now"; INSTALLED in Edit, NOT published): Slots has 9 Models
(Slot1..9, 7 BaseParts / 181 descendants each, canvas MeshPart 2.3x2.0x0.1, from 189,2,-14 to 217,2,-4); all Default ->
Persistent (QQ PORTRAITS DONE; attribute StreamingWas keeps the old mode = the undo). Scenes untouched. CAUTION (runner 6): her
answers "slow, every few seconds" and "only the character; the painted frame, easel and background stay" do not fully fit a
streamed-out Canvas (its SurfaceGui, background included, would vanish too). If the blink survives on her phone/Quest, the next
lead is PortraitServer's receipt-retry loop (deliver(): hang -> prepareModel -> UpdateAsync -> show() every 10 s doubling to
120 s while a paid receipt will not settle; "paid receipt awaiting retry" would repeat in the live SERVER log) - but that would
show on desktop too, so a device-only cause (ViewportFrame re-render on low memory, or the bust rbxthumb reloading) is also open.
Job 91 play test PASSED (runner 6): 9 slots Persistent, 9 mounted copies with a sitter at once, 0 added / 0 removed over 8 s, and
the slots stayed on the client from Porto (579 studs away). Edit holds job 91 (nine ModelStreamingMode changes + StreamingWas).
Shannon publishes and checks on her phone / Quest. Runner 6 idle after. (The Italian Hall of Fame: workspace.HallOfFame's
HallServer builds each French entry with Champion.MakeStatue - the model for Wednesday's monument.)

## Job 92: acorn thank-you gifts, paid the next time a named player joins (Studio EDIT; ask Shannon first)

Shannon, Oct 13: three players wrote to the mayor (La Poste); "went to gift them 1000 acorns as a thank you for writing; how can
we best do that for next time they log in?" - "I have their user names". tools/thanks: ThanksServer.lua, ThanksClient.lua,
make_install_thanks1.py -> install_thanks1.lua (usernames read from tools/thanks/names.txt, one per line, before generating).
workspace.Thanks.Gifts holds one StringValue per gift: Name = USERNAME, Value = acorns, attribute Id ("note1"; a later gift to
the same person = a new Id), optional Note. ThanksServer: on join, after SaveLoaded + Delay 8 s, every unpaid gift for that
username is paid through RS.AwardAcorns + the Acorns attribute (the game's own ledger, no DataStore) and flagged on the save as
Item_thanks_<Id> = 1 via RS.AwardItems, so it never repeats; the client shows a card (DisplayOrder 100, waits for a clear
moment): "A thank-you from the mayor" / note / "1000 acorns are in your purse." [Thank you!]. Shannon can add future gifts in
Studio with no code (a StringValue under Gifts). Cap MaxGift 5000. Test: the owner's own username in Gifts on the test server.
Job 92 names (checked on Roblox's user API): mentallyunstable_xo (display dakota, id 4161205246), blizzy_1718 (7902108387),
bdawg_012 (8009538846); 1000 acorns each, Id note1.

## Look survey (runner 6, Oct 13, read-only; place v1327 = jobs 90 + 91 published)

Lighting: ClockTime 14.5, Brightness 3, Ambient/OutdoorAmbient 70,70,70, EnvironmentDiffuse/Specular 1, GlobalShadows true,
ShadowSoftness 0.2, Exposure 0, Fog 350..1100 (dead: an Atmosphere is present). Sky: a six-image skybox (Bk/Ft/Lf/Rt 6444884337,
Dn 6444884785, Up 6412503613), sun 6196665106 at 11 deg, 3000 stars. Atmosphere Density 0.3, Offset 0.25, Color 199,199,199,
Decay 106,112,125, Glare 0, Haze 0. Bloom Intensity 1 / Size 24 / Threshold 2. SunRays 0.01. No ColorCorrection. No Clouds.
Terrain: WaterColor 52,104,78, Reflectance 0.55, Transparency 0.45, WaveSize 0.06, WaveSpeed 5; Grass/LeafyGrass colour
96,150,72. French ground = Terrain Grass (2504 of 4732 rays) + path/plaza parts; Terrain.Decoration / GrassLength unreadable from
execute_luau (Properties panel). Grass/flower props: Porto 1746, Village 105, Forest 23, Domaine 15.
Reading vs Shannon's "refined, same vibe, no time-of-day or haze change": the skybox is a custom one already (which images
decide the clouds; she said "better sky" - a sky with soft clouds is the candidate); shadows are already on and soft; water
is half-reflective and fairly opaque; the forest floor IS Terrain Grass, so grass decoration applies; Bloom threshold 2 means
lanterns barely glow; no colour grading. Plan for her preview, settings only: Terrain.Decoration on + grass length ~0.7 +
Grass colour a touch deeper; WaterReflectance 0.8-0.9 / Transparency 0.6-0.7 / WaveSize 0.1; Bloom Threshold ~1.2 (lantern
glow); ColorCorrection Contrast +0.06, Saturation +0.08; a cloud skybox for her to choose from (two or three candidates).
ClockTime, Atmosphere stay.
Result job 92 (runner 6, 1100f61, Shannon's "Yes, install"; INSTALLED in Edit, NOT published): QQ THANKS DONE ... gifts:
mentallyunstable_xo=1000, blizzy_1718=1000, bdawg_012=1000. Pre-checks: the names appear nowhere else; AwardItems accepts
thanks_note1; AwardAcorns only records to the ledger, so the server's attribute add is the single credit (no double pay).
Preview with a 50-acorn test line in her own name: paid 9.2 s after the folder went in (110 -> 160, Item_thanks_note1 = 1), the
card at x 173..493 y 78..246 with 0 overlaps, a rejoin paid nothing again. Her "it says 50 but it should be 1000, right?" = the
test line only; the three real lines are 1000. Pictures tools/thanks/shots. She publishes next.

(Oct 14: the week's handoff is tools/cloud/HANDOFF_cloud_2026-10-14.md; the Roblox cache cleanup on her PC was done by hand: 13.2 -> 15.3 GB free, rbx-storage 3.7 GB still to delete with Studio closed.)

## Job 93: READ-ONLY survey + pictures of site E for the Italian Hall of Fame (Studio EDIT mode; nothing changed) - runner 7

Shannon (Oct 14, to the cloud thread): "make this hall of fame look distinctively different from the one in France. I think that
the best place for it is E; so, yes" (E = Prato dei Fiori, the coastal meadow between the church and the lighthouse). The export of
Codex's daily Guardian is done (tools/porto_keeper/daily, runner 7) - skip that part. THE CLOUD THREAD'S BRANCH IS
claude/youthful-curie-8azx86 (it contains epic-hawking); pull it for every job; keep pushing pictures to epic-hawking.
1. Run tools/hall_italy/survey93.lua in Edit (read-only; ~15k raycasts, give it a few seconds). Send every `QQ HALL` line
   unchanged (the site E lines matter most: the flattest clear 26 x 18 windows, their centre, ground height, what stands near).
2. Pictures (Edit mode, no change): tools/hall_italy/view93_E1.lua and view93_E2.lua move ONLY the editor camera (E1 standing
   at eye height, E2 a high three-quarter view); one picture each as tools/hall_italy/shots/hall-site-E1.jpg / -E2.jpg
   (git add -f, push to epic-hawking). Sites A-D are not needed any more.
Raw URL base for this commit: https://raw.githubusercontent.com/selard73/Create-repository/<SHA>/tools/hall_italy/ (the SHA is
this commit's; the runner may also just read the files from the pulled branch and checksum them against the git blob).
Result job 93 (runner 7, 1457043; Studio Edit v1352, Oct 14 ~16:50Z; read-only, the editor camera put back afterwards): all 55
QQ HALL lines + the two QQ VIEW93 lines are in tools/hall_italy/survey93_result_2026-10-14.txt (unchanged). Site E: 4800 cells,
ground under all, water 68, blocked by things 1622, Grass 92%; 485 clear windows; the flattest three, all DEAD FLAT at y 2.0 (rise
0.0), 18 wide x 26 deep: centre (538, -1073); (544, -1089) and (544, -1101) with butterfly_squirrel_color within 6 studs. Ground at E
meadow middle (520,-1080) Terrain Grass y 2.0; E meadow west (470,-1050) y 1.8. The provisional (500, -1080) is not among the three
picked (the picker drops windows within 12 studs of a better one) but the meadow is flat there too (both spot rays 1.8..2.0). Sites A,
B, C: NO clear window; D: one at (378, -924), rise 8.8. Notes for the installer: in Edit, Champion.MakeStatue and MakeSquirrel are
MISSING (ChampionServer makes them at run time, so statues show only in a play test); PortoKeeper attrs print Facing null (JSONEncode
drops Vector3s; the value is a vector); PortoKeeperServer 14386 carries neither the job 28 nor the job 90 strings (Codex's rewrite).
Pictures: tools/hall_italy/shots/hall-site-E1.jpg (eye height from the church side: the meadow, the promenade wall and path, the
lighthouse and cottage beyond) and hall-site-E2.jpg (high three-quarter from the lighthouse side: the meadow with the fort, the town
and the church behind, the sea on the right, the Guardian plinth and a bench bottom right). Studio is shared with Codex today (it goes
in and out of play test on another part of the map), so job 94's play-test preview waits for a quiet window from Shannon.

## Job 94: the Belvedere dei Guardiani - play-test PREVIEW first (nothing installed; pictures for Shannon's yes) - runner 7

tools/hall_italy/install_hall1.lua (from make_install_hall1.py: install_hall1.template.lua + src/HallServer.lua; reviewed by two
readers, 17 findings fixed). What it builds: workspace.HallOfGuardians - a round mosaic terrace (R 17) on the meadow's edge, a low
parapet with a sea-blue majolica band on the sea side, a column with the gold harbour key, two lanterns, a lectern at the entrance
with the roll of the Guardians, Porto's own cypresses / lemon trees / harbour benches copied in; HallServer (17497 chars) builds a
pedestal + marble statue (Champion.MakeStatue, the acorn swapped for the harbour key) for every Guardian: No. 1 (Darkknight, the
historical "first" record) in the centre, each day's Guardian (Codex's daily_v2 ledger, one per 09:00 UTC day) right and left
of him in turn, the next empty pedestal with the resting key and "THIS COULD BE YOU". The list is READ from PortoKeeper_v1
(first + daily_v2) once a minute and 3 s after the lighthouse plaque names a new winner; never a write; Codex's PortoKeeperServer
is not touched. Provisional site (500, -1080), the front facing east (+x), the crescent toward the sea (west) - the survey's
site E window may move it; the installer measures the ground itself, aborts if the rise across the terrace is over 3 studs or
there is water/nothing under the rim, and reports anything standing within 19-21 studs (QQ BELV NOTE).
The installer also refuses to bury anything big (a tree, a wall, a path slab, a bench inside r 20.5: `QQ BELV ABORT: standing
inside the terrace's footprint ...`) and sets small props (flowers, grass) aside into HudBackup.HallOfGuardians_props_n.
STEP 0 (Edit, read-only, in the next Edit gap - BEFORE the preview): run tools/hall_italy/probe94.lua and send every `QQ PROBE94`
line: for five candidate centres it lists what stands within 22 studs (BIG things by name and box; small props counted) and the
terrain under the rim. The cloud thread then fixes the centre in make_install_hall1.py and regenerates install_hall1.lua (a new
commit on claude/youthful-curie-8azx86); pull before the preview.
PREVIEW (a play test on the test server; discarded on stop; Edit checked unchanged afterwards; no ask needed):
1. Start a play test. Run the installer's body on the SERVER (execute_luau, server context). In a play test it sets PreviewJson
   (three sample Guardians: SelBell, dakota, blizzy_1718) so the crescent shows statues. Expect `QQ BELV DONE ...` then, within
   ~30 s, "HallOfGuardians: ready - 3 Guardians on the belvedere (7 slots)" and three "Key" models in Slot_1..3. On
   `QQ BELV ABORT ...` send the line and stop.
2. Pictures with the GAME's own camera (walk the avatar there; no camera rig behind her): (a) from the front step looking at
   the crescent, (b) from the terrace's centre, (c) a high three-quarter view from the land side, (d) from the parapet looking
   back at the statues, (e) one close look at a pedestal tile and the lectern words. tools/hall_italy/shots/belv-j94-*.jpg.
3. Report: every QQ BELV line, the "HallOfGuardians:" log lines, whether each statue holds the key in the raised hand, whether
   the benches face the sea (their facing is a guess), the copies found (cypress / lemon / bench counts), whether the terrace's
   edge floats or buries on the slope, the tile and lectern texts legible, anything standing through the terrace.
4. Stop the play test; confirm Edit has no workspace.HallOfGuardians. Nothing is installed until Shannon says yes to the pictures.
Result job 94 step 0 (runner 7, 44484a9; Studio Edit v1352, Oct 14 ~17:15Z; read-only): probe94.lua run as committed (4740 bytes,
adler32 2575085141); all 57 QQ PROBE94 lines unchanged in tools/hall_italy/probe94_result_2026-10-14.txt. The rim at r 17.5 has
ground under all 12 points at every centre; terrain y 2.0 at (500,-1080), (512,-1066), (524,-1078), (538,-1073) [the last two dead
flat 2.0..2.0], y 0.4 at (486,-1060) [rim 0.4..2.0]. Above-ground BIG things, nearest first: (500,-1080): the Coastal stone pine grove
(11 parts, x 495..515 z -1103..-1085) at 3.0 studs - inside the terrace; the Sentiero del Faro paving from 17.7; Upper town to meadow
(the stair, 15 parts, x 462..522 z -1075..-1033) at 20.9. (512,-1066): the stair at 15.7, the pine grove at 17.1, 181 small props (the
most flowers). (524,-1078): the Drone Flyer's drone (x 525..527 z -1087..-1085, top 3.7) at 7.2 studs, the pine grove at 12.9.
(538,-1073): the Mediterranean umbrella pine (x 555..572 z -1072..-1054) at 15.8, the drone at 16.5, the Silver olive tree at 18.1,
170 small props. (486,-1060): the stair at 0.0 (on it), Sentiero del Faro landings and paving from 14.6, handrails from 19.5.
NOTE for the installer's big-thing check: every centre also lists Grotta.CameraStops.Back/North/Roof/South and Grotta.Glow.Blue glow
floor as BIG - those are the sea cave's camera stops and floor 18-63 studs BELOW the terrain (tops -18.4 .. -62.5), not obstacles on
the meadow; a check keyed on box size alone would abort on them, so key it on the top being above the ground. The drone is a squirrel's
prop (the Drone Flyer), 3.7 high: moving it would need Shannon's yes. Camera not moved; nothing changed.
Site fixed from the probe (cloud thread): centre (526, -1053), the FRONT facing west (yaw 90: toward the Sentiero del Faro and
the town stair, the way players come), the crescent bulging east against the hill. Clearances: the pine groves (z < -1085) 34
studs, the Drone Flyer's drone (526,-1086) 32, the olive and umbrella pine (x > 554) 28-29, the town stair's landing ~27. The
installer re-checks all of it at run time (abort on anything big inside r 20.5). install_hall1.lua regenerated for this site.
Result job 94 PREVIEW (runner 7, f8e0765; play test on the test server, Studio v1369, Oct 14 ~17:50Z; NOTHING built, nothing
installed): QQ BELV ABORT: standing inside the terrace's footprint at (526, -1053): Upper town to meadow (x 495..548 z -1053..-1000);
pick another centre; nothing built. Details in tools/hall_italy/preview94_result_2026-10-14.txt. How it was run: the MCP sandbox has
no loadstring, so the installer (fetched on the server from the raw URL, len 37282 adler 1296612856 = the blob) ran as a Script with
ONE patched line: line 343 (the loadstring compile check) became `local RT = 17`. TWO DEFECTS in the committed file: (1) RT is used at
line 429 (`<= RT + 3.5`, the footprint scan) but declared only at line 462 - run as committed it errors "attempt to perform
arithmetic (add) on nil and number" before building anything; (2) the loadstring compile check cannot run in a Script
(LoadStringEnabled is off and not settable from the MCP) - keep it for the Edit install only if the Edit command context has
loadstring (the MCP's execute_luau does not: "loadstring() is not available" in Play and in Edit alike; test before relying on it).
WHY IT ABORTED, from a read-only part list of "Upper town to meadow" (111 parts: the stair down from the upper town, its treads,
nosings, rail posts, handrails, and the paved path along the meadow's north edge): the path's foot lands inside the terrace -
rail posts at (515,-1044) 14.2 studs and (518,-1040) 14.9 from the centre, a handrail x 515..522 z -1044..-1036 at 14.9, posts at
(522,-1036/-1037) 17.1, the Solid turning landing x 505..517 z -1046..-1034 at 19.8, the Level stair exit x 507..518 z -1044..-1033
at 19.9, paving x 504..514 z -1048..-1035 at 20.7. The abort box x 495..548 z -1053..-1000 is wide because the installer's reach test
(distance - Size.Magnitude/2) also catches the two long diagonal handrails (x 522..548 z -1036..-1007 and x 514..540 z -1029..-1000,
32-39 studs away by centre, magnitude ~40): consider testing against a part's real box instead of its magnitude. The probe's earlier
box for this model (x 462..522 z -1075..-1033) was only the parts within 22 studs of the five probed centres; the model really spans
x 462..559 z -1075..-961. Terrain under the rim was fine (centre y 2.0). Geometry of the meadow for the next centre (all from probe94
+ this list): the open middle is bounded by the path foot/rail posts (north-west, x<=525 z>=-1046), the pine groves (south-west: x
495..515 z -1103..-1085 and x 511..529 z -1109..-1099), the umbrella pine + silver olive (east, x>=554 z -1072..-1054), the Drone
Flyer's drone (526,-1086, a squirrel's prop, 3.7 tall) in the middle, and the Guardian's terrace to the south (z<=-1125). A clear
circle of r 20.5 does not fit anywhere there without moving the drone (Shannon's call) or shrinking the footprint check / the terrace;
(538,-1073) has the umbrella pine at 15.8, the drone at 16.5, the olive at 18.1; (524,-1078) has the drone at 7.2, the pine grove at
12.9. Edit after the stop: no workspace.HallOfGuardians, no Runner7 script, HttpEnabled false (checked in the next line).
Edit check after the preview (runner 7): PlaceVersion 1369; workspace.HallOfGuardians absent; no Runner7 script in
ServerScriptService; HttpEnabled false; HudBackup.HallOfGuardians* 0; PortoKeeperServer 14386. Edit is unchanged.
Shannon (Oct 14, to runner 7): YES, the Drone Flyer's drone (526,-1086) may be shifted a few studs if the belvedere needs it.
Round 2 (cloud thread, after the first preview's ABORT): (1) RT is declared at the top of the installer (it was used before its
declaration); (2) the loadstring compile check runs only where loadstring exists (the Studio MCP has none; the sources are
compiled with the luau CLI before every push); (3) the footprint test measures the distance to each part's OWN box (rotation
respected) instead of "distance minus half the diagonal", which had caught handrails forty studs away; small props are parked
only when they stand under the terrace or the step. New centre (530, -1064), front facing west: the town stair's foot (517,-1046)
22 studs, its paving 22.6, the Drone Flyer's drone (526,-1086) 22.4, pine grove A 25.8, the olive 24, the umbrella pine 25 - the
drone does NOT need to move (Shannon's yes to shifting it is noted, unused). Same preview plan; Studio idle, Codex out.
Result job 94 PREVIEW round 2 (runner 7, 8ab3bf3; play test on the test server, Studio v1369, Oct 14 ~18:10-18:25Z; NOTHING
installed): QQ BELV DONE: workspace.HallOfGuardians at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 1.7..2.0); terrace R 17,
parapet 16 segments, 7 slots; copies: Italian cypress 2, Lemon tree 2, Harbour bench 2; 115 small props set aside
(HudBackup.HallOfGuardians_props_*); HallServer 17497 chars. No QQ BELV NOTE. Then "HallOfGuardians: ready - 3 Guardians on the
belvedere (7 slots)" ~5 s after HallServer went in. Every check line, the slot/lectern texts and the copies are in
tools/hall_italy/preview94r2_result_2026-10-14.txt; pictures tools/hall_italy/shots/belv-j94-{a-frontstep,b-centre,c-high,
d-parapet,e-lectern,f-tiles}.jpg. Findings: each statue holds the key in the raised LEFT hand (key 1.6-2.0 studs above the hand
centre, bottoms 0.2-0.3 above it); Slot 4 is the inviting pedestal "THIS COULD BE YOU / Guardian No. 4 / Find all 44 squirrels of
Porto Nocciola" with the resting key; tiles "1ST GUARDIAN / SelBell / All 44 squirrels, Oct 11, 2026" etc. and the lectern roll
"1. SelBell   2. dakota   3. blizzy_1718" are legible in the pictures; the floor top sits 0.5 over the grass at 10 rim points and
0.6/0.8 on the west edge (ground 1.7): nothing floats or buries, the skirt bottom is 3 studs under; the two benches look along +x
(EAST, at the crescent and statues) - the sea is west/south-west of this meadow, so they do not face the sea at this siting (fine as
seats for looking at the Guardians; say if they should turn); 11 Windflower stems (0.04-thick rods, tops 0.34-0.49 over the terrain,
under the 0.5 parking threshold) are now inside the floor slab, invisible - harmless, a 0.3 threshold would take them; the lemon
tree copies' boxes reach y -0.4/-0.1 (the grass is ~1.8-2.0) but look planted at ground level in picture (a).
HOW IT HAD TO RUN (three attempts; the two preview-only patches are NOT in the file): a Script on the test server cannot (1) call
loadstring - `type(loadstring) == "function"` is TRUE there and the call THROWS "loadstring() is not available", so the round-2 guard
does not protect line 343 (attempt 1 died there); (2) write RunContext (attempt 2 died at line 645: "cannot write 'RunContext'
(lacking capability Plugin)"); (3) write Source ("lacking capability PluginOrOpenCloud"). Attempt 3: line 343 as
`pcall(loadstring, SERVER)` (abort only when it compiles badly) and the HallServer creation handed SERVER over in a StringValue, the
runner creating HallServer (Source + RunContext Server) from the MCP context. For the EDIT install (MCP context: Source and
RunContext writable, loadstring throws the same way) the file needs the pcall at line 343; then it can run as committed.
Shannon's verdict on the pictures pending; her yes = the Edit install.
Edit check after the round-2 preview (runner 7): PlaceVersion 1369; workspace.HallOfGuardians absent; no Runner7 script or
StringValue; HttpEnabled false; HudBackup.HallOfGuardians* 0; Prato dei Fiori coastal meadow 1470 parts (nothing parked);
PortoKeeperServer 14386. Edit is unchanged.

Preview round 2 PASSED (runner 7, ef33a6c): QQ BELV DONE at (530, 1.9, -1064); three statues with the key in the raised left hand,
the invitation pedestal at slot 4, the lectern roll, 115 flower stems parked, nothing floating or buried; six pictures
tools/hall_italy/shots/belv-j94-*.jpg. Round 3 (this commit, for the EDIT install): the compile check is a pcall round loadstring
(a Script's loadstring call throws even though the global exists); HallServer gains a Studio-only TestLedger attribute (JSON
{first = rec, daily = daily_v2 state}) so the ledger reading can be tested in a play test. Shannon's verdict on the pictures pending.
INSTALL PLAN (on her yes; Studio EDIT, the MCP context, HttpEnabled on for the fetch and straight back off): run install_hall1.lua
from this commit; expect `QQ BELV DONE ... 115 small props set aside (HudBackup.HallOfGuardians_props_1)` (the count may differ a
little); nothing else changes (the 115 windflower stems are in that backup folder with their places kept - the undo is to move
them back and delete workspace.HallOfGuardians). Then a play test: set workspace.HallOfGuardians attribute TestLedger to
{"first":{"uid":9611145467,"name":"SelBell","user":"SelBell","t":1791676800,"total":44},"daily":{"version":2,"revision":2,"days":
{"20737":{"uid":4161205246,"name":"dakota","t":1791763200,"day":20737,"total":44},"20738":{"uid":7902108387,"name":"blizzy_1718",
"t":1791849600,"day":20738,"total":44}},"winners":{},"attempts":{}}} and set Rebuild to 1: within a few seconds the three statues
(SelBell centre, dakota right, blizzy left) and the invitation at slot 4; the lectern roll "1. SelBell   2. dakota   3. blizzy_1718".
Stop the play test (the attributes do not persist). On live servers the same reading runs against the real store once a minute.
She publishes when she likes; the first live server shows Darkknight (No. 1) and every daily Guardian since.
Result job 94 INSTALL (runner 7, 3fcd4d5, Shannon's "install"; INSTALLED in Edit v1369, Oct 14 ~18:45Z, NOT published): run
UNPATCHED from the MCP context (fetched in Edit, len 38826 adler 1059105496 = the blob; HttpEnabled on for the fetch and back
off; executed through a temporary ModuleScript "return function() <file> end" + require, destroyed after - the MCP's execute_luau
has no usable loadstring). QQ BELV DONE: workspace.HallOfGuardians at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 1.7..2.0);
terrace R 17, parapet 16 segments, 7 slots; copies: Italian cypress 2, Lemon tree 2, Harbour bench 2; 115 small props set aside
(HudBackup.HallOfGuardians_props_*); HallServer 17897 chars. Edit now holds workspace.HallOfGuardians (149 parts: Belvedere, Lectern,
HallServer 17897 RunContext Server) and ServerStorage.HudBackup.HallOfGuardians_props_1 (115 windflower things, places kept = the
undo together with deleting the folder). Benches left facing the statues (her choice). TestLedger play test PASSED: with the plan's
JSON and Rebuild 1, after 42 s three figures (SelBell centre at (543,-1064), dakota at (541,-1070), blizzy_1718 at (541,-1059)) with
keys, then Slot_4 "THIS COULD BE YOU / Guardian No. 4" and the roll "1. SelBell   2. dakota   3. blizzy_1718" (the roll shows "No
Guardian yet ..." until the rebuild finishes); server start logged "HallOfGuardians: ready - 0 Guardians on the belvedere (7
slots)". Lines in tools/hall_italy/install94_result_2026-10-14.txt. She publishes (Alt+P) when she likes; the first live server then
shows Darkknight (No. 1) and every daily Guardian since.
Edit check after the install + test (runner 7): PlaceVersion 1369; HallOfGuardians 149 parts, 0 Slot_ models (as it must be in
Edit), HallServer 17897 RunContext Server Enabled; attrs TestLedger nil, Rebuild 0, PreviewJson "", Slots 7; backup
HudBackup.HallOfGuardians_props_1 115 things; no Runner7 leftovers; HttpEnabled false; PortoKeeperServer 14386. Unpublished in
Studio: job 94 (the Belvedere dei Guardiani). Shannon publishes.
Shannon on the installed hall (Oct 14, to runner 7): "I don't like the position of the benches, I don't think we need benches there
and I don't like the colors of the signs." Her pick for the signs (lectern plaque + pedestal tiles), from four options: TERRACOTTA
WITH CREAM LETTERS (the terrace rim's terracotta 178,92,62; cream 250,244,228). Runner 7 REMOVED the two Belv_Harbour_bench copies
from workspace.HallOfGuardians.Belvedere in Edit at her word (QQ BENCH removed 2). Current sign colours for reference: lectern plaque
52,110,150 SmoothPlastic, frame 214,160,44, Title 255,206,64 / Sub, Roll, Foot 250,244,228; the lighthouse and French plaques are
150,108,58 with 255,226,150 titles. Needed from the cloud thread (round 4): no benches in install_hall1.template.lua; the lectern plaque
and HallServer's pedestal tiles in terracotta with cream text (keep the gold frame/trim or not, your call); a re-run of the installer
(it moves the old folder to HudBackup.HallOfGuardians_pre_1 and parks props again - say whether a re-run re-parks or reuses props_1).
Result job 94 (runner 7, 77ba17e, Shannon's "install"; INSTALLED in Edit, NOT published): QQ BELV DONE at (530, 1.9, -1064); TestLedger
play test passed (3 statues, slot 4 invitation, the roll); Edit check clean; 115 props in HudBackup.HallOfGuardians_props_1.
Shannon, looking at it in Studio: "I don't like the position of the benches, I don't think we need benches there and I don't like the
colors of the signs"; her pick: terracotta with cream letters. Runner 7 removed the two bench copies at her word (QQ BENCH removed 2).
ROUND 4 (this commit): no benches in the installer; the lectern plaque terracotta (178,92,62) with cream letters and a cream marble
frame; HallServer's pedestal tiles terracotta with cream letters (the blue stays on the parapet band and the floor mosaic); parked
props now carry a ParkedFrom attribute (their old parent's full name) for the undo. RE-RUN PLAN (on her yes; Edit, MCP context):
run install_hall1.lua from this commit; the old folder goes to HudBackup.HallOfGuardians_pre_1 (its HallServer disabled); the props
already parked stay in HallOfGuardians_props_1 (they are no longer under the terrace, so the re-run parks nothing new and makes no
second folder); expect `QQ BELV DONE ... 0 small props set aside`. The undo of everything: delete workspace.HallOfGuardians and move
the 115 things in HudBackup.HallOfGuardians_props_1 back under workspace.PortoNocciola["14 Lighthouse coast"]["Prato dei Fiori coastal
meadow"] (round-3 parking kept their CFrames but not their parent; later parkings carry ParkedFrom). Then a quick look in Edit
(terracotta signs; no benches) and the TestLedger play test is not needed again.
Result job 94 RE-RUN round 4 (runner 7, 7666d06, Shannon's yes; Studio Edit v1369, Oct 14 ~19:30Z; NOT published): run unpatched
from the MCP context (fetched in Edit, len 38896 adler 1270728139 = the blob; HttpEnabled on for the fetch and back off; the
ModuleScript route). QQ BELV DONE: workspace.HallOfGuardians at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 1.7..2.0);
terrace R 17, parapet 16 segments, 7 slots; copies: Italian cypress 2, Lemon tree 2; 0 small props set aside
(HudBackup.HallOfGuardians_props_*); HallServer 17909 chars; the old folder is HudBackup.HallOfGuardians_pre_1. Edit after: the hall
123 parts, 0 benches, HallServer 17909 RunContext Server; lectern plaque 178,92,62 SmoothPlastic, frame 240,236,226, Title/Sub/Roll/Foot
text 250,244,228; HallServer carries the terracotta 178,92,62 for the tiles; HudBackup.HallOfGuardians_props_1 still 115 (nothing new
parked, no second folder); HudBackup.HallOfGuardians_pre_1 = the round-3 folder, its HallServer Enabled false; HttpEnabled false; no
leftovers. Unpublished in Studio: job 94 round 4. Shannon's verdict on the terracotta signs pending; she publishes.
PUBLISHED by Shannon at 18:38:04Z Oct 14 (games API "updated"; the round-4 re-run and its pictures were ~18:30-18:36Z, not 19:30Z as
written above): the live game carries job 94 round 4 - the Belvedere dei Guardiani (no benches, terracotta signs). Nothing
unpublished in Studio. She is checking it live; the first live server should raise Darkknight (No. 1) and every daily Guardian.

## Job 95: the onboarding funnel for the Creator Dashboard (Studio EDIT; ask Shannon first) - AFTER the belvedere's round 4

Shannon (Oct 11): a funnel so she can see where new players drop off (33 % still playing at 5 min, 20 % at 10 min; she cannot watch
new players herself): spawned / first squirrel / fifth squirrel / map opened / second area / all 44 / reached Italy, first-session
players; also retention by device. tools/funnel/install_funnel1.lua (make_install_funnel1.py; src/FunnelServer.lua, src/FunnelClient.lua):
workspace.Funnel = FunnelEvent + FunnelServer + FunnelClient. Six funnel steps, each from attributes the game already keeps on every
player (SquirrelSetup, SpawnReturn, TravelServer): 1 Joined (SaveLoaded), 2 First squirrel (SquirrelsFound 1), 3 Five squirrels,
4 Second area (the Area attribute changes from the first area seen this visit), 5 All 44 in France (Found_forest + village +
domaine), 6 Reached Italy (Item_porto). Roblox's rules (docs): server-only, published place only (Studio sends nothing), a later
step completes the earlier ones, only a player's first time at a step counts. Two custom fields on every event for the dashboard's
breakdowns: Device (Phone / Tablet / Desktop / Console / VR, reported once by the client) and Cohort. The funnel counts FIRST-SESSION
players only: New = no squirrel found and Italy not reached when the funnel first sees the player; the save remembers it
(Item_funnel = 1 through RS.AwardItems, the game's own ledger, as the thank-you gifts do) so later visits keep counting; everyone
else is Returning and gets no funnel steps. "Map opened" is a custom event MapOpened (value = squirrels found at that moment, once
per visit, both cohorts), so the funnel stays a line of progress. Retention by device needs no code: Creator Dashboard > Analytics
> Engagement > Retention has a platform breakdown. Folder attributes: Enabled, ForceNew (Studio only: everyone New, for the play
test), LogPrints (one Output line per event). No DataStore write, no publish.
PLAY TEST (after the Edit install): with ForceNew true on workspace.Funnel, join: Output "Funnel: step 1 Joined for SelBell (Desktop,
New)" about 2 s after SaveLoaded (Desktop; on the phone emulator "Phone"); the owner's save already has squirrels and Italy, so
steps 2, 3, 5, 6 print at once ("step 2 First squirrel ...", "step 3 ...", "step 5 All 44 in France ...", "step 6 Reached Italy ...");
walk from the spawn area into another area (or travel): "step 4 Second area ..."; open the map: "MapOpened for SelBell with 88
squirrels (Desktop, New)"; open it again: nothing. Then ForceNew back to false (the Edit value) and a rejoin prints "Funnel: ready"
only (Returning, no steps). Every line says "- not sent" in Studio? No: in Studio the pcall succeeds silently (Roblox drops the
event); only a live server delivers. The dashboard's Funnel page unlocks once events arrive (Creator Dashboard > Analytics >
Funnel); allow a day.
Job 95 review (1 reader, 7 findings; 5 applied): the cohort is decided the moment the save is in (a squirrel found in the first second
no longer marks a new player Returning); the device report is waited for up to 30 s, and a player who leaves before it is still counted
as Joined (device Unknown); a map opened before the player is ready is kept and logged once ready; only the highest step reached is
sent on each change (Roblox completes the earlier ones itself; fewer calls); the client waits for a real viewport before telling phone
from tablet. Not applied: a failed save load (SquirrelSetup sets no attribute for it) can show a veteran as New - rare, noted. JOB 95
READY on claude/youthful-curie-8azx86 (this commit): install_funnel1.lua on Shannon's yes (Edit, MCP context, HttpEnabled on for the
fetch and back off), then the PLAY TEST above. She publishes; events start on the next live servers; the Funnel page appears in the
Creator Dashboard (Analytics > Funnel) once events arrive, allow a day.
Result job 95 (runner 7, c23152a, Shannon's "good enough"; INSTALLED in Edit, Oct 14 ~19:00Z, NOT published): run unpatched from
the MCP context (fetched in Edit, len 12024 adler 2739429316 = the blob; HttpEnabled on/off; ModuleScript route). QQ FUNNEL DONE:
workspace.Funnel (FunnelServer 7232, FunnelClient 1913 chars; Enabled true, ForceNew false, LogPrints true). PLAY TEST (ForceNew true
in Edit for the test, back to false after): "Funnel: ready (6 steps; events leave only a published place)"; "Funnel: step 1 Joined for
CozyGameMode (Desktop, New)"; "Funnel: step 6 Reached Italy for CozyGameMode (Desktop, New)" (steps 2/3/5 not printed separately -
the highest step only, as reviewed; step 4 likewise silent after a porto -> village move because 6 was already reached); "Funnel:
MapOpened for CozyGameMode with 88 squirrels (Desktop, New)" once for two openings via PlayerGui OpenPanel = "map"; every one with
"AnalyticsService: ... event fired." before it. Lines in tools/funnel/playtest95_result_2026-10-14.txt. She publishes when she likes.
SHANNON on the LIVE belvedere (Oct 14, after the publish): "I think the lamps on the end are too bright; also, the text looks very
plain against the background, how can we make it look more special without making it gaudy?" Runner 7 mocked four treatments on
the test server (discarded on stop; pictures tools/hall_italy/shots/belv-mock-tiles-ABC.jpg, belv-mock-lectern-D.jpg,
belv-mock-lanterns-E.jpg): A (Slot_1) "engraved" = UIStroke 1.6 px dark terracotta 120,55,35 at transparency 0.15 round each letter
+ a cream hairline frame (UIStroke 1.5 px on a Frame inset 7 px); B (Slot_2) gold letters 255,206,64 with a 1 px dark edge;
C (Slot_3) an inset cream 250,244,228 panel (inset 10 px, gold 214,160,44 1.5 px stroke) with terracotta 178,92,62 letters;
D (lectern) cream letters with a soft dark edge (1.2 px, transparency 0.35), a gold rule 2 px under the title (y 47, 60 % wide) and a
cream hairline border inset 8 px; E the south lantern dimmed: Lamp Material Glass, colour 255,196,120, transparency 0.15, PointLight
0.35 / range 12 (installed: Neon 255,214,140, light 1.0 / 16). Her pick pending; then one line each in the template + HallServer.
Edit check after the job 95 play test (runner 7): v1369; Funnel = FunnelEvent, FunnelServer 7232, FunnelClient 1913, Enabled true,
ForceNew FALSE again, LogPrints true; HallOfGuardians 123 parts, 0 Slot_ models, 0 mock-up instances, both lanterns Neon 255,214,140
light 1.0/16 as installed, TestLedger nil, Rebuild 0; no Runner7 leftovers; HttpEnabled false. Unpublished in Studio: job 95.
Shannon (Oct 14, to runner 7) on the belvedere's capacity: "latest 7 please" - the crescent shows the LATEST seven Guardians
(the newest always gets a statue, the oldest steps down to the lectern roll), not the first seven forever. Open: whether
Darkknight (No. 1) stays pinned in the centre regardless (runner 7 is asking). Her lettering pick (A/B/C/D) and the lantern level
are still pending.
Shannon (Oct 14, to runner 7): Darkknight: "rotate please" - No. 1 is NOT pinned; the latest seven, plain. On the lettering: she
leans to B (gold letters with a dark edge) "but I don't like the font and it is too just yellow". Runner 7 mocked (test server,
discarded) an OLD-GOLD finish - TextColor3 white + UIGradient rotation 90 with 255,226,150 -> 232,190,90 (0.45) -> 176,124,40, plus a
UIStroke 1.1 px 110,50,30 at transparency 0.1 - in three fonts, one per tile: Slot_2 (dakota, left) Garamond, Slot_1 (SelBell, centre)
Bodoni, Slot_3 (blizzy, right) Antique; picture tools/hall_italy/shots/belv-mock-fonts-gold.jpg. Her font pick pending; the small
"When" line in a serif at 15 px is thin - consider a size up or Merriweather for that line.
Shannon on the old-gold font mock-ups (Garamond / Bodoni / Antique): "I don't like any of those, they all look terrible". Runner 7
put up a FONT SAMPLER on the test server (14 fonts, cream on terracotta, the name + the date line in each: Antique, Garamond, Bodoni,
Merriweather, Fondamento, JosefinSans, Michroma, Oswald, GothamBold, Nunito, Sarpanch, Fantasy, PatrickHand, FredokaOne); picture
tools/hall_italy/shots/belv-font-sampler.jpg. Her pick pending; the gold finish is dropped unless she says otherwise.
Shannon's pick from the font sampler (Oct 14): the left column, fifth from the top = GothamBold (no. 9). Lettering for the tiles
AND the lectern: GothamBold, cream 250,244,228 on the terracotta; the gold finish is dropped. Lanterns: no further word from her, so
the mocked dim level stands unless she objects: Lamp Material Glass, colour 255,196,120, transparency 0.15, PointLight 0.35 /
range 12 (installed: Neon 255,214,140, 1.0 / 16). ROUND 5 brief: latest seven (Darkknight rotates like everyone), GothamBold cream
lettering, dimmer lanterns. The TestLedger play test is worth repeating once (the rotation: 8+ entries).
Round 5, part 1 (cloud thread): Shannon "latest 7 please" -> HallServer Mode "latest": the newest Guardian always gets a statue, the
oldest steps down to the lectern roll (everyone stays on the roll); PinFirst true (default) = Darkknight (No. 1) keeps the centre and
the six newest stand beside him, newest nearest the centre; PinFirst false = the seven newest, the newest in the centre - one attribute
on workspace.HallOfGuardians, no re-run needed to flip it (set Rebuild 1 after). Lanterns dimmed to mock E. Her lettering pick (tiles
A/B/C, lectern D) still to come; then the re-run carries all three.
ROUND 5 (cloud thread, Shannon's three decisions): (1) Mode "latest", PinFirst FALSE ("rotate please"): the crescent shows the newest
seven, the newest in the CENTRE, the older ones right and left of it in turn, the oldest of the seven at the horns; everyone stays on
the lectern roll (the newest six names, "N more, then"). (2) Lettering GothamBold, cream 250,244,228 on the terracotta, tiles (Title/
Who/When) and lectern (Title/Sub/Roll/Foot); no gold, no gradient. (3) Lanterns: Glass 255,196,120 transparency 0.15, PointLight 0.35 /
range 12. RE-RUN PLAN (on her yes; Edit, MCP context): run install_hall1.lua from this commit; the old folder goes to
HudBackup.HallOfGuardians_pre_2; the props stay in props_1 (expect "0 small props set aside"). TestLedger PLAY TEST with eight entries,
then Rebuild 1: set workspace.HallOfGuardians attribute TestLedger to
{"first":{"uid":9611145467,"name":"SelBell","user":"SelBell","t":1791676800,"total":44},"daily":{"version":2,"revision":7,"days":{
"20737":{"uid":4161205246,"name":"dakota","t":1791763200,"day":20737,"total":44},"20738":{"uid":7902108387,"name":"blizzy_1718",
"t":1791849600,"day":20738,"total":44},"20739":{"uid":1,"name":"Roblox","t":1791936000,"day":20739,"total":44},"20740":{"uid":2,
"name":"John","t":1792022400,"day":20740,"total":44},"20741":{"uid":3,"name":"Jane","t":1792108800,"day":20741,"total":44},"20742":
{"uid":4,"name":"Four","t":1792195200,"day":20742,"total":44},"20743":{"uid":5,"name":"Five","t":1792281600,"day":20743,"total":44}},
"winners":{},"attempts":{}}}
Expected: seven statues (the low uids give default figures), slot 1 (centre) = No. 8 "Five", slot 2 (right) = No. 7 "Four", slot 3
(left) = No. 6, slot 4 = No. 5, slot 5 = No. 4 "Roblox", slot 6 = No. 3 blizzy, slot 7 = No. 2 dakota; NO invitation pedestal; SelBell
(No. 1) only on the roll: "2 more, then 3. blizzy_1718   4. Roblox   5. John   6. Jane   7. Four   8. Five". Then clear TestLedger,
Rebuild 1 again: all slots empty but the slot 1 invitation. Stop (nothing persists). Edit check. She publishes.
Result job 94 RE-RUN round 5 (runner 7, 80b6bb1, Shannon's yes; INSTALLED in Edit v1369, Oct 14 ~19:45Z, NOT published): run
unpatched (len 40333 adler 2954596965 = the blob; HttpEnabled on/off; ModuleScript route). QQ BELV DONE: workspace.HallOfGuardians at
(530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 1.7..2.0); terrace R 17, parapet 16 segments, 7 slots; copies: Italian cypress 2,
Lemon tree 2; 0 small props set aside (HudBackup.HallOfGuardians_props_*); HallServer 18987 chars; the old folder is
HudBackup.HallOfGuardians_pre_2. Edit: 123 parts, 0 benches, Mode latest, PinFirst false, Slots 7; lectern GothamBold cream on
178,92,62; HallServer carries GothamBold; both lanterns Glass 255,196,120 transp 0.15, light 0.35/12; backups props_1 115, pre_1, pre_2.
TestLedger test, eight entries: PASS exactly as expected - slot 1 (centre) 8TH GUARDIAN Five, 2 Four, 3 Jane, 4 John, 5 Roblox, 6
blizzy_1718, 7 dakota; no invitation; Roll "2 more, then 3. blizzy_1718   4. Roblox   5. John   6. Jane   7. Four   8. Five". The
"clear" step as written (TestLedger "" + Rebuild) changes nothing - by design, an unreadable ledger keeps the last list (`current`); a
VALID empty ledger {"daily":{"version":2,"revision":8,"days":{},"winners":{},"attempts":{}}} + a NEW Rebuild value gave the expected
slot 1 invitation "Guardian No. 1" and the "No Guardian yet" roll in 20 s. Two notes: Rebuild set to its current value fires nothing;
the lectern roll wraps "5. John" across lines (a non-breaking space between number and name would keep each pair together). Pictures
tools/hall_italy/shots/belv-j94r5-crescent-eight.jpg, belv-j94r5-lectern.jpg; lines in tools/hall_italy/install94r5_result_2026-10-14.txt.
Unpublished in Studio: job 94 round 5 + job 95. She publishes.
Edit check after the round-5 test (runner 7): v1369; HallOfGuardians 123 parts, 0 Slot_ models, HallServer 18987 enabled, Mode latest,
PinFirst false, TestLedger nil, Rebuild 0, PreviewJson "", lanterns Glass; Funnel present, ForceNew false; no leftovers; HttpEnabled false.
SHANNON on the round-5 picture of seven statues (Oct 14): "that actually looks a little overbearing and creepy". So the full crescent of
seven marble figures with raised keys is too much (the five placeholder avatars of the test ids make it worse than real players would,
but the reaction is to the row itself). Runner 7 is asking her which way to go: fewer pedestals (3 or 5) with more air; smaller figures
(Scale 1.35 -> ~1.1) on lower pedestals; or only the newest Guardian in marble (one statue, centre) and the past ones as named plaques
along the parapet, no figures. Hold the publish of round 5 until she decides; the live game still shows round 4 (first seven, cream).
SHANNON (Oct 14, right after): "too many statues; why did we do it this way rather than the carousel like in france?" - answer given
to her: the all-together crescent came from her "distinctively different from the one in France" (France = one Keeper at a time in a
frame with Newer/Older buttons). HER DIRECTION NOW (runner 7's reading, relayed; she may still amend): a CAROUSEL - one pedestal in the
centre of the crescent, one Guardian at a time, the newest first, Older/Newer buttons like workspace.HallOfFame's Newer/Older models,
everyone on the lectern roll; the terrace, lectern, lanterns, cypresses and lemon trees stay. Round 6 please; round 5 stays unpublished
(live = round 4).
SHANNON (Oct 14), clarifying the original brief: "when I said make it different, I meant the same display concept, just a different
model or style." So the Italian hall = the FRENCH DISPLAY CONCEPT (one Keeper/Guardian shown at a time, Newer/Older paging, the plaque
with name/date/count) in an Italian model and style (the terrace, terracotta, lectern, lanterns, cypresses, lemon trees, the harbour
key). Round 6 = that; not seven statues, not a crescent of pedestals.
ROUND 6 (cloud thread; Shannon: "too many statues; why did we do it this way rather than the carousel like in France?" and "when I
said make it different, I meant the same display concept, just a different model or style"): the French DISPLAY CONCEPT in the
Italian style. ONE pedestal in the centre of the crescent (where slot 1 stood; terracotta tile, GothamBold cream), one Guardian at a
time, the newest first; Older / Newer = two posts with cream marble discs and terracotta chevrons in front of the pedestal (click
or tap, ClickDetectors, 40 studs), the French buttons' construction; the plaque reads "3RD GUARDIAN / name / All 44 squirrels, Oct 12,
2026 · 3 of 8"; everyone on the lectern roll. Mechanism = France's: HallServer makes each statue once (Champion.MakeStatue + the
harbour key), 300 studs below the terrace, keeps it in ReplicatedStorage.HallStatues (the forty seen most recently) and hands its name
over HallStatue (RemoteFunction); HallClient (new, RunContext Client) clones the one it shows into workspace.HallView_local on that
screen only. The list is still read from PortoKeeper_v1 (first + daily_v2) and now published as the folder's HallJson attribute.
Dropped: the six other pedestals, Mode/PinFirst/Slots. Kept: terrace, parapet, column, dim lanterns, lectern (roll), cypresses, lemon
trees, terracotta signs. A WaitingKey rests on the pedestal while there is no Guardian; the tile then reads "THIS COULD BE YOU".
PREVIEW first (play test on the test server, nothing installed): run the installer's body on the server; PreviewJson gives three
sample Guardians; expect "HallOfGuardians: ready - 3 Guardians on the roll, one at a time on the belvedere", the newest (blizzy_1718,
3 of 3) on the pedestal within ~10 s, the Older button lit and Newer dimmed; click Older twice -> dakota (2 of 3), SelBell (1 of 3),
Newer back; the lectern roll "1. SelBell   2. dakota   3. blizzy_1718". Pictures with the game's camera: the pedestal from the step,
the buttons, the tile. Then on her yes the Edit install (old folder -> HudBackup.HallOfGuardians_pre_3; props stay), the TestLedger
play test (three entries), Edit check; she publishes.
Result job 94 round 6 PREVIEW (runner 7, 3f8a44b; play test on the test server, NOTHING installed, Oct 14 ~20:30Z): QQ BELV DONE:
workspace.HallOfGuardians at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 1.7..2.0); terrace R 17, parapet 16 segments, one
pedestal + Older/Newer; copies: Italian cypress 2, Lemon tree 2; 0 small props set aside (HudBackup.HallOfGuardians_props_*);
HallServer 15329, HallClient 4703 chars; the old folder is HudBackup.HallOfGuardians_pre_3. Server: "HallOfGuardians: ready - 3
Guardians on the roll, one at a time on the belvedere" 1 s after the scripts went in; HallStatues = No_3; HallJson 211 chars; Roll
"1. SelBell   2. dakota   3. blizzy_1718". Client: tile "3RD GUARDIAN / blizzy_1718 / All 44 squirrels, Oct 13, 2026 · 3 of 3";
Older lit (0.00) / Newer dimmed (0.55); No_3 shown on the pedestal at (542.6,10.5,-1064); HallStatue:InvokeServer(3) -> "No_3" in
0.2 s. Two notes: (a) the client had TWO HallView_local folders (the first empty) because HallClient ran twice in this preview (the
script was created from the server context after the player was in; a real install has it in the place first) - a guard that reuses
an existing HallView_local would cost one line; (b) PAGING was not exercised: the Studio automation mouse does not reach 3D
ClickDetectors (two inset-corrected tries); the detectors are present and Hooked on Cap/Post/Button of both posts; Shannon was asked to
tap Older in the running test. Pictures tools/hall_italy/shots/belv-j94r6-{step,pedestal-buttons,tile}.jpg; lines in
tools/hall_italy/preview94r6_result_2026-10-14.txt. Her verdict + yes to install pending.
SHANNON on the round-6 preview pictures (Oct 14): "because there is now only one statue at a time, that circle area is too big and the
columns with the arrows on the side are too big." ROUND 7 please: the terrace scaled down to suit ONE statue (R 17 -> about 10-11; the
parapet, skirt, rim, mosaic rings and the step with it; the lectern nearer the pedestal; the cypresses and lemon trees re-placed to the
new rim), and the Older/Newer posts much smaller (lower, slimmer, smaller discs and chevrons - buttons, not columns). Everything else
as round 6. Preview again before any install; round 5 is still what Edit holds, round 4 is live.
ROUND 7 (cloud thread; Shannon on the round-6 preview: "because there is now only one statue at a time, that circle area is too big
and the columns with the arrows on the side are too big"): the terrace sized for one statue - R 17 -> 10.5 (skirt, rim, mosaic rings
3.8/3.3/1.0, step 8 wide, parapet R 9.1 in 12 segments, column 6 tall with a 2.8 key, lanterns 3-stud posts, lectern three quarters
(5.4 x 2.1 plaque, same layout), pedestal 5.8 back of centre, cypresses at R 12 scale 0.85, lemon trees scale 0.7); the Older/Newer
posts knee-high (0.7 x 1.3 post, a 1.1 disc at 2 studs, x +-3.0, 2.2 in front of the pedestal). HallClient reuses one HallView_local
folder. PREVIEW again (same plan as round 6: play test, PreviewJson, pictures from the step and of the buttons/tile); nothing installed;
Edit = round 5, live = round 4.
Result job 94 round 7 PREVIEW (runner 7, c7323ce; test server, NOTHING installed, Oct 14 ~20:50Z): QQ BELV DONE: workspace.HallOfGuardians
at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 2.0..2.0); terrace R 10, parapet 12 segments, one pedestal + Older/Newer; copies:
Italian cypress 2, Lemon tree 2; 0 small props set aside (HudBackup.HallOfGuardians_props_*); HallServer 15329, HallClient 4864 chars;
the old folder is HudBackup.HallOfGuardians_pre_3. "HallOfGuardians: ready - 3 Guardians on the roll, one at a time on the belvedere"
in 1 s; No_3 shown at once in ONE HallView_local (the reuse guard works); tile "3RD GUARDIAN / blizzy_1718 / ... · 3 of 3"; Older lit /
Newer dimmed; boxes: Pedestal (535.8,3.8,-1064) 3.7x2.6x3.7, Older/Newer (532.2,3.8,-1067/-1061) 1.1x2.5x0.9, Lectern (522.7,3.9,-1064)
5.7x3.0x2.3. Paging not exercised (automation mouse). Pictures tools/hall_italy/shots/belv-j94r7-{step,pedestal-buttons,high}.jpg;
lines in tools/hall_italy/preview94r7_result_2026-10-14.txt. Shannon's verdict pending; her yes = the Edit install (pre_3), then the
three-entry TestLedger test, Edit check, her publish.
Result job 94 INSTALL round 7 (runner 7, c7323ce, Shannon's "that looks much better" + "install"; INSTALLED in Edit v1369, Oct 14
~21:05Z, NOT published): run unpatched from the MCP context (len 45585 adler 3907716040 = the blob; HttpEnabled on/off; ModuleScript
route). QQ BELV DONE: workspace.HallOfGuardians at (530, 1.9, -1064) yaw 90 (ground centre 2.0, edges 2.0..2.0); terrace R 10, parapet
12 segments, one pedestal + Older/Newer; copies: Italian cypress 2, Lemon tree 2; 0 small props set aside
(HudBackup.HallOfGuardians_props_*); HallServer 15329, HallClient 4864 chars; the old folder is HudBackup.HallOfGuardians_pre_3. Edit:
121 parts (Belvedere, Lectern, Pedestal, Older, Newer, HallStatue, HallServer Server, HallClient Client), attr Total 44; backups
props_1 115, pre_1/2/3 with HallServer disabled. TestLedger (three entries) PASSED: "ready - 0 Guardians" at start, then HallStatues
No_3, Roll "1. SelBell   2. dakota   3. blizzy_1718", the client shows No_3 in 1 s, tile "3RD GUARDIAN / blizzy_1718 / All 44 squirrels,
Oct 12, 2026 · 3 of 3", Older lit / Newer dimmed. One note: the Studio client still makes TWO HallView_local folders (first with the
statue, second empty, none on the server): HallClient starts twice in a Studio play test and the reuse guard loses the race - harmless,
a one-line fix some day. Paging not exercised by the runner. Lines in tools/hall_italy/install94r7_result_2026-10-14.txt. Unpublished in
Studio: job 94 round 7 + job 95. She publishes.
Edit check after the round-7 test (runner 7): v1369; HallOfGuardians 121 parts (Belvedere, Lectern, Pedestal, Older, Newer, HallStatue,
HallServer, HallClient); TestLedger nil, Rebuild 0, HallJson nil; no HallView_local or RS.HallStatues in Edit; no leftovers; Funnel
ForceNew false; HttpEnabled false. Unpublished in Studio: job 94 round 7 (the belvedere, one Guardian at a time) + job 95 (the funnel).
PUBLISHED by Shannon at 19:41:36Z Oct 14 (games API "updated"; "I have published the update"): the live game now carries job 94 round 7
(the Belvedere dei Guardiani: one Guardian at a time, newest first, Older/Newer buttons, terrace R 10.5, GothamBold cream on
terracotta, dim lanterns, everyone on the lectern roll) AND job 95 (the onboarding funnel; events start on the next live servers; the
Funnel page appears in the Creator Dashboard about a day after the first events). Nothing unpublished in Studio. (Time correction:
runner 7's "~Z" estimates in the round 5-7 paragraphs above ran about 90 minutes fast; the real clock: round 7 install ~19:30Z.)

## Job 96: the portraits blink on phones and VR - the client diagnostic (PLAY TEST, client context; nothing installed) - runner 7

Shannon: "the portraits in the French section have the characters in them continuously blinking in and out on mobile and VR (but
not on desktop)"; "slow, every few seconds"; "its DEFINITELY ONLY the character, not the easel or setting". Job 91's streaming change
was not the fix. The cloud thread's reading of PortraitClient (village/build_portraits.lua lines 1179-1270): each slot's server
Picture (SurfaceGui + ViewportFrame Portrait3D + the sitter in its World) is a template; the client clones the WHOLE Picture into
PlayerGui.PortraitGalleryPictures (a mount) and swaps the mount for a fresh clone whenever refresh() runs - on a RenderToken or
GalleryModelKey attribute change, on any GuiObject's Visible/Image/Size/Position change in the template, on anything added to or
removed from ReplicatedStorage.PortraitGalleryModels, on template descendants added/removed. The frame and background are plain
images (drawn at once); the sitter is a ViewportFrame that needs a frame or more to render, so on a slow device every swap shows as
the character blinking out and in - desktop swaps within a frame and shows nothing. The probe names the trigger that fires every
few seconds. tools/portraits/blink_probe1.lua: run on the CLIENT (execute_luau, client context) in a play test on the phone
emulator (iPhone 7), standing in the French gallery looking at the portraits (workspace.PortraitGallery.Slots, x 189..217, z -14..-4),
for 90 s. It prints QQ BLINK lines: every REMOUNT (slot, viewport visible, sitter parts, image), every candidate trigger with the
slot and what changed, models-folder changes, canvas streaming, a heartbeat every 10 s (mounts, remounts so far, memory), then
"QQ BLINK END (n lines, m remounts in 90 s)". Send every line unchanged, and say whether the emulator itself showed any blink.
Then the fix (job 97, after the lines): expected - refresh() skips the swap when nothing the picture shows has changed (key, token,
image, visible flags), and when it must swap it parents the new mount before destroying the old one and destroys the old only after
the new viewport has rendered (two frames), so no gap is ever visible; an exact-string patch of workspace.PortraitGallery.PortraitClient
(the vr1-patched text; anchors counted first; backup HudBackup.PortraitClient_pre_blink1).
Result job 96 (runner 7, ffecfea; play test, client context, NOTHING installed, Oct 14 ~19:55Z): the probe ran 90 s but found nothing
to catch: "START: 9 canvases, 0 models, 9 mounts, memory 4229 MB, device mouse" ... "QQ BLINK END (10 lines, 0 remounts in 90 s)"
(all lines in tools/portraits/blink_probe1_result_2026-10-14.txt). Every mount is empty (Portrait3D Visible false, World 0
descendants) and the easels are blank on screen: in Studio the portrait store is unreachable, so there are no sitters, no models and
no triggers. Two limits: (1) the Device Emulator cannot be switched from the MCP (StudioDeviceEmulatorService is not reachable; the
run was the desktop viewport, "device mouse") - Shannon would have to pick iPhone 7 in Studio's Test tab herself; (2) without sitters
the probe cannot name the trigger. Options: a Studio-only sample sitter (a PreviewJson-style hook in PortraitServer that fills one slot
with the owner's avatar when the store is off) so the probe has something to watch; or install job 97's fix on the reading alone (skip
no-op swaps; parent the new mount before destroying the old; destroy after two rendered frames) - it is safe either way - and let
Shannon judge on her phone. No blink seen in the emulator-less run (nothing to blink).
SHANNON (Oct 14, after the job 96 run): "there has been no further issue with the art work." - the portraits no longer blink for her,
so job 96 is CLOSED and job 97 (the no-gap fix) is NOT needed unless it comes back. For the record: village/build_portraits.lua line 489
opens the PortraitWall store only outside Studio, so a Studio play test has no entries, 0 models and empty mounts - the blink can only
ever be judged live. Next per the handoff: the phone camera (she still owes what she saw), then the look pass.
SHANNON (Oct 14, to runner 7), NEXT: "we need a tool that will count and give info for on how far each player gets and what they
interact with." Runner 7's reading: (a) "how far each player gets" = progress, which job 95's funnel now reports in aggregate on the
Creator Dashboard once events arrive (joined / first squirrel / fifth / second area / all 44 / Italy, by device and cohort); (b) "what
they interact with" = the activities and things players actually use - the shop, the boat, the balloon, the games (crab, sea glass,
piazza race, octopus), the prompts/tools, La Poste, the belvedere buttons, travel - which the game does not log today. Proposal to
design: AnalyticsService custom events (LogCustomEvent) fired from the existing server scripts on each interaction, with the Device and
Cohort fields the funnel already builds (tools/funnel/src/FunnelServer.lua), so the Creator Dashboard's Custom Events page shows counts
per interaction; plus, if she wants it in-game, an owner-only panel listing the players on the server with their progress and recent
interactions (no DataStore). Runner 7 is asking her where she wants to read it (dashboard vs in-game) and whether per-player history
across visits matters (that would need save fields through the game's own ledger).
Shannon's answers (Oct 14): read it on the CREATOR DASHBOARD (counts per step and per interaction, by device and cohort; no in-game
panel); counts and live views are enough - NO per-player history, nothing new on player saves. She put this NEXT ("What's next is we
need a tool ..."), ahead of the look pass. So the job = interaction analytics: AnalyticsService custom events (one event per
interaction kind, value = a count or the squirrels found, with the funnel's Device/Cohort fields) fired from the existing server scripts
- shop purchases, boat taken, balloon ride, each game played (crab, sea glass, piazza race, octopus), prompts/tools used, La Poste
letters, belvedere paging, travel/funicolare - exact-string patches or a small listener folder where the scripts already fire remotes.
Job 96 CLOSED (Shannon, Oct 14: "there has been no further issue with the art work"); Studio cannot show sitters (the PortraitWall store
opens only outside Studio, build_portraits.lua ~489), so the probe saw 9 empty mounts and 0 remounts. Job 97 (the no-gap fix,
tools/portraits/blink1.lua from make_blink1.py: a swap only when something shown changed; the new picture up before the old goes)
is written, self-tested against the repo CLIENT + vr1 and compiled - NOT installed, kept for the day the blink returns.

## Job 98: what players interact with, counted for the Creator Dashboard (Studio EDIT; ask Shannon first) - before the look pass

Shannon (Oct 14): "we need a tool that will count and give info on how far each player gets and what they interact with"; her
answers to runner 7: read it on the CREATOR DASHBOARD, counts are enough, no per-player history, nothing new on saves. "How far" is
the funnel (job 95, live). tools/interact/install_interact1.lua (make_install_interact1.py; src/InteractServer.lua): workspace.Interact
+ InteractServer. Nothing in the game is patched: the script listens to what the game already fires and sends one AnalyticsService
custom event per interaction - Interact_Prompt (every ProximityPrompt triggered: the boat, the balloon, the games, La Poste, the
opera, pick-ups ...), Interact_Click (every ClickDetector: the belvedere's Older/Newer, the French hall's buttons, the race gate),
Interact_Seat (the boat, the balloon basket, the funicolare, benches), Interact_Tool / Interact_ToolUse (camera, slingshot,
binoculars ...), Interact_Area (forest / village / domaine / porto entered: travel, the funicolare, the boat), Interact_Item (an item
or keepsake gained after the save loaded: a shop buy, the backpack, the chute ...). Fields: Device and Cohort (the funnel's, now
published by FunnelServer as player attributes FunnelDevice / FunnelCohort - install_funnel1.lua regenerated, a re-run refreshes
the live Funnel folder) and Name (the prompt's text or the thing's model name). Throttles: once per player per thing per Repeat
(60 s), at most Budget (90) events per server per minute; the rest counted, never sent. The dashboard's Custom Events page then
shows, per kind, how many players use each thing, split by device or cohort. Events leave only a published place; in Studio the
server prints what it would send. No DataStore, no publish.
INSTALL (on her yes; Edit, MCP context): 1. re-run tools/funnel/install_funnel1.lua (the old Funnel folder -> HudBackup.Funnel_pre_1;
expect QQ FUNNEL DONE with FunnelServer 7394); 2. run install_interact1.lua (expect "QQ INTERACT DONE: workspace.Interact
(InteractServer 7522 chars; Enabled true, Repeat 60, Budget 90)"). PLAY TEST: "Interact: ready ..." in Output; walk to a prompt and
use it -> "Interact: Prompt "<text>" by <name>"; click the belvedere's Older post -> "Interact: Click "Older" ..."; equip the camera
-> "Interact: Tool "Camera" ..." and a photo -> ToolUse; sit in the boat -> Seat; travel -> Area; use it again within a minute ->
nothing (Repeat). Edit check; she publishes.

## Job 99: the look pass, settings only (play-test PREVIEW first, then Studio EDIT on her yes) - after job 98

Shannon (Oct 12, another game's dock and grass: "they have a better sky and better grass"; "just refined", same vibe, no time-of-day
or haze change). tools/look/look_pass1.lua: water Reflectance 0.55 -> 0.85, Transparency 0.45 -> 0.65, WaveSize 0.06 -> 0.10; Bloom
Threshold 2 -> 1.2 (the lanterns glow); a ColorCorrectionEffect "LookGrade" Contrast 0.06 / Saturation 0.08; Terrain Grass + LeafyGrass
colour 96,150,72 -> 86,140,62. Every old value is kept as a LookWas_* attribute on Lighting / Terrain; tools/look/look_undo1.lua puts
everything back in one run. NOT scriptable (hers, in the Properties panel): Terrain.Decoration on + GrassLength ~0.7; the cloud skybox
from the Toolbox (two or three candidates she picks). ClockTime, Atmosphere, Fog, the sun untouched.
PREVIEW: a play test, the script's body on the server; pictures with the game's camera BEFORE (the same spots) and AFTER on desktop and
the phone emulator: the French village lake or river with the sky (water), a lantern at the harbour or the piazza (bloom), the forest
floor (grass), the Porto piazza (grading). Send the QQ LOOK lines and the picture pairs; she picks what stays. Then EDIT on her yes (the
same script); the undo is look_undo1.lua. No publish.
Job 98 review (1 reader, 7 findings; 6 applied): names lose a trailing _<number> (the per-ride Boat_<uid> would have burnt Roblox's
8,000-combination cap) and never name a player's character; the game's own awards (Item_funnel, thanks_*, porto) are not counted as
items; nothing is counted after a failed save load; the throttle is ten-second buckets (Budget / 6), the Repeat stamp set only when an
event is sent, and the truncation reported as one Interact_Dropped event per bucket; the spawn area is not a move; Studio prints say
"(Studio, not sent)". The InteractServer length in the install line changes with this commit (read the QQ line as printed).
Result job 98 (runner 7, 8a45f57, Shannon's "clear, install"; INSTALLED in Edit v1369, Oct 14 ~20:40Z, NOT published): step 1 QQ FUNNEL
DONE: workspace.Funnel (FunnelServer 7394, FunnelClient 1913 chars; Enabled true, ForceNew false, LogPrints true); the old folder is
HudBackup.Funnel_pre_1. Step 2 QQ INTERACT DONE: workspace.Interact (InteractServer 8554 chars; Enabled true, Repeat 60, Budget 90).
Both run unpatched from the MCP context (lens 12186 / 10858, adlers 2271121862 / 461758808 = the blobs). PLAY TEST, every kind fired:
"Interact: ready ..."; Seat "Harbour bench" (Seat:Sit); Area "village" then Area "porto" (teleports); Tool "Binoculars" (EquipTool; the
test account has no Camera tool) and ToolUse "Binoculars" (Tool:Activate on the client); Prompt "Harbour bell" (the bell's "Ring" prompt
held from the client at 4.7 studs); Items daily_day, daily_streak, frenchrank, passport_porto_bell. Repeat PASS: a second sit on the same
bench ~40 s later printed nothing. Click not exercised (automation mouse). NOTE: the Item events for daily_day / daily_streak / frenchrank
/ passport_porto_bell are save bookkeeping, not things players "interact with" - say whether to filter them (keep shop buys, keepsakes,
backpack, chute, passport stamps?). Lines in tools/interact/playtest98_result_2026-10-14.txt. She publishes.
Edit check after the job 98 play test (runner 7): v1369; Funnel (FunnelServer 7394, ForceNew false); Interact (InteractServer 8554,
Enabled true, Repeat 60, Budget 90); backup Funnel_pre_1; HallOfGuardians round 7 present; no leftovers; HttpEnabled false.
Unpublished in Studio: job 98. She publishes; then job 99's preview.
Job 98 round 2 (cloud thread, after the play test): the save's bookkeeping is not counted as an Item - daily_* (the card, the streak),
passport_* (stamps), frenchrank, champion*, thanks_*, funnel, porto; what stays: shop buys and keepsakes, the backpack, the chute, the
gifts card's rows. A re-run of install_interact1.lua (the old folder -> HudBackup.Interact_pre_1) before her publish; expect
"QQ INTERACT DONE: workspace.Interact (InteractServer <new length> chars; ...)".
PUBLISHED by Shannon at 02:43:10Z Oct 15 (games API "updated", seen by runner 7 at 02:46Z): job 98 round 1 (the interaction counter
+ the funnel refresh) is LIVE, Items unfiltered. Round 2 (9d5b80e: Item events skip daily_*, passport_*, frenchrank, champion*,
thanks_*, funnel, porto) is verified on the branch (install_interact1.lua 11225 bytes, adler32 465068626 = raw); runner 7 is asking
her yes for the re-run (old folder -> HudBackup.Interact_pre_1), then a quick play test, then her publish, then job 99's preview.
Result job 98 round 2 (runner 7, 9d5b80e, Shannon's yes; INSTALLED in Edit, Oct 15 ~02:50Z, NOT published): run unpatched (len 11225
adler 465068626 = the blob). QQ INTERACT DONE: workspace.Interact (InteractServer 8921 chars; Enabled true, Repeat 60, Budget 90); the
old folder is HudBackup.Interact_pre_1 (InteractServer 8554, disabled). Play test: "Interact: ready ..." then, after 12 s for the
join-time items, only "Interact: Seat "Harbour bench" by CozyGameMode (Studio, not sent)" - 0 bookkeeping Item lines (round 1 printed
daily_day, daily_streak, frenchrank): the filter works. Lines in tools/interact/playtest98_result_2026-10-14.txt. She publishes; then
job 99's preview.
Edit check after the round-2 test (runner 7): v1369; Interact (InteractServer 8921, Enabled true, Repeat 60, Budget 90); Funnel
(FunnelServer 7394, ForceNew false); backups Funnel_pre_1, Interact_pre_1; no leftovers; HttpEnabled false. Unpublished: job 98 round 2.
PUBLISHED by Shannon at 2026-10-15T02:50:28.832Z (games API "updated"; "published"): job 98 round 2 (the item filter) is LIVE. Nothing unpublished in Studio.
Next: job 99's look-pass PREVIEW (play test, before/after pictures, desktop viewport).
Result job 99 PREVIEW (runner 7, abbc23c; play test, nothing installed, Oct 15 ~03:00Z; desktop viewport only - the emulator is not
switchable from the MCP): QQ LOOK PREVIEW (play test, discarded on stop) / Terrain.WaterReflectance 0.55 -> 0.85 / WaterTransparency
0.45 -> 0.65 / WaterWaveSize 0.06 -> 0.1 / Bloom.Threshold 2 -> 1.2 / LookGrade added / Terrain Grass colour 96,150,72 -> 86,140,62 /
LeafyGrass the same / QQ LOOK DONE (7 lines). Four before/after pairs with the same camera each: tools/look/shots/look-{before,after}-
{W-harbour,A-meadow,C-forest,B-lantern,D-piazza}.jpg (five spots: the harbour water + sky, the belvedere meadow, the forest floor, a
piazza lamp post, the fountain square). What shows: the water brighter and more mirror-like; grass a shade deeper; a little more
contrast and saturation everywhere; BUT at Bloom.Threshold 1.2 the pale piazza cobbles bloom noticeably brighter in daylight (the lamps
are unlit at ClockTime 14.5, so the lantern glow itself cannot be judged by day). Lines in tools/look/preview99_result_2026-10-15.txt.
Shannon picks what stays; the Edit run is the same script (undo look_undo1.lua).
Edit check after the job 99 preview (runner 7): v1369; water refl 0.55 / transp 0.45 / wave 0.06; Bloom threshold 2; no LookGrade;
0 LookWas_ attributes; grass 96,150,72; HttpEnabled false. Edit untouched by the preview. Her picks pending.
Job 99 round 2 (cloud thread, after the preview): Bloom threshold 1.2 -> 1.55 (the pale cobbles bloomed by day at 1.2; the lantern glow
is a night check - ClockTime 14.5 keeps the lamps unlit by day); each of the four changes is now a switch at the top of look_pass1.lua
(WATER, BLOOM, GRADE, GRASS) so Shannon's picks are one edit each before the Edit run. Her picks pending.
SHANNON's picks from the ten look-pass pictures (Oct 15): WATER, GRASS COLOUR and COLOUR GRADING stay; BLOOM does not (the daylight
paving glare). Runner 7 set BLOOM = false in tools/look/look_pass1.lua (line 12) on epic-hawking and runs it in Edit with that switch;
undo = tools/look/look_undo1.lua.
Result job 99 EDIT run (runner 7, f547f6d = 55f6931 with BLOOM = false; Shannon's picks; INSTALLED in Edit, Oct 15 ~03:15Z, NOT
published): QQ LOOK EDIT (the real change; undo = look_undo1.lua) / Terrain.WaterReflectance 0.55 -> 0.85 / WaterTransparency 0.45 ->
0.65 / WaterWaveSize 0.06 -> 0.1 / LookGrade added / Terrain Grass colour 96,150,72 -> 86,140,62 / LeafyGrass the same / QQ LOOK DONE
(6 lines). Edit now: water 0.85 / 0.65 / 0.10; Bloom threshold 2 (untouched); LookGrade contrast 0.06 sat 0.08; grass 86,140,62;
LookWas_ attributes on Terrain: GrassColor, LeafyGrassColor, WaterReflectance, WaterTransparency, WaterWaveSize (the undo's record).
SHANNON, right after (Oct 15): "I thought you were going to add fluffy clouds in the sky?" and "and some birds?" - CLOUDS: runner 7 is
previewing Roblox's volumetric Clouds (Instance "Clouds" under Terrain: Cover ~0.6, Density ~0.4, white) in a play test now; if she
likes them they are one more switch in look_pass1.lua (+ undo). BIRDS: a new job for the cloud thread - ambient birds (gulls circling
over the harbour and the lighthouse, swallows over the village), simple looping flight paths, light, no gameplay; design it.
CLOUDS preview (runner 7, Oct 15 ~03:25Z, play test, nothing installed): Roblox volumetric Clouds under Terrain, Cover 0.6, Density 0.4,
white - fluffy cumulus over the meadow with the sun and the belvedere (tools/look/shots/clouds-preview-meadow.jpg). Note: Cover/Density
set on the SERVER after parenting did not reach the client copy (it showed 0/0); set on the client for the picture. In Edit the
instance is saved with its values, so a real install has no such issue; set the values before parenting anyway. Studio render quality
Automatic was enough. Her verdict pending; if yes: a CLOUDS switch in look_pass1.lua (create Terrain.Clouds with the values, undo =
destroy it).
CLOUDS INSTALLED in Edit (runner 7, Oct 15 ~03:30Z, Shannon: "I see them on the screen; that looks good"; NOT published): QQ LOOK EDIT
Terrain.Clouds added: Cover 0.60 Density 0.40 Color 255,255,255 (Terrain attribute LookWas_Clouds = "none" = there was no Clouds before;
undo = destroy workspace.Terrain.Clouds). Edit now: water 0.85/0.65/0.10, LookGrade on, grass 86,140,62, Bloom threshold 2 (untouched),
Clouds on. Cloud thread: please add a CLOUDS switch to look_pass1.lua (create Terrain.Clouds 0.6/0.4 white if absent, values set BEFORE
parenting) and the matching line in look_undo1.lua, so the files match Edit. Unpublished: job 99 (water, grading, grass, clouds).
Job 99 DONE in Edit (runner 7, Shannon's picks: water, grass colour, grading, CLOUDS; not bloom): water 0.85/0.65/0.10, LookGrade
0.06/0.08, grass 86,140,62, Terrain.Clouds Cover 0.6 Density 0.4 white (Terrain attribute LookWas_Clouds = "none"); Bloom threshold
stays 2. look_pass1.lua now has the CLOUDS switch (values set before parenting) and look_undo1.lua the matching removal, so the files
match Edit. She publishes. Hers still: Terrain.Decoration + GrassLength, a Toolbox skybox if she wants another sky.

## Job 100: ambient birds (play-test PREVIEW first, then Studio EDIT on her yes) - runner 7

Shannon (Oct 15): "and some birds?". tools/birds/install_birds1.lua (make_install_birds1.py; src/BirdsClient.lua): workspace.Birds +
BirdsClient (RunContext Client) + attribute Sites (JSON). Gulls (white, grey wings, 1.6-stud wingspan) circle slowly, gliding between
bouts of flapping, rising and falling: six over the harbour (centre 225, -670, flight height y 0, radius ~36, the quay is at -47) and
five round the lighthouse (520, -1178, y 88, radius ~28, the top is 74); eight swallows (small, dark, fast) dart in figure-eights over
the French village (262, -58, y 30, radius ~34). Every bird is three parts moved on the client only (nothing replicates, nothing to
touch, no gameplay); a flock sleeps while the camera is beyond its Range (400-500 studs). To move a flock later: edit the Sites
attribute in Studio, no code. PREVIEW: a play test, the installer's body on the server (the client script then runs on the test
client); pictures with the game's camera: the harbour from the piazza looking up, the lighthouse from the meadow, the French village
from the fountain; a few seconds apart to show the motion. Her verdict, then the Edit install on her yes; undo = delete workspace.Birds.
Result job 100 PREVIEW (runner 7, cd206d4; play test, nothing installed, Oct 15 ~03:45Z): QQ BIRDS DONE: workspace.Birds (BirdsClient
5714 chars; 3 sites: harbour gulls, lighthouse gulls, village swallows); client "Birds: 3 flocks on this screen". Positions on the
client: harbour gulls x 183..265 y -4..5 z -705..-650 (as designed; the other flocks asleep at y -1000 until the camera comes near);
lighthouse gulls x 495..546 y 84..93 z -1203..-1184 (10-19 over the lantern); village swallows x 229..293 y 25..33 z -78..-43.
Pictures tools/birds/shots/birds-{harbour,lighthouse,village}-{1,2}.jpg: the VILLAGE swallows read best (dark, several in frame,
moving between frames); one HARBOUR gull reads from under the circle, the rest are a dozen pixels at 40-75 studs and vanish against
the (new) clouds; the LIGHTHOUSE gulls are not readable at all (white on white clouds, small, far side of the circle). Lines in
tools/birds/preview100_result_2026-10-15.txt.
SHANNON, during the preview (Oct 15): "actually, on the italy map we should have some mesh seaguls and maybe a pelican." - DIRECTION
for round 2: the Italian flocks (harbour + lighthouse) become MESH gulls (a real gull model: Toolbox/Creator Store mesh, or a mesh she
imports as with the balloon and petals, or the Studio MCP's generate_mesh), bigger than 1.6 studs so they read at 50 studs, with grey
wingtips for contrast against the clouds, plus ONE pelican (perched on a harbour post / mooring pile, or a slow low glide over the
water). The French swallows can stay as they are. Say what you need from her (a mesh pick) or from me (generate_mesh / upload).
SHANNON (Oct 15, right after): "Also, that announcement about the daily questions and the golden squirrel in the french section
carries over into the italy map, those things should only show if you are on the french map." - NEW JOB (101?): the Daily system's
HUD announcements (the top-right banner "Golden Squirrel: <name> is hiding in Rue de Noisette ..." seen in the Porto pictures, and the
DailyQuestion card/notice) must show only while the player's Area is a French one (forest / village / domaine), hidden in porto (and on
the boat/balloon?). Find the client that draws them (Daily / DailyQuestion clients) and gate on the player's Area attribute.
SHANNON (Oct 15): "also, the icon box with the gift in it, should have the word 'gift' under it so it matches the other boxes in
design" - a GiftsClient tweak (tools/gifts/src/GiftsClient.lua, the HUD gift box): a caption "Gift" under the icon in the same style
as Passport / Map (font, size, colour); desktop and the phone column alike. Small job; can ride with the announcements fix.
Job 100 round 2 (cloud thread; Shannon: "on the italy map we should have some mesh seaguls and maybe a pelican"; runner 7: the part
gulls read small and white-on-white): BirdsClient v2 - gulls bigger (3-stud span) with DARK wingtips, the harbour flock lower (y -12,
35 over the quay) and tighter; ONE pelican (5-stud span, long bill, dark head) in a slow low glide over the harbour water (y -36, 14
over the sea); the French swallows as before. MESH birds: a template dropped into workspace.Birds.Templates named Gull / Pelican /
Swallow (a Model or MeshPart facing -Z, any size: the script scales it to the kind's span; parts named LeftWing / RightWing flap)
replaces the part-built bird of that kind on the spot - her import (Meshy FBX, as the squirrels), a Creator Store mesh, or the
Studio MCP's generate_mesh; the part-built birds stand in until then. The installer keeps an old Templates folder on a re-run.
PREVIEW again (same plan; the harbour from the quay this time, the pelican low over the water).

## Job 101: the golden squirrel announcements only on the French map (Studio EDIT; ask Shannon first)

Shannon (Oct 15): "that announcement about the daily questions and the golden squirrel in the french section carries over into the
italy map, those things should only show if you are on the french map". tools/daily/golden_gate1.lua (make_golden_gate1.py;
self-tested against boundary/build_daily.lua's CLIENT): four exact-string patches of workspace.Daily.DailyClient + an appended
watcher - the pill under the purse and the daily card's golden line need the player's Area to be forest / village / domaine, and
the pill follows every Area change (hidden in Porto, back in France). The daily acorns card itself still shows everywhere. The
Question of the Day's reminders carry their own French gate already (QuestionClient FRENCH_QUESTION_REMINDERS_20261002_V1); the
installer prints whether the live QuestionClient has it - if ABSENT, say so and the cloud thread patches that too. Backup
HudBackup.DailyClient_pre_golden1; "QQ GOLD" lines. PLAY TEST: on a desktop view, spawn in France: the pill shows; travel to Porto:
the pill goes; back: it returns; the daily card in Porto has no golden line. No publish.

## Job 102: "Gift" under the HUD gift box (Studio EDIT; ask Shannon first)

Shannon (Oct 15): "the icon box with the gift in it, should have the word 'gift' under it so it matches the other boxes in design".
tools/gifts/src/GiftsClient.lua: a Caption TextLabel under the gift drawing in the HUD squares' own style (FredokaOne 10, gold, 46 x 14
at the bottom, as hudCaption draws "Passport" and "Map"); the box, lid, ribbon and bow move up 8 px to make room. install_gifts1.lua
regenerated (a re-run: the old Gifts folder -> HudBackup.Gifts_pre_n, attributes carried; the PromptClient patch reports "already").
PLAY TEST: desktop and the phone emulator: "Gift" under the box, nothing overlapping (phone column: the box at x 541..589 as before).
Result job 102 (runner 7, 07ab577, Shannon's "install both"; INSTALLED in Edit, Oct 15 ~04:05Z, NOT published): QQ GIFTS DONE:
workspace.Gifts (GiftsServer 8379, GiftsClient 24294 chars; GroupId 969906332, CommunityAcorns 150, BoostMaxGain 150, LikeReward
backpack, PopupDelay 180, FirstFind true, AutoPopup true, BoostOn true); the old Gifts folder is HudBackup.Gifts_pre_3; PromptClient
already patched (30763). Play test of the caption follows.
Result job 101 (runner 7, 07ab577): QQ GOLD QuestionClient 28598 chars, French gate present / QQ GOLD DailyClient is 15020 chars /
QQ GOLD ABORT - anchor 3 not found; nothing changed. CAUSE: the LIVE workspace.Daily.DailyClient (15020 chars, adler32 1705313267)
already begins with "-- FRENCH_ONLY_HUD_20261002_V1": frenchMapHudAllowed() (Area forest/village/domaine), updateFrenchDailyHud() on
every Area change hides the GoldPill and the card's GoldenSquirrelLine outside France and disables a GoldenReveal, setPill() keys the
pill on attributes FrenchHudPillEligible / FrenchHudPanelBlocked, goldReveal() returns outside France. The patch was written against
an older DailyClient. So the leak Shannon sees in Italy is NOT a missing gate: suspects - (a) the Area attribute not switching to
"porto" on some arrival path (boat, balloon, funicolare, the one-click boat card) so the pill stays; (b) the pill text set before
Area changes and nothing re-evaluating ... (the Area signal does); (c) the QuestionClient reminder (it has FRENCH_QUESTION_REMINDERS).
Runner 7 is asking her exactly what she saw in Italy (the top-right pill, the daily card's golden line, the question reminder) and how
she got there. A runner probe can log the Area attribute along a boat ride / balloon flight / travel board next.

## Job 103: the forest treehouse - READ-ONLY survey first (Studio EDIT; no ask), then the build - runner 7

Shannon (Oct 15, her yes: "yes to the treehouse build, lets start with that"): "a lot of people are coming staying a minute and leaving
... seems like a lot are finding the first 15 squirrels and then don't go on; ... finding parts and building a treehouse in the forest
... strew the pieces throughout the french map, and have a count somewhere to show how many more they need, and they can piece it
together as they collect the pieces". The design (cloud thread): a half-built platform in a big tree in sight of the forest spawn with a
sign and the count; twelve pieces, the first two or three close to the spawn (a win in the first minute), the rest along the forest,
three or four beyond the gate in Rue de Noisette and the chateau ("4 pieces lie beyond the forest gate" on the count); the treehouse
grows per piece (ladder, platform, railing, walls, roof, window, lantern, flag), finished = a lookout worth climbing; per player, kept
on the save through RS.AwardItems (Item_tree_<piece>), no new store; the pieces are props with a pick-up prompt; the count on the sign
and a small HUD pill. SURVEY (tools/treehouse/survey103.lua, read-only, Edit): the forest spawn and its ground, every tree-like model
within 90 studs of the spawn (foot, top, trunk width, distance), the French squirrels' positions by map, the gates, the ground round the
spawn, path parts. Send every `QQ TREE` line unchanged; the cloud thread then picks the tree and the piece spots and writes the installer
for a play-test PREVIEW with pictures (nothing installed; she decides in the morning).

## Job 104 (after 103's preview): an adversarial survey of Codex's Japan map (READ-ONLY) - her ask of Oct 15

Shannon: "codex made a 3rd map for Japan and I wanted you to do an adversarial survey of it to find things wrong so we can fix them".
The cloud thread writes the survey (what is there, scripts, squirrels, spawn, gates, prompts, floating or sunken parts, unanchored
parts, overlaps) and the runner exports Codex's Japan scripts for review; findings listed for the morning, nothing changed.
Result job 103 SURVEY (runner 7, 02f309b; Edit v1369, read-only, Oct 15 ~04:30Z): 57 QQ TREE lines in
tools/treehouse/survey103_result_2026-10-15.txt. The script needed ONE fix to run: section (3) "local lo, hi = m and extents(m)" keeps
only the first value (the and-expression truncates the list) and crashed on hi.X; runner 7 ran it with "local lo, hi; if m then lo, hi =
extents(m) end" - everything else verbatim; please fix the file. Headlines: forest spawn (3,1) ground 2.0 on Spawn_forest, terrain
0.1; 57 tree-like models within 90 studs - all 2-part kit models (Trunk + Foliage; trunks 1.3-4.4 studs wide, 4-9 tall; tops y 8-19);
nearest: Boundary.Dressing.pine_squat (-2,24) 24 studs, pine_mid (-12,20) 24, round_tree (6,26) 25 (trunk 4.4 wide, 9.1 tall, top
14.5), Forest.pine_mid_s73 (15,-22) 26, pine_tall (14,25) 26, Forest.pine_tall_s79 (30,2) 27 (top 15.4). Biggest trunks near the spawn:
round_tree (6,26) 4.4 wide, Forest.round_tree_s82 (38,10) 3.4, Forest.round_tree_s52 (-37,-41) 3.4; tallest: pine_tall (-3,-51) top
19.2, (54,24) 19.2, (38,27) 18.5. The three "ForestKit" hits at y 100 are templates in the air. Squirrels with positions: forest 15
(nearest the spawn: surfing (-16,-47), fairy (18,-52), parachute (60,7,-18), baking_betty (-18,-93); ranger (0,-200) farthest), village
14, domaine 15. Boundary.Gates NOT found under that name. Rings: r 12 grass 0.1 (dais parts aside); r 24 grass except "Wall" y 220 at
(3,25) and "Roof" y 80 at (-21,1) overhead; r 40 grass. No path-like parts within 60 studs. No fat trunk near the spawn: the treehouse
likely needs its own built tree or a platform across two or three pines.

## Job 101 round 2: the Wise Squirrel draw announcement only in France (Studio EDIT; ask Shannon first) - runner 7

Round 1 aborted (the live DailyClient already carries the Oct 2 gate: the golden pill and the card's golden line hide outside
France). Reading the LIVE QuestionClient (tools/tools_src/QuestionClient_phone1.lua, 28598 bytes, the one in Studio): the reminders,
the arrow and the board announce are gated (frenchQuestionReminderAllowed) but the "drawn" event is NOT - when the day's draw is
made, EVERY player gets the banner "Today's Wise Squirrel: <name>! The answers were: ..." sliding in at the top of the screen plus
the chat line "<name> is today's Wise Squirrel!" (or "Nobody got a Question of the Day right today. New ones are up!") - in Porto
Nocciola too. That is the "announcement about the daily questions" she saw carrying over. tools/daily/golden_gate2.lua (from
make_golden_gate2.py; self-tested on the live copy, compiles): ONE exact-string patch of workspace.DailyQuestion.QuestionClient - the
drawn block runs only when frenchQuestionReminderAllowed(); the personal "You're the Wise Squirrel!" prize banner stays everywhere
(it explains the acorns that just arrived). Backup HudBackup.QuestionClient_pre_golden2; marker FRENCH_DRAWN_ANNOUNCE_20261015_V1.
The GOLDEN squirrel part of her report: nothing ungated found in DailyClient; still to learn from her what she saw and how she got
to Italy (the Area attribute along the boat / balloon / funicolare / travel board is the suspect; a runner probe can log it).
PLAN: ask her; run golden_gate2.lua in Edit; expect "QQ GOLD DONE: QuestionClient 28598 -> n chars".

## Job 103 BUILD: the forest treehouse - play-test PREVIEW with pictures (NOT installed; she decides in the morning) - runner 7

REVIEWED (cloud thread, round 2 = the commit saying "reviewed"): the adversarial review found and round 2 fixed - the rope coil
stood on end (a Cylinder's axis is X), the door lintel sat 4.8 over the deck and collided (tall avatars could not enter: now looks
only, 6 studs clear) and the room was a 2-stud ring round the trunk (walls now 11 x 11, 3 studs of floor all round; the railing
stands until the walls replace it; the roof 12.4 deep; the lantern hangs beside the door under the eave; the canopy balls and the
branches raised to clear the ceiling), a player holding all twelve Item_tree_* but no Item_tree_done was never paid (paid on join
now), Enabled off-then-on left no house, a re-run left a second TreehouseGui, the sign said "4 of them lie beyond the gate" after
far pieces were found, a pick's "Got it!" could be skipped when the attribute beat the reply, a missing Tree attribute built the
house at the origin, water and a tester's own character counted as ground in the installer; REACH 14 studs and 1.5 s between
honoured picks. Verify in the play test: the truss ladder climbs (CanQuery true on the ladder and the deck now).

From the survey: no kit tree can carry a house (two-part models, trunks 1.3-4.4 wide), so the treehouse gets its own tree: a big OAK
32 studs south of the forest spawn at (-4, -30) (flat terrain grass, nothing within 18 studs; the nearest pines are at (15,-22) and
(-18,-18)), a 6-stud trunk, roots, four branches, a canopy of leaf balls; its +z faces the spawn. tools/treehouse/install_treehouse1.lua
(from make_install_treehouse1.py; src/TreehouseServer.lua 4806, src/TreehouseClient.lua 19277; all three compile):
- workspace.Treehouse {Oak (shared), TreehouseServer (RunContext Server), TreehouseClient (RunContext Client)}; attributes Enabled,
  Tree (JSON x/y/z/yaw), Pieces (JSON [{id, x, y, z, kind, yaw, far}] - move a spot in Studio by editing the attribute, no code);
  ReplicatedStorage.TreehousePick (RemoteEvent). Re-runnable: the old folder -> HudBackup.Treehouse_pre_n.
- TWELVE pieces (bundles of planks, a coil of rope, a stack of shingles, a lantern in its crate; a "Treehouse piece" tag within 42
  studs; a "Treehouse piece / Pick up" prompt, Style Custom so PromptClient draws it): p1 (14,-8) and p2 (-12,-12) in sight of the
  spawn, p3 (22,-30), p4 (-20,-40) by the surfing squirrel, p5 (30,-60), p6 (-12,-85) by Baking Betty, p7 (60,-105) by the scientist,
  p8 (70,-140) by the rainy-day squirrel; beyond the gate: p9 (210,-70) and p10 (300,-90) in Rue de Noisette, p11 (455,-75) and p12
  (560,-110) at the chateau. The installer rays every spot (terrain, or a slab no higher than 2.5 over the terrain; a roof or a tree
  is refused), nudges a refused spot up to 12 studs round, skips one with no open ground and says so; aborts under 10 placed.
- PER PLAYER: the pieces this player has not found and the house are drawn on their own screen (workspace.Treehouse_local), like the
  belvedere; the SERVER is the authority: a pick-up is a request (RS.TreehousePick "pick"), honoured once per piece when the save is
  loaded and the character stands within 20 studs of the spot; kept on the save as Item_tree_<id> through RS.AwardItems (no new
  store); the player attribute TreePieces carries the count (the dashboard can read it). The house grows by count: 1 ladder (a
  climbable truss), 3 deck, 5 railing, 7 walls with a door, 9 roof, 10 window, 11 lantern, 12 flag; at 12 "Treehouse built!" card and
  100 acorns once (RS.AwardAcorns + the Acorns attribute, flag Item_tree_done - the thank-you gifts' pattern).
- THE COUNT: the sign at the oak's foot ("The Treehouse / 3 of 12 pieces found. / 9 more to find. / 4 of them lie beyond the forest
  gate."), a toast at every pick-up ("Treehouse piece 3 of 12! 9 more to find", bottom centre where the question toast sits), and on
  DESKTOP a pill under the golden pill (top right, y 100: "Treehouse: 3 of 12 pieces"; hidden in Italy, while a panel is open, and at
  12). Phones get no pill (the HUD column has no room; the sign and the toasts carry the count) - say if she wants one anyway.
PREVIEW (play test, desktop first, then the iPhone 7 emulator if she can switch it): run the installer's body on the test server;
expect "QQ TREE oak at (-4, 0.1, -30) ...", twelve "QQ TREE piece ..." lines (none SKIPPED - report any), "QQ TREE DONE". Pictures:
(1) the oak from the spawn pad with the sign; (2) p1 and p2 from the spawn; (3) a pick-up (the prompt, then the toast); (4) the
house at 1, 3, 7 and 12 pieces - in a play test the save is Studio's, so pick the pieces up (walk p1..p8, then the gate - or, for the
picture only, set the test player's attributes Item_tree_p1..p12 = 1 from the command bar; they are not saved); (5) climb the ladder
and stand on the deck; (6) the "Treehouse built!" card; (7) p9..p12 where they lie. Report every QQ TREE line.

## Job 104 survey script: tools/japan/survey104.lua (READ-ONLY, Edit; no ask) + the script export - runner 7

tools/japan/survey104.lua ROUND 2 (the first cut, in 3bf662d, threw on its first line - three NotScriptable Workspace
properties - and would have lost every line; if it was run, run round 2) looks for what is wrong: JapanMap's shape and the parts of it lying west of x 4500 (in France /
Porto); every script named Japan* or whose Source mentions Japan outside the backups (= what Codex patched: BalloonServer,
SpawnReturnServer, Travel ...; with sizes and adler32); the preview gate's module; the backups' weight in ServerStorage and Studio
memory; unanchored / huge / invisible-solid parts; floating and buried models (<= 400 parts); a 50-stud ground grid for holes;
seats, prompts (Style - PromptClient draws only Custom), click detectors, NPCs, spawns; the texts on signs; effects, lights, sounds
(a Sound not on a part plays everywhere, France included); Lighting and the water; Travel / SpawnPads / Boundary and the Area
attribute's reach; squirrel-like models. Round 2 after the review: no require() of the preview module (its shape is read from its
Source), the model pass walks each part once (the Studio script timeout would have killed the first cut on a deep model tree), the
body runs under pcall and prints what it gathered on a fault, and the script RETURNS its lines too. ~150-190 "QQ JAPAN" lines; send
them all unchanged to tools/japan/survey104_result_<date>.txt.
THEN EXPORT (Source to files, tools/japan/studio_2026-10-15/<Name>.lua, LF): every SCRIPT line the survey prints that is not a backup
- at least JapanMap.JapanEnvironment, the three AutomaticFoodSeatContact, ServerScriptService.JapanPreviewAccess + JapanPreviewGuard,
StarterPlayerScripts JapanAtmosphere / JapanWaterAppearance / JapanTrainInteriorCamera / JapanPreviewVisibility, the live
BalloonServer, BalloonClient, SpawnReturnServer, TravelServer, HidePortoFromFrance / HideFranceFromPorto, and the backups' copies in
ServerStorage.JapanBeforePrivatePreview (BalloonServer, BalloonClient, JapanEnvironment, JapanAtmosphere, SpawnReturnServer) so the
cloud thread can diff what Codex changed in the live scripts. Nothing changed in Studio.

Result job 104 (runner 7, on 3740085): survey104 ROUND 2 run in Edit Oct 15 ~04:55Z, no error: 82 QQ JAPAN lines, all unchanged in
tools/japan/survey104_result_2026-10-15.txt. (Round 1 from 3bf662d had been run first with two one-line fixes - the three NotScriptable
reads pcall-guarded, and table.insert(texts, s:gsub(..)) passing gsub's count as a 3rd argument - its 91 lines sit beside it as
survey104_result_round1_2026-10-15.txt: its nested-model pass flags 578 "floating" candidates, mostly bamboo clumps on the slope and
props whose bottom centre is 0.7 under the ground; round 2's top-most pass flags 7.) Headlines: JapanMap 23,074 descendants / 20,373
parts, box x 442..7128 - the Airport connection's "Sign · JAPAN / Airport taxi" and its taxi stop post stand in France at (445,6,-44);
16 Japan scripts outside the backups (Workspace.MapMusic.MusicClient 11980 / adler32 2355573903 mentions Japan too - not exported, say
if wanted); 120 scripts in 22 backup folders = 17,794 descendants (6% of ServerStorage's 318,798) + 6 other Japan* folders (4,469);
0 unanchored; 180 huge parts (sculpted terrain meshes, the widest 1317); 855 invisible solid parts; ground grid 532 of 1365 rays void
(the list caps at 15: the whole x 5200 column from z -1270 to -570 - the sea west of the island; 98 Water hits elsewhere); 7
ProximityPrompts, all Style Default; 12 seats; 154 text labels (108 Japanese), fonts Garamond + GothamMedium; 1 sound, positional;
0 NPCs, 0 spawns, 0 squirrels; Travel has nothing named Japan (the taxi prompt is the only link); Lighting = the look pass. EXPORT:
21 files in tools/japan/studio_2026-10-15/ (14 live + before/ 7), every one adler32-verified against Studio's Source: JapanEnvironment
6327, AutomaticFoodSeatContact 2245 (three identical copies), JapanPreviewAccess 966, JapanPreviewGuard 1449, JapanAtmosphere 1807,
JapanWaterAppearance 1039 (ONE line, starts and ends with a space), JapanTrainInteriorCamera 1386, JapanPreviewVisibility 2184 (its
Source ends LF CR LF - the stray CR is in the file; git's autocrlf may drop it in the blob), BalloonServer 14415, BalloonClient 35840,
SpawnReturnServer 5219, TravelServer 4939 (= the Oct 14 export), HidePortoFromFrance 3902, HideFranceFromPorto 3334; before/:
BalloonServer 11362 + BalloonClient 32702 (= tools/balloon/src BalloonServer_ride1.lua / BalloonClient.lua), JapanEnvironment 6013,
JapanAtmosphere 1724, SpawnReturnServer 4997 (JapanBeforePrivatePreview), HidePortoFromFrance 3789 + HideFranceFromPorto 3221
(JapanIntegrationBackup). Nothing changed in Studio. Note for the thread: this runner's shell wrapper rejects heredocs holding some
quote patterns (a quote followed by a space, e.g. gsub(' station','')); such files were written with the Write tool and checksummed.

Result job 104 REVIEW (cloud thread, two adversarial code reviews + the survey): tools/japan/FINDINGS_japan_2026-10-15.md - the
write-up for Shannon's morning. Headlines: Japan is a PRIVATE PREVIEW locked to her user id (hidden client-side for everyone else,
a server guard throws others out); touching every player NOW: three live scripts (SpawnReturnServer, BalloonServer, JapanEnvironment)
require the JapanPreviewAccess module with a timeout-less WaitForChild - remove or rename the module and nobody is returned to their
dais, Area is never set and CharacterAutoLoads stays true (random spawns, Porto included), and the balloon is gone; the hidden taxi
sign + post ten studs from the Spawn_domaine pad may be solid (check CanCollide by eye); the balloon's PlayerRemoving safety net was
removed; HER session after a balloon preview keeps fog off, atmosphere .08 and the CLOUDS at cover .08 (the look pass set 0.6/0.4) -
nothing restores them; her Area freezes in Japan ("domaine" or "porto") so the French HUD / question reminders / golden pill show in
Japan; she can never take the ordinary balloon ride again. The map: NO SEA (532 of 1365 ground rays void - walk off a cliff and fall
forever), 855 invisible floors in and around the lake, the volcano backdrop floating at y 133, a lookout and two bamboo clumps
floating, 180 sculpted mesh parts up to 1,317 studs (collision to be walked), yen menus / Garamond signs, no squirrels / spawn pad /
Area id / Travel entry. Recommendation: move Japan to its own place file until it is ready (or, if she keeps previewing live, six
small patches: the module fallback, the two solid parts, the lighting+clouds restore, the balloon safety net, the ride opt-in, Area
"japan"). RUNNER NEXT (read-only, no ask): (1) run tools/japan/probe_serverstorage.lua (what fills ServerStorage's 318,798 - the
Japan share is 7%); (2) export Workspace.MapMusic.MusicClient (11980) to tools/japan/studio_2026-10-15/; (3) in Edit, read CanCollide
on JapanMap."Airport connection".("Provence taxi stop post" and "Sign · JAPAN / Airport taxi") and the Destination attributes of the
two JapanAirportPrompt prompts, and whether JapanMap has an Origin attribute and each Railway BoardingPoint a StationIndex; (4) when
Shannon previews Japan herself: the lake's edge (walk in: walk on water, wade or swim?), the island's west edge (what is below?),
the Fuji lookout, the volcano backdrop from the island, and whether her fog/clouds look different after a balloon trip.

Result RUNNER NEXT (runner 7, on bd7709d, Oct 15 ~06:00Z, Studio EDIT, read-only): (1) probe_serverstorage.lua run verbatim - 84
children, 318,798 descendants; PortoEnvironmentBackup_20261001 alone holds 291,576 (91%: BeforeOrganicHillside20261002 56,473,
BeforeUniformStoreyHeights20261003 50,645, BeforeConsistentLargeOpenings20261003 50,549, BeforeIndividualBlocks20261002 40,625,
BeforePlacementStructures20261003 26,957 ...), then JapanBeforeBlender 9,361 and the other Japan folders; every line in
tools/japan/runner_next_result_2026-10-15.txt. (2) MusicClient exported: tools/japan/studio_2026-10-15/MusicClient.lua (11980,
adler32 2355573903, verified). (3) "Provence taxi stop post" and "Sign · JAPAN / Airport taxi" at (445,6..7,-44): CanCollide false,
CanQuery false, CanTouch false, anchored. The two JapanAirportPrompt: on the Japan side (6145,0.6,222) Destination (438,4.4,-36)
"Return to Provence"; on the Provence sign Destination (6145,0.6,222) "Travel to Japan"; both MaxActivationDistance 14. JapanMap
Origin (6000,0,0) (+ 50 other attributes, listed: Finished=true, PrivatePreviewUserId 9611145467, NaturalRevisionNeedsSave=true,
ShinkansenRevisionNeedsSave=true ...). BoardingPoints: Tea Hills (5630) StationIndex 1, Lantern Street (6000) 2, Palace Grounds
(6379) 3; the train StationIndex 2 at (6000,0,181). Nothing changed.

Result BIRD RIGS (runner 7, Oct 15 ~06:00Z; Shannon in this session: "this is the meshy model for the pelican; I need you to create
it and rig it in blender", then the gull): both rigged in Blender, see tools/birds/RIG_NOTES_2026-10-15.md (bones, Roblox axes for
each motion, tested ranges, pictures in tools/birds/shots/). Both Meshy models are STANDING cartoon birds with FOLDED wings fused
to the body: they flap to about 55 degrees, turn their heads, waddle, and the pelican opens its pouch, but they cannot spread their
wings for flight. So they suit perched birds (pelican on a post or the quay, gulls on railings and roofs); BirdsClient's circling
flock would keep the part-built birds or need flying-pose models. A template with BONES (not LeftWing/RightWing parts) needs a
BirdsClient change. The FBX/blend files stay on her PC (roblox-props/meshy/pelican, /gull); she imports them with Import 3D.

## Job 100 round 3: the birds - her rigged Meshy pelican and gull PERCHED, bone-driven (play-test PREVIEW; install on her yes) - runner 7

Runner 7 rigged Shannon's Meshy "Pippin the Pelican" and gull in Blender (tools/birds/RIG_NOTES_2026-10-15.md: standing cartoon
birds with folded wings; bones Wing.L/.R, WingTip.L/.R, Head, Neck(1), Jaw, Thigh.L/.R, Body; tested ranges - flap to 55 about the
model's +Z, head turn 35 about +Y, jaw -20 about +X, thigh 25 about +X, body roll 7 about +Z; they suit PERCHED birds, not flight).
BirdsClient v3 (tools/birds/src/BirdsClient.lua 17318; install_birds1.lua regenerated, both compile): a site with perch = true stands
its birds on a spot (x/y/z the first bird's feet, yaw its facing, n birds gap studs apart, height in studs) and drives the mesh's
bones through a little life - look left/right, a preen-flap, a waddle on the spot (body roll + legs), the pelican's gulp - between
idle sways; a site without a template gets a part-built standing bird. The FLYING flocks stay part-built unless a wings-spread
mesh named Templates.GullFlying / Templates.PelicanFlying exists (so her standing meshes are never flown). Three perches as first
guesses (move them by editing the Sites attribute, no code): the pelican on the quay (222, -46.5, -662) facing 160; three gulls on
the harbour rail (236, -46.5, -680) facing 80; two gulls at the lighthouse terrace (526, 2.4, -1170) facing 300.
WHAT THE RUNNER NEEDS FIRST: her rigged FBX files imported into Studio (Avatar/3D importer, the same settings as the whale) as
workspace.Birds.Templates.Pelican and workspace.Birds.Templates.Gull - a Model whose MeshPart carries the Bone instances; facing -Z
after import (the RIG_NOTES say the importer's InitialPoses + AnimationController are harmless; a rotated PivotOffset on the
MeshPart should be set to identity as the octopus needed). Without the templates the perches show part-built standing birds.
PREVIEW: run install_birds1.lua's body in a play test (the Templates folder carries over from the old Birds folder), expect
"Birds: 7 sites on this screen (3 perched) (mesh: pelican, gull)" in the client log; pictures: the pelican on the quay (close),
the gulls on the rail mid-flap, the lighthouse gulls; say if a bone turns the wrong way (the axis maths follows the RIG_NOTES
table: a bone turns about the model's axis mapped into the bone's own space at rest), and move the perches onto real posts /
rails with the attribute, then report the numbers you settled on.

Result job 104 CORRECTIONS (runner 7's Studio readings, 3981d7b): the two Airport-connection parts by the chateau pad are
CanCollide/CanQuery/CanTouch false (not a hazard); JapanMap has Origin (6000,0,0) and the three stations their StationIndex (the
train fragility is latent, not a fault); ServerStorage's 318,798 instances are 91% ONE folder, PortoEnvironmentBackup_20261001
(291,576: eighty "Before..." copies of Porto's buildings from Oct 1-3) - four times the live Porto map; the first thing to archive
to a separate place file, Japan or no Japan. MusicClient exported (tools/japan/studio_2026-10-15/MusicClient.lua). The findings
document is corrected (tools/japan/FINDINGS_japan_2026-10-15.md).

## Job 105: the Japan fixes - Studio EDIT (ask Shannon before the edit, as always; her words: "please make any fixes for issues you found on the Japan map") - runner 7

tools/japan/japan_fix1.lua (from make_japan_fix1.py; every patch self-tested on the Oct 15 exports and compiled): exact-string patches
of NINE live scripts, all anchors counted first (one missing = nothing changed), originals -> HudBackup.<Name>_pre_japanfix1, each
patched source compiled before the write, a script already carrying JAPANFIX1 skipped. Expect nine "QQ JFIX <Name> a -> b chars" lines,
"QQ JFIX BalloonField.JapanPreview = true", "QQ JFIX DONE: 9 scripts patched, 0 already patched". What it fixes (FINDINGS A1 / A1d / A2):
- SpawnReturnServer, BalloonServer, JapanEnvironment: the JapanPreviewAccess module is optional (FindFirstChild + a stub that allows
  nobody) - removing Japan can no longer stop the dais return, the Area attribute, CharacterAutoLoads or the balloon.
- SpawnReturnServer: her Area becomes "japan" in Japan instead of freezing at "domaine" / "porto" (the French HUD, the daily pill,
  the question reminders, the shop's country all treat "japan" as not-France).
- BalloonServer: the end-of-flight tail runs under pcall (the balloon is freed whatever happens), the PlayerRemoving safety net is
  back (a vanished rider frees the balloon a second later), a landed preview counts as a balloon flight, and the new BalloonField
  attribute JapanPreview = false gives her the ORDINARY ride again (the client's prompt text follows it).
- BalloonClient: the reveal remembers fog / atmosphere / clouds and puts them back on an aborted flight or a respawn (a landing hands
  over to JapanAtmosphere); no lightning behind the cloud cover; after a respawn the camera follows the new character; the toast
  uses her display name.
- JapanAtmosphere: the game's baseline (fog, atmosphere, ClockTime AND the Clouds) is taken once at load and restored when she
  leaves Japan - the end of the "no fog, thin clouds after a balloon trip" problem; it no longer waits for the waterwheel to stream
  in before it works.
- JapanEnvironment: Origin is read before the train is marked busy; the chateau taxi streams the ground in before the hop.
- HidePortoFromFrance / HideFranceFromPorto: Japan counts as neither side (no 70k-instance sweep when she crosses z -260 / -560 there).
- JapanWaterAppearance owner-only; JapanPreviewVisibility also hides Smoke / Fire / Sparkles / Highlight.
NOT in this job (design / terrain, her call): the missing sea round the island, the floating backdrop / lookout / bamboo, the
invisible water floors, the sculpted meshes' collision, the taxi door in the chateau grounds, the Porto backup folder (291k).
PLAY TEST after the edit (as her, the owner): (1) balloon to Japan, then the taxi back to the chateau: the fog, the clouds and the
atmosphere look as before the trip (compare with a fresh join); (2) in Japan her Area attribute reads "japan" (Players.<her>.Area in
the Explorer) and no French pill / reminder shows; (3) the train rides and the prompts come back after it; (4) as an ordinary test
player (a second client, or a Studio test server with the owner check failing): the balloon ride ends home as before, with
balloon_flights awarded; (5) set BalloonField.JapanPreview = false in a test: her prompt says "All aboard" and the ordinary ride
runs. Report every QQ JFIX line.

Result job 100 round 3 PREVIEW (runner 7, b276363, play test Oct 15 ~13:30Z, nothing installed, Edit verified clean after): Shannon
imported pelican_rigged.fbx + gull_rigged.fbx with Import 3D (they landed in JAPAN at (5919, 9..12, 74): Models gull_rigged /
pelican_rigged, MeshPart Gull / Pelican with all 16 / 18 Bones under it, InitialPoses + AnimationController, UNANCHORED and
CanCollide true, MeshPart facing -Z up +Y, PivotOffset rotated 90 deg about X with position (0,-2.25,0) / (0,-1.5,0) = the feet).
On the test server: workspace.Birds.Templates {Pelican, Gull} = clones, anchored, PivotOffset rotation cleared (position kept), then
install_birds1.lua's body (20446, adler32 1373547079): "QQ BIRDS DONE ... 7 sites: 4 flocks + 3 perches ...". Client log "Birds: 7
sites on this screen (3 perched) (mesh: pelican, gull, gull)". THREE FINDINGS for v4: (1) STREAMING: the templates sat in Japan, so
the client had the Models but not their MeshParts - the perches came up EMPTY (0 meshparts) until I set ModelStreamingMode
Persistent on both templates (then a Sites nudge rebuilt them with mesh + bones). The installer must make Templates' models
Persistent (and anchored, no collide) - and move her imports out of Japan into Templates. (2) PERCH SPOTS: (222,-46.5,-662) is over
the WATER (nothing under it to the terrain at -52.9); the lighthouse spot y 2.4 buried the gulls' feet 1.1 in the rock (top 3.5).
Settled numbers that look right in the pictures: pelican on the quay coping (232.5, -46.56, -667.6) yaw 280 (faces the promenade);
three gulls on the coping stones (231.6, -46.56, -673.4) yaw 102 gap 2.6 (along the edge, facing the water); lighthouse gulls
(526, 3.5, -1170) yaw 300 (on the rock beside the lighthouse keeper). (3) BONES: every axis turns the right way - measured at its
largest: Wing.L 55 deg about bird-frame (0,0,-1), Wing.R 55 about (0,0,+1) = up and out on both sides; Head yaw -35..+35; Thighs
swing fore/aft; Body roll; the pelican's Jaw tips the bill down. Pictures with poses held: tools/birds/shots/r3_*.jpg. No bone needs
flipping; the whole bird faces -Z at rest (no facing attribute needed). Also: BirdsClient animates on RenderStepped.

Result job 103 PREVIEW (runner 7, 3740085, same play test): install_treehouse1.lua body (33952, adler32 3227345674) on the test server:
QQ TREE oak at (-4, 0.1, -30) on terrain Grass, yaw 12.7 (its +z faces the spawn)
QQ TREE piece p1 (planks) at (14, 0.1, -8) on terrain Grass
QQ TREE piece p2 (rope) at (-12, 0.1, -12) on terrain Grass
QQ TREE piece p3 (planks) at (22, 0.1, -24) on terrain Grass (nudged 0, 6)
QQ TREE piece p4 (shingles) at (-20, 0.1, -40) on terrain Grass
QQ TREE piece p5 (planks) at (30, 0.1, -60) on terrain Grass
QQ TREE piece p6 (rope) at (-12, 0.1, -85) on terrain Grass
QQ TREE piece p7 (shingles) at (60, 0.1, -105) on terrain Grass
QQ TREE piece p8 (planks) at (70, 0.1, -140) on terrain Grass
QQ TREE piece p9 (lantern, beyond the gate) at (210, 0.6, -70) on PlotN
QQ TREE piece p10 SKIPPED - no open ground within 12 studs of (300, -90): Roof at y 25.7
QQ TREE piece p11 (shingles, beyond the gate) at (455, 3.2, -75) on terrain Sand
QQ TREE piece p12 (lantern, beyond the gate) at (560, 6.8, -110) on terrain Ground
QQ TREE DONE: workspace.Treehouse (oak at (-4, 0.1, -30); 11 pieces placed, skipped p10 (Roof at y 25.7); TreehouseServer 4806, TreehouseClient 19277 chars; RS.TreehousePick)
Client: "Treehouse: 0 of 11 pieces on this screen". P10 NEEDS A NEW SPOT (Rue de Noisette under a roof); with 11 pieces the FLAG
stage (12) never shows and the sign/pill say "of 11". Checked: a real pick-up of p1 ("got,p1,1"; pill "Treehouse: 1 of 11 pieces";
toast "Treehouse piece 1 of 11! 10 more to find"; the LADDER appears); house at 3 (deck), 7 (walls + door), 11 (roof, window, lit
lantern; sign "All 11 pieces found ..."); the LADDER CLIMBS (W held: Running > Climbing > Running, 3.3 -> 13.8 = standing on the
deck, then walked onto it through the door); the DECK HOLDS (stood at 13.8). The last piece p12 picked for real at the chateau: server
"got,p12,11 | done,100,11", Acorns 110 -> 210 once, Item_tree_done 1; the card "Treehouse built! 100 acorns for the builder. Climb
the ladder and look out over the forest. [Hooray!]" (in its own ScreenGui TreehouseDone). Pictures: tools/treehouse/shots/t1..t6.
Nothing installed; both wait for her yes.

Round 4 birds / round 3 treehouse (cloud thread, after runner 7's previews, 2c71acd): BIRDS - the three perches moved to the spots
runner 7 settled (pelican (232.5,-46.56,-667.6) yaw 280; 3 gulls (231.6,-46.56,-673.4) yaw 102 gap 2.6; lighthouse gulls y 3.5) and
the installer sets ModelStreamingMode Persistent on every Templates model (her imports sit far away; a streamed-out template is an
empty Model and the perches came up empty). TREEHOUSE - p10 moves from (300,-90) (under a Rue de Noisette roof) to (240,-70) by the
mime, the nudge rings widen to 6/12/18/24 studs, and the house's stage thresholds now follow the number of pieces actually placed
(12: 1/3/5/7/9/10/11/12; 11: 1/3/5/6/8/9/10/11), so a skipped spot can never hide the flag. Both ready for her morning yes: the
runner re-runs the treehouse preview body once to confirm p10 lands (expect twelve "QQ TREE piece" lines, none SKIPPED), then installs
on her word; the birds install needs workspace.Birds.Templates.Pelican / Gull in Edit first (clone her imports there, as in the preview).
Job 105 REVIEWED (cloud thread; adversarial review of all nine patches: no change for ordinary players; the installer's find/replace
proven byte-for-byte in standalone Luau). Round 2 fixes from it: the balloon's tail now frees, homes and resets the balloon only while
it is still this rider's (busy == p) - during the owner's long preview yields the safety net may already have handed it to the next
rider; a tail fault also clears JapanPreviewInFlight and sends "home"; the backup clone is nil-guarded. BalloonServer now 7 patches.
Ready for Shannon's yes: run tools/japan/japan_fix1.lua in Edit; expect nine "QQ JFIX" lines and "QQ JFIX DONE: 9 scripts patched".

Birds v5 (cloud thread, after runner 7's fresh play test of the install): the client built the perches before the Persistent
templates' MeshParts had arrived and never rebuilt. v5 waits (up to 25 s) until every perch kind's template has a part before it
builds, rebuilds (debounced 1.5 s) when a template or its mesh arrives later, and prints its "Birds: ..." line after that wait.
Re-run install_birds1.lua in Edit on her word (re-runnable: the Templates carry over; expect "Birds: 7 sites ... (3 perched) (mesh:
pelican, gull)" in a fresh play test). Not for publishing until that line reads mesh.

## Job 106: the Japan map's visual fixes - READ-ONLY geometry survey first (Edit; no ask), then the fix installer - runner 7

Shannon: "make the visual fixes in the Japan map, especially with the ground, a lot of things are overlapping and a lot of things are
floating and the water has places where it is exposed and look weird". tools/japan/survey106.lua (compiles; pcall'd; returns its
lines) measures what the fixer will act on: every prop's gap to the ground under five footprint points (FLOAT / SUNK / SLOPE lines
with the gap in studs and what lies under), flat ground slabs whose top faces sit within 0.15 studs and overlap (FIGHT lines =
z-fighting), and the water on a 12-stud grid (visible water, its levels, water over nothing, water lapping over ground parts, the
JapanWaterBasins manifest) plus a 25-stud ASCII MAP of the island (~ water, v water over nothing, f water over a part, # parts,
. terrain, blank nothing). Send every line unchanged (the MAP rows too) to tools/japan/survey106_result_<date>.txt. Then PICTURES in
Edit (camera placed by script, as before): the three worst FLOAT lines, the three worst SUNK, two FIGHT spots, and the water edge at
two WATER-LAP spots and one WATER-VOID spot - name each picture by the line it shows. The fixer (next commit) re-measures and acts
on thresholds we set from these numbers: snap floating props down, lift buried ones, nudge fighting slabs, fill / drain water.

## Job 107: the statues' second right arm (Shannon, Oct 15: "2 arms on the right hand side, one that holds up the acorn and the original arm the player avatar has") - runner 7

Reading village/build_champion.lua (MakeStatue): the arm pose moves the arm's parts and everything welded to them, so a lone extra
arm at the side means TWO figures on one spot - every other part overlaps exactly and only the raised arm shows twice. Two paths do
it: two builds overlapping (the keeper's retries, a Hall refresh) both parent a "Figure" to the same folder and the first is never
taken down; or a build that throws after parenting (the pose step) leaves an unposed figure and the retry stands a posed one in it.
STEP 1 (read-only, no ask, Edit or a play test): tools/statues/probe107.lua lists every model with a RightHand (players excluded),
how many RightHand / RightUpperArm parts it holds, whether its right hand is raised, and flags models within 2.5 studs of another
("SHARES ITS SPOT WITH"). Send the "QQ ARM" lines; a pair on one spot confirms the cause, a single model with RightHand x2 means a
worn sleeve instead (tell me, and the fix changes). Also export the live workspace.Champion.ChampionServer to
tools/statues/studio_2026-10-15/ChampionServer.lua (the repo's village/build_champion.lua is the Oct 10 copy).
STEP 2 (ask her): tools/statues/armfix1.lua - two exact-string patches of ChampionServer: MakeStatue runs one figure at a time (a
60 s queue, a failed build frees it) and destroys a same-named figure already in the target folder before parenting the new one.
Backup HudBackup.ChampionServer_pre_armfix1; expect "QQ ARM DONE: ChampionServer a -> b chars". Then: delete the doubled figures
standing now (the probe names them) or let the next daily / Hall rebuild replace them, and a play test of the fountain statue, the
Hall carousel and the harbour Guardian - one right arm each.

Result INSTALLS (runner 7, Oct 15 ~14:30Z, Shannon's yes to all three, Studio EDIT, unpublished): BIRDS 1c1ff14 - her imports moved
into workspace.Birds.Templates (Pelican / Gull; anchored, no collide/query/touch, PivotOffset rotation cleared, parked at
(-50,-200,-50) / (-44,-200,-50)), then "QQ BIRDS DONE: workspace.Birds (BirdsClient 17318 chars; 7 sites: 4 flocks + 3 perches ...);
the old folder is HudBackup.Birds_pre_1", Templates Persistent. TREEHOUSE c043d9b - 12 "QQ TREE piece" lines, none skipped (p10 at
(240, 0.1, -60) on terrain Grass), "QQ TREE DONE: ... 12 pieces placed; TreehouseServer 4806, TreehouseClient 19623 chars". JAPAN
FIX fcc8139 - "QQ JFIX SpawnReturnServer 5219 -> 5901 chars (2 patches ...)", "BalloonServer 14415 -> 15866 (7)", "BalloonClient
35840 -> 37493 (8)", "JapanEnvironment 6327 -> 7092 (3)", "JapanAtmosphere 1807 -> 2577 (3)", "HidePortoFromFrance 3902 -> 4035
(1)", "HideFranceFromPorto 3334 -> 3462 (1)", "JapanWaterAppearance 1039 -> 1110 (1)", "JapanPreviewVisibility 2184 -> 2412 (2)",
each "backup HudBackup.<Name>_pre_japanfix1"; "QQ JFIX BalloonField.JapanPreview = true (set it false for the ordinary ride)";
"QQ JFIX DONE: 9 scripts patched, 0 already patched".

Result job 105 PLAY CHECKS (runner 7, play test as her, nothing kept): (1) balloon to Japan (rise 0, hover 16, gust 24, storm 42,
sign 55, previewCloud 61, previewReveal 65, descent 71, touchdown 86, landed 89 s; Japan fog 100000, atmo 0.08/0, clouds 0.08/0.10),
train, then the taxi back to the chateau (438,7,-36): fog 350..1100, clock 14.5, atmosphere 0.30/0.00/0.00, clouds 0.60/0.40 -
IDENTICAL to the start of the session. (2) Area "japan" on landing ("domaine" back at the chateau); no golden / question / daily
notice visible in Japan. (3) Lantern Street -> Palace Grounds ride: seated, carried 6000 -> 6379, off at the platform, StationIndex
3, all three station prompts enabled again with new texts. (4) not testable here (a Studio test player is always the owner). (5)
JapanPreview = false on the test server: the ORDINARY ride ran (rise, hover, gust, storm, sign, fade, home), back on the field,
Item_balloon_flights 1 -> 2 (the landed preview had counted as 1). The prompt text did NOT follow the attribute at once (still
"private Japan preview / Fly to Japan" 2 s after the change; "Your balloon / All aboard" only after the ride) - updatePrompt is not
wired to JapanPreview's change signal. BIRDS v4 BUG (sent earlier): "Birds: 7 sites ... (part-built)" - built before the
Persistent templates streamed in; v5 at 70594b5 not yet run (needs her word).

Result job 106 (runner 7, 70594b5, Edit, read-only): survey106.lua (11356, adler32 196694321) - 148 "QQ GEO" lines unchanged in
tools/japan/survey106_result_2026-10-15.txt (31 FLOATING, 35 SUNK, 9 SLOPE, 134 FIGHT pairs, 26 WATER-LAP, water over NOTHING 0 -
so no WATER-VOID picture). Pictures in tools/japan/shots106/ named by their line: FLOAT MountainBackdrop (5440,-580) = the volcano's
crater top, reads as part of the volcano; FLOAT Fuji photography lookout (5684,-304) = a deck with a red railing jutting off the
hill edge, no posts under its outer end; FLOAT Bamboo clump (6464,-365) = bamboo poles on the steep south bank, bases in the air
downhill; SUNK Bamboo grove maze (5478,-245) = poles in grass where the ground rises, reads fine (just shorter); SUNK Northern bridge
approach steps (6101,-215) = at the canal's north end a grey slab cuts across the water and the water shows a hard bright wall
(one of her "exposed water" spots); SUNK Blue vending machine (6027,82) = base 1 stud in the ground, reads as a plain box; FIGHT
palace apron (6386,-24) and FIGHT walkway/Lantern Street paving (6000,-40) = patchwork / faint seams in a still, the flicker shows
in motion; WATER-LAP canal (6092,-100) = water fills the stone channel, fine; WATER-LAP lake (6728,224) = a stair runs into the lake
and its underwater support shows through as a hard-edged dark slab (another "weird water" spot).

Result job 107 STEP 1 (runner 7, 116c970): ChampionServer exported: tools/statues/studio_2026-10-15/ChampionServer.lua (34338,
adler32 1570845504, via base64 through the Studio log, verified). probe107 (3585, adler32 284781702) in Edit: "QQ ARM models with a
RightHand (players excluded): 0" (statues are built at run time). In a play test with ChampionServer's Studio switches
(StatueDebug(9611145467, "SelBell") -> "feet 4.40 | plinth top 4.40 | box bottom 4.40 | height 9.3"; HallDebug two keepers uid 1 +
156): "QQ ARM models with a RightHand (players excluded): 2", "QQ ARM ReplicatedStorage.HallStatues.No_2.Figure: 17 parts;
RightHand x1, RightUpperArm x1, LeftHand x1, Head x1; right hand down; anchored; at (403,11,-28) box 5x7x2", "QQ ARM
Workspace.Champion.Figure: 18 parts; RightHand x1, RightUpperArm x1, LeftHand x1, Head x1; right hand down; anchored; at
(262,9,-54) box 5x9x3". NO "SHARES ITS SPOT" pair, no doubled hand - not reproduced with these avatars. HoldHand = Left, so the
raised acorn arm is the statue's LEFT = the VIEWER'S RIGHT (her "two arms on the right hand side"). LEAD: layered clothing. Her
own statue carries "Accessory (g) [Pants, LAYERED]" (WrapLayer order 6; the body has 15 WrapTargets); aim() moves the arm parts and
destroys the Humanoid, but a WrapLayer top (jacket / sweater / shirt accessory) is wrapped to the body cage - its sleeve may stay
in the arm's original hanging pose = "the original arm the avatar has". The two test avatars have no layered TOP, so it could not
show. Needed: whose statue showed it (fountain / Hall / harbour Guardian, and the player's name) - then StatueDebug with that uid
reproduces it. Pictures: tools/statues/shots/fountain_statue_SelBell_*.jpg.

Job 106 FIXER (cloud thread, from survey106's 148 lines and the ten pictures; Shannon's call for the edge: "real sea with a wall farther
out"): tools/japan/japan_geo1.lua (compiles; an adversarial review is running - wait for the commit that says "reviewed"). Edit mode;
everything re-measured; every move logged in ServerStorage.HudBackup.JapanGeo1_log (JSON) for an undo. What it does: (1) PROPS - the
Landscape bamboo clumps floating on the south ridge's slope come down onto the ground under their centre; the Blue vending machine
comes up out of the market platform (it stood 1 stud sunk); the Raked gravel garden (1.8 up) and the Fishing bank come down; the Fuji
photography lookout gets a stone plinth down to the hillside; any other small prop hovering evenly up to 3 studs comes down. Left
alone: bridges, the canal boat, the waterwheel, the castle's inner staircase, the market stalls (their foundations are meant to sit in
the ground - the survey's "floating" market stalls were that), the bamboo grove maze (the picture shows it fine), the volcano crater.
(2) SLABS - the 134 fighting pairs (the dashed seams on the paving): the higher of each pair rises until the faces are 0.16 apart,
repeated until none fight. (3) WATER - the lake stair's dark underwater support takes the bed's sand look; each rectangular basin in
Codex's JapanWaterBasins manifest is refilled (air inside the basin box up to its level becomes water: the canal no longer ends in a
vertical wall short of its north end - the "hard water wall" picture); a REAL SEA at y -6 (the level of the sea basin east of the
island) across x 4900..7400, z -1500..900 - only air becomes water, land is untouched - on a sand bed at y -64..-60, and an invisible
wall 150 studs out from the map's box (JapanMap."Sea wall"). PLAY TEST after: the slope bamboo stands on the ground; the vending
machine on the platform; the paving seams gone (Lantern Street, the market lane, the palace apron); the canal's north end; the lake
stair; walk off the north edge and the west edge - into water, swim to the wall; the volcano and Fuji from the sea.

## Job 108 (her idea, Oct 15): paid cheats for the harder treehouse pieces - DESIGN, waits for her Developer Product id

Shannon: "lets make some paid cheats to find some more difficult treehouse pieces". Design (cloud thread): a "Piece finder" bought
for 150 acorns OR a Developer Product (Robux; consumable, so a product not a pass): for 90 s a glowing trail of acorn-gold sparkles
leads from the player to the NEAREST piece they have not found yet (within the map they are in; beyond-the-gate pieces only once the
gate is open), with a pointer pill "Treehouse piece: 62 studs" that counts down; the piece gets a beacon. Sold from the treehouse sign
(a second prompt "Need a hint?") and from the HUD pill. The acorn price keeps it fair for free players; the Robux price is hers.
WHAT SHE CREATES: Creator Dashboard > the experience > Monetization > Developer Products > Create: name "Treehouse piece finder",
description "Shows the way to your nearest missing treehouse piece for 90 seconds", a 512 x 512 image (optional; an acorn on a
map), price in Robux (suggest 25-49). Send the product id. The game passes for the hand glider and the zip line handle are the same
page, "Passes": name required ("Hand glider", "Zip line handle"), description optional, image optional (a screenshot of the item in
the game works), price in Robux - send both ids. Code: TreehouseServer gets a "finder" request (acorns deducted through the Acorns
attribute + RS.AwardAcorns with a negative amount if the ledger allows it - to check - or MarketplaceService:PromptProductPurchase
for Robux with ProcessReceipt in a small ReceiptServer), TreehouseClient draws the trail and the pill.

Result job 101 r2 + birds v5 INSTALLED (runner 7, Shannon's "yes" in this session, Studio EDIT, unpublished): golden_gate2.lua at
c637682 (5360, adler32 2575032067): "QQ GOLD QuestionClient is 28598 chars", "QQ GOLD DONE: QuestionClient 28598 -> 28803 chars;
backup ServerStorage.HudBackup.QuestionClient_pre_golden2", "QQ GOLD DONE: DailyClient 15020 -> 15211 chars; backup
ServerStorage.HudBackup.DailyClient_pre_golden2". Birds v5 install_birds1.lua at 70594b5 (21872, adler32 4190865495): "QQ BIRDS DONE:
workspace.Birds (BirdsClient 18479 chars; 7 sites: 4 flocks + 3 perches ...); the old folder is HudBackup.Birds_pre_2"; Templates
carried over, Persistent. Fresh play test: Pelican on the quay 1 meshpart / 18 bones, Gulls on the harbour rail 3 / 48, Gulls at the
lighthouse 2 / 32 - the meshes are there from the start now.

Result job 107 REPRODUCED (runner 7, play test, nothing kept): Shannon named cryb4bi (uid 635352862, "might be a sleeve") and
nana3365308 (uid 4416624022, the 8th Grand Keeper) and sent pictures. StatueDebug(4416624022) at the fountain: her avatar wears
"Accessory (T2_Ballet_Sleeves_(Nm)) [Jacket, LAYERED] attach BodyFrontAttachment" (+ Summer hair, layered sneakers, a face
accessory). Front picture: next to the raised acorn arm (the statue's LEFT = the viewer's right) a thin second arm hangs from the
shoulder to the hip. Destroying only that Jacket accessory on the test figure removes the hanging arm - before/after picture
tools/statues/shots/nana_with_vs_without_layered_jacket.jpg. CAUSE = a layered (WrapLayer) upper-body accessory: its sleeve stays in
the avatar's original pose when aim() moves the arm. So armfix round 2 as you proposed: drop WrapLayer Jacket / Sweater / Shirt /
TShirt / DressSkirt (any layered upper-body type) before stoneify. cryb4bi's CURRENT avatar (StatueDebug 635352862) has only
LongStraightHair + a layered eyebrow, no sleeve - her statue's sleeve must come from what she wore then, or from her boutique look.
BOUTIQUE ruled out: one MakeStatue figure per style (rue, cafe, chateau, riviera, jardin, soiree, adventurer, skycaptain, royalpage,
woodlandbard, moonmagician, harborsailor, variant 1) - every Sleeve / PuffSleeve / Cuff sits on its arm after the pose, none left
hanging. NEW from Shannon: "it looks like the statue in the monument for star is completely gone" - asking her which monument and
the exact name; then StatueDebug with that uid shows whether makeFigure fails for that avatar.

Job 107 ROUND 2 (cloud thread; runner 7 reproduced it: nana3365308's "T2_Ballet_Sleeves", a LAYERED jacket - its sleeve stays in the
avatar's pose beside the carved raised arm; destroying that accessory removes the second arm; the boutique's 12 styles all follow the
arm). tools/statues/armfix1.lua now carries THREE patches of workspace.Champion.ChampionServer (self-tested on the live 34338-byte
export): the one-figure-at-a-time queue, the same-spot guard, and - the reproduced cause - layered upper-body clothing (WrapLayer
accessories of type Jacket / Shirt / TShirt / Sweater / DressSkirt) comes off the figure before stoneify; layered pants and shoes
keep. Backup HudBackup.ChampionServer_pre_armfix1. On her word: run it in Edit ("QQ ARM DONE: ChampionServer 34338 -> n"), then a
StatueDebug build of nana3365308 (one right arm), and the fountain / Hall / Guardian statues rebuild themselves at their next refresh
(or rebuild them now). "The statue in the monument for star is completely gone" (Shannon): waiting for which monument and the name.

## Job 109: Game Passes beside the Acorn Store - the zip line handle (pass 2036372649) and the hand glider (pass 2037656625) - runner 7

Shannon's ids (Oct 15) and her ask: "purchase with a LOT of acorns OR purchase for robux". tools/passes/install_passes1.lua (from
make_install_passes1.py; self-tested on both repo copies of the ShopClient, 35014 and 38666 - confirm which is live by size, the
anchors are the same in both; compiles): (1) workspace.Passes {PassServer (RunContext Server, src/PassServer.lua)} with attributes
Pass_ziphandle / Pass_glider - whoever OWNS a pass gets the item on arrival (UserOwnsGamePassAsync after the save loads) and whoever
BUYS one gets it the moment Roblox confirms (PromptGamePassPurchaseFinished), through RS.AwardItems so it is kept on the save exactly
like an acorn purchase (Item_<id>; the tower and the ramp already check that). (2) Three exact-string patches of ShopClient (marker
PASS1; backup HudBackup.ShopClient_pre_pass1): on the row of any item with a pass id a GREEN Robux button (its price fetched from
Roblox) sits right of the acorn button (acorns on the left, 70 px each) until the item is yours; a click opens Roblox's own
purchase prompt. Nothing else in the store changes. ACORN PRICES are hers (attributes on workspace.Shop): today Price_ziphandle 60,
Price_glider 1000; the "a LOT of acorns" side suggested: ziphandle 600, glider 2500 - set them in Studio, no code.
EDIT on her word; expect "QQ PASS DONE: workspace.Passes (PassServer n chars; Pass_ziphandle 2036372649, Pass_glider 2037656625);
ShopClient 38666 -> 40654 chars; Price_...". PLAY TEST: the store's France tab: the Zipline handle and Hang glider rows show "600
acorns" (or whatever she set) and a green Robux button with the pass price; the Robux button opens Roblox's prompt (in Studio the
purchase can be tested with the test-purchase dialog: buy -> the row flips to "owned" and the ride accepts you); a player who
already owns the pass gets the item on join; phones: the two 70-px buttons fit the row (picture).

Result job 107 ROUND 2 INSTALLED (runner 7, Shannon's "Yes, install it", Studio EDIT, unpublished): armfix1.lua at 5fc434f (3939,
adler32 4026402376): "QQ ARM ChampionServer is 34338 chars", "QQ ARM DONE: ChampionServer 34338 -> 35767 chars; backup
ServerStorage.HudBackup.ChampionServer_pre_armfix1". Play test: StatueDebug(4416624022) -> "feet 4.40 | plinth top 4.40 | box bottom
3.10 | height 9.5"; one Figure on the plinth; accessories left: Summer [Hair], layered sneakers x2, a Face accessory - the layered
Jacket is gone; log "Champion: the statue of nana3365308 (No. nil) stands by the fountain (arms posed true/true)", no warning.
Picture tools/statues/shots/nana_statue_after_armfix1.jpg: one raised arm, one relaxed arm, no hanging sleeve. Job 109 read: the
live ShopClient is 38666 chars (adler32 1446548555); Price_ziphandle 60, Price_glider 1000. STAR: Shannon says the missing statue is in
the FRENCH HALL OF FAME; asking her for the exact name to rebuild it with StatueDebug.

Job 109 REVIEWED (cloud thread; round 2 from the review): the Robux button hides, and refuses a click, until the save has loaded
(the store can open before it, and a player who already bought the item with acorns could have been sold the pass); the acorn
button's text scales to its half-width; workspace.Passes is waited for; a re-run never overrides a deliberate 0 in Pass_glider;
PassServer re-checks ownership when Roblox refuses a sale ("already own") so the item still arrives. Four ShopClient patches now.
Design note for Shannon: the Robux path does not wait for "find 10 in the Rue first" the way the acorn purchase does - usual for
passes; say if the gate should apply to Robux too. ACORN PRICES: her "yes to both" (Oct 15) = Price_ziphandle 600, Price_glider
2500 - set them on workspace.Shop when installing. Run install_passes1.lua from this commit.

## Job 110: "Buy here" cards at the zipline's launch and the hang glider's ramp (play-test PREVIEW, then install on her word) - runner 7

Shannon: "put a button or icon at the top of the tower where you zipline and the top of the cliff where you handglide to let them
buy it right from that spot; I noticed a lot of games do that". tools/buyhere/install_buyhere1.lua (BuyHereClient, RunContext
Client, 5141 chars; compiles): a floating card (this player's only) over Zipline.Launch and over HangGlider.Ramp for a player
without the item: the name, "600 acorns   or   R$ 79" (acorns from the store's Price_<id>, Robux from the pass), and a green "Buy
here" button that opens the Acorn Store at that row (both buttons there); hides the moment the item is theirs; shows within 45-50
studs. Spots are the folder's Spots attribute (JSON) - move a card with it. PREVIEW: a play test with a fresh test player (no items):
pictures of the card at the tower top and at the ramp, then a tap -> the store opens at the row; then install on her word.

Result STAR (runner 7, play test, nothing kept): Shannon: the missing statue is in the FRENCH HALL OF FAME; the record she sent:
{"day": 20722, "n": 2, "name": "STAR", "t": 1790423656, "uid": 3129625152, "user": "Captin_crunch65"}. In the test:
GetHumanoidDescriptionFromUserId ok; CreateHumanoidModelFromDescription ok (321 descendants); one accessory "Hair-Male-004-Black
[Hair, LAYERED]"; HeightScale 1.05 WidthScale 0.88 BodyTypeScale 0.40 (a short body). StatueDebug(3129625152, "STAR") -> "feet 4.40 |
plinth top 4.40 | box bottom 3.02 | height 6.6", no warning. HallDebug({uid 3129625152, "STAR"}) -> HallJson
[{"uid":3129625152,"name":"STAR","no":1,"total":44,"day":20722}]; RS.HallStatues.No_1 = Figure 17 parts box (3.5,5.5,2.3) +
GiantAcorn; the client's HallView_local shows it at (403.0,8.6,-28.5). Picture tools/statues/shots/hall_STAR_statue_test.jpg: the
statue IS there in Studio - small (about the saluting squirrel's chest height), the acorn floating beside it rather than on the hand.
So nothing in STAR's avatar breaks the build; on the live server the build must have failed. The French HallServer (exported:
tools/statues/studio_2026-10-15/HallServer_France.lua, 5874 chars, adler32 1535594508, verified) builds a statue ON REQUEST
(RemoteFunction from the client), and on a makeStatue failure it warns "HallServer: no statue for No. <n>: <err>" and returns nil
(nothing cached, so a LATER request would try again). Check HallClient: does it ever ask again after a nil? Her live F9 SERVER log
would show the warn line if this is it. STAR's statue is also small for the frame (BodyTypeScale 0.4) and its acorn misses the hand.

## Job 107b: the French Hall of Fame's empty frame ("the statue in the monument for star is completely gone") - runner 7

Runner 7: STAR = Captin_crunch65 (uid 3129625152, No. 2); the avatar and the figure build without a warning in a play test, so the
LIVE build failed once (a hiccup fetching the avatar). Reading the exported HallServer_France and the client: a failed MakeStatue is
neither cached nor asked for again - the client clears the frame and shows NOTHING until someone pages away and back; a server
hiccup leaves the frame empty for the whole session. tools/statues/hallretry1.lua (make_hallretry1.py; compiles; server patch
self-tested on the live export): workspace.HallOfFame.HallServer's build() tries MakeStatue twice (2 s apart); HallClient asks up
to three times (4 s apart) while that statue is still the one wanted. Backups HudBackup.HallServer_pre_hallretry1 /
HallClient_pre_hallretry1. Please export the live HallClient first (tools/statues/studio_2026-10-15/HallClient_France.lua) so the
anchor is confirmed, then run on her word; expect "QQ HALL HallServer 5874 -> n", "QQ HALL HallClient a -> b", "QQ HALL DONE: 2".
Separately noted: STAR's body is short (BodyTypeScale 0.4) so the statue is small in the frame and its acorn floats beside the
hand - a picture and the hand / acorn positions (GetBoundingBox of the GiantAcorn vs the LeftHand) would let me size the acorn to
the hand rather than the body.

Result job 109 INSTALLED (runner 7, Shannon's "Yes, 600 / 2500 acorns", Studio EDIT, unpublished): install_passes1.lua at 19ceb34
(9597, adler32 349118418): "QQ PASS ShopClient is 38666 chars", "QQ PASS DONE: workspace.Passes (PassServer 2815 chars;
Pass_ziphandle 2036372649, Pass_glider 2037656625); ShopClient 38666 -> 41226 chars; Price_ziphandle 60, Price_glider 1000 acorns";
then workspace.Shop Price_ziphandle 60 -> 600, Price_glider 1000 -> 2500 (her prices). Play test (Item_ziphandle / Item_glider set 0
on the test server, since the owner has both): the France tab's rows read "600 acorns" + a green Robux button " 45" (zipline handle)
and "2500 acorns" + " 72" (hang glider); both buttons 70 x 36 at x 884 / 958 inside the 408-wide row, no overlap. Pictures
tools/passes/shots/store_*_row.jpg. Not tested: the actual purchase prompt (Studio test purchase) and a phone-size view.

Result job 110 PREVIEW (runner 7, 19ceb34, same play test, nothing installed): install_buyhere1.lua (7201, adler32 1001074480): "QQ
BUYHERE DONE: workspace.BuyHere (BuyHereClient 5141 chars; 2 spots: Zipline/Launch NOT FOUND, HangGlider/Ramp found)". The zipline
has NO child "Launch" - its launch is only the attributes LaunchX/Y/Z = (-17.15, 78.8, 5); the tower-top parts are
Zipline.StationPost (-19,72,3) and Zipline.StationSign (-19,74,3) (the deck itself is ForestTower.Deck5, top y 70.3). In the preview
I set the zipline spot's anchor to "Zipline/StationPost" with dy 4: the card shows over the post at the tower top ("Zip line handle /
600 acorns or 45 / Buy here"). The glider card over HangGlider.Ramp.Rail: "Hang glider / 2500 acorns or 72 / Buy here", clean.
workspace.Shop.OpenAt:Fire("glider") opens the store with the Hang glider row at the top of the list. Pictures
tools/buyhere/shots/buyhere_*.jpg. FIX FOR THE INSTALL: the zipline spot's anchor -> "Zipline/StationPost" (or a point from the
Launch attributes).

Result STAR follow-up (runner 7): HallClient exported (tools/statues/studio_2026-10-15/HallClient_France.lua, 4155, adler32
2260345047, verified) for hallretry1's anchor. STAR's statue (StatueDebug 3129625152 at the fountain): LeftHand pos
(261.40,8.19,-53.98) SIZE (0.77,2.85,0.97) (her own avatar's LeftHand is 0.82 x 0.89 x 0.80); GiantAcorn box centre
(261.40,10.21,-53.98) size (1.27,1.59,1.27), bottom 9.42 (the hand box top is 9.62); Head (262.81,7.66,-53.72) size 1.72. Upper
arms 0.52 x 0.62, lower arms 0.37 x 0.36 - a body package whose HAND part carries most of the arm length (a 2.85-tall hand box). So
the acorn is placed on the top of a hand BOX that reaches far above the visible hand: in the picture
(tools/statues/shots/star_fountain_acorn.jpg) the acorn floats about a head's height above the statue and no raised arm reads.
Suggest: rest the acorn on the hand's lowest-third point along the arm direction (or on the LeftLowerArm end + a fixed offset), and
size it from the head, not the body height, when the hand box is taller than ~1.5 x its width.

Job 106 GEO REVIEWED (cloud thread; two adversarial rounds + a third set of fixes): japan_geo1.lua at this commit. Round 3: the
water is written through the terrain's CHANNELS (only the liquid layer for water, the solid layers for the sand bed - a plain
voxel round-trip would have notched every existing shore), basin boxes rounded inward to the grid so nothing spills past a bank,
the wall idempotent and clamped inside the sea on all sides with the sea 150 studs beyond it, the slab rise formula right when the
lower slab must move, bamboo hover test widened (the one visible lake-bank floater comes down), a task.wait per chunk (Studio stays
responsive; expect some seconds). RUNNER: SAVE the place first; run in Edit; the "readback" line must say "liquid 0.5" (the sea's
top cell) - if it says 0 or errors, stop and send me the output; then the play test per the FIXER paragraph (pictures before/after
at the same spots as shots106, plus the north edge into the sea and the canal's north end).
Job 110: the zipline card anchors on Zipline/StationPost (dy 4) - the installer from this commit; install on her word (109 is in).
Job 107b: hallretry1's client anchor confirmed on the live HallClient export (4155); run on her word.
Job 107c (cloud thread, from runner 7's measurements of STAR's statue: LeftHand box 2.85 tall, the acorn on its top at y 9.42, a
head above the visible hand): tools/statues/acornhand1.lua - the acorn rests in the PALM (the hand's grip attachment) for every
statue from now on; the old spot is the fallback. Statues already standing keep their acorn until rebuilt. Run on her word after
hallretry1 (same Studio window); expect "QQ ACORN DONE: ChampionServer 35767 -> n".

Result jobs 107b + 107c + 110 INSTALLED (runner 7, Shannon's yes to all four, Studio EDIT, unpublished; checked first: HallServer
5874 / 1535594508 and HallClient 4155 / 2260345047 unchanged, ChampionServer 35767): hallretry1.lua at be0d835 (3882, adler32
4263034157): "QQ HALL HallServer 5874 -> 6204 chars (backup HudBackup.HallServer_pre_hallretry1)", "QQ HALL HallClient 4155 -> 4377
chars (backup HudBackup.HallClient_pre_hallretry1)", "QQ HALL DONE: 2 patched". acornhand1.lua at 4bdb61f (2627, adler32
3823132582): "QQ ACORN DONE: ChampionServer 35767 -> 36212 chars; backup HudBackup.ChampionServer_pre_acornhand1".
install_buyhere1.lua at 4bdb61f (7216, adler32 1476539830): "QQ BUYHERE DONE: workspace.BuyHere (BuyHereClient 5141 chars; 2
spots: Zipline/StationPost found, HangGlider/Ramp found)". JOB 106 japan_geo1.lua (4bdb61f = e44dfe0, 17195, adler32 3765546536)
NOT RUN YET: she started "Save to Roblox" at 13:07:10Z just as her PC lost DNS to every roblox.com host (the log shows no save
result); a local AutoRecovery copy (16 MB) was written at 13:07:09Z with the three installs in it. Waiting for her to confirm the
Roblox save before the terrain run. Not yet re-verified in play: STAR's frame with the retry + the acorn in the palm.

Result REOPEN CHECK (runner 7, Oct 15 ~13:45Z): the Team Create session had dropped at 13:06:55Z during her DNS outage ("TeamCreateManager
Disconnected due to Lost connection to the game server, please reconnect (277)"); save 13:07 failed, publishes 13:22 / 13:27 / 13:36 each
"server publish request timed out" after 240 s. Before she closed the place I fingerprinted every script (370, path/length/adler32) and
the day's settings into the Studio log (FP1). She reopened from the start page: "team create connect (connection accepted)" at
13:41:01Z. Fingerprint FP2 on the reopened place: 366 scripts - identical except the last three installs, which never reached the
Team Create server (made at ~13:05-13:06Z): HallServer/HallClient back at 5874/4155, ChampionServer at 35767, no workspace.BuyHere.
All settings identical (Price_ziphandle 600, Price_glider 2500, JapanPreview true, water 0.85/0.65/0.10, grass, Clouds 0.60/0.40,
LookGrade, Birds Templates 2, Treehouse 12 pieces, Passes). RE-RUN (her earlier yes): hallretry1 "HallServer 5874 -> 6204", "HallClient
4155 -> 4377", "QQ HALL DONE: 2 patched"; acornhand1 "ChampionServer 35767 -> 36212"; buyhere1 "QQ BUYHERE DONE ... Zipline/StationPost
found, HangGlider/Ramp found". All four sources now equal the FP1 values exactly. ALL PRESENT - she can publish. japan_geo1 still
unrun (after a successful publish + save).

PUBLISHED (Shannon, Oct 15 2026): Studio log "Sent message to server to publish" 13:43:10Z -> "Published new changes in "1001 Squirrels"
to Roblox" / "Place published" 13:43:15Z (place version before it 1426); games API updated 2026-10-15T13:43:15.7Z. LIVE now = everything
installed in Edit through today: look pass (water, grading, grass) + Clouds, Gift caption (102), interaction counter r2 (98), treehouse
(c043d9b, 12 pieces), birds v5 (perched pelican + gulls, Templates Persistent), Japan fixes (job 105, 9 scripts), golden gate r2 (101),
armfix r2 (107), Game Passes + 600/2500 prices (109), Buy here cards (110), hall retry (107b), acorn in the palm (107c). She is to Shut
Down All Servers so players get it. NOT in it: japan_geo1 (job 106) - next, after a fresh Save to Roblox.

Birds v6 (Shannon, after the publish: "those birds flying in the france map are too many and too quickly; it looks like that movie
The Birds"): the village swallows are THREE (were eight), on a wider lazy figure-eight at less than half the speed (0.38, was 0.85),
flapping in bouts between glides (3.2 beats/s, was 6), banking less. Harbour and lighthouse gulls unchanged. Re-run
install_birds1.lua in Edit (re-runnable; the Templates carry over), then a play test over the Rue (a picture), then publish on her word.

Treehouse round 4 (Shannon, hunting the pieces live: "put a yellow glowy outline around the treehouse pieces, the way you do to
show things are interactable, to make them stand out more"): every piece this player has not found carries the interact pills'
gold Highlight (outline solid, a soft fill that breathes), occluded by walls like the pill outlines. At most 12 highlights per
player, under Roblox's 31. Re-run install_treehouse1.lua in Edit (re-runnable: the old folder -> HudBackup; the per-player saves
are untouched - the pieces are on the save, not in the folder), a play-test picture of a glowing piece, publish with the next batch.

## Job 111: the treehouse moves to a clearing left of the zip line tower + the first-piece reveal (Shannon, Oct 15) - runner 7

Shannon: "the treehouse is too close to everything else and it's too crowded; put it in a corner to the left of the zip line tower;
clear a space of trees and rocks and mushrooms; an open area clearly designated for the treehouse. When they collect their first
glowy piece, a quick zoom screenshot of the spot where the treehouse will be (the sign before it is made should say 'Future Location
of ...'), hold about 8 seconds, then the camera goes back". Cloud thread: yes; six seconds suggested; the name proposed "Acorn
Heights" (or Hazel Heights / The Nutty Lookout / The Oak Hideout - hers to pick); the pick-up chime already plays (soft).
STEP 1 (read-only, no ask): tools/treehouse/survey111.lua - finds ForestTower, "left of it" as seen from the forest spawn, and for
four candidate centres (45 / 60 studs left, 15 behind, 15 nearer) reports the ground over a 24-stud radius, what a clearing would
remove (kit trees / rocks / mushrooms / bushes: the Scatter attribute or kit names) and what it must keep (squirrels, walls, the
tower, paths, anything unsure). Send every "QQ SITE" line + one picture from the spawn looking at the tower with the left side in view.
STEP 2 (cloud thread, after the lines): install_treehouse2 - clears the chosen circle (the removed props go to
HudBackup.TreehouseCleared_n, never squirrels or walls), builds the oak there with a stone-ring "site" and the sign "Future home of
<name>" until the first piece, moves p1/p2 so the first two pieces lie between the spawn and the site, and the client's first-piece
reveal: camera to the site for ~6 s with "That's where <name> will stand", then back. Pieces already found are kept (they are on the
save); the house simply stands at the new site.
Job 111 WORDS (Shannon, Oct 15): the name is "Homebase Treehouse" ("the forest is where we start and the player is traveling around
the world; they always have the homebase treehouse to come back to as theirs"); roomier inside, a balcony; decorations to buy later.
The sign before the build: "Future home of Homebase Treehouse. Please excuse the dirt." The first-piece reveal line: "A squirrel was
going to live here, but you got the first piece, so it's yours now. The squirrel won't mind." (camera on the site ~6 s, then back).
Job 111 DESIGN AGREED (Shannon, Oct 15: "the pieces should be really really easy to find; the treehouse should be an easy win ...
what if all the pieces to build the main treehouse are in the forest, then some add on items are in the next sections?" - yes):
ALL TWELVE pieces in the forest, each beside a forest squirrel (collecting pieces walks the player past the squirrels that open the
gate), glowing, tags readable from 60 studs, the sign and the pill always saying "N to go"; the house roomier with a balcony; the
site a cleared circle left of the zip line tower. ADD-ONS (the job after): found in the next sections and drawn in the player's own
treehouse - Rue de Noisette: a string of lanterns for the balcony, a window box; the chateau: a hammock, a roof telescope; Porto:
a striped awning / a potted lemon tree; plus a few in the Acorn Store (rug, flag colour, pet bed, lantern colour) for acorns or
Robux. The finished-house card and the sign name the next add-on and where it waits, with the gate count ("Ten forest squirrels
open the gate - 7 found"). Pieces already collected are kept on the saves.

Result birds v6 + treehouse r4 INSTALLED (runner 7, Shannon's yes, Studio EDIT, unpublished): birds 7111966 (21975, adler32 3433540002):
"QQ BIRDS DONE: workspace.Birds (BirdsClient 18582 chars; 7 sites ...); the old folder is HudBackup.Birds_pre_3". treehouse f73c0a0
(35050, adler32 2013708329): 12 "QQ TREE piece" lines as before (none skipped), "QQ TREE DONE: ... 12 pieces placed; TreehouseServer 4806,
TreehouseClient 20367 chars; RS.TreehousePick); the old folder is HudBackup.Treehouse_pre_1". Not yet looked at in play.

Result job 111 survey (runner 7, f385b20, Edit, read-only): survey111.lua (6029, adler32 407390585) stopped at line 82 ("Position is not a
valid member of Model Workspace.choc_v2" - the same and/or truncation as survey103: a Model with no parts fell through to m.Position);
run with that one line replaced by `local lo, hi; if not m:IsA("Model") then lo, hi = m.Position - m.Size / 2, m.Position + m.Size / 2
end`. Lines unchanged:
QQ SITE ForestTower box -31.05000114440918, -1, -2.1380996704101562..-15.75, 81.82499694824219, 12.138099670410156, centre (-23, 5); the spawn looks at it along (-0.99, 0.15); LEFT of it is (0.15, 0.99)
QQ SITE tall walls within 160 studs of the tower: Wall at (-14,25) size 233x1; Terrain at (0,0) size 2044x2044; Leg3 at (-18,10) size 1x1; Leg2 at (-18,0) size 1x1; Leg1 at (-28,0) size 1x1; Leg4 at (-28,10) size 1x1
QQ SITE A: 45 left of the tower: centre (-17, 49), 52 studs from the spawn, ground 8.8 (terrain Grass); over a 24-stud radius the ground runs y 0.0..220.0; hits: Baseplate 1, Wall 1, terrain Grass 30
QQ SITE   would clear (4): Boundary.Dressing.pine_squat (-2,24) 12x12, 29 studs out | Boundary.Dressing.pine_mid (-12,20) 8x9, 30 studs out | Boundary.Dressing.pine_mid (-26,24) 12x12, 27 studs out | Boundary.Dressing.pine_tall (-18,26) 9x9, 24 studs out
QQ SITE   must keep / unsure (0): nothing
QQ SITE B: 60 left of the tower: centre (-14, 64), 66 studs from the spawn, ground 3.3 (terrain Grass); over a 24-stud radius the ground runs y 0.0..12.1; hits: Baseplate 8, terrain Grass 24
QQ SITE   would clear (0): nothing
QQ SITE   must keep / unsure (0): nothing
QQ SITE C: 45 left, 15 behind: centre (-2, 47), 46 studs from the spawn, ground 12.1 (terrain Grass); over a 24-stud radius the ground runs y 0.3..12.1; hits: Foliage 1, terrain Grass 31
QQ SITE   would clear (6): Boundary.Dressing.pine_squat (-2,24) 12x12, 23 studs out | Boundary.Dressing.pine_tall (14,25) 9x9, 27 studs out | Boundary.Dressing.round_tree (6,26) 15x14, 23 studs out | Boundary.Dressing.pine_mid (-12,20) 8x9, 29 studs out | Boundary.Dressing.pine_tall (-18,26) 9x9, 27 studs out | Forest.stump_s69 (-7,18) 6x6, 30 studs out
QQ SITE   must keep / unsure (0): nothing
QQ SITE D: 45 left, 15 nearer the spawn: centre (-31, 52), 61 studs from the spawn, ground 9.8 (terrain Grass); over a 24-stud radius the ground runs y 0.0..13.9; hits: Baseplate 4, terrain Grass 28
QQ SITE   would clear (4): Boundary.Dressing.pine_mid (-26,24) 12x12, 29 studs out | Boundary.Dressing.pine_tall (-18,26) 9x9, 29 studs out | Boundary.Dressing.pine_mid (-34,24) 8x8, 28 studs out | Boundary.Dressing.pine_tall (-42,24) 6x6, 29 studs out
QQ SITE   must keep / unsure (0): nothing
FINDING: the "Wall at (-14,25) size 233x1" is Workspace.Boundary.Walls.Wall - the forest's INVISIBLE NORTH EDGE (Transparency 1,
CanCollide, 224 tall, x -130..102). ALL FOUR candidates (z 47..64) lie OUTSIDE it, on the rising grass bank players cannot reach; the
"would clear" trees are the Boundary.Dressing pines along that edge. Between the tower (box z to 12) and the edge (z 25) there are only
~13 studs. Ground at x -17: z 15/20 grass y 0.1, z 24/28 the edge pines, z 35 y 3.5, z 45 y 8.5, z 60 y 5.9. So "left of the tower"
as the spawn sees it is beyond the map edge: either the edge moves north (a clearing at z 35..65 on a bank that rises to ~9-12), or
the site is elsewhere. Picture tools/treehouse/shots/survey111_spawn_to_tower.jpg (spawn -> tower, the left side = the bank behind
the edge). Asking Shannon which she means.

Result job 111 - SHANNON'S ANSWER (runner 7): asked with the spawn -> tower picture ("left of the tower is outside the forest's invisible
edge, on the grassy bank"), she chose "Move the edge out" = the HILLSIDE behind the tower's left (the hollow plan), not the west
candidates; survey111 round 2 (5a198cc) not run. The bank, terrain y (read-only, Edit; x -70..30 every 10, z every 5):
z 15/20: 0.1 everywhere (inside the edge) | z 25 (the edge wall): -3.8..0.2 | z 30: -1.0..3.2 | z 35: 3.7..7.9 | z 40: 7.5..11.2 |
z 45: 9.5..13.1 | z 50: 9.7..14.1 (the crest) | z 55: 8.2..13.9 | z 60: 4.7..12.8 | z 65: -2.9..10.6 | z 70: -6.6..6.9, and none (no
terrain) at x 20..30 | z 75: mostly none | z 80+: none at all = the end of the terrain, the world's edge. So the bank is a ridge ~50
studs deep cresting at y 10-14 around z 45-55, falling away to nothing by z 75-80. On it: only Boundary.Dressing pine_mid / pine_tall
/ round_tree. The north edge is Boundary.Walls.Wall at (-14.1, 25.0), 233 x 1.2 (x -130..102); the west/south edge wall at (-130,
-95) 241 x 1.2. NOTE: workspace has TWO children named "Boundary" (a Folder with only PatchModule, and a Folder with 5 children
holding Walls + Dressing) - workspace.Boundary.Walls fails by name; find the walls by searching.

PUBLISHED v1428 (Shannon, "I have saved and I have published"): Studio log 14:19:25Z "Published new changes ... Add publish notes to
v1428" (birds v6 + treehouse r4 glow are live). Team Create connected since 13:41:01Z, no disconnect since.

Result job 106 INSTALLED (runner 7, her earlier yes "Japan map fixes" + her save/publish first; Studio EDIT, unpublished):
japan_geo1.lua at 4bdb61f (17195, adler32 3765546536), 6.5 s:
QQ GEO1 props moved: 8
QQ GEO1   MOVE Landscape.Bamboo clump down 0.19 (bamboo down onto the ground)
QQ GEO1   MOVE LanternStreet.Blue vending machine up 0.96 (vending machine up onto the platform)
QQ GEO1   MOVE TeaHills.Fishing bank down 0.55 (down onto the ground)
QQ GEO1   MOVE TeaHills.Fuji photography lookout: a stone plinth 25 x 24.5 x 18 down to the hillside
QQ GEO1   MOVE Landscape.Bamboo clump up 0.97 (bamboo up out of the ground)
QQ GEO1   MOVE Landscape.Bamboo clump down 1.07 (bamboo down onto the ground)
QQ GEO1   MOVE Landscape.Bamboo clump down 0.20 (bamboo down onto the ground)
QQ GEO1   MOVE PalaceGrounds.Raked gravel garden down 1.75 (down onto the ground)
QQ GEO1 slabs raised to stop z-fighting: 130 moves in 3 passes
QQ GEO1 underwater stair supports given the bed's sand look: 1
QQ GEO1   basin Canal refilled: x 6089..6113, z -221..101, up to y 1.30 (0 air cells became water)
QQ GEO1   basin Mountain stream refilled: x 5756..5774, z -305..85, up to y 1.10 (0 air cells became water)
QQ GEO1   basin Rice west refilled: x 5471..5521, z 62..104, up to y 2.25 (0 air cells became water)
QQ GEO1   basin Rice middle refilled: x 5531..5581, z 62..104, up to y 2.25 (0 air cells became water)
QQ GEO1   basin Rice east refilled: x 5591..5641, z 62..104, up to y 2.25 (0 air cells became water)
QQ GEO1 rectangular basins refilled from JapanWaterBasins: 5
QQ GEO1 the sea: air below y -6 across x 4750..7400, z -1500..900 is water now (5344805 cells in 110 chunks), on a sand bed (397200 cells); readback at (5000,-10,-1200): liquid 1
QQ GEO1 the wall: invisible, x 4900 and 7250, z -1350 and 621, y -70..100 (6 parts in JapanMap.Sea wall)
QQ GEO1 DONE: 8 props moved, 130 slab moves, 1 supports recoloured, 5 basins refilled, the sea and the wall; log HudBackup.JapanGeo1_log (16378 chars)
Readback "liquid 1" (full water, not 0). AFTER pictures (tools/japan/shots106/after_*.jpg): the north edge now looks out on open sea,
BUT the sea's far end shows as a straight line with a step at the horizon (the sea box ends at z 900 / x 7400 with void beyond), and a
paler rectangle shows in the near water north of the island; the Fuji lookout stands on a pale stone plinth; the vending machine
stands on the platform. UNCHANGED: the canal's north end (6101,-215) - the slab still crosses the water and the water shows the same
hard bright wall ("0 air cells became water": the box had no air to fill - the wall is the terrain water's own end face, not a gap);
the lake stair (6728,224) - the dark band under the stair is still there (likely the stair's shadow on the bed, not the support).
Undo in this Studio session: Ctrl+Z to the "before JapanGeo1" waypoint; the moves are logged in HudBackup.JapanGeo1_log.

Job 106 GEO ROUND 2 (after runner 7's run of japan_geo1 on the saved place, unpublished): the sea, the wall, 8 props and 130 slab
moves are in; the readback "liquid 1" was the full cell under the surface (the probe point is y -12..-8; the surface cell above it is
the 0.5 one) - a pass. Three faults to fix: (1) the sea's far end is a straight step at the horizon (the box ends at z 900 / x 7400)
and a paler rectangle in the near water (a depth change: Codex's basin floor vs our sand bed at -60); (2) the five basins had no air
to fill (their water already fills the manifest boxes), so the canal still ends in a bright vertical face at its north end where
the dry channel continues; (3) the lake stair's dark band is the stair's shadow on the bed, not the support. STEP 1 (read-only, no
ask): tools/japan/probe106b.lua - the bed depth over the sea on a 60-stud grid, the canal channel's bed beyond the water's end, the
lake stair's parts, anything standing at the horizon, the water colour. Send the "QQ GEO2" lines. STEP 2 (cloud thread): round 2 -
a horizon sea (flat water-coloured parts beyond the terrain to 3000 studs out, under the fog), the sand bed raised to the basin
floor's depth, the canal's water carried on along its channel or ended at a stone weir, CastShadow off on the stair.

Birds v7 (Shannon, live: "too many flying in the air ... the one flying low needs to go ... only keep the ones much higher up";
"the pelican and seagulls on the ground are all lined up in a row"): the harbour flock is three gulls at y 22 (70 over the quay,
was six at -12), the low pelican flight is gone, the lighthouse flock three at y 92; perched birds take per-bird OFFSETS (dx along
the rail, dy up, dz across, yaw) instead of a row - the rail's three gulls are now spread 7.5 and 5.5 studs apart, turned different
ways; the pelican keeps its own post. First guesses - tune the offsets in the Sites attribute in Studio until they sit on real rail /
bollards, then report the numbers. Re-run install_birds1.lua (re-runnable), picture, publish with the next batch.

Job 111 BUILD (cloud thread): tools/treehouse/install_treehouse2.lua (make_install_treehouse2.py; src/TreehouseClient2.lua; compiles;
an adversarial review is running - wait for the commit that says "homebase reviewed"): the hollow cut into the bank behind the
tower's left at (-18, 47) (a back rim built to y 9 where the ridge fell to nothing, a grass floor at 0.1, a stepped bowl of radius 27
cut to y 17, a dirt disk of radius 15), the north edge opened between x -48 and 12 with a U of the same invisible wall round the
hollow to z 70, the dressing pines on the site to HudBackup.TreehouseCleared_n, the oak taller (its trunk rises through the roof),
ten stones at the dirt's edge, the sign at the mouth ("Future home of Homebase Treehouse. Please excuse the dirt." until the deck;
then the count; then "est. today. Welcome home."), the house roomier (16 x 16 deck, a 13 x 13 room, a 16 x 8 BALCONY toward the
spawn with its railing, the ladder landing on it, an awning over the door), the first-piece reveal (the camera to the hollow for
~6 s with her line, then back), and TWELVE pieces all in the forest: p1 in sight of the spawn, p2..p12 beside eleven forest
squirrels. Pieces already collected stay on the saves. Preview in a play test (terrain and all; discarded on stop): pictures of
the hollow from the spawn, from the tower top, the sign, the reveal, the house at 3 / 7 / 12, the balcony; then install on her word.

Shannon on the job 106 result (pictures sent): "changes are fine please proceed" - japan_geo1 KEPT in Edit (not undone), to go out with
her next publish. Round 2 items (sea far-edge step, canal north end, lake band) still welcome from the cloud thread.
Job 111 HOMEBASE REVIEWED (cloud thread; the adversarial review's fixes applied): the flag moved to the balcony's front corner post
(it stood inside a leaf ball), the bowl cut as an amphitheatre (widening with height, not an overhang), the rim's ends rounded, the
U's back wall a stud inside the floor's face (no invisible wall in open air), the deck's side rails continuous at the railing
stage, the stilts' feet on the ground, the stone ring's gap at the mouth, the edge search re-run safe, the reveal toast tall enough
for her line. Preview per the "Job 111 BUILD" paragraph from THIS commit; the runner will see four 4-stud terraces in the bowl's
walls and the rim's slab from the tower top - say if they look wrong by eye.

Result PUBLISH v1429 (Shannon, Alt+P, ~14:27:53Z Oct 15): out with it - treehouse r4 glow (the old oak (-4,-30), 12 pieces),
japan_geo1, ChampionServer 36212 (armfix1 + acornhand1), HallServer 6204 / HallClient 4377 (hallretry1), BuyHere, Passes (600 /
2500 acorns), golden_gate2, japan_fix1. NOT in it: birds v7 and the four perches (below), Homebase (preview only).

Result BIRDS v7 INSTALLED + PERCHES (runner 7, Shannon's "Yes, install", Studio EDIT, unpublished): install_birds1.lua at c5bdc28
(22237, adler32 1722286785), BirdsClient 18905 chars, the old folder HudBackup.Birds_pre_4. Then her own spots ("the pelican should be
perched in the edge of one of the boats, and the 3 gull should be more spread out. one maybe perched on the rescue boat on the beach,
one down by the tide pools where the crabs are and one at the current location") set in workspace.Birds Sites, one site per bird:
  Pelican on Rosina        x 211.04  y -51.26  z -628.0   yaw -90   height 2.6  range 220
  Gull on the quay         x 231.6   y -46.56  z -673.4   yaw 102   height 1.4  range 220
  Gull on the rescue boat  x 253.27  y -46.28  z -710.97  yaw -148  height 1.4  range 220
  Gull at the tide pools   x 300.0   y -51.76  z -800.0   yaw -45   height 1.4  range 220
(lighthouse pair unchanged, height 1.4; flocks as v7). Play test: the four built (pelican box 1.4 x 2.6 x 2.8, each gull 0.9 x 1.4 x
1.9). By eye: the pelican sits on Rosina's bow beside the fisher squirrel, about two thirds of his height, on the boat's edge; the gull
on the red rescue boat's bow rim next to the lifeguard chair; the tide-pool gull on the sand between the two pools beside the crab
squirrel. Pictures tools/birds/shots/v7_*.jpg. Waits for her publish.

Result job 111 PREVIEW (runner 7, play test, nothing kept): install_treehouse2.lua at 1bade88 (41445, adler32 1124487011) on the
test server: "QQ TREE terrain: rim to y 9 behind z 62..84, floor at 0.1, a bowl of radius 27 cut to y 17, dirt radius 15, centred
(-18, 47)", "QQ TREE edge: the north wall opens between x -48 and 12; a U of wall round the hollow to z 73", "QQ TREE dressing
cleared from the site: 5 (HudBackup.TreehouseCleared_1)", p1..p12 piece lines (none skipped), "QQ TREE DONE: Homebase Treehouse at
(-18, 0.1, 47) yaw 155.5 in its hollow; 12 pieces placed; TreehouseServer 4806, TreehouseClient 22722 chars; the old folder is
HudBackup.Treehouse_pre_2". Pictures tools/treehouse/shots/hb1..hb10. What I saw:
 1. FLOOR is y 2.0, not 0.1 (terrain read over x -30..-10, z 30..60). The oak's roots (y 0.7, 1.8 thick, top 1.6) are under it -
    no roots show.
 2. THE MOUTH: a grass lip y 4.4 - 5.3 across z 20..25 (it was 0.1 at z 20 before). From the forest the hollow does not read as an
    opening - you see a hump with the trunk behind it - and the sign (board y 2.4..5.2 at (-2.3, 34.4)) is hidden behind the lip, only
    its top edge shows (hb3). The mouth needs cutting down to the floor's height.
 3. FROM THE TOWER TOP (hb2): the four terraces do not show at all - the bowl reads as a smooth dent round the oak; the back rim reads
    as a flat-topped slab with straight edges and square corners behind the tree (looks built, not natural).
 4. THE REVEAL: both messages show and fit ("A squirrel was going to live here, but you got the first piece, so it's yours now. The
    squirrel won't mind." then "Homebase piece 1 of 12! 11 more to find", hb4/hb5); the camera move itself cannot be pictured
    (screen_capture sets its own camera) and plays once per session.
 5. THE HOUSE: 3 pieces = deck, stilts, ladder (hb6); 7 = room walls and railings (hb7); 12 = roof with awning, lit lantern, window,
    flag on the balcony corner (hb8, hb9) - all clean, nothing floating. INSIDE (hb10): the trunk (TrunkHigh 4.8 across) stands in
    the middle of the room about 6 studs in from the door, so from outside the doorway is filled by the trunk (hb8) and inside it
    blocks the view; the room is empty otherwise.
Waits for the cloud's round 2 (the floor, the mouth lip, the terraces / rim) and her word to install.
Job 111 ROUND 2 (cloud thread, from runner 7's preview hb1..hb10): the floor and the dirt are filled on whole 4-stud voxel rows
(floor y 0; a part-filled row had rendered 2 studs high and buried the roots); the mouth is cut flat (air x -44..8, y 0..12, z
16..32: the lip that hid the sign is gone); the back rim is a bank of eight overlapping mounds along z 74 on a plug below (no more
slab with square corners); the bowl's steps start at radius 27 and widen; the HOUSE sits 4 studs forward of the trunk (the trunk at
the back of the room, the doorway clear - the sign, ladder and balcony move with it; the stone ring's gap still clears the balcony).
Preview again from this commit (same pictures, plus one through the doorway from the balcony); then install on her word.

Job 106 GEO ROUND 2 installer (cloud thread, from probe106b): tools/japan/japan_geo2.lua (compiles; Edit; after geo1; Ctrl+Z to
"before JapanGeo2"): (1) the paler rectangle was a DEPTH step - Codex's basin bed is -26..-35, ours -58: every deep water cell below
y -30 in the fill box becomes sand, one bed; (2) the sea carried on to z 1300 and x 7800 (the north shore is at z ~450, so the edge
is 850 studs out, in the fog - FogEnd 1100) and three flat water-coloured parts beyond it to 3000 studs, so no edge shows;
(3) the canal's bright end face: a stone WEIR across the canal at z -221..-224 (the water ends against stone; the dry foundation
beyond stays dry); (4) CastShadow off on the lake stair's treads and supports. SAVE first, run, then pictures: north from the shore,
the canal's north end from the bridge, the lake stair. Expect "QQ GEO2 DONE".

Result BIRDS bench gull (runner 7, Shannon: "the gull on the rescue boat is wrong; put it perched on the back of the bench facing away
from the water instead", Studio EDIT, unpublished): in workspace.Birds Sites the "Gull on the rescue boat" became "Gull on the bench":
x 247.85, y -44.85 (the top of the Harbour bench's back slat, PortoNocciola."06 Piazza details and planting"."Harbour bench"), z -711,
yaw -90 (faces +X: the bench seat and the water are to -X), height 1.4, range 220. Old Sites string in
ServerStorage.HudBackup.BirdsSites_pre_bench. Play test: built, feet at -44.85, look (1,0,0); picture tools/birds/shots/
v7_gull_on_bench.jpg (on the back rail, the water behind it).

Result job 111 ROUND 2 PREVIEW (runner 7, play test, nothing kept): install_treehouse2.lua at 7a9aa6e (42201, adler32 438641579):
"QQ TREE terrain: a mound bank along z 74, floor at y 0 (whole voxel rows), a bowl of radius 27..33 cut to y 16, the mouth cut flat z
16..32, dirt radius 15, centred (-18, 47)", "QQ TREE edge: the north wall opens between x -48 and 12; a U of wall round the hollow to z
73", "QQ TREE dressing cleared from the site: 5 (HudBackup.TreehouseCleared_1)", p1..p12 piece lines (none skipped), "QQ TREE DONE:
Homebase Treehouse at (-18, 0.0, 47) yaw 155.5 in its hollow; 12 pieces placed; TreehouseServer 4806, TreehouseClient 22929 chars; the
old folder is HudBackup.Treehouse_pre_2". Pictures tools/treehouse/shots/r2_hb*.jpg.
 FLOOR AT THE OAK: y 2.0 still (raycast at (-24,47) (-12,47) (-18,41) (-18,53) all 2.00; the whole floor x -32..-4, z 32..64 is 2.0).
    WHY: ReadVoxels in the hollow = row -8..-4 full, row -4..0 FULL (occupancy 1.00), row 0..4 air - and Roblox draws a full row's
    surface 2 studs above the row's top: a full -4..0 row = a surface at y 2.0. The forest next door is the same row at occupancy 0.52 ->
    surface 0.1 (-2 + 4 x occupancy). So for a floor level with the forest write the -4..0 row at occupancy ~0.52 (WriteVoxels), not a
    full row. The roots (top 1.45) are still under it.
 MOUTH: fixed - no lip; the ground ramps 0.1 (z 16) -> 2.0 (z 28) into the floor. From the spawn the oak, the dirt and the sign show
    (r2_hb1, r2_hb3). The sign's own POST pokes up in front of the bottom line: "0 of 12 pi_es found" - the post hides the "ec" (r2_hb3,
    and again in r2_hb4).
 TOWER TOP (r2_hb2): the back rim now reads as soft rounded mounds - good, no slab. The bowl's terraces still do not show as steps
    from up there (a smooth dent round the oak).
 REVEAL (r2_hb4): caught this time (screen_capture with no camera, 1 s after the pick): the camera looks down into the hollow - oak,
    dirt, the ladder, the sign - with her line in the toast. A pine stands at the right edge of that view and a leaf crown at the
    left, both in the foreground; the hollow itself is clear.
 HOUSE: 3 / 7 / 12 clean (r2_hb6..8), the trunk now at the back edge of the deck; the flag on the balcony corner (r2_hb9). THROUGH
    THE DOORWAY from the balcony (r2_hb11): the room's floor and the trunk standing against the back wall, door clear. INSIDE
    (r2_hb10): the trunk at the back, 8 studs of open floor in front of it; the room is empty (no furniture).
Waits for her word to install (the floor occupancy and the sign post are the two things left).

Result job 111 ROUND 2 INSTALLED (runner 7, Shannon: "install now, and make fixes when cloud fixed them", Studio EDIT, unpublished):
install_treehouse2.lua at 7a9aa6e (42201, adler32 438641579) - the same QQ lines as the round 2 preview, word for word ("QQ TREE DONE:
Homebase Treehouse at (-18, 0.0, 47) yaw 155.5 in its hollow; 12 pieces placed; TreehouseServer 4806, TreehouseClient 22929 chars; the
old folder is HudBackup.Treehouse_pre_2"; dressing in HudBackup.TreehouseCleared_1). Readback: ground at (-24,47) y 2.00 Ground,
(-18,24) 1.92 Grass, (-18,12) 0.06 Grass. NEXT: she wants the floor (occupancy ~0.52 in the -4..0 row) and the sign post fixed as a
PATCH on top of this installed version - please make it re-runnable against the installed Homebase, not a fresh install.
Job 111 ROUND 3 (cloud thread; CORRECTION of the cd56cb2 note, which claimed client edits a failed anchor had left out). Runner 7
installed round 2 (7a9aa6e) in Edit on Shannon's word ("install now, and make fixes when cloud fixed them"), floor still y 2.0, and
asked for round 3 as a PATCH over it, not a fresh install. tools/treehouse/patch_treehouse2_r3.lua (make_patch_treehouse2_r3.py):
 1. FLOOR: the hollow's top voxel row (y -4..0, bowl radius 31 + the mouth x +-26 z 16..32) set to the forest's occupancy 0.52 wherever
    it is fuller (ReadVoxelChannels / WriteVoxelChannels SolidOccupancy) -> surface y ~0.1, the roots show. Readback lines at the oak,
    the mouth, left and right: "QQ TREE3 readback <where>: occupancy 0.52 Grass -> surface y ~0.1".
 2. CLIENT (TreehouseClient2.lua round 3): the sign's post at L(-9, 1.5, 17.6), behind the board (its back is at 17.85), so it never
    crosses the bottom text line; furniture - with the walls a table (x 2.4..5.6, z -4.8..-2.8, clear of the trunk's 2.4 radius at
    z -4), two stools and a mug; with the window a shelf under it (x -6.3..-5.3) with a potted plant; with the flag a round rug
    (a cylinder stood on end, 5 wide) mid-room and a gold cushion by the window. All looks-only (no collide, no query).
    The installed TreehouseClient is disabled, cloned to HudBackup.TreehouseClient_pre_r3_n, destroyed, and a fresh Script (RunContext
    Client) carries the new source; the new client clears the old Treehouse_local and TreehouseGui itself, so in play it restarts clean.
 Needs workspace.Treehouse (aborts otherwise); re-runnable (a second run finds the client already round 3). Waypoints before/after.
 install_treehouse2.lua is regenerated from the same client (44986 bytes) for a future fresh install only.
Preview in play from this commit (the floor y at the oak ~0.1 and the readback lines, the sign's bottom line, the room furnished),
then install in Edit on her word; geo2 (323dd1f) after that; then she publishes.

Result job 111 ROUND 3 PATCH PREVIEW (runner 7, play test over the installed round 2, nothing kept): patch_treehouse2_r3.lua at a9c0448
(29239, adler32 1316508335): "QQ TREE3 floor: the top voxel row set to 0.52 over 175 of 202 cells in the hollow (surface y ~0.1)",
"QQ TREE3 readback the oak: occupancy 0.52 Enum.Material.Ground -> surface y ~0.1", "... the mouth: occupancy 0.52
Enum.Material.Grass -> surface y ~0.1", "... the left: ... Grass -> surface y ~0.1", "... the right: ... Grass -> surface y ~0.1",
"QQ TREE3 client: TreehouseClient replaced, 24562 chars; the round-2 copy is HudBackup.TreehouseClient_pre_r3_1", "QQ TREE3 DONE: the
floor's top row at 0.52 round (-18, 47); the sign's post behind the board; the room furnished".
 FLOOR: raycast 0.1 at the oak's four sides and over the whole hollow x -32..-4, z 12..60 and the mouth (the bowl walls unchanged);
    the roots (top 1.45) stand out of the dirt (r3_roots_at_the_oak). One Treehouse_local and one TreehouseGui after the client swap.
 SIGN: "0 of 12 pieces found." whole, the post below the board (r3_sign_bottom_line_whole).
 ROOM at 7 (no roof yet, r3_room_at_7) and 12 (r3_room_at_12_*): table 3.2 x 2.0 top at 11.8 (1.35 above the floor), two stools
    (seats 0.9 up), a mug, all in the back-left corner beside the trunk - the table's inner legs 0.3 from the trunk, its top all but
    touching it; the shelf with a potted plant on the right wall; a round red rug; a gold cushion. By eye: the furniture is small
    for a full-size avatar (the table reaches the knee); the mug is a plain red cube. The WINDOW is only on the outside: the right
    wall is one solid 13 x 6.5 part with the glass on its outer face, so inside there is no window above the shelf (same in round 2).
Not installed: the furniture is new (her "make fixes when cloud fixed them" covered the floor and the sign) - asking her first.

Result job 111 ROUND 3 PATCH INSTALLED (runner 7, Shannon chose "Install it all" after the preview pictures - furniture as it is;
Studio EDIT, unpublished): patch_treehouse2_r3.lua at a9c0448 (29239, adler32 1316508335) - the same QQ TREE3 lines as the preview, word
for word, through "QQ TREE3 DONE: the floor's top row at 0.52 round (-18, 47); the sign's post behind the board; the room furnished".
Readback: one TreehouseClient (Script, RunContext Client, enabled, 24562 chars), HudBackup.TreehouseClient_pre_r3_1 there; ground
(-24,47) 0.06 Ground, (-12,47) 0.06 Ground, (-18,24) 0.06 Grass, (-30,40) 0.06 Grass. Open by-eye notes (small furniture, cube mug,
outside-only window) stay for a later round if she asks.
Result job 111 round 3 (runner 7, a9c0448, preview then INSTALLED in Edit on Shannon's "Install it all", unpublished; logged at
c88cabe / e0f70f0 on claude/epic-hawking-188q4l, pictures r3_*): all QQ TREE3 lines as expected; the floor 0.1 across the hollow and
the mouth (readback 0.06), the roots show; the sign line "0 of 12 pieces found." whole; one TreehouseClient (24562 chars), one
Treehouse_local, one TreehouseGui; HudBackup.TreehouseClient_pre_r3_1 kept. By eye: the furniture knee-high for an avatar (table top
1.35 above the floor), the mug a plain red cube, the table top almost touching the trunk, and the window only on the outside - the
window wall one solid part (round 2 carried that).
Job 111 ROUND 3b (cloud thread): the SAME patch_treehouse2_r3.lua, client only (its floor pass finds nothing fuller than 0.52 now),
re-run over round 3: the round-3 client goes to HudBackup.TreehouseClient_pre_r3_2. The client: the window wall is four parts round a
2.8 x 2.8 hole (y 12.7..15.5) once the window stage comes (solid before), the frame 0.5 thick at the wall's centre so it shows both
sides, the pane in the hole; the table top 2.6 above the floor (an R15 avatar is ~5), the stools' seats 1.6, half a stud clear of the
trunk; the mug a cream cylinder with a handle; the shelf's top at the sill; the rug 6 wide, the cushion 1.8. Optional - Shannon took
the furniture as it was; preview and offer.

Result job 111 ROUND 3b PREVIEW (runner 7, play test over the installed round 3, nothing kept): patch_treehouse2_r3.lua at 608aca5
(30455, adler32 1153411002): "QQ TREE3 floor: the top voxel row set to 0.52 over 0 of 202 cells in the hollow (surface y ~0.1)", the four
readback lines as before, "QQ TREE3 client: TreehouseClient replaced, 25778 chars; the round-2 copy is HudBackup.TreehouseClient_pre_r3_2",
"QQ TREE3 DONE: ...". One Treehouse_local. Table top 13.2 (2.75 above the floor), stools' seats 12.2 (1.75), the cream mug with a handle
on the table; at 12 the window wall is four parts round the hole, the glass (T 0.3) and frame - the window SHOWS from inside with the
view out, the potted plant on the sill shelf, the gold cushion and the red rug (r3b_window_from_inside, r3b_room_at_7_table,
r3b_room_at_12_table). Asking her whether to install (optional).
Result job 111 round 3b PREVIEW (runner 7, 608aca5, play test, nothing kept; logged at ce3c466 on claude/epic-hawking-188q4l, pictures
r3b_*): the floor pass changed 0 of 202 cells; the client replaced (25778 chars, the round-3 one saved as
HudBackup.TreehouseClient_pre_r3_2 in the preview); the table top 2.75 above the floor, the seats 1.75, the cream mug with its handle;
at 12 pieces the window shows from inside with the view out, the plant on the sill. Shannon has the pictures; install waits on her word.

Result job 111 ROUND 3b INSTALLED (runner 7, Shannon: "Install the update" after the r3b pictures, Studio EDIT, unpublished):
patch_treehouse2_r3.lua at 608aca5 (30455, adler32 1153411002) - the same QQ TREE3 lines as the 3b preview ("... over 0 of 202 cells",
"QQ TREE3 client: TreehouseClient replaced, 25778 chars; the round-2 copy is HudBackup.TreehouseClient_pre_r3_2", "QQ TREE3 DONE").
Readback: one TreehouseClient, 25778 chars; HudBackup.TreehouseClient_pre_r3_2 there. Next: japan_geo2 on her yes + a save; then she
publishes.
Result job 111 round 3b (runner 7, 608aca5, INSTALLED in Edit on Shannon's "Install the update", unpublished; logged at 8dd6298):
QQ lines as in the preview; one TreehouseClient (25778 chars); HudBackup.TreehouseClient_pre_r3_2 kept. Homebase Treehouse is done
through round 3b. Next: japan_geo2.lua (323dd1f) on her yes and a save; then publish.
Job 106 geo2 FIX (cloud thread, from runner 7's read before running): raiseBed's region top was y BED = -30, off the 4-stud grid -
ReadVoxelChannels would have thrown on the first chunk, right after the "before JapanGeo2" waypoint, before any change. Now
math.floor(BED / 4) * 4 = -32: a full row up to -32 draws its surface at -30, which is BED, and the sand band fillAir writes for the
new areas (level BED) draw at -30 too. Nothing else changed.

Result JAPAN GEO2 INSTALLED (runner 7, Studio EDIT, unpublished; Shannon confirmed in this session "Published and saved, go" after her
publish of Homebase r3b + birds v7): japan_geo2.lua at bee201f (8615, adler32 2093036727; the only change from 323dd1f is raiseBed's gy2
= -32). My "off the grid throws" call was WRONG: a read-only ReadVoxelChannels probe with top -30 did NOT error (it returned 9 rows, the
region widened to -28); the -32 still matters - with -30 the -32..-28 row would have turned to sand too (bed drawn at -26, not -30).
Output, 7.6 s: "QQ GEO2 the bed: 2749626 deep water cells below y -30 became sand (one depth with Codex's basin, bed -26..-35)", "QQ GEO2
more sea: north band z 900..1300 and east band x 7400..7800 - 272600 sand cells, 817800 water cells", "QQ GEO2 the horizon: three flat
sea parts (colour 0.203922, 0.407843, 0.305882) to x 9400 and z -2800..2800, 0.4 under the water's surface", "QQ GEO2 the canal's north
end: a stone weir across x 6086..6116 at z -221..-224 (top y 2.0, the water at 1.3 ends against it)", "QQ GEO2 lake stair: CastShadow
off on 54 parts" (32 "Lake swim exit tread" + 22 "Promenade approach tread" + 1 support - not three), "QQ GEO2 DONE: ...".
Play test (avatar teleported to the north shore (6100, 0, 465): Area "japan", the client's water (24,112,151) blue, client FOG
99999..100000 = NO FOG in Japan, atmosphere 0.08 / haze 0; server fog 350..1100 but the client's is what shows). Pictures
tools/japan/shots_geo2/:
 HORIZON - NOT FIXED: (a) the parts are painted Edit's WaterColor (52,104,78) green, but in Japan JapanWaterAppearance paints the
    terrain water (24,112,151) - from 60 up a duller grey-green band sits on the horizon above the blue (geo2_horizon_from_60_up);
    (b) STREAMING: only 2 of the 7 horizon parts were on the client (the two north ones, (5512/7038, -6.9, 2040)); from 90 up over
    the shore the sea ends in a stepped silhouette against the sky - the streamed terrain water's edge, with the north parts making
    a raised middle step (geo2_sea_edge_from_90_up). From the shore at eye height it reads as a thin line (geo2_shore_out_to_sea);
    east from x 7200 the horizon is clean (geo2_east_from_x7200). And there is no fog to hide anything (FogEnd 100000 on the client).
    Suggest: the horizon parts in a Model with ModelStreamingMode Persistent, coloured (24,112,151) (or set by the client to the
    terrain's WaterColor while in Japan), and a ring that starts nearer the island so the streamed terrain edge never shows.
 BED: the near water reads one even blue from above, no paler rectangle (geo2_sea_edge_from_90_up, foreground).
 CANAL WEIR: from the north the canal ends against a grey stone weir with its row of capstones, grass beyond - reads like a canal's
    end (geo2_canal_weir_from_north); from the south it sits under the bridge (geo2_canal_weir_under_bridge). Raycast: water 1.30 to
    z -210, the bridge deck at -218, weir lip 2.60 at -221, weir 2.00 at -224, then "Continuous shallow river exit" (Plastic) y 0.30
    at -228 and grass. A small sliver of blue shows at the weir's west foot.
 LAKE STAIR: no dark band - the water under the treads is clean blue; the treads above water are dark wood (geo2_lake_stair).
Asked her to save; publish is hers.
## Job 106 round 3: the Japan horizon, for real (Studio EDIT; ask Shannon first) - runner 7
tools/japan/japan_geo3.lua (6169 bytes, compiles; needs geo2 in). From runner 7's geo2 play check: the horizon parts were Edit's green
(52,104,78) against the client's Japan blue (24,112,151), only 2 of 7 streamed, and Japan's client fog is 99999..100000, so from 90
up the streamed terrain sea ended in a stepped silhouette on the sky.
 1. HORIZON: the old "Horizon sea" folder (under JapanMap or workspace) goes; a MODEL "Horizon sea" directly under workspace with
    ModelStreamingMode Persistent (all its parts on every client, always), planes 1 stud thick at y -6.9 from the ISLAND'S box
    (x 5150..7150, z -1300..500) outward to x 4000..13000, z -6000..6000 (tiled under 2048: ~30 parts; the west edge 4000 keeps them
    3000+ studs from Porto under France's fog), under the terrain sea where it is streamed and carrying on where it is not. Painted
    (24,112,151), and HorizonSeaClient (RunContext Client, in the model) repaints them the terrain's live WaterColor on start and on
    change - Japan's blue in Japan, France's green anywhere else. Locked, no collide/query/touch, no shadows.
 2. WEIR: "Weir" and "Weir lip" widened to 34 (x 6084..6118), into the canal's walls, over the blue sliver at the west foot.
 Log HudBackup.JapanGeo3_log; waypoints before/after; "QQ GEO3" lines, "QQ GEO3 DONE".
Play check after: from the north shore at eye height and from 90 up (the old stepped silhouette spot) - one blue sea to the sky, no
step, no green band; the west view from the island's west shore; the weir's west foot; and from France - the Porto lighthouse top or
the harbour looking east - that nothing new shows on the horizon (the model is on every client). Pictures; send the QQ GEO3 lines.

Result JAPAN GEO3 INSTALLED + PLAY CHECK (runner 7, Shannon "Yes, run it" in this session, Studio EDIT, unpublished): japan_geo3.lua at
b770974 (6169, adler32 3875565686): "QQ GEO3 the horizon: 7 old parts removed; workspace['Horizon sea'] (Model, Persistent) with 34
planes at y -6.9 round the island's box x 5150..7150 z -1300..500, out to x 4000..13000 z -6000..6000, colour (24,112,151) +
HorizonSeaClient (573 chars) painting the live WaterColor", "QQ GEO3 the weir: 2 parts widened to 34 (x 6084..6118), into the canal's
walls, over the sliver at the west foot", "QQ GEO3 DONE: ...". Readback: Model, Persistent, 35 children, no old folder in JapanMap.
Pictures tools/japan/shots_geo3/ (force-added). Also: Oct 15's pictures had never pushed - .gitignore has *.jpg; all force-added in
2c4916c (shots_geo2 included).
 STREAMING + COLOUR: fixed - all 34 planes on the client, painted (24,112,151) = the client's water in Japan.
 BUT HIDDEN: 19 of the 34 had LocalTransparencyModifier 1 on the client - every plane with z > -1300 (the north row and the west/east
    strips); the 15 south planes showed. CAUSE: HideFranceFromPorto (hides z > -540 while you are in Porto) and HidePortoFromFrance
    (hides z < -560 while in France) both skip ONLY JapanMap descendants, and with JAPANFIX1 their state freezes when x > 4500 - so in
    Japan you keep whichever side you came from hidden. The test player spawned in Porto, so the north planes were hidden. geo2's
    folder was inside JapanMap -> skipped -> shown; geo3 moved the model to workspace -> hidden. Arriving from France (the balloon)
    hides the SOUTH planes instead. FIX: parent the Model under workspace.JapanMap (a Persistent Model may sit inside it; it also falls
    under JapanPreviewVisibility like the rest of Japan), or add workspace["Horizon sea"] to both scripts' skip roots.
 From 90 up over the north shore with the north planes hidden: the same stepped silhouette as geo2 (geo3_sea_from_90_up_planes_hidden).
    The stepped edge is the streamed TERRAIN water ending ~400-500 studs out (measured from the picture's angles). Atmosphere test on
    the client (density 0.3, haze 1.5): the edge stays crisp, the sky turns grey (geo3_test_haze_*) - haze is not the answer.
 With ALL planes forced shown on the test client (LTM 0): the sea carries on far past the old step, to a soft far edge about 1100
    studs out (seems to be the draw distance at Studio's Automatic quality), BUT the old stepped terrain edge still shows as a COLOUR
    step - the textured terrain water is a deeper blue than the flat planes 0.9 under it (geo3_test_all_planes_shown_90_up); a thin
    dark diagonal line also crosses the far planes (a tile seam?). Looking WEST from the west ridge (5250, 20, -400): a hard straight
    dark line where the terrain water stops (x 4750) and the paler, untextured planes begin (geo3_west_shore_looking_west).
    Suggest: planes a touch darker / deeper so they match the terrain water's look, and/or the terrain sea carried farther so the
    junction sits near the draw distance.
 From the shore at eye height (planes hidden as above): one blue sea with a thin straight horizon line (geo3_shore_eye_height).
 WEIR: x 6084..6118 into the stone bank; no blue sliver at the west foot (geo3_weir_west_foot). From the north-west the canal's last
    few studs of terrain water behind the weir read as a flat bright sheet (shallow water over sand -0.2..-1.5, surface 1.3).
 PORTO (harbour, then the lighthouse looking east; client fog 350..1100, Atmosphere density 0.30): an ordinary sea to the horizon,
    nothing new (geo3_porto_looking_east).
Waiting: the cloud's next round (the Model into JapanMap first); geo3 stays in Edit unless Shannon wants it undone.
Result JAPAN GEO3 (runner 7, b770974, installed in Edit, unpublished; logged at 06a542b, pictures tools/japan/shots_geo3/ - the
Oct 15 pictures were missing because .gitignore excludes *.jpg; force-added at 2c4916c with shots_geo2): all 34 planes reach the
client, coloured (24,112,151). BUT 19 of 34 have LocalTransparencyModifier 1: HideFranceFromPorto (hides z > -540) and
HidePortoFromFrance (hides z < -560) skip ONLY JapanMap descendants, and with JAPANFIX1 their state freezes past x 4500 - so whichever
side you came from stays hidden (from Porto: the north planes). geo2's folder sat inside JapanMap and was skipped; geo3 moved it out.
With all planes forced visible the sea runs on to a soft far edge ~1100 out, but the terrain water is a deeper blue than the flat
planes (a COLOUR step at the streamed terrain's edge ~400-500 out), a thin dark diagonal seam crosses the far planes, and looking
west from (5250,20,-400) a hard dark line at x 4750 where the terrain water stops. Haze (Atmosphere 0.3 / 1.5) did not hide it.
Weir: no sliver; the last studs of shallow canal water behind it read as a flat bright sheet. Porto looking east: nothing new.
## Job 106 round 4: the horizon under JapanMap, shaded and tunable, the tiles edge to edge (Studio EDIT; ask Shannon first) - runner 7
tools/japan/japan_geo4.lua (compiles; needs geo3 in). Rebuilds "Horizon sea" as a Persistent Model UNDER workspace.JapanMap (the hide
scripts skip it); 34 planes edge to edge (no 0.5 overlaps), alternate tiles 0.05 lower so no coplanar faces overlap (the diagonal
seam); Reflectance 0 and the colour x 0.8 (the bare planes read paler than the textured water); the model's attributes Shade (0.8) and
Reflectance (0) are applied by HorizonSeaClient on start and on any change of them or of Terrain.WaterColor - so the runner can TUNE
them live in play (Explorer: JapanMap > Horizon sea > Attributes) until the far planes match the terrain water at the streamed edge,
then set the found values on the model in Edit (they replicate). "QQ GEO4" lines. Check: from Porto's side AND the balloon side
nothing hidden (34 of 34 with LocalTransparencyModifier 0); the colour step from 90 up and the west line at x 4750 softened; no seam.
## Job 112 (queued, waiting on her position): MOVE the Homebase Treehouse + a bigger room with no trunk inside
Shannon (Oct 15, after round 3b): "I still do not like the location of the treehouse. I want it where my player is standing now in
the live game. you will have to remove some trees to put it there." and "the inside area needs to be bigger and maybe remove the
tree trunk going through the middle on the inside, it just takes up too much room."
Plan: she opens Studio, presses Play, walks to the spot, says "I'm there"; runner 7 reads HumanoidRootPart position + ground + every
model/part within 30 studs + a picture from above. Then make_install_treehouse3.py: SITE = her spot; clear trees/rocks/mushrooms in
a ~24 radius to HudBackup.TreehouseCleared_n; level a disk of ground at the forest's row (occupancy 0.52); the oak as a great stump:
the trunk ends UNDER the deck (no trunk in the room), branches out from below the deck, the leaf crown round and above the roof;
deck ~22 x 22, balcony 22 x 8, room ~19 inside, door/window/lantern/flag/furniture out with the walls, the middle open floor; the
sign and the reveal follow the site (TREE attribute). The old hollow: the dressing pines back from HudBackup.TreehouseCleared_n, the
wall U removed (HollowWallBack etc.) and the north edge wall restored, the dell left grassy (not refilled unless she asks). Pieces stay.
Job 112 SITE (runner 7, read-only in Play, Oct 15): her character at (-107.38, 3.29, 4.40), Area forest, facing ~ -X; terrain Grass
y 0.06, flat (0.06 at radius 12; dips to -0.32 at 24 toward the west); the forest's north-west corner: the north edge wall at z 25
(x -130..-47), the west at x -130. Within 26: pine_squat_s17, pine_mid_s16, mushrooms_s11/s12/s25, pine_squat_s20, pine_mid_s10,
round_tree_s21, bush_big_s9 (all Forest) - cleared; Boundary.Dressing trees along z 23-25 / x -130 - kept (backdrop);
Workspace.Acorns.Acorn at (-95.6, 8.1) - kept (lands under the balcony's inner edge, still reachable); no squirrels within 60.
BUILD: tools/treehouse/install_treehouse3.lua (make_install_treehouse3.py, 46305 bytes, compiles): SITE (-107, 4) floor 0.06, yaw 91.6
(local +z = east, toward the spawn): the deck x -118..-88 z -7..15, the balcony and ladder (-87, 3) on the east, the sign (-85, 15),
the trunk (-120.5, 4.4) on the west (radius 3.6, 6 from the west wall), the crown to x -137 (past the wall, among the dressing).
Preview in play from this commit, then install on her word.

Result job 112 (runner 7): Shannon's spot read in her Play session: CozyGameMode root (-107.38, 3.29, 4.40), terrain Grass 0.06, flat
(0.06 at r12; -0.05..-0.32 west/north-west at r24); north wall z 25 (20 studs), west wall x -130 (22 studs). PREVIEW of 723a34a in her
own live Play session ("I JUST WANT IT WHERE A AM CURRENTLY STANDING"): built; clearing by pivot missed pine_squat_s20 (inside the
deck, through the roof corner), round_tree_s21, mushrooms_s11/s12/s25. INSTALLED in Edit from fc531ed (46863, adler32 278897978) after
she stopped Play: "QQ TREE old hollow: 5 dressing models back from HudBackup.TreehouseCleared_1", "QQ TREE old hollow: the U of wall
removed (3 parts); the north edge re-joined x -130..102", "QQ TREE old hollow: the dirt re-grassed round (-18, 47)", "QQ TREE cleared
from the site: 9 (HudBackup.TreehouseCleared_2, each with a ClearedFrom attribute)" = pine_mid_s10, mushrooms_s11, bush_big_s9,
mushrooms_s25, pine_mid_s16, pine_squat_s17, round_tree_s21, pine_squat_s20, mushrooms_s12; "left standing": 8 Boundary.Dressing
trees, 5 DomaineKit templates (stored ~100 under ground, 0 visible parts - harmless), Baseplate; p1..p12; "QQ TREE DONE: Homebase
Treehouse at (-107, 0.1, 4) yaw 91.6, the trunk behind the house; 12 pieces placed; TreehouseServer 4806, TreehouseClient 25951
chars; the old folder is HudBackup.Treehouse_pre_3". Treehouse Tree attr {x -107, z 4, y 0.06, yaw 91.6}. Unpublished; asked her to save.
Result job 112 (runner 7, fc531ed, INSTALLED in Edit, unpublished; logged at 537d4e4). Preview 723a34a in her own Play session first
(she saw it live; "I JUST WANT IT WHERE A AM CURRENTLY STANDING"): a pine stood inside the deck and poked through the roof - the
clearing went by pivot, and some Forest models' pivots sit far from their geometry -> fc531ed clears by bounding box (centre within
26 or nearest point within 18). Install: old hollow - 5 pines back from TreehouseCleared_1, the U removed (3), the north edge re-joined
x -130..102, the dirt re-grassed at (-18, 47); cleared from the site 9 (HudBackup.TreehouseCleared_2: pine_mid_s10, mushrooms_s11/
s12/s25, bush_big_s9, pine_mid_s16, pine_squat_s17, round_tree_s21, pine_squat_s20); left standing: 8 Boundary.Dressing edge trees
and 5 DomaineKit templates (stored ~100 below ground, 0 visible parts - harmless); 12 pieces; DONE at (-107, 0.1, 4) yaw 91.6; old
folder HudBackup.Treehouse_pre_3. Homebase Treehouse now stands in the forest's north-west corner. Next: geo4.

Result JAPAN GEO4 INSTALLED + PLAY CHECK (runner 7, Shannon "Yes, run it", Studio EDIT, unpublished): japan_geo4.lua at 026423a (5974,
adler32 1343372298): "QQ GEO4 the horizon: 35 old parts removed; JapanMap['Horizon sea'] (Model, Persistent, Shade 0.80, Reflectance
0.00) with 34 planes edge to edge at y -6.9 / -6.95 round the island's box x 5150..7150 z -1300..500, out to x 4000..13000 z
-6000..6000; HorizonSeaClient 875 chars", "QQ GEO4 DONE: ...". Readback: Model under JapanMap, Persistent, 35 children, none left in
workspace. Play: arriving FROM PORTO 34 of 34 planes on the client, 0 hidden; arriving FROM FRANCE (village -> Japan) 34 of 34, 0
hidden. Shade tuned on the test client only (attributes): 0.80 = a dark navy band beyond the terrain edge; 1.45 = too bright cyan;
1.10 = close, a little dark; 1.20 with Reflectance 0.10 = BEST - the step from 90 up nearly gone (geo4_90_up_shade120_refl010_BEST).
PLEASE BAKE Shade 1.2, Reflectance 0.1 (I did not set them in Edit). West from (5250,20,-400) at 1.2: the hard dark line at x 4750
is gone, a faint seam only. Eye level on the north shore: one sea to the horizon. No diagonal seam seen. Pictures tools/japan/shots_geo4/.
Result JAPAN GEO4 (runner 7, 026423a, INSTALLED in Edit, unpublished; logged at 2dccea8, pictures tools/japan/shots_geo4/): 34 of 34
planes, 0 hidden, arriving from Porto and from France alike - a Persistent model nested under JapanMap streams fine. Shade tuned on
the test client: 0.8 a dark navy band, 1.45 too bright cyan, 1.1 close but dark, 1.2 with Reflectance 0.1 best - the step from 90 up
nearly gone; west from (5250,20,-400) the hard line at x 4750 gone, a faint seam; the north shore at eye level one sea to the
horizon; no diagonal seam. Not yet set in Edit.
Job 106 round 4b (cloud thread): tools/japan/japan_geo4b.lua sets Shade 1.2 / Reflectance 0.1 on the installed model and its planes
(Edit, re-runnable, "QQ GEO4B DONE"); japan_geo4.lua's defaults baked to the same. Run on Shannon's word, save; then the Japan
horizon is done and she can publish.

Result JAPAN GEO4B (runner 7, Shannon "Yes", Studio EDIT, unpublished): japan_geo4b.lua at 9b9e5c4 (1352, adler32 3481514143): "QQ GEO4B
DONE: Workspace.JapanMap.Horizon sea - Shade 1.20, Reflectance 0.10 on the model and its 34 planes". Readback Shade 1.2, Reflectance 0.1.
Asked her to save and publish.
Result JAPAN GEO4B (runner 7, 9b9e5c4, done in Edit on Shannon's "Yes", unpublished; logged at d94e8aa): "QQ GEO4B DONE:
Workspace.JapanMap.Horizon sea - Shade 1.20, Reflectance 0.10 on the model and its 34 planes"; readback matches. JOB 106 CLOSED:
Japan's ground/water visual fixes = geo1 (sea, wall, props, slabs) + geo2 (bed, more sea, weir, stair shadow) + geo3/4/4b (the horizon
as a persistent model under JapanMap, the live water colour x 1.2, reflectance 0.1, tiles edge to edge). Left for later, from the
FINDINGS doc: the bright sheet of shallow canal water behind the weir, the door, the floating backdrop. She saves and publishes.
## Job 113: the croc shout capped, the heroes pointed at the painter, a hung portrait announced (Studio EDIT; ask Shannon first) - runner 7
Shannon (Oct 15): the croc game's game-wide announcement "not sure that's the best thing"; "no one is getting their portrait painted".
Her picks: cap the shout (my suggestion), options 1 + 3, wording "Heroes should have a portrait done! the painter is waiting...".
tools/croc/croc_portrait1.lua (make_croc_portrait1.py, 5551 bytes; anchors found once in forest/build_croc.lua and
village/build_portraits.lua; all four embedded sources compile patched). Three exact-string patches, each independent (anchor counted,
result compiled, original to HudBackup.<Name>_pre_crocportrait1, marker CROCPORTRAIT1_20261015):
 1. workspace.Lagoon.CrocClient celebrate(names): onlookers see the all-free card (confetti, fanfare, island burst) ONCE a session;
    the rescuers always see it, and their card is 138 tall with a third line "Heroes should have a portrait done! The painter is
    waiting by the river."
 2. workspace.PortraitGallery.PortraitServer hang(): after the sitter's "hung", done:FireAllClients("hungall", DisplayName, UserId).
 3. workspace.PortraitGallery.PortraitClient note handler: "hungall" (not the sitter) shows "<name>'s new portrait is hanging in the
    painter's gallery by the river." for five seconds (the sitter's own note is unchanged). The viewer handler ignores "hungall".
"QQ CROCP" lines; "QQ CROCP DONE: CrocClient true, PortraitServer true, PortraitClient true" when all three went in. The live
CrocClient may differ from the repo's builder (snore patches etc.) - an anchor miss skips that script and says so; tell the cloud thread.
Check in play: free all three squirrels - the card with the third line; the painter (80 acorns) - the gallery note for a second player
or the same client would need two players, so a read of the patched text is enough.
## Job 114: a 1000-acorn thank-you for Carhartt0520 (Studio EDIT; ask Shannon first) - runner 7
Shannon (Oct 15): "craft a cute response for carhartt who sent a message to the mayor, and gift them the 1000 acorns as a thank you".
La Poste dev desk: Carhartt0520 (@Carhartt0520, Roblox id 4348272918, checked on the users API) wrote "hello how are you". She sends
the reply herself from the dev desk (text in the cloud thread's answer). The acorns: tools/thanks/gift_carhartt0520.lua (compiles)
adds workspace.Thanks.Gifts.Carhartt0520 = 1000, Id carhartt0520_1, Note = the mayor's note; job 92's ThanksServer pays it once on
their next join (Item_thanks_carhartt0520_1) with the card "A thank-you from the mayor". Re-runnable. "QQ THANKS DONE".

Result job 113 INSTALLED (runner 7, Shannon "Yes", Studio EDIT, unpublished): croc_portrait1.lua at f6c8bdc (5551, adler32 3907133302):
"QQ CROCP CrocClient: 36718 -> 37322 chars; backup HudBackup.CrocClient_pre_crocportrait1", "QQ CROCP PortraitServer: 25128 -> 25282
chars; backup HudBackup.PortraitServer_pre_crocportrait1", "QQ CROCP PortraitClient: 26669 -> 26939 chars; backup
HudBackup.PortraitClient_pre_crocportrait1", "QQ CROCP DONE: CrocClient true, PortraitServer true, PortraitClient true". Play check
(CrocEvent:FireAllClients("allfree", names) from the test server - exactly what CrocServer sends after the third cage; the cages
were not opened by hand): {me} -> the card with the third line "Heroes should have a portrait done! The painter is waiting by the
river." (wraps to 2 lines, fits the 138 card); {SomeoneElse} afterwards -> no card (onlooker once a session works); {Ethan, me} ->
the card again, "merci, Ethan & SelBell!" + the third line. PortraitDone "hungall" ("Carhartt0520", uid 1) -> "Carhartt0520's new
portrait is hanging in the painter's gallery by the river." OVERLAP (phone rule): the croc card (y 62, DisplayOrder 19) sits on top
of (1) the DailyCard (DailyGui, order 15) when both show at join - picture crocp_card_rescuer_over_daily_card - and (2) the
PortraitNote (y 70) when a portrait is hung during the card. Pre-existing slot clash (the card was always at y 62), now 34 taller;
suggest the card waits while DailyCard / PortraitNote is up, or sits below them. Pictures tools/croc/shots/.

Result job 114 INSTALLED (runner 7, Shannon "Yes" in this session, Studio EDIT, unpublished): gift_carhartt0520.lua at fa0874d (1880,
adler32 3910230008): "QQ THANKS DONE: workspace.Thanks.Gifts.Carhartt0520 = 1000 acorns, Id carhartt0520_1, with its note (4 gifts
listed; paid on their next join, once)". Readback Value 1000, Id carhartt0520_1, Note "You wrote to the mayor. The mayor wrote back.
Everybody wins. Especially you." (ThanksServer matches the USERNAME, case-insensitive.)
Result jobs 113 + 114 (runner 7, INSTALLED in Edit on Shannon's "Yes", unpublished; logged at 852f449, pictures tools/croc/shots/):
113 - CrocClient 36718 -> 37322, PortraitServer 25128 -> 25282, PortraitClient 26669 -> 26939, "QQ CROCP DONE: ... true, true, true".
Play check (CrocEvent "allfree" fired from the test server): {me} the card with the hero line (fits); {SomeoneElse} after - no card
(once a session works); {Ethan, me} - the card again with the hero line; "hungall" shows "Carhartt0520's new portrait is hanging in
the painter's gallery by the river.". OVERLAP (phone): the croc card (y 62, order 19, 34 taller now) covers the DailyCard at join and
the PortraitNote (y 70) when a portrait is hung during the card. 114 - "QQ THANKS DONE: workspace.Thanks.Gifts.Carhartt0520 = 1000
acorns, Id carhartt0520_1, with its note (4 gifts listed)"; the Note reads back right.
Job 113 round 2: tools/croc/croc_portrait2.lua (make_croc_portrait2.py, 3633 bytes, compiles; self-tested over round 1's patched
sources): CrocClient celebrate() waits up to 8 s while the DailyCard is down (Position.Y.Offset > -100) or the PortraitNote shows
(TextTransparency < 0.9); PortraitClient's note waits up to 7 s while PlayerGui.CrocToast is up. No deadlock (the card waits only
before it exists). "QQ CROCP2 DONE: CrocClient true, PortraitClient true". Ask Shannon, run, save.

Result job 113 ROUND 2 INSTALLED (runner 7, Shannon "Yes", Studio EDIT, unpublished): croc_portrait2.lua at 8861a31 (3633, adler32
832543403): "QQ CROCP2 CrocClient: 37322 -> 37937 chars; backup HudBackup.CrocClient_pre_crocportrait2", "QQ CROCP2 PortraitClient:
26939 -> 27117 chars; backup HudBackup.PortraitClient_pre_crocportrait2", "QQ CROCP2 DONE: CrocClient true, PortraitClient true".
Play check: (1) DailyCard down (offset 62) when allfree fired -> the daily card went up at 2.58 s and the croc card appeared at 2.68 s
(daily offset -290 by then) - no overlap. (2) hungall 0.8 s after a croc card -> the croc card left at 4.8 s, the portrait note showed
at 4.9 s with no croc card present. Both cards take turns.
Result job 113 round 2 (runner 7, 8861a31, INSTALLED in Edit on Shannon's "Yes", unpublished; logged at f6ca994): CrocClient 37322 ->
37937, PortraitClient 26939 -> 27117, "QQ CROCP2 DONE: CrocClient true, PortraitClient true". Play check: allfree with the DailyCard
down - the daily card up at 2.58 s, the croc card at 2.68 s; hungall during a croc card - the card left at 4.8 s, the note at 4.9 s.
No overlap. JOB 113 CLOSED, JOB 114 CLOSED. She saves and publishes.

PUBLISHED (Shannon: "saved and published", Oct 15 2026 evening, after job 113 round 2): out with it - Homebase at her spot (job 112,
fc531ed), Japan geo2/geo3/geo4/geo4b (the horizon under JapanMap, Shade 1.2 / Reflectance 0.1), birds v7 + the bench gull, jobs
113 + 113r2 (croc hero line, hungall note, cards take turns), job 114 (Carhartt0520's 1000-acorn gift, paid on their next join to a
new server). Nothing installed in Edit is left unpublished.
PUBLISHED (Shannon, Oct 15, "saved and published"; runner 7 logged at ece2647): the Homebase move (job 112), the Japan horizon (geo2
to geo4b), birds v7 with the bench gull, croc jobs 113 + 113r2, gift job 114. Nothing installed in Edit is left unpublished.
Open: the World Pass timing and the under-13 check; the treehouse add-ons and decorations; the piece-finder product id (108);
Star's statue log lines; later the multi-place split, the PortoEnvironmentBackup archive, Japan FINDINGS (the canal's bright
sheet behind the weir, the door, the floating backdrop).
## Job 115: what brings players back (read-only, Oct 17) - runner 7
Shannon (Oct 15): new players have suddenly started coming back for a second play; "yes please do" to reading what they head for.
Her choice: "You read it in my Chrome". Runner 7's one-time run Oct 17 10:00 -04:00 (14:00Z) reads her Creator Dashboard read-only:
Custom Events Interact_Prompt / Area / Item / Seat / Tool by Cohort and Name (top 15), day-1 retention by platform (7 days), the
Funnel steps; it messages the cloud thread "Runner 7: Creator Dashboard read for what brings players back (Oct 17)" (screenshots
from her if Chrome is not connected). The cloud thread's own check-in fires Oct 17 17:16Z as a fallback. Then: Returning vs New, what
to build more of.
## Job 116: Shademade as a guest on the private Japan preview (Studio EDIT; ask Shannon first) - runner 7
Shannon (Oct 15): "can you set shademade up so that his balloon also goes to Japan map, even though its not done yet, I want him to
see it." Shademade = Roblox user id 3121141 (users API). tools/japan/japan_guest1.lua (make_japan_guest1.py, 7527 bytes; self-tested
against the Oct 15 exports with japan_fix1 applied, all seven sources compile patched). Marker JAPANGUEST1_20261015; originals to
HudBackup.<Name>_pre_japanguest1; an anchor miss skips that script and says so.
 1. ServerScriptService.JapanPreviewAccess: IsAllowed = the owner, Access.GuestUserIds ({[3121141] = true}), or any id in the
    module's attribute GuestUserIds (comma-separated; the installer creates it empty) - Shannon can add or remove guests in
    Properties. Server side all follows: BalloonServer flies a guest to Japan (and skips the 44-squirrel lock for that ride), the
    guard lets them stay, the train, the taxi home, SpawnReturn's Area "japan"; JapanPreviewGuard mirrors it to the player
    attribute JapanPreviewAllowed every 0.2 s.
 2. BalloonField.BalloonClient: previewOwner = owner or JapanPreviewAllowed, kept current; the prompt reads "Your balloon · private
    Japan preview / Fly to Japan" for a guest. 3. JapanPreviewVisibility: waits up to 8 s for the attribute; a guest is not hidden
    from Japan. 4. JapanAtmosphere, 5. JapanWaterAppearance: lighting and water for a guest. 6. MapMusic.MusicClient: the four owner
    checks -> isPreview(). 7. JapanMap's three AutomaticFoodSeatContact: the food seats.
 Prints BalloonField.JapanPreview (false would give everyone the ordinary ride). "QQ JGUEST DONE: ..." with one result per script.
 Takes effect for Shademade only once PUBLISHED (and on his next join). Check in play: the owner's ride still flies to Japan; an
 ordinary test player is still hidden from and thrown out of Japan.

Result job 116 INSTALLED (runner 7, Shannon in this session: "Pull ... at commit 7fbcdc9 and run tools/japan/japan_guest1.lua in
Studio Edit", unpublished): japan_guest1.lua at 7fbcdc9 (7527, adler32 549230530): "QQ JGUEST JapanPreviewAccess: 966 -> 1441 chars",
"BalloonClient: 37493 -> 37807", "JapanPreviewVisibility: 2412 -> 2639", "JapanAtmosphere: 2577 -> 2658", "JapanWaterAppearance: 1110 ->
1204", "MusicClient: 11980 -> 12084", "AutomaticFoodSeatContact (Street ramen cart) / (Yakitori counter) / (Ramen kitchen): 2245 ->
2329" each (backups HudBackup.<Name>_pre_japanguest1, _2, _3), "QQ JGUEST BalloonField.JapanPreview = true (false would give everyone,
guests included, the ordinary ride)", "QQ JGUEST DONE: JapanPreviewAccess ok | BalloonClient ok | JapanPreviewVisibility ok |
JapanAtmosphere ok | JapanWaterAppearance ok | MusicClient ok | AutomaticFoodSeatContact#1 ok | AutomaticFoodSeatContact#2 ok |
AutomaticFoodSeatContact#3 ok". Readback: marker in JapanPreviewAccess, its GuestUserIds attribute ''. Play check not run yet.
Result job 116 (runner 7, 7fbcdc9, INSTALLED in Edit on Shannon's word, unpublished; logged at 3183be4): every script ok -
JapanPreviewAccess 966 -> 1441, BalloonClient 37493 -> 37807, JapanPreviewVisibility 2412 -> 2639, JapanAtmosphere 2577 -> 2658,
JapanWaterAppearance 1110 -> 1204, MusicClient 11980 -> 12084, AutomaticFoodSeatContact x3 2245 -> 2329 (backups _pre_japanguest1,
_2, _3); BalloonField.JapanPreview = true; the marker in JapanPreviewAccess, GuestUserIds attribute ''. Play check pending
(the owner's ride to Japan; an ordinary test player still hidden and returned). Then save + publish; Shademade sees it on his next join.

Result job 116 PLAY CHECK (runner 7, play test, nothing kept; Shannon had already published - "it is published, thank you"):
(1) OWNER: IsAllowed true, JapanPreviewAllowed true; the client's balloon prompt reads "Your balloon Â· private Japan preview / Fly to
Japan" (the ride path itself is unchanged since job 105's flight check; not flown again). (2) ORDINARY PLAYER, simulated in Play Solo:
a temporary server Script in the play-test server set JapanPreviewAccess.OwnerUserId = 0 (a require from the MCP's own context gets
a SEPARATE module copy - the first try changed nothing; the game's scripts share one copy). Then: JapanPreviewAllowed -> false;
pivoted into Japan (6100,4,270) -> JapanPreviewGuard put the player at Spawn_forest (3,6,1) after 0.49 s. GUEST via the attribute:
GuestUserIds "123, 9611145467" -> allowed true, pivoted into Japan and left there 1 s; attribute cleared -> false, thrown out to
(3,5,1). Owner restored -> true. Shademade's table entry Access.GuestUserIds[3121141] = true. NOT testable in Play Solo: the
ordinary player's CLIENT side (JapanPreviewVisibility hiding, the ordinary balloon prompt text) - the client scripts compare the
UserId with 9611145467 themselves, and the Studio test player is always that id; only a Local Server with a second player shows it.
Result job 116 play check (runner 7, logged at bf7fe2c; Shannon had already PUBLISHED: "it is published, thank you"): owner -
IsAllowed true, the balloon prompt "Your balloon · private Japan preview / Fly to Japan". Ordinary player (Play Solo, OwnerUserId set
to 0 by a temporary server Script - a require from the MCP context gets a separate module copy): JapanPreviewAllowed false; pivoted
into Japan, returned to Spawn_forest in 0.49 s. Guest by attribute: GuestUserIds "123, 9611145467" -> allowed, stayed; cleared ->
thrown out. Shademade's table entry [3121141] = true. Not testable solo: an ordinary client's hide / prompt text (the test player
always has the owner id) - that logic is unchanged for a non-guest id (attribute false -> hidden). JOB 116 CLOSED. The Oct 17
dashboard read is still scheduled (14:00Z).
## Job 117: SelBell's treehouse starts over (Studio EDIT; ask Shannon first) - runner 7
Shannon (Oct 15): "reset selbell's treehouse build so that she can start the game from scratch and experience it from the beginning";
"maybe if you click that reset squirrels it can reset everything?" - no: SquirrelSetup's reset clears the FINDS only and keeps acorns
and items on purpose ("keep any acorns/items earned"); the treehouse pieces are items (Item_tree_<id>), so they would stay. So she
presses Reset progress for the squirrels herself, and the treehouse gets its own reset:
tools/treehouse/install_treehouse_reset1.lua (compiles; src/TreehouseReset.lua) adds workspace.Treehouse.TreehouseReset (server
Script) + the folder attributes ResetUserIds "9611145467" and ResetRound 1. On a listed player's join (SaveLoaded + 2 s) every
Item_tree_* they hold is taken back through RS.AwardItems with a NEGATIVE count (the ledger's own "consumed" path - no DataStore
here), the pieces first, Item_tree_done a second later (so TreehouseServer's join check never sees twelve pieces without the flag),
then Item_treereset_r1 = 1 marks the round and TreePieces = 0. Once per round; bump ResetRound to repeat; delete the script to undo.
Squirrels, acorns, other items untouched; the 100-acorn builder's prize can be won again. Live only after the publish, on her next
join. Play check in Studio (her save): Output "TreehouseReset: CozyGameMode - 12 pieces taken back and the done flag (round 1)";
the twelve glowing pieces back, the sign "Future home of Homebase Treehouse. Please excuse the dirt. 0 of 12"; pick p1 -> the reveal.
NOTE: a Studio play test writes her real save too (Studio saves are on), so the check itself resets her - fine, that is the point;
after it she will not see it again live unless ResetRound is bumped. If she wants the first time LIVE, skip the Studio play test.

Result job 117 INSTALLED (runner 7, Shannon "Yes, add it", Studio EDIT, unpublished, NOT play-tested): install_treehouse_reset1.lua
at 66cf63c (4277, adler32 1723564345): "QQ TRESET DONE: workspace.Treehouse.TreehouseReset (2733 chars); ResetUserIds "9611145467",
ResetRound 1". Readback: Script, RunContext Server, Enabled, 2733 chars; folder attributes ResetUserIds '9611145467', ResetRound 1.
(Note: in a Studio play test SquirrelSetup never reads or saves the owner's store - studioFullFindsPreview - so a test could not
spend the live reset either; it would only find no tree items. Not run anyway.)
## Job 118: the MESSAGE IN A BOTTLE game on the Porto beach (play-test PREVIEW first; install on her word) - runner 7
Shannon: Oct 6 (HANDOFF_2026-10-07_PORTO_PART7.md: fill-in-the-blank notes sent TO someone at sea, not from a stranded player; the next
day a reply that answers what you picked; random silly bottles wash up too) + Oct 15 ("preset better with the choose fill in the
blank"; finds pay acorns, "I thought we were charging acorns to send"; "build it as soon as we can" - for the Oct 18 event).
tools/bottle/install_bottle1.lua (make_install_bottle1.py; src/BottleText.lua, BottleServer.lua, BottleClient.lua; compiles):
 - scans the main Porto beach (x 215..340, z -800..-690, step 4) for open sand and water; the STAND on level open sand 10..18 studs
   from the water with 7 clear studs, the candidate nearest Spawn_porto, its back to the sea; up to 10 WASH SPOTS at the waterline
   (open sand within 5 of the water, 12 apart); the reply spot = the one nearest the stand. Prints all of it.
 - workspace.Bottles {BottleEvent, BottleText (module: 7 recipients, 6 cards x 6 x 6 choices, 2 echo lines per card, 4 voice lines
   per recipient, 16 beach notes), BottleServer, BottleClient (Client), Stand (Persistent: counter, posts, striped awning, crate of
   bottles, sign MESSAGGI IN BOTTIGLIA / Messages in a Bottle, WritePrompt)} + ReplicatedStorage.BottleTemplate.
 - SEND at the stand: To / Note / Blank 1 / Blank 2 cyclers, a preview, "Cork it & toss it! (15 acorns)"; one a day; the bottle
   flies out to sea. After the Daily reset (workspace.Daily DayOffsetHours, 9 h) a glowing reply bottle lies at the reply spot for
   the sender only; "Read it" -> the reply (the echo of their picks + the recipient's voice + signature) and what they wrote.
 - BEACH: 3 silly bottles at a time (respawn 75 s), anyone may uncork: a note + 10 acorns, 5 paid a day.
 - Save, via RS.AwardItems deltas only: Item_bottle_out (day + 1), Item_bottle_card (to*1e6 + card*1e4 + a*100 + b),
   Item_bottle_paid (day*10 + n), Item_bottles_found, Item_bottle_replies. Folder attributes SendCost 15, FindPrize 10, FindCap 5,
   MaxBeach 3, RespawnSeconds 75, TestDayOffset (Studio only: set 1 to see tomorrow's reply).
PREVIEW (play test, the installer's body on the server): the QQ BOTTLE lines (scan counts, the stand, the wash spots); pictures of
the stand from the beach and the promenade, the panel (desktop + phone emulator), a toss, a beach bottle uncorked (the note card),
then TestDayOffset 1 -> the reply bottle by the stand and its note. Show her; she can move the stand. Install in Edit on her word.

Result job 118 PREVIEW (runner 7, play test, nothing kept): install_bottle1.lua at 698785f (39406, adler32 1978412821) on the test
server: "QQ BOTTLE scan: x 215..340 z -800..-690 step 4 - 193 open sand points, 401 water points", "QQ BOTTLE stand: (291.0, -48.1,
-720.0), 17 studs from the water, back to the sea toward (0.71, -0.71); 25 candidates, 4 blocked before it", "QQ BOTTLE wash spots
(10): 1 (303, -52.4, -728) | 2 (291, -51.8, -736) | 3 (319, -52.1, -712) | 4 (271, -52.2, -744) | 5 (259, -52.4, -748) | 6 (331,
-52.3, -704) | 7 (339, -51.6, -720) | 8 (335, -51.8, -740) | 9 (247, -52.8, -752) | 10 (235, -52.9, -720); the reply spot is no. 1,
nearest the stand", "QQ BOTTLE DONE: workspace.Bottles (BottleServer 7718, BottleClient 12683, BottleText 7091 chars); the stand at
(291, -48.1, -720); 10 wash spots; send 15, find 10 (5 a day)". Pictures tools/bottle/shots/b1..b8 (force-added).
 STAND: 55 parts on the client, box (291.3, -44.0, -718.8) 9.8 x 8.2 x 3.6; striped blue awning, bottles on the counter, the crate of
    bottles at its side, "MESSAGGI IN BOTTIGLIA / Messages in a Bottle" readable from the promenade side (b2, b3); from the sea side
    the sign board's back is plain white (b1). Sits on the sand between the beach umbrellas, beside the round stone platform and the
    "LA CALETTA" sign; nothing intersects it. Prompt "Messages in a Bottle / Write a message" (max 10).
 PANEL (desktop 1672x635, b4): title, "One bottle a day. A reply washes up tomorrow.", To / Note / Blank 1 / Blank 2 cyclers, the
    preview, "Cork it & toss it! (15 acorns)" - clean. CUT: the Note cycler's own text "Note 1: Ahoy! I hope you have enough ___. I'm
    sending you" stops mid-sentence (two lines in a one-line box).
 PHONE: not pictured - Studio's device emulator can't be switched from the MCP. By the code's fit(): the panel is 440 x 470 scaled by
    min((W-24)/440, (H-40)/470), clamp 0.5..1, centred, IgnoreGuiInset - on an 844 x 390 phone that is 0.745 -> 328 x 350 at y 20..370,
    x 258..586, so its top ~36 px (title + the X button at about (560, 40)) sit under the top HUD bar's height (the
    "Squirrel Luminary" pill and the right-hand buttons draw above it, DisplayOrder). Needs a phone check in her Device emulator.
 TOSS (the send call the button makes): acorns 110 -> 95, Item_bottle_out 20742, Item_bottle_card 1010101, server "sent", then "state";
    the panel closed. The flight / "Off it goes!" toast was over before my picture (b5 shows after).
 BEACH: 3 bottles at wash spots 2, 4, 10; "Message in a bottle / Uncork" -> the card "A message in a bottle! / The waves are doing a lot
    today. Too much, if you ask me. / - Granchio / +10 acorns / Lovely!" (b5); acorns 95 -> 105, Item_bottles_found 1.
 REPLY (TestDayOffset 1, state refresh): workspace.ReplyBottle at (303, -52.0, -728) on sand (terrain Sand -52.36 under it), glowing,
    toast "A reply to your bottle has washed up by the bottle stand on the beach!" (b6); prompt max 9 - from 10.2 it does not show, from
    6.8 it does. "Read it": "A reply washed up! / Enough snacks? I never have enough snacks. How did you know? P.S. If you see my ship,
    tell it to come back. / - Captain Barnacle, on a very small island / You wrote: ..." (b8), Item_bottle_replies 1. CUT: the "You
    wrote:" line is one line and stops at "...enough snacks. I'm" (the rest - "sending you a hug." - is lost). The card also has a large
    empty band under its title.
 OVERLAP: the game's "Gifts for squirrel friends" popup (GiftsGui) opened on its own timer ON TOP of the reply card (b7) - the bottle
    cards should wait while GiftsGui is up (or the gifts popup should wait for an open bottle card).
 Also: ReplyBottle is a direct child of workspace (not inside workspace.Bottles).
Waits for round 2 (the review's fixes + these) and her word to install.
Job 118 ROUND 2 (cloud thread, from runner 7's preview at 137a64f + an independent code review). Same file, tools/bottle/install_bottle1.lua:
 - SERVER: the save stores only the REAL day (TestDayOffset moves "today" in comparisons only, never what is written); the server
   pushes every ready player's state when the day turns (a 30 s check) and when TestDayOffset changes - so a reply appears at the
   daily reset without reopening the panel, and the Studio check shows at once.
 - CLIENT: the panel is wide and short (640 x 310, two columns: the four cyclers left, the preview and the button right) so a
   landscape phone keeps ~0.9 scale; the fit keeps 110 px clear for the top HUD bar and sits 24 px low; the Note row reads "Note n of
   6" (the sentence is in the preview); cycler texts, the preview and the send button TextScaled with size limits; the note card
   420 x 330 with the signature and the "You wrote" line in their own rooms; the toss and reply bottles live in workspace.Bottles;
   the reply's Read-it prompt reaches 14 studs, beach bottles 12.
 - INSTALLER: the scan and every abort run BEFORE the old install is moved (an ABORT leaves the game working; the old stand is
   ignored by the scan); spot 1 is the REPLY spot and is no longer a wash spot (no beach bottle inside the reply bottle); the sign
   is lettered on its back too; two small patches, each skipped harmlessly on an anchor miss, backups _pre_bottle1:
   workspace.Gifts.GiftsClient's MODAL table gets bottle = true (the gifts popup opened over a bottle note in the preview), and
   workspace.Interact.InteractServer's SKIP_PREFIX gets "bottle_" (the bookkeeping items are not interactions; bottles_found is).
Preview again in play from this commit: the QQ BOTTLE lines, the panel on desktop (and on her phone emulator if she can switch it),
the note card with a long "You wrote" line, TestDayOffset 1 -> the reply bottle appears without reopening; then install in Edit
on her word.

Result job 118 ROUND 2 PREVIEW (runner 7, play test, nothing kept): install_bottle1.lua at 7f0ab4f (43579, adler32 1331052144):
"QQ BOTTLE scan: x 215..340 z -800..-690 step 4 - 194 open sand points, 401 water points", "QQ BOTTLE stand: (295.0, -48.3, -716.0), 17
studs from the water, back to the sea toward (0.71, -0.71); 25 candidates, 2 blocked before it", "QQ BOTTLE spots: 1 (303, -52.4, -728) |
2 (291, -51.8, -736) | 3 (319, -52.1, -712) | 4 (271, -52.2, -744) | 5 (331, -52.3, -704) | 6 (339, -51.8, -716) | 7 (335, -51.8, -740) |
8 (259, -52.4, -748) | 9 (247, -52.8, -752) | 10 (235, -52.9, -716); no. 1, nearest the stand, is the REPLY spot, the other 9 are wash
spots", "QQ BOTTLE GiftsClient: 24294 -> 24362 chars; backup HudBackup.GiftsClient_pre_bottle1", "QQ BOTTLE InteractServer: 8921 -> 8985
chars; backup HudBackup.InteractServer_pre_bottle1", "QQ BOTTLE DONE: workspace.Bottles (BottleServer 8434, BottleClient 13721,
BottleText 7091 chars); the stand at (295, -48.3, -716); 9 wash spots + the reply spot; send 15, find 10 (5 a day)". The stand moved 4
studs from round 1's (291, -720). PANEL (desktop, r2_panel_desktop_two_columns): 640 x 310 at scale 1, two columns, "Note 1 of 6",
the preview beside the cyclers - clean. LONGEST message (to 7, card 5, a 3, b 6; 100 chars) sent: 110 -> 95, Item_bottle_out 20742
(the real day). TestDayOffset 1 (no panel reopen): workspace.Bottles.ReplyBottle appeared on the client 0.1 s later at (303,-52,-728),
prompt max 14; read from 8.2: "A reply washed up! / Bring your friends? Done. I've wanted to build a sandcastle for ages. Your bottle
floated all the way to me! The sea is very big. / - Hana, a squirrel very far to the east / You wrote: If you come to Porto, bring your
friends and we can build a sandcastle." - every label TextFits true, the You wrote line whole on two lines (r2_reply_long_you_wrote).
While a bottle card is open PlayerGui OpenPanel = "bottle", and GiftsClient's MODAL now has bottle = true (line 142; line 319 checks it).
PHONE still not pictured (no emulator from the MCP); by fit() 844 x 390 -> scale 0.90.

Result job 118 ROUND 2 INSTALLED (runner 7, Shannon "Yes, install it" after the round 2 pictures, Studio EDIT, unpublished):
install_bottle1.lua at 7f0ab4f (43579, adler32 1331052144) - the same QQ BOTTLE lines as the round 2 preview, word for word (stand
(295.0, -48.3, -716.0); spots 1 = REPLY (303, -52.4, -728) + 9 wash; GiftsClient 24294 -> 24362, InteractServer 8921 -> 8985; DONE
BottleServer 8434, BottleClient 13721, BottleText 7091). Readback: workspace.Bottles = BottleEvent, BottleText, Stand (Persistent),
BottleServer, BottleClient; TestDayOffset 0; ReplicatedStorage.BottleTemplate present. Asked her to save; she publishes.
## Job 119: the Homebase's sounds and its two camera moments (Studio EDIT; ask Shannon first) - runner 7
Shannon (Oct 15, building it herself): "the toast when you find a piece should be a different sound than the toast for when you find
a squirrel"; "when all pieces are found and the house is complete, maybe do another video quick view of the completed house with
firework celebration or sparklers or confetti ... 'Welcome home (name of player)!'"; "a 6 second hold is almost too long, maybe make
it 4.5 seconds for the first one and the final one".
tools/treehouse/patch_treehouse3_r2.lua (make_patch_treehouse3_r2.py, 33823 bytes, compiles) replaces the installed TreehouseClient
(old -> HudBackup.TreehouseClient_pre_r2_n) with TreehouseClient3 r2:
 1. a piece plays its OWN sound - the harbour bell's ding (rbxassetid://16480570986, the Capitaneria bell) at 1.5x, volume 0.55 -
    from the folder attributes PieceSound / PieceSoundSpeed / PieceSoundVolume (set by the patch if absent; swap in any sound in
    Properties). The squirrel fanfare (1845415163) is no longer used for pieces.
 2. the first-piece look: 1.2 s fly-in, a 4.5 s hold (was ~5.3), then back; her reveal line shows 6.2 s.
 3. the finale on "done": the house redrawn, the camera flies to the finished house (in front of the balcony, up and to the right),
    fireworks (a burst every ~0.5 s, coloured sparks with a flash of light) over the house and confetti over the deck for 4.5 s,
    the fanfare, the banner "Welcome home, <DisplayName>!" (gold, top of the screen), then back to the player and the built card.
Preview in play: pick p1 (the look, 4.5 s), hear the bell ding on each piece; to see the finale fast, set the test player's
Item_tree_p1..p12 (server side, or the Studio save) and pick the last one - the "done" event fires once the twelfth is in.
Her reset (job 117) is installed and unpublished; after the publish she will meet all of this on her own run.

Result job 119 PREVIEW (runner 7, play test, nothing kept): patch_treehouse3_r2.lua at 8676938 (33823, adler32 1631506975): "QQ TREE119
(play test: preview only)", "QQ TREE119 DONE: TreehouseClient 31668 chars; the old one is HudBackup.TreehouseClient_pre_r2_1; PieceSound
rbxassetid://16480570986 at 1.5x". (The test player had Item_treereset_r1 = 1 and no tree items: job 117's reset ran in this play
test on the Studio player - harmless, Studio never saves the owner.) p1: the ONE sound made was rbxassetid://16480570986 speed 1.50 vol
0.55 in TreehouseGui (no squirrel fanfare); the camera was scripted from 0.76 s to 7.48 s after the pick = 6.7 s (1.2 fly-in + 4.5 hold
+ ~1 back). I cannot hear it - Shannon to judge the ding. FINALE: p2..p11 set on the server, p12 picked for real -> TreePieces 12, +100
acorns (110 -> 210), the camera on the house, "Welcome home, SelBell!" in gold at the top, then back, then the "Homebase Treehouse:
built!" card. Replayed with TreehousePick:FireClient(p, "done", 100, 12) for the picture (t119_finale_welcome_home): the house from
above with its lantern, the banner across the top over the oak's crown. The fireworks (bursts 18..30 above the deck, 80 particles
each) show only as a faint sparkle trail in daylight on my capture - the banner band sits where they burst. Suggest: bursts a little
lower / to the sides, or the banner lower, so the two do not share the sky. The built card after the replays opened on top of the
camera's house view once (t119_built_card_over_house) - only because I fired done twice; in one real run it comes after the camera
returns. Waits for her word to install.
Job 119 r2b (cloud thread, from runner 7's preview at 9b3f011: the bell only, the 4.5 s hold, the finale and "Welcome home, SelBell!"
all right; the fireworks a faint sparkle trail in daylight, bursting in the banner's band): the bursts alternate either side of the
house (local x +-11..19) at 15..25 above the oak's foot - beside the house, below the banner - 130 sparks of size 1.8 (Brightness 5
where the property exists) with a brighter, wider flash. Same file, patch_treehouse3_r2.lua, re-run over the preview state or Edit.
## Job 120: a 1000-acorn thank-you for Aspej000 (Studio EDIT; her request = her go) - runner 7
Shannon (Oct 15): "please send 1000 acorns and a thank you to aspej000 @Aspej000" (wrote "Do you like Jazz?" at La Poste; Roblox id
8974266168, users API). tools/thanks/gift_aspej000.lua (job 114's script, compiles): workspace.Thanks.Gifts.Aspej000 = 1000, Id
aspej000_1, Note "Thanks for writing to the mayor! Here are 1000 acorns. Spend them on something jazzy."; paid once on their next
join after the publish. "QQ THANKS DONE".

Result job 119 INSTALLED (runner 7, Studio EDIT, unpublished): first 8676938 on Shannon's "Install as it is" ("QQ TREE119 DONE:
TreehouseClient 31668 chars; the old one is HudBackup.TreehouseClient_pre_r2_1; PieceSound rbxassetid://16480570986 at 1.5x"), then
r2b 9344c6f (34104, adler32 630858847) on her "Yes, both" in this session: "QQ TREE119 DONE: TreehouseClient 31949 chars; the old one
is HudBackup.TreehouseClient_pre_r2_2; PieceSound rbxassetid://16480570986 at 1.5x". The r2b fireworks were NOT re-previewed (her
choice). Readback: one TreehouseClient, 31949 chars; TreehouseReset still there; PieceSound 1.5x / 0.55.
Result job 120 INSTALLED (runner 7, her "Yes, both", Studio EDIT, unpublished): gift_aspej000.lua at 60058f4 (1860, adler32
1733580574): "QQ THANKS DONE: workspace.Thanks.Gifts.Aspej000 = 1000 acorns, Id aspej000_1, with its note (5 gifts listed; paid on
their next join, once)". Readback Note "Thanks for writing to the mayor! Here are 1000 acorns. Spend them on something jazzy."
Also in Edit, unpublished: job 118 (bottle game) and job 117 (treehouse reset) - all go out with her next publish.
Result jobs 119 r2b + 120 (runner 7, INSTALLED in Edit on Shannon's "Yes, both", unpublished; logged at ff187cf): QQ TREE119 DONE
(TreehouseClient 31949; old -> HudBackup.TreehouseClient_pre_r2_2; r2b's fireworks not re-previewed); QQ THANKS DONE Aspej000 1000.
## Job 121: the Homebase room roomier, the yellow square, the seats (play-test PREVIEW, then Edit on her word) - runner 7
Shannon (Oct 15): "the door entry and ceiling are too low, for a tall character it will be hard to fit ... the doorway entrance is
definitely too low"; "inside there is a yellow square on the ground and I am not sure what that is"; "the chairs in there should have
the sit mechanic". tools/treehouse/patch_treehouse3_r3.lua (make_patch_treehouse3_r3.py, 37042 bytes, compiles; replaces the client,
old -> HudBackup.TreehouseClient_pre_r3_n; "QQ TREE121"):
 - walls 9 tall (floor 10.5 .. 19.5; were 6.5): the door 5 wide, the opening ~7.6 high under a lintel trim, a dark door frame, a wall
   piece over it; the window holes as before (y 12.7..15.5), the wall above them 4 tall; the roof, ridge, awning and lantern up 2.5.
 - the yellow square was the gold floor cushion: replaced by a red ARMCHAIR (base, seat cushion, back, two arms) by the left window,
   facing the middle of the room.
 - the two stools and the armchair's cushion get a "Sit" prompt (7 studs): the house is drawn on each screen, so the sit is local -
   the root placed on the seat (HipHeight-based), Humanoid.Sit, a WeldConstraint to the seat; a jump stands up; a redraw frees you.
 Everything from job 119 (the bell, the 4.5 s holds, the finale) stays.
PREVIEW: walk in through the door with the default avatar (and, if you can, a tall one - head clearance), the ceiling from inside, sit
on a stool and the armchair (do they sit at the right height, facing the table / the room? does a jump stand up?), pictures inside.

Result job 121 PREVIEW (runner 7, play test, nothing kept): patch_treehouse3_r3.lua at 0b38129 (37042, adler32 514236549): "QQ TREE121 (play
test: preview only)", "QQ TREE121 DONE: TreehouseClient 34887 chars; the old one is HudBackup.TreehouseClient_pre_r3_3; PieceSound
rbxassetid://16480570986 at 1.5x". At 12 pieces: deck top 10.56, walls 9 tall (top 19.56), the door posts at z 1.1 and 6.3 (5 wide), the
lowest thing over the doorway at 18.56 = 8.0 above the deck; the test avatar is 6.30 tall (HipHeight 2.22) - clears with 1.7 to spare.
SITTING (prompt triggered from the client): stool 1 (top 12.26) -> Sit true, facing -X (toward the table), BUT the LowerTorso's bottom is
1.02 above the seat top; the armchair (top 12.06) -> Sit true, facing -Z into the room, LowerTorso bottom 1.02 above the cushion
(t121_armchair_sitting: reads acceptably on the armchair, the cushion being deep). SEATED HEIGHT: about 1.0 too high on both - lower
the root by ~1.0 (offset p.Size.Y/2 + HipHeight*0.5 + 0.9 -> about + HipHeight*0.5 - 0.1). A jump stood the player up (Sit false).
Stool 2 did not seat in my test - my placement put stool 1's prompt nearer (they are 2.8 apart, one prompt shows at a time); not a fault
found. Not installed.

Treehouse RESET round 2 (runner 7, Shannon in this session: "please reset my treehouse to not made yet again so I can see the effects
once its built" / "set me to zero pieces please", Studio EDIT, unpublished): workspace.Treehouse ResetRound 1 -> 2 (ResetUserIds
'9611145467', TreehouseReset enabled). Runs once on her next live join after the publish.
Job 121 r3b (cloud thread, from runner 7's preview at ecd7c06: walls 9, door 5 wide, the lowest thing over the doorway 8.0 above the
deck - a 6.30-tall avatar clears; stool and armchair seat, a jump frees; the LowerTorso 1.02 above the seat top): the seated root
offset is HipHeight * 0.5 - 0.1 (was + 0.9). Same file, patch_treehouse3_r3.lua. Also logged by runner 7: Shannon asked "set me to
zero pieces please" - workspace.Treehouse ResetRound = 2 in Edit (unpublished), so her pieces go once more on her next live join.

Result job 121 r3b PREVIEW + INSTALLED (runner 7): patch_treehouse3_r3.lua at 8574619 (37108, adler32 2455483522). Play test: all three
seats (stool 1, stool 2, armchair) -> Sit true, LowerTorso bottom 0.02 above the seat top (was 1.02) - t121b_armchair_sitting. Then
INSTALLED in Edit on Shannon's "Yes, install it", unpublished: "QQ TREE121 DONE: TreehouseClient 34953 chars; the old one is
HudBackup.TreehouseClient_pre_r3_3; PieceSound rbxassetid://16480570986 at 1.5x". Readback: one TreehouseClient 34953 chars; ResetRound
2; TreehouseReset present. Unpublished in Edit now: jobs 117 (+ round 2), 118, 119 r2b, 120, 121.

PUBLISHED (Shannon: "published; testing it now.", Oct 16 2026): out with it - job 117 + ResetRound 2 (her treehouse starts over on her
next live join), job 118 (Message in a Bottle stand on the Porto beach), job 119 r2b (bell per piece, 4.5 s holds, the finale with
fireworks), job 120 (Aspej000's 1000 acorns), job 121 r3b (taller door/ceiling, armchair, sittable seats). Nothing left unpublished.
## Job 122: the finished Homebase's sign (Studio EDIT; her request = her go) - runner 7
Shannon (Oct 15, in the live game): "why does the sign say Treehouse est. today.? welcome home? Maybe once its done it should
Selbell's Homebase Treehouse?", then "Welcome home". The finished sign now reads "<DisplayName>'s / Homebase Treehouse / Welcome home!"
(was "Homebase Treehouse / est. today. / Welcome home."). tools/treehouse/patch_treehouse3_r4.lua (make_patch_treehouse3_r4.py,
compiles; replaces the client, old -> HudBackup.TreehouseClient_pre_r4_n; "QQ TREE122"). Nothing else changed from job 121 r3b.
## Job 123: the Homebase seats sit you on touch (Studio EDIT; her request = her go) - runner 7
Shannon (Oct 15): "the chair in the treehouse and the 2 stools by the table should have an automatic sit mechanic, not an interact
button." tools/treehouse/patch_treehouse3_r5.lua (make_patch_treehouse3_r5.py, 37512 bytes, compiles; "QQ TREE123"; replaces the client,
old -> HudBackup.TreehouseClient_pre_r5_n; INCLUDES job 122's sign, so it supersedes patch_treehouse3_r4.lua): the three seats lose
their "Sit" prompt; walking into one (BasePart.Touched by the local character - the house is drawn on this client, its physics is
the character's own) places you on it and welds you on, like a Roblox Seat; not while jumping or climbing; a jump stands you up and
for 2 s no seat takes you, so you can walk off. Check in play: walk into each stool and the armchair (you sit), jump (you stand and
can walk away without sitting again), the hips on the seat; walking along the table's side should not grab you from the far side.
## Job 124: a build's sounds for the Homebase pieces (play-test PREVIEW, her listening pass, then Edit) - runner 7
Shannon (Oct 15): "how difficult would it be to take different short clips of this for the sound of picking up a piece? to make it
sound like its a build? 6186807867" -> "go". rbxassetid://6186807867 = "Construction_Sounds" (audio, Blu_Lucario, IsPublicDomain true
on the economy API - whether it PLAYS in her place is the first thing to check). tools/treehouse/patch_treehouse3_r6.lua
(make_patch_treehouse3_r6.py, 40411 bytes, compiles; "QQ TREE124"; replaces the client, old -> HudBackup.TreehouseClient_pre_r6_n;
INCLUDES jobs 122 (the sign) and 123 (sit on touch) - install r6 instead of r5 if r5 is not in yet):
 - the client preloads the recording; once loaded it prints "Treehouse: build sound ... loaded, N s long; slices 1 a-b, 2 ..." and
   each piece plays the NEXT slice (piece n -> slice n) through Sound.PlaybackRegion; the last piece a slice of at least 2.5 s.
 - folder attributes (set if absent): PieceClipSound "rbxassetid://6186807867", PieceClips "" (empty = TOTAL evenly spaced slices of
   PieceClipLength), PieceClipLength 1.0, PieceClipVolume 0.6. PieceClips "0.4-1.3, 2.0-2.8, ..." picks slices by hand (live: the
   client rebuilds the list when the attribute changes). If the recording does not load in 15 s: "did not load - pieces use the bell".
PREVIEW: the load line (does it load? how long is it?); then her LISTENING PASS: in a play test, a command-bar loop that plays each
slice in turn with its number (e.g. for i, c in slices: play, print i, wait) so she can say "3 and 7 are silence / a clang" - then set
PieceClips by hand to the good parts. Then install in Edit with that PieceClips value, and she publishes.
Job 124 r6b (cloud thread): Shannon saw the 122 sign in a preview and did not like the layout ("Maybe do Homebase Treehouse Welcome home
SelBell?"): the finished sign reads "Homebase Treehouse / Welcome home, <DisplayName>!". Same file, patch_treehouse3_r6.lua. Nothing of
122 / 123 / 124 is installed yet (runner 7).
Job 118 ROUND 3 (cloud thread; Shannon playing it live, Oct 15): "there should not be 2 right on the shore at once, that is too many.
maybe one very silly one"; the kiosk "is sitting on a beach towel and in the way of an umbrella ... maybe further up, on the landing
behind the police officer next to the boat club"; "the fill in the blank is nonsensical"; "we should be able to personalize it more";
"the replies ... should be short goofy one liners"; the kiosk faces "the way my character is facing now; the same way as the police
squirrel". Same file, tools/bottle/install_bottle1.lua (a full re-run: the old folder -> HudBackup.Bottles_pre_n; the saves untouched):
 - MaxBeach 1 (one silly bottle at a time), RespawnSeconds 90.
 - the KIOSK at her spot: runner 7's reading (473.34, -8.77, -970.93) on the Via della Piazza paving (Cobblestone, top -12.0) by the
   Circolo Velico courtyard, 12 studs from officer_acorn_police_squirrel_color; yaw 98.6 (hers 98.2, the officer's 99.1 from its
   bones) - the counter, sign and prompt face that way. No waterline within 40 studs, so the REPLY bottle lies at the kiosk's foot
   (2.5 right, 4.5 in front, on the ground) and every waterline spot on the main beach is a wash spot. The acorn spot 10 studs away
   (Workspace.Acorns.Acorn) is not touched.
 - BottleText: six new cards where every blank-1 x blank-2 pairing reads as a sensible silly sentence; a fifth row "Ask:" with six
   questions; the note is signed "From <DisplayName>"; the reply is "Dear <DisplayName>," + ONE goofy line - the recipient's own
   answer to the question (7 x 6 answers); bottles sent before this round (no question) get their echo line. Item_bottle_card is now
   to*1e8 + q*1e6 + card*1e4 + a*100 + b (old codes < 1e8 decode as before). A squirrel-hint P.S. is built but OFF (folder attribute
   ReplyHints true turns it on).
 - the panel 640 x 330 with the fifth row; the reply card 420 x 340.
PREVIEW in play: the QQ BOTTLE lines ("stand (her spot)", the reply spot line); pictures of the kiosk on the landing from where
players arrive; the panel with the Ask row; send one; TestDayOffset 1 -> the reply bottle at the kiosk's foot and its one-liner.
Then install on her word; she publishes.

Result jobs 122-124 (runner 7): 122 previewed ("SelBell's / Homebase Treehouse / Welcome home!", fits) - Shannon disliked the layout,
asked for "Homebase Treehouse Welcome home SelBell" -> r6b. 124 at 822346d previewed: "Treehouse: build sound rbxassetid://6186807867
loaded, 12.6 s long; slices 1 0.1-1.1 ... 12 11.5-12.5". Listening pass: her audio was off at first (the game played every slice,
PlaybackLoudness 41..248); she asked for longer slices -> 1.5 s each (PieceClipLength 1.5 in play), heard them twice: good = 2, 3, 4, 5,
6, 7, 8, 9, 10, 12 (1 and 11 duds); "Use the 10 good ones", 8 and 9 repeated. PieceClips = "1.09-2.59, 2.08-3.58, 3.07-4.57, 4.06-5.56,
5.05-6.55, 6.05-7.55, 7.04-8.54, 8.03-9.53, 9.02-10.52, 11.0-12.5, 7.04-8.54, 8.03-9.53". PREVIEW of r6b ee9c2b7 (40401, adler32 1431826533)
with that PieceClips: the client read it ("slices 1 1.1-2.6 ... 10 11.0-12.5, 11 7.0-8.5, 12 8.0-9.5"); sign at 12 = "Homebase Treehouse /
Welcome home, SelBell!" TextFits true, 4 lines (t124b_sign_homebase_welcome_home_selbell); no Sit prompts; walking into the armchair and
both stools seated in 0.4-0.6 s, LowerTorso 0.01-0.02 above each seat, armchair facing -Z, stools -X; a jump + walking off -> not
re-grabbed. INSTALLED in Edit on her "Yes, install it all": "QQ TREE124 DONE: TreehouseClient 38139 chars; the old one is
HudBackup.TreehouseClient_pre_r6_1; PieceSound rbxassetid://16480570986 at 1.5x" + PieceClips set as above (PieceClipLength 1, Volume
0.6, ResetRound 2). Unpublished. (In every Studio play test TreehouseReset printed "CozyGameMode - 0 pieces taken back (round 2)" -
the script runs; the live question is still open with her.)
Treehouse RESET round 3 (runner 7, Shannon: "Yes, restart me again", Studio EDIT, unpublished): ResetRound 2 -> 3 (ResetUserIds
'9611145467', TreehouseReset enabled). Runs once on her next live join after the publish (with r6b + her PieceClips).

PUBLISHED (Shannon: "published; testing now"): treehouse r6b (sign "Homebase Treehouse / Welcome home, <name>!", walk-in seats, her 10
build-sound slices) + ResetRound 3. Nothing left unpublished in Edit.

Result job 118 ROUND 3 PREVIEW (runner 7, partial, play test, nothing kept): install_bottle1.lua at 1f66b4b (51689, adler32 4215756385):
"QQ BOTTLE stand (her spot): (473.3, -12.0, -970.9) on ...Via della Piazza.Continuous fitted paving, facing yaw 99; NOT clear:
...13 Hillside town.Filled village paving corners.Circolo Velico level courtyard.Continuous fitted cobblestone; nearest water 244
studs", "QQ BOTTLE the reply spot: in front of the kiosk at (468, -12.0, -973) - the waterline is more than 30 studs away", "QQ
BOTTLE spots: 1 (335, -51.8, -740) ... 10 (235, -53.1, -744); no. 1 ... is the REPLY spot, the other 10 are wash spots" (contradicts
the line before - which is it?), "QQ BOTTLE GiftsClient: already patched", "QQ BOTTLE InteractServer: already patched", "QQ BOTTLE
DONE: ... (BottleServer 10288, BottleClient 14400, BottleText 11018 chars); the stand at (473, -12.0, -971); 10 wash spots + the reply
spot; ... the old folder is HudBackup.Bottles_pre_1". SIGN (her complaint about the LIVE stand, same here): SignBoard y -6.45..-4.95,
the AwningFringe -5.23..-4.78 hangs over its top - from the normal camera "MESSAGGI IN BOTTIGLIA" is hidden, only "Messages in a
Bottle" shows (r3_kiosk_player_view_sign_hidden). Shannon also wants the toss to be a short animation of the bottle thrown into the sea.
Job 118 ROUND 4 (cloud thread; from Shannon via runner 7 at 0163d94: "you cannot see [the sign] under the awning unless you tilt the
view"; "the animation for cork it and throw it, it should be a short animation that shows the bottle being thrown into the sea").
Same file, tools/bottle/install_bottle1.lua (55361 bytes, compiles):
 - the sign board stands ON the awning (y ~8.8..10.7 above the kiosk's floor, two short posts and a trim on top), both faces lettered -
   both lines readable at normal camera height, clear of the fringe.
 - the toss: the camera cuts to the shore spot nearest the kiosk (TossView attribute, set by the installer: the camera 6 behind and 7
   above the waterline spot, looking out), the bottle arcs ~28 studs out over the water, splashes (spray + the croc game's splash
   sound, her pick 76469933896339), bobs and drifts away, then the camera comes back (~3.3 s). Toast: "Off it goes! Come back to the
   kiosk tomorrow for a reply."
 - the "waterline spots" line now says plainly whether no. 1 is the reply spot or the reply lies at the kiosk (round 3 printed both).
 - clear(): the floor the kiosk stands on no longer counts as an obstacle (round 3 flagged the courtyard cobblestone under it).
 Runner 7 also reported (0163d94): the treehouse did NOT reset live for her after the last publish; a forced Studio re-run took 12 +
 done to 0 correctly. Open: her F9 "TreehouseReset:" lines / an old server / another account. ResetRound is 3 in Edit.
Job 117 r2 (cloud thread, for the live reset that did not happen): TreehouseReset now prints on every listed join - "joined - listed,
round N; waiting for the save", then either the "N pieces taken back" line, "round N was already done on this save", or "the save
never loaded" - so her F9 Server log says which. Re-run tools/treehouse/install_treehouse_reset1.lua in Edit (it replaces the
script and keeps ResetUserIds / ResetRound 3). Likely cause to rule out first: after a publish, an already-running server keeps the
OLD place version (no TreehouseReset) until it restarts - "Restart servers for updates" on the Creator Dashboard, or a fresh server.

Result job 118 ROUND 4 PREVIEW (runner 7, play test, nothing kept): install_bottle1.lua at d4b9857 (55382, adler32 2490489069): stand (her
spot) (473.3, -12.0, -970.9) yaw 99 - STILL "NOT clear: ...Circolo Velico level courtyard.Continuous fitted cobblestone" (that part is at
(457.5, -12.3, -940.0), 0.5 x 10.6 x 1.3 - 31 studs off; nothing touches the kiosk by eye); "the reply spot: in front of the kiosk at
(468, -12.0, -973)"; "waterline spots: ... 10 wash spots (the reply lies at the kiosk)"; "toss view: the camera at (341, -45, -740) on
the shore, the bottle lands at (307, -52.9, -740) on the water"; DONE BottleClient 16676. SIGN: on top of the awning, both lines read from
the normal camera (r4_kiosk_sign_on_awning). PANEL: five rows To / Note / Blank 1 / Blank 2 / Ask, the preview signed "From SelBell".
A send happened while the panel was open (not by my code - Shannon may have clicked); the "Off it goes!" toast then sat OVER the Ask row of
the re-opened panel (r4_panel_five_rows_toast_over_ask). TOSS (FireClient "sent" twice for the pictures - the server refuses a second
real send the same day: "Your bottle is already out at sea. Check the beach tomorrow!" = stale wording): the camera cuts to the shore
looking -X, but the view is filled by the stone QUAY WALL ("Continuous fitted paving" at x ~315, top -46.8) and the bottle lands behind
it at (307, -740) - neither the arc nor the splash shows (r4_toss_view_quay_wall_blocks). Needs a toss line out over open water. REPLY
(TestDayOffset 1): workspace.Bottles.ReplyBottle at (468.5, -11.6, -972.7), glowing at the kiosk's foot (r4_reply_at_kiosk); card "Dear
SelBell, / Coconuts. Only coconuts. It's coconuts or nothing on this island. / - Captain Barnacle ... / You wrote: ... What's your
favourite food?" all TextFits (r4_reply_card). Stale line in BottleClient 211: "A reply to your bottle has washed up by the bottle stand
on the beach!". Not installed.
Job 118 ROUND 5 (cloud thread). Shannon, on round 4's pictures: "the post holding up the sign on the left side should be behind the sign
not in front"; "the sound you are using for the throw of the bottle is the same sound as when the croc attacks, that does not work";
"the animation is so quick you can't tell what is happening". Runner 7's round-4 preview (51603bf): the toss camera looked into the
quay wall ("Continuous fitted paving", x ~315, top -46.8) - neither the arc nor the splash showed; stale "beach" wording in two
places; the "Off it goes!" toast left over the Ask row when the panel reopened; "NOT clear" printed for a big courtyard part 31 away.
Same file, tools/bottle/install_bottle1.lua (57932 bytes, compiles):
 - the sign posts BEHIND the board (z +0.05; the board's back face is at -0.175).
 - TossSound folder attribute, default rbxassetid://9116394876 (the bottle notes' chime, at 0.9 speed) - not the croc's splash; any id
   from the Toolbox, or "" for none.
 - the toss ~7 s: 0.9 s on the shore with the bottle, a 2.6 s arc (the bottle scaled 2.2x, sparkling), the camera FOLLOWING it, the
   landing spray, a 3 s bob out to sea, then back. The toast comes as it lands.
 - the toss view is chosen with sight-line raycasts: the first waterline spot (nearest the kiosk first) whose camera (8 back, 10 up),
   throw point, arc top and landing (28 out, checked to be over terrain Water) all see each other; printed, or "NO shore spot ..."
 - wording: "A reply to your bottle is waiting at the bottle kiosk by the boat club!", "... waiting right here by the kiosk", the
   server's "Come back to the kiosk tomorrow!"; opening the panel clears any toast.
 - the clearance check at her spot is 3 studs and reads "a part's box reaches the spot (check by eye)" instead of NOT clear.
Job 118 round 5b: Shannon's splash pick, rbxassetid://129669875728815 ("Splash.mp3", Teriyaki's Games group, IsPublicDomain true) is
the TossSound default, at normal speed, volume 0.6. If it does not play (audio privacy), the attribute can be set to another id.

Result job 118 ROUND 5 PREVIEW (runner 7, play test, nothing kept): f126f3a (57940, adler32 2055725830) then c172f87 (57920, adler32
4160347013, the splash TossSound): "QQ BOTTLE stand (her spot): (473.3, -12.0, -970.9) ... facing yaw 99; 3 studs clear; nearest water
244 studs", "QQ BOTTLE toss view: the camera at (283, -42, -732) on the shore, the bottle lands at (283, -53.2, -768) on open water -
clear sight lines", "QQ BOTTLE DONE: ... BottleClient 17706 ...". TOSS: mid-arc the 2.2x bottle with sparkles flies out over open sea
against the sky, the lighthouse path and tide pools to the right (r5_toss_mid_arc). The landing moment itself could not be caught live
(screen_capture timed out twice at ~3.5 s); a raycast camera -> landing hits terrain Water at (283.0, -52.9, -767.7) - nothing between -
and a 2.2x bottle placed at the landing spot shows plainly on open water from the toss camera (r5_landing_view_open_water). SOUND
rbxassetid://129669875728815: IsLoaded, TimeLength 1.78 s, peak loudness 238 on the client. SIGN: posts behind the board, both lines clear
from the front (r5_sign_front). Wording: "A reply to your bottle is waiting at the bottle kiosk by the boat club!", "Off it goes! Come back
to the kiosk tomorrow for a reply." (at 4.2 s, as it lands).

Result job 118 ROUND 5 + reset diagnostics INSTALLED (runner 7, Shannon "Yes, install both", Studio EDIT, unpublished): install_bottle1.lua at
c172f87 (57920, adler32 4160347013) - the same QQ BOTTLE lines as the round 5 preview (stand (473.3, -12.0, -970.9) yaw 99, 3 studs
clear; toss view camera (283, -42, -732) -> (283, -53.2, -768) clear; DONE BottleServer 10292, BottleClient 17706, BottleText 11018; old
folder HudBackup.Bottles_pre_1). install_treehouse_reset1.lua at d4b9857 (4725, adler32 2367559483): "QQ TRESET DONE:
workspace.Treehouse.TreehouseReset (3137 chars); ResetUserIds "9611145467", ResetRound 3". Readback: Bottles = BottleEvent, BottleText,
Stand, BottleServer, BottleClient; TossSound rbxassetid://129669875728815; TestDayOffset 0. Told her: save, publish, then restart
servers for the update and join a fresh server; F9 Server shows a "TreehouseReset:" line.

PUBLISHED (Shannon: "saved and published; servers restarted"): bottle round 5 (c172f87, the kiosk by the boat club, the toss, the splash)
and the TreehouseReset diagnostics (ResetRound 3). Servers restarted, so her next join is on the new version. Waiting for her F9 Server
"TreehouseReset:" line.
Job 118 ROUND 6 (cloud thread; Shannon live after r5, via runner 7: "if you already sent a message that day, if you click E for send a
message you should not get the menu to choose a message, you should only get the note that says 'Your bottle is out at sea. A reply
will wash up here tomorrow!'"). BottleClient: E at the kiosk with a bottle at sea shows ONLY that note (a toast, her exact words) -
no panel; with a reply waiting, E reads it straight away (the reply card), the glowing bottle at the kiosk's foot still works too;
otherwise the writing panel as before. The kiosk prompt's action text follows (this player's view only): "Write a message" /
"Your bottle is at sea" / "Read your reply". Same file, tools/bottle/install_bottle1.lua (a full re-run as before).

Result job 118 ROUND 6 PREVIEW (runner 7, play test, nothing kept): install_bottle1.lua at 617e1ee (59000, adler32 761408470): stand (473.3,
-12.0, -970.9) yaw 99, 3 studs clear; toss view clear; DONE BottleClient 18786. Three states: (1) fresh - prompt "Write a message", E
-> the five-row panel. (2) after a send (110 -> 95) - prompt "Your bottle is at sea", E -> NO panel, only the toast "Your bottle is out
at sea. A reply will wash up here tomorrow!" (r6_at_sea_note_only). (3) TestDayOffset 1 - prompt "Read your reply", E -> the reply card
straight away (Captain Barnacle). OVERLAP: about 4 s after the day turned, the client's delayed toast "A reply to your bottle is waiting
at the bottle kiosk by the boat club!" appeared OVER the open reply card, covering its "Lovely!" button
(r6_reply_card_toast_over_button). Fix: skip that toast while a bottle card/panel is open (OpenPanel == "bottle") or once the reply was
read, or when the player is already within the prompt range of the kiosk. Not installed.
Job 118 round 6b (cloud thread, from runner 7's r6 preview at c06626d: all three kiosk states right; the delayed "A reply to your
bottle is waiting ..." toast landed on top of the open reply card): the toast is skipped when a bottle card or panel is open
(OpenPanel "bottle"), when the reply has been read by then, or when the player is within 14 studs of the kiosk. Same file.

Result job 118 ROUND 6b PREVIEW + INSTALLED (runner 7): install_bottle1.lua at f4239f9 (59396, adler32 1988666265). Play test: sent one,
TestDayOffset 1, E at the kiosk ("Read your reply") -> the reply card, and no reminder toast over it for 7 s (r6b_reply_card_clear). Then
INSTALLED in Edit on Shannon's "Yes, install it", unpublished: stand (473.3, -12.0, -970.9) yaw 99, 3 studs clear; toss view clear; "QQ
BOTTLE DONE: workspace.Bottles (BottleServer 10292, BottleClient 19182, BottleText 11018 chars) ... the old folder is HudBackup.Bottles_pre_2".
Readback: BottleEvent, BottleText, Stand, BottleServer, BottleClient; TossSound 129669875728815; TestDayOffset 0. Told her: save, publish,
restart servers.

PUBLISHED (Shannon: "saves published and restarted"): bottle round 6b (f4239f9) - E at the kiosk by state, the reply toast fix. Servers
restarted. Nothing left unpublished in Edit.

PARKED IDEA (Shannon, Oct 16: "lets hold that off for a later time" - do NOT build yet): the Homebase is solo (drawn per screen), so
players can't show it off, and a visitor sees the owner floating above the dirt. Idea: when players are in the hollow together, every
screen draws the house of whoever there has built the most, the sign naming them ("Welcome to <name>'s Homebase Treehouse!"); their
own progress unchanged. Raise again only when she asks.
Result job 117 (Shannon, Oct 16, live after the restarted servers): "it started over, it looks fine" - the treehouse reset (ResetRound 3)
ran live. The earlier miss was most likely an old server still on the previous version. JOB 117 CLOSED. To reset again later: bump
workspace.Treehouse ResetRound (the reset runs once per round per listed id; ResetUserIds "9611145467").

NEW REQUEST (Shannon, Oct 16): rebuild Japan in a more realistic style, OUR OWN build styled after nine reference screenshots
she took in another Roblox game, combined with what we already have ("we will combine this with some of what we already have in our
current Japan map"); garden first, then the town street. Brief, her quotes, the read of the pictures and a survey of JapanMap:
tools/japan/reference_2026-10-16/BRIEF.md; pictures ref_01..09.webp there.
## Job 125: the Japan restyle (design; her choices first) - cloud thread
Shannon (Oct 16, via runner 7, brief tools/japan/reference_2026-10-16/BRIEF.md + ref_01..09): restyle Japan more realistically, OUR OWN
build styled after nine screenshots of another game, combined with what we have; "Both, garden first". The plan for her to choose from:
tools/japan/PLAN_japan_restyle_2026-10-16.md - KEEP (train, palace, Fuji/volcano, lake/horizon, balloon/taxi/gate, shop interiors,
squirrels), UPGRADE U1-U9 (Japan-only soft light via JapanAtmosphere; PBR ground variants; grass/hydrangea clump meshes; the canal's
taiko bridge; layered autumn maples + a black pine; then timber/plaster/roof tiles, paper-lantern strings, market tubs/crates, temple
details), NEW N1 the Momiji Garden around the existing canal + bridge (~6100, -215) and N2 Lantern Street machiya fronts / torii /
stairs / planters. First step after her picks: a 40 x 40 LOOK TEST near the bridge (light + materials + grass + one lantern + one
maple), previewed with pictures beside ref_01. Her questions: which items; the garden's site; grass as Japan-only meshes vs place-wide
terrain decoration; Meshy hero props (prompts on request). Phone budget: part count reported before/after each step (today 20,422).
Job 125 revision (Shannon, Oct 16): "I don't want it too realistic, on same par with the italy and france maps, just same elements as
in the photos". The plan is revised: the ELEMENTS from the pictures in our own style (Rue de Noisette / Porto finish, the game's normal
light, built-in materials with our colours); the Japan-only light grade (U1) and the photographic ground variants dropped; the look
test is compared with ref_01 AND with Rue de Noisette.
Job 125 answers (Shannon, Oct 16): no Meshy (the cloud thread builds the pieces from parts); the grass stays as is; "our current Japan
map is TERRIBLE and needs fixing" - all of it, garden first around the canal + red bridge. Next: a read-only survey of the canal area.

Result job 125 GARDEN SURVEY (runner 7, Studio EDIT, read-only): tools/japan/garden_survey_2026-10-16/SURVEY.md + g1..g4 + style_rue_de_noisette.
Shannon's rule (Oct 16): "the no was not to build anything using roblox parts" -> real meshes only (runner 7 models in Blender; generate_mesh
to try; Meshy last resort) - she said "yes, to all of that".
## Job 125 garden batch 1: Blender pieces + the look test (import, then a play-test PREVIEW; Edit on her word) - runner 7
Shannon (Oct 16): "the no was not to build anything using roblox parts" ... "if you build it has to be in blender"; meshes in the
France/Italy finish; grass unchanged. tools/japan/garden/gen_garden1.py (bpy; run here with bpy 5.2.2 - runs the same in her
Blender: blender -b --python gen_garden1.py, GARDEN_OUT=dir optional) -> tools/japan/garden/out1/: torii.fbx (304 tris), lantern.fbx
(220), bridge.fbx (taiko, 40 x 8.8, rise 5.5; ~1.7k), maple_a/maple_b.fbx (~1.1k each, faceted autumn clusters), pine.fbx (~600),
rocks.fbx (3 shapes, moss tops), slabs.fbx (3), waterfall.fbx (~700: rocks, moss, a curved water sheet, foam); every mesh named for
its colour; pieces.json (bounding boxes in Roblox axes); previews prev_lineup / bridge / torii_lantern / trees / waterfall .jpg.
IMPORT: each FBX via Studio's 3D Importer into ServerStorage.JapanGardenKit, one Model per file named after the file (torii,
lantern, bridge, maple_a, maple_b, pine, rocks, slabs, waterfall), mesh names kept. Then tools/japan/garden/garden_look1.lua
(make_garden_look1.py; 9218 bytes, compiles): places by bounding box (whatever the importer did to the pivot): the taiko bridge at
(6101, 0.3, -215) replacing LanternStreet's "Canal footbridge" there (-> HudBackup.MomijiGardenReplaced, with the flat "Vermilion
maple"s within 30), the waterfall over the weir (6101, 1.0, -222.5) facing north up the canal, a torii on the west path (6058, -215,
yaw 90), maples (6131, -236) and (6071, -238), a pine (6129, -202), four lit stone lanterns at the bridge ends, rocks at the falls'
foot, four stepping slabs from the east end toward the falls. Colours by mesh name, SmoothPlastic (Neon paper + PointLight, Glass
water DoubleSided), the deck and slabs PreciseConvexDecomposition. "QQ GARDEN DONE ... no parts built".
PREVIEW in play: walk over the bridge (does the arch walk? the ends meet the path?), pictures from the street side, from the bridge
toward the falls, from above, and one beside Rue de Noisette's trees for the style check; part / triangle counts before and after.

Result job 125 LOOK TEST 1 (runner 7): kit imported by Shannon (one combined FBX, the 9 merged in Blender) and moved to ServerStorage.JapanGardenKit
(9 Models, mesh names kept, 0 scripts). garden_look1.lua at 13739b1 (9218, adler32 989581473) in play: "QQ GARDEN replaced (to
HudBackup.MomijiGardenReplaced): 1 - Canal footbridge", "QQ GARDEN DONE: workspace.JapanMap.MomijiGarden - 17 pieces, 39 meshes; no parts
built". Her verdict: orange maples OUT ("the orange trees clash, not the green ones"); the other pieces good; the bridge misaligned (the old
approach steps stand 4.8-5.2 above the new deck ends; walking stuck at x 6118.7). Her notes on the waterway ("SERIOUS fixing"): the black
rocks = BlenderScenery."Sculpted terrain".JP_Canal_Rocks_84/_118 (Rock + JM_PhotographicRock, render black); the canal walkways float 0.8-2.7
and tilt; and "the edge of this waterway looks unfinished" (her screenshot shots_look1/her_unfinished_waterway_edge.webp - a small pool
with grey rocks in the water and a dark stone rim with a round hole on top; location to confirm). Pictures shots_look1/ (force-added).
## Job 125 garden batch 2: the WATERWAY + the KOI POND (import out2, then a play-test PREVIEW; Edit on her word) - runner 7
Shannon (Oct 16): "the waterway where the bridge is need SERIOUS fixing", "the edge of this waterway looks unfinished", "this walkway
is lifted right off the ground", orange maples OUT, and (via runner 7) "waterfall -> natural stream -> KOI POND, not to the sea",
"stepping stones and lanterns around it", rail / station / arrival court untouched; "I have a koi meshy made for the pond too".
Blender pieces (tools/japan/garden/gen_garden2.py + gen_garden2b.py, bpy 5.2.2 here; runs the same in her Blender) -> out2/:
canal_edge.fbx + canal_edge_b.fbx (one 8-long bank segment each, two block patterns: a mossy lawn lip flush with the lawn and two
stone courses down to -3.2), reeds.fbx (tall leaves + purple iris), pond_rim.fbx (a half-round stone rim, water face radius 12.5 = the
channel's width, 8-long tails meeting the edge segments, the lip filling the old channel's footprint behind it), stepstone.fbx
(Step1..3 flat-topped columns, top 0, down to -3.2), koi.fbx (Koi_Orange/White/Gold - the FALLBACK; her Meshy koi preferred),
lilies.fbx (pads + a pink lotus); pieces.json + pieces_2b.json; previews prev_canal*.jpg, prev_pond*.jpg.
IMPORT into ServerStorage.JapanGardenKit (as batch 1): Models canal_edge, canal_edge_b, reeds, pond_rim, stepstone, lilies, koi (mesh
names kept), AND Shannon's Meshy koi as a Model named "koi_meshy" (any mesh names; it is scaled to 2.4 long by the script).
tools/japan/garden/garden_look2.lua (make_garden_look2.py; compiles): 1. finds the canal from the two "Canal stone bank" parts;
2. TERRAIN: the water from 1.3 down to -0.6 (the -4..0 row at occupancy 0.35), the bed up to -3 all along (the -8..-4 row at 0.75,
Ground), rock above the water cut to -1.2, nothing wet under the old banks; 3. RETIRES -> HudBackup.MomijiGardenReplaced (attribute
GardenWasIn): both banks, JP_Canal_Rocks_*, the three "Canal footbridge"s (their z kept), the approach steps, the weir, bank supports
whose top is above the new water; the two "River end foundation closure" blocks LOWERED flush with the lawn (GardenOldCF); 4. the
canal's floating "Walkway" parts levelled flat, top 0.2 (GardenOldCF; the station's walkway at z 139 untouched); 5. PLACES meshes only:
a taiko bridge at each old crossing (y 0: deck ends at 0.3 on the lawn), the stone edge both sides alternating patterns, rocks and reed
clumps along it (none at the bridges), the waterfall at the south end, the torii / pine / four lanterns / slabs from look test 1 (NO
maples); 6. the KOI POND: rim at the channel's north end (centre line ZC = the last 8-multiple, apex ~Z2), seven stepping stones
across at ZC + 4 (tops -0.1), six koi swimming slow circles (KoiSwim Client script, attributes SwimCX/CZ/R/Y/Speed/Phase; Meshy koi
if "koi_meshy" is in the kit, else koi.fbx; MESHY_KOI_FACING at the top of the script if they swim backwards), three lanterns, three
lily clusters. Output "QQ GARDEN2 ... DONE ... no parts built".
PREVIEW in play: the bridge walkable end to end (the deck ends meet the lawn, no old steps), the water at -0.6 with the stone edge
meeting the lawn, the stream bed visible, the pond with its koi circling the right way round, the stepping stones walkable, pictures:
from the bridge down the stream, the pond from the lawn and from the stepping stones, one beside Rue de Noisette; part / triangle counts.

Result job 125 LOOK TEST 2 (runner 7, play test, stopped, nothing kept): kit2 (canal_edge, canal_edge_b, reeds, pond_rim, stepstone,
lilies, koi + her Meshy koi decimated 83,816 -> 1,500 tris, 512 texture) imported by Shannon as one combined FBX, in
ServerStorage.JapanGardenKit. garden_look2.lua at 20dbe24 aborted at line 334 (RF shadowed; fixed in 81a9f18, not re-run). Before the
abort: water to -0.6, bed -3, 10 retired, walkways levelled, 3 taiko bridges (both walk tests passed: up 5.3, down to 0.2 on the lawn),
the edge, rocks/reeds and the pond built; the koi swam BACKWARDS at identity (head +Z). SHANNON, watching live: "that does not look
promising; that moss on those rocks does not look like moss, those flowers are misaligned and look plastic and the water does not look
like water". Pictures shots_look2/. HOLD further garden_look2 runs until a new direction is agreed with her.
## Job 125 garden batch 3: the CANAL kept as a canal (import out3, then a play-test PREVIEW; Edit on her word) - runner 7
Shannon after look test 2 ("all in all it looks pretty bad, even worse than before" - the moss, reeds, lilies and pale water over a
grey bed failed; batch 2 is dropped): "actually, I like the look as a canal, how can we keep it as a canal?" Her brief via runner 7: a
proper Japanese town canal (Kyoto's Shirakawa, Tsuwano), the channel straight, same width, the water at 1.3 as now; stone-block walls
with a coping instead of the flat concrete slabs; stone steps down to the water by each bridge; the taiko bridges seated so their
ends meet the walkways (no white approach steps); the walkways flat on the ground; JP_Canal_Rocks retired and the end pool's terrain
rock cleared; "The waterfall feeds it"; "Yes, koi in the canal" (her Meshy koi, facing 180, swimming along it); "skiff in the water
too?"; torii / lanterns / pine / rocks / slabs where they fit; NO moss, reeds, lilies, pond rim; grass unchanged; meshes only.
Blender (tools/japan/garden/gen_garden3.py) -> out3/: canal_wall.fbx + canal_wall_b.fbx (8-long wall segments, the water face at x 0,
body to -4, stacked blocks both faces, coping 2.1 overhanging 0.3), canal_steps.fbx (five treads 1.85..0.85 out into the water, 4.5
long), bridge_steps.fbx (Steps_Landing: two steps rising 1.0 at a bridge end), skiff.fbx (a Yanagawa-style punt 14 long, origin at
the waterline, rails, thwarts, a pole); pieces.json; previews prev_canal_wall / prev_canal_steps / prev_skiff .jpg.
IMPORT into ServerStorage.JapanGardenKit (as before): Models canal_wall, canal_wall_b, canal_steps, bridge_steps, skiff (mesh names
kept); koi_meshy already there.
tools/japan/garden/garden_look3.lua (make_garden_look3.py; compiles): finds the canal from the two "Canal stone bank" parts; TERRAIN
only in the end pool (z Z1-2..Z1+16): rock above the bed cleared, the water filled flat to 1.3 up to the new end wall; RETIRES ->
HudBackup.MomijiGardenReplaced: both banks, JP_Canal_Rocks_*, the three "Canal footbridge"s, the approach steps, the weir; LEVELS the
canal's floating Walkways with their bottom at 0 (top 1.0; the station walkway untouched); PLACES: wall segments both sides alternating
(the last one pulled back to end at Z2) and four across each end (south at Z1+3.5 where the weir stood, north at Z2+1.5), a taiko bridge
at each crossing at y 0.7 (deck ends 1.0 = the walkway tops; the deck clears the coping by 0.36 at the wall's back), a landing-steps
piece at each bridge end, water steps on both walls 3.5 north of each bridge, the waterfall at (CX, 1.0, Z1+5) over the south end wall,
torii / pine / lanterns (4 at the garden bridge, 2 at each other) / four slabs as look 1, kit rocks at the walls' feet and by the falls,
5 koi swimming slow ovals in the reaches between bridges, a skiff moored by the garden bridge's west steps and one gliding along the
longest reach (CanalLife Client script: Life* attributes, nose along the way). Output "QQ GARDEN3 ... DONE ... no parts built".
PREVIEW in play: walk each bridge end to end (landings meet the walkways?), the walls from the lawn (1.7 of stone + coping above the
grass) and from the water, the stair into the water, the falls pouring in over the end wall, the koi head-first, the skiffs, pictures
from a bridge down the canal, from the lawn, one beside Rue de Noisette; part / triangle counts.
