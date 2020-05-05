local CONTEXT = 3

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function operateView(tool)
    local currentView = comp.CurrentFrame.CurrentView
    viewNumber = getViewer(currentView)
    if viewNumber then
        local viewOutput = currentView:GetPreview():GetConnectedOutput()
        if not viewOutput then
            print('no tool in current viewer')
            return
        end
        local currentlyViewedTool = viewOutput:GetTool() 
        if currentlyViewedTool ~= nil then
            comp:SetData("ContextTool."..CONTEXT, currentlyViewedTool.Name)
            local contextTool = comp:FindTool(tool)
            comp.CurrentFrame:ViewOn(contextTool, viewNumber)
        end
    end
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

local tool = comp:GetData("ContextTool."..CONTEXT)
if tool then
    operateView(tool)
end
