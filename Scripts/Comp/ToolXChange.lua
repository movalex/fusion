_VERSION = [[Version 1.5 - Mar-06-2021]]
--[[  HEADER :

      Fusion 9.0.2 build 15 | windows 10 x64, jeremy bepoix - jeremy.bepoix@gmail.com
      Fusion 9.0.2 build 15 | ubuntu 18.04 & centOS 7
      Fusion 16 
      Fusion 17 

      v1.5 - 2021-03-06

      =====Overview======

      This script allows sharing tools, group of nodes and more 

]]--

--[[  VERSIONING :

      v1.5
      update: Alexey Bogomolov (mail@abogomolov.com)
        - search by Name for more reliable and fast filtering
        - add Date column for more reliable sorting (not ideal though)
        - tools publish by enter button
        - edit name (add EDIT button, add rename tag dialogue window)
        - filter allowed users by table (more than one username allowed to edit tools). See [c]allowedUsers[/c] variable.
        - dedicated uuid function. Looks like UUID generation is not random enough, and some tools are constantly overwritten, especially after restart. So I implemented a custom UUID generation.
        - add entry numbering (in the order of creation)
        - entry name can have spaces and capital letters
        - if there's old data found without the tool position in it, the entry will be placed at the end of the list.
        - fix numbering of the consequent entries if previous entry was deleted


      v1.4
      feedback: Alexey Bogomolov (wsl forum > www.steakunderwater.com )
        - On mac use "USER" environment
        - get current comp: pasting to any comp opened

      v1.3
        - add delete button
        - add time delta on date
        - complete description 

      v1.2
        - add replace func uuid() by embed bmd.uuid()
        - change spaghetti code
        - add findSys() to find wich system is used (thanks to Reactor creator for those lines)
        - add error balise
        - add description
      
      v1.1
        - add sanity Check (removing special character)
        - add popup warning same file written

      v1.0
        - Initial prototype.

        TODO:
        - Edit Description for existing entries
]]--


json = require "dkjson"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 800,700
local allowedUsers = {"abogomolov"}
local dlg = nil
local sep = package.config:sub(1,1) 

--========================================================================================================================
--
-- SET LAYOUT
--
--========================================================================================================================

