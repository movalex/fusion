--[[
    ReFill Utilities Module
    Provides ReFill-specific functionality and automated workflows
    For iterative growth operations and canvas generation

    Overview:
    ReFill creates iterative growth effects by propagating patterns from
    defined starting points, with growth speed controlled by map sources.

    Key Concepts:
    - Canvas Generation: Creates clean blank plates for growth to start from
      * generate_canvas_fast: Renders one frame and copies it (preferred)
      * generate_canvas: Renders all frames individually (fallback if copying fails)

    - Growth Processing: Renders the actual iterative growth effect
      * process_forward: Processes growth from start to end frame

    - Loader Reloading Hack: The pattern `tool.LD1_Load = path .. ""` forces
      the loader to refresh its clip, necessary for macros with non-standard
      frame starts (0 or 1001). This is not a typo.

    Module Refactoring: 2024-2025
    License: MIT
--]]

local refill_utilities = {}

-- Load shared Fusion library
local flib = require("fusionlib")

-- Configuration constants
local CONFIG = {
    -- Sleep durations (seconds)
    SLEEP_SHORT = 0.1,    -- Playback monitoring loop
    SLEEP_MEDIUM = 1,     -- Wait for mode switches
    SLEEP_LONG = 2,       -- Wait for render completion

    -- Tool property names (for maintainability)
    PROP_BLANK_CANVAS = "Switch_BlankCanvas_Source",
    PROP_SAVE_FRAMES = "SV1_SaveFrames",
    PROP_OUTPUT_MODE = "Switch_OutputMode_Source",
    PROP_START_FRAME = "CT5_StartFrame",
    PROP_GLOBAL_IN = "GlobalIn",
    PROP_LOADER_CLIP = "LD1_Load",

    -- Canvas mode values
    MODE_CANVAS = 1,
    MODE_OUTPUT = 0,

    -- Save modes
    SAVE_FULL = "Full",
    SAVE_INTERACTIVE = "HiQInteractive"
}

--[[============================================================================
    HELPER FUNCTIONS (Private)
    These functions extract common patterns and reduce code duplication
============================================================================]]

--- Get render range from composition
--- @param comp object Fusion composition
--- @return number renderStart, number renderEnd
local function get_render_range(comp)
    local attrs = comp:GetAttrs()
    return attrs.COMPN_RenderStart, attrs.COMPN_RenderEnd
end

--- Monitor playback progress and print updates
--- @param comp object Fusion composition
--- @param renderEnd number End frame to monitor
--- @param startFrame number Starting frame for progress tracking
--- @param messagePrefix string Prefix for progress messages
--- @return boolean Success status
local function monitor_playback_progress(comp, renderEnd, startFrame, messagePrefix)
    local currentFrame = startFrame

    while true do
        -- Check if playback stopped (primary exit condition)
        if not comp:IsPlaying() then
            flib.sleep(CONFIG.SLEEP_MEDIUM)
            break
        end

        -- Check if reached the end (secondary exit condition)
        if comp.CurrentTime >= renderEnd then
            print(messagePrefix .. " complete")
            break
        end

        -- Update progress only when frame changes
        if comp.CurrentTime > currentFrame then
            currentFrame = comp.CurrentTime
            print(messagePrefix .. " frame " .. currentFrame)
        end

        flib.sleep(CONFIG.SLEEP_SHORT)
    end

    return true
end

--- Force loader to reload clip by toggling passthrough
--- Required for macros with non-standard frame starts (0 or 1001)
--- The double assignment with empty string concatenation forces a refresh
--- @param tool object ReFill macro tool
--- @param ldr object Loader node
--- @param clipPath string Path to clip file
--- @param comp object Fusion composition
local function reload_loader_clip(tool, ldr, clipPath, comp)
    comp:Lock()
    local mappedPath = comp:MapPath(clipPath)
    tool[CONFIG.PROP_LOADER_CLIP] = mappedPath
    tool[CONFIG.PROP_LOADER_CLIP] = mappedPath .. ""  -- Reload hack: forces refresh
    ldr:SetAttrs({TOOLB_PassThrough = true})
    ldr:SetAttrs({TOOLB_PassThrough = false})
    comp:Unlock()
end

--- Get and validate tool nodes (Loader and Saver)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return object|nil ldr Loader node or nil on error
--- @return object|nil svr Saver node or nil on error
local function get_tool_nodes(tool, comp)
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    local svr = tool:GetChildrenList(false, "Saver")[1]

    if not svr then
        flib.show_warning(comp, "Saver node not found")
        return nil, nil
    end
    if not ldr then
        flib.show_warning(comp, "Loader node not found")
        return nil, nil
    end

    return ldr, svr
end

