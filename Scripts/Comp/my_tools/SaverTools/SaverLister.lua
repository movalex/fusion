local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 650,200

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
    WindowTitle = 'Saver Lister',
    Geometry = {100, 400, width, height},
    Spacing = 5,
    
  ui:VGroup{
    ID = 'root',
    ui:Tree{ID = 'Tree', SortingEnabled=true, Events = {ItemDoubleClicked=true, ItemClicked=true,},},
  },
})

itm = win:GetItems()

hdr = itm.Tree:NewItem()
hdr.Text[0] = 'Pass'
hdr.Text[1] = 'Saver Name'
hdr.Text[2] = 'In'
hdr.Text[3] = 'Out'
hdr.Text[4] = 'Destination'
-- hdr.Text[5] = ''
itm.Tree:SetHeaderItem(hdr)
itm.Tree.ColumnCount = 5

-- Resize the Columns
itm.Tree.ColumnWidth[0] = 30
itm.Tree.ColumnWidth[1] = 100
itm.Tree.ColumnWidth[2] = 40
itm.Tree.ColumnWidth[3] = 40
itm.Tree.ColumnWidth[4] = 300 
-- itm.Tree.ColumnWidth[5] = 220
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
