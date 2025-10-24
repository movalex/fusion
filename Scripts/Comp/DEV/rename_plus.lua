--[[  
    Rename Plus script
Description:
    Rename any tool
Author:
    Alexey Bogomolov
License:
    The authors hereby grant permission to use, copy, and distribute this
    software and its documentation for any purpose, provided that existing
    copyright notices are retained in all copies and that this notice is
    included verbatim in any distributions. Additionally, the authors grant
    permission to modify this software and its documentation for any
    purpose, provided that such modifications are not distributed without
    the explicit consent of the authors and that existing copyright notices
    are retained in all copies.

    IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
    DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
    OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES
    THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

    THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
    THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND
    DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
    UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
    Copyright 2024 Alexey Bogomolov
Email:
    mail@abogomolov.com
Features:
    * rename Underlays only
    * apply existing tool name (will be autoincremented)
    * tool name can start with a number ("_" is prepended)
    * cancel renaming sequence with Cancel button
    * batch rename tools (numbers _01, _02... appended)
    * fix name serialization
Version history:
    v1.3: add start UI next to the mouse pointer
    v1.4: launch on any Fusion window
    v1.5: prevent multiple windows, set UI boundaries to prevent launch beyond screen
    v1.7: rename loaders properly, add batch rename function
    v1.8: batch rename will properly close the UI after rename
    v1.9: update ToolTagger data on a tool rename
    v1.91: fix Resolve 17 compatibility (omit __flags data)
    v1.92: add fix serialization option to batch rename (replace ToolName1_1_1_2_3_4_5 with just ToolName for selected nodes)
    v1.93: add batch rename options
]]
--

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local ui_width, ui_height = 400,100


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
if not fu:GetResolve() then
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
        -- Spacing = 50,
        
        ui:VGroup{
        ID = 'root',
            ui:HGroup{
                ui:LineEdit {
                    ID = 'mytext', Text = tostring(cur_name),
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true},
                    Enabled = true,
                }
            },
            ui:HGroup{
                -- ui:VGap(20),
                ui:CheckBox{
                    ID = 'batch',
                    Text = 'Batch Rename',
                    Checked = false,
                },
                ui:CheckBox{
                    ID = 'fix',
                    Text = 'Enumeration',
                    Enabled = false,
                    Checked = false,
                },
                ui:ComboBox{
                    ID = 'FixMode',
                    Text = 'Fix Mode',
                    Enabled = false,
                },

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
            },
        }
    })

    itm = win:GetItems()
    itm.mytext:SelectAll()
    itm.FixMode:AddItem('Strip Numbers')
    itm.FixMode:AddItem('Enumerate')
    itm.FixMode:AddItem('Strip and Re-enumerate')
    itm.FixMode:AddItem('Add Tool ID')
    

    function fixToolManagerTags(toolName, newName)
        local data = comp:GetData("ToolManager")
        if data then
            for tag, toolNames in pairs(data) do
                if tag ~= "__flags" then
                    for index, dataToolName in pairs(toolNames) do
                        if dataToolName == toolName then
                            data[tag][index] = newName
                        end
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
            for num, t in ipairs(tools) do
                newName = itm.mytext:GetText() .. '_' .. string.format("%02d",num)
                fixToolManagerTags(t.Name, newName)
                t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = newName })
                count = count + 1
            end
            print('batch renamed ' .. count .. ' tools')
            comp:EndUndo()
            disp:ExitLoop()
            cancelled = true -- break the UI loop
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
        -- fix ToolManager tags after renaming if the same name was autoincremented by Fusion
        fixToolManagerTags(prevName, tool.Name)
    end
   
    function fixSerializing(tools)
        if #tools == 0 then
            print("no tools selected")
            return
        end
        for i, t in ipairs(tools) do
            if itm.FixMode.CurrentIndex == 0 then
                toolName = string.gsub(t.Name, "[_%d]+$", "")
            elseif itm.FixMode.CurrentIndex == 1 then
                toolName = t.Name .. "_" .. string.format("%02d", tostring(i))
            elseif itm.FixMode.CurrentIndex == 2 then
                toolName = string.gsub(t.Name, "[_%d]+$", "") .. "_" .. string.format("%02d", tostring(i)) 
            elseif itm.FixMode.CurrentIndex == 3 then
                toolName = t.Name .. "_" .. t.ID
            else
                return
            end
            t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
        end
    end

    function win.On.batch.Clicked(ev)
        itm.fix.Enabled = true
        itm.mytext:SelectAll()
        itm.mytext:SetFocus("OtherFocusReason")
    end
    
    function win.On.fix.Clicked(ev)
        itm.fix:SetFocus("OtherFocusReason")
        itm.mytext.Enabled = not itm.fix.Checked
        itm.FixMode.Enabled = itm.fix.Checked
    end

    function win.On.ok.Clicked(ev)
        if itm.batch.Checked == true then
            local selectedNodes = comp:GetToolList(true)
            if itm.fix.Checked == true then
                fixSerializing(selectedNodes)
            else
                batchRename(selectedNodes)
            end
        else
            do_rename()
        end
        disp:ExitLoop()
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
        selectedNodes = comp:GetToolList(true)
        if #selectedNodes > 0 then
            for i, tool in ipairs(selectedNodes) do
                current_name = tool.Name
                showUI(tool, current_name)
                if cancelled or itm.fix.Enabled == true then
                    break
                end
            end
        end
    end
    comp:EndUndo(true)
end