win = disp:AddWindow({
  ID = 'toolsXchange',
  WindowTitle = "ToolXChange  ".._VERSION,
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
        ui:Tree{ID = 'TreeUI', SortingEnabled=true, UniformRowHeights=false, Events = {ItemDoubleClicked=true, ItemClicked=true,},},
        },
        
    ui:HGroup{
        Weight = 0.1,
        ui:LineEdit{ID='LineEditUI', PlaceholderText = 'Name your tool ...', Events = {ReturnPressed = true, EditingFinished = true}},
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
        ui:Button{ID = 'editButton', Text = 'EDIT',},
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

if not comp then
    comp = fu.CurrentComp
end

fuProfile = comp:MapPath('Profile:\\')
platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")
searchFilterText = ""
itm = win:GetItems()


function repoPath()
    -- find if ".config" file present in "Profile:"
    repodir = bmd.readdir(fuProfile .. "*.config")
    for i, f in ipairs(repodir) do
        filename = tostring(f.Name)
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
        print("[Error] There is an unknown Fusion platform detected")
        return
    end
end

---------------------------------------------------------------------------------------------------------
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
-- 
-- get a unique ID for the JSON nomenclature to create
--
---------------------------------------------------------------------------------------------------------

local function uuid()
    local random = math.random
    math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(math.random(), 0xf) or random(math.random(), 0xb)
        return string.format('%x', v)
    end)
end

---------------------------------------------------------------------------------------------------------
-- 
-- write json file function
-- 
--------------------------------------------------------------------------------------------------------- 

function writeJsonFile(filePath, data)
    -- encode JSON & save-it
    local jsonEncode = json.encode(data, {indent = true})
    local json_file = io.open(filePath, "w")
    json_file:write(tostring(jsonEncode))
    io.close(json_file)
end

---------------------------------------------------------------------------------------------------------
-- 
-- create json file structure
-- 
--------------------------------------------------------------------------------------------------------- 

function createJson()
    nameID = uuid()
    comp = fu.CurrentComp

    local nodes = bmd.writestring(comp:CopySettings(comp:GetToolList(true)))

    -- prompt red text.line.edit if user won't named a selection
    if itm.LineEditUI.Text == "" then 
        itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
        itm.LineEditUI:SetText("please, name your selection ...")
        print('[Warning] no name mention')
        bmd.wait(2)
        clearUI()
        return  
    -- prompt red text.line.edit if user won't select a tool
    elseif string.len(nodes) <= 27 then 
        itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
        itm.LineEditUI:SetText("please, select tools and name it...")
        print('[Warning] no tool selected')
        bmd.wait(2)
        clearUI()
        return
    -- create JSON with this data : num, users, usersToolName, usersToolComment, toolRaw, toolDate, toolPathBaseName, toolPathName
    else --string.len(nodes) >= 30 then 
        -- itm.LineEditUI.Text = itm.LineEditUI.Text:gsub('[%p%c%s]', '') -- disabled
        json_fileName = tostring(nameID)..".json"
        -- create table with main data
        tbl = {
            num = { tostring(#jsonList + 1) },
            users = { user:lower() },
            usersToolName = { itm.LineEditUI.Text },
            usersToolComment = { itm.userToolComment.PlainText },
            toolRaw = { nodes },
            toolDate = { os.date('%m-%d-%Y|%H:%M:%S') },
            toolPathBaseName = { REPOSITORY_FOLDER },
            toolPathName = { json_fileName }
            }

        writeJsonFile(REPOSITORY_FOLDER..sep..json_fileName, tbl)

    end
    -- if all good, user return with green line.
    itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.34, G=0.6, B=0.34, A=1.0 })
    itm.LineEditUI:SetText("Published!")    
end

---------------------------------------------------------------------------------------------------------
-- 
-- create tree View and populate with Json file data
--
---------------------------------------------------------------------------------------------------------

function populateTree()
    -- init TreeView
    itm.UpdatesEnabled = false
    itm.SortingEnabled = false
    itm.TreeUI:Clear()
    lastID = 0
    number = #jsonList
    fixData = {}
    for i,v in ipairs(jsonList) do
        -- search filter func
        if #searchFilterText == 0 or v.usersToolName[1]:lower():match(searchFilterText:lower()) then
            if not v.num then
                table.insert(fixData, v)
                number = number + 1
            else
                number = tonumber(v.num[1])
                lastID = lastID + 1
            end
            itm.TreeUI:SetHeaderLabels({'#','Author', 'Name', 'Description','Date', 'Created','toolRaw','toolPathName', 'toolPathBaseName' })
            -- Number of columns in the Tree list after SetHeaderItem to hide not registred (toolRaw, toolPathName, toolPathBaseName )
            itm.TreeUI.ColumnCount = 6
            -- Resize the Columns
            itm.TreeUI.ColumnWidth[0] = 40
            itm.TreeUI.ColumnWidth[1] = 100
            itm.TreeUI.ColumnWidth[2] = 180
            itm.TreeUI.ColumnWidth[3] = 250
            itm.TreeUI.ColumnWidth[4] = 100
            itm.TreeUI.ColumnWidth[5] = 100
            -- creat columns
            itmSettingsFile = itm.TreeUI:NewItem();
            -- append data of Json 
            itmSettingsFile.Text[0] = string.format("%02d", number);
            itmSettingsFile.Text[1] = v.users[1];
            itmSettingsFile.Text[2] = v.usersToolName[1];
            itmSettingsFile.Text[3] = v.usersToolComment[1];
            -- get time delta creation
            itmSettingsFile.Text[4] = GetDate(v.toolDate[1])
            itmSettingsFile.Text[5] = get_time_difference(v.toolDate[1])
            -- create unregistred columns with data 
            itmSettingsFile.Text[6] = v.toolRaw[1] --not registred, only data use
            itmSettingsFile.Text[7] = v.toolPathName[1] --not registred, only data use
            itmSettingsFile.Text[8] = v.toolPathBaseName[1] --not registred, only data use
            -- add toolName tooltips
            itmSettingsFile.ToolTip[1] = v.toolPathName[1]
            itmSettingsFile.ToolTip[2] = v.toolPathName[1]
            itmSettingsFile.ToolTip[3] = v.toolPathName[1]
            -- sorting columns & order
            itm.TreeUI:AddTopLevelItem(itmSettingsFile)
            itm.TreeUI:SortByColumn(0, "AscendingOrder")
        end
    end

    if #fixData > 0 then
        print("No entry ID found in ".. #fixData .. " file(s)")
        for i, data in pairs(fixData) do
            lastID = lastID + 1
            print("adding ID: " .. lastID)
            data["num"] = {lastID}
            writeJsonFile(REPOSITORY_FOLDER..sep..data.toolPathName[1], data)
        end
        populateTree()
    end
    itm.UpdatesEnabled = true
    itm.SortingEnabled = true
end


---------------------------------------------------------------------------------------------------------
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
    elseif et.mins >= 0 then
        outString = et.mins..minsText..'ago'
    else
        outString = "0 minutes ago"
    end
    
    return outString
end

function GetDate(jsonTime)
    formatPattern = '^(%d+)-(%d+)-(%d+)|' 
    month, day, year = jsonTime:match(formatPattern)
    return year .. '-' .. month .. "-" .. day
end

---------------------------------------------------------------------------------------------------------
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
        itm.toolsXchange.WindowTitle = "ToolXChange | Searching for \"" .. tostring(searchFilterText) .. "\""
    else
        itm.toolsXchange.WindowTitle = "ToolXChange  ".._VERSION
    end
end

---------------------------------------------------------------------------------------------------------
-- 
-- Paste tool when user doubleClicks on Item 
--
---------------------------------------------------------------------------------------------------------

function win.On.TreeUI.ItemDoubleClicked(ev)
    local comp = fu:GetCurrentComp()
    comp:Paste(bmd.readstring(tostring(ev.item.Text[6])))
end

---------------------------------------------------------------------------------------------------------
-- 
-- Clean tool Name & tool Comment
--
---------------------------------------------------------------------------------------------------------

function clearUI()
    itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.16, G=0.15, B=0.17, A=1.0 })
    itm.userToolComment:Clear()
    itm.LineEditUI:Clear()
