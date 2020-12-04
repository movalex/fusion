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
                    Weight = 0.6,
                    ID = 'Label',
                    Text = 'Frames to Offset:',
                    Alignment = {AlignLeft = true, AlignVCenter = true}
                },
                ui:SpinBox {
                    Weight = 0.4,
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
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn - currentOffset
        newOut = renderOut - currentOffset
        if newIn < GStart then
            newIn = GStart
        end
        if newOut < GStart + currentOffset then
            newOut = GStart + currentOffset
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.right.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn + currentOffset
        newOut = renderOut + currentOffset
        if newIn > GEnd - currentOffset then
            newIn = GEnd - currentOffset
        end
        if newOut > GEnd then
            newOut = GEnd
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.minus.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn + currentOffset

        newOut = renderOut - currentOffset
        if newIn > midPoint then
            newIn = midPoint
        end
        if newOut < midPoint then
            newOut = midPoint
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.plus.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        newIn = renderIn - currentOffset
        newOut = renderOut + currentOffset
        if newIn < GStart then
            newIn = GStart
        end
        if newOut > GEnd then
            newOut = GEnd
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
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
