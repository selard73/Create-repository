# gen_lift_runner.py TAG -> run_lift.lua: the basket lift at the top of the Sandstone Climb (domaine/build_lift.lua)
import sys

TAG = sys.argv[1] if len(sys.argv) > 1 else "v1"
build = open(r"C:\Users\slard\roblox-props\domaine\build_lift.lua", encoding="utf-8").read()
assert "]===]" not in build and "[===[" not in build
runner = (
    "-- run_lift.lua " + TAG + " (EDIT mode): the basket lift at the top of the Sandstone Climb - the hoist, the basket, the\n"
    "-- LiftServer/LiftClient (domaine/build_lift.lua)\n"
    'if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end\n'
    "local build = (function()\n" + build + "\nend)()\n"
    "local ok, res = pcall(build, {})\n"
    'if not ok then warn("QQ LIFT BUILD FAILED " .. tostring(res)) return end\n'
    "local out = {}\n"
    'for _, n in ipairs({"LiftServer", "LiftClient"}) do\n'
    '\tlocal f, e = loadstring(res[n].Source)\n'
    '\ttable.insert(out, n .. (f and " compiles" or (" COMPILE ERROR " .. tostring(e))))\n'
    'end\n'
    'warn("QQ LIFT ' + TAG + ' done - " .. table.concat(out, ", ") .. " | drop " .. tostring(res:GetAttribute("Drop")) .. " | hop " .. tostring(res:GetAttribute("HopX")) .. "," .. tostring(res:GetAttribute("HopY")) .. "," .. tostring(res:GetAttribute("HopZ")))\n'
)
open(r"C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\scratchpad\run_lift.lua", "w", encoding="utf-8", newline="\n").write(runner)
print("run_lift.lua", TAG, len(runner), "chars")
