# Treehouse decor + new-player retention - roadmap (agreed order, Oct 20 2026)

One change at a time, in this order. Each step: preview in a play test with close pictures -> Shannon approves -> install in
Edit -> she publishes (Alt+P) -> next step. Economy numbers: ECONOMY_AUDIT_2026-10-20.md (approved: rugs 100/300/1000, packs
Handful 25 R$=100, Pouch 75=330, Basket 200=1000, Treasure Chest 500=3000, Starter 50=500 + exclusive).

## Core path
1. Baseline - write down today's day-1 and day-7 retention (Creator Dashboard > Analytics > Retention).
2. Decor system + Basic rugs (Sunny Yellow, Pastel Blue): buy, save, swap; red rug stays free.
3. Cute rugs: Acorn Print, Tree Ring, Squirrel Footprints, Lavender Sprig, Cloud.
4. Fancy rugs: Peekaboo (twitching tail), World Map (Provence + Italy, maps addable), Acorn-shaped.
5. Robux acorn packs: Shannon creates 5 Developer Products and sends the IDs; route through Receipts.ReceiptRouter; packs never
   doubled by the invite boost. OPEN: old packs (Handful 150/22, Basket 500/79, Barrow 1200/149) off sale? Starter exclusive item?
6. Bottle nudge: a squirrel suggests tossing a message bottle in a new player's first session (reply waits tomorrow).
7. Roommate: the first squirrel you find moves into your treehouse and greets you by name (SquirrelBubble); now and then it
   leaves a small surprise present on the rug (Shannon: "people like little surprise gifts and prizes").
8. Mailbox + first 10 letters (forest squirrels): one letter a night from a squirrel you found, own voice, sometimes a gift or a
   hint about an unfound squirrel.
9. The rest of the letters in batches of ~20; Shannon edits each batch.
10. Planted acorn: planted on day one, grows one stage per visit day, never wilts.
11. Welcome Week presents: first 7 visit days (any 7) each unwrap a treehouse decor gift.
Check-in: compare retention with step 1, then pick from the parking lot.

## Parking lot (later, decide from the numbers)
Polaroid wall of found squirrels; "I'll finish it tomorrow" painting; squirrel birthdays; time-of-day life (morning bakery,
night lanterns, Friday Club Rana); Japan postcard + countdown; visiting friends' treehouses; first squirrel in the first
minute (36 % of new players leave before a first find).

## Progress
- Step 0 (economy audit): done Oct 20.
- Step 1 baseline (Oct 20, dashboard cohort table, cohorts Oct 12-17): 212 new players (19-53 a day, ~35 avg).
  Day 1: 6 came back = 2.8 % (Oct 12 1/53, Oct 13 1/46, Oct 14 2/19, Oct 15 0/21, Oct 16 0/28, Oct 17 2/45).
  Days 2-6: 0-2 players per cohort. Day 7: no cohort old enough yet. Earlier (Shannon, Oct 11): 33 % still playing at 5 min,
  20 % at 10 min. The onboarding funnel (workspace.Funnel, 6 steps: Joined / First squirrel / Five squirrels / Second area /
  All 44 in France / Reached Italy) has been sending since ~Oct 14 - still to read: average session time.
  Funnel (data to Oct 20 4:00, 176 new players): Joined 176 (100 %) -> First squirrel 113 (64 %) -> Five squirrels 78 (44 %)
  -> Second area 62 (35 %) -> All 44 in France 10 (5.7 %) -> Reached Italy 10 (5.7 %). 63 of 176 (36 %) leave without finding
  a single squirrel. Shannon's reading (the right one): read it by step rate - the start converts well (64 % find one, 69 % of
  those find five, 79 % reach a second area); the steep step is All 44 in France (16 %), and with 2.8 % day-1 return it is the
  same problem as retention: engaged players do not come back to finish. So the come-back features stay the priority; the
  "first squirrel in the first minute" idea goes to the parking lot.
- Shannon (Oct 20): "a handful of people really like the game ... most people not as much; we need to find things that will
  appeal to those players". Next: find out who leaves and what they try, from what is already logged - funnel split by
  Device (FunnelServer CustomField01), the Interact_* custom events (InteractServer, since Oct 14, split by Device / Cohort),
  and the mayor's letters - then choose features for them.
- Funnel, Device = Desktop (counts shown as sessions): 16 -> 11 (69 %) -> 8 (73 %) -> 8 (100 %) -> 3 (37.5 %) -> 3; 18.75 % reach
  Italy. Everyone else (overall minus desktop, approx.): 160 -> 102 (64 %) -> 70 (69 %) -> 54 (77 %) -> 7 (13 %) -> 7; 4.4 %.
  Desktop is only ~9 % of new players. Early steps are the same on every device; the gap is the long stretch to all 44
  (desktop 38 %, others 13 %). Tiny sample (3 desktop finishers). Next: the Phone (and Tablet) view.
