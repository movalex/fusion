--[[
    VectorFill Workflow Automation Module
    Provides automated workflows for VectorFill iterative growth operations

    Module Refactoring: 2025
    License: MIT
--]]

local vectorfill_workflows = {}

-- Load core library
local vlib = require("vectorlib")

--- Auto Process - Complete canvas generation and setup workflow in one click
--- Performs: Generate Canvas → Set Start Frame → Process Growth
--- @param tool object VectorFill macro tool
--- @param comp object Fusion composition
--- @param options table Configuration options (show_progress, etc.)
--- @return boolean Success status
function vectorfill_workflows.auto_process(tool, comp, options)
    options = options or {}
    local show_progress = options.show_progress ~= false

    if show_progress then
        print("=== Starting VectorFill Auto Process ===")
    end

    -- Step 1: Check composition is saved
    if not vlib.check_comp(comp) then
        return false
    end

    -- Step 2: Validate inputs are connected
    local growth_source_input = tool:FindMainInput(1)  -- Growth Source
    local image_input = tool:FindMainInput(2)  -- Image

    if not growth_source_input or not growth_source_input:GetConnectedOutput() then
        vlib.show_warning(comp, "Growth Source input not connected.\nPlease connect a growth source and try again.")
        return false
    end

    if not image_input or not image_input:GetConnectedOutput() then
        vlib.show_warning(comp, "Image input not connected.\nPlease connect an image and try again.")
        return false
    end

    -- Step 3: Generate canvas
    if show_progress then
        print("Step 1/2: Generating canvas...")
    end

    local success = vectorfill_workflows.generate_canvas(tool, comp, {show_progress = show_progress})
    if not success then
        return false
    end

    -- Step 4: Set start frame and process growth
    vectorfill_workflows.set_start_frame(tool, comp)

    if show_progress then
        print("Step 2/2: Starting growth processing...")
    end

    success = vectorfill_workflows.process(tool, comp)
    if not success then
        return false
    end

    if show_progress then
        print("=== VectorFill Auto Process Complete ===")
        print("Growth processing is now running!")
        print("Once playback finishes, you can switch output modes:")
        print("  - Render: Live calculation (slower)")
        print("  - Age: Cached result (faster)")
        print("  - Trail: Dynamic gradient effect")
        print("  - Growth Speed: Speed map visualization")
    end

    return true
end

--- Generate Canvas - EXACTLY like VectorWarp's generate_cleanpass_fast
--- Renders ONE frame, then copies it to all other frames
--- @param tool object VectorFill macro tool
--- @param comp object Fusion composition
--- @param options table Configuration options
--- @return boolean Success status
function vectorfill_workflows.generate_canvas(tool, comp, options)
    options = options or {}
    local show_progress = options.show_progress ~= false

    if show_progress then
        print("=== Generating VectorFill Canvas ===")
    end

    -- Check composition is saved
    if not vlib.check_comp(comp) then
        return false
    end

    -- Initialize UTF-8 support
    vlib.init_utf8()

    -- Get composition render range
    local render_start = comp:GetAttrs().COMPN_RenderStart
    local render_end = comp:GetAttrs().COMPN_RenderEnd

    if render_end <= render_start then
        vlib.show_warning(comp, "Invalid render range.\nPlease set a valid render range and try again.")
        return false
    end

    -- Set to Canvas mode
    tool.Switch_BlankCanvas_Source = 1  -- Canvas mode
    vectorfill_workflows.set_output_mode(tool, "render")

    -- Move to start frame
    comp.CurrentTime = render_start
    comp:SetAttrs({COMPN_CurrentTime = render_start})
    comp:SetAttrs({COMPN_RenderEnd = render_start + 1})  -- Render just the single frame

    -- Render single frame
    if show_progress then
        print("Rendering initial blank frame...")
    end

    fusion.CacheManager:Purge()

    local saver = tool:GetChildrenList(false, "Saver")
    if #saver == 0 then
        vlib.show_warning(comp, "Saver node not found")
        return false
    end

    local saver_node = saver[1]
    saver_node.SaveFrames = "HiQInteractive"
    comp:Loop(false)
    comp:Play()
    vlib.sleep(2)
    comp:Stop()

    if show_progress then
        print("Rendered a single blank canvas file")
    end

    -- Restore render range
    comp:SetAttrs({COMPN_RenderEnd = render_end})

    -- Get saver and loader references
    local saverClip = saver_node.Clip[0]
    local seq = vlib.parse_filename(saverClip)

    local loader = tool:GetChildrenList(false, "Loader")
    if #loader == 0 then
        vlib.show_warning(comp, "Loader node not found")
        return false
    end

    local ldr = loader[1]

    -- Configure loader
    ldr.MissingFrames[0] = 2  -- Show missing frames as color

    local padding = string.format("%04d", render_start)
    local loaderClip = seq.Path .. seq.CleanName .. padding .. seq.Extension
    if show_progress then
        print("Clip Parsed and Loaded: " .. loaderClip)
    end
    ldr.Loop[0] = 0

    seq = vlib.parse_filename(comp:MapPath(loaderClip))

    -- Copy frame to create sequence (EXACTLY like VectorWarp)
    if show_progress then
        print("Copying blank frame to all frames in range...")
    end

    comp:Lock()
    local oldName = seq.FullPath

    -- Copy the single rendered frame to all frames in the range
    for frame = render_start, render_end do
        local padding = string.format("%04d", frame)
        local newName = seq.Path .. seq.CleanName .. padding .. seq.Extension
        -- Skip the original frame (it already exists)
        if frame ~= render_start and not vlib.file_exists(newName) then
            if not vlib.copy_file(oldName, newName) then
                print("Failed to copy frame " .. frame)
            end
        end
    end
    comp:Unlock()

    if show_progress then
        print("Canvas files created for all frames")
    end

    -- Load the sequence
    ldr.Clip[0] = loaderClip

    if show_progress then
        print("Canvas files created: " .. loaderClip)
    end

    -- Move loader to match render range
    vlib.move_loader(ldr, comp)

    if show_progress then
        print("[Done] Canvas generation complete")
    end

    return true
