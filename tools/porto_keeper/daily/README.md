# Italy daily Guardian

This is the reviewed Oct 13 patch for the current Studio sources. The six runtime
sources are `PortoKeeperServer.lua`, `PortoKeeperClient.lua`, `DailyKeeperCore.lua`,
`DailyKeeperStore.lua`, `SquirrelSetup.lua`, and `FindsEpoch.lua`.

The `*.baseline.lua` files preserve the exact prior Studio scripts. Build the new
sources with `python build_sources.py`, regenerate the extracted integration fixture
with `python make_test_fixture.py`, and run `luau test_daily.luau` offline. The fixture
executes the actual generated load/save/collection/reset functions, runtime claim queue,
render selection, and client receipt handler against mocks.
Run `luau-analyze` on the three pure modules and `luau-compile --null` on all six
runtime sources. `python make_installer.py` creates `install_daily.lua` and hashes.

## Behavior

- Italy has 44 registry IDs, counted once after normalizing saved aliases.
- Only an actual new server-validated Italy collection can qualify. Restoring 44
  saved finds or collecting a France squirrel never qualifies. The completed save
  must be confirmed before the daily claim is attempted. A versioned `italyAttempts`
  outbox entry is saved atomically with the 44th find, including its original day,
  reset generation, and stable claim ID. Load replays ONLY these recorded intents;
  it never synthesizes an intent from a legacy full save.
- The daily boundary matches France: fixed 09:00 UTC, without daylight-saving changes.
- `PortoKeeper_v1/first` is read only. Darknight's legacy record is preserved and
  included in the once-per-player exclusion. The owner and configured excluded IDs
  remain ineligible. Award data never gets erased by a player progress reset.
- One `daily_v2` ledger transaction checks the day's vacancy, prior winner IDs, and
  the player's consumed reset generation. A losing completed attempt cannot compete
  on another day until an explicit successful reset increments its generation.
- The existing reset button clears squirrel finds across ALL maps; that scope is
  unchanged. It retains saved acorns, items, Passport stamps, and other save fields.
  Reset failure does not pretend to clear finds. Uncertain or stale sessions cannot
  save or compete until rejoining.
- Messaging invalidates caches; 30-second polling recovers missed messages. The
  daily display rolls over and retries missing avatars throughout the server's life.
  Historical winners keep their title when the displayed daily statue changes.
- Outstanding intents retry in generation order while online and on rejoin. A
  settled receipt is acknowledged and removed on a later ordinary player save.
  Lost save replies and lost acknowledgements replay the same ID idempotently.
  Historical wins receive a dated private confirmation, never a current-day statue
  announcement. Replayed losses retain their original dated result.
- Reset invalidates prior sessions' writes and new claims from their old generation.
  A reset preserves an already persisted completion intent for its ORIGINAL day,
  and drops any never-persisted local intent. It cannot retag an old completion as
  a new-day attempt. Returning with 44 still requires reset and recollection.

## Installation and rollback

Run `install_daily.lua` only through a trusted Studio Edit workflow. It checks the
experience, exact old sources, source classes, and compilation before changing
anything. It installs three modules and updates three scripts. It does not access
datastores, start Play, enable API access, save/publish the place, or restart servers.
Original scripts are retained, disabled, in
`ServerStorage.PortoDailyBackup_20261013`. Repeat installation of matching sources
is a no-op; unexpected source changes abort rather than overwrite other work.

The recovery upgrade uses `python make_installer.py --upgrade-from recovery-baseline
--output install_recovery.lua --backup PortoDailyRecoveryBackup_20261013` (one command).
It expects the exact six previously installed daily sources preserved in
`recovery-baseline/`, and backs up changed sources in
`ServerStorage.PortoDailyRecoveryBackup_20261013`. The original backup folder remains
untouched. To undo only this unpublished recovery upgrade, restore its five changed
sources; `DailyKeeperStore` is unchanged. `verification-before-recovery.json` records
previous verification and `verification.json` records the current read-back checks.

To roll back BEFORE publication, restore those three original sources and remove
the three added modules after confirming no other code depends on them. Do not
roll back a published persistence protocol casually: old save writers do not
understand reset generations and can reintroduce old finds or remove the new fields.

## Publication prerequisites and limits

Publishing and restarting servers require Shannon's separate approval. Any rollout
must retire old servers in coordination with publication, so old and new save
protocols do not remain active together. Studio API access should stay off.

The winner is the FIRST SUCCESSFUL ATOMIC CLAIM among eligible confirmed saves,
not provably the earliest wall-clock collection across servers. A slower connection
or save can lose to a later collection. Completion time pins the claim to its original
day, including recovery across 09:00 UTC. Durable intents do not expire solely due
to an outage: they can settle an unclaimed historical day after recovery, without
replacing an existing winner, changing today's statue, or occupying today's slot.
If another eligible claim already committed for that day, recovery returns a loss.
Legacy full saves have no durable intent and do not receive retroactive awards.

Player saves and the daily ledger remain separate records. The player-save outbox
closes the crash gap: once 44 is durably stored, its attempt can be retried on rejoin.
A crash BEFORE that transaction commits cannot preserve unsaved progress. Recovery
requires the player to remain online or rejoin; no background all-player scan is added.
Reset generations guard NEW writers; they cannot make already-running OLD server
code obey the protocol. Old servers must be retired for rollout.
Currency/item delta persistence retains the existing save behavior; this patch does
not implement a new financial transaction journal or guarantee exactly-once deltas
under ambiguous legacy autosave responses.

Live avatar rendering, BadgeService delivery, real MessagingService behavior,
datastore throughput/CAS behavior, and a live clock rollover still need validation
in a separately approved isolated test experience before production rollout. The
offline suite simulates these races and failures, without contacting Roblox data.
The shared ledger has Roblox's normal entry-size limit; future large-scale growth
would require a reviewed sharding/migration design, never silent history truncation.
