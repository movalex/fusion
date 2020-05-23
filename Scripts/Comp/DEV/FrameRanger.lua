local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 220,160

comp = fu:GetCurrentComp()

app:AddConfig("FRanger", {
    Target {
        ID = "FRanger",
    },
    Hotkeys {
        Target = "FRanger",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
    },
})
function getBounds()
    compAttrs = comp:GetAttrs()
    rStart = compAttrs.COMPN_RenderStart
    rEnd = compAttrs.COMPN_RenderEnd
    return rStart, rEnd
end


function plusOffset(offset, s, e)
    comp:SetAttrs({COMPN_RenderStart = s + offset})
    comp:SetAttrs({COMPN_RenderEnd = e - offset})
end


function minusOffset(offset, s, e)
    comp:SetAttrs({COMPN_RenderStart = s - offset})
    comp:SetAttrs({COMPN_RenderEnd = e + offset})
end


function showUI()
    frameOffset = comp:GetData("FR.offset") or 24
    local x = 500
    local y = 600
    -- local x = fu:GetMousePos()[1]
    -- local y = fu:GetMousePos()[2]
    -- if y < 90 then
    --     y = 130
    -- end

    win = disp:AddWindow({
        ID = "FRanger",
        TargetID = "FRanger",
        WindowTitle = "Frame Ranger",
        Geometry = {x+20, y, width, height},
        Spacing = 10,
        
        ui:VGroup{
        ID = 'root',
        -- GUI elements:
            ui:HGroup{
                ui:Label{
                    Weight = 0.8,
                    ID = 'Label',
                    Text = 'amount of frames to offset:',
                    Alignment = {AlignRight = true, AlignVCenter = true}
                },
                ui:LineEdit {
                    Weight = 0.2,
                    ID = 'offset', Text = tostring(frameOffset),
                    Alignment = {AlignCenter = true},
                    Events = {ReturnPressed = true},
                }
            },
            ui:HGroup{
                VMargin = 3,
                ui:Button{
                    ID = 'minus', Text = '-',
                },
                    ui:Button{
                    ID = 'plus', Text = '+',
                    
                }
            },
            ui:VGroup{
                VMargin = 3,
                ui:Button{
                    ID = 'reset', Text = 'reset globals',
                },
            },
            ui:HGroup{
                VMargin = 3,
                ui:Button{
                    ID = 'setIn', Text = 'saver IN',
                },
                    ui:Button{
                    ID = 'setOut', Text = 'saver out',
                }
            },
        }
    })
    itm = win:GetItems()
    itm.offset:SelectAll()
    function win.On.minus.Clicked(ev)
        comp:SetData("FR.set", true)
        local s, e = getBounds()
        local currentOffset = tonumber(itm.offset:GetText())
        plusOffset(currentOffset, s, e)
    end
    function win.On.plus.Clicked(ev)
        comp:SetData("FR.set", false)
        local s, e = getBounds()
        local currentOffset = tonumber(itm.offset:GetText())
        local gstart = comp:GetAttrs().COMPN_GlobalStart
        if s - currentOffset < 0 then
            comp:SetAttrs({COMPN_GlobalStart = s - currentOffset})
        end
        minusOffset(currentOffset, s, e)
    end
    function win.On.close.Clicked(ev)
        disp:ExitLoop()
    end
    function win.On.offset.ReturnPressed(ev)
        frameOffset = comp:SetData("FR.offset", itm.offset:GetText()) 
    end 
    function win.On.setIn.Clicked (ev)
        tool = comp.ActiveTool
        if tool and tool.ID == 'Saver' then
            tool:SetAttrs({TOOLNT_EnabledRegion_Start = comp.CurrentTime})
        end
    end
    function win.On.setOut.Clicked (ev)
        tool = comp.ActiveTool
        if tool and tool.ID == 'Saver' then
            tool:SetAttrs({TOOLNT_EnabledRegion_End = comp.CurrentTime})
        end
    end
    function win.On.reset.Clicked(ev)
        gStart = comp:GetAttrs().COMPN_GlobalStart
        if gStart < 0 then
            gStart = 0
            comp:SetAttrs({COMPN_GlobalStart = 0})
        end
        gEnd = comp:GetAttrs().COMPN_GlobalEnd
        comp:SetAttrs({COMPN_RenderStart = gStart})
        comp:SetAttrs({COMPN_RenderEnd = gEnd})
    end

    function win.On.FRanger.Close(ev)
        disp:ExitLoop()
    end


    win:Show()
    disp:RunLoop()
    win:Hide()
end

showUI()
