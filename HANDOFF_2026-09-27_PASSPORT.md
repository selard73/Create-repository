# 1001 Squirrels — bookstore, Passport and store update

September 27, 2026. Changes are saved as a Roblox Studio draft; this update has not been published.

## What changed

- All three bookstore stories are free. Reading does not require book ownership or deduct acorns. The books' contents and narration support remain intact. Phones use one readable page and larger page-turn controls; larger screens retain the two-page spread.
- A small Passport button joins the existing top-right controls. It opens a parchment journal in the game's walnut, cream and gold palette. It starts closed, uses scrolling pages, and closes when movement or a race/ride needs the screen.
- The Passport records 17 permanent activity stamps: rescue, question board, forest race, basket, squirrel find, Golden Squirrel, reading, café, cheese, fountain bubbles, glace, hat, portrait, baguette chase, zipline, sandstone climb and glider.
- Enjoying three different activities on a day completes one outing. Repeats count once that day. Five outing days earn a golden Passport cover. Days need not be consecutive; missing days loses nothing. No additional acorn payout was added.
- The Clues page reopens the Golden Squirrel clue, explains Grand Keeper and the Hall of Fame, and includes the riverside portrait. The saved place's portrait price is **120 acorns**; it was not changed.
- Acorn Store cards now include small illustrations, readable descriptions and separate price controls. The store reflows to the phone's height instead of shrinking all its text. Acorn packs also have illustrations and space for long names.
- Nearby prompts, the coffee timer and competing panels are temporarily hidden while reading these panels, then restored. The new interface has no pulsing or size-bouncing animations.

Grand Keeper remains the major prestige achievement. The Passport gives casual visitors a personal goal even when they do not win the daily statue competition. Existing statues, titles, Hall of Fame, pricing and activities were preserved.

## Implementation and maintenance

Project: `C:\Users\slard\roblox-props`.

New installer: `passport/build_passport.lua`. Like the existing builders, it returns a function and must run in **Edit mode**. It installs the new folder/modules/events and narrowly updates the integrated scripts. It does not rebuild the village or other scenery. Install the Passport before rebuilding scripts that require its illustration module.

Readable Passport sources are in `passport/src/`. The installer embeds these sources and integration snapshots; keep the embedded copies synchronized when editing. It is a snapshot installer: refresh its embedded integrations before rerunning it after unrelated future changes to those scripts. The individual bookstore, HUD, forest-race, climb, baguette, glace and shop-panel builders were also updated. Prior builder versions are backed up in `backups/codex_20260927_passport/`.

Progress uses the existing `AwardItems` save ledger with bounded `passport_*` keys. Only server-confirmed events award stamps. Existing basket/rescue/race/climb/find/hat achievements can receive historical stamps without advancing today's outing. Daily rollover follows the existing Daily folder's offset. Grand Keeper data is not touched.

The book stamp records opening a valid story inside the bookstore; it does not claim that the player finished reading it. Zipline and glider stamps record a valid ride launch. Hat stamps count buying or wearing; baguette counts grabbing the baguette. The game’s existing authoritative actions remain responsible for validating each activity.

## Verification

- All changed Lua sources compiled in Studio before installation.
- Pure progression checks covered duplicate activities, unknown IDs, three distinct activities, reconstruction from saved values, day rollover, missed days, permanent stamps and the five-outing milestone.
- Client/server tests verified all three released books at zero acorns without ownership, invalid book rejection, an interior-only reading stamp, coffee/rescue integration, duplicate-event protection, one outing and no currency change.
- Phone book layout checks verified text fits its page and uses a native 17-pixel font; page turning and closing were checked visually.
- Visual checks used the iPhone 7 simulator and the desktop viewport. Further hands-on testing on an actual phone remains useful for comfort and touch feel. Automatic closing on sustained movement still needs a hands-on check.
- Studio API access was verified OFF. Test sessions explicitly reported that they would not save. No live player save was edited.

The final world-integrity check passed 54/54, with no stray objects, loose characters or runtime leftovers. All 14 integrated sources compiled; all three books and their prompts were confirmed free. Temporary test scripts were removed before saving. Live persistence is deliberately not tested against the owner's data. Every activity was connected to its existing server success signal, but a full multiplayer round of every minigame was not performed.

## Review before publishing

In Studio Play mode, tap the small book icon, try Outing / Stamps / Clues, and open the purse to see the store illustrations. In the bookstore, every book should say **Read - free**. The new progress in isolated Studio tests is disposable.

Publishing remains a separate step, only on Shannon's instruction. No price reduction for the portrait is included; test whether players value seeing their picture in the gallery before deciding on a new price.

Previews: [Passport on iPhone](passport-iphone-preview.png), [free book reader](free-book-iphone-preview.png), [illustrated store](store-iphone-preview.png).
