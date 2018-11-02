
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 400,100

win = disp:AddWindow({
  ID = 'SManage',
  WindowTitle = 'Manage Savers',
  Geometry = {100, 400, width, height},
  Spacing = 50,
  
  ui:VGroup{
    ID = 'root',
    
    -- Add your GUI elements here:
    ui:HGroup{
      Margin = 20,
      ui:Button{ID = 'Disable', Text = 'Disable Unselected',},
      ui:Button{ID = 'Enable', Text = 'Enable All',},
    }
  },
})

disabled_tool = "Saver"

-- The window was closed
function win.On.SManage.Close(ev)
    disp:ExitLoop()
end

-- Add your GUI element based event functions here:
-- itm = win:GetItems()

function win.On.Disable.Clicked(ev)
    comp:Lock()
    local selectedSavers = comp:GetToolList(true, disabled_tool)
    local allSavers = comp:GetToolList(false, disabled_tool)
    for i, currentSaver in pairs(allSavers) do
        local isSelected = false
        for j, currentSelectedSaver in pairs(selectedSavers) do
            if(currentSaver == currentSelectedSaver) then
            isSelected = true
        end
    end
        if isSelected == false then
            currentSaver:SetAttrs( { TOOLB_PassThrough = true } )
        end
    end
    comp:Unlock()
end

function win.On.Enable.Clicked(ev)
    comp:Lock()
    local allSavers = comp:GetToolList(false, disabled_tool)
        for i, currentSaver in pairs(allSavers) do
            currentSaver:SetAttrs( { TOOLB_PassThrough = false } )
        end
    comp:Unlock()
end

win:Show()
disp:RunLoop()
win:Hide()
