--[[
Backup Savers Render Job script.
The script creates backup of rendered files in the given directory, retaining the folder structure. Missing folders will be created.
Should be placed to Scripts:Job folder.

Version: 1.2

Description:
0. add the script to Scripts:Job folder (such as %AppData%\Roaming\Blackmagic Design\Fusion\Scripts\Job)
1. click Pause Render before adding the comp to the queue
2. add the comp to the queue, right click the render job and click Script — Render End — backup_renders
3. resume the render
4. all files listed in the active savers will be backed up to the Backup Folder

Copyright © 2022 Alexey Bogomolov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

------------------------------
-- parse filename scriptlib function
-- folowing filepath format should be parsed correctly:
-- 101_064_040..exr
------------------------------

print("Backup renders script started")

function ParseFilename(filename)
    local seq = {}
    seq.FullPath = filename


    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", 
    function(path, name)
        seq.Path = path
        seq.FullName = name
    end)

    string.gsub(seq.FullName, "^(.+)(%..+)$", 
    function(name, ext)
        seq.Name = name
        seq.Extension = ext
    end)

    if not seq.Name then -- no extension?
    seq.Name = seq.FullName
    end

    seq.SNum = string.match(seq.Name, "%d+$")

    if seq.SNum then 
        seq.Number = tonumber( seq.SNum ) 
        seq.Padding = string.len( seq.SNum )
        seq.CleanName = string.match(seq.Name,"^(.-)%d+$")
    else
        renderStart = comp:GetAttrs().COMPN_RenderStart
        seq.SNum = tostring(renderStart)
        seq.Number = 0
        seq.Padding = 4
        seq.CleanName = seq.Name
    end

    if seq.Extension == nil then 
    seq.Extension = ""
    end
    return seq
end

------------------------------
-- check if movie format scriptlib function
------------------------------

function IsMovieFormat(extension)
    if extension ~= nil then
        if  (extension == ".avi") or
            (extension == ".vdr") or
            (extension == ".wav") or
            (extension == ".dvs") or
            (extension == ".fb" ) or
            (extension == ".omf") or
            (extension == ".omfi") or
            (extension == ".stm") or
            (extension == ".tar") or
            (extension == ".vpv") or
            (extension == ".mp4") or
            (extension == ".mxf") or 
            (extension == ".mov") then
            return true
        end
    end
    return false
end


------------------------------
-- backup location
-- should be set with fusion data and UI manager 
------------------------------

local DEFAULT_BACKUP_FOLDER = [[D:\RENDER\BACKUP\Renders]]
local root_folder = fu:GetData("BackupRenders.Root") or "Renders" -- this is a root folder all savers should use
local target = fu:GetData("BackupRenders.Folder") or DEFAULT_BACKUP_FOLDER 

------------------------------
-- folder request UI
------------------------------
function RequestFolder()

    local ui = fu.UIManager
    local disp = bmd.UIDispatcher(ui)
    local width, height = 500,100

    win = disp:AddWindow({
        ID = 'MyWin',
        WindowTitle = 'BACKUP RENDERS?',
        Geometry = {600, 300, width, height},
        Spacing = 10,
        Margin = 10,
        
        ui:VGroup{
            ID = 'root',
            Weight = 1,

            -- Open Folder
            ui:VGroup{
                ui:HGroup{
                    ui:Label{
                        Weight = 0.1,
                        ID = 'FolderLabel',
                        Text = 'Backup folder:',
                    },
                    ui:LineEdit{
                        Weight = 0.8,
                        ID='FolderLine', 
                        Text = target or " ",
                        Events = {ReturnPressed = true},
                        Alignment = {AlignCenter = true, AlignVCenter = true},
                    },
                    ui:Button{
                        ID = 'FolderButton', 
                        Text = 'Browse folder...',
                        Weight = 0.2,
                    },
                },
                ui:HGroup{
                    ui:Label{
                        Weight = 0.1,
                        ID = 'RootLabel',
                        Text = 'Root folder:',
                    },
                    ui:LineEdit{
                        Weight = 0.8,
                        ID='RootLine', 
                        Text = root_folder,
                        Events = {ReturnPressed = true},
                        Alignment = {AlignCenter = true, AlignVCenter = true},
                    },
                },
                ui:HGroup{

                    ui:Button{
                        ID = 'OkButton', 
                        Text = 'Ok',
                        Weight = 0.1,
                    },
                    ui:Button{
                        ID = 'AbortButton', 
                        Text = 'Skip Backup',
                        Weight = 0.1,
                    },
                },
            },

        },
    })

    itm = win:GetItems()
    itm.RootLine:SetClearButtonEnabled(true)    
    function skipBackup()
        print("Backup task aborted")
        disp:ExitLoop()
        result = nil
    end
    
    -- The window was closed
    function win.On.MyWin.Close(ev)
        skipBackup()
    end
    -- Abort button clicked
    function win.On.AbortButton.Clicked(ev)
        skipBackup()
    end
    
    -- OK button clicked
    function win.On.OkButton.Clicked(ev)
        backup_folder = itm["FolderLine"].Text
        root_folder = itm["RootLine"].Text
        fu:SetData("BackupRenders.Folder", backup_folder)
        fu:SetData("BackupRenders.Root", root_folder)
        disp:ExitLoop()
    end    -- The Open Folder button was clicked

    function win.On.FolderButton.Clicked(ev)
        selectedPath = fu:RequestDir(target)
        if selectedPath then
            print('[Backup location set to] :: ', tostring(selectedPath))
            itm.FolderLine.Text = selectedPath
        end
    end
    
    function win.On.FolderLine.ReturnPressed(ev)
        local result = itm["FolderLine"].Text
        fu:SetData("BackupRenders.Folder", result)
        print("new backup folder saved: ".. result)
    end

    function win.On.RootLine.ReturnPressed(ev)
        local result = itm["RootLine"].Text
        fu:SetData("BackupRenders.Root", result)
        print("new root folder saved: ".. result)
    end
    
    win:Show()
    disp:RunLoop()
    win:Hide()

    return backup_folder, root_folder
end

function GetMkdirOption()
    platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")
    mkdir_option = ''
    if platform == 'Mac' or platform == 'Linux' then
        mkdir_option = '-p '
    end
    return mkdir_option 
end

------------------------------
-- main function
------------------------------

function DoBackup(saverList)

    backup_folder, root_folder = RequestFolder()
    mkdir_option = GetMkdirOption()
    if backup_folder == nil then
        return
    end
    
    local path_separator = package.path:match( "(%p)%?%." )

    for i, saver in ipairs(savers) do
        if not saver:GetAttrs().TOOLB_PassThrough then
            clip_name = comp:MapPath(saver.Clip[1])
            parse = ParseFilename(clip_name)
            full_path = parse.FullPath
            parent = parse.Path
            target = string.gsub(parent, "(.*)"..root_folder.."(.*)", backup_folder.."%2")
            if target == parent then
                print("Could not proceed backup.\nCheck if the root folder is set correctly")
                break
            end
            print("[TARGET FOLDER] :: "..target)
            if not bmd.direxists(target) then
                os.execute("mkdir " .. mkdir_option .. target)
            end
            if not IsMovieFormat(parse.Extension) then
                -- Example: filename..exr
                sequence_pattern = parse.Path .. parse.CleanName .. "*" .. parse.Extension
                sequence_path = parse.Path .. parse.CleanName .. parse.SNum .. parse.Extension
                print('[sequence found] :: ' .. sequence_pattern)
                dir = bmd.readdir(sequence_pattern)
                print("copying ".. #dir .. " files")
                
                for i=1, #dir do
                    if not dir[i].IsDir then
                        print("[copying file] :: " .. dir.Parent .. dir[i].Name)
                        bmd.copyfile(dir.Parent..dir[i].Name, target..dir[i].Name)
                    end
                end
            else
                -- Example: filename.mp4
                print("[copying file] :: " ..full_path)
                bmd.copyfile(full_path, target..parse.FullName)
            end
        end
    print("Done!")
    end
end


comp = fu:GetCurrentComp()
savers = comp:GetToolList(false, "Saver")
DoBackup(savers)
