# FreshStart (Oct 22 2026)

Shannon's ask: her brother tries the game in VR on her alt **selard327** (user id 8119732427): reset it to a brand-new
player with 1500 acorns and Japan access like SelBell; and reset her own **SelBell / CozyGameMode** (9611145467) to brand new.
She approved writing those two saves ("Yes - install the fresh start for selard327 and SelBell as described").

Installed in Studio Edit Oct 22 ~19:30 UTC (unpublished at that moment) by an installer run from the chat (the app refused to
save the .lua here; its content is in the session transcript and summarised below):

- `workspace.SquirrelScripts.SquirrelSetup` got a `FRESHSTART1` block appended (backup `HudBackup.SquirrelSetup_pre_freshstart1`):
  when a listed player's save has loaded and `Item_freshstart_r<Round>` is missing, it copies the old record to the key
  `freshstart_backup_u<uid>_r<round>_<time>` in the same store (`SquirrelFinds_v1`), writes a fresh record through the game's
  own reset (`FindsEpoch.reset`, generation bumped) with `acorns` = the configured purse, `items = {freshstart_r<round> = 1}`,
  empty passport / area / italyAttempts, freezes that session's saving, and kicks once with the Message. The next join loads
  brand new. Studio: the owner's save is never available there, so it logs "nothing done".
- `workspace.SpawnReturn.SpawnReturnServer` (backup `SpawnReturnServer_pre_freshstart1`): the owner-only Japan start
  (`OwnerStartArea = "japan"`) also applies to ids in the SpawnReturn attribute `JapanStartUserIds` (= 8119732427).
- `ServerScriptService.JapanPreviewAccess` attribute `GuestUserIds` = 8119732427 (every Japan script follows the server's mark).
- `workspace.FreshStart` folder attributes: `UserIds` "8119732427,9611145467", `Round` 1, `Acorns` "8119732427=1500",
  `Message`, `DryRun` false. Bump `Round` to reset the same people again; edit `Acorns` for a different purse.

What stays after a reset (side stores, untouched): photo album, portraits on the easel, post-office letters, race and climb
best times, daily-question answers.

To put a save back: read the backup key and write it to `u<uid>` with `UpdateAsync` (a small script; ask Claude).
