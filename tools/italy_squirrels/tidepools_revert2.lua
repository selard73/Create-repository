-- Oct 4 2026: undo tidepools_build2 (limestone shelf, pools too small for 4-stud terrain): paste the terrain backup back, clear the sliver past the backup's south edge,
-- remove the empty 'Natural tide pools' folder, put the old ring-pool parts back where they were.
local T=workspace.Terrain
local SS=game:GetService('ServerStorage')
local bk=SS:FindFirstChild('TidePoolBackup')
if not bk then warn('QW2@ABORT no backup') return end
local tr=bk:FindFirstChild('Terrain_v2_x276_y-68_z-816')
local old=bk:FindFirstChild('OldRingPools')
if not (tr and old) then warn('QW2@ABORT backup pieces missing') return end
local cove=workspace.PortoNocciola['14 Lighthouse coast']:FindFirstChild('Cala della Sabbia and tide pools')
T:PasteRegion(tr,Vector3int16.new(69,-17,-204),true)
local f=cove:FindFirstChild('Natural tide pools') if f and #f:GetChildren()==0 then f:Destroy() end
local n=0 for _,p in ipairs(old:GetChildren()) do p.Parent=cove n+=1 end
game:GetService('ChangeHistoryService'):SetWaypoint('Tide pools v2 reverted')
for _,y in ipairs({-50,-54}) do
	local reg=Region3.new(Vector3.new(280,y-2,-800),Vector3.new(316,y+2,-764)):ExpandToGrid(4)
	local mats=T:ReadVoxels(reg,4) local cnt={}
	for x=1,mats.Size.X do for z=1,mats.Size.Z do local m=mats[x][1][z].Name cnt[m]=(cnt[m] or 0)+1 end end
	local s2='' for k,v in pairs(cnt) do s2=s2..k..'='..v..' ' end
	warn('QW2@VOX y'..y..' '..s2)
end
warn('QW2@REVERTED parts back',n)
