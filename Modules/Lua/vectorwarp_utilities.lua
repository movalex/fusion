--[[
    VectorWarp Utilities Module
    Provides VectorWarp-specific functionality and automated workflows
    For motion vector analysis, stabilization, and tracking operations

    Authors: Emilio Sapia, Alexey Bogomolov
    Module Refactoring: 2024-2025
    License: MIT
--]]

local vectorwarp_utilities = {}

-- Load shared Fusion library
local flib = require("fusionlib")

--------------------------------------------------------------------------------
-- CORE VECTORWARP OPERATIONS
--------------------------------------------------------------------------------

--- Generate CleanPass STMaps (fast method using file copying)
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
function vectorwarp_utilities.generate_cleanpass_fast(tool, comp)
    if not flib.check_comp(comp) then
        return false
    end

    -- Initialize UTF-8 support
    flib.init_utf8()

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
    flib.sleep(2)
    tool.SaveFrames = "Full"
    comp:Stop()
    print("Rendered a single clean plate file")

    -- Restore render range
    comp:SetAttrs({COMPN_RenderEnd = renderEnd})

    -- Get saver and loader references
    local svr = tool:GetChildrenList(false, "Saver")[1]
    local saverClip = svr.Clip[0]
    local seq = flib.parse_filename(saverClip)

    local ldr = tool:GetChildrenList(false, "Loader")[1]

    -- Configure loader
    ldr.MissingFrames[0] = 2 -- Show missing frames as color

    local padding = string.format("%04d", renderStart)
    local loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension
    print("Clip Parsed and Loaded: ".. loaderClip)
    ldr.Loop[0] = 0
    tool.Depth[0] = 5

    seq = flib.parse_filename(comp:MapPath(loaderClip))

    -- Copy frame to create sequence
    comp:Lock()
    local oldName = seq.FullPath

    -- Copy the single rendered frame to all frames in the range
    for frame = renderStart, renderEnd do
        local padding = string.format("%04d", frame)
        local newName = seq.Path .. seq.CleanName .. padding .. seq.Extension
        -- Skip the original frame (it already exists)
        if frame ~= renderStart and not flib.file_exists(newName) then
            if not flib.copy_file(oldName, newName) then
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
    flib.move_loader(ldr, comp)

    print("[Done] Now press Analyze button")
    return true
end

--- Render CleanPass STMaps (safe method, renders each frame)
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
function vectorwarp_utilities.render_cleanpass_safe(tool, comp)
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
        local seq = flib.parse_filename(loaderClip)
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
            flib.sleep(2)
            break
        end
    end

    comp.CurrentTime = tool.ReferenceFrame[fu.TIME_UNDEFINED] or temp_time
    tool.SaveFrames = "Full"
    ldr.Clip[0] = comp:MapPath(loaderClip)

    flib.move_loader(ldr, comp)
    print("[Done] Now press Analyze button")

    fusion.CacheManager:Purge()
    return true
end

--- Set reference frame for motion analysis
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @param frame number Optional frame number (uses current time if not provided)
function vectorwarp_utilities.set_reference_frame(tool, comp, frame)
    frame = frame or comp.CurrentTime
    tool:SetInput('ReferenceFrame', frame, fu.TIME_UNDEFINED)
    print("Reference frame set to: " .. frame)
    return frame
end

