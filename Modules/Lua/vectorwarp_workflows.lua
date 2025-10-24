--[[
    VectorWarp Workflow Automation Module
    Provides automated and simplified workflows for VectorWarp operations
    Uses vectorlib for core functionality

    Authors: Emilio Sapia, Alexey Bogomolov
    Module Refactoring: 2024
    License: MIT
--]]

local vectorwarp_workflows = {}

-- Load core library
local vlib = require("vectorlib")

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
function vectorwarp_workflows.auto_process(tool, comp, options)
    options = options or {}
    local method = options.method or "fast"
    local direction = options.direction or "both"
    local show_progress = options.show_progress ~= false
    local auto_reference = options.auto_reference ~= false

    if show_progress then
        print("=== Starting VectorWarp Auto Process ===")
    end

    -- Step 1: Check composition is valid
    if not vlib.check_comp(comp) then
        return false
    end

    -- Step 2: Generate CleanPass
    if show_progress then
        print("Step 1/3: Generating CleanPass STMaps...")
    end

    local success
    if method == "fast" then
        success = vlib.generate_cleanpass_fast(tool, comp)
    else
        success = vlib.render_cleanpass_safe(tool, comp)
    end

    if not success then
        vlib.show_warning(comp, "Failed to generate CleanPass")
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

    vlib.set_reference_frame(tool, comp, refFrame)

    -- Step 4: Analyze motion
    if show_progress then
        print("Step 3/3: Analyzing motion vectors...")
    end

    if direction == "forward" then
        success = vlib.analyze_forward(tool, comp)
    elseif direction == "backward" then
        success = vlib.analyze_backward(tool, comp)
    else
        success = vlib.analyze_both(tool, comp)
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
function vectorwarp_workflows.quick_stabilize(tool, comp)
    print("=== Starting Quick Stabilize ===")

    local renderStart = comp:GetAttrs().COMPN_RenderStart
    local renderEnd = comp:GetAttrs().COMPN_RenderEnd
    local middleFrame = math.floor((renderStart + renderEnd) / 2)

    print("Using middle frame as reference: " .. middleFrame)

    -- Run auto process with middle frame as reference
    return vectorwarp_workflows.auto_process(tool, comp, {
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
function vectorwarp_workflows.quick_track(tool, comp)
    print("=== Starting Quick Track ===")

    -- Run auto process with current frame as reference
    return vectorwarp_workflows.auto_process(tool, comp, {
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
function vectorwarp_workflows.resume_analysis(tool, comp, from_direction)
    print("=== Resuming Analysis ===")

    local refFrame = tool.ReferenceFrame[fu.TIME_UNDEFINED]
    if not refFrame then
        vlib.show_warning(comp, "No reference frame set. Please set reference frame first.")
        return false
    end

    -- Check if CleanPass exists
    local ldr = tool:GetChildrenList(false, "Loader")[1]
    if not ldr or ldr.Clip[0] == "" then
        vlib.show_warning(comp, "No CleanPass found. Please generate CleanPass first.")
        return false
    end

    -- Resume analysis from specified direction
    if from_direction == "forward" then
        return vlib.analyze_forward(tool, comp)
    elseif from_direction == "backward" then
        return vlib.analyze_backward(tool, comp)
    else
        return vlib.analyze_both(tool, comp)
    end
end

--- Batch Process - Process multiple clips with same settings
--- @param comp object Fusion composition
--- @param clips table Array of clip paths
--- @param settings table Processing settings
--- @return table Results for each clip
function vectorwarp_workflows.batch_process(comp, clips, settings)
    local results = {}

    for i, clip_path in ipairs(clips) do
        print("Processing clip " .. i .. " of " .. #clips .. ": " .. clip_path)

        -- Create a new VectorWarp tool for each clip
        local tool = comp:AddTool("MacroOperator", -32768, -32768)
        -- Note: Loading the macro settings would need to be done here

        -- Process the clip
        local success = vectorwarp_workflows.auto_process(tool, comp, settings)

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

--- Interactive Setup - Guide user through setup with dialogs
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean Success status
function vectorwarp_workflows.interactive_setup(tool, comp)
    -- Step 1: Ask about workflow type
    local d = {}
    d[1] = {
        "WorkflowType",
        Name = "Select Workflow Type",
        "Dropdown",
        Default = 1,
        Options = {
            {1, "Stabilization (removes camera shake)"},
            {2, "Motion Tracking (follow object motion)"},
            {3, "Custom (manual settings)"}
        }
    }

    local result = comp:AskUser("VectorWarp Setup", d)
    if not result then
        return false
    end

    local workflow_type = result.WorkflowType

    -- Step 2: Ask about quality settings
    d = {}
    d[1] = {
        "Quality",
        Name = "Processing Quality",
        "Dropdown",
        Default = 1,
        Options = {
            {1, "Fast (file copying)"},
            {2, "Safe (full render)"}
        }
    }
    d[2] = {
        "Direction",
        Name = "Analysis Direction",
        "Dropdown",
        Default = 3,
        Options = {
            {1, "Forward only"},
            {2, "Backward only"},
            {3, "Both directions"}
        }
    }

    result = comp:AskUser("VectorWarp Settings", d)
    if not result then
        return false
    end

    local method = result.Quality == 1 and "fast" or "safe"
    local direction = ({"forward", "backward", "both"})[result.Direction]

    -- Step 3: Execute based on workflow type
    if workflow_type == 1 then
        -- Stabilization
        return vectorwarp_workflows.quick_stabilize(tool, comp)
    elseif workflow_type == 2 then
        -- Motion Tracking
        return vectorwarp_workflows.quick_track(tool, comp)
    else
        -- Custom
        return vectorwarp_workflows.auto_process(tool, comp, {
            method = method,
            direction = direction,
            show_progress = true,
            auto_reference = true
        })
    end
end

--- Validate Setup - Check if VectorWarp is properly configured
--- @param tool object VectorWarp macro tool
--- @param comp object Fusion composition
--- @return boolean, string Success status and message
function vectorwarp_workflows.validate_setup(tool, comp)
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
function vectorwarp_workflows.reset(tool, comp)
    local confirm = vlib.show_confirmation(comp,
        "This will delete all vector files and reset settings.\nContinue?")

    if not confirm then
        return false
    end

    -- Delete vector files
    vlib.delete_vectors(tool, comp)

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
function vectorwarp_workflows.get_status(tool, comp)
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
function vectorwarp_workflows.show_help(comp)
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

return vectorwarp_workflows