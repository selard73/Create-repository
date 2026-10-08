-- FoundSoundZone: the sound a squirrel rings when you find it can now differ from section to section.
-- The Chateau de l'Acorn plays a busy French rap track and the ta-da fanfare simply vanished underneath it.
-- Chimes sit high in the spectrum, above where a rap vocal and its beat live, so a chime cuts through where a
-- mid-range fanfare fights. Both the sound and its volume are attributes on workspace.SquirrelScripts, so
-- retuning either is editing a number rather than shipping code:
--     FoundSound_domaine  / FoundVolume_domaine    the Chateau
--     FoundSound_village  / FoundVolume_village    Rue de Noisette
--     FoundSound_forest   / FoundVolume_forest     the Great Acorn Forest
--     FoundSound          / FoundVolume            the fallback where a section sets nothing
-- Run in edit mode: require(workspace.FoundSoundZone.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local SS = workspace:WaitForChild("SquirrelScripts")
	local anim = SS:WaitForChild("SquirrelAnim")
	-- Carriage returns are the one thing that can silently defeat a plain-text match: the live Source, this
	-- file and the clipboard in between may each use a different line ending. Strip them from all three.
	local CR = string.char(13)
	local function lf(t) return (t:gsub(CR, "")) end
	local src = lf(anim.Source)

	local OLD = lf([==[
	-- FoundSound attribute on the folder: any sound id; default is Roblox's built-in ta-da fanfare
	local snd = Instance.new("Sound"); snd.SoundId = script.Parent:GetAttribute("FoundSound") or "rbxassetid://1845415163"
	snd.Volume = 0.9; snd.PlaybackSpeed = 1; snd.RollOffMaxDistance = 60; snd.Parent = mesh; snd:Play()
]==])
	local NEW = lf([==[
	-- FoundSound: which sound a found squirrel rings, held as attributes on the folder so it can be changed
	-- without touching code. A SECTION can have its own: the Chateau's music is a busy French rap track and the
	-- ta-da fanfare disappeared underneath it, so that section rings a bright chime instead - chimes sit high in
	-- the spectrum, above where a rap vocal and its beat live, so they cut through rather than fight it.
	--     FoundSound_forest / _village / _domaine     a sound id for that section
	--     FoundVolume_forest / _village / _domaine    how loud, over that section's own music
	--     FoundSound / FoundVolume                    the fallback for a section with nothing set
	-- The x lines are the ones the music, the gates and the boundary all use, so the sound that rings always
	-- belongs to the music that is playing.
	local SF = script.Parent
	local zone = mesh.Position.X >= 353 and "domaine" or (mesh.Position.X >= 150 and "village" or "forest")
	local want = SF:GetAttribute("FoundSound_" .. zone) or SF:GetAttribute("FoundSound")
	local digits = want and tostring(want):match("%d+")
	local snd = Instance.new("Sound")
	snd.SoundId = digits and ("rbxassetid://" .. digits) or "rbxassetid://1845415163"
	snd.Volume = SF:GetAttribute("FoundVolume_" .. zone) or SF:GetAttribute("FoundVolume") or 0.9
	snd.PlaybackSpeed = 1; snd.RollOffMaxDistance = 60; snd.Parent = mesh; snd:Play()
]==])

	if src:find("FoundSound_", 1, true) then
		print("FoundSoundZone: the per-section block is already in SquirrelAnim")
	else
		-- count by plain text, and refuse to write unless there is exactly one place to put it: a patch that
		-- half-lands is far worse than one that does not land at all
		local count, at = 0, 1
		while true do
			local j = src:find(OLD, at, true)
			if not j then break end
			count += 1; at = j + 1
		end
		assert(count == 1, "FoundSoundZone: expected 1 copy of the found-sound block, found " .. count .. " - nothing changed")
		local i = src:find(OLD, 1, true)
		anim.Source = src:sub(1, i - 1) .. NEW .. src:sub(i + #OLD)
	end

	-- What each section rings, and how loud it has to be to sit over that section's own music. The Chateau is
	-- loudest because it competes with a rap track; the Rue only has an accordion waltz to carry over, so it
	-- needs far less. Anything passed in opts wins, so a single number can be retried without editing this.
	local SOUND = {
		domaine = {id = 9116394876, volume = 2.2},     -- soft cluster of chiming hits, bright enough to cut the rap
		village = {id = 102392307584303, volume = 1.2},  -- a one-second bling; the shortness is what sets it
		                                               -- apart from the Chateau's 2.4s shimmer
	}
	local said = {}
	for zone, d in pairs(SOUND) do
		local id = opts[zone] or d.id
		local vol = opts[zone .. "Volume"] or d.volume
		SS:SetAttribute("FoundSound_" .. zone, tostring(id))
		SS:SetAttribute("FoundVolume_" .. zone, vol)
		table.insert(said, string.format("%s rings %s at %.1f", zone, tostring(id), vol))
	end
	table.sort(said)
	print("FoundSoundZone: " .. table.concat(said, ", ") .. "; the forest keeps the fanfare")
end
