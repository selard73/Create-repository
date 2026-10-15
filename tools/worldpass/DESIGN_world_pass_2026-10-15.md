# World Pass - a monthly subscription for 1001 Squirrels (design, Oct 15 2026)

Shannon's idea: "building these maps is VERY time and resource intensive; what if the first 2 maps stay free, but a subscription like a
'world pass' lets players 1. preview the new maps first 2. access to more maps 3. get one pass item of their choice a month?"
Cloud thread's recommendation, in short: yes to the subscription, with early access instead of locked maps, and launched once the
retention work (treehouse, passes, buy-here, portraits) has had a few weeks to show returning players.

## 1. The offer

WORLD PASS - $4.99 a month (Roblox's fixed local-currency tiers are 2.99 / 4.99 / 7.99 / 9.99 / 14.99; you keep 70% of the first
month and 100% of every month after - better than a pass). Four perks, each one a thing a free player keeps nothing of:

1. FIRST INTO EVERY NEW MAP. Subscribers walk the next map while it is still being finished - Japan first - with a "World Pass
   preview" banner so they know it is unfinished. When the map opens to everyone, it opens to everyone (no map is ever locked).
2. ONE PICK A MONTH. Each billing month a subscriber chooses one: the zip line handle, the hang glider, a future pass item, or 500
   acorns. A subscriber who already owns both passes still has the acorns and the newest item to pick, so the perk never runs dry.
3. THE WORLD PASS BADGE AND TITLE. A gold "World Pass" title (the game's title system already shows Wise Squirrel / Champion), a
   small gold globe on their name in the Hall of Fame plaques and the Passport cover.
4. THE MONTH'S SOUVENIR. One cosmetic a month (a hat or a scarf from the Dress Shop's kit, new each month, gone when the month
   ends) - cheap for us, visible to everyone, the reason to stay subscribed.

Not in the offer: "access to more maps" as a lock. Maps that only subscribers can enter make the game smaller for most players and
empty for the ones who paid. Early access gives the same feeling of privilege without taking anything away.

## 2. What Roblox gives us (and the two things to check)

- Subscriptions within experiences: monthly, auto-renewing, bought in the game or on the game's page; priced in local currency (the
  tiers above) or Robux (49 or more); paid out in Robux. Not for sale on Xbox, PlayStation, Meta Quest, or in a list of countries
  (Argentina, China, India, Japan, Turkey, UAE, Ukraine, Vietnam and others).
- The game asks Roblox whether a player subscribes (MarketplaceService:GetUserSubscriptionStatusAsync) and hears when that changes
  (UserSubscriptionStatusChanged); it opens the purchase prompt with PromptSubscriptionPurchase.
- TO CHECK BEFORE ANYTHING IS BUILT: (a) whether players under 13 can buy a subscription at all - the game's players skew young, and
  a perk only teenagers can buy would sit unsold; the Creator Hub's subscription eligibility page says; (b) that a subscription is
  never the only way to play content that was free before (Roblox's own rule, and ours: perk 1 is early access, nothing is locked).
- Console players cannot subscribe: they keep everything free players have; early access is simply not for sale to them.

## 3. How it works in the game

- SubscriptionServer (workspace.WorldPass): on arrival (after the save loads) asks Roblox once, sets the player attribute
  WorldPass = true/false, listens for changes; the subscription id lives as an attribute on the folder (she creates the subscription
  on the Creator Dashboard - Monetization > Subscriptions - and sends the id, exactly like the passes).
- Early access = the Japan gate we already have. JapanPreviewAccess.IsAllowed(player) becomes "the owner, or WorldPass = true"; the
  client's visibility script reads the server's JapanPreviewAllowed attribute instead of the hard-coded owner id (it already sets
  that attribute, "presentation only"); the taxi sign in the chateau grounds becomes the subscribers' door (visible to them only)
  and the balloon's Japan flight becomes a choice at the basket ("Fly to Japan - World Pass" beside "All aboard") rather than a
  replacement of the ordinary ride. The job-105 fixes (Area "japan", the lighting restore, the module fallback) already make the
  preview safe for more than one visitor; the geometry fixes (job 106) make it worth visiting.
- The monthly pick: a card in the Acorn Store's new "World Pass" tab (and from the Passport cover): "Your pick for October" with the
  four choices; the choice is kept on the save as Item_wp_<YYYYMM> through AwardItems so it is once per month, and the item itself is
  granted the way the passes are (AwardItems: Item_ziphandle / Item_glider / 500 acorns through AwardAcorns).
- The badge and title: the existing title system (ChampionTitle attribute) gains "World Pass"; the Hall plaques and the Passport
  cover draw a small globe when WorldPass is true.
- The souvenir: a monthly accessory from the Dress Shop's catalogue, worn through the existing boutique code; a StringValue under
  workspace.WorldPass names the month's item - new month, new line, no code.
- The sell: a "World Pass" row at the top of the Acorn Store (price from Roblox, a short list of the four perks, the purchase
  prompt), the same row on the Japan taxi sign and at the balloon, and one line in the daily card once a week ("Walk Japan before
  anyone else - World Pass").

## 4. When

1. Now: keep shipping the retention work; watch the interaction dashboard for returning players.
2. In two to three weeks, if players come back: she creates the subscription (name "World Pass", the description below, a 512 x 512
   icon - I draw it - price $4.99) and sends the id; the SubscriptionServer, the gate change, the store row and the pick card are
   one job each; the badge and the souvenir a week later.
3. The day Japan is ready for visitors (the sea, the floating pieces, the door decided): World Pass launches with "Japan: open to
   World Pass this month, to everyone when it is finished".

Description for the dashboard: "Walk every new map before anyone else, pick one Acorn Store treasure (or 500 acorns) every month,
wear the month's souvenir and the gold World Pass title. The forest and Porto Nocciola stay free for everyone, always."

## 5. Risks, honestly

- Churn: a subscription sells on habit. Launched to players who stay a minute, it is cancelled after one month; hence the wait.
- Under-13 purchasing (see 2a): if under-13s cannot subscribe, the World Pass is a perk for the older third of the audience, and the
  early-access perk should also be sold as a one-off pass ("Japan early ticket", 79 Robux) so younger players are not shut out.
- Expectation: "preview the new map" means an unfinished map; the banner and the description must say so, or the first subscribers
  feel cheated by a lake with no shore.
