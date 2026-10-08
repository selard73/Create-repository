# Official Passport 2.1 — adventures and completed stamps

The current Studio draft contains this update. Do not run map builders to apply it.
`build_passport.lua` is a guarded **migration from the existing v1 Passport**; it does not create a whole game from scratch. Import it as a ModuleScript and require it in Studio Edit mode only. It validates the 20 original integration sources against the captured pre-change or current v2 source and refuses unrelated edits. It updates five Passport sources and creates inert artwork previews. Existing Rules, free book UI and illustrated Acorn Store remain in place. The HUD passport button gets a shaded book icon without its old circular backing.

The prior full v1 installer is backed up under `backups/codex_20260927_passport_v2/passport/build_passport.lua`. For a fresh reconstruction, install v1 first, then this migration. After editing game integrations, review and regenerate the guarded migration instead of bypassing its source checks.

## Player experience

- Outings lists at most five unfinished experiences. Only these cards open description modals.
- Finishing removes the card from Outings and adds its personal result, actual game artwork and dated stamp to Completed. Completed cards show all their text without expanding.
- Complete more offers the next eligible, unfinished activities. Completed activities do not recycle into the list. An exhausted page waits for new unlocked areas or a second player for the baguette chase.
- Clues retains daily discovery and the optional Grand Keeper honour. Keeper never blocks an outing page.
- There are 21 normal memories and one Keeper bonus. Repeating an activity updates its latest result in Completed, rather than adding a second card.
- The existing five-day golden cover remains. Missing a day never resets it.
- Colour palette: Baguette Chase cream, brown type, amber buttons and the same travelling gold rim; pine/rust stamps.
- Heading: Official Passport. Smaller centred mobile descriptions with clear padding; completed cards have faint, dated COMPLETED seals.
- HUD artwork: assets/passport-hud-icon.png, uploaded Roblox image 134474000744911. Warm pine/gold/brown book with a friendly acorn, no pale circle or white outline. Generated with the built-in image tool; see the handoff for its prompt.
- Squirrel count icon: generated natural squirrel pictogram, saved as assets/squirrel-natural.png and uploaded as 90886407221518. Replaces the furred ViewportFrame cutout. All four HUD buttons use aligned icons with gold labels or counts below. No count logic changes.
- Text is crisp brown with BuilderSans body copy and no text glow/stroke; gold is confined to frame borders.

## Persistence

SquirrelSetup owns the existing player save key and merges the new `passport` field. Journal validates/merges timestamped records. PassportSave and PassportActivity are server-only BindableEvents; the only client command asks to advance a completed page. No client-supplied scores or memory details are trusted. Earlier numeric stamps migrate without invented historical details.

## Files and testing

`src/` holds the Passport modules. `integrations/` contains the exact installed sources for the 20 activity/save/HUD scripts. Their individual project builders are also updated. `install_art.lua` copies original game meshes/textures into ReplicatedStorage.PassportArt and strips scripts, prompts, sounds, physics interactions and tags. `test_journal.lua` is a read-only Edit-mode test of the rules and result formatting.

Studio tests cover bounded page advancement, full readable Completed cards, duplicate protection, server event detail replication, JSON roundtrip/merge, free books, actual squirrel/acorn touch and phone-simulator clicks. Full live multi-session DataStore and global leaderboard verification require a controlled live playtest; Studio API access was off and was not changed. No test scripts should remain in the saved place. Never publish a QA-seeded session.

## Cities round (Oct 1 2026)
`patch_travel.py` is the single source for the boat / falls / chute / porto outings, their stamp texts and artwork, the NORMAL count and the per-city sub-tabs (French Squirrel Country | Porto Nocciola once Item_porto >= 1). It patches `src/*.lua`, the copies embedded in `build_passport.lua`, and writes `install_passport_travel.lua` for the live scripts. The world map lives in `../boundary/hudbar_map_block.lua` + `patch_map_world.py` (same pattern).
