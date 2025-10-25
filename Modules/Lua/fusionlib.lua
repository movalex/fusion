--[[
    Fusion Utilities Library
    Provides core functionality for Fusion macros and tools
    General-purpose utilities for file operations, dialogs, and composition management

    Original Authors: Emilio Sapia, Alexey Bogomolov
    Module Refactoring: 2024-2025
    License: MIT
--]]

local fusionlib = {}

-- UTF-8 module handling
local utf_module_loaded = false
local utf8_module = nil

--- Initialize UTF-8 module for non-Latin character support
--- @return boolean Whether UTF-8 module was loaded successfully
function fusionlib.init_utf8()
    if not utf_module_loaded then
        local success, module = pcall(require, "win-125x")
        if success then
            utf_module_loaded = true
            utf8_module = module
            if module.codepage then
                print("Current codepage win-125x settings: " .. module.codepage)
            end
            print('Module win-125x found and loaded')
        else
            print('Module win-125x not found - non-Latin paths may not work correctly')
        end
    end
    return utf_module_loaded
end

--- Parse filename into components
--- @param filename string Full path to file
--- @return table Table with Path, FullName, Name, CleanName, Extension, Number, Padding, SNum
function fusionlib.parse_filename(filename)
    local seq = {}
    seq.FullPath = filename

    -- Extract path and name
    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name)
        seq.Path = path
        seq.FullName = name
    end)

    -- Extract name and extension
    string.gsub(seq.FullName or "", "^(.+)(%..+)$", function(name, ext)
        seq.Name = name
        seq.Extension = ext
    end)

    -- Handle no extension case
    if not seq.Name then
        seq.Name = seq.FullName
    end

    -- Extract clean name and sequence number
    if seq.Name then
        string.gsub(seq.Name, "^(.-)(%d+)$", function(name, SNum)
            seq.CleanName = name
            seq.SNum = SNum
        end)
    end

    -- Process sequence number
    if seq.SNum then
        seq.Number = tonumber(seq.SNum)
        seq.Padding = string.len(seq.SNum)
    else
        seq.SNum = ""
        seq.CleanName = seq.Name
    end

    if seq.Extension == nil then
        seq.Extension = ""
    end

    return seq
end

--- Copy file with UTF-8 support
--- @param old_path string Source file path
--- @param new_path string Destination file path
--- @return boolean Success status
function fusionlib.copy_file(old_path, new_path)
    print("Copying file from: " .. old_path .. " to: " .. new_path)

    -- Convert paths if UTF-8 module is loaded
    if utf_module_loaded and utf8_to_win then
        old_path = utf8_to_win(old_path)
        new_path = utf8_to_win(new_path)
    end

    local old_file = io.open(old_path, "rb")
    local new_file = io.open(new_path, "wb")
    local old_file_sz, new_file_sz = 0, 0

    if not old_file or not new_file then
        if old_file then old_file:close() end
        if new_file then new_file:close() end
        return false
    end

    -- Copy file in chunks
    while true do
        local block = old_file:read(2^13) -- 8KB chunks
        if not block then
            old_file_sz = old_file:seek("end")
            break
        end
        new_file:write(block)
    end

    old_file:close()
    new_file_sz = new_file:seek("end")
    new_file:close()

    return new_file_sz == old_file_sz
end

--- Sleep function for delays
--- @param seconds number Seconds to sleep
function fusionlib.sleep(seconds)
    local sec = tonumber(os.clock() + seconds)
    while (os.clock() < sec) do
    end
end

--- Check if file exists
--- @param filepath string Path to file
--- @return boolean Whether file exists
function fusionlib.file_exists(filepath)
    if bmd and bmd.fileexists then
        return bmd.fileexists(filepath)
    else
        -- Fallback method using io.open
        local f = io.open(filepath, "r")
        if f then
            f:close()
            return true
        end
        return false
    end
end

--- Move clip timing for Loader tools
--- Adjusts a Loader's global start position and preserves clip trimming values
--- @param loader object Loader tool to move
--- @param oldstart number Current global start frame
--- @param newstart number New global start frame to move to
function fusionlib.move_clip(loader, oldstart, newstart)
    -- Remember clip trimming values
    local globalin    = loader.GlobalIn[oldstart]
    local globalout   = loader.GlobalOut[oldstart]
    local clipstart   = loader.ClipTimeStart[oldstart]
    local clipend     = loader.ClipTimeEnd[oldstart]
    local extfirst    = loader.HoldFirstFrame[oldstart]
    local extlast     = loader.HoldLastFrame[oldstart]

    local len = globalout - globalin + 1

    if newstart > oldstart then -- Moving forwards
        loader.GlobalOut[oldstart] = newstart + len - 1
        loader.GlobalIn[oldstart] = newstart
    else -- Moving backwards
        loader.GlobalIn[oldstart] = newstart
        loader.GlobalOut[newstart] = newstart + len - 1
    end

    -- Fix trimming values at new position
    loader.ClipTimeStart[newstart]     = clipstart
    loader.ClipTimeEnd[newstart]       = clipend
    loader.HoldFirstFrame[newstart]    = extfirst
    loader.HoldLastFrame[newstart]     = extlast