- Funnel, Device = Phone (sessions): 59 -> 42 (71 %) -> 28 (67 %) -> 24 (86 %) -> 5 (21 %) -> 5; 8.5 % reach Italy. Phones do
  BETTER than average - not the problem. Left over (overall minus desktop minus phone, approx.): ~101 -> 60 (59 %) -> 42 (70 %)
  -> 30 (71 %) -> 2 (7 %) -> 2 (2 %). That group = Tablet / Console / VR / Unknown (FunnelServer logs a quick leaver whose
  device report never came as "Unknown"). Next: which of those it is.
- Funnel, Device = Tablet (FunnelClient: touch + shorter screen side >= 600): 96 -> 59 (61 %) -> 41 (69 %) -> 30 (73 %) ->
  2 (7 %) -> 2; 2.1 % reach Italy. Unknown: 5 -> 1 -> 1. Totals check (16 + 59 + 96 + 5 = 176).
  TABLETS = 55 % of new players and the weakest at every step (Italy: tablet 2 %, phone 8.5 %, desktop 19 %). At phone rates
  tablets would give ~8 Italy arrivals instead of 2. The HUD rules were measured at phone size (666x374), never at tablet size.
  Next (proposed): tablet check - Shannon sets Studio's Device Simulator to an iPad, I play-test, measure every element and
  send pictures; read-only. Then fixes one at a time.
- Shannon (Oct 20): surprised - she never plays on a tablet and never checked it; console is not enabled; the Device list showed
  no VR. Before tablet work: cross-check our "Tablet" label against Roblox's own Platform breakdown in the dashboard (our
  label is a screen-size guess; if some phones report a big screen they would be counted as tablets).
- Shannon (Oct 20): Roblox has the game at 16+ until it reaches 250 engaged players - so today's players are mostly older;
  "younger players" is not the tablet explanation (left: screen layout, speed). Today's numbers describe a 16+ audience.
- CONFIRMED by Roblox's own Acquisition breakdown (all time): tablet 280, phone 130 (iOS 83, Android 47), computer 80 =
  490; tablets 57 % (our funnel label said 55 %). Next: tablet check in the iPad Device Simulator.
- TABLET CHECK done Oct 20 (iPad Air 5th gen sim, 1180x820, France only; play test, nothing changed; Studio API access was
  off). Works: forest-start HUD, map, squirrel panel, album, squirrel card, Acorn Store, Passport, Gifts; croc rescue freed
  2 squirrels (+5 each) via the head pill. Problems: (1) ChaseGui Join (12,68 108x30) covers HintGui HintButton (12,64
  104x40) - both use the left corner on touch screens (ChaseClient PHONE / HintClient isMobile = TouchEnabled and not
  KeyboardEnabled), so it may happen on phones too; (2) panels are phone-sized on the big screen (store shows ~2 items,
  map small + right of centre, album names 10 px); (3) side note: squirrel card counter reads "40 / 77" with 88 squirrels.
  Croc rescue needs the player in the small space between the three cages (MaxActivationDistance 4; at 4.5 studs outside
  a cage no button) - a likely cause of "rescue is broken" on any device. Confirm per device with Custom events >
  Interact_Item "croc_rescues" split by Device.
- Shannon: "please test the rest of it too" (France). Not started - usage was 78 % weekly (over her 70 % rule), asked her.
  France prompts to test (45): Forest: Question boards (-5,-8), Forest Race (13,4), Zipline (-19,72,3), hoop/slingshot,
  Toadstool Run, treehouse. Rue: Baguette (189,-105), Post Office (190,-138; text box = on-screen keyboard), Cheese (205,-137),
  Cafe (202,-104), Glaces (248,-64), Hat shop (inside 300,344,-153), Dress shop (inside 295,393,-101), Bookshop (340,303,-140),
  River boat (159,-166). Chateau: Garden (384,-128), Tractor/hens/pump (512,-59), Mill (583,-53), Chapel (647,-164),
  Sandstone Climb (498,-243), Basket lift (492,73,-250), Hang glider (480,82,-255), Zipline home (678,82,-154), Travel board
  (427,-46). Japan airport taxi (445,-44) is gated to Shannon by PreviewAccess - skip.
- Shannon chose fixes 1 + 3 (not the croc distance: "I see people freeing the squirrels all the time").
  tablet1 INSTALLED in Edit Oct 20 (tools/tablet/tablet1.lua; backups HudBackup.HintClient_pre_tablet1 /
  ShopClient_pre_tablet1): Hint sits under the Baguette Chase button on touch screens (y 106-146 on iPad); Acorn Store
  440x560 at UIScale 1.2 on tablets. Verified in an iPad play test. UNPUBLISHED - phone-size check next (Hint move affects
  phones), then her publish. Windows still to enlarge on tablets, one at a time: map, album, passport, others.
