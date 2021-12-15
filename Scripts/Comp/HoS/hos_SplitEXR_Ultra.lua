--[[--
Split EXR Ultra v3.0
by S.Neve / House of Secrets

-------------------------------------------------------------------------------
Description
-------------------------------------------------------------------------------
This script will split a multi-channel EXR image out into multiple Loader nodes.

-------------------------------------------------------------------------------
Fusion Support
-------------------------------------------------------------------------------
This script has been tested and works with Fusion v7 to v9 and Resolve 15.1+. It runs on Windows, Mac, and Linux.

-------------------------------------------------------------------------------
Installation
-------------------------------------------------------------------------------
Copy the script to your Fusion user preferences "Scripts:/tool/" folder.

-------------------------------------------------------------------------------
Usage
-------------------------------------------------------------------------------
Add a Loader node to your Fusion composite and select an EXR based image sequence in the file browser dialog.
Right click on the Loader node in the Fusion flow area. In the contextual popup menu select the "Script > hos_SplitEXR_Ultra" menu item.
The hos_SplitEXR script will then generate a series of Loader nodes in your composite that are used to process each of the channels in the multi-channel EXR file.

-------------------------------------------------------------------------------
RELEASE NOTES
-------------------------------------------------------------------------------
* v 3.0 2021-12-12 by Alexey Bogomolov <mail@abogomolov.com>
    - Use Fusion UI Manager instead of AskUser dialogue.
    - Run the script without closing the UI!
    - Merge loaders now work with any OS. Merge node is created explicitly.
        NB: Merge loaders will work correctly if the Grid Placement is set to 0
    - Some code cleanup

* v2.4 Ultra 2021-09.11 by Alexey Bogomolov <mail@abogomolov.com>
	- add option to rename Loaders by channel name for multipart EXRs 
		(when "Multipart uses channel Name" is enabled,
		the loader will be renamed based on the first channel found
		instead of the part name)
	- set tile offset to true if Fusion prefs is set to force tiles (first launch only)

* v2.3 Ultra 2020-3-09 by Alexey Bogomolov <mail@abogomolov.com>
    - add multipart EXR support
    - add Undo splitting
    - add merge loaders option 
    - fix freezing UI in Fusion 17+ on macOS if the AskUser text field has Wrap = true option

* v2.2 Ultra 2019-10-01 by bfloch
	- Fix for Blender support with "local channel = string.match(channelName, "[.]([^.]+)$")"

* v2.1 Ultra 2018-09-16 by Andrew Hazelden <andrew@andrewhazelden.com>
	- Resolve 15.1+ Loader node compatibility verified.
	- Note: You may have to run the Split EXR Ultra script a 2nd time to activate settings in the script's GUI like switching from a horizontal to a vertical placement in Resolve.

* v2.0.0 Ultra 2018-01-17 by Andrew Hazelden <andrew@andrewhazelden.com>
	- Prepared for inclusion with Reactor.

* v1.11.0 Ultra 2017-11-24 by Andrew Hazelden <andrew@andrewhazelden.com>
	- Added a "Split All Selected Nodes" checkbox to the AskUser dialog. The "Split All Selected Nodes" checkbox allows the Split EXR Ultra script to automatically process and split apart multiple Loader nodes at the same time when you have several Loader nodes selected in the flow area.
	- Added a "Verbose Logging" checkbox to the AskUser dialog. This prints out detailed information to the Console tab about the channel splitting task.
	- Updated the C4D channel code to only be used if the regular exr channel matching process fails
	- Fixed an R/G/B channel matching logic issue
	- Fixed several variable scope issues
	- Updated the logDebug() function to only print output when a debugging state is active
	- Added a logDump() function

* v1.10.0 Ultra 2017-11-23 by Cedric Duriau <duriau.cedric@live.be>
	- Refactored code
	- Split code into functions
	- Improved tool validation
	- Altered input data format for loader generation
	- Implemented logging functions by level

* v1.9.0 Ultra 2017-10-31 by Andrew Hazelden <andrew@andrewhazelden.com>
	- Merged the Tim Little v1.8 revisions with my v1.7.2 revisions to make an "ultra" version that has the best parts of both scripts integrated together. The script works with Fusion (Free) and Fusion Studio v7-9.
	- Added a new "Skip Importing Alpha Channels" option that can be used when you don't want to have the alpha channels loaded by default. This is useful when loading 3D renderings with image based lighting or physical sky backgrounds that have RGB image data in the sky background zone of the scene but a transparent un-premultiplied alpha channel.

* v1.8.0 2017-08-21 by Tim Little <timhlittl@gmail.com> www.littlevfx.com
	- Added a method to handle exr's that utilize a phrase at the end of its channel name (rather than a single character)

* v1.7.2 2017-10-27 by Andrew Hazelden <andrew@andrewhazelden.com> 
	- Replaced the preference writing code so it uses the Fusion native setData() and getData() functions.
	- Updated the AskUser dialog.

* v1.7.1 2017-10-04 by Andrew Hazelden <andrew@andrewhazelden.com> 
	- Updated the script to have cross-platform Fusion 8.2.1 + Fusion 9.0.1 support.
	- The script can now be installed as either a Fusion Comp script (Scripts:/Comp/) that is accessible using the main Fusion menubar's Script > hos_SplitEXR menu item, or as a Fusion tool script (Scripts:/tool/) and accessed by right clicking on a Loader node in the flow area and then selecting the Script > hos_SplitEXR contextual menu item.
	- Improved the Lua script comments to make the program flow easier to understand for new pipeline TDs who need to customize this script in the future.
	- Improved the error handling and added more verbosity to the error messages.
	- Changed the Fusion preference writing path to use the user preference profile folder since the applications folder is usually write locked for non super-users.
	- Updated the "loader = Loader({Clip = loader_clip})" line to use the comp.Loader() prefix to avoid a tool script based error.

* v1.7.0 by S.Neve
	- Added checksum to see which fusion version is running

* v1.6.0 by S.Neve
	- Fixed preference saving, iterating over the table needs to be done using pairs, rather than ipairs

* v1.5.0 by S.Neve
	- Fixed the preference saving on Win 7 and 8. This is the same problem that occurs on all tools that use the script preference saving function this tool uses.
	- Added Fusion 7 support by explicitly using ipairs when iterating table value key pairs.

* v1.4.0 by S.Neve
	- Added grid and tile placement options as per request
	- Added preference writing and loading, so settings are saved between sessions.

* v1.3.0 by S.Neve
	- Changed the new Loader name creation as per request by Alexey D.
	- This needs testing to see everything works.

* v1.2.0 by S.Neve
	- Changed the Loader tool EXR format check, this should have fixed the (strange and random) 'attempt
	to index global tool (a nil value)' error.

* v1.1.0 by S.Neve
	- Expanded the prototype a bit, to handle XYZ channel names aswel.
	- Added menu to handle placement options, later i will add options to handle what to do with which channels.
	- Spaghetti code galore by the way, will fix this with v1.2

* v1.0.0 by S.Neve
	- Initial prototype.
--]]--