--- Analyze motion vectors forward
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.analyze_forward(tool, comp)
    print("Running Analyze Forward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        flib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
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
            flib.sleep(2)
            break
        end
    end

    comp.CurrentTime = refFrame
    tool.SaveFrames = "Full"

    print("Forward analysis complete")
    return true
end

--- Analyze motion vectors backward
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.analyze_backward(tool, comp)
    print("Running Analyze Backward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        flib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
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
            flib.sleep(2)
            break
        end
    end

    comp.CurrentTime = refFrame
    tool.SaveFrames = "Full"

    print("Backward analysis complete")
    return true
end

--- Analyze motion vectors in both directions
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.analyze_both(tool, comp)
    print("Running Analyze Forward then Backward")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if refFrame < renderStart or refFrame > renderEnd then
        flib.show_warning(comp, "Reference frame [" .. refFrame .. "] is out of the region!\nAnalyze process cancelled.")
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
                flib.sleep(2)
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
                flib.sleep(2)
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
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.delete_vectors(tool, comp)
    local confirmation = flib.show_confirmation(comp, "Are you sure you want\nto remove all Vectors?")

    if not confirmation then
        print("Cancelled")
        return false
    end

    local ldr = tool:GetChildrenList(false, "Loader")[1]
    local clipPath = comp:MapPath(ldr.Clip[0])
    local seq = flib.parse_filename(clipPath)

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
    flib.init_utf8()
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

--- Move loader to match render range (wrapper for fusionlib function)
--- @param ldr object Loader tool
--- @param comp object Fusion composition
function vectorwarp_utilities.move_loader(ldr, comp)
    return flib.move_loader(ldr, comp)
end

--- Create a loader from current VectorWarp tool settings
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
function vectorwarp_utilities.create_loader(tool, comp)
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

--------------------------------------------------------------------------------
-- HIGH-LEVEL WORKFLOWS
--------------------------------------------------------------------------------

--- Options table structure for workflows
--- @class WorkflowOptions
--- @field method string "fast" or "safe" for CleanPass generation
--- @field direction string "forward", "backward", or "both" for analysis
--- @field reference_frame number Optional reference frame (uses current time if not set)
--- @field show_progress boolean Whether to show progress messages
--- @field auto_reference boolean Whether to auto-set reference frame

--- Auto Process - Complete workflow in one click
--- Performs: Generate CleanPass → Set Reference → Analyze Motion
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @param options WorkflowOptions Configuration options
--- @return boolean Success status
function vectorwarp_utilities.auto_process(tool, comp, options)
    options = options or {}
    local method = options.method or "fast"
    local direction = options.direction or "both"
    local show_progress = options.show_progress ~= false
    local auto_reference = options.auto_reference ~= false

    if show_progress then
        print("=== Starting VectorWarp Auto Process ===")
    end

    -- Step 1: Check composition is valid
    if not flib.check_comp(comp) then
        return false
    end

    -- Step 2: Generate CleanPass
    if show_progress then
        print("Step 1/3: Generating CleanPass STMaps...")
    end

    local success
    if method == "fast" then
        success = vectorwarp_utilities.generate_cleanpass_fast(tool, comp)
    else
        success = vectorwarp_utilities.render_cleanpass_safe(tool, comp)
    end

    if not success then
        flib.show_warning(comp, "Failed to generate CleanPass")
        return false
    end

    -- Step 3: Set reference frame
    if show_progress then
        print("Step 2/3: Setting reference frame...")
    end

    local refFrame
    if options.reference_frame then
        refFrame = options.reference_frame
    elseif auto_reference then
        -- Auto-set to current frame
        refFrame = comp.CurrentTime
    else
        -- Use existing reference frame from tool
        refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    end

    vectorwarp_utilities.set_reference_frame(tool, comp, refFrame)

    -- Step 4: Analyze motion
    if show_progress then
        print("Step 3/3: Analyzing motion vectors...")
    end

    if direction == "forward" then
        success = vectorwarp_utilities.analyze_forward(tool, comp)
    elseif direction == "backward" then
        success = vectorwarp_utilities.analyze_backward(tool, comp)
    else
        success = vectorwarp_utilities.analyze_both(tool, comp)
    end

    if show_progress then
        if success then
            print("=== VectorWarp Auto Process Complete ===")
            print("Ready to apply distortion using STMapper or Texture node")
        else
            print("=== VectorWarp Auto Process Failed ===")
        end
    end

    return success
end

--- Quick Stabilize - Simplified stabilization workflow
--- Auto-sets reference to middle frame and analyzes both directions
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.quick_stabilize(tool, comp)
    print("=== Starting Quick Stabilize ===")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    local middleFrame = math.floor((renderStart + renderEnd) / 2)

    print("Using middle frame as reference: " .. middleFrame)

    -- Run auto process with middle frame as reference
    return vectorwarp_utilities.auto_process(tool, comp, {
        method = "fast",
        direction = "both",
        reference_frame = middleFrame,
        show_progress = true,
        auto_reference = false
    })
end

--- Quick Track - Simplified tracking workflow
--- Uses current frame as reference and tracks forward
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.quick_track(tool, comp)
    print("=== Starting Quick Track ===")

    -- Run auto process with current frame as reference
    return vectorwarp_utilities.auto_process(tool, comp, {
        method = "fast",
        direction = "forward",
        reference_frame = comp.CurrentTime,
        show_progress = true,
        auto_reference = false
    })
end

--- Resume Analysis - Continue analyzing from where it stopped
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @param from_direction string "forward" or "backward"
--- @return boolean Success status
function vectorwarp_utilities.resume_analysis(tool, comp, from_direction)
    print("=== Resuming Analysis ===")

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if not refFrame then
        flib.show_warning(comp, "No reference frame set. Please set reference frame first.")
        return false
    end

    -- Check if CleanPass exists
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    if not ldr or ldr.Clip[0] == "" then
        flib.show_warning(comp, "No CleanPass found. Please generate CleanPass first.")
        return false
    end

    -- Resume analysis from specified direction
    if from_direction == "forward" then
        return vectorwarp_utilities.analyze_forward(tool, comp)
    elseif from_direction == "backward" then
        return vectorwarp_utilities.analyze_backward(tool, comp)
    else
        return vectorwarp_utilities.analyze_both(tool, comp)
    end
end

--- Batch Process - Process multiple clips with same settings
--- @param comp object Fusion composition
--- @param clips table Array of clip paths
--- @param settings table Processing settings
--- @return table Results for each clip
function vectorwarp_utilities.batch_process(comp, clips, settings)
    local results = {}

    for i, clip_path in ipairs(clips) do
        print("Processing clip " .. i .. " of " .. #clips .. ": " .. clip_path)

        -- Create a new VectorWarp tool for each clip
        local tool = comp:AddTool("MacroOperator", -32768, -32768)
        -- Note: Loading the macro settings would need to be done here

        -- Process the clip
        local success = vectorwarp_utilities.auto_process(tool, comp, settings)

        results[i] = {
            clip = clip_path,
            success = success
        }

        if not success then
            print("Failed to process clip: " .. clip_path)
        end
    end

    return results
end

--- Validate Setup - Check if VectorWarp is properly configured
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean, string Success status and message
function vectorwarp_utilities.validate_setup(tool, comp)
    -- Check if composition is saved
    if comp:GetAttrs('COMPS_FileName') == '' then
        return false, "Composition not saved"
    end

    -- Check if input is connected
    if not tool.Input or not tool.Input:GetConnectedOutput() then
        return false, "No input connected to VectorWarp"
    end

    -- Check if saver path is valid
    local svr = tool:GetChildrenList(false, "Saver")[1]
    if not svr or svr.Clip[0] == "" then
        return false, "Saver path not configured"
    end

    -- Check render range
    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    if renderEnd <= renderStart then
        return false, "Invalid render range"
    end

    return true, "Setup valid"
end

--- Reset VectorWarp - Clear all generated files and reset settings
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_utilities.reset(tool, comp)
    local confirm = flib.show_confirmation(comp,
        "This will delete all vector files and reset settings.\nContinue?")

    if not confirm then
        return false
    end

    -- Delete vector files
    vectorwarp_utilities.delete_vectors(tool, comp)

    -- Reset tool settings
    tool.ReferenceFrame = 0
    tool.Render = 0
    tool.Direction = 0

    -- Clear loader
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    if ldr then
        ldr.Clip[0] = ""
    end

    print("VectorWarp has been reset")
    return true
end

--- Get workflow status - Check current state of VectorWarp processing
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return table Status information
function vectorwarp_utilities.get_status(tool, comp)
    local status = {}

    -- Check if CleanPass exists
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    status.has_cleanpass = ldr and ldr.Clip[0] ~= ""

    -- Check reference frame
    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    status.has_reference = refFrame ~= nil
    status.reference_frame = refFrame

    -- Check render mode
    status.render_mode = tool.Render == 0 and "CleanPass" or "Full Render"

    -- Check direction
    status.direction = tool.Direction == 0 and "Forward" or "Backward"

    -- Check if comp is saved
    status.comp_saved = comp:GetAttrs('COMPS_FileName') ~= ''

    -- Get render range
    status.render_start = comp:GetAttrs().COMPN_RenderStart
    status.render_end = comp:GetAttrs().COMPN_RenderEnd

    return status
end

--- Print workflow help
--- @param comp object Fusion composition
function vectorwarp_utilities.show_help(comp)
    local help_text = [[
VECTORWARP WORKFLOW HELP

Quick Workflows:
- Auto Process: Complete workflow in one click
- Quick Stabilize: Auto-stabilize using middle frame
- Quick Track: Track forward from current frame

Manual Workflow:
1. Generate CleanPass (creates STMaps)
2. Set Reference Frame (tracking anchor point)
3. Analyze Motion (forward/backward/both)
4. Apply using STMapper or Texture node

Tips:
- Use "fast" method for quick testing
- Use "safe" method for final renders
- Set reference frame where motion is clearest
- Analyze both directions for best results
]]

    local d = {}
    d[1] = {
        "Help",
        Name = "",
        "Text",
        ReadOnly = true,
        Lines = 20,
        Wrap = true,
        Default = help_text
    }

    comp:AskUser("VectorWarp Help", d)
end

return vectorwarp_utilities
