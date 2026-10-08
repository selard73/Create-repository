# HANDOFF 2026-10-01 (12:30): cities round for 1001 Squirrels - travel, passport, map

## Starter prompt for the new chat
Please read C:\Users\slard\roblox-props\HANDOFF_2026-10-01_CITIES.md and the memory notes it points to (new-maps-travel-plan,
squirrel-speech-bubbles, ask-before-studio-edits, chasing-rainbows-squirrels standing rules). We are building the "cities" round of
1001 Squirrels (Roblox Studio is open on the live place, Team Create, API access OFF). Build in this order, one Studio step at a time:
(3) travel between cities from any spawn-in point, (4) the passport's new activities and per-city sub-tabs, (2) the Map rewrite. Item (1),
the jetty warnings, is already in the place as boat scripts v40 but NOT published. Publish only on her word.

## Where things stand
- LIVE = v829 (published Oct 1 10:54): the whole falls / going-over / parachute / bubble / river-drift round. Memory
  new-maps-travel-plan.md "PUBLISHED v829" lists it.
- In the shared place, NOT published: boat scripts v40 (tools/boat/install_boat_i6.lua, built by tools/boat/build_install.py from
  BoatServer.server.v2.lua + BoatClient.client.v2.lua). v40 = the jetty warnings for players with all 44 and no parachute, her words:
  hold 1 "Wait! Stop! You might want to talk to Sky Diving Squirrel before you go.", hold 2 "So hard headed! Sure you don't want to talk
  to Sky Dive first?", hold 3 "Don't say I didn't warn you.", hold 4 sails (the count forgets after 60 s). The jetty prompt reads
  "Bateau - see the Sky Diving Squirrel first / Take the boat (no parachute!)" until HasChute. Verified in play Oct 1 12:28.
- The Studio-only ZZ_TEST_Give44 script is REMOVED (tools/boat/remove_give44.lua). For her own tests re-add it with
  tools/boat/install_give44.lua and remove it again before any publish.

## Her decisions for this round (Oct 1 12:1x)
- Travel back to France lands in the LAST French section the player was in (not the forest start).
- The Porto Nocciola Clues sub-tab says "coming soon" until Italian squirrels / a daily Italian question exist.
- The Map: she asked which is more elegant with 20 cities coming - a draggable Google-Maps-style mega map, or one map that shows the
  city you are in. My recommendation (sent 12:30): one hand-drawn chart PER CITY (the current parchment look), plus a small "world"
  overview (a sketched coastline with a pin per opened city) to switch charts; a mega map would shrink everything and crawl on phones.
  WAIT for her choice before drawing. The current chart: image rbxassetid://127000767898563, 1024x560, world rect x -130..700,
  z -250..30 (boundary/build_hudbar.lua lines 206-216: IMG_W/H/M, DISP_W 560, WX0..WZ1, toMap()); boundary/map_01_parchment.png is a
  screenshot of the panel. AREAS tables (forest/village/domaine with x/z rects and needs) live in HudBarUI.HudBarClient,
  HudBar.PatchModule, and passport/build_passport.lua (lines ~4363, ~4721); the Boundary areas in Boundary.PatchModule (~317).

## Facts gathered for the build (tools/plan_probe1.lua, Oct 1 11:57)
- Squirrel Registry (workspace.SquirrelScripts.SquirrelRegistry): maps forest / village / domaine (15 / 14 / 15 = 44). Porto Nocciola
  has no squirrels yet (her plan doc: Harbour Front 17 first; 3 areas, 50 total). Do not add a map entry until squirrels exist.
- Spawns: workspace.Spawn_forest (3,2,1), Spawn_village (196,2,-36), Spawn_domaine (438,4,-36) (SpawnLocations). SpawnReturn
  (Workspace.SpawnReturn.SpawnReturnServer, 81 lines): ORDER {forest, village, domaine}, picks by the player attribute Area /
  SavedArea capped by the found-count gates; SquirrelSetup saves data.area as SavedArea. Italy needs: a Spawn_porto at the landing
  beach (the dry-landing shore east of the plunge pool, around x 215..235, z -575..-600, grass 3-6 studs above the water; sand edge)
  and a SpawnReturn rule: Area == "porto" and the player has reached Italy -> Spawn_porto.
- Persistence without touching the DataStore: fire ReplicatedStorage.AwardItems (BindableEvent) with (player, "porto", 1) once the
  player lands at Porto Nocciola; it becomes the saved attribute Item_porto (SquirrelSetup owns the key). "Opened" = Item_porto >= 1.
- Travel boards: a ProximityPrompt sign at each of the three French spawn daises ("Travel to Porto Nocciola", shown only when
  Item_porto >= 1) and one at Spawn_porto ("Travel to French Squirrel Country" -> the last French section: the player attribute
  Area if it is forest/village/domaine, else SavedArea, else forest). Teleport = server PivotTo to the spawn + set Area; a short fade
  on the client. Keep NoMusic rules in mind (music is off after the boat; decide whether travel back turns it on - probably yes:
  clear NoMusic on arrival in France).