VERSION = [[v3.0 "Ultra" (2021-12-10)]]
AUTHOR = [[S.Neve / House of Secrets]]
CONTRIBUTORS = {"Tim Little", "Andrew Hazelden", "Cedric Duriau", "Bryan Ray", "Alexey Bogomolov"
}
CHANNEL_NO_MATCH = "SomethingThatWontMatchHopefully"
CHANNELS_TO_SKIP = {r = true, red = true,
                g = true, green = true,
                b = true, blue = true,
                a = true, alpha = true,
                somethingthatwontmatchhopefully = true}
PLATFORM = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")

comp = fu:GetCurrentComp()


local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 530,230

------------------------------------------------------------------------
-- logging
------------------------------------------------------------------------

function _log(mode, message)
	return string.format("[%s] %s", mode, message)
end

function logError(message)
	print(_log("ERROR", message))
end

function logDebug(message, state)
	if state == 1 or state == true then
		-- Only print the logDebug output when the debugging "state" is enabled
		print(_log("DEBUG", message))
	end
end

function logDump(variable, state)
	if state == 1 or state == true then
		-- Only print the logDump output when the debugging "state" is enabled
		dump(variable)
	end
end

function logWarning(message)
	print(_log("WARNING", message))
end

-------------------------------------------------------------------------------
-- Read a fusion specific preference value. If nothing exists set and return a default value
-- Example: splitDirection = getPreferenceData("hos_SplitEXR.splitDirection", 1, true)
function getPreferenceData(pref, defaultValue, debugPrint)
	-- Choose if you are saving the preference to the comp or to all of fusion
	-- local newPreference = comp:GetData(pref)
	local newPreference = fu:GetData(pref)
    
	if newPreference then
		-- List the existing preference value
		if (debugPrint == true) or (debugPrint == 1) then
			if newPreference == nil then
				print("[Reading " .. tostring(pref) .. " Preference Data] " .. "nil")
			else
				print("[Reading " .. tostring(pref) .. " Preference Data] " .. tostring(newPreference))
			end
		end
	else
		-- Force a default value into the preference & then list it
		newPreference = defaultValue

		-- Choose if you are saving the preference to the comp or to all of fusion
        -- comp:SetData(pref, defaultValue)
		fu:SetData(pref, defaultValue)

		if (debugPrint == true) or (debugPrint == 1) then
			if newPreference == nil then
				print("[Creating " .. tostring(pref) .. " Preference Data] " .. "nil")
			else
				print("[Creating ".. tostring(pref) .. " Preference Entry] " .. tostring(newPreference))
			end
		end
	end

	return newPreference
