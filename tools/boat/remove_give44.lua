-- remove_give44 v1: deletes the TEST-ONLY ZZ_TEST_Give44 script from ServerScriptService (run before publishing).
local SSS = game:GetService("ServerScriptService")
local s = SSS:FindFirstChild("ZZ_TEST_Give44_DELETE_BEFORE_PUBLISH")
if s then s:Destroy(); print("QQ G44 removed the test script") else print("QQ G44 no test script to remove") end
