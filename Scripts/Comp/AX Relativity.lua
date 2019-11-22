_VERSION = "v4.1 2019-11-03"
--[[--
AX Relativity - v4.1 2019-11-03
by Protean

Overview:
The AX Relativity script converts all absolute paths in your comp to relative ones for easy sharing across different machines and/or users.

Installation:
Copy the Lua comp script to your "Scripts:/Comp/" PathMap folder. If you downloaded this script from the web make sure the script has a .lua file extension.

Disclaimer:
AX Relativity isn't a foolproof way of backing up your work. Please be sure to double-check your work


Version History:
v3.2 2009 by Protean
- Original script "AX Relativity V3.2" by protean

v4 2019-11-03 by Pieter Van Houte
- Compatibility with Fusion 9+ and additional error handling by Pieter Van Houte, a decade later - https://www.steakunderwater.com/wesuckless/viewtopic.php?p=26676#p26676

v4.1 2019-11-03 by Andrew Hazelden <andrew@andrewhazelden.com>
- Code re-formatting
- Proof-read the script comments
- Script cleanup for spaces vs tabs
- Removed several bmd.scriptlib dependencies to improve Reactor packaging script reliability down the road in a post-Fu/ReFu v16+ world.

--]]--


--------------- bmd.scriptlib Dependencies -------------------------------------------------------------------------
-- These functions were shamelessly copied from "bmd.scriptlib" to reduce the patchwork of risks that exist in Fu/ReFu v16.x+ where scriptlib support changes impact Lua script compatibility for Reactor based installations:

------------------------------------------------------------------------------
-- ParseFilename()
--
-- This is a great function for ripping a filepath into little bits
-- returns a table with the following
--
-- FullPath : The raw, original path sent to the function
-- Path : The path, without filename
-- FullName : The name of the clip w\ extension
-- Name : The name without extension
-- CleanName: The name of the clip, without extension or sequence
-- SNum : The original sequence string, or "" if no sequence
-- Number : The sequence as a numeric value, or nil if no sequence
-- Extension : The raw extension of the clip
-- Padding : Amount of padding in the sequence, or nil if no sequence
-- UNC : A true or false value indicating whether the path is a UNC path or not
------------------------------------------------------------------------------
function ParseFilename(filename)
	local seq = {}
	seq.FullPath = filename
	string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name) seq.Path = path seq.FullName = name end)
	string.gsub(seq.FullName, "^(.+)(%..+)$", function(name, ext) seq.Name = name seq.Extension = ext end)

	if not seq.Name then -- no extension?
		seq.Name = seq.FullName
	end

	string.gsub(seq.Name, "^(.-)(%d+)$", function(name, SNum) seq.CleanName = name seq.SNum = SNum end)

	if seq.SNum then
		seq.Number = tonumber(seq.SNum)
		seq.Padding = string.len(seq.SNum)
	else
		seq.SNum = ""
		seq.CleanName = seq.Name
	end

	if seq.Extension == nil then seq.Extension = "" end
	seq.UNC = (string.sub(seq.Path, 1, 2) == [[\\]])

	return seq
end

--------------- GLOBALS --------------------------------------------------------------------------------------------
-- Find out the current operating system platform. The platform variable should be set to either 'Windows', 'Mac', or 'Linux'.
local platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

-- Add the platform specific folder slash character
local os_separator = package.config:sub(1,1)

local COMPNAME, COMPFILENAME, PATTERN, PARSECOMP, NEWCOMPNAME, NEWCOMPPATH, NEWCOMPEXT, NEWCOMP

COMPNAME = composition:GetAttrs().COMPS_Name
-- print(COMPNAME)

COMPFILENAME = composition:GetAttrs().COMPS_FileName
-- print(COMPFILENAME)

if COMPFILENAME == "" then
	print "[Error] Please save your comp first..."
	return
else
	PATTERN = "[%w%=%:%_%s%-.%.]+"
	PARSECOMP = ParseFilename(COMPFILENAME)
	NEWCOMPNAME = PARSECOMP.Name .. "_relative"
	NEWCOMPPATH = PARSECOMP.Path
	NEWCOMPEXT = PARSECOMP.Extension
	NEWCOMP = NEWCOMPPATH .. NEWCOMPNAME .. NEWCOMPEXT
end
----------------- END GLOBALS --------------------------------------------------------------------------------------

