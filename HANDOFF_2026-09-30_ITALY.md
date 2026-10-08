# 1001 Squirrels: handoff (Sep 30, 2026, ~10:20 EDT). Next up: the Italian fishing village

## Where things stand
- **Live version: v744** (published Sep 30 ~10:18 EDT, on Shannon's word). API access was turned OFF again and checked.
- **The motorboat is DONE and LIVE** (jetty, moored boat, 44-squirrel lock, driving, engine sound). It has nowhere to go yet; that's fine by Shannon.
  - The full boat story (scripts, positions, lessons) is in `HANDOFF_2026-09-30_BOAT.md`, sections PROGRESS through PHONE TEST.
  - **What exists:**
    - `workspace.River.Jetty`.
    - `workspace.River.BoatPreview`: the moored army-green boat, with ropes, a bow ring and a stern cleat.
    - `workspace.Boat`: BoatServer, BoatClient, BoatEvent (installer i5). Tools are in `tools/boat/`.
  - **Engine sound:** 15067494918. Shannon has not listened to it yet; she may ask for pitch or volume tweaks (`ENGINE` table in BoatServer).

## The travel plan (agreed Sep 29, see memory new-maps-travel-plan)
1. River: DONE (v726).
2. Map edge: ring the open space with hills, forest and haze; the river leaves through a gorge at the south edge; the road leaves through a pass or tunnel. **NOT built yet.**
3. Boat: DONE. Later it leaves town through that gorge, then a transition, then Italy.
4. Taxi, airport front, flight screen, Japan (later).
5-6. Build Italy, then Japan. Each starts with an arrival area that grows.
- **New maps live in the SAME place** (not separate places), so acorns, the passport, shops and saves just work.
- **Both trips unlock at 44 squirrels** (forest + village + domaine). The boat lock counts those three maps only, so new Italy squirrels won't re-lock it.

## Italy: open questions for Shannon (ideas first, honest feedback, then build)
- **Look and feel:** a Cinque Terre-style fishing village? For example: colourful stacked houses on a cliff, a little harbour with fishing boats, a piazza, a lemon grove, a lighthouse, cafes and gelato. Ask for her reference pictures.
- **Where it sits in the place:** a separate area far from the current map, reached only by the boat trip.
  - Survey the free space first, read-only.
  - Measure the current world's full extent first (not recorded here). Known: the Domaine build box is x 380..724, z -284..64, and the river runs z 80 to -300.
- **The arrival:** the boat trip ends at an Italian harbour quay. Decide the transition: a short cut-scene down the gorge, a fade, or a map screen like the flight idea.
- **Squirrels:** how many Italian squirrels and what themes (fisherman, gondolier, pizza chef...)? That uses the Meshy squirrel pipeline in `roblox-props/squirrels/` (see memory chasing-rainbows-squirrels). Registry maps are in SquirrelScripts.SquirrelRegistry.
- **Does the map edge (step 2) come first?** The boat needs the gorge to leave through.

## Standing rules (unchanged, plus today's)
- **Ask Shannon before EVERY edit** to the place (memory ask-before-studio-edits). Read-only probes and camera moves are fine.
- **Save data:** never touch her real save data. API access stays OFF in Play tests. Publish only on her word.
- **Before any click:** take a screenshot, check Studio is in front and in Edit mode, restore her camera and clipboard afterwards.
  - Her clipboard is often an image; `setclip.ps1` saves it, and you restore it with `-STA SetImage`.
- **Phones:** nothing may overlap. Measure it with `tools/boat/ph1_cli.lua`-style probes in Test > Device Simulator (iPhone 7).
- **Keep Codex's work.** Never rerun the old builders.
- **Look right up close:** Shannon inspects extreme close-ups.
  - Check fittings from a dead-level side view, not only from above.
  - When she circles a spot on a screenshot, map it through the SAME camera with a ray onto the mesh.
  - No floating or sunk parts, no V-kinks in rope, nothing passing through wood.

## Studio workflow that works (details in the BOAT handoff)
- **Bring Studio forward:** use PowerShell `SetForegroundWindow` on `RobloxStudioBeta`. Never `open_application`.
- **Command bar:**
  1. `powershell -File tools/setclip.ps1 -Path <script>`.
  2. Click (700,725-735), then ctrl+a, ctrl+v.
  3. Zoom on the editor to confirm the script's last line / QQ tag.
  4. Click Run at (1418,648); a short script puts it lower (658-693), so zoom to check.
- **Output:** `print` lines tagged `QQ`, read from the newest `%LOCALAPPDATA%\Roblox\logs\*Studio*.log`.
- **Play:** (86,46); Stop: (142,46); Client/Server tabs: (242,112)/(305,112).
  - The daily card's Collect button is at (835,300).
  - `tools/boat/bt2_srv.lua` fakes 44 finds in the test copy.
- **Blender:** `blender-launcher.exe --background --python X.py -- args`. It writes results to files; sleep about 25 s before reading them.
- **Importing a model:** Home > Import (570,82), type the file path, then Import (967,645). The imported model lands in workspace under the file's name.

## Starter prompt for the new chat
> Please read C:\Users\slard\roblox-props\HANDOFF_2026-09-30_ITALY.md. We're starting the Italian fishing village for 1001 Squirrels. Ideas first: help me decide the look, where it goes in the place, how the boat trip arrives there, and whether the map edge/gorge comes first. Read-only survey of free space is fine; ask before any edit.
