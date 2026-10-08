# Handoff for ChatGPT: build Porto Nocciola, the Italian fishing town, in 1001 Squirrels

Written Oct 1 2026 by Claude (Claude Code) for Shannon, who is moving this build to ChatGPT. Everything you need is in
this file: the game's rules, her plan, the exact ground you build on, and every game system the new town must plug into.
Read it all before touching Studio.

---

## 1. The job in one paragraph

1001 Squirrels is Shannon's Roblox game: players find hidden themed squirrels across connected maps (a forest, a French
street called Rue de Noisette, and a Provence estate called Chateau de l'Acorn), earn acorns, fill a Passport and chase
daily honours. A river runs from the French street down a gorge and over a 52-stud waterfall into a plunge pool. That
pool and the coastal plain at the foot of the cliff are **Porto Nocciola** ("Hazelnut Harbour"), the first Italian
city. Right now it is an empty grassy plain with a beach, a sea, one spawn dais and one luggage cart. **Your job: build
Area 1, Harbour Front (Il Porto), with its 17 squirrels**, to Shannon's quality bar, plugged into the game's systems.
Hillside Town and Lighthouse Point come later.

---

## 2. Standing rules (non-negotiable; Shannon set every one of these)

1. **Never write her DataStore.** She plays the live game on her phone. Studio's "Enable Studio Access to API Services"
   stays OFF. Test grants are player attributes only (they are never saved with API access off).
2. **Ask before every edit** to the place (Team Create is on with Drafts OFF, so edits land straight in her shared
   place). Read-only probes and editor camera moves need no permission. When she has just flagged something as wrong and
   you are fixing exactly that, just fix it and show her; ask only for a new kind of change or a real design choice.
3. **Publish only on her word.** Publish = click the 3D viewport, press Alt+P, then read "Published new changes in
   '1001 Squirrels' to Roblox" in the Output window (the version number shows there too).
4. **Phones: nothing may overlap anything, ever.** Measure rectangles, don't eyeball. Test in Studio's
   Test menu > Device Simulator on an iPhone 7 (667x375) and an iPhone XR (896x414). Real screen position of any GUI =
   `AbsolutePosition + GuiService:GetGuiInset()`, for every ScreenGui (IgnoreGuiInset or not).
5. **Every squirrel speaks through `ReplicatedStorage.SquirrelBubble`** (a drawn comic speech bubble on the screen
   layer, with her squirrel sounds). Never a toast or a pill for a squirrel's words. Call it from a client script:
   `require(game.ReplicatedStorage.SquirrelBubble).say(squirrelModelOrPart, "text", {secs = 3.5})`.
   Long lines: split into several bubbles about 3.6 s apart. Never write squirrel noises as text.
6. **Keep everyone's earlier work.** Do not rebuild existing systems from old builder scripts. Change a live script by
   reading its current source in Studio first, then patching exact lines (assert every anchor; abort on any mismatch).
7. **The owner never takes a Keeper slot.** `ChampionServer.crown()` returns early for `game.CreatorId` (her account).
   Leave that in place; it lets her test "find all".
8. **Squirrel bios:** build each joke from that squirrel's own job, costume or props. No acorn joke as the default
   punchline. Check the other bios on the same map first so no gag, food or sentence shape repeats.
9. **No picture pages.** Show her things by leaving the Studio editor camera on them, or by play-testing in Studio.
10. Before any click or keypress, take a screenshot and make sure Roblox Studio is the front window (she sometimes plays
    the live game on the same PC). Keep her clipboard safe: save it before you set it, restore it after.

---

## 3. Where things stand (Oct 1 2026, evening)

- **Live version: v843** (Oct 1 21:18; v841 + the boat v45 changes below, now published). It has the waterfall, the parachute, the luggage-cart travel between France and Porto
  Nocciola, the Passport city tabs and a draggable world map.
