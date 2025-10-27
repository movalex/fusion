--[[
    ReFill Utilities Module
    Provides ReFill-specific functionality and automated workflows
    For iterative growth operations and canvas generation

    Module Refactoring: 2024-2025
    License: MIT
--]]

local refill_utilities = {}

-- Load shared Fusion library
local flib = require("fusionlib")

--- Auto Process - Complete canvas generation and setup workflow in one click
--- Performs: Generate Canvas → Set Start Frame → Process Growth
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.auto_process(tool, comp)
    print("=== Starting ReFill Auto Process ===")

    -- Step 1: Check composition is saved
    if not flib.check_comp(comp) then
        return false
    end

    -- Step 2: Validate inputs are connected
    local growth_source_input = tool:FindMainInput(1)  -- Growth Source
    local image_input = tool:FindMainInput(2)  -- Image

    if not growth_source_input or not growth_source_input:GetConnectedOutput() then
        flib.show_warning(comp, "Growth Source input not connected.\nPlease connect a growth source and try again.")
        return false
    end

    if not image_input or not image_input:GetConnectedOutput() then
        flib.show_warning(comp, "Image input not connected.\nPlease connect an image and try again.")
        return false
    end

    -- Step 3: Generate canvas
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
    
    
    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    tool.GlobalIn = renderStart

    
    -- Set to Canvas mode
    tool.Switch_BlankCanvas_Source = 1
    tool.SV1_SaveFrames = "HiQInteractive"
    flib.sleep(1)

    -- Move to start frame
    comp.CurrentTime = renderStart
    comp:SetAttrs({COMPN_CurrentTime = renderStart})
    comp:SetAttrs({COMPN_RenderEnd = renderStart + 1})  -- Render just the single frame
    compIsLooped = comp:GetAttrs().COMPB_LoopPlay
    
    -- Render single frame
    -- fusion.CacheManager:Purge()
    comp:Loop(false)
    comp:Play()
    flib.sleep(2)
    tool.SV1_SaveFrames = "Full"
    comp:Stop()
    print("Rendered a single blank canvas file")

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
    -- tool.Depth[0] = 5

    seq = flib.parse_filename(comp:MapPath(loaderClip))
    -- Copy frame to create sequence
    print("Copying blank frame to all frames in range...")
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
    
    comp:Lock()
    local clipUpdate = comp:MapPath(loaderClip)
    tool.LD1_Load = clipUpdate
    tool.LD1_Load = clipUpdate .. ""
    ldr:SetAttrs({TOOLB_PassThrough = true})
    ldr:SetAttrs({TOOLB_PassThrough = false})
    comp:Unlock()
    flib.move_loader(ldr, comp)

    print("Canvas files created: " .. loaderClip)
    comp.CurrentTime = renderStart

    -- Move loader to match render range

    print("[Done] Canvas generation complete (fast)")
    return true
end

--- Generate Canvas - Renders all frames (safe method, like VectorWarp's render_cleanpass_safe)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.generate_canvas(tool, comp)
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    local svr = tool:GetChildrenList(false, "Saver")[1]
    
    if not svr then
        flib.show_warning(comp, "Saver node not found")
        return false
    end
    if not ldr then
        flib.show_warning(comp, "Loader node not found")
        return false
    end
    local saverClip = svr.Clip[0]
    
    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    comp.CurrentTime = renderStart
    
    tool.GlobalIn = renderStart
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
    -- tool.Render = 0
    local tempStart = renderStart
    compIsLooped = comp:GetAttrs().COMPB_LoopPlay

    comp:Loop(false)

    fusion.CacheManager:Purge()
    tool.SV1_SaveFrames = "HiQInteractive"
    comp:Play()

    -- Wait for render to complete
    while true do
        -- Check if playback stopped (primary exit condition)
        if not comp:IsPlaying() then
            flib.sleep(1)
            break
        end
        
        -- Check if we've reached the end (secondary exit condition)
        if comp.CurrentTime >= renderEnd then
            print("Canvas generation complete")
            break
        end
        
        -- Update progress only when frame changes
        if comp.CurrentTime > tempStart then
            tempStart = comp.CurrentTime
            print("Rendering canvas frame " .. tempStart)
        end
        
        flib.sleep(0.1)  -- Small delay to avoid busy-waiting
    end

    comp:Stop()
    comp.CurrentTime = renderStart
    comp:Lock()
    local clipUpdate = comp:MapPath(loaderClip)
    tool.LD1_Load = clipUpdate
    tool.LD1_Load = clipUpdate .. ""
    ldr:SetAttrs({TOOLB_PassThrough = true})
    ldr:SetAttrs({TOOLB_PassThrough = false})
    comp:Unlock()
    flib.move_loader(ldr, comp)
    return true
end

--- Clear cache and reset - Clears render cache and prepares for fresh processing
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.clear_cache(tool, comp)
    print("=== Clearing ReFill Cache ===")

    -- Get render range
    local renderStart = comp:GetAttrs().COMPN_RenderStart

    -- Purge cache
    fusion.CacheManager:Purge()

    -- Go to start
    comp.CurrentTime = renderStart

    print("Cache cleared. Ready for new processing.")
    return true
end

--- Set start value - Set the CT5_StartFrame parameter to render start
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.set_start_frame(tool, comp)
    local renderStart = comp:GetAttrs().COMPN_RenderStart
    tool.CT5_StartFrame = renderStart
    print("Start value set to frame: " .. renderStart)
    return true
end

--- Go to start frame - Move timeline to the first frame of render range
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.go_to_start(tool, comp)
    -- Get render start
    local renderStart = comp:GetAttrs().COMPN_RenderStart

    -- Go to start frame
    comp.CurrentTime = renderStart
    print("Moved to start frame: " .. renderStart)
    tool.CT5_StartFrame = renderStart
    print("Start value set to frame: " .. renderStart)
    comp:SetAttrs({COMPN_CurrentTime = renderStart})

    return true
end

--- Process - Start the growth processing (assumes canvas already generated)
--- @param tool object ReFill macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function refill_utilities.process_forward(tool, comp)

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    comp.CurrentTime = renderStart
    -- Set to Output mode and Render output
    tool.Switch_BlankCanvas_Source = 0  -- Output mode
    tool.SV1_SaveFrames = "HiQInteractive"
    refill_utilities.set_output_mode(tool, "render")
    flib.sleep(1)
    compIsLooped = comp:GetAttrs().COMPB_LoopPlay

    -- Purge cache
    comp:Loop(false)
    fusion.CacheManager:Purge()
    local tempStart = renderStart

    -- Play forward
    comp:Play()
    while true do
        -- Check if playback stopped (primary exit condition)
        if not comp:IsPlaying() then
            flib.sleep(1)
            break
        end
        
        -- Check if we've reached the end (secondary exit condition)
        if comp.CurrentTime >= renderEnd then
            print("Reached render end frame: " .. renderEnd)
            break
        end
        
        -- Update and print progress only when frame changes
        if comp.CurrentTime > tempStart then
            tempStart = comp.CurrentTime
            print("Processing frame " .. tempStart)
        end
        
        flib.sleep(0.1)  -- Small delay to avoid busy-waiting
    end

    comp:Stop()
    comp:Loop(compIsLooped)
    refill_utilities.set_output_mode(tool, "age")
    tool.SV1_SaveFrames = "Full"
    print("Forward processing complete")
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
        tool.Switch_OutputMode_Source = mode_value
        print("Output mode set to: " .. mode)
        return true
    else
        print("Invalid mode: " .. tostring(mode))
        print("Valid modes: render, age, trail, growth_speed")
        return false
    end
end

return refill_utilities
