# 1001 Squirrels: handoff (Sep 30, 2026, ~00:40 EDT). Next up: the motorboat

## Where things stand
- **The game:** "1001 Squirrels" on Roblox, owned by Shannon.
  - Her account: Roblox user `oodlesofpoodlesyay`, display name **SelBell**, user id 9611145467.
  - IDs: place `117372258657114`, universe `10766369535`.
  - Team Create is on, and Drafts Mode is OFF, so script edits go straight into the shared place.
- **Live version: v726**, published Sep 30 at 03:52 UTC (11:52 PM EDT Sep 29). **Nothing is waiting to be published.**
  - "Enable Studio Access to API Services" is OFF; it was checked on reopening the dialog.
- **The river is DONE.**
  - Built Sep 29 and published as v723, then v726 with fixes.
  - The full story, every script and the terrain lessons are in `HANDOFF_2026-09-29_RIVER.md` (the sections BUILT, Round 2-5, PUBLISHED, and the forest quay).

### River facts the boat needs
- **Water:** Terrain water, surface at **y -0.9**, about 6 studs deep in the middle. The current flows **north to south**, that is, toward -z.
- **`workspace.River` (a Folder):**
  - Attributes: `Line` = "x,z,halfWidth;..." in downstream order from z 80 to -300, `WaterY` = -0.9, `FlowSpeed` 2.6, `PushSpeed` 4, `PushAccel` 14.
  - Children:
    - `Quay`: the Rue-side wall face at x 163.9 for z -171..-69, plus the forest-side parts WallW/KerbW/KerbSkirtW/CapW at x ~142.6-144.5, z -132..-108.
    - `FishRocks`.
- **`StarterPlayerScripts.RiverCurrent` (LocalScript):** drifting leaves and streaks, plus the swimmer push. It pushes only swimming humanoids; a boat will need its own gentle drift.
- **The bridge** (`Village.Props.bridge`):
  - It sits at x 141..171. The deck is z -124.0..-116.0 (measured).
  - **Clearance is only ~2.9 studs above the water at the centre (measured), so a boat can NEVER pass under it.**
