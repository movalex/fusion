--[[
    Vector Processing Library
    Provides core functionality for vector-based motion analysis tools
    Used by VectorWarp and other optical flow based macros

    Original Authors: Emilio Sapia, Alexey Bogomolov
    Module Refactoring: 2024
    License: MIT
--]]

local vectorlib = {}

-- Module dependencies (currently not using external modules to avoid compatibility issues)
-- local vfilesystemutils = nil
-- local vtextutils = nil

-- UTF-8 module handling
local utf_module_loaded = false
local utf8_module = nil

--- Initialize UTF-8 module for non-Latin character support
--- @return boolean Whether UTF-8 module was loaded successfully
function vectorlib.init_utf8()
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
function vectorlib.parse_filename(filename)
    -- Using local implementation to avoid external dependencies
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
function vectorlib.copy_file(old_path, new_path)
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
function vectorlib.sleep(seconds)
    local sec = tonumber(os.clock() + seconds)
    while (os.clock() < sec) do
    end
end

--- Check if composition is valid and saved
--- @param comp object Fusion composition object
--- @return boolean Whether composition is valid
function vectorlib.check_comp(comp)
    if fu:GetResolve() then
        print("This tool is currently tested with Fusion Studio.")
        return true
    elseif comp:GetAttrs('COMPS_FileName') == '' then
        print('[Vector Tool] Please save the composition')
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
function vectorlib.move_loader(ldr, comp)
    if ldr.ID ~= "Loader" then
        return nil
    end

    local globalStart = comp:GetAttrs().COMPN_GlobalStart
    local inPoint = comp:GetAttrs().COMPN_RenderStart

    comp:StartUndo('Move Loader')

    local clipName = ldr.Clip[1]

    if inPoint == globalStart then
        print("Render IN and Comp Global Start are the same. Trying to parse the loader filename to find the first frame")
        if clipName == "" then
            print("Clip Name is empty. Loader not moved")
            comp:EndUndo()
            return
        end
        local seq = vectorlib.parse_filename(clipName)
        if seq.Number then
            inPoint = seq.Number
        end
    end

    bmd.MoveClip(ldr, globalStart, tonumber(inPoint))
    print("New Loader IN point: " .. inPoint)

    comp:EndUndo()

    ldr.HoldFirstFrame[0] = 0
    ldr.HoldLastFrame[0] = 0
end

--- Generate CleanPass STMaps (fast method using file copying)
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
function vectorlib.generate_cleanpass_fast(tool, comp)
    if not vectorlib.check_comp(comp) then
        return false
    end

    -- Initialize UTF-8 support
    vectorlib.init_utf8()

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    -- Set to CleanPass render mode
    tool.Render = 0

    -- Move to start frame
    comp.CurrentTime = renderStart
    comp:SetAttrs({COMPN_CurrentTime = renderStart})
    comp:SetAttrs({COMPN_RenderEnd = renderStart + 1})  -- This renders just the single frame in Fusion

    -- Render single frame
    fusion.CacheManager:Purge()
    tool.SaveFrames = "HiQInteractive"
    comp:Loop(false)
    comp:Play()
    vectorlib.sleep(2)
    tool.SaveFrames = "Full"
    comp:Stop()
    print("Rendered a single clean plate file")

    -- Restore render range
    comp:SetAttrs({COMPN_RenderEnd = renderEnd})

    -- Get saver and loader references
    local svr = tool:GetChildrenList(false, "Saver")[1]
    local saverClip = svr.Clip[0]
    local seq = vectorlib.parse_filename(saverClip)

    local ldr = tool:GetChildrenList(false, "Loader")[1]

    -- Configure loader
    ldr.MissingFrames[0] = 2 -- Show missing frames as color

    local padding = string.format("%04d", renderStart)
    local loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension
    print("Clip Parsed and Loaded: ".. loaderClip)
    ldr.Loop[0] = 0
    tool.Depth[0] = 5

    seq = vectorlib.parse_filename(comp:MapPath(loaderClip))

    -- Copy frame to create sequence
    comp:Lock()
    local oldName = seq.FullPath

    -- Copy the single rendered frame to all frames in the range
    for frame = renderStart, renderEnd do
        local padding = string.format("%04d", frame)
        local newName = seq.Path .. seq.CleanName .. padding .. seq.Extension
        -- Skip the original frame (it already exists)
        if frame ~= renderStart and not bmd.fileexists(newName) then
            if not vectorlib.copy_file(oldName, newName) then
                print("Failed to copy frame " .. frame)
            end
        end
    end
    comp:Unlock()

    -- Load the sequence
    ldr.Clip[0] = loaderClip

    print("Clean Pass STMap files created: ".. loaderClip)
    comp.CurrentTime = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    comp:Loop(true)

    -- Move loader to match render range
    vectorlib.move_loader(ldr, comp)

    print("[Done] Now press Analyze button")
    return true
