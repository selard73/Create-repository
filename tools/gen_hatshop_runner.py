# gen_hatshop_runner.py TAG -> run_hatshop.lua: village/build_hatshop.lua (the Chapelier's room, the hats, HatServer/HatClient)
import sys

TAG = sys.argv[1] if len(sys.argv) > 1 else "v1"
build = open(r"C:\Users\slard\roblox-props\village\build_hatshop.lua", encoding="utf-8").read()
runner = (
    "-- run_hatshop.lua " + TAG + " (EDIT mode): the Chapelier's hat shop - the room over the shop, the hat wall, the mirror,\n"
    "-- the Catalogue in ReplicatedStorage.HatKit, HatServer/HatClient (village/build_hatshop.lua)\n"
    'if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end\n'
    "local build = (function()\n" + build + "\nend)()\n"
    "local ok, res = pcall(build, {})\n"
    'if not ok then warn("QQ HATSHOP BUILD FAILED " .. tostring(res)) return end\n'
    "local out = {}\n"
    'for _, n in ipairs({"HatServer", "HatClient"}) do\n'
    "\tlocal f, e = loadstring(res[n].Source)\n"
    '\ttable.insert(out, n .. (f and " compiles" or (" COMPILE ERROR " .. tostring(e))))\n'
    "end\n"
    'local cat = game.ReplicatedStorage.HatKit:FindFirstChild("Catalogue")\n'
    'local f2, e2 = loadstring(cat and cat.Source or "")\n'
    'table.insert(out, "Catalogue" .. (f2 and " compiles" or (" COMPILE ERROR " .. tostring(e2))))\n'
    'warn("QQ HATSHOP ' + TAG + ' done - " .. table.concat(out, ", ") .. " | " .. res:GetFullName())\n'
)
open(r"C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\scratchpad\run_hatshop.lua", "w", encoding="utf-8", newline="\n").write(runner)
print("run_hatshop.lua", TAG, len(runner), "chars")