- **Published in v843:** boat scripts "v45", verified in Studio:
  - The jetty sign reads: "Sailing to Italy today? / If you have found all 44 squirrels, you can take the boat. /
    See Sky Diving Squirrel first." Its post now stands behind the board.
  - On phones the boat's notes (the parachute warnings, steering hint, welcome) find a spot clear of the prompt button.
- Nothing is pending. No test scripts are left in the place.

---

## 4. Her plan for Porto Nocciola (copied from her plan doc, Sep 30 2026)

**Overview.** A fishing village called Porto Nocciola ("Hazelnut Harbour"), three areas, 50 squirrels, high summer, to
match the romantic sunny feel of Provence.

- **Look:** "postcard Italy": pastel houses stacked up a hillside, fishing boats, striped awnings, laundry lines between
  windows. Think Cinque Terre and the Amalfi coast, not a specific real town.
- **Palette:** Provence's warm golden light, shifted from purple and gold to lemon yellow and sea blue. Lemon trees play
  the role lavender plays in Provence. Laundry lines and striped awnings replace cafe string lights.
- **Skybox:** open sparkling sea with sailboats and distant rocky islands on one side, green coastal cliffs on the other.
- **Content rules:** no spirits, folklore creatures or magic; no wishing-fountain or good-luck-charm gags.
- **Same systems as Provence:** find squirrels, prompt interactions, earn acorns, Passport daily tasks, Keeper of the
  Great Acorn.
- **Map edges:** no fog; a sunny day. Open sea, sailboats and distant islands for depth. Block empty ground with lemon
  terraces, olive groves, stone walls and tall coastal cliffs.
- **Set pieces, one per area** (each hides movement the way the swamp croc does, so rigging stays simple): Harbour Front
  = a rowboat race around the buoys (water hides the body).
