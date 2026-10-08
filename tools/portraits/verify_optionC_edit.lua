-- v19 read-only (EDIT): the saved place has option C and the new words, and no test fixture or mock store
local G = workspace.PortraitGallery
local srv, cli = G.PortraitServer.Source, G.PortraitClient.Source
local checks = {
	{"server has PER_SITTER", srv:find("PER_SITTER", 1, true) ~= nil},
	{"server has no test mock", srv:find("PortraitReliabilityFixture", 1, true) == nil},
	{"server keeps the live DataStore line", srv:find('store = DSS:GetDataStore("PortraitWall")', 1, true) ~= nil},
	{"server reveal sends variant", srv:find("variant=entry.variant", 1, true) ~= nil},
	{"client turns the scene", cli:find("local turn = e and tonumber(e.variant) or 0", 1, true) ~= nil},
	{"store words", workspace.Shop.ShopClient.Source:find("the nine newest stay, up to three of you.", 1, true) ~= nil},
	{"passport price", workspace.Passport.Catalogue.Source:find("A portrait costs 80 acorns", 1, true) ~= nil},
	{"register", workspace.Bookshop.Room.Register.Screen.SurfaceGui.TextLabel.Text == "Free to read"},
	{"PerSitter attribute", G:GetAttribute("PerSitter") == 3},
	{"no fixture in ServerStorage", game.ServerStorage:FindFirstChild("PortraitReliabilityFixture") == nil},
	{"scripts enabled", G.PortraitServer.Enabled and G.PortraitClient.Enabled},
}
local bad = 0
for _, c in ipairs(checks) do print("QQ19 " .. (c[2] and "ok   " or "FAIL ") .. c[1]); if not c[2] then bad += 1 end end
print("QQ19 DONE - " .. bad .. " failed; server " .. #srv .. " client " .. #cli)
