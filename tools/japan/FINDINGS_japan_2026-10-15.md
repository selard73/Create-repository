# Japan map - adversarial survey, Oct 15 2026 (job 104; nothing changed in Studio)

Shannon: "codex made a 3rd map for Japan and I wanted you to do an adversarial survey of it to find things wrong so we can fix them."
Sources: survey104 (82 lines, Edit v1369, tools/japan/survey104_result_2026-10-15.txt), runner 7's first look, the 21 exported scripts
(tools/japan/studio_2026-10-15/, every one checksummed against Studio), two adversarial code reviews. Ranked: what touches every
player in the live game first, then the map itself, then the work list before Japan can open.

## What Japan is today

A PRIVATE PREVIEW locked to one account (your user id 9611145467, "SelBell"): workspace.JapanMap (23,074 instances, 20,373 parts,
x 5200..7100 / z -1270..450, a sculpted Fuji to y 320), with three districts (Tea Hills, Lantern Street, Palace Grounds), a Shinkansen
between three stations (you ride inside the cabin, first person), an outdoor market with ramen / yakitori / mochi stalls and
auto-seating, a cat cafe, a sushi bar, a kimono shop, a Kyoto palace, a rumbling volcano, groves and a lake. Every OTHER player has it
hidden on their own screen (JapanPreviewVisibility makes every part, decal, light, sound and prompt of it invisible / silent) and a
server guard (JapanPreviewGuard, five times a second) teleports anyone else who gets inside its box back to their spawn pad. The only
ways in are yours: your balloon (its prompt now reads "Fly to Japan" and the whole ride became the Japan transfer) and an "Airport
taxi / Travel to Japan" sign that Codex planted in the CHATEAU GROUNDS at (445, 7, -44), ten studs from the Spawn_domaine pad; the
way back is the "Airport taxi / Return to Provence" prompt at the Japan arrivals board. No squirrels, no spawn pad, no Travel entry,
no Area id, no music of its own in the live scripts - it is scenery with a train.

## A. What touches every player now (fix before the next publish, whatever happens to Japan)

@@A1@@

A2. THE BALLOON (Codex patched the live BalloonServer and BalloonClient; the ordinary ride was checked on both exit paths - completed
and cut short - and still ends exactly as before: home, jump restored, "home" broadcast, prompt back, balloon_flights awarded; no
regression for other riders). What is wrong:
- YOUR SESSION STAYS CHANGED AFTER A JAPAN FLIGHT. The reveal tweens Lighting's fog to "off" (FogEnd 100000), the Atmosphere to
  density .08 / haze 0 and the CLOUDS to cover .08 / density .1 / white, and nothing ever puts them back: JapanAtmosphere only saves
  the Lighting values once you are inside Japan's box, which the server allows only AFTER the reveal has finished, so it saves the
  already-changed values and "restores" those when you leave; nothing touches the Clouds at all. So after one trip to Japan your
  France and your Porto have no fog, thin white clouds (the look pass set 0.6 / 0.4) and a flat atmosphere until you rejoin - and the
  next balloon storm snapshots those wrong values too. This is very likely why the game looks different to you than to players.
  (BalloonClient revealJapan; fix: save FogEnd/FogStart/Atmosphere/Clouds before the reveal and tween them back on previewLanded,
  "home" and respawn - or let JapanAtmosphere own the values by clearing JapanPreviewInFlight before the reveal; the Clouds need a
  restore of their own either way.)
- THE SAFETY NET IS GONE. The old server had a PlayerRemoving handler that freed the balloon (busy nil, prompt on, basket home) if a
  rider vanished; Codex removed it, and the end-of-flight tail now runs outside the error guard. Any throw there - e.g. the owner
  leaving at the moment of touchdown, when the tail fires an event at a departed player - leaves `busy` set and the prompt off for
  EVERY player until the server restarts. (Fix: free busy / prompt at the top of the tail, pcall the tail, put the handler back.)
