------------------------------------
-- V2.4 updated by Alexey Bogomolov <mail@abogomolov.com>
-- + cleaned up and updated for Fusion 9/17 and Resolve 
-- + add support for mapped paths
-- + catch if no path found in a Loader

-- V2.3 Update Log:
-- + Updated syntax to work in Fusion 8

-- written by Tim Little for Fusion 6.4 (timhlittle@gmail.com)


--// Scan Selected Tool //--
function scanSelectedTool()
	tool = comp:GetToolList(true, "Loader")

	if tool[1] == nil then
		--// Pop-up Window to Let User Know Error //--
		ret = comp:AskUser("Select a Loader",{})
		print ("Select a Loader")
		return nil
	else
		tool = tool[1]
		toolName = tool:GetAttrs().TOOLS_Name
		myLoader = tool -- give the tool a variable name that makes sense in the script
		loaderClip = myLoader.Clip[comp.CurrentTime]
		if (loaderClip ~= "" and loaderClip ~= nil) then
			return comp:MapPath(loaderClip)
        end --End of If Clip Exists
	end --End of If Loader

end --End of Function

--// Scan Composition and Update Loaders //--
function updateLoaders(oldLoaderClip, newFileName, onlySelectedLoaders)
	comp:Lock()
	newClipFileParse = bmd.parseFilename(comp:MapPath(newFileName))
	for i, tool in ipairs(comp:GetToolList(onlySelectedLoaders, "Loader")) do -- iterate through all tools in the comp
		toolName = tool:GetAttrs().TOOLS_Name
		myLoader = tool -- give the tool a variable name that makes sense in the script
		loaderClip = comp:MapPath(myLoader.Clip[comp.CurrentTime])
		if loaderClip == oldLoaderClip then
			print ("\n"..toolName)
			print ("Found match")

			-- replace loader clip
			myLoader.Clip[comp.CurrentTime] = comp:ReverseMapPath(newFileName)
			print ("Set "..toolName..".clip to "..newFileName)
		else
            -- skip loader
		end
	end -- End of For Loop that iterates thru tool selection
	comp:Unlock()

end --End of Function

--// Scan for Loaders with Comment //--

-----------------------------------------------------------------------------------------
--	EXECUTE SCRIPT
-----------------------------------------------------------------------------------------

print "============== SCRIPT BEGIN =============="

oldLoaderClip = scanSelectedTool()

if oldLoaderClip then
	oldFileParse = bmd.parseFilename(oldLoaderClip)
	oldClipFolderPath = oldFileParse.Path
	oldClipCleanName = oldFileParse.CleanName
	--=============================================================================================--
	--// Pop-up Window //--

		ret = comp:AskUser("Update Loaders v2.4",
				{
				{"Instructions:","Text", Default = "\n- Choose new file for the selected loader\n- The script will update other loaders that share the same file\n- Can update multi-pass sequences that were loaded using the mEXR script", ReadOnly=true, Lines=6},
				{"Selected Loader:","Text",Lines =1, ReadOnly = true, Default = toolName },
				{"Current File:","Text", Lines =1, ReadOnly=true, Default = oldFileParse.FullName},
				{"Only Selected Loaders","Checkbox", Default = 0},
				{"Choose New File:", "FileBrowse", Default = oldFileParse.FullPath, Width = 1},
				})

	--// Button Handling for the User Interface //--
		-- Check to see if the user cancelled
		if not ret then
			print("Cancelled")
			return
		end

		--// Store User Response

		-- Define the file to be converted
			filePathBrowse = ret["Choose New File:"]
			print ('new path is ', filePathBrowse)

		-- Define user Variable
			onlySelectedLoaders = ret["Only Selected Loaders"]
			if onlySelectedLoaders == 1 then
				onlySelectedLoaders = true
			else
				onlySelectedLoaders = false
			end


	--// Main Execution of Script //--

	-- Check new file path is valid

		if fileexists(comp:MapPath(filePathBrowse)) then
            -- print('file exists!')
			updateLoaders(oldLoaderClip, filePathBrowse, onlySelectedLoaders)

			--// Pop-up Window to Let User Know Script is Complete //--
			ret = comp:AskUser("Script Complete!",{})
		else
			ret = comp:AskUser("ERROR: New File Path is not Valid",{})
		end
    else
        print("no Clip found in the Loader")
end -- end of If loader clip is not nil
print "============== SCRIPT END =============="
collectgarbage()
