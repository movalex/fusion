-- if not CONTEXT then
--     CONTEXT = 1
-- end

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function getViewer(currentView)
    local leftViewer = {"Left", "LeftView"}
    local rightViewer = {"Right", "RightView"}
    if has_value(leftViewer, currentView.ID) then
        return 1
    elseif has_value(rightViewer, currentView.ID) then
        return 2
    else
        print('select viewer, then switch context')
        return nil
    end
end

function switchContext(toolName)
    local currentView = comp.CurrentFrame.CurrentView
    viewNumber = getViewer(currentView)
    if viewNumber then
        -- previousTool = comp:GetData("Context.previousTool")
        -- if previousTool ~= nil and previousTool ~= toolName then
        --     print("prev and tool", previousTool, toolName)
        --     comp:SetData("Context.previousTool")
        --     comp.CurrentFrame:ViewOn(currentView, comp:FindTool(previousTool))
        --     return
        -- end
        local viewOutput = currentView:GetPreview():GetConnectedOutput()
        if not viewOutput then
            -- no toolName in current viewer
            comp.CurrentFrame:ViewOn(comp:FindTool(toolName), viewNumber)
            -- comp:SetData("ContextTool."..CONTEXT, toolName)
            return
        end
        local currentlyViewedTool = viewOutput:GetTool() 
        if currentlyViewedTool ~= nil then
            -- comp:SetData("ContextTool.previousTool", currentlyViewedTool.Name)
            local contextTool = comp:FindTool(toolName)
            comp.CurrentFrame:ViewOn(contextTool, viewNumber)
        end
    end
end
print(CONTEXT)
local toolName = comp:GetData("ContextTool."..CONTEXT)
if toolName then
    switchContext(toolName)
else print("add at least one context tool")
end