- **The south stretch** (the boat's water):
  - From the bridge (z -116) south to the village rim wall at **z -205** (invisible boundary walls), about 85 studs long.
  - Water is roughly x 147..164 near the bridge, then bends east (x ~152..169 at z -206).
  - The Rue quay's east wall runs along the plots down to z -171; beyond that the natural bank curves out.
  - The west bank is the forest, with the lagoon (swamp) just west at x 89-139, z -208..-152.
  - Things on the east quay near the bridge: the Daily Question board at (168.2, -135.5) and the spy squirrel at (166.6, -114.5), both on the sidewalk and street.

## THE BOAT: what Shannon decided (Sep 29-30)
- **What it is:** a simple motorboat you **sit in to start and steer**.
  - Phones: the default VehicleSeat thumbstick. Computers: WASD.
  - Gentle speed, bob on the water, never tips over, can't leave the river.
  - Engine sound, a small wake, and the current nudges it downstream when idle.
- **The dock:** on the **Rue stone quay just SOUTH (downstream) of the bridge** (Shannon: "choice 1 definitely, south of the bridge").
  - It becomes a small wooden jetty coming off the quay wall (x 163.9), somewhere around z -135..-165.
  - Keep it clear of the Daily Question board and the bridge. Mooring posts would be nice.
  - Boats drive the south stretch only. Buoys, or an invisible stop, keep them away from the bridge (z > -126) and inside the map.
  - Later, the Italy trip leaves this way: through a future gorge at the south edge.
- **Locked until the player has found all 44 squirrels.** Before that, the jetty shows a friendly note like "Find all 44 squirrels to take the boat out".
  - Check how the game counts all 44. The Passport HUD shows "0/44"; there are `Found_<map>` player attributes such as `Found_forest` and `Found_village`, with totals in `workspace.SquirrelScripts.SquirrelRegistry`. Read those live scripts (read-only) first.
- **The model:** Shannon made it in Meshy, and she **approved** the second one.
  - `C:\Users\slard\roblox-props\boat\meshy_v2\Meshy_AI_cute_cartoon_motorboa_0930042613_image-to-3d-texture_fbx\` (`.fbx` + a 4096 `.png` texture).
  - Look: cream hull, sky-blue stripe, honey-wood rim, floor and bench, red outboard with a tiller, no logo.
  - It is **273,172 triangles**. Size in Meshy units 1.903 × 0.984 × 0.653 (L × W × H).
  - Preview renders: `boat\meshy_v2\views\` (made by `boat\inspect_boat.py`).
  - The first attempt, `meshy_v1`, was black/grey with a brand logo on the motor. REJECTED: do not use it.
- **Model to-do:**
  1. Decimate to ~8k triangles, keeping the look, and reduce the texture to 1024.
  2. Scale to ~8 studs long × ~4 wide, set it facing forward, bottom at the waterline.
  3. Export FBX, then Import 3D in Studio.
  4. Add an invisible simple hull part for physics, a VehicleSeat on the bench, and a motor/wake attachment.
  5. **Render a preview for Shannon before importing** (low angles, backface culling on).

## Suggested build steps (confirm with Shannon as you go)
1. **Read-only first:** how the game counts found squirrels (for the 44 lock); where the jetty fits on the quay between z -126 and -171 (measure what stands there); and that the water at the dock is deep enough.
2. **Model:** prepare it in Blender, preview it, then import.
3. **Jetty:** wooden planks and posts off the quay wall. It must be solid underfoot with no floating parts, so raycast every post down to the bed. Match the quay and bridge look.
4. **Driving script:**
   - Server spawns one boat per player at the dock on request (a prompt on the jetty), with a cap.
   - Movement: VehicleSeat Throttle/Steer drives a LinearVelocity + AlignOrientation (or a similar scripted float), held at WaterY with a gentle bob.
   - It is clamped to the river corridor using `workspace.River.Line` (half widths), and to z < -127 and z > -203.
   - The boat despawns when the player leaves it, or after a while.
   - Engine sound and a wake: ParticleEmitter or a few fading parts. No pulsing UI.
5. **The 44 lock:** the prompt shows the note until the player has found all 44.
6. **Play test with API access OFF:**
   - Open the gates, and fake 44 finds only in the Play copy.
   - Drive it: steering, the bridge stop, the rim stop, the quay walls, and phone controls (Device Simulator; nothing may overlap on the phone UI).
7. **Show Shannon, then publish only on her word.**

## Studio workflow that works
- **Getting control:**
  - Computer-use: `request_access(["Roblox Studio"])`. Studio sits on display **"XV270 X1 (2)"**; use `switch_display` to get there.
  - Shannon plays on this PC. **Take a screenshot first**, and make sure Studio is in front and in Edit mode (the Stop button greyed) before clicking. She often Play-tests between messages.
  - **Don't use `open_application("Roblox Studio")`**: it opened an old local "saved file.rbxl" once. If Studio is minimized, restore it with PowerShell: `ShowWindow(MainWindowHandle, 9)` + `SetForegroundWindow` on the `RobloxStudioBeta` process.
- **Command bar:**
  1. Run `powershell -File tools/setclip.ps1 -Path <script>`. It keeps her clipboard first; her clipboard is often an IMAGE (her screenshots), saved as `tools/clipboard_saves/shannon_clipboard_<stamp>.png`.
  2. Maximize Studio (double-click the title bar at y 88 when windowed). The command bar is at about (800,700), and **Run is at (1416,648)** with a multi-line script. It moves with the text, so zoom in and check line 1's `-- vN` tag first.
  - Studio sometimes overwrites the clipboard. If line 1 shows an old script, `Set-Clipboard` it again.
  3. At the end: restore the editor camera (`tools/river/cam_restore.lua`), un-maximize the window (double-click at y 8), and restore her clipboard. For an image, use `powershell -STA` with `[System.Windows.Forms.Clipboard]::SetImage([System.Drawing.Image]::FromFile(png))`.
- **Output:** print lines starting with `QQ` and read them from the newest `%LOCALAPPDATA%\Roblox\logs\*Studio*.log`. `task.wait` works in the command bar; I use it for camera tours, taking zoom shots in between.
- **Play tests:**
  - The Play button is at (86,46) and Stop at (142,46) when maximized. The Client/Server tabs are at (240,112)/(306,112).
  - To open the gates, set `Found_forest`/`Found_village` = 15 on the test player (server).
  - The river swim test scripts `tools/river/t21_swim_srv.lua` and `t22_watch_cli.lua` show the pattern.
- **Publishing** (only on Shannon's word):
  1. Maximized: File (13,25) > Experience Settings (56,347) > Security (400,257). Toggle API at (705,386), then Save (1017,601).
  2. File > Publish to Roblox (56,267). The Output says "Published"/"Place published" and shows the version.
  3. Toggle API OFF, Save, then reopen the dialog to check it stayed OFF. Close it with Cancel (903,601).
- **Blender:**
  - `C:\Users\slard\AppData\Local\Microsoft\WindowsApps\blender-launcher.exe --background --python X.py -- args`.
  - Stdout is NOT captured (the launcher detaches), so write results to files and sleep ~25-30 s before reading them.
- **Workspace quirks:** `workspace.Boundary` resolves to a different folder than the one that holds `Gates`/`Walls`, so find those by name (`d.Parent.Name == "Gates"`).

## Terrain and building lessons (from the river, apply to anything near the water)
- **Surface height:** a solid terrain surface draws at **cell centre + 4 × occupancy**. It smooths each 4-stud cell with its neighbours, so write → raycast → correct → repeat. Liquid is linear.
- **Pebble is NOT a terrain material:** it is silently stored as Grass.
- **Undersides:** a MeshPart's mesh does not fill its box. Find the real underside by raycasting up into the part, and ground by raycasting down.
- **Shannon checks every close-up:**
  - things floating or sunk;
  - seams between two ground textures (the whole map's ground is now terrain grass at y 0.08);
  - white kerbs that stop short;
  - grass poking through paving;
  - things you can walk through that look solid (the Rue sign was one: CanCollide);
  - gaps under paving.
  Check all of these before showing her anything.

## Standing rules
- **Save data:** never write to Shannon's real save data. API access stays OFF in Play tests.
- **Publish only** when she says so.
- **Ideas first:** give honest feedback on an idea before building it.
- **Keep Codex's work.** The old builders in `roblox-props` (village, glider, hat shop, portraits…) are out of date: never rerun them.
- **Phones:** nothing may overlap. No pulsing animations.
- **Credits:** she's watching usage. Keep steps lean, and save notes at natural stopping points.

## Starter prompt for the new chat
> Please read C:\Users\slard\roblox-props\HANDOFF_2026-09-30_BOAT.md and start the motorboat: first prepare the Meshy model and show me a preview, and check (read-only) how the game counts all 44 squirrels and where the jetty fits south of the bridge.

## PROGRESS Sep 30 (morning chat)
- MODEL DONE (not imported yet): boat/prep_boat.py -> boat/prep_v2/boat.blend (8k tris, 1024 tex, 8 x 4.14 x 2.74 studs, bow -Y, motor +Y, keel z 0, floor z 0.9, bench top z ~1.4 at y ~0, gunwale ~1.9).
  Shannon picked ARMY GREEN outer hull (her idea: one colour outside, keep wood + white inside). boat/recolor_boat.py repaints per FACE (owner map, not per texel).
  Final files: boat/recolor/boat_army.fbx + boat_tex_army.png (renders army_low/high.png). Two hairline white specks low on the hull remain; check in Studio.
- 44 COUNT (read-only): SquirrelSetup sets player attrs Found_<map.id> for every Registry.maps entry; SquirrelScripts attrs AllTotal (= #Registry.squirrels = 44), MapTotal, Total.
  Honours tier 3 = all 44 (HonourTier attr). Lock idea: sum Found_forest+Found_village+Found_domaine >= 44 (fixed to these three maps, so Italy/Japan squirrels added later never re-lock the boat) - confirm with Shannon.
- JETTY SPOT (measured): water x ~146..164.5, 7 deep mid-channel, 2-3 at the quay wall. Quay kerb top y 0.75 (River.Quay.Kerb), plot ground y 0.50.
  Sidewalk hedges at x 168.9, z -143.4/-149.8/-156.2/-162.6; Daily Question board (168.2,-135.6). Quay wall face ends z -171.
  PROPOSAL shown (boat/jetty_plan.png): deck along the wall x 160.4..163.9, z -146..-168, step from the sidewalk at z -165..-169.5 (south of the last hedge); boat moors west of it; stop line z -127.
  Nothing overhead but a plane-tree canopy (26+ studs). Terrain water also sits hidden under the east street (x 167-176) - harmless, noted.
- Tools: tools/boat/*.lua (probes b1-b5, all read-only). Her editor camera = tools/river/cam_restore.lua values (unchanged). Run button sits lower for short scripts (y ~658).
- JETTY BUILT Sep 30 ~08:19 EDT (Shannon approved; NOT published): tools/boat/build_jetty.lua (j1) -> workspace.River.Jetty (Built attr "j1 2026-09-30").
  Deck x 160.1..163.6, z -146..-168, top y 0.6 (kerb 0.775); 22 planks; 3 stringers; 5 post pairs (outer x 160.3 = mooring posts to y 1.45, rope rings on 2nd+4th; inner x 163.3), beds -6.5..-2.3;
  "BATEAUX" sign at (162.6, -167.3) facing the street. Close-ups: boat/jetty_closeups.png. Undo = delete River.Jetty.
- NEW RULE (Shannon, Sep 30): ask her before EVERY edit to the place; read-only probes and camera moves are fine.
- BOAT IMPORTED Sep 30 ~08:22 EDT (Shannon approved; NOT published): Import 3D of boat/recolor/boat_army.fbx (uploaded to her account: mesh + texture).
  Still preview = workspace.River.BoatPreview (Model, MeshPart "Boat" 4.14 x 2.74 x 8, anchored), at (157.6, keel -1.45, -157), bow +z (upstream), motor south.
  Import orientation: long axis came in along z; needed a 180 turn (p2) for the bow to face +z. Scale dummy was temporary and deleted. Close-ups: boat/boat_preview_closeups.png.
  In-game the wood rim reads mustard-yellow next to the jetty's honey wood (offered Shannon a darker wood tone).
- MOORED Sep 30 ~08:33 EDT (Shannon approved; NOT published): tools/boat/moor_p3.lua (p3). Shannon wants the boat pointing DOWNSTREAM (-z, the way players drive).
  Boat CFrame = CFrame.new(157.6, -1.45 + 2.74/2, -166.5) with IDENTITY rotation = bow -z, motor north at z ~-162.5; bow just past the deck end (-168).
  Ropes: 4-segment sagging Fabric cylinders named "MooringRope" inside River.BoatPreview: bow line -> post z -167.65, stern line -> post z -162.55. Last post got two rope rings (Jetty "Rope").
  Shannon likes the bright mustard trim as is (no recolour). Close-ups: boat/boat_moored_closeups.png.
- DRIVABLE BOAT INSTALLED Sep 30 ~08:51 EDT (Shannon approved; NOT published): installer tools/boat/install_boat_i3.lua (generated from BoatServer.server.lua + BoatClient.client.lua by a small python step; see gi*.py pattern).
  workspace.Boat (Built "i3"): BoatServer (Script, Server), BoatClient (Script, Client), BoatEvent. Prompt "BoatPrompt" in River.BoatPreview.Boat.PromptSpot (hold 0.35, dist 8, like the zipline; PromptUI restyles it).
  Lock = Found_forest+Found_village+Found_domaine >= 44. Spawns a separate boat on the water (slots x ~151, z -157.5/-147.5/-137.5/-178/-189), max 6; jump out -> back on the jetty at (161.9, 3.6, -164.5), boat destroyed.
  Driving (client, driver owns physics): LinearVelocity + AlignOrientation, max 13 fwd / 4.5 back, current 1.1, bob; kept inside River.Line (halfWidth - 2 - 1.3), z -129..-202.6, and out of the jetty/moored-boat boxes.
  Bugs fixed during tests: (1) seating from the jetty dragged the boat onto the jetty -> PivotTo the player into the seat first; (2) streaming: prompt looked up lazily;
  (3) Baseplate is a UnionOperation (channel cut to y -12) whose rough collision snagged the hull -> collision group "Boats" (collides only with Boats; driver's parts join it while seated, restored after).
  PLAY TEST PASSED (API off): locked note, prompt "Needs all 44 squirrels (30/44)", take, forward, turn, south stop, bridge stop, pass moored boat, wake, jump out. No script errors.
  NOT DONE: engine sound (no built-in engine sound; needs a Creator Store audio or an upload - ask Shannon), phone test in Device Simulator.
  Known small thing: the prompt pill keeps its old text while it is on screen (PromptUI caches); it refreshes next time it shows.
- FITTINGS Sep 30 ~09:05 EDT (Shannon approved): tools/boat/fittings_m2.lua -> River.BoatPreview.Fittings (BowPlate, BowEye, 12 BowRing segments on the bow post's jetty side at mesh-local (0.757, 0.64, -3.78), r 0.17; CleatBase + CleatBar on the stern-corner rim at (1.48, 0.552, 2.72)).
  Ropes re-aimed: bow line through the ring bottom with a short tail; stern line to the cleat + 2 figure-of-eight turns. Installer i4: BoatServer copies Fittings onto every driven boat (checked in play: same local spot).
  Blender->Roblox mesh-local: X = -blender x, Y = blender z - 1.37, Z = blender y (bow -Z). measure_fit.py/fit_measure.txt hold the rim/post numbers.
- ROPE/KNOT Sep 30 ~09:15 EDT: tools/boat/fittings_m6.lua is CURRENT (Shannon: "the rope looks fine"). Small bow ring (r 0.075, 16 segs), round turn + two half hitches (smooth cylinder coils), 0.08 rope on both lines,
  bow line = one smooth Bezier curve out past the bow and back to the post (a straight line cut through the rim; a 2-point route made a V kink - both her close-ups). Stern cleat unchanged.
  Driven boats copy River.BoatPreview.Fittings at spawn, so no reinstall was needed for the smaller ring. (An m7 "slimmer knot" was written and deleted unrun.)
  Her editor camera is still on my close-up view: restore with tools/river/cam_restore.lua when she's not using Studio.
- RING MOVED Sep 30 ~09:19 EDT (Shannon: "too far up... should be flush to the top of the side"): tools/boat/fittings_m8.lua is now CURRENT.
  Bow ring on the hull SIDE at mesh-local (1.23, 0.505, -3.0), facing the side's normal (0.82, 0, -0.57); plate top = top of the side (0.578). Rope curve control point (2.2, 0.3, -2.7).
  Knot + rope unchanged from m6 (she said the rope looks fine). Camera + her clipboard restored. Sheet: boat/boat_ring_side.png.
- RING MOVED AGAIN ~09:20 EDT to the spot Shannon circled (nearer the bow post): tools/boat/fittings_m9.lua is CURRENT. Side point mesh-local (0.81, 0.54, -3.4), normal (0.65, 0, -0.76); rope control (2.1, 0.3, -3.0).
  (Its Built attribute still reads "m8 ..." - cosmetic.) Camera + clipboard restored. Picture: boat/boat_ring_m9.jpg.
- RING LOWERED ~09:22 EDT: tools/boat/fittings_m10.lua is CURRENT. Side-on check (t8) showed m9's plate + ring stood ABOVE the top of the side (Shannon was right; the Blender "top" overstated it).
  Now plate centre mesh-local y 0.50 (world top ~0.49), ring centre 0.03 below the plate's middle so it never rises above the plate. Verify fittings with a DEAD-LEVEL side-on camera, not from above.
  Picture: boat/boat_ring_m10_sideon.jpg. Camera + clipboard restored.
- RING AT HER CIRCLE ~09:40 EDT: tools/boat/fittings_m12.lua is CURRENT. Placed by casting a ray from the same side-on camera she circled on (525 px right / 75 px down at ~1040 px/stud) onto the hull:
  hit world (157.997, 0.389, -170.206), normal (0.63, -0.18, -0.76); plate lies flat on the flared side (full normal), ring hangs 0.03 below the plate middle. Sheet: boat/boat_ring_m12.png.
  Lesson: when she circles a spot on a screenshot, map it through the SAME camera (ray onto the mesh) instead of guessing from Blender numbers.
- STERN REDONE ~09:48 EDT (Shannon approved): tools/boat/fittings_m14.lua is CURRENT (bow as m12).
  Horn cleat on the flat top of the side rim at mesh-local (1.66, 0.53, 2.2), lengthwise along the rim (tangent (-0.175,0,1)): 2 feet, bar, 2 horns + ball tips (Fittings: CleatFoot/CleatBar/CleatHorn/CleatTip; driven boats copy them).
  Cleat hitch from 0.06 rope: oval turn under the horns, figure-of-eight arcs over the bar, locking turn on the bow-side horn, tail forward along the rim. Stern line = smooth curve from the post.
  Sheet: boat/boat_stern_new.png. Camera + her clipboard (text) restored.
- ENGINE SOUND candidate (Shannon's pick): 15067494918 "driving" by DEUTZFAHRISDABEST, audio, public domain, desc "Perkins CV12-6A diesel" (a big tank diesel).
  Loads fine for this game in a play test (client): 4.97 s, loops. Not built in yet - proposed: Sound on the driven hull, server sets Volume/PlaybackSpeed from speed; pitch up so it sounds like a small outboard.
- ENGINE SOUND IN ~10:05 EDT (Shannon approved; NOT published): installer i5. Sound "Engine" (15067494918) on each driven hull, looped, InverseTapered 8..80 studs.
  BoatServer ENGINE = {vol0 0.22, vol1 0.5, pitch0 1.5, pitch1 2.0, top 13}; the 0.2 s loop eases volume/pitch toward the speed target. Play test: IsPlaying/IsLoaded true, 0.24/1.54 idle -> 0.38/1.78 at ~9 studs/s.
  I can't hear audio: Shannon to judge pitch/volume. Next: her listen + tweak, phone test (Device Simulator), then publish only on her word.
- PHONE TEST PASSED ~10:12 EDT (Test > Device Simulator, iPhone 7 666x374; API off, test copy only): locked note + steering note both 103,200-563,256, 0 overlaps (tools/boat/ph1_cli.lua);
  prompt pill fine; thumbstick drives + steers; jump button (a held press) gets you out onto the jetty. Device Simulator switched back off. Sheet: boat/boat_phone_test.png.
  Remaining: Shannon listens to the engine (15067494918, pitch 1.5-2.0) and tries it; publish only on her word.
- PUBLISHED Sep 30 ~10:18 EDT on Shannon's word ("go ahead and publish it"): v744. API access ON for the publish, then OFF, saved, reopened and checked OFF.
