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
- STEP 2 INSTALLED Oct 21 (tools/decor/rugs1.lua; backups PassportClient_pre_rugs1 + TreehouseClient_pre_rugs1; new
  workspace.Treehouse.DecorServer + DecorClient + RS.DecorAction), PUBLISHED by her Oct 21 ~20:29 UTC - reshaped by
  Shannon in the previews:
  * a "Treehouse" tab in the Passport beside Wardrobe (the Passport's own fit() sizes the row - five tabs fit);
    appears once Item_tree_done >= 1; summary "Your Homebase, your way"; mini-rug badge on the tab.
  * the tab is the COLLECTION: Place / Store only, NO buying there. Buying happens out in the game (from the Cute
    tier on). THREE NATIVE FREE RUGS (her call - "I thought sunny gold and blue were free"): Classic Red (default),
    Sunny Yellow, Pastel Blue. Storing all = bare floor. Ledger: placed = Item_rugon_<id> (red = no line),
    bare = Item_rug_bare; AwardItems only.
  * first-build mini tutorial (her ask): once ever (Item_tree_decortip), 6 s after Item_tree_done - a toast
    ("Your Homebase is yours to decorate! Open your Passport -> Treehouse...") + the Passport button glows ~60 s
    or until the Passport opens.
  * VERIFIED in an iPad play test end to end: tip fired once + saved; tab row spaced by the Passport itself; Place
    Sunny -> floor yellow; Store -> bare; Place Red -> default back. NOTE: dropping an interact prompt on the rug
    was her call ("it should not just have an interact button"); no Acorn Store row (free rugs need no shop).
  * Her idea logged for later: Outings could hold sub-tabs ("What's next?" / "Completed") to free a top-row slot.
  * The Cute tier (step 3) adds the first PAID rugs: sold in the world, they appear in the tab once owned.
  * Oct 21 late: workspace.Treehouse.ResetRound bumped 3 -> 4 (was 3; ResetUserIds 9611145467 unchanged) so Shannon
    relives the first build on her device - the reset also claws back Item_tree_decortip, so the tip replays. Runs
    once on her next join after her publish. Published ~20:34 UTC.
  * rugs2 INSTALLED Oct 21 late (tools/decor/rugs2.lua; backups TreehouseClient_pre_rugs2 + DecorClient_pre_rugs2):
    on her device the tip toast showed the BANNED fuzzy gold - rugs1 put UIStrokes on text objects without
    ApplyStrokeMode.Border (default Contextual strokes the LETTERS). Fixed on the tip toast + the tab's Place/Store
    buttons; verified crisp in a play test. The tip had fired at her JAPAN spawn because her save still said "built"
    for the seconds before the round-4 reset clawed it (a reset-list race, not normal play; the flag was clawed too,
    so the tip replays properly after her rebuild). LESSON for every future toast: a UIStroke on a TextLabel/TextButton
    MUST set ApplyStrokeMode.Border - the old slingshot-note rule (its fix, the badge toast and the question note were
    checked and remain intact). (Correction: she saw it on DESKTOP - she owns no tablet yet; computer, phone and VR only.)
  * rugs3 INSTALLED Oct 21 late (tools/decor/rugs3.lua; backup TreehouseClient_pre_rugs3): "I did not get any tutorial
    or note after the treehouse was complete" - the rugs1 tip latched a SESSION boolean when it mis-fired at her
    spawn (the reset race), so her rebuild in the same session was blocked. Now the ledger flag is the only lasting
    latch, the state is re-checked after the 6 s wait (a claw-back during it cancels the tip), and the toast only
    shows when the server GRANTS the flag. Play-test proved both: claw mid-wait -> silent; rebuild same session ->
    tip fires. HER SAVE after her session: done=1, decortip=0 - after she publishes rugs2+rugs3 and REJOINS, the
    owed tip greets her ~6 s after spawn, crisp.
  * ResetRound bumped 4 -> 5 (her ask, "reset me to no treehouse again so I can test it again"): her next join after
    the publish claws the treehouse + flags; with rugs3 the pending spawn tip is cancelled by the claw and the
    tutorial arrives at the rebuild's completion - the clean first-build test. Ships with rugs2+rugs3 in one Alt+P.
  * LIVE-SERVER LESSON (Oct 21 night): her rejoins kept landing in servers still running the OLD version - the reset
    "didn't happen" and old toasts showed. The cure is hers: game page -> Shut Down All Servers after each publish.
    (Rounds 5-7 were burned learning this; round 7 completed properly - fanfare + toast on her desktop.)
  * rugs4 INSTALLED Oct 21 night (tools/decor/rugs4.lua; backups TreehouseClient_pre_rugs4 + DecorServer_pre_rugs4):
    the toast was NOT the tutorial she asked for ("that is not what I wanted" / "it should be when you climb into
    the treehouse for the first time"). The one-toast tip is REPLACED by the guided first-climb chain (previewed,
    then installed, both play-test proven): first climb into the finished room -> welcome note + Passport button
    glows -> Passport open -> Treehouse tab glows -> tab open -> "Pick a rug for your floor!" + Place buttons pulse
    -> first rug placed -> sparkles on the rug + "Looks lovely in here!". Half-done chains re-arm on the next climb
    (after leaving the room) until the first rug is down. DecorServer awards Item_tree_decortip on the FIRST place
    (however reached), so self-taught players are never nagged; a treehouse reset claws the flag to re-arm it all.
    ResetRound bumped 7 -> 8 for her live test; ships with rugs4 in one Alt+P + Shut Down All Servers.
  * rugs5 INSTALLED Oct 21 late night (tools/decor/rugs5.lua; backup TreehouseClient_pre_rugs5): round 8 reset her,
    she rebuilt, climbed in - crickets. CAUSE: rugs4's watcher checked the once-ever flag ONCE at session start; her
    save still carried round 7's flag for the first seconds, the watcher quit for the session, and the reset wiped
    the flag AFTER - Studio accounts start blank, so tests never hit that order. The watcher now never quits (idles
    while the flag is on, arms whenever the tutorial becomes owed, survives mid-session resets). Proven in Studio
    against her exact join order: flag-on-at-join -> wipe -> rebuild -> climb -> greeting + glow fired.
    HER STATE: done=1, decortip=0 - the tutorial is OWED as her save stands. NO round 9 needed: publish rugs5,
    Shut Down All Servers, join, CLIMB IN (no rebuild). ResetRound stays 8 (consumed).
    LESSON: test flows against a save that arrives mid-state, not only a blank account; a once-ever watcher must
    never latch on a session-start read.
  * rugs6 INSTALLED Oct 21 (evening session after the handoff; tools/decor/rugs6.lua, helpers also in
    rugs6_parts.lua; backup TreehouseClient_pre_rugs6): she saw the rugs5 chain live and restyled it in a long
    play-test preview. The note: no "You can decorate" - a big card in the MIDDLE for 6 s (gone at once when a panel
    opens, above the prompt pills): "Welcome home!" / "The squirrels have opinions about your floor... Open your
    Passport and decorate it however you like!"; the last word uses the same card. The Passport button: its WHOLE
    box breathes gold (light <-> darker gold) behind its picture, its word dark while it does; 10 little firework
    sparks burst round it every breath; a 4-degree wiggle every other breath; a short green NEON arrow (3-layer tube,
    the board arrow's curve, last 60 %) points at it from the left, bobbing away from it. The Treehouse tab and the
    Place buttons: a green layer breathing between two greens with a deep-gold border, word same size in cream.
    TURNED DOWN on the way (do not offer again): a ring outside the button (spilled onto the row below), a 12-degree
    wiggle ("TOOO much"), a word that grew, a fill fading back to the pale cream ("should not go complete white"),
    gold rings inside the edge, a round light ("the glow is a circle", corners stayed brown), a thin two-stroke arrow
    over the tab ("looks bad"). A UIScale on a HUD-column button pushes the buttons under it - never scale them.
    Play-test proven end to end (house built on the test server - Studio has no data access - avatar moved into the
    room): note + gold box + arrow at the climb -> Passport open restores the button exactly -> green tab -> Place
    buttons green + "Pick a rug" -> Sunny Yellow placed -> DecorServer awarded tree_decortip -> last word. No errors.
    NOT YET CHECKED at phone size (the note and arrow shrink there by design). She HAD placed a rug in her live test
    (tree_decortip on her save), so on her word ResetRound was bumped 8 -> 9 (ResetUserIds 9611145467 only). Ships
    with rugs6 in one Alt+P + Shut Down All Servers; her next join claws her treehouse back to zero, she rebuilds,
    climbs in, and the new chain plays from the start. (She published it 23:13 UTC Oct 21 and tested on desktop.)
  * rugs7 INSTALLED Oct 21 late (tools/decor/rugs7.lua; backup TreehouseClient_pre_rugs7): "for the desktop the arrow
    does not work because the icons are arranged differently" -> where the HUD is a ROW (the Gifts script's test: not
    a touch screen - computers AND VR) the arrow is left out and a cartoon iris closes the screen to a gold-rimmed
    circle round the Passport for ~1.6 s, then opens (early if a panel opens); touch screens keep the arrow. Layers:
    prompt pills 30 < iris 31 < note 32. She asked "what are you talking about an iris and a taxi?" - say "the screen
    goes dark except a circle round the Passport", not "iris"; never name on-screen bystanders (the Japan airport-taxi
    prompt) without saying what they are. Touch path play-tested after install (card + box + arrow, no iris, cleanup
    on Passport open, no errors); the desktop path only seen as the preview (Studio stays on the iPad simulator) - her
    desktop test is the proof. She had placed a rug again in her rugs6 desktop test, so on her word ResetRound was
    bumped 9 -> 10 (her account only); ships with rugs7 in one Alt+P + Shut Down All Servers.
  * hud34 INSTALLED Oct 21 late (tools/tablet/hud34.lua; backups <script>_pre_hud34 for PassportClient, DecorClient,
    TreehouseClient, HintClient, ChaseClient, BadgeCaseClient). PHONES (touch, short side < 600): her phone test - the
    Treehouse page "is not scrollable because it overlaps with the icons at the bottom" (the 284 px rug list spilled out
    of a 112 px page, over the jump button and Reset progress) and "the passport open model on the cell phone is too
    small" -> the open Passport reaches to 8 px from the bottom (was 92; 215 -> 299 tall on a 667x375 phone), and while
    it is open Roblox's tool bar (Backpack) and screenshot bar (Captures) and ResetGui step aside, restored on close;
    the Treehouse page lives in a ScrollingFrame "DecorList" (Outings' gold bar), the tutorial's "Pick a rug" line
    inside it. Her rule recalled: windows may cover the bottom bar on phones. COMPUTERS + VR (the HUD row): "the hint
    button should go above the baguette button; just get rid of the medal completely" -> Hint at 12,64 (left, under
    Roblox's buttons), its message at 12,170, Baguette Chase measured to just under Hint; NO_MEDAL = true on every
    device (the title pill opens the case). Proven after install at phone size (299 tall, the three step aside and
    return, list scrolls, no errors); the computer layout seen as the preview only - her desktop check is the proof.
    KNOWN, not fixed (pre-existing on computers + tablets): the camera's album panel starts under Hint at the Baguette
    Chase button's spot - offered as a separate fix. Studio tip: in the phone simulator MCP clicks on Passport tabs
    do not land - select the tab with GuiService.SelectedObject and press Return. PUBLISHED by her (Oct 21 late).
  * hud35 INSTALLED Oct 21 late (tools/tablet/hud35.lua; backups ChaseClient_pre_hud35, CameraClient_pre_hud35), her
    "make the other mentioned fixes now": Baguette Chase under Hint on PHONES too (was right of Hint); the camera album
    panel starts under the Baguette Chase button wherever it shows, and on a phone (where that would hit the joystick
    ring, y 282) it sits BESIDE the Hint/Baguette column at (150,64). Phone play test: Hint 64-104, Baguette 112-142,
    panel x 150-294 y 64-210, the button hides outside France, no errors. Her ask "make sure the baguette chase button
    is only on the screen in the french map" - it already was (ChaseClient frenchMapHudAllowed on every Area change);
    my previews forced it visible in Japan. iPad: still under Hint (she once said "right of Hint, as it is now" - it
    was under; not changed). Waiting for her Alt+P.
  * mail1 INSTALLED Oct 21 late (tools/decor/mail1.lua, helper in mail1_parts.lua; backup TreehouseClient_pre_mail1):
    "we need a cute mailbox in front of the treehouse please" -> each player's own (drawn by TreehouseClient with the
    ladder, from the first piece): L(9.5, 0, 23), right of the ladder mirroring the sign, facing the path, a rock 4 studs
    behind; a chunky rounded mint box (2.0 x 1.05 x 2.8 + dome) on a wood post, cream arched door with a 🌰 and a gold
    knob, red flag UP at the back of the outer side, the player's DisplayName on both sides (dark green FredokaOne, no
    stroke; on the +X face the canvas's RIGHT edge is the back end - keep the name off the pole), five flowers at its
    foot. Two preview rounds (round 1: name hidden by the pole, box too small). Proven after install: absent with no
    pieces, appears with the first piece, no errors. Not interactive yet - roadmap step 8 (letters) can use it (flag
    up = a letter waiting?). PUBLISHED by her with hud35 (01:22 UTC Oct 22).
  * mail2 INSTALLED Oct 22 (tools/decor/mail2.lua, helper mail2_parts.lua; backup TreehouseClient_pre_mail2): she saw
    mail1 live - "cute but can we make it wood, so that it matches the treehouse" + "it is sitting right behind a rock,
    so it is hard for the player to access it" (players walk up from Spawn_forest, straight in front at local z 110;
    the big rock x 7-12 z 27-33 stood between them and L(9.5, 23) - I had called it "behind"; +z is the FRONT). Now
    L(4, 24.5), just right of the ladder, nothing in front; honey planks C(184,140,90) ("a little lighter, but still
    matching"), a WOOD dome, door C(122,86,50) with the acorn, gold knob, red flag, CREAM nameplates with the name in
    dark ink on both sides, flowers. Proven after install (spot, colour, name, no errors). PUBLISHED 01:37 UTC Oct 22.
  * hud36 INSTALLED Oct 22 (tools/tablet/hud36.lua; backups HudBarClient_pre_hud36, GiftsClient_pre_hud36): "on phone
    and tablet ... the acorns should be top right corner, the squirrels should be under that" -> touch screens: purse -2,
    squirrels -1, Passport 0 (GiftsClient's phone squirrelsUp to -3 removed). Proven after install: phone 667x375 column
    acorns / squirrels / Map / Gift, Passport in the top row; iPad Air column acorns / squirrels / Passport / Map, Gift
    beside the top; no errors. Note: the tablet coffee/zoomies pills (pills29) sit at a fixed y 64 - under the Gift,
    which is now beside the squirrels, no longer beside the Passport - her answer: "Keep the coffee/zoomies pills where
    they are, under the Gift." PUBLISHED 01:37 UTC Oct 22 (with mail2).
  * mail3 INSTALLED Oct 22 (tools/mail/mail3.lua; source copies Letters.lua / MailServer.lua / MailClient.lua, her
    readable list LETTERS.md; backups TreehouseClient_pre_mail3, GiftsClient_pre_mail3) = roadmap step 8, the letters.
    "Periodically we will send the player a letter ... notify the player that they have mail ... an animated letter fly
    out and open on the screen" + on other maps her exact note "You have mail. When you get the chance, check your
    mailbox at Homebase." + "they should not accumulate" + the sender's own face in the corner. workspace.Mail:
    Letters (10, her approved words; ADD AT THE END ONLY - the waiting letter is saved by number), MailServer (one a day
    on the daily card's day, from a FOUND squirrel, welcome at the first piece; one waits at a time, the next the day
    after it is read; ledger Item_mail_<id>, mail_wait, mail_day, mail_read; gifts via AwardAcorns; RemoteFunction
    RS.MailAction; copies the sender's mesh to RS.MailPortraits for the stamp), MailClient (flag up/down, gold Highlight,
    bobbing ✉ "1" tag hidden while the pill shows, top note once per letter per session, "Check mail" Custom prompt on
    Box; 3D envelope pops out of the Door, flies to the screen, seal pops, flap folds, letter slides out and unfolds,
    stamp = ViewportFrame of the sender; OpenPanel "mail", closes if another panel opens). TreehouseClient: mailbox
    parts named Box / Door / Flag (Model, pivot FlagPivot). GiftsClient MODAL + mail. Proven after install (iPad play
    test): tree_p1 -> welcome delivered (mail_wait 1), flag/glow/tag/prompt on; Check mail -> letter with the Ranger's
    face, 110 -> 125 acorns; Close -> flag down 90°, glow + tag gone, mail_read 1; second check same day -> "No new mail
    yet ... check back tomorrow!"; no errors. PHONE size not looked at yet (built to scale down to fit). PUBLISHED by her ~02:10 UTC Oct 22
    (servers shut down).
  * gordo1 INSTALLED Oct 22 (tools/gordo/gordo1.lua; sources Lines.lua / GordoServer.lua / GordoClient.lua; new scripts
    only, nothing backed up because nothing existing changed) = roadmap step 7 the roommate, as Shannon redefined it: "Gordo
    squirrel, moves in to 'watch the house while you are way' once the player has traveled to Italy- after about 1 minute
    of Italy game play, a funny message pops up about it. when they return home to the treehouse, Gordo is in there to meet
    them and periodically says funny things using the speech bubble." + four spots in turn ("First inside where he is now,
    once on the porch, one down by the ladder, once sitting in the chair") + "he should only change location if the player
    leaves sight of the treehouse then returns". workspace.Gordo (ItalySeconds 60): Lines (her words to edit: italy note,
    firstGreet, 4 greets, 12 chatter), GordoServer (seconds in Area "porto" count while the room's walls stand -> Item_gordo_home
    1, RS.GordoMovedIn "moved"; client "met" -> 2; RS.GordoHome = coloured bones-only copy of gordo_squirrel_color),
    GordoClient (paper note with his face, OK/14 s; Gordo drawn locally in Treehouse_local.GordoRoommate at SPOTS inside
    L(0,10.5,-6.3) / porch L(-5.5,10.5,15) / ladder L(-3.4,ground,22.6) / chair cushion L(-7,12,3.6); SquirrelAnim's idle +
    head turns to you; "left sight" = >140 studs from the house AND (house off screen OR >320 OR Area ~= forest) - from
    Italy the camera still pointed at the house, hence the last two; greets once per return in that spot's area, chatter
    every 25-40 s, never while OpenPanel/letter/note is up; the armchair cushion's CanTouch off while he sits in it; first
    visit inside, later sessions start at day % 4). Her squirrel sound plays with each bubble (SquirrelBubble). Proven
    with the INSTALLED scripts: not home before Italy, note at 61 s, first greeting at home, gordo_home 2, no errors; the
    four-spot cycle + mailbox-trip-moves-nothing + chair seat proven in the preview round 4. PUBLISHED by her with wall1 (03:21 UTC Oct 22).
  * wall1 INSTALLED Oct 22 (tools/portraitwall/wall1.lua; sources WallClient.lua, decor_wall_row.lua, ../gordo/GordoClient.lua
    + Lines.lua; backups PortraitServer_pre_wall1, DecorServer_pre_wall1, DecorClient_pre_wall1, GordoClient_pre_wall1,
    Lines_pre_wall1). Shannon: "when you sit for a portrait, that portrait gets put on the wall in the treehouse (as well as
    on the easel by the river) ... in the treehouse menu so you can store it ... or keep it hanging there" + no name plaque
    ("you don't have name plaques under pictures in a home") + "include gordo with a button of 'evict Gordo' ... another
    button to 'Invite Gordo Back'". PortraitServer: hang() sets PortraitWallKey / PortraitWallVariant on the sitter; at join
    wallPortrait() finds the newest painting (easels' list, else the pending_u<uid> receipt when its target <= Item_portrait -
    a READ of the PortraitWall store, never a write) and prepareModel()s it; retireUnusedModels keeps players' wall keys.
    WallClient (workspace.Treehouse, Client): the easel's own Picture (cloned from Slot1, PixelsPerStud 140/1.5) on a 3.45 x 3
    canvas in a gilt Metal frame C(214,176,60), back wall centre L(0,16.1,-9.3), facing the door, above Gordo; hidden when
    Item_wall_bare = 1 or no walls; VR / no-model fallback = AvatarBust image. DecorServer: "wall" store/hang
    (Item_wall_bare) and "gordo" evict/invite (Item_gordo_out, only once gordo_home >= 1). DecorClient: WALL row (bust thumb in
    gold, On the wall/Stored, Store/Hang; "Sit for one with the painter by the river" without a portrait) and ROOMMATE row
    (only after Gordo moved in; his face, Watching your house / Back in the forest, sulking, Evict Gordo / Invite Gordo
    back); subtitle "Place a rug, hang your portrait, or store them for later." GordoClient: evicted = waits for the Passport
    to close, says Lines.evicted, gone 3.6 s later; invited back = Lines.welcomeBack as his next greeting. Proven with the
    INSTALLED scripts in one play test: a real sitting -> key set at hang (13 s); Italy minute -> note at 61 s; home: painting
    with the 3D sitter + Gordo's first greeting; Store / Hang; Evict (stays till the Passport closes, parting line, gone);
    Invite back -> welcome-back line; no errors server or client. NOT testable in Studio: the join-time read of a saved
    sitting (no DataStore access) - checked by reading only. PUBLISHED by her (03:21 UTC Oct 22), servers shut down.
  * shelf1 INSTALLED Oct 22 (tools/shelf/shelf1.lua; source ShelfClient.lua; backups DecorServer_pre_shelf1,
    DecorClient_pre_shelf1). Shannon: "2 types of book shelves (2 styles to pick from) where we will store souvenirs and
    trophies like a little keeper of the great acorn award and an award for saving the baby squirrels from the croc".
    Rounds: part-built trophies TURNED DOWN ("blocky / cheap", "too big and bulky", "the gold looks wrong"; "nope, not a
    golden baby"); Studio's AI mesh tests (gold key fine, acorns never came out gold) parked in
    ServerStorage.TrophyTests_unused; then SHE made the three in Meshy (zips in Downloads). Pipeline: roblox-props/meshy/
    prep_trophy.py (Blender 5.2 via run_blender.py; the key FBX crashed Blender until use_custom_normals=False, use_anim=False)
    -> 9000 tris, 1k PBR maps, upright, 1 unit tall -> Desktop\Trophies\*.fbx -> her File > Import 3D (came in WITH full
    SurfaceAppearance: colour/metal/rough/normal) -> ReplicatedStorage.TrophyModels {Acorn, Key, Rescue} anchored, 1 stud.
    ShelfClient (workspace.Treehouse, Client): left wall between the back corner and the window, F0 = L(-9.3,10.5,-5.4) yaw 90;
    Bookcase (4.6 x 6.6, books, plant, warm light; trophies at eye level) or Plank Ledges (3 honey planks on brackets);
    trophies centred, only once earned: Keeper = Acorn on a walnut base + brass plaque (Item_passport_keeper or ChampionNo),
    Swamp Rescue = Rescue cup TURNED 180 so its squirrel-and-croc plaque faces out (Item_croc_rescues), Guardian = Key in a
    walnut stand + brass keyhole plate + plaque (PortoKeeperTitle). DecorServer "shelf" bookcase/planks/store
    (Item_shelfon_planks, Item_shelf_bare; nothing = bookcase). DecorClient SHELF rows between RUG and WALL (little style
    pictures, Place/Store); subtitle "Place a rug and a shelf, hang your portrait, or store them for later." Proven with the
    INSTALLED scripts: bookcase + all three trophies; Place planks / Store / Place bookcase all work; no script errors.
    WATCH: the server logged "Invalid TexturePack source textures. PBR textures may not be visible" (fresh uploads still
    processing?) - check the gold in the live game. PUBLISHED by her 04:14 UTC Oct 22 (servers shut down).
  * shelf2 INSTALLED Oct 22 ~05:40 UTC on her word, PUBLISHED with shelf3 ~13:10 UTC (tools/shelf/shelf2.lua = shelf2_head.lua + ShelfClient.lua;
    backups ServerStorage.HudBackup.ShelfClient_pre_shelf2 + folder TrophySA_pre_shelf2 with the three original SAs).
    Proven with the INSTALLED scripts in a play test (tablet mode): all three trophies on the bookcase, a real tap on the
    cup opened its card, x closed it, the TexturePack error gone from server start, no script errors. Shannon on live: "the trophies do look flat", "they look orangy" +
    "can we also make them so if you click on them it zooms in and makes them bigger". CAUSE: the TexturePack error was MY
    leftover test model (ServerStorage.TrophyTests_unused, a placeholder MetalnessMap) - not her trophies. The real cause:
    lower graphics levels (tablets/phones/Auto) draw only a SurfaceAppearance's colour map; her Meshy gold kept all its shine
    in the metal map, so colour-only = flat beige, and the warm shelf light made it orange. FIX: the shine baked into the
    colour maps (roblox-props/meshy/bake_gold.py: Cycles, Blender's studio.exr, view from above the surface, baked FROM her
    full-detail Meshy model onto the 9000-tri one, normal map off, margin 48 - baking from the simplified mesh showed its
    triangles as fine cracks when drawn big; then gold_grade.py: a gold ramp where metal+warm, silver ramp for pale metal,
    original colour where not metal). SA = ColorMap + flat-ish RoughnessMap only (ids in roblox-props/meshy/
    gold_maps_uploaded.txt). Shelf light C(255,244,228). LOOK CLOSER: tap/click a trophy -> card like the portrait viewer
    (ViewportFrame, trophy turning 30 deg/s, zooms in over 0.5 s, drag to turn, title + one line, x / Esc / any other panel
    closes, OpenPanel "trophy"); not in VR. ClickDetectors DON'T fire on these client-only parts (touch mode) - it raycasts a
    quick tap itself (mouse: GetMouseLocation + ViewportPointToRay; touch: Position + ScreenPointToRay). MCP user_mouse_input
    x/y are GUI coords = screenshot y minus 58. Card kept 150 px clear of each side (ChaseGui.Join ends 142; HUD right column
    starts 126 in); rect check at 1180x820: no overlaps. Installer also deletes ServerStorage.TrophyTests_unused.
  * shelf3 INSTALLED Oct 22 on her word ("Install the pull-forward trophies in place of the card, with a backup."),
    PUBLISHED by her with shelf2 (~13:10 UTC Oct 22: "It looks good I have published it") (tools/shelf/shelf3.lua = shelf3_head.lua + ShelfClient.lua; backup
    ServerStorage.HudBackup.ShelfClient_pre_shelf3 = the card version; its source also in tools/shelf/ShelfClient_shelf2.lua).
    Proven with the INSTALLED script: no card GUI, a real tap pulled the cup out x3.30 with the tag hidden, a tap sent it
    home (scale 1, tag back, OpenPanel cleared), no shelf errors.
  * funnel2 INSTALLED Oct 22 on her word ("Install the new funnel steps and tracking, with a backup."), PUBLISHED 17:22 UTC Oct 22
    (tools/funnel/funnel2.lua built by make_funnel2.py from funnel2_head.lua + src/SquirrelStats.lua + src/StatsClient.lua;
    backup ServerStorage.HudBackup.FunnelServer_pre_funnel2; test lines in tools/funnel/playtest_funnel2_2026-10-22.txt).
    Proven with the INSTALLED scripts (restarted on a wiped, ForceNew test player): steps 1-6 in order, SquirrelFound per
    find, AreaFPS Rue 57 (an earlier preview run said 50 - Studio readings vary), and on stopping the test the real
    PlayerRemoving handler sent StillMissing x3 (Spy, Margaux, Fishing) + QuitInFrance "Rue: 11 of 14"; no errors. Shannon: where and why new players drop between the Rue and all 44 ("a
    sharp drop after they get to the 2nd section"; is a particular squirrel too hard). Onboarding funnel 6 -> 11 steps
    (Joined / First / Five / Ten (Rue open) / Reached the Rue / Twenty / Reached the Chateau / Thirty / Forty / All 44 /
    Italy; read the dashboard from the publish date - steps 4-6 change meaning). New custom events: SquirrelFound (field 3
    "Rue: Marcel the Mime Squirrel", value = finds on that map), StillMissing (leaving with <=5 left in that area, one per
    squirrel), QuitInFrance (New only; value = seconds in the area; field 2 time bucket; field 3 "Rue: 3 of 14"),
    AreaFPS / AreaMemory (StatsClient, once per area per visit after 20 s). Area = SpawnReturn's x-line zones (Rue x>=150,
    Chateau x>=353 - only past the gates). In the Studio test on her PC: forest 60 fps, Rue 50.
  * welcome1 INSTALLED Oct 22 on her word ("Install the welcome, free hint, board move and hen eyes, with backups."),
    PUBLISHED 17:22 UTC Oct 22, + welcome1b right after (tools/welcome/welcome1b.lua; backups DailyClient_pre_welcome1b,
    QuestionClient_pre_welcome1b): the question banner landed ON the daily card (both waited for the first find) ->
    PlayerGui attribute DailyCardPending (set when a claimable day arrives, cleared when the card has slid away) and the
    reminder waits while it is set. Proven with the INSTALLED scripts on a wiped newcomer: the real WelcomeClient put the
    glow + sparkles on Surfer Dude in 0.7 s; the real HintServer offered the free hint (FirstStuck cut to 10 s for the
    test), the real button took it (HintServer log, FreeHintReady cleared, 2-min hint); first-find bubble "You found me! 43
    more..."; card "Your first daily acorns!" after the find, alone; banner 3 s after the card went; 5 hens with eyes in
    Edit (DomaineClient's PivotTo carries them); board #2 at 429.5, 5.3, -12.5 facing the pad exactly; no errors. Test
    artifact to remember: restarting DailyClient/QuestionClient in a play test leaves the old copy's GUI (two DailyGuis).
    Was: PREVIEWED (tools/welcome/welcome1.lua built by make_welcome1.py from
    welcome1_head.lua + src/WelcomeClient.lua; backups <Script>_pre_welcome1 for HintServer, HintClient, DailyClient,
    QuestionClient, PassportClient). Shannon: "less than half stay to get a first squirrel ... why?" -> found: no goal is ever
    shown; nearest squirrel (Surfer Dude) 52 studs off, grey among grey rocks, every other one hidden; the daily card said
    "Welcome back" to first-timers ~16 s in; the question banner + board #2 are classroom-ish. Her "make all of the changes".
    BUILT: WelcomeClient (new, workspace.Welcome, Client) - a player with 0 finds gets the nearest forest squirrel outlined
    gold (Highlight AlwaysOnTop) + sparkles + SquirrelBubble calls every 12 s for 3 min ("Psst! Over here! ... Click on
    me!" - her wording, not "Tap me"),
    then after the first find the found squirrel says "You found me! N more of us are hiding in France - M right here in the
    forest." FREE HINT: HintServer sets FreeHintReady=<zone> after 75 s with no first find / 180 s since the last find, one
    free per zone per visit; the Hint button turns plain gold "Free hint!" (she TURNED DOWN a pulsing glow: "that glow on
    FREE HINT is not good", "its too glowy", "it blurs" -> also the button's UIStroke was Contextual: now Border); the card
    says "Free!" / "Get free hint"; the paid hint unchanged otherwise. DailyClient: a newcomer's card waits for the first
    find (+6 s, and while any panel is open), subtitle "Your first daily acorns!". QuestionClient reminder waits for a first
    find. BOARD #2 moved to the chateau arrival lawn at her circled spot (429.5, -12.5) by the monument hall, writing
    toward the pad; unlock now Found_village >= 10; Passport row "Chateau question"; reminder "...at the chateau!". HENS:
    black dot eyes (0.11 balls) either side of the head, placed in WORLD axes from the beak (the beak's own axes are tilted
    - first try put them 2 studs up); inside each hen model so DomaineClient's PivotTo carries them. Proven in a play test on
    a wiped newcomer: glow + bubble, free hint granted (HintServer log), first-find bubble, card wording, hens, board.
    Lesson: a Script created with Instance.new in a play test never runs (a clone of an existing one does); run preview
    client code straight from execute_luau instead. The hint's own glow stays on its squirrel for 2 min (not the welcome's).
  * bottle2 INSTALLED Oct 22 on her word ("Install the bottle scatter, with a backup."), PUBLISHED 17:22 UTC Oct 22 (tools/bottle/
    bottle2.lua; backup ServerStorage.HudBackup.BottleServer_pre_bottle2). Proven with the INSTALLED script: 2 bottles
    out at start, 101 studs apart, both on sand, no errors. Was PREVIEWED first. Shannon: the
    beach bottles "keep spawning over and over in the same place ... supposed to be random, scattered". Was: ten fixed
    WashSpots in a 100 x 45 strip (closest 12 studs), MaxBeach 1, respawn 90 s. Now: pickSpot() = a random point on
    Terrain Sand inside BeachMin (232,-56,-792)..BeachMax (348,-40,-680) (the sea glass's test: Terrain, Sand, flat,
    nothing built on it), >= MinApart 40 from live bottles and the last 3 collected spots (160 tries, half spacing after
    100, old list as the last fallback); MaxBeach 2. Proven in a play test with a patched copy: 2 bottles 50 studs apart;
    8 wash-ups in a row closest 30 studs. Her other report: crab game 1 crab per cast x12 - odds unchanged (0/1/2/3 =
    15/40/30/15 %, gold 5 %); the 6-crab bucket trims each cast; waiting for her bucket count.
  * decorvr1 INSTALLED Oct 22 on her word ("Install the VR fix for the Treehouse tab, with backups."), PUBLISHED 17:22 UTC Oct 22
    (tools/decor/decorvr1.lua; backups ServerStorage.HudBackup.DecorClient_pre_decorvr1, TreehouseClient_pre_decorvr1).
    Proven with the INSTALLED scripts: normal screen 48 pieces in the tab; headset layout (screens moved as
    VRWindowClient does, DecorClient restarted) 48 pieces built on the VR window in 0.3 s; no errors from either script. Shannon: "when you open the menu for treehouse items on vr it is blank" ("the wardrobe
    tab is populated and the other tabs too, its just that one"). CAUSE: in a headset VRWindowClient moves the Passport's
    Page into PlayerGui.VRWindow.PassportGui; DecorClient waited for PassportGui.Page, timed out, returned -> empty tab.
    (WardrobeClient has looked in both places since Oct 9.) FIX: the same two-place lookup in DecorClient, and in the
    TreehouseClient first-build tip's Treehouse-tab glow. Proven by running VRWindowClient's adoption without a headset:
    old lookup -> nil; fixed DecorClient built all 47 pieces on the VR window's Page. (MCP screen_capture only showed the
    VR window's SurfaceGui with AlwaysOnTop off.) Watch in VR: Gordo's face is a ViewportFrame - may not draw in headsets. Shannon TURNED DOWN the card:
    "I don't want the tap to open a card, it want it to just pull the trophy itself forward and enlarged so you can see it
    better, no card there." Now the tap pulls the whole Trophy_<id> model (mesh + base + plaque) to the middle of the
    view: d = clamp(camera-to-head - 1.2, 2.2, 4) in front of the camera, Model:ScaleTo so it is ~half the screen tall
    (x2.9-3.3), 0.45 s eased flight, turns 35 deg/s, upright with its front to you; CanQuery off while out (the camera
    mustn't duck in front of it); own Head.HonourTag hidden while out (it drew over the key); OpenPanel "trophy". Home
    again (0.35 s, turning back the short way) on any tap, walking (MoveDirection), Esc, another panel, respawn.
    Proven in a play test: tap acorn -> out x2.92; tap -> home at scale 1, tag back, OpenPanel cleared; cup out x3.30 and
    an S-key step sent it home; key out x2.98 with the tag hidden.
  * PUBLISHED by her in one Alt+P, servers shut down (game page Updated stamp 17:22:38 UTC Oct 22): decorvr1, funnel2,
    welcome1 + welcome1b, bottle2. Funnel dashboard date ranges start Oct 22. Still to check live: the Treehouse tab in
    her headset (and Gordo's ViewportFrame face there); the funnel's first read ~Oct 27-28.
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
- REST-OF-FRANCE TABLET CHECK (Oct 21, iPad Air sim 1180x820, one play test, NOTHING changed in Studio; PlaceVersion
  reads 1628 in Studio). Works on iPad: Forest Race, question board, hoop + slingshot (fires), binoculars (tap toggles),
  zipline both ways, Baguette Chase join/leave, cheese, cafe coffee (prompt shows only while seated at that table), glaces,
  hat + dress mirrors (try-on; Buy greys out when short), bookshop reader, river boat, garden (no packet -> "the Acorn
  Store has them"), hens, tractor, pump, windmill, chapel bell + candle, Sandstone Climb start, basket lift, hang glider,
  zipline home, travel cart to Porto. Toadstool Run: layout read from RunClient only (hops were not streamed in).
  iPad problems found (tablet-only fixes, one at a time, on her word):
  1. Slingshot: SlingUI.Shoot "HOLD TO SHOOT" (965,617 100x100, inset space) overlaps the jump button (TouchGui
     JumpButton 1010,552 120x120) - a tap there shoots instead of jumping.
  2. SpeedClient "Coffee zoomies" pill (UDim2(1,-12,0,102), IgnoreGuiInset) sits ON the Passport button (screen
     1122-1170 x 64-112); the store "Zoomies" pill (y 130) would sit on the squirrels button. Phones probably too (unchecked).
  3. Windows sit too high on iPad (Shannon agreed twice): Baguette Chase info card (screen y 58-270, under the title pill)
     and the book reader (y 72-542, bottom third empty) - centre them on tablets; watch for others.
  4. Shop lists are phone-sized: hat mirror list shows 2 rows (826-1166 x 207-612), dress list 2 rows - taller on iPad.
  Small: chase card says "You're in the chase with 0 players" while the button says "Chasing (1)"; the "Join the baguette
  chase" pill stays while you are in; the question note and the race clock share top-centre (the note picks a clear spot
  only when it appears, so starting the race in its 6 s overlaps); zipline/mill notes touch the top of Roblox's hotbar
  (allowed by her hotbar rule). Treehouse "Homebase" pill and the golden-squirrel pill are already hidden on touch.
  Decided by Shannon today: golden-squirrel pill STAYS OFF on phones + tablets (her Sep 26 rule); NO how-to note for the
  tractor ("you just go forward"). Wanted: binoculars one-line how-to on touch (e.g. "Tap the screen to look - hidden
  squirrels glow red. Tap again to stop."); Passport button glows ~1 minute when the question note ("Open Passport ->
  Clues") pops up.
  ALL DEVICES (not iPad items): (a) BOOK NARRATION with sound for the bookshop books - target within ~a week (~Oct 28),
  before younger players arrive; (b) WHY PLAYERS STOP AT THE CHATEAU: forest 15 + Rue get found, the chateau squirrels do
  not - read the data (which chateau squirrels are found least, where people stop), walk it as a new player on iPad, then
  nudges to finish; (c) dress try-on makes her avatar's arms vanish (puff sleeves + floating hands); (d) hens have no eyes.
  Shannon is buying a real iPad to test herself. Only a real iPad shows: the real keyboard over the letter box, the sea-glass
  reveal (camera parts), frame rate, joystick feel.
  Test notes: Studio spawns her in Japan; an avatar seated in a chapel pew stays Seated through PivotTo and prompts ignore
  it (set Humanoid.Sit = false + Jump first); BoatPrompt hangs on an Attachment (WorldPosition, not Position); pills live in
  PlayerGui.PromptTouch.HeadStack / SignStack.Slot.Pill (press-hold ~600 ms at the pill centre, inset coords).
- FRANCE iPad FIXES INSTALLED Oct 21 (Shannon: "please fix any issues you found in France map first"), all in Edit,
  UNPUBLISHED, installers tools/tablet/*, backups ServerStorage.HudBackup.<Script>_pre_<job>:
  sling24+28: tablet HOLD TO SHOOT at (1,-255,1,-100) - clear of the jump button and centre-aligned with it (both y 612;
    her "align ... so it looks nicer" -> "that looks perfect"). Phones keep (1,-115,1,-45). ServerStorage.SlingshotTool.
  pills25+29: tablet Coffee/Zoomies pills at (1,-66,0,64) - left of the Passport icon's top, under the Gift icon (her
    spot); stack +28. Phones/computers keep (1,-12,0,102). Workspace.Speed.SpeedClient.
  cards26+chase30+31+32 (Workspace.Baguette.ChaseClient + Workspace.Bookshop.BookClient): tablet Baguette Chase card
    centred at scale 0.35 (0.45 was "a little too low" -> higher; placed LIVE on viewport change - a load-time check saw
    a 1x1 viewport and kept it top); book reader centred vertically on tablets (phones y 72); the sign's JOIN prompt
    hides while the card is open OR you are in the chase (ALL devices, her rule), back when out + closed; the bottom
    "You're in the baguette chase! Waiting..." toast gone - the top banner alone says waiting (ALL devices); "Go get
    it!" toast kept when the chase is on. Verified in play: join->pill hidden, card 222..427, leave->pill back.
  shops27 (Workspace.HatShop.HatClient + Workspace.DressShop.DressClient): tablet hat panel 336x560 scale<=1.15 (4 hat
    rows show), dress panel caps 420x640. Phones/computers unchanged. Verified on iPad.
  Her verdicts live: slingshot alignment "that looks perfect"; the set "that all looks good".
- ITALY RUN-THROUGH done Oct 21 (iPad sim, read-only; crab/sea glass/Bella/bottles were cleared Oct 20). WORKS: harbour
  bell (Customs Squirrel comes), funicular (seats lock while moving, rode bottom->top), Piazza Race start/quit (clock
  clean on iPad), opera duet (lights dim + spotlight), grotta cage rescue (+5), Polpo throws you out ("VIA! Out of my
  grotto!", dazed stars), lemon seller 8 acorns (comic bubble reply, item chip on the purse), travel board both ways.
  Correct-by-design: "Sell photos" prompt stays off with no photos; balloon shows HER "Fly to Japan - private preview"
  (the public 44-squirrel flight can't be tested from her account). PolpoClient's "infinite yield" console warning at
  spawn is streaming timing, harmless. Not retested: pearl sneak (Polpo mechanics verified), camera->sell loop (needs
  photos; live since Oct 8). NO overlaps found in Italy on iPad.
  PUBLISHED by Shannon Oct 21 ~19:56 UTC (live Updated stamp checked; Studio's PlaceVersion counter only refreshes on
  reopen). NEXT: decor roadmap step 2 (rugs), or the "who stops at the chateau" data read, her pick. Book narration
  target ~Oct 28.
