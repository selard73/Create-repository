# Jobs 7, 8 and 9, in this order. Ask Shannon before each Studio edit; send each result to the cloud session
# "GitHub free credit eligibility" as ONE message per job (every Output line with the job's QQ tag, unchanged).

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
