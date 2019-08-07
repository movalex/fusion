--[[--
Archive Composition v2.3.1 2018-02-21 
by Isaac Guenard and Sean Konrad

-------------------------------------------------------------------------------
Description
-------------------------------------------------------------------------------

This script scans every loader and saver for clips, then copies those clips to a specified destination. Fonts used in Text tools are also included. 

Size is pre-calculated so that you can be certain enough space exists for the composition and footage at the destination before proceeding.

-------------------------------------------------------------------------------
Fusion Support
-------------------------------------------------------------------------------
This script has been tested and works with Fusion v7 to v9. It runs on Windows, Mac, and Linux.

-------------------------------------------------------------------------------
Installation
-------------------------------------------------------------------------------
Copy the script to your Fusion user preferences "Scripts:/Comp/" folder.

-------------------------------------------------------------------------------
Version History
-------------------------------------------------------------------------------

* 2003-06-04 by Isaac Guenard, Sean Konrad
	- Initial Release

* 2005-09-27 by Isaac Guenard, Sean Konrad
	- Updated for Fusion 5 compatibility

* 2008-10-04 by Isaac Guenard, Sean Konrad
	- Fixed bugs in handling of MOV files and stills. Added support for archiving fonts and fbx meshes

* 2016-12-19 by Andrew Hazelden (andrew@andrewhazelden.com)
	- We Suck Less Thread (https://www.steakunderwater.com/wesuckless/viewtopic.php?f=6&t=1111)
	- Changed TIME_UNDEFINED to fu.TIME_UNDEFINED
	- Changed the direxists(dir) function to work with Fusion 8
	- Changed the GetNextCompositionSave() function to work Fusion 8 on macOS/Windows/Linux
	- Changed the folder paths and directory creation code to be cross platform compatible
	- Added a createdir(dir) function
	- Added a fu_major_version variable
	- Added an operating system platform check and an os_separator variable
	- Added Alembic mesh archiving support

* v2.1 2017.06.12 by Pieter Van Houte
	- Replaced the eyeon.SV_GetFrames() function from from bmd.scriptlib with an inline SV_GetFrames() function
	- Changed the SV_GetFrames function to work with Fusion 8+
	
* v2.2 2018-01-06 by Andrew Hazelden (andrew@andrewhazelden.com)
	- Updated for Fusion 9 compatibility
	- Added audio archiving support from the Saver node (SoundFilename), SuckLessAudio Modifier Fuse, and Fusion timeline (COMPS_AudioFilename)
	- Added support for archiving the new movie formats available with Fusion 9+ and the FFmpeg library.
	- Replaced the bmd.scriptlib bmd.pathIsMovieFormat() function from bmd.scriptlib with an inline pathIsMovieFormat().
	- Updated the PathMap resolving on Alembic meshes, FBX meshes, and audio files
	- Added a pathIsAudioFormat() function that could be used in the future
	- Refactored the string concatenating ".." code to improve formatting

* v2.3 2018-02-19 by Andrew Hazelden (andrew@andrewhazelden.com)
 - Added improved error handling so nil values are ignored gracefully when accessing COMPS_AudioFilename.

* v2.3.1 2018-02-21 by Andrew Hazelden (andrew@andrewhazelden.com)
	- Updated the error handling of frame padding so nil values are processed gracefully
	- Updated the way saver nodes are processed when the "Include Audio" checkbox is active
	- Updated the way saver nodes are processed to add support for Saver nodes with PathMaps
	- Added an ArchiveLog.txt logfile that saves the Console tab error log messages along with a date and time stamp to the Archive Composition output folder.
	- Added a "Client Notes for ArchiveLog.txt" text field to the AskUser dialog. That textual message is saved into to the ArchiveLog.txt file.
	- Added an "Open Archive Composition Folder" checkbox to the AskUser dialog that will open the output folder up in a desktop folder browsing window.
	- Added the ability to save/restore the Archive Composition checkbox states in the AskUser dialog.

-------------------------------------------------------------------------------
Wishlist
-------------------------------------------------------------------------------
IFL sequence processing with individual frame copying support
standalone version?
make prints support multiframe better
saver needs to handle multiframe formats better (currently prints 1 frame)
output a todo script instead of immediate mode copy
Make it ignore orphaned Loaders?
Handle Fuses and Plugins
Maybe even handle imported camera paths?
preserve original file structure
make a trimmed files only mode
compression option for zip files

------------------------------------------------------------------------------
--]]--


----------------------------------------------------------------------
-- Exit if this is not a composition script
----------------------------------------------------------------------
if composition == nil then
	dprintf("This is a composition script, it should be run from within the Fusion interface.\n")
	exit()
end

dprintf = function(fmt, ...)
	-- Display the debug output in the Console tab
	comp:Print(fmt:format(...))
	
	local archive_log_path = comp:MapPath("Temp:/ArchiveLog.txt")
	log_fp, err = io.open(archive_log_path, "a")
	if err then
		comp:Print("[Log Error] Could not write to the file \"" .. archive_log_path .. "\"\n")
	else
		time_stamp = os.date('[%Y-%m-%d|%I:%M:%S %p] ')
		log_fp:write(time_stamp)
		log_fp:write(fmt:format(...))
		log_fp:close()
	end
end

-- Clear the log file at the start of the Reactor session
local archive_log_path = comp:MapPath("Temp:/ArchiveLog.txt")
local log_start_fp, err = io.open(archive_log_path, "w")
if err then
	comp:Print("[Log Error] Could not write to the file \"" .. archive_log_path .. "\"\n")
else
	-- time_stamp = os.date('[%Y-%m-%d|%I:%M:%S %p] ')
	-- log_start_fp:write(time_stamp .. "\n")
	log_start_fp:write("")
	log_start_fp:close()
end

----------------------------------------------------------------------
-- Find out the current operating system platform. (Andrew Hazelden Edit)
-- The platform local variable should be set to either 'Windows', 'Mac', or 'Linux'.
----------------------------------------------------------------------
-- Find out if we are running Fusion 7 / 8 / 9
local fu_major_version = math.floor(tonumber(eyeon._VERSION))

local platform = ''
local os_separator = ''
if string.find(comp:MapPath('Fusion:\\'), 'Program Files', 1) then
	-- Check if the OS is Windows by searching for the Program Files folder
	platform = 'Windows'
	os_separator = '\\'
elseif string.find(comp:MapPath('Fusion:\\'), 'PROGRA~1', 1) then
	-- Check if the OS is Windows by searching for the Program Files folder
	platform = 'Windows'
	os_separator = '\\'
elseif string.find(comp:MapPath('Fusion:\\'), 'Applications', 1) then
	-- Check if the OS is Mac by searching for the Applications folder
	platform = 'Mac'
	os_separator = '/'
else
	platform = 'Linux'
	os_separator = '/'
end

------------------------------------------------------------------------------
--			DECLARE FUNCTIONS																										--
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- FUNCTION SetPreferenceData()
-- Set a fusion specific preference value
-- Example: SetPreferenceData('EyeonLegacy.ArchiveComposition.fbx', 1, true)
------------------------------------------------------------------------------
function SetPreferenceData(pref, value, status)
	-- comp:SetData(pref, value)
	fusion:SetData(pref, value)

	-- List the preference value
	if status == 1 or status == true then
		if value == nil then
			print('[Setting ' .. pref .. ' Preference Data] ' .. 'nil')
		else
			print('[Setting ' .. pref .. ' Preference Data] ' .. value)
		end
	end
end

------------------------------------------------------------------------------
-- FUNCTION GetPreferenceData()
-- Read a fusion specific preference value. If nothing exists set and return a default value
-- Example: GetPreferenceData('EyeonLegacy.ArchiveComposition.fbx', 1, true)
------------------------------------------------------------------------------
function GetPreferenceData(pref, defaultValue, status)
	-- local newPreference = comp:GetData(pref)
	local newPreference = fusion:GetData(pref)
	if newPreference then
		-- List the existing preference value
		if status == 1 or status == true then
			if newPreference == nil then
				print('[Reading ' .. pref .. ' Preference Data] ' .. 'nil')
			else
				print('[Reading ' .. pref .. ' Preference Data] ' .. newPreference)
			end
		end
	else
		-- Force a default value into the preference & then list it
		newPreference = defaultValue
        -- comp:SetData(pref, defaultValue)
		fusion:SetData(pref, defaultValue)

		if status == 1 or status == true then
			if newPreference == nil then
				print('[Creating ' .. pref .. ' Preference Data] ' .. 'nil')
			else
				print('[Creating '.. pref .. ' Preference Entry] ' .. newPreference)
			end
		end
	end

	return newPreference
end

------------------------------------------------------------------------------
-- FUNCTION pathIsMovieFormat()
-- Checks if a file is a movie format
-- Adds support for the new Fusion 9+ movie formats that are not found in the standard bmd.scriptlib version of the bmd.pathIsMovieFormat() function.
------------------------------------------------------------------------------

function pathIsMovieFormat(path)
    local extension = eyeon.parseFilename(path).Extension:lower()
    -- print(extension)
	if extension ~= nil then
        if  ( extension == ".3gp" ) or
            ( extension == ".aac" ) or
            ( extension == ".aif" ) or
            ( extension == ".aiff" ) or
            ( extension == ".avi" ) or
            ( extension == ".dvs" ) or
            ( extension == ".fb" ) or
            ( extension == ".flv" ) or
            ( extension == ".m2ts" ) or
            ( extension == ".m4a" ) or
            ( extension == ".m4b" ) or
            ( extension == ".m4p" ) or
            ( extension == ".mkv" ) or
            ( extension == ".mov" ) or
            ( extension == ".mp3" ) or
            ( extension == ".mp4" ) or
            ( extension == ".mts" ) or
            ( extension == ".mxf" ) or
            ( extension == ".omf" ) or
            ( extension == ".omfi" ) or
            ( extension == ".qt" ) or
            ( extension == ".stm" ) or
            ( extension == ".tar" ) or
            ( extension == ".vdr" ) or
            ( extension == ".vpv" ) or
            ( extension == ".wav" ) or
            ( extension == ".webm" ) then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------
-- FUNCTION pathIsAudioFormat()
-- Checks if a file is an audio format
------------------------------------------------------------------------------

function pathIsAudioFormat(path)
    local extension = eyeon.parseFilename(path).Extension:lower()
	if extension ~= nil then
            if	( extension == ".aac" ) or
				( extension == ".aif" ) or
				( extension == ".aiff" ) or
				( extension == ".m4a" ) or
				( extension == ".mp3" ) or
				( extension == ".wav" ) then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------
-- FUNCTION createdir()
-- Creates a new folder using the operating system provided native calls
------------------------------------------------------------------------------

function createdir(dir)
	if platform == 'Windows' then
		os.execute('mkdir "' .. dir ..'"')
	else
		-- Mac and Linux
		os.execute('mkdir -p "' .. dir ..'"')
	end
end
		
------------------------------------------------------------------------------
-- FUNCTION direxists()
--
-- Masks the real readdir, handles the path to eliminate trailing \ 
-- deals with files named same as directory trying to create
------------------------------------------------------------------------------
function direxists(dir)
	local val = false
	local x = string.sub(dir, -1, -1)
	
	if (x == "\\") or (x == "/") then
		str = string.sub(dir, 1, -2)
	else 
		str = dir
	end
	
	-- Fusion 8.x compatibility fix: Commented out the lua-fs related readdir() call
	-- local res = readdir(str)
	-- if res then val = res[1].IsDir end
	
	if fu_major_version >= 8 then
		-- The script is running on Fusion 8+ so we will use the fileexists command
		if eyeon.fileexists(dir) then
			val = true
		end
	else
		-- The script is running on Fusion 6/7 so we will use the direxists command
		if eyeon.direxists(dir) then
			val = true
		end
	end
	
	return val
end

------------------------------------------------------------------------------
-- FUNCTION filesize()
-- Return the size of the file named in the src_path string, or 0 and an error
------------------------------------------------------------------------------
function filesize(src_path)
	src, errMsg = io.open(comp:MapPath(src_path), "rb")
	if src == nil then
		return 0, "SOURCE : " .. errMsg
	end
	local size = src:seek("end")
	src:close()
	
	return size, errMsg
end

------------------------------------------------------------------------------
-- FUNCTION compare_clip()
-- Used by buildClipList() to ensure that loaders pointing at the same media are not
-- added to the cliplist twice. 
-- WARNING requires global variable 'cliplist'
------------------------------------------------------------------------------
function compare_clip(seq)
	for index, item in pairs(cliplist) do
		if item.Seq.Path == seq.Path then
			if item.Multiframe == 1 then
				if item.Seq.FullName == seq.FullName then
					return index
				end
			else
				if item.Seq.CleanName .. item.Seq.Extension == seq.CleanName .. seq.Extension then
					return index
				end
			end
		end
	end
	return nil
end

------------------------------------------------------------------------------
-- FUNCTION buildClipList()
-- Assembles a table of values useful for manipulating every clip in the composition
-- WARNING requires global variable 'cliplist'
------------------------------------------------------------------------------
function buildClipList(ld)
	local attrs = ld:GetAttrs()
	local isduplicate
	
	-- What if we wanted to archive even passed through tools?
	-- The tool is passed through
	if attrs.TOOLB_PassThrough == true then
		return false
	end
	
	-- The loader not is set up
	if attrs.TOOLST_Clip_Name == nil then
		return false
	end
	
	-- If its a loader
    -- for i = 1, table.getn(attrs.TOOLST_Clip_Name) do
		local seq = eyeon.parseFilename(composition:MapPath(attrs.TOOLST_Clip_Name[1]))
		clip = {}
		clip.ClipName		= attrs.TOOLST_Clip_Name[1]
		clip.Number			= seq.Number
		clip.ImportMode     = attrs.TOOLIT_Clip_ImportMode[1]
		clip.Start			= attrs.TOOLNT_Clip_Start[1]
		clip.TrimIn			= attrs.TOOLIT_Clip_TrimIn[1]
		clip.TrimOut		= attrs.TOOLIT_Clip_TrimOut[1]
		clip.Loader			= ld
		
		-- Do we have this clip already?
		isduplicate = compare_clip(seq)

		if isduplicate == nil then
			files = {}
			files.Seq						= seq
			files.InitialFrame	= attrs.TOOLIT_Clip_InitialFrame[1]
			files.Length				= attrs.TOOLIT_Clip_Length[1]
			files.Multiframe		= attrs.TOOLBT_Clip_IsMultiFrame[1]
			files.Clip				= {clip}
			table.insert(cliplist, files)
		else
			table.insert(cliplist[isduplicate].Clip, clip)
		end
    -- end
    return
end


function GetNextCompositionSave()
	usual_path = string.lower(fusion:MapPath("Comps:" .. os_separator))
	x, y = string.find(usual_path, ":")
	
	if x == nil then
		-- May not be a valid path, or may be a unc name
		if fu_major_version >= 8 then
			-- The script is running on Fusion 8+ so we will use the fileexists command
			if eyeon.fileexists(usual_path) then
				path = usual_path
			end
		else
			-- The script is running on Fusion 6/7 so we will use the direxists command
			if eyeon.direxists(usual_path) then
				path = usual_path
			end
		end
		
		-- Fallback to using the user's home folder if the absolute path doesn't exist
		if path == nil then
			if platform == 'Windows' then
				path = os.getenv("USERPROFILE") .. os_separator .. string.sub(usual_path, x)
			else
				 -- macOS/ Linux
				 path = os.getenv("HOME") .. os_separator .. string.sub(usual_path, x)
			end
		end
	else
		-- May be a virtual using fusion: or temp:
		virtual = string.sub(usual_path, 1, x)
		
		if virtual == "fusion:" then
			path = getfilepath(fusion:GetAttrs().FUSIONS_FileName) .. string.sub(usual_path, x+1)
		elseif virtual == "temp:" then
			if platform == 'Windows' then
				path = os.getenv("TEMP") .. os_separator .. string.sub(usual_path, x+1)
			else
				-- macOS/ Linux	 
				-- note: $TMPDIR has a trailing slash built in like /var/folders/h9/y47405113bqb9v343fl5rxlr0000gn/T/
				path = os.getenvx("TMPDIR") .. string.sub(usual_path, x+1)
			end
		else
			path = usual_path
		end
	end

	return path .. composition:GetAttrs().COMPS_Name .. ".comp"
end


------------------------------------------------------------------------------
-- SV_GetFrames(sv)
--
-- This function takes a Saver and returns a table containing the names of 
-- the frames the saver will actually output. If the tool provided is not a 
-- saver or the saver has never been set up then the return value is nil.
--
------------------------------------------------------------------------------
function SV_GetFrames(sv)
	local fla = sv.Composition:GetAttrs()
	
	 if sv.ID ~= "Saver" then
		return nil, "The tool " .. sv.Name .. " is not a Saver tool."
	end
	
	if sv.Normal[fu.TIME_UNDEFINED] == 1 then
		return nil, sv.Name .. " is set to 2:3 pulldown. This function does not support pulldown."
	end
	
	-- Its safe to assume [0] for Clipname since savers have no cliplists
	local sv_file = sv.Clip[0]

	if sv_file == "" then
		return nil, sv.Name .. " does not yet have a filename to save to."
	end
	
	-- Multiframe clips only have one filename
	if pathIsMovieFormat(sv.Clip[0]) == true then
		return {sv_file}
	end
	
	local seq = eyeon.parseFilename(sv_file)
	
	-- Saver has a control to force the starting sequence number.
	if sv.SetSequenceStart[fu.TIME_UNDEFINED] == 0 then
		start = fla.COMPN_RenderStart
	else
		start = sv.SequenceStartFrame[fu.TIME_UNDEFINED] 
					+ fla.COMPN_RenderStart 
					- fla.COMPN_GlobalStart
	end
	
	local length = fla.COMPN_RenderEnd - fla.COMPN_RenderStart

	if seq.Padding == nil then
		 -- Never rendered, no numbering provided assume default fusion padding
		seq.Padding = 4
	end
		
	local files = {}
	for i = start, start + length do
			-- PathMap process each of the saver node output filenames
		 table.insert(files, comp:MapPath(seq.Path .. seq.CleanName .. string.format("%0" .. seq.Padding .. "d", i) .. seq.Extension))
	end
	return files
end

------------------------------------------------------------------------------
-- Find out the current directory from a file path
------------------------------------------------------------------------------
function Dirname(mediaDirName)
	return mediaDirName:match('(.*' .. os_separator .. ')')
end

------------------------------------------------------------------------------
-- Open a folder window up using your desktop file browser
------------------------------------------------------------------------------
function OpenDirectory(mediaDirName)
	command = nil
	dir = Dirname(mediaDirName)

	if platform == "Windows" then
		-- Running on Windows
		command = 'explorer "' .. dir .. '"'
		
		print("[Launch Command] ", command)
		os.execute(command)
	elseif platform == "Mac" then
		-- Running on Mac
		command = 'open "' .. dir .. '" &'

		print("[Launch Command] ", command)
		os.execute(command)
	elseif platform == "Linux" then
		-- Running on Linux
		command = 'nautilus "' .. dir .. '" &'

		print("[Launch Command] ", command)
		os.execute(command)
	else
		print("[Platform] ", platform)
		print("There is an invalid platform defined in the local platform variable at the top of the code.")
	end
end

------------------------------------------------------------------------------
-- MAIN BODY
------------------------------------------------------------------------------
function main()
	-- Keep track of exec time
	local t_start = os.time()

	total_size	= 0
	size		= 0
	badframe	= {}
	cliplist	= {}
	errText		= ""

	------------------------------------------------------------------------------
	-- If the composition is not saved, offer a chance to save the composition, or exit
	------------------------------------------------------------------------------
	while composition:GetAttrs().COMPS_FileName == "" do
		ret = composition:AskUser("Error: Comp not saved!", {
			{"save_path", Name = "save composition to", "FileBrowse", Default = GetNextCompositionSave(), Save = true},
			{"description", "Text", Lines = 5, Default = "Please save the composition before running this script. You can use the path dialog above to save the composition, or Cancel to exit.", ReadOnly = true, Wrap = true}
			})
		if ret == nil then
			return
		else
			composition:Save(ret.save_path)
		end
	end

	lds = comp:GetToolList(false, "Loader")
	svs = comp:GetToolList(false, "Saver")
	txt = comp:GetToolList(false, "TextPlus")
	txt3d = comp:GetToolList(false, "Text3D")
	fbx = comp:GetToolList(false, "SurfaceFBXMesh")
	abc = comp:GetToolList(false, "SurfaceAlembicMesh")
	snd = comp:GetToolList(false, "Fuse.SuckLessAudio")
    luts = comp:GetToolList(false, "FileLUT")

	------------------------------------------------------------------------------
	-- Allow the user to choose initial options for the script, including
	-- pre-calculate filesize for total copy, and to select whether savers are included
	------------------------------------------------------------------------------
	
	-- Restore the previous AskUser dialog settings from the "Profile:/Fusion.prefs" file
	printStatus = false
	analyzeChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.analyze', 1, printStatus)
	saversChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.savers', 1, printStatus)
	fbxChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.fbx', 1, printStatus)
	abcChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.abc', 1, printStatus)
	audioChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.audio', 1, printStatus)
	fontsChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.fonts', 1, printStatus)
	openFolderChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.openFolder', 1, printStatus)
	lutsChk = GetPreferenceData('EyeonLegacy.ArchiveComposition.luts', 1, printStatus)
	
	-- Show the AskUser Dialog
	init = composition:AskUser("Archive Composition", {
		{"analyze", Name = "Calculate Total Size", "Checkbox", Default = analyzeChk, NumAcross = 2},
		{"savers", Name = "Include Savers", "Checkbox", Default = saversChk, NumAcross = 2},
		{"fbx", Name = "Include FBX", "Checkbox", Default = fbxChk, NumAcross = 2},
		{"abc", Name = "Include Alembic", "Checkbox", Default = abcChk, NumAcross = 2},
		{"audio", Name = "Include Audio", "Checkbox", Default = audioChk, NumAcross = 2},
		{"fonts", Name = "Include Fonts", "Checkbox", Default = fontsChk, NumAcross = 2},
		{"luts", Name = "Include LUTs", "Checkbox", Default = lutsChk, NumAcross = 2},
		{"openFolder", Name = "Open Archive Composition Folder", "Checkbox", Default = openFolderChk, NumAcross = 1},
		{"note", Name = "Client Notes", "Text", Default ="", Wrap = true, Lines = 4},
		{"instructions", Name = "Instructions", "Text", Default ="This script will collect all the clips used by your composition into folders beneath a single root directory. A copy of the composition will also be saved in the destination, with all loaders pointing to the new clip locations.\n\nThe script will calculate total file sizes before copying so that you can ensure enough space is available at the destination. You may disable the filesize pass by deselecting the checkbox above.", Wrap = true, Lines = 12, ReadOnly = true}
		})

	if init == nil then return end
	
	-- Save the latest AskUser dialog settings into the "Profile:/Fusion.prefs" file
	SetPreferenceData('EyeonLegacy.ArchiveComposition.analyze', init.analyze, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.savers', init.savers, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.fbx', init.fbx, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.abc', init.abc, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.audio', init.audio, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.fonts', init.fonts, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.luts', init.luts, printStatus)
	SetPreferenceData('EyeonLegacy.ArchiveComposition.openFolder', init.openFolder, printStatus)
	
	------------------------------------------------------------------------------
	-- LOADERS CLIPLIST
	--
	-- Assemble the loader cliplist
	------------------------------------------------------------------------------
	for i, ld in pairs(lds) do
		 buildClipList(ld)
	end

	------------------------------------------------------------------------------
	-- SAVERS CLIPLIST
	--
	-- Assemble the saver cliplist. If savers are not included then we just have an empty table
	------------------------------------------------------------------------------
	err = ""
	sv_cliplist = {}

	if init.savers == 1 then
		for i, sv in pairs(svs) do
			files, errText = SV_GetFrames(sv)
			if (files == nil) or (table.getn(files) == 0) then 
				err = err .. errText .. "\n"
			else
				table.insert(sv_cliplist, {sv, files})
			end
		end
	end

	if err ~= "" then 
		ret = composition:AskUser("Warning", {
		{"description", "Text", Lines = 10, Default = "One or more Saver tools will be ignored. Tool names and reasons are listed below. Click OK to continue or Cancel to exit the script.\n\n" .. err, ReadOnly = true, Wrap = true}
		})
		if ret == nil then return end
	end
	err = ""
	errText = ""

	------------------------------------------------------------------------------
	-- LUTS LIST
	------------------------------------------------------------------------------
    luts_list = {}

    if init.luts == 1 and table.getn(luts) > 0 then
        for i, lut in pairs(luts) do
            if not luts_list[composition:MapPath(lut.LUTFile[fu.TIME_UNDEFINED])] then
                luts_list[composition:MapPath(lut.LUTFile[fu.TIME_UNDEFINED])] = {lut}
            end
            table.insert(luts_list[composition:MapPath(lut.LUTFile[fu.TIME_UNDEFINED])], lut)
        end
    end

	------------------------------------------------------------------------------
	-- FONT LIST
	------------------------------------------------------------------------------
	font_files = {}

	-- Skip this if there are no text tools
	if table.getn(txt) == 0 and table.getn(txt3d) == 0 then
		init.fonts = 0
	end

	if init.fonts == 1 then
		local fontmanager = fusion.FontManager
		local fontlist = fontmanager:GetFontList()

		for i, t in pairs(txt) do
			local font = t.Font[fu.TIME_UNDEFINED]
			local style = t.Style[fu.TIME_UNDEFINED]
		
			font_files[ fontlist[ font ][ style ] ] = true
		end
	
		for i, t in pairs(txt3d) do
			local font = t.Font[fu.TIME_UNDEFINED]
			local style = t.Style[fu.TIME_UNDEFINED]
		
			font_files[ fontlist[ font ][ style ] ] = true
		end 
	end

	------------------------------------------------------------------------------
	-- FBX MESHES
	------------------------------------------------------------------------------
	fbx_files = {}

	if init.fbx == 1 then
		for i, t in pairs(fbx) do
			if not fbx_files[ composition:MapPath(t.ImportFile[fu.TIME_UNDEFINED]) ] then
				fbx_files[ composition:MapPath(t.ImportFile[fu.TIME_UNDEFINED]) ] = {t}
			else
				table.insert( fbx_files[ composition:MapPath(t.ImportFile[fu.TIME_UNDEFINED]) ], t) 
			end
		
		end
	end

	------------------------------------------------------------------------------
	-- ABC MESHES
	--
	------------------------------------------------------------------------------
	abc_files = {}

	if init.fbx == 1 then
		for i, t in pairs(abc) do
			if not abc_files[ composition:MapPath(t.Filename[fu.TIME_UNDEFINED]) ] then
				abc_files[ composition:MapPath(t.Filename[fu.TIME_UNDEFINED]) ] = {t}
			else
				table.insert( abc_files[ composition:MapPath(t.Filename[fu.TIME_UNDEFINED]) ], t) 
			end
		
		end
	end

	------------------------------------------------------------------------------
	-- AUDIO
	--
	------------------------------------------------------------------------------
	sound_files = {}

	if init.audio == 1 then
		-- Suckless Audio Modifier - WaveFile
		for i, sn in pairs(snd) do
			modifer_sound_file = composition:MapPath(sn.WaveFile[0])
			if (modifer_sound_file ~= nil) and (not sound_files[modifer_sound_file]) then
				sound_files[modifer_sound_file] = { WaveFile = sn }
			end
		end

		-- Saver - SoundFilename
		for i, sv in pairs(svs) do
			-- Make sure there are no duplicate entries
			if not sound_files[composition:MapPath(sv.SoundFilename[0])] then
				sound_files[composition:MapPath(sv.SoundFilename[0])] = { SoundFilename = sv }
			end
		end

		-- Comp timeline speaker icon based audio clip
		timeline_sound_file = composition:MapPath(comp:GetAttrs().COMPS_AudioFilename)
		if (timeline_sound_file ~= nil) and (not sound_files[timeline_sound_file]) then
			sound_files[timeline_sound_file] = { SoundFilename = composition }
		end
	end

	------------------------------------------------------------------------------
	-- CALCULATE FILESIZES
	--
	-- If the option to pre-calculate file size was selected, go ahead and do it
	------------------------------------------------------------------------------
	if init.analyze == 1 then
		-- Calculate font filesizes
		for i, v in pairs(font_files) do
			total_size = total_size + filesize(i)
		end

        -- Calculate luts size
        for i, v in pairs(luts_list) do
            total_size = total_size + filesize(i)
        end

		-- Calculate fbx filesizes
		for i, v in pairs(fbx_files) do
			total_size = total_size + filesize(i)
		end
	
		-- Calculate abc filesizes
		for i, v in pairs(abc_files) do
			total_size = total_size + filesize(i)
		end

		-- Calculate audio filesizes
		for i, v in pairs(sound_files) do
			total_size = total_size + filesize(i)
		end

		-- Calculate loader filesizes
		for i, v in pairs(cliplist) do
			if v.Multiframe == 1 then
				total_size = total_size + filesize(v.Seq.FullPath)
			else
				
				-- Check if the footage is a still, an image sequence, or a movie
				if (v.Seq.Padding == nil) and (v.Length == 1) then
					-- This is a still frame
					total_size = total_size + filesize(v.Seq.FullPath)
				elseif pathIsMovieFormat(v.Seq.FullPath) == true then
					-- This is a movie
					total_size = total_size + filesize(v.Seq.FullPath)
				else
					-- Check if frame padding is missing
					SeqPadding = v.Seq.Padding
					if SeqPadding == nil then
						SeqPadding = 1
					end
					
					-- This is an image sequence
					for i = v.InitialFrame, v.InitialFrame + (v.Length-1) do
						fname = v.Seq.CleanName .. string.format("%0" .. SeqPadding .. "d", i) .. v.Seq.Extension
						total_size = total_size + filesize(v.Seq.Path .. fname)
					end
				end
			end
		end

		-- Saver filesizes
		for i, clip in pairs(sv_cliplist) do
			for i, file in pairs(clip[2]) do
				total_size = total_size + filesize(file)
			end
		end

		local res = table.getn(cliplist)+table.getn(sv_cliplist) .. " clips total at " .. string.format("%.2f", total_size / 1048576) .. " MB."
		ret = composition:AskUser("Composition - Total File Size", {
			{"result", "Text", Name = "Total Filesize For Composition", Default = res, ReadOnly = true, Lines = 1},
			{"instructions", "Text", Name = "Instructions", Default = "Click OK to continue, or Cancel to exit.", ReadOnly = true}
			})
		if ret == nil then return end
	end

	-- Need to add fonts and fbx to filesize calculation

	--------------------------------------------
	-- Reset total size to avoid double counting
	total_size = 0

	------------------------------------------------------------------------------
	-- CHOOSE DESTINATION FOLDER
	--
	-- Select the ultimate destination folder for the archived composition
	------------------------------------------------------------------------------
	msg = "Select a destination folder, All footage in your composition will be copied to subfolders of this directory."
	errText = ""

	--------------------------------------------
	-- Keep displaying the dialog until they get a valid path, or they cancel the script
	gotpath = false

	while gotpath == false do
		-- Destination Directory
		-- local defaultPath = comp:MapPath('UserDocs:' .. os_separator .. 'Archive Composition'..os_separator)
		local defaultPath = comp:MapPath('Comp:' .. os_separator .. 'Archive Composition' .. os_separator)

		ret = composition:AskUser("Archive Composition", {
			{"root", Name = "Specify a destination directory", "PathBrowse", Save = true, Default = defaultPath},
			{"instructions", Name = "About this script", "Text", Default = errText .. msg, Wrap = true, Lines = 10}
			})
	
		if ret == nil then return end
	
		--------------------------------------------
		-- no entry made? ask again
		if ret.root == "" then 
			errText = "Error: You must provide a root directory for the script to copy files to.\n\n"
			gotpath = false
		else
			--------------------------------------------
			-- manually entered paths may not have a slash at the end. provide one
			if string.sub(ret.root, -1, -1) ~= os_separator then
				ret.root = ret.root .. os_separator
			end
		
			--------------------------------------------
			-- The createdir() function returns false if it fails, and false if the directory exists
			-- so we create the directory, and then see if it really is there.
			createdir(ret.root)
		
			-- Is the directory there?
			gotpath = direxists(ret.root)
			errText = "Error: Could not create directory " .. ret.root .. "\n\n"
		end
	end

	--------------------------------------------
	-- I use ret a lot for dialogs, so get the important 
	-- information into a more stable variable
	output_root = ret.root

	--------------------------------------------
	-- Now that the new dir exists
	-- save a copy of the composition in the root folder of the destination directory
    --
    function check_extension(comp_name)
        -- this will check if COMPS_Name has returned file name without extension
        if string.sub(comp_name, -5) ~= '.comp' then
            return '.comp'
        else
            return ''
        end
    end

    comp_name = composition:GetAttrs().COMPS_Name
	output_composition = output_root .. comp_name .. check_extension(comp_name)
	composition:Save(output_composition)

	dprintf("-----------------------------------\n")
	dprintf("-- Archiving Composition         --\n")
	dprintf("-----------------------------------\n")

	------------------------------------------------------------------------------
	-- Save a Client Note entry to the ArchiveLog.txt file
	--
	--
	------------------------------------------------------------------------------
	-- Only add this section if there is content to be written
	if (init.note ~= nil) and (init.note ~= "") then
		dprintf("\n")
		dprintf("Client Notes\n")
		dprintf("------------\n")
		dprintf(init.note .. "\n")
	end
	
	------------------------------------------------------------------------------
	-- COPY ALL FONTS
	------------------------------------------------------------------------------
	if init.fonts == 1 then 
		dprintf("\n")
		dprintf("Copy Fonts\n")
		dprintf("------------\n")

		-- Create a folder for the fonts
		new_dir = output_root .. "Fonts" .. os_separator
		createdir(new_dir)
	
		for font_path, val in pairs(font_files) do
			fseq = eyeon.parseFilename(font_path)
		
			dprintf(font_path .. "\n")
			size, errText = eyeon.copyfile(font_path, new_dir .. fseq.FullName)
	
			if size == 0 then 
				table.insert(badframe, errText)
			end
		
			total_size = total_size + size
		end
	end


	------------------------------------------------------------------------------
	-- COPY ALL FBX FILES
	-- if two fbx files with the same name came from different directories this 
	-- function would overwrite one of them.
	------------------------------------------------------------------------------
	if init.fbx == 1 then
		dprintf("\n")
		dprintf("Copy FBX + OBJ Meshes\n")
		dprintf("---------------------\n")
	
		-- Create a folder for the fbx files
		new_dir = output_root .. "Meshes" .. os_separator
		virtual_dir = "Comp:" .. os_separator .. "Meshes" .. os_separator
	
		createdir(new_dir)
	
		for mesh, val in pairs(fbx_files) do
			mesh_seq = eyeon.parseFilename(mesh)
		
			dprintf(mesh .. "\n")
			size, errText = eyeon.copyfile(mesh, new_dir .. mesh_seq.FullName)
		
			if size == 0 then 
				table.insert(badframe, errText)
			end
		
			total_size = total_size + size
		
			comp:Lock()
			for i, tool in pairs(val) do
				tool.ImportFile[fu.TIME_UNDEFINED] = virtual_dir .. mesh_seq.FullName
			end
			comp:Unlock()
		end
	
	
	end

	------------------------------------------------------------------------------
	--	COPY ALL LUT FILES
	--	if two lut files with the same name came from different directories this 
	--	function would overwrite one of them.
	------------------------------------------------------------------------------
	if init.luts == 1 then
		dprintf("\n")
		dprintf("Copy LUTs\n")
		dprintf("---------------\n")
	
		-- Create a folder for the abc files
		new_dir = output_root .. "LUTs" .. os_separator
		virtual_dir = "Comp:" .. os_separator .. "LUTs" .. os_separator
	
		createdir(new_dir)
	
		for name, val in pairs(luts_list) do
			lut_seq = eyeon.parseFilename(name)
		
			dprintf(name.. "\n")
			size, errText = eyeon.copyfile(name, new_dir .. lut_seq.FullName)
		
			if size == 0 then 
				table.insert(badframe, errText)
			end
		
			total_size = total_size + size
		
			comp:Lock()
			for _, tool in pairs(val) do
				tool.LUTFile[fu.TIME_UNDEFINED] = virtual_dir .. lut_seq.FullName
			end
			comp:Unlock()
		end
	
	end


	------------------------------------------------------------------------------
	--	COPY ALL ABC FILES
	--	if two abc files with the same name came from different directories this 
	--	function would overwrite one of them.
	------------------------------------------------------------------------------
	if init.abc == 1 then
		dprintf("\n")
		dprintf("Copy ABC Meshes\n")
		dprintf("---------------\n")
	
		-- Create a folder for the abc files
		new_dir = output_root .. "Meshes" .. os_separator
		virtual_dir = "Comp:" .. os_separator .. "Meshes" .. os_separator
	
		createdir(new_dir)
	
		for mesh, val in pairs(abc_files) do
			mesh_seq = eyeon.parseFilename(mesh)
		
			dprintf(mesh .. "\n")
			size, errText = eyeon.copyfile(mesh, new_dir .. mesh_seq.FullName)
		
			if size == 0 then 
				table.insert(badframe, errText)
			end
		
			total_size = total_size + size
		
			comp:Lock()
			for i, tool in pairs(val) do
				tool.Filename[fu.TIME_UNDEFINED] = virtual_dir .. mesh_seq.FullName
			end
			comp:Unlock()
		end
	
	end

	------------------------------------------------------------------------------
	-- COPY ALL AUDIO FILES
	-- if two audio files with the same name came from different directories this 
	-- function would overwrite one of them.
	------------------------------------------------------------------------------
	if init.audio == 1 then
		dprintf("\n")
		dprintf("Copy Audio\n")
		dprintf("----------\n")
	
		-- Create a folder for the audio files
		new_dir = output_root .. "Audio" .. os_separator
		virtual_dir = "Comp:" .. os_separator .. "Audio" .. os_separator
	
		createdir(new_dir)
	
		-- Process the audio files from the Saver Node / SuckLessAudio Fuse / Timeline audio clip
		for audio, val in pairs(sound_files) do
			if (audio ~= "") and (audio ~= nil) then
				audio_seq = eyeon.parseFilename(audio)
				dprintf(audio .. "\n")
				size, errText = eyeon.copyfile(audio, new_dir .. audio_seq.FullName)
		
				if size == 0 then 
					table.insert(badframe, errText)
				end
		
				total_size = total_size + size
		
				comp:Lock()
				for i, tool in pairs(val) do
					if tool ~= nil and tool:GetAttrs().TOOLS_RegID == 'Saver' then
						-- This is a Saver node
						tool.SoundFilename = virtual_dir .. audio_seq.FullName
					elseif tool ~= nil and tool:GetAttrs().TOOLS_RegID == 'Fuse.SuckLessAudio' then
						-- This is a SuckLessAudio Modifier
						tool.WaveFile = virtual_dir .. audio_seq.FullName
					-- elseif tool ~= nil and tool:GetAttrs().COMPS_AudioFilename ~= nil then
						-- Todo: Timeline audio clip
						-- tool:SetAttrs({ COMPS_AudioFilename = virtual_dir .. audio_seq.FullName })
					end
				end
			end
			comp:Unlock()
		end

	end

	------------------------------------------------------------------------------
	-- COPY ALL LOADER CLIPS
	------------------------------------------------------------------------------
	dprintf("\n")
	dprintf("Copy Loaders\n")
	dprintf("------------\n")

	index = 1
	for i, clip in pairs(cliplist) do
		seq = clip.Seq

		--------------------------------------------
		-- Different branches for multiframe versus sequence
		if clip.Multiframe == 1 or pathIsMovieFormat(seq.FullPath) == true then
			--------------------------------------------
			-- Before we copy make sure one with the same name does not already exist
			-- an alternate method would be to call fileexists() on filename
			if io.open(output_root .. seq.FullName, "r") == nil then
				init_frame = seq.FullName
			else
				init_frame = string.format("%04d", i) .. "__" .. seq.FullName
			end

			new_dir = output_root .. "Movies" .. os_separator
			virtual_dir = "Comp:" .. os_separator .. "Movies" .. os_separator

			createdir(new_dir)

			dprintf(seq.Name .. " : Copying " .. string.format("%.2f", filesize(seq.FullPath) / 1048576) .. " MB\n")
			size, errText = eyeon.copyfile(seq.FullPath, new_dir .. init_frame)

			if size == 0 then 
				table.insert(badframe, errText)
			end

			total_size = total_size + size
		else
			if clip.Length == 1 then
				new_dir = output_root .. "Stills" .. os_separator
				virtual_dir = "Comp:" .. os_separator .. "Stills" .. os_separator

				createdir(new_dir)

				-- Does a still file with the same name already exist at this location?
				if fileexists(new_dir .. seq.FullName) == true then
					init_frame = string.format("%04d", i) .. "__" .. seq.FullName
				else
					init_frame = seq.FullName
				end

				dprintf(init_frame .. " : Copying " .. string.format("%.2f", filesize(seq.FullPath) / 1048576) .. " MB\n")
				size, errText = eyeon.copyfile(seq.FullPath, new_dir .. init_frame)
				if size == 0 then 
					table.insert(badframe, errText)
				end
				total_size = total_size + size
			else
				-- It's an image sequence
				d_name = string.format("%04d", index) .. "__" .. seq.CleanName .. "_" .. seq.Extension
				new_dir = output_root .. d_name .. os_separator
				virtual_dir = "Comp:" .. os_separator .. d_name .. os_separator
			
				createdir(new_dir)
			
				start = clip.InitialFrame
				theend = start + (clip.Length-1)
			
				seqPadding = seq.Padding
				if seqPadding == nil then
					seqPadding = 1
				end
					
				init_frame = seq.CleanName .. string.format("%0" .. seqPadding .. "d", start) .. seq.Extension
			
				dprintf(init_frame .. " : " .. clip.Length .. " Frames\n")
			
				for i = start, theend do
					fname = seq.CleanName .. string.format("%0" .. seqPadding .. "d", i) .. seq.Extension
				
					size, errText = eyeon.copyfile(seq.Path .. fname, new_dir .. fname)
				
					if size == 0 then 
						table.insert(badframe, errText)
						composition:Print("x")
					else
						composition:Print(".")
					end
				
					total_size = total_size + size
				end
			
				composition:Print("\n")
				composition:Print("\n")
				index = index + 1
			end
		end

		--------------------------------------------
		-- The clip was copied so update the loaders using that clip
		composition:Lock()
		for index, item in pairs(clip.Clip) do
			item.Loader.Clip[item.Start] = virtual_dir .. init_frame
		end
		composition:Unlock()
	
	end



	------------------------------------------------------------------------------
	-- COPY FILES FROM SAVERS
	--
	--
	------------------------------------------------------------------------------
	dprintf("\n")
	dprintf("Copy Savers\n")
	dprintf("-----------\n")

	for i, s in pairs(sv_cliplist) do
		sv = s[1]
		sva = sv:GetAttrs()
		files = s[2]
	
		d_name = string.format("%04d", i) .. "___" .. sva.TOOLS_Name
		new_dir = output_root .. d_name .. os_separator
	
		createdir(new_dir)
	
		init_frame = eyeon.getfilename(files[1])
	
		dprintf(sva.TOOLS_Name .. " : " .. table.getn(files) .. " Frames\n")
	
		for i, file in pairs(files) do
			size, errText = eyeon.copyfile(file, new_dir .. eyeon.parseFilename(file).FullName)
		
			if size == 0 then 
				table.insert(badframe, errText)
				composition:Print("x")
			else
				composition:Print(".")
			end
		
			total_size = total_size + size
		end
	
		dprintf("\n")
	
		--------------------------------------------
		-- The clip was copied so update saver using that clip
		composition:Lock()
		sv.Clip[fu.TIME_UNDEFINED] = "Comp:" .. os_separator .. d_name .. os_separator .. init_frame
		composition:Unlock()
	end


	-- Keep track of exec time
	local t_end = os.time()

	-- Print the estimated time of execution in seconds
	dprintf(string.format("[Processing Time] %.3f s\n", os.difftime(t_end, t_start)))

	-- Display the ArchiveLog.txt output location:
	archive_log = "ArchiveLog.txt"
	archive_log_path = comp:MapPath("Temp:/" .. archive_log)
	dprintf("[Archive Composition Log] " .. output_root .. archive_log .. "\n")

	------------------------------------------------------------------------------
	-- PRINT ERRORS THAT OCCURED ALONG THE WAY
	--
	------------------------------------------------------------------------------

	if table.getn(badframe) == 0 then
		ret = composition:AskUser("Copy Complete", {
			{"results", Name = "File Copy Complete", "Text", Default = "File copy complete.\nAll clips have been copied to:\n \"" .. ret.root .. "\"\n\n" .. string.format("%.2f", total_size / 1048576) .. " MB were copied in total.", Lines = 7, ReadOnly = true, Wrap = true}
			})
	else
		ret = composition:AskUser("Copy Complete", {
			{"results", Name = "File Copy Complete", "Text", Default = "File copy complete.\n" .. table.getn(badframe) .. " files were not copied to:\n \"" .. ret.root .. "\"\n\n" .. string.format("%.2f", total_size / 1048576) .. " MB were copied in total.\n\nClick OK to print a complete list of failed frames to the console, along with reasons for failing.", Lines = 10, ReadOnly = true, Wrap = true}
			})
		if ret ~= nil then
			-- Display a list of the files that couldn't be archived
			dprintf("\n")
			for i, v in pairs(badframe) do
				dprintf(v .. "\n")
			end
	--	else
	--		return
		end
	end

	-- Copy the ArchiveLog.txt file into the output folder:
	size, errText = eyeon.copyfile(archive_log_path, output_root .. archive_log)
	if size == 0 then 
		dprintf("[Archive Composition Log] There was an error saving the file: " .. archive_log .. "\n")
	end

	-- Open up the Archive Composition output folder
	if init.openFolder == 1 or init.openFolder == true then
		OpenDirectory(output_root)
	end

	-- Save the comp with the relinked file paths
	composition:Save(output_composition)

end

-- Run main
main()

-- Our work here is done.
dprintf("[Done]\n")
