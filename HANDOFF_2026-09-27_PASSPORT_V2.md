# 1001 Squirrels — Passport adventures update

September 27, 2026 · Passport 2.1

This replaces the earlier Passport design. Saved to the Roblox Studio draft on September 27, 2026 with the latest visual refinements, with 54 local project files synchronized and hash-checked. **Published as version 618 on September 27, 2026 at 8:41 PM EDT.**

## The player flow

- **Outings:** up to five unfinished activities at a time. Tap an activity to open a description modal explaining what to do. Completing it removes it from Outings.
- **Completed:** each finished activity appears once, with its actual result and a dated passport stamp. The full result is readable by scrolling; completed cards do not open another modal.
- **Explore more:** after completing the current group, opens the next eligible unfinished activities. Completed activities do not immediately cycle back into Outings. If the player needs to unlock an area or bring a friend for the baguette chase, the page explains that.
- **Clues:** the daily Golden Squirrel clue, the golden-cover progress and the Grand Keeper bonus. Grand Keeper never blocks a five-outing page.

The congratulation is **“Well done, Squirrel Adventurer!”**. The unexplained SC initials and sentimental “lovely memories” wording were removed.

## Visual direction

The Passport now follows the existing Baguette Chase modal: warm cream, crisp brown headings, BuilderSans body copy, amber buttons and the same travelling gold rim. The previous dark pine header and yellow title were removed. Every activity card, including completed entries, has a subtle gold edge with a faint inward glow. Text has no glow or outlines. Actual game squirrels and props remain the artwork; the shaded coffee has visible coffee in the cup.

The four HUD buttons share an upper icon area and a lower gold caption/count baseline. Passport and Map now have labels below their smaller icons. Counts and button actions are unchanged. All buttons use the same opaque plum backing. The Passport image remains **134474000744911**.

The current squirrel pictogram is **90886407221518**, saved as `squirrel-natural.png` and `squirrel-hud-icon.png`. It has a rounded head, small ears and a broad tail. It uses a plum background matching the HUD; transparent generated versions had visible residue and were rejected. The previous SVG variants and assets **87497813680328** and **73964035055257** were rejected by the user. Their retained SVG files are historical, not masters for the current PNG. The user approved this replacement at its actual small size for publication.

The compact mobile layout remains below the top controls and above movement/jump controls. Description text is centered at 13px on small phones, with clear side and bottom padding. Completed cards retain their faint dated COMPLETED stamps and full result text without another expansion view. Only unfinished outings expand. Movement, races and rides close the Passport.

Publication was explicitly approved and completed. Studio reported PublishSuccessful and Published new changes in 1001 Squirrels to Roblox, version 618. Studio API access remained off. Dress-shop development has now begun as a separate unpublished draft.

## Activities and recorded results

| Activity | Completed result |
|---|---|
| Squirrel discovery | Most recently found squirrel and its area; corresponding squirrel artwork when available |
| Daily forest question | Answered today; reminder to check tomorrow for the grand prize |
| Swamp rescue | “[DisplayName] saves the day! You freed Madame Margaux's babies from Croque Monsieur in the swamp.” |
| Forest race | Latest time, previous-best comparison, improvement, acorns earned and available leaderboard position |
| Basketball | Baskets, longest consecutive streak up to three and basket acorn rewards; encouragement after zero baskets |
| Bookstore | Story title and the character read about; all three books remain free |
| Café coffee | Actual speed boost and duration: currently 35% for five minutes, usable in the forest race |
| Cheese | “Enjoyed some French cheese — the gift that keeps on giving.” |
| Church bell | Bell rung |
| Glace | Actual flavours eaten, including a mystery flavour when applicable |
| Fountain bubbles | Colour selected |
| Hat shop | Purchased hat's colour and style |
| Riverside portrait | Portrait added to the French Painter Squirrel's collection; price remains 120 acorns |
| Baguette chase | Duration of the most recent hold and acorns earned while holding |
| Toadstool Run | Completion and its acorn award, currently 10 |
| Windmill | Sail ride taken |
| Chickens | Fed at the farm |
| Sandstone race | Latest time, personal-best comparison, available rank, acorns and summit bell |
| Zipline | Ride taken |
| Hang glider | Flight taken |
| Golden Squirrel | Name, area and acorn reward |
| Grand Keeper bonus | First to complete the 44-squirrel collection that day; permanent honour and Keeper number when known |

Repeated activities update the latest result on their existing Completed card. This is one saved record per activity, not an unlimited history of every race or coffee. Older v1 stamps retain completion status without inventing past details; repeating the activity adds current details.

## Collection and saves

Ordinary squirrels, race squirrels, Golden Squirrels and acorns accept click/tap or physical touch. Shared server checks and duplicate protection prevent both inputs awarding the same collectible twice.

