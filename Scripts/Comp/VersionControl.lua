--[[--
	Fusion 9 Loaders Version Control, Muse VFX edition
	v1.3 - 2018-05-14
	by Bryan Ray with input from the We Suck Less community. Special thanks to Steven Benjamin, pingking, Cedric Duriau, 'Greg Bovine',
		and Andrew Hazelden.

	=====Overview======

	Updates the version of multiple Loaders. Allows the user to choose a version for one or more Loaders simultaneously.

	This script is tailored to the Muse VFX pipeline. It may not function in other pipelines, but the development thread at We Suck Less
	(see below) and in-line comments contain detailed information about its construction to allow others to easily modify the script for 
	their own use.
	
	The development thread at We Suck Less: 
	https://www.steakunderwater.com/wesuckless/posting.php?mode=reply&f=6&t=1854#pr13878
	

	=====License======

	This script is released to the public domain, and no guarantee is made as to its suitability for any particular purpose. No warranty
	is provided, and no burden of support is assumed by any of its creators or distributors. 


-- To Do: 	
		MuseTools edition: Correct handling of render layers: Element / layer / buffer
			Do I really need this? Do we need to filter for scene file? There could be collisions resulting from 
			layers named identically in two or more scenes.
		When multiple options found, create a dialog for user selection.
		Refactor
			More pipeline-customizability at head
		Improve color schema
		Add OK/Cancel buttons?
			If so, alter the window closed event.
			Close window and commit on selection, maybe? 

		Create a generic fork that removes Muse-specific pipeline

		Tile color by hue 

--]]--




-- ===========================================================================
-- constants
-- ===========================================================================

-- PIPELINE CONFIG
VERSION_FORMAT = "[Vv]%d+"	-- Matches v## format. This will match element_v03 or v03_element, as well. For v_## use "[Vv]_%d+". 
							-- And beware of projects or elements that end with a v. Dragunov1, for instance, will give you a false match.

RESOLUTION_FORMAT = "%d+[Xx]%d+"	-- Matches ####x#### format for resolution folder. Beware of projects or shots that match this pattern.
									-- 2x4 will give a false match.

LAYER_POSITION = 1			-- The Version folder has a predictable format, so it is used as a signpost for discovering the render Layer.
							-- In the default pipeline, the Layer is one level up (to the left) from the Version. If you have a path such as
							-- project/shot/renders/VERSION/resolution/LAYER/buffer/foo.####.exr, then the layer name is 2 levels below the
							-- version, and this value should therefore be 2.

COMP_FILE_DEPTH = 3			-- Determines how deep in the shot directory structure the comp file lives. This is used to identify assets that
							-- are external to the shot folder.

FILE_TYPES = { 'jpg', 'png', 'exr', 'dpx', 'tga', 'tif', 'tiff', 'jpeg', }

SEPARATOR = package.config:sub(1,1)	-- Folder separator used by the Operating System.

-- Configuration information for the UI.
TREE_COLUMNS = {"Layer", "Version", "Lock", "File Path", "Resolution"}	
COLUMN_WIDTHS = {180, 80, 40, 690, 90}


-- Data structures for holding a LayerSet. For the future: Learn about making classes in Lua: http://lua-users.org/wiki/SimpleLuaClasses
LAYER_STRUCT = { 
		layer = "", 			-- Layer name. string 
		version = "", 			-- Layer version. string
		locked = false, 		-- Can this Layer be updated? Boolean
		path = "", 				-- Path to the Layer parent folder. NOT the file. string
		res = "",				-- Resolution 
		}

CHILD_STRUCT = {
		pass = "",	 			-- Buffer name. string
		version = "",			-- Buffer version. string
		locked = false,			-- Can this Loader be updated? Boolean
		path = "",				-- Full path to the file. string
		passthrough = false,
		} 


-- ===========================================================================
-- globals
-- ===========================================================================
_fusion = nil
_comp = nil



-- ===========================================================================
-- Functions                   
-- ===========================================================================


-- *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- This function is tailored to the pipeline where the script is to be used.
-- It parses a Loader's Clip to extract data necessary for the rest of the functions to operate.
-- Hopefully, it will eventually be documented well enough to allow a TD of moderate skill
-- to easily customize it.
-- *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- getLayer(tool)
--
-- Arguments: 
-- 		tool, table reference, a Loader
-- Returns: out, table, a table containing data formatted for LOADER_SETS
-------------------------------------------------------------------------
function getLayer(tool)

	-- Create a table out of the clip's path
	local pathTable = split(_comp:MapPath(tool:GetInput("Clip")), SEPARATOR)

	-- Copy the data structures into the output variable
	local out = tableCopy(LAYER_STRUCT)
	out.children = {}
	out.children[1] = tableCopy(CHILD_STRUCT)

	-- Get the version number and record its position in the path
	local versionFolderDepth
	out.version, versionFolderDepth = getVersionFromPath(pathTable, VERSION_FORMAT) 

	local position = 0
	local tableSize = table.getn(pathTable)

	-- Muse VFX Edition: We have a pipeline mismatch between renders from Max and from Houdini
	-- This line corrects for that discrepancy. 
	position = adjustPosition(pathTable, versionFolderDepth, tool)

	-- Muse VFX Edition: Identifies the resolution folder.
	out.res, _ = getResolutionFromPath(pathTable, versionFolderDepth, RESOLUTION_FORMAT, position)

	-- Get the render Layer's name
	out.layer = pathTable[versionFolderDepth + position]

	-- Reconstruct partial path to root of layer
	out.path = buildPath(pathTable, versionFolderDepth + position)	

	-- Record information about the Loader
	out.children[1].pass = tool.Name
	out.children[1].path = _comp:MapPath(tool.Clip[_fusion.TIME_UNDEFINED])
	out.children[1].version = out.version
	out.children[1].tool = tool 		

	-- Determine if the Loader is local to the shot
	if isLocal(pathTable) == false then
		out.colors = {R = 0.4, G = 0.4, B = 0.1, A = 1}
		out.children[1].colors = {R = 0.4, G = 0.4, B = 0.1, A = 0.5}
	end

	-- Muse VFX Edition: 05_output contains rendered comps. We generally don't want to alter
	-- these versions because they're used for viewing historical changes in the shot.
	-- We therefore pre-lock them.

	if out.layer == "05_output" then lockLoader(tool.Name, true) end

	if tool:GetData("locked") == true then
		out.children[1].locked = true
	else
		out.children[1].locked = false
	end

	out.children[1].passthrough = tool:GetAttrs().TOOLB_PassThrough

	-- Test to be sure we found a version folder
	if versionFolderDepth > 1 then
	else 	-- Loader is versionless, but we'll store it anyway. We may want to add more 
			-- features later that would work on versionless elements.
		out.path = tool.Clip[_fusion.TIME_UNDEFINED] 
		out.version = ''
		out.layer = tool.Name
		out.children[1].version = ''
		--_comp:Print("Version number not found for " .. tool.Name .. ". \n")
	end

	return out

end -- end of getLayer()




--=========================================================================================
-- Main Code
--=========================================================================================

function main()
	-- get fusion instance
	_fusion = getFusion()

	-- ensure a fusion instance was retrieved
	if not _fusion then
		error("Please open the Fusion GUI before running this tool.")
	end

	-- get composition
	_comp = _fusion.CurrentComp
	SetActiveComp(_comp)

	-- Set up aliases to the UI Manager framework
	ui = _fusion.UIManager
	disp = bmd.UIDispatcher(ui)

	-- Gather Loader Sets
	createLoaderSets()

	-- create the main window
	local x = _fusion:GetMousePos()[1]
	local y = _fusion:GetMousePos()[2]
	local width = 1200
	local windowSz = 60 + table.getn(LOADER_SETS) * 20

	mainWindow = createMainWindow(x, y, width, windowSz, "Loaders Version Control")
	mainWindowItems = mainWindow:GetItems()

	-- assign signals
	-- A tree row was clicked on
	function mainWindow.On.tree.ItemClicked(ev)
		if ev.column == 1 then 							-- Loader name
			if ev.item:ChildCount() == 0 then
				local x = _fusion:GetMousePos()[1]
				local y = _fusion:GetMousePos()[2]
				renameLoader(x-120, y-30, 240, 60, ev.item)
			end
		end
		if ev.column == 2 then 							-- Version
			if ev.item.Text[2] == '' then
				-- Do nothing: no versions
			else
				local x = _fusion:GetMousePos()[1]
				local y = _fusion:GetMousePos()[2]
				ChooseVersion(x-120, y-30, 240, 60, ev.item)
			end
		end

		if ev.column == 3 then  						-- Lock
			lockLoader(ev.item.Text[1], ev.item.CheckState[3])
		end

		if ev.column == 4 then 							-- Path
			bmd.setclipboard("\""..ev.item.Text[4].."\"")
		end

		if ev.column == 5 then 							-- Resolution
			if ev.item.Text[5] == '' then
				-- Do nothing: No resolution folder
			else
				local x = _fusion:GetMousePos()[1]
				local y = _fusion:GetMousePos()[2]
				chooseResolution(x-120, y-30, 240, 60, ev.item)
			end
		end
	end

	-- close event
	function mainWindow.On.VersionControl.Close(ev) disp:ExitLoop() end


	-- configure tree
	configureTree(mainWindowItems.tree, TREE_COLUMNS, COLUMN_WIDTHS)

	-- add items
	populateLoaderTree(LOADER_SETS)


	mainWindow:Show()
	disp:RunLoop()
	mainWindow:Hide()

end -- end of Main()



--==========================================================================
-- Processing Functions
-- These routines are used to modify the Loaders and provide an interface to
-- the user for doing so.
--==========================================================================



---------------------------------------------------------------------------------------
-- updateLoaders(set, version)
--
-- Repath selected Loaders to new version.
--
-- Arguments:
-- 		set, string, the name of the layer as contained in the Layer column of the tree
--		version, string, the new version
-- Returns: nothing
---------------------------------------------------------------------------------------
function updateLoaders(set, version)
	_comp:Print("Locking...\n")
	lockComp(_comp)		-- Suppress File browsers and prevent Viewer updates

	local tools = {}
	local oldColor = {}
	local thisLayer = {}


	-- Get the layer from LOADER_SETS
	for i, layer in ipairs(LOADER_SETS) do
		if set == layer.layer then
			-- Get a list of tools
			for i, child in ipairs(layer.children) do
				tools[i] = child.tool

				-- Get the color from the last processed Loader that is not locked
				if child.tool:GetData("locked") == true then
					--do nothing
				else
					oldColor = child.tool.TileColor
				end
			end
			thisLayer = layer
			break
		end
	end


	-- UI Manager progress bar
	local totalSteps = table.getn(tools)
	local msgwin, msgitm = ProgressWinCreate()


	-- Determine the new tile color for this set
	local color = cycleColor(oldColor)


	for i, tool in ipairs(tools) do

		-- Update the progress bar
		ProgressWinUpdate(msgwin, msgitm, "Processing Loaders", i, totalSteps)

		-- Extract data about the path
		local pathTable = split(tool:GetInput("Clip"), SEPARATOR)
		local versionFolderDepth
		_, versionFolderDepth = getVersionFromPath(pathTable, VERSION_FORMAT) 
		local position = adjustPosition(pathTable, versionFolderDepth, tool)
		local tableSize = table.getn(pathTable)

		-- Filter for Locked status
		if tool:GetData("locked") == true then 
			_comp:Print(tool.Name.." is locked.\n")
		else

			-- Store In/Out
			local globalIn = tool.GlobalIn[_fusion.TIME_UNDEFINED]
			local globalOut = tool.GlobalOut[_fusion.TIME_UNDEFINED]
			local trimIn = tool.ClipTimeStart[_fusion.TIME_UNDEFINED]
			local trimOut = tool.ClipTimeEnd[_fusion.TIME_UNDEFINED]
			local holdFirst = tool.HoldFirstFrame[_fusion.TIME_UNDEFINED]
			local holdLast = tool.HoldLastFrame[_fusion.TIME_UNDEFINED]

			-- Replace Version folder in path table
			pathTable[versionFolderDepth] = version

			-- Replace version in filename
			pathTable[tableSize] = string.gsub(pathTable[tableSize], VERSION_FORMAT, version)

			-- Check for resolution change
			local res = ''
			local resolutionFolderDepth = 0
			res, resolutionFolderDepth = getResolutionFromPath(pathTable, versionFolderDepth, RESOLUTION_FORMAT)
			resPath = buildPath(pathTable, resolutionFolderDepth - 1)
			resList = listFolders(resPath)
			res = resList[table.getn(resList)]
			pathTable[resolutionFolderDepth] = res

			-- Test for file format change
			notFound = true
			for key, value in pairs(FILE_TYPES) do
				pathTable[tableSize] = string.gsub(pathTable[tableSize], "%.%a+", "."..value)

				-- Reconstruct path
				local path = buildPath(pathTable) 			

				-- Check for files in path
				if bmd.fileexists(path) then
					-- update Clip
					tool.Clip[_fusion.TIME_UNDEFINED] = path

					--Restore In/Out
					tool.GlobalIn[_fusion.TIME_UNDEFINED] = globalIn
					tool.GlobalOut[_fusion.TIME_UNDEFINED] = globalOut
					tool.ClipTimeStart[_fusion.TIME_UNDEFINED] = trimIn
					tool.ClipTimeEnd[_fusion.TIME_UNDEFINED] = trimOut
					tool.HoldFirstFrame[_fusion.TIME_UNDEFINED] = holdFirst
					tool.HoldLastFrame[_fusion.TIME_UNDEFINED] = holdLast

					-- Change tile color
					tool.TileColor = color

					-- Update entry in LOADER_SETS
					thisLayer.children[i].path = path
					thisLayer.children[i].version = version
					thisLayer.version = version

					-- Log change in console
					_comp:Print("Version Control: "..tool.Name.." updated to version "..version.."\n")
					notFound = false
					break
				end
			end -- end of for each FILE_TYPES
			if notFound == true then
				_comp:Print("Version Control: Could not update "..tool.Name..". New file not found.\n")
				thisLayer.children[i].colors = { R = 0.6, G = 0.1, B = 0.1, A = 1 }	
			end
		end -- end of if locked
	end -- end of for each tool

	unlockComp(_comp)
	_comp:Print("Unlocked.\n")

	-- Destroy the progress bar
	msgwin:Hide()
end -- end of updateLoaders()


---------------------------------------------------------------------------------------
-- updateResolution(set, resolution)
--
-- Updates Loader paths with a new resolution folder.
--
-- Arguments: 
-- 		set, string, the name of the layer as contained in the Layer column of the tree
--		resolution, string, the name of the resolution folder selected by the user
-- Returns:
-- 		nothing
---------------------------------------------------------------------------------------
function updateResolution(set, resolution)
	_comp:Print("Locking...\n")
	lockComp(_comp)		-- Suppress file browsers and prevent Viewer updates

	local tools = {}
	local oldColor = {}
	local thisLayer = {}


	-- Get the layer from LOADER_SETS
	for i, layer in ipairs(LOADER_SETS) do
		if set == layer.layer then
			-- Get a list of tools
			for i, child in ipairs(layer.children) do
				tools[i] = child.tool

				-- Get the color from the last processed Loader that is not locked
				if child.tool:GetData("locked") == true then
					--do nothing
				else
					oldColor = child.tool.TileColor
				end
			end
			thisLayer = layer
			break
		end
	end


	-- UI Manager progress bar
	local totalSteps = table.getn(tools)
	local msgwin, msgitm = ProgressWinCreate()

	for i, tool in ipairs(tools) do

		-- Update the progress bar
		ProgressWinUpdate(msgwin, msgitm, "Processing Loaders", i, totalSteps)

		if tool:GetData("locked") == true then
			_comp:Print(tool.Name .. " is locked.\n")
		else
			local pathTable = split(tool:GetInput("Clip"), SEPARATOR)
			local versionFolderDepth
			local depth = 0
			_, versionFolderDepth = getVersionFromPath(pathTable, VERSION_FORMAT)
			
			for i, folder in ipairs(pathTable) do
				if string.match(pathTable[i], RESOLUTION_FORMAT) then
					depth = i
					break
				end
			end

			local position = adjustPosition(pathTable, versionFolderDepth, tool)
			local layer = pathTable[versionFolderDepth + position]
			local tableSize = table.getn(pathTable)


			-- Store In/Out
			local globalIn = tool.GlobalIn[_fusion.TIME_UNDEFINED]
			local globalOut = tool.GlobalOut[_fusion.TIME_UNDEFINED]
			local trimIn = tool.ClipTimeStart[_fusion.TIME_UNDEFINED]
			local trimOut = tool.ClipTimeEnd[_fusion.TIME_UNDEFINED]
			local holdFirst = tool.HoldFirstFrame[_fusion.TIME_UNDEFINED]
			local holdLast = tool.HoldLastFrame[_fusion.TIME_UNDEFINED]

			-- Replace Resolution folder in path table
			pathTable[depth] = resolution

			-- Check for files in path
			-- We want to test for changed file formats as well.
			notFound = true
			for key, value in pairs(FILE_TYPES) do
				pathTable[tableSize] = string.gsub(pathTable[tableSize], "%.%a+", "."..value)
				local path = buildPath(pathTable)

				if bmd.fileexists(path) then
					--update clip
					tool.Clip[_fusion.TIME_UNDEFINED] = path

					--Restore In/Out
					tool.GlobalIn[_fusion.TIME_UNDEFINED] = globalIn
					tool.GlobalOut[_fusion.TIME_UNDEFINED] = globalOut
					tool.ClipTimeStart[_fusion.TIME_UNDEFINED] = trimIn
					tool.ClipTimeEnd[_fusion.TIME_UNDEFINED] = trimOut
					tool.HoldFirstFrame[_fusion.TIME_UNDEFINED] = holdFirst
					tool.HoldLastFrame[_fusion.TIME_UNDEFINED] = holdLast	

					-- Update LOADER_SETS
					thisLayer.res = resolution

					-- Log change in console
					_comp:Print("Version Control: "..tool.Name.." updated to "..resolution.."\n")
					notFound = false
					break
				end
			end
			if notFound == true then
				_comp:Print("Version Control: Could not update "..tool.Name..". New file not found.\n")
				thisLayer.children[i].colors = { R = 0.6, G = 0.1, B = 0.1, A = 1 }	
			end
		end
	end

	unlockComp(_comp)
	_comp:Print("Unlocked.\n")

	-- Destroy the progress bar
	msgwin:Hide()
end -- end of updateResolution()


--------------------------------------------------------------------
-- renameLoader()
--
-- Provides an interface for the user to change
-- the name of a Loader from the script interface. Contains
-- both the interface and the update code.
--
-- Arguments:
--		x, integer, the X-coordinate where the interface will appear
--		y, integer, the Y-coordinate where the interface will appear
--		width, integer, the width in pixels of the interface
--		height, integer, the height in pixels of the interface
--		item, table, the tree row the user clicked on
-- Returns:
-- 		nothing
--------------------------------------------------------------------
function renameLoader(x, y, width, height, item)
	local ldrName = item.Text[1]
	local tools = _comp:GetToolList(false, "Loader")
	local ldr = ''
	for i, tool in ipairs(tools) do
		if tool.Name == ldrName then
			ldr = tool
			break
		end
	end

	winName = createRenameWindow(x, y, width, height, "Rename Loader", ldrName)
	itmName = winName:GetItems()
	itmName.newName:SelectAll()

	function winName.On.Rename.Close(ev)
		if ldrName == itmName.newName.Text then
			winName:Hide()	-- Do nothing
		else
			winName:Hide()
			ldr:SetAttrs({TOOLS_Name = itmName.newName.Text, TOOLB_NameSet = true})
			item.Text[1] = itmName.newName.Text
			_comp:Print(ldrName.." renamed to "..itmName.newName.Text.."\n")
		end
	end

	function winName.On.newName.ReturnPressed(ev)
		if ldrName == itmName.newName.Text then
			winName:Hide()	-- Do nothing
		else
			winName:Hide()
			ldr:SetAttrs({TOOLS_Name = itmName.newName.Text, TOOLB_NameSet = true})
			item.Text[1] = itmName.newName.Text
			_comp:Print(ldrName.." renamed to "..itmName.newName.Text.."\n")
		end
	end

	winName:Show()
end -- end of renameLoader()



--------------------------------------------------------------------
-- ChooseVersion(x, y, width, height, item)
--
-- Provides an interface for changing a layer's version
--
-- Arguments:
-- 		x, integer, the X-coordinate where the interface will appear
--		y, integer, the Y-coordinate where the interface will appear
--		width, integer, the width in pixels of the interface
--		height, integer, the height in pixels of the interface
--		item, table, the tree row the user clicked on
-- Returns:
-- 		nothing
--------------------------------------------------------------------
function ChooseVersion(x, y, width, height, item)

	-- Create UI Manager Window
	winVer = createVersionWindow(x, y, width, height, "Choose Version")
	itmVer = winVer:GetItems()

	-- Construct a path to the folder just below the version
	local pathTable = split(item.Text[4], SEPARATOR)
	local version
	local depth

	version, depth = getVersionFromPath(pathTable, VERSION_FORMAT)
	if depth == 1 then	-- Version number not found, it's probably to the right of the Layer (Max render).
		depth = table.getn(pathTable)
	end

	path = buildPath(pathTable, depth-1)

	versionList = listFolders(path)

	--Cull empty versions from the list
	versionList = cullEmptyVersions(versionList, item.Text[4])

	for i, j in ipairs(versionList) do 		-- Populates the combo box
		itmVer.VersionList:AddItem(j)
	end

	itmVer.VersionList.CurrentText = item.Text[2]

	function winVer.On.Versions.Close(ev) 
		if item.Text[2] == itmVer.VersionList.CurrentText then
			winVer:Hide()	-- No change, just destroy the window.
		else
			item.Text[2] = itmVer.VersionList.CurrentText
			winVer:Hide()
			updateLoaders(item.Text[1], itmVer.VersionList.CurrentText) 
			--Repopulate tree 
			mainWindowItems.tree:Clear()
			populateLoaderTree(LOADER_SETS)
		end
	end

	winVer:Show()
end -- end of ChooseVersion()



--------------------------------------------------------------------
-- chooseResolution()
--
-- Provides an interface for changing to a different 
-- resolution, assuming multiple resolution folders are
-- present. 
-- Arguments:
--		x, integer, the X-coordinate where the interface will appear
--		y, integre, the Y-coordinate where the interface will appear
--		width, integer, the width in pixels of the interface
--		height, integer, the height in pixels of the interface
--		item, table, the tree row the user clicked on
-- Returns:
-- 		nothing
--------------------------------------------------------------------
function chooseResolution(x, y, width, height, item)

	-- Create UI Manager Window
	winRes = createVersionWindow(x, y, width, height, "Choose Resolution")
	itmRes = winRes:GetItems()

	-- Determine associated Layer
	for i, set in ipairs(LOADER_SETS) do
		if item.Text[1] == set.layer then
			path = set.children[1].path
			break
		end
	end

	-- Construct a path to the folder just below the resolution
	local pathTable = split(path, SEPARATOR)

	local depth = 0
	for i, folder in ipairs(pathTable) do
		if string.match(pathTable[i], RESOLUTION_FORMAT) then
			depth = i
			break
		end
	end


	if depth == 0 then 
		depth = table.getn(pathTable)
	end

	path = buildPath(pathTable, depth-1)

	resList = listFolders(path)

	for i, j in ipairs(resList) do
		itmRes.VersionList:AddItem(j)
	end

	itmRes.VersionList.CurrentText = item.Text[5]

	function winRes.On.Versions.Close(ev)
		if item.Text[5] == itmRes.VersionList.CurrentText then
			winRes:Hide() -- No change, just destroy the window
		else
			item.Text[5] = itmRes.VersionList.CurrentText
			winRes:Hide()
			updateResolution(item.Text[1], itmRes.VersionList.CurrentText)
			-- Repopulate Tree
			mainWindowItems.tree:Clear()
			populateLoaderTree(LOADER_SETS)
		end
	end

	winRes:Show()

end -- end of chooseResolution()




--===================================================================
-- Utility Functions
-- 
-- These functions support operation of the script but are specific
-- enough that they're not likely to be useful in other contexts
--===================================================================


------------------------------------------------------------------------
-- createLoaderSets()
--
-- Constructs and populates the LOADER_SETS global table. If there are a 
-- large number of Loaders in the comp, this can take a while, so a 
-- progress bar is provided.
--
-- Arguments: None
-- Returns: Nothing, but creates a global table
------------------------------------------------------------------------
function createLoaderSets()
	LOADER_SETS = {}
	local tools = _comp:GetToolList(false, "Loader")
	
	-- UI Manger progress bar
	local totalSteps = table.getn(tools)
	local msgwin, msgitm = ProgressWinCreate()


	for i, tool in pairs(tools) do

		-- Update the progress bar
		ProgressWinUpdate(msgwin, msgitm, "Gathering Loaders", i, totalSteps)
		
		-- Get data
		local thisLayer = getLayer(tool)

		if layerExists(thisLayer.layer) == true then 
			addLayerChild(thisLayer)
		else 
			createLayer(thisLayer) 
		end
	end

	-- Put the Layers in alphabetical order
	table.sort(LOADER_SETS, function(a, b)
		return (a.layer < b.layer)
	end)

	-- Destroy the progress bar
	msgwin:Hide()
end -- end of createLoaderSets()


-------------------------------------------------------------------------------------
-- cullEmptyVersions(list, path)
--
-- Searches a list of folders for files. If no files are found in a particular folder
-- it is removed from the list. This ensures that the user cannot attempt to update 
-- to a version that doesn't exist. This is necessary in the event that the Layer 
-- folder is inside the version folder.
--
-- Arguments:
--		list, table, folder names
--		path, string, the path to a layer set
-- Returns:
--		list, table, A table of folder names from which empty paths have been removed
-------------------------------------------------------------------------------------
function cullEmptyVersions(list, path)

	-- Identify the relevant layer from LOADER_SETS using the path
	local thisLayer = {}
	for i, layer in ipairs(LOADER_SETS) do
		if layer.path == path then
			-- layer found
			thisLayer = layer
			break
		end
	end

	-- determine the depth of the version folder
	local pathTable = split(thisLayer.children[1].path, SEPARATOR)
	local depth = 0
	_, depth = getVersionFromPath(pathTable, VERSION_FORMAT)

	
	for i, item in ipairs(list) do
		-- construct a path for the version in question
		-- perform a fileexists check on the path for each Loader in the set
		local flag = false
		for i, child in ipairs(thisLayer.children) do
			local childPathTable = split(child.path, SEPARATOR)
			childPathTable[depth] = version
			local newPath = buildPath(childPathTable)
			if bmd.fileexists(newPath) then
				flag = true
				break
			end
		end
		-- if none of the files are found, remove the version from the list
		if flag == false then
			table.remove(list, i)
		end
	end

	return list
