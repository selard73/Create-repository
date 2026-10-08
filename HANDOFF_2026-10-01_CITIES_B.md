# HANDOFF 2026-10-01 (17:27): cities round, parts B + C - ALL PUBLISHED (v841)

## After v841 (21:00): boat scripts v45 IN THE PLACE, NOT PUBLISHED (replaces the v44 note below)
- Jetty sign last line now "See Sky Diving Squirrel first." (her words): "Sailing to Italy today? / If you have found all 44
  squirrels, you can take the boat. / See Sky Diving Squirrel first."; the post stays behind the board (v44).
- Her phone report: the parachute warnings hid behind the boat's prompt button. Cause: the phone pill (PromptTouch,
  DisplayOrder 30, up-right of the head) sat on the note (BoatUI, DisplayOrder 5, fixed at y 72). BoatClient v45 placeToast():
  on touch screens the note scans for a spot clear of every visible screen element (PromptTouch included; rects =
  AbsolutePosition + GuiInset), down the middle from y 72, then left, then right; nowhere clear -> DisplayOrder 31 so the
  words still show. Computers keep y 72. Measured in the Device Simulator with tools/boat/ph2_cli.lua: iPhone 7 (666x373)
  warnings 1-3 note 103,160-563,216 under the pill 322,104-?,151, 0 overlaps; iPhone XR (801x391) note 170,202-630,258,
  pill 430,147-?,194, 0 overlaps. Simulator switched back off. Publish on her word.

## After v841 (20:45): boat scripts v44 IN THE PLACE, NOT PUBLISHED
Her note on the jetty board ("the post holding up this sign is covering the text") + new words: "Sailing to Italy today? / If you
have found all 44 squirrels, you can take the boat. / You might want to check in with Sky Diving Squirrel before you leave."
BoatServer: the post (0.3 x 4.9) now stands BEHIND the board (x 163.455, -x side), deck to just under the board top; any old
ChuteNote is destroyed and rebuilt at server start. Edit script tools/boat/edit_v44_note.py; packer tools/travel/pack_module.py
(NAME SOURCE). Verified in play from the street side. Publish on her word.

