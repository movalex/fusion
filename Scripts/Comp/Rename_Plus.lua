local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 300,78

function showUI(tool, str)
    win = disp:AddWindow({
        ID = 'renameplus',
        TargetID = "renameplus",
        WindowTitle = 'Rename+ Tool',
        Geometry = {700, 510, width, height},
        Spacing = 50,
        
        ui:VGroup{
        ID = 'root',
        -- GUI elements:
            ui:HGroup{
                VMargin = 10,
                ui:LineEdit {
                    ID = 'mytext', Text = tostring(str),
                    Alignment = {AlignHCenter = true},
                    Events = {ReturnPressed = true},
                }
            },
            ui:HGroup{
                VMargin = 3,
                
                ui:VGap(20),
                ui:Button{
                    ID = 'cancel', Text = 'Cancel'
                },
                ui:Button{
                    ID = 'ok', Text = 'Ok',
                    
                }
            }
        }
    })
    itm = win:GetItems()
    itm.mytext:SelectAll()
    s = itm.ok:GetAutoDefault()

    function win.On.renameplus.Close(ev)
        disp:ExitLoop()
    end
        
    function win.On.ok.Clicked(ev)
        tool:SetAttrs({TOOLS_Name = itm.mytext:GetText()})
        disp:ExitLoop()
    end
    
    -- function win.On.esc.Clicked(ev)
    --     disp:ExitLoop()
    -- end

    function win.On.cancel.Clicked(ev)
        disp:ExitLoop()
    end

    function win.On.mytext.ReturnPressed(ev)
        tool:SetAttrs({TOOLS_Name = itm.mytext:GetText()})
        disp:ExitLoop()
    end

    -- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the Atomizer window instead of closing the foreground composite.
    app:AddConfig("renameplus", {
        Target {
            ID = "renameplus",
        },
    
        Hotkeys {
            Target = "renameplus",
            Defaults = true,
        
            ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
            CONTROL_W = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
            CONTROL_F4 = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
        },
    })

    win:Show()
    disp:RunLoop()
    win:Hide()
end

-- comp:Lock()
composition:StartUndo("renaming")
active = comp.ActiveTool
if active and active:GetAttrs().TOOLS_RegID == 'Underlay' then
    current_name = active:GetAttrs().TOOLS_Name
    showUI(active, current_name)
else
    local selectednodes = comp:GetToolList(true)
    for i, tool in ipairs(selectednodes) do
        name = tool:GetAttrs().TOOLS_Name
        showUI(tool,name)
    end
end
composition:EndUndo(true)
-- comp:Unlock()
