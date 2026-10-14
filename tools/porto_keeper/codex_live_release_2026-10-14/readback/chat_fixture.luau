return function(d)
local task,TextChatService,warn=d.task,d.TextChatService,d.warn
local function chat(text)
    task.spawn(function()
        local ok, err = pcall(function()
            local channels = TextChatService:WaitForChild("TextChannels", 5)
            local channel = channels and channels:WaitForChild("RBXGeneral", 5)
            assert(channel, "RBXGeneral unavailable")
            local safe = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
            channel:DisplaySystemMessage(safe)
        end)
        if not ok then warn("PortoKeeper: chat announcement unavailable: " .. tostring(err)) end
    end)
end

return chat
end