--- Validate that required inputs are connected
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Whether inputs are valid
local function validate_inputs(tool, comp)
    local growth_source = tool:FindMainInput(1)  -- Growth Source
    local image_input = tool:FindMainInput(2)    -- Image

    if not growth_source or not growth_source:GetConnectedOutput() then
        flib.show_warning(comp, "Growth Source input not connected.\nPlease connect a growth source and try again.")
        return false
    end

    if not image_input or not image_input:GetConnectedOutput() then
        flib.show_warning(comp, "Image input not connected.\nPlease connect an image and try again.")
        return false
    end

    return true
end

--[[============================================================================
    PUBLIC API FUNCTIONS
    These functions are exposed for use by the ReFill macro

    Canvas Generation Strategies:
    - generate_canvas_fast: Renders one frame and copies it (preferred, faster)
    - generate_canvas: Renders all frames individually (fallback, more reliable)

    Workflow:
    - Canvas generation creates clean plates (blank starting frames)
    - Process forward creates the actual growth render
============================================================================]]

--- Auto Process - Complete canvas generation and setup workflow in one click
--- Performs: Generate Canvas → Set Start Frame → Process Growth
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.auto_process(tool, comp)
    print("=== Starting ReFill Auto Process ===")

    -- Validate composition and inputs
    if not flib.check_comp(comp) then
        return false
    end

    if not validate_inputs(tool, comp) then
        return false
    end

    -- Step 1: Generate canvas
    print("Step 1/2: Generating canvas...")

    local success = refill_utilities.generate_canvas(tool, comp)
    if not success then
        return false
    end

    -- Step 4: Set start frame and process growth
    refill_utilities.go_to_start(tool, comp)

    print("Step 2/2: Starting growth processing...")

    success = refill_utilities.process_forward(tool, comp)
    if not success then
        return false
    end

    print("=== ReFill Auto Process Complete ===")
    print("Growth processing is now running!")
    print("Once playback finishes, you can switch output modes:")
    print("  - Render: Live calculation (slower)")
    print("  - Age: Cached result (faster)")
    print("  - Trail: Dynamic gradient effect")
    print("  - Growth Speed: Speed map visualization")

    return true
end

--- Generate Canvas Fast - Renders ONE frame and copies it (fast method)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.generate_canvas_fast(tool, comp)
    print("=== Generating ReFill Canvas (Fast) ===")

    if not flib.check_comp(comp) then
        return false
    end

    -- Initialize UTF-8 support
    flib.init_utf8()

    -- Get render range and tool nodes
    local renderStart, renderEnd = get_render_range(comp)
    local ldr, svr = get_tool_nodes(tool, comp)
    if not ldr or not svr then
        return false
    end

    tool[CONFIG.PROP_GLOBAL_IN] = renderStart

    -- Set to Canvas mode
    tool[CONFIG.PROP_BLANK_CANVAS] = CONFIG.MODE_CANVAS
    tool[CONFIG.PROP_SAVE_FRAMES] = CONFIG.SAVE_INTERACTIVE
    flib.sleep(CONFIG.SLEEP_MEDIUM)

    -- Render single frame
    comp.CurrentTime = renderStart
    comp:SetAttrs({COMPN_CurrentTime = renderStart})
    comp:SetAttrs({COMPN_RenderEnd = renderStart + 1})  -- Render just one frame
    local compIsLooped = comp:GetAttrs().COMPB_LoopPlay

    comp:Loop(false)
    comp:Play()
    flib.sleep(CONFIG.SLEEP_LONG)
    tool[CONFIG.PROP_SAVE_FRAMES] = CONFIG.SAVE_FULL
    comp:Stop()
    print("Rendered single blank canvas frame")

    -- Restore render range
    comp:SetAttrs({COMPN_RenderEnd = renderEnd})

    -- Parse clip paths
    local saverClip = svr.Clip[0]
    local seq = flib.parse_filename(saverClip)
    local padding = string.format("%04d", renderStart)
    local loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension

    -- Configure loader
    ldr.MissingFrames[0] = 2  -- Show missing frames as color
    ldr.Loop[0] = 0
    print("Clip path: " .. loaderClip)

    -- Copy rendered frame to all frames in range
    seq = flib.parse_filename(comp:MapPath(loaderClip))
    local oldName = seq.FullPath
    print("Copying canvas frame to entire range...")

    for frame = renderStart, renderEnd do
        local framePadding = string.format("%04d", frame)
        local newName = seq.Path .. seq.CleanName .. framePadding .. seq.Extension

        if frame ~= renderStart and not flib.file_exists(newName) then
            if not flib.copy_file(oldName, newName) then
                print("Warning: Failed to copy frame " .. frame)
            end
        end
    end

    -- Reload loader clip and move to render range
    reload_loader_clip(tool, ldr, loaderClip, comp)
    flib.move_loader(ldr, comp)

    print("Canvas files created: " .. loaderClip)
    comp.CurrentTime = renderStart
    print("[Done] Canvas generation complete (fast)")
    return true