----------------- START FUNCTIONS ----------------------------------------------------------------------------------
function literalize(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
end

-- Run gsub in a case insensitive way
function insensGsub(s, pat, repl) -- Case insensitive gsub
	pat = string.gsub(pat, '(%a)',
	function (v) return '[' .. string.upper(v) .. string.lower(v) .. ']' end)
	return string.gsub(s, pat, repl)
end

-- Expand a filepath string into separate elements in a new Lua table
function splitPath(str, pat)
	local pathTable = {} -- To store original path
	local x = 1
	for i in string.gmatch(str, pat) do -- Iterate every word in filename
		pathTable[x] = i
		x = x + 1
	end
	return pathTable
end

-- Covert the capitalization of entries in a Lua table to lowercase
function lowerCase(table)
	local lowTable = {}
	local x = 1
	for i, v in ipairs(table) do
		lowTable[x] = string.lower(v)
		x = x + 1
	end
	return lowTable
end

-- Rewrite all filepaths to be relative
function relative(file1,file2)
	local file1Lwr = string.lower(file1)
	local file2Lwr = string.lower(file2)
	local file1_Path = ParseFilename(file1).Path
	local file2_Path = ParseFilename(file2).Path
	local newPath = file2_Path -- Will be overwritten by a new string if relative path found
	local filePathTable = {}
	print("\t\t[Comp Path] " .. file1_Path)
	print("\t\t[Filepath] " .. file2_Path)
	local file1_Path_lit = literalize(file1_Path) -- gsub doesn't do literal string comparison so...

	if file2_Path:find(file1_Path, 1, true) ~= nil then -- First check if footage downstream
		print("[Footage Dowstream]")
		newPath = "COMP:\\\\" .. insensGsub(file2, file1_Path_lit, "")
	else
		local filePathTbl = splitPath(file2_Path, PATTERN)
		local compPathTbl = splitPath(file1_Path, PATTERN)
		local filePathTbl_lwr = lowerCase(filePathTbl)
		local compPathTbl_lwr = lowerCase(compPathTbl)
		local sharedPath = ""
		local pathBuilder = ""
		local sharePoint = 0
		local fork = 0
		-- dump(filePathTbl_lwr)
		for i, v in ipairs(compPathTbl_lwr) do
			-- dump(filePathTbl)
			-- print("\t[File Entry] " .. filePathTbl[i])
			-- print("\t[Comp Entry] " .. v)
			if v == filePathTbl_lwr[i] and fork == 0 then -- Compare file and comp tables // 'fork' checks if there has already been a non-match
				sharedPath = sharedPath .. compPathTbl[i] .. "\\\\"
				sharePoint = i
			elseif sharePoint ~= 0 then -- If the comp/file tables return no match but there is a shared path
				fork = 1
				pathBuilder = pathBuilder .. "..\\\\"
			elseif sharePoint == 0 then -- If no initial match so no relative path
				break
			end
		end

		if sharePoint == 0 then
			newPath = file2
			print("[No relative path found]")
		else
			print("[Footage Upstream]")

			sharedPath_lit = literalize(sharedPath)
			print("[SharedPath] " .. sharedPath)
			-- print("\t\t[file2] " .. file2)

			newPath = insensGsub(file2, sharedPath_lit, "COMP:\\\\" .. pathBuilder)
			-- print("\t\t[Newpath] " .. newpath)
		end

	end
	-- print("\t\t[Comp File] " .. COMPFILENAME)
	-- print("\t\t[New Path] " .. newPath)
	-- print("\n")
	return newPath
end

-- Use a Lua native approach to check if a file exists on disk
function fileExists(file)
	local f = io.open(file, "r")
	if f ~= nil then io.close(f) return true else return false end
end

-- Find out the current directory from a file path
function dirname(mediaDirName)
	return mediaDirName:match('(.*' .. os_separator .. ')')
end

-- Open a folder window up using your desktop file browser
function openDirectory(mediaDirName)
	command = nil
	dir = dirname(mediaDirName)

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

----------------- END FUNCTIONS -----------------------------------------------------------------------------------

----------------- BEGIN SCRIPT ------------------------------------------------------------------------------------
print("AX Relativity - " .. tostring(_VERSION))
print("-------------------------------")
print("[Start Time] " .. tostring(os.date('%I:%M:%S %p')) .. "\n")

print("[Note] Fusion's built-in Lua v5.1 based interpreter may have difficulty handing Unicode extended + multibyte characters in filepaths.\n")

----- Test Destination Comp --------------------------------------------------------------------------------------
destComp, err = io.open(NEWCOMP, "w+")
if not destComp then
	print("[Error] Could not create output composition " .. NEWCOMP .. " The system returned the following error : \n" .. err)
	exit()
else
	destComp:close()
	destComp = nil
end
-----------------------------------------------------------------------------------------------------------------
print("[Processing Comp]")
print("\t[Comp File] " .. string.gsub(COMPFILENAME, "\\", "\\\\"))
print("\t[Comp Dest] " .. NEWCOMP .. "\n")

-- COMPFILENAME file reading
compFile = io.open(COMPFILENAME, "r+")

local lines = {}
for line in compFile:lines() do
	table.insert(lines, line)
end

for i, v in ipairs(lines) do
	findPattern = "%\"(.-)%\"" ---- Look for a string in quotes (any text entry basically)
	s, e = v:find(findPattern)
	if s ~= nil then
		cleanLine = string.gsub(v:sub(s,e), "%\"" ,"") ---- Remove the quotation marks
		if cleanLine:find("%a%:%\\%\\") ~= nil then ---- Look for a drive path <letter>:\\
			local relativePath = relative(string.gsub(COMPFILENAME, "\\", "\\\\"), cleanLine)
			local cleanLine_lit = literalize(cleanLine)
			local newLine = v:gsub(cleanLine_lit, relativePath)
			print("\t[Old Line] " .. v)
			print("\t[New Line] " .. newLine .. "\n")
			lines[i] = newLine
		end
	end
end 

compFile:close()

-- NEWCOMP file writing
destComp = io.open(NEWCOMP, "w")

for i, l in ipairs(lines) do
	-- print(l)
	destComp:write(l, "\n")
end

destComp:close()
print("[Comp Saved] Relative comp file saved as:\n\"" .. NEWCOMP .. "\"\n")


-- Open up the reative comp's containing folder in a desktop folder browsing window
print("[Open Containing Folder]")
openDirectory(NEWCOMP)
print("\n")

-- Script complete
print("[End Time] " .. tostring(os.date('%I:%M:%S %p')) .. "")
print("-------------------------------")
print("My work here is done.\n")