- ONE MODULE CAN TAKE THE BALLOON DOWN. BalloonServer (and SpawnReturnServer, and JapanEnvironment) now begin with
  `require(ServerScriptService:WaitForChild("JapanPreviewAccess"))` with NO timeout. If that module is ever renamed or removed (for
  instance when Japan is cleaned out of the place) the balloon script blocks before it builds the balloon: no balloon for anyone,
  and SpawnReturn's dais-return stops. (Fix: WaitForChild with a timeout and a fallback that allows nobody.)
- YOU CAN NEVER TAKE THE ORDINARY RIDE AGAIN: the preview is keyed on your user id alone, the prompt always says "Fly to Japan", the
  "fade" phase is dropped and balloon_flights is never awarded to you, so your Passport's balloon entry and the "balloon is ready"
  sign stay as they are. (Fix: an opt-in - a second prompt or an attribute - and the award on a completed preview too.)
- Smaller: after a respawn on the owner's abort path the camera is pointed at the dead Humanoid and freezes (stopPreviewCamera
  restores the old subject); up to ~15 s of blank pale screen with no liveness check during the two stream requests; the landing
  heights are hard-coded (y .1 / y 4 at (6090..6100, 270)) where the home pad uses a raycast; other players see your balloon freeze
  out at sea in its storm pose, vanish, and come back to the pad 30-45 s later; the "To Be Continued" sign still shows for its full
  6 s before the cloud cover; lightning keeps striking behind the white screen until the reveal; "Welcome to Japan, SelBell" is
  hard-coded; JapanBalloonPhase is set on every rider and read by nothing.


## B. The map itself (for when it opens; nobody else can see it today)

1. THE SEA IS MISSING. Of 1,365 ground rays over Japan's box, 532 find NOTHING down to y -400: the whole strip west of the island
   (x 5200, z -1270..-570, and more the list cut off) is void - no terrain, no water. The island is ringed by sculpted cliff meshes
   (JP_Island_Cliffs_West/North/South, up to 1,317 studs long); a player who steps off a cliff falls until Roblox kills the character
   and respawns them. Porto's sea is terrain water you can swim in; Japan's "sea" is the sky. Needs terrain water (or a kill-plane
   with a splash and a swim back) before anyone else visits. (98 rays did hit terrain Water: the lake and basins inland.)
2. 855 INVISIBLE SOLID PARTS: "Water basin collision supports" (498) and "Water bank walking supports" (136) are invisible floors in
   and around the lake, plus 221 more elsewhere. Check by eye in the preview: do you WALK ON the lake's surface, wade, or swim? Invisible
   floors at the water line read as "walking on water"; invisible walls at the island's edge would be a fine fix for finding 1.
3. FLOATING (round 2, top-most models, verify by eye): MountainBackdrop (3 parts, 42 wide) hangs at y 133 at (5440, -580) north-west
   of the island - it is the volcano ("Rumbling volcano" with the crater, plume and rumble live inside it), a backdrop floating in the
   sky; two Bamboo clumps on the slope at (6576, -365) y 19 and (5540, -365) y 14; the "Fuji photography lookout" (10 parts, 30 wide)
   at (5684, -304) with its bottom at y 23 and nothing within 12 studs under its centre. (Round 1's per-model pass flagged 578, mostly
   bamboo on the slope and market props sunk 0.7 under the street - those are fine.)
4. 180 HUGE MESH PARTS (size over 400 studs): the sculpted terrain - JP_Fuji_Sculpted 875 x 320 x 870, two ridgelines 790 x 450, the
   volcano 403 x 400, the island cliffs; plus Landscape.Walkway 13 x 0 x 500 (a zero-thick 500-stud strip). Walk the hills in the
   preview: a MeshPart that big collides at whatever CollisionFidelity it was imported with (a "Box" or "Hull" Fuji is a wall you
   cannot climb; "PreciseConvexDecomposition" on 875 studs is heavy). The ridgelines' box reaches y 320.
