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