The existing player save document now includes a bounded Passport journal and current outing page. The save owner merges timestamped records so older writes cannot replace newer results. Activity results come from server gameplay events. The client can request the next page, but the server verifies that the current one is complete.

The existing golden cover still takes three different activities on five separate days; days need not be consecutive. No additional currency reward or new prices were introduced.

## Verification and limits

- Pure rules: catalogue IDs, groups of five, no recycling of completed outings, newly unlocked activities, detailed text, invalid-record rejection, JSON roundtrip and stale-save merging.
- Studio client/server: completion gate, detailed result replication, duplicate outing protection, no extra currency, all three free books and 21 readable Completed cards with no extra expansion view.
- Actual gameplay inputs: physically touched a squirrel and an acorn; clicked both through the iPhone simulator without moving into them. Each collection awarded once.
- UI reviewed in the iPhone 7 landscape simulator. This is a simulator check, not a test on physical phone hardware.
- Final visual check confirmed the softened title, gold description rim, centered 13px description, dated COMPLETED seal and shaded coffee with a visible dark surface. `passport-completed-refined-phone.png` shows two temporary client-only sample results; they were cleared by stopping Play and never sent to the server or saved.
- Subsequent final phone preview confirmed clean gold/brown text with all text glow removed, the new smooth squirrel silhouette and normal zero-completion startup. `passport-outings-phone.png` shows an earlier visual iteration; `hud-balanced-phone.png` shows the aligned HUD and cream Passport before the latest small card-glow addition. The completed-card and description screenshots demonstrate spacing and stamps but predate the final text-outline removal and squirrel icon replacement.
- Final Edit-mode audit: all 26 expected sources matched, all 54 existing world checks passed, and both disposable QA scripts were removed. No test teleports or pre-filled completions remain in the saved source.
- Activity integrations compile and use the games' actual completion events. Structured sample results were used for the full visual catalogue; every minigame was not played end to end.
- Studio API access was off and was left unchanged. Test-session progress was not saved to player DataStores. Live cross-session persistence, worldwide leaderboard positions and the daily statue competition still need a controlled live playtest.

## Project handoff

Project: `C:\Users\slard\roblox-props`

Original files are backed up under `backups\codex_20260927_passport_v2`. The project builders, exact integration sources and Passport sources are synchronized. `passport\README.md` explains the guarded migration installer. It requires the existing v1 Passport; it is not a whole-game builder. No scenery builders need to run to apply this update to the current Studio draft.

The update touches 20 activity/save/HUD integrations, five Passport sources and the shared book-icon illustration. The 53 inert art previews reuse existing game meshes/textures and have scripts, prompts, tags, sounds and physical interactions removed. The small cup adjustment is confined to its UI preview.

## Icon generation record

Generated using the built-in `image_gen` tool, not the API/CLI. Final saved asset: `passport-hud-icon.png` beside this handoff and `C:\Users\slard\roblox-props\passport\assets\passport-hud-icon.png`. The prior detailed cover was used as the edit reference. Final prompt:

> Transform this passport into a SIMPLIFIED FLAT 2D casual-game HUD icon. Preserve only its recognizable closed book shape and the pine green / muted warm golden yellow / brown palette. It must harmonize with simple filled map, acorn and squirrel icons in a Roblox game at 40px. Remove ALL lettering, remove the formal gold frame, remove leather texture, metallic reflections, embossed details and realistic rendering. No crest, no shield, no country emblem, no white outline. Rounded pine-green book cover, slightly visible warm tan page edge and brown spine, just one friendly simple golden acorn motif with a clearly rounded nut and little cap. Gentle broad painted shading using only 3-4 colour values, no dramatic highlights, no bright white against dark. Slight 5-degree tilt. Warm and friendly, clean professional hand-painted game icon, restrained detail and clear organic acorn shape. Genuinely transparent background. No circular backing or surrounding badge, no square tile, no shadows outside the book, no extra elements. One isolated book, filling about 88% of a square canvas. Prioritize graceful curves and legibility, not realism.

## Latest squirrel generation

Built-in `image_gen` was used, with no CLI/API fallback. The chosen asset is `squirrel-natural.png` (opaque plum backing). The original SVG replacement was rejected; the generated transparent attempts were also discarded due to edge residue.

Initial prompt: Create one minimal squirrel pictogram readable at 30 pixels: naturally proportioned seated squirrel in side profile, small ears, rounded head, short tapered muzzle, tucked paws, strong haunch, full bushy plume tail without a spiral hole; solid warm ivory, smooth edges, no decorative elements.

Final chosen edit prompt: Clean up this exact squirrel icon, preserving the animal shape and natural proportions. Remove all stray pixels, specks and residue. Make the animal flat warm ivory #FFF6DC with smooth antialiased edges. Use a uniform solid dark plum #261E34 background including the eye and gap between tail and body. No transparency, noise, vignette or extra elements.

