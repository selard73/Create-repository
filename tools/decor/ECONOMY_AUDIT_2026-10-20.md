# Acorn economy audit - Oct 20 2026 (step 1 of treehouse decor)

Read-only audit of the live place scripts and folder attributes in Studio (placeId 117372258657114). Nothing was changed.
Status: WAITING for Shannon's approval of the numbers. Step 2 (decor system + rugs + Developer Products) not started.

## Where acorns come from
| Source | Acorns | Limit / notes | Where |
|---|---|---|---|
| Finding a squirrel | 0 | finds pay nothing; only the daily Golden Squirrel pays | SquirrelSetup.onFound |
| Passport outings | 0 | stamps + passport_outings counter only | Passport.Rules |
| Daily Guardian statue | 0 | honour only | PortoKeeper |
| Scattered acorns | 1 each | AcornSpots 130 (forest 32, village 8, domaine 25, porto 65; Japan 0); Density 0.33 = ~43 out per server, shared; Respawn 300 s at another spot in the same section | AcornSystem |
| Daily card | 10 + 5/streak day, max 40 | once a day | Daily (BaseReward/StepReward/MaxReward) |
| Golden Squirrel | 30 | once a day; French maps only | Daily.GoldReward |
| Daily question | 25 right answer; nightly draw 200 + Wise badge (one winner) | one try a day | DailyQuestion Reward/Prize |
| Bamboo maze | 25 | once a day | JapanMap.BambooMaze.RewardAcorns |
| Message bottles | 10 each | FindCap 5 a day, MaxBeach 1, respawn 90 s; sending costs 15 | Bottles |
| Forest Race / Porto Race / Sandstone Climb | 10 | only a new personal best (first finish counts), MinSeconds guard | BestAcorns |
| Toadstool Run | 10 | every finish, NO cap | ToadstoolRun.Reward |
| Croc / Polpo rescue | 5 per captive | RescueCap 20 per hour each; 3 cages each, respawn 90 s | Lagoon / Grotta |
| Croc / Polpo flee | 3 (+1 per bonk) | FleeCap 3 per hour | Lagoon / Grotta |
| Hoop | +3 per basket, -1 per shot | 3 shots then 60 s rest | Hoop |
| Baguette chase | 10 per grab; +1 per 10 s held | GrabCap 12 per hour, HoldCap 30 per hold, 2+ players | Baguette |
| Crab trap | 3 per crab, gold 100 (5 % a cast) | ~1.45 crabs a cast, 10-15 s wait, bucket 6; no cap; avg ~9 a cast | CrabGame |
| Photos | 20 each, whale 40 = 100 a set of 4 | repeatable after selling, no cap | PhotoGame |
| Sea glass crafts | suncatcher 60, necklace 70, vase 80, shell box 150; parfum kept | pieces respawn 45-90 s | SeaGlass.Recipes |
| Garden | 4 a harvest (1 per acorn picked) | seed 15 -> 5 harvests, 600 s apart | Garden |
| Treehouse finished | 100 | once ever | TreehouseServer PRIZE |
| Community group | 150 | once ever | Gifts.CommunityAcorns |
| Invite a friend | doubles every gain < 150 | while both in the server (BoostMaxGain 150) | GiftsServer |
| Mayor thank-you | set by Shannon (MaxGift 5000) | occasional | Thanks |

## What is for sale
- Acorn Store (Shop Price_*): cheese 8, bubbles 15, seed 15, zoomies 25, fountainmode 25, crabtrap 40, slingshot 45, camera 50,
  portrait 80, ziphandle 600, backpack 900 (also free via the like gift), glider 2500. Binoculars = Game Pass only.
- Hat shop: beret 50, cloche 70, bowler 80, boater 90, fedora 100, sun 110, top 150.
- Dress shop: round 35, pearls 45, cateye 50, aviator 60, rue 60, adventurer 65, harborsailor 75, riviera 80, woodlandbard 85,
  cafe 90, skycaptain 95, jardin 110, moonmagician 130, chateau 140, royalpage 140, soiree 155.
- Small spends: Porto cappuccino 5 (France coffee free), lemon 8, hoop shot 1, letter stamp 30, message bottle 15.
- Robux, LIVE: Developer Products Handful 150 acorns = 22 R$ (3714570389), Basket 500 = 79 R$ (3714570753),
  Barrow 1200 = 149 R$ (3714570864), Hint = 25 R$ (3713471302). Game Passes: ziphandle 2036372649, glider 2037656625,
  binoculars 1991720687. Packs are granted by workspace.Receipts.ReceiptRouter from workspace.AcornPacks attributes
  (Product_<key>, Acorns_<key>), KEYS = handful/basket/barrow.

## Session estimate (20-30 min)
- New player: daily card 10, question 25, scattered ~15, first race + climb 20, toadstool 10-20, a croc round ~15
  => ~100 (70-140). One-time extras early on: treehouse 100, community 150.
- Returning player (most squirrels found, owns camera + crab trap): dailies ~100-150 (card 25-40, question 25, Golden 30,
  maze 25, bottles 20-30) + 2-3 activities ~125-175 (photo set 100, crab bucket ~40, a craft 60-80, rescues 15, scattered 15)
  => ~250 (175-300). A grinder farming photos / crabs / toadstool: 400-600.

## Proposal (pending approval)
Rugs: Basic 100 (= treehouse prize, ~0.4 returning session), Cute 300 (~1.2), Fancy 1000 (~4). All ten rugs = 4700.
Robux packs at a base of 4 acorns per Robux:
| Pack | R$ | Base | Bonus | Total |
|---|---|---|---|---|
| Handful | 25 | 100 | - | 100 (one Basic) |
| Pouch | 75 | 300 | +10 % | 330 (one Cute) |
| Basket | 200 | 800 | +25 % | 1000 (one Fancy) |
| Treasure Chest | 500 | 2000 | +50 % | 3000 (all three Fancy) |
| Starter (once) | 50 | - | - | 500 + an exclusive item |

## Notes for step 2
- The new ladder pays 4-6 acorns per Robux; the live packs pay 6.3-8. Recommended: take the three old packs off sale when the
  new ones go live (the old Barrow would otherwise undercut the new Basket).
- GiftsServer doubles gains under BoostMaxGain (150) while an invite boost is on; the new Handful (100) would be doubled.
  Tag pack grants (as Gifts tags its own with "gift") so packs never double.
- ReceiptRouter is the single ProcessReceipt; new products must be routed there (one ProcessReceipt per game).
- Saving: everything goes through RS.AwardAcorns / RS.AwardItems (SquirrelSetup owns the one save key); decor ownership can be
  Item_decor_<id> and the equipped choice an Item value, never a DataStore write from the decor scripts.
