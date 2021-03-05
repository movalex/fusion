--[[  
    Rename Plus script
Description:
    Rename any tool
Author:
    Alexey Bogomolov
License:
    MIT
    Copyright 2020 Alexey Bogomolov
Email:
    mail@abogomolov.com
Features:
    * rename Underlay only
    * apply existing tool name
    * tool name can start with a number ("_" is prepended)
    * cancel renaming sequence with Cancel button
    * batch rename tools (numbers _01, _02... appended)
Version history:
    v1.3: add start UI next to the mouse pointer
    v1.4: launch on any Fusion window
    v1.5: prevent multiple windows, set UI boundaries to prevent launch beyond screen
    v1.7: rename loaders properly, add batch rename function
    v1.8: batch rename will properly close the UI after rename
    v1.9: update ToolTagger data on a tool rename
]]
--

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local ui_width, ui_height = 300,78


app:AddConfig("renameplus", {
    Target {
        ID = "renameplus",
    },
    Hotkeys {
        Target = "renameplus",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
    },
})

window_dimensions = fusion:GetPrefs("Global.Main.Window")
if not window_dimensions or window_dimensions.Width == -1 then
    print("[Warning] The Window preference is undefined.\nPlease press 'Grab program layout' in the Layout Preference section")
    window_dimensions.Width = 1920
    window_dimensions.Height = 1100
end
if window_dimensions.Width > 10000 then
    print("Apparently Fusion has incorrect window dimensions. Press 'Grab program layout' in the Layout Preference section")
    window_dimensions.Width = 1920
    window_dimensions.Height = 1100
end

mouseX = fu:GetMousePos()[1]
mouseY = fu:GetMousePos()[2]

if window_dimensions.Width - mouseX < ui_width then
    mouseX = mouseX - ui_width
end

if window_dimensions.Height - mouseY < ui_height then
    mouseY = mouseY - ui_height
end

function showUI(tool, cur_name)
    win = disp:AddWindow({
        ID = 'renameplus',
        TargetID = "renameplus",
        WindowTitle = 'Rename+ Tool',
        Geometry = {mouseX+20, mouseY, ui_width, ui_height},
        Spacing = 50,
        
        ui:VGroup{
        ID = 'root',
            ui:HGroup{
                ui:LineEdit {
                    ID = 'mytext', Text = tostring(cur_name),
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true},
                }
            },
            ui:HGroup{
                ui:VGap(20),
                ui:CheckBox{
                    ID = 'batch',
                    Text = 'batch rename',
                    Checked = false,
                },
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

    itm = win:GetItems()
    itm.mytext:SelectAll()
    
    function fixTags(toolName, newName)
        local data = comp:GetData("ToolManager")
        if data then
            for tag, toolNames in pairs(data) do
                for index, dataToolName in pairs(toolNames) do
                    if dataToolName == toolName then
                        data[tag][index] = newName
                    end
                end
            end
            comp:SetData("ToolManager", data)
        end
    end

    function batchRename(tools)
        -- this script will rename selected nodes sequentially
        if not tools then
            return
        end
        if #tools < 2 then
            do_rename()
            disp:ExitLoop()
        else
            comp:StartUndo("batch rename tools")
            local count = 0
            for num, tool in ipairs(tools) do
                newName = itm.mytext:GetText() .. '_' .. string.format("%02d",num)
                fixTags(tool.Name, newName)
                tool:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = newName })
                count = count + 1
            end
            print('batch renamed ' .. count .. ' tools')
            comp:EndUndo()
            disp:ExitLoop()
            cancelled = true
        end
    end

    function win.On.cancel.Clicked(ev)
        cancelled = true
        disp:ExitLoop()
    end
    
    function win.On.renameplus.Close(ev)
       disp:ExitLoop()
    end
    
    function do_rename()
        local new_name = itm.mytext:GetText()
        if new_name == cur_name then
            -- name not changed
            return
        end
        if tonumber(string.sub(new_name, 1, 1)) ~= nil then
            print('tool\'s name can\'t start with a number, now prepending with "_"')
            new_name = '_'.. new_name
        end
        local prevName = tool.Name
        tool:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = new_name})
        -- fix tags after renaming if the same name was autoincremented by Fusion
        fixTags(prevName, tool.Name)
    end
    
    function win.On.batch.Clicked(ev)
        itm.mytext:SelectAll()
        itm.mytext:SetFocus("OtherFocusReason")
    end

    function win.On.ok.Clicked(ev)
        if itm.batch.Checked == true then
            local selectedNodes = comp:GetToolList(true)
            batchRename(selectedNodes)
        else
            do_rename()
            disp:ExitLoop()
        end
    end
    
    function win.On.mytext.ReturnPressed(ev)
        if itm.batch.Checked == true then
            local selectedNodes = comp:GetToolList(true)
            batchRename(selectedNodes)
        else
            do_rename()
            disp:ExitLoop()
        end
    end
    
    win:Show()
    disp:RunLoop()
    win:Hide()
end




local main_win = ui:FindWindow("renameplus")
if main_win then
    main_win:Raise()
    main_win:ActivateWindow()
    return
else
    comp:StartUndo("RenamePlus:")
    active = comp.ActiveTool
    if active and active.ID == 'Underlay' then
        current_name = active.Name
        showUI(active, current_name)
    else
        local selectednodes = comp:GetToolList(true)
        if #selectednodes > 0 then
            for i, tool in ipairs(selectednodes) do
                current_name = tool.Name
                showUI(tool, current_name)
                if cancelled then
                    break
                end
            end
        end
    end
    comp:EndUndo(true)
end
