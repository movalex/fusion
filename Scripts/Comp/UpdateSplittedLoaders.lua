------------------------------------
-- Update Loaders
-- V2.3

-- V2.3 Update Log:
-- + Updated syntax to work in Fusion 8


-- written by Tim Little for Fusion 6.4 (timhlittle@gmail.com)

------------------------------------

-----------------------------------------------------------------------------------------
--	DEFINE VARIABLES
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------
--	DEFINE FUNCTIONS
-----------------------------------------------------------------------------------------

--// Strip Leaf from Path //--
function stripLeafFromPath(stringVal)
	--print "running stripLeafFromPath Function"
	--print (stringVal)
    startScan = string.len(stringVal)
    for i = startScan, 1, -1 do -- for the length of the string to one, stepping at a -1 interval
       if string.sub(stringVal,i,i) == [[\]] then -- if the character being checked was a \
           toreturn = string.sub(stringVal,1,i-1) -- take all characters after the character just checked
		   print (toreturn)
           return toreturn -- return it
       end
    end
end

--// Strip EndSlash From File //--
function stripEndSlash(stringVal)
    startScan = string.len(stringVal)
       if string.sub(stringVal,startScan,startScan) == [[\]] then -- if the character being checked was a \
           toreturn = string.sub(stringVal,1,startScan-1) -- take all characters before the character just checked
           return toreturn -- return it
       end
end

--// Strip End Character From File //--
function stripEndCharacter(stringVal)
    startScan = string.len(stringVal)

	toreturn = string.sub(stringVal,1,startScan-1) -- take all characters before the last character

	return toreturn -- return it
end

--// Strip Extension From File //--
function stripExtension(stringVal)
    startScan = string.len(stringVal)
    for i = startScan, 1, -1 do -- for the length of the string to one, stepping at a -1 interval
       if string.sub(stringVal,i,i) == "." then -- if the character being checked was a period
           toreturn = string.sub(stringVal,1,i-1) -- take all characters before the character just checked
           return toreturn -- return it
       end
    end
end

--// Extract Last Folder from Path //--
function extractLastFolder(stringVal)
    startScan = string.len(stringVal)
    for i = startScan, 1, -1 do -- for the length of the string to one, stepping at a -1 interval
       if string.sub(stringVal,i,i) == [[\]] then -- if the character being checked was a \
           toreturn = string.sub(stringVal,i+1,startScan) -- take all characters after the character just checked
           return toreturn -- return it
       end
    end
end



--// Recursively Scan Directory and return EXR sequences//--
function ScanDirectory(path, recursive, clipFolderName)

	print("clipFolderName is " .. clipFolderName)

	path = (path.."\\" .. clipFolderName)

	if direxists(path) then

		-----------------------------------------------------------
		--	SCAN AND PROCESS FILES
		-----------------------------------------------------------

		exrOnly = false
		
		local scannedDir = readdir(path.."\\*")
		local numberOfFiles = table.getn(scannedDir) -- get the total number of files in the directory
		print ("reading path ".. path)

		newClipTable = {}

		print("number of files: "..numberOfFiles)

		for i = 1, numberOfFiles do -- iterate through each file in the directory

			stripEndSlashResult = (stripEndSlash(path))

			if (stripEndSlashResult == nil) then
				slashOrNoSlash = [[\]]
			else
				slashOrNoSlash = ""
			end

			local file = (path.. slashOrNoSlash ..scannedDir[i].Name)

			--// Check to see if the object is a folder or file
			--// If it is a folder, ignore
			--// If it is a file, return the first image in the image sequence

			if (scannedDir[i].IsDir == true) then
				--print("-- found a folder!")
			else
				seq = bmd.parseFilename(file)
				if seq.Extension ~= ".exr" and exrOnly == true then
					--this file does not have a .exr extension, skip it
				else

					if cleanName == seq.CleanName and clipFolderName == lastclipFolderName then
						--The file is part of an existing image sequence, skip it

					--// If the file is a exr file, and NOT a duplicate //--
					else
						print(seq.FullPath)
						lastclipFolderName = clipFolderName
						cleanName = (seq.CleanName or {})
						return seq.FullPath
					end
				end
			end
		end
	else
		return nil
	end
end -- end of function


