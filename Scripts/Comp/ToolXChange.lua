_VERSION = [[Version 1.4 - Septembre 2, 2019]]
--[[  HEADER :

      Fusion 9.0.2 build 15 | windows 10 x64, jeremy bepoix - jeremy.bepoix@gmail.com
      Fusion 9.0.2 build 15 | ubuntu 18.04 & centOS 7
      Fusion 16 on MacOSX

      v1.4 - 2019-09-02

      =====Overview======

      This script allows to share tool, group of nodes and more 


]]--

--[[  VERSIONING :

	  v1.4
	  feedback : Movalex (wsl forum > www.steakunderwater.com )
	  	- On mac use "USER" environment
	  	- get current comp : pasting to any comp opened

	  v1.3
	  add delete button
	  add time delta on date
	  complete description 

	  v1.2
	  add replace func uuid() by embed bmd.uuid()
	  change spaghetti code
	  add findSys() to find wich system is used (thanks to Reactor creator for those lines)
	  add error balise
	  add description
      
	  v1.1
	  add sanity Check (removing special character)
	  add popup warning same file written

	  v1.0
      Initial prototype.
]]--


--[[  TODO :

    - submit by enter  

]]--

json = require "dkjson"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 800,700


--========================================================================================================================
--
-- SET LAYOUT
--
--========================================================================================================================

win = disp:AddWindow({
  ID = 'toolsXchange',
  WindowTitle = "toolsXchange  ".._VERSION,
  Geometry = {100, 100, width, height},
  
  ui:VGroup{
    ID = 'root',

    ui:HGroup{
		Weight = 0,

		ui:Button
		{
			Weight = 0,

			MinimumSize = { 24, 24 },

			Text = "\xF0\x9F\x94\x8D",
			Flat = true,
			ID = "SearchButton",
			Font = ui:Font{ Family = "Symbola", PixelSize = 14 },
		},
		ui:LineEdit
		{
			ID = "SearchText",
		},
	},

	ui:HGroup{
		Weight = 3,
		ui:Tree{ID = 'FileFinder', SortingEnabled=true, UniformRowHeights=true, Events = {ItemDoubleClicked=true, ItemClicked=true,},},
		},
		
	ui:HGroup{
		Weight = 0.1,
		ui:LineEdit{ID='userToolName', PlaceholderText = 'Name your tool ...', },
		},

	ui:HGroup{
		Weight = 0.5,
	    ui:TextEdit{
			ID = 'userToolComment',
			PlaceholderText = 'Add a description ...',
	        Font = ui:Font{
	          Family = 'Droid Sans Mono',
	          StyleName = 'Regular',
	          PixelSize = 12,
	          MonoSpaced = true,
	          StyleStrategy = {ForceIntegerMetrics = true},
				},
			},
	    },

	ui:HGroup{
		Weight = 0.1,
		ui:Button{ID = 'publishButton', Text = 'PUBLISH',},
		ui:Button{ID = 'deleteButton', Text = 'DELETE',},
		ui:Button{ID = 'repoButton', Text = 'OPEN REPOSITORY',},
  	},

	},
})


--========================================================================================================================
--
-- FIRST START & REPOSITIRY SETUP
--
--========================================================================================================================


---------------------------------------------------------------------------------------------------------
-- repoPath()
-- 
-- search if ".config" file present in "Profile:" directory
--
---------------------------------------------------------------------------------------------------------
fuProfile = comp:MapPath('Profile:\\')
platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")
searchFilterText = ""
itm = win:GetItems()


function repoPath()
	-- find if ".config" file present in "Profile:"
	repodir = bmd.readdir(fuProfile .. "*.config")
	for i, f in ipairs(repodir) do
		filename = tostring(f.Name)
		print(filename)
	end
	-- if not create config file wih firstStart() function
	if filename == nil then
		firstStart()
	else
		repofile = io.open(fuProfile.."toolXchange.config", "r")
		ret = repofile:read("*all")
		REPOSITORY_FOLDER = comp:MapPath(ret)
	end
end

