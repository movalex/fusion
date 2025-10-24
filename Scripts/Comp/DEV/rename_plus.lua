--[[
    Rename Plus - Advanced Tool Renaming for Fusion
    
Description:
    A comprehensive tool renaming utility for Blackmagic Fusion that provides both
    single and batch renaming capabilities with advanced enumeration options.
    
    The script opens a floating dialog near the cursor that allows users to:
    - Rename individual selected tools or underlays
    - Batch rename multiple tools with automatic sequential numbering (_01, _02, etc.)
    - Fix tool name serialization issues (removes duplicate numbers like Tool1_1_1)
    - Apply five enumeration modes:
        * Strip Numbers: Removes all trailing numbers and underscores
        * Enumerate: Adds sequential numbers to existing names
        * Strip and Re-enumerate: Removes old numbers then adds new sequential numbers
        * Strip and Enumerate by Type: Groups tools by type, removes old numbers, 
          then enumerates within each type group (e.g., Blur_01, Blur_02, Merge_01, Merge_02)
        * Add Tool ID: Appends the internal Fusion tool ID to the name
    
    The UI appears at the cursor position with smart boundary detection to stay on screen.
    Automatically updates ToolManager metadata to maintain tag associations after renaming.
    
Author:
    Alexey Bogomolov
    
Email:
    mail@abogomolov.com
    
Features:
    * Single tool rename: Rename active tool or underlay
    * Batch rename: Sequentially rename multiple selected tools with _01, _02, etc.
    * Smart name validation: Prepends "_" if name starts with a number
    * ToolManager integration: Preserves tool tags and metadata after renaming
    * Enumeration modes: Strip, enumerate, or re-enumerate tool names
    * Fusion auto-increment: Properly handles Fusion's automatic name incrementing
    * UI positioning: Opens near cursor with screen boundary detection
    * Keyboard shortcuts: ESC to cancel, Enter to confirm
    * Single instance: Prevents multiple dialog windows
    * Undo support: All operations wrapped in undo/redo
    
Usage:
    - Select tool(s) and run script
    - For single rename: Enter new name and press Enter or click OK
    - For batch rename: Check "Batch Rename", enter base name, click OK
    - For enumeration: Check "Batch Rename" and "Enumeration", select mode, click OK
    - Press ESC or click Cancel to abort
    
Version History:
    v1.93: Added batch rename options with four enumeration modes
    v1.92: Added fix serialization to remove duplicate number suffixes
    v1.91: Fixed Resolve 17 compatibility (omit __flags metadata)
    v1.9:  Added ToolTagger metadata update on rename
    v1.8:  Batch rename now properly closes UI after completion
    v1.7:  Added proper loader renaming and batch rename function
    v1.5:  Added UI boundary detection to prevent off-screen launch
    v1.4:  Enabled launching on any Fusion window
    v1.3:  Added UI positioning next to mouse pointer
    
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
]]
--

-- ============================================================================
-- CONSTANTS AND INITIALIZATION
-- ============================================================================

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local UI_WIDTH, UI_HEIGHT = 400, 100
local DEFAULT_SCREEN_WIDTH = 1920
local DEFAULT_SCREEN_HEIGHT = 1100
local MAX_VALID_WIDTH = 10000

-- Configuration: Set to true to update ToolManager tags when renaming tools
local UPDATE_TOOLMANAGER_TAGS = false

-- Configure keyboard shortcuts for the rename dialog
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

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Get window dimensions with fallback to defaults
--- @return table Window dimensions with Width and Height
local function getWindowDimensions()
    local window_dimensions = fusion:GetPrefs("Global.Main.Window")
    
    if not fu:GetResolve() then
        if not window_dimensions or window_dimensions.Width == -1 then
            print("[Warning] Window preference is undefined. Using default dimensions.")
            print("Please press 'Grab program layout' in the Layout Preference section")
            window_dimensions = {Width = DEFAULT_SCREEN_WIDTH, Height = DEFAULT_SCREEN_HEIGHT}
        elseif window_dimensions.Width > MAX_VALID_WIDTH then
            print("[Warning] Invalid window dimensions detected. Using defaults.")
            print("Please press 'Grab program layout' in the Layout Preference section")
            window_dimensions = {Width = DEFAULT_SCREEN_WIDTH, Height = DEFAULT_SCREEN_HEIGHT}
        end
    end
    
    return window_dimensions
