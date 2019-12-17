-- Add Tool X
-- by Stefan Ihringer <stefan@bildfehler.de>
--
-- based on AddTool by eyeon software and "Add Anything" by Andreas Opferkuch
-- (andreas dot opferkuch at gmx dot at, http://www.variations-of-shadow.com)
--
-- * remembers your favorite tools and preselects them in the list. This way you will never again
--   get confused by similarly named tools that you never use. These favorites get written to disk into your profile directory.
-- * reduced interface from Add Anything (press ESC to dismiss popup)
-- * also allows to launch scripts like Add Anything
-- * caseless sorting of tool list like Add Anything
-- * Ctrl-U hotkey to reload tool list (like Add Anything). Macros and Scripts are always refreshed since they might change more often.
-- * makes 3rd party tools or Fuses easier to spot by printing the vendor ID (Krokodove is abreviated to KD)
--
-- version 1.5, 2013-08-09: option to cache macros and scripts (disabled by default but speeds up popup if you have lots of path maps)
--                          ignores hidden dot-files
-- version 1.4, 2013-07-28: favorite tools are now sorted to the top of the list (can be disabled)
--                          start with a capital letter to disable non-consecutive matching
--                          fixed not being able to run Python and tool scripts
--                          fixed entering spaces
--                          some code refactoring and documentation
-- version 1.3, 2013-07-26: now lists .py scripts but no longer shows tool scripts 
--                          added options to not list scripts or macros
--                          fixed saving of recently used script or macro
-- version 1.2, 2013-07-25: implemented regular expression inspired by Tabtabtab by Ben Dickson (www.github.com/dbr/tabtabtab-nuke/)
--                          you can now skip letters if the 1st letter matches, so for example "tk" will match the Tracker.
--                          dialog pops up where your mouse is (can be disabled)
-- version 1.1, 2013-07-25: fixed preference saving problems (backslashes in macro paths)
--                          fixed regression (didn't remember most recently used tool)
--                          popup has a label at the bottom (can be disabled)
-- version 1.0, 2013-07-24: initial release
--
-- AddTool by eyeon software
-- blazej floch: Modified
-- 22-Oct-09, daniel koch: List restriction
-- 31-Mar-11, daniel koch: Added Macros:
-- 24-Jun-11, daniel: Fixed macro subdirs, removed .setting, supports multipath Macro:
-- 18-Jul-11, daniel: Now rescans Macro: each time, and uses comp:MapPathSegments() to handle multipath, multilevel mappings
--  6-Sep-11, daniel: Minor bugfix

-- show the helpful label at the bottom of the popup?
SHOW_LABEL = true
-- pop up where the mouse is (remove line to pop up in the center of the screen)
CURSOR_POPUP = true
-- disable to hide macros
SHOW_MACROS = true
-- disable to hide scripts
SHOW_SCRIPTS = true
-- sort by tool weight (puts favorites to the top of the list)
SORT_BY_POPULARITY = true
-- cache macros and scripts (use if you have lots of path maps to speed up the popup)
--CACHE_MACROS_AND_SCRIPTS = true


-- parses the given directory "path" for macros and scripts. Results are added to the table "tbl" that already
-- contains Fusion's tools and plugins.
function AddDirectory(tbl, path)
	if path:sub(-1) ~= "\\" then
		path = path .. "\\"
	end
	local dirlist = eyeon.readdir(path.."*")

	for i,v in ipairs(dirlist) do
		if v.IsDir then
			AddDirectory(tbl, path..v.Name)
		else
			-- tools and scripts use REGS_ID for the complete path to the file which is a unique ID (change taken from Add Anything)
			local filename = ""
			local ext = ""
			string.gsub(v.Name, "^(.+)(%..+)$", function(s1, s2) filename = s1 ext = s2:lower() end)
			local data = {REGS_Name = filename, REGS_ID = path..v.Name, Weight = 0}
			if filename:sub(1,1) ~= "." then
				if ext == ".setting" then
					data.REGS_OpIconString = "Macro"
					table.insert(tbl, data)
				elseif ext == ".eyeonscript" or ext == ".py" then
					-- don't list tool scripts since you can't run them via the Add Tool script
					data.REGS_OpIconString = "Script"
					table.insert(tbl, data)
				end
			end
		end
	end
end

-- fixed version of doPrefs from eyeon.scriptlib, by Peter Loveday
function doPrefs(scriptName,readPrefs,developer,tPrefs)
	if not scriptName then
		error("ERROR: You did not specify a scriptName.")
	end
	
	developer = developer and developer.."\\" or ""
	
	local f_dir = os.getenv("FUSION_PROFILE_DIR") or fusion:MapPath("Profiles:\\")
	local profileName = os.getenv("FUSION_PROFILE") or "Default"
	
	if f_dir:sub(-1)=="\\" then 
		f_dir = f_dir:sub(1, -2) 
	end
	
	local prefDir = f_dir.."\\"..profileName.."\\ScriptPrefs\\"..developer
	local prefFile = prefDir .. scriptName..".ScriptPrefs"
	
	if not eyeon.direxists(prefDir) then
		eyeon.createdir(prefDir)
	end
	
	if readPrefs then
		return eyeon.readfile(prefFile)
	else
		if type(tPrefs) == "table" then
			eyeon.writefile(prefFile, tPrefs)
		else
			error("ERROR: This function requires a table.")
		end
	end
end

function CopyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- retrieve the list of all available tools, macros and scripts which gets saved to the global alltools table.
-- Cache tool names and IDs first time round, to avoid delays
function initList()
	-- needed because in Lua, nil doesn't equal false
	if CACHE_MACROS_AND_SCRIPTS == false then CACHE_MACROS_AND_SCRIPTS = nil end
	if globals.__addtool_data and (globals.__addtool_data.cached_macros_and_scripts == CACHE_MACROS_AND_SCRIPTS) then
		alltools = CopyTable(globals.__addtool_data)
	else
--		print("rescanning tools")
		alltools = fu:GetRegSummary(CT_Tool)
		-- Fill in missing entries
		for i,v in ipairs(alltools) do
			v.Weight = 0
			-- If there is no Name use the OpIconString if available
			if not v.REGS_Name then
				if not v.REGS_OpIconString then
					v.REGS_Name = "???"
				else
					v.REGS_Name = v.REGS_OpIconString
				end
			end
			
			-- If there is no OpIconString use the first 4 letter of the Name if available
			if not v.REGS_OpIconString then
				if not v.REGS_Name then
					v.REGS_OpIconString = "???"
				else
					v.REGS_OpIconString = string.sub(v.REGS_Name, 0, 4)
				end
			end

			-- label 3rd party tools
			local dotpos = string.find(v.REGS_ID, ".", 1, true)
			if dotpos then
				local vendor = string.sub(v.REGS_ID, 1, dotpos - 1)
				if vendor == "KomkomDoorn" then vendor = "KD" end
				v.REGS_OpIconString = vendor .. "." .. v.REGS_OpIconString
			end
		end

		alltools.lasttool = 1
		alltools.cached_macros_and_scripts = nil
		globals.__addtool_data = CopyTable(alltools)
	end

	if not alltools.cached_macros_and_scripts then
		-- Rescan and re-add macros
		if SHOW_MACROS == true then
--			print("rescanning macros")
			local paths = comp:MapPathSegments("Macros:")
			for k,v in ipairs(paths) do
				AddDirectory(alltools, v)
			end
		end
		-- same goes for scripts
		if SHOW_SCRIPTS == true then
--			print("rescanning scripts")
			paths = comp:MapPathSegments("Scripts:")
			for k,v in ipairs(paths) do
				AddDirectory(alltools, v)
			end
		end

		if CACHE_MACROS_AND_SCRIPTS == true then
--			print("caching macros and scripts")
			alltools.cached_macros_and_scripts = true
			globals.__addtool_data = CopyTable(alltools)
		end
	end
end

-- populates the IUP object "list" with strings based on a sorted version of "data" (a table of registry summary objects) 
-- if "favorites_first" is true, favorite tools (weight > 0) will be listed before all other tools
function UpdateList(list, data, favorites_first)
	if favorites_first == true then
		-- sort by weight first, then alphabetically
		table.sort(data, function(a,b)
				if a.Weight == b.Weight then
					return (a.REGS_Name:lower() < b.REGS_Name:lower())
				else
					return (a.Weight > b.Weight)
				end
			end)
	else
		-- just sort alphabetically
		table.sort(data, function(a,b) return (a.REGS_Name:lower() < b.REGS_Name:lower()) end)
	end
	
	list[1] = nil		-- clears the list
	for i,v in ipairs(data) do
		local asterisks = ""
		if v.Weight and v.Weight > 0 then asterisks = " " .. string.rep("*", 1 + math.log(v.Weight)) end
		list[tostring(i)] = v.REGS_Name .. " (" .. v.REGS_OpIconString .. ")" .. asterisks
	end
end






-- load weights (for speed reasons they are not added to the list of all tools just yet. This happens
-- in the restrictlist() function that gets called once something has been entered by the user)
toolWeights = doPrefs("Add Tool X", true, "CompFu")
if toolWeights == nil or toolWeights == false then
	toolWeights = {}
end
--dump(toolWeights)

-- initialize tool list
initList()

-- other globals:
local toolid = nil			-- chosen tool
local tools = alltools		-- tool data

-- Define our UI
local toollist = iup.list{expand="HORIZONTAL", size="x100", dropdown="NO"}
UpdateList(toollist, tools)

local toolname = iup.text{"",	expand="HORIZONTAL"}
local ok = iup.button{title = "OK", size=50, expand="NO", visible = "NO"}
local cancel = iup.button{title = "Cancel", size=50, expand="NO", visible = "NO"}
local label = iup.hbox{
	margin = "5x5",
	iup.fill{},
	iup.label{title = "esc to close, ctrl-u to reload and clear favorites", },
	iup.fill{},
}
if SHOW_LABEL ~= true then
	label = iup.fill{}
end

local dlg = iup.dialog
{
	title = "Add Tool",
	foreground = "YES",
--	margin = "10x10",
	defaultenter = ok, defaultesc = cancel,
	border = "NO", minbox = "NO", maxbox = "NO", menubox = "NO", resize = "NO",
	bgcolor = "64 64 64", fgcolor = "192 192 192",

	iup.vbox
	{
		toolname,
		toollist,
		label,
	},
}

iup.SetAttribute(dlg, "NATIVEPARENT", touserdata(fu:GetMainWindow()))

function moveselection(num)
	movetoselection(num + toollist.value)
end

function movetoselection(num)
	num = math.min(math.max(1, num), #tools)
	toollist.value = num
	v = toollist[num]
	toolname.value = tools[num].REGS_Name
	toolname.selection = "1:1000"
end

function restrictlist(fromlist, text)
	text = text:gsub(" ", "")
	local tolist = {}
	local lowtext = text:lower()
	local listsize = 0
	local i,v
	local useRegexp = true

	-- starting with a capital letter will disable the fancy non-consecutive matching feature
	if #text > 0 then
		if text:sub(1, 1) ~= text:lower():sub(1, 1) then
			useRegexp = false
		end
	end

	-- Build a regular expression that matches names even though you've skipped several letters.
	-- For example: "t3" will match "Transform 3D" (1st letter has to match though).
	-- Inspired by Tabtabtab by Ben Dickson (www.github.com/dbr/tabtabtab-nuke/)
	local rex = "^"
	for i = 1, #lowtext do
		rex = rex .. lowtext:sub(i, i) .. ".*"
	end

	-- restrict list to only those containing our text
	for i,v in ipairs(fromlist) do
		local lowname = string.gsub(v.REGS_Name:lower(), " ", "")				-- lower case name without spaces

		if string.find(lowname, lowtext, 1, true)								-- search the name (plain text matching)
		  or string.find(v.REGS_OpIconString:lower(), lowtext, 1, true)			-- search the icon string
		  or (useRegexp and string.find(lowname, rex)) then						-- search regular expression (see above)
			v.Weight = toolWeights[v.REGS_ID] or 0
			listsize = listsize + 1
			tolist[listsize] = v
		end
	end
	
	UpdateList(toollist, tolist, #text > 0 and SORT_BY_POPULARITY)

	-- now select one
	if listsize > 0 then
		local len = string.len(text)
		local sel = 0
		local highestWeight = 0
		
		-- select the tool with the highest weight of all displayed items
		for i,v in ipairs(tolist) do
			for i,v in ipairs(tolist) do
				if v.Weight and v.Weight > highestWeight then
					sel = i
					highestWeight = v.Weight
				end
			end
		end

		-- look for a match at the start of the name
		if sel == 0 then
			for i,v in ipairs(tolist) do
				if string.sub(v.REGS_Name:lower(), 1, len) == lowtext then
					sel = i
					break
				end
			end
		end
		
		-- look for a match at the start of the icon string
		if sel == 0 then
			for i,v in ipairs(tolist) do
				if string.sub(v.REGS_OpIconString:lower(), 1, len) == lowtext then
					sel = i
					break
				end
			end
		end

		if sel == 0 then
			sel = 1
		end
		toollist.value = tostring(sel)
	end

	return tolist
end

function toolname:action(key, text)
	if key == iup.K_BS or key == iup.K_DEL or key == iup.K_cDEL then
		if string.len(text) > 0 then
			tools = restrictlist(alltools, text)
		else
			tools = alltools
			UpdateList(toollist, tools)
			self.value = ""
		end
	elseif key == 21 then -- CTRL + U re-initializes list of tools, macros and scripts
		toolWeights = {}
		globals.__addtool_data = nil
		initList()
		if string.len(text) > 0 then
			tools = restrictlist(alltools, text)
		else
			tools = alltools
			UpdateList(toollist, tools)
			self.value = ""
		end
	elseif key == iup.K_UP then
		moveselection(-1)
	elseif key == iup.K_PGUP then
		moveselection(-10)
	elseif key == iup.K_cPGUP then
		movetoselection(1)
	elseif key == iup.K_cHOME then
		tools = alltools
		UpdateList(toollist, tools)
		movetoselection(1)
	elseif key == iup.K_DOWN then
		moveselection(1)
	elseif key == iup.K_PGDN then
		moveselection(10)
	elseif key == iup.K_cPGDN then
		movetoselection(#tools)
	elseif key == iup.K_cEND then
		tools = alltools
		UpdateList(toollist, tools)
		movetoselection(#tools)
	elseif key >= 32 and key < 127 then
		tools = restrictlist(alltools, text)	-- could restrict from tools list
	elseif key == 127 then	-- Ctrl+Backspace
		text = string.sub(text, self.caret+1, 1000)
		tools = restrictlist(alltools, text)
		self.value = text
--	else
		--print(key)
	end
	
	return iup.DEFAULT
end

function toollist:action(text, item, sel)
	-- clicking a list item will execute it immediately (taken from Add Anything)
	ok:action()
	return iup.CLOSE
--[[
	toolname.value = tools[item].REGS_Name
	toolname.selection = "1:1000"
	iup.SetFocus(toolname)
	
	return iup.DEFAULT
]]--
end

function toollist:dblclick_cb(pos, text)	-- not called?
	ok:action()
end

function ok:action()
	local num = tonumber(toollist.value)
	if num == 0 then
			return iup.CLOSE
	elseif num <= #tools then
		toolid = tools[num].REGS_ID
		-- update tool weight
		if toolWeights[toolid] == nil then
			toolWeights[toolid] = 1
		else
			toolWeights[toolid] = toolWeights[toolid] + 1
		end
		tools[num].Weight = toolWeights[toolid]

		return iup.CLOSE
	end
end

function cancel:action()
	return iup.CLOSE
end




-- start with last tool
local id = alltools.lasttool

for i,v in ipairs(tools) do
	if v.REGS_ID == id then
		toollist.value = i
		toolname.value = v.REGS_Name
		break
	end
end

if CURSOR_POPUP ~= true then
	dlg:show()
else
	-- window pops up at a convenient place, centered on the mouse cursor
	dlg:map()
	dlgsize = iup.GetAttribute(dlg, "RASTERSIZE")
	dlgsize = { w = tonumber(string.match(dlgsize, "(%d+)x")), h = tonumber(string.match(dlgsize, "x(%d+)")) + 40}
	screensize = iup.GetGlobal("SCREENSIZE")
	screensize = { w = tonumber(string.match(screensize, "(%d+)x")), h = tonumber(string.match(screensize, "x(%d+)"))}
	pos = iup.GetGlobal("CURSORPOS")
	pos = {
		x = tonumber(string.match(pos, "(%d+)x")) - 20,
		y = tonumber(string.match(pos, "x(%d+)")) - 5,
	}
	-- make sure dialog is fully visible on screen
	pos.x = math.max(5, math.min(screensize.w - dlgsize.w - 8, pos.x))
	pos.y = math.max(5, math.min(screensize.h - dlgsize.h, pos.y))
	dlg:showxy(pos.x, pos.y)
end

toolname.selection = "1:1000"

status,err = pcall(iup.MainLoop)

dlg:destroy()

-- Do the AddTool() after the iup dialog has closed, otherwise some fighting
-- over window focus happens, causing a deadlock within Windows
if toolid ~= nil then
--	print("chosen tool: " .. toolid)
	if string.find(toolid:lower(), "%.setting$") then
		comp:Paste(eyeon.readfile(toolid))
	elseif string.find(toolid:lower(), "%.eyeonscript$") or string.find(toolid:lower(), "%.py$") then
		comp:RunScript(toolid)
	else
		local tool = comp:AddTool(toolid, true, -32768, -32768)
	end
	globals.__addtool_weights = CopyTable(toolWeights)
	globals.__addtool_data.lasttool = toolid
	
	-- save weights to disk
	doPrefs("Add Tool X", false, "CompFu", toolWeights)
end


if not status then
	print(err)
end

