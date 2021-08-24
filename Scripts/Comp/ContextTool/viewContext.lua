function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- function set(...)
--    local ret = {}
--    for _,k in ipairs({...}) do ret[k] = true end
--    return ret
-- end

function getViewer(currentView)
    leftViewer = {"Left", "LeftView"}
    rightViewer = {"Right", "RightView"}
    print(currentView:GetID())
    if has_value(leftViewer, currentView.ID) then
        return 1
    elseif has_value(rightViewer, currentView.ID) then
        return 2
    elseif currentView:GetID() == "MultiView" then
        print("found")
        return tonumber(currentView.ID:match("%d$"))
    else
        print('select viewer, then switch context')
        return nil
    end
end

function switchContext(toolName)
    contextTool = comp:FindTool(toolName)
    local currentView = comp.CurrentFrame.CurrentView
    viewNumber = getViewer(currentView)
    print(viewNumber)
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

local toolName = comp:GetData("ContextTool.contexts."..CONTEXT)

if toolName then
    switchContext(toolName)
else 
    print("no context tool found")
end
