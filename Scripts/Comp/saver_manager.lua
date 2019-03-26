local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 250,110

app:AddConfig("SManager", {
    Target {
        ID = "SManager",
    },
    Hotkeys {
        Target = "SManager",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
    },
})

win = disp:AddWindow({
  ID = 'SManage',
  TargetID = 'SManager',
  WindowTitle = 'Manage Savers',
  Geometry = {100, 400, width, height},
  Spacing = 5,
  
  ui:VGroup{
    ID = 'root',
    
    -- Add your GUI elements here:
    ui:HGroup{VMargin = 10,
      ui:Button{ID = 'Disable', Text = 'Disable Unselected',},
      ui:Button{ID = 'Enable', Text = 'Enable All',},
    },
    ui:VGroup{
      ui.Button{ID= 'SelectAll', Text = 'Select All Savers'}
    },
    ui:VGroup{
      ui.Button{ID= 'CreateLoaders', Text = 'Create Loaders'}
    }
  },
})

-- The window was closed
function win.On.SManage.Close(ev)
    disp:ExitLoop()
end

-- Add your GUI element based event functions here:
-- itm = win:GetItems()

function win.On.Disable.Clicked(ev)
    -- comp:Lock()
    local selectedSavers = comp:GetToolList(true, "Saver")
    local allSavers = comp:GetToolList(false, "Saver")
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
    -- comp:Unlock()
end

function win.On.Enable.Clicked(ev)
    -- comp:Lock()
    local allSavers = comp:GetToolList(false, "Saver")
        for i, currentSaver in pairs(allSavers) do
            currentSaver:SetAttrs( { TOOLB_PassThrough = false } )
        end
    -- comp:Unlock()
end

function win.On.SelectAll.Clicked(ev)
    local allSavers = comp:GetToolList(false, "Saver")
    flow = comp.CurrentFrame.FlowView
    for _, sav in pairs(allSavers) do
        flow:Select(sav)
    end
end

function win.On.CreateLoaders.Clicked(ev)
    comp:RunScript('Scripts:Comp/loader_from_saver.lua')
end

win:Show()
disp:RunLoop()
win:Hide()