end

--- Calculate UI position near mouse with screen boundary detection
--- @return number, number Mouse X and Y coordinates adjusted for screen boundaries
local function calculateUIPosition()
    local window_dimensions = getWindowDimensions()
    local mouseX = fu:GetMousePos()[1]
    local mouseY = fu:GetMousePos()[2]
    
    -- Adjust X position if too close to right edge
    if window_dimensions.Width - mouseX < UI_WIDTH then
        mouseX = mouseX - UI_WIDTH
    end
    
    -- Adjust Y position if too close to bottom edge
    if window_dimensions.Height - mouseY < UI_HEIGHT then
        mouseY = mouseY - UI_HEIGHT
    end
    
    return mouseX, mouseY
end

--- Update ToolManager metadata when a tool is renamed
--- @param toolName string Original tool name
--- @param newName string New tool name
local function updateToolManagerTags(toolName, newName)
    local data = comp:GetData("ToolManager")
    if not data then
        return
    end
    
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

--- Validate and fix tool name (prepend underscore if starts with number)
--- @param name string Tool name to validate
--- @return string Valid tool name
local function validateToolName(name)
    if tonumber(string.sub(name, 1, 1)) ~= nil then
        print("Tool name cannot start with a number. Prepending '_'")
        return '_' .. name
    end
    return name
end

-- ============================================================================
-- UI CREATION AND EVENT HANDLERS
-- ============================================================================

