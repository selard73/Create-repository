return function(d)
local pg,task,os,showBanner=d.pg,d.task,d.os,d.showBanner
local function dailyCardUp()                          -- the daily acorns card is showing (nothing goes on top of it: Shannon)
	local dg = pg:FindFirstChild("DailyGui")
	local dc = dg and dg:FindFirstChild("DailyCard")
	return dc ~= nil and dc:IsA("GuiObject") and dc.Visible and dg.Enabled
end
local function titleBannerUp()                        -- the honours' "You are now a ..." banner (finding all 44 brings both at once)
	local hb = pg:FindFirstChild("HonourBar")
	local b = hb and hb:FindFirstChild("Banner")
	return b ~= nil and b:IsA("GuiObject") and b.Visible
end
local function banner(big, small)
    task.spawn(function()
        local started = os.clock()
        task.wait(0.3)
        while (dailyCardUp() or titleBannerUp()) and os.clock() - started < 90 do task.wait(0.3) end
        showBanner(big, small)
    end)
end


return banner
end