---------------------------------------------------------------------------------------------------------
-- firstStart()
-- 
-- Run window for path request, and create "toolXchange.config" file
--
---------------------------------------------------------------------------------------------------------
function firstStart()
	local width,height = 800,120
	first_start_win = disp:AddWindow({
		ID = 'firststart',
		WindowTitle = 'Choose repository folder',
		Geometry = {100, 100, width, height},

		ui:VGroup{
			ID = 'root',
			ui:TextEdit{
				ID = 'FirstStartLbl',
				Text = "This window appears during the first start, select a folder that will act as a repository : ",
				Font = ui:Font{
					Family = 'Droid Sans Mono',
					-- Family = 'Tahoma',
					StyleName = 'Regular',
					PixelSize = 14,
					MonoSpaced = true,
					StyleStrategy = {ForceIntegerMetrics = true},
					},
				ReadOnly = true,
				Weight = 0,
				},
		ui:HGroup{	  
			ui:Label{
				ID='FolderTxt',
				Text = 'Please Enter a folder path.',
				Weight = 1.25,
				},			  
			ui:Button{
				ID = 'FolderButton', 
				Text = 'Select a Folder',
				Weight = 0.25,
				},
			},
		},
	})

	itm_fs = first_start_win:GetItems()

	-- The window was closed
	function first_start_win.On.firststart.Close(ev)
		disp:ExitLoop()
	end

	-- The Open Folder button was clicked
	function first_start_win.On.FolderButton.Clicked(ev)
		selectedPath = tostring(fu:RequestDir('Scripts:/Comp'))
		itm_fs.FolderTxt.Text = selectedPath

		-- create file "toolXchange.config" with path inside
		conf_file = io.open(fuProfile.."toolXchange.config", "w")
		conf_file:write(tostring(selectedPath:gsub("\\","/")))
		io.close(conf_file)

		REPOSITORY_FOLDER = selectedPath:gsub("\\","/")

		disp:ExitLoop()
	end


	
	first_start_win:Show()
	disp:RunLoop()
	first_start_win:Hide()
	

end


--========================================================================================================================
--
-- MAIN FUNC
--
--========================================================================================================================



---------------------------------------------------------------------------------------------------------
-- findSys()
-- 
-- search the operating system, to determine the user
--
---------------------------------------------------------------------------------------------------------
function findSys()
	if platform == "Windows" then
		user = os.getenv("USERNAME")
	elseif platform == "Mac" then
		user = os.getenv("USER")
	elseif platform == "Linux" then
		user = os.getenv("USER")
	else
		print("[Error] There is an invalid Fusion platform detected")
		return
	end
end



---------------------------------------------------------------------------------------------------------
-- ReadJson() > require "dkjson"
-- 
-- read all JSON in the 'REPOSITORY_FOLDER' directory, decodes the JSONs and puts them in a list
--
---------------------------------------------------------------------------------------------------------
function ReadJson()
	jsonList = {}

	-- find if '.json' file exist on rootPath
	local rootdir = bmd.readdir(REPOSITORY_FOLDER .. "*.json")

	-- find it then decode & put them to a list
	for i,v in ipairs(rootdir) do
		jsonPath = REPOSITORY_FOLDER..v.Name

		local file = io.open(jsonPath, "r")
		local ret = file:read("*all")
		local decodeJson = json.decode( ret )
		file:close()
		table.insert(jsonList, decodeJson)		
	end
end



---------------------------------------------------------------------------------------------------------
-- createJson()
-- 
-- get a unique ID for the JSON nomenclature to create
--
---------------------------------------------------------------------------------------------------------
function createJson()
	nameID = bmd.getappuuid()
	cmp = fusion.CurrentComp

	local nodes = bmd.writestring(cmp:CopySettings())

	-- prompt red text.line.edit if user won't named a selection
	if itm.userToolName.Text == "" then 
		itm.userToolName:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
		itm.userToolName:SetText("please, name your selection ...")
		print('[Warning] no name mention')
		bmd.wait(2)
		clearUI()
		return	
	-- prompt red text.line.edit if user won't select a tool
	elseif string.len(nodes) <= 27 then 
		itm.userToolName:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
		itm.userToolName:SetText("please, select tools and name it...")
		print('[Warning] no tool selected')
		bmd.wait(2)
		clearUI()
		return
	-- create JSON with this data : users, usersToolName, usersToolComment, toolRaw, toolDate, toolPathBaseName, toolPathName
	else --string.len(nodes) >= 30 then	
		itm.userToolName.Text = itm.userToolName.Text:gsub('[%p%c%s]', '')
		json_fileName = tostring(nameID)..".json"
		-- creat table with main data
		tbl = {
	  		users = { user:lower() },
	  		usersToolName = { itm.userToolName.Text:lower() },
	  		usersToolComment = { itm.userToolComment.PlainText:lower() },
	  		toolRaw = { nodes },
	  		toolDate = { os.date('%m-%d-%Y|%H:%M:%S') },
	  		toolPathBaseName = { REPOSITORY_FOLDER },
	  		toolPathName = { json_fileName }
			}
		-- encode JSON & save-it
		local jsonEncode = json.encode (tbl, { indent = true })
		json_file = io.open(REPOSITORY_FOLDER..json_fileName, "w")
		json_file:write(tostring(jsonEncode))
		io.close(json_file)
	end
	-- if all good, user return with green line.
	itm.userToolName:SetPaletteColor("All", "Base", { R=0.34, G=0.6, B=0.34, A=1.0 })
	itm.userToolName:SetText("Published...")	
