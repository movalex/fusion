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
        contextTool = comp:FindTool(toolName)
        viewOutput = currentView:GetPreview():GetConnectedOutput()
        if viewOutput then
            currentlyViewedTool = viewOutput:GetTool()
            prevTool = comp:GetData("ContextTool.previousTool") or toolName
            if currentlyViewedTool and toolName ~= currentlyViewedTool.Name then
                comp.CurrentFrame:ViewOn(contextTool, viewNumber)
                comp:SetData("ContextTool.previousTool", currentlyViewedTool.Name)
            else
                comp.CurrentFrame:ViewOn(comp:FindTool(prevTool), viewNumber)
                comp:SetData("ContextTool.previousTool", toolName)
            end
        else
            comp.CurrentFrame:ViewOn(contextTool, viewNumber)
        end
    end
end

local toolName = comp:GetData("ContextTool."..CONTEXT)

if toolName then
    switchContext(toolName)
else 
    print("no context tool found")
end
