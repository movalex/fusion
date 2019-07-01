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
          ui:Button{ID = 'Disable', Text = 'Solo Selected',},
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

function check_selected(tool)
    return tool:GetAttrs('TOOLB_Selected')
end

function check_enabled(tool)
    return tool:GetAttrs('TOOLB_PassThrough')
end

function win.On.Disable.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    local selectedSavers = cmp:GetToolList(true, "Saver")
    local allSavers = cmp:GetToolList(false, "Saver")
    for _, currentSaver in pairs(allSavers) do
        if not check_selected(currentSaver) then
            currentSaver:SetAttrs( { TOOLB_PassThrough = true } )
        end
    end
    for _, sel in pairs(selectedSavers) do
        if check_enabled(sel) then
            sel:SetAttrs({ TOOLB_PassThrough = false})
        end
    end
end

function win.On.Enable.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    local allSavers = cmp:GetToolList(false, "Saver")
        for i, currentSaver in pairs(allSavers) do
            currentSaver:SetAttrs( { TOOLB_PassThrough = false } )
        end
end

function win.On.SelectAll.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    local allSavers = cmp:GetToolList(false, "Saver")
    flow = cmp.CurrentFrame.FlowView
    for _, sav in pairs(allSavers) do
        flow:Select(sav)
    end
end

function win.On.CreateLoaders.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    cmp:RunScript('Scripts:Comp/Saver Tools/LoaderFromSaver.lua')
end

win:Show()
disp:RunLoop()
win:Hide()