## PUBLISHED v841 (17:27, her word "fix the overlap, then publish all")
Everything in part C below plus the overlap fix: map block v3 (marker "-- world-map v3"): the Golden Squirrel pill
(DailyGui.GoldPill, computers only, at y 72 right -12) sat on the header line of both HUD panels (y 64); a Heartbeat in
the map block hides it while the map OR the squirrels panel (hudPanel) is open and restores it on close (only if it was
showing and has text). Verified in play: pill on join -> map open, header "You are here: The Great Acorn Forest" clean ->
closed, pill back -> squirrels panel open, clean -> closed, pill back. Nothing is unpublished now. Her camera restored.
NEXT: Harbour Front / the Italian squirrels (Porto Nocciola's map entry in the SquirrelRegistry only once squirrels exist).


## PART C (17:10) - what changed after part B below
- PUBLISHED v836 (16:35, her word "cart is good, can publish"): travel carts + Porto dais + boat v42 + the v40 warnings.
- IN THE PLACE SINCE, NOT PUBLISHED (she said "do the rest"; publishing still needs her word):
  1. PASSPORT cities patch (passport/patch_travel.py -> src/*.lua + build_passport.lua + install_passport_travel.lua, applied
     to the LIVE workspace.Passport scripts, marker "-- travel-passport v1"): four outings boat / falls / chute / porto
     (needAll = the 44 found; areas village / village / porto / porto), stamp texts in Journal.describe (falls says whether
     the chute was on), artwork previews in ReplicatedStorage.PassportArt (boat = the moored boat mesh, chute = the rainbow
     canopy, porto = the Porto luggage cart, falls = a little built cliff + sheet + pool); PassportClient: NORMAL (the count
     of non-bonus outings) replaces the hard-coded 21; per-city sub-tab row (French Squirrel Country | Porto Nocciola) under
     Outings / Completed / Clues once Item_porto >= 1; the list starts at y 124 while it shows; Italy's Outings empty card,
     Completed filtered per city, Italy's Clues = "coming soon". Verified in play (screens: all four tabs).
  2. BOAT v43: BoatServer fires PassportActivity boat (take), falls {chute=...} and chute (the eject). Installed with 1.
  3. THE MAP (her choice: ONE draggable map): boundary/marketing/make_map_world.py draws the whole world as one parchment
     (1024x900, world x -130..700, z -700..30: France + the gorge + the aqueduct + the falls + the harbour + the Porto shore
     with its dais and cart); uploaded through the Import 3D carrier italy/map/map_carrier.obj -> IMAGE rbxassetid://
     126434655912945. boundary/hudbar_map_block.lua replaces the map section of HudBarUI.HudBarClient (patch:
     boundary/patch_map_world.py <asset> -> install_map_world.lua, marker "-- world-map v2"; also patched into
     passport/integrations/...HudBarClient.lua and both copies in build_passport.lua): a 560x380 window onto the chart, drag
     (mouse/finger), wheel + pinch zoom, + / - / Me buttons in the window's bottom corner (the top is where the Golden
     Squirrel notice sits), area covers/plates/dot ride on the chart; AREAS gets porto {x 100..330, z -700..-548, needs =
     "porto" (Item_porto)}, plate "Porto Nocciola / harbour coming soon". Opening centres on the player at zoom >= 1.
     Verified in play: pan, zoom out to the whole world, covers lift after the grant, Me recentres.
- KNOWN (pre-existing): the Golden Squirrel notice at the top overlaps the map panel's header text "You are here: ..." on a
  computer screen; it did so with the old map too. Ask her whether to move the notice or the header.
- NEXT: her word to publish (passport + boat v43 + map) -> publish (Alt+P) -> then Harbour Front / Italian squirrels.

# HANDOFF 2026-10-01 (16:35): cities round, part B - travel carts in, boat v42 in, nothing published

## Starter prompt for the new chat
Please read C:\Users\slard\roblox-props\HANDOFF_2026-10-01_CITIES_B.md (and _CITIES.md before it) and the memory notes
new-maps-travel-plan, squirrel-speech-bubbles, ask-before-studio-edits, chasing-rainbows-squirrels standing rules. Roblox
Studio is open on the live 1001 Squirrels place (Team Create, API access OFF). Everything below is IN THE PLACE but NOT
PUBLISHED (live = v829). Publish only on her word. Next: her verdict on the luggage cart, then (4) the passport, then (2) the Map.

## In the place since v829 (all unpublished)
- TRAVEL (tools/travel/install_travel_t1.lua v3, run as a PatchModule): Spawn_porto + SpawnDais_porto (the fourth acorn dais)
  at (232, -580) on the dry grass east of the plunge pool; workspace.Travel = TravelEvent, Points (TWO luggage carts:
  TravelCart_domaine at (427, -46) on the Hall of Fame lawn at the Chateau beside the gravel path, facing it, bound for Porto;
  TravelCart_porto at (239.5, -580) east of the Porto dais facing it, bound for France), TravelServer, TravelClient.
  Her calls: NO signs anywhere (the four signposts of v1/v2 are gone - "the space there is already cramped"), ONE travel
  point in France by the Hall of Fame, the carts show for everyone and only the hold prompt waits for Item_porto >= 1.
  Hold = fade to dark with the city name (TravelGui, DisplayOrder 30), server RequestStreamAroundAsync + PivotTo to the dais,
  Area + RespawnLocation set, NoMusic cleared in France / set at Porto, "arrived" -> fade in. Back to France = the LAST French
  section stood in: Area if French, else Item_frenchrank (1/2/3 kept by TravelServer from the Area attribute), else SavedArea.
  Item_porto is awarded by TravelServer the first time the player is down at Porto (Area == porto, no Parachute, root below
  SEA_Y + 12) through ReplicatedStorage.AwardItems (never the DataStore); it also fires PassportActivity "porto" (no catalogue
  entry yet, so nothing happens until step 4).
- SpawnReturnServer patched (live + boundary/build_spawnreturn.lua): south of z -300 is "porto"; target(): a player whose
  last area is porto respawns there once Item_porto >= 1, otherwise in ORDER[Item_frenchrank] or forest.
- BOAT SCRIPTS v42 (tools/boat/BoatServer.server.v2.lua 676 lines / BoatClient.client.v2.lua 366; install_boat_i6.lua):
  her four notes + one more, all verified in Studio play: (1) phones/VR: the seat's Throttle/Steer first, and when both are
  idle the thumbstick is read directly (steerInput: PlayerModule GetMoveVector, then hum.MoveDirection) as a camera-relative
  direction to go -> throttle = dot with the hull's forward, steer = dot with its right; the Sep 30 Device Simulator test
  passed with the OLD code, so the real-device failure is not reproduced here - she must try it on her phone after publish;
  (2)+(5) jump out within DOCK_R 24 of the jetty = back on the deck; farther out = you fall in the water and the boat is
  RELEASED (adrift: boats[p] -> adrift[m], seat.Disabled, server network owner, driftStep follows River.Line at DRIFT_SPEED 7
  with a pull back to the centre line, idle engine, wake; over the brink -> startFall(nil, m) -> breakUp -> wreckage; out of
  the box -> destroyed); leave(p, backOnJetty) is the one entry point (Occupant nil, Empty watchdog, Died, PlayerRemoving,
  new character); (3) the v40 jetty warnings (her three lines, 4th hold sails) are still in and still unpublished;
  (4) dockTake/dockFree: taking the boat hides every BasePart of River.BoatPreview (attribute DockT keeps the transparency)
  and disables its prompt; attribute Boat.DockBusy = userId; freed when the taken boat (even adrift) passes HALF_Z = -356 or
  is gone; take() refuses while the dock is busy.
- ZZ_TEST_Give44 is NOT in the place (tests used attribute one-liners instead, see tools/travel/TEST_ONELINERS.md).

## Verified today in Studio play (16:00-16:30)
Travel: cart prompt hidden before Item_porto; grant -> hold -> fade "Porto Nocciola" -> Porto dais (Area porto, NoMusic
true) -> hold the Porto cart -> fade "French Squirrel Country" -> the last French dais (Area forest, NoMusic nil). Her own
trip (she played while I coded, 20:04Z): boat -> falls -> Porto -> cart back -> landed on the Rue (frenchrank 2). Boat v42:
warning note on hold 1, seated on hold 4, moored boat gone (visT 1, prompt off, DockBusy = her id); W 5 s + Space -> in the
water at (155,1,-208), the empty boat went on (172,-225) -> (193,-262) in 6 s, dock freed after HALF_Z, wreck=2 at the falls.

## HOW TO INSTALL WITHOUT THE CLIPBOARD (the harness denied setclip.ps1 today)
Pack the installer as a PatchModule rbxmx (python in this chat: Folder <Name> + ModuleScript PatchModule, source =
"return function()\n" .. installer .. "\nend", CDATA; tools/travel/export/InstallTravel.rbxmx, InstallBoat.rbxmx,
InstallRound.rbxmx exist). Studio: Home > Explorer button (right end of the Home tab) opens the Explorer on the right;
right-click Workspace > Insert > Import Roblox Model > type the full path in File name > Enter; then type in the command bar
require(workspace.<Name>.PatchModule)() and Run; then workspace.<Name>:Destroy(). The computer-use `type` action pastes
text (it says "via clipboard" and leaves her clipboard as it was) - whole scripts can be typed into the command bar that
way; the Run button is at the right end of the bar's first line (y 740 for one line, 642 for a tall paste at this layout).
Explorer: the X at about (1352,196) - it did not close on the first try; check.

## Her words today (keep)
- "if you jump out of the boat, you should fall in the water, the boat should remain and keep down the river" (done, v42).
- "do not build a picture page; no need to do that" - show things by leaving the Studio camera on them instead.
- "I would like a different thing than a sign to show that you can travel between places, the space there is already
  cramped, maybe the travel point can be by the squire in the chateau area instead of in the forest?" -> "Yes, I like your
  suggestion 1" (luggage cart by the Hall of Fame; her camera was left on it at 16:30).

## Next
1. Her verdict on the cart (look, colours, stickers, the spot). Fix what she flags.
2. Publish on her word (v829 + travel + boat v42). API ON for the publish, then OFF and checked.
3. Step (4) passport: catalogue entries boat / falls / chute / porto (fire from BoatServer take / startFall / attachChute and
   the TravelServer award), Journal.describe lines, per-city sub-tabs under Outings / Completed / Clues once Item_porto >= 1
   (France = forest/village/domaine, Italy = porto; Italian Clues = "coming soon"). Patch the LIVE Passport scripts and the
   local passport/src + build_passport.lua the same way (keep Codex's work).
4. Step (2) the Map once she chooses (one chart per city + a small world overview, or one draggable mega map).
5. Her camera: restore with tools/cam_restore_shannon4.lua when she is done looking at the cart.
