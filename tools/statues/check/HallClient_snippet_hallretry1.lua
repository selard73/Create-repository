local fn, store, want, view, e, mine, shownNo = nil, nil, 1, nil, {no = 1}, 1, nil
task.spawn(function()
		local ok, name, src
		for attempt = 1, 3 do   -- HALLRETRY1_20261015: a statue that failed to build is asked for again, not left as an empty frame
			ok, name = pcall(function() return fn:InvokeServer(e.no) end)
			if mine ~= want then return end                                  -- (scrolled on while it was being made)
			src = ok and name and store:WaitForChild(name, 15)
			if src then break end
			if mine ~= want then return end
			task.wait(4)
		end
		if mine ~= want then return end
		view:ClearAllChildren()
		if src then local c = src:Clone(); c.Parent = view; shownNo = e.no end
end)