end

---------------------------------------------------------------------------------------------------------
-- 
-- dependent func : ReadJson(), populateTree(), clearUI()
-- publish tool
--
--------------------------------------------------------------------------------------------------------- 

function DoPublish()
    createJson()
    bmd.wait(1)
    ReadJson()
    populateTree()
    clearUI()
end

function win.On.publishButton.Clicked(ev)
    DoPublish()
end

function win.On.LineEditUI.ReturnPressed(ev)
    DoPublish()
end

---------------------------------------------------------------------------------------------------------
-- 
-- get selectedItem for deleteButton()
--
--------------------------------------------------------------------------------------------------------- 

function win.On.TreeUI.ItemClicked(ev)
    selectedItem = ev.item.Text[8] .. sep .. ev.item.Text[7]
    print(ev.item.Text[7])
    selectedUser = ev.item.Text[1]
    selectedID = ev.item.Text[0]
end

---------------------------------------------------------------------------------------------------------
-- 
-- check if lua table has sertain value
-- 
--------------------------------------------------------------------------------------------------------- 

function HasValue(tab, val)
    for i, j in pairs(tab) do
        if j == val then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------------------------------------
-- 
-- edit Tree entry, launches separate window, blocking main window from editing
-- 
--------------------------------------------------------------------------------------------------------- 