end

--- Clear cache and reset - Clears render cache and prepares for fresh processing
--- @param tool object VectorFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorfill_workflows.clear_cache(tool, comp)
    print("=== Clearing VectorFill Cache ===")

    -- Get render range
    local render_start = comp:GetAttrs().COMPN_RenderStart

    -- Purge cache
    fusion.CacheManager:Purge()

    -- Go to start
    comp.CurrentTime = render_start

    print("Cache cleared. Ready for new processing.")
    return true
end

--- Set start frame - Go to the first frame of render range
--- @param tool object VectorFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorfill_workflows.set_start_frame(tool, comp)
    -- Get render start
    local render_start = comp:GetAttrs().COMPN_RenderStart

    -- Go to start frame
    comp.CurrentTime = render_start
    comp:SetAttrs({COMPN_CurrentTime = render_start})

    print("Moved to start frame: " .. render_start)
    return true
end

--- Process - Start the growth processing (assumes canvas already generated)
--- @param tool object VectorFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorfill_workflows.process(tool, comp)
    print("=== Starting VectorFill Processing ===")

    -- Check composition is saved
    if not vlib.check_comp(comp) then
        return false
    end

    -- Get render range
    local render_start = comp:GetAttrs().COMPN_RenderStart
    local render_end = comp:GetAttrs().COMPN_RenderEnd

    -- Set to Output mode and Render output
    tool.Switch_BlankCanvas_Source = 0  -- Output mode
    vectorfill_workflows.set_output_mode(tool, "render")

    -- Go to start frame
    comp.CurrentTime = render_start
    comp:SetAttrs({COMPN_CurrentTime = render_start})

    -- Purge cache
    fusion.CacheManager:Purge()

    -- Find the Saver node
    local saver = tool:GetChildrenList(false, "Saver")
    if #saver > 0 then
        local saver_node = saver[1]

        -- Enable interactive rendering (and leave it that way - no switching!)
        saver_node.SaveFrames = "HiQInteractive"

        local frame_count = render_end - render_start + 1
        print("Starting growth processing for " .. frame_count .. " frames...")

        -- Start playback
        comp:Loop(false)
        comp:Play()

        print("Growth processing started - playback will continue until the end")

        -- Wait for playback to complete
        local wait_time = math.max(5, frame_count * 0.2)  -- Approximate wait time
        vlib.sleep(wait_time)

        -- Switch to Age mode for faster playback
        vectorfill_workflows.set_output_mode(tool, "age")

        print("Processing complete!")
        print("You can now play back the growth effect or switch output modes")
    else
        print("Warning: Saver node not found")
        return false
    end

    return true
end

--- Set output mode helper function
--- @param tool object VectorFill macro tool
--- @param mode string "render", "age", "trail", or "growth_speed"
--- @return boolean Success status
function vectorfill_workflows.set_output_mode(tool, mode)
    local mode_map = {
        render = 0,
        age = 1,
        trail = 2,
        growth_speed = 3
    }

    local mode_value = mode_map[mode]
    if mode_value then
        tool.Switch_OutputMode_Source = mode_value
        print("Output mode set to: " .. mode)
        return true
    else
        print("Invalid mode: " .. tostring(mode))
        print("Valid modes: render, age, trail, growth_speed")
        return false
    end
end

return vectorfill_workflows
