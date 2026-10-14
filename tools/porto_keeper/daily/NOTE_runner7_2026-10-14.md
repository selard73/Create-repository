# PortoKeeper "Italy daily Guardian": what is in Studio and where it came from (runner 7, Oct 14 2026)

Written for the cloud thread. Nothing here was built by the cloud/runner bridge; it was built by **Codex** on Shannon's PC on
Oct 13 (task folders under `C:\Users\slard\Documents\Codex\2026-10-13\task\`) and **published by Codex at 02:31:27Z Oct 14**
(Studio log line quoted in `../codex_live_release_2026-10-14/publication-verification.json`). JOB.md and the Oct 14 handoff
still describe the pre-Codex PortoKeeper (PortoKeeperServer 11893 = job 90); that version is kept in
`ServerStorage.PortoDailyBackup_20261013.PortoKeeperServer`.

## What it does (from Codex's README in this folder)
- Guardian of the Harbour is now a DAILY award: the first fresh, server-validated 44th Italy find per 09:00 UTC day.
- DataStore `PortoKeeper_v1`, key `daily_v2` (DailyKeeperCore.KEY): `{version=2, revision, days={[dayIndex]=rec},
  winners={[uid string]=rec}, attempts={[uid]={epoch, day, t, claimId}}, legacy=rec}`; `rec = {uid, name, t, day, claimId,
  epoch, total=44, durable}`; `dayIndex = floor((t - 9*3600)/86400)`. The legacy `first` record (Darkknight) is read-only and
  copied into `winners` on load. **`days` is the list of past Guardians** (one per day) - the monument's data. Read only; never
  write this store (standing rule).
- The plinth by the lighthouse shows TODAY's Guardian ("Awaiting today's Guardian" when none); historical winners keep the
  title (player attribute PortoKeeperTitle) and the badge. Fireworks + banner + chat line on a fresh win (PortoKeeperClient).
- RS objects the server waits for: PortoKeeperEvent (a RemoteEvent, present in Edit); SquirrelCollectedServer, GetItalyAttempts,
  AckItalyAttempt, ItalyCelebrationFresh are NOT in Edit - created at run time (see the grep in the commit message / SquirrelSetup).
- SquirrelSetup (workspace.SquirrelScripts) was patched too: a versioned `italyAttempts` outbox saved atomically with the 44th
  find, reset generations (FindsEpoch module), save/reset protocol changes. Old servers had to be retired at rollout.

## Folders
- `./` (this folder) = Codex's working set as found untracked in the clone on Oct 14 (README, build_sources.py, installers
  `install_daily.lua` / `install_recovery.lua`, offline tests `test_daily.luau` = 53 PASS, baselines). Its manifest is one
  round OLDER than Studio (Server 13679, Client 4327): the "celebration fix" round came after it.
- `./studio_2026-10-14/` = the read-back of the PUBLISHED place, LF-normalized by runner 7 (Codex's copies are CRLF).
  `CHECKSUMS.md` has length + adler32 + sha256 per file. Verified against Studio (Edit, PlaceVersion 1352) on Oct 14:
  PortoKeeperServer 14386, PortoKeeperClient 12323, DailyKeeperCore 5889, DailyKeeperStore 2080, KeeperCelebration 2056
  match byte for byte (length + adler32), and so do SquirrelSetup 33348, SquirrelRegistry 21360 and FindsEpoch 2913 (all three
  under Workspace.SquirrelScripts; FindsEpoch is a ModuleScript there); the sha256 of all 13 files equals Codex's publication-verification record.
  **Count every installer anchor against these files, not against JOB.md's older sizes.**
- `../codex_live_release_2026-10-14/` = Codex's release folder verbatim (before/after/readback sources, `production.patch`,
  `install-production.lua`, preflight + publication verification JSON, python helpers).

## Timeline (games API "updated" / Studio log)
- Oct 13 ~20:10Z: daily system installed in Edit (install_daily.lua, then install_recovery.lua).
- Oct 14 02:31:27Z: Codex publish ("live-italy-release": SquirrelSetup, PortoKeeperServer, PortoKeeperClient, KeeperCelebration).
- Oct 14 13:04Z and 15:45:45Z: further publishes (Shannon; job 92 Thanks etc.). Studio Edit = PlaceVersion 1352 at 15:50Z.

## Other Studio facts (read-only survey, Oct 14)
- ServerStorage backups: `PortoDailyBackup_20261013` (PortoKeeperServer 11893, SquirrelSetup 24819, PortoKeeperClient 3286) and
  `PortoDailyRecoveryBackup_20261013` (12585 / 29909 / 3678 / DailyKeeperCore 5510 / FindsEpoch 1088).
- workspace.PortoKeeper attributes: Title "Guardian of the Harbour", Need 44, PlinthX 488, PlinthZ -1158, TopY 6.4, FigureX 488,
  Scale 1.5, Facing (0.806, 0, 0.591), KeyShare 0.42, RestKeyHeight 3.4, Badge_key 0, NoKeeperUserIds "".
- Plaque in Edit: "GUARDIAN OF THE HARBOUR / OF PORTO NOCCIOLA / This could be you / Be the first to find all 44 ..." (rewritten
  at run time by setPlaque). No Figure in Edit.
- The French Hall (the model for the Italian monument): workspace.HallOfFame = HallServer 5874, HallClient 4155, HallStatue
  (RemoteFunction), Pavilion 23x21x14 at (403.6, 12.8, -32.2), Setting, HallSign, Frame, Newer/Older buttons, PlaqueStand
  (Words: Title "THE GRAND KEEPERS", Sub "OF THE GREAT ACORN", Who, When, Count).
- Shannon's answers (Oct 14): the monument stands in THE GROVES; it looks LIKE THE FRENCH HALL IN ITALIAN DRESS (pavilion,
  framed statue, plaque stand, < > paging; terracotta / stone arches / a "Guardians of the Harbour" sign).