- tablet2 INSTALLED (tools/tablet/tablet2.lua; backup HudBackup.ChaseClient_pre_tablet2): Shannon wanted Hint ABOVE the
  Baguette Chase button and ONLY on iPad. HintClient restored to its exact pre-tablet1 source (phones untouched); ChaseClient
  on tablets only (PHONE layout + short side >= 600) puts Join under Hint: Hint y 64-104, Baguette Chase y 112-142 (iPad
  play test). "Store cut off at the bottom": her Studio viewport crops the simulated iPad (scrollbar; joystick and jump
  button cut too) - in the real 1180x820 frame the store ends at y 746. Phones: the old overlap probably exists there too
  (same corner, same code) - not touched; check at phone size only if she asks.
- tablet3 INSTALLED (tools/tablet/tablet3.lua): Shannon "still too big and cut off at the bottom" -> "maybe 20 % bigger" ->
  tablet store 440x420 at UIScale 1.2 (528x504 on iPad Air, y 158-662), previewed on her real screen first. All three
  (tablet1-3) in Edit, UNPUBLISHED. Her Studio viewport is shorter than the simulated iPad (scrolls) - judge bottoms there.
- Post office on iPad (she flagged it): the box's "Open" prompt pill (PromptTouch, DisplayOrder 30, head stack, x 317-559
  y 344-391) stays on screen while the letter is open and sits ON the writing box (x 386-794 y 335-469; PostOffice gui
  DisplayOrder 7). Fix idea: PostClient hides the prompt locally (prompt.Enabled=false) while gui.Enabled. Not done - asked.
  Untestable in Studio: the real iPad keyboard may cover the Send button (y 513-555) while typing (tapping the shade puts
  the keyboard away). Also: first press on the pill missed once (pill follows the head every frame).
- Keyboard test (iPad sim, writing box focused): Studio draws a stand-in keyboard with BLANK keys (Shannon saw it; Studio's
  placeholder, a real iPad draws its own keys). Roblox reports OnScreenKeyboardPosition (0,407) size (1180,413): it covers
  y 407-820, so the Send button (y 513-555) is hidden and the writing box (335-469) half hidden while typing.
  Fix idea: PostClient slides the panel up while UIS.OnScreenKeyboardVisible so the box + Send sit above the keyboard
  (shift ~156 px on iPad Air), plus hide the post box prompt while the letter is open. Asked her: iPad only or phones too.
  Pill first-press miss happened twice in Studio (likely the Studio window taking focus on the first click).
- Shannon: "please just fix the ipad version for now, we will check and tackle phone next". tablet4 (lift 158) INSTALLED,
  then replaced by tablet5 (tools/tablet/tablet5.lua, rebuilt from HudBackup.PostClient_pre_tablet4): on TABLETS while the
  keyboard is out the letter panel sits at y 60 and shrinks to fit (iPad Air: 0.82; box y 175-284, Send y 320-355, Studio's
  keyboard bar from ~365, reported keyboard top 407); keyboard away -> scale 1, centred (Send 513-555); post box prompt hidden
  while the letter is open and back after. Verified in an iPad play test + her real screen. UNPUBLISHED.