end

--- Render CleanPass STMaps (safe method, renders each frame)
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
function vectorlib.render_cleanpass_safe(tool, comp)
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    local svr = tool:GetChildrenList(false, "Saver")[1]
    local saverClip = svr.Clip[0]

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    -- Replace double dots in the saver path
    local padding = string.format("%04d", renderStart)

    local loaderClip = comp:MapPath(saverClip)
    local pattern = "%.%.(%w+)$"
    if string.match(loaderClip, pattern) then
        loaderClip = loaderClip:gsub(pattern, "." .. padding .. ".%1")
    else
        local seq = vectorlib.parse_filename(loaderClip)
        loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension
    end

    -- Set to CleanPass render mode
    tool.Render = 0
    local temp_time = comp.CurrentTime
    comp.CurrentTime = renderStart
    comp:Loop(false)
    fusion.CacheManager:Purge()
    tool.SaveFrames = "HiQInteractive"
    comp:Play()

    -- Wait for render to complete
    while true do
        if temp_time < comp.CurrentTime then
            temp_time = temp_time + 1
            print(".")
        end
        if not comp:IsPlaying() then
            vectorlib.sleep(2)
            break
        end
    end

    comp.CurrentTime = tool.ReferenceFrame[fu.TIME_UNDEFINED] or temp_time
    tool.SaveFrames = "Full"
    ldr.Clip[0] = comp:MapPath(loaderClip)

    vectorlib.move_loader(ldr, comp)
    print("[Done] Now press Analyze button")

    fusion.CacheManager:Purge()
    return true
end

--- Set reference frame for motion analysis
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
--- @param frame number Optional frame number (uses current time if not provided)
function vectorlib.set_reference_frame(tool, comp, frame)
    frame = frame or comp.CurrentTime
    tool:SetInput('ReferenceFrame', frame, fu.TIME_UNDEFINED)
    print("Reference frame set to: " .. frame)
    return frame
end

--- Show warning dialog
--- @param comp object Fusion composition
--- @param message string Warning message
--- @return boolean User response
function vectorlib.show_warning(comp, message)
    print('[Vector Tool] ' .. message)
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
function vectorlib.show_confirmation(comp, message)
    print('[Vector Tool] ' .. message)
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

