local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 250,100

comp = fu:GetCurrentComp()


function getBounds()
    compAttrs = comp:GetAttrs()
    rStart = compAttrs.COMPN_RenderStart
    rEnd = compAttrs.COMPN_RenderEnd
    return rStart, rEnd
end


function plusOffset(offset, s, e)
    comp = fu:GetCurrentComp()
    comp:SetAttrs({COMPN_RenderStart = s - offset})
    comp:SetAttrs({COMPN_RenderEnd = e + offset})
end


function minusOffset(offset, s, e)
    comp = fu:GetCurrentComp()
    comp:SetAttrs({COMPN_RenderStart = s + offset})
    comp:SetAttrs({COMPN_RenderEnd = e - offset})
    comp:SetData("FrameRanger.IsSet", "true")
end

function leftOffset(offset, s, e)
    comp = fu:GetCurrentComp()
    comp:SetAttrs({COMPN_RenderStart = s - offset})
    comp:SetAttrs({COMPN_RenderEnd = e - offset})
    comp:SetData("FrameRanger.IsSet", "true")
end

function rightOffset(offset, s, e)
    comp = fu:GetCurrentComp()
    comp:SetAttrs({COMPN_RenderStart = s + offset})
    comp:SetAttrs({COMPN_RenderEnd = e + offset})
    comp:SetData("FrameRanger.IsSet", "true")
end

function showUI()
    frameOffset = comp:GetData("FrameRanger.offset") or 24
    local windowPosX = 900
    local windowPosY = 800
    local buttonSize = {45, 25}

    win = disp:AddWindow({
        ID = "FrameRanger",
        TargetID = "FrameRanger",
        WindowTitle = "Frame Ranger",
        Geometry = {windowPosX +20, windowPosY, width, height},

        ui:VGroup{
        ID = 'root',
            ui:HGroup{
                ui:HGap(0.25,0),
                ui:Label{
                    Weight = 0.8,
                    ID = 'Label',
                    Text = 'Frames to Offset:',
                    Alignment = {AlignLeft = true, AlignVCenter = true}
                },
                ui:SpinBox {
                    Weight = 0.2,
                    ID = 'offset', Value = frameOffset,
                    Alignment = {AlignRight = true},
                    Maximum = comp:GetAttrs().COMPN_GlobalEnd / 2,
                    Events = {ValueChanged = true, EditingFinished = true},
                },
            },
            ui:HGroup {
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'minus', Text = '> <',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'plus', Text = '< >',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'left', Text = '< <',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'right', Text = '> >',
                },
            },
            ui:VGroup {
                ui:Button{
                    ID = 'reset', Text = 'Reset Globals',
                },
            }
        }
    })
    itm = win:GetItems()
    itm.offset:SelectAll()

    function win.On.offset.ValueChanged(ev)
        comp:SetData("FrameRanger.offset", itm.offset.Value)
    end

    function win.On.offset.EditingFinished(ev)
        comp:SetData("FrameRanger.offset", itm.offset.Value)
    end

    function win.On.left.Clicked(ev)
        local s, e = getBounds()
        local currentOffset = itm.offset.Value
        leftOffset(currentOffset, s, e)
    end

    function win.On.right.Clicked(ev)
        local s, e = getBounds()
        local currentOffset = itm.offset.Value
        rightOffset(currentOffset, s, e)
    end

    function win.On.minus.Clicked(ev)
        local s, e = getBounds()
        local currentOffset = itm.offset.Value
        minusOffset(currentOffset, s, e)
    end

    function win.On.plus.Clicked(ev)
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        local currentOffset = itm.offset.Value
        if renderIn - currentOffset < GStart or renderOut + currentOffset > GEnd then
            comp:SetAttrs({COMPN_RenderEnd = GEnd})
            comp:SetAttrs({COMPN_RenderStart = GStart})
            return
        end
        plusOffset(currentOffset, renderIn, renderOut)
    end

    function win.On.reset.Clicked(ev)
        comp = fu:GetCurrentComp()
        gStart = comp:GetAttrs().COMPN_GlobalStart
        if gStart < 0 then
            gStart = 0
            comp:SetAttrs({COMPN_GlobalStart = 0})
        end
        gEnd = comp:GetAttrs().COMPN_GlobalEnd
        comp:SetAttrs({COMPN_RenderStart = gStart})
        comp:SetAttrs({COMPN_RenderEnd = gEnd})
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        comp:SetData("FrameRanger.IsSet", "false")
    end

    function win.On.FrameRanger.Close(ev)
        disp:ExitLoop()
    end

    win:Show()
    disp:RunLoop()
    win:Hide()
end


showUI()
