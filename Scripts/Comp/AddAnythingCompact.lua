-- ================================
-- Compact version of "Add Anything"
-- Can only be closed with ESC or Enter

-- ### Define your options - they work the same way as those in the full "Add Anything" ###
-- 1: enabled - 0: disabled

globals.displayToolsCompact = 1
globals.displayMacrosCompact = 1
globals.displayScriptsCompact = 1

globals.caselessSortingCompact = 1

-- The list gets cached on first running of macro. If you 
-- add a tool/macro/script and need to refresh it, hit Ctrl + u.
-- (Unfortunately, F-keys don't work)
--
-- Changes to the original code by blazej/daniel are only loosely marked since so much was changed
--
-- Change history:
-- -------------------
-- Jan 27, 2012 (v2)
--    -) List can be sorted independent of case (used to be the same way "Add Tool" does it as of now - listing items starting with lower case
--       characters at the bottom of the list)
--    -) Caches and settings are seperated for "Add Tool", "Add Anything" and "Add Anything Compact". They don't overwrite each others lists 
--       any more
--    -) Files are checked strictly by ending of filename (formerly, e.g. ".lua.bak" would be found and added to the list as well, 
--       now only e.g. ".lua")
--
-- Modified by Andreas Opferkuch 
-- andreas dot opferkuch at gmx dot at
-- http://www.variations-of-shadow.com
-- Modified: Mar 06, 2011
-- ================================

-- AddTool by eyeon software
-- Modified by blazej floch
-- List restriction by daniel koch, 22-Oct-09


-- == CHANGE BEGIN ==