function win.On.editButton.Clicked(ev)
    if not selectedItem then
        print("select the item to edit")
        return
    end

    if not bmd.fileexists(selectedItem) then
        print('JSON file not found. Trying to fix file path...')
        parse = bmd.parseFilename(selectedItem)
        parse.FullPath = REPOSITORY_FOLDER
        selectedItem = parse.FullPath..sep..parse.FullName
        print("Found new path: " .. selectedItem)
    end
    
    local file = io.open(selectedItem, "r")
    local ret = file:read("*all")
    local decodeJson = json.decode( ret )
    file:close()
    local name = decodeJson.usersToolName[1]
    win:SetEnabled(false)

    dlg = disp:AddWindow({
        ID = 'edit',
        TargetID = "edit",
        WindowTitle = 'Rename+ Tool',
        Geometry = {500, 400, 200, 100},
        ui:VGroup{
        ID = 'root',
            ui:HGroup{
                ui:LineEdit {
                    ID = 'renameLine', Text = name,
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true},
                }
            },
         ui:HGroup{
            ui:VGap(20),
            ui:Button{
                ID = 'cancel', Text = 'Cancel',
                Weight = .7,
                },
                ui:Button{
                ID = 'ok', Text = 'Ok',
                Weight = .3,
                
                }
            }
        }
    })

    dlg:Show()
    itm_edit = dlg:GetItems()
    itm_edit.renameLine:SelectAll()

    function dlg.On.cancel.Clicked(ev)
        dlg:Hide()
        win:SetEnabled(true)
    end
    function dlg.On.edit.Close(ev)
        dlg:Hide()
        win:SetEnabled(true)
    end
        
    function DoRename()
        decodeJson.usersToolName[1] = itm_edit.renameLine.Text
        decodeJson.users[1] = user
        if parse then
            decodeJson.toolPathBaseName[1] = parse.FullPath
        end
        writeJsonFile(selectedItem, decodeJson)
        dlg:Hide()
        win:SetEnabled(true)
        ReadJson()
        populateTree()
    end

    function dlg.On.ok.Clicked(ev)
        DoRename()
    end    

    function dlg.On.renameLine.ReturnPressed(ev)
        DoRename()
    end
end

---------------------------------------------------------------------------------------------------------
-- 
-- match if user is a creator and delete
--
---------------------------------------------------------------------------------------------------------

function win.On.deleteButton.Clicked(ev)
    if not selectedItem then
        print("select the item to delete")
        return
    end
    table.insert(allowedUsers, user)
    if not HasValue(allowedUsers, selectedUser) then
        itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.66, G=0.3, B=0.3, A=1.0 })
        itm.LineEditUI:SetText("your are not the creator of this tool")
        print('[Error] : your are not the creator of this tool')
        bmd.wait(2)
        clearUI()
        return
    end
    if not bmd.fileexists(selectedItem) then
        print('JSON file not found')
        parse = bmd.parseFilename(selectedItem)
        parse.FullPath = REPOSITORY_FOLDER
        local sep = package.config:sub(1,1) 
        selectedItem = parse.FullPath..sep..parse.FullName
        if bmd.fileexists(selectedItem) then
            print("found new path "..selectedItem)
        end
    end
    
    -- decrease each consequent entry number if previous entry was deleted
    for i, entry in pairs(jsonList) do
        if entry.num and tonumber(entry.num[1]) > tonumber(selectedID) then
            entry.num[1] = tonumber(entry.num[1]) - 1
            local filePath = REPOSITORY_FOLDER .. sep .. entry.toolPathName[1]
            writeJsonFile(filePath, entry)
        end
    end

    os.remove(selectedItem)
    itm.LineEditUI:SetPaletteColor("All", "Base", { R=0.34, G=0.6, B=0.34, A=1.0 })
    itm.LineEditUI:SetText("Tool deleted")
    print('[Info] : '..user..' deleted tool : '..selectedItem)

    bmd.wait(.6)
    clearUI()

    -- refresh TreeItem
    
    ReadJson()
    populateTree()
    clearUI()
end



---------------------------------------------------------------------------------------------------------
-- 
-- open Repository folder
--
---------------------------------------------------------------------------------------------------------

function win.On.repoButton.Clicked(ev)
    bmd.openfileexternal("Open", REPOSITORY_FOLDER)
end

---------------------------------------------------------------------------------------------------------
-- 
-- close window
--
-----------------------------------------------------------------------------------------------------------

function win.On.toolsXchange.Close(ev)
    disp:ExitLoop()
end

---------------------------------------------------------------------------------------------------------
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
