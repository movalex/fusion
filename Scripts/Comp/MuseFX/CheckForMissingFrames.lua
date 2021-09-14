
print("\nCheck for Missing Frames, v0.1 by Bryan Ray for Muse VFX\n")

--[[--
This script scans all Loaders in the comp and tests them for missing frames. It does not presently identify the missing frames;
it only compares the values of the start and end frames against the number of files in the clip's parent folder to determine 
if there is a mismatch.
--]]--

for i, tool in ipairs(comp:GetToolList(false, "Loader")) do
	if tool and tool.Clip and tool.Clip[fu.TIME_UNDEFINED] then
		myclip = tool.Clip[fu.TIME_UNDEFINED]
		framelist = bmd.readdir(bmd.readdir(myclip).Parent..'*')
		if table.getn(framelist) > 1 then
			startframe = framelist[1].Name
			seq = {}
			string.gsub(startframe, "^(.+)(%..+)$", function(name, ext) seq.Name = name seq.Extension = ext end)
			string.gsub(seq.Name, "^(.-)(%d+)$", function(name, SNum) seq.CleanName = name seq.SNum = SNum end)
			if seq.SNum then
				startframe = tonumber( seq.SNum )
				seq.Padding = string.len( seq.SNum )
			else
			   seq.SNum = ""
			   seq.CleanName = seq.Name
			end

			endframe = framelist[table.getn(framelist)].Name

			seqEnd = {}
			string.gsub(endframe, "^(.+)(%..+)$", function(name, ext) seqEnd.Name = name seqEnd.Extension = ext end)
			string.gsub(seqEnd.Name, "^(.-)(%d+)$", function(name, SNum) seqEnd.CleanName = name seqEnd.SNum = SNum end)

			if seqEnd.SNum then
				endframe = tonumber( seqEnd.SNum )
				seqEnd.Padding = string.len( seqEnd.SNum )
			else
			   seqEnd.SNum = ""
			   seqEnd.CleanName = seqEnd.Name
			end

			if (endframe - startframe) > table.getn(framelist) then
				print("Missing frames in "..tool.Name.."!")
			end
		else
			if tool.Loop == 1 then
				print(tool.Name.. " is a still frame. Skipping")
			else
				print("WARNING: "..tool.Name.." contains only one frame and is not set to Loop.")
			end
		end
	end
end