- Passport: passport/build_passport.lua installs Workspace.Passport (PassportServer 167 lines, PassportClient 276 lines, Journal
  module 188 lines). Outings are DATA entries {id, name, area, icon, hint, detail} (build_passport.lua ~8655-8662: find, riddle,
  rescue, race, hoop in forest; book, coffee, cheese in village; ...). PassportClient tabs: Outings / Completed / Clues / Wardrobe
  (line 44; names list at 228); rows via addRow; the Journal lists outings per area from registry.maps and composes descriptions by
  id (Journal 137-166). PassportServer fires activities from ReplicatedStorage.PassportActivity (ids "find", "keeper", "gold",
  "race", "bubbles", ...) and from character attributes {Riding = "zipline", Gliding = "glider"} (line 110). New activities to add:
  "boat" (took the boat), "falls" (went over the falls), "chute" (parachuted down), "porto" (arrived at Porto Nocciola), fired from
  BoatServer (take / startFall / attachChute / the landed event). Sub-tabs: a row under Outings / Completed / Clues with
  "French Squirrel Country" | "Porto Nocciola", shown only when Item_porto >= 1; areas forest/village/domaine group under France,
  area "porto" under Italy; the Italian Clues sub-tab = "coming soon". Update the local builder too (keep Codex's work).
- Boat scripts: tools/boat/BoatServer.server.v2.lua (559 lines) / BoatClient.client.v2.lua (351) - the going-over, the pack
  (attachPack), the chute (attachChute + poseRider through the RIG ATTACHMENTS: characters use AnimationConstraint joints, C0 is read
  only), the eject, the landing ("landed" event -> a good place to award "porto"), the wreckage, the notes (toast 72 px from the top).
- Speech: every squirrel speaks through ReplicatedStorage.SquirrelBubble (tools/bubble/). Never a toast for a squirrel.
- South build: only SouthGorge (Rock, Aqueduct, Trees, LipRocks, RapidsRocks, Falls, FallsB) + the plunge pool / cove terrain. No
  harbour town yet (her plan: Porto Nocciola harbour quay/town, Italian planting, extend the sea, a sea return by the Captain later).

## Studio driving (what works)
- tools\setclip.ps1 -Path <lua> (saves her clipboard to tools\clipboard_saves, restores: restoreclip_image.ps1 for images,
  Set-Clipboard for text) then tools\studio_front.ps1. Paste: click the command bar, ctrl+a, Delete, ctrl+v, ctrl+Home; verify line 1
  with a zoom; click Run. THE PANEL LAYOUT MOVES after every Play/Stop: take a 0.5 screenshot first; the Run button is at the right
  end of the command bar's first line (seen at y 640, 644, 667, 675, 681, 700 today). Output lines end with "- Edit" / "- Client" /
  "- Server": check which DataModel ran your script (an install that says Client ran inside a play session and is lost on Stop).
- Play = (166,129); Stop = click the command bar then shift+F5; Client / Server tabs (326,196) / (380,196); the Daily Acorns card on
  join: Collect at (828,383). Logs: %LOCALAPPDATA%\Roblox\logs\*Studio*.log, grep "QQ ".
- Bash heredocs: apostrophes break the tool, and BACKSLASHES ARE EATEN ("\n" in Python/Lua text becomes a newline) - write files
  with the Write tool or avoid backslashes (string.char(10)). Pastes sometimes pick up a stray first character: re-paste.
- A Scriptable camera set before ProximityPrompt:InputHoldBegin() stops the prompt from firing: teleport, hold, THEN move the camera.
- Images into the game: a textured quad OBJ + MTL imported with Import 3D (button (651,165), file field (512,458), Import (955,683))
  uploads the image; read MeshPart.TextureID, then delete the carrier (tools/boat/bubble_tex_probe.lua pattern).
- Test helpers (play, Client tab): tools/boat/bt_full3_cli.lua (squirrel -> jetty -> brink, then hold W), bt_jetty_take_cli.lua,
  bt_v22b_cli.lua (bubble frames), river_look_cli.lua; Server tab: pose_test2_srv.lua, champion_test_srv.lua.

## Standing rules (unchanged)
Never write her DataStore; API access stays OFF; publish only on her word (click the viewport + Alt+P, then read "Published new
changes ... v<N>" in the Output); ask before new builds, just fix what she flags; phones: nothing may overlap; keep Codex's work;
pictures go on the artifact page https://claude.ai/artifact/G6ndq3Srm1yUcRrSTcvGy8 (she cannot see SendUserFile images); restore her
clipboard and her editor camera (tools/cam_restore_shannon4.lua) when done.