end


-------------------------------------------------------------------------------
-- Set a fusion specific preference value
-- Example: setPreferenceData("hos_SplitEXR.splitDirection", 1, true)
function setPreferenceData(pref, value, debugPrint)
	-- Choose if you are saving the preference to the comp or to all of fusion
	-- comp:SetData(pref, value)
	fu:SetData(pref, value)

	-- List the preference value
	if (debugPrint == true) or (debugPrint == 1) then
		if value == nil then
			print("[Setting " .. tostring(pref) .. " Preference Data] " .. "nil")
		else
			print("[Setting " .. tostring(pref) .. " Preference Data] " .. tostring(value))
		end
	end
end

function GetLoaderChannels(tool)
	-- Get all loader channel and filter out the ones to skip
	sourceChannels = tool.Clip1.OpenEXRFormat.RedName:GetAttrs().INPIDT_ComboControl_ID
	allChannels = { }
	for i, channelName in pairs(sourceChannels) do
        if not CHANNELS_TO_SKIP[channelName:lower()] then
            table.insert(allChannels, channelName)
        end
	end
	-- sort channel table
	-- sortedChannels = table.sort(allChannels)
	return allChannels
end

function GetChannelData(loaderChannels)
	-- Gets the channels by prefix from given loader channels
	local _channelPrefixSet = {}
	local channelData = {}
	
	for i, channelName in pairs(loaderChannels) do
		-- Get prefix and channel from full channel name
		local prefix, channel = string.match(channelName, "(.+)[.](.+)")
		
		if prefix and channel then
			local channels = {}
			
			-- Check if prefix was already stored in tmp set
			if _channelPrefixSet[prefix] then
				-- Get previously assigned channels of current prefix
				channels = channelData[prefix]
			else
				-- Store prefix
				_channelPrefixSet[prefix] = true
			end
			
			-- Add full channel name to assigned channels of current prefix
			table.insert(channels, channelName)

			-- Store channels for current prefix
			channelData[prefix] = channels
		end
	end
	return channelData
end

function GetLoaderClip(tool)
	local loader_clip = tool.Clip[fu.TIME_UNDEFINED]
	if not loader_clip then
		logError("Loader contains no clips to explore")
		return
	end
    return loader_clip
end

function GetTilesOffset()
    if fu.Version < 16 then
        return 3
    end
    return 2
end

function MatchExt(file, fileType)
	-- Get the file extension
	local ext = string.match(tostring(file), '^.+(%..+)$')

	-- Compare the results
	if ext:lower() == tostring(fileType) then
		return true
    end
    return false
end