- NEXT (her order): phones - the Hint/Baguette overlap and the letter keyboard at iPhone size.
- Italy check on iPad (Oct 20): crab cast/pull/sell, sea glass pick-up, Bella's panel (made the parfum), bottle write + toss -
  no overlaps except the bottle kiosk pill over the "To:" row. Fixed for PHONES AND TABLETS: touch6 (BottleClient hides the
  kiosk prompt while the panel is open). reveal7 + 7b: sea glass PICK-UP REVEAL (her idea: round gold-rimmed window mid-screen,
  piece spinning, gold diamonds on the top/sides, "Name! / You have N", acorn chime, 3 s / rare 3.8 s, flat screens; VR keeps
  the toast) + PromptClient hides prompt pills while PlayerGui.PromptsHidden; bottle texts -> "Expect a reply in 24 hours"
  (4 lines; replies really come after the 09:00 UTC daily reset). gifts8: Gifts card UIScale 1.3 on tablets.
  All in tools/tablet/*.lua, backups in ServerStorage.HudBackup, ALL UNPUBLISHED.
- gifts9: Gifts row buttons 104x28 on tablets (she: "too fat ... no space between them"). reveal10: the pick-up reveal's
  piece now floats in the REAL world inside a gold ring (no fill) - real Glass (Transparency 0.4) for sea glass, textured
  AI-generated shells/pearl from ReplicatedStorage.SeaGlassRevealPieces (seaglass, shell_scallop, shell_spiral,
  shell_cowrie, pearl; made with Studio generate_mesh Oct 20, she approved them). A ViewportFrame cannot draw Glass or
  light through it. The beach pieces are UNCHANGED (she likes them). NOTE: the MCP screen_capture does not show parts
  parented to the camera - check the reveal on her real screen (computer-use screenshot). She: "that looks great".
  reveal10b: glass Transparency 0.4 -> 0.25 (she: "a little less see through").
- PHONES (Oct 20): phone11 = Hint on top / Baguette Chase under it on phones too (it covered Hint on every phone);
  phone12 = mailbox on phones (letter slides up so the writing box sits above the keyboard; Send back after Done; post box
  prompt hidden while open, all touch screens) + Baguette Chase goes under the Keeper/Wise medal (BadgeButton.Medal, drawn
  under Hint); phone13 = on PHONES with the medal showing, Baguette Chase sits beside Hint (the column hit the
  QuestionNews.QuestionReminder note). Verified: Galaxy S22 Ultra 678x339, iPhone 7 667x375 - no overlaps.
  phone14: iPhone XR 802x414 puts the question note at the TOP (x 171-631 y 64-112), so if it appears before the medal,
  Baguette Chase goes under the medal instead (sticky for the visit). Verified on the XR in both orders - no overlaps.
  (The note finds its own clear spot only when it appears; my tests forced the medal on afterwards.) XR mailbox not yet checked.
  Shannon then: "the medal cannot go between the bagette race and the hint" / "I want the baguette race to be to the RIGHT of
  the hint" / "that's just on mobile" -> phone15+16: PHONES = Baguette Chase beside Hint (x 124-254 y 69-99), medal under
  Hint; TABLETS = Baguette Chase under Hint, medal under Baguette Chase (BadgeCaseClient), medal hides while the question
  note sits on its spot. ChaseClient phone12-14 medal logic removed (rebuilt from ChaseClient_pre_phone12). XR: no overlaps.
- acorn17: AcornClient's flight aimed at a fixed sum from the old 3-square bar = the Gift button now; aims at
  HudBar.Bar.Purse (XR: counter centre 768,88 vs gift 700,32 vs old aim 656,32). All devices.
- medal18: Shannon agreed - NO medal on phones and tablets (touch layout); computers keep it; the title pill opens the badge
  case everywhere. Verified on the XR as a pretend Keeper #3: medal stays hidden.
- XR mailbox checked: post box button hidden, box 59-175 above the keyboard while typing. chase19: ChaseGui DisplayOrder 8 -> 6
  on touch screens (beside Hint it poked through the letter / store / squirrel windows at 7) - verified dimmed + behind the letter.
  Found, pre-existing, NOT fixed: on the XR the letter panel (scale 0.87, y 20-394) reaches down under Roblox's own hotbar.
- hud20: touch screens - acorns above Passport in the HUD column. phone21/21b: PHONES - a "Send" button beside the letter while
  typing (right of the panel, level with the box; grey until sendable); taps are caught through UIS.InputBegan too (the tap that
  closes the keyboard never reaches a GuiButton). Verified on the XR: sent, 110 -> 80 acorns, "Posted" toast. Her rule: windows
  may cover Roblox's tool hotbar. hud22 + hud23 (PHONES, GiftsClient): top row Passport | squirrels; column squirrels, acorns,
  map, Gift (Passport took the Gift's spot; Gift at the bottom; squirrels LayoutOrder -3). Acorn flight follows the purse
  (XR aims 768,88). Tablets: acorns, Passport, squirrels, map + Gift beside the top. Computers unchanged.
- PUBLISHED by Shannon Oct 20 ~09:40 local: PlaceVersion 1590 (everything above). Post-publish iPad check: HUD Gift beside
  the top, acorns / Passport / squirrels / map column, Hint with Baguette Chase under it, no medal, no overlaps; store 1.2x
  at y 158-662.
- Still open: the rest-of-France tablet pass (list above); other iPad windows (map, album, passport) bigger?; then back to
  the roadmap (rugs etc.). Parking lot: more animated pop-ups for tablet players.
- Retention read (Oct 20, cohorts Oct 13-17, all BEFORE v1590): Day 1 = 5 of 159 new players (3.1 %) - flat vs the 2.8 %
  baseline; a few players return on days 2-4. First cohort with the tablet/phone fixes = Oct 20 (dashboard lags ~2 days).
  Re-check ~Oct 27-28: sum Day 1 for cohorts Oct 20+ and compare with 5/159.
- Shannon's insight (Oct 20): tablet players may love lots of animated pop-ups (why a "catch a star" game is so popular) -
  movement/navigation is harder on a tablet. Parking-lot idea: more animated pop-ups/reveals (lightweight 2D, not heavy 3D).