end


---------------------------------------------------------------------------------------------------------
-- MatchFilter()
-- 
-- search bar filter
--
---------------------------------------------------------------------------------------------------------
function MatchFilter(t, filter)
	for i,v in pairs(t) do
		if type(v) == "string" or type(v) == "number" then
			if tostring(v):lower():match(filter) then
				return true
			end
		elseif type(v) == "table" then
			if MatchFilter(v, filter) then
				return true
			end
		end
	end

	return false
end


---------------------------------------------------------------------------------------------------------
-- populateTree()
-- 
-- creat tree View and populate with Json file data
--
---------------------------------------------------------------------------------------------------------
function populateTree()
	-- init TreeView
	itm.UpdatesEnabled = false
	itm.SortingEnabled = false
	itm.FileFinder:Clear()

	for i,v in ipairs(jsonList) do
		-- search filter func
		if #searchFilterText == 0 or MatchFilter(v, searchFilterText:lower()) then
			itm.FileFinder:SetHeaderLabels({'Author', 'Name', 'Description','Date', 'toolRaw','toolPathName', 'toolPathBaseName' })
			-- Number of columns in the Tree list after SetHeaderItem to hide not registred (toolRaw, toolPathName, toolPathBaseName )
			itm.FileFinder.ColumnCount = 4
			-- Resize the Columns
			itm.FileFinder.ColumnWidth[0] = 100
			itm.FileFinder.ColumnWidth[1] = 180
			itm.FileFinder.ColumnWidth[2] = 350
			itm.FileFinder.ColumnWidth[3] = 100
			-- creat columns
			itmSettingsFile = itm.FileFinder:NewItem();
			-- append data of Json 
			itmSettingsFile.Text[0] = v.users[1];
			itmSettingsFile.Text[1] = v.usersToolName[1];
			itmSettingsFile.Text[2] = v.usersToolComment[1];
			-- get time delta creation
			itmSettingsFile.Text[3] = get_time_difference(v.toolDate[1])
			-- creat unregistred columns with data 
			itmSettingsFile.Text[4] = v.toolRaw[1] --not registred, only data use
			itmSettingsFile.Text[5] = v.toolPathName[1] --not registred, only data use
			itmSettingsFile.Text[6] = v.toolPathBaseName[1] --not registred, only data use
			-- add toolName tooltips
			itmSettingsFile.ToolTip[0] = v.toolPathName[1]
			itmSettingsFile.ToolTip[1] = v.toolPathName[1]
			itmSettingsFile.ToolTip[2] = v.toolPathName[1]
			-- sorting columns & order
			itm.FileFinder:AddTopLevelItem(itmSettingsFile)
			itm.FileFinder:SortByColumn(3, "AscendingOrder")
		end
	end
	itm.UpdatesEnabled = true
	itm.SortingEnabled = true
end


---------------------------------------------------------------------------------------------------------
-- get_time_difference()
-- 
-- get time delta between JsonFile date and Now
--
---------------------------------------------------------------------------------------------------------
function get_time_difference(jsonTime)
	-- date format : 08-16-2019|21:24:00
	formatPattern = '^(%d+)-(%d+)-(%d+)|(%d+):(%d+):(%d+)$' 
	month, day, year, hour, min, sec = jsonTime:match(formatPattern)
	timeStamp = os.time({month=month, day=day, year=year, hour=hour, min=min, sec=sec})
	elapsedSeconds = os.time(os.date('*t')) - timeStamp	
	et = ConvertSeconds(elapsedSeconds)	
	if et.days == 1 then daysText = ' day ' else daysText = ' days ' end
	if et.hours == 1 then hoursText = ' hour ' else hoursText = ' hours ' end
	if et.mins == 1 then minsText = ' minute ' else minsText = ' minutes ' end
	
	if et.days > 0 then
		outString = et.days..daysText..'ago'
	elseif et.hours > 0 then
		outString = et.hours..hoursText..'ago'
	elseif et.mins > 0 then
		outString = et.mins..minsText..'ago'
	else
		outString = "A few seconds ago"
	end
	
	return outString
end