- **Snack gags** (the harbour's versions of the French cheese, ice cream and coffee gags): pizza cheese stretches until it
  snaps back into the squirrel's face; a gelato scoop tower wobbles higher and tips onto his head; a lemon gives a
  super-sour pucker, eyes squeezed shut, whole body shivering; one cannoli bite bursts cream out both ends.

**Area 1: Harbour Front - Il Porto (17 squirrels) - THIS IS YOUR SCOPE.** A curved harbour full of bright fishing
boats, wooden piers, nets drying on racks, a fish market, a gelato shop, a boatyard, a small sandy cove and tide pools.

| # | Squirrel | Where | Interaction |
| --- | --- | --- | --- |
| 1 | River boat captain | Arrival dock | Welcomes you; ride back to Provence |
| 2 | Net mender | Pier | Untangle the fishing net |
| 3 | Fish market seller | Fish market | Weigh a fish; it flops out of your arms |
| 4 | Rowboat racer | Harbour | Rowboat race around the buoys (set piece) |
| 5 | Gelato maker | Gelato shop | Stack scoops into a tower (snack gag) |
| 6 | Harbourmaster | Harbour office | Ring the bell as the boats come in |
| 7 | Deckhand | Fishing boat | Tie the boat to the dock with a knot |
| 8 | Sandwich chaser | Pier benches | Chase off the seagull that stole his sandwich |
| 9 | Octopus wrangler | Fish market tank | Catch the octopus; it squirts ink on your face |
| 10 | Sandcastle builder | Cove | Help build a sandcastle before the wave |
| 11 | Snorkeler | Rocks by the cove | Dive down for a shiny shell |
| 12 | Beach umbrella napper | Cove | Wake him before the tide tickles his toes |
| 13 | Crab counter | Tide pools | Count the crabs hiding under rocks |
| 14 | Boat painter | Boatyard | Paint a name on a boat |
| 15 | Paddleboarder | Cove | Balance on the paddleboard without tipping |
| 16 | Fruit boat vendor | Floating fruit boat | Buy a lemon (snack gag) |
| 17 | Pier jumper | End of the pier | Cannonball splash contest |

Later areas, for context only (do not build yet): **Hillside Town - Pastel Hill** (17: pizza chef, baker, cannoli
maker, scooter racer, funicular operator, laundry line dangler, accordion player, fountain splasher, stair racer,
balcony gardener, clock tower keeper, mosaic artist, pasta nonna, opera singer, lemon picker, olive presser, postcard
seller; a funicular links it to the harbour). **Lighthouse Point** (16: lighthouse keeper, spiral stair climber, sea
cave rower, sailboat skipper, cliff-top painter, telescope squirrel, lost hiker, flower crown maker, bottle finder,
high-dive squirrel, watchtower lookout, seashell collector, signal flag squirrel, pearl diver, sunset bench squirrel,
lizard sunbather; reached by a coastal path and a small ferry).

**What changed since her plan doc was written** (her later decisions; these win):
- The arrival is NOT a river dock. The boat leaves the jetty on the French street, runs down the gorge and **goes over
  the waterfall**: the boat breaks up in the plunge pool, the player is thrown out and either swims (no parachute) or
  steers down under the Sky Diving Squirrel's rainbow parachute (they borrow it after finding all 44 French squirrels).
  A note says "Welcome to Porto Nocciola!" (or "Dry feet! Welcome to Porto Nocciola!").
- Travel between the cities afterwards is by **luggage cart** (hold the prompt on its trunk): one cart on the Hall of Fame
  lawn at the Chateau goes to Porto Nocciola, its twin on the Porto shore goes back to the last French area the player
  stood in. She chose the cart over signposts because "the space there is already cramped".
- So the plan's "River boat captain: ride back to Provence" is best a squirrel standing by the Porto cart and dais who
  welcomes arrivals and points at the cart (his words in a SquirrelBubble). Ask her.
- Her earlier list also mentioned: a "Captain-by-sea" return, Italian planting, extending the sea, and the harbour
  quay/town. Ask before adding a sea return; the cart already does that job.

---

## 5. The ground you build on (measured in the place)

World axes: x east, z north (south is NEGATIVE z), y up. The French areas sit at y ~0. Italy is ~50 studs lower.

| Thing | Where / value |
| --- | --- |
| The waterfall's brink (lip) | z -547.5, river surface y -0.9, channel x ~170..196 at the lip |
| Plunge pool + harbour + sea water surface | y -52.9 (terrain water) |
| The plain (grass) at the cliff foot | y ~-48 (4-5 studs above the water) |
| Cliff amphitheatre (cream layered sandstone) | two arms either side of the falls, about x 100..330, z -540..-562 |
| Pool / harbour water | from the cliff foot (z ~-556) south, about x 150..240, widening toward the sea |
| Dry landing shore east of the pool | x ~220..260, z ~-560..-620, grass, sand edge at the water |
| Spawn dais (acorn medallion) + `workspace.Spawn_porto` | (232, -48.4 ground, -580), tip toward the water. Do not move. |
| Luggage cart to France `workspace.Travel.Points.TravelCart_porto` | (239.5, -580), facing the dais. Do not move without asking. |
| Sea terrain far edge | z -1556 (x +-1400). Extend the sea when the harbour is built (visible as grey marks on the horizon). |
| Base slab | `workspace.Baseplate` was cut away south of z -546.5 so Italy's terrain can sit low. |
| World-map rectangle for Porto | x 100..330, z -700..-548 (the HUD map's area; update it if the town grows past it) |

What already exists in the south (leave alone unless she asks):
- `workspace.SouthGorge` = Rock (gorge walls + cliff pieces), Aqueduct, Trees (181 on the rims and plateau), LipRocks,
  RapidsRocks, Falls and FallsB (the falling water: beams and particles, scenery only).
- `workspace.Boat.Wreckage` (floating wreck pieces after a boat goes over), `workspace.Travel` (carts + scripts),
  `workspace.SpawnDais_porto`, `workspace.Spawn_porto`.
- Backups of everything changed in the south sit in `ServerStorage.GorgeBackup`.
- Three white slabs in the sky visible from the harbour are the Hat, Dress and Book shop interiors parked high above the
  village. Ask her before moving them.

Keep clear: the falls and their mist; the swim/parachute landing zone in the pool and on the east shore (players land
there, sometimes steering from the brink); the dais and the cart.

---

## 6. Game systems the town must plug into

Read each live script's current source in Studio before you change it. Paths are in the Explorer.

**Squirrels** (`workspace.SquirrelScripts`)
- `SquirrelRegistry` (ModuleScript) is the one list of every squirrel: `maps = {{id, name}, ...}` and
  `squirrels = {{id, map, name, bio, face?}, ...}`. Today: maps forest / village / domaine with 15 / 14 / 15 = 44.
  Add `{id = "porto", name = "Porto Nocciola"}` and the Italian squirrels only when they exist in the world.
- Each squirrel in the world is a model named `<id>_color` (what players see and find) with a texture twin `<id>_gray`.
  Copy the structure of an existing one (for example `workspace.parachute_squirrel_color`) before making new ones.
- `SquirrelSetup` (server) owns finding (click or touch), the per-player attributes `Found_<map>`, `SquirrelsFound`,
  `FoundIds`, and the ONE save key. Other scripts never save: they fire `ReplicatedStorage.AwardItems` (BindableEvent:
  player, itemId, n) or `AwardAcorns` and SquirrelSetup records it.
- **Decision for Shannon BEFORE adding Italian squirrels to the registry:** the HUD counter shows found / all, and the
  Keeper of the Great Acorn (`workspace.Champion.ChampionServer`) uses the total number of squirrels ("first to find all
  N in a day", hall entries store `total`). Adding 17 Italian squirrels raises the Keeper bar from 44 to 61 for
  everyone. Also many texts say "all 44" (the jetty sign, the boat lock note, the Sky Diving Squirrel, the Passport
  Keeper outing). The boat lock itself counts only the three French maps and is unaffected. Ask her: does Keeper stay
  "all of French Squirrel Country" (44) or become "every squirrel in the game"?

**Prompts.** Every ProximityPrompt in the game is restyled automatically by `workspace.PromptUI` (a compact pill; on
phones a button that sits up and to the right of the player's head and dodges other UI). Just create normal
ProximityPrompts. On phones a prompt can ask for a fixed spot with the attribute `PhoneSpot = "jump"` or sit under a sign
with `PhoneSpot = "sign"` + `PhoneAnchor` (a world Vector3).

**Spawning** (`workspace.SpawnReturn.SpawnReturnServer`): anywhere south of z -300 counts as area "porto". A player whose
last area was porto respawns on `Spawn_porto` once they have opened Porto (`Item_porto >= 1`), otherwise in their last
French area. The player attribute `Area` holds the current area.

**Travel** (`workspace.Travel`): TravelServer awards `Item_porto` (through AwardItems) the first time a player is down
at Porto, and handles the carts (fade, teleport, NoMusic). The carts show to everyone; their prompt shows only once Porto
is opened.

**Music** (`workspace.MapMusic.MusicClient`): plays per area. At Porto the music is currently OFF on purpose (the boat
and TravelServer set the character attribute `NoMusic`; MusicClient goes quiet on it). If she wants Porto music, add a
porto area to MusicClient and stop setting NoMusic on arrival at Porto (TravelServer) and after the falls (BoatServer).

**Passport** (`workspace.Passport`: PassportServer, PassportClient, Journal, Catalogue, Rules, PassportVisuals)
- Outings are data entries in `Catalogue` `{id, name, area, icon, hint, detail}`. Italian ones use `area = "porto"`
  (today: chute and porto; the boat and falls outings sit under France with `area = "village"`). Outings flagged
  `needAll = true` are offered only after all 44 French squirrels are found. An outing is stamped by firing `ReplicatedStorage.PassportActivity`
  (BindableEvent: player, id, dataTable) from a server script when the player really does the thing.
- The Passport shows city tabs (French Squirrel Country | Porto Nocciola) once `Item_porto >= 1`. The Porto Clues tab
  currently says "Italian clues: coming soon" (in PassportClient); replace that when Italian squirrels or a daily Italian
  question exist. New stamp texts go in `Journal.describe`; artwork previews in `ReplicatedStorage.PassportArt`
  (inert copies of game models; `PassportVisuals` maps outing id -> preview name).
- Local single source for these patches: `roblox-props/passport/patch_travel.py` (writes the live installer too).

**The world map** (HUD "Map" button, `workspace.HudBarUI.HudBarClient`): ONE draggable parchment chart of the whole
world (drag, wheel, pinch, + / - / Me). The image is drawn by `roblox-props/boundary/marketing/make_map_world.py` and
uploaded (current asset 126434655912945). The panel's code block lives in `roblox-props/boundary/hudbar_map_block.lua`,
applied by `boundary/patch_map_world.py <assetId>`. Porto's plate currently says "harbour coming soon": once the town
exists, redraw the chart with its landmarks, re-upload, and switch Porto's plate to "found / total".

**Speech** (`ReplicatedStorage.SquirrelBubble`, see rule 5) and **notes** (short system notes like "Welcome to Porto
Nocciola" are toasts high on the screen; on phones they must not collide with anything; see BoatClient's `placeToast`).

**Acorns, Daily, Golden Squirrel:** the daily Golden Squirrel picks from the registry and names an area; check
`workspace.Daily` (DailyServer) handles a porto squirrel and area name before Italian squirrels join the registry.

---

## 7. Shannon's quality bar (read twice)

She wants new maps "very detailed and finished and high fidelity" on the first delivery: "It's ok if you take a long
time to build it; but I need it done right the first time." Agree on reference pictures and a build sheet with her
before generating anything; show nothing until the checklist passes. What she catches, so check it yourself first:

- Anything floating or sunk. Measure each prop's real underside by raycasting; terrain smooths 4-stud cells so small
  ground patches sag: write, raycast, correct, repeat.
- Two ground materials meeting (part grass next to terrain grass reads as "fabric patched together"): use one ground.
- Grass running straight into water ("tsunami"): every bank needs a worn sand or mud band at the waterline.
- Seams: roof meets wall, post meets cap, rope with no V-kinks, nothing passing through wood; check fittings from a
  dead-level side view, not only from above. She inspects extreme close-ups.
- Round "pompom" bushes stuck on cliff faces are bad: cliff faces stay clean rock; trees only on the grass above.
- Stones on flat shelves, kerbs or walls that stop short, paving that juts over nothing.
- Terrain trap: `Enum.Material.Pebble` is not a terrain material and is silently stored as Grass.
- Props need secondary detail (hoops, slats, frames, shutters, tiles); ground needs paths, tufts, small terrain rises.
- Play-walk the whole area; check phones in the Device Simulator (rule 4).
- When she circles a spot on a screenshot, find it through the SAME camera (raycast from that view).

---

## 8. Driving Studio on her PC (what works)

- Studio is open on the live place "1001 Squirrels" (Team Create, API access OFF). Windows 11, Studio on her second
  monitor.
- **Command bar** (bottom of Studio): click it, Ctrl+A, Delete, paste or type the script, then click Run at the right
  end of the bar's first line. The Run button moves when the panels move: take a screenshot first. Long scripts are more
  reliable as a module: write a .rbxmx file containing a Folder with a ModuleScript "PatchModule" whose source is
  `return function() ... end`, then Explorer > right-click Workspace > Insert > Import Roblox Model > the file path >
  Open, then run `require(workspace.<Folder>.PatchModule)()` and `workspace.<Folder>:Destroy()`. Example packer:
  `roblox-props/tools/travel/pack_module.py NAME source.lua`.
- **Output:** print lines with a unique tag (for example `QQ`) and read them in the Output window or from the newest
  `%LOCALAPPDATA%\Roblox\logs\*Studio*.log`. Each line says Edit / Client / Server: check which one ran your script (a
  script that says Client ran inside a play session and is lost on Stop).
- **Play / Stop:** the Play button in the top-left toolbar; stop with Shift+F5 (command bar focused). While playing, the
  viewport has Client and Server tabs. The Daily Acorns card appears on join: click Collect.
- **Test grants in play** (Server tab command bar; attributes only, never saved):
  `local p=game.Players:GetPlayers()[1] p:SetAttribute("Found_forest",15) p:SetAttribute("Found_village",14)
  p:SetAttribute("Found_domaine",15) p:SetAttribute("SquirrelsFound",44)` opens all the French gates;
  `game.ReplicatedStorage.AwardItems:Fire(p,"porto",1)` opens Porto (cart prompts, Passport city tabs, map cover).
  Without the Found grants the boundary gates bounce a test character back.
- Holding a prompt from a script: `prompt:InputHoldBegin() task.wait(0.8) prompt:InputHoldEnd()` (client). Do not set a
  Scriptable camera before the hold (it stops prompts firing).
- **Device Simulator:** Test menu (menu bar) > Device Simulator; choose the device in the bar above the viewport (only
  while not playing). Switch it off afterwards.
- **Getting images into the game** (textures, decals, chart): make a one-quad OBJ + MTL whose `map_Kd` is the PNG, Home >
  Import 3D > the OBJ > Import; read the imported MeshPart's `TextureID` (that is the uploaded image's asset id), then
  delete the carrier model. Example: `roblox-props/italy/map/map_carrier.obj`.
- Her editor camera: put it back when you finish (her saved view of the falls is in
  `roblox-props/tools/cam_restore_shannon4.lua`).

---

## 9. Files on this PC (C:\Users\slard\roblox-props)

| Path | What |
| --- | --- |
| `HANDOFF_2026-10-01_CITIES_B.md` | the latest detailed engineering log (travel, passport, map, boat v41-v45) |
| `HANDOFF_2026-09-30_FALLS.md`, `HANDOFF_2026-10-01_CITIES.md` | how the gorge, falls, parachute and travel were built |
| `italy/GORGE_BUILD_SHEET.md`, `italy/plan/plan_map.png` | the south's layout notes and a top-down plan |
| `tools/boat/BoatServer.server.v2.lua`, `BoatClient.client.v2.lua` | the boat (local copies of the live scripts, v45) |
| `tools/travel/install_travel_t1.lua` | the Porto dais, carts, TravelServer/Client, SpawnReturn patch |
| `passport/patch_travel.py`, `passport/src/*.lua` | the Passport's cities patch and its sources |
| `boundary/hudbar_map_block.lua`, `boundary/patch_map_world.py`, `boundary/marketing/make_map_world.py` | the world map |
| `tools/bubble/SquirrelBubble.module.lua` | the speech bubble module |
| `squirrels/` | the earlier Meshy squirrel pipeline (models were made with Meshy, prepared in Blender) |

The local builder scripts for the forest, village and estate are OUT OF DATE (another assistant changed the live game
since). Never rerun them; patch live scripts instead.

---

## 10. How to start (suggested)

1. Read-only survey of the south in Studio (no edits): confirm the numbers in section 5, list what is there.
2. With Shannon: agree reference pictures (Cinque Terre / Amalfi fishing harbour), a layout sketch of Harbour Front on
   the plain and around the pool (curved harbour, piers, fish market, gelato shop, boatyard, cove, tide pools, harbour
   office), and the Keeper decision in section 6.
3. Write a build sheet: every building and prop with size, position, materials and colours; the 17 squirrels' hiding
   spots and their interactions; the rowboat race set piece.
4. Build the ground first (terrain, quay walls, sand bands, extended sea), then the set piece, then buildings and props,
   then the squirrels (registry + models + interactions + bios), then Passport outings, map chart, music if wanted.
5. Run the quality checklist (section 7) and the phone check (rule 4), play-walk it, then show her in Studio. Ask before
   each edit; publish only when she says.
