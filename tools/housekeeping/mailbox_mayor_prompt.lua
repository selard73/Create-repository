-- Shannon requested this one-label correction on Oct 17, 2026.
-- Correct the saved E-prompt default; existing menu/notification wording is already correct.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning(),"Apply in stopped Studio Edit")
assert(game.PlaceId==117372258657114,"Wrong place")
local post=assert(workspace:FindFirstChild("PostOffice"))
local prompt=post.PostBox.Body.PostPrompt
assert(prompt:IsA("ProximityPrompt"),"Unexpected mailbox prompt")
local before="La Poste - write to the dev"
local after="La Poste - write to the mayor"
assert(prompt.ObjectText==before or prompt.ObjectText==after,"Unexpected prompt wording; inspect first")
local client=post.PostClient.Source;local server=post.PostServer.Source
assert(client:find('prompt.ObjectText = "'..after..'"',1,true),"Client wording differs; inspect first")
local action,key=prompt.ActionText,prompt.KeyboardKeyCode
local count=#post:GetDescendants()
local old=prompt.ObjectText
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before mailbox mayor prompt")end)
prompt.ObjectText=after
assert(prompt.ObjectText==after and prompt.ActionText==action and prompt.KeyboardKeyCode==key)
assert(post.PostClient.Source==client and post.PostServer.Source==server and #post:GetDescendants()==count)
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After mailbox mayor prompt")end)
print("QQ MAILBOX MAYOR PROMPT: "..old.." -> "..prompt.ObjectText)
print("QQ MAILBOX PRESERVED: ActionText="..action.."; key="..key.Name.."; mailbox scripts and contents unchanged")
print("QQ MAILBOX STATUS: EDIT; NOT PUBLISHED")