end

--- Check if composition is valid and saved
--- @param comp object Fusion composition object
--- @return boolean Whether composition is valid
function fusionlib.check_comp(comp)
    if fu:GetResolve() then
        print("This tool is currently tested with Fusion Studio.")
        return true
    elseif comp:GetAttrs('COMPS_FileName') == '' then
        print('[Fusion Tool] Please save the composition')
        local d = {}
        d[1] = {
            "Warning",
            Name = "",
            "Text",
            ReadOnly = true,
            Lines = 2,
            Wrap = false,
            Default = "Please save the comp to proceed"
        }
        local ask = comp:AskUser("Warning", d)
        if ask then
            comp:SaveAs()
        end
        return ask ~= nil
    end
    return true
end

--- Move loader to match render range
--- @param ldr object Loader tool
--- @param comp object Fusion composition
function fusionlib.move_loader(ldr, comp)
    if ldr.ID ~= "Loader" then
        return nil
    end

    local globalStart = comp:GetAttrs().COMPN_GlobalStart
    local inPoint = comp:GetAttrs().COMPN_RenderStart

    comp:StartUndo('Move Loader')

    local clipName = ldr.Clip[1]

    if inPoint == globalStart then
        print("Render IN and Comp Global Start are the same.\nTrying to parse the loader filename to find the first frame")
        if clipName == "" then
            print("Clip Name is empty. Loader not moved")
            comp:EndUndo()
            return
        end
        local seq = fusionlib.parse_filename(clipName)
        if seq.Number then
            inPoint = seq.Number
        end
    end

    fusionlib.move_clip(ldr, globalStart, tonumber(inPoint))
    print("New Loader IN point: " .. inPoint)

    comp:EndUndo()

    ldr.HoldFirstFrame[0] = 0
    ldr.HoldLastFrame[0] = 0
end

--- Show warning dialog
--- @param comp object Fusion composition
--- @param message string Warning message
--- @return boolean User response
function fusionlib.show_warning(comp, message)
    print('[Fusion Tool] ' .. message)
    local d = {}
    d[1] = {
        "Warning",
        Name = "",
        "Text",
        ReadOnly = true,
        Lines = 3,
        Wrap = false,
        Default = message
    }
    local ask = comp:AskUser("Warning", d)
    return ask ~= nil
end

--- Show confirmation dialog
--- @param comp object Fusion composition
--- @param message string Confirmation message
--- @return boolean User response
function fusionlib.show_confirmation(comp, message)
    print('[Fusion Tool] ' .. message)
    local d = {}
    d[1] = {
        "Confirmation",
        Name = "",
        "Text",
        ReadOnly = true,
        Lines = 2,
        Wrap = false,
        Default = message
    }
    local ask = comp:AskUser("Confirmation", d)
    return ask ~= nil
end

--- Create a loader from current macro tool's internal loader settings
--- @param tool object Macro tool containing a Loader node
--- @param comp object Fusion composition
function fusionlib.create_loader(tool, comp)
    comp:Lock()
    comp:StartUndo('Create Loader')

    local tool_ldr = tool:GetChildrenList(false, "Loader")[1]
    if not tool_ldr then
        print("Error: No Loader found inside the macro")
        comp:Unlock()
        return nil
    end

    local settings = comp:CopySettings(tool_ldr)
    local flow = comp.CurrentFrame.FlowView
    local x, y = flow:GetPos(tool)

    local loader = comp:AddTool("Loader")
    loader:LoadSettings(settings)
    flow:SetPos(loader, x, y + 1)

    -- local inputs = tool.MainOutput:GetConnectedInputs()
    -- for i, input in ipairs(inputs) do
    --     input:ConnectTo(loader.Output)
    -- end
    
    -- FIX: Adjust loader frames to match composition render range
    fusionlib.move_loader(loader, comp)
    
    comp:EndUndo()
    comp:Unlock()

    print("Created new Loader from macro settings")
    return loader
end

return fusionlib
