"""Writes setup_all.lua: ONE command-bar paste that (1) inserts the saved sitting pup asset if no sitting pup is in the
Workspace, (2) removes old PupScripts / StandingPupScripts folders, (3) creates the StandingPupScripts folder with the
three scripts. Run: python gen_setup_all.py"""
from pathlib import Path
import make_standing_scripts as m   # also rebuilds StandingPup.rbxmx

SIT_ASSET_ID = 89842519385833       # "pup_rigged" Model in Shannon's Asset Manager (Sep 11)

def lua_long(s):
    assert "]==]" not in s
    return "[==[" + s + "]==]"

lua = f"""-- Standing pup: full setup in one paste (Ctrl+Enter). Safe to run again.
local ws = workspace
-- 1) sitting pup present? (rigged mesh with Hips bone but no leg bones)
local haveSit = false
for _, p in ipairs(ws:GetDescendants()) do
	if p:IsA("MeshPart") and p:FindFirstChild("Hips", true) and not p:FindFirstChild("FrontUpper.L", true) then haveSit = true end
end
if not haveSit then
	local ok, err = pcall(function()
		local asset = game:GetService("InsertService"):LoadAsset({SIT_ASSET_ID})
		local sit = asset:FindFirstChildOfClass("Model") or asset:GetChildren()[1]
		sit.Name = "SittingPup"; sit.Parent = ws
		local stand
		for _, p in ipairs(ws:GetDescendants()) do
			if p:IsA("MeshPart") and p:FindFirstChild("FrontUpper.L", true) then stand = p:FindFirstAncestorOfClass("Model") or p end
		end
		asset:Destroy()
	end)
	if ok then print("Sitting pup inserted from your uploads") else warn("Could not insert the sitting pup: " .. tostring(err)) end
else
	print("Sitting pup already in the Workspace")
end
-- 1b) park the sitting pup next to the standing dog, feet on the same level, keeping his own rotation
do
	local sit, stand
	for _, p in ipairs(ws:GetDescendants()) do
		if p:IsA("MeshPart") and p:FindFirstChild("Hips", true) then
			if p:FindFirstChild("FrontUpper.L", true) then stand = p else sit = p end
		end
	end
	if sit and stand then
		local sm = sit:FindFirstAncestorOfClass("Model") or sit
		local st = stand:FindFirstAncestorOfClass("Model") or stand
		if sit.Size.Y > 20 then sm:ScaleTo(sm:GetScale() * 3.5 / sit.Size.Y) end
		local standFeet = stand.Position.Y - stand.Size.Y / 2
		local sitFeet = sit.Position.Y - sit.Size.Y / 2
		local target = Vector3.new(st:GetPivot().Position.X, sm:GetPivot().Position.Y + (standFeet - sitFeet), st:GetPivot().Position.Z + 6)
		sm:PivotTo(CFrame.new(target - sm:GetPivot().Position) * sm:GetPivot())
		print("Sitting pup parked beside the standing dog")
	end
end
-- 2) old script folders out
for _, n in ipairs({{"PupScripts", "StandingPupScripts"}}) do
	local f = ws:FindFirstChild(n); if f then f.Parent = nil end
end
-- 3) new scripts
local folder = Instance.new("Folder"); folder.Name = "StandingPupScripts"
local function mk(name, ctx, src)
	local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = folder
end
mk("PupBrain", Enum.RunContext.Server, {lua_long(m.BRAIN)})
mk("PupAnim", Enum.RunContext.Client, {lua_long(m.ANIM)})
mk("SitAnim", Enum.RunContext.Client, {lua_long(m.SITANIM)})
folder.Parent = ws
print("StandingPupScripts installed. Press PLAY to test, then Alt+P to publish.")
"""
out = Path(__file__).parent / "setup_all.lua"
out.write_text(lua, encoding="utf-8")
print("wrote", out, len(lua), "chars")