-- scans input path recursively and adds all files of certain filetype to list
-- filetype without "." in the beginning
function parseDir(inPath, fileType)
   local tempItems = readdir(inPath .. "*.*")
   
   local cntItems = #tempItems
   
   if cntItems > 0 then
	   for j = 1, cntItems do
		  if tempItems[j].IsDir then
			  parseDir(inPath .. tempItems[j].Name .. "\\", fileType)
			  --print(inPath .. tempItems[j].Name .. "\\")
		  elseif string.lower(string.sub(tempItems[j].Name, -#fileType)) == fileType then
			  local currName = tempItems[j].Name
		   
			  table.insert(alltools, { REGI_ClassType = fileType, REGS_ID = inPath .. currName, 
					REGS_Name = string.sub(currName, 1, #currName - #fileType - 1), 
					REGS_OpIconString = "..." } )
		  end
	   end
   end
end

function addMacros()
	pathStr = comp:GetCompPathMap()["Macros:"]

	pathStr = pathStr .. ";" .. fusion:GetGlobalPathMap()["Macros:"]

	paths = eyeon.split(pathStr, ";")
	table.sort(paths)
	cntPaths = #paths

	i = 1

	-- remove duplicate paths
	while i < cntPaths do
		if paths[i] == paths[i + 1] then
		   table.remove(paths, i + 1)
		   i = i - 1
		   cntPaths = cntPaths - 1
		end
		i = i + 1
	end
	
	for i, currPath in ipairs(paths) do
	   currPath = comp:MapPath(currPath)
	   parseDir(currPath, "setting")
	end
end

function addScripts()
	pathStr = comp:GetCompPathMap()["Scripts:"]

	pathStr = pathStr .. ";" .. fusion:GetGlobalPathMap()["Scripts:"]

	paths = eyeon.split(pathStr, ";")
	table.sort(paths)
	cntPaths = #paths

	local i = 1

	-- remove duplicate paths
	while i < cntPaths do
		if paths[i] == paths[i + 1] then
		   table.remove(paths, i + 1)
		   i = i - 1
		   cntPaths = cntPaths - 1
		end
		i = i + 1
	end
	
	for i, currPath in ipairs(paths) do
	   currPath = comp:MapPath(currPath)
	   parseDir(currPath, "lua")
	end
end

-- == CHANGE END ==

function initList()
	-- Cache tool names and IDs first time round, to avoid delays
	if globals.__addanycompact_data then
		alltools = globals.__addanycompact_data
	else
		alltools = {}
		
		if globals.displayToolsCompact == 1 then
			alltools = fu:GetRegSummary(CT_Tool)
			
			-- Fill in missing entries
			for i,v in ipairs(alltools) do
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
			end
		end
		
		-- == CHANGE BEGIN ==
		if globals.displayMacrosCompact == 1 then
			addMacros()
		end
		
		if globals.displayScriptsCompact == 1 then
			addScripts()
		end
		-- == CHANGE END ==

		alltools.lasttool = 1

		globals.__addanycompact_data = alltools
	end
end

initList()
	
tools = alltools

local otherfield = { REGS_Name = "REGS_OpIconString", REGS_OpIconString = "REGS_Name" }


function UpdateList(list, data)
	if globals.caselessSortingCompact == 1 then
		table.sort(data, function(a,b) return (string.lower(a.REGS_Name) < string.lower(b.REGS_Name)) end)
	else
		table.sort(data, function(a,b) return (a.REGS_Name < b.REGS_Name) end)
	end
	
	list[1] = nil		-- clears the list
	for i,v in ipairs(data) do
	-- == MY CHANGE BEGIN ==
		if v.REGI_ClassType == "lua" or v.REGI_ClassType == "setting" then
			list[tostring(i)] = v.REGS_Name
		else
			list[tostring(i)] = v.REGS_Name .. " (" .. v.REGS_OpIconString .. ")"
		end
	-- == MY CHANGE END ==
	end
end


-- Define our UI
local toolid = nil

local toollist = iup.list{expand="HORIZONTAL", size="x50", dropdown="NO"}

UpdateList(toollist, tools)

local toolname = iup.text{"",	expand="HORIZONTAL"}
local ok = iup.button{title = "OK", size=50, expand="NO", visible="NO"}
local cancel = iup.button{title = "Cancel", size=50, expand="NO", visible="NO"}

local dlg = iup.dialog
{
	title = "Add Anything Compact",
	foreground = "YES",
	--margin = "10x10",
	defaultenter = ok, defaultesc = cancel,
	border = "NO", minbox = "NO", maxbox = "NO", menubox = "NO", resize = "NO",
	
	iup.vbox
	{
		toolname,
		toollist,
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
	local tolist = {}
	local lowtext = string.lower(text)
	local listsize = 0
	local i,v

	-- restrict list to only those containing our text
	for i,v in ipairs(fromlist) do
		local lowname = string.lower(v.REGS_Name)
		if string.find(lowname, lowtext)								-- search the name
		  or string.find(string.lower(v.REGS_OpIconString), lowtext)	-- search the icon string
		  or string.find(string.gsub(lowname, " ", ""), lowtext) then	-- search the name with spaces removed
			listsize = listsize + 1
			tolist[listsize] = v
		end
	end
	
	UpdateList(toollist, tolist)

	-- now select one
	if listsize > 0 then
		local len = string.len(text)
		local sel = 0
		
		-- look for a match at the start of the name
		for i,v in ipairs(tolist) do
			if string.lower(string.sub(v.REGS_Name,1,len)) == lowtext then
				sel = i
				break
			end
		end
		
		if sel == 0 then
			-- look for a match at the start of the icon string
			for i,v in ipairs(tolist) do
				if string.lower(string.sub(v.REGS_OpIconString,1,len)) == lowtext then
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
	elseif key == 21 then -- CTRL + u
		globals.__addanycompact_data = nil
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

	-- == MY CHANGE BEGIN ==
	if num == 0 then return iup.CLOSE end 
	-- == MY CHANGE END ==
	
	if num <= #tools then
		local id = tools[num].REGS_ID
		
		alltools.lasttool = id
		toolid = id;

		return iup.CLOSE
	end
end

function cancel:action()
	-- dump(alltools)
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

dlg:show()

toolname.selection = "1:1000"

status,err = pcall(iup.MainLoop)

dlg:destroy()

-- Do the AddTool() after the iup dialog has closed, otherwise some fighting
-- over window focus happens, causing a deadlock within Windows
if toolid ~= nil then
	-- == MY CHANGE BEGIN ==
	if string.find(toolid, ".setting") then
		toolid = string.gsub(toolid, "\\", "\\\\")
		comp:Paste(eyeon.readfile(toolid))
	elseif string.find(toolid, ".lua") then
		toolid = string.gsub(toolid, "\\", "\\\\")
		composition:RunScript(toolid)
	else
		local tool = comp:AddTool(toolid, -32768, -32768)
	end
	-- == MY CHANGE END ==
end

globals.__addanycompact_data = alltools

if not status then
	print(err)
end