--- Analyze motion vectors forward
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorlib.analyze_forward(tool, comp)
    print("Running Analyze Forward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        vectorlib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
        return false
    end

    -- Check if there's anything to analyze forward
    if refFrame >= renderEnd then
        print("Reference frame is at or after render end - no forward analysis needed")
        return true
    end

    -- Set to full render mode
    tool.Render = 1

    -- Set vectors direction to forward
    tool.Direction = 0

    comp.CurrentTime = refFrame
    comp:Loop(false)
    fusion.CacheManager:Purge()
    local temp_time = comp.CurrentTime
    tool.SaveFrames = "HiQInteractive"

    -- Play forward
    comp:Play()
    while true do
        if temp_time < comp.CurrentTime then
            temp_time = temp_time + 1
            print("Analyzing forward frame " .. temp_time)
        end
        if not comp:IsPlaying() then
            vectorlib.sleep(2)
            break
        end
    end

    comp.CurrentTime = refFrame
    tool.SaveFrames = "Full"

    print("Forward analysis complete")
    return true
end

--- Analyze motion vectors backward
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorlib.analyze_backward(tool, comp)
    print("Running Analyze Backward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        vectorlib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
        return false
    end

    -- Check if there's anything to analyze backward
    if refFrame <= renderStart then
        print("Reference frame is at or before render start - no backward analysis needed")
        return true
    end

    -- Set to full render mode
    tool.Render = 1

    -- Set vectors direction to backward
    tool.Direction = 1

    comp.CurrentTime = refFrame
    comp:Loop(false)
    fusion.CacheManager:Purge()
    local temp_time = comp.CurrentTime
    tool.SaveFrames = "HiQInteractive"

    -- Play backward
    comp:Play(true)
    while true do
        if temp_time > comp.CurrentTime then
            temp_time = temp_time - 1
            print("Analyzing backward frame " .. temp_time)
        end
        if not comp:IsPlaying() then
            vectorlib.sleep(2)
            break
        end
    end

    comp.CurrentTime = refFrame
    tool.SaveFrames = "Full"

    print("Backward analysis complete")
    return true
end

--- Analyze motion vectors in both directions
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorlib.analyze_both(tool, comp)
    print("Running Analyze Forward then Backward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        vectorlib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
        return false
    end

    -- Set to full render mode
    tool.Render = 1

    -- First analyze forward (only if there are frames after the reference frame)
    if refFrame < renderEnd then
        print("Analyzing forward from frame " .. refFrame .. " to " .. renderEnd)
        tool.Direction = 0
        comp.CurrentTime = refFrame
        comp:Loop(false)
        fusion.CacheManager:Purge()
        local temp_time = comp.CurrentTime
        tool.SaveFrames = "HiQInteractive"

        comp:Play()
        while true do
            if temp_time < comp.CurrentTime then
                temp_time = temp_time + 1
                print("Analyzing forward frame " .. temp_time)
            end
            if not comp:IsPlaying() then
                vectorlib.sleep(2)
                break
            end
        end
    else
        print("Reference frame is at render end - no forward analysis needed")
    end

    -- Then analyze backward (only if there are frames before the reference frame)
    if refFrame > renderStart then
        print("Analyzing backward from frame " .. refFrame .. " to " .. renderStart)
        comp.CurrentTime = refFrame
        fusion.CacheManager:Purge()
        tool.Direction = 1
        temp_time = comp.CurrentTime

        comp:Play(true)
        while true do
            if temp_time > comp.CurrentTime then
                temp_time = temp_time - 1
                print("Analyzing backward frame " .. temp_time)
            end
            if not comp:IsPlaying() then
                vectorlib.sleep(2)
                break
            end
        end
    else
        print("Reference frame is at render start - no backward analysis needed")
    end

    tool.SaveFrames = "Full"
    comp.CurrentTime = refFrame
    collectgarbage()

    print("Forward and backward analysis complete")
    return true
end

--- Delete vector files
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorlib.delete_vectors(tool, comp)
    local confirmation = vectorlib.show_confirmation(comp, "Are you sure you want\nto remove all Vectors?")

    if not confirmation then
        print("Cancelled")
        return false
    end

    local ldr = tool:GetChildrenList(false, "Loader")[1]
    local clipPath = comp:MapPath(ldr.Clip[0])
    local seq = vectorlib.parse_filename(clipPath)

    -- Determine platform and delete command
    local platform = (FuPLATFORM_WINDOWS and 'Windows') or
                    (FuPLATFORM_MAC and 'Mac') or
                    (FuPLATFORM_LINUX and 'Linux')

    local deleteCommand
    if platform == "Windows" then
        deleteCommand = "del /Q "  -- /Q for quiet mode (no prompts)
    elseif platform == "Mac" or platform == "Linux" then
        deleteCommand = "rm -f "   -- -f for force (no prompts)
    else
        print("OS Platform not detected")
        return false
    end

    local imageSequenceFilename = seq.Path .. "*" .. seq.Extension
    print('[Formatted Image Sequence] ' .. imageSequenceFilename)

    -- Initialize UTF-8 support for path conversion
    vectorlib.init_utf8()
    if utf_module_loaded and utf8_to_win then
        imageSequenceFilename = utf8_to_win(imageSequenceFilename)
    end

    -- Wrap path in quotes to handle spaces in path names
    local deleteRenderedCommand = deleteCommand .. '"' .. imageSequenceFilename .. '"'
    print("Deleting file sequence using command: [ " .. deleteRenderedCommand .. " ]")
    os.execute(deleteRenderedCommand)
    print('[Vector files Cleared]')

    return true
end

--- Create a loader from current Vector tool settings
--- @param tool object Vector processing macro tool
--- @param comp object Fusion composition
function vectorlib.create_loader(tool, comp)
    comp:Lock()
    comp:StartUndo('Create Vector Loader')

    local tool_ldr = tool:GetChildrenList(false, "Loader")[1]
    local settings = comp:CopySettings(tool_ldr)
    local flow = comp.CurrentFrame.FlowView
    local x, y = flow:GetPos(tool)

    local loader = comp:AddTool("Loader")
    loader:LoadSettings(settings)
    flow:SetPos(loader, x, y + 1)

    local inputs = tool.MainOutput:GetConnectedInputs()
    for i, input in ipairs(inputs) do
        input:ConnectTo(loader.Output)
    end

    comp:EndUndo()
    comp:Unlock()

    print("Created new Loader with vector tool settings")
end

return vectorlib