5. PERFORMANCE WHEN IT OPENS: 20,373 parts (Porto has 70,630 but streams in pieces), 1,207 MeshParts with 157 unique meshes, 159
   SurfaceAppearance (PBR texture sets - the heaviest thing on a phone's memory), 154 SurfaceGuis, 133 lights, 6,965 shadow-casting
   parts, 28 Neon. With StreamingEnabled true only the district you stand in streams, which helps; the lights and the PBR sets are the
   phone risk. Nothing is unanchored (good), nothing default-named (good), no unions.
6. THE TAXI SIGN IN THE CHATEAU GROUNDS: "Sign · JAPAN / Airport taxi" (5 x 4 x 0) and a "Provence taxi stop post" (3 x 0 x 0, a
   zero-thick line) at (445, 7, -44) - inside the French domaine, ten studs from its arrival pad, part of workspace.JapanMap (that is
   why JapanMap's box starts at x 442). Hidden for everyone but you; when Japan opens, an airport taxi in the chateau's garden is the
   oddest door in the game - the boat and the balloon are how 1001 Squirrels travels. Worth deciding now where Japan's real door goes
   (the Porto harbour? a ship? the balloon for everyone?).
7. SIGNS AND TEXT: 154 labels, 108 of them Japanese (喫茶 cafe, 寿司 sushi, 本日のおすすめ "today's special", menus "700 / 500 / 300" -
   yen prices in a game that pays in acorns); fonts Garamond and GothamMedium (the game's signs are FredokaOne / GothamBold). English
   ones: WELCOME TO JAPAN, CASTLE LOOKOUT, FUJI VIEW, VOLCANO LOOKOUT, Origami library, Garden tea house, Koto pavilion, Tea farmhouse,
   Rice barn, Castle kitchen. The menus and shops are fronts: no shop, prompt or acorn price is wired to any of them.
8. WHAT WORKS INSIDE: 7 prompts (the three station boarding points, the cabin's ride and exit controls, the two taxi links), 12 seats
   (one disabled - the train's passenger seat, enabled only during a ride), three market stalls that seat you on contact (owner only
   today), the volcano's rumble + plume every 24 s (one positional sound). 0 NPCs, 0 squirrels, 0 spawn locations, 0 click detectors.
9. THE TRAIN: one Script moves the whole Indigo bullet train on the server every frame of a ride (8 s minimum, 45 studs/s), seats the
   rider, locks the camera to FIRST PERSON inside the cabin (JapanTrainInteriorCamera; on a phone first person is unusual for this
   game) and walks the rider out at the next station. Only one rider at a time (`busy`); the stations loop Tea Hills -> Lantern Street
   -> Palace -> Tea Hills.

## C. The place file and the backups (not Japan's fault alone)

ServerStorage holds 318,798 instances. Codex's 22 "JapanBefore*" revision backups are 17,794 of them (120 scripts among them, four
MusicClient variants) and six other Japan* folders 4,469 (the mountain's authoring facets 2,304, interiors and old facades 2,023) -
7% of the whole. The other 93% is older: every install's HudBackup copies and whatever else accumulated. All of it is in the place
file and in every server's memory at start. tools/japan/probe_serverstorage.lua (read-only) lists the 40 biggest folders so we can see
what to archive to a separate place. Studio itself sat at 1,860 MB with the place open.

## D. Before Japan can open to players - the work list

- A sea (B1), the invisible floors decided (B2), the floating backdrop and lookout grounded (B3), the sculpted meshes' collision
  checked on foot (B4), the door (B6).
- Squirrels: none registered (SquirrelRegistry has forest 15 / village 14 / domaine 15 / porto 44); the registry, the map panel, the
  Passport, the portraits and the HUD count all key on map ids - a "japan" id with its squirrels, the Found_japan attribute and the
  travel unlock rule (all 44 French? all of Porto?).
- A spawn pad (SpawnPads with Area "japan") and the Area rule: today SpawnReturnServer says z < -300 is "porto" and everything else is
  French by x - Japan straddles z -300, so without a rule half of Japan counts as Porto and half as France (the French HUD, the daily
  pill, the question reminders and the golden squirrel would all show in the Japanese half). Codex avoided the question by skipping
  the Area update for you while you are there, which leaves YOUR Area stale (see A).
- Travel: a Travel board entry / a boat or balloon for everyone, the return trip, the one-click card pattern.
- Music: MapMusic.MusicClient mentions Japan (not yet exported; four Japan music variants sit in the backups).
- Analytics: the funnel's and the interaction counter's map names.
- The 22 revision backups out of the live place.

## E. Recommendation

@@E@@
