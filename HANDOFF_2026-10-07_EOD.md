# Handoff: 1001 Squirrels, end of Oct 7 2026 (start the next chat from here)

**Starter prompt for a new chat:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-07_EOD.md and continue 1001 Squirrels. Next job: the remaining 21 Porto squirrels (6 more for Via della Piazza, 15 for The Groves), one at a time, each shown to me before the next. Use the Roblox_Studio MCP tools (no screen). Check weekly usage first. Ask me before every Studio edit (fixes of something I just flagged: just do them and show me). Never launch Studio.

## Read first (rules, in her words)
- Ask before every Studio edit; flagged fixes: just do + show. Publish only on her word. Never write her DataStores (the new PortoKeeper_v1 store was approved Oct 7). API access OFF for play tests.
- Phones: no overlaps, ever. Measure rects in the Device Simulator (Test > Device Simulator); the connector cannot toggle it, the desktop tools can (see "Studio control" below).
- Every squirrel speaks through ReplicatedStorage.SquirrelBubble. No acorn joke in every bio; the joke comes from the character. Short bios (1-2 lines; she called Antigravity's "cute but much too long").
- New builds detailed and finished first time; pictures (artifact page) before building big things.
- Stop at 70% weekly usage. Oct 7 ended at ~12% Fable.
- NEVER `open_application` Roblox Studio (opens a second instance / freezes). HARD RULE, in memory.

## Live state
- Published Oct 7 15:00 EDT (v1144 expected; Studio shows the version only after a reopen). Contains everything from Oct 7:
  whale lane + PortoWhale (60 studs, route A-B, soft plume spout, sound), HUD per area, album sections + card carousel + card/album fitted above the hotbar and below the phone Hint button, short bios, registry areas, badges Maestro/Genius/Luminary with ids, Guardian of the Harbour monument (placeholder), Officer Acorn, Giulia, Lighthouse bench moved.
- Full day log (every edit, waypoint, failure and recovery): HANDOFF_2026-10-07_WHALE.md (long; grep it).

## Porto Nocciola squirrels: 24 of 45
Registry = Workspace.SquirrelScripts.SquirrelRegistry (maps.porto.areas: harbour "The Harbour", borgo "Via della Piazza", groves "The Groves"; every porto entry has `area`). Zones = workspace.Zones parts porto_harbour / porto_harbour_sea / porto_borgo / porto_borgo_coast / porto_groves (MapId=porto, Area=...).
- The Harbour (15, done): customs, fishmonger, deckhand (Gino), netmender, gelato, boatpainter, realtor (Signora Chiave), italytourist (Penny), tightrope, seacaptain, sunbather, crabcatcher, conductor, lifeguard, octopus.
- Via della Piazza (9 of 15): sassyshopper, pogo, pizzadelivery, baker, giulia_market (Giulia), officer_acorn_police (Officer Acorn), goldenyears, goodneighbor, operasinger. NEED 6 MORE. Zone = the hill town, z -1000..-540 (plus the lighthouse-coast stair x 300..355 z < -880).
- The Groves (0 of 15): lemon + olive groves, lighthouse coast, Faro, Grotta Azzurra, Spiaggia dei Ciottoli; zone z -1300..-1000, x 300..800. NEED 15. Ideas she liked earlier: the lemon seller (saved for "the mountain"), lighthouse keeper, olive picker, grove cat?, beekeeper no (domaine has one).
- Honours: Squirrel Maestro at 15 porto found (badge 1472887764139377), Squirrel Genius at 30 (4327774231356693), Squirrel Luminary at 45 (511740616906295) - Honours folder attrs Badge_porto / Badge_genius / Badge_luminary. TitleClient banners per tier. Badge art: roblox-props/badges/*.png (HUD acorn shapes in tier colours).
- Guardian of the Harbour (Porto champion): workspace.PortoKeeper (plinth at 488,2,-1158 by the lighthouse, key on top, plaque "This could be you"), PortoKeeperServer/Client, RemoteEvent PortoKeeperEvent, store PortoKeeper_v1 key "first", Need=45, owner excluded, statue via Champion.MakeStatue with the acorn-bow Key in the raised hand, title shows over all honours (TitleServer PortoKeeperTitle). Badge_key = 0 (she has not made that badge yet). KeeperDebug BindableFunction in Studio for tests.

## Squirrel pipeline (what worked for the 24)
- Art: squirrel art style method memory (edits of ONE base image in ChatGPT; base + prompt on Desktop\squirrel). Props pinned to chest; check head-turn renders; sharpen/saturate textures (1k is the texture ceiling - portrait sharpness "good enough", parked).
- Mesh: Meshy -> roblox-props/squirrels/<id>/ (rig_any / blender prep scripts there; see squirrels/*/ for the pattern, e.g. customs_squirrel). Colour + gray FBX each; Import 3D by her (the MCP has no FBX import). After import: flatten SurfaceAppearance -> TextureID, attrs SquirrelId/DisplayName/ColorTexture/GrayTexture, RenderFidelity Precise, gray twin to workspace.SquirrelTwins at (0,-401.2,0), registry entry with area + short bio, place it (feet on the ground, facing checked with a capture), bubble lines via SquirrelBubble.
- Antigravity (another agent) also builds squirrels in its own session on the same place: coordinate; it once rotated all of Porto (fixed) and placed a squirrel on the lifted town. Check `workspace.PortoNocciola` landmarks (Fontana del Limone pivot 593.52,-11.95,-794) if anything looks off.