--// Get Old Clip Folders //--
function getOldLoaderClipFolders(newClip, onlySelectedLoaders, loaderList)

	print (newPath)
	newClip_FileParse = bmd.parseFilename(newClip)
	newPath = newClip_FileParse.Path
	newPath = stripEndSlash(newPath)

	comp:Lock()

	for i, myLoader in ipairs(loaderList) do -- iterate through selected tools in the comp

		loaderClip = (myLoader.Clip[comp.CurrentTime])
		fileParse = bmd.parseFilename(loaderClip)
		path = fileParse.Path
		path = stripEndSlash(path)

		--Store Variables from current footage
		loaderClip = myLoader.Clip[comp.CurrentTime]

		fileParse = bmd.parseFilename(loaderClip)

		clipFolderPath= fileParse.Path
		clipCleanFileName = fileParse.CleanName
		clipFileType = fileParse.Extension
		clipFullName = fileParse.FullName

		clipStart = myLoader.ClipTimeStart
		clipEnd = myLoader.ClipTimeEnd
		holdFirstFrame = myLoader.HoldFirstFrame
		holdLastFrame = myLoader.HoldLastFrame
		globalIn = myLoader.GlobalIn
		globalOut = myLoader.GlobalOut

		clipFolderName = extractLastFolder(path)

		newFile = ScanDirectory(newPath, 0, clipFolderName)

		if newFile == nil then
			print("Warning: Could not find match for " .. clipFolderName)
			myLoader:SetAttrs({TOOLB_PassThrough = true})
		else



			myLoader.Clip[comp.CurrentTime] = newFile

			-- Match old trim in/trim out settings
			--[[MyLoader.ClipTimeStart = myLoaderclipStart
			MyLoader.ClipTimeEnd = clipEnd
			MyLoader.HoldFirstFrame = holdFirstFrame
			MyLoader.HoldLastFrame = holdLastFrame
			MyLoader.GlobalIn = globalIn
			MyLoader.GlobalOut = globalOut
			]]--

			newFileParse = bmd.parseFilename(newFile)

			myLoader.Comments = "mEXR CHILD:" .. newFileParse.CleanName
			print ("Set ".. myLoader.Name ..".comments to " .. "mEXR CHILD:" .. newClipFileParse.CleanName)
		end

	end -- End of For Loop that iterates thru tool selection
	comp:Unlock()
end



--// Scan Selected Tool //--
function scanSelectedTool()

	print ("scanSelectedTool landmark 01")-------------------------------------

	tool = composition:GetToolList(true,"Loader")
	
	print ("scanSelectedTool landmark 02")-------------------------------------

	if tool[1] == nil then
		--// Pop-up Window to Let User Know Error //--
		ret = composition:AskUser("Must Select a Loader",{})
		print ("Must Select a Loader")
		return nil
	else
		tool = tool[1]

		dump(tool)

		toolName = tool:GetAttrs().TOOLS_Name
		myLoader = tool -- give the tool a variable name that makes sense in the script

		dump(myLoader)

		print ("scanSelectedTool landmark 03")-------------------------------------
		--loaderClip = myLoader.Clip[comp.CurrentTime]
		loaderClip = myLoader.Clip[comp.CurrentTime]

		print ("scanSelectedTool landmark 04")-------------------------------------
		print (loaderClip)

		print ("scanSelectedTool landmark 05")-------------------------------------

		if (loaderClip ~= "" and loaderClip ~= nil) then

			print ("scanSelectedTool landmark 08")-------------------------------------

			loaderClip = myLoader.Clip[comp.CurrentTime]
			fileParse = bmd.parseFilename(loaderClip)

			clipFolderPath = fileParse.Path
			clipCleanFileName = fileParse.CleanName
			clipFileType = fileParse.Extension
			clipFullName = fileParse.FullName

			return loaderClip

		end --End of If Clip Exists
	end --End of If Loader

end --End of Function


