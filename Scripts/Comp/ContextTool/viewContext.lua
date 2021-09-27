function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end


function getViewer(currentView)
    leftViewer = {"Left", "LeftView"}
    rightViewer = {"Right", "RightView"}
    -- print(currentView.ID)
    -- print(currentView:GetID())
    if has_value(leftViewer, currentView.ID) then
        return 1
    elseif has_value(rightViewer, currentView.ID) then
        return 2
    elseif currentView.ID == "Image View" or currentView.ID == "MultiView" then
        print("found floating frame")
        return 3
    else
        print('select viewer, then switch context')
        return nil
    end
end

function switchContext(toolName)
    contextTool = comp:FindTool(toolName)
    local currentView = comp.CurrentFrame.CurrentView
    viewNumber = getViewer(currentView)
    -- print("view number: ", viewNumber)
    prevTool = comp:GetData("ContextTool.previousTool") or toolName
    if viewNumber and currentView.CurrentViewer then
        viewOutput = currentView:GetPreview():GetConnectedOutput()
        if viewOutput then
            currentlyViewedTool = viewOutput:GetTool()
        end
        if currentlyViewedTool then
            if contextTool.Name ~= currentlyViewedTool.Name then
                comp.CurrentFrame:ViewOn(contextTool, viewNumber)
                comp:SetData("ContextTool.previousTool", currentlyViewedTool.Name)
            else
                comp.CurrentFrame:ViewOn(comp:FindTool(prevTool), viewNumber)
                comp:SetData("ContextTool.previousTool", contextTool.Name)
            end
        else 
            comp.CurrentFrame:ViewOn(contextTool, viewNumber)
            comp:SetData("ContextTool.previousTool", contextTool.Name)
        end
    else
        comp.CurrentFrame:ViewOn(contextTool, viewNumber)
        comp:SetData("ContextTool.previousTool", contextTool.Name)
    end
end


if not CONTEXT then
    print('Use <ALT> + 1...9 to switch contexts')
    CONTEXT = 1
end

local toolName = comp:GetData("ContextTool.contexts."..CONTEXT)

if toolName then
    switchContext(toolName)
else 
    print("no context tool found")
end