end -- end of cullEmptyVersions()


--------------------------------------------------------------------------
-- lockLoader(toolname, state)
--
-- Locks or unlocks a Loader. Sets the tile color to blue if the Loader
-- is being locked and back to its original color if it is being unlocked.
--
-- Arguments:
--		toolname, string, the name of a Loader
--		state, boolean or string, the desired end status for the Loader
-- Returns: Nothing
--------------------------------------------------------------------------
function lockLoader(toolname, state)
	local lock = false
	local report = "false"
	if state == "Checked" or state == true then 
		lock = true 
		report = "true"
	end
	tools = _comp:GetToolList(false, "Loader")
	for i, tool in pairs(tools) do
		if tool.Name == toolname then
			tool:SetData("locked", lock)
			if lock == true then
				tool:SetData("color", tool.TileColor)
				tool.TileColor = {R = 0.2, G = 0.2, B = 0.5}
			else
				tool.TileColor = tool:GetData("color")
			end
			_comp:Print(tool.Name.." lock status set to "..report..".\n")
			break 
		end
	end
end -- end of lockLoader


---------------------------------------------------------------------------------------------------
-- adjustPosition(pathTable, versionFolderDepth, tool)
--
-- Compensates for a pipeline irregularity at Muse VFX. Houdini and
-- Max renders do not have the same path structure, and all CG renders have an extra
-- folder in the path.
-- 
-- Arguments:
--		pathTable, table, a file path parsed into a table
-- 		versionFolderDepth, integer, the index of the version folder in pathTable
--		tool, table reference, a Fusion Loader
-- 	Returns:
--		position, integer, an adjusted LAYER_POSITION for calculating the index of the layer folder
---------------------------------------------------------------------------------------------------
function adjustPosition(pathTable, versionFolderDepth, tool)
	local position = 0
	local tableSize = table.getn(pathTable)
	-- Rendered CG elements have a different path pattern than other elements. 
	-- Adjust the Layer position based on whether or not "renders" was detected.
	if pathTable[versionFolderDepth - 2] == "renders" or pathTable[versionFolderDepth - 3] == "renders" then 
		-- Houdini and Max currently build their paths differently. Check for Houdini's
		-- "_RGBA" buffer folder and adjust accordingly.
		local flag = false
		for i, folder in pairs(listFolders(buildPath(pathTable, tableSize-2))) do
			if folder == "_RGBA" then 
				flag = true
				tool:SetData("Houdini", true)
				break 
			end
		end

		if flag == true then
			position = LAYER_POSITION
		else
			position = -1
		end

	else
		position = -1
	end

	return position
end -- end of adjustPostion()


--------------------------------------------------------------------------
-- layerExists(layer)
--
-- Tests for presence of a render layer in LOADER_SETS, a global table
--
-- Arguments:
--		layer, string, the name of a layer
-- Returns:
--		boolean indicating whether or not the layer was found in the table
---------------------------------------------------------------------------
function layerExists(layer)
	for i, set in pairs(LOADER_SETS) do
		if layer == set.layer then
			return true end
	end
	return false
end -- end of layerExists()


-----------------------------------------------------------------------------------------
-- createLayer(layer)
--
-- Adds a layer to LOADER_SETS
--
-- Arguments:
-- 		layer, table, a layer conforming to the data structure described in the constants
-- Returns:
--		nothing, but inserts a record into a global table
-----------------------------------------------------------------------------------------
function createLayer(layer)
	table.insert(LOADER_SETS, layer)
end -- end of createLayer()


---------------------------------------------------------
-- addLayerChild(layer)
--
-- Copies a Child record into a layer
--
-- Arguments:
--		layer, table, a layer record containing a Loader
-- Returns:
--		nothing, but inserts a record into a global table
---------------------------------------------------------
function addLayerChild(layer)
	for i, set in ipairs(LOADER_SETS) do
		if layer.layer == set.layer then
			child = tableCopy(layer.children[1])
			table.insert(set.children, child)
			break
		end
	end
end -- end of addLayerChild(layer)




--==================================================================
-- Library Functions
-- These routines are likely to be useful in other scripts
--==================================================================


-------------------------------------------------------------------------
-- getVersionFromPath(pathTable, pattern)
--
-- Extracts the version number from a table of folder names.
--
-- Arguments:
--		pathTable, table, a file path parsed into table form
--		pattern, string, a Lua string matching pattern
-- Returns:
--		version, string, the version number found in the table
--		i, integer, the table index at which the version number was found
-------------------------------------------------------------------------
function getVersionFromPath(pathTable, pattern)
	local i = table.getn(pathTable)
	while i > 1 do
		i = i - 1
		if string.match(pathTable[i], pattern) ~= nil then
			version = pathTable[i]
			break
		end
	end

	return version, i
end -- end of getVersionFromPath()


--------------------------------------------------------------------------------
-- getResolutionFromPath(pathTable, depth, pattern)
--
-- Extracts the name of the resolution folder from a table of folder names.
--
-- Arguments:
--		pathTable, table, a file path parsed into table form
--		pattern, string, a Lua string matching pattern
-- Returns:
--		res, string, the resolution folder found in the table
--		depth, integer, the table index at which the resolution folder was found
--------------------------------------------------------------------------------
function getResolutionFromPath(pathTable, depth, pattern)
	local res = ''
	for i, folder in ipairs(pathTable) do
		if string.match(pathTable[i], pattern) then
			res = pathTable[i]
			depth = i
			break
		end
	end
	return res, depth
end -- end of getResolutionFromPath


---------------------------------------------------------------------------------
-- buildPath(pathTable, [depth])
--
-- Creates a path string from a table of folders, ending at the 
-- specified index.
--
-- Arguments: 
--		pathTable, table, a path parsed into table format
--		depth, integer, optional the index of the last folder in the output path
-- Returns:
--		path, string, a path
--
-- @TODO: Generalize this function for non-Windows environments
---------------------------------------------------------------------------------
function buildPath(pathTable, depth)
	local path = pathTable[1] 	-- Initialize the path with the first folder to avoid having a slash at the beginning (Windows)
	if depth == nil then 		-- depth is an optional parameter. If omitted, the entire path is rebuilt.
		depth = table.getn(pathTable)
	end

	for j = 2, depth do
		path = path .. SEPARATOR .. pathTable[j]
	end

	if depth < table.getn(pathTable) then 	-- We didn't reach the file at the end of the path. Append a slash.
		path = path .. SEPARATOR
	end

	return path
end -- end of buildPath()


------------------------------------------------------------------------
-- getFusion()
--
-- check if global fusion is set, meaning this script is being
-- executed from within fusion
--
-- Arguments: None
-- Returns: handle to the Fusion instance
------------------------------------------------------------------------
function getFusion()
	if fusion == nil then 
		-- remotely get the fusion ui instance
		fusion = bmd.scriptapp("Fusion", "localhost")
	end
	return fusion
end -- end of getFusion()


-------------------------------------------------------------------------
-- listFolders(path)
--
-- Returns a table containing a sorted list of folders
--
-- Arguments: 
-- 		path, string
-- Returns:
--		folderList, table, a list of folders found at the end of the path
-------------------------------------------------------------------------
function listFolders(path)
	local folderList = {}
	local data = bmd.readdir(path..'*')
	for i, dir in ipairs(data) do 
		if dir.IsDir == true then
			table.insert(folderList, dir.Name)
		end
	end
	table.sort(folderList)
	return folderList
end -- end of listFolders(path)


-----------------------------------------------------------------------
-- tableCopy(table)
--
-- Makes a copy of a table. Does not copy metatables.
--
-- Arguments:
--		table, table, a table
-- Returns:
--		out, table, a copy of the input table
--
-- WARNING: Don't run on a table containing an empty table constructor.
-- Results in a recursive reference to the table instead of a copy of 
-- the constructor.
-----------------------------------------------------------------------
function tableCopy(table)
	out = {}
	for key, value in pairs(table) do
		if type(value) == 'table' then
			value = tableCopy(value)    -- Recursion to make copies of sub-tables.
		end
		out[key] = value
	end
	return out
end -- end of tableCopy


----------------------------------------------------------------------------
-- isLocal(pathTable)
--
-- Determines if the asset is local to the shot or project, depending on the 
-- value in COMP_FILE_DEPTH and the path to the active comp.
--
-- Arguments: 
-- 		pathTable, table, a path parsed into table format
-- Returns:
--		boolean, indicating whether or not the pathTable points to a location
--			shared with the active comp.
function isLocal(pathTable)
	local shotPath = _comp:MapPath("comp:")
	local shotPathTable = split(shotPath, SEPARATOR)
	for i=1, table.getn(shotPathTable) - COMP_FILE_DEPTH do
		if string.upper(shotPathTable[i]) ~= string.upper(pathTable[i]) then
			return false
		end
	end
	return true
end -- end of isLocal()


----------------------------------------------
-- cycleColor(oldColor)
--
-- Cycles colors through shades of orange.
--
-- Arguments:
--		oldColor, table, an RGB tool tileColor
-- Returns:
--		color, table, an RGB tool tileColor
----------------------------------------------
function cycleColor(oldColor)

	if oldColor == nil or oldColor.R == nil then
		color = { R=0.8, G=0.3, B=0, __flags=256, }
	else
		local r = oldColor.R
		local g = oldColor.G
		local b = oldColor.B
		r = r+0.25
		g = g+0.25
		if r > 1 then r = 0.8 end
		if g > 1 then g = 0.3 end
		if r == 1.0 then
			if b == 0 then
				if g == 0 then
					r = 0.8
					g = 0.3
					b = 0
				end
			end
		end

		color = {R = r, G = g, B = b, __flags = 256, }
	end

	return color
end -- end of cycleColor()


----------------------------------------------------------------------------------------------
-- Fusion can be locked or unlocked multiple times. These functions ensure that the lock state
-- is not nested.
----------------------------------------------------------------------------------------------

-- Unlocks the comp
function unlockComp(c)
	if c:GetAttrs().COMPB_Locked == false then lockComp(c) end
	while c:GetAttrs().COMPB_Locked == true do
		c:Unlock()
	end
end

-- Locks the comp
function lockComp(c)
	if c:GetAttrs().COMPB_Locked == true then unlockComp(c) end
	while c:GetAttrs().COMPB_Locked == false do
		c:Lock()
	end
end



--Functions lifted from bmd.scriptlib
-----------------------------------------------------
-- split(strInput, delimit)
--
-- converts string strInput into a table, separating
-- records using the provided delimiter string
--
-----------------------------------------------------
function split(strInput, delimit)
	local strLength
	local strTemp
	local strCollect
	local tblSplit
	local intCount

	tblSplit = {}
	intCount = 0
	strCollect = ""
	if delimit == nil then
		delimit = ","
	end

	strLength = string.len(strInput)
	for i = 1, strLength do
		strTemp = string.sub(strInput, i, i)
		if strTemp == delimit then
			intCount = intCount + 1
			tblSplit[intCount] = trim(strCollect)
			strCollect = ""
		else
			strCollect = strCollect .. strTemp
		end
	end
	intCount = intCount + 1
	tblSplit[intCount] = trim(strCollect)

	return tblSplit
end

-----------------------------------------------------
-- trim(strTrim)
--
-- returns strTrim with leading and trailing spaces
-- removed.
--
-- introduced bmd.dfscriptlib v1.0
-- last updated in v1.3
-----------------------------------------------------
function trim(strTrim)
	strTrim = string.gsub(strTrim, "^(%s+)", "") -- remove leading spaces
	strTrim = string.gsub(strTrim, "(%s+)$", "") -- remove trailing spaces
	return strTrim
end




--=========================================================================================
-- UI Manager --
--=========================================================================================

function createMainWindow(x, y, width, height, title)
	-- creates the main window

	window = disp:AddWindow({
		ID = 'VersionControl',
		WindowTitle = title,
		Geometry = {x, y, width, height},
	  
		ui:VGroup{
	    	ID = 'root',
    		ui:Tree{
    			ID = 'tree',
    			SortingEnabled = true,
    		},
	   	},
	})
	return window
end


function createVersionWindow(x, y, width, height, title)
	-- Creates the Choose Versions window

	window = disp:AddWindow({
		ID = 'Versions',
		WindowTitle = title,
		Geometry = {x, y, width, height},

		ui:VGroup{
			ID = 'root',
			ui:ComboBox{
				ID = 'VersionList',
				Text = '',
			},
		},			
	})
	return window
end


function createRenameWindow(x, y, width, height, title, oldName)
	-- Creates the Rename Loader window

	window = disp:AddWindow({
		ID = 'Rename',
		WindowTitle = title,
		Geometry = {x, y, width, height,},

		ui:VGroup{
			ID = 'root',
			ui:LineEdit{
				ID = 'newName',
				Text = oldName,
				Events = {ReturnPressed = true,}
			},
		},
	})
	return window
end

--------------- Tree Creation functions ----------------------
function configureTree(tree, columns, widths)
	-- configures given tree with given data
	tree.ColumnCount = table.getn(columns)

	-- create column headers
	local header = tree:NewItem()
	for i, column in ipairs(columns) do
		header.Text[i] = column
		tree.ColumnWidth[i] = widths[i]
	end

	tree:SetHeaderItem(header)
end

function setTreeItemValue(item, index, value, allowCheckbox)
	-- set the value of a tree item

	if type(value) == "boolean" and allowCheckbox then
		item.Text[index] = ''
		if value then
			item.CheckState[index] = "Checked"
		else
			item.CheckState[index] = "Unchecked"
		end
	elseif type(value) == 'table' then
		item.BackgroundColor[4] = value
	else
		item.Text[index] = value
	end
end

function createTreeItem(tree, data, allowCheckbox)
	-- creates a tree item
	local item = tree:NewItem()
	for i, value in ipairs(data) do
		setTreeItemValue(item, i, value, allowCheckbox)
	end
	return item
end

function addTreeTopLevelItem(tree, data)
	-- creates a tree item parented to the tree
	local item = createTreeItem(tree, data, false)
	tree:AddTopLevelItem(item)
	return item
end

function addTreeLevelItem(tree, data, parent)
	-- creates a tree item parented to the given parent item
	local item = createTreeItem(tree, data, true)
	for i=1, 6 do
		item.TextColor[i] = {R = 0.21, G = 0.6, B = 0.7, A = 1}
	end
	item.TextColor[2] =  {R = 0.21, G = 0.6, B = 0.6, A = 0.6}
	if data[6] == true then
		item.TextColor[1] = {R = 0.4, G = 0.8, B = 0.4, A = 0.6}
	end
	parent:AddChild(item)
	return item
end


function populateLoaderTree(loaderSets)
	local list = {}
	for i, set in ipairs(loaderSets) do
		list[i] = addTreeTopLevelItem(mainWindowItems.tree, { set.layer, set.version, false, set.path, set.res, set.colors })
		for j, child in ipairs(set.children) do
			addTreeLevelItem(mainWindowItems.tree, { child.pass, child.version, child.locked, child.path, child.colors, child.passthrough }, list[i])
		end
	end
	return list
end


---------------------- Progress Window Functions -----------------------

-- Progress Window Creation
function ProgressWinCreate()
	local x = _fusion:GetMousePos()[1]
	local y = _fusion:GetMousePos()[2]
	local width = 562
	local height = 268

	local win = disp:AddWindow({
			ID = "MsgWin",
			WindowTitle = "",
			Target = "MsgWin",
			Geometry = {x, y, width, height},

			ui:VGroup{
				ui:Label{
					ID = "Title",
					Text = "",
					Alignment = {
						AlignHCenter = true,
						AlignVCenter = true,
					},
					Font = ui:Font{
						PixelSize = 14,
					},
					WordWrap = true,
					Weight = 0.3,
				},


				ui:TextEdit{
					ID = "ProgressHTML",
					ReadOnly = true,
				},
			},

		})

	itm = win:GetItems()

	win:Show()

	return win, itm
end

-- Progress Window Refresh
function ProgressWinUpdate(win, itm, title, progressLevel, progressMax)
	--Update the window title
	itm.MsgWin.WindowTitle = tostring(title)

	-- Update the heading text
	itm.Title.Text = title .. "\nProcessing Loader "..tostring(progressLevel) .. " of ".. tostring(progressMax)

	-- Add the webpage header text
	html = "<html>\n"
	html = html.."\t<head>\n"
	html = html.."\t\t<style>\n"
	html = html.."\t\t</style>\n"
	html = html .."\t</head>\n"
	html = html .."\t<body>\n"
	html = html .."\t<div>\n"
	html = html .."\t<div style=\"float:right;\">\n"
	html = html .. museLogo()
	html = html .. "\t</div>\n"
	html = html .. "\t\t<div>"
	html = html .. "\t\t\t<div style=\"float:right;width:46px;\">\n"

	-- progressScale is a multiplier to adjust the number of bar elements rendered per step.
	progressScale = 59/progressMax

	-- Scale the progress values to better fill the window size
	progressLevelScaled = progressLevel * progressScale - 1
	progressMaxScaled = progressMax * progressScale

	--Update the activity monitor view = turn the images into HTML <img> tags
	for img = 1, progressLevelScaled do
		-- These images are the progressbar "ON" cells
		html = html .. ProgressbarCellON()
	end

	for img = progressLevelScaled + 1, progressMaxScaled do
		-- These images are the progressbar "OFF" cells
		html = html .. ProgressbarCellOFF()
	end

	html = html .. "\t\t\t</div>\n"
	html = html .. "\t\t</div>\n"
	html = html .. "\t</body>\n"
	html = html .. "</html>"

	-- Refresh the progress bar
	itm.ProgressHTML.HTML = html
end

-- Progressbar ON cell encoded as Base64 content
function ProgressbarCellON()
	return [[<img src='data:image/png;base64,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'/>]]
end

function ProgressbarCellOFF()
	return [[<img src='data:image/png;base64,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'/>]]
end