function ProcessMultichannel(tool)
    local loaderChannels = GetLoaderChannels(tool)

    -- Debug print the channel list
    logDebug("[EXR Check 3] [Sorted Channel List]", VERBOSE)
    -- logDump(loaderChannels, VERBOSE)

    -- Get list of unique channel prefixes to know how many loaders to create
    local channelData = GetChannelData(loaderChannels)

    -- Debug print the loader node list
    logDebug("[EXR Check 4] [Loader Node List]", VERBOSE)
    -- logDump(channelData, VERBOSE)

    loaders_list = {}
    mergesList = {}
	
	comp:Lock()
	comp:StartUndo('SplitEXR MultiChannel')
	
    -- Update the loader node channel settings
    for prefix, channels in pairs(channelData) do
        -- Debug print the loader list
        logDebug("[EXR Check 5] Loader List " .. prefix, VERBOSE)
        LDR = comp.Loader({Clip = GetLoaderClip(tool)})
        flow = comp.CurrentFrame.FlowView
        local x_pos, y_pos = flow:GetPos(LDR)
        if mergeAll then
            logDebug("Merging Loaders...", VERBOSE)
            MRG = comp:AddTool("Merge", -32768, -32768)
            MRG:ConnectInput("Foreground", LDR)
            table.insert(mergesList, MRG)
        end

        -- Force an initial (invalid) EXR channel name value into the OpenEXRFormat setting
        LDR:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = prefix})
        LDR.Clip1.OpenEXRFormat.RedName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.GreenName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.BlueName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.AlphaName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.XName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.YName = CHANNEL_NO_MATCH
        LDR.Clip1.OpenEXRFormat.ZName = CHANNEL_NO_MATCH

        -- Refresh the OpenEXRFormat setting using real channel name data in a 2nd stage
        for i, channelName in pairs(channels) do
            local channel = string.match(channelName, "[.]([^.]+)$")
            local _channelLower = channel:lower()

            -- Perform a channel match for renderers that use a single letter character at the end of the channel name to define the red/green/blue channels
            -- Example: Vray names its channels like "lighting.R"
            if (_channelLower == "r") or (_channelLower == "red") then
                -- Red channel found
            
                LDR.Clip1.OpenEXRFormat.RedName = channelName
                logDebug("[EXR Check 6] [Red Channel Assignment] " .. channelName, VERBOSE)

            elseif (_channelLower == "g") or (_channelLower == "green") then
                -- Green channel found

                LDR.Clip1.OpenEXRFormat.GreenName = channelName
                logDebug("[EXR Check 6] [Green Channel Assignment] " .. channelName, VERBOSE)
            
            elseif (_channelLower == "b") or (_channelLower == "blue") then
                -- Blue channel found
                
                LDR.Clip1.OpenEXRFormat.BlueName = channelName
                logDebug("[EXR Check 6] [Blue Channel Assignment] " .. channelName, VERBOSE)
            
            elseif (_channelLower == "a") or (_channelLower == "alpha") then
                -- Alpha channel found
                if not skipAlpha then
                    -- Load the regular alpha channel
            
                    LDR.Clip1.OpenEXRFormat.AlphaName = channelName
                    logDebug("[EXR Check 6] [Alpha Channel Assignment] " .. channelName, VERBOSE)
                
                else
                    -- The Skip Importing Alpha Channels checkbox was enabled in the AskUser dialog
                
                    LDR.Clip1.OpenEXRFormat.AlphaName = CHANNEL_NO_MATCH
                    logDebug("[EXR Check 6] [Alpha Channel Assignment] " .. CHANNEL_NO_MATCH, VERBOSE)
                
                end
            elseif (_channelLower == "x") then
                -- X channel found
                
                LDR.Clip1.OpenEXRFormat.RedName = channelName
                logDebug("[EXR Check 6] [X Channel Assignment] " .. channelName, VERBOSE)
           
            elseif (_channelLower == "y") then
                -- Y channel found
               
                LDR.Clip1.OpenEXRFormat.GreenName = channelName
                logDebug("[EXR Check 6] [Y Channel Assignment] " .. channelName, VERBOSE)
           
            elseif (_channelLower == "z") then
                -- Z channel found
               
                LDR.Clip1.OpenEXRFormat.BlueName = channelName
                logDebug("[EXR Check 6] [Z Channel Assignment] " .. channelName, VERBOSE)
           
            else
                ------------------------------------------------------------------------
                -- Check if a Cinema4D (C4D) style EXR channel name is in use
                -- Perform a channel match for renderers that use a phrase at the end of the channel name to define the red/green/blue channels
                -- Example: C4D names its channels like "#0005#diffuse_direct.red"

                -- Create a new empty table
                myTableOfPhrases = {}
                myIndex = 1

                -- Break a channel name string down into individual phrases using Lua's gmatch function and the . delimiter character
                for myPhrase in string.gmatch(channelName, "[^%.]+") do
                    -- Add each phrase to the existing table
                    myTableOfPhrases[myIndex] = myPhrase

                        -- Iterate up the index
                    myIndex = myIndex + 1
                end

                -- Scan through the "myTableOfPhrases" Lua table to find final phrase 
                -- Example: The phrase "red" would be extracted from a "#0005#diffuse_direct.red" channel name.
                tableLength = table.getn(myTableOfPhrases)
                lastItem = myTableOfPhrases[tableLength]

                -- Debug print the C4D channel assignment
                logDebug("[EXR Check 7] [C4D Channel Phrase] " .. tostring(lastItem), VERBOSE)

                if (lastItem == "red") then
                    -- C4D red channel found
                    LDR.Clip1.OpenEXRFormat.RedName = channelName
                    logDebug("[EXR Check 6] [Red Channel Assignment] " .. channelName, VERBOSE)
                elseif (lastItem == "green") then
                    -- C4D green channel found
                    LDR.Clip1.OpenEXRFormat.GreenName = channelName
                    logDebug("[EXR Check 6] [Green Channel Assignment] " .. channelName, VERBOSE)
                elseif (lastItem == "blue") then
                    -- C4D blue channel found
                    LDR.Clip1.OpenEXRFormat.BlueName = channelName
                    logDebug("[EXR Check 6] [Blue Channel Assignment] " .. channelName, VERBOSE)
                elseif (lastItem == "alpha") then
                    -- C4D alpha channel found
                    if (skipAlpha == 0) then
                        -- Load the regular alpha channel
                        LDR.Clip1.OpenEXRFormat.AlphaName = channelName
                        logDebug("[EXR Check 6] [Alpha Channel Assignment] " .. channelName, VERBOSE)
                    else
                        -- the Skip Importing Alpha Channels checkbox was enabled in the AskUser dialog
                        LDR.Clip1.OpenEXRFormat.AlphaName = CHANNEL_NO_MATCH
                        logDebug("[EXR Check 6] [Alpha Channel Assignment] " .. CHANNEL_NO_MATCH, VERBOSE)
                    end
                end
            end
        end
        table.insert(loaders_list, LDR)
    end
    print('total loaders created: ' .. tostring(#loaders_list))

	MoveLoaders(org_x_pos, org_y_pos, loaders_list)
    if mergeAll then
        MoveLoaders(org_x_pos + (1 - splitDirection),
                    org_y_pos + splitDirection * GetTilesOffset(), mergesList)
    end

	comp:Unlock()
	comp:EndUndo()
    comp:SetActiveTool(tool)
end

function ProcessMultipart(tool)
	comp:Lock()
	comp:StartUndo('SplitEXR MultiPart')
	print('splitting multipart file')
	local loaders_list = {}
    local mergesList = {}
	partsTable = tool.Clip1.OpenEXRFormat.Part:GetAttrs().INPIDT_ComboControl_ID
	for i, exr_part in pairs(partsTable) do
		tool.Clip1.OpenEXRFormat.Part = exr_part
		-- if you set mpUseChannelName, the loaders will be named by the first channel name, not by the part name,
		-- since sometimes the channel name is more meaningful.
		if mpUseChannelName then
			channelName = tool.Clip1.OpenEXRFormat.RedName:GetAttrs().INPIDT_ComboControl_ID[2]
			if not CHANNELS_TO_SKIP[channelName:lower()] then
				channelName = string.match(channelName, '(.+)%..+$') or Z
			end
		else
			channelName = exr_part
		end
		logDebug('splitting channel: '.. channelName, VERBOSE)

        if channelName then
            local LDR = comp.Loader({Clip = GetLoaderClip(tool)})
            if mergeAll then
                local x_pos, y_pos = flow:GetPos(LDR)
                logDebug("Merging Loaders...", VERBOSE)
                MRG = comp:AddTool("Merge", -32768, -32768)
                MRG:ConnectInput("Foreground", LDR)
                table.insert(mergesList, MRG)
            end

            LDR:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = channelName})
            LDR.Clip1.OpenEXRFormat.Part = exr_part
            loaders_list[i] = LDR
		end
	end
	if #loaders_list > 0 then
		print('total loaders created: ' .. tostring(#loaders_list))
		MoveLoaders(org_x_pos, org_y_pos, loaders_list)
        tilesOffset = 1
        if tiles then
            tilesOffset = 2
        end
        if mergeAll then
            MoveLoaders(org_x_pos + (1 - splitDirection),
                        org_y_pos + splitDirection * GetTilesOffset(), mergesList)
        end
	end
    comp:Unlock()
	comp:EndUndo()
    comp:SetActiveTool(tool)
end

function getLoader(verbose, tool)
   	-- Process an individual loader node
	-- Get node attributes
  	local attrs = tool:GetAttrs()
    flow = comp.CurrentFrame.FlowView
    org_x_pos, org_y_pos = flow:GetPos(tool)
	-- Ensure node is a loader
	local node_type = attrs.TOOLS_RegID
	if node_type ~= "Loader" then
		logError("Selected tool is not a Loader")
		return
	end
	-- If the Skip Importing Alpha Channels checkbox was enabled
    -- then set the alpha channel to "None" on the orignal Loader node
    local skipAlpha = fu:GetData("SplitEXR.skipAlpha")

    if skipAlpha then
        tool.Clip1.OpenEXRFormat.AlphaName = CHANNEL_NO_MATCH
    end
	-- Ensure loader clip is of format EXR
	local loader_clip_format = attrs.TOOLST_Clip_FormatName[1]

	if loader_clip_format ~= "OpenEXRFormat" then
		logError("Loader is not an EXR file")
		return
	end

	-- Print the Loader attributes
	logDebug("[EXR Check 1] [Loader Node] " .. tostring(loader_clip), verbose)
	logDebug("[EXR Check 2] [Loader Node Atttributes]", verbose)
	-- logDump(attrs, verbose)
	-- Filter out None,R,G,B and A as these are already used by the original Loader
	-- If the Skip Importing Alpha Channels checkbox was enabled in the user dialog,
    -- then keep the alpha channel separate as an extra loader item
    if tool.Clip1.OpenEXRFormat.Part then
		ProcessMultipart(tool)
	else
		ProcessMultichannel(tool)
    end
end

function MoveLoaders(org_x_pos, org_y_pos, loaders)
    -- Used to add to the placement offset for the tool in the flow
    count = 1
    -- Work out the node spacing offsets in the flow area
    local y_pos_add = 1
    if tiles then
        y_pos_add = GetTilesOffset()
    end
    for i, ldr in pairs(loaders) do
        flow:SetPos(ldr, org_x_pos + (count * splitDirection), org_y_pos + (y_pos_add * count * (1 - splitDirection)))
        count = count + 1
        if grid > 0 then
            if count - 1 >= grid then
                count = 1
                org_y_pos = org_y_pos + (y_pos_add * splitDirection)
                org_x_pos = org_x_pos + (1 * (1-splitDirection))
            end
        end
    end
end

------------------------------------------------------------------------
-- Main UI
------------------------------------------------------------------------
function showUI()
    -- Keep track of exec time
    local t_start = os.time()
    -- Read the updated preferences
    mergeCheck = true
    VERBOSE = getPreferenceData("SplitEXR.verbose", 0, false)
    splitAllSelectedNodes = getPreferenceData("SplitEXR.splitAllSelectedNodes", 1, VERBOSE)
    splitDirection = getPreferenceData("SplitEXR.splitDirection", 0, VERBOSE)
    createComboBox = getPreferenceData("SplitEXR.createComboBox", 0, VERBOSE)
    skipAlpha = getPreferenceData("SplitEXR.skipAlpha", 0, VERBOSE)
    forceTilesPref = fu:GetPrefs("Comp.FlowView.ForceSource")
    forceTile = 0
    if forceTilesPref then
        forceTile = 1
    end
    tiles = getPreferenceData("SplitEXR.tiles", forceTile, VERBOSE)
    grid = getPreferenceData("SplitEXR.grid", 0, VERBOSE)
    mergeAll = getPreferenceData('SplitEXR.mergeAll', 0, VERBOSE)
    mpUseChannelName = getPreferenceData('SplitEXR.mpUseChannelName', 0, VERBOSE)

    win = disp:AddWindow({
        ID = "SplitEXR",
        TargetID = "SplitEXR",
        WindowTitle = "[Split EXR] " .. VERSION,
        Geometry = {500, 500, width, height},
        ui:VGroup {
            ui:Label{
                Weight = 0,
                Text = 'This script will split a multi-channel or multi-part EXR image out into Loaders'
            },
            ui:HGroup{
                Weight = 0,
                ui:Label{
                    Weight = 0.3,
                    Text = "Place nodes: ",
                },
                ui:ComboBox {
                    Weight = 0.7,
                    ID = 'layoutComboBox',
                    Value = tonumber(splitDirection)
                },
            },
            ui:HGroup{
                Weight = 0,
                ui:Label{
                    Weight = 0.3,
                    Text = "Create: ",
                },
                ui:ComboBox {
                    Weight = 0.7,
                    ID = 'createComboBox',
                    Value = tonumber(createComboBox)
                },
            },            ui:HGroup{
                Weight = 0,
                ui:Label{
                    Weight = 0.3,
                    Text = "Grid Placement: ",
                },
                ui:Slider{
                    Weight = 0.6,
                    ID = 'GridSlider',
                    Events = {SliderMoved = true, ValueChanged = true, SliderPressed = true}
                },
                ui:LineEdit{
                    Weight = 0.1,
                    ID='GridLineEdit',
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true }
                },
            },

            ui:VGroup{
                Weight = 0,
                ui:HGroup{
                    ui:CheckBox{
                        ID = "splitAllSelectedNodes",
                        Text = "Split All Selected Nodes",
                        Checked = splitAllSelectedNodes or false,
                    },
                    ui:CheckBox{
                        ID = "mpUseChannelName",
                        Text = "Multipart Uses Channel Name",
                        Checked = mpUseChannelName or false,
                    },
                },
                ui:HGroup{
                    ui:CheckBox{
                        ID = "skipAlpha",
                        Text = "Skip Importing Alpha Channels",
                        Checked = skipAlpha or false,
                    },
                    ui:CheckBox{
                        ID = "verboseCheckBox",
                        Text = "Verbose Logging",
                        Checked = VERBOSE or false,
                    },
                },
                ui:HGroup{
                    ui:CheckBox{
                        ID = "showTiles",
                        Text = "Source Tiles Enabled",
                        Checked = tiles or false,
                    },
                    ui:CheckBox{
                        ID = "mergeAll",
                        Text = "Merge Loaders",
                        Checked = mergeAll or false,
                        Visible = mergeCheck,
                    },
                },
            },
            ui:HGroup{
                Weight = 0,
                ui:Button{
                    ID = 'runButton', Text = 'Run',
                },
                ui:Button{
                    ID = 'runCloseButton', Text = 'Run and Close',
                },
                ui:Button{
                    ID = 'cancelButton', Text = 'Cancel',
                },
            },
        },
    })

    function win.On.SplitEXR.Close(ev)
        disp:ExitLoop()
    end
    function win.On.cancelButton.Clicked(ev)
        disp:ExitLoop()
    end

    itm = win:GetItems()

    itm.layoutComboBox:AddItem('Vertically')
    itm.layoutComboBox:AddItem('Horizontally')
    itm.layoutComboBox:SetCurrentIndex(layoutIndex)

    itm.createComboBox:AddItem('Loaders')
    itm.createComboBox:AddItem('ReadEXR Fuses')
    itm.createComboBox:SetCurrentIndex(createComboBox)

    itm.GridSlider.Value = grid or 0
    if itm.mergeAll.Checked then
        itm.GridSlider.Value = 0
    end
    itm.GridSlider.Minimum = 0
    itm.GridSlider.Maximum = 25
    -- set step by clicking on the slider
    itm.GridSlider:SetPageStep(3)

    itm.GridLineEdit.Text = tostring(itm.GridSlider:GetSliderPosition())
    itm.GridLineEdit:SetDragEnabled(true)

    -- Read the Placement, Grid Placement, and Source Tiles settings from the UI
    splitDirection = itm.layoutComboBox:GetCurrentIndex()
    grid = itm.GridSlider.Value
    VERBOSE = itm.verboseCheckBox.Checked
    splitAllSelectedNodes = itm.splitAllSelectedNodes.Checked
    skipAlpha = itm.skipAlpha.Checked
    tiles = itm.showTiles.Checked
    mergeAll = itm.mergeAll.Checked
    mpUseChannelName = itm.mpUseChannelName.Checked


    function win.On.splitAllSelectedNodes.Clicked(ev)
        splitAllSelectedNodes = itm.splitAllSelectedNodes.Checked
        setPreferenceData("SplitEXR.splitAllSelectedNodes", splitAllSelectedNodes, VERBOSE)
    end
    function win.On.skipAlpha.Clicked(ev)
        skipAlpha = itm.skipAlpha.Checked
        setPreferenceData("SplitEXR.skipAlpha", skipAlpha, VERBOSE)
    end
    function win.On.mpUseChannelName.Clicked(ev)
        mpUseChannelName = itm.mpUseChannelName.Checked
        setPreferenceData("SplitEXR.mpUseChannelName", mpUseChannelName, VERBOSE)
    end
    function win.On.showTiles.Clicked(ev)
        tiles = itm.showTiles.Checked
        setPreferenceData("SplitEXR.tiles", tiles, VERBOSE)
    end
    function win.On.verboseCheckBox.Clicked(ev)
        VERBOSE = itm.verboseCheckBox.Checked
        setPreferenceData("SplitEXR.verbose", itm.verboseCheckBox.Checked, VERBOSE)
    end
    function win.On.mergeAll.Clicked(ev)
        mergeAll = itm.mergeAll.Checked
        setPreferenceData("SplitEXR.mergeAll", mergeAll, VERBOSE)
        if mergeAll then
            grid = 0
            itm.GridSlider.Value = grid
            itm.GridLineEdit.Text = tostring(grid)
            setPreferenceData("SplitEXR.grid", grid, VERBOSE)
        end
    end

    function win.On.GridSlider.SliderPressed(ev)
        -- Reset slider with ALT pressed
        if ev.modifiers.AltModifier == true then
            itm.GridLineEdit.Text = "0"
            itm.GridSlider.Value = 0
        end
    end

    function win.On.createComboBox.CurrentIndexChanged(ev)
        createComboBox = itm.createComboBox:GetCurrentIndex()
        setPreferenceData("SplitEXR.createComboBox", createComboBox, VERBOSE)
    end

    function win.On.layoutComboBox.CurrentIndexChanged(ev)
        splitDirection = itm.layoutComboBox:GetCurrentIndex()
        setPreferenceData("SplitEXR.splitDirection", splitDirection, VERBOSE)
    end

    function win.On.GridLineEdit.ReturnPressed(ev)
        num = tonumber(itm.GridLineEdit.Text)
        print(num)
        if num == nil then
            dump("not a number!")
            return
        end
        itm.GridSlider.Value = tonumber(num)
    end

    function win.On.GridSlider.ValueChanged(ev)
        grid = itm.GridSlider.Value
        if grid > 0 then
            mergeAll = false
            itm.mergeAll.Checked = mergeAll
            setPreferenceData("SplitEXR.mergeAll", mergeAll, VERBOSE)
        end
        itm.GridLineEdit.Text = tostring(ev.Value)
        logDebug('Slider Value: ' .. tostring(ev.Value), VERBOSE)
        setPreferenceData("SplitEXR.grid", itm.GridSlider.Value, VERBOSE)
    end

    function win.On.GridSlider.SliderMoved(ev)
        itm.GridLineEdit.Text = tostring(ev.Value)
        logDebug('Slider Value: ' .. tostring(ev.Value), VERBOSE)
    end

    function process()
        if splitAllSelectedNodes == 0 then
            local tool = comp.ActiveTool
            if not tool then
                logError("The \"Active Tool\" selection is empty. Please select a node before running this script again.\n\nNote: If you want to process multiple selected nodes at the same time please enable the \"Split All Selected Nodes\" option in the dialog.\n")
                return
            end
            if tool.ID == "MediaIn" then
                print('Davinci Resolve MediaIn nodes are not supported by SplitEXR yet. Try Loader instead')
                return
            end
            -- Process only the first actively selected node
            getLoader(verbose, tool)
        else
            local toolList = comp:GetToolList(true, "Loader")

            if table.getn(toolList) == 0 then
                logError("The \"tool\" selection is empty. Please select a node before running this script again.")
                return
            end
            -- Iterate through each of the selected loader nodes
            for i, tool in pairs(toolList) do
                getLoader(verbose, tool)
            end
        end

    end

    function win.On.runButton.Clicked(ev)
        print("Run")
        process()
    end
    function win.On.runCloseButton.Clicked(ev)
        print("Run and close")
        process()
        disp:ExitLoop()
    end

    win:Show()
    disp:RunLoop()
    win:Hide()

    -- Print estimated time of execution in seconds
    print(string.format("[Time run] %.2f s", os.difftime(os.time(), t_start)))

    print("[Done]")
end




-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------
function main()
	
    -- Check if Fusion is running
	if not fusion then
		logError("[Error] This is a Blackmagic Fusion lua script, it should be run from within Fusion.")
	end
    comp = fusion:GetCurrentComp()

	print(string.format("[Split EXR] %s", VERSION))
	print(string.format("[Created By] %s", AUTHOR))
	print(string.format("[With Contributions From] %s", table.concat(CONTRIBUTORS, ", ")))
	print("\n")

    win = ui:FindWindow("SplitEXR")

    if win then
        win:Raise()
        win:ActivateWindow()
    else
        showUI()
    end
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------


-- Run main
main()
