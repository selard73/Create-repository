# 1001 Squirrels - morning brief, 24 Sep 2026

Nothing was published overnight. Everything below sits in the saved place (Team Create) or on disk, ready to install
and test the moment Studio is unlocked. API access is OFF for testing; it goes back ON before any publish.

## Done and tested in Studio

**Acorn packs (Developer Products)** - code complete, waiting on the products.
- The Acorn Store has a new section, "Acorn packs - Robux, straight into your purse": a handful (150), a basket (500),
  a wheelbarrow (1200). The Robux price is read from each product, so pricing lives on the Creator Hub only.
- One receipt router now handles every Developer Product (Roblox allows a single handler per game); the paid Hint
  hands over to it. Each purchase is granted exactly once, even if a server dies mid-way.
- Tested: the Studio "try" grant (+150 acorns, toast) and a real Roblox test purchase of the Hint through the router.
- **You**: create three Developer Products on the Creator Hub (Monetization > Developer Products) - suggested names
  "A handful of acorns", "A basket of acorns", "A wheelbarrow of acorns"; icons in this folder: pack_handful.png,
  pack_basket.png, pack_barrow.png. Prices are yours to set; for scale, the Hint is 23 Robux. Suggestion: 49 / 129 / 249.
  Then give me the three product ids and I wire them in (attributes, no rebuild) and we publish. Until then the section
  is hidden in the live game.

**La Poste - letters to the dev** - built and tested end to end.
- A yellow post box outside LA POSTE. Open it, write up to 240 characters, send for 30 acorns (a stamp). One letter
  out at a time. "Replies take about a day - come back and check the box."
- You open the same box and get a **Dev desk**: every waiting letter with a reply box. Your reply is filtered and
  saved; the writer gets "There is a letter for you at the post office!" the moment you send it (or when they next
  join), and reads it at the box.
- Both directions go through Roblox's text filter. Records live in their own DataStore.
- Tested the whole loop on your account: post, desk, reply, notice, read, keep.
- Price (30) and length (240) are attributes on workspace.PostOffice if you want them different.

## Built overnight, NOT yet tested (the PC locked before I could run them)

**Seed packets - the garden** (domaine/build_garden.lua, runner run_garden.lua)
- Four personal beds in the corners of the vegetable garden. Plant a seed packet (15 acorns) and one of six things
  comes up, picked at random; only you see your plants.
  1. A giant grinning pumpkin that says "Bonjour!" (and "Ca va?", "Magnifique!") when you come near.
  2. An acorn bush: harvest 4 acorns every 10 minutes, five times, then it withers and frees the bed.
  3. A sunflower with a face that turns to follow you.
  4. A red toadstool trampoline: land on the cap and it launches you.
  5. A shy carrot: pops up to look when you approach, dives back down if you get too close ("Oh la la!").
  6. A giant strawberry that giggles and wiggles when touched.
- Plants grow from a sprout over 45 s and survive leaving (saved as counts in the same ledger as everything else).
- Odds: bush 25%, pumpkin 20%, the rest ~14% each. All numbers are attributes on workspace.Garden.

**Cheese** (village/build_cheese.lua, runner run_cheese.lua)
- New store row: "Wedge of cheese", 8 acorns. Eaten on the spot. For 90 seconds you toot every few seconds with a
  green puff from behind, heard and seen by everyone nearby; you get a green tinge at the edges of the screen and the
  toast "That cheese was ripe. Excuse you." A second wedge extends it.
- The toot sound is a placeholder (a pitch-wobbled groan from Roblox's library). **You**: pick a proper one from the
  Creator Store and I set the FartSound attribute.

**Backpack** (village/build_backpack.lua, runner run_backpack.lua)
- Owners wear a canvas backpack with straps, buckles and an acorn in the side pocket, visible to everyone, and a small
  copy of one of their squirrels rides in the top. "Favourite" = the first find by name until we add a picker
  (player attribute BackpackPal).

## Morning order of play
1. Unlock the PC. I install run_garden, run_cheese, run_backpack (edit mode), then test each in Play with API off.
2. You look at the garden plants, the cheese and the backpack; we adjust.
3. You create the three Developer Products and give me the ids.
4. Store switches to turn on when approved: Sell_seed, Sell_cheese, Sell_backpack (all off now).
5. API access ON, publish, notes.