---------------------------------------------------------------------------------------------------------
-- ConvertSeconds()
-- 
-- dependent to get_time_difference() convert time to second and deliver day, hour, min
--
---------------------------------------------------------------------------------------------------------
function ConvertSeconds(secondsArg)    
	local daysDiff = math.floor(secondsArg / 86400)
	local hoursDiff = math.floor(secondsArg / 3600)
	local minsDiff = math.floor(secondsArg / 60)
	local elapsedTable = {days=daysDiff, hours=hoursDiff, mins=minsDiff}	
	
	return elapsedTable	
end


---------------------------------------------------------------------------------------------------------
-- Event SearchButton.Clicked() & SearchText.TextChanged()
-- 
-- when search button Clicked set text to none to pass with the TextChanged
--
---------------------------------------------------------------------------------------------------------
function win.On.SearchButton.Clicked(ev)
		itm.SearchText.Text = ""
	itm.SearchText:SetFocus("OtherFocusReason")
end

function win.On.SearchText.TextChanged(ev)
	searchFilterText = ev.Text
	itm.SearchButton.Text = (searchFilterText == "") and "\xF0\x9F\x94\x8D" or "\xF0\x9F\x97\x99",
	populateTree()

	if searchFilterText and searchFilterText ~= "" then
		itm.toolsXchange.WindowTitle = "toolsXchange | Searching for \"" .. tostring(searchFilterText) .. "\""
	else
		itm.toolsXchange.WindowTitle = "toolsXchange  ".._VERSION
	end
end


---------------------------------------------------------------------------------------------------------
-- Event FileFinder.ItemDoubleClicked()
-- 
-- Paste tool when user doubleClic on Item 
--
---------------------------------------------------------------------------------------------------------
function win.On.FileFinder.ItemDoubleClicked(ev)
	local cmp = fu:GetCurrentComp()
    cmp:Paste(bmd.readstring(tostring(ev.item.Text[4])))
end


---------------------------------------------------------------------------------------------------------
-- clearUI()
-- 
-- Clean tool Name & tool Comment
--
---------------------------------------------------------------------------------------------------------
function clearUI()
	itm.userToolName:SetPaletteColor("All", "Base", { R=0.16, G=0.15, B=0.17, A=1.0 })
	itm.userToolComment:Clear()
	itm.userToolName:Clear()
end



---------------------------------------------------------------------------------------------------------
-- Event publishButton.Clicked()
-- 
-- dependent func : ReadJson() , populateTree() , clearUI()
--
-- publish tool  
--------------------------------------------------------------------------------------------------------- 
function win.On.publishButton.Clicked(ev)
	createJson()
	bmd.wait(1)
	ReadJson()
	populateTree()
	clearUI()
end



---------------------------------------------------------------------------------------------------------
-- Event FileFinder.ItemClicked()
-- 
-- get selectedItem for deleteButton()
--
----------------------------------------------------------------------------------------------------------- 
function win.On.FileFinder.ItemClicked(ev)
	selectedItem = ev.item.Text[6]..'\\'..ev.item.Text[5]
	selectedUser = ev.item.Text[0]
end



---------------------------------------------------------------------------------------------------------
-- Event deleteButton.Clicked()
-- 
-- match if user are creator and delete
--
-----------------------------------------------------------------------------------------------------------
function win.On.deleteButton.Clicked(ev)
	if selectedUser == user then
		os.remove(selectedItem)
		itm.userToolName:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
		itm.userToolName:SetText("Tool deleted")
		print('[Info] : '..user..' deleted tool : '..selectedItem)
		bmd.wait(2)
		clearUI()
	else
		itm.userToolName:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
		itm.userToolName:SetText("your are not the creator of this tool")
		print('[Error] : your are not the creator of this tool')
		bmd.wait(2)
		clearUI()
		return
	end
	-- refresh, 
	ReadJson()
	populateTree()
	clearUI()
end



---------------------------------------------------------------------------------------------------------
-- Event repoButton.Clicked()
-- 
-- open Repository folder
--
-----------------------------------------------------------------------------------------------------------
function win.On.repoButton.Clicked(ev)
	bmd.openfileexternal("Open", REPOSITORY_FOLDER)
end



---------------------------------------------------------------------------------------------------------
-- Event toolsXchange.Close()
-- 
-- close window
--
-----------------------------------------------------------------------------------------------------------
function win.On.toolsXchange.Close(ev)
    disp:ExitLoop()
end



---------------------------------------------------------------------------------------------------------
-- Main()
-- 
-- Main run script
--
-----------------------------------------------------------------------------------------------------------
function Main()
	repoPath()
	findSys()
	ReadJson()
	populateTree()
end


Main()


win:Show()
itm.userToolComment:SetPaletteColor("All", "Base", { R=0.12, G=0.12, B=0.12, A=1.0 })
disp:RunLoop()
win:Hide()