end

--- Generate Canvas - Renders all frames (safe method, fallback for generate_canvas_fast)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.generate_canvas(tool, comp)
    -- Get tool nodes and render range
    local ldr, svr = get_tool_nodes(tool, comp)
    if not ldr or not svr then
        return false
    end

    local renderStart, renderEnd = get_render_range(comp)
    comp.CurrentTime = renderStart
    tool[CONFIG.PROP_GLOBAL_IN] = renderStart

    -- Parse saver clip path and build loader clip path
    local saverClip = svr.Clip[0]
    local padding = string.format("%04d", renderStart)
    local loaderClip = comp:MapPath(saverClip)

    -- Handle different clip path patterns
    local pattern = "%.%.(%w+)$"
    if string.match(loaderClip, pattern) then
        loaderClip = loaderClip:gsub(pattern, "." .. padding .. ".%1")
    else
        local seq = flib.parse_filename(loaderClip)
        loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension
    end

    -- Prepare for rendering
    local compIsLooped = comp:GetAttrs().COMPB_LoopPlay
    comp:Loop(false)
    fusion.CacheManager:Purge()

    -- Start rendering all frames
    tool[CONFIG.PROP_SAVE_FRAMES] = CONFIG.SAVE_INTERACTIVE
    comp:Play()

    -- Monitor playback progress
    monitor_playback_progress(comp, renderEnd, renderStart, "Rendering canvas")

    -- Cleanup and restore
    comp:Stop()
    comp.CurrentTime = renderStart

    -- Reload loader clip and move to render range
    reload_loader_clip(tool, ldr, loaderClip, comp)
    flib.move_loader(ldr, comp)

    print("[Done] Canvas generation complete (safe method)")
    return true
end

--- Clear cache and reset - Clears render cache and prepares for fresh processing
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.clear_cache(tool, comp)
    print("=== Clearing ReFill Cache ===")

    local renderStart = get_render_range(comp)

    fusion.CacheManager:Purge()
    comp.CurrentTime = renderStart

    print("Cache cleared. Ready for new processing.")
    return true
end

--- Set start value - Set the CT5_StartFrame parameter to render start
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.set_start_frame(tool, comp)
    local renderStart = get_render_range(comp)
    tool[CONFIG.PROP_START_FRAME] = renderStart
    print("Start frame parameter set to: " .. renderStart)
    return true
end

--- Go to start frame - Move timeline and set start parameter
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.go_to_start(tool, comp)
    local renderStart = get_render_range(comp)

    comp.CurrentTime = renderStart
    comp:SetAttrs({COMPN_CurrentTime = renderStart})
    tool[CONFIG.PROP_START_FRAME] = renderStart

    print("Timeline moved to start frame: " .. renderStart)
    return true
end

--- Process Forward - Start the growth processing (assumes canvas already generated)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.process_forward(tool, comp)
    -- Get render range and prepare composition
    local renderStart, renderEnd = get_render_range(comp)
    comp.CurrentTime = renderStart

    -- Set to Output mode for growth processing
    tool[CONFIG.PROP_BLANK_CANVAS] = CONFIG.MODE_OUTPUT
    tool[CONFIG.PROP_SAVE_FRAMES] = CONFIG.SAVE_INTERACTIVE
    refill_utilities.set_output_mode(tool, "render")
    flib.sleep(CONFIG.SLEEP_MEDIUM)

    -- Save loop state and prepare for rendering
    local compIsLooped = comp:GetAttrs().COMPB_LoopPlay
    comp:Loop(false)
    fusion.CacheManager:Purge()

    -- Start processing
    comp:Play()
    monitor_playback_progress(comp, renderEnd, renderStart, "Processing growth")

    -- Restore composition state
    comp:Stop()
    comp:Loop(compIsLooped)

    -- Switch to cached age mode for playback
    refill_utilities.set_output_mode(tool, "age")
    tool[CONFIG.PROP_SAVE_FRAMES] = CONFIG.SAVE_FULL

    print("[Done] Growth processing complete")
    return true
end

--- Set output mode helper function
--- @param tool object ReFill macro tool
--- @param mode string "render", "age", "trail", or "growth_speed"
--- @return boolean Success status
function refill_utilities.set_output_mode(tool, mode)
    local mode_map = {
        render = 0,
        age = 1,
        trail = 2,
        growth_speed = 3
    }

    local mode_value = mode_map[mode]
    if mode_value then
        tool[CONFIG.PROP_OUTPUT_MODE] = mode_value
        print("Output mode set to: " .. mode)
        return true
    else
        print("Invalid mode: " .. tostring(mode))
        print("Valid modes: render, age, trail, growth_speed")
        return false
    end
end

return refill_utilities
