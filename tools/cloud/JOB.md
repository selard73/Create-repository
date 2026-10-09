# Job 4: square fix, PASS 2 (Studio EDIT: one more cut on the Piazza slab; ask Shannon first)

Pass 1 (job 3) cut 14 parts and took the square from 13,432 stacked points to 102. Cutting the paving strips exposed
a pair underneath: the "Pink house piazza corner" cobblestone wedges sit 0.03 above the Piazza del Limone slab (60 points).
Pass 2 cuts the slab (now a union) by those wedges. The small sliver remnants at the round landings are left alone.

1. Fetch the same script:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/square_fix1.lua
2. Change TWO lines near the top: `local DRY = true` -> `local DRY = false`, and `local MIN_POINTS = 3` -> `local MIN_POINTS = 20`.
   Change nothing else. (With 20, only the slab qualifies; the strips' leftover slivers are below the threshold.)
3. Tell Shannon: one part (the Piazza del Limone slab) will be cut again, by the cobblestone wedges and, as a no-op,
   the same landings and strips as before; its new original goes to ServerStorage.CSGBackup_Square too. Wait for her yes.
4. Run it in Studio, Edit mode, with execute_luau.
5. Send ONE message to the cloud session "GitHub free credit eligibility" with every Output line that starts with
   `QQ SQF`, unchanged. If anything errors, send the error text.
6. Do NOT publish. Do not analyse.

Undo (Edit mode, run as is; it restores pass 1 and pass 2 together, newest union first):
https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/square_undo1.lua