--- Show the rename UI dialog
--- @param tool table The Fusion tool to rename
--- @param cur_name string Current name of the tool
function showUI(tool, cur_name)
    local mouseX, mouseY = calculateUIPosition()
    
    win = disp:AddWindow({
        ID = 'renameplus',
        TargetID = "renameplus",
        WindowTitle = 'Rename+ Tool',
        Geometry = {mouseX + 20, mouseY, UI_WIDTH, UI_HEIGHT},
        
        ui:VGroup{
            ID = 'root',
            ui:HGroup{
                ui:LineEdit {
                    ID = 'mytext',
                    Text = tostring(cur_name),
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true},
                    Enabled = true,
                }
            },
            ui:HGroup{
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
                    ID = 'cancel',
                    Text = 'Cancel',
                    Weight = 0.7,
                },
                ui:Button{
                    ID = 'ok',
                    Text = 'Ok',
                    Weight = 0.3,
                }
            },
        }
    })

    itm = win:GetItems()
    itm.mytext:SelectAll()
    
    -- Populate enumeration mode dropdown
    itm.FixMode:AddItem('Enumerate')
    itm.FixMode:AddItem('Append ID')
    itm.FixMode:AddItem('Strip Numbers')
    itm.FixMode:AddItem('Strip and Enumerate All')
    itm.FixMode:AddItem('Strip and Enumerate by ID')
    
    -- ------------------------------------------------------------------------
    -- Rename Functions
    -- ------------------------------------------------------------------------
    
    --- Rename a single tool
    local function renameSingleTool()
        local new_name = itm.mytext:GetText()
        
        if new_name == cur_name then
            return -- Name unchanged
        end
        
        new_name = validateToolName(new_name)
        local prevName = tool.Name
        
        tool:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = new_name})
        
        -- Update ToolManager tags if enabled
        if UPDATE_TOOLMANAGER_TAGS then
            updateToolManagerTags(prevName, tool.Name)
        end
    end
    
    --- Batch rename multiple tools with sequential numbering
    --- @param tools table Array of tools to rename
    local function batchRenameTools(tools)
        if not tools or #tools == 0 then
            return
        end
        
        if #tools < 2 then
            renameSingleTool()
            disp:ExitLoop()
            return
        end
        
        comp:StartUndo("Batch Rename Tools")
        local baseName = itm.mytext:GetText()
        local count = 0
        
        for num, t in ipairs(tools) do
            local newName = baseName .. '_' .. string.format("%02d", num)
            if UPDATE_TOOLMANAGER_TAGS then
                updateToolManagerTags(t.Name, newName)
            end
            t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = newName})
            count = count + 1
        end
        
        print(string.format("Batch renamed %d tools", count))
        comp:EndUndo()
        disp:ExitLoop()
        cancelled = true -- Break the UI loop
    end
    
    --- Fix tool name serialization with various enumeration modes
    --- @param tools table Array of tools to fix
    local function fixToolSerialization(tools)
        if #tools == 0 then
            print("No tools selected")
            return
        end
        
        local mode = itm.FixMode.CurrentIndex
        
        -- Mode 0: Enumerate - Add sequential number to existing name
        if mode == 0 then
            for i, t in ipairs(tools) do
                local toolName = t.Name .. "_" .. string.format("%02d", i)
                t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
            end
            
        -- Mode 1: Append ID - Append internal Fusion tool ID
        elseif mode == 1 then
            for _, t in ipairs(tools) do
                local toolName = t.Name .. "_" .. t.ID
                t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
            end
            
        -- Mode 2: Strip Numbers - Remove trailing numbers and underscores
        elseif mode == 2 then
            for _, t in ipairs(tools) do
                local toolName = string.gsub(t.Name, "[_%d]+$", "")
                t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
            end
            
        -- Mode 3: Strip and Enumerate All - Remove old numbers then add new sequential
        elseif mode == 3 then
            for i, t in ipairs(tools) do
                local toolName = string.gsub(t.Name, "[_%d]+$", "") .. "_" .. string.format("%02d", i)
                t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
            end
            
        -- Mode 4: Strip and Enumerate by ID - Group by type, then enumerate within groups
        elseif mode == 4 then
            local toolsByType = {}
            
            -- Group tools by their ID (type)
            for _, t in ipairs(tools) do
                local toolType = t.ID
                if not toolsByType[toolType] then
                    toolsByType[toolType] = {}
                end
                table.insert(toolsByType[toolType], t)
            end
            
            -- Enumerate within each type group
            for toolType, typeTools in pairs(toolsByType) do
                for i, t in ipairs(typeTools) do
                    local baseName = string.gsub(t.Name, "[_%d]+$", "")
                    local toolName = baseName .. "_" .. string.format("%02d", i)
                    t:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = toolName})
                end
            end
        end
    end
    
    -- ------------------------------------------------------------------------
    -- Event Handlers
    -- ------------------------------------------------------------------------
    
    function win.On.cancel.Clicked(ev)
        cancelled = true
        disp:ExitLoop()
    end
    
    function win.On.renameplus.Close(ev)
        disp:ExitLoop()
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
        if itm.batch.Checked then
            local selectedNodes = comp:GetToolList(true)
            if itm.fix.Checked then
                fixToolSerialization(selectedNodes)
            else
                batchRenameTools(selectedNodes)
            end
        else
            renameSingleTool()
        end
        disp:ExitLoop()
    end
    
    function win.On.mytext.ReturnPressed(ev)
        if itm.batch.Checked then
            local selectedNodes = comp:GetToolList(true)
            batchRenameTools(selectedNodes)
        else
            renameSingleTool()
            disp:ExitLoop()
        end
    end
    
    win:Show()
    disp:RunLoop()
    win:Hide()
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

-- Prevent multiple instances of the dialog
local main_win = ui:FindWindow("renameplus")
if main_win then
    main_win:Raise()
    main_win:ActivateWindow()
    return
end

comp:StartUndo("RenamePlus")

local active = comp.ActiveTool

-- Handle Underlay tools specifically
if active and active.ID == 'Underlay' then
    local current_name = active.Name
    showUI(active, current_name)
else
    -- Handle selected tools
    local selectedNodes = comp:GetToolList(true)
    
    if #selectedNodes > 0 then
        for i, tool in ipairs(selectedNodes) do
            local current_name = tool.Name
            showUI(tool, current_name)
            
            -- Break loop if cancelled or in batch mode
            if cancelled or itm.fix.Enabled then
                break
            end
        end
    end
end

comp:EndUndo(true)