function museLogo()
	return [[<img src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAg4AAAByEAYAAABrVIXpAAAAAXNSR0IDN8dNUwAAIABJREFUeJzsvX14FPW5//+afc4DZAMIASOZWNBAURKMGCzKoKgBsQZL27XFMlTbk1Yum/Rw9aS9OMfhXLYnelRWL48nx1IZWx+iVVmU2vhQGShHQ8uRBVEWRDKgmAARNiGQTbLZ+f3xndnJD7U+ZJEH5/VPrjzNzO7OfD735/153/ctfF38uvh10TBwcHBwcHBwcHBwcHBwcHBwyBCuk30BDg4ODg4ODg4ODg4ODg4OZx6O4ODg4ODg4ODg4ODg4ODg4JBxHMHBwcHBwcHBwcHBwcHBwcEh43hO9gWcMOLEiYMRNaJGFKikkkowSo1SoxTQ0NCAIEGCGTxvggSJDB7vRPFFrzNAgAD2+2Z9bx3v+N9bP2+jjbaPOb+IiAioqKggxISYEAMhJISEEJn/fM4wjJgRM2JgxI24ESd9n1vvmxAVokIUhLgQF+LY77eDwymI0WQ0GU32fY2CgkL6vhUQEABBEzRBwxkfPglrfLXmwbARNsJgiIZoiEANNdTw0XE70+c/1fmi12ndd8fff9bxjp8fzc8h/fX484YIEbLHaxpppBGEEqFEKCHzn4+DA3x0nDDH33S8XG1UG9Wk78c0n3TfW/e3FWfUU089CM1Cs9BMetwRREEUxI85joODwxnL6Ss4mAOc0Wg0Go1gBIyAEQDqqKMOXJJLckngi/qivigEmgPNgWbwB/1BfxCGycPkYTLkkUceAxZk1oCpo6MP+N7ieCHD+jsL6/soUaIfc92fdlzN0Azt8//fR67DwrqO4//P/Pv06/ik437C/33kfNb1R4yIEQGjwCgwCoASSigBt+7W3ToIYSEshKFH7BF7RNiv7Ff2K5CoSlQlqqAn1hPriUFPc09zTzP0x/pj/THSAZfQJrQJbSDUCXVCHV+9Cct6n0uMEqME3IpbcSuQV51XnVcNhXqhXqiDEBSCQhDea3yv8b1GiFfHq+PVkEqkEqkECAkhIQwMjB0cTgJpYcEcJ7yqV/WqMCwwLDAsAGOUMcoYBXr0Hr1Hh/fV99X3VeiMdcY6Y6THe6FJaBKa+OotzKxxPGSEjBAYQSNoBIFqqqkGj+pRPao971lfs9uy27LbYKQ8Uh4pg0/zaT4Nezywxn1r/jhunDB0Qzd0Pnl+Of7nnzSPfML/pY9v8VnnueP//pP+77jX95HzHX+dn3Qdx12/UWPUGDW2wGNtbAgVQoVQAW7RLbpFWyA+rBxWDitwmMMcBnr1Xr1Xh0RjojHRCH16n96n28cVIkJEiNjXbR3XweH/hxUfW/GdjIwMRqVRaVQCDTTQAIIqqIIK7oQ74U6AN+qNeqPgi/livhh4Q96QNwS+al+1rxpGRkZGRkbAH/aH/WEQZEEWZDAwMICOcEe4IwyHSg+VHiqFZDgZToahT+6T+2Toaexp7GmEZCwZS8YgFUqFUiGgggoqQGgUGoVGIEKECAiVQqVQyVdvXHdwOAMRTpcuFemBs4ACCoAwYcKQrWar2SqMDI0MjQzBueFzw+eGYdzt424fdzuMlcZKYyUoEAvEAhGGakO1oRoMlYZKQyXIlrKlbAl7J83ikwKbT/v9Jy3IP+P/f+bAJ1O//6I//6TrN3fQDMVQDIW00u3SXJpLA0EXdEGHPrFP7BOhQ+lQOhQ4Ih4Rj4hwkIMcBN6T3pPek+DdR9595N1H4N3Sd0vfLYUPAh8EPgjAkeYjzUeaoV/tV/tVEAqEAqFgwAR1pmEtLMyJfXRkdGR0BOb8bM7P5vwMpsvT5ekynCOeI54jkg4wdE3XdA3Wamu1tRq8fN/L9718HxzQD+gHdGenweHkkBZWzfF8fMH4gvEFMHfy3MlzJ8PF6sXqxSqMlkZLoyXoFXvFXhF26jv1nTq8WPti7Yu1sL5xfeP6Ruis7qzurB4gRJ5pAaq1gKg36o16e5z1NHmaPE0QjAVjwRgUUkghMC44LjguCOeuPHfluSuhUCqUCiUYLg2XhkuQSy65QJ6Wp+VptnD5ET7v/HD87z/n/3/i/Jep68n0/x33e0M1VEMd4CQxf285cly6S3fpYMiGbMhwVDuqHdWgU+vUOjWIq3E1rkKr0qq0Kvbhd+Xvyt+VD7qoi7oI7fH2eHscesI94Z4w9oLN2kl2xvOvBqZzNC10mRtv1oaDX/Nrfg3yonnRvCicJZ0lnSXBGMYwBhizcMzCMQthtD5aH63DCHWEOkKFYfowfZhux8cBLaAFNBiiD9GH6OBVvIpXASQkJNLxRrfULXVLcEQ6Ih2RoFvulrtlOKIeUY+ocFA9qB5UoU1pU9oUeK/jvY73OuAD8QPxAxFag63B1iAcjh2OHY5BojRRmii1xz1rYzAtTFjrAQcHh1OeU1ZwMJqNZqOZ9IDmrfRWeithjDxGHiPDRVzERcDUyVMnT50MJXqJXqLDSH2kPlKHbDFbzBbBo3k0jzZgYWVZvRxr+anB8YGbOXH1i/1iv2g79T7UPtQ+1GC3tFvaLcHfxb+Lfxdh48yNMzfOhJaqlqqWKuimm27sAE+oEWqEmpPz0jKJFcCeEz8nfk4cblt+2/LbloMkSZIkQbacLWfLpFNT0pjPT5fapXap8Kr0qvSqBPeX3V92fxm0RlojrZEBz4eDw4nEWjibTqgL2i5ou6ANavNq82rzoIwyygAfPnxgB7QmllBxWDusHdbgWf1Z/VkdVkxbMW3FNFuITKdcnK5Y75NpabacYUPEIeIQEc7XztfO16BicsXkislQJpaJZSKM1cZqYzUIqkE1qIJf8St+xXb8HZ+i4nCKYM1/piPCEuz7pD6pT4IuuugCWrVWrVWDbdI2aZsErz/y+iOvPwJbg1uDW4NwsOJgxcEKSEVT0VTUdgQ6n/dpjuVstIQF08nkLnGXuEsgL5GXyEuAWCVWiVVQ0lLSUtICE5WJykQFiuViuViGkdJIaaQEQ9Wh6lAV/JJf8kt2nOxSXapL5aPjxOe9f44X6sy4xBIUrfiuV+vVejXokrqkLgkOSAekAxK0aC1aiwZvS29Lb0vw9rq31729Dlr0Fr1Fh3hzvDneDMmaZE2yZoDz1RwnHcHNweHU49QRHMwBKhVPxVNx8AV8AV8Azms8r/G8RphlzDJmGfAN+RvyN2QQFVERFcjWsrVszbaGORPrGY75+Sb0hJ7QoVVv1Vt12ChuFDeK8JLwkvCSAFvbtrZtbYPuku6S7hJsC6okSIJ0Eq//c2ItzAKlgdJAKSy+ffHti2+H7+nf07+ng1/1q371sx/vGMc4BqiSKqkSPPTIQ4889Aj0xfpifTEQqoVqofrEvBYHB8vSO6x5WPOwZli6fOnypcthljpLnaWCW3WrbvUzHMhcmB1SD6mHVLhnyz1b7tkCq6tWV62uAqPOqDPqBuTAnyZYO3nW6xtWMaxiWAVcIl0iXSLBVWuvWnvVWpisTlYnqzBcHa4OV+1UlI849RzOLKw4SU7JKRk66aQT2KHt0HZotqCsLdOWacvgA+UD5QMFUgWpglTBACHuTHMAnWGkN9zMHXwrlSbYHGwONsP4xPjE+ARcdP1F1190PUyRp8hTZChWi9ViFfLJJx9bcDxt4mPLyWkKy71Sr9QrQVyP63EdWsQWsUWEzcpmZbMCfxf+LvxdgJ2JnYmdCYhXxivjlZCqSlWlqkAICAEhcPrNAw4OZyInXXBIB4amVeqc2Dmxc2Jw7dpr1167Fiq1Sq1Sg7GMZSwDck3NnXCHrzjmBNWv9Cv9CuxnP/uBddI6aZ0Eq/es3rN6D2xv3N64vRGSwWQwGbRTO071wCulptSUCuOV8cp4Be5tubfl3hb4mvo19WsqH9kB/lTMhUxMjIkxEWrn1c6rnQct0ZZoSxTcze5md/OAop0ODhkkJaWklASXiZeJl4nwm7W/WfubtTBcG64N1z7/8awds/XqenW9Cv+y+l9W/8tq6Ah0BDoCA1K5TtWA87hUqSw5S86SoVwtV8tVuMG4wbjBsFNMgkpQCSoDxi8HB0gvJI8px5RjCmyXtkvbJXg+//n85/Ph1ZpXa16tgQ+jH0Y/HFiU8kxNQTzNSBfLNcczX4OvwdcAY6vGVo2tgkvWXrL2krUwXZ2uTlfTJW/Stci8ePHCRx2OZxpm3G/VhLBqoFj3uzUPNM9rntc8D/bp+/R9OvRpfVqfBsSIEXNqnzg4nAy+fMHBsoaZlrCsWFYsKwaX119ef3k93GjcaNxowAX6BfoFOgSkgBSQcAQGh8+GGcAnlaSSVGC3ulvdrcIz4jPiMyK8MO2FaS9Mg0OJQ4lDCT5aDfwUo1/ul/tlkDRJkzSov73+9vrbIU/Kk/KkL37cw9Jh6bAEPxd+LvxcgL9U/qXyL5WQXZNdk10DnqAn6Ani5Eg6ZAYzRSAlpsSUCDf9003/dNM/wT/zz/wz4JN9sk/+4offzW52A9VbqrdUb4Gds3bO2jkLsnOzc7NzwZVwJVwnohvDF8RoMBqMBrvmxDnqOeo5Knx71bdXfXsVzNZn67N1GCWOEkeJ4FJciks5udfscBphChCdSqfSqcBr2mvaaxo8tuixRY8tgq2RrZGtEUgWJAuSBQOs6KfI83GmY+3gWzUXAjWBmkANjGsa1zSuCWatmrVq1iq4XLxcvFyEIqVIKVIgoAbUgGp363H4f1hCTbfarXaroOu6ruuwXl+vr9fhlZmvzHxlJrwbfjf8bhh66aUX7BorpUKpUHoSX4CDw1eAL69LhbWTYw4Mo0pHlY4qhVBrqDXUCtfPuH7G9TNgpDZSG6kNsIA5OHwezEDLqs5+nnyefJ4Mtyq3KrcqMFGaKE2U4Pe1v6/9fS3EmmJNsSa728kpt7NvVpP2tnnbvG3gnuGe4Z7B53c2HIdlXfcX+4v9xdBd113XXQfuuDvujtu5oenuLQ4OmcBMbfKpPtWnggsXLhi0oGwdz1PmKfOUwbHgseCxIHgWexZ7FoO/wF/gLxhQVPIkYeXmW9Xfy6Pl0fIo3Hz7zbfffDtM0afoU3TbCj3Y59zhK4oZbw1lKEOBq7iKq4BxK8etHLcSntCe0J7QYM2da+5ccycc0Y5oR7QBtT4c4SGzWPGv2Zbdev7HB8YHxgfg2oXXLrx2Icx4fcbrM16HQqVQKVQGFGc8050Lg8SqQZWtZCvZCkxUJ6oTVRinj9PH6XDlwisXXrkQXi16tejVInhx9YurX1wN70rvSu9KkEwkE0mne5eDwwnlhAsO6Vy0UkophfOi50XPi8KPl/94+Y+Xwwx5hjxDtgcKJwfVIaOYE/VQfag+VIc54hxxjgijD48+PPowPKg+qD6owuaCzQWbCyDZlGxKNp1CVtMT1M8+XcvCbD/V39zf3N8MPYU9hT2FdrxptctyAlCHjGLlEn9al4DPiKAIiqCAkC/kC/nQt6JvRd8KOwfYV+Or8dWcvJ1BK2XC2smcG5kbmRuBHxg/MH5gQLFULBVL4JJdsks+CRfocEbjlt2yW4Zx6jh1nAq3yrfKt8pw1vaztp+1HZ7Qn9Cf0KE92h5tjw7Y8XXG/S+GVfS1yqgyquzaGUV6kV6kw5y8OXlz8uAa7RrtGg1EVVRFdUAtFkdoHBymgG0VHx6vjlfHq1CkFqlFKlyuXK5crsDz6vPq8yq8qL2ovahBm96mt+nYNb/MecXBwWHwnDDBwRIarECrpKKkoqQCan9W+7Pan0GFVqFVaOCVvbJXPlFX4eBgYi5wrFzHcr1cL9ehTq1T61R4aNlDyx5aBmur1latrYLept6m3lNJeDjBGPON+cZ86K/qr+qvgpQn5Ul5bMeDk1rhcFpgpeyZTjrLMm6lMKR3rr6khZQ1//nr/HX+Oph3zbxr5l0DP5J+JP1IslMmrNoqDg4nFKsYqTZMG6bBAn2BvkCHs/Sz9LN0+G31b6t/Ww3vJ95PvD9Q6HaEh8+EETNiRox0kYXctty23DaYXje9bnodhIpCRaEiuEC7QLtAs9tNOhttJxhLgDBT9ybIE+QJMoyVx8pjZZiWNy1vWh48FX8q/lQcmpuam5qb7CLb6Zo5p3rRTQeHUxhXxo9o9gW2FN6SxpLGkkZbaJgmT5OnyeAVvaJXzPjZHRw+E1Y/9PPl8+XzZbh1xq0zbp0Blzdf3nx5M7jqXHWuOjvV4ozHWqiZlk+rm8CJclg4OJxQzKIORq6Ra+TaqQxfFtb5AhWBikAFfOv1b73+rdfhR/yIHwGj5FHyKBlHaHA4OZg76LlSrpQrwRxpjjRHgurN1ZurN8Oo4KjgqCCkmlJNqSaceeBTsLrLCFEhKkRhfGR8ZHwEapfXLq9dDr9c+cuVv1xpb3QElIASUHBqk50sTOdrjpQj5UgwXZwuThdh6cKlC5cuhFuvufWaW6+x2wxbQpIRNsJG+OReuoPD6UrmHA6Whczc0SmOF8eL43Dbz2772W0DhAYrt/5Lx7LumkqyVf3fUizTAamVK2dNBMdb28y/t3LGHMXzC2J+Dpa1/2QpyJbV8VzpXOlcCW7hFm4B2sV2sV2EaCKaiCaw758z/fPexS52AUmSJE/2xTg4fEFSpEiBETWiRhRYylKWnvjTWk4Ky7k3t3lu89xmuGXhLQtvWQijlFHKKIWTl5NtChzWPJ0uXicbsiHz0Z1Wax48btxLp2Sd6ePhicKKI8x5L/1+fsL7faKvI4sssoCr9Kv0q3RoV9vVdhVWVK+oXlENR0qPlB4pBSEmxITYl3BdpzpWvGsK9P6IP+KPwGWVl1VeVgkL1y5cu3AtTFInqZNUu8bMKf+8WHHOcfGyIRqiIdpfrfHLGj/S96/5cyt1LR3XWXH0Kfr6rescpY3SRmlwo3qjeqMK52nnaedp8Hvh98LvBdhYsbFiYwX0FvQW9BacPt3OHBxOBTImOBgVRoVRAflavpavwU2Hbzp802GYxjSm8SUKDeYAabXB6dA79A4dWrVWrVWDfdo+bZ8GHyofKh8qkFATakKFPqVP6VOgX+wX+0Vwa27Nrdlfjz9+ut3a8cUtrQHVycH7h3hEj+gRIV/NV/NVGCOPkcfIMFofrY/WYZg+TB+mg1/0i35xgMBzgrCEh4naRG2iBrdqt2q3avBr8dfir0VoCbeEW8IDqsWfqUWFLKHB2dFyOBP4soQzq9q5OR+UN5U3lTfBD1p+0PKDFhjFKEbBiRcazOuwuoF0y91ytwztUrvULtlt4lqlVqlVgiPSEemIZM9/6fZxJh48eBhQ+8JaKJvjZXo8PH4hcYovME421vtn1a4aKY4UR4owRhwjjhFhlDpKHaXCEHWIOkQFt+JW3AonLq4wP6ccLUfL0WC+Pl+fr8Oh8w+df+h8eHz/4/sf3w991X3VfdUgNAgNQsMJuI5THdPBazk/hjOc4cANRTcU3VAE31W+q3xXgdGMZjQffW5OOqag1a/36/06JKSElJCgS+1Su1S7zWRcjItxEQ5xiENAp9wpd8p2vGy1IbeOY8XJXt2re3XIUXPUHNVO3RkuD5eHy5Av58v5MuTpeXqeDllSlpQlDRhnTnbqgvl8+SW/5JegQq/QK3QopJBC4HHtce1xDVYHVwdXB6FT7BQ7RdvZ4qSeOjh8MoMWHCzLuafAU+ApgOsWXrfwuoUwW5mtzFbAr/pVv8oJG0CsXN2j0lHpqAQ72clOYIO4QdwgwsaOjR0bO2DX/l37d+2H9o3tG9s3Qk99T31PPaTWpdal1oGxz9hn7APjAuMC4wI7IKCJJppIK5hCoVAoFAJ3cAd3AGWUUTbggnLJJRfYz372Z/71nvaYM4vQIXQIHeCb6Zvpmwn5s/Nn58+GsQ1jG8Y22H3oL5Mvky+T4QLxAvECEYJ6UA/q4BJdokvM/OW5JbfkluAi6SLpIgkWaAu0BRrc13xf833N0BnrjHXGwFXhqnA5fZwdHBywHQNFjUWNRY1w8/k3n3/z+VAsFovFIicudcJqA2zqKta084b6hvqGCutr19eur4U3a96sebMG3m94v+H9Bjgy/cj0I9MhWZosTZZC6tHUo6lHwVhjrDHW2IcXgkJQCPKRhW66m49lCbN2+KyVg1Usx5kHP56buImbwH3UfdR9FHI25mzM2QhnzTtr3lnzYMK8CfMmzINvKN9QvqHANH2aPk232yP68eOHzOf+m59zUAtqQQ1CWkgLabC7bHfZ7jL4q/JX5a+KHXcJFUKF8BWYBy1LvbWTX6gX6oU6LFq4aOGihTBXnavOVWGINEQaInHyUiWsbhiSIRkSdEvdUrcE7Xq73q5Di9aitWgQ02JaTIMdM3fM3DET9LAe1sPQtq5tXds6ODL7yOwjs+HojUdvPHoj9P2679d9v4ZUW6ot1QbGOcY5xjlgFBvFRjEIjwmPCY+BMF2YLkwH91Xuq9xXQda8rHlZ82Bo1dCqoVUwomNEx4gOKJKKpCIJSrQSrUSDieJEcaJoFzW1attkyVlylmynwH7ZQoQVZ45VxipjFajWqrVqDcYylrHAw40PNz7cCK31rfWt9QOEuFNFYHJwOIX44oKDtQNaTz31MFmfrE/WYf6q+avmr4KhylBlqELmHzwzcEtoCS2hwZv6m/qbOkSKI8WRYvhL8C/BvwRhT/2e+j31kJiVmJWYBakxqTGpMdhWsQUsYAF236g66qgDYYwwRhiDHUBdyqVcOuD8IxnJSOB+7ud+0tbddGNf63uHz8RRjnIUOOw77Dvsg93tu9t3t8NrE16b8NoE+OOdf7zzj3fCN/Z8Y8839kCVUWVUGVAhVogV4oD7LMMBvV/3634drpGuka6RYNuWbVu2bYFIY6Qx0ghGjVFj1AzoX+7g4PCVw8rdzopkRbIi8K0nvvXEt56wdeh0289Mn9dcUByQDkgHJHhVe1V7VYPIosiiyCLY/JPNP9n8EziUPJQ8lITk1OTU5FQwuowuowt4gRd4AXueM+ct4TbhNuE2bOHcKvP+SS/kF/yCX2ArHukG9w6fhyMc4QjQtrVta9tWeGvkWyPfGglNNzbd2HQjlMwsmVkyE2avnL1y9kp7gWsJWh7JI3kkMhdvmUJGoVwoF8p2uLQrvCu8Kwz74vvi++IDigqfoY4/K2WAKqqoggmBCYEJAfhJy09aftIClyqXKpcqEJADckDmy19omsJGDz30AK200gpEtagW1WBj2cayjWWwhS1sAfYIe4Q9AhwuP1x+uBwSmxKbEpsg9VTqqdRTYNQZdUYddpw8hSlMwY6Ds8kmGxjBCEaAMFYYK4zFHice5EEeJD2edCY7k51J2O/a79rvgndi78TeiUHzLc23NN8CvhG+Eb4RkBfLi+XFoGhZ0bKiZVAWKYuURWyhrUwpU8oUGC2NlkZL4Nf8ml/jy0tNM58Ha8PrBvkG+QYZht8+/Pbht8PvhN8JvxPgbeVt5W0FjJARMkJfnaLjDg6fhS8sOFgPVJ6cJ+fJ8J3N39n8nc12e59MDwSWor5f3C/uFyEiRsSICI89+diTjz0JO6p2VO2ogt4VvSt6V4ARN+JGHFjDGtYMaPP0Nm/zNrjCrrArbCunrnZXu6sdhB8KPxR+iF1jYJYwS5iFLbDEiBEbELh10UUX9oLXyYH/Ypjvm7HUWGoshVRhqjBVCO9VvVf1XhU85XnK85QHXlvy2pLXlsC8wLzAvAB83/i+8X0DiimmGHDjxp2J6zEDh3zyyQe+ff23r//29bB5z+Y9m/fA7rbdbbvbwB11R90D24g5ODic+VjzgdlWtry+vL68HuYoc5Q5CgSkgBSQyLgFvlfpVXoViIpRMSrCw7UP1z5cC6/seGXHKzvgw8IPCz8shFRzqjnVjC0AmFZfYamwVFgKwhRhijAFXM2uZlfzgPmvU+gUOkFoEpqEJhBqhBqhxv5/3ud93sfeSU0aSSNJel5kAxvYQLoIrcNnxIoXzA2c1ILUgtQCOOo56jnqgU0PbHpg0wPw1h1v3fHWHaDN0+Zp82DR8kXLFy2HK9Ur1SvVATvsGXI+WDu8luPvOv06/TodVnSs6FjRYbdTdkkuySVxxuSyG01Gk9FEup37RHmiPFGG2utrr6+9HqbqU/WpOnhkj+yRv8TrUg3VUG2BKqbElJgCmqRJmgTrZq6buW4mxNbF1sXWQUdhR2FHISSHJocmh4LxgPGA8QD2/WYKCML9wv3C/SC4BJfgAuEV4RXhFRByhVwhF4QqoUqosh0trlJXqat0QKqr5eiYy1zmYj//j/Ioj4JRbpQb5WDcbdxt3A2pRCqRSkDfHX139N0BB/WD+kEdDrxx4I0Db8DmOZvnbJ4DzwSfCT4ThJJQSagkBJIqqZIKV6hXqFeocL5+vn6+Djlijpgjfgltj8240OoucqV8pXylDPkL8xfmL4Rwfjg/nA9bIlsiWyK2AzztCHNw+Arz+QUHayAxA6lLxUvFS0W4dPKlky+dnMEFn4lVpGa3tlvbrcF/Ff9X8X8VQ6QyUhmphEN3Hbrr0F1gjDRGGiNJS/HCXcJdwl3gynZlu7LB8yvPrzy/Am/Cm/AmwFvprfRWgqfGU+OpsSdMoUvoErqAbWxjG3ZKhRVgWsrvJjaxacDPra/ttNOOkwP/eTGFG6PEKDFKIBVLxVIxSC5NLk0uhWQoGUqGoDXeGm+NwwpphbRCgu1t29u2t8FiabG0WIJLtEu0SzTb0TtYrAlsgjZBm6DBddp12nUaPFD7QO0DtWAUGAVGwQDr8RkScDk4OHwyRpVRZVRBsCRYEiyBeUXziuYVDWhzmSmhwZxvurVurVuDl3iJl4D78u/Lvy8f3gy/GX4zDL31vfW99cABDnAAOI/zOA9cY11jXWPB7XF73B7wtnvbve3gPeY95j0GnkmeSZ5J4G5zt7nbwJXrynXlAg000AC8wiu8gr2DbXWhsuIAS2Cw5jvr59bfOXw2rPfPTElJlaZKU6XQL/VL/RIkk8lkMgl9T/c93fc0vN71etfrXaDfqd+p3wk7v7vzuzu/CwvVhepCFUbpo/RROhnb+LGs7ddK10rXSrB+2fpl65dm39oBAAAgAElEQVTBmw1vNrzZAN6wN+wNg1An1Al1gz/fySLtaDDbWn498fXE1xNQO7l2cu1kuFi6WLpYsjOHTvj1mBttR7Qj2hENolJUikrw3OrnVj+3GtYtW7ds3TJ476r3rnrvKkhMSUxJTAFjojHRmAg8zMM8TNqZazmYhAuFC4ULbeHAvca9xr0GPPWeek89uKvd1e5qcAfdQXcQ3EvcS9xL7FoFrlmuWa5ZA4qIWnGvJTweFw+ni05ON6Yb0yH1SuqV1CvQH+4P94ftWhD95f3l/eWQnJucm5wL8UQ8EU/A63e/fvfrd8MbvMEbwLPrnl337DqYJc4SZ4kwV5+rz9XtIp05eo6eo3PCuwBZteku0i7SLtLg55N/Pvnnk2F5eHl4eRii8Wg8GneEBwcH+AKCg9UuLz+WH8uPwZy8OXlz8uzif5ma4KyuEe+I74jviHDvsnuX3bsMntvw3IbnNsDRcUfHHR0H7GUve0G4QrhCuAJcQVfQFQTvLu8u7y4IxAKxQAz8Ff4KfwW4R7hHuEfYDgcrsErnIloLxkYa+TztEB2BISOknSlRokTBH/KH/CFIhVPhVBj65X65X4aeW3pu6bkF/jriryP+OgI6pA6pQ4JfKL9QfqHAdGW6Ml3JnPBg5cxaE9wL2gvaCxpsb9zeuL0R/M3+Zn8zCI1Co/BVaKPp4PBVxBrnm2mmGcrbytvK2+DizRdvvngzuFSX6lIzd7pupVvpVuA59Tn1ORWWL1q+aPki2LF0x9IdSyHVnmpPtZMWbK0FgOdBz4OeB8G/wr/CvwICoUAoEAKvx+vxesBV7ip3lQ/YEbQcfVYR5GqqqebzC6jOPJgRLEHLctBYC7bUptSm1CboS/Ql+hLw4YYPN3y4AX77y9/+8re/hK7GrsauRvjJ7T+5/Se3w2h5tDxaZvBxmbmDbeXeXy1eLV4twlviW+JbIvRX9lf2Vw7Y8T/diudZG0nmgnli3cS6iXVQu7Z2be1amKpMVaYq4Jbdsls+gddhpQybj9E2eZu8TYY/lv2x7I9l8NKNL9340o3wfv379e/XQ19bX1tfGxjNRrPRjO1YsBwJVwtXC1eDu8vd5e4Cz72eez33gm+6b7pvOnhinpgnBp4mT5OnCdwb3BvcG0CYJEwSJg0ohmg6b9KCohkfpzdawoT5R6ml5t8bbUab0UY6vmM+85lvF51P6Sk9pUMqlAqlQpAMJoPJIPSV95X3lUNvY29jbyPsDOwM7AxAS3lLeUs5vDzr5Vkvz4I5zGEOUCVVSVUSlMglcokMPtkn+2ROWNFVq/ZXmV6ml+lQu7J2Ze1KWF68vHh5MUQLogXRgo/p6uHg8BXiswsOx6UUlFeWV5ZXQplWppVpH9Ot4YtiDgh79b36Xh3uE+4T7hNg9ZOrn1z9JBzrPdZ7rBf4gA/4AIT1wnphPXjaPe2edshKZiWzkpAVzgpnhcFT4anwVNiB2EeEhRAhQjhFXk4RhBKhRCj56M/dVe4qd5VtAfZoHs2jQbI92Z5sh1goFoqF4J5l9yy7Z5mdanixfLF8sZyBIpNmwDVWH6uP1eFK7UrtSg22S9ul7ZJtLfXoHt2j49xPDg5nIFbNhiGlQ0qHlEJlXmVeZR4ExaAYFDN3Hit1wnI03Lvn3j337oGdk3ZO2jlpgNBg7sS6Aq6AKwD+pD/pT0L2a9mvZb8G/mp/tb8aXHWuOlcdCPVCvVCP7WCwsL4/3RaKZyjHF2O0hCFX3BV3xcFd565z14Ev4ov4IvZC7I+RP0b+GAHfQt9C30K4Vb1VvVWFfD1fz9cZ9LzkVbyKV4GZ4kxxpgirV69evXo1xOKxeCwO7gJ3gbvgS7C2ZwrTiWOlUExomNAwoWGAo0G7WLtYy7xz93hSSkpJKXYXmeeU55TnFHhy9JOjnxwNMT2mx3To8fR4ejykhSirBlna0VviKnGVgDflTXlT4Av6gr4g+Cp9lb5K8I7zjvOOGzAemHH7R1KnrONbmDXOPsLnHC8+qcho2jlhbgRaRTq99d56bz0EooFoIGpvOPUV9BX0FUCP1qP1aLC7dHfp7lJoKG8obyiH9fPWz1s/D0JiSAyJcK1+rX6tDgVigVggDuiGkWHcolt0iwOEh5baltoWWD5v+bzl82BL5ZbKLZV8ddqsOzgM4DMLDkbEiBgRyIpmRbOiIK2V1kpr7RoOg8Z8AONqXI2r8PCihxc9vAgikUgkEoFjXce6jg2omeC63HW563LwLfYt9i2GHCVHyVHAX+ov9ZeCq8pV5ar6mKItjuX99MTqEmIqw1ZA423yNnmb7IF+Z/XO6p3VsIIVrAAKpAKpQLKrew+2erTVdUXSJV3S4emyp8ueLoN9yj5lnwLuRneju/E0CrgcHBw+M0bCSBgJO3e4bHnZ8rLldpvkQR/fLAa5Wd+sb9YhvCy8LLwMdiZ2JnYmIDU9NT01HYQ5whxhDrjHuMe4x0DW4qzFWYshO5AdyA7Y46KQEBJCAnuH2xEUTm/M1BarGr5VtDEQDAQDQUiKSTEpQmRCZEJkAhRrxVqxBvPF+eJ8cUB3iy+KuSFkVem//PrLr7/8elt4T6pJNakO2Oj5hA2Ek465gWZ1lxnVNqptVBvckndL3i15MFWbqk3VTmDqhOVk0BN6QoeNbGQj8Luy35X9rgzW/eu6f133r9CxpGNJxxIwCo1Co5B0DTJLOHQtcS1xLQFfqa/UVwqB+kB9oB58IV/IF7It/9bnIASEgPBxDt5TZeFrxXnH1cRKC25NriZXk+2k8S/1L/UvtTeerLadb8bejL0Zg5bKlsqWSvh7yd9L/l4CP1R/qP5QhTKxTCwTwaf5NJ9Gxl9/WngwN2RvW3XbqttWwV1ld5XdVQbbo9uj26MDup0547LDV4DPXEDbskIVVhZWFlbCheqF6oVq5toTWsqlVfzmaflp+WkZjp579Nyj55LOBXPNcc1xzbEXfkMYwhAgUB2oDlTbuWdOddivBtbn7A65Q+4QeAKegCcAG8MbwxvD8Iz8jPyMDMe0Y9oxLQMnNK3HxUqxUqxAaU1pTWkN9Kl9ap8K/Yn+RH8CJ4fZweFMwnyerUBy6qqpq6auguHScGm4lIHjm4L7AfWAekCFlY+sfGTlI7CtcVvjtkZIxVPxVNwWXN33u+933w85pTmlOaWQG82N5kbBW+It8ZYMEDzP0O4BDiaWAGGl0pgLTKtN+OO1j9c+XgtvSW9Jb0l2TYDBEhADYkCES7VLtUs1yAvlhfJC0BvuDfeGOeUXUFatKKs7wqKiRUWLimCGNkObodkOyoxjCjaHOMQh4DHtMe0xDX617FfLfrUM/iT9SfqTBPFfxX8V/5WdSpMWGK92X+2+GvxL/Ev8S2DogqELhi6AvMa8xrxGyI5kR7Ij4K3z1nnr7OYygiIogsIp/7l8KqYwYLWtdze5m9xNtnAwpGRIyZASGBoZGhkagd5Yb6w3Bmsq1lSsqYBf5v8y/5f58JT4lPiUCIf1w/phncy3lzWxUi2maFO0KRosmrxo8qLJUBAsCBYE7c/XSUVz+Crw6YKD+SBYivqF2oXahRoU6AV6gc7glUFT6bWsZI/veXzP43ugNdwabg3bVjfhDeEN4Q3wPep71Pco5CZzk7lJ8Df6G/2NA5RCJ8D6amJ+7pazJSkn5aQMLxS/UPxCMWzTt+nbdHtHY7DkirlirghTV05dOXUleHWv7tWht7q3urcaDNmQDTkDJ3JwcDjpWM9zUA2qQRWmyFPkKbL93A8Wq2j8q7zKq8Bfqv5S9Zcq6H2o96Heh0hvKbvWuNa41kB2ZXZldiVkL85enL3Yttg7Rcm+2li5+9ZO8J62PW172mDVolWLVi2CI+IR8YiYgROZAtl5ynnKeQqMbxjfML4Beup66nrqoD/UH+oPccp1KzEajAajAXxRX9QXhesWXrfwuoV2940sLUvL0k7Aec3uErqqq7oK96++f/X9q+Gujrs67uqAtza9temtTZBMJBPJBOk2k5YzwftT70+9P4VcT64n1wN5K/JW5K2A7Prs+ux6uwaDK+QKuUIfkzp8pmI5ImRBFmQ7tcxyeOQW5BbkFkBWW1ZbVhvs1HZqOzWoz6rPqs+CB7UHtQc12CvvlffKJy5u80peySvBldKV0pUSyIZsyAbkqrlqrpq5uNTB4VTmUwUHqxiNv95f76+H0pbSltIWyJKypCxp8BdgWQDX6mv1tTr8Tfqb9DcJ+tV+tV8FYb4wX5gP3r95/+b9G+Tk5uTm5IJP8kk+aYBl9EwfWB0+G+Z9YE28bYm2RFsC/qz8WfmzAsekY9IxafCncWtuza3BJH2SPkmHEU0jmkY0Qc/8nvk989NtqB3l2sHhDMAIGkEjCEWJokRRwraqD7oYn7lw26/v1/frsGrLqi2rtkB7uD3cHsZ29v3G9RvXbyBrRdaKrBWQncxOZiftKvJOETKHgVj3g7WDuiG6IbohajffypSFPF/MF/NFuHDVhasuXGU7B/oCfYG+gF38+6RjOQ7N+fji8MXhi8PwPfl78vdkCGpBLaiRcWu9VQRxl7pL3aXCXbV31d5VCys2rNiwYgPs37V/1/5ddnvZtIOp3l3vroes9qz2rHYYOm7ouKHjIGdNzpqcNQMcDFYtBqct9//DEiBM4dVd6i51l4Jf8kt+CXJjubHcGBzlKEcBdZ26Tl0H/7H6P1b/x2rYoexQdij255ZprHXTXG2uNleDudvnbp+7HdwRd8QdAaPOqDNO4y4vDg7/iE93OJjVqoN6UA/q8DXla8rXlMwVibSsZS/PfHnmyzOhY37H/I75pJPnXN9zfc/1PchakLUgawH4Rb/oF+3iOI7Q4PCxmNZBawB/fd7r816fBy16i96iM/h2SaY18mzlbOVsBcZGxkbGRqBvRN+IvhF2G8909WgHB4fTFqv7zDhpnDROgjwlT8lTBn9cq2bDG9Ib0hsSbG7b3La5DVKTUpNSk+w2g76nfU/7nobsRHYiOwGeiCfiiTipgw7/GCvV4mDpwdKDpaDJmqzJ0K1369364I9vbsQzUZwoThQhEAgEAgHoDfQGegP2zv7JxggYASMAZ0tnS2dLcNOMm2bcNAPO4RzOgYx1V7NIaSktpUFMi2kxDe7cc+eeO/fAqvmr5q+aD0eePvL0kaft90d4WHhYeBg8SzxLPEsgd0XuitwVMDQ0NDQ0BIFIIBKIgLvSXemudJ77z4wlQJjrFU+Dp8HTAFnVWdVZ1aQF35diL8VeisF/zvzPmf85E97S39Lf0iElpsSUmMHrMQWtYdowbZgG31e+r3xfgfKG8obyBrvNuhM3OpyJfLrDwVSsR0ojpZESjFRHqiNVBt9exize9478jvyODFtDW0NbQ5C6OnV16moQHhIeEh4CX4mvxFcCWXOz5mbNBVfClXAlcFInHD4b5oTSFmoLtYXgDf0N/Q0d+umnPwOHHyIPkYfI9o6n1dbTEhwGW6TSwcHhJGLujFrdZ4qvL76++Hp7x2ywdNNNN/C/W/53y/9ugcNrDq85vAbbqfVT109dP4XAtsC2wDbbmpvOyXZw+EeYcVKqJFWSKoH/W/Z/y/5vmV0rZLBY92GRXqQX6Xa3lr7mvua+Zuiv66/rr+Ok1TQywkbYCEOgIlARqIBv/+zbP/v2z+Bi5WLlYgVcskt2yZk7n+VstHbK71l0z6J7FsGaR9c8uuZROFZxrOJYBelUE6FT6BQ6wZfty/Zlw5BdQ3YN2QU5dTl1OXUDij5a7SmdDbbBYS74XdWualc1+Kp91b5q8NR56jx1sL55ffP6Zrin456OezpsR1DGhQdT4BIlURIlWFi0sGhhEYyOj46PjkMqmAqmgpxyKUkODoPh0wUH05I3omZEzYgayBFzxBxx8Ce2cuyjalSNqnDwlYOvHHwF6KWX3gGBlll92R11R93RT26r4+DwcVhWw96S3pLeEthavLV4a7Hd336w+ESf6BOhaGXRyqKVdluwPk+fp88DqXAqnArjpFY4OJyGWH3TLcHB6nqTqWLJB7WD2kENotFoNBqFZGeyM9k5wNlQ76v31UNgUmBSYNKAGg3OwsPhc2Clnu6r2FexrwJ2K7uV3QqD3zgy//8s+Sz5LBlG1I+oH1EPyUnJSclJkKxMViYr7S5nXxrWQs3ccCivL68vr4c54hxxjggBOSAH5Mydzhondsu75d0y3Ft2b9m9ZfCn5J+Sf0pC95juMd1jSBdrcS1wLXAtgMB3At8JfMdus5slZolZIrjD7rA77DgZThiW88GsTWd1I/GEPWFPGJrrm+ub62H5suXLli+Dt+W35bflAamyGcKlulSXClPVqepUFW64/Ybbb7gdfGFf2BcekNrhxI8OZwCfLDhYirRZvbWgqKCooAj8ul/364M/cUJKSAkJds7cOXPnTOiJ98R74gNqNjR6G72N9oJOCApBwXE0OHxRzADESqmIS3EpLg3+sG7VrbpVOEs/Sz9LB6/qVb0qJLuSXckuu7q8o1Q7OJyGNNBAA+RquVquZi+sBl3V3NzhapVapVYJ9sX3xffFwbjfuN+4307h8G/yb/JvArfiVtyKI7g7fDGEaqFaqLa7V+ySdkm7JOiX+qV+afDHz5FypBwJ8oP5wfwgpEpTpalS6B/RP6J/BBAixJdYzNQoNUqNUjir5KySs0rgu4e/e/i7h2G0OFocLTJ4ocXCHAfe533eB8L54fxwPqyR18hrZOje2723ey/2Rtrdrrtdd0OgK9AV6ILcTbmbcjfZXdasBehp303iNCNdO8MUeqyU7WaxWWwW4f5196+7fx28o76jvqNmvjZJlpqlZqlwnXaddp0GZc1lzWXN9nNkFTt1cDid+UTBwWqfZCm3VlEdt+yW3fLgT3xMPCYeE2GvslfZq0CqPdWeagdBFERBBN8G3wbfBvCEPCFPyCmK4zA4hIgQESLQUdpR2lEKHVqH1qFl4Lhm+7lhyjBlmGI7cqxAK1WXqkvVgREzYkZs8OdzcHD48jDqjXqjHvyaX/NrkKPkKDkKgy4uZzkH97GPfUDHLR23dNxCuhuFp9JT6akE7ybvJu8mZ/5zGCTmAjbVnGpONcN+9rMfSGpJLakN/vBWitHw0uGlw0uB6Uxnuu1kNRJGwvgydmhNR4PlQLriiSueuOIJuFi/WL9Yz2AKhXkea+PiUfVR9VEVntOe057T4FjwWPBYEOiiiy5wLXUtdS2FwK7ArsAuyC3JLcktAX/IH/KHBmyoOc6lk4v5nLgirogrAkKb0Ca0wYaSDSUbSuC/i/+7+L+LoVVtVVtVMtdO06oJJp4tni1CaHJocmgyBOuD9cF66C/tL+0vxWm37nBa8+kOB3Ng9ePHT+YG7ISW0BIaHFWPqkdVMB41HjUeBVfcFXfFwZv0Jr1Ju82Tg8OgMGspdFd2V3ZXwhH9iH5EJ31/f2HMhUdACSgBBTxtnjbPgKJv6RzWJppoGvzLcHBw+BIxHQ7WvOfFizcDh7WE/E61U+1UIbk0uTS5FIQfCz8WfgyeXE+uJ9cucuZYqx0ygVFlVBlVcHjR4UWHF0Gf1qf1aYM/rvV8ZMlZcpZsC2T94/rH9Y+DVFOqKdXECbeGpxKpRCoBZ9ecXXN2DcxV5ipzFRiiDFGGKJk7T6/Wq/Vq8ILygvKCAn948g9P/uFJ6CzsLOwsJN1dRhghjBBGgH+6f7p/OuS25bbltoEv7ov74iDogi7oOELDqYbVZt2s9UAFFVTAusp1lesq4XHpcelxCTrkDrlDZvBxpIkbN25gmjZNm6bBFaErQleE7FoklmDopFg4nI58epcKy9plVfXPUNuglJySU/IA5W4MYxgDrvmu+a754A65Q+4QUEMNNYM/n8NXnFJKKYVEQaIgUQBHtCPaEY3Bd6swnwfL8uyKuWKumO1oSOfgNdJI4+BfhoODw5eIVdzNFL4z1Z3JSqmwLO1GjVFj1ICwRlgjrAF3o7vR3QiuZlezqxmnSLJDRjAwMICOYEewIwhJJakklcEfV5AFWZDtnXojakSNqJ1SaAlsJ2yhZC743Al3wp2AK6+/8vorr4cJygRlgkLGFoSWlX6rtlXbqsHvOn7X8bsOaJ3bOrd1Lhj/Zvyb8W8gvCC8ILwA/in+Kf4pkKvmqrkq+BK+hC/hCA2nDZbwUOOqcdVAT01PTU8NPNvzbM+zPfCy8rLysgK9Yq/YK2butEO1odpQDarWVq2tWgtj1DHqGBWSsWQsGQOjyWgynA0sh9OMTxccThD9Sr/Sr0B/qD/UHwKhRCgRSsBV6ip1lYIr6Aq6gvbPHRwygZULZ7WtylQgku5GUUIJJWAsMBYYCyAlpaSUZCvUDg4OpxHmgsBKMczYeGFaaF2SS3JJdg6xVRbdHXPH3LEBCxMHh0xg1lJIRBPRRDRzDoekmlSTKhwrPVZ6rBSMQqPQKLTnW0twMNqMNuMEWMKtdoKFYqFYKMLV0tXS1RJkkUVWJk5gPvcHpYPSQQnUZeoydRm8uevNXW/ugtSS1JLUEruoq/dB74PeByEnmBPMCYKvwdfga7CLdzpCw2mGJTyEXWFXGOIl8ZJ4Cfxh9R9W/2E1vCW/Jb8lZ64NrJWq+3Xp69LXJbhy85Wbr9wMRqVRaVQOKF7pOB0cTiNOmuCQ7ntsWlYZxzjG2dV7hbgQF+I4A7PD6YGVy2c5JjawgQ2krXhEiRI9mRfo4ODwuamiiip7ZzNjO8JmQJmtZqvZKrjnu+e759tV063A9ssutudwZuMKuUKuELQpbUqbAvv0ffo+nS/evtmc7w7IB+QDMuzSdmm7NDC+aXzT+CYYi43FxmIw6ow6o47ML5BMB5Ir4Aq4AjB98/TN0zfDeMYzHuw4c5D0qX1qnwovyS/JL8nwYuWLlS9WQs/unt09u0k7dN173XvdeyFbzBazRfBH/BF/xBYWnXj2NMd0fFtFWN+tfrf63Wp4/L7H73v8PvhQ/1D/UCdjwrRVjHU2s5kNjGka0zSmyW47m+nilQ4OJ5KTJzgcj2l5t3Z4hBqhRnBSKRxOV8xAKO1syNTOqIODw5eG1Z6yr7SvtK8UEnJCTsgM+nm2iiOPlkZLoyXI3Za7LXcb9sLPWihlKIXRwQGAGDFicKD5QPOBZnhJekl6SfoCNY3MvzvGMY4BTVKT1CTBjrt33L3jbjCeMp4ynsKuBXaCBHdrx3eYNEwaJsFMbaY2U4NsLVvL1jJwAnMjYbe6W92twuOrH1/9+Gpon9Q+qX0SsJe97AXXN13fdH0TAoFAIBCALD1Lz9LBVeAqcBXgdJ04w7C6BVnFUNfXr69fXw+vKq8qryqZE6YtQe988XzxfBEuq76s+rJq6I/3x/vjkIqkIqkIThc0h9OCU0dwGMYwhg0ojuUEWg6nM2a/7XQA51jfHBxOP6qpphqO1h+tP1o/YAdrsLVfTGGhQCvQCjQYUTmickQl6ar2acHBqUrukEGsFNX+mv6a/hp4ruO5juc64BnxGfEZEQ5zmMMM2Dk9ToCwUos6tU6tU4MX5BfkF2T4fc/ve37fA52xzlhnjLQF3aryf6JqFljXeaF4oXihCBPUCeoE9aPX/UVJqAk1ocLz8vPy8zJsqdxSuaXS7j5lbYx5F3sXexdD1oasDVkbwF3jrnHXON1lznSs9sVd9V31XfXwbO2ztc/Wgq7qqq6SMYdNjpaj5Wgwa9WsVbNWwbDGYY3DGqG3rreut26Ag8jB4RTm1BEcHBwcHBwcTiXMlIoevUfv0WG/tF/aL2XAymoK6qMYxShgYnRidGIUXA+4HnA9AMYGY4OxAWimmeYMvA4HhwEImqAJGhxSDimHFPifrP/J+p8sqH+k/pH6R+DP8p/lP8uwVdwqbhVhm75N36bDy/LL8ssy1HfUd9R3wL/v+Pcd/74Ddi3dtXTXUjDOM84zzgPhKeEp4SnwxD1xT9zuYmE5ewaLVRMi0BZoC7TBNxZ+Y+E3FtrF9gaN6Wx4R35HfkeG52c/P/v52XB07tG5R+cCQxnKULt9YtasrFlZswbUaggLYcGp2XTmYwlopnMoFo/FY3F4kRd5EejRerQebfCnsWr8XKBdoF2gQVmwLFgWhL4lfUv6lgzoXuE4HRxOYRzBwcHBwcHB4WOwFkh9dX11fXX2xmmf3Cf3yYM/vtWub9qMaTOmzYCcDTkbcjZA/939d/ffbbcxdHDIKOZCyVXpqnRVQkeiI9GRgGf0Z/RndKjNqs2qzYKba2+uvbkWbp5387yb58HiRYsXLV4Evy35bclvS2DvlL1T9k6B/jX9a/rXgHC5cLlwOXh+4fmF5xfgv8N/h/8OcFe5q9xVZMzhYASNoBGEs8Nnh88OwxRtijZFA7fu1t364I9vCYwvyi/KL8qwc9POTTs3gfFj48fGj0H4QPhA+AD8ul/367bwkRYanFoNXyksZ3a61kfHSx0vdcBuebe8WyZjTgerWdFlMy6bcdkM8LZ7273t0JfoS/Ql7CKtDg6nIo7g4ODg4ODg8HEc16Vi98zdM3fPhC6lS+lSBn94t+yW3TJcIl8iXyLD17SvaV/TIFWSKkmVDKgB46RkOZwIzPvbWih7Yp6YJwZHG482Hm2Ed+vfrX+3HnaM3DFyx0jYX7G/Yn8F9I7sHdk7EoyIETEiINwl3CXcBe4H3A+4H4DsRHYiOwGBUCAUCA0oAj5YzOfASmW4gAu4ADhbOVs5W2HwqbhmqtR70nvSexK8suyVZa8sg+7e7t7uXmAsYxkLnhpPjacGsjZlbcraBB7Fo3gUp6vaVx7TYWAJ05qqqZoKvXqv3qsP/vBuyS25JbhIvki+SIYx+hh9jA49i3sW9yy22ys784XDqYgjODg4ODg4OPwDrFxdPaJH9Ai06q16q87gazmY7TGL5WK5WIbZa2evnb0WvE//f+y9e3wU9b3//5zZa0JCNogSrhkQdVGEQLHusYqD1TZaTrNU2uZUhKG1dW09JZzaUx59tBH3gscAACAASURBVGXsoT3peXhKfPRy9pxaGfqwNXqohtZqtBwZrbZpvSRaCkFQJoASIZANhmSzt/n98ZvZyZeWCtnlPs9/9sFlPzOzc/t8Xu/3+/X2bfBtgGwoG8qGwOw0O83OIhyIi8vfwPYa8DR6Gj2NUNZU1lTWBOVryteUr4HAvwT+JfAv4B3rHesdC55LPZd6LgXfNb5rfNdA8I3gG8E3oLyjvKO8A0o3lG4o3QBiq9gqtlI000Szw+wwOyDQEGgINMDc2XNnz50NJVqJVqIVPn7WyBpZA/6g/EH5gwLbMtsy2zJgzjfnm/NBOCwcFg6Dv9nf7G8Gf5W/yl/llKi4nN/Y95GdcbC5b3Pf5j54R3tHe0ejcG8R630xxZhiTDFgTtOcpjlNkNWyWlaDTCwTy8Tc94XLmYkrOLi4uLi4uPw9rInifnm/vF+G17XXtdc1yMpZOSsXPnxQCkpBCRYqC5WFCsxaPGvxrMWQiWfimThOFycXl5OIoAiKoICnzdPmaYNR3lHeUV4IRUPRUBRCG0IbQhsgtDi0OLQYKjZVbKrYBBWTKiZVTILSeaXzSueBJ+KJeCIgRIWoUMySIGvBdYFxgXGBAWHChAERsSiT2T65T+6T4bm+5/qe64P39r6397295Nteeud753vnQ7Aj2BHsAE+zp9nTjNuFwuX/wTZLfavzrc63OuEl/SX9JR1yck7OyYWPX6aUKWUKXFV3Vd1VdeBf6F/oXwgpJaWkFJx27C4uZxCu4ODi4uLi4vJ3sNugDVUNVQ1VwR+7/tj1xy54j/d4rxgbsEzqphvTjekG3L7i9hW3r4AxtWNqx9Q6XQXcrhUupwL7ehc1URM18CV9SV8SglXBqmAVlMglcokMwUQwEUyAr9XX6msFURVVUT15pQWmbMqmDJIhGZIB45XxyniFvBAxYqwa+53GTmOnAe217bXttZDdkN2Q3eCYYPo6fB2+DvC3+lv9rSC0CC1CS+HH5XJuYQttg52DnYOd8ILwgvCC4HR3KRT7vpxpzDRmGnBR00VNFzVBWkpLaQlywVwwF8QtrXA5o3AFBxcXFxcXl+NAWCWsElbB6+rr6usq7NB2aDs0Cl/wWPjw4QNukm+Sb5Lh0099+qlPPwWlNaU1pTVgSqZkSoVvx8XlhLC8EWzvBCEuxIW4kxFx0tuYWwsnsVlsFpvhsscve/yyx6FcK9fKtcKHzygZJaNAu9FutBuwb/G+xfsWA3vZy14QJVESJQjoAT2gu5kNLseJlZn2l8RfEn9JQJfapXapFK0Ub6I0UZoowTRjmjHNgLSRNtIGZBoyDZkGp5uLi8uZgCs4uLi4uLi4HAdCm9AmtMEB+YB8QIZN0iZpkwQD+oA+oBdhA9bCLaSH9JAOS+Wl8lIZbq2+tfrW6mHCg2sO5nIeYbaZbWYb+Nv8bf42uES6RLpEAp/hM3xG4eMfkY/IR2R49f5X73/1fhhsGGwYbADhBuEG4Qbw1nhrvDVOZkPBtfgu5wdWW+OeVT2relbBa+pr6msqZMmSLcLwVndWLuu4rOOyDhDuFu4W7oZ0NB1NRwEFBaUIG3JxKQKu4ODi4uLi4nI8WBHNnJEzcgY81/Vc13NdsF3eLm+XKVqmg11iMU4eJ4+T4XPS56TPSfDJwCcDnwxAmV6ml+lgVplVZhVuqYXLuc0qVrEKypvKm8qbYLI8WZ4sD8uwKJD97Gc/0BnvjHfGIdeT68n1AD300AP+Rn+jvxE8DZ4GT4NjDuji8vewS4tSsVQsFYPXl7++/PXlMMAAA0UY32/4Db8Bl667dN2l6yDgDXgDXshIGSkjQa4p15Rzuxy5nCF4T/cOuLi4uLi4nFVYEzgr45pfV/+6+tfVMF2aLk2XoJxyyouxHSv1tkqpUqoU+JzyOeVzCoxlLGOBR/oe6XukD/ZG9kb2RoA4ceJOyrvd9tDF5WzGFtYu4AIuAC7UL9Qv1Ml7L4wYSyDsoosuYF/3vu593UAppZQ65pe+Tl+nrxPEmBgTY7j3lcuI2CnvlHfKcFA9qB5UoVwv18v1kY8nGqIhGlCtVqvVKpQvL19evhx62nraetogF8/Fc3HwJDwJTwK3BMjltOJmOLi4uLi4uJwAduTKrDFrzBp4dtGzi55dBG1Gm9FmFC9lNo+1sLIXXJ/RPqN9RoPVa1evXb0Wbmm8pfGWRsdk0m6LluvIdeQ6wGwxW8wW3EiXy9lJCy20wIWJCxMXJgpfqNnYXWbeVN5U3lSGmcDOZCYzwSN7ZI8Mvnpfva8eaKKJpsK3e9ZjP0cSJEjgPlfeB7trxf7k/uT+JOxV96p7VfKZbCPGKpmokqvkKhnG1o6tHVsL2Y5sR7YDsslsMpt0vRxczgzcDIczHetBbjaajWYjmJiYAB100EFesRQ6hA6hY5hrsqtkuri4uJxU7InkgdoDtQdq4Rfrf7H+F+thujpdna7CVGmqNFWi8EisjRWRDcpBOSjDPyj/oPyDAjN6Z/TO6IX2ce3j2sfBs6FnQ8+GoF1pV9oV6G7qbupugqHYUGwo5pSE5N8T9qcduT3ZC4iTNf6Ztt8n+nva///oCPrxRtRtb4FmmmnGaadqZ75Ypqd2iYIgC7IgAyFChE7guE41MWLE4KLYRbGLYhDoDfQGegsfNkWKFLBrwa4FuxZAak1qTWqN49Xi3end6d0Jnpc9L3teHtZ943zJcLDnn1EzakbBTJpJM+lE1sUOsUPscBa4trApBIWgEBx2vZ2m38veHzNoBs0gznP46OfdyaaTTjqhv6O/o78DjDuNO4074RrpGukaqfC2rqP10fpoHS5ceeHKC1dCrjHXmGuETDATzAQh0BBoCDQU6VhcXEaIKzicoZhxM27GyT8YR2ujtdGa85ysCFWEKkIw2DzYPNgM78jvyO/I0Cv3yr2yk4Io6IIu6KfzSFxcXFzOUeyFWgMNNEC71q61a/Cw8bDxsAF3KXcpdylQaVQalQZFd/MXNEETNKikkkpggbJAWaDAB1d/cPUHV8PbvM3bwBt1b9S9UQc79Z36Th3eee6d5955Dt5T3lPeUyClp/SUjrNgtSOXxzLHs//+RM3z3m/cY2H9f9MwDfNvfc8W4Ee6H/af328/3+d7pmqqpjrs044s2l0erMCAXSpjL/iFJqFJaAKiRImSF5bs9np54eDoT3s/rPFy0Vw0F4UjNUdqjtRASkkpKQXSSlpJK4454pHIkciRCAy1DbUNtUFWy2pZzbmebE+Qk9Xe8rixFrx2IKVyW+W2ym3g1byaVyt8+EEGGQT2GHuMPQZkZ2VnZWeBcFg4LBx2zCJtMz5bqDnXsTOk7OO1H3OXt13ednkbhHvDveFeGD179OzRs+HguIPjDo6DrcGtwa1B6GzsbOxshCMc4QggGIIhGJz0biZmh9lhdgC11FILJWqJWqLCuOi46LgoXFB/Qf0F9eBNeBPexPuNVkTChAmDr8XX4msZVhJUJPPRUqlUKpVg3GvjXhv3mvNcyXZnu7PdYIbNsBl2BHIXl9OBKzicYZj1Zr1Z7/S1viZxTeKaBNRV11XXVcMMbYY2Q4NRjGIUMKQNaUMavCW9Jb0lwZMrn1z55ErY3Lq5dXMrHG443HB4WBsrFxcXF5fiItQL9UK90wf918KvhV8LMEWdok5R4Vb5VvlW2ZkAn6yJt71gLKOMMuAy4zLjMgMulS6VLpUgo2W0jAYpI2WkDEhXp6vT1ZC7Pnd97vq/s6A/FqfKrd/ezi52setv/HsvvYwk4l1NNdXDPo/17++3Xzab2cxmMNeZ68x1zp/z59s2Fa2gggoQVEEV1L/++/zx2N+3OdZ1U0cddeRTrO3rML0uvS69DoYYYgg4rB/WD+vw7rZ3t727DbqMLqPLgK36Vn2rDtv0bfo2HfbH98f3xyFDhgynbsH4V1iCjjfijXgjcGHFhRUXVoBH9agelYJT0ge1QW1Qg0Rfoi/RRz4CLmbEjJgBb5m3zFsGQplQJpQV44DObGyhQdRFXdThyqYrm65sgts237b5ts1wdfvV7Ve3Q0VvRW9FL4iyKIsyZKWslJWgR+/Re3TYfP3m6zdfD+v71vet74O93Xu793aDWC/Wi/UUPaPGbDVbzVbHRPTyyOWRyyPwiYpPVHyiAj5Q/YHqD1RDZV1lXWXdsOv5FCNWi9ViNZQqpUqp4mSKFIpX9+peHSqMCqPCAO7mbu6G7Jrsmuwap8vLMTOoXFxOAa7gcIZgPxA8hsfwGPDRxo82frQRvtT+pfYvtcMkfZI+SQdRFVVR/evvj2c844EZj894fMbjMMGYYEwwQNuobdQ2DmvzZEdSXFxcXFyKitApdAqdcLjmcM3hGniw7cG2B9sgKAWloAQf42N8DCgxSowSg5O/gLMj69ZE3IcPH85nscY/6Zzqhe7Jxj4eKzPhlI1nCxvWpy1AHek90nukF4xeo9fohecff/7x5x+HJxuebHiyAfaE94T3hJ3U9GJ1h3g/zG6z2+wGT5WnylMF5V8r/1r510CQBEmQCh+/X+/X+3VIPJd4LvEcmPvN/eZ+EHYLu4XdIJaJZWIZTiaLXapyrmKl0F7CJVwCrNy1ctfKXTBHmiPNkZyF7dHYApA971ysLlYXq1AulUvlEnx/wfcXfH8BHAgeCB4IgoCAUIz9tUuVrIyc2aHZodkh+ErFVyq+UgGzmMUswCt5Ja/E6W9nevT9WaTnmgcPHqBiRcWKihUg/rP4z+I/Q/bu7N3ZuyHnzXlzXqfLilty7XI6cE0jzxDs2riLay+uvbgWls1eNnvZbJhsTDYmGyBKoiRKx/6+/QC/QLtAu0CDxcZiY7EBkWgkGomCGTNjZozT/8B1cXFxOVexIkd2KZvtev+jvh/1/agPfiP9RvqNBIPGoDFo4D6PXU4t9gLHuu68slf2yk5kdLY+W5+tw+flz8ufl+Hb7d9u/3Y73Nh5Y+eNneDHjx8wG8wG81TUhNvtXq39DcgBOSAPK/0YKdZ4dsr/kVVHVh1ZBcJoYbQwGsRJ4iRxEngkj+SRzv02mHaGQDASjAQj8Im6T9R9og5qlBqlRgEv3uOLTlrXV0ALaAENPmx82PiwAbWbazfXbna8MUzN1EytCPttZQSHjJARMuD21bevvn01zJZmS7Ml8Kpe1aty7gmWR2F7QNildd4qb5W3CnK1udpc7bASr4SZME9lKYmLyzBcweF0Y9coJoSEkICreq/qvaoXpknTpGnSCJRgK6XyIi7iImDBrgW7FuwCn+yTfTJkm7JN2Sbcia6Li4vLycKKIIkJMSEmoDveHe+Oww/++IM//uCP8CvlV8qvFHhPek96T6J4ppIuLoVglSgE1aAaVGEe85gHfKX9K+1faYdbjFuMWwzwt/pb/a3FWzgeE2ueYmc02AKJPc8pdNy0mlbTKmQ6M52ZTuCDfJAPOiUVQkyICedBG0y7lKIqVhWrisHV0tXS1RL4NJ/m00Y+rl36e516nXqdCmWRskhZBDLJTDKTHNY9Z6T7bZWAXZq4NHFpAuYac425BngUj+JRRj7u2YYtwPk1v+bXQHxCfEJ8AswnzCfMJyCn5bSchiPgubicBlzB4XRjPQDEsBgWwyBJkiRJEFADakAd+bB2RsQUaYo0RQJfzBfzxWDw7sG7B+92+vO67YzOU6yJZT419Ux3KXdx+XvYtdxW+7wzBSEiRIQIiC1ii9gC79a/W/9uPTTd23Rv073wgPyA/IAM+7R92j4NTMVUTOU077SLi4W9kJmsT9Yn6/CFdV9Y94V1cHXt1bVX1zJyE9CR7o/dVaNQrP3NqTk1p+KUmlzDNVwD4gZxg7gBhKSQFJKc+4KD1d73wpoLay6sgTHKGGWMQuGZAZaQOl4dr45XoSxZlixLwsCWgS0DWyC3Krcqt4oRL4RN2ZRNGSa2TGyZ2AKj1dHqaLWA/T1bsc6TqImaqJEX5OyMBrvL3Qmb67q4FBFXcDjN2A8EO2Uvr+AXKeLlN/yG33BqLgfnDc4bnAeZhkxDpmGYmYzLeYU9cfO2eFu8LSDME+YJ8073Xrmc81iu5/k2YIVGKi1MyZRMaZhLeY4cucLHLRZ2pNSudT7UcKjhUAP8ZONPNv5kI6zpW9O3pg9ekV+RX5FhSB1Sh1SKV+Pv4lII1gJ9sjpZnazCbXW31d1WB1ValValQU7JKTmFv+72caZjL8zsSPt85jMfxHvEe8R7hpVunOOCg40n5Al5Qsf2Chsp9vPefj4P1gzWDNZASkpJKQnMVeYqcyTdP+yAXUgMiaHTZwZ52rEFNCkn5STyArx5h3mHecewriOu4OByGnEFh3Mc2wXbTj1Lz0zPTM+E1I2pG1M3AhEiRE7zTrocG2uiU+zaO3siJTaJTWITromQy8nFyqSya6LLKaec4pnP2ZkBuZZcS64Fx17/DMN+Htu1xRkjY2QMeDL2ZOzJGHyt62tdX+uCdfI6eZ0Me9Q96h7VcYF3S+FcTid2V4K5ylxlrgLXr71+7fVrHQ+AXGeuM9fJWZM5aXcJyC9UpzOd6cBDPMRDOO1Hz3GEBqFBaICDiYOJgwk4LB2WDktFGNgKnB3kIAeBRG2iNlEL2fuy92Xvg1RZqixVNkwoPtH9ttqlHogeiB6IwoA2oA1oRdjvs4y0kTbSBuw19hp7DUgtSS1JLQFe4AVeALPJbDKbOGvuS5dzE1dwOF+wHjS5B3MP5h6ETGOmMdPoRAZdzlAaaKABcnpOz+nDUkALxE698zZ4G7wNwEIWshD3heRycrCuK3vBUiKXyCVy8SJSOTkn52TIqlk1q3LGCg42drcgX6ev09cJ/oQ/4U/Ajo4dHTs64L7v3fe9+74HX33tq6999TV4VH5UflSGPcoeZY8CaTktp2Vc7weX08IoY5QxyoAb1BvUG1QoV8qVcgXSnenOdOewBU6hWEK4LbhnjayRNSg888dKQbfNEMUasUasAeEW4RbhFmchmy+1OMex2/rua9rXtK8J/qz/Wf+zDlmyZAsYN6Wn9JQOf9L+pP1Jg+627rbuNjCnmdPMaZBtybZkW4Zl2p7g/EMICkEhCNvZznZgu7Jd2a44JonnPFaGzm5tt7Zbg7b1bevb1kPam/amvUA//fTjZDacbRlILucUruBwvrGFLWwBZjKTmU5kwuXMRGgWmoVmSHekO9IdkNWzelYvfFyP7JE9MoxeNnrZ6GWOh4i5ydxkbgI66aTT6Z7i4lII+fZ2VluuUdIoaZTkdHMolCFjyBgyYDA6GB2MAoc4xCEQZgozhZmcsS7lwiphlbDKKaUrbS5tLm2GzDcy38h8A/SX9Zf1l+GbXd/s+mYXrJi6YuqKqRBX4kpcgZeUl5SXFDioHlQPqpDW03pa56+6Ebi4FBXrurpEuUS5RIFpwWnBaUFIbkluSW4ZlmlU6ALHvo5jxIjBkDwkD8lF8DqxhIRSuVQulaF0Vemq0lXAJCYxCSfj7zwppbAzHPqT/cn+JDwmPCY8JoChG7qhn7g5aFbLalkNXuEVXgE2VG6o3FAJA9KANCCRvy7MZrPZbB6W8n+i+221Id4f3R/dH4WHux7uergLuuiii3NYeLCu3x65R+6R4WHpYelhCdqb2pvam8CsMqvMKvLzfGqppZbz5np2OTM5rk43LucQVuTP3GJuMbfgKp5nOvXUUw8DsYHYQAzSK9Ir0isoOPLiMTyGx4ALtQu1CzXwftL7Se8nIXtP9p7sPcNMhtyMB5diYEVY7AyHMsooowgZDnZ7O+OIccSA/r7+vv4+8oIDN3IjN3LGp0bbEUav4TW8hrMAsjOQBhsHGwcb4Xdrfrfmd2ug7bq269qug/GPjH9k/CNwxZwr5lwxB+YwhznA5dLl0uWSY/Y3hjGMAUqUEqVEAb/iV/yK8xywuyGZmJg4E/W8IHT088b68/ua+J2hQs9Zh3Wd59vbWWZ5dknS0efJvq/svxd1URf1YV2vihS5t9sRXrHsimVXLIPnf/n8L5//JaSb083pZhDjYlyMg9AoNAqNJz6+EBJCQghy4Vw4F4b+p/qf6n/KuU5PuIvXUYzSRmmjNAgtCC0ILQB2spOdYMbNuBknn2F4zmMvRK2I+auJVxOvJuBHi3606EeL4Pb229tvb4cZygxlhgIBKSAFJOf6sjMwB/QBfUCHl42XjZcNWLty7cq1K+G15teaX2uG3Cdyn8h9AoS5wlxhLnjinrgnDuK14rXitZx4aaedAWN5cOj1er1eD+ZGc6O5EerX1q+tXwthPayHdSjVS/VSfZhZ9pmO/fy0MnqG9CF9SAfDMAzDgEf6Hul7pA/+993/ffd/34Uj3z3y3SPfBR7jMR4D8SHxIfEh8GgezaMBceLEOePMlV3OD1zBwcXlTMby2EioCTWhOi/0QrG7mIyRx8hjZPA95HvI9xBk4pl4Jo5TYnGepJS6nGSaaKIJSrVSrVSDMXVj6sbUUXhJgPX9frVf7VdhqGSoZKgEeJRHeRQnsnO2LHyPchu3J/beiDfijUBqb2pvai8ka5I1yRow9hp7jb2wS92l7lLhGe0Z7RkNyvVyvVyHscpYZawCVdGqaFUUxvSN6RvTB2MWjVk0ZhFUrKhYUbECfIpP8SmQUlNqSoXcvbl7c/c6mRdHL+zs50feVO+o/S9aNwEXwIno214eGTkjZ2QQFVERFfAZPsNnOOfJp/pUnwqjlFHKKAXGMY5xQFgNq2EVpkvTpemSIziNFL/qV/0qXMZlXAb4b/bf7L8ZhhqGGoYawN/kb/I3FdDtwVpQ2pk7Pdt6tvVsczxh7etwpJSqpWqpChVyhVwhD9s/K6PCzvQ7XyLDtvCZ1tJaWoNnGp5peKYBtlVuq9xWCR9SP6R+SIXL5cvly2Uo08q0Mg16lV6lV4H2je0b2zfCs/XP1j9bD2/yJm8CmcWZxZnF5Pu1e5o9zZ5m8K/xr/GvAaFWqBVqGbGpoe2NY5uhb2rc1LipEV5pfaX1lVa4JHJJ5JIITFg5YeWElY7geqa/F4T1wnphvZMx9G7Xu13vdsFfpv5l6l+mwo47dtyx4w5INiYbk41g/tD8oflDJ/PDF/VFfVHwNnubvc3DfmfXs8vlNOAKDi4uZzB2quMR/Yh+RIf36t6re68OJ1V6hC9MW+HPt6u6uezmspthcObgzMGZTgTJTcl2KQZmrVlr1kJIC2khDcZoY7QxGgVP+OyF2CH9kH5Ih2Rbsi3ZBoQJEwahX+gX+p376KzBWuDYkWFvt7fb2w2eiCfiiYD/Rv+N/hshFUvFUjEY6hjqGOqAVDQVTUXh4LyD8w7OgwMPHHjgwAOw7fC2w9sOgzBWGCuMBWGnsFPYCZ63PW973gaWs5zlYGbNrJklPyEVvid8T/gejpmezff4Ht8DZjCDGTjF8DZ2UfXRf+8yMuy2gZZwZ37T/Kb5zWGmq6200up0u+KbfJNvgrhSXCmuhBK9RC/R4ZpF1yy6ZhH8u/bv2r9rMIUpTClgt+yF3kRtojZRcxbwB70HvQe9jgeAnelwwgsd2zTZyjjoNXqNXgMyqzOrM6sLv7xsL5kJUydMnTAVxC3iFnEL5DbkNuQ2gPmA+YD5APnf/XzBvq7sTJodrTtad7TCn1v+3PLnFvC+6H3R+yL47vPd57sPhj4/9Pmhz8NA+UD5QDlknsk8k3lmWOnLWMYyFsTHxMfExyDYGewMdoJf9st+2SkdLfR9YHvj2N2Q9sX3xffFYUfPjp4dPZC7O3d37m5gHvOYxxnv9ZMP/NzDPdwzLAP1BvMG8wYwt5pbza3AkzzJkyD8QviF8AvwLfEt8S2B0nBpuDTsvDdcocHldOJOBVxczmSsF6edUn1o36F9h/bhZB6MtK2g9b0qpUqpUuCCoQuGLhiC/fp+fb8OuZpcTa4GaKMNt22qS6FYC6LxLeNbxrdARW9Fb0Uv+fZdI8VO5d2n7FP2KTD47uC7g+8Cr/M6r4P4cfHj4sdxSscsIeKswxYArFT5vABR66n11EIgEUgEEpBuTDemGyEdSUfSEUi3pdvSbZBJZpKZJGTbsm3ZNjCjZtSMQiaSiWQiYL5qvmq+CtzHfdwH7Gc/+3FqMQYYYGDY/ljnM/9pl165JVinhh/yQ36I02XKPm9LWMIS4Ot8na8DKVKkIJlJZpIZeLXp1aZXm2DXul3rdq2DKdoUbYrGyDONrPeIfZmEIqFIKAL7w/vD+8OQac40Z5rBG/VGvdECutJYKeUHGg40HGiAlJJSUgoE9aAe1EcwnkVAD+gBHaaqU9WpKvhKfCW+Euf+MJeYS8wlONf1eZLpYCO0Cq1CK/iT/qQ/CdlYNpaNwZHWI61HWiHdne5Odw/7vexS3e/yXb4LwheFLwpfBDEqRsUoBBPBRDABo9pGtY1qA0/ME/PEKPo8w870Ca4KrgquckxMB0IDoYGQ81zM/WvuX3P/ivMcO9MEiK1sZeuwP3+f7/N94ON8nI+DsFvYLewGcY24RlwDvnm+eb55UBoqDZWGIBAOhANhJ+OBECFCp+lYXM57XMHBxeVMJkqUKAzWDtYO1kJ3XXddd92wGuuRTuCsSMIF+gX6BTpM2Thl45SNsM3YZmwzhvVzLtQN3OX8xpqo25HXKWunrJ2y1qmlLZR8O7CVe1fuXQnp+9L3pe8D4VvCt4RvOTXG+cjXuYItQHQIHUIHePDgwWnz54/6o/4omDEzZsYgq2SVrALZh7IPZR+C7LzsvOw85+9ziVwil3DMPc2F5kJzIfnMBmGJsERYAuxlL3vB3GnuNHfiTNDt1HP7eWFH5F1ODvbC147U3sEd3OFksOS7RNjnw2qPl2pLtaXa4B3lHeUdxenuIiIW5CBud60oT5QnyhOQS+aSuSRkG7IN2QZGnCp/NLYg3q/0K/0KjGY0owsYz6N4FI8C09Rp6jQVRq0ctXLUSuhP9Cf6E2Dqpm7qOILl+RYhtq4zsUVsEVugJFwSLgmDJ+wJe8KQXJJcklwCadKkNCXyJwAAIABJREFUGdZFyxKSvbpX9+rgX+Jf4l8CwVAwFAwNE6BG6O3xvljnSewWu8VuKEmWJEuS4H3I+5D3IUhtSm1KbYLM1szWzFYwXzdfN18Heuih5yTsT7GxTJCEMqFMKANvzBvzxsBf66/114Kvw9fh63DeB+fddetyRuIKDi4uZzB26UOmM9OZ6YQ97GEPzkLLjx9/AePb7cwuW37Z8suWw6Z5m+ZtmgfZa7PXZq8FM2SGzNCwlEcXlxPA7q9uR8guNS81LzUdz4BCGdQGtUENdi/fvXz3csi+k30n+45zvYqdYqfY6aR+n7MTL7sEw6rBznsu2BNvK6Xd1+pr9bWSz5wyp5vTzelOyYvdxcj8hvkN8xvkI2JCt9AtdOOYDlvPhXzk11742m6gruBwcrEFB7t0yCt4Ba/z92bEjJiRv/5/tnlqj9qj9qiQ03JaTivcC8GuiQ9uDG4MbgSz3+w3+yGbyCayCWd/7Ij5iSIkhISQgIOJg4mDCTioHFQOKjDBmGBMMBh5aaF1n0yVp8pTZbhozkVzLpoDh7sPdx/uhlwoF8qFwDRMwzRAiAgRIXLi2znrOeo5ElADakAFX5WvylcFOSNn5AzINeQacg3OvMVuNyomxISYGPZ8OlW/o73fq8RV4irwR/wRf8TJBDAzZsYcLpieLdjCiJXhZP+e9n0ixISYEOPcfd+5nJW4goOLy5mMPYG0UhaN+437jfth0Bg0Bg3wS37JL418eFuwmLlr5q6Zu2DUwlELRy2EIYYY4m/0xz7PUkpdCsTqslKpVqqVKlxy/SXXX3K945pfqCnpIeWQckiBPTV7avbUkG8DJrwhvCG8AZ6oJ+qJkl9gF2xSebZhCxFhISz8jVISIS7EhTiOe7l9n9tmmzZHp+KeraUp5ypHLyyOcV+ZYTNshmFAHpAHZKckacSleRZ2LX5pZWllaSV5YSr3RO6J3BNg3mPeY97DyN8j1vXZV9NX01cDb6tvq2+rMFOZqcxUCuhWYQkVVXKVXCXDdGG6MF2AHeoOdYcK2e5sd7YbaKYZV3D/K28ZT9KT9CTB0+3p9nQPEy6tjBChSqgSqnCev6d7vy3TxPz1crbPa471u56tx+NyTlNIFp2Li8upwmrPtUfdo+5R4ZBxyDhkFD6snXJue79NbJjYMLEBsjuzO7M7nVRrN2LpMhLMerPerIeLtYu1izWYZEwyJhkU3v3EWiDt0fZoezTobutu625zvAjsLg92ZMsuTXJ5H+yJqvt5bn5az3G7vV6+dK5AvIpX8SpQ1lLWUtYCbGITmyCn5JSc4pgPjhR7oTgUGgoNhWCntFPaKUFWzsrZAsa1Ga2P1kfrMMecY84xwRfyhXwhyKpZNas6gr/LUdjXld2dxiqdywucZ7pnwOm+Hwv9dHE5i3AFBxeXswA7VW5/cn9yfxJ2a7u13RoFR6bsicJEY6Ix0YArg1cGrwyC2WA2mA2Qacu0ZdqG1bK6uBwP1sLGa3gNrwEf2PyBzR/YDBVUUFGE4bN6Vs/q0Cl3yp0yJGoTtYlaEC4XLhcud9oFijExJsaGufe7uJzHmK1mq9kKyY3JjcmNjodDodgCn7/B3+BvcNqimk+YT5hP4GTMjNRU1Fq42p4Q24XtwnYBjihHlCNK4fvvw4cPmMtc5gIXtF7QekErZIyMkTHAbDQbzcYC9t/FxcXlPMcVHFxczgLsmrx+rV/r12Ab29gGZKSMlJEKH79ML9PLdLhu2XXLrlsGZZPKJpVNgkwik8gk+OsUaxeXv4MdERwTHBMcE4S52lxtrgY+1af61MLHt5sm/Hn5n5f/eTkMqUPqkAp8ls/yWfDO9M70zgQxJIbEEG4tq4sL5M0bM02ZpkyT401QKHb3lEBLoCXQQt400G6vnE+1L3TBbqWQv8VbvIVjIllw+2bLXHOGNkObocGVDVc2XNkA2TXZNdk1kG3MNmYbcTP9XFxcXEaIKzi4uJwNWAumbHO2OdsMW4QtwhYB+o1+o98ofHiP4TE8BnxA/YD6ARWmRqdGp0Yho2W0jDYsEuZGeFyOAzsieIV+hX6FDtO16dp0jcI9FKyFRbfULXVLsLVpa9PWJsi15dpybc7Cx/OC5wXPCyCqoiqquCmoLi7gPL+baKKJwhfqFrZJIC200IJjLjrJnGROckwjzYSZMBMFbMdq77c/uD+4Pwg72MEOipeBN0Ybo43R4Lrq66qvqwb/dP90/3TIBDPBTHBYpoOLi4uLywnhCg4uLmcRtlnTG9E3om9E813qCm9faZVWTJGmSFMkmL9s/rL5yxxzP1t4yJtIurj8Dcxms9lshtKO0o7SDliwa8GuBbugQqvQKrQijG/Vgm/RtmhbNOgKdYW6Qs51KW4SN4mbwBf2hX3hAszkThQr8mkfv92W0O7S4Qp1LmcEVuZBqiHVkGoAUzM1Uyvi+Hb7SFtwsO6HvMBR4H0gRIWoEIXB2GBsMAbtUrvULjmeFIXiM3yGz4BrpWulayWojlRHqiPDBAerJMXFxcXF5cRwBQcXl7MJq33TgfiB+IE4dGgdWocGWSNrZI3Chy+hhBLgI+pH1I+oMCE5ITkhCen+dH+6n3xbNReXv4XZbXab3TDdmG5MN+CDfJAP4mTQFMqANqANaNC2vG1523Loa+pr6msCpjOd6U7fcU+Hp8PTQd5stdjYEdVcc6451wyCJmiCBqPaRrWNaoPRidGJ0QkI1AZqA7XOws420XQFCJfTgd2lor+mv6a/BjJqRs2oRdzA0SaBVneHoi3UrUylXEuuJdcCHSs7VnashP3GfmO/UYTxLU+ki5WLlYsVWMACFgC8zMu8DNlkNplNgtlpdppnUxvF8wXruWquMleZqyDXkevIdYBZY9aYNWfxebMFbUtwt7vLmDEzZsZwhL4zHSujyoybcTM+7LxYmU/2/OF4P+3fwW7HapvU5s+7LXgW631rnwerRMzOrDQVUzEVzp7zcBR2YMRud50/LitwUqzfzxUcXFzOImzzu1RrqjXVCm0b2za2bYQ+pU/pU4qwAeuFcIV6hXqFCtdzPdfjLJjytaxn6YPV5eRgLyj8CX/Cn4APr/jwig+vgPHKeGW8Qj6DZsRY1+XbxtvG2wa8xEu8BGRnZWdlZ4Fwn3CfcB/4rvVd67sWPEFP0BMsvlmkPdHwNHgaPA1wRe0VtVfUwp1fu/Nrd34NvlPxnYrvVMB/bP6Pzf+xGb5+59fv/PqdsLB2Ye3CWhgjjZHGSGC2mC1mC25NuMupxbre7AW77bFQMPb9bQvSXrx4gR566KHoApuQFJJCErqMLqPLgD/zZ/5M4d0wbEqVUqVUgZsrbq64uQImPDHhiQlPQDqRTqQTuF1vzjDsDDe7dKesqqyqrAomRydHJ0dhrD5WH6uDGBbDYtj5f2c69kLWztQbo4xRxigwuWVyy+QWCOkhPaSTL2U6UzJw7PNhL/xzTbmmXBOIzWKz2AyjGkc1jmqEi9SL1ItUmMQkJgGTmic1T2r+O5+tk1ontcLk2sm1k2uhuqa6proGqhPVieoESB1Sh9ThmKCXGCVGieGYoI903poXdqzS5spIZaQyApNbJ7dOboWK5ormimYnEJEXOs5UbGGuyqwyqxxz74taLmq5qAUmxSfFJ8VhVGJUYlTCKSUrVLDzFu0AXFxcTh3WhGdL55bOLZ2wo2JHxY4KuFq7Wrtao+Ba+XKj3Cg3YOHqhasXrobn+p7re64PDioHlYMKeBo9jZ5Gp8TD5fzGfhFd2nRp06VNcIN5g3mDCT7ZJ/vkwse3M3he1l/WX9bhrc63Ot/qdFzwxZniTHEm+JK+pC8JIuL/r6YXybvBFtw8IU/IE4KbpJukmyT4/OOff/zzj8M0ZZoyTQG/7Jf9Mvm2n7b3yY3rblx34zp4TntOe06D/07+d/K/k9AV7Yp2RZ32tK7XhMspwfZusD8LFQQt8gLfAzzAA4WPd8ztKIIiKHBEPiIfkeGF5S8sf2E5XL/6+tXXr4YyyigrZHxrgTdTm6nN1OAG5QblBgWa1Wa1WXXaRXuSnqQnyZnf/vFcxV5AWpk09vm6vff23tt74VLzUvNSE3rbe9t72+GxjY9tfGwjPB1/Ov50HNKN6cZ0IwirhFXCqtN9MA62cOANe8PesHP9fXL1J1d/crUjoOyt21u3tw4eWfnIykdWwu+Dvw/+PjjMDLZI9/X77q8loJtBM2gGIRAPxANxmMhEJgKXG5cblxsw4/oZ18+4HqasnrJ6ymoY2z62fWw7BNcG1wbXgtAutAvtf2dDdvvVCqFCqAChV+gVep33vSiLsijD4OzB2YOzoX1t+9r2tfCzlT9b+bOVsKd5T/OeZqfr2/sel3Ue7G5X82vm18yvgfrq+ur6ahgnjZPGSbDH3GPuMeGX2i+1X2rwB+MPxh8MJzBot/U97VhCQ64115prdeb5i+sW1y2ug5u4iZuAEqlEKpFgq7HV2GrAz+792b0/uxfeaHij4Y0GZ5wTna+4goOLy1mI0Cq0Cq1wMHwwfDAMLygvKC8oToApQIBAIeNbE7o56hx1jgofXfnRlR9dCb+I/SL2ixjkkrlkLjlswuUulM5LTNVUTRVKI6WR0gh8/PGPP/7xx2GKMcWYYpBfeBdKr9wr98qw6bVNr216DQ5vP7z98HZgGtOY5kzMfJpP82nHP6F4X44y2bsqdFXoqhB8qfpL1V+qhqnKVGWqMswr4igvFXsiFFJCSkhxmr306/16vw5NWpPWpMFA00DTQBMIcSEuxIuw3y4upxKrFEHoErqELpyFzgu8wAsnYXv2+8a6316JvRJ7JQZvKm8qbyowW52tzlbJe1aMlDKlTClTYJGxyFhkwB+if4j+IQp7avfU7qkFMSkmxSQITUKT0FT4YbmcGHbGWWW4MlwZhs/P/vzsz8+GBfICeYEMHt2je3Ty16Odcdfb3dvd2w0vxl+MvxhnxAuok4Wd2n65frl+uQ5f3PzFzV/cDNNXT189fbXzvpkuTZemS1BeUV5RXgFvLXhrwVsL4O2mt5vebgIxIkbEk5HJYQk9doaUX/WrfhVmyDPkGTJ8ZNdHdn1kF0S0iBbRYJI8SZ4kQ8mykmUly4adl5Hen8dqB2+/fy0hdZoxzZhmQH9vf29/L/y448cdP+6AtJE20obTvvdY2IGUizsu7ri4A77Y/sX2L7Y758X+/nRlujJdganyVHmqDPGN8Y3xjfBb47fGbw1ItaRaUi2OB80p52ihIVQeKg/B0val7Uvb4TblNuU2BUJSSApJ5Odt1vSKrJJVsgp8b/v3tn9v+7D5ygkKdW5JhYvL2YjdtcJ6ELx4/4v3v3g/7FH3qHtUCjeRtCjXyrVyDW5dceuKW1fA9PD08PRw3hPMde0+X7EjS9aL/araq2qvqoUP6x/WP6yDT/JJPqnwzdiZBa/rr+uv6/BS8KXgS0HIbshuyG4AYYOwQdgAvpm+mb6Z4A16g95g8SIKdoQjGA1Gg1G4xbzFvMUESZM0SRvmzn+cBOSAHJDhBv0G/QYdZjTPaJ7RDNnObGe28ySY+Lm4nAIEVVAFFURN1ESNvKdKfiFXpG4Yf7XdbqFb6IZ35Xfld2X4nfI75XcKpLSUltKKML6d6aDP1GfqULe2bm3dWvB1+Dp8HZDrzHXmOnFLDE8Tdi3/2Pqx9WPr4TL1MvUyFTyaR/Now/6jdf1N0ifpk3T42IqPrfjYCiiNlkZLo07t/+k+j3Yqfkm4JFwShltW37L6ltUwVZuqTdX++n1jC9rTtGnaNA0mRSdFJ0Uh05HpyHSAKZmSKVG0kqZ8yYD1XqySqqQqCZbPXj57+Wz4Tt136r5TB0v0JfoSHcJ6WA/rTtt1j+yRPTIFC4HviyUwBdSAGlBhtjxbni1Dabw0Xhof9r59n9IHO2PjYi7mYkCSJVmSnYCcjX0ebMHhrsfvevyux+Em5SblJsUpNc2XUp4qjhYakuXJ8iQsXbZ02dJlcJt8m3ybDCE5JIdkHCHH+v18+PABs5RZyiwFxrSOaR3TCplIJpKJnPj83xUcXFzOYoSgEBSCsKtzV+euTnheeV55XoE0adLF2ID1op6hz9Bn6PDpzZ/e/OnNUFpTWlNaA7nuXHeuG9cE7zzDfhFX1VTVVNXAp9s/3f7pdhjHOMZB0VI53+M93gOevP/J+5+8H/bduO/GfTeSrw0XJ4gTxAngv8N/h/+OYROaIqU42yZ79gvZvg/s7i0njPW7XCBdIF0gwYzVM1bPWA2pjlRHqgOyWlbLasO6W7i4nA3Y97tt0mrXNPTTTz95s+Oivyes7dreCpuFzcJmAXYru5XdCkUT3m0z5TqpTqqTYF58XnxeHLL12fpsvWNS6HKKiREj5nRdyV9exxC47Od2RIpIEQlq5Bq5RoZ0c7o53eyYEJ6u+YxtohhuCjeFm2C+Nl+br4FX9+pe/djfG5KGpCEJEkbCSBjQf3f/3f13QyqSiqQihV+feSG8jTbaYFZ8VnxWHL7++Ncf//rjcAd3cAcwVZ+qT9UdT4BiZTiOeL8tweU95T3lPQX6uvu6+7rhiH5EP6I7wsOxrhehQWgQGmBAHpAHZBjShrQh7djbs4VXyZAMyYC7Vty14q4VTgmmv8Pf4e84BcLD0UJDZ3lneScsvXrp1UuvhtvU29Tb1GHTpGOdJ0sYsudhidpEbaIWjkSORI4M795znN3rXMHBxeUsxk7pGqodqh2qhWeWP7P8meWwV9or7ZUo2oTLr/k1vwa3KLcotyiwoGZBzYIa8l4RZtSMmq6J1jmPrWgHQoFQIATR3mhvtBc+qHxQ+aACoiIqolKE7ViRlNeU15TXFHi26tmqZ6sgPSE9IT0BhHqhXqgHn+pTfSr4W/2t/laKH0m1Xri+kC/kC0GJXCKXyBQsqHgkj+SRnFKLVDgVToUh2ZPsSfY4x+/iUlSszDj7vXF0pG7E2LXVVrcWoUwoE8pwFm4neQFnl1C9mXgz8WYCNmubtc0apOSUnJKLsAEr8jdFn6JP0WFp9dLqpdVQVVtVW1ULOTWn5lRcE9hTjB3xf7f+3fp36+Fl5WXlZcXJwDwWF2oXahdq8I91/1j3j3VQuqp0VekqyMQz8Uz81D9/7QVoSU1JTUkN1G6u3Vy7GSYqE5WJCsd839jX3cvSy9LLEmyt31q/tR4GFw8uHlwMg82DzYPNIw8M5X8HSzCcWz+3fm493LPsnmX3LANZkzVZg1K1VC1VOXapw9HY72lroZvv4mSZZJ7w51HdO+zuO3uMPcYeA3618lcrf7XS6e6WFxDCQ+Gh8LHNZoWwEBbCsCW6JbolCr+Xfi/9XoK0lJbS0rEP76+Eh2V3LbtrmdP9zY8fPydBeDhaaJDKpXIJlo5bOm7pOLhNv02/TT8OocGa1x+UDkoHJfjVol8t+tUi2P3E7id2PwEDmwY2DWyC5MLkwuTCYZ4h74MrOLi4nAPYqZ/bG7Y3bG+AzepmdbNaxAmX9WC6SL9Iv0iHpRVLK5ZWwCXJS5KXJCEXz8VzcTcye65in1ehSqgSquCatmvarmmDRSxiEVAql8qlcvG2d1g7rB3WYKOwUdgowJ6WPS17WoAtbGGLUzvo1/26Xwdvh7fD21H8rhR5jiohKRT7fg1IASkgQe7u3N25uyEZTAaTQcjqWT2rF297Li4AgiEYggHllFOO00yiUOwJZz6V+yHzIfMhnOvXznA4SdgCSooUKeDpyqcrn66ELqVL6VIo2ETZxs6guka9Rr1GhVv/69b/uvW/wB/1R/3RYRFyl1OCLTwPSoPSoAStXa1drV3QrXVr3RrHznSwSn+u1q/Wr9ZhbnBucG4Q0pF0JB0pfjvA98PuFhCuD9eH62G+PF+eL4NX9ape9djfO2gcNA4a0LKoZVHLIjjwjQPfOPANMH9s/tj8MaQXpxenF0OOHDk4/pIRSziz36ezwrPCs8LQsK5hXcM6mKPMUeYo4FE9qufv7J+Nvf3DxmHjsOE8Dv5P+T/l/xR4TH5MfkyGR9VH1UdVeFR+VH5UHvYpPSo9KsGjPMqjOJ+PaI9oj2jQLDVLzRKsV9Yr6xX4gfoD9QcqfH3O1+d8fQ483v149+PdMGQMGUMG5O7I3ZG7wxEm7IzNo7HNnA9Jh6RDEjy4/sH1D66HF4wXjBeMExAerFKM2LrYutg6uEm9Sb1JLWKpxdFCQ7A8WB6EpSuWrli6Am6TbpNuk05AaJAPygdleFB/UH9Qh58Hfx78eRAGPzv42cHPOm0z05l0Jp1x2py+3/3imka6uJwD2GY0Q/qQPqTDk+ufXP/keviQ8iHlQwpcpl+mX6ZTcO2c/QC9UrlSuVKBz+363K7P7YL/vPc/7/3Pe6Gnpqemp2aYaZ/r3n12c9RC+9LEpYlLE7C8d3nv8l6YqE3UJmoULZPGnrC/JL8kvyTDbxf8dsFvF0CqPlWfqndKiLwbvBu8GyDQH+gP9A/rlnK8EZbjxRrPTs3MVGeqM9WFD2svkPILv53end6dMJAZyAxkINucbc42O6m0RYtEu5zfWCnRlbHKWGXs/Rc0x4u9oBgKDYWGQjg51na/u1NUGy+EhJAQgh1tO9p2tEHrvtZ9rftgsj5Zn6wXzxNwFKMYBXxS+qT0SQn2tO5p3dMKT8Wfij8Vd9rwuWaSpwahTWgT2uAvib8k/pKAF7QXtBc0WKwsVhYrf0NYszIGxjKWsTilMq+WvFryagkMyoPyoAw+3af79JPXZSCf2RAtiZZEofbh2odrH4aJ8kR5oswxBRM7s+GP8h/lP8rw+8rfV/6+ErLhbDgbBmGeME+YB8KNwo3CjU5pwPHeALZp5YT6CfUT6uEL1V+o/kI11Gyu2VyzGURDNMS/sV/571uZEb1qr9qrQpvUJrVJ8PTyp5c/vRza5Xa5XYbulu6W7hYYenvo7aG3h7WftNvp2qkq9kLWKtEyk2bSTALb2c524BVe4RXIClkhK0Dmq5mvZr4K6TXpNek1kJuWm5abRj5gwQ/5IT8cZvZsj7+KVQwvPbHmr/b5f0N9Q31DhR8s+MGCHywgP5++VrpWulYCn+EzfH/jd8kLD6qkSircVXdX3V115J+Lv+38bedvO0dgLnm00NBd3l3eDcvuXHbnsjvhM/pn9M/oEDJCRsjguIWGn0o/lX4qwf888j+P/M8j0FPbU9tTC+YD5gPmAyDOF+eL80F8QnxCfML5Hd5vHuhmOLi4nEPYC7IdrTtad7TCb/Tf6L/RYYABBoq4HbsbwIf5MB8GPr3606s/vdrpr2zXvrucpRz1IpvYMrFlYgvEemO9sV6YJc2SZknD2jkWijWx2q/t1/Zr8PCChxc8vAD21u6t3VsLvM7rvA7CYmGxsBgCyUAykARfs6/Z1+xEuoqNnUmRUlNqSnVSMQvNPLAnOuPl8fJ4GcrbytvK28Dca+4190IulovlYpz0yLDLeYI1sRUlURIlGLts7LKxy8Are2WvXPjwttB9qOZQzaEayD2YezD3IM4C5xQJz7aQlwllQpkQtK5sXdm60mnvdrypv++LJUSOZzzjgeUrlq9YvgLmROdE50Rx+ty7GX+nBFuQHawfrB+sh6dWPrXyqZXQrXfr3TrHfF57DI/hMZyMlasar2q8qhHS8XQ8HT/5mQ75zIZYOBaOwXzmMx/wal7Nqx37ez1qj9qjwmNdj3U91gUHogeiB6LkJ3ri8+Lz4vPgH+sf6x8LYlSMilHe9z60TRT9kl/yS7Cod1Hvol6IqBE1or5/RoNtYm69rvm3lf+28t9Wwj3r71l/z3p4qOWhloda4LXka8nXkvBu1btV71ZBwp/wJ/zQ91jfY32PQd/Wvq19W6Hvrb63+t6Cvnf63ul7B/oO9x3uOwyHU4dTh1NweMLhCYcnwOHfH/794d/DkdePvH7kdRj61tC3hr4FOX/On/ODMF+YL8x3SiT89/nv898HgfpAfaB+mPBwLKxSNFtI7Ix3xjvj0FTZVNlUCb/Tfqf9ToO0nJbT8rGH+atSi7V3rb1rLXwk9pHYR2InkPFw1PxsdM3omtE1sPSjSz+69KMjEBqs0omfGj81fmrATyp/UvmTSuiJ9kR7ok4prfBl4cvCl8Hb5G3yNkEgHAgHwiA2iU3icQirruDg4nIOIUSEiBCBjJJRMgo8OfXJqU9OhVeUV5RXlGGpdUXCdh/+J/mf5H+Sof5r9V+r/xqMqhpVNarKNdM667BfZFamQWWkMlIZgSXXL7l+yfVwnXSddJ3kuBcXi5SUklISPK0+rT6tgt6oN+qNkOnP9Gf6nUiNt8Hb4G2AYH+wP9gPYkgMiSFOXjszy5SsP9If6Y9Aj9Fj9BgUnqJtL1jU8ep4FcbFx8XHxZ1UdDvC5AoOLsXAnsAGO4OdwU64WLtYu1gDDx48RRh/QBvQBjQ4FD0UPRQFPsWn+BQwj3nMA+qpp55T1nZQSApJIQm7W3e37m6FDfduuHfDvdBr9Bq9BsUrjbIEjrASVsIKfHndl9d9eR1cGbwyeGVwmCDrlkadGlpppRX+EvxL8C9BJ9PhmJ4OdqaDPlYfq8PCtQvXLlwLZa1lrWWtkDEyRsYovqdDvhtFpCRSEoHaXbW7ancN82w4xgIxp+W0nAZtWpvWpsGLvMiLQKYz05npBGGJsERYAt4eb4+3BwIzAzMDM49fkLcFkBmdMzpndMLN2s3azdow76JjkJWzclaGPyl/Uv6kwOr1q9evXg8/L/t52c/L4O3E24m3E5Cpz9Rn6oHd7Ga302VKnCvOFeeC7yO+j/g+Av53/O/434HApwKfCnwKAksDSwNLIfDZwGcDnz2Oz28Hvh34NgTeCbwTeAcCzYHmQDOMWjhq4aiFULambE3ZmmEBCzsD5H2wBQuhWWgWmmF7zfaa7TVw//3333///U6phV3adcxxji61WB1bHVsNNzXc1HBTA/i7/d3+7r8hPNjzs5ZcS67F8Wi4fd3t625fB7cZtxkDDPJWAAAgAElEQVS3GSMQGuSfyj+V4SeLfrLoJ4vgwKwDsw7McgQ34W7hbuFu8D7gfcD7AIyqH1U/qh4CLYGWQAsILUKLcBwlIW5JhYvLOYhd0rAvuC+4LwiPPPfIc4885/RtHq+P18frFO4ibH1/jDxGHiPD7dLt0u0SpJSUklLgseWPLX9sOQzEB+IDcRBiQkyIFXx4LsXGjshZfbUrtUqtUoPl65avW74OFmmLtEUalKglaolavM3aEcdt6jZ1mwoP3fvQ/8feu4dHVZ7r/581p0xOZCIIQUFWBHFUasZDIdggC7+2jm6UpF+qka2w2Jtds1stgbpt3Je9WPZyd6e92BBsqimHzcKixnoKSjUqhcVBCGglwQMDsnEFOYzJQBIIyZBkZn5/fOedlR/I5hQUde5/vGrNzJo1a973fe7nfu778eWPw6H3D71/6H0SEkppo7RR2ghu0226TXAqTsWp9MrRPk+FjJBSipGOoBpUg6pF3Ik4rLPFQHmgPFCG75V+r/R7pfBh4YeFHxZaSoeE5jeJJM4BgsDK0XP0HB2Gq8PV4eqZx7qegHghfUg/pB/SIZQbyg3lQuxw7HDsMHCYwxy2iPAE8XC+ES8ko/6oP+qHNeE14TVhi/+4S7tLu0s7dSf5dCFMYK83rjeuN+ChVx969aFXoWJWxayKWbC9env19mqska94xzSJvkVC6RDsDHYG4c3iN4vfLIYCrUAr0GCINkQbonGCCaNIrxirj9XH6jBaGi2NlmB1zeqa1TUW0S2IrHPdbxJpFDXeGm8N3Jx3c97Neb3SHU4CIXl/bdlry15bBs23Nt/afCuWsmGnbadtJ7ir3dXuanDWOGucNSDVS/VS/cmvWxAq7lJ3qbsUbp95+8zbZ8JQdag6VOWkBLv4uw+ND40PDShfUb6ifAW8a75rvmtCt6fb0+3BIhhek16TXgP7Hvse+x5w7XLtcu0C18Ouh10Pg6PGUeOoAdsI2wjbiF6jLKf7exGfT5jYxhsVlFNOubVfi458ghA8QwWWVCVVSVVgr7fX2+thR9mOsh1lMN893z2/1/sXUEABZz5qIYifVf5V/lV+a9RCeE2IUcxpM6fNnDYTpmhTtCnaWYxOsIQlwMKGhQ0LGyB0beja0LUQmxubG5vbi2iIr5MZjgxHhgPSPGmeNA/Y3Da3zX3630+ScEgiiW8jxAIQLyTrjDqjzoCVS1cuXbkU7tPv0+/Trbivc0Z8hmugMlAZqMB0Y7ox3bD+fc1VNVfVXAXtWrvWrvWabf2KOl5JnARxqbUw/cwuyy7LLoPpV06/cvqVcLdyt3K3AplKppKp0Gdxl6JQEaZXzzQ80/BMA2wr3la8rRiildHKaCVIj0iPSI+Ay+VyuVzgrnRXuivBFrQFbUHO//MT/x311PbU9tTCZw989sBnD0C33q1365Cipqgp6tm/fLqZbqabcBM3cRPwevD14OtBy+wr1hprjbX2OjAmkcSZIL7+C2+D64zrjOsMuOTVS1695FXO2XtFEIaf8zmfA4e0Q9ohzXo/2+W2y22X9+oMxv/9V1Vwi87b4ZzDOYdzoJpqqoErlSuVKxW4mqu5mtOQVJ8mxIjKaG20NlqDh5SHlIcU+OOyPy774zLLYyDxuxZETBJ9C6F0qPu47uM62LB9w/YN22Eyk5nMyc1SRXrFJCYxCXhff19/X4dOOunk3D0dEp4NccWA/wH/A/4H4NKZl868dCYn/T0Kz4ZNbGITsGHBhgUbFlgjDNId0h3SHeBodbQ6WiGlJ6UnpafX81VIIf+LJ4AgJIcqQ5WhCuTn5efl54FDdsgO+eR/d8g4ZBwyQJd0SZdgU3hTeFMYuud2z+2eS6KQt1XaKm2VFrGQVpBWkFYArhpXjavGUlpJQSkoBbHOGXGF4ZlCjBYnzgeC6BP/+1xHveJ/L7xD7OX2cns57CzbWbazDOavmL9i/gqIbY1tjW3tpQw9U+IhEAvEAvBO+J3wO2HrsqeNmTZm2pizGJ3gIAeBJcYSY4kBC+9deO/CeyF0T+ie0D0QezL2ZOxJkH4m/Uz6GTiWO5Y7llspx2neNG+a98yJBoHkSEUSSXyLIRayzprOms4aeHH6i9NfnA5bjC3GFgOiSlSJKn34hvENM8fMMXNM+Gfzn81/NuGeMfeMuWeMJcX6uvOuv+sQG1msNlYbq4VB/kH+QX6YsXTG0hlL4R79Hv0eHfqZ/cx+Jn1HNMQhvvaVxkpjpQGve1/3vu6F8LrwuvA64BIu4RKw77TvtO+E1NbU1tTWXh2b0zVVOlfEd3gR+7o7d3fu7lwrl/pcYdNsmk2DG7UbtRs18CpexatAxB/xR/wQVaNqVCX5O0nirBArjhXHiiErmBXMCsL4reO3jt/ad6kyYmZZKJTigiS4hVu4xRp5ShRoX7WJsDihxwvQ7RXbK7ZXwLONzzY+2wgH9YP6QZ0+M70VEAqsm+Sb5JtkmLV01tJZSyHPnefOc5NIAUi4uyfRpxBKh47SjtKOUnhzwpsT3pwAQS2oBTVOnV6hj9HH6HC9fr1+vQ7darfarZ67p0PCs6HcW+4th5vlm+Wb5dNIozAOGgcNqGmoaahpgKaKpoqmCuAQhzjUS9lQ465x14BTdapO9TSIEUFIxtOnrqm/pv6aerjEvMS8xOTkcZzx0Y5NyiZlkwJvtb7V+lYrHLvl2C3HbiFRodrabe22dkgdkToidQT0W9lvZb+VkFqTWpNaAw6vw+vwgi3flm/LxyqYz7WRIP5eFMRi3enrBsXJiIfgzuDOICxYtmDZgmWwgQ1s4PRHLXLVXDVXhX999V9f/ddX4c7qO6vvrIZ/GvRPg/5pEEwxp5hTzLMgGoQZpCAafhT6UehHvYgGoWgQRINQNJwj0SCQVDgkkcR3AEIKuC+8L7wvDEu9S71LvdbGcoV8hXyFTN/NmsYPcAO1gdpADVRVVVUVUsenjk8dDy88+sKjLzwKzd5mb7OXxIFQdMKSOD8QedfCrf4K9Qr1ChV+Ov6n4386HhRTMRUT0vQ0PU2nz4mGiBkxIyZsZjObgUVXLbpq0VXQvKB5QfMCEm5TwuQqpSKlIqUC3DPcM9wzQFolrZJWARVU8BW6vwuFgekzfaYPPp/0+aTPJ8EAfYA+QOfs0zHi93eoNlQbqsGdeXfm3ZkHO6t2Vu2sslzH7YbdsBvnzy09iW8ZRCpEvLM5umR0yegSK85OHGzPFYeVw8phBRqmN0xvmA7dv+7+dfevsSTMo2yjbKN6pRZ9xb9bAdHpFSMWq7yrvKu8MNwYbgw3YApTmMKpZ9XPFEIi/33t+9r3Nfil/Ev5lzJU6VV6lQ5b3FvcW9wWcSPVSrVSLUnlXx8hkV7Bx3wMrNfWa+s1+In5E/Mn5pd08I9LryhUCpVCBT5o/KDxg0YrfvNMlQ4JzwY1VU1V4fbtt2+/fTtcKl8qXypzSmXDZnmzvFmGjddtvG7jdRDJj+RH8kH6sfRj6cfgCDqCjiCkOFIcKQ6QRkmjpFGcUtkgiC+h+PAu9S71Lu31OzjJvnZEP6If0eHN6W9Of3M6ND3R9ETTEyQkRLbJtsm2yeDe5d7l3gUZ9Rn1GfXgDDqDziCJ9Uk0POyl9lJ7qTW6ctajvvHPI84ZPRU9FT0VWGkT8VGIPsfxxENcsbGjfEf5jnKYnzM/Z34Oic9VYBaYBeapFQ+XK5crlyvwb/wb/wa4trq2urZaz9GZmkEulBZKCyUI3Rq6NXQrxObF5sXm/S9Ew6i0UWmjzp1oEEgSDkkk8V2AWCh8+PDBB3Uf1H1QB88seGbBMwvgofkPzX9oPgzUB+oDdfouXjA+UnGRcZFxkQFT5anyVBmGPDDkgSEPgF6sF+vFsNO707vTC9GyaFm0rFfMYRLnBuHNEJ8ZdZY6S52lMKZ+TP2YelBjakyNWR12kT7S1xDS60/5lE+ByrbKtso2CNwYuDFwo+W2LFyQnT6nz+mDtJVpK9NWWgeSr42QihM0oiNa/0D9A/UPWGkddtWu2tWzf3mX4lJcCtwu3y7fLsO6WetmrZsFm4Obg5uDluS1r6TfSXy7ITqpOXKOnCPDj7N+nPXjLLhIv0i/SOec45HF3+/Wd+u7dfhk8yebP9kM0eeiz0WfA5vL5rK5rNnfC8W7R4xYtBvtRrsBzxc+X/h8IQwdP3T80PEwgQlMoO9NcYW7v0/36T4dHlUeVR5VYLm+XF+uwxv+N/xv+OGwflg/rPf6nfcx4ftdw/GeDrXFtcW1xTBu2Lhh44bBEHmIPETmhPss0ivGqmPVsSp8P/f7ud/Phb/l/C3nbzmWS//pejqIWGWhbBiXNy5vXJ4Ve3wyhNSQGlItL6ymPzb9semPwE52srOXsmGle6V7ZS8TxFN4NiSuSxAhccXBZeZl5mUm2BSbYlO+5A/iDal98j55nwxbza3mVhN6NvZs7NkIUoFUIBWAc5RzlHMUpM9Nn5s+txfREPdwER4K19ZeW3ttLSgtSovSAhdrF2sXayA9LT0tPX3y6z4p4tfX3tLe0t4CW4q3FG8phvWB9YH1ATimHFOOKX2YrnU8TqZ4iMdpnjBqoYxTxikWgXU8xHVmkUXW6bz/8YoGfYm+RIeFv1v4u4W/g9BdobtCd32JouE5x3OO575E0SA8qvpoBC5JOCSRxHcIwq04UhgpjBTCG9ob2hsa9J/Uf1L/SfDPxj8b/2ych5n9OBObbqQb6Qb4Db/hN6yZwT+rf1b/rMI63zrfOh8cDRwNHA1YB6+k8uHMkHA3jhcGA2oG1AyogX+I/UPsH2Jwt3a3drcGlxmXGZcZlrS/zxH/3vexj31A1YqqFVUrYMOSDUs2LIGewp7CnkJgJCMZCfZr7dfar4W06rTqtGpwFboKXYW9OhNfU+dPPH/dFd0V3RWwpWhL0ZYiuEu9S71Lhf70p/+5vEH8Pg3Vh+pDdZjGNKYBe36353d7fgcHPQc9Bz298s+ThUgSXwIR25Zam1qbWgtF04qmFU2DG/Qb9Bv0PjCJjKPb7Da7TdhsbjY3mxAsCZYES4AtbGFLL8KhzlHnqLMk21874uuHzWfz2Xywv3V/6/5WeGrZU8ueWgbZWraWrcEN6g3qDaoVI9pXsKk21aZCrpKr5CrwoPqg+qAKw8cMHzN8DFQb1Ua1Abt9u327fRDTYlpMs1zxk8qHs8Rxng7rf7X+V+t/1UvpcLynw/HpFcZEY6IBm4s2F20ugmPmMfOYeWqlQ6KgL0wtTC0E/3/6/9P/n3CpcqlyqcLJlQ0ijSLuvfWu913vu16I7I3sjeztlUbR7mh3tEMKKaQAkk/yST5OrWwQiCuO0urS6tLqYMCmAZsGbDr5dYlG1D5ln7JPgVB5qDxUDtzFXdwFtiZbk60J3PPc89zzrPhJKSAFpABEy6Pl0XLI8+Z587zw75v+fdO/b4KRxkhjpAF2xa7YFc7ZzFyYWd7SckvLLS1WAf268rryuoK1f54vL5njiYc44bizdGfpzlIr1ULcZ2Eu6cKF62ze73iiQZhBPr7w8YWPQ2hyaHJoMsQqY5Wxyl4eDdWOakd1L6JBTpPT5L5TNByPJOGQRBLfQYgDTGdtZ21nLbzke8n3kg8GpgxMGZgChWahWWhCmplmppn0eYEjZlzztDwtT0uM7JPXmdeZ1wkvB14OvByAz6o/q/6sGiI5kZxITi/mPuny/f+D8GTAixcvuPwuv8tvzQwXryleU7wGfmD8wPiBYbkcn3NKyckQ3wBDekgP6bBw1sJZC2fBy3NfnvvyXOiY3TG7Yzawn/3sB9sntk9sn0BqIDWQGgB3mbvMXdYrrir+ub5uiI6DiF37hE/4BEsiea4FnVBKjNPH6eN0UN9U31TfhCULlixYsgCOBI4EjgT6zi09iW8HRPyw6Bwq1Uq1Ug2TZ06eOXmmRfSes3It3kGMK5dZnb06e3U2dLo73Z1ukG6RbpFuAUeho9BRCI5aR62jtlfBfKEQZfH9Q5jUfZrzac6nObBw+sLpC6fDL2O/jP0yZplL9nlHNF5oZJvZZrYJk/XJ+mQdrtKv0q/SoXpt9drqtbBOXaeuU+Fw+HD4cJhEIXmhKEa+KUgoHcxOs9OE2ura6tpqGJc1LmtcFgzRh+hDdE5Mr4h7Oow1x5pjTRidPTp7dDas9q/2r/afOr1CKAuvqruq7qo6GK+OV8erp1Y2CCn8a22vtb3WBs33N9/ffD8nT6M4Q2VD4vrinhS2OludrQ5cWa4sV9aJ9yHx38dTrJrkJrlJho6ejp6OHpBGS6Ol0eDwODwOD6SEUkIpoV6NgnzyyQd7q73V3grjYuNi42IwUh2pjlQts9W+gkivGiwPlgfL8CP9R/qPdFjtWe1Z7YEjVUeqjlSBrdRWaivl/HnLHE88VNgr7BWwo3RH6Y5SmL9s/rL5y8D+mf0z+2cwjnGM48wbQB1Gh9FhwHKWs5xeHg1TQlNCU74k3lIQDe4Md4Yb0kakjUgbcf6IBoGkaWQSSXwXITo9fpvf5rfcxf/0+J8e/9Pj8Lr5uvm6CZ1Gp9FpcN5yxMWs2kB1oDpQhWKj2Cg24D/m/8f8/5gP9266d9O9myAnnBPOCZNwLRaS4cTJ9zuGhOlj/AAgTKeu8FzhucIDDzz/wPMPPA/aNG2aNg1+yA/5Ib2UK+cqqT4Z4gfpNrVNbVPhee157XkNqsPV4eowHKk4UnGkAtjNbnaDNFIaKY0Ed6G70F1oMex2r91r9154yhZJl3RJh0PBQ8FDQXgn953cd3LhqHpUPar23fuky+lyumx14O5vub/l/hbIqsqqyqqyDrJJM8nvNmJqTI2pVmFUUF5QXlAOP53000k/nQSD1EHqIJU+G5GLaBEtolmz8PU59Tn1ORB9I/pG9A2Q2qV2qR2cOc4cZ45VyFyoBHEiVjc+MrVJ36Rv0mHBdQuuW3AdfKp8qnyqWEqDPke8sHNpLs2lWSMXv5r2q2m/mgaP5j2a92gejAmPCY/p5VIfrYvWRet6efIkcXqI708f+z/2f+yHDeYGc4MJPfTQ87/82cXqxerFKkyaP2n+pPnQr7hfcb9i6An0BHoCVkddIJFGEVc23LbmtjW3rYFL5EvkS2RObsYYNwnepG3SNmmwvmp91foqiIyIjIiM+BJlQ3FKcUpxrxHUMyWghdeLiJGM728ng/icIvY8sjiyOLIY+G/+m/8GR8ARcASsgjbx+xLmlPHXTzFSjBTDWrfOG+KNj1Q9VU/VIVIdqY5UQ9gMm2HzKzRlFsRDnLgUHlVNWpPWpFkEjhg9PVN0yV1ylwz7svdl78uGoz1He472QOyp2FOxp3oRDX9x/MXxly8hGvp4dOJkSBIOSSTxXYYw04kX/k2BpkBTAJ6+/enbn74d/spf+Svnn3g4/uA1yhxljjLhIeMh4yEDnmh5ouWJFijSi/QiHQaVDyofVG4x6CL1QpgQfWsgPBjiDLUwkRIu1CMKRxSOKITpB6YfmH4Afpv126zfZsF0c7o53QRZlmVZ7iVVPF+IH+QOG4eNwwY8bz5vPm9C1dqqtVVroemWpluaboHY6tjq2GprljolLSUtJQ3Sh6QPSR8CzoAz4Az0UjZcaIj/XkSs3YbCDYUbCmGbuk3dpp548DxrxJUnwoX6H41/NP7RAHWMOkYdA/1b+7f2b7W8HWJ1sbpYXR+8bxIXNoTZWvz5cwfdQXcQfljyw5IflsCsrbO2ztpqmQCLzu45I77uH9AP6Ad0eP261697/TpoDbYGW4NAP/rRzyogXANcA1wDehUUF7gSR+x/QgK/Ln9d/rp8WDBhwYQFE2CXukvdpVoEz3m7jniBJrw2/kH/B/0fdPjNnN/M+c0cmP387OdnPw835N+Qf0O+lTYiPAJiSkyJKXxnifhTIZFeoXVoHRq8WfRm0ZtFEFSDalDl1OkV2hhtjAY3GDcYNxjQXdJd0l1yYnpFIo2i2lvtrT77NIrmlc0rm1dyYhqF8GwodhY7i79+M2Fpm7RN2tbL20IocI5Li+hRe9QeFeqL6ovqiyyPioTSUtz/c/1n/DwSF4QkTDeDlcHKYCW0t7a3trdCl6fL0+WBWHmsPHY+PcPiz4UgCuPLJVOXTl06dSn8UP2h+kP17L2gsowsI8uAf5r0T5P+aRL4X/K/5H/JIhQcbzjecLzx9RENAsmRiiSSSCLRSbbV2GpsNRD0BX1BHzxZ9GTRk0UQeTXyauRVuJM7uZPzN2qRQHzDEPm/+Xq+nq/DKG2UNkqD7XO2z9k+B9bKa+W1Mryrv6u/q8Oe8j3le8ohHAgHwgEsZt2UTMnstTFfaAdgUUjEY9KEckEw4hlqhpqhwghthDZCg/Gbxm8avwlu5mZuxspvdptu023Sd6afp0L8fYSZYrVWrVVr8FTjU41PNcK+R/Y9su8RiN0YuzF2I0jzpHnSPHAWOgudhZA+OX1y+mRwqS7VpfYqkC607+c4iJnUppymnKYcWFG2omxFmSWJztaz9Wydc/99xO+vR/bIHhmmqFPUKSrkHMg5kHMAnsl9JveZXNiZszNnZ46VaiGu74KRsCdxdhDrQjzeUsxcDw4PDg8OQ9HWoq1FW+HH/JgfAzmxnFhOrO9HALqMLqPLgLeVt5W3Fajz1fnqfBC1RW1RG0hPSE9IT4DzQeeDzgfB6XF6nJ5ehcc35DkUaRrR0mhptBTW1K2pW1NnEdqlaqlaqsJIeaQ8Urb2lT5H/H6JAmSIOcQcYsI98j3yPTLcrN2s3azBe+p76nsqrDHWGGsMaNAatAYNWkpbSltKe40ixteDhMT9G/J9nC8k0ityPs75OAfWq+vV9erpp1cIpcPfq/5e9fcq6KSTTsBZ4ixxlkBqaWppaincnnJ7yu0pcKl5qXmpyanTKOLpTRtLNpZsLIFIQaQgUgDSZGmyNBkcIUfIEYIUd4o7xQ3SCGmENILT92w4TxDKBeFRIlVIFdKXpNGI52+jb6Nvow+erni64ukK+GHsh7EfxiDLzDKzTM551DOshbWwBpuNzcZmA5YXLS9aXgTti9sXty+2Rk+63u96v+t9cHlcHtf5MGUWREN8/cjMyczJzIGpM6fOnDoTpihTlCkKeAyP4TE4688t1vuR5khzpAm/Wvqrpb9aCs5lzmXOZbBGXaOuUcFR46hx1Hz1RINAknBIIokkEpAKpUKp0Jo1+6L1i9YvWqFyWeWyymUQ0SN6RIc71TvVO9VeXgDnucAVnZ9MI9PINGC0MloZrcC1XMu1QNFnRZ8VfQYfjPlgzAdjYEvblrYtbbBd3i5vl6HJ0+Rp8kBHfUd9R71lrkYZZZT1iiOLf46ElP9sZ/uERE8UDPWx+lg9iYIh0YmKH0Ds9fZ6ez1kaBlahgaDqwdXD66GawPXBq4NwJitY7aO2Qp5ap6ap8JAZaAyULG8ML4ygiEOQYjsN/eb+01Y1LiocVEjPD/4+cHPD4Yvrv/i+i+uh9j1setj14M0Q5ohzQDHK45XHK9AxqiMURmjwC27ZbcMtmJbsa2Y8zdL2deIb9Qxf8wf88N61rMeixi7U7tTu1OzXPrPGfGDSIaeoWfocIdyh3KHAsPXDF8zfA2sNFeaK00wJhgTjAmwz7vPu88LPcU9xT3FvWIJ43GFCa+JC5zY+c4g3pEWEnnRIRUjb55CT6GnEMZUjakaUwU/nvTjST+eBNeb15vXm5BGGmnQ5+uA+J1vZzvbgeeyn8t+Lhta97bubd1L4uQqTBjdiltxK2BfZV9lX8U3r7AVo4bx9ShaGC2MFoIhG7IhQ3RCdEJ0Avxi6S+W/mIpeHWv7tXPPaXmlIjfR9EhH2oONYeacCmXcimgjFfGK+MhMC0wLTAN3lPeU95T4O8r/r7i7yvAzDFzzBxo87Z527zQ7en2dHtIdISF4kzsTwkpvChIvmXrxAmeDr5aX63PSo84ZXqFPFYeK8P3a75f8/0a+Fvwb8G/BcFebC+2F4PX8BpeA27Ouznv5jNJo3j8lcdfeRyaHm56uOlhYA972AO2XbZdtl29lA3Lncudy8/cs+G8Ie56KFVKlVIliTSK4xUjgpg4Wny0+GgxvFj6YumLpfBX/a/6X3WQsqVsKRvIJZfcs7iO+Lmrq7yrvKscmn/d/OvmX8NR71HvUa9F3IrrEPs39dRTf8534YTrEEq0flo/rZ8G9z9///P3P281Dk5JNMTPhxE1okZUS4kliJ3jIUxur5SvlK+UYRazmIUVv7neXG+uN63Rkq9aSZokHJJIIokTIBYiccBpKmsqayqDJ71Pep/0QtP4pvFN4+Fe817zXhMGyYPkQTLnb+TieMQXYrHPjjBHmCNMK7f4dm7nduBA3oG8A3lWLNFHnR91ftQJu+t21+2ug/2+/b79PjhUe6j2UC2EjbARNqA7vzu/Ox8iNZGaSI1VoCWIg/jMb+IC4qZICaIiHj8qDhqOsCPsCFseBf0D/QP9AzDUO9Q71Asj7xl5z8h74GrzavNqE4a3DG8Z3gIDxw8cP3A8pGqpWqrWa8byazrIR5WoElVgt7nb3G3C021Ptz3dBn8Z8JcBfxkAR94+8vaRtyE2OzY7NhukR6RHpEfAMcUxxTEFMvwZ/gw/uGvcNe4aq6D6xhUmcYiDehtttGEpPEbGRsZGxqzvs6/SARKFh+kwHSZco1yjXKNArpqr5qrgH+Yf5h8Ghm7ohg5bGrY0bGkAUzEVU4Gj7qPuo27oLuwu7C4k4d7+XfOCEAfBEw7qYqZZrGPH35fjpbsCgigTz/GpCoD4+pAgeMvsZfYySCtPK08rh8EVgysGV4Dvad/Tvqdh3JXjrhx3JfhSfCm+FMhWs9Vs9TzGu8XX14PaQe2gBssnLJ+wfAJ8uOHDDR9usOIvxey4y3AZLgNcH7k+cn0EkltyS9/kAjX+fQrFn1j31gbWBtYG4Ij3iPeIFx5Y88CaB9bAWH2sPla34m3P+3oWf32bYTNsBlzERVwE3KTcpD5ChVEAACAASURBVNykWDHHLTNbZrbMBNMwDdOwTG4D0wPTA9OhkUYagWa5WW6W4XDwcPBwELr93f5uP3R7u73dXqCaaqqxiDExwiU69vF/CmLzG2PuLDwdaj6u+bgG1k9aP2n9pNNQOmgDtAFar/SK1M2pm1MtJYm/xd/ibzkNzwaRRqHVaXUavOt/1/+uHyKhSCgSAmmqNFWaank2uB1uh9vR6/5+zcqGBETMh1gvT7GfCBNZ0XgJaSEtpMHhlYdXHl4JPY4eR48DYi/FXoq9BHTRRddZXFd8FIX3eZ/3QZooTZQmgn2UfZR9FDjdTrfT3YfKBqFoqI/WR+uhX1m/sn5lcP/S+5fevxT+0fxH8x9Na1TypESDSJ2Im4e+o7+jv6PDUHWoOlSF0dpobbRmEQnHQyivvLJX9srwi/G/GP+L8XCs4VjDsQbY5N7k3uTuZSb5FREPScIhiSSSOCkEo+oocZQ4SqDF3+Jv8cNidbG6WIVgQ7Ah2GB5BoxgBCMAO3bsX+WFHncAE8qLTDPTzDThCv0K/QrdmpU7uvTo0qNLoUVr0Vo0+OK2L2774jar09C0vWl703Zova31ttbboONAx4GOA9AtdUvdkmU6JBjllNKU0pRScB1wHXAdgHQ1XU1XoX9n/87+nZYU8+Ksi7MuzoKB+kB9oA6eSZ5JnklWh1J4M5xQ0JyvNIlTIX4dXXqX3qXD+8b7xvsG/GHBHxb8YYF1AD/adbTraBeJAlZIJ517nXudeyE9kB5ID0Dqg6kPpj7YK+f7G0o0JCAKyzgBtd233bfdB8salzUua7Q6DIP1wfpgnb5XosQPzOL5yTPzzDzTGu24W79bv1sHUzM1UwNzmjnNnGbFmh2tOVpztMY6+H5rIIgDAUEIxJ/nWGGsMFZo/VNAeHD06D16j06i4yv+LloTrYn2KkATOP73eZIDd8K7pC6lLqUOMg5kHMg4AINSBqUMSgE5S86Ss0AeJg+Th8Gg2KDYoBikmqlmqtmr83yy2Lo+QqfeqXfq8Kr+qv6qDjVX1VxVcxUcix6LHosCu9jFLrCH7CF7CNyV7kp3pUWE9Zl3xNcNQTzU2mpttSQ6oVuCW4JbghDyh/whP/xL3r/k/Use3MZt3Ab0M/uZ/UzOnznvyRB/LkS8njANHaQP0gfpcCM3ciMQHhYeFh4Gh/XD+mEdQkpICSnwxaAvBn0xCEKDQoNCg6BpftP8pvlwdNLRSUcnwbGiY0XHiuBY1bGqY1XWDHxLsCXYEoTdxm5jtwGhqlBVqApi4Vg41sss8ELDCUqHitqK2goYN2zcsHHDYIgxxBhicMr0ijHXjbluzHXQnt+e357fK43iFAo3EWOYSKMobS5tLsVKoxDKhngahUh/uWBHQ88QgnhIaU1pTWmF9HB6OD1spd5ESiOlkdJeHguncvc82fv8QvqF9AvrfqaGUkOpIUgpSClIKbDSas6aIBNEgxk1oyb0q+pX1a8Kpq6ZumbqGphiTjGnmGdANJgHzYMmLNGWaEs0+O+i/y767yIY9viwx4c9bpnKjlPHqeNUcOpO3al/yeeOEw9XGFcYVxhQOql0UukkiC6ILogugC2FWwq3FFomp+ebeEgSDkkkkcQpIQpIsYF2V3dXd1fDyyUvl7xcAo0ljSWNJfAvS/9l6b8shbHaWG2sBqmkkgpfX8Es3JfjxInIq06RU+QUGS4yLjIuMmC4MdwYblimYGKmUhRiESJEgNic2JzYHIiuia6JrgE+4zM+s2bixEHEbtgNu2HFG4n3TzDpJzuIflUKkVMh/n21qq1qqwpvam9qb2qwaMKiCYsmwLYbt9247UbontE9o3sGljR3nbROWgfO2c7ZztmQ8UnGJxmfgLvEXeIusaTXF1r6xLlCypfypXxL+rgqsCqwKgBDrhxy5ZArQVVURVV6FSLni2iJP1ei4BisDdYGaxbhMUYdo45RrdGoyJzInMgcYA5zmHMerucCRcLd//jfWwsttEBsZmxmbOaJ/39sfmx+bD6Jg2ECr/Iqr57GGwtidI1tjW0N2GW7bJctSb5dt+t23frvvmpCrsvsMrtMeNt423jbgIWNCxsXNkLzzuadzTshFowFY0GQBkoDpYGQ4k/xp/jBXeoudZf28g75tiFeiNhaba22VnCVukpdpZbSq1wpV8oV+B/1f9T/UeFe7uVeYKgx1Bhq9CJYvy7EiU7RCEgnnXQgXUvX0jUYbA42B5vwPfV76vdUa+ZcFFCJ/TAvmhfNg+iw6LDoMMvlP5wXzgvnwa6tu7bu2gorqldUr6iGv9X+rfZvtXCUoxzlwiUeEkqH6o+rP66G9U+vf3r90/AT4yfGT4wvUTrEcbFysXKxAlOzpmZNzYJwLBwLx6yY75MqG+L3baO+Ud+ow/rc9bnrcyFyWeSyyGVWJ/6CVzacK8TvKh7nm9aa1prWCq4aV42rxvIkSqQynSWEl4xYZx3FjmJHsdWgOuvzqRidcMfcMTf0K+1X2q8U7n/6/qfvfxqm5E3Jm5J35kSDaOgtGrto7KKxlgKk2dvsbfbC7xp/1/i7RutcWaAVaAUaODWn5tROfHmx/lytXa1drcHsSbMnzZ4E84x5xjwDNudvzt+cf/4VD0nCIYkkkjhtJBQPcTfiHnePu8cNdf46f50fPtc+1z7XLFf9ScokZZJiEccJs5oLDfGNQBAC4mBm1+yaXQMnTpxw6o6V6GCfrJN9oXb044WVaCDsMnYZuwx4btZzs56bBS8Pfnnwy4Nhf8H+gv0FEL07enf0bhKtdduPbD+y/QhcE10TXRMh/aP0j9I/showtnxbvi2fC/fz9xFEx+ZY/bH6Y/XwQuCFwAsBSJ+TPid9DtzN3dxNr3jSr+p+xJ/HBDGm/L8DyGk/198VnK4C5Xx5ppxn5cLJINzjN6ub1c0q/CH7D9l/yE4IGYjtj+2P7QfpYelh6WFwtbpaXa2Q1p7WntYOdr/db/d/+4jEE3Cc4kGkKglidsmyJcuWLIOdxk5jpwHTh00fNn0Y3GjcaNxoQKqcKqfKfOWeO6eEWIfiz19inYgr+E71XApT4/5mf7O/CcOzhmcNz4J+Y/qN6TcGXpjwwoQXJliNCqlYKpaKz/unOm0k0isCHYGOANReV3td7XVQsLVga8FWyzPjBKWDaTNtJvxA/YH6A9WKTxUTBidDSA/pIb1XGsVHzR81f4SV9rLbttu22/Js+LYpG46HUG7ZW+2t9tZecbriuYt7D501xAE0vs+JBsG5enQJAjYzmBnMDMLUe6beM/WeXooG8fKnIhri6SRLjCXGEgMWXbXoqkVXQejJ0JOhJyH2ZOzJ2JMQeTjycORhqPfUe+o9MK98Xvm8cpAmSZOkSdZzeDLFQ4J40K/Wr9Zh9tLZS2cvhXn6PH2eDluqt1RvqbbSevqaeEgSDkkkkcQZI+HxEHe9FbObe/fu3bt3L8wfMX/E/BHwQdkHZR+UwX3yffJ9snXwSjfTzXSTZKHzNUMckFrMFrPFBEM1VEOFZWuXrV22Frb4t/i3+KFzeefyzuUQezj2cOxhEm6d9hx7jj3Hkoin16fXp9eDy+vyurxgC9gCtu9gWoJwQW/xtfhafLA4d3Hu4lxgKUtZao06ZGqZWqbG16cASuK7CTEqFR+N3qxsVjYr8Pu237f9vg3qC+sL6wshmhZNi6Zh/d6F18TKtJVpK8EVdoVd4V6mg9+yQuikEMRDXMHm1tyaW4MurUvr0uBv9X+r/1s97KzeWb2zGu6+5+577r4HJumT9Ek6DGEIQ+gVV/wtWR+FV83F8sXyxTLco92j3aPBh9kfZn+YDfUl9SX1JX0gYT9PSKRX+D/2f+yHDeoGdYMKP1F/ov5EPbnSIaFMOgUSaRRxYm9TxaaKTRUQKYuURcp6pVG0OlodreB2u91u97dQ2XAyiJj28xXzKYiLcyUa4nHUYmT3/pT7U+5PgSn6FH2KfgaKhjjRsFhfrC/WYdGjix5d9CiE5oXmheZBrDJWGau0RkIcKx0rHSshtTK1MrXSSqeaP33+9PnTSZwvfqD9QPuBdhqKB67mamCWMkuZpcB8eb48Xz5/oxZfP+HwXdmgkkjiW4iE6VnAHrAHIG1U2qi0URAOhoPhINTqtXqtDttat7Vua4WiNUVritbAJHWSOkmF4dpwbbjWy2wrWXidX8Q7ax1Gh9FhQL1Sr9Qr8IL0gvSCBO/MemfWO7MgaAbNoAmR1ZHVkdXA27zN2yD9RvqN9Buwz7XPtc+FtHBaOC0MqTmpOak54Kxx1jhrepnZfVNSJ/oaoiCJSzZb9Va9VYdFuYtyF+VCt9FtdBswWZ+sT9ZhgDpAHaBy4YzUJPHtRLxj2Kl1ap0avKW+pb6lwh8m/GHCHyZAQ2VDZUMldBd3F3cXA5dxGZdZqUVpgbRAWgDcVe4qdxXY3Da3zc23pmA+Y4gCKSyFpbCl/BCKrj3aHm2PBhVyhVwhw8bsjdkbs62RCyGFvsi8yLzIPI8moF814gXVUGWoMlSBfDlfzpfhAz7gA7DSQOIjKhfKPnGCp0PcU3ecOc4cZ8IQfYg+ROesn3fhlfFK4yuNrzRC0xNNTzQ9ATTRRJOlmEgoG/wOv8P/7VU2fGMgiIZ4elBmSWZJZglMvXLqlVOv7EU0nK6iQYxOaIu1xRosWrFoxaIVEFodWh1abSkapAelB6UHwfGG4w3HG5DhznBnuC1zYckn+SQf7Gjd0bqjFebPmj9r/iyQ8qQ8KQ9uUm9Sb1LBKTtlp3zi5Qji4Rr9Gv0aHWZNmzVt1jSYz3zm0/fEw8nVzafpNnrWEFKZGmqoOQ+vnwRgmWB9XVLNCx59dVASM719Ha/zDYGQ0to8No/NY0lH3abbdJuwb8a+GftmwFPff+r7T30fSpeVLitdBktYwhIss6luuVvulkk+r32FOMEgTOAajAajwYB52jxtngazG2c3zm6E51Y+t/K5lbBv3b51+9ZBpDZSG6kl0YqzzbPNs82DlJUpK1NWQqY7053phoxwRjgjDM6AM+AMWB2i5MEoDjGzX2Yrs5VBq7/V3+qHPz36p0f/9CjMz56fPb+XdD1iRIyI8TVfcxLfOsTMmBkzodlsNptNWK4v15fr8B9t/9H2H23wQeCDwAcB6L67++7uu0kModtvst9kvwlSC1ILUgsgrTCtMK3Qigf8zhINxyO+3gmPAkepo9RRCunV6dXp1VYqyjrHOsc6B/z7gn9f8O8L4NcNv274dQOsVlerq1Vo1Vq1Vq1XbPI3HA7FoTgUK2Yy4ov4Ij4Il4fLw+VW7OoFB+HpoH6sfqzCemW9sl6BHrPH7DHP/OWEsmGTsknZpMBGdaO6UYVIe6Q90m6lUTjDzrAzDO773Pe577NSYJL76dcLEZ8p4i2nbpq6aeqmsycaEqMTDYsaFjVA6Peh34d+30vRIBTErzlec7wGGRkZGRkZkDYkbUjaEGvkSZhCCuXZjtodtTtqLeJho7nR3GhaDY6TQcRsXmNeY15jwqw5s+bMmgOjfaN9o30WERerilXFqs7+Pp6ccBB3MB6DI0ymhKnauaLb7Da7Teiu667rrjv31/vGQiwk4j6bETNi0mdS8x65R+6RIaJFtEgfvN43FvHnWTB1wgTwBPOvM0V8YxIu/mJD/c5CdHxypBwpx4pLy3BkODIcYN9r32vfCw0lDSUNJVA+q3xW+SyY2TizcWYjLJIXyYtkCJgBM2BCWA7LYZnkwfY0IQ6qR9Qj6hEV/s7f+TuWVO6h2x+6/aHboTJSGamMQCAaiAai0LWya2XXShK539IqaZW0ChyHHIcchyCtOK04rRj63djvxn43QtqqtFVpqyyviwttJvdCg+hQ2d12t90NHWqH2qHCi+qL6osqPFb0WNFjRbBKW6Wt0uCIccQ4YpBU/CRxdhD7Ulzi36A2qA0q/Db7t9m/zYbfNfyu4XcN8Gnxp8WfFkPUE/VEPSRihuxT7FPsUyB1YurE1ImQMTFjYsZES+p93iTP3xIkfu819hp7jaUAS5+cPjl9MrQ91vZY22PwSs4rOa/kwC93/HLHL3fAr3N/nfvrXHjLeMt4y4BmvVlv1q3z9zeViBeje923dt/afSt0lneWd5b3SoO5wJRdCaVDnKh/s+jNojeL4IByQDmgcMbXm0ijaHyt8bVGaK5srmyuxEqjiCsbUqpTqlOqv0TZkMTXAmGimOpL9aX6YErWlKwpWTBFm6JN0c6CaNCX6Et0WDhh4YSFEyD0ROiJ0BO9zBqPG53I8GR4MjyQlpOWk5YDtrAtbAtjjSIJojM+ciNGewLugDvghvkL5i+YvwA2spGNnAbxoByneHh11quzXoUbjBuMGwys5/74FKjTxEkJByHVEO6ee9fuXbt3LRxTj6nH1DN/IwHBaB5QD6gHVDjkOeQ55AGiRIme/et+UyFm3sSGv1fdq+5VocvoMrqMs39dQQx9rn+uf65DW0VbRVvFOV/uNxbieY74I/6I37rPPVqP1qOd/esKV/o9+h59jw7t1e3V7dV9c83fBiSY2nxHviMfUstTy1PLIbMwszCzEKIzojOiM2BzcHNwcxD+0/mfzv90ws8n/HzCzyfAf/Ff/BfwrvKu8q4CB5WDykGlV6fhG3oAO2fElQtiBnu/sl/Zr0CtUqvUKqDN0mZps+DnRT8v+nkRPPnsk88++SxsO7Tt0LZD0Dmqc1TnqF7SvUekR6RHwF5tr7ZXg9vj9rg90K++X32/esjsyezJ7AFXiavEVWJ17JNE0JlBjCA56h31jnpLGVTXU9dT1wOPNT7W+Fgj/NeC/1rwXwvgQ/lD+UMZjinHlGMK506QJvHtxHGmr2Lf/7PxZ+PPBjwsPSw9LMGzyrPKswo039J8S/MtENsT2xPbA9Id0h3SHWB32V12F6QNSBuQNgAyajNqM2rBUe4od5RbpsFJnCaEC7/y/w7yrqAr6ApC5n2Z92XeZ42ofFH/Rf0X9fCC4wXHCw5LefbI9EemPzIdnleeV55X4FP5U/lTGTrMDrPDtAr5CxWCUGjUG/VGHTp9nb5OH3S91PVS10uWWWkiNeZCQ/x88Un5J+WflMMGY4OxwTh9pUMijULZqGxUrL+PXB25OnI1SPdJ90n39VI2THZPdk/u9Tv7qpQNF8hIy4WGWG2sNlYLXo/X4/VAkVwkF8ln4NEQJ5rE6MTCPy3808I/QeiN0BuhN77EoyHuiZZQNJyMaDgexxMP8XNcwB/wB/y9iAd5o7xRthrRJ0NC8aBdo12jwX1Z92XdlwWZrZmtma0QrY5WR6s54wmIk3s4xD+YMAOq99X76n2wa86uObvmwPfM75nfM62C+ZSIb4hHtCPaEQ1Wt61uW90GBwMHAwcDWBoRL168WBrTs2RSvjGIPygi3/u9wvcK3yu03P5HKCOUEQqnf9CM3+dDHOIQsHrZ6mWrl8HhXYd3Hd4FPMmTPIl1n9tpp/18fbgLCPHCqKemp6anBjat2LRi0wq4Y+sdW+/YCkPMIeYQk9N3j45/H1/IX8hfyLBmxZoVa1ZAxxUdV3RcgbVRiPt8gTH4XzmEtLzYVmwrBpfu0l06OCY6JjomgivHlePKgbAW1sIabJO3ydtk+Fj+WP5YhhcnvDjhxQnga/W1+lotN97rjeuN6w2QNVmTNein9FP6KeBUnapTxSIkvmmFcfx5ESNRgoAU5o671F3qLhXeU95T3lPg3YZ3G95tgA/v/fDeD++Fg48dfOzgY9CzrmddzzqIvR17O/Y2iVQJcdCxbbNts20DZ74z35kP7r3uve69kPJYymMpj4HT7XQ73b3iPMV9TEo8zwlCEZIwXb1RulG6EZoebHqw6UFYMmTJkCVDYMPEDRM3TISJ5kRzogn/R/4/8v+R4XL9cv1yPfF1JjpySXxHIAjHeIzlfm2/tl+DDdoGbYMGKx5f8fiKx+G95e8tf285tFW2VbZVQnRndGd0J9YBNR5j63jG8YzjGUhbnrY8bTmkhdJCaSHLu0E0npI4S4j7HSfghTIsNZwaTg2D0+P0OD0Q9oa9YS8crDtYd7AOXq99vfb1Wlhz/5r719wPI5aPWD5iOYzxjPGM8cBN+k36TTpcbV5tXm3CQG2gNlCDVD1VT9V7xXF+1Uqp+PO5R9mj7FFgXeO6xnWN0PV41+Ndj1ueF5GCSEGkAKiggguwIXZCeoW71l3rhoLPCj4r+Ozk6RUCIs6wZkXNipoV0EwzzZCoa2x7bHtse6xRRRE7/pV5NogCNn7/TzniEj/3CiKFl3iJl76C6/yaEJNjckyGHDlHzpEhW86Ws2VOfp48jmhYYi4xl5iwaO2itYvWQug3od+EfvO/EA2hjFBGqBfRIDxyTtdcVawz8XhiobAKFAYKA4XWCKcot8cqY5WxCjgMh+EwTnw5EfMum7Ipm5BZllmWWQYhOSSHZEjxpHhSennYnAqnNI0UHZg93j3ePV74c/afs/+cDQ+ZD5kPmTBUG6oN1f6XfN34F9ChdWgdGrxpvGm8acCK3BW5K3Kha1fXrq5dwM/4GT8DqVKqlCqBMsoo44JdiPoakkfySB7Y6dnp2emBZ33P+p71wQPjHxj/wHgYZA4yB5n/C8ETH8E4oh/Rj+hQo9aoNSq8teCtBW8tgO5gd7A7CFKX1CV1WZJpqUwqk8q+qk/59UO4I28r2VayrQReuO2F2164zeIZ+sv95f4yJycI4ht3i9KitCjwF/Mv5l9MWOtf61/rh8h9kfsi94EtaAvagr1MoL7t7sKnC7EgilzksD1sD4NbdatuFZwVzgpnBXR5u7xdXjg24tiIYyNgr2evZ68HPn/i8yc+fwLemfvO3HfmwuBlg5cNXgZXT7h6wtUT4Pql1y+9fqnFzIqFUnyvInfcaTpNp2lJGROE3vkmJuIEiBh9ELOdXUqX0qVAu9autWvwhf6F/oUOu9Xd6m4VGswGs8GEhuyG7IZs2Pnozkd3PgpNJU0lTSUQ/mv4r+G/QmxnbGdsJ+DDhw8YyEAGWrOgtotsF9kuAudA50DnQEiZmzI3ZS64n3A/4X6il5Qznjpy2oRyEmeFhOlqvb3eXm8RCMfaj7Ufa4ePZ3w84+MZsKNqR9WOKng5++Xsl7Nh3OPjHh/3OIybM27OuDlWvvbFxsXGxUavOFIlXnAk02C+WRDrRFyp2CV3yV0ytCqtSqsCu9nNbuBd413jXQPWLli7YO0C+PCPH/7xwz9Cm96mt+kQ9Uf9UT/wI37Ej6w4OGm3tFvaDSlaipaiQZojzZHmgJTylPKUcrBV26pt1b3i45LoW4iGXpzIdVQ5qhxVkK6n6+k6pJgpZooJx3Yd23VsF3SWdZZ1lsHWgq0FWwusEZm/tP2l7S9tkDshd0LuBPBN9033TYe8aXnT8qbBlfqV+pU6XKJdol2iWTPoIlVDpGQk1vlzjOtMeIUYzUazAcsblzcub4T3M97PeD8DohujG6MbwX6X/S77XXxjCtVEekXc02Gduk5dp8Ld5t3m3aZ1nhAQylfh2bBJ36Rv0iHyXOS5yHO9CGeRRuFwO9yOXmkUddTxFYyai7qts66zrrMODmw/sP3AdrhCu0K7QjtR0RQ2wkbYgD1te9r2tEFPa09rTysXXNpIX0F876GyUFmoDA7HDscOx3qlrInz4vGjE3FvsoVXLbxq4VUQejj0cOhhiD0Veyr21Ikpbxk9GT0ZPZbp+hkTDcfjeMVDnOAMeAKegAfmZc/LnpcNs+XZ8mwZxspj5bEyOEyH6TCtlxHn1L3GXmOvAcGSYEmwBNq97d52L9hKbaW2UnAaTsNpnLrxIV0jXyNfI8dO6dsiNj6R73mzebN5swn/d87/nfN/51iNXHGg7zF6jB4D9hv7jf0GvKW8pbylwHNFzxU9VwS76nfV76qHaFO0KdoEti22LbYtkFmdWZ1ZDRn3ZdyXcR/Yym3ltnPJX/2GIeaL+WI+SClJKUkpgVvDt4ZvDUPRzKKZRTMtxUOamWammVahIiSUK/WV+kodXrj9hdtfuB325OzJ2ZMD0Veir0RfAftU+1T7VMisyazJrIGMURmjMkZZM/ffFQgmV0ga7/Df4b/DD3eOv3P8neMhV8/Vc3VwK27FrVidd1M1VVOFmqKaopoieCn4UvClIBy4/MDlBy6HWH4sP5YP9oH2gfaBkFWeVZ5VDmnBtGBasJepXhJfjriXSaw4VhwrtuKihNfLsZxjOcdyoGtu19yuub2kYfEDukt2yS4ZshxZjiwHDK4bXDe4DobJw+RhMlz+6uWvXv6q9b+HKEOUIYqVH55FFllAKqmkYsUKuVSX6lLBbtgNu2HlRouNRjxPPUqP0qNYigTh7XFUO6od1ay8dnEg+9z83PzchD3L9izbswz+x/M/nv/xQGN9Y31jPTR7mj3NHjg88fDEwxMtU83YgNiA2AAsSVsGGWRY1yU5JIfk6JUX73P5XD5w7XXtdfVSMDiCjqAjaBESogBO4mtCvPMVc8fcMTd0l3eXd5db6084FA6FQyTivbLnZs/NnguX11xec3kNXKteq16rwtVbr9569Va43LjcuNywCOtMI9PINKx1TSiNhPlUQtp8tqNKF5qS6Ku6HvE+J3k/QTyL+xxVokpUsSTl4vs9Kh+Vj8oQ0kN6SIdGtVFtVGG7sd3YbsBHCz5a8NEC2Onb6dvpg+CtwVuDt0J4YHhgeCDELopdFLsIa0Q17skguSSX5AKHw+FwOCwTSPcG9wb3hl4ErM/ms/n41hYQFzyEG35drC5WZ/0ee/J78nvyrX3lGMc4BnQv7l7cvRgiiyOLI4vB/qD9QfuDkLY3bW/aXuhf3b+6fzUMDQ4NDg1CbmluaW4p5H6W+1nuZ3CZfJl8mQyDtEHaIA2ytWwtW0tsJ6SQQgrg0lyaS7P2Q/Eci8ZMh9whd8iwS9ml7FLgxVkvznpxFqxQVigrFDj44MEHDz4IsWdiz8SeAUc/Rz9HP/Dcva4I8AAAD65JREFU6rnVcyu4y9xl7rILvwEWrY/WR+thuGe4Z7gHfrHmF2t+sQZGM5rRWATvR/JH8kcy/H7C7yf8fkKvhtTIyMjISLDfbL/ZfjNkVGdUZ1RDxuKMxRmLwVZnq7N9labL8fOWaIiN9473jvfCz9f8fM3P10CumWvmmtZI31pjrbHWgN8W/bbot0WwI7ojuiMKtv22/bb9kLUya2XWSstc9pt+3o2VxcpiZZb56/Sl05dOX9prtEL1qB7V8lp5Vn1WfVaFxbMWz1o8C0IloZJQSa/R1eMVDe0Z7RntkDogdUDqACtmvM/XX7GuxOtLQYh5a7213looGV8yvmQ85Cv5Sr4CKXqKnqLDbnO3uduEisaKxopGqCmoKagpgJ7inuKeYsicmDkxcyJkKBlKhmKlcp0Mp004CMRKYiWxEoh6o96oFzK8Gd4ML8jFcrFcDIMrBlcMrrBMsXaU7ijdUQqfrfps1WeroL2gvaC9AGK3xG6J3WIdcJ0/c/7M+TPIWpW1KmuVVXBf6AvQ+UKiA1oSLYmWQFZJVklWCciKrMgKDPIM8gzywOGawzWHayBQEagIVEDjY42PNT4GHf06+nX0s2b8pNnSbGk2uGa4ZrhmQJaZZWaZ4Cp0FboKv4OFxnExN4KZ9xgew2NArpFr5BpWXF2Lp8XT4rHMWPbM2DNjzwwI14RrwjUQeyX2SuwVizFOeSTlkZRHIMvIMrIMcPqdfqc/2TE6Y4gCLP4ci3VHMOtdE7smdk20pMU9vh5fjw8i7og74rY6KtJPpZ9KPwV7pb3SXgkp76e8n/I+pJekl6SXQHpFekV6BXhkj+yRIaMioyKjwlJe9Nf6a/01SPWkelI94KhwVDgqLLOfntKe0p5SaPe1+9p90GK0GC2GNbMqlEet9a31rfXQ0drR2tEKHXUddR110LWqa1XXKojsjeyN7IXYTbGbYjcB+9nPfsCBAweWYmGiNFGaCFKT1CQ1gW2EbYRtBNhX2VfZV1mFpMvtcrvc4PQ5fU4f2FvtrfZWS7mWfB4vbAiTW+Hx013SXdJdAuH2cHu43VIARV6KvBR5CWw9th5bD7gfcz/mfgz6Dek3pN8QS+HjafW0elohuyK7IrsCskuzS7NLLemleL+EOfSZzvYKZU1fQbz/mRIHwrw27t1zxjjTzxH/76UKqUKq4ITrFkSliAHsqumq6aqBNrPNbDPhUOmh0kOlcLj+cP3hegi1hlpDrdAWbgu3haGjvKO8oxy6n+x+svtJiF0S+//au3rQtq42/Jxzr6SrP1sJppjUBBNEUCEUQzOI4sFDKBo6iGKCKB08eCjBgwiiiKLBgwcTPHjwIDqUDMEI40GUUEwQQYOhJoRiimhF68FQtbhgqGll/d17z+nw3fcexf0M+RL3q+2cZxHkx4nOPfd9z3ne533ea/IagEMc4hCqVeoD9gH7YEg5UzAKRgEIFUKFUAGwpqwpawoI9oK9YE9dkPzK1AWpOL8xoHPKrtyVu4BMyIRMAGJcjItxwE7YCTsBDFqD1qAFDLKD7CALOGPOmDMGiD2xJ/YAWZIlWQJ4jdd4DQi0Aq1ACwinwqlwSkm4R7dGt0a3gJHiSHGkCESmIlORKWVed6V+pX6lDhiTxqQxCdVamv8t/1se+GH/h/0f9oFfKr9UfqkA/Xw/388DaKCBhlKYhmvhWrgGjMyNzI3Mqfx07gjLE/Cfg0cIv1V8q/hWEbi1eGvx1iJgTplT5hTwbOvZ1rMt4Kf6T/Wf6sDg/cH7g/cB9jH7mH0MhPZCe6E9VeAI7AR2Ajv/3jlc5mVe5lUL1Y2ZGzM3ZoB35t6Ze2cO+H3199XfV4Fvst9kv8kCP6/+vPrz6hDRtWPsGDvAqDPqjDpDBbYKq7CL7GlG759XUIqOR8ej48pU8e3s29m3s0Cz3qw368DzwvPC8wJw9OvRr0e//hczyE1z09xUrRP0/hkJI2Ek8M8TvSeIB/JYuWJdsa5YwHv77+2/tw+MHI0cjRwB39a/rX9bB76rflf9rgp0nnaedp6qToTItci1yDV1b6c8d1oe+Z8JB4J4KB6Kh0D3oHvQPQDasXasHQPccXfcHQfkptyUm4AoiZIowQ84dHBms2yWzQLGnDFnzAHR+eh8dB6ItqPtaFtJvd7YBOhtDJEWaZEGOolOopMAjqvH1eOqOmDKFbkiV9Tz8FsBgggiCDXHdWAOzIFiriPJSDKSHGKk3tR19i60NI6uM9OZ6cwAx8Xj4nEREEmRFElALsgFuaAusDQ32ZcurbAVtqJ68OJL8aX4EhDOhDPhjPIu0HhNUMD0vA38A5i3/x3LsRwLsMftcXvoQOasOWvOmopPIidyIgfIQ3kohyrG+B7f43tAtmVbtgF2k91kNwFWYiVWGmLs88gjD+U14/Uyyp7syR4gH8vH8rEisvAH/sAfQ58EIhKu4iquAuw6u86uA7iLu7gLsA22wTYANs/m2bzaRzR2jdyMg+lgOphW5m4UP/kqX+WrQxehc36g0zgFtO+9igtV2mzLtmwL6E/3p/vTwKAxaAwagPPcee48B8SBOBAHgHxXvivfhRosv41tbAP8Pr/P7wOYxjSm8dou1P5+pk9yMTz5+6/6c8/r36M/f5KgoV/3WvGoN5sKNz6h1BRN0YSqOBKRQEoFL5/7Unzv57A9tsf2lATXODAOjAMglAwlQ0kg2Aw2g01lSkfj0/yLgDaLu5ggJaBHxFNccHadXWdXmWHbpm3aJmCn7JSdUgo8sS22xTYgK7IiK0qZia/xNb6Gf76hfMYes8fsMcCX+BJfApBBBhmoc+o9cU/cA6QjHelA5TlS3j1hT9gTIPh58PPg50C8F+/Fe4CVslJW6uV7wM8NaKpczs25OaBT6VQ6FeB4/nj+eB5wnjpPnaeA/FJ+Kb+En9+N+8Z9474qaMRKsVKsdH7O4XSuctNu2k0D7ZX2SntFnYvdiBtxIwB+xI/4URUsyINkNDeaG80BoVwoF8pdIm8hyr/ee9Jf7C/2F4H2dnu7vQ301/pr/TVArIt1sQ4/71Gh16yYFbMCxPZj+7F9IHwrfCt86x9UNLzs9/E8Kqhlr3Onc6dzB+hn+pl+Zmgfp2RKpuDnId7kTd4EYpOxydgkEF+OL8eXAb7Ld/nu6f/sKxMOJ8c49sq9cq+spFU2bNgAxKyYFbPwXQz5TX6T3xyS9nkMT7gQLoQLQz1luvIGAJBN2ZRNQORFXuSB7lh3rDsGdAqdQqcAOAvOgrMAiAfigXgAP2Dxj/hH/CN1MYmsRFYiK0DYCTthRwU4qnS+6SAJo3vkHrlHQLfcLXfLQHevu9fdA5yG03AagHginognAG7gBm4AfJEv8kVVMaBWF5IIGlkja2ShJar/NEgJQRVaL0CSUogUD07RKTpF1apBUlWah+2uuqvuqkosoi7qog7gNm7jNiA/kZ/ITwD5hfxCfgH/4ua7tFKLg3fAwBjGMAawu+wuuwu/l57MeNkhO2SHACuzMisDvMVbvAUYTaNpNAEjZ+SMnJpqYNbMmlkDjLSRNtKKsPXHUnqeN35P7ptKJF520H735mL7Fw7PFJcuFvaEPWFPAPYj+5H9CHDLbtktA6IhGqIByJZsyZaqeMgluSSX8HcPGzKX0Hg9EIFAFzJvLJ6/vl5vKrvH7rF7iuAkRRO5lVNFjEx3A5OBycCk6qWluOHnea9nWBMMlxR0gSCC2/NAo4o8jdV0q27VrQ7lvw+dD50PAafklJySavWhcz0pI6jCKzMyIzMASiihBMgNuSE34I9Tpv1MlXxqJQrmg/lgHojcjtyO3AasXWvX2h26oFzQfUktL3bGztgZ4M/kn8k/k8p7Q2yIDbEB8K/4V/wrwHIsx3JU67g/reicjb+k592tdCvdiiIe7KbdtJuA/Ex+Jj8DjGfGM+OZeq6xh7GHsYfKk+iiPtdTQQXKvJt388Dx2vHa8ZpqmXWvulfdq0OKBq8AFM1EM9EMEDbDZtgcUgj92/eCk8RDYpAYJIB2vp1v54H+Un+pv6Tu8SzGYiwGhLZCW6EtIB6Lx+KxIaU85ZlT8Crc/3/gLRQtXLgSroQrKuENMoPMIKMqLdQTSpJmkvYHGoFGoDHUe6yJhhdAhAAxSpFipBgpqoqF3bJbdgtw1p11Zx3ABCYwAZg75o65o3ozAxOBicCEkvxrouFF0L6jQBmtRqvRKhCcCc4EZ4DBo8GjwSPAfeA+cB8AKKCAgipgBevBerAOmIvmorkI8AzP8Ax0Rfn/BZJQe4y6P1XBC6j0/pAHDY078ntlqVXMU7QQ8SR6oid6isAQ02JaTAPyurwuryuFBLkOo4YaavAPfNQSRhI08qSh95BMK6lCySf4BJ8AuMlNbgJ8ls/y2aEKEBEK5CFBCYsq12Smo4mGyw3a77S/vP0RSAVSgRQQyAVygRxg7Vg71g4gsiIrsoCbdbNuFnDn3Xl3HhCbYlNsAmJf7It9QCyLZbGs3gdfoeB5AWi8Jmg9KU5UUEEFfsWYrbN1tg7wBm/wBsATPMETKg74rRleHCHiwSccyyijPJTfKQ5ctoO/xosgpeWJcx3lQZ7iKZ4acqNPI400IE1pSlO1aJxs2aA8SK2nxJcREU8EJUnySfFH+cucNqfNaSCwFdgKbAFmykyZKYBP8kk+iX//wvWaoPeOpjzFE/FEPKHOGUTwmOPmuDkOhBZCC6EFwLRMy7TOH9FAINNoq2yVrTLAN/km3wR6lV6lV1EEd6AWqAVqgLVmrVlrSlF5aU3SvThKSlNqRTLyRt7IA4PkIDlIKlP00GHoMHQIhO6E7oTuDJmUn5d9T3HD82Sh+048FU/FU6r1zl6wF+wFwGgYDaMBWA2rYTWGPF1O5ptT8OoKh1NAB3iSEFKvk18xaaKJJvyxHX6i1Afkl8MJUyHqHaVEQfBNfXaxi2EGVa/zy4HWmS6mJCmiQOERCdSTSISafxHU63wxQIoEet4H8kAewH9vUEUVVfgXepKg+hUkr8Lsxzf6pJ5u6iGnaTueC7gf9ygxewdAP3DTPtP7SOMsQIoITzHn72sah7Ysl+UygBxyyKnKqA+9D88W1DpB8YJaJSh/eESE72FFLVze8/HjhCYSNM4ClAdPxgmalkDxwvv08563L0/GC5/49y6ulD8ve0HRV1hSIcMjapjFLGYp5eF5JRr+BtoPHqFESmtqQaUpFkRsvWmFTP898fIjTR3Dp/gUnw61tHoK1osSr/17j/f9aD/793Z6v2lc8kueD86ccNDQ0NDQ0NDQ0NDQ0NC4ZCCCShPRL+KyrssZfS9+Zv8hDQ0NDQ0NDQ0NDQ0NjcuJy3ahPitc1nU5o++lCQcNDQ0NDQ0NDQ0NDQ0NDY0zx19b6nowBcEvLAAAAABJRU5ErkJggg=='/>]]
end


--==================================================================================================================================
--==================================================================================================================================

main() -- Execute the program