--// Scan Composition and Update Loaders //--
function updateLoaders(oldLoaderClip, newFileName, onlySelectedLoaders)

	comp:Lock()

	newClipFileParse = bmd.parseFilename(newFileName)

	for i, tool in ipairs(composition:GetToolList(onlySelectedLoaders,"Loader")) do -- iterate through all tools in the comp

		toolName = tool:GetAttrs().TOOLS_Name
		myLoader = tool -- give the tool a variable name that makes sense in the script

		loaderClip = (myLoader.Clip[comp.CurrentTime])

		if loaderClip == oldLoaderClip then

			print ("\n"..toolName)
			print ("Found match")

			--Store Variables from current footage
			loaderClip = myLoader.Clip[comp.CurrentTime]

			fileParse = bmd.parseFilename(loaderClip)

			clipFolderPath= fileParse.Path
			clipCleanFileName = fileParse.CleanName
			clipFileType = fileParse.Extension
			clipFullName = fileParse.FullName

			clipStart = myLoader.ClipTimeStart
			clipEnd = myLoader.ClipTimeEnd
			holdFirstFrame = myLoader.HoldFirstFrame
			holdLastFrame = myLoader.HoldLastFrame
			globalIn = myLoader.GlobalIn
			globalOut = myLoader.GlobalOut


			-- replace loader clip
			myLoader.Clip[comp.CurrentTime] = newFileName

			-- Match old trim in/trim out settings
			--[[
			myLoader.ClipTimeStart = clipStart
			myLoader.ClipTimeEnd = clipEnd
			myLoader.HoldFirstFrame = holdFirstFrame
			myLoader.HoldLastFrame = holdLastFrame
			myLoader.GlobalIn = globalIn
			myLoader.GlobalOut = globalOut
			]]--

			-- Assign custom comment to loader
			if (myLoader.Comments) then --does the tool have a Comments tab?

			if string.find(myLoader.Comments[comp.CurrentTime], "mEXR BEAUTY:") then
				myLoader.Comments = "mEXR BEAUTY:" .. newClipFileParse.CleanName
				print ("Set "..toolName..".comments to " .. "mEXR BEAUTY:" .. newClipFileParse.CleanName)
			end
		end

			print ("Set "..toolName..".clip to "..newFileName)

			--tool:SetAttrs{["TOOLST_AltClip_Name"]= nil}

		else
			-- skip loader
		end

	end -- End of For Loop that iterates thru tool selection

	comp:Unlock()


end --End of Function


--// Scan for Loaders with Comment //--
function scanForChildLoaders(beautyCleanName)

	MyCnt = 0

	-- Create empty table
	childLoaderTable = {}

	for i, tool in ipairs(composition:GetToolList(false,"Loader")) do -- iterate through all loaders in the comp

		id = tool:GetAttrs().TOOLS_RegID
		MyName = tool:GetAttrs().TOOLS_Name

		if (tool.Comments) then --does the tool have a Comments tab?

			if string.find(tool.Comments[comp.CurrentTime], ("mEXR CHILD:" .. beautyCleanName)) then
				MyCnt=MyCnt+1

				table.insert (childLoaderTable, tool)
				--flow:Select(tool,true) -- Add the current tool to selection
			end
		end
	end

	return childLoaderTable

end -- end of function


-----------------------------------------------------------------------------------------
--	EXECUTE SCRIPT
-----------------------------------------------------------------------------------------

print "============== SCRIPT BEGIN =============="

oldLoaderClip = scanSelectedTool()

print("landmark 01")

if oldLoaderClip ~= nil then
	oldFileParse = bmd.parseFilename(oldLoaderClip)
	oldClipFolderPath = oldFileParse.Path
	oldClipCleanName = oldFileParse.CleanName

	--=============================================================================================--
	--// Pop-up Window //--

		ret = composition:AskUser("Update Loaders v2.2",
				{
				{"Instructions:","Text", Default = "\n- Choose new file for the selected loader\n- The script will update other loaders that share the same file\n- Can update multi-pass sequences that were loaded using the mEXR script", ReadOnly=true, Lines=6,Width=2.5},
				{"Selected Loader:","Text",Lines =1, ReadOnly = true, Default = toolName },
				{"Current File:","Text", Lines =1, ReadOnly=true, Default = oldFileParse.FullName},
				{"Only Selected Loaders","Checkbox", Default = 0},
				{"Update All Associated Passes","Checkbox", Default = 1},
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
			print (filePathBrowse)

		-- Define user Variable
			onlySelectedLoaders = ret["Only Selected Loaders"]
			if onlySelectedLoaders == 1 then
				onlySelectedLoaders = true
			else
				onlySelectedLoaders = false
			end

			print (onlySelectedLoaders)

		-- Define user Variable
			updateSeperateLoaders = ret["Update All Associated Passes"]
			if updateSeperateLoaders == 1 then
				updateSeperateLoaders = true
			else
				updateSeperateLoaders = false
			end

	--// Main Execution of Script //--

	-- Check new file path is valid

		if fileexists(filePathBrowse) then

			updateLoaders(oldLoaderClip, filePathBrowse, onlySelectedLoaders)

			if updateSeperateLoaders == true then

				childLoaderList = scanForChildLoaders(oldClipCleanName)

				getOldLoaderClipFolders(filePathBrowse, false, childLoaderList)
			end

			--// Pop-up Window to Let User Know Script is Complete //--
			ret = composition:AskUser("Script Complete!",{})
		else
			ret = composition:AskUser("ERROR: File Path Not Valid",{})
		end
end -- end of If loader clip is not nil
print "============== SCRIPT END =============="

