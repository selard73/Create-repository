# Job 3: square fix, REAL RUN (Studio EDIT: cuts 14 floor parts; ask Shannon first)

Only run this after Shannon has said yes to the cut in BOTH threads.

1. Fetch the script (it changed slightly since job 2: a MIN_POINTS = 3 threshold drops the 1-point wedge cut):
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/square_fix1.lua
2. Read it. Change the one line near the top `local DRY = true` to `local DRY = false`. Change nothing else.
3. Tell Shannon what it will do (14 parts cut by CSG: the Piazza del Limone slab by 24 pieces, 12 Via della Piazza
   paving strips and 1 turning landing by 1-3 pieces each; originals to ServerStorage.CSGBackup_Square; undo available)
   and wait for her yes.
4. Run it in Studio, Edit mode, with execute_luau. It takes a few seconds (the big slab union is the slow one).
5. Send ONE message to the cloud session "GitHub free credit eligibility" with every Output line that starts with
   `QQ SQF`, unchanged (the CUT lines, the VERIFY line, and any LEFT lines). If anything errors, send the error text.
6. Do NOT publish. Do not take captures unless Shannon asks. Do not analyse.

Undo, if Shannon wants it reversed (Edit mode, run as is):
https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/square_undo1.lua
