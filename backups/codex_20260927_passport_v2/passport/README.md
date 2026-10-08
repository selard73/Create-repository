# Passport 2.1 — personal memories

The current Studio draft contains this update. Do not run map builders to apply it.
`build_passport.lua` is a guarded **migration from the existing v1 Passport**; it does not create a whole game from scratch. Import it as a ModuleScript and require it in Studio Edit mode only. It validates the 19 original integration sources against the captured pre-change or current v2 source and refuses unrelated edits. It updates five Passport sources and creates inert artwork previews. Existing Rules, free book UI, HUD and illustrated Acorn Store remain in place.

The prior full v1 installer is backed up under `backups/codex_20260927_passport_v2/passport/build_passport.lua`. For a fresh reconstruction, install v1 first, then this migration. After editing game integrations, review and regenerate the guarded migration instead of bypassing its source checks.

## Player experience

- Outings lists at most five unfinished experiences. Only these cards open description modals.
- Finishing removes the card from Outings and adds its personal result, actual game artwork and dated stamp to Completed. Completed cards show all their text without expanding.
- Complete more offers the next eligible, unfinished activities. Completed activities do not recycle into the list. An exhausted page waits for new unlocked areas or a second player for the baguette chase.
- Clues retains daily discovery and the optional Grand Keeper honour. Keeper never blocks an outing page.
- There are 21 normal memories and one Keeper bonus. Repeating an activity updates its latest result in Completed, rather than adding a second card.
- The existing five-day golden cover remains. Missing a day never resets it.
- Colour palette: deep pine green, gold/yellow, brown, small rust accents, light cream. Gold glow; no teal/cyan UI accents.

## Persistence

SquirrelSetup owns the existing player save key and merges the new `passport` field. Journal validates/merges timestamped records. PassportSave and PassportActivity are server-only BindableEvents; the only client command asks to advance a completed page. No client-supplied scores or memory details are trusted. Earlier numeric stamps migrate without invented historical details.

## Files and testing

`src/` holds the Passport modules. `integrations/` contains the exact installed sources for the 19 activity/save scripts. Their individual project builders are also updated. `install_art.lua` copies original game meshes/textures into ReplicatedStorage.PassportArt and strips scripts, prompts, sounds, physics interactions and tags. `test_journal.lua` is a read-only Edit-mode test of the rules and result formatting.

Studio tests cover bounded page advancement, full readable Completed cards, duplicate protection, server event detail replication, JSON roundtrip/merge, free books, actual squirrel/acorn touch and phone-simulator clicks. Full live multi-session DataStore and global leaderboard verification require a controlled live playtest; Studio API access was off and was not changed. No test scripts should remain in the saved place. Never publish a QA-seeded session.
