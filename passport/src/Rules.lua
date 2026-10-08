-- Pure progression rules. Mutate session state before emitting ledger writes.
local Rules = {}
function Rules.record(state, id, day, allowed)
 if not allowed[id] or state.stamps[id] == day then return nil end
 local old = state.stamps[id] or 0
 state.stamps[id] = day
 local changes = {{"passport_"..id, day - old}}
 local n = 0
 for key, d in pairs(state.stamps) do if allowed[key] and d == day then n += 1 end end
 if n >= 3 and state.last < day then
  table.insert(changes, {"passport_outing_last", day-state.last})
  table.insert(changes, {"passport_outings", 1})
  state.last = day; state.outings += 1
 end
 return changes
end
return Rules