## Studio control (what the tools can and cannot do)
- Roblox_Studio MCP: `list_roblox_studios` (the id CHANGES every time Studio/the place is reopened), `execute_luau` (datamodel Edit / Server / Client; `warn` output is NOT returned - wrap scripts, see italy/whale/mcp_wrap.py), `screen_capture` (edit-time, camera_position/look_at; often times out above water, retry), `start_stop_play`, `user_mouse_input` (clicks inside the GAME client, by instance path or x/y), `get_console_output`. Large returns are saved to a file by the tool (use that to dump scripts).
- It cannot: import FBX, publish, open menus, toggle the Device Simulator. For those: she does it, or the desktop tools (computer-use) with Studio GRANTED and IN FRONT (ask her to click Studio first; never launch it). Alt+P publishes; a toast "Published" appears; verify in %LOCALAPPDATA%\Roblox\logs\*_Studio_*.log ("Go to PublishSuccessful").
- Publish hang recovery (happened Oct 7): if a publish/save times out after 240 s ("server publish request timed out", "Failed to download place file"), that Studio session can never save again -> dump every changed script + setting via execute_luau into roblox-props/italy/whale/replay/ (pattern there: bundle + settings + checksums), close Studio WITHOUT saving, reopen the cloud place, replay. Keep edits as anchor-based Lua patches (they replay deterministically).

## Phones (fixed Oct 7, keep it that way)
- HudBarClient (Workspace.HudBarUI) owns the squirrel Panel on phones: position top-right under the icons + Hint button (PANEL_Y 114 on mobile), UIScale fit reserving 72 px for the hotbar, width budget vp.X-40. It leaves any Card with attribute SelfFit alone.
- SquirrelAnim: hudCols() up to 8 columns when the viewport is < 480 tall; modalBand() starts at PHONE_TOP 114 on phones and ends 72+8 above the window bottom; card = two columns on short screens (portrait left, name+bio block centred right, hint row under the portrait), scale budget includes the carousel arrows. Measured OK on iPhone 7 (667x375).

## Open items (her priorities in order)
1. The 21 squirrels (above). Then the sea shell / glass craft game (pictures first; she described it as a big build).
2. Guardian badge (Badge_key) when she makes it; 5-medal BadgeCase (BadgeCaseClient lays out 3 France medals only); Giulia's facing check in play; whale extras (shore squirrels reacting, foam wake).
3. Antigravity's two "missing" Via della Piazza squirrels (she counted 11, place has 9).

## Files
- roblox-props/HANDOFF_2026-10-07_WHALE.md (full log), italy/whale/ (whale, lane, installer, spout, replay/, page_whale, squirrel-card-layouts.html), tools/italy_squirrels/ (installers, pack.py), badges/ (badge PNGs), memory: new-maps-travel-plan.md, never-launch-studio.md, phone-ui-no-overlap.md